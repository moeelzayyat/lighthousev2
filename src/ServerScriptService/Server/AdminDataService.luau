--!strict
-- AdminDataService (R1.8, Data domain): support tools for the owner. inspect, grant, rollback.
--   * snapshots: on each profile load the server keeps one copy of that player's data per UTC day, the 7 newest
--     days, in LighthouseKeepers_Snapshots_v2 (key player_<UserId>). Studio uses an in-memory store.
--   * rollback(day): online -> the profile is replaced now (validated, saved); offline -> marked and applied at
--     the player's next load (the pre-rollback state is snapshotted first)
--   * every call is checked against OWNER_IDS; anything else is refused and logged (AdminRejected)
-- Callable from the live server console (require + handle) or through the AdminRequest remote.

local AdminDataService = {}

AdminDataService.OWNER_IDS = { [11752219158] = true } :: { [number]: boolean } -- the owner's account
AdminDataService.SNAPSHOT_STORE = "LighthouseKeepers_Snapshots_v2"
AdminDataService.KEEP_DAYS = 7

export type SnapshotRecord = { days: { [string]: any }, pendingRollback: string? }

local function deepCopy(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local c = {}
	for k, v in t do
		c[k] = deepCopy(v)
	end
	return c
end

function AdminDataService.dayKey(t: number): string
	return os.date("!%Y-%m-%d", t)
end

-- Pure: adds today's copy (first one of the day wins) and keeps the KEEP_DAYS newest days.
function AdminDataService.addSnapshot(record: SnapshotRecord?, day: string, data: any): SnapshotRecord
	local r: SnapshotRecord = record or { days = {} }
	if type(r.days) ~= "table" then
		r.days = {}
	end
	if r.days[day] == nil then
		r.days[day] = deepCopy(data)
	end
	local keys = {}
	for k in r.days do
		table.insert(keys, k)
	end
	table.sort(keys, function(a, b)
		return a > b
	end)
	for i = AdminDataService.KEEP_DAYS + 1, #keys do
		r.days[keys[i]] = nil
	end
	return r
end

-- A DataStore stand-in (GetAsync / UpdateAsync) for Studio and tests
function AdminDataService.memoryStore(): any
	local values: { [string]: any } = {}
	return {
		values = values,
		GetAsync = function(_self: any, key: string)
			return deepCopy(values[key])
		end,
		UpdateAsync = function(_self: any, key: string, fn: (any) -> any)
			local result = fn(deepCopy(values[key]))
			if result ~= nil then
				values[key] = deepCopy(result)
			end
			return result
		end,
	}
end

export type Deps = {
	playerData: any, -- PlayerData: data(player), replaceData(player, data)
	grant: any, -- GrantService
	store: any, -- DataStore-like
	findPlayer: (userId: number) -> any,
	now: () -> number,
	log: (string, { [string]: any }) -> (),
	newId: () -> string,
}

local deps: Deps? = nil

function AdminDataService.init(d: Deps)
	deps = d
end

local function keyFor(userId: number): string
	return "player_" .. userId
end

-- Bus consumer for ProfileLoaded: snapshot the day, apply a pending rollback
function AdminDataService.onProfileLoaded(userId: number)
	local d = deps
	if not d then
		return
	end
	local player = d.findPlayer(userId)
	local data = player and d.playerData.data(player)
	if not data then
		return
	end
	local pending: string? = nil
	local pendingData: any = nil
	local ok, err = pcall(function()
		d.store:UpdateAsync(keyFor(userId), function(record: any)
			local r = AdminDataService.addSnapshot(record, AdminDataService.dayKey(d.now()), data)
			pending = r.pendingRollback
			pendingData = if pending then deepCopy(r.days[pending]) else nil
			r.pendingRollback = nil
			return r
		end)
	end)
	if not ok then
		warn("[AdminDataService] snapshot failed for " .. userId .. ": " .. tostring(err))
		return
	end
	if pending and pendingData then
		d.playerData.replaceData(player, pendingData)
		d.log("AdminRollbackApplied", { user = userId, day = pending })
	end
end

function AdminDataService.authorized(callerUserId: number): boolean
	return AdminDataService.OWNER_IDS[callerUserId] == true
end

local ACTIONS = { inspect = true, grant = true, rollback = true }

-- The single entry point. Returns ok and a result (a table for inspect, a message otherwise).
function AdminDataService.handle(callerUserId: number, action: string, targetUserId: number, arg: any): (boolean, any)
	local d = deps
	if not d then
		return false, "not ready"
	end
	if not AdminDataService.authorized(callerUserId) then
		d.log("AdminRejected", { caller = callerUserId, action = tostring(action), target = tostring(targetUserId) })
		warn("[AdminDataService] refused " .. tostring(action) .. " from user " .. tostring(callerUserId))
		return false, "not allowed"
	end
	if not ACTIONS[action] or type(targetUserId) ~= "number" or targetUserId <= 0 or targetUserId % 1 ~= 0 then
		return false, "bad request"
	end
	local player = d.findPlayer(targetUserId)
	if action == "inspect" then
		local online = player and d.playerData.data(player)
		local record = d.store:GetAsync(keyFor(targetUserId))
		local days = {}
		if record and type(record.days) == "table" then
			for day in record.days do
				table.insert(days, day)
			end
			table.sort(days)
		end
		d.log("AdminInspect", { caller = callerUserId, target = targetUserId })
		return true, { online = online ~= nil, data = deepCopy(online), snapshotDays = days }
	elseif action == "grant" then
		if type(arg) ~= "number" or arg <= 0 or arg % 1 ~= 0 or arg > 1000 then
			return false, "grant needs a whole number of Pearls, 1-1000"
		end
		if not player then
			return false, "the player must be online in this server"
		end
		local status = d.grant.Grant(player, "admin:" .. d.newId(), { Pearls = arg }, "admin")
		d.log("AdminGrant", { caller = callerUserId, target = targetUserId, pearls = arg, status = status })
		return status == "granted", status
	else -- rollback
		if type(arg) ~= "string" or not string.match(arg, "^%d%d%d%d%-%d%d%-%d%d$") then
			return false, "rollback needs a day like 2026-10-16"
		end
		local record = d.store:GetAsync(keyFor(targetUserId))
		local snapshot = record and type(record.days) == "table" and record.days[arg]
		if not snapshot then
			return false, "no snapshot for " .. arg
		end
		if player and d.playerData.data(player) then
			-- keep today's state as a snapshot before overwriting it
			local current = d.playerData.data(player)
			d.store:UpdateAsync(keyFor(targetUserId), function(r: any)
				return AdminDataService.addSnapshot(r, AdminDataService.dayKey(d.now()), current)
			end)
			d.playerData.replaceData(player, deepCopy(snapshot))
			d.log("AdminRollback", { caller = callerUserId, target = targetUserId, day = arg, applied = "now" })
			return true, "rolled back to " .. arg
		end
		d.store:UpdateAsync(keyFor(targetUserId), function(r: any)
			if r then
				r.pendingRollback = arg
			end
			return r
		end)
		d.log("AdminRollback", { caller = callerUserId, target = targetUserId, day = arg, applied = "next load" })
		return true, "will roll back to " .. arg .. " when the player next joins"
	end
end

return AdminDataService
