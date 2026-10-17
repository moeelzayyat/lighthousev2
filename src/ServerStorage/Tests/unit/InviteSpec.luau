--!strict
-- S7.5: a player who joined from an invite and their inviter both get the Shared Lantern after a voyage together,
-- once per pair (idempotent), however many voyages they share.
return function(T: any)
	local InviteService = T.require(game.ServerScriptService.Server.InviteService)
	local GrantService = T.require(game.ServerScriptService.Server.GrantService)
	local Items = T.require(game.ReplicatedStorage.Shared.Items)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)

	local function source(inst: Instance): string
		return (inst :: any).Source
	end

	-- two players with real profile tables; grants go through GrantService.apply (the claim logic itself)
	local function world(referrers: { [number]: number })
		local profiles: { [number]: any } = {}
		local players: { [number]: any } = {}
		for _, id in { 1, 2, 3 } do
			profiles[id] = { Pearls = 0, Owned = {}, Counts = {}, Grants = {} }
			players[id] = { UserId = id, DisplayName = "P" .. id }
		end
		local w = { handler = nil :: any, notes = {} :: { string }, profiles = profiles }
		InviteService.start({
			subscribe = function(_name: string, h: (any) -> ())
				w.handler = h
				return nil
			end,
			referrerOf = function(userId: number)
				return referrers[userId]
			end,
			byUserIds = function(ids: { number })
				local list = {}
				for _, id in ids do
					table.insert(list, players[id])
				end
				return list
			end,
			grant = function(player: any, claimId: string, rewards: any, _source: string)
				return (GrantService.apply(profiles[player.UserId], claimId, rewards, 1000))
			end,
			notify = function(player: any, text: string)
				table.insert(w.notes, player.UserId .. ": " .. text)
			end,
			nameOf = function(player: any)
				return player.DisplayName
			end,
		})
		return w
	end

	T.describe("the reward", function()
		T.it("is a beam colour that is earned, never sold, and passes the registry", function()
			local item = Items.BeamSharedLantern
			T.expect(item.kind).toBe("Cosmetic")
			T.expect(item.price).toBe(nil)
			T.expect(item.reward).toBe("invite")
			local problems = {}
			for _, p in Registry.check(Registry.catalogs()) do
				if string.sub(p, 1, 6) == "Items." then
					table.insert(problems, p)
				end
			end
			T.expect(problems).toEqual({})
		end)
	end)

	T.describe("sharing a voyage", function()
		T.it("both get it once per pair, however many voyages they share", function()
			local w = world({ [2] = 1 }) -- player 2 joined from player 1's invite
			for _ = 1, 3 do
				w.handler({ Crew = { 1, 2, 3 }, NightReached = 2, Outcome = "Defeat" })
			end
			T.expect(w.profiles[1].Owned.BeamSharedLantern).toBe(true)
			T.expect(w.profiles[2].Owned.BeamSharedLantern).toBe(true)
			T.expect(w.profiles[3].Owned.BeamSharedLantern).toBe(nil) -- in the crew, but not part of the pair
			T.expect(#w.notes).toBe(2)
			T.expect(w.notes[1]).toContain("You sailed with P")
			T.expect(w.profiles[1].Grants["invite:1:2"] ~= nil).toBe(true)
		end)

		T.it("needs the inviter aboard and at least one night together", function()
			local w = world({ [2] = 1 })
			w.handler({ Crew = { 2, 3 }, NightReached = 5, Outcome = "Victory" }) -- inviter not in this crew
			w.handler({ Crew = { 1, 2 }, NightReached = 0, Outcome = "Abandoned" }) -- quit before night 1
			T.expect(w.profiles[2].Owned.BeamSharedLantern).toBe(nil)
			local nobody = world({})
			nobody.handler({ Crew = { 1, 2 }, NightReached = 3, Outcome = "Defeat" })
			T.expect(nobody.profiles[1].Owned.BeamSharedLantern).toBe(nil)
		end)

		T.it("the claim id is the same whichever of the two is first", function()
			T.expect(InviteService.claimId(9, 4)).toBe(InviteService.claimId(4, 9))
		end)
	end)

	T.describe("wiring", function()
		T.it("LiveOps reads the join data and starts it", function()
			local liveOps = source(game.ServerScriptService.Server.Domains.LiveOps)
			T.expect(liveOps).toContain("joinData.ReferredByPlayerId")
			T.expect(liveOps).toContain("InviteService.start({")
		end)
	end)
end
