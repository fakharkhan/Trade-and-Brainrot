local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)
local Util = require(script.Parent.Util)
local BrainrotModels = require(script.Parent.BrainrotModels)
local Carry = require(script.Parent.Carry)
local RateLimit = require(script.Parent.RateLimit)

local Bases = {
	list = {},
	baseOf = {},
	stealCooldown = {},
	stealProtectUntil = {}, -- [player] = clock
	map = nil,
	onChanged = nil, -- optional callback(player) after slot change
}

local function incomeOf(slot, player)
	local data = nil
	local ok, DataService = pcall(function() return require(script.Parent.DataService) end)
	if ok and DataService then
		data = DataService.get(player)
	end
	return Util.incomeOf(slot, data and data.Rebirths or 0, data and data.Level or 1)
end

function Bases.slotText(slot, player)
	if not slot then return "" end
	local name = slot.Super and ("SUPER " .. slot.Def.Name) or slot.Def.Name
	return ("%s\n+%d/s"):format(name, incomeOf(slot, player))
end

function Bases.updateSign(base)
	local text = base.Owner and (base.Owner.DisplayName .. "'s Base") or ("Base " .. base.Index .. " (free)")
	for _, label in ipairs(base.SignLabels or {}) do
		label.Text = text
		label.TextColor3 = base.Owner and Color3.fromRGB(255, 220, 90) or Color3.fromRGB(200, 200, 200)
	end
end

-- Physical sign board standing at the open front of the base. The name is shown
-- on both faces so it can be read from the track and from inside the base.
local function buildSignBoard(base, pos, frontDir, folder)
	local half = Config.BaseSize / 2
	local wood = Color3.fromRGB(110, 75, 45)
	local frontX = pos.X + frontDir * half
	local postOffsetZ = 9

	for _, side in ipairs({ -1, 1 }) do
		Util.makePart("SignPost", Vector3.new(1, 7, 1), Vector3.new(frontX, 4.5, pos.Z + side * postOffsetZ), wood, Enum.Material.Wood, folder)
	end

	local board = Util.makePart("SignBoard", Vector3.new(0.6, 5, postOffsetZ * 2 + 2), Vector3.new(frontX, 9, pos.Z), Color3.fromRGB(45, 35, 30), Enum.Material.Wood, folder)
	base.SignLabels = {}
	for _, face in ipairs({ Enum.NormalId.Right, Enum.NormalId.Left }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0
		gui.Parent = board

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.TextColor3 = Color3.fromRGB(255, 220, 90)
		label.TextStrokeTransparency = 0.3
		label.Text = ""
		label.Parent = gui

		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 12)
		pad.PaddingBottom = UDim.new(0, 12)
		pad.PaddingLeft = UDim.new(0, 16)
		pad.PaddingRight = UDim.new(0, 16)
		pad.Parent = label

		table.insert(base.SignLabels, label)
	end
end

function Bases.countOwned(player)
	local base = Bases.baseOf[player]
	if not base then return 0 end
	local n = 0
	for i = 1, #base.Pedestals do
		if base.Slots[i] then n += 1 end
	end
	return n
end

function Bases.freeSlots(player)
	local base = Bases.baseOf[player]
	if not base then return 0 end
	return #base.Pedestals - Bases.countOwned(player)
end

function Bases.firstFreeSlot(base)
	for i = 1, #base.Pedestals do
		if not base.Slots[i] then return i end
	end
end

function Bases.totalIncome(player)
	local base = Bases.baseOf[player]
	if not base then return 0 end
	local total = 0
	for i = 1, #base.Pedestals do
		local slot = base.Slots[i]
		if slot then total += incomeOf(slot, player) end
	end
	return total
end

function Bases.refreshSlot(base, i)
	local ped = base.Pedestals[i]
	local slot = base.Slots[i]
	if ped.Model then
		ped.Model:Destroy()
		ped.Model = nil
	end
	if slot then
		local m = BrainrotModels.build(slot.Def, slot.Super)
		m.Parent = base.Folder
		m:PivotTo(CFrame.new(ped.Pad.Position + Vector3.new(0, 0.5 + Util.footOf(slot.Def), 0)) * CFrame.Angles(0, -base.FrontDir * Util.PI / 2, 0))
		ped.Model = m
		ped.Pick.ObjectText = slot.Def.Name
		BrainrotModels.playSpawnPop(m)
		BrainrotModels.startIdleBob(m)
		local color = Util.rarityColor(slot.Def.Rarity)
		ped.Label.TextColor3 = color
	end
	ped.Pick.Enabled = slot ~= nil
	ped.Place.Enabled = slot == nil
	ped.Label.Text = Bases.slotText(slot, base.Owner)
	ped.Label.Parent.Enabled = slot ~= nil
	if base.Owner then
		local stat = Util.getStat(base.Owner, "Brainrots")
		if stat then stat.Value = Bases.countOwned(base.Owner) end
		local incomeStat = Util.getStat(base.Owner, "Income")
		if incomeStat then incomeStat.Value = Bases.totalIncome(base.Owner) end
		if Bases.onChanged then
			Bases.onChanged(base.Owner)
		end
	end
end

-- Update pedestal labels and income stat without rebuilding models (used after level-ups)
function Bases.refreshLabels(player)
	local base = Bases.baseOf[player]
	if not base then return end
	for i = 1, #base.Pedestals do
		local slot = base.Slots[i]
		if slot then
			base.Pedestals[i].Label.Text = Bases.slotText(slot, player)
		end
	end
	local incomeStat = Util.getStat(player, "Income")
	if incomeStat then incomeStat.Value = Bases.totalIncome(player) end
end

function Bases.returnCarry(player)
	local c = Carry.get(player)
	if not c then return end
	local base = Bases.baseOf[player]
	local i = base and Bases.firstFreeSlot(base)
	if i then
		base.Slots[i] = c.Slot
		Bases.refreshSlot(base, i)
	end
	Carry.drop(player)
end

function Bases.pickUp(player, base, i)
	if not RateLimit.allow(player, "pick", 0.2) then return end
	local slot = base.Slots[i]
	if not slot then return end
	if Carry.isCarrying(player) then
		Util.notify(player, "You're already carrying a brainrot. Place it first!")
		return
	end
	local stealing = base.Owner ~= player
	if stealing then
		local protectUntil = Bases.stealProtectUntil[base.Owner]
		if protectUntil and os.clock() < protectUntil then
			Util.notify(player, "That base is protected after a recent steal.")
			return
		end
		local left = Config.StealCooldown - (os.clock() - (Bases.stealCooldown[player] or -999))
		if left > 0 then
			Util.notify(player, ("Steal is on cooldown (%ds)."):format(math.ceil(left)))
			return
		end
	end
	if not Carry.attach(player, slot) then return end
	base.Slots[i] = nil
	Bases.refreshSlot(base, i)
	if stealing then
		Bases.stealCooldown[player] = os.clock()
		if base.Owner then
			Bases.stealProtectUntil[base.Owner] = os.clock() + Config.StealProtectSeconds
			Util.notify(base.Owner, player.DisplayName .. " stole your " .. slot.Def.Name .. "!")
		end
		Util.notify(player, "You stole " .. slot.Def.Name .. "! Carry it to your base.")
	end
end

function Bases.place(player, base, i)
	if not RateLimit.allow(player, "place", 0.15) then return end
	if base.Owner ~= player then
		Util.notify(player, "That's not your base.")
		return
	end
	local c = Carry.get(player)
	if not c then
		Util.notify(player, "Pick up a brainrot first.")
		return
	end
	if base.Slots[i] then return end
	base.Slots[i] = c.Slot
	Carry.drop(player)
	Bases.refreshSlot(base, i)
	Util.notify(player, "Placed " .. base.Slots[i].Def.Name .. "!")
end

function Bases.sellCarried(player)
	if not RateLimit.allow(player, "sell", 0.3) then return end
	local c = Carry.get(player)
	if not c then
		Util.notify(player, "Carry a brainrot to the Trader to sell it.")
		return
	end
	local value = math.floor(c.Slot.Def.Price * (c.Slot.Super and Config.SuperMultiplier or 1) * Config.SellFraction)
	local coins = Util.getStat(player, "Coins")
	if coins then coins.Value += value end
	Util.notify(player, ("Trader bought %s for %d coins."):format(c.Slot.Def.Name, value))
	Carry.drop(player)
	if Bases.onChanged then Bases.onChanged(player) end
end

local function buildTrader(parent, origin)
	local model = Instance.new("Model")
	model.Name = "Trader"
	local skin = Color3.fromRGB(240, 200, 160)
	local coat = Color3.fromRGB(120, 50, 60)
	local pants = Color3.fromRGB(50, 50, 70)
	local hat = Color3.fromRGB(30, 30, 35)
	local BALL, BLOCK, CYL = Enum.PartType.Ball, Enum.PartType.Block, Enum.PartType.Cylinder
	local V3 = Vector3.new
	local function np(shape, size, cf, color, material)
		local p = Instance.new("Part")
		p.Shape = shape
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.Parent = model
		return p
	end
	for _, sx in ipairs({ -1, 1 }) do
		np(BLOCK, V3(0.9, 2, 0.9), origin * CFrame.new(sx * 0.55, 1, 0), pants)
		np(BLOCK, V3(0.8, 2.2, 0.8), origin * CFrame.new(sx * 1.55, 3.2, 0), coat)
		np(BALL, V3(0.9, 0.9, 0.9), origin * CFrame.new(sx * 1.55, 2.0, 0), skin)
	end
	np(BLOCK, V3(2.3, 2.4, 1.3), origin * CFrame.new(0, 3.2, 0), coat)
	local head = np(BALL, V3(1.8, 1.8, 1.8), origin * CFrame.new(0, 5.2, 0), skin)
	for _, sx in ipairs({ -1, 1 }) do
		np(BALL, V3(0.3, 0.3, 0.3), origin * CFrame.new(sx * 0.4, 5.4, -0.8), Color3.new(0.05, 0.05, 0.05))
	end
	np(BLOCK, V3(0.9, 0.25, 0.3), origin * CFrame.new(0, 4.9, -0.85), Color3.fromRGB(80, 50, 30))
	np(CYL, V3(0.25, 2.8, 2.8), origin * CFrame.new(0, 6.1, 0) * CFrame.Angles(0, 0, Util.PI / 2), hat)
	np(CYL, V3(1.5, 1.8, 1.8), origin * CFrame.new(0, 6.9, 0) * CFrame.Angles(0, 0, Util.PI / 2), hat)
	np(BALL, V3(1.4, 1.4, 1.4), origin * CFrame.new(-1.9, 1.5, -0.6), Color3.fromRGB(140, 100, 50))
	np(CYL, V3(0.2, 0.9, 0.9), origin * CFrame.new(-1.9, 2.3, -0.6) * CFrame.Angles(0, 0, Util.PI / 2), Util.GOLD, Enum.Material.Neon)
	model.Parent = parent
	Util.makeLabel(head, "Trader", UDim2.fromOffset(80, 24), Vector3.new(0, 2.5, 0), 40)
	return model
end

function Bases.buildOne(index, placeIndex, pos, map)
	local frontDir = (placeIndex == 1) and 1 or -1
	local base = { Index = index, Pos = pos, Owner = nil, Slots = {}, Pedestals = {}, FrontDir = frontDir }
	local folder = Instance.new("Folder")
	folder.Name = "Base_" .. index
	folder.Parent = map
	base.Folder = folder

	local color = (placeIndex == 1) and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(120, 180, 255)
	Util.makePart("Floor", Vector3.new(Config.BaseSize, 1, Config.BaseSize), pos + Vector3.new(0, 0.5, 0), color, nil, folder)

	local fence = Color3.fromRGB(90, 90, 100)
	local half = Config.BaseSize / 2
	Util.makePart("FenceBack", Vector3.new(1, 6, Config.BaseSize), pos + Vector3.new(-frontDir * half, 4, 0), fence, Enum.Material.Metal, folder)
	Util.makePart("FenceSideA", Vector3.new(Config.BaseSize, 6, 1), pos + Vector3.new(0, 4, half), fence, Enum.Material.Metal, folder)
	Util.makePart("FenceSideB", Vector3.new(Config.BaseSize, 6, 1), pos + Vector3.new(0, 4, -half), fence, Enum.Material.Metal, folder)

	buildSignBoard(base, pos, frontDir, folder)

	base.SpawnPos = pos + Vector3.new(frontDir * 8, 4, 8)

	local counter = Util.makePart("TradingShop", Vector3.new(3, 4, 10), pos + Vector3.new(frontDir * 9.5, 3, -13), Color3.fromRGB(150, 100, 60), Enum.Material.Wood, folder)
	Util.makeLabel(counter, "Trading Shop", UDim2.fromOffset(110, 28), Vector3.new(0, 3.5, 0), 40)
	buildTrader(folder, CFrame.new(pos + Vector3.new(frontDir * 14, 1, -13)) * CFrame.Angles(0, frontDir * Util.PI / 2, 0))

	local sell = Instance.new("ProximityPrompt")
	sell.ObjectText = "Trader"
	sell.ActionText = "Sell carried brainrot"
	sell.KeyboardKeyCode = Enum.KeyCode.E
	sell.HoldDuration = 0
	sell.MaxActivationDistance = 10
	sell.Parent = counter
	sell.Triggered:Connect(function(player) Bases.sellCarried(player) end)

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

	for col = 1, 2 do
		for row = 1, 4 do
			local lx = frontDir * (col == 1 and -8 or -16)
			local lz = (row - 2.5) * 8
			local pad = Util.makePart("Pedestal", Vector3.new(6, 1, 6), pos + Vector3.new(lx, 1.5, lz), Color3.fromRGB(60, 60, 70), Enum.Material.Slate, folder)
			local label = Util.makeLabel(pad, "", UDim2.fromOffset(120, 36), Vector3.new(0, 7, 0), 40)
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
			pick.HoldDuration = Config.PickupHold
			pick.MaxActivationDistance = 7
			pick.Enabled = false
			pick.Parent = pad

			local i = #base.Pedestals + 1
			base.Pedestals[i] = { Pad = pad, Label = label, Place = place, Pick = pick }
			place.Triggered:Connect(function(player) Bases.place(player, base, i) end)
			pick.Triggered:Connect(function(player) Bases.pickUp(player, base, i) end)
		end
	end

	Bases.updateSign(base)
	Bases.list[index] = base
	return base
end

function Bases.buildAll(map)
	Bases.map = map
	local count = 0
	for placeIndex, offset in ipairs(Config.PlaceOffsets) do
		for i = 1, Config.BasesPerPlace do
			count += 1
			Bases.buildOne(count, placeIndex, offset + Vector3.new(0, 0, (i - 2) * Config.BaseSpacing), map)
		end
	end
end

function Bases.assign(player)
	for _, base in ipairs(Bases.list) do
		if not base.Owner then
			base.Owner = player
			Bases.baseOf[player] = base
			Bases.updateSign(base)
			return base
		end
	end
	return nil
end

function Bases.release(player)
	Carry.drop(player)
	local base = Bases.baseOf[player]
	if base then
		for i = 1, #base.Pedestals do
			base.Slots[i] = nil
			Bases.refreshSlot(base, i)
		end
		base.Owner = nil
		Bases.baseOf[player] = nil
		Bases.updateSign(base)
	end
	Bases.stealCooldown[player] = nil
	Bases.stealProtectUntil[player] = nil
end

function Bases.applySavedSlots(player, savedSlots)
	local base = Bases.baseOf[player]
	if not base or typeof(savedSlots) ~= "table" then return end
	for i = 1, #base.Pedestals do
		local s = savedSlots[tostring(i)] or savedSlots[i]
		if typeof(s) == "table" and s.Id then
			local def = BrainrotDefs.GetById(s.Id)
			if def then
				base.Slots[i] = { Def = def, Super = s.Super == true }
				Bases.refreshSlot(base, i)
			end
		end
	end
end

function Bases.serializeSlots(player)
	local base = Bases.baseOf[player]
	local out = {}
	if not base then return out end
	for i = 1, #base.Pedestals do
		local slot = base.Slots[i]
		if slot then
			out[tostring(i)] = { Id = slot.Def.Id, Super = slot.Super == true }
		end
	end
	return out
end

function Bases.transferSlots(from, to, indices)
	local fromBase, toBase = Bases.baseOf[from], Bases.baseOf[to]
	if not (fromBase and toBase) then return false end
	if #indices < 1 then return false end
	if Bases.freeSlots(to) < #indices then return false end
	for _, i in ipairs(indices) do
		local slot = fromBase.Slots[i]
		if not slot then return false end
		local freeIndex = Bases.firstFreeSlot(toBase)
		if not freeIndex then return false end
		fromBase.Slots[i] = nil
		toBase.Slots[freeIndex] = slot
		Bases.refreshSlot(fromBase, i)
		Bases.refreshSlot(toBase, freeIndex)
	end
	return true
end

-- Legacy cheapest-N transfer for simple offers
function Bases.transferCheapest(from, to, n)
	local fromBase = Bases.baseOf[from]
	if not fromBase then return false end
	local owned = {}
	for i = 1, #fromBase.Pedestals do
		if fromBase.Slots[i] then table.insert(owned, i) end
	end
	table.sort(owned, function(a, b)
		return incomeOf(fromBase.Slots[a], from) < incomeOf(fromBase.Slots[b], from)
	end)
	if #owned < n then return false end
	local indices = {}
	for k = 1, n do table.insert(indices, owned[k]) end
	return Bases.transferSlots(from, to, indices)
end

function Bases.upgradeBest(player)
	local base = Bases.baseOf[player]
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
	Bases.refreshSlot(base, best)
	return true
end

function Bases.clearAllSlots(player)
	local base = Bases.baseOf[player]
	if not base then return end
	for i = 1, #base.Pedestals do
		base.Slots[i] = nil
		Bases.refreshSlot(base, i)
	end
end

function Bases.installApi()
	local api = Instance.new("BindableFunction")
	api.Name = "BaseApi"
	api.OnInvoke = function(action, a, b, c)
		if action == "Count" then return Bases.countOwned(a) end
		if action == "Free" then return Bases.freeSlots(a) end
		if action == "Transfer" then return Bases.transferCheapest(a, b, c) end
		if action == "TransferSlots" then return Bases.transferSlots(a, b, c) end
		if action == "IsCarrying" then return Carry.isCarrying(a) end
		if action == "ListSlots" then
			local base = Bases.baseOf[a]
			if not base then return {} end
			local list = {}
			for i = 1, #base.Pedestals do
				local slot = base.Slots[i]
				if slot then
					table.insert(list, { Index = i, Id = slot.Def.Id, Name = slot.Def.Name, Super = slot.Super, Income = incomeOf(slot, a) })
				end
			end
			return list
		end
	end
	api.Parent = ServerStorage
	return api
end

return Bases
