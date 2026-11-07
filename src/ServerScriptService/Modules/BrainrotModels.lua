local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Util = require(script.Parent.Util)

local BALL, BLOCK, CYL = Enum.PartType.Ball, Enum.PartType.Block, Enum.PartType.Cylinder
local V3 = Vector3.new
local PI = Util.PI
local GOLD = Util.GOLD

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

local function addEyes(model, x, y, z, size)
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, BALL, V3(size, size, size), CFrame.new(sx * x, y, z), Color3.new(1, 1, 1), nil, "Eye")
		newPart(model, BALL, V3(size * 0.5, size * 0.5, size * 0.5), CFrame.new(sx * x, y, z - size * 0.32), Color3.new(0.05, 0.05, 0.05), nil, "Eye")
	end
end

local STYLES = {}

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

STYLES.tall = function(model, c)
	local belly = Color3.fromRGB(235, 225, 205)
	local shoe = Color3.fromRGB(40, 120, 230)
	local sole = Color3.new(1, 1, 1)
	local dark = c:Lerp(Color3.new(0, 0, 0), 0.25)
	newPart(model, BALL, V3(3.2, 3.0, 5.2), CFrame.new(0, 0.4, 0), c, nil, "Body")
	newPart(model, BALL, V3(2.6, 2.2, 4.4), CFrame.new(0, -0.35, 0.1), belly)
	newPart(model, BALL, V3(1.15, 1.15, 1.15), CFrame.new(-1.35, 0.85, -1.4), Color3.new(1, 1, 1), nil, "Eye")
	newPart(model, BALL, V3(0.55, 0.55, 0.55), CFrame.new(-1.55, 0.85, -1.65), Color3.new(0.05, 0.05, 0.05), nil, "Eye")
	newPart(model, BLOCK, V3(0.35, 2.2, 1.4), CFrame.new(0, 1.6, 2.3) * CFrame.Angles(math.rad(-18), 0, 0), dark)
	newPart(model, BLOCK, V3(0.3, 1.4, 1.0), CFrame.new(0, 0.2, 2.9) * CFrame.Angles(math.rad(25), 0, 0), dark)
	newPart(model, BLOCK, V3(0.3, 1.1, 0.9), CFrame.new(0, -0.7, 2.55) * CFrame.Angles(math.rad(-30), 0, 0), dark)
	for _, xz in ipairs({ { -0.85, -1.1 }, { 0.85, -1.1 }, { -0.85, 1.15 }, { 0.85, 1.15 } }) do
		newPart(model, CYL, V3(1.1, 0.85, 0.85), CFrame.new(xz[1], -1.0, xz[2]) * CFrame.Angles(0, 0, PI / 2), c)
		newPart(model, BLOCK, V3(1.15, 0.55, 1.55), CFrame.new(xz[1], -1.75, xz[2] - 0.15), shoe)
		newPart(model, BLOCK, V3(1.2, 0.18, 1.65), CFrame.new(xz[1], -2.05, xz[2] - 0.15), sole)
		newPart(model, BLOCK, V3(0.35, 0.35, 0.7), CFrame.new(xz[1] + 0.35, -1.6, xz[2] - 0.15), sole)
	end
end

STYLES.leafy = function(model, c)
	local bark = Color3.fromRGB(150, 105, 60)
	local barkDark = Color3.fromRGB(100, 65, 35)
	local face = Color3.fromRGB(230, 195, 150)
	local beard = Color3.fromRGB(230, 230, 220)
	newPart(model, BALL, V3(3.4, 3.6, 2.8), CFrame.new(0, 0.9, 0), c, nil, "Body")
	newPart(model, BALL, V3(3.0, 2.8, 2.8), CFrame.new(0, 3.2, 0), c)
	newPart(model, BALL, V3(2.2, 2.0, 2.0), CFrame.new(0, 3.0, -0.55), face)
	newPart(model, BALL, V3(1.8, 1.0, 1.4), CFrame.new(0, 2.15, -0.5), beard)
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, BALL, V3(1.0, 1.0, 0.7), CFrame.new(sx * 1.55, 3.7, 0.1), c)
	end
	addEyes(model, 0.55, 3.25, -1.35, 0.85)
	newPart(model, BLOCK, V3(0.7, 0.12, 0.1), CFrame.new(0, 2.55, -1.45), barkDark)
	newPart(model, CYL, V3(0.35, 2.4, 0.35), CFrame.new(-0.4, 1.0, -1.1) * CFrame.Angles(math.rad(15), 0, math.rad(20)), bark, Enum.Material.Wood)
	newPart(model, CYL, V3(0.3, 2.0, 0.3), CFrame.new(0.5, 0.7, -1.0) * CFrame.Angles(math.rad(-10), 0, math.rad(-25)), barkDark, Enum.Material.Wood)
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, CYL, V3(2.4, 0.85, 0.85), CFrame.new(sx * 1.9, 1.1, 0) * CFrame.Angles(0, 0, math.rad(sx * 55)), bark, Enum.Material.Wood)
		newPart(model, BALL, V3(1.1, 1.1, 1.1), CFrame.new(sx * 1.5, 0.15, 0.4), bark, Enum.Material.Wood)
		newPart(model, CYL, V3(2.6, 1.0, 1.0), CFrame.new(sx * 0.75, -1.35, 0) * CFrame.Angles(0, 0, PI / 2), bark, Enum.Material.Wood)
		newPart(model, BLOCK, V3(1.3, 0.45, 1.9), CFrame.new(sx * 0.75, -2.55, -0.25), barkDark, Enum.Material.Wood)
		for t = -1, 1 do
			newPart(model, BLOCK, V3(0.28, 0.25, 0.55), CFrame.new(sx * 0.75 + t * 0.35, -2.55, -1.05), barkDark, Enum.Material.Wood)
		end
	end
end

STYLES.doodle = function(model, c)
	local dark = Color3.fromRGB(35, 30, 28)
	local shade = c:Lerp(Color3.new(0, 0, 0), 0.25)
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, BLOCK, V3(0.9, 1.8, 0.9), CFrame.new(sx * 0.65, -1.0, 0), c, nil, "Leg")
	end
	newPart(model, BLOCK, V3(2.4, 2.2, 1.4), CFrame.new(0, 1.0, 0), c, nil, "Body")
	newPart(model, BLOCK, V3(2.4, 3.2, 2.0), CFrame.new(0, 3.7, 0), c)
	newPart(model, BLOCK, V3(2.2, 0.2, 1.8), CFrame.new(0, 5.4, 0), shade)
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, BLOCK, V3(0.95, 0.95, 0.08), CFrame.new(sx * 0.6, 4.3, -1.01), dark, nil, "Eye")
		newPart(model, BLOCK, V3(0.75, 0.75, 0.08), CFrame.new(sx * 0.6, 4.3, -1.04), Color3.new(1, 1, 1), nil, "Eye")
		newPart(model, BLOCK, V3(0.3, 0.3, 0.08), CFrame.new(sx * 0.6, 4.3, -1.08), dark, nil, "Eye")
		newPart(model, BLOCK, V3(0.12, 0.4, 0.1), CFrame.new(sx * 1.0, 4.9, -1.02) * CFrame.Angles(0, 0, math.rad(-sx * 35)), dark)
	end
	newPart(model, BLOCK, V3(0.8, 0.14, 0.1), CFrame.new(0, 3.1, -1.02), dark)
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, BLOCK, V3(0.5, 0.14, 0.1), CFrame.new(sx * 0.6, 3.25, -1.02) * CFrame.Angles(0, 0, math.rad(sx * 30)), dark)
	end
	newPart(model, BLOCK, V3(0.6, 2.2, 0.6), CFrame.new(1.7, 0.7, 0) * CFrame.Angles(0, 0, math.rad(15)), shade)
	newPart(model, CYL, V3(2.6, 0.8, 0.8), CFrame.new(2.3, -0.6, -0.3) * CFrame.Angles(0, 0, PI / 2), dark, Enum.Material.Wood)
	newPart(model, BALL, V3(0.8, 0.8, 0.8), CFrame.new(2.3, 0.7, -0.3), dark, Enum.Material.Wood)
	newPart(model, BLOCK, V3(2.2, 0.15, 1.3), CFrame.new(-2.2, 1.5, 0) * CFrame.Angles(0, 0, math.rad(20)), shade)
	newPart(model, BLOCK, V3(0.9, 0.15, 0.7), CFrame.new(-3.2, 1.1, 0) * CFrame.Angles(0, 0, math.rad(20)), shade)
end

-- starblast: capsule body, beak head, exploding star hair, two thick shoe legs
STYLES.starblast = function(model, c)
	local star = Color3.fromRGB(255, 200, 40)
	local beak = Color3.fromRGB(40, 40, 45)
	local shoe = Color3.fromRGB(30, 30, 35)
	newPart(model, BALL, V3(4.2, 2.6, 2.6), CFrame.new(0.3, 0.4, 0), c, nil, "Body")
	newPart(model, BALL, V3(1.8, 1.8, 1.8), CFrame.new(-1.8, 0.9, 0), c)
	newPart(model, BLOCK, V3(0.9, 0.7, 0.5), CFrame.new(-2.7, 0.55, -0.2) * CFrame.Angles(math.rad(20), 0, math.rad(-15)), beak)
	newPart(model, BALL, V3(0.55, 0.55, 0.55), CFrame.new(-2.05, 1.15, -0.75), Color3.new(1, 1, 1), nil, "Eye")
	newPart(model, BALL, V3(0.28, 0.28, 0.28), CFrame.new(-2.15, 1.15, -0.95), Color3.new(0.05, 0.05, 0.05), nil, "Eye")
	for a = 0, 7 do
		local ang = math.rad(a * 45)
		newPart(model, BLOCK, V3(0.35, 1.6, 0.25), CFrame.new(-1.8, 2.2, 0) * CFrame.Angles(0, 0, ang) * CFrame.new(0, 0.7, 0), star)
	end
	newPart(model, BALL, V3(0.9, 0.9, 0.9), CFrame.new(-1.8, 2.2, 0), star)
	for _, sx in ipairs({ -0.7, 0.9 }) do
		newPart(model, BLOCK, V3(0.9, 1.7, 0.9), CFrame.new(sx, -1.0, 0), c)
		newPart(model, BALL, V3(1.3, 0.7, 1.5), CFrame.new(sx, -1.95, -0.15), shoe)
	end
end

-- antenna: long capsule + round head with two antennae + fat shoe legs
STYLES.antenna = function(model, c)
	local dark = c:Lerp(Color3.new(0, 0, 0), 0.25)
	local shoe = Color3.fromRGB(50, 50, 60)
	newPart(model, BALL, V3(4.6, 2.4, 2.4), CFrame.new(0.2, 0.5, 0), c, nil, "Body")
	newPart(model, BALL, V3(2.0, 2.0, 2.0), CFrame.new(-2.0, 0.9, 0), c)
	newPart(model, BALL, V3(0.6, 0.6, 0.6), CFrame.new(-2.25, 1.15, -0.85), Color3.new(1, 1, 1), nil, "Eye")
	newPart(model, BALL, V3(0.3, 0.3, 0.3), CFrame.new(-2.35, 1.15, -1.05), Color3.new(0.05, 0.05, 0.05), nil, "Eye")
	for _, sx in ipairs({ -0.35, 0.35 }) do
		newPart(model, CYL, V3(1.2, 0.18, 0.18), CFrame.new(-2.0 + sx * 0.2, 2.0, 0) * CFrame.Angles(0, 0, math.rad(sx * 35) + PI / 2), dark)
		newPart(model, BALL, V3(0.45, 0.45, 0.45), CFrame.new(-2.0 + sx * 0.85, 2.55, 0), Color3.fromRGB(255, 90, 90))
	end
	for _, sx in ipairs({ -0.75, 0.95 }) do
		newPart(model, CYL, V3(1.5, 1.0, 1.0), CFrame.new(sx, -0.9, 0) * CFrame.Angles(0, 0, PI / 2), c)
		newPart(model, BALL, V3(1.5, 0.8, 1.7), CFrame.new(sx, -1.85, -0.1), shoe)
	end
end

-- catleg: chubby cat head/body with pointy ears and four zigzag stub legs
STYLES.catleg = function(model, c)
	local dark = Color3.fromRGB(40, 35, 35)
	local belly = c:Lerp(Color3.new(1, 1, 1), 0.35)
	newPart(model, BALL, V3(3.4, 2.6, 2.8), CFrame.new(0, 0.3, 0), c, nil, "Body")
	newPart(model, BALL, V3(2.8, 2.6, 2.6), CFrame.new(-0.2, 1.5, 0), c)
	newPart(model, BALL, V3(2.0, 1.6, 1.2), CFrame.new(-0.2, 1.2, -0.9), belly)
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, BLOCK, V3(0.7, 1.1, 0.35), CFrame.new(sx * 0.85, 2.7, 0.1) * CFrame.Angles(0, 0, math.rad(-sx * 18)), c)
	end
	addEyes(model, 0.55, 1.7, -1.2, 0.7)
	newPart(model, BLOCK, V3(0.6, 0.12, 0.1), CFrame.new(-0.15, 1.15, -1.35) * CFrame.Angles(0, 0, math.rad(12)), dark)
	for _, xz in ipairs({ { -0.9, -0.7 }, { 0.9, -0.7 }, { -0.9, 0.7 }, { 0.9, 0.7 } }) do
		newPart(model, BLOCK, V3(0.35, 0.9, 0.35), CFrame.new(xz[1], -1.0, xz[2]) * CFrame.Angles(0, 0, math.rad(xz[1] * 12)), dark)
		newPart(model, BLOCK, V3(0.35, 0.55, 0.35), CFrame.new(xz[1] * 1.15, -1.55, xz[2]) * CFrame.Angles(0, 0, math.rad(-xz[1] * 20)), dark)
	end
end

-- swordbox: boxy dual-sword fighter with mismatched eyes and scribbled mouth band
STYLES.swordbox = function(model, c)
	local dark = Color3.fromRGB(25, 25, 30)
	local steel = Color3.fromRGB(200, 210, 230)
	local shade = c:Lerp(Color3.new(0, 0, 0), 0.2)
	newPart(model, BLOCK, V3(2.8, 3.4, 1.6), CFrame.new(0, 1.2, 0), c, nil, "Body")
	newPart(model, BLOCK, V3(2.9, 0.9, 1.7), CFrame.new(0, 0.55, 0), dark) -- scribbled mouth/band
	newPart(model, BALL, V3(1.1, 1.1, 0.2), CFrame.new(-0.55, 2.15, -0.85), Color3.new(1, 1, 1), nil, "Eye")
	newPart(model, BALL, V3(0.85, 0.85, 0.2), CFrame.new(0.6, 2.35, -0.85), Color3.new(1, 1, 1), nil, "Eye")
	newPart(model, BALL, V3(0.4, 0.4, 0.15), CFrame.new(-0.55, 2.15, -0.95), dark, nil, "Eye")
	newPart(model, BALL, V3(0.3, 0.3, 0.15), CFrame.new(0.6, 2.35, -0.95), dark, nil, "Eye")
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, BLOCK, V3(0.45, 1.6, 0.45), CFrame.new(sx * 0.55, -0.9, 0), shade)
		newPart(model, BALL, V3(0.8, 0.45, 1.0), CFrame.new(sx * 0.55, -1.75, -0.1), dark)
		newPart(model, BLOCK, V3(0.35, 2.2, 0.35), CFrame.new(sx * 1.5, 2.4, 0) * CFrame.Angles(0, 0, math.rad(-sx * 25)), shade)
		newPart(model, BLOCK, V3(0.25, 3.2, 0.45), CFrame.new(sx * 1.85, 4.0, 0) * CFrame.Angles(0, 0, math.rad(-sx * 10)), steel)
		newPart(model, BLOCK, V3(0.55, 0.35, 0.55), CFrame.new(sx * 1.7, 2.35, 0), dark)
	end
end

-- flybeak: oval flying bird with big wings, pointed beak, whiskers
STYLES.flybeak = function(model, c)
	local beak = Color3.fromRGB(255, 160, 40)
	local wing = c:Lerp(Color3.new(1, 1, 1), 0.15)
	newPart(model, BALL, V3(4.0, 2.2, 2.4), CFrame.new(0, 0.8, 0), c, nil, "Body")
	newPart(model, BLOCK, V3(1.2, 0.55, 0.45), CFrame.new(-2.3, 0.85, 0) * CFrame.Angles(0, 0, math.rad(-10)), beak)
	newPart(model, BALL, V3(0.5, 0.5, 0.5), CFrame.new(-1.5, 1.2, -0.85), Color3.new(1, 1, 1), nil, "Eye")
	newPart(model, BALL, V3(0.25, 0.25, 0.25), CFrame.new(-1.6, 1.2, -1.0), Color3.new(0.05, 0.05, 0.05), nil, "Eye")
	for _, y in ipairs({ 0.5, 0.85, 1.2 }) do
		newPart(model, BLOCK, V3(0.7, 0.08, 0.08), CFrame.new(-2.5, y, 0.35) * CFrame.Angles(0, math.rad(20), math.rad((y - 0.85) * 40)), Color3.fromRGB(40, 40, 40))
	end
	for _, sx in ipairs({ -1, 1 }) do
		newPart(model, BALL, V3(2.6, 0.5, 1.8), CFrame.new(sx * 0.2, 1.1, sx * 1.4) * CFrame.Angles(math.rad(sx * 12), 0, math.rad(sx * 8)), wing)
	end
	newPart(model, BLOCK, V3(0.9, 0.35, 0.5), CFrame.new(2.0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(15)), c)
end

local BrainrotModels = {}

function BrainrotModels.build(def, super)
	local customModels = ServerStorage:FindFirstChild("BrainrotModels")
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
		local styleFn = STYLES[def.Style or "round"] or STYLES.round
		styleFn(model, def.Color)
		if super then
			for _, d in ipairs(model:GetChildren()) do
				if d:IsA("BasePart") and d ~= root and d.Name ~= "Eye" then
					d.Color = GOLD
					d.Material = Enum.Material.Neon
				end
			end
		end
		local rare = def.Rarity == "Epic" or def.Rarity == "Legendary" or def.Rarity == "Mythic"
		if super or rare then
			local body = model:FindFirstChild("Body")
			if body then
				local sp = Instance.new("Sparkles")
				sp.SparkleColor = Util.rarityColor(def.Rarity)
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

function BrainrotModels.playSpawnPop(model)
	local root = model and model.PrimaryPart
	if not root then return end
	local goal = root.CFrame
	root.CFrame = goal * CFrame.new(0, 2, 0)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= root then
			d.Transparency = math.min(d.Transparency + 0.4, 0.85)
		end
	end
	task.spawn(function()
		local tw = TweenService:Create(root, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = goal })
		tw:Play()
		tw.Completed:Wait()
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "Root" then
				TweenService:Create(d, TweenInfo.new(0.2), { Transparency = 0 }):Play()
			end
		end
	end)
end

function BrainrotModels.startIdleBob(model)
	local root = model and model.PrimaryPart
	if not root then return end
	task.spawn(function()
		local base = root.CFrame
		local t0 = os.clock()
		while model.Parent and root.Parent do
			local t = os.clock() - t0
			root.CFrame = base * CFrame.new(0, math.sin(t * 2) * 0.12, 0)
			task.wait(0.03)
		end
	end)
end

return BrainrotModels
