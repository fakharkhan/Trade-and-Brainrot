-- Shared game config. Studio helpers never run on a live server.
local RunService = game:GetService("RunService")

local IS_STUDIO = RunService:IsStudio()

local Config = {
	IsStudio = IS_STUDIO,

	BaseSize = 40,
	BaseSpacing = 46,
	PlaceOffsets = { Vector3.new(-120, 0, 0), Vector3.new(120, 0, 0) },
	BasesPerPlace = 3,
	PedestalsPerBase = 8,

	-- Live start coins; Studio gets a higher amount for testing
	StartCoins = IS_STUDIO and 2000 or 100,
	StudioGiveStarterBrainrot = IS_STUDIO,
	StudioFreeSuperUpgrade = IS_STUDIO,

	SpawnInterval = 10, -- seconds between brainrots on the track
	TrackSpeed = 2, -- studs per second (slow so players can catch them; 80s to cross)
	TrackHalfLength = 80,
	CarryScale = 0.3, -- size of a brainrot while held (placed ones return to full size)

	PickupHold = 0.7,
	StealCooldown = 30,
	StealProtectSeconds = 15,
	SellFraction = 0.7, -- Trader pays this share of price when you sell a brainrot

	-- Player levels: spend coins to level up for a permanent income bonus
	MaxLevel = 1000,
	LevelIncomeBonus = 0.05, -- +5% income per level above 1

	SuperMultiplier = 5,
	-- Set after creating the Developer Product in Creator Hub
	SuperUpgradeProductId = 0,
	SuperUpgradePriceRobux = 100,

	AutosaveSeconds = 60,
	DataStoreName = "TradeBrainrot_v1",
	ReceiptStoreName = "SuperUpgradeReceipts_v1",

	TradeOfferExpireSeconds = 30,
	RemoteRateLimitSeconds = 0.35,

	RebirthMinIncome = 50, -- total income/s required to rebirth
	RebirthIncomeBonus = 0.25, -- +25% income per rebirth

	RarityColors = {
		Common = Color3.fromRGB(200, 200, 200),
		Rare = Color3.fromRGB(80, 160, 255),
		Epic = Color3.fromRGB(180, 90, 255),
		Legendary = Color3.fromRGB(255, 180, 40),
		Mythic = Color3.fromRGB(255, 70, 120),
	},
}

-- Coins needed to go from `level` to `level + 1` (1 -> 2 costs 50, 999 -> 1000 costs millions)
function Config.LevelCost(level)
	return math.floor(50 * (level ^ 1.7))
end

function Config.LevelIncomeMultiplier(level)
	level = math.clamp(level or 1, 1, Config.MaxLevel)
	return 1 + (level - 1) * Config.LevelIncomeBonus
end

return Config
