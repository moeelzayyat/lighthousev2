--!strict
-- R1.3: schema v2 validation, v1 -> v2 migration on fixtures, and GrantService idempotency.
return function(T: any)
	local ProfileSchema = T.require(game.ServerScriptService.Server.ProfileSchema)
	local MigrationService = T.require(game.ServerScriptService.Server.MigrationService)
	local GrantService = T.require(game.ServerScriptService.Server.GrantService)
	local fixtures = T.require(game.ServerStorage.Tests.fixtures.profiles.v1)

	local function clone(t: any): any
		if type(t) ~= "table" then
			return t
		end
		local c = {}
		for k, v in t do
			c[k] = clone(v)
		end
		return c
	end

	T.describe("schema v2", function()
		T.it("a fresh template validates with no fixes and owns the starters", function()
			local data, fixes = ProfileSchema.validate(ProfileSchema.template())
			T.expect(#fixes).toBe(0)
			T.expect(data.SchemaVersion).toBe(2)
			T.expect(data.Pearls).toBe(0)
			T.expect(data.Owned.DriftwoodHarpoon).toBe(true)
			T.expect(data.Owned.OilskinCoat).toBe(true)
			T.expect(data.Owned.BeamAmber).toBe(true)
			T.expect(data.Equipped).toEqual({ Weapon = "DriftwoodHarpoon", Armor = "OilskinCoat", Beam = "BeamAmber" })
		end)

		T.it("repairs wrong types with the default and lists every fix", function()
			local bad = ProfileSchema.template() :: any
			bad.Pearls = "25"
			bad.Stats.Runs = -1
			bad.Counts.FireShellCrate = 2.5
			bad.Equipped.Weapon = "StormHarpoon" -- not owned
			bad.Settings.Shake = "yes"
			local data, fixes = ProfileSchema.validate(bad)
			T.expect(data.Pearls).toBe(0)
			T.expect(data.Stats.Runs).toBe(0)
			T.expect(data.Counts.FireShellCrate).toBeNil()
			T.expect(data.Equipped.Weapon).toBe("DriftwoodHarpoon")
			T.expect(data.Settings.Shake).toBe(true)
			T.expect(#fixes).toBe(5)
		end)

		T.it("a non-table profile becomes a fresh template", function()
			local data, fixes = ProfileSchema.validate("garbage")
			T.expect(data.SchemaVersion).toBe(2)
			T.expect(#fixes).toBe(1)
		end)
	end)

	T.describe("migration v1 -> v2 (fixtures)", function()
		T.it("a full v1 profile keeps its values", function()
			local data, fixes = MigrationService.upgrade(clone(fixtures.full))
			T.expect(fixes[1]).toBe("migrated v1 -> v2")
			T.expect(#fixes).toBe(1)
			T.expect(data.Pearls).toBe(37)
			T.expect(data.Owned.StormHarpoon).toBe(true)
			T.expect(data.Counts.FireShellCrate).toBe(3)
			T.expect(data.Equipped.Weapon).toBe("StormHarpoon")
			T.expect(data.Stats.Runs).toBe(12)
			T.expect(data.Stats.Victories).toBe(2)
			T.expect(data.Stats.BestNight).toBe(13)
			T.expect(data.SchemaVersion).toBe(2)
		end)

		T.it("missing fields get defaults", function()
			local data = MigrationService.upgrade(clone(fixtures.missingFields))
			T.expect(data.Pearls).toBe(5)
			T.expect(data.Equipped.Beam).toBe("BeamAmber")
			T.expect(data.Stats.Victories).toBe(0)
			T.expect(data.Stats.BestNight).toBe(2)
		end)

		T.it("pearls = \"25\" (string) becomes the default and is reported", function()
			local data, fixes = MigrationService.upgrade(clone(fixtures.stringPearls))
			T.expect(data.Pearls).toBe(0)
			local found = false
			for _, f in fixes do
				if string.find(f, "^Pearls") then
					found = true
				end
			end
			T.expect(found).toBe(true)
			T.expect(data.Counts.FireShellCrate).toBeNil() -- negative count dropped
			T.expect(data.Counts.NoSuchItem).toBeNil() -- unknown item dropped
			T.expect(data.Equipped.Weapon).toBe("DriftwoodHarpoon") -- not owned -> starter
			T.expect(data.Stats.Runs).toBe(0)
		end)

		T.it("unknown fields are preserved", function()
			local data = MigrationService.upgrade(clone(fixtures.unknownFields)) :: any
			T.expect(data.futureThing).toEqual({ a = 1 })
		end)

		T.it("a v2 profile passes through upgrade unchanged", function()
			local v2 = ProfileSchema.template()
			v2.Pearls = 12
			local before = clone(v2)
			local data, fixes = MigrationService.upgrade(v2)
			T.expect(#fixes).toBe(0)
			T.expect(data).toEqual(before)
		end)
	end)

	T.describe("GrantService", function()
		T.it("the same claimId twice grants once", function()
			local data = ProfileSchema.template()
			T.expect(GrantService.apply(data, "v1:night1:42", { Pearls = 1 }, 1000)).toBe("granted")
			T.expect(GrantService.apply(data, "v1:night1:42", { Pearls = 1 }, 1001)).toBe("duplicate")
			T.expect(data.Pearls).toBe(1)
			T.expect(data.Grants["v1:night1:42"]).toBe(1000)
		end)

		T.it("many different claims each grant once (serialised)", function()
			local data = ProfileSchema.template()
			for i = 1, 13 do
				GrantService.apply(data, "v:" .. i, { Pearls = 1 }, 1000)
				GrantService.apply(data, "v:" .. i, { Pearls = 1 }, 1000)
			end
			T.expect(data.Pearls).toBe(13)
		end)

		T.it("items: gear becomes owned, stackables are counted", function()
			local data = ProfileSchema.template()
			GrantService.apply(data, "boss:1", { Items = { StormHarpoon = 1, FireShellCrate = 2 } }, 1)
			T.expect(data.Owned.StormHarpoon).toBe(true)
			T.expect(data.Counts.FireShellCrate).toBe(2)
		end)

		T.it("invalid rewards change nothing and record no claim", function()
			local data = ProfileSchema.template()
			T.expect(GrantService.apply(data, "x", { Pearls = -5 }, 1)).toBe("invalid")
			T.expect(GrantService.apply(data, "x", { Pearls = 1.5 }, 1)).toBe("invalid")
			T.expect(GrantService.apply(data, "x", { Items = { NoSuchItem = 1 } }, 1)).toBe("invalid")
			T.expect(GrantService.apply(data, "", { Pearls = 1 }, 1)).toBe("invalid")
			T.expect(data.Pearls).toBe(0)
			T.expect(next(data.Grants)).toBeNil()
		end)

		T.it("claim ids older than 30 days are pruned on the next grant", function()
			local data = ProfileSchema.template()
			GrantService.apply(data, "old", { Pearls = 1 }, 0)
			GrantService.apply(data, "new", { Pearls = 1 }, 31 * 86400)
			T.expect(data.Grants.old).toBeNil()
			T.expect(data.Grants.new).toBe(31 * 86400)
		end)
	end)
end
