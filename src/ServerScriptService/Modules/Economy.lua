local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Util = require(script.Parent.Util)
local Bases = require(script.Parent.Bases)
local DataService = require(script.Parent.DataService)

local Economy = {}

function Economy.startIncomeLoop()
	local remotes = require(ReplicatedStorage.Shared.Remotes)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, base in ipairs(Bases.list) do
				local owner = base.Owner
				if owner then
					local total = Bases.totalIncome(owner)
					if total > 0 then
						local coins = Util.getStat(owner, "Coins")
						if coins then
							coins.Value += total
							local data = DataService.get(owner)
							if data then data.Coins = coins.Value end
						end
						local incomeStat = Util.getStat(owner, "Income")
						if incomeStat then incomeStat.Value = total end
						if remotes.IncomeUpdate then
							remotes.IncomeUpdate:FireClient(owner, total)
						end
					end
				end
			end
		end
	end)
end

return Economy
