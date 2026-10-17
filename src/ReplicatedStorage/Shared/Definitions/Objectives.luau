--!strict
-- Definitions/Objectives (S7.2): the daily objective pool. Each player gets one objective a day (UTC), picked
-- from the pool by their account and the date; finishing it pays a few Pearls once. No streak and no penalty:
-- a missed day changes nothing (architecture §13, rule 10: no anxiety mechanics). Rewards: D-026.
--   event    the bus event that counts toward it (each one adds 1)
--   reach    the event carries a value to reach instead (NightSurvived: the night number)
--   target   what finishes it
--   reward   Pearls (GrantService claim "objective:<day>:<id>")

export type ObjectiveDef = { id: string, displayName: string, event: string, target: number, reward: number, reach: boolean? }

local Objectives = {
	ORDER = { "DeliverOil", "SurviveNight4", "BuildCannons", "RepairTower", "DefeatCreatures" },

	DeliverOil = { id = "DeliverOil", displayName = "Deliver 10 oil to the lamp", event = "Refuelled", target = 10, reward = 3 } :: ObjectiveDef,
	SurviveNight4 = { id = "SurviveNight4", displayName = "Survive night 4", event = "NightSurvived", target = 4, reward = 4, reach = true } :: ObjectiveDef,
	BuildCannons = { id = "BuildCannons", displayName = "Build 2 cannons", event = "CannonBuilt", target = 2, reward = 3 } :: ObjectiveDef,
	RepairTower = { id = "RepairTower", displayName = "Repair the tower 5 times", event = "TowerRepaired", target = 5, reward = 3 } :: ObjectiveDef,
	DefeatCreatures = { id = "DefeatCreatures", displayName = "Defeat 40 creatures", event = "CreatureKilled", target = 40, reward = 3 } :: ObjectiveDef,
}

-- The UTC day an objective belongs to
function Objectives.dayKey(now: number): string
	return os.date("!%Y-%m-%d", now) :: string
end

-- Today's objective for an account: the same all day, spread over the pool by account and date
function Objectives.pick(userId: number, dayKey: string): string
	local h = 2166136261
	local s = dayKey .. ":" .. tostring(userId)
	for i = 1, #s do
		h = bit32.bxor(h, string.byte(s, i))
		h = (bit32.lshift(h, 24) + h * 403) % 2 ^ 32
	end
	return Objectives.ORDER[h % #Objectives.ORDER + 1]
end

-- Brings a profile's `Objectives` to the day of `now`: a new day starts a fresh objective (nothing else changes)
function Objectives.rollOver(state: any, userId: number, now: number): string
	local day = Objectives.dayKey(now)
	if state.DayKey ~= day then
		state.DayKey = day
		state.Progress = {}
		state.Claimed = {}
	end
	return Objectives.pick(userId, day)
end

-- Counts one event toward today's objective. Returns the objective id when this event finished it (once).
function Objectives.count(state: any, userId: number, now: number, eventName: string, amount: number): string?
	local id = Objectives.rollOver(state, userId, now)
	local def = (Objectives :: any)[id] :: ObjectiveDef
	if def.event ~= eventName or state.Claimed[id] then
		return nil
	end
	local before = state.Progress[id] or 0
	local progress = math.min(def.target, if def.reach then math.max(before, amount) else before + amount)
	state.Progress[id] = progress
	if progress >= def.target then
		state.Claimed[id] = true
		return id
	end
	return nil
end

return Objectives
