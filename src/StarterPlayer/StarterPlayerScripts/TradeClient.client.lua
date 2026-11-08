-- Client HUD: coins, income, carry status, trade UI (responsive + mobile-friendly)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("TradeEvent")
local remotesFolder = ReplicatedStorage:WaitForChild("GameRemotes", 10)
local incomeEvent = remotesFolder and remotesFolder:WaitForChild("IncomeUpdate", 10)
local gameEvent = remotesFolder and remotesFolder:WaitForChild("GameEvent", 10)

local gui = Instance.new("ScreenGui")
gui.Name = "TradeGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local scale = Instance.new("UIScale")
scale.Parent = gui
local function refreshScale()
	local cam = workspace.CurrentCamera
	local size = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local s = math.clamp(math.min(size.X, size.Y) / 900, 0.75, 1.25)
	if isMobile then s = math.clamp(s * 1.1, 0.85, 1.35) end
	scale.Scale = s
end
refreshScale()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
end

local function make(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do obj[k] = v end
	obj.Parent = parent
	return obj
end

local function corner(obj, r)
	make("UICorner", { CornerRadius = UDim.new(0, r or 8) }, obj)
end

-- Top HUD panel
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local hud = make("Frame", {
	Size = UDim2.fromOffset(280, 156),
	Position = UDim2.new(0.5, -140, 0, 12),
	BackgroundColor3 = Color3.fromRGB(25, 25, 35),
	BackgroundTransparency = 0.15,
}, gui)
corner(hud, 12)
make("UIStroke", { Color = Color3.fromRGB(255, 200, 60), Thickness = 1.5, Transparency = 0.4 }, hud)

local coinsBar = make("TextLabel", {
	Size = UDim2.new(1, -16, 0, 32), Position = UDim2.fromOffset(8, 8),
	BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 215, 70),
	Font = Enum.Font.GothamBold, TextSize = 22, Text = "Coins: …", TextXAlignment = Enum.TextXAlignment.Left,
}, hud)

local incomeBar = make("TextLabel", {
	Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(8, 40),
	BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(140, 255, 160),
	Font = Enum.Font.GothamMedium, TextSize = 16, Text = "Income: 0/s", TextXAlignment = Enum.TextXAlignment.Left,
}, hud)

local carryBar = make("TextLabel", {
	Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 66),
	BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(180, 200, 255),
	Font = Enum.Font.Gotham, TextSize = 14, Text = "Carrying: none", TextXAlignment = Enum.TextXAlignment.Left,
}, hud)

local levelBar = make("TextLabel", {
	Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 88),
	BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 190, 255),
	Font = Enum.Font.GothamBold, TextSize = 14, Text = "Level 1 / " .. Config.MaxLevel,
	TextXAlignment = Enum.TextXAlignment.Left,
}, hud)

local function makeUpgradeButton(text, xOffset, width, amount)
	local btn = make("TextButton", {
		Size = UDim2.fromOffset(width, 30), Position = UDim2.fromOffset(xOffset, 116),
		Text = text, Font = Enum.Font.GothamBold, TextSize = 13,
		BackgroundColor3 = Color3.fromRGB(150, 80, 210), TextColor3 = Color3.new(1, 1, 1),
	}, hud)
	corner(btn, 8)
	btn.MouseButton1Click:Connect(function()
		if gameEvent then gameEvent:FireServer("UpgradeLevel", amount) end
	end)
	return btn
end
local upgrade1 = makeUpgradeButton("Level Up", 8, 112, 1)
makeUpgradeButton("+10", 126, 62, 10)
makeUpgradeButton("Max", 194, 78, "max")

task.spawn(function()
	local stats = player:WaitForChild("leaderstats", 30)
	if not stats then
		coinsBar.Text = "Coins: (waiting…)"
		return
	end
	local coins = stats:WaitForChild("Coins", 10)
	local income = stats:FindFirstChild("Income") or stats:WaitForChild("Income", 5)
	local level = stats:FindFirstChild("Level") or stats:WaitForChild("Level", 5)
	local function updateCoins()
		if coins then coinsBar.Text = "Coins: " .. tostring(coins.Value) end
	end
	local function updateIncome()
		if income then incomeBar.Text = "Income: " .. tostring(income.Value) .. "/s" end
	end
	local function updateLevel()
		if not level then return end
		local lv = level.Value
		if lv >= Config.MaxLevel then
			levelBar.Text = "Level " .. lv .. " / " .. Config.MaxLevel .. " (MAX)"
			upgrade1.Text = "MAX"
		else
			levelBar.Text = ("Level %d / %d  |  next: %d"):format(lv, Config.MaxLevel, Config.LevelCost(lv))
			upgrade1.Text = "Level Up"
		end
	end
	updateCoins()
	updateIncome()
	updateLevel()
	if coins then coins:GetPropertyChangedSignal("Value"):Connect(updateCoins) end
	if income then income:GetPropertyChangedSignal("Value"):Connect(updateIncome) end
	if level then level:GetPropertyChangedSignal("Value"):Connect(updateLevel) end
end)

if incomeEvent then
	incomeEvent.OnClientEvent:Connect(function(total)
		incomeBar.Text = "Income: " .. tostring(total) .. "/s"
	end)
end
if gameEvent then
	gameEvent.OnClientEvent:Connect(function(action, a)
		if action == "Carry" then
			carryBar.Text = a and ("Carrying: " .. tostring(a)) or "Carrying: none"
		end
	end)
end

-- Trade button
local openBtn = make("TextButton", {
	Size = UDim2.fromOffset(110, 44), Position = UDim2.new(0, 12, 0.5, -22),
	Text = "Trade", Font = Enum.Font.GothamBold, TextSize = 18,
	BackgroundColor3 = Color3.fromRGB(60, 120, 220), TextColor3 = Color3.new(1, 1, 1),
	AutoButtonColor = true,
}, gui)
corner(openBtn, 10)

local frame = make("Frame", {
	Size = UDim2.fromOffset(300, 380), Position = UDim2.new(0, 130, 0.5, -120),
	BackgroundColor3 = Color3.fromRGB(30, 30, 42), Visible = false,
}, gui)
corner(frame, 12)

make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = "Trade with a player",
	Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.new(1, 1, 1),
}, frame)

local giveBox = make("TextBox", {
	Size = UDim2.fromOffset(130, 32), Position = UDim2.fromOffset(12, 40),
	PlaceholderText = "Brainrots to give", Text = "1", Font = Enum.Font.Gotham, TextSize = 14,
	BackgroundColor3 = Color3.fromRGB(55, 55, 70), TextColor3 = Color3.new(1, 1, 1),
}, frame)
corner(giveBox)

local wantBox = make("TextBox", {
	Size = UDim2.fromOffset(130, 32), Position = UDim2.fromOffset(158, 40),
	PlaceholderText = "Coins you want", Text = "10", Font = Enum.Font.Gotham, TextSize = 14,
	BackgroundColor3 = Color3.fromRGB(55, 55, 70), TextColor3 = Color3.new(1, 1, 1),
}, frame)
corner(wantBox)

local hint = make("TextLabel", {
	Size = UDim2.new(1, -20, 0, 36), Position = UDim2.fromOffset(10, 76),
	BackgroundTransparency = 1, Text = "Offers expire in 30s. Cheapest brainrots transfer unless you select slots below.",
	Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true, TextColor3 = Color3.fromRGB(180, 180, 200),
}, frame)

local slotList = make("ScrollingFrame", {
	Size = UDim2.new(1, -20, 0, 80), Position = UDim2.fromOffset(10, 112),
	BackgroundColor3 = Color3.fromRGB(40, 40, 55), BorderSizePixel = 0,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5,
}, frame)
corner(slotList)
make("UIListLayout", { Padding = UDim.new(0, 3) }, slotList)

local selected = {} -- [index]=true

local function refreshSlots(list)
	for _, child in ipairs(slotList:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	selected = {}
	if typeof(list) ~= "table" then return end
	for _, info in ipairs(list) do
		local btn = make("TextButton", {
			Size = UDim2.new(1, -6, 0, 26),
			Text = string.format("[%d] %s%s  +%d/s", info.Index, info.Name, info.Super and " ★" or "", info.Income or 0),
			Font = Enum.Font.Gotham, TextSize = 12,
			BackgroundColor3 = Color3.fromRGB(60, 60, 80), TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, slotList)
		corner(btn, 6)
		local pad = make("UIPadding", {}, btn)
		pad.PaddingLeft = UDim.new(0, 6)
		btn.MouseButton1Click:Connect(function()
			if selected[info.Index] then
				selected[info.Index] = nil
				btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
			else
				selected[info.Index] = true
				btn.BackgroundColor3 = Color3.fromRGB(80, 140, 90)
			end
		end)
	end
end

local list = make("ScrollingFrame", {
	Size = UDim2.new(1, -20, 1, -210), Position = UDim2.fromOffset(10, 200),
	BackgroundColor3 = Color3.fromRGB(40, 40, 55), BorderSizePixel = 0,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6,
}, frame)
corner(list)
make("UIListLayout", { Padding = UDim.new(0, 4) }, list)

local function selectedIndices()
	local out = {}
	for idx in pairs(selected) do table.insert(out, idx) end
	table.sort(out)
	return out
end

local function refreshList()
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local btn = make("TextButton", {
				Size = UDim2.new(1, -6, 0, 34), Text = "Offer to " .. other.DisplayName,
				Font = Enum.Font.GothamBold, TextSize = 14,
				BackgroundColor3 = Color3.fromRGB(70, 150, 85), TextColor3 = Color3.new(1, 1, 1),
			}, list)
			corner(btn)
			btn.MouseButton1Click:Connect(function()
				local idxs = selectedIndices()
				local give = tonumber(giveBox.Text) or 1
				if #idxs > 0 then give = #idxs end
				event:FireServer("Offer", other.UserId, give, tonumber(wantBox.Text), #idxs > 0 and idxs or nil)
			end)
		end
	end
end

openBtn.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
	if frame.Visible then
		refreshList()
		event:FireServer("ListMySlots")
	end
end)
Players.PlayerAdded:Connect(function() if frame.Visible then refreshList() end end)
Players.PlayerRemoving:Connect(function() task.defer(function() if frame.Visible then refreshList() end end) end)

local popup = make("Frame", {
	Size = UDim2.fromOffset(320, 140), Position = UDim2.new(0.5, -160, 0, 120),
	BackgroundColor3 = Color3.fromRGB(30, 30, 42), Visible = false,
}, gui)
corner(popup, 12)

local popupText = make("TextLabel", {
	Size = UDim2.new(1, -20, 0, 70), Position = UDim2.fromOffset(10, 8), BackgroundTransparency = 1,
	Font = Enum.Font.Gotham, TextSize = 15, TextWrapped = true, TextColor3 = Color3.new(1, 1, 1), Text = "",
}, popup)

local acceptBtn = make("TextButton", {
	Size = UDim2.fromOffset(140, 40), Position = UDim2.fromOffset(12, 88), Text = "Accept",
	Font = Enum.Font.GothamBold, TextSize = 16,
	BackgroundColor3 = Color3.fromRGB(80, 170, 90), TextColor3 = Color3.new(1, 1, 1),
}, popup)
corner(acceptBtn)

local declineBtn = make("TextButton", {
	Size = UDim2.fromOffset(140, 40), Position = UDim2.fromOffset(168, 88), Text = "Decline",
	Font = Enum.Font.GothamBold, TextSize = 16,
	BackgroundColor3 = Color3.fromRGB(190, 70, 70), TextColor3 = Color3.new(1, 1, 1),
}, popup)
corner(declineBtn)

acceptBtn.MouseButton1Click:Connect(function()
	popup.Visible = false
	event:FireServer("Respond", true)
end)
declineBtn.MouseButton1Click:Connect(function()
	popup.Visible = false
	event:FireServer("Respond", false)
end)

local toast = make("TextLabel", {
	Size = UDim2.fromOffset(380, 40), Position = UDim2.new(0.5, -190, 1, -70),
	BackgroundColor3 = Color3.fromRGB(30, 30, 42), Font = Enum.Font.Gotham, TextSize = 15,
	TextColor3 = Color3.new(1, 1, 1), Text = "", Visible = false,
}, gui)
corner(toast)

local toastId = 0
local function showToast(msg)
	toastId += 1
	local id = toastId
	toast.Text = msg
	toast.Visible = true
	task.delay(4, function()
		if id == toastId then toast.Visible = false end
	end)
end

event.OnClientEvent:Connect(function(action, a, b, c, d, e)
	if action == "Incoming" then
		popupText.Text = ("%s offers %d brainrots for %d Coins.\nAccept within 30s."):format(b, c, d)
		popup.Visible = true
	elseif action == "TradeExpired" then
		popup.Visible = false
		showToast("Trade offer expired.")
	elseif action == "OpenTrade" then
		frame.Visible = true
		refreshList()
		event:FireServer("ListMySlots")
	elseif action == "MySlots" then
		refreshSlots(a)
	elseif action == "Message" then
		showToast(a)
		if typeof(a) == "string" and a:find("Placed") then
			carryBar.Text = "Carrying: none"
		end
	end
end)
