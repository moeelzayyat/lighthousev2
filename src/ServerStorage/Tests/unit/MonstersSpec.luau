--!strict
-- S6.5/S6.6: Spitter Eel, Puffer Mine, Ghost Lantern, Tide Witch and Coral Shaman: each warns for at least 0.6 s with its own sound, has a loot
-- table, joins the nights on a schedule, and the telegraph reaches the client in the snapshot.
return function(T: any)
	local Creatures = T.require(game.ReplicatedStorage.Shared.Creatures)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)
	local SoundFx = T.require(game.ReplicatedStorage.Shared.SoundFx)
	local Snap = T.require(game.ReplicatedStorage.Shared.CreatureSnapshot)
	local WaveDirector = T.require(game.ServerScriptService.Server.WaveDirector)

	local NEW = { "SpitterEel", "PufferMine", "GhostLantern", "TideWitch", "CoralShaman" }
	local function source(inst: Instance): string
		return (inst :: any).Source
	end

	T.describe("the monsters", function()
		T.it("pass the boot registry", function()
			local problems = {}
			for _, p in Registry.check(Registry.catalogs()) do
				if string.sub(p, 1, 10) == "Creatures." then
					table.insert(problems, p)
				end
			end
			T.expect(problems).toEqual({})
		end)

		T.it("each warns for at least 0.6 s with its own sounds and has a loot table", function()
			local seen: { [string]: boolean } = {}
			for _, id in NEW do
				local d = Creatures[id]
				T.expect(d.telegraph >= 0.6).toBe(true)
				T.expect(SoundFx.SOUNDS[d.telegraphSound] ~= nil).toBe(true)
				T.expect(SoundFx.SOUNDS[d.releaseSound] ~= nil).toBe(true)
				T.expect(seen[d.telegraphSound]).toBe(nil)
				seen[d.telegraphSound] = true
				local sum = 0
				for _, row in d.loot do
					sum += row.chance
				end
				T.expect(sum).toBeCloseTo(1)
			end
			T.expect({ Creatures.SpitterEel.behaviour, Creatures.PufferMine.behaviour, Creatures.GhostLantern.behaviour, Creatures.TideWitch.behaviour, Creatures.CoralShaman.behaviour }).toEqual({ "spitter", "mine", "ghost", "summoner", "healer" })
			T.expect(Creatures[Creatures.TideWitch.summonKind].big).toBe(false)
			T.expect(Creatures.GhostLantern.weaponImmune).toBe(true)
		end)
	end)

	T.describe("the nights they join", function()
		T.it("follow each monster's schedule", function()
			T.expect(WaveDirector.specials(1, Creatures)).toEqual({})
			T.expect(WaveDirector.specials(2, Creatures)).toEqual({ SpitterEel = 1 })
			T.expect(WaveDirector.specials(3, Creatures)).toEqual({ SpitterEel = 1, PufferMine = 2 })
			T.expect(WaveDirector.specials(5, Creatures)).toEqual({ SpitterEel = 2, PufferMine = 3, GhostLantern = 1, TideWitch = 1 })
			T.expect(WaveDirector.specials(6, Creatures)).toEqual({ SpitterEel = 3, PufferMine = 3, GhostLantern = 1, TideWitch = 1, CoralShaman = 1 })
			T.expect(WaveDirector.specials(13, Creatures)).toEqual({ SpitterEel = 4, PufferMine = 5, GhostLantern = 3, TideWitch = 2, CoralShaman = 2 })
		end)
	end)

	T.describe("the telegraph on the wire", function()
		T.it("is both target bits together and survives a round trip", function()
			T.expect(Snap.TELEGRAPH).toBe(96)
			T.expect(Snap.isTelegraph(96)).toBe(true)
			T.expect(Snap.isTelegraph(96 + Snap.MOVING + Snap.HIT)).toBe(true)
			T.expect(Snap.isTelegraph(Snap.TARGET_PLAYER)).toBe(false)
			T.expect(Snap.isTelegraph(Snap.TARGET_CANNON + Snap.DYING)).toBe(false)
			local _, list = Snap.decode(Snap.encode({ { id = 7, kind = 2, x = 1, y = 2, z = 3, yaw = 90, state = Snap.TELEGRAPH, hp = 0.5 } }, 10))
			T.expect(Snap.isTelegraph(list[1].state)).toBe(true)
		end)
	end)

	T.describe("wiring", function()
		T.it("the server runs the moves, drops the loot and spawns them; the client draws the warning", function()
			local Server = game.ServerScriptService.Server
			local creatures = source(Server.CreatureService)
			T.expect(creatures).toContain("if crab.stats.weaponImmune then")
			T.expect(creatures).toContain("if releaseMove(crab, players) then")
			T.expect(creatures).toContain("CreatureSnapshot.TELEGRAPH")
			T.expect(creatures).toContain("markSpot(spot, stats.splashRadius, stats.telegraph)")
			T.expect(source(Server.LootService)).toContain("if stats and stats.loot then")
			local gameState = source(Server.GameState)
			T.expect(gameState).toContain("WaveDirector.specials(night, Creatures)")
			T.expect(gameState).toContain("stopSpecials()")
			T.expect(source(game.StarterPlayer.StarterPlayerScripts.Client.CreatureView)).toContain("Snap.isTelegraph(state)")
		end)
	end)
end
