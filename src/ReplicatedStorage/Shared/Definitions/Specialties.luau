--!strict
-- Definitions/Specialties (S7.4): Keeper, Oiler, Engineer and Harpooner, earned only by playing the role (the
-- profile's `Roles` counters, filled from the event bus). Each rank adds a small bonus; all specialties together
-- stop at TOTAL_CAP (+15%, architecture §7.2). Nothing here is bought. Thresholds and steps: D-028.
--   role        the counter in the profile's `Roles` that earns it
--   thresholds  the count for rank 1, 2, 3
--   bonus       what each rank adds (`step`), applied where the role is played

export type SpecialtyDef = { id: string, displayName: string, role: string, thresholds: { number }, step: number, bonus: string }

local Specialties = {
	ORDER = { "Keeper", "Harpooner", "Oiler", "Engineer" },
	TOTAL_CAP = 0.15,

	Keeper = { id = "Keeper", displayName = "Keeper", role = "BeamKills", thresholds = { 50, 250, 1000 }, step = 0.02, bonus = "beam damage while you keep the lamp" } :: SpecialtyDef,
	Harpooner = { id = "Harpooner", displayName = "Harpooner", role = "WeaponKills", thresholds = { 50, 250, 1000 }, step = 0.02, bonus = "weapon damage" } :: SpecialtyDef,
	Oiler = { id = "Oiler", displayName = "Oiler", role = "OilDelivered", thresholds = { 25, 100, 300 }, step = 0.02, bonus = "walk speed" } :: SpecialtyDef,
	Engineer = { id = "Engineer", displayName = "Engineer", role = "Repairs", thresholds = { 20, 80, 250 }, step = 0.02, bonus = "tower repair" } :: SpecialtyDef,
}

-- The rank a role count earns (0 to 3)
function Specialties.rankFor(def: SpecialtyDef, count: number): number
	local rank = 0
	for i, need in def.thresholds do
		if count >= need then
			rank = i
		end
	end
	return rank
end

-- Every specialty's rank from a profile's `Roles`, with the total cap applied (ranks over it come off the last
-- specialties in ORDER first)
function Specialties.ranks(roles: { [string]: number }): { [string]: number }
	local out: { [string]: number } = {}
	local total = 0
	for _, id in Specialties.ORDER do
		local def = (Specialties :: any)[id] :: SpecialtyDef
		local rank = Specialties.rankFor(def, roles[def.role] or 0)
		while rank > 0 and total + rank * def.step > Specialties.TOTAL_CAP + 1e-9 do
			rank -= 1
		end
		out[id] = rank
		total += rank * def.step
	end
	return out
end

-- One specialty's bonus (an AdditivePct share), after the cap
function Specialties.bonus(roles: { [string]: number }, id: string): number
	local def = (Specialties :: any)[id] :: SpecialtyDef
	return (Specialties.ranks(roles)[id] or 0) * def.step
end

return Specialties
