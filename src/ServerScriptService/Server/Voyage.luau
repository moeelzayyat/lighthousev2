--!strict
-- Voyage (R1.2): pure Pearl rules, no Instances. Extracted from GameState.run with identical
-- arithmetic (docs/STATS.md "Pearl rules"). Per-award Pearls stay with the caller.
-- Encounter domain; moves under Domains/Encounter at S5.

local Voyage = {}

export type PearlConfig = {
	PEARLS_PER_NIGHT: number?,
	PEARLS_NIGHT_STEP: number?, -- old triangular step (night N gives N); 0 = off
	PEARLS_VICTORY_BONUS: number?,
}

-- Pearls for one player at the end of a voyage (Victory or Defeat; an abandoned voyage pays nothing).
-- night: the night reached (on a win, the final night). A loss at night n pays for n - 1 nights.
function Voyage.pearlsFor(night: number, won: boolean, config: PearlConfig): number
	local survived = if won then night else math.max(0, night - 1)
	local earned = (config.PEARLS_PER_NIGHT or 0) * survived + (config.PEARLS_NIGHT_STEP or 0) * survived * (survived + 1) / 2
	if won then
		earned += config.PEARLS_VICTORY_BONUS or 0
	end
	return earned
end

return Voyage
