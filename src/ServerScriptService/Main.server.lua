--[[
	Trade and Brainrot — main server entry.
	Loads modules with pcall isolation so one failure cannot stop the game.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ensure Shared modules are require-able (Rojo maps ReplicatedStorage.Shared)
local function boot()
	local Util = require(script.Parent.Modules.Util)
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local DataService = require(script.Parent.Modules.DataService)
	local Bases = require(script.Parent.Modules.Bases)
	local Track = require(script.Parent.Modules.Track)
	local Shop = require(script.Parent.Modules.Shop)
	local Economy = require(script.Parent.Modules.Economy)
	local PlayersService = require(script.Parent.Modules.PlayersService)

	Util.safe("DataService.init", function()
		DataService.init()
		DataService.startAutosave()
		DataService.bindToClose()
	end)

	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = workspace

	Util.safe("world", function()
		Util.makePart("Ground", Vector3.new(400, 1, 220), Vector3.new(0, -0.5, 0), Color3.fromRGB(90, 140, 80), Enum.Material.Grass, map)

		local spawn = Instance.new("SpawnLocation")
		spawn.Position = Vector3.new(0, 1, 75)
		spawn.Size = Vector3.new(12, 1, 12)
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Parent = map

		local wallColor = Color3.fromRGB(110, 110, 120)
		local H, T = 20, 2
		local halfX, halfZ = 190, 110
		Util.makePart("Wall_N", Vector3.new(halfX * 2, H, T), Vector3.new(0, H / 2, -halfZ), wallColor, Enum.Material.Concrete, map)
		Util.makePart("Wall_S", Vector3.new(halfX * 2, H, T), Vector3.new(0, H / 2, halfZ), wallColor, Enum.Material.Concrete, map)
		Util.makePart("Wall_W", Vector3.new(T, H, halfZ * 2), Vector3.new(-halfX, H / 2, 0), wallColor, Enum.Material.Concrete, map)
		Util.makePart("Wall_E", Vector3.new(T, H, halfZ * 2), Vector3.new(halfX, H / 2, 0), wallColor, Enum.Material.Concrete, map)

		Bases.buildAll(map)
		Bases.installApi()
	end)

	Util.safe("Track.start", function() Track.start(map) end)
	Util.safe("Shop.showcase", function() Shop.buildShowcase(map) end)
	Util.safe("Shop.super", function() Shop.buildSuperStand(map) end)
	Util.safe("Shop.daily", function() Shop.buildDailyPad(map) end)
	Util.safe("Shop.rebirth", function() Shop.buildRebirthPad(map) end)
	Util.safe("Economy", function() Economy.startIncomeLoop() end)
	Util.safe("PlayersService", function() PlayersService.start() end)

	-- Touch remotes so they exist
	local _ = Remotes.GameEvent
	local _2 = Remotes.IncomeUpdate

	print("[TradeBrainrot] World ready. Modules loaded.")
end

local ok, err = pcall(boot)
if not ok then
	warn("[TradeBrainrot] FATAL boot failure: " .. tostring(err))
end
