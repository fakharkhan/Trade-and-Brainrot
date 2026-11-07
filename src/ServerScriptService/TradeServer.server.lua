-- TradeServer: player-to-player trades with expiry, validation, and optional slot indices.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local RateLimit = require(script.Parent.Modules.RateLimit)

local event = ReplicatedStorage:FindFirstChild("TradeEvent")
if not event then
	event = Instance.new("RemoteEvent")
	event.Name = "TradeEvent"
	event.Parent = ReplicatedStorage
end

local api = ServerStorage:WaitForChild("BaseApi", 60)

local pending = {} -- [targetUserId] = { from, give, want, indices?, expires }

local function coinsOf(player)
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Coins")
end

local function notify(player, message)
	if player and player.Parent == Players then
		event:FireClient(player, "Message", message)
	end
end

local function clearExpired()
	local now = os.clock()
	for id, offer in pairs(pending) do
		if offer.expires and now > offer.expires then
			pending[id] = nil
			if offer.from and offer.from.Parent == Players then
				notify(offer.from, "Your trade offer expired.")
			end
			local target = Players:GetPlayerByUserId(id)
			if target then
				event:FireClient(target, "TradeExpired")
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(5)
		pcall(clearExpired)
	end
end)

event.OnServerEvent:Connect(function(player, action, a, b, c, d)
	if typeof(action) ~= "string" then return end
	if not RateLimit.allow(player, "trade_" .. action, Config.RemoteRateLimitSeconds) then
		return
	end

	if action == "ListMySlots" then
		if not api then return end
		local list = api:Invoke("ListSlots", player)
		event:FireClient(player, "MySlots", list)
		return
	end

	if action == "Offer" then
		if api and api:Invoke("IsCarrying", player) then
			notify(player, "Place your carried brainrot before trading.")
			return
		end
		local target = Players:GetPlayerByUserId(tonumber(a) or 0)
		local give, want = math.floor(tonumber(b) or 0), math.floor(tonumber(c) or 0)
		local indices = typeof(d) == "table" and d or nil

		if not target or target == player then return end
		if give < 1 or want < 0 or give > 8 or want > 1000000 then
			notify(player, "Invalid offer.")
			return
		end
		if not api then
			notify(player, "Trade system not ready.")
			return
		end
		if api:Invoke("Count", player) < give then
			notify(player, "You don't have that many brainrots.")
			return
		end
		if indices then
			if #indices ~= give then
				notify(player, "Selected brainrots don't match offer count.")
				return
			end
			for _, idx in ipairs(indices) do
				if typeof(idx) ~= "number" then
					notify(player, "Invalid slot selection.")
					return
				end
			end
		end

		pending[target.UserId] = {
			from = player,
			give = give,
			want = want,
			indices = indices,
			expires = os.clock() + Config.TradeOfferExpireSeconds,
		}
		notify(player, "Offer sent to " .. target.DisplayName .. " (expires in " .. Config.TradeOfferExpireSeconds .. "s)")
		event:FireClient(target, "Incoming", player.UserId, player.DisplayName, give, want, indices)

	elseif action == "Respond" then
		local offer = pending[player.UserId]
		pending[player.UserId] = nil
		if not offer then return end
		if offer.expires and os.clock() > offer.expires then
			notify(player, "That offer already expired.")
			return
		end

		local from = offer.from
		if not from or from.Parent ~= Players then return end

		if not a then
			notify(from, player.DisplayName .. " declined your trade.")
			return
		end

		if api and (api:Invoke("IsCarrying", player) or api:Invoke("IsCarrying", from)) then
			notify(player, "Trade failed: someone is carrying a brainrot.")
			notify(from, "Trade failed: someone is carrying a brainrot.")
			return
		end

		local fromCoins, toCoins = coinsOf(from), coinsOf(player)
		if not (fromCoins and toCoins) then return end

		if api:Invoke("Count", from) < offer.give then
			notify(player, "Trade failed: they no longer have the brainrots.")
			notify(from, "Trade failed: not enough brainrots.")
			return
		end
		if api:Invoke("Free", player) < offer.give then
			notify(player, "Trade failed: your base doesn't have enough free pedestals.")
			notify(from, "Trade failed: " .. player.DisplayName .. "'s base is full.")
			return
		end
		if toCoins.Value < offer.want then
			notify(player, "Trade failed: you don't have enough Coins.")
			notify(from, "Trade failed: " .. player.DisplayName .. " doesn't have enough Coins.")
			return
		end

		local ok
		if offer.indices then
			ok = api:Invoke("TransferSlots", from, player, offer.indices)
		else
			ok = api:Invoke("Transfer", from, player, offer.give)
		end
		if not ok then
			notify(from, "Trade failed.")
			notify(player, "Trade failed.")
			return
		end
		toCoins.Value -= offer.want
		fromCoins.Value += offer.want

		notify(from, ("Trade done! You gave %d brainrots and got %d Coins."):format(offer.give, offer.want))
		notify(player, ("Trade done! You got %d brainrots and paid %d Coins."):format(offer.give, offer.want))
	end
end)

Players.PlayerRemoving:Connect(function(p)
	pending[p.UserId] = nil
	for id, offer in pairs(pending) do
		if offer.from == p then pending[id] = nil end
	end
end)
