local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local last = {} -- [player] = {[key]=clock}

local RateLimit = {}

function RateLimit.allow(player, key, seconds)
	seconds = seconds or Config.RemoteRateLimitSeconds
	if not player then return false end
	last[player] = last[player] or {}
	local t = os.clock()
	local prev = last[player][key] or -999
	if t - prev < seconds then
		return false
	end
	last[player][key] = t
	return true
end

function RateLimit.clear(player)
	last[player] = nil
end

return RateLimit
