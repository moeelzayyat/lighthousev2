--!strict
-- LeaderboardService (S7.3, LiveOps domain): keeps the harbor boards (Definitions/Leaderboards). Every
-- NightSurvived on the bus raises each crew member's best night for that voyage and adds one night to their
-- week; the scores are written every FLUSH_SECONDS and the boards re-read right after, so a board shows a new
-- score within 60 s. The weekly board writes to a new store each week (reset on schedule).
--   start(deps)   deps.storeFor(name) gives { raise(key, value), add(key, delta), top(n) -> {{key, value}} }

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Leaderboards = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("Leaderboards")) :: any

local LeaderboardService = {}

export type Store = {
	raise: (key: string, value: number) -> (),
	add: (key: string, delta: number) -> (),
	top: (n: number) -> { { key: string, value: number } },
}
export type Deps = {
	subscribe: (name: string, handler: (any) -> ()) -> any,
	storeFor: (name: string) -> Store,
	voyage: () -> string?,
	now: () -> number,
	nameOf: (userId: number) -> string,
	show: (boardId: string, title: string, rows: { string }) -> (),
	every: (seconds: number, fn: () -> ()) -> (),
}

-- best[boardId][userId] = night; weekly[userId] = nights (written at the next flush)
local best: { [string]: { [number]: number } } = {}
local weekly: { [number]: number } = {}

function LeaderboardService.pending(): ({ [string]: { [number]: number } }, { [number]: number })
	return best, weekly
end

-- Writes what is pending, then re-reads every board and shows it
function LeaderboardService.flush(deps: Deps)
	local now = deps.now()
	for _, id in Leaderboards.ORDER do
		local def = Leaderboards[id]
		local store = deps.storeFor(Leaderboards.storeName(def, now))
		if def.kind == "best" then
			for userId, night in (best[id] or {}) :: { [any]: any } do
				store.raise(tostring(userId), night)
			end
			best[id] = {}
		else
			for userId, nights in weekly do
				store.add(tostring(userId), nights)
			end
			table.clear(weekly)
		end
		local rows = {}
		for i, entry in store.top(Leaderboards.TOP) do
			table.insert(rows, string.format("%d. %s  %d", i, deps.nameOf(tonumber(entry.key) or 0), entry.value))
		end
		deps.show(id, def.title, rows)
	end
end

function LeaderboardService.start(deps: Deps)
	deps.subscribe("NightSurvived", function(e)
		local voyage = deps.voyage()
		for _, id in Leaderboards.ORDER do
			local def = Leaderboards[id]
			if def.kind == "best" and def.voyage == voyage then
				best[id] = best[id] or {}
				for _, userId in e.Crew do
					best[id][userId] = math.max(best[id][userId] or 0, e.Night)
				end
			end
		end
		for _, userId in e.Crew do
			weekly[userId] = (weekly[userId] or 0) + 1
		end
	end)
	deps.every(Leaderboards.FLUSH_SECONDS, function()
		LeaderboardService.flush(deps)
	end)
end

return LeaderboardService
