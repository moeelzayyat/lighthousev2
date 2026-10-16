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

-- Pearls banked at the dawn after night n (S2.2): the per-night part of pearlsFor, granted as each night is
-- survived, so the dawns of a voyage add up to the night Pearls pearlsFor counts.
function Voyage.dawnPearls(night: number, config: PearlConfig): number
	return (config.PEARLS_PER_NIGHT or 0) + (config.PEARLS_NIGHT_STEP or 0) * night
end

-- What Results still pays after dawn banking: the voyage's pearlsFor less what was banked (never negative).
-- A win leaves the victory bonus; a loss leaves nothing unless the player missed a dawn.
function Voyage.resultPearls(night: number, won: boolean, banked: number, config: PearlConfig): number
	return math.max(0, Voyage.pearlsFor(night, won, config) - banked)
end

-- Claim id of one dawn grant (architecture §2.4): voyageId:night<n>:userId
function Voyage.dawnClaimId(voyageId: string, night: number, userId: number): string
	return voyageId .. ":night" .. night .. ":" .. userId
end

return Voyage
