--!strict
-- R1.2: WaveDirector.nightPlan / bigNights must reproduce the pre-R1.2 GameState numbers exactly.
-- REFERENCE was produced on 2026-10-16 by running a verbatim copy of GameState.luau lines 424-435
-- (854f4e9) against the live Config (NIGHTS_TO_WIN 13): "crabs/skitters" for crew 1..4.

local REFERENCE: { [string]: { [number]: { string } } } = {
	none = {
		[1] = { "14/17", "14/27", "14/36", "14/42" },
		[4] = { "34/33", "34/53", "34/70", "34/82" },
		[7] = { "46/42", "46/69", "46/90", "46/106" },
		[10] = { "58/52", "58/85", "58/111", "58/130" },
		[13] = { "105/62", "105/100", "105/131", "105/154" },
	},
	SpringTide = {
		[1] = { "20/24", "20/38", "20/50", "20/59" },
		[4] = { "48/46", "48/75", "48/98", "48/115" },
		[7] = { "64/59", "64/96", "64/126", "64/148" },
		[10] = { "81/73", "81/118", "81/155", "81/182" },
		[13] = { "147/86", "147/140", "147/183", "147/216" },
	},
}
-- FogBank and LeakyStores do not change spawn counts: they must equal "none".
REFERENCE.FogBank = REFERENCE.none
REFERENCE.LeakyStores = REFERENCE.none

return function(T: any)
	local WaveDirector = T.require(game.ServerScriptService.Server.WaveDirector)
	local Config = T.require(game.ReplicatedStorage.Shared.Config)
	local Forecasts = T.require(game.ReplicatedStorage.Shared.Forecasts)

	local function withConfig(overrides: { [string]: any }): any
		local c = table.clone(Config)
		for k, v in overrides do
			c[k] = v
		end
		return c
	end

	T.describe("nightPlan", function()
		for _, forecastId in { "none", "FogBank", "SpringTide", "LeakyStores" } do
			T.it("matches today's numbers: nights 1/4/7/10/13 x crew 1-4, forecast " .. forecastId, function()
				local forecast = if forecastId == "none" then nil else Forecasts[forecastId]
				for night, row in REFERENCE[forecastId] do
					for crew = 1, 4 do
						local plan = WaveDirector.nightPlan(night, crew, forecast, Config)
						local got = plan.crabs .. "/" .. plan.skitters
						if got ~= row[crew] then
							error(string.format("night %d crew %d %s: expected %s, got %s", night, crew, forecastId, row[crew], got))
						end
					end
				end
			end)
		end

		T.it("clamps the crew size to 1..4", function()
			T.expect(WaveDirector.nightPlan(1, 0, nil, Config).skitters).toBe(17)
			T.expect(WaveDirector.nightPlan(1, 9, nil, Config).skitters).toBe(42)
		end)

		T.it("has no skitters when the swarm is switched off", function()
			local plan = WaveDirector.nightPlan(4, 4, nil, withConfig({ SWARM_ENABLED = false }))
			T.expect(plan.skitters).toBe(0)
			T.expect(plan.crabs).toBe(34)
		end)

		T.it("applies the final-night crisis multiplier only on the final night", function()
			T.expect(WaveDirector.nightPlan(12, 4, nil, Config).crabs).toBe(66)
			T.expect(WaveDirector.nightPlan(7, 4, nil, withConfig({ NIGHTS_TO_WIN = 7 })).crabs).toBe(69)
		end)

		T.it("growth is full to night 3, then half rate", function()
			T.expect(WaveDirector.growth(1, Config)).toBe(0)
			T.expect(WaveDirector.growth(3, Config)).toBe(2)
			T.expect(WaveDirector.growth(5, Config)).toBe(3)
			T.expect(WaveDirector.growth(13, Config)).toBe(7)
		end)
	end)

	T.describe("bigNights", function()
		T.it("13 nights: 13, 10, 7, 4 in pick order", function()
			T.expect(WaveDirector.bigNights(Config)).toEqual({ 13, 10, 7, 4 })
			T.expect(WaveDirector.nightPlan(4, 1, nil, Config).boss).toBe(true)
			T.expect(WaveDirector.nightPlan(5, 1, nil, Config).boss).toBeNil()
		end)

		T.it("respects MAX_BIG_PER_RUN and BIG_MONSTERS_ENABLED", function()
			T.expect(WaveDirector.bigNights(withConfig({ MAX_BIG_PER_RUN = 2 }))).toEqual({ 13, 10 })
			T.expect(WaveDirector.bigNights(withConfig({ BIG_MONSTERS_ENABLED = false }))).toEqual({})
		end)

		T.it("short runs (5 nights or fewer): the middle and the final night", function()
			T.expect(WaveDirector.bigNights(withConfig({ NIGHTS_TO_WIN = 5 }))).toEqual({ 3, 5 })
			T.expect(WaveDirector.bigNights(withConfig({ NIGHTS_TO_WIN = 3 }))).toEqual({ 2, 3 })
		end)

		T.it("a 7-night run gets 7 and 4 (D-003 Standard Voyage schedule)", function()
			T.expect(WaveDirector.bigNights(withConfig({ NIGHTS_TO_WIN = 7 }))).toEqual({ 7, 4 })
		end)
	end)
end
