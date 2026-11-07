local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)
local Util = require(script.Parent.Util)
local Bases = require(script.Parent.Bases)
local RateLimit = require(script.Parent.RateLimit)

local Shop = {}

function Shop.buildShowcase(map)
	local folder = Instance.new("Folder")
	folder.Name = "BrainrotShowcase"
	folder.Parent = map

	local platform = Util.makePart("ShowcasePad", Vector3.new(36, 1, 10), Vector3.new(0, 0.5, 55), Color3.fromRGB(45, 45, 55), Enum.Material.Slate, folder)
	Util.makeLabel(platform, "Showcase", UDim2.fromOffset(100, 24), Vector3.new(0, 5, 0), 30)

	-- Showcase a mix including the newest sketch-based brainrots
	local BrainrotModels = require(script.Parent.BrainrotModels)
	local showcaseIds = { "gattini", "antennini", "volanti", "stellina", "spadino", "tralalero" }
	for i, id in ipairs(showcaseIds) do
		local def = BrainrotDefs.GetById(id) or BrainrotDefs[i]
		local x = (i - 3.5) * 5.5
		local ped = Util.makePart("Showcase_" .. def.Id, Vector3.new(4, 1, 4), Vector3.new(x, 1.5, 55), Color3.fromRGB(70, 70, 80), Enum.Material.Slate, folder)
		local m = BrainrotModels.build(def, false)
		m.Parent = folder
		m:PivotTo(CFrame.new(ped.Position + Vector3.new(0, 0.5 + Util.footOf(def), 0)) * CFrame.Angles(0, Util.PI, 0))
		Util.makeLabel(m.PrimaryPart, def.Name .. "\n" .. def.Rarity, UDim2.fromOffset(100, 32), Vector3.new(0, 5, 0), 25, Util.rarityColor(def.Rarity))
	end

	if Config.StudioFreeCoinsPad then
		local coinPad = Util.makePart("FreeCoins", Vector3.new(6, 1.5, 6), Vector3.new(0, 1.25, 48), Util.GOLD, Enum.Material.Neon, folder)
		Util.makeLabel(coinPad, "STUDIO\n+500 coins", UDim2.fromOffset(100, 32), Vector3.new(0, 3, 0), 30)
		local freeCoins = Instance.new("ProximityPrompt")
		freeCoins.ObjectText = "Studio Coins"
		freeCoins.ActionText = "Claim +500"
		freeCoins.KeyboardKeyCode = Enum.KeyCode.E
		freeCoins.HoldDuration = 0
		freeCoins.MaxActivationDistance = 12
		freeCoins.Parent = coinPad
		freeCoins.Triggered:Connect(function(player)
			if not Config.IsStudio then return end
			if not RateLimit.allow(player, "freecoins", 1) then return end
			local coins = Util.getStat(player, "Coins")
			if coins then
				coins.Value += 500
				Util.notify(player, "Studio: +500 coins")
			end
		end)
	end
end

function Shop.buildSuperStand(map)
	local stand = Util.makePart("SuperUpgradeStand", Vector3.new(10, 5, 3), Vector3.new(0, 2.5, 60), Util.GOLD, Enum.Material.Neon, map)
	Util.makeLabel(stand, ("Super Upgrade\nR$ %d"):format(Config.SuperUpgradePriceRobux), UDim2.fromOffset(110, 32), Vector3.new(0, 4, 0), 30)

	local superPrompt = Instance.new("ProximityPrompt")
	superPrompt.ObjectText = "Super Upgrade Brainrot"
	superPrompt.ActionText = ("Buy for %d Robux"):format(Config.SuperUpgradePriceRobux)
	superPrompt.KeyboardKeyCode = Enum.KeyCode.E
	superPrompt.HoldDuration = 0
	superPrompt.MaxActivationDistance = 12
	superPrompt.Parent = stand

	superPrompt.Triggered:Connect(function(player)
		if not RateLimit.allow(player, "super", 1) then return end
		local base = Bases.baseOf[player]
		local hasOne = false
		if base then
			for i = 1, #base.Pedestals do
				if base.Slots[i] and not base.Slots[i].Super then hasOne = true end
			end
		end
		if not hasOne then
			Util.notify(player, "Place a brainrot in your base first - upgrade applies to your best one!")
			return
		end

		if Config.SuperUpgradeProductId == 0 then
			if Config.StudioFreeSuperUpgrade and Config.IsStudio then
				if Bases.upgradeBest(player) then
					Util.notify(player, ("Super Upgrade! x%d income (Studio test)"):format(Config.SuperMultiplier))
				end
			else
				Util.notify(player, "Robux shop not configured yet. Set SuperUpgradeProductId in Config.")
			end
			return
		end

		MarketplaceService:PromptProductPurchase(player, Config.SuperUpgradeProductId)
	end)

	local okStore, receipts = pcall(function()
		return DataStoreService:GetDataStore(Config.ReceiptStoreName)
	end)
	if not okStore then
		warn("[Shop] Receipt store unavailable: " .. tostring(receipts))
		receipts = {
			GetAsync = function() error("unavailable") end,
			SetAsync = function() error("unavailable") end,
		}
	end

	MarketplaceService.ProcessReceipt = function(info)
		if info.ProductId ~= Config.SuperUpgradeProductId or Config.SuperUpgradeProductId == 0 then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local player = Players:GetPlayerByUserId(info.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local key = info.PlayerId .. "_" .. info.PurchaseId
		local ok, already = pcall(function() return receipts:GetAsync(key) end)
		if ok and already then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		if not ok and not RunService:IsStudio() then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if not Bases.upgradeBest(player) then
			Util.notify(player, "No brainrot to upgrade yet. We'll retry when you have one.")
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		pcall(function() receipts:SetAsync(key, true) end)
		Util.notify(player, ("Super Upgrade! Your best brainrot now earns x%d!"):format(Config.SuperMultiplier))
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

function Shop.buildDailyPad(map)
	local pad = Util.makePart("DailyBonus", Vector3.new(6, 1.5, 6), Vector3.new(12, 1.25, 48), Color3.fromRGB(80, 200, 120), Enum.Material.Neon, map)
	Util.makeLabel(pad, "Daily Bonus\nE = claim", UDim2.fromOffset(100, 32), Vector3.new(0, 3, 0), 30)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Daily Bonus"
	prompt.ActionText = ("Claim +%d coins"):format(Config.DailyBonusCoins)
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.Parent = pad
	prompt.Triggered:Connect(function(player)
		local Progress = require(script.Parent.Progress)
		Progress.claimDaily(player)
	end)
end

function Shop.buildRebirthPad(map)
	local pad = Util.makePart("RebirthPad", Vector3.new(6, 1.5, 6), Vector3.new(-12, 1.25, 48), Color3.fromRGB(200, 80, 220), Enum.Material.Neon, map)
	Util.makeLabel(pad, "REBIRTH\nE = reset+", UDim2.fromOffset(100, 32), Vector3.new(0, 3, 0), 30)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Rebirth"
	prompt.ActionText = "Rebirth for income bonus"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 12
	prompt.Parent = pad
	prompt.Triggered:Connect(function(player)
		local Progress = require(script.Parent.Progress)
		Progress.tryRebirth(player)
	end)
end

return Shop
