--!strict
-- GrantService (R1.3, Economy domain): the only writer of Pearls and items granted to a player.
-- Every grant carries a claimId; a claim is applied once (Profile.Grants[claimId] = time) and a repeat returns
-- "duplicate" without changing anything. Claim ids older than 30 days are pruned on the next grant.
--   apply(data, claimId, rewards, now)          pure, on a schema-v2 profile table (tested directly)
--   Grant(player, claimId, rewards, source)     the server entry point: applies, saves soon, publishes

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Items = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Items")) :: any
local ProfileSchema = require(script.Parent.ProfileSchema)

local GrantService = {}

export type Rewards = { Pearls: number?, Items: { [string]: number }? }
export type Status = "granted" | "duplicate" | "invalid"

GrantService.CLAIM_ID_MAX = 100

local OWNED_KINDS = { Weapon = true, Armor = true, Cosmetic = true }

local function wholeNonNegative(x: any): boolean
	return type(x) == "number" and x == x and x >= 0 and x < 1e6 and x % 1 == 0
end

-- Why a reward table is not acceptable, or nil when it is.
function GrantService.check(claimId: any, rewards: any): string?
	if type(claimId) ~= "string" or #claimId == 0 or #claimId > GrantService.CLAIM_ID_MAX then
		return "bad claim id"
	end
	if type(rewards) ~= "table" then
		return "rewards must be a table"
	end
	if rewards.Pearls ~= nil and not wholeNonNegative(rewards.Pearls) then
		return "Pearls must be a whole number >= 0"
	end
	if rewards.Items ~= nil then
		if type(rewards.Items) ~= "table" then
			return "Items must be a table"
		end
		for id, n in rewards.Items do
			if type(Items[id]) ~= "table" then
				return "unknown item " .. tostring(id)
			end
			if not wholeNonNegative(n) or n == 0 then
				return "bad amount for " .. tostring(id)
			end
		end
	end
	return nil
end

local function prune(grants: { [string]: number }, now: number)
	for id, at in grants do
		if type(at) ~= "number" or now - at > ProfileSchema.GRANT_TTL_SECONDS then
			grants[id] = nil
		end
	end
end

-- Applies a claim to a profile table. Pure apart from mutating `data`.
function GrantService.apply(data: any, claimId: string, rewards: Rewards, now: number): (Status, string?)
	local problem = GrantService.check(claimId, rewards)
	if problem then
		return "invalid", problem
	end
	if data.Grants[claimId] ~= nil then
		return "duplicate", nil
	end
	prune(data.Grants, now)
	data.Pearls += rewards.Pearls or 0
	if rewards.Items then
		for id, n in rewards.Items do
			if OWNED_KINDS[Items[id].kind] then
				data.Owned[id] = true
			else
				data.Counts[id] = (data.Counts[id] or 0) + n
			end
		end
	end
	data.Grants[claimId] = now
	return "granted", nil
end

-- Server entry point. source names where it came from for telemetry ("run", "sell", "dawn", ...).
-- Returns the status; a granted Pearl claim is saved straight away and published as PearlsGranted.
function GrantService.Grant(player: Player, claimId: string, rewards: Rewards, source: string): (Status, string?)
	local PlayerData = require(script.Parent.PlayerData) :: any
	local EventLog = require(script.Parent.EventLog) :: any
	local status: Status, detail: string? = "invalid", "no profile"
	local balance = 0
	PlayerData.mutate(player, function(data: any): boolean
		status, detail = GrantService.apply(data, claimId, rewards, os.time())
		balance = data.Pearls
		return status == "granted"
	end, true)
	if status == "granted" then
		EventLog.log("Grant", { player = player.Name, claim = claimId, pearls = rewards.Pearls or 0, source = source, total = balance })
		if (rewards.Pearls or 0) > 0 then
			EventLog.Publish("PearlsGranted", { UserId = player.UserId, Amount = rewards.Pearls, Balance = balance, Source = source, ClaimId = claimId })
		end
	elseif status == "invalid" then
		warn("[GrantService] refused " .. tostring(claimId) .. " for " .. player.Name .. ": " .. tostring(detail))
	end
	return status, detail
end

return GrantService
