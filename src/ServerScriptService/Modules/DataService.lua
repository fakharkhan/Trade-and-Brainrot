local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {
	profiles = {}, -- [player] = data table
	_store = nil,
	_loadFailed = {}, -- [userId] = true — never overwrite on failed load
}

local DEFAULT = {
	Coins = Config.StartCoins,
	Rebirths = 0,
	LuckLevel = 0,
	LastDaily = 0,
	Slots = {}, -- { {Id=, Super=} , ... } indexed by pedestal
}

local function cloneDefault()
	local t = {
		Coins = Config.IsStudio and Config.StartCoins or 100,
		Rebirths = 0,
		LuckLevel = 0,
		LastDaily = 0,
		Slots = {},
	}
	return t
end

function DataService.init()
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		DataService._store = store
	else
		warn("[DataService] DataStore unavailable: " .. tostring(store))
		DataService._store = nil
	end
end

local function keyFor(userId)
	return "p_" .. tostring(userId)
end

function DataService.load(player)
	local data = cloneDefault()
	if not DataService._store then
		DataService.profiles[player] = data
		return data, true
	end

	local ok, result
	for attempt = 1, 3 do
		ok, result = pcall(function()
			return DataService._store:GetAsync(keyFor(player.UserId))
		end)
		if ok then break end
		task.wait(0.5 * attempt)
	end

	if not ok then
		warn("[DataService] Load failed for " .. player.Name .. ": " .. tostring(result))
		DataService._loadFailed[player.UserId] = true
		DataService.profiles[player] = data
		return data, false
	end

	if typeof(result) == "table" then
		data.Coins = tonumber(result.Coins) or data.Coins
		data.Rebirths = tonumber(result.Rebirths) or 0
		data.LuckLevel = tonumber(result.LuckLevel) or 0
		data.LastDaily = tonumber(result.LastDaily) or 0
		data.Slots = typeof(result.Slots) == "table" and result.Slots or {}
	end
	DataService.profiles[player] = data
	DataService._loadFailed[player.UserId] = nil
	return data, true
end

function DataService.get(player)
	return DataService.profiles[player]
end

function DataService.save(player)
	local data = DataService.profiles[player]
	if not data then return false end
	if DataService._loadFailed[player.UserId] then
		warn("[DataService] Skipping save for " .. player.Name .. " (previous load failed)")
		return false
	end
	if not DataService._store then
		return true -- Studio / unpublished: treat as ok
	end
	local ok, err = pcall(function()
		DataService._store:SetAsync(keyFor(player.UserId), data)
	end)
	if not ok then
		warn("[DataService] Save failed for " .. player.Name .. ": " .. tostring(err))
	end
	return ok
end

function DataService.release(player)
	DataService.save(player)
	DataService.profiles[player] = nil
	DataService._loadFailed[player.UserId] = nil
end

function DataService.startAutosave()
	task.spawn(function()
		while true do
			task.wait(Config.AutosaveSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				pcall(function() DataService.save(player) end)
			end
		end
	end)
end

function DataService.bindToClose()
	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			pcall(function() DataService.save(player) end)
		end
		task.wait(2)
	end)
end

return DataService
