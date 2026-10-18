--!strict
-- MAP.1 (D-049): the second map, Frostbite Isle, and shared crew unlocks. The catalog passes the registry; any crew
-- member's unlock lets the whole crew choose a map, nobody's means the home isle; the harbor sends the map to the
-- isle and the isle only trusts known ids; old saves get the unlock from an earlier Standard win.
return function(T: any)
	local Maps = T.require(game.ReplicatedStorage.Shared.Definitions.Maps)
	local Voyages = T.require(game.ReplicatedStorage.Shared.Definitions.Voyages)
	local Forecasts = T.require(game.ReplicatedStorage.Shared.Forecasts)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)
	local IsleArrival = T.require(game.ServerScriptService.Server.IsleArrival)
	local ProfileSchema = T.require(game.ServerScriptService.Server.ProfileSchema)

	local function holds(keys: { string }): (string) -> boolean
		return function(key: string): boolean
			return table.find(keys, key) ~= nil
		end
	end

	T.describe("maps", function()
		T.it("pass the registry; the home isle needs no unlock and Frostbite Isle comes from a Standard win", function()
			local problems = {}
			for _, p in Registry.check(Registry.catalogs()) do
				if string.sub(p, 1, 5) == "Maps." then
					table.insert(problems, p)
				end
			end
			T.expect(problems).toEqual({})
			T.expect(Maps.DEFAULT).toBe("LighthouseIsle")
			T.expect(Maps.FrostIsle.unlock).toBe("FrostIsle")
			T.expect(Voyages[Maps.FrostIsle.grantedBy].id).toBe("Standard")
		end)

		T.it("shared crew unlock: one member's unlock opens the map for the whole crew", function()
			T.expect(Maps.availableFor(holds({}))).toEqual({ "LighthouseIsle" })
			T.expect(Maps.availableFor(holds({ "FrostIsle" }))).toEqual({ "LighthouseIsle", "FrostIsle" })
			T.expect(Maps.resolve("FrostIsle", holds({ "FrostIsle" }))).toBe("FrostIsle")
			T.expect(Maps.resolve("FrostIsle", holds({}))).toBe("LighthouseIsle") -- nobody aboard holds it
			T.expect(Maps.resolve("Nowhere", holds({ "FrostIsle" }))).toBe("LighthouseIsle")
			T.expect(Maps.resolve(nil, holds({}))).toBe("LighthouseIsle")
		end)

		T.it("the isle takes a known map from the harbor's teleport data and drops anything else", function()
			local known = { voyages = Voyages, forecasts = Forecasts, maps = Maps }
			local plan = IsleArrival.parse({ TeleportData = { v = 1, crew = { 1 }, voyage = "Standard", map = "FrostIsle" } }, known) :: any
			T.expect(plan.map).toBe("FrostIsle")
			local bad = IsleArrival.parse({ TeleportData = { v = 1, crew = { 1 }, map = "Moon" } }, known) :: any
			T.expect(bad.map).toBe(nil)
			local noMaps = IsleArrival.parse({ TeleportData = { v = 1, crew = { 1 }, map = "FrostIsle" } }, { voyages = Voyages, forecasts = Forecasts }) :: any
			T.expect(noMaps.map).toBe(nil)
		end)

		T.it("a new profile starts without it; an older save with a Standard win gets it", function()
			local fresh = ProfileSchema.template()
			T.expect(fresh.Unlocks.FrostIsle).toBe(false)
			local old = ProfileSchema.template() :: any
			old.Unlocks.FrostIsle = nil
			old.Unlocks.LongVoyage = true
			local fixed = ProfileSchema.validate(old)
			T.expect(fixed.Unlocks.FrostIsle).toBe(true)
		end)
	end)
end
