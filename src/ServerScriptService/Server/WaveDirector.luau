--!strict
-- WaveDirector (R1.2): pure night planning, no Instances, no randomness.
-- Extracted from GameState.run with identical arithmetic (docs/STATS.md "Night plan").
-- Encounter domain; moves under Domains/Encounter at S5.

local WaveDirector = {}

-- The subset of Shared/Config this module reads (all optional where GameState had defaults).
export type WaveConfig = {
	NIGHTS_TO_WIN: number,
	CRABS_BASE: number,
	CRABS_PER_NIGHT: number,
	FINAL_NIGHT_CRAB_MULTIPLIER: number,
	GROWTH_FULL_UNTIL: number?,
	GROWTH_LATE_RATE: number?,
	SWARM_ENABLED: boolean?,
	SWARM_BASE: number?,
	SWARM_PER_NIGHT: number?,
	SWARM_BY_CREW: { number }?,
	BIG_MONSTERS_ENABLED: boolean?,
	BIG_EVERY_NIGHTS: number?,
	MAX_BIG_PER_RUN: number?,
}

-- A forecast definition (Shared/Forecasts entry) or nil; only crabMult affects the plan.
export type ForecastDef = { crabMult: number? }

export type NightPlan = {
	crabs: number, -- Rock Crabs in the wave
	skitters: number, -- Sand Skitters in the swarm (0 when SWARM_ENABLED is false)
	boss: boolean?, -- true on a scheduled big-monster night (the kind is picked by the caller)
}

-- Difficulty steps: full growth up to GROWTH_FULL_UNTIL, then GROWTH_LATE_RATE per night (owner, Oct 13).
function WaveDirector.growth(night: number, config: WaveConfig): number
	local fullUntil = config.GROWTH_FULL_UNTIL or math.huge
	return if night <= fullUntil then night - 1 else (fullUntil - 1) + (night - fullUntil) * (config.GROWTH_LATE_RATE or 1)
end

-- Nights that get a big monster: short runs the middle and final night; long runs (more than 5 nights)
-- every BIG_EVERY_NIGHTS counting back from the final night (13 -> 13, 10, 7, 4); at most MAX_BIG_PER_RUN.
-- Returned in pick order (the order GameState consumes random kinds in).
function WaveDirector.bigNights(config: WaveConfig): { number }
	local candidates: { number } = {}
	local every = config.BIG_EVERY_NIGHTS or 0
	if config.NIGHTS_TO_WIN > 5 and every > 0 then
		local n = config.NIGHTS_TO_WIN
		while n >= 2 do
			table.insert(candidates, n)
			n -= every
		end
	else
		candidates = { math.max(1, math.ceil(config.NIGHTS_TO_WIN / 2)), config.NIGHTS_TO_WIN }
	end
	local picked: { number } = {}
	local seen: { [number]: boolean } = {}
	for _, n in candidates do
		if config.BIG_MONSTERS_ENABLED and #picked < (config.MAX_BIG_PER_RUN or 0) and not seen[n] then
			seen[n] = true
			table.insert(picked, n)
		end
	end
	return picked
end

-- Spawn counts for one night. crewSize is the raw ready-player count (clamped to 1..4 here).
function WaveDirector.nightPlan(night: number, crewSize: number, forecast: ForecastDef?, config: WaveConfig): NightPlan
	local growth = WaveDirector.growth(night, config)
	local crabMult = if forecast and forecast.crabMult then forecast.crabMult else 1
	local crabs = math.floor((config.CRABS_BASE + config.CRABS_PER_NIGHT * growth) * crabMult + 0.5)
	if night == config.NIGHTS_TO_WIN then
		crabs = math.floor(crabs * config.FINAL_NIGHT_CRAB_MULTIPLIER)
	end
	local crew = math.clamp(crewSize, 1, 4)
	local crewShare = (config.SWARM_BY_CREW and config.SWARM_BY_CREW[crew]) or 1
	local skitters = math.floor(((config.SWARM_BASE or 0) + (config.SWARM_PER_NIGHT or 0) * growth) * crewShare * crabMult + 0.5)
	if not config.SWARM_ENABLED then
		skitters = 0
	end
	local boss: boolean? = nil
	if table.find(WaveDirector.bigNights(config), night) then
		boss = true
	end
	return { crabs = crabs, skitters = skitters, boss = boss }
end

return WaveDirector
