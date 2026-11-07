-- GameSetup (Script) -> put in ServerScriptService   (REPLACES the old GameSetup)
--
--  * 6 bases (2 places x 3). Each player is auto-assigned one and spawns there.
--  * Each base has 8 pedestals AND its own Trading Shop corner with a Trader NPC.
--  * Brainrots earn coins automatically (no collecting needed).
--  * Brainrots ride the track. Press E on one to buy it, then CARRY it to your base and place it.
--  * You can also pick up your own brainrots, or steal other players' brainrots (then carry them home).
--  * Trader NPC: sell the brainrot you're carrying, or open the player-to-player trade window.
--  * "Super Upgrade Brainrot" Robux stand (needs a Developer Product ID, see CONFIG).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")

local CONFIG = {
	BaseSize = 40,
	BaseSpacing = 46,
	PlaceOffsets = { Vector3.new(-120, 0, 0), Vector3.new(120, 0, 0) }, -- the 2 places
	BasesPerPlace = 3,
	StartCoins = 2000, -- enough to buy several brainrots while testing

	SpawnInterval = 5, -- seconds between brainrots on the track
	TrackSpeed = 10, -- studs per second
	TrackHalfLength = 80,

	PickupHold = 0.7, -- seconds to hold E to pick up / steal
	StealCooldown = 30, -- seconds between steals per player
	SellFraction = 0.5, -- trader pays this share of the brainrot's price

	SuperMultiplier = 5, -- income multiplier for a Super brainrot

	-- !!! IMPORTANT !!!
	-- Create a Developer Product (Creator Hub > your experience > Monetization > Developer Products)
	-- named "Super Upgrade Brainrot", priced at 100 Robux, then paste its ID here.
	SuperUpgradeProductId = 0,
	SuperUpgradePriceRobux = 100,
}

-- Style: "doodle", "tall" (Tralalero), "leafy" (Patapim). Foot = pivot-to-ground offset.
-- To use your own models, put Models named EXACTLY like these inside ServerStorage > BrainrotModels.
local BRAINROTS = {
	{ Name = "Tung Tung Tung Sahur", Rarity = "Common", Price = 25, Income = 1, Weight = 40, Style = "doodle", Color = Color3.fromRGB(205, 160, 100), Foot = 1.9 },
	{ Name = "Tralalero Tralala", Rarity = "Rare", Price = 150, Income = 6, Weight = 35, Style = "tall", Color = Color3.fromRGB(120, 145, 155), Foot = 2.15 },
	{ Name = "Brr Brr Patapim", Rarity = "Epic", Price = 400, Income = 15, Weight = 25, Style = "leafy", Color = Color3.fromRGB(110, 170, 80), Foot = 2.8 },
}

local DEFAULT_FOOT = 1.9
local GOLD = Color3.fromRGB(255, 200, 40)
local PI = math.pi

local function footOf(def)
	return (def and def.Foot) or DEFAULT_FOOT
end

local map = Instance.new("Folder")
map.Name = "Map"
map.Parent = workspace

-- Helpers ---------------------------------------------------------------
local function makePart(name, size, position, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Anchored = true
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent or map
	return p
end

local function makeLabel(parent, text, size, offset, maxDistance)
	local gui = Instance.new("BillboardGui")
	gui.Size = size or UDim2.fromOffset(110, 32)
	gui.StudsOffset = offset or Vector3.new(0, 3, 0)
	-- Avoid AlwaysOnTop: distant labels were stacking as giant text in the middle of the screen
	gui.AlwaysOnTop = false
	gui.MaxDistance = maxDistance or 35
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Text = text
	label.Parent = gui
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = 14
	cap.MinTextSize = 8
	cap.Parent = label
	return label
end

local function getStat(player, name)
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild(name)
end

local function notify(player, message)
	local ev = ReplicatedStorage:FindFirstChild("TradeEvent")
	if ev and player and player.Parent == Players then
		ev:FireClient(player, "Message", message)
	end
end

local function incomeOf(slot)
	return slot.Def.Income * (slot.Super and CONFIG.SuperMultiplier or 1)
end

-- Brainrot graphics -------------------------------------------------------
local function newPart(model, shape, size, cf, color, material, name)
	local p = Instance.new("Part")
	p.Name = name or "Piece"
	p.Shape = shape
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanCollide = false
	p.Parent = model
	return p
end

local BALL, BLOCK, CYL = Enum.PartType.Ball, Enum.PartType.Block, Enum.PartType.Cylinder
local V3 = Vector3.new

local function addEyes(model, x, y, z, size)
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, BALL, V3(size, size, size), CFrame.new(sx * x, y, z), Color3.new(1, 1, 1), nil, "Eye")
		newPart(model, BALL, V3(size * 0.5, size * 0.5, size * 0.5), CFrame.new(sx * x, y, z - size * 0.32), Color3.new(0.05, 0.05, 0.05), nil, "Eye")
	end
end

local STYLES = {}

-- round: a fluffy ball critter with ears and an antenna
STYLES.round = function(model, c)
	local light = c:Lerp(Color3.new(1, 1, 1), 0.45)
	local dark = c:Lerp(Color3.new(0, 0, 0), 0.3)
	newPart(model, BALL, V3(3.8, 3.8, 3.8), CFrame.new(0, 0, 0), c, nil, "Body")
	newPart(model, BALL, V3(2.4, 2.4, 1.2), CFrame.new(0, -0.5, -1.3), light)
	addEyes(model, 0.7, 0.7, -1.45, 1.2)
	newPart(model, BALL, V3(0.7, 0.7, 0.7), CFrame.new(0, 0.1, -1.9), Color3.fromRGB(255, 150, 40))
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, BALL, V3(1.2, 1.2, 1.2), CFrame.new(sx * 1.3, 1.6, 0.1), dark)
	end
	newPart(model, CYL, V3(1.4, 0.2, 0.2), CFrame.new(0, 2.5, 0) * CFrame.Angles(0, 0, PI / 2), dark)
	newPart(model, BALL, V3(0.6, 0.6, 0.6), CFrame.new(0, 3.3, 0), Color3.fromRGB(255, 70, 70))
end

-- tall: Tralalero-style — horizontal capsule shark-body, one googly eye, jagged fin, 4 legs in blue sneakers
STYLES.tall = function(model, c)
	local belly = Color3.fromRGB(235, 225, 205)
	local shoe = Color3.fromRGB(40, 120, 230)
	local sole = Color3.new(1, 1, 1)
	local dark = c:Lerp(Color3.new(0, 0, 0), 0.25)

	-- horizontal sausage body (facing +Z travel in world via model pivot)
	newPart(model, BALL, V3(3.2, 3.0, 5.2), CFrame.new(0, 0.4, 0), c, nil, "Body")
	newPart(model, BALL, V3(2.6, 2.2, 4.4), CFrame.new(0, -0.35, 0.1), belly)

	-- single side googly eye (sketch silhouette)
	newPart(model, BALL, V3(1.15, 1.15, 1.15), CFrame.new(-1.35, 0.85, -1.4), Color3.new(1, 1, 1), nil, "Eye")
	newPart(model, BALL, V3(0.55, 0.55, 0.55), CFrame.new(-1.55, 0.85, -1.65), Color3.new(0.05, 0.05, 0.05), nil, "Eye")

	-- jagged rear fin / tail
	newPart(model, BLOCK, V3(0.35, 2.2, 1.4), CFrame.new(0, 1.6, 2.3) * CFrame.Angles(math.rad(-18), 0, 0), dark)
	newPart(model, BLOCK, V3(0.3, 1.4, 1.0), CFrame.new(0, 0.2, 2.9) * CFrame.Angles(math.rad(25), 0, 0), dark)
	newPart(model, BLOCK, V3(0.3, 1.1, 0.9), CFrame.new(0, -0.7, 2.55) * CFrame.Angles(math.rad(-30), 0, 0), dark)

	-- four short legs + blue sneakers
	for _, xz in ipairs({
		{ -0.85, -1.1 }, { 0.85, -1.1 },
		{ -0.85, 1.15 }, { 0.85, 1.15 },
	}) do
		newPart(model, CYL, V3(1.1, 0.85, 0.85), CFrame.new(xz[1], -1.0, xz[2]) * CFrame.Angles(0, 0, PI / 2), c)
		newPart(model, BLOCK, V3(1.15, 0.55, 1.55), CFrame.new(xz[1], -1.75, xz[2] - 0.15), shoe)
		newPart(model, BLOCK, V3(1.2, 0.18, 1.65), CFrame.new(xz[1], -2.05, xz[2] - 0.15), sole)
		newPart(model, BLOCK, V3(0.35, 0.35, 0.7), CFrame.new(xz[1] + 0.35, -1.6, xz[2] - 0.15), sole) -- swoosh hint
	end
end

-- leafy: Patapim-style — mossy green torso/head, wooden bark limbs, power stance
STYLES.leafy = function(model, c)
	local moss = c
	local bark = Color3.fromRGB(150, 105, 60)
	local barkDark = Color3.fromRGB(100, 65, 35)
	local face = Color3.fromRGB(230, 195, 150)
	local beard = Color3.fromRGB(230, 230, 220)

	-- mossy torso + head
	newPart(model, BALL, V3(3.4, 3.6, 2.8), CFrame.new(0, 0.9, 0), moss, nil, "Body")
	newPart(model, BALL, V3(3.0, 2.8, 2.8), CFrame.new(0, 3.2, 0), moss)
	newPart(model, BALL, V3(2.2, 2.0, 2.0), CFrame.new(0, 3.0, -0.55), face)
	newPart(model, BALL, V3(1.8, 1.0, 1.4), CFrame.new(0, 2.15, -0.5), beard)

	-- moss ear flaps (from the blocky sketch hat/ears)
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, BALL, V3(1.0, 1.0, 0.7), CFrame.new(sx * 1.55, 3.7, 0.1), moss)
	end

	addEyes(model, 0.55, 3.25, -1.35, 0.85)
	-- smile
	newPart(model, BLOCK, V3(0.7, 0.12, 0.1), CFrame.new(0, 2.55, -1.45), barkDark)

	-- wooden vine wrap on chest
	newPart(model, CYL, V3(0.35, 2.4, 0.35), CFrame.new(-0.4, 1.0, -1.1) * CFrame.Angles(math.rad(15), 0, math.rad(20)), bark, Enum.Material.Wood)
	newPart(model, CYL, V3(0.3, 2.0, 0.3), CFrame.new(0.5, 0.7, -1.0) * CFrame.Angles(math.rad(-10), 0, math.rad(-25)), barkDark, Enum.Material.Wood)

	-- wooden arms on hips
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, CYL, V3(2.4, 0.85, 0.85), CFrame.new(sx * 1.9, 1.1, 0) * CFrame.Angles(0, 0, math.rad(sx * 55)), bark, Enum.Material.Wood)
		newPart(model, BALL, V3(1.1, 1.1, 1.1), CFrame.new(sx * 1.5, 0.15, 0.4), bark, Enum.Material.Wood) -- fists
	end

	-- wooden legs + flat toed feet
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, CYL, V3(2.6, 1.0, 1.0), CFrame.new(sx * 0.75, -1.35, 0) * CFrame.Angles(0, 0, PI / 2), bark, Enum.Material.Wood)
		newPart(model, BLOCK, V3(1.3, 0.45, 1.9), CFrame.new(sx * 0.75, -2.55, -0.25), barkDark, Enum.Material.Wood)
		for t = -1, 1 do
			newPart(model, BLOCK, V3(0.28, 0.25, 0.55), CFrame.new(sx * 0.75 + t * 0.35, -2.55, -1.05), barkDark, Enum.Material.Wood)
		end
	end
end

-- doodle: built from the player's own hand-drawn sketch
STYLES.doodle = function(model, c)
	local dark = Color3.fromRGB(35, 30, 28)
	local shade = c:Lerp(Color3.new(0, 0, 0), 0.25)

	-- legs
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, BLOCK, V3(0.9, 1.8, 0.9), CFrame.new(sx * 0.65, -1.0, 0), c, nil, "Leg")
	end
	-- body
	newPart(model, BLOCK, V3(2.4, 2.2, 1.4), CFrame.new(0, 1.0, 0), c, nil, "Body")
	-- tall square head
	newPart(model, BLOCK, V3(2.4, 3.2, 2.0), CFrame.new(0, 3.7, 0), c)
	newPart(model, BLOCK, V3(2.2, 0.2, 1.8), CFrame.new(0, 5.4, 0), shade) -- slightly rounded top edge

	-- square eyes with eyelashes
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, BLOCK, V3(0.95, 0.95, 0.08), CFrame.new(sx * 0.6, 4.3, -1.01), dark, nil, "Eye")
		newPart(model, BLOCK, V3(0.75, 0.75, 0.08), CFrame.new(sx * 0.6, 4.3, -1.04), Color3.new(1, 1, 1), nil, "Eye")
		newPart(model, BLOCK, V3(0.3, 0.3, 0.08), CFrame.new(sx * 0.6, 4.3, -1.08), dark, nil, "Eye")
		newPart(model, BLOCK, V3(0.12, 0.4, 0.1), CFrame.new(sx * 1.0, 4.9, -1.02) * CFrame.Angles(0, 0, math.rad(-sx * 35)), dark)
	end

	-- smile
	newPart(model, BLOCK, V3(0.8, 0.14, 0.1), CFrame.new(0, 3.1, -1.02), dark)
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, BLOCK, V3(0.5, 0.14, 0.1), CFrame.new(sx * 0.6, 3.25, -1.02) * CFrame.Angles(0, 0, math.rad(sx * 30)), dark)
	end

	-- arm holding the dark club (character's right side)
	newPart(model, BLOCK, V3(0.6, 2.2, 0.6), CFrame.new(1.7, 0.7, 0) * CFrame.Angles(0, 0, math.rad(15)), shade)
	newPart(model, CYL, V3(2.6, 0.8, 0.8), CFrame.new(2.3, -0.6, -0.3) * CFrame.Angles(0, 0, PI / 2), dark, Enum.Material.Wood)
	newPart(model, BALL, V3(0.8, 0.8, 0.8), CFrame.new(2.3, 0.7, -0.3), dark, Enum.Material.Wood)

	-- cape flap on the other side
	newPart(model, BLOCK, V3(2.2, 0.15, 1.3), CFrame.new(-2.2, 1.5, 0) * CFrame.Angles(0, 0, math.rad(20)), shade)
	newPart(model, BLOCK, V3(0.9, 0.15, 0.7), CFrame.new(-3.2, 1.1, 0) * CFrame.Angles(0, 0, math.rad(20)), shade)
end

local customModels = ServerStorage:FindFirstChild("BrainrotModels")

local function buildBrainrotModel(def, super)
	local model
	local template = customModels and customModels:FindFirstChild(def.Name)
	if template then
		model = template:Clone()
		if not model.PrimaryPart then
			model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
		end
	else
		model = Instance.new("Model")
		local root = Instance.new("Part")
		root.Name = "Root"
		root.Size = V3(1, 1, 1)
		root.Transparency = 1
		root.CanCollide = false
		root.Anchored = true
		root.CFrame = CFrame.new()
		root.Parent = model
		model.PrimaryPart = root

		STYLES[def.Style or "round"](model, def.Color)

		if super then
			for _, d in ipairs(model:GetChildren()) do
				if d:IsA("BasePart") and d ~= root and d.Name ~= "Eye" then
					d.Color = GOLD
					d.Material = Enum.Material.Neon
				end
			end
		end
		if super or def.Rarity == "Epic" then
			local body = model:FindFirstChild("Body")
			if body then
				local sp = Instance.new("Sparkles")
				sp.SparkleColor = GOLD
				sp.Parent = body
			end
		end
	end
	model.Name = def.Name

	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
		end
	end
	return model
end

-- State -----------------------------------------------------------------
local bases = {}
local baseOf = {} -- [player] = base
local carrying = {} -- [player] = { Slot = slot, Model = model }
local stealCooldown = {}

-- Slots hold { Def = brainrot definition, Super = bool }
local function slotText(slot)
	if not slot then return "" end
	local name = slot.Super and ("SUPER " .. slot.Def.Name) or slot.Def.Name
	return ("%s\n+%d coins/s"):format(name, incomeOf(slot))
end

local function updateSign(base)
	base.SignLabel.Text = base.Owner and (base.Owner.DisplayName .. "'s Base") or ("Base " .. base.Index .. " (free)")
end

local function countOwned(player)
	local base = baseOf[player]
	if not base then return 0 end
	local n = 0
	for i = 1, #base.Pedestals do
		if base.Slots[i] then n += 1 end
	end
	return n
end

local function freeSlots(player)
	local base = baseOf[player]
	if not base then return 0 end
	return #base.Pedestals - countOwned(player)
end

local function firstFreeSlot(base)
	for i = 1, #base.Pedestals do
		if not base.Slots[i] then return i end
	end
end

local function refreshSlot(base, i)
	local ped = base.Pedestals[i]
	local slot = base.Slots[i]
	if ped.Model then
		ped.Model:Destroy()
		ped.Model = nil
	end
	if slot then
		local m = buildBrainrotModel(slot.Def, slot.Super)
		m.Parent = base.Folder
		m:PivotTo(CFrame.new(ped.Pad.Position + Vector3.new(0, 0.5 + footOf(slot.Def), 0)) * CFrame.Angles(0, -base.FrontDir * PI / 2, 0))
		ped.Model = m
		ped.Pick.ObjectText = slot.Def.Name
	end
	ped.Pick.Enabled = slot ~= nil
	ped.Place.Enabled = slot == nil
	ped.Label.Text = slotText(slot)
	ped.Label.Parent.Enabled = slot ~= nil -- no text at all when empty
	if base.Owner then
		local stat = getStat(base.Owner, "Brainrots")
		if stat then stat.Value = countOwned(base.Owner) end
	end
end

-- Carrying ---------------------------------------------------------------
local function dropCarry(player)
	local c = carrying[player]
	carrying[player] = nil
	if c and c.Model then c.Model:Destroy() end
end

local function attachCarry(player, slot)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end

	local model = buildBrainrotModel(slot.Def, slot.Super)
	model.Parent = char
	model:PivotTo(hrp.CFrame * CFrame.new(0, 5.5, 0))

	local primary = model.PrimaryPart
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.Massless = true
			if d ~= primary then
				local w = Instance.new("WeldConstraint")
				w.Part0 = primary
				w.Part1 = d
				w.Parent = d
			end
		end
	end
	local w = Instance.new("WeldConstraint")
	w.Part0 = hrp
	w.Part1 = primary
	w.Parent = primary

	makeLabel(primary, slot.Def.Name, UDim2.fromOffset(100, 28), Vector3.new(0, 4.5, 0), 40)
	carrying[player] = { Slot = slot, Model = model }
	return true
end

-- if a player dies/leaves while carrying, the brainrot goes into their base (if there's room)
local function returnCarry(player)
	local c = carrying[player]
	if not c then return end
	local base = baseOf[player]
	local i = base and firstFreeSlot(base)
	if i then
		base.Slots[i] = c.Slot
		refreshSlot(base, i)
	end
	dropCarry(player)
end

local function pickUpFromPedestal(player, base, i)
	local slot = base.Slots[i]
	if not slot then return end
	if carrying[player] then
		notify(player, "You're already carrying a brainrot. Place it first!")
		return
	end
	local stealing = base.Owner ~= player
	if stealing then
		local left = CONFIG.StealCooldown - (os.clock() - (stealCooldown[player] or -999))
		if left > 0 then
			notify(player, ("Steal is on cooldown (%ds)."):format(math.ceil(left)))
			return
		end
	end
	if not attachCarry(player, slot) then return end
	base.Slots[i] = nil
	refreshSlot(base, i)
	if stealing then
		stealCooldown[player] = os.clock()
		if base.Owner then notify(base.Owner, player.DisplayName .. " stole your " .. slot.Def.Name .. "!") end
		notify(player, "You stole " .. slot.Def.Name .. "! Carry it to your base.")
	end
end

local function placeOnPedestal(player, base, i)
	if base.Owner ~= player then
		notify(player, "That's not your base.")
		return
	end
	local c = carrying[player]
	if not c then
		notify(player, "Pick up a brainrot first.")
		return
	end
	if base.Slots[i] then return end
	base.Slots[i] = c.Slot
	dropCarry(player)
	refreshSlot(base, i)
end

local function sellCarried(player)
	local c = carrying[player]
	if not c then
		notify(player, "Carry a brainrot to the Trader to sell it.")
		return
	end
	local value = math.floor(c.Slot.Def.Price * (c.Slot.Super and CONFIG.SuperMultiplier or 1) * CONFIG.SellFraction)
	local coins = getStat(player, "Coins")
	if coins then coins.Value += value end
	notify(player, ("Trader bought %s for %d coins."):format(c.Slot.Def.Name, value))
	dropCarry(player)
end

-- Trader NPC (original blocky character) ---------------------------------
local function buildTrader(parent, origin)
	local model = Instance.new("Model")
	model.Name = "Trader"
	local skin = Color3.fromRGB(240, 200, 160)
	local coat = Color3.fromRGB(120, 50, 60)
	local pants = Color3.fromRGB(50, 50, 70)
	local hat = Color3.fromRGB(30, 30, 35)

	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, BLOCK, V3(0.9, 2, 0.9), origin * CFrame.new(sx * 0.55, 1, 0), pants)
		newPart(model, BLOCK, V3(0.8, 2.2, 0.8), origin * CFrame.new(sx * 1.55, 3.2, 0), coat)
		newPart(model, BALL, V3(0.9, 0.9, 0.9), origin * CFrame.new(sx * 1.55, 2.0, 0), skin)
	end
	newPart(model, BLOCK, V3(2.3, 2.4, 1.3), origin * CFrame.new(0, 3.2, 0), coat)
	local head = newPart(model, BALL, V3(1.8, 1.8, 1.8), origin * CFrame.new(0, 5.2, 0), skin)
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, BALL, V3(0.3, 0.3, 0.3), origin * CFrame.new(sx * 0.4, 5.4, -0.8), Color3.new(0.05, 0.05, 0.05))
	end
	newPart(model, BLOCK, V3(0.9, 0.25, 0.3), origin * CFrame.new(0, 4.9, -0.85), Color3.fromRGB(80, 50, 30)) -- moustache
	-- top hat
	newPart(model, CYL, V3(0.25, 2.8, 2.8), origin * CFrame.new(0, 6.1, 0) * CFrame.Angles(0, 0, PI / 2), hat)
	newPart(model, CYL, V3(1.5, 1.8, 1.8), origin * CFrame.new(0, 6.9, 0) * CFrame.Angles(0, 0, PI / 2), hat)
	-- coin bag
	newPart(model, BALL, V3(1.4, 1.4, 1.4), origin * CFrame.new(-1.9, 1.5, -0.6), Color3.fromRGB(140, 100, 50))
	newPart(model, CYL, V3(0.2, 0.9, 0.9), origin * CFrame.new(-1.9, 2.3, -0.6) * CFrame.Angles(0, 0, PI / 2), GOLD, Enum.Material.Neon)

	model.Parent = parent
	makeLabel(head, "Trader", UDim2.fromOffset(80, 24), Vector3.new(0, 2.5, 0), 40)
	return model
end

-- Bases -----------------------------------------------------------------
local function buildBase(index, placeIndex, pos)
	local frontDir = (placeIndex == 1) and 1 or -1 -- front faces the track
	local base = { Index = index, Pos = pos, Owner = nil, Slots = {}, Pedestals = {}, FrontDir = frontDir }

	local folder = Instance.new("Folder")
	folder.Name = "Base_" .. index
	folder.Parent = map
	base.Folder = folder

	local color = (placeIndex == 1) and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(120, 180, 255)
	makePart("Floor", Vector3.new(CONFIG.BaseSize, 1, CONFIG.BaseSize), pos + Vector3.new(0, 0.5, 0), color, nil, folder)

	-- fence: back + both sides, front stays open
	local fence = Color3.fromRGB(90, 90, 100)
	local half = CONFIG.BaseSize / 2
	makePart("FenceBack", Vector3.new(1, 6, CONFIG.BaseSize), pos + Vector3.new(-frontDir * half, 4, 0), fence, Enum.Material.Metal, folder)
	makePart("FenceSideA", Vector3.new(CONFIG.BaseSize, 6, 1), pos + Vector3.new(0, 4, half), fence, Enum.Material.Metal, folder)
	makePart("FenceSideB", Vector3.new(CONFIG.BaseSize, 6, 1), pos + Vector3.new(0, 4, -half), fence, Enum.Material.Metal, folder)

	-- owner sign
	local signAnchor = makePart("SignAnchor", Vector3.new(1, 1, 1), pos + Vector3.new(0, 14, 0), Color3.new(1, 1, 1), nil, folder)
	signAnchor.Transparency = 1
	signAnchor.CanCollide = false
	base.SignLabel = makeLabel(signAnchor, "", UDim2.fromOffset(140, 28), Vector3.new(0, 0, 0), 50)

	base.SpawnPos = pos + Vector3.new(frontDir * 8, 4, 8)

	-- Trading shop corner (front side of the base) + Trader NPC
	local counter = makePart("TradingShop", Vector3.new(3, 4, 10), pos + Vector3.new(frontDir * 9.5, 3, -13), Color3.fromRGB(150, 100, 60), Enum.Material.Wood, folder)
	makeLabel(counter, "Trading Shop", UDim2.fromOffset(110, 28), Vector3.new(0, 3.5, 0), 40)
	buildTrader(folder, CFrame.new(pos + Vector3.new(frontDir * 14, 1, -13)) * CFrame.Angles(0, frontDir * PI / 2, 0))

	local sell = Instance.new("ProximityPrompt")
	sell.ObjectText = "Trader"
	sell.ActionText = "Sell carried brainrot"
	sell.KeyboardKeyCode = Enum.KeyCode.E
	sell.HoldDuration = 0
	sell.MaxActivationDistance = 10
	sell.Parent = counter
	sell.Triggered:Connect(sellCarried)

	local tradeWith = Instance.new("ProximityPrompt")
	tradeWith.ObjectText = "Trader"
	tradeWith.ActionText = "Trade with players"
	tradeWith.KeyboardKeyCode = Enum.KeyCode.F
	tradeWith.HoldDuration = 0
	tradeWith.MaxActivationDistance = 10
	tradeWith.UIOffset = Vector2.new(0, 80)
	tradeWith.Parent = counter
	tradeWith.Triggered:Connect(function(player)
		local ev = ReplicatedStorage:FindFirstChild("TradeEvent")
		if ev then ev:FireClient(player, "OpenTrade") end
	end)

	-- 8 pedestals in the back half of the base (2 columns x 4 rows)
	for col = 1, 2 do
		for row = 1, 4 do
			local lx = frontDir * (col == 1 and -8 or -16)
			local lz = (row - 2.5) * 8
			local pad = makePart("Pedestal", Vector3.new(6, 1, 6), pos + Vector3.new(lx, 1.5, lz), Color3.fromRGB(60, 60, 70), Enum.Material.Slate, folder)

			local label = makeLabel(pad, "", UDim2.fromOffset(120, 36), Vector3.new(0, 7, 0), 40)
			label.Parent.Enabled = false

			local place = Instance.new("ProximityPrompt")
			place.ObjectText = "Pedestal"
			place.ActionText = "Place brainrot"
			place.KeyboardKeyCode = Enum.KeyCode.E
			place.HoldDuration = 0
			place.MaxActivationDistance = 7
			place.Parent = pad

			local pick = Instance.new("ProximityPrompt")
			pick.ActionText = "Pick up"
			pick.KeyboardKeyCode = Enum.KeyCode.E
			pick.HoldDuration = CONFIG.PickupHold
			pick.MaxActivationDistance = 7
			pick.Enabled = false
			pick.Parent = pad

			local i = #base.Pedestals + 1
			base.Pedestals[i] = { Pad = pad, Label = label, Place = place, Pick = pick }

			place.Triggered:Connect(function(player) placeOnPedestal(player, base, i) end)
			pick.Triggered:Connect(function(player) pickUpFromPedestal(player, base, i) end)
		end
	end

	updateSign(base)
	bases[index] = base
	return base
end

-- Move n of a player's cheapest brainrots to another player (used by trading)
local function transfer(from, to, n)
	local fromBase, toBase = baseOf[from], baseOf[to]
	if not (fromBase and toBase) then return false end
	if countOwned(from) < n or freeSlots(to) < n then return false end

	local owned = {}
	for i = 1, #fromBase.Pedestals do
		if fromBase.Slots[i] then table.insert(owned, i) end
	end
	table.sort(owned, function(a, b)
		return incomeOf(fromBase.Slots[a]) < incomeOf(fromBase.Slots[b])
	end)

	for k = 1, n do
		local i = owned[k]
		local slot = fromBase.Slots[i]
		local freeIndex = firstFreeSlot(toBase)
		fromBase.Slots[i] = nil
		toBase.Slots[freeIndex] = slot
		refreshSlot(fromBase, i)
		refreshSlot(toBase, freeIndex)
	end
	return true
end

-- Upgrade the player's best non-super brainrot to Super
local function upgradeBest(player)
	local base = baseOf[player]
	if not base then return false end
	local best, bestIncome
	for i = 1, #base.Pedestals do
		local slot = base.Slots[i]
		if slot and not slot.Super and (not bestIncome or slot.Def.Income > bestIncome) then
			best, bestIncome = i, slot.Def.Income
		end
	end
	if not best then return false end
	base.Slots[best].Super = true
	refreshSlot(base, best)
	return true
end

-- API for the trading script
local api = Instance.new("BindableFunction")
api.Name = "BaseApi"
api.OnInvoke = function(action, a, b, c)
	if action == "Count" then return countOwned(a) end
	if action == "Free" then return freeSlots(a) end
	if action == "Transfer" then return transfer(a, b, c) end
end
api.Parent = ServerStorage

-- World -----------------------------------------------------------------
makePart("Ground", Vector3.new(400, 1, 220), Vector3.new(0, -0.5, 0), Color3.fromRGB(90, 140, 80), Enum.Material.Grass)

local spawn = Instance.new("SpawnLocation")
spawn.Position = Vector3.new(0, 1, 75)
spawn.Size = Vector3.new(12, 1, 12)
spawn.Anchored = true
spawn.Neutral = true
spawn.Parent = map

local count = 0
for placeIndex, offset in ipairs(CONFIG.PlaceOffsets) do
	for i = 1, CONFIG.BasesPerPlace do
		count += 1
		buildBase(count, placeIndex, offset + Vector3.new(0, 0, (i - 2) * CONFIG.BaseSpacing))
	end
end

-- Wall
local wallColor = Color3.fromRGB(110, 110, 120)
local H, T = 20, 2
local halfX, halfZ = 190, 110
makePart("Wall_N", Vector3.new(halfX * 2, H, T), Vector3.new(0, H / 2, -halfZ), wallColor, Enum.Material.Concrete)
makePart("Wall_S", Vector3.new(halfX * 2, H, T), Vector3.new(0, H / 2, halfZ), wallColor, Enum.Material.Concrete)
makePart("Wall_W", Vector3.new(T, H, halfZ * 2), Vector3.new(-halfX, H / 2, 0), wallColor, Enum.Material.Concrete)
makePart("Wall_E", Vector3.new(T, H, halfZ * 2), Vector3.new(halfX, H / 2, 0), wallColor, Enum.Material.Concrete)

-- Track
local L = CONFIG.TrackHalfLength
makePart("Track", Vector3.new(L * 2, 0.4, 8), Vector3.new(0, 0.2, 0), Color3.fromRGB(40, 40, 45), Enum.Material.Metal)

-- Brainrots on the track ------------------------------------------------
local function pickBrainrot()
	local total = 0
	for _, d in ipairs(BRAINROTS) do total += d.Weight end
	local r = math.random() * total
	for _, d in ipairs(BRAINROTS) do
		r -= d.Weight
		if r <= 0 then return d end
	end
	return BRAINROTS[1]
end

local function spawnRunner()
	local def = pickBrainrot()
	local model = buildBrainrotModel(def, false)
	model.Parent = map
	local face = CFrame.Angles(0, -PI / 2, 0) -- face the direction of travel (+X)
	local trackY = 0.4 + footOf(def)
	model:PivotTo(CFrame.new(-L, trackY, 0) * face)

	local root = model.PrimaryPart
	makeLabel(root, ("%s\n%d coins | +%d/s"):format(def.Name, def.Price, def.Income), UDim2.fromOffset(120, 36), Vector3.new(0, 5, 0), 28)

	local buy = Instance.new("ProximityPrompt")
	buy.ObjectText = def.Name
	buy.ActionText = ("Buy & carry (%d coins)"):format(def.Price)
	buy.KeyboardKeyCode = Enum.KeyCode.E
	buy.HoldDuration = 0
	buy.MaxActivationDistance = 10
	buy.Parent = root

	local sold = false
	buy.Triggered:Connect(function(player)
		if sold then return end
		local coins = getStat(player, "Coins")
		if not coins then return end
		if not baseOf[player] then
			notify(player, "You don't have a base.")
			return
		end
		if carrying[player] then
			notify(player, "You're already carrying a brainrot. Place it in your base first!")
			return
		end
		if coins.Value < def.Price then
			notify(player, "Not enough coins.")
			return
		end
		if not attachCarry(player, { Def = def, Super = false }) then return end
		sold = true
		coins.Value -= def.Price
		notify(player, "Bought " .. def.Name .. "! Carry it to a pedestal in your base.")
		model:Destroy()
	end)

	task.spawn(function()
		local duration = (L * 2) / CONFIG.TrackSpeed
		local t = 0
		while model.Parent and t < duration do
			t += RunService.Heartbeat:Wait()
			if model.Parent then
				model:PivotTo(CFrame.new(-L + (L * 2) * math.min(t / duration, 1), trackY, 0) * face)
			end
		end
		if model.Parent then model:Destroy() end
	end)
end

-- Showcase near spawn so the new Tralalero / Patapim models are visible immediately
local function buildShowcase()
	local folder = Instance.new("Folder")
	folder.Name = "BrainrotShowcase"
	folder.Parent = map

	local platform = makePart("ShowcasePad", Vector3.new(28, 1, 10), Vector3.new(0, 0.5, 55), Color3.fromRGB(45, 45, 55), Enum.Material.Slate, folder)
	makeLabel(platform, "Showcase", UDim2.fromOffset(100, 24), Vector3.new(0, 5, 0), 30)

	for i, def in ipairs(BRAINROTS) do
		local x = (i - 2) * 8
		local ped = makePart("Showcase_" .. def.Name, Vector3.new(5, 1, 5), Vector3.new(x, 1.5, 55), Color3.fromRGB(70, 70, 80), Enum.Material.Slate, folder)
		local m = buildBrainrotModel(def, false)
		m.Parent = folder
		m:PivotTo(CFrame.new(ped.Position + Vector3.new(0, 0.5 + footOf(def), 0)) * CFrame.Angles(0, PI, 0))
		makeLabel(m.PrimaryPart, def.Name .. "\n" .. def.Rarity, UDim2.fromOffset(100, 32), Vector3.new(0, 5, 0), 25)
	end

	-- Free coins pad for testing when you're broke
	local coinPad = makePart("FreeCoins", Vector3.new(6, 1.5, 6), Vector3.new(0, 1.25, 48), GOLD, Enum.Material.Neon, folder)
	makeLabel(coinPad, "FREE COINS\nE = +500", UDim2.fromOffset(100, 32), Vector3.new(0, 3, 0), 30)
	local freeCoins = Instance.new("ProximityPrompt")
	freeCoins.ObjectText = "Free Coins"
	freeCoins.ActionText = "Claim +500 coins"
	freeCoins.KeyboardKeyCode = Enum.KeyCode.E
	freeCoins.HoldDuration = 0
	freeCoins.MaxActivationDistance = 12
	freeCoins.Parent = coinPad
	freeCoins.Triggered:Connect(function(player)
		local coins = getStat(player, "Coins")
		if coins then
			coins.Value += 500
			notify(player, "Claimed +500 coins!")
		end
	end)
end
buildShowcase()

task.spawn(function()
	while true do
		spawnRunner()
		task.wait(CONFIG.SpawnInterval)
	end
end)

-- Income: coins are added automatically every second (nothing to collect)
task.spawn(function()
	while true do
		task.wait(1)
		for _, base in ipairs(bases) do
			local owner = base.Owner
			if owner then
				local total = 0
				for i = 1, #base.Pedestals do
					local slot = base.Slots[i]
					if slot then total += incomeOf(slot) end
				end
				local coins = getStat(owner, "Coins")
				if coins and total > 0 then coins.Value += total end
			end
		end
	end
end)

-- Robux stand: Super Upgrade Brainrot -------------------------------------
local stand = makePart("SuperUpgradeStand", Vector3.new(10, 5, 3), Vector3.new(0, 2.5, 60), GOLD, Enum.Material.Neon)
makeLabel(stand, ("Super Upgrade\nR$ %d"):format(CONFIG.SuperUpgradePriceRobux), UDim2.fromOffset(110, 32), Vector3.new(0, 4, 0), 30)

local superPrompt = Instance.new("ProximityPrompt")
superPrompt.ObjectText = "Super Upgrade Brainrot"
superPrompt.ActionText = ("Buy for %d Robux"):format(CONFIG.SuperUpgradePriceRobux)
superPrompt.KeyboardKeyCode = Enum.KeyCode.E
superPrompt.HoldDuration = 0
superPrompt.MaxActivationDistance = 12
superPrompt.Parent = stand

superPrompt.Triggered:Connect(function(player)
	local base = baseOf[player]
	local hasOne = false
	if base then
		for i = 1, #base.Pedestals do
			if base.Slots[i] and not base.Slots[i].Super then hasOne = true end
		end
	end
	if not hasOne then
		notify(player, "Place a brainrot in your base first - the upgrade applies to your best one!")
		return
	end

	-- No Developer Product yet: grant free in Studio / local play so testing works.
	-- For a live game, set CONFIG.SuperUpgradeProductId to your Creator Hub product ID.
	if CONFIG.SuperUpgradeProductId == 0 then
		if upgradeBest(player) then
			notify(player, ("Super Upgrade! Your best brainrot now earns x%d! (Studio free test)"):format(CONFIG.SuperMultiplier))
		else
			notify(player, "No brainrot to upgrade yet.")
		end
		return
	end

	MarketplaceService:PromptProductPurchase(player, CONFIG.SuperUpgradeProductId)
end)

-- GetDataStore throws on an unpublished place; never let that stop the rest of the script
local okStore, receipts = pcall(function()
	return DataStoreService:GetDataStore("SuperUpgradeReceipts")
end)
if not okStore then
	warn("[GameSetup] DataStore unavailable (publish the place to enable receipts): " .. tostring(receipts))
	receipts = {
		GetAsync = function() error("DataStore unavailable") end,
		SetAsync = function() error("DataStore unavailable") end,
	}
end

MarketplaceService.ProcessReceipt = function(info)
	if info.ProductId ~= CONFIG.SuperUpgradeProductId then
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
	-- if the DataStore is unavailable, only continue while testing in Studio
	if not ok and not RunService:IsStudio() then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if not upgradeBest(player) then
		notify(player, "No brainrot to upgrade yet. We'll retry when you have one.")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	pcall(function() receipts:SetAsync(key, true) end)
	notify(player, ("Super Upgrade! Your best brainrot now earns x%d!"):format(CONFIG.SuperMultiplier))
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Players -----------------------------------------------------------------
local function teleportToBase(player, char)
	local base = baseOf[player]
	if not base then return end
	char:WaitForChild("HumanoidRootPart", 5)
	task.wait()
	char:PivotTo(CFrame.new(base.SpawnPos))
end

local function setupPlayer(player)
	-- Studio can fire PlayerAdded and also already have the player in GetPlayers()
	if player:FindFirstChild("leaderstats") then
		return
	end

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = CONFIG.StartCoins
	coins.Parent = stats

	local brainrots = Instance.new("IntValue")
	brainrots.Name = "Brainrots"
	brainrots.Value = 0
	brainrots.Parent = stats

	stats.Parent = player

	-- assign the first free base + free starter brainrot so Super Upgrade can be tested immediately
	for _, base in ipairs(bases) do
		if not base.Owner then
			base.Owner = player
			baseOf[player] = base
			updateSign(base)
			base.Slots[1] = { Def = BRAINROTS[1], Super = false }
			refreshSlot(base, 1)
			break
		end
	end
	if not baseOf[player] then
		notify(player, "Server is full - no free base!")
	else
		notify(player, ("Welcome! %d coins + a free Tung Tung in your base."):format(CONFIG.StartCoins))
	end

	player.CharacterAdded:Connect(function(char)
		teleportToBase(player, char)
	end)
	player.CharacterRemoving:Connect(function()
		returnCarry(player)
	end)
	if player.Character then
		task.spawn(teleportToBase, player, player.Character)
	end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, p)
end

Players.PlayerRemoving:Connect(function(player)
	dropCarry(player)
	local base = baseOf[player]
	if base then
		for i = 1, #base.Pedestals do
			base.Slots[i] = nil
		end
		base.Owner = nil
		baseOf[player] = nil
		for i = 1, #base.Pedestals do
			refreshSlot(base, i)
		end
		updateSign(base)
	end
	stealCooldown[player] = nil
end)

print("World built: 6 bases with trading shops + traders, track, wall, brainrots, Robux stand.")
