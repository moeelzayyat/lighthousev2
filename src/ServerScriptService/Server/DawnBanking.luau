--!strict
-- DawnBanking (S2.2, Economy domain): a bus consumer. At each dawn (NightSurvived) every crew member is granted
-- that night's Pearls through GrantService, saved at once (architecture §2.4). A player who leaves at night 5 keeps
-- the 4 Pearls banked at dawns 1-4. The claim id voyageId:night<n>:userId makes a repeated dawn grant once.
-- Results then pays only what is still owed (Voyage.resultPearls): the victory bonus, or nothing on a loss.

local Voyage = require(script.Parent.Voyage)

local DawnBanking = {}

type Bus = {
	Subscribe: (name: string, handler: ({ [string]: any }) -> ()) -> () -> (),
}

export type Deps = {
	-- grants to an online player; returns GrantService's status ("granted" | "duplicate" | "invalid")
	grant: (userId: number, claimId: string, rewards: { Pearls: number }) -> string,
	-- tells the player's client "+N Pearl banked"
	notify: (userId: number, amount: number) -> (),
	config: Voyage.PearlConfig,
}

-- voyageId -> userId -> night -> Pearls banked that dawn (a replayed dawn overwrites, never adds)
local banked: { [string]: { [number]: { [number]: number } } } = {}

-- Pearls banked for a player on a voyage so far.
function DawnBanking.bankedFor(voyageId: string, userId: number): number
	local nights = banked[voyageId] and banked[voyageId][userId]
	local total = 0
	if nights then
		for _, amount in nights do
			total += amount
		end
	end
	return total
end

-- Drops a finished voyage's tally (called after its Results are paid).
function DawnBanking.forget(voyageId: string)
	banked[voyageId] = nil
end

-- One dawn: grants the night's Pearls to each crew member and records what was banked.
function DawnBanking.bank(voyageId: string, night: number, crew: { number }, deps: Deps)
	local amount = Voyage.dawnPearls(night, deps.config)
	if amount <= 0 then
		return
	end
	for _, userId in crew do
		local status = deps.grant(userId, Voyage.dawnClaimId(voyageId, night, userId), { Pearls = amount })
		if status == "granted" or status == "duplicate" then
			local voyage = banked[voyageId] or {}
			banked[voyageId] = voyage
			local nights = voyage[userId] or {}
			voyage[userId] = nights
			nights[night] = amount
		end
		if status == "granted" then
			deps.notify(userId, amount)
		end
	end
end

-- Subscribes to NightSurvived. Returns the unsubscribe function.
function DawnBanking.start(bus: Bus, deps: Deps): () -> ()
	return bus.Subscribe("NightSurvived", function(e)
		DawnBanking.bank(e.VoyageId, e.Night, e.Crew, deps)
	end)
end

return DawnBanking
