-- TradeServer (Script) -> put in ServerScriptService   (REPLACES the old TradeServer)
-- Player-to-player trading: one player offers N brainrots and asks for Coins.
-- The offering player's cheapest brainrots (by income) are the ones that move.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local event = Instance.new("RemoteEvent")
event.Name = "TradeEvent"
event.Parent = ReplicatedStorage

local api = ServerStorage:WaitForChild("BaseApi") -- created by GameSetup

local pending = {} -- [targetUserId] = { from = player, give = n, want = n }

local function coinsOf(player)
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Coins")
end

local function notify(player, message)
	event:FireClient(player, "Message", message)
end

event.OnServerEvent:Connect(function(player, action, a, b, c)
	if action == "Offer" then
		local target = Players:GetPlayerByUserId(tonumber(a) or 0)
		local give, want = math.floor(tonumber(b) or 0), math.floor(tonumber(c) or 0)

		if not target or target == player then return end
		if give < 1 or want < 0 or give > 8 or want > 100000 then
			notify(player, "Invalid offer.")
			return
		end

		if api:Invoke("Count", player) < give then
			notify(player, "You don't have that many brainrots.")
			return
		end

		pending[target.UserId] = { from = player, give = give, want = want }
		notify(player, "Offer sent to " .. target.Name)
		event:FireClient(target, "Incoming", player.UserId, player.Name, give, want)

	elseif action == "Respond" then
		local offer = pending[player.UserId]
		pending[player.UserId] = nil
		if not offer then return end

		local from = offer.from
		if not from or from.Parent ~= Players then return end

		if not a then
			notify(from, player.Name .. " declined your trade.")
			return
		end

		local fromCoins, toCoins = coinsOf(from), coinsOf(player)
		if not (fromCoins and toCoins) then return end

		-- re-check everything at the moment of the trade
		if api:Invoke("Count", from) < offer.give then
			notify(player, "Trade failed: they no longer have the brainrots.")
			notify(from, "Trade failed: not enough brainrots.")
			return
		end
		if api:Invoke("Free", player) < offer.give then
			notify(player, "Trade failed: your base doesn't have enough free pedestals.")
			notify(from, "Trade failed: " .. player.Name .. "'s base is full.")
			return
		end
		if toCoins.Value < offer.want then
			notify(player, "Trade failed: you don't have enough Coins.")
			notify(from, "Trade failed: " .. player.Name .. " doesn't have enough Coins.")
			return
		end

		if not api:Invoke("Transfer", from, player, offer.give) then
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
