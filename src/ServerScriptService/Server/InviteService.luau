--!strict
-- InviteService (S7.5, LiveOps domain): the invite reward. A player who joins from another player's invite (Roblox
-- join data: ReferredByPlayerId) and then survives at least one night in the same voyage as them earns the
-- "Shared Lantern" beam colour, and so does the player who invited them. It is a GrantService claim per pair,
-- "invite:<lower id>:<higher id>", so each pair is rewarded once, however many voyages they share.

local InviteService = {}

InviteService.ITEM = "BeamSharedLantern"

export type Deps = {
	subscribe: (name: string, handler: (any) -> ()) -> any,
	referrerOf: (userId: number) -> number?,
	byUserIds: (ids: { number }) -> { any },
	grant: (player: any, claimId: string, rewards: any, source: string) -> string,
	notify: (player: any, text: string) -> (),
	nameOf: (player: any) -> string,
}

function InviteService.claimId(a: number, b: number): string
	return string.format("invite:%d:%d", math.min(a, b), math.max(a, b))
end

function InviteService.start(deps: Deps)
	deps.subscribe("VoyageEnded", function(e)
		if (e.NightReached or 0) < 1 then
			return -- the pair has to keep the light through at least one night together
		end
		local crew: { number } = e.Crew or {}
		for _, invitee in crew do
			local inviter = deps.referrerOf(invitee)
			if inviter and inviter ~= invitee and table.find(crew, inviter) then
				local claim = InviteService.claimId(invitee, inviter)
				local players = deps.byUserIds({ invitee, inviter })
				for _, player in players do
					if deps.grant(player, claim, { Items = { [InviteService.ITEM] = 1 } }, "invite") == "granted" then
						local other = nil
						for _, p in players do
							if p ~= player then
								other = p
							end
						end
						deps.notify(player, string.format("You sailed with %s: the Shared Lantern beam colour is yours! Equip it from your BAG.", if other then deps.nameOf(other) else "your friend"))
					end
				end
			end
		end
	end)
end

return InviteService
