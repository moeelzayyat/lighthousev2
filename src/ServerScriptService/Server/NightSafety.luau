--!strict
-- NightSafety (S2.3, Encounter domain): the Night-1 safety reserve for first voyages (architecture §3). Pure.
-- On the first blackout of Night 1, when a sailing crew member has never completed a voyage (Stats.Runs == 0),
-- the emergency reserve refills the lamp once (to its maximum). Never on a later night, never twice in a voyage,
-- never for a crew whose members have all completed a voyage. GameState applies it; the crew feed and the coach
-- (Coach client) then point the player at the oil barrels.

local NightSafety = {}

-- crewRuns: each sailing member's completed voyages (unknown counts as 0, as the coach treats it).
function NightSafety.shouldRefill(night: number, fuel: number, used: boolean, crewRuns: { number }): boolean
	if night ~= 1 or used or fuel > 0 then
		return false
	end
	for _, runs in crewRuns do
		if runs <= 0 then
			return true
		end
	end
	return false
end

return NightSafety
