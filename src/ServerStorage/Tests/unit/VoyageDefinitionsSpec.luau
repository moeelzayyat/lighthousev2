--!strict
-- S2.1: voyage definitions (D-003): Standard 7 nights, Long 13 nights unlocked by a Standard win.
return function(T: any)
	local Voyages = T.require(game.ReplicatedStorage.Shared.Definitions.Voyages)
	local WaveDirector = T.require(game.ServerScriptService.Server.WaveDirector)
	local Voyage = T.require(game.ServerScriptService.Server.Voyage)
	local Config = T.require(game.ReplicatedStorage.Shared.Config)

	T.describe("definitions", function()
		T.it("every definition is well formed", function()
			for _, id in Voyages.ORDER do
				local def = Voyages[id]
				T.expect(def.id).toBe(id)
				T.expect(def.nights >= 1 and def.nights % 1 == 0).toBe(true)
				for _, n in def.bossNights do
					T.expect(n >= 1 and n <= def.nights).toBe(true)
				end
				if def.unlock then
					local granted = false
					for _, other in Voyages.ORDER do
						if Voyages[other].unlocks == def.unlock then
							granted = true
						end
					end
					T.expect(granted).toBe(true) -- something must grant every unlock
				end
			end
			T.expect(Voyages[Voyages.DEFAULT].unlock).toBeNil() -- the default needs nothing
		end)

		T.it("Standard: 7 nights, big monsters on 4 and 7", function()
			T.expect(Voyages.Standard.nights).toBe(7)
			T.expect(WaveDirector.bossNightsFor(Voyages.Standard, Config)).toEqual({ 4, 7 })
		end)

		T.it("Long: 13 nights, big monsters on 4, 7 and every night from 8", function()
			T.expect(Voyages.Long.nights).toBe(13)
			T.expect(WaveDirector.bossNightsFor(Voyages.Long, Config)).toEqual({ 4, 7, 8, 9, 10, 11, 12, 13 })
		end)

		T.it("no big monsters at all when they are switched off", function()
			local off = table.clone(Config)
			off.BIG_MONSTERS_ENABLED = false
			T.expect(WaveDirector.bossNightsFor(Voyages.Long, off)).toEqual({})
		end)
	end)

	T.describe("night plan per definition", function()
		T.it("Standard: the final-night crisis lands on night 7, bosses flagged on 4 and 7", function()
			local cfg = WaveDirector.configFor(Voyages.Standard, Config)
			T.expect(WaveDirector.nightPlan(7, 4, nil, cfg, Voyages.Standard).crabs).toBe(69) -- 46 x 1.5
			T.expect(WaveDirector.nightPlan(6, 4, nil, cfg, Voyages.Standard).crabs).toBe(42)
			T.expect(WaveDirector.nightPlan(4, 4, nil, cfg, Voyages.Standard).boss).toBe(true)
			T.expect(WaveDirector.nightPlan(5, 4, nil, cfg, Voyages.Standard).boss).toBeNil()
			T.expect(WaveDirector.nightPlan(7, 4, nil, cfg, Voyages.Standard).boss).toBe(true)
		end)

		T.it("Long: same numbers as the old 13-night run, boss every night from 8", function()
			local cfg = WaveDirector.configFor(Voyages.Long, Config)
			T.expect(WaveDirector.nightPlan(13, 4, nil, cfg, Voyages.Long).crabs).toBe(105)
			T.expect(WaveDirector.nightPlan(1, 4, nil, cfg, Voyages.Long).skitters).toBe(42)
			T.expect(WaveDirector.nightPlan(9, 1, nil, cfg, Voyages.Long).boss).toBe(true)
			T.expect(WaveDirector.nightPlan(6, 1, nil, cfg, Voyages.Long).boss).toBeNil()
		end)

		T.it("configFor changes only the length", function()
			local cfg = WaveDirector.configFor(Voyages.Standard, Config)
			T.expect(cfg.NIGHTS_TO_WIN).toBe(7)
			T.expect(cfg.CRABS_BASE).toBe(Config.CRABS_BASE)
			T.expect(Config.NIGHTS_TO_WIN).toBe(13) -- the shared Config is not modified
		end)
	end)

	T.describe("Pearls per definition", function()
		T.it("Standard win = 12, Long win = 18", function()
			T.expect(Voyage.pearlsFor(Voyages.Standard.nights, true, Config)).toBe(12)
			T.expect(Voyage.pearlsFor(Voyages.Long.nights, true, Config)).toBe(18)
		end)
	end)
end
