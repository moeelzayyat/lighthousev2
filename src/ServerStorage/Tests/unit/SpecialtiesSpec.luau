--!strict
-- S7.4: specialties come only from playing the role, ranks follow the thresholds, and all of them together stop
-- at +15%.
return function(T: any)
	local Specialties = T.require(game.ReplicatedStorage.Shared.Definitions.Specialties)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)
	local SpecialtyService = T.require(game.ServerScriptService.Server.SpecialtyService)
	local ProfileSchema = T.require(game.ServerScriptService.Server.ProfileSchema)

	local function source(inst: Instance): string
		return (inst :: any).Source
	end

	T.describe("ranks", function()
		T.it("pass the registry and follow the thresholds", function()
			local problems = {}
			for _, p in Registry.check(Registry.catalogs()) do
				if string.sub(p, 1, 12) == "Specialties." then
					table.insert(problems, p)
				end
			end
			T.expect(problems).toEqual({})
			local oiler = Specialties.Oiler
			T.expect(Specialties.rankFor(oiler, 0)).toBe(0)
			T.expect(Specialties.rankFor(oiler, 24)).toBe(0)
			T.expect(Specialties.rankFor(oiler, 25)).toBe(1)
			T.expect(Specialties.rankFor(oiler, 299)).toBe(2)
			T.expect(Specialties.rankFor(oiler, 5000)).toBe(3)
		end)

		T.it("cap: every role maxed still adds +15% at most", function()
			local roles = { BeamKills = 99999, WeaponKills = 99999, OilDelivered = 99999, Repairs = 99999 }
			local ranks = Specialties.ranks(roles)
			local total = 0
			for _, id in Specialties.ORDER do
				total += Specialties.bonus(roles, id)
			end
			T.expect(total <= Specialties.TOTAL_CAP + 1e-9).toBe(true)
			T.expect(ranks).toEqual({ Keeper = 3, Harpooner = 3, Oiler = 1, Engineer = 0 })
			T.expect(Specialties.bonus(roles, "Keeper")).toBeCloseTo(0.06)
			T.expect(Specialties.bonus({ Repairs = 300 }, "Engineer")).toBeCloseTo(0.06) -- alone it is not capped
		end)
	end)

	T.describe("earning", function()
		T.it("only role events count, and a rank is recorded when its threshold is reached", function()
			local data = { Roles = {}, Unlocks = { LongVoyage = false, Specialties = {} } }
			local player = { UserId = 7 }
			local handlers: { [string]: (any) -> () } = {}
			local notes: { string } = {}
			local pushes = 0
			SpecialtyService.start({
				subscribe = function(name: string, h: (any) -> ())
					handlers[name] = h
					return nil
				end,
				byUserIds = function()
					return { player }
				end,
				mutate = function(_p: any, fn: (any) -> boolean)
					if fn(data) then
						pushes += 1
					end
					return true
				end,
				notify = function(_p: any, text: string)
					table.insert(notes, text)
				end,
			})
			for _ = 1, 24 do
				handlers.Refuelled({ UserId = 7 })
			end
			T.expect(data.Unlocks.Specialties.Oiler).toBe(nil)
			handlers.Refuelled({ UserId = 7 })
			T.expect(data.Roles.OilDelivered).toBe(25)
			T.expect(data.Unlocks.Specialties.Oiler).toBe(1)
			T.expect(notes).toEqual({ "Specialty earned: Oiler rank 1! +2% walk speed." })
			T.expect(pushes).toBe(1) -- counting alone does not push the profile
			handlers.CreatureKilled({ Source = "Weapon:DriftwoodHarpoon", KillerId = 7 })
			handlers.CreatureKilled({ Source = "FocusedBeam", KillerId = 7 })
			handlers.CreatureKilled({ Source = "Cannon", KillerId = 7 }) -- not a role kill
			handlers.TowerRepaired({ UserId = 7 })
			handlers.CannonBuilt({ UserId = 7 })
			T.expect(data.Roles).toEqual({ OilDelivered = 25, WeaponKills = 1, BeamKills = 1, Repairs = 2 })
		end)

		T.it("nothing else writes the counters or the ranks; the profile field defaults silently", function()
			local Server = game.ServerScriptService.Server
			for _, inst in Server:GetDescendants() do
				if inst:IsA("ModuleScript") and inst.Name ~= "SpecialtyService" and inst.Name ~= "ProfileSchema" then
					local s = source(inst)
					T.expect(string.find(s, "Unlocks.Specialties[", 1, true)).toBe(nil)
					T.expect(string.find(s, "data.Roles[", 1, true)).toBe(nil)
				end
			end
			local saved = ProfileSchema.template()
			saved.Roles = nil :: any
			local data, fixes = ProfileSchema.validate(saved)
			T.expect(data.Roles).toEqual({})
			T.expect(fixes).toEqual({})
		end)
	end)

	T.describe("wiring", function()
		T.it("the bonuses reach the beam, the repairs, the weapons and the walk speed", function()
			local Server = game.ServerScriptService.Server
			T.expect(source(Server.CreatureService)).toContain("keeper:GetAttribute(\"Spec_Keeper\")")
			T.expect(source(Server.TowerService)).toContain("player:GetAttribute(\"Spec_Engineer\")")
			local economy = source(Server.Domains.Economy)
			T.expect(economy).toContain("Specialties.bonus(roles, \"Harpooner\")")
			T.expect(economy).toContain("Specialties.bonus(roles, \"Oiler\")")
			T.expect(source(Server.Domains.LiveOps)).toContain("SpecialtyService.start({")
		end)
	end)
end
