local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local Util = {}
Util.GOLD = Color3.fromRGB(255, 200, 40)
Util.PI = math.pi
Util.DEFAULT_FOOT = 1.9

function Util.safe(label, fn)
	local ok, err = pcall(fn)
	if not ok then
		warn("[TradeBrainrot] " .. tostring(label) .. ": " .. tostring(err))
	end
	return ok, err
end

function Util.footOf(def)
	return (def and def.Foot) or Util.DEFAULT_FOOT
end

function Util.makePart(name, size, position, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Anchored = true
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function Util.makeLabel(parent, text, size, offset, maxDistance, textColor)
	local gui = Instance.new("BillboardGui")
	gui.Size = size or UDim2.fromOffset(110, 32)
	gui.StudsOffset = offset or Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = maxDistance or 35
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = textColor or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Text = text
	label.Parent = gui
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = 14
	cap.MinTextSize = 8
	cap.Parent = label
	return label
end

function Util.getStat(player, name)
	local stats = player and player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild(name)
end

function Util.notify(player, message)
	local ev = ReplicatedStorage:FindFirstChild("TradeEvent")
	if ev and player and player.Parent == Players then
		ev:FireClient(player, "Message", message)
	end
end

function Util.incomeOf(slot, rebirths)
	if not slot or not slot.Def then return 0 end
	local mult = (slot.Super and Config.SuperMultiplier or 1)
	local rebirthMult = 1 + (rebirths or 0) * Config.RebirthIncomeBonus
	return math.floor(slot.Def.Income * mult * rebirthMult)
end

function Util.rarityColor(rarity)
	return Config.RarityColors[rarity] or Color3.new(1, 1, 1)
end

return Util
