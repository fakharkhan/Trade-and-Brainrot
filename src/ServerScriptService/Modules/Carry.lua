local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Util = require(script.Parent.Util)
local BrainrotModels = require(script.Parent.BrainrotModels)

local Carry = {
	_carrying = {}, -- [player] = { Slot, Model }
}

function Carry.get(player)
	return Carry._carrying[player]
end

function Carry.isCarrying(player)
	return Carry._carrying[player] ~= nil
end

function Carry.drop(player)
	local c = Carry._carrying[player]
	Carry._carrying[player] = nil
	if c and c.Model then
		c.Model:Destroy()
	end
end

function Carry.attach(player, slot)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	if Carry._carrying[player] then return false end

	local model = BrainrotModels.build(slot.Def, slot.Super)
	-- Held brainrots are shrunk so the player can see them; pedestals rebuild
	-- a fresh full-size model when the brainrot is placed.
	local scale = Config.CarryScale
	model:ScaleTo(scale)
	model.Parent = char
	-- hold it in front of the chest, slightly to the right
	model:PivotTo(hrp.CFrame * CFrame.new(1.3, 0.4, -2))

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

	Util.makeLabel(primary, slot.Def.Name, UDim2.fromOffset(100, 28), Vector3.new(0, 4.5 * scale + 0.5, 0), 40, Util.rarityColor(slot.Def.Rarity))
	Carry._carrying[player] = { Slot = slot, Model = model }
	local remotes = require(ReplicatedStorage.Shared.Remotes)
	if remotes.GameEvent then
		remotes.GameEvent:FireClient(player, "Carry", slot.Def.Name)
	end
	return true
end

function Carry.clear(player)
	Carry.drop(player)
end

return Carry
