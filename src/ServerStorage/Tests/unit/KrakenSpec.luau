--!strict
-- D-047: the Kraken, the final boss of every voyage that has a last night. It passes the registry, it is never a
-- random boss, it leads the last night (not on Endless), and from the shallows where it stays it can still reach
-- the tower and the beach.
return function(T: any)
	local Creatures = T.require(game.ReplicatedStorage.Shared.Creatures)
	local Config = T.require(game.ReplicatedStorage.Shared.Config)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)
	local WaveDirector = T.require(game.ServerScriptService.Server.WaveDirector)
	local Voyages = T.require(game.ReplicatedStorage.Shared.Definitions.Voyages)

	T.describe("the Kraken", function()
		T.it("passes the registry and is never a random boss", function()
			local problems = {}
			for _, p in Registry.check(Registry.catalogs()) do
				if string.find(p, "Kraken", 1, true) or string.sub(p, 1, 18) == "Creatures.BIG_POOL" then
					table.insert(problems, p)
				end
			end
			T.expect(#problems).toBe(0)
			T.expect(Config.FINAL_BOSS).toBe("Kraken")
			T.expect(Creatures.Kraken.big).toBe(true)
			T.expect(Creatures.Kraken.finalBoss).toBe(true)
			T.expect(table.find(Creatures.BIG_POOL, "Kraken")).toBe(nil)
		end)

		T.it("leads the last night of a voyage, and none on Endless or with big monsters off", function()
			T.expect(WaveDirector.finalBossNight(Voyages.Standard, Config)).toBe(7)
			T.expect(WaveDirector.finalBossNight(Voyages.Long, Config)).toBe(13)
			T.expect(WaveDirector.finalBossNight({ nights = 999, bossNights = {}, endless = true }, Config)).toBe(nil)
			local off = table.clone(Config)
			off.BIG_MONSTERS_ENABLED = false
			T.expect(WaveDirector.finalBossNight(Voyages.Standard, off)).toBe(nil)
			local none = table.clone(Config)
			none.FINAL_BOSS = nil
			T.expect(WaveDirector.finalBossNight(Voyages.Standard, none)).toBe(nil)
		end)

		T.it("stays in the water but can reach the tower and the beach", function()
			local k = Creatures.Kraken
			T.expect(k.minRadius > Config.ISLAND_RADIUS).toBe(true) -- off the island
			T.expect(k.minRadius < Config.CREATURE_SPAWN_RADIUS + 1).toBe(true) -- not counted as fled
			T.expect(Config.TOWER_ATTACK_RADIUS + k.towerRange >= k.minRadius).toBe(true) -- slams the tower from there
			T.expect(k.telegraph >= 0.6).toBe(true) -- every move is warned first
			T.expect(k.towerHit / k.attackInterval <= 1).toBe(true) -- at most 1 tower damage a second
			T.expect(math.floor(k.health * (1 + Config.FINAL_BOSS_HEALTH_PER_EXTRA * 3) + 0.5)).toBe(3360) -- a crew of 4
		end)
	end)
end
