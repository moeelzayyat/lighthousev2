--!strict
-- S3.1b: the main-mode test (7-night Standard voyage vs Endless Storm).
return function(T: any)
	local ModeTest = T.require(game.ServerScriptService.Server.ModeTest)
	local Voyages = T.require(game.ReplicatedStorage.Shared.Definitions.Voyages)
	local WaveDirector = T.require(game.ServerScriptService.Server.WaveDirector)
	local RunCard = T.require(game.ReplicatedStorage.Shared.RunCard)
	local Config = T.require(game.ReplicatedStorage.Shared.Config)

	local ON = { MODE_TEST_ENABLED = true, MODE_TEST_START = 1000 }

	T.describe("armFor", function()
		T.it("only accounts created from the start time are in the test, and only when it is on", function()
			T.expect(ModeTest.armFor(1, 999, ON)).toBeNil()
			T.expect(ModeTest.armFor(1, 1000, ON) ~= nil).toBe(true)
			T.expect(ModeTest.armFor(1, 5000, { MODE_TEST_ENABLED = false, MODE_TEST_START = 1000 })).toBeNil()
		end)

		T.it("an account always gets the same arm", function()
			for id = 1, 50 do
				T.expect(ModeTest.armFor(id, 2000, ON)).toBe(ModeTest.armFor(id, 9000, ON))
			end
		end)

		T.it("splits accounts about 50/50", function()
			local endless = 0
			for id = 100000, 109999 do
				if ModeTest.armFor(id, 2000, ON) == "Endless" then
					endless += 1
				end
			end
			T.expect(endless > 4500 and endless < 5500).toBe(true)
		end)
	end)

	T.describe("voyageFor", function()
		T.it("Endless only when every tested member is in the Endless arm", function()
			T.expect(ModeTest.voyageFor({})).toBeNil()
			T.expect(ModeTest.voyageFor({ "Endless" })).toBe("Endless")
			T.expect(ModeTest.voyageFor({ "Endless", "Endless" })).toBe("Endless")
			T.expect(ModeTest.voyageFor({ "Endless", "Standard" })).toBeNil()
			T.expect(ModeTest.voyageFor({ "Standard" })).toBeNil()
		end)
	end)

	T.describe("Endless Storm", function()
		T.it("is test-only, endless, off the crew card, with Long's boss rule", function()
			local def = Voyages.Endless
			T.expect(def.endless).toBe(true)
			T.expect(def.testOnly).toBe(true)
			T.expect(table.find(Voyages.ORDER, "Endless")).toBeNil()
			local bosses = WaveDirector.bossNightsFor(def, Config)
			T.expect(bosses[1]).toBe(4)
			T.expect(bosses[2]).toBe(7)
			T.expect(bosses[3]).toBe(8)
			T.expect(bosses[12]).toBe(17) -- every night from 8 keeps going
		end)

		T.it("night 9 plays like Long's night 9 (same curve, no final-night crisis)", function()
			local endless = WaveDirector.nightPlan(9, 2, nil, WaveDirector.configFor(Voyages.Endless, Config), Voyages.Endless)
			local long = WaveDirector.nightPlan(9, 2, nil, WaveDirector.configFor(Voyages.Long, Config), Voyages.Long)
			T.expect(endless).toEqual(long)
		end)

		T.it("the share line gives the night reached", function()
			T.expect(RunCard.text({ result = "Defeat", nightReached = 9, totalNights = 0, voyage = "Endless", duration = 1210, crewSize = 2 }))
				.toBe("Lighthouse Keepers \u{00B7} Endless Storm: reached night 9 \u{00B7} 20:10 \u{00B7} crew of 2")
		end)
	end)
end
