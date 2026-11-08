local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)
local Util = require(script.Parent.Util)
local Bases = require(script.Parent.Bases)
local Carry = require(script.Parent.Carry)
local DataService = require(script.Parent.DataService)
local RateLimit = require(script.Parent.RateLimit)

local PlayersService = {}

local function teleportToBase(player, char)
	local base = Bases.baseOf[player]
	if not base then return end
	char:WaitForChild("HumanoidRootPart", 5)
	task.wait()
	pcall(function()
		char:PivotTo(CFrame.new(base.SpawnPos))
	end)
end

local function syncProfileFromLive(player)
	local data = DataService.get(player)
	if not data then return end
	local coins = Util.getStat(player, "Coins")
	if coins then data.Coins = coins.Value end
	data.Slots = Bases.serializeSlots(player)
end

function PlayersService.setup(player)
	if player:FindFirstChild("leaderstats") then
		return
	end

	local data, loadedOk = DataService.load(player)

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.Coins or Config.StartCoins
	coins.Parent = stats

	local brainrots = Instance.new("IntValue")
	brainrots.Name = "Brainrots"
	brainrots.Value = 0
	brainrots.Parent = stats

	local income = Instance.new("IntValue")
	income.Name = "Income"
	income.Value = 0
	income.Parent = stats

	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = data.Level or 1
	level.Parent = stats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = data.Rebirths or 0
	rebirths.Parent = stats

	stats.Parent = player

	coins:GetPropertyChangedSignal("Value"):Connect(function()
		local d = DataService.get(player)
		if d then d.Coins = coins.Value end
	end)

	local base = Bases.assign(player)
	if not base then
		Util.notify(player, "Server is full - no free base!")
		return
	end

	Bases.applySavedSlots(player, data.Slots)

	local hasAny = Bases.countOwned(player) > 0
	if not hasAny and Config.StudioGiveStarterBrainrot then
		base.Slots[1] = { Def = BrainrotDefs[1], Super = false }
		Bases.refreshSlot(base, 1)
	end

	Bases.onChanged = Bases.onChanged or function(p)
		syncProfileFromLive(p)
	end

	player.CharacterAdded:Connect(function(char)
		teleportToBase(player, char)
	end)
	player.CharacterRemoving:Connect(function()
		Bases.returnCarry(player)
		syncProfileFromLive(player)
	end)
	if player.Character then
		task.spawn(teleportToBase, player, player.Character)
	end

	local msg = ("Welcome! %d coins | Level %d"):format(coins.Value, data.Level or 1)
	if (data.Rebirths or 0) > 0 then
		msg ..= (" | Rebirths: %d"):format(data.Rebirths)
	end
	if not loadedOk then
		msg ..= " (save load failed — progress may not persist this session)"
	end
	Util.notify(player, msg)
end

function PlayersService.remove(player)
	syncProfileFromLive(player)
	DataService.release(player)
	Bases.release(player)
	RateLimit.clear(player)
	Carry.clear(player)
end

function PlayersService.start()
	Bases.onChanged = function(player)
		syncProfileFromLive(player)
	end

	Players.PlayerAdded:Connect(function(player)
		Util.safe("setupPlayer " .. player.Name, function()
			PlayersService.setup(player)
		end)
	end)
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			Util.safe("setupPlayer " .. p.Name, function()
				PlayersService.setup(p)
			end)
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		Util.safe("removePlayer " .. player.Name, function()
			PlayersService.remove(player)
		end)
	end)
end

return PlayersService
