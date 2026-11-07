local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)
local Util = require(script.Parent.Util)
local BrainrotModels = require(script.Parent.BrainrotModels)
local Carry = require(script.Parent.Carry)
local Bases = require(script.Parent.Bases)
local DataService = require(script.Parent.DataService)
local RateLimit = require(script.Parent.RateLimit)

local Track = {}

function Track.start(map)
	local L = Config.TrackHalfLength
	Util.makePart("Track", Vector3.new(L * 2, 0.4, 8), Vector3.new(0, 0.2, 0), Color3.fromRGB(40, 40, 45), Enum.Material.Metal, map)

	local function spawnRunner()
		local luck = 0
		-- average luck of online players slightly affects spawn (simple)
		local DataService = require(script.Parent.DataService)
		local n = 0
		for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
			local d = DataService.get(plr)
			if d then
				luck += (d.LuckLevel or 0)
				n += 1
			end
		end
		if n > 0 then luck = luck / n * 0.15 end

		local def = BrainrotDefs.PickWeighted(luck)
		local model = BrainrotModels.build(def, false)
		model.Parent = map
		local face = CFrame.Angles(0, -Util.PI / 2, 0)
		local trackY = 0.4 + Util.footOf(def)
		model:PivotTo(CFrame.new(-L, trackY, 0) * face)
		BrainrotModels.startIdleBob(model)

		local root = model.PrimaryPart
		local color = Util.rarityColor(def.Rarity)
		Util.makeLabel(root, ("%s\n%d | +%d/s"):format(def.Name, def.Price, def.Income), UDim2.fromOffset(120, 36), Vector3.new(0, 5, 0), 28, color)

		local buy = Instance.new("ProximityPrompt")
		buy.ObjectText = def.Name
		buy.ActionText = ("Buy & carry (%d)"):format(def.Price)
		buy.KeyboardKeyCode = Enum.KeyCode.E
		buy.HoldDuration = 0
		buy.MaxActivationDistance = 10
		buy.Parent = root

		local sold = false
		buy.Triggered:Connect(function(player)
			if sold then return end
			if not RateLimit.allow(player, "buy", 0.4) then return end
			local coins = Util.getStat(player, "Coins")
			if not coins then return end
			if not Bases.baseOf[player] then
				Util.notify(player, "You don't have a base.")
				return
			end
			if Carry.isCarrying(player) then
				Util.notify(player, "You're already carrying a brainrot.")
				return
			end
			if coins.Value < def.Price then
				Util.notify(player, "Not enough coins.")
				return
			end
			if not Carry.attach(player, { Def = def, Super = false }) then return end
			sold = true
			coins.Value -= def.Price
			local data = DataService.get(player)
			if data then data.Coins = coins.Value end
			Util.notify(player, "Bought " .. def.Name .. "! Carry it to a pedestal.")
			model:Destroy()
		end)

		task.spawn(function()
			local duration = (L * 2) / Config.TrackSpeed
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

	task.spawn(function()
		while true do
			Util.safe("spawnRunner", spawnRunner)
			task.wait(Config.SpawnInterval)
		end
	end)
end

return Track
