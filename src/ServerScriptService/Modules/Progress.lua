local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Util = require(script.Parent.Util)
local Bases = require(script.Parent.Bases)
local Carry = require(script.Parent.Carry)
local DataService = require(script.Parent.DataService)
local RateLimit = require(script.Parent.RateLimit)

local Progress = {}

local DAY = 86400

function Progress.claimDaily(player)
	if not RateLimit.allow(player, "daily", 1) then return end
	local data = DataService.get(player)
	if not data then return end
	local now = os.time()
	if data.LastDaily > 0 and (now - data.LastDaily) < DAY then
		local left = DAY - (now - data.LastDaily)
		Util.notify(player, ("Daily already claimed. Come back in %dh."):format(math.ceil(left / 3600)))
		return
	end
	data.LastDaily = now
	local coins = Util.getStat(player, "Coins")
	if coins then
		coins.Value += Config.DailyBonusCoins
		data.Coins = coins.Value
	end
	Util.notify(player, ("Daily bonus! +%d coins"):format(Config.DailyBonusCoins))
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

return Progress
