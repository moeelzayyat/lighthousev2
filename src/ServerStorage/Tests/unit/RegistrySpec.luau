--!strict
-- S5.4: `_Registry` checks every catalog at boot; a broken definition fails with a clear message.
return function(T: any)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)

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

	local function fresh(): any
		return deepCopy(Registry.catalogs())
	end

	local function hasProblem(problems: { string }, text: string): boolean
		for _, p in problems do
			if string.find(p, text, 1, true) then
				return true
			end
		end
		return false
	end

	T.describe("the real catalogs", function()
		T.it("have no problems", function()
			T.expect(Registry.check(Registry.catalogs())).toEqual({})
		end)

		T.it("count every definition", function()
			T.expect(Registry.count(Registry.catalogs())).toBeGreaterThan(30)
		end)
	end)

	T.describe("broken samples", function()
		T.it("a negative price names the item and the field", function()
			local all = fresh()
			all.Items.FlareGun.price = -5
			T.expect(hasProblem(Registry.check(all), "Items.FlareGun.price: must be a positive number, got -5")).toBe(true)
		end)

		T.it("a duplicate id in an order list fails", function()
			local all = fresh()
			table.insert(all.Items.SHOP_ORDER, "FlareGun")
			T.expect(hasProblem(Registry.check(all), "Items.SHOP_ORDER: duplicate id \"FlareGun\"")).toBe(true)
			local all2 = fresh()
			table.insert(all2.Upgrades.EVOLUTIONS, deepCopy(all2.Upgrades.EVOLUTIONS[1]))
			T.expect(hasProblem(Registry.check(all2), "duplicate id OverchargedBeam")).toBe(true)
		end)

		T.it("a loot table must sum to 1", function()
			local all = fresh()
			-- S6.5: creature loot rows name their drops ({ kind, min, max })
			all.Creatures.RockCrab.loot = { { chance = 0.5, drops = { { "CrabClaw", 1, 1 } } }, { chance = 0.4, drops = { { "Shells", 3, 5 } } } }
			T.expect(hasProblem(Registry.check(all), "Creatures.RockCrab.loot: chances must sum to 1, got 0.9000")).toBe(true)
			all.Creatures.RockCrab.loot[2].chance = 0.5
			T.expect(Registry.check(all)).toEqual({})
		end)

		T.it("cross-catalog links are checked", function()
			local all = fresh()
			all.Weapons.Slingshot = deepCopy(all.Weapons.FlareGun)
			all.Items.FireShellCrate.ammoType = "Grapeshot"
			all.Voyages.Long.unlock = "Nothing"
			local problems = Registry.check(all)
			T.expect(hasProblem(problems, "Weapons.Slingshot: has no Items.Slingshot entry of kind Weapon")).toBe(true)
			T.expect(hasProblem(problems, "Items.FireShellCrate.ammoType: must name a defined Ammo type")).toBe(true)
			T.expect(hasProblem(problems, "Voyages.Long.unlock: no voyage grants Nothing")).toBe(true)
		end)

		T.it("ranges and types are checked", function()
			local all = fresh()
			all.Voyages.Standard.bossNights = { 4, 9 }
			all.Creatures.SandSkitter.health = 0 / 0
			all.Items.KeepersCoat.damageReduction = 1.5
			all.Events.Broken = { UserId = "Player" }
			local problems = Registry.check(all)
			T.expect(hasProblem(problems, "Voyages.Standard.bossNights[2]: must be at most 7, got 9")).toBe(true)
			T.expect(hasProblem(problems, "Creatures.SandSkitter.health: must be a positive number")).toBe(true)
			T.expect(hasProblem(problems, "Items.KeepersCoat.damageReduction: must be at most 0.9, got 1.5")).toBe(true)
			T.expect(hasProblem(problems, "Events.Broken.UserId: type must be number/string/boolean/table")).toBe(true)
		end)

		T.it("assertValid stops with one message that lists every problem", function()
			local all = fresh()
			all.Items.FlareGun.price = -5
			all.Ammo.DEFAULT = "Nope"
			T.expect(function()
				Registry.assertValid(all)
			end).toThrow("Definitions: 2 problems; the server will not start")
			local ok, err = pcall(Registry.assertValid, all)
			T.expect(ok).toBe(false)
			T.expect(tostring(err)).toContain("- Ammo.DEFAULT: must name a defined ammo type")
			T.expect(tostring(err)).toContain("- Items.FlareGun.price")
		end)
	end)
end
