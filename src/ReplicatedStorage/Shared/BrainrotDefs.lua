-- Brainrot catalog. Price/income scale by rarity. Weight controls track spawn chance.
local BrainrotDefs = {
	{ Id = "tung", Name = "Tung Tung Tung Sahur", Rarity = "Common", Price = 25, Income = 1, Weight = 36, Style = "doodle", Color = Color3.fromRGB(205, 160, 100), Foot = 1.9 },
	{ Id = "lirili", Name = "Lirili Larila", Rarity = "Common", Price = 40, Income = 2, Weight = 28, Style = "round", Color = Color3.fromRGB(240, 180, 90), Foot = 1.9 },
	{ Id = "bombini", Name = "Bombini Gusini", Rarity = "Common", Price = 55, Income = 3, Weight = 24, Style = "round", Color = Color3.fromRGB(220, 90, 70), Foot = 1.9 },
	{ Id = "gattini", Name = "Gattini Zigzagini", Rarity = "Common", Price = 70, Income = 3, Weight = 22, Style = "catleg", Color = Color3.fromRGB(255, 170, 90), Foot = 1.7 },

	{ Id = "tralalero", Name = "Tralalero Tralala", Rarity = "Rare", Price = 150, Income = 6, Weight = 16, Style = "tall", Color = Color3.fromRGB(120, 145, 155), Foot = 2.15 },
	{ Id = "cappuccino", Name = "Cappuccino Assassino", Rarity = "Rare", Price = 220, Income = 9, Weight = 12, Style = "round", Color = Color3.fromRGB(140, 90, 50), Foot = 1.9 },
	{ Id = "tripi", Name = "Trippi Troppi", Rarity = "Rare", Price = 280, Income = 11, Weight = 10, Style = "doodle", Color = Color3.fromRGB(90, 200, 160), Foot = 1.9 },
	{ Id = "antennini", Name = "Antennini Capsulini", Rarity = "Rare", Price = 300, Income = 12, Weight = 10, Style = "antenna", Color = Color3.fromRGB(180, 210, 255), Foot = 2.0 },
	{ Id = "volanti", Name = "Volanti Beccini", Rarity = "Rare", Price = 340, Income = 13, Weight = 9, Style = "flybeak", Color = Color3.fromRGB(255, 190, 70), Foot = 1.2 },

	{ Id = "patapim", Name = "Brr Brr Patapim", Rarity = "Epic", Price = 450, Income = 18, Weight = 7, Style = "leafy", Color = Color3.fromRGB(110, 170, 80), Foot = 2.8 },
	{ Id = "ballerina", Name = "Ballerina Cappuccina", Rarity = "Epic", Price = 600, Income = 24, Weight = 5, Style = "doodle", Color = Color3.fromRGB(255, 160, 200), Foot = 1.9 },
	{ Id = "frigo", Name = "Frigo Camelo", Rarity = "Epic", Price = 750, Income = 30, Weight = 4, Style = "tall", Color = Color3.fromRGB(100, 180, 220), Foot = 2.15 },
	{ Id = "stellina", Name = "Boom Boom Stellina", Rarity = "Epic", Price = 800, Income = 32, Weight = 4, Style = "starblast", Color = Color3.fromRGB(255, 230, 180), Foot = 2.1 },
	{ Id = "spadino", Name = "Spadino Boxadino", Rarity = "Epic", Price = 900, Income = 36, Weight = 3, Style = "swordbox", Color = Color3.fromRGB(120, 200, 140), Foot = 1.9 },

	{ Id = "udindin", Name = "Udindindun", Rarity = "Legendary", Price = 1500, Income = 55, Weight = 3, Style = "leafy", Color = Color3.fromRGB(255, 200, 60), Foot = 2.8 },
	{ Id = "chimpanzini", Name = "Chimpanzini Bananini", Rarity = "Legendary", Price = 2200, Income = 75, Weight = 2, Style = "doodle", Color = Color3.fromRGB(255, 220, 80), Foot = 1.9 },

	{ Id = "saturno", Name = "Saturno Saturnita", Rarity = "Mythic", Price = 5000, Income = 150, Weight = 1, Style = "round", Color = Color3.fromRGB(255, 80, 160), Foot = 1.9 },
}

local byId = {}
local byName = {}
for _, def in ipairs(BrainrotDefs) do
	byId[def.Id] = def
	byName[def.Name] = def
end

function BrainrotDefs.GetById(id)
	return byId[id]
end

function BrainrotDefs.GetByName(name)
	return byName[name]
end

function BrainrotDefs.PickWeighted(luckBonus)
	luckBonus = luckBonus or 0
	local total = 0
	local weights = {}
	for i, d in ipairs(BrainrotDefs) do
		-- luckBonus slightly boosts rare+ weights
		local w = d.Weight
		if luckBonus > 0 and d.Rarity ~= "Common" then
			w = w * (1 + luckBonus)
		end
		weights[i] = w
		total += w
	end
	local r = math.random() * total
	for i, d in ipairs(BrainrotDefs) do
		r -= weights[i]
		if r <= 0 then return d end
	end
	return BrainrotDefs[1]
end

return BrainrotDefs
