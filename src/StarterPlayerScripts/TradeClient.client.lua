-- TradeClient (LocalScript) -> put in StarterPlayer > StarterPlayerScripts
-- Simple trading screen. Press the "Trade" button to open it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("TradeEvent")

local gui = Instance.new("ScreenGui")
gui.Name = "TradeGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function make(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do obj[k] = v end
	obj.Parent = parent
	return obj
end

local function corner(obj)
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, obj)
end

-- Coins display (bottom of the screen)
local coinsBar = make("TextLabel", {
	Size = UDim2.fromOffset(220, 44), Position = UDim2.new(0.5, -110, 1, -60),
	BackgroundColor3 = Color3.fromRGB(35, 35, 45), TextColor3 = Color3.fromRGB(255, 215, 70),
	Font = Enum.Font.GothamBold, TextSize = 24, Text = "Coins: 0",
}, gui)
corner(coinsBar)

task.spawn(function()
	local stats = player:WaitForChild("leaderstats", 30)
	if not stats then
		coinsBar.Text = "Coins: (waiting…)"
		return
	end
	local coins = stats:WaitForChild("Coins", 10)
	if not coins then
		coinsBar.Text = "Coins: (missing)"
		return
	end
	local function update()
		coinsBar.Text = "Coins: " .. tostring(coins.Value)
	end
	update()
	coins:GetPropertyChangedSignal("Value"):Connect(update)
end)

-- Open/close button
local openBtn = make("TextButton", {
	Size = UDim2.fromOffset(100, 40), Position = UDim2.new(0, 10, 0.5, 0),
	Text = "Trade", Font = Enum.Font.GothamBold, TextSize = 18,
	BackgroundColor3 = Color3.fromRGB(60, 120, 220), TextColor3 = Color3.new(1, 1, 1),
}, gui)
corner(openBtn)

-- Trade window
local frame = make("Frame", {
	Size = UDim2.fromOffset(280, 340), Position = UDim2.new(0, 120, 0.5, -100),
	BackgroundColor3 = Color3.fromRGB(35, 35, 45), Visible = false,
}, gui)
corner(frame)

make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "Trade with a player",
	Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.new(1, 1, 1),
}, frame)

local giveBox = make("TextBox", {
	Size = UDim2.fromOffset(120, 30), Position = UDim2.fromOffset(10, 35),
	PlaceholderText = "Brainrots to give", Text = "1", Font = Enum.Font.Gotham, TextSize = 14,
	BackgroundColor3 = Color3.fromRGB(60, 60, 75), TextColor3 = Color3.new(1, 1, 1),
}, frame)
corner(giveBox)

local wantBox = make("TextBox", {
	Size = UDim2.fromOffset(120, 30), Position = UDim2.fromOffset(150, 35),
	PlaceholderText = "Coins you want", Text = "10", Font = Enum.Font.Gotham, TextSize = 14,
	BackgroundColor3 = Color3.fromRGB(60, 60, 75), TextColor3 = Color3.new(1, 1, 1),
}, frame)
corner(wantBox)

local list = make("ScrollingFrame", {
	Size = UDim2.new(1, -20, 1, -85), Position = UDim2.fromOffset(10, 75),
	BackgroundColor3 = Color3.fromRGB(45, 45, 58), BorderSizePixel = 0,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6,
}, frame)
corner(list)
make("UIListLayout", { Padding = UDim.new(0, 4) }, list)

local function refreshList()
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local btn = make("TextButton", {
				Size = UDim2.new(1, -6, 0, 30), Text = "Offer to " .. other.Name,
				Font = Enum.Font.Gotham, TextSize = 14,
				BackgroundColor3 = Color3.fromRGB(80, 160, 90), TextColor3 = Color3.new(1, 1, 1),
			}, list)
			corner(btn)
			btn.MouseButton1Click:Connect(function()
				event:FireServer("Offer", other.UserId, tonumber(giveBox.Text), tonumber(wantBox.Text))
			end)
		end
	end
end

openBtn.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
	if frame.Visible then refreshList() end
end)
Players.PlayerAdded:Connect(function() if frame.Visible then refreshList() end end)
Players.PlayerRemoving:Connect(function() task.defer(function() if frame.Visible then refreshList() end end) end)

-- Incoming offer popup
local popup = make("Frame", {
	Size = UDim2.fromOffset(300, 130), Position = UDim2.new(0.5, -150, 0, 20),
	BackgroundColor3 = Color3.fromRGB(35, 35, 45), Visible = false,
}, gui)
corner(popup)

local popupText = make("TextLabel", {
	Size = UDim2.new(1, -20, 0, 70), Position = UDim2.fromOffset(10, 5), BackgroundTransparency = 1,
	Font = Enum.Font.Gotham, TextSize = 16, TextWrapped = true, TextColor3 = Color3.new(1, 1, 1), Text = "",
}, popup)

local acceptBtn = make("TextButton", {
	Size = UDim2.fromOffset(130, 36), Position = UDim2.fromOffset(10, 85), Text = "Accept",
	Font = Enum.Font.GothamBold, TextSize = 16,
	BackgroundColor3 = Color3.fromRGB(80, 170, 90), TextColor3 = Color3.new(1, 1, 1),
}, popup)
corner(acceptBtn)

local declineBtn = make("TextButton", {
	Size = UDim2.fromOffset(130, 36), Position = UDim2.fromOffset(160, 85), Text = "Decline",
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

-- Message toast
local toast = make("TextLabel", {
	Size = UDim2.fromOffset(360, 36), Position = UDim2.new(0.5, -180, 1, -120),
	BackgroundColor3 = Color3.fromRGB(35, 35, 45), Font = Enum.Font.Gotham, TextSize = 16,
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

event.OnClientEvent:Connect(function(action, a, b, c, d)
	if action == "Incoming" then
		-- a = fromUserId, b = fromName, c = give (Brains), d = want (Coins)
		popupText.Text = ("%s wants to give you %d brainrots for %d Coins."):format(b, c, d)
		popup.Visible = true
	elseif action == "OpenTrade" then
		frame.Visible = true
		refreshList()
	elseif action == "Message" then
		showToast(a)
	end
end)
