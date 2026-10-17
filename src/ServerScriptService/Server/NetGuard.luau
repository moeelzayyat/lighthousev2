--!strict
-- NetGuard (R1.4): the per-remote guard layer from docs/API_CONTRACTS.md.
--   * a per-player token bucket for every client -> server remote (RATES below = the contract's Rate column)
--   * a capped requestId replay map for economic remotes (checked BEFORE the rate limit)
--   * shared type guards (finite numbers/vectors, request ids)
-- Counters are kept as attributes on this ModuleScript (Allowed_<Remote>, Limited_<Remote>) so a probe in
-- another script context can read them; ServerScriptService never replicates to clients.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local NetGuard = {}

-- remote -> { sustained per second, burst }
NetGuard.RATES = {
	Attack = { 6, 10 },
	BeamControl = { 20, 30 },
	LampAction = { 4, 6 },
	LampShift = { 4, 6 },
	BuyUpgrade = { 3, 5 },
	ShopRequest = { 5, 8 },
	TraderRequest = { 3, 5 },
	LoadoutRequest = { 5, 8 },
	GearAction = { 2, 4 },
	SetReady = { 2, 3 },
	VoteRematch = { 2, 3 },
	EnterLobby = { 1, 2 },
	ReportDevice = { 1, 1 },
	CoachEvent = { 4, 8 },
	ForecastVote = { 3, 5 },
	AdminRequest = { 1, 3 }, -- R1.8, owner-only channel
	ChooseVoyage = { 2, 3 }, -- S2.1
	MerchantRequest = { 5, 8 }, -- S6.2
	CodeRedeem = { 0.1, 1 }, -- L1.4: one code every 10 s
	SniperAction = { 3, 5 }, -- D-044: the rifle fires once a second; leave
} :: { [string]: { number } }

NetGuard.REPLAY_CAP = 40
NetGuard.REQUEST_ID_MAX = 40

-- Token bucket ----------------------------------------------------------------------

export type Bucket = { tokens: number, last: number, rate: number, burst: number }

function NetGuard.newBucket(rate: number, burst: number, now: number): Bucket
	return { tokens = burst, last = now, rate = rate, burst = burst }
end

-- Takes one token if available. Pure: the caller supplies the time.
function NetGuard.take(bucket: Bucket, now: number): boolean
	local elapsed = math.max(0, now - bucket.last)
	local tokens = math.min(bucket.burst, bucket.tokens + elapsed * bucket.rate)
	bucket.last = now
	if tokens >= 1 then
		bucket.tokens = tokens - 1
		return true
	end
	bucket.tokens = tokens
	return false
end

-- Per-player limiter ----------------------------------------------------------------

NetGuard.now = os.clock -- replaced by a fake clock in tests

local buckets: { [any]: { [string]: Bucket } } = {}

local function bump(attribute: string)
	local holder = script :: any
	holder:SetAttribute(attribute, ((holder:GetAttribute(attribute) :: number?) or 0) + 1)
end

-- True when `player` may use `remote` now; false (and counted) when over the contract rate.
function NetGuard.allow(player: any, remote: string): boolean
	local rate = NetGuard.RATES[remote]
	assert(rate ~= nil, "NetGuard: no contract rate for remote " .. tostring(remote))
	local perPlayer = buckets[player]
	if not perPlayer then
		perPlayer = {}
		buckets[player] = perPlayer
	end
	local now = NetGuard.now()
	local bucket = perPlayer[remote]
	if not bucket then
		bucket = NetGuard.newBucket(rate[1], rate[2], now)
		perPlayer[remote] = bucket
	end
	if NetGuard.take(bucket, now) then
		bump("Allowed_" .. remote)
		return true
	end
	bump("Limited_" .. remote)
	return false
end

-- Connecting handlers -------------------------------------------------------------
-- B1.3: every client -> server handler is connected here (a spec checks that no other OnServerEvent exists). In
-- Studio only, each handler is also exposed as ServerStorage.NetHooks.<Remote> (a BindableFunction), so the
-- security suite in TestRunner can call the live handler as a real or a fake player. Live servers never make it.
function NetGuard.expose(name: string, fn: (...any) -> ...any)
	if not RunService:IsStudio() then
		return
	end
	local folder = ServerStorage:FindFirstChild("NetHooks")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "NetHooks"
		folder.Parent = ServerStorage
	end
	local hook = Instance.new("BindableFunction")
	hook.Name = name
	hook.OnInvoke = fn
	hook.Parent = folder
end

function NetGuard.connect(remote: any, handler: (...any) -> ())
	remote.OnServerEvent:Connect(handler)
	NetGuard.expose(remote.Name, function(...)
		local ok, err = pcall(handler, ...)
		return ok, if ok then nil else tostring(err)
	end)
end

function NetGuard.forget(player: any)
	buckets[player] = nil
end

-- Replay map ------------------------------------------------------------------------
-- One per economic remote. Remembers the last REPLAY_CAP results per player (oldest dropped first).

export type ReplayMap = {
	get: (player: any, requestId: string) -> { any }?,
	put: (player: any, requestId: string, result: { any }) -> (),
	forget: (player: any) -> (),
	size: (player: any) -> number,
}

type Memory = { results: { [string]: { any } }, order: { string } }

local replayMaps: { ReplayMap } = {}

function NetGuard.replayMap(cap: number?): ReplayMap
	local limit = cap or NetGuard.REPLAY_CAP
	local memories: { [any]: Memory } = {}
	local map: ReplayMap = {
		get = function(player: any, requestId: string): { any }?
			local memory = memories[player]
			return if memory then memory.results[requestId] else nil
		end,
		put = function(player: any, requestId: string, result: { any })
			local memory = memories[player]
			if not memory then
				memory = { results = {}, order = {} }
				memories[player] = memory
			end
			if memory.results[requestId] == nil then
				table.insert(memory.order, requestId)
			end
			memory.results[requestId] = result
			while #memory.order > limit do
				memory.results[table.remove(memory.order, 1) :: string] = nil
			end
		end,
		forget = function(player: any)
			memories[player] = nil
		end,
		size = function(player: any): number
			local memory = memories[player]
			return if memory then #memory.order else 0
		end,
	}
	table.insert(replayMaps, map)
	return map
end

-- Type guards -----------------------------------------------------------------------

function NetGuard.isFiniteNumber(x: any): boolean
	return type(x) == "number" and x == x and x ~= math.huge and x ~= -math.huge
end

function NetGuard.isFiniteVector3(v: any): boolean
	return typeof(v) == "Vector3" and NetGuard.isFiniteNumber(v.X) and NetGuard.isFiniteNumber(v.Y) and NetGuard.isFiniteNumber(v.Z)
end

function NetGuard.isRequestId(s: any): boolean
	return type(s) == "string" and #s > 0 and #s <= NetGuard.REQUEST_ID_MAX
end

Players.PlayerRemoving:Connect(function(player: Player)
	NetGuard.forget(player)
	for _, map in replayMaps do
		map.forget(player)
	end
end)

return NetGuard
