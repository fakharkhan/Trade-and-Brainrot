local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Util = require(script.Parent.Util)
local Bases = require(script.Parent.Bases)
local Carry = require(script.Parent.Carry)
local DataService = require(script.Parent.DataService)
local RateLimit = require(script.Parent.RateLimit)

local Progress = {}

-- Spend coins to raise the player level (1 to Config.MaxLevel).
-- amount: a number of levels to buy, or "max" to buy as many as affordable.
function Progress.upgradeLevel(player, amount)
	if not RateLimit.allow(player, "level", 0.1) then return end
	local data = DataService.get(player)
	local coins = Util.getStat(player, "Coins")
	if not (data and coins) then return end

	if amount == "max" then
		amount = Config.MaxLevel
	elseif typeof(amount) == "number" then
		amount = math.clamp(math.floor(amount), 1, 100)
	else
		return
	end

	local level = data.Level or 1
	if level >= Config.MaxLevel then
		Util.notify(player, "You are already at max level (" .. Config.MaxLevel .. ").")
		return
	end

	local target = math.min(Config.MaxLevel, level + amount)
	local newLevel, spent = level, 0
	while newLevel < target do
		local cost = Config.LevelCost(newLevel)
		if coins.Value - spent < cost then break end
		spent += cost
		newLevel += 1
	end

	if newLevel == level then
		Util.notify(player, ("Not enough coins. Level %d costs %d."):format(level + 1, Config.LevelCost(level)))
		return
	end

	coins.Value -= spent
	data.Coins = coins.Value
	data.Level = newLevel
	local levelStat = Util.getStat(player, "Level")
	if levelStat then levelStat.Value = newLevel end
	Bases.refreshLabels(player)
	Util.notify(player, ("Level %d! Income x%.2f"):format(newLevel, Config.LevelIncomeMultiplier(newLevel)))
end

function Progress.tryRebirth(player)
	if not RateLimit.allow(player, "rebirth", 2) then return end
	if Carry.isCarrying(player) then
		Util.notify(player, "Place your carried brainrot before rebirthing.")
		return
	end
	local data = DataService.get(player)
	if not data then return end
	local income = Bases.totalIncome(player)
	if income < Config.RebirthMinIncome then
		Util.notify(player, ("Need %d income/s to rebirth (you have %d)."):format(Config.RebirthMinIncome, income))
		return
	end
	Bases.clearAllSlots(player)
	local coins = Util.getStat(player, "Coins")
	if coins then
		coins.Value = Config.IsStudio and Config.StartCoins or 100
		data.Coins = coins.Value
	end
	data.Rebirths = (data.Rebirths or 0) + 1
	data.LuckLevel = (data.LuckLevel or 0) + 1
	data.Slots = {}
	local rebirthStat = Util.getStat(player, "Rebirths")
	if rebirthStat then rebirthStat.Value = data.Rebirths end
	local pct = math.floor(Config.RebirthIncomeBonus * 100 * data.Rebirths)
	Util.notify(player, ("Rebirth #%d! Permanent +%d%% income. Luck +1."):format(data.Rebirths, pct))
	DataService.save(player)
end

function Progress.start()
	local remotes = require(ReplicatedStorage.Shared.Remotes)
	if remotes.GameEvent then
		remotes.GameEvent.OnServerEvent:Connect(function(player, action, a)
			if action == "UpgradeLevel" then
				Progress.upgradeLevel(player, a)
			end
		end)
	end
end

return Progress
