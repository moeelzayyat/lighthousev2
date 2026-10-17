--!strict
-- Definitions/Leaderboards (S7.3): the boards on the harbor island. Live servers keep them in ordered data stores
-- (one per board; the weekly board gets a new store each week, so it resets on Monday 00:00 UTC); Studio uses an
-- in-memory store, so a play test never writes one.
--   kind "best"    the highest night a player has survived on that voyage (NightSurvived)
--   kind "weekly"  nights survived this week, all voyages together

export type BoardDef = { id: string, title: string, store: string, kind: string, voyage: string? }

local Leaderboards = {
	ORDER = { "BestNightStandard", "BestNightLong", "WeeklyNights" },
	TOP = 10, -- rows shown
	FLUSH_SECONDS = 30, -- pending scores are written at least this often (the board updates within 60 s)

	BestNightStandard = { id = "BestNightStandard", title = "Best night: Standard", store = "LK_BestNight_Standard_v1", kind = "best", voyage = "Standard" } :: BoardDef,
	BestNightLong = { id = "BestNightLong", title = "Best night: Long Voyage", store = "LK_BestNight_Long_v1", kind = "best", voyage = "Long" } :: BoardDef,
	WeeklyNights = { id = "WeeklyNights", title = "Nights this week", store = "LK_WeeklyNights_v1_", kind = "weekly" } :: BoardDef,
}

local WEEK = 7 * 86400
local FIRST_MONDAY = 4 * 86400 -- 1970-01-05 00:00 UTC

-- The week a time falls in (weeks start Monday 00:00 UTC); the weekly board's store name ends with it
function Leaderboards.weekIndex(now: number): number
	return math.floor((now - FIRST_MONDAY) / WEEK)
end

-- The data store a board writes to at `now`
function Leaderboards.storeName(def: BoardDef, now: number): string
	return if def.kind == "weekly" then def.store .. Leaderboards.weekIndex(now) else def.store
end

return Leaderboards
