--!strict
-- S2.3: Night-1 safety. A first-voyage crew's first Night-1 blackout is caught once by the reserve.
return function(T: any)
	local NightSafety = T.require(game.ServerScriptService.Server.NightSafety)
	local Config = T.require(game.ReplicatedStorage.Shared.Config)

	-- Lamp model with the live numbers (LampService: drain only at night, wide beam, crew-size multiplier;
	-- GameState: a night is lost after DARK_GRACE_SECONDS of darkness). Nobody carries oil.
	-- Returns the last night survived.
	local function nightsSurvived(startFuel: number, crewRuns: { number }): number
		local fuel = startFuel
		local used = false
		local rate = Config.FUEL_DRAIN_PER_SECOND * Config.FUEL_DRAIN_BY_CREW_SIZE[math.clamp(#crewRuns, 1, 4)]
		local dt = 0.2
		for night = 1, 7 do
			local dark = 0
			local t = 0
			while t < Config.NIGHT_SECONDS do
				if NightSafety.shouldRefill(night, fuel, used, crewRuns) then
					used = true
					fuel = Config.MAX_FUEL
				end
				fuel = math.max(0, fuel - rate * dt)
				dark = if fuel <= 0 then dark + dt else 0
				if dark >= Config.DARK_GRACE_SECONDS then
					return night - 1
				end
				t += dt
			end
		end
		return 7
	end

	T.describe("shouldRefill", function()
		T.it("only on Night 1, at a blackout, once, for a crew with a first voyager", function()
			T.expect(NightSafety.shouldRefill(1, 0, false, { 0 })).toBe(true)
			T.expect(NightSafety.shouldRefill(1, 0, false, { 3, 0 })).toBe(true)
			T.expect(NightSafety.shouldRefill(1, 0.5, false, { 0 })).toBe(false) -- still lit
			T.expect(NightSafety.shouldRefill(1, 0, true, { 0 })).toBe(false) -- already used this voyage
			T.expect(NightSafety.shouldRefill(2, 0, false, { 0 })).toBe(false) -- later night
			T.expect(NightSafety.shouldRefill(0, 0, false, { 0 })).toBe(false) -- prologue
			T.expect(NightSafety.shouldRefill(1, 0, false, { 1 })).toBe(false) -- 1-run player
			T.expect(NightSafety.shouldRefill(1, 0, false, { 1, 4 })).toBe(false)
			T.expect(NightSafety.shouldRefill(1, 0, false, {})).toBe(false)
		end)
	end)

	T.describe("with the live lamp numbers, nobody carrying oil", function()
		T.it("a 0-run solo player whose lamp is empty at nightfall survives Night 1 once and loses Night 2", function()
			T.expect(nightsSurvived(0, { 0 })).toBe(1)
		end)

		T.it("a 1-run solo player gets no refill and loses Night 1", function()
			T.expect(nightsSurvived(0, { 1 })).toBe(0)
		end)

		T.it("a blackout late in Night 1 is caught too; a full crew of first voyagers also reaches dawn 1", function()
			T.expect(nightsSurvived(40, { 0 })).toBe(1)
			T.expect(nightsSurvived(0, { 0, 0, 0, 0 })).toBe(1)
		end)
	end)
end
