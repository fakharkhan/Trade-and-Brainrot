-- Creates remotes once (server) or waits for them (client).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local folder = ReplicatedStorage:FindFirstChild("GameRemotes")
if not folder then
	if RunService:IsServer() then
		folder = Instance.new("Folder")
		folder.Name = "GameRemotes"
		folder.Parent = ReplicatedStorage
	else
		folder = ReplicatedStorage:WaitForChild("GameRemotes", 30)
	end
end

local function getRemote(name, className)
	className = className or "RemoteEvent"
	local existing = folder and folder:FindFirstChild(name)
	if existing then return existing end
	if RunService:IsServer() and folder then
		local r = Instance.new(className)
		r.Name = name
		r.Parent = folder
		return r
	end
	return folder and folder:WaitForChild(name, 30)
end

-- TradeEvent kept at ReplicatedStorage root for backward compatibility with TradeServer
local tradeEvent = ReplicatedStorage:FindFirstChild("TradeEvent")
if not tradeEvent and RunService:IsServer() then
	tradeEvent = Instance.new("RemoteEvent")
	tradeEvent.Name = "TradeEvent"
	tradeEvent.Parent = ReplicatedStorage
elseif not tradeEvent then
	tradeEvent = ReplicatedStorage:WaitForChild("TradeEvent", 30)
end

return {
	Folder = folder,
	TradeEvent = tradeEvent,
	GameEvent = getRemote("GameEvent"),
	IncomeUpdate = getRemote("IncomeUpdate"),
}
