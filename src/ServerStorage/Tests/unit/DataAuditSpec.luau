--!strict
-- L1.2: the migration chain on every saved-profile fixture. Each one loads to a valid current profile, keeps its
-- values, loads again with no further change (idempotent), and survives a DataStore-style JSON round trip.
-- The rollback drill itself is AdminDataSpec (online and offline rollback restore the snapshot).
return function(T: any)
	local HttpService = game:GetService("HttpService")
	local MigrationService = T.require(game.ServerScriptService.Server.MigrationService)
	local ProfileSchema = T.require(game.ServerScriptService.Server.ProfileSchema)
	local fixtures = game.ServerStorage.Tests.fixtures.profiles

	local function deepCopy(v: any): any
		if type(v) ~= "table" then
			return v
		end
		local out = {}
		for k, x in v do
			out[k] = deepCopy(x)
		end
		return out
	end

	local function load(name: string): any
		return deepCopy(T.require(fixtures:FindFirstChild(name) :: ModuleScript))
	end

	T.describe("every fixture", function()
		T.it("loads to a valid profile with every current field, then loads again unchanged", function()
			-- `v1` holds several v1 saves; every other module is one save
			local profiles: { [string]: any } = {}
			for _, m in fixtures:GetChildren() do
				if m:IsA("ModuleScript") then
					if m.Name == "v1" then
						for key, p in load("v1") do
							profiles["v1." .. key] = p
						end
					else
						profiles[m.Name] = load(m.Name)
					end
				end
			end
			local names = {}
			for name in profiles do
				table.insert(names, name)
			end
			table.sort(names)
			T.expect(#names >= 5).toBe(true)
			local template = ProfileSchema.template()
			for _, name in names do
				local data = MigrationService.upgrade(profiles[name])
				for field in template do
					if data[field] == nil then
						error(name .. " is missing " .. field .. " after the upgrade")
					end
				end
				local before = HttpService:JSONEncode(data)
				local again, fixes = MigrationService.upgrade(HttpService:JSONDecode(before))
				if #fixes > 0 then
					error(name .. " changed on its second load: " .. table.concat(fixes, "; "))
				end
				T.expect(again).toEqual(HttpService:JSONDecode(before))
			end
		end)

		T.it("the full B1 profile loads with no fixes and keeps every value", function()
			local saved = load("v2_full_B1")
			local data, fixes = MigrationService.upgrade(deepCopy(saved))
			T.expect(fixes).toEqual({})
			T.expect(data.Pearls).toBe(212)
			T.expect(data.Boosts).toEqual(saved.Boosts)
			T.expect(data.Roles).toEqual(saved.Roles)
			local unlocks = table.clone(saved.Unlocks)
			unlocks.FrostIsle = true -- MAP.1: saved before Frostbite Isle; its Standard win (LongVoyage) earns it
			T.expect(data.Unlocks).toEqual(unlocks)
			T.expect(data.Equipped).toEqual(saved.Equipped)
			T.expect(data.Owned.BeamSharedLantern).toBe(true)
		end)

		T.it("older fixtures keep their Pearls, items and stats", function()
			local fromV1 = MigrationService.upgrade(load("v1").full)
			T.expect(fromV1.Pearls).toBe(37)
			T.expect(fromV1.Stats.Victories).toBe(2)
			local s64 = load("v2_before_S6_4")
			local data = MigrationService.upgrade(deepCopy(s64))
			T.expect(data.Pearls).toBe(s64.Pearls)
			for id in s64.Owned do
				T.expect(data.Owned[id]).toBe(true)
			end
			T.expect(data.Stats).toEqual(s64.Stats)
			T.expect(data.Boosts).toEqual({})
			T.expect(data.Roles).toEqual({})
		end)
	end)
end
