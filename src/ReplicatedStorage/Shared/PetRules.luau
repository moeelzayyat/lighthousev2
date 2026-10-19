--!strict
-- PetRules (PET.1, D-051): the pet that flies out and brings back Shells from fallen creatures (the owner's idea,
-- 2026-10-19; the plan had "loot-collecting pet (earnable; modest range)").
--   * Earnable: sold for Pearls at the Quartermaster; also for Robux once the owner creates its developer product
--     (convenience may be sold for Robux only when it is also earnable).
--   * New players borrow one for their first Config.PET_LOAN_VOYAGES voyages. No timer is shown (no countdown
--     pressure); after that the loaner goes home and a one-line note says where to get one.
--   * It only picks up Shells (never Sea Glass, claws, Black Pearls or Pearls), one orb at a time (it flies
--     there at Config.PET_SPEED, then rests Config.PET_PICK_INTERVAL seconds), within Config.PET_RANGE studs of its owner. The server decides; clients
--     only draw it (Client/PetView).

local PetRules = {}

PetRules.LOANER = "PetPuffin"

-- The pet a player has out now, and whether it is the loaner. `equipped` is the profile's equipped pet,
-- `ownsPet` whether the player owns any pet, `runs` their finished voyages; `isPet(id)` checks the catalogue.
function PetRules.active(equipped: string?, ownsPet: boolean, runs: number, loanVoyages: number, isPet: (string) -> boolean): (string?, boolean)
	if type(equipped) == "string" and isPet(equipped) then
		return equipped, false
	end
	if not ownsPet and runs < loanVoyages then
		return PetRules.LOANER, true
	end
	return nil, false
end

-- Whether the "your puffin went home" note is due: the voyage that ended the loan has just been played
function PetRules.loanJustEnded(ownsPet: boolean, runs: number, loanVoyages: number): boolean
	return not ownsPet and runs == loanVoyages
end

export type Drop = { kind: string, position: Vector3, landed: boolean?, claimed: boolean? }

-- The Shells orb the pet fetches next: the nearest landed one within `range` of its owner that no other pet is
-- already fetching, or nil
function PetRules.pick(owner: Vector3, drops: { Drop }, range: number): number?
	local best, bestDistance = nil, range
	for index, drop in drops do
		if drop.kind == "Shells" and drop.landed and not drop.claimed then
			local distance = (drop.position - owner).Magnitude
			if distance <= bestDistance then
				best, bestDistance = index, distance
			end
		end
	end
	return best
end

return PetRules
