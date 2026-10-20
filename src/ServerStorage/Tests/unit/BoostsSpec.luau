--!strict
-- S6.4: the Quartermaster's permanent boosts (capped at +15% all together), the new profile field with its
-- default, and the new gear (Coral Lance, Tidecaller Blades, Kelpweave Vest).
return function(T: any)
	local Boosts = T.require(game.ReplicatedStorage.Shared.Definitions.Boosts)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)
	local Items = T.require(game.ReplicatedStorage.Shared.Items)
	local Weapons = T.require(game.ReplicatedStorage.Shared.Weapons)
	local StatPipeline = T.require(game.ReplicatedStorage.Shared.StatPipeline)
	local ProfileSchema = T.require(game.ServerScriptService.Server.ProfileSchema)
	local MigrationService = T.require(game.ServerScriptService.Server.MigrationService)
	local fixtures = game.ServerStorage.Tests.fixtures.profiles

	local function source(inst: Instance): string
		return (inst :: any).Source
	end
	local function deepCopy(t: any): any
		if type(t) ~= "table" then
			return t
		end
		local c = {}
		for k, v in t do
			c[k] = deepCopy(v)
		end
		return c
	end

	T.describe("the boosts", function()
		T.it("pass the boot registry with the new gear", function()
			local problems = {}
			for _, p in Registry.check(Registry.catalogs()) do
				for _, prefix in { "Boosts.", "Items.", "Weapons." } do
					if string.sub(p, 1, #prefix) == prefix then
						table.insert(problems, p)
					end
				end
			end
			T.expect(problems).toEqual({})
		end)

		T.it("cap all boosts together at +15%", function()
			local ranks: { [string]: number } = {}
			local spent = 0
			for _ = 1, 5 do
				local ok, price = Boosts.nextRank(ranks, "ShellPouch")
				T.expect(ok).toBe(true)
				spent += price
				ranks.ShellPouch = (ranks.ShellPouch or 0) + 1
			end
			T.expect(spent).toBe(200)
			local ok, _, reason = Boosts.nextRank(ranks, "ShellPouch")
			T.expect(ok).toBe(false)
			T.expect(reason).toBe("Shell Pouch is at its top rank.")
			for _ = 1, 5 do
				T.expect((Boosts.nextRank(ranks, "SeaBoots"))).toBe(true)
				ranks.SeaBoots = (ranks.SeaBoots or 0) + 1
			end
			T.expect(Boosts.total(ranks)).toBeCloseTo(0.15)
			local capped, price, why = Boosts.nextRank(ranks, "SharpSteel")
			T.expect(capped).toBe(false)
			T.expect(price).toBe(nil)
			T.expect(why).toBe("Your boosts together are at the +15% limit.")
			T.expect(Boosts.bonus(ranks, "ShellGainPct")).toBeCloseTo(0.1)
			T.expect(Boosts.bonus(ranks, "PlayerSpeed")).toBeCloseTo(0.05)
			T.expect(Boosts.bonus(ranks, "WeaponDamage")).toBe(0)
			T.expect(StatPipeline.compute("ShellGainPct", 0, { flat = { 0.3 } })).toBe(0.15)
		end)
	end)

	T.describe("the profile field", function()
		T.it("a fresh profile starts with no boosts", function()
			T.expect(ProfileSchema.template().Boosts).toEqual({})
		end)

		T.it("a v2 profile saved before S6.4 loads with Boosts = {} and nothing else changed or repaired", function()
			local saved = require(fixtures.v2_before_S6_4) :: any
			local before = deepCopy(saved)
			local data, fixes = MigrationService.upgrade(deepCopy(saved))
			T.expect(fixes).toEqual({})
			T.expect(data.Boosts).toEqual({})
			T.expect(data.Roles).toEqual({}) -- S7.4: also added with its default
			data.Boosts = nil
			data.Roles = nil
			T.expect(data.Unlocks.FrostIsle).toBe(true) -- MAP.1: a Standard winner (LongVoyage) also has Frostbite Isle
			data.Unlocks.FrostIsle = nil
			T.expect(data.TutorialDone).toBe(data.Stats.Runs > 0) -- TUT.1: added from the voyages already played
			data.TutorialDone = nil
			T.expect(data).toEqual(before)
		end)

		T.it("real timestamps survive a load (D-022)", function()
			local saved = deepCopy(require(fixtures.v2_before_S6_4) :: any)
			local data, fixes = ProfileSchema.validate(saved)
			T.expect(data.CreatedAt).toBe(1760600000)
			T.expect(data.LastSeenAt).toBe(1760650000)
			T.expect(fixes).toEqual({})
			saved.CreatedAt = -5
			local _, bad = ProfileSchema.validate(saved)
			T.expect(bad).toEqual({ "CreatedAt: not a whole number" })
		end)

		T.it("a v1 profile lifted to v2 gets Boosts = {}", function()
			local v1 = require(fixtures.v1) :: any
			local data = MigrationService.upgrade(deepCopy(v1.full))
			T.expect(data.Boosts).toEqual({})
			T.expect(data.Pearls).toBe(37)
		end)

		T.it("bad ranks are dropped and ranks over the cap come down", function()
			local bad = deepCopy(require(fixtures.v2_before_S6_4) :: any)
			bad.Boosts = { ShellPouch = 9, Nope = 1, SeaBoots = 2.5, SharpSteel = 2 }
			local data, fixes = ProfileSchema.validate(bad)
			T.expect(data.Boosts).toEqual({ SharpSteel = 2 })
			T.expect(#fixes).toBe(3)
			local over = deepCopy(require(fixtures.v2_before_S6_4) :: any)
			over.Boosts = { ShellPouch = 5, SeaBoots = 5, SharpSteel = 5 }
			local fixed, notes = ProfileSchema.validate(over)
			T.expect(fixed.Boosts).toEqual({ ShellPouch = 5, SeaBoots = 5 })
			T.expect(Boosts.total(fixed.Boosts) <= Boosts.TOTAL_CAP + 1e-9).toBe(true)
			T.expect(table.concat(notes, "\n")).toContain("Boosts.SharpSteel: over the total cap, lowered")
			local wrongType = deepCopy(require(fixtures.v2_before_S6_4) :: any)
			wrongType.Boosts = "lots"
			local w, wf = ProfileSchema.validate(wrongType)
			T.expect(w.Boosts).toEqual({})
			T.expect(wf).toEqual({ "Boosts: not a table" })
		end)
	end)

	T.describe("the new gear", function()
		T.it("Coral Lance, Tidecaller Blades and Kelpweave Vest are sold for Pearls", function()
			for _, id in { "CoralLance", "TidecallerBlades", "KelpweaveVest" } do
				T.expect(table.find(Items.SHOP_ORDER, id) ~= nil).toBe(true)
				T.expect(type(Items[id].price)).toBe("number")
			end
			T.expect(Weapons.CoralLance.archetype).toBe("Thrown")
			T.expect(Weapons.TidecallerBlades.archetype).toBe("Orbit")
			T.expect(Weapons.TidecallerBlades.voyageOnly).toBe(nil)
			local vest = StatPipeline.armor("KelpweaveVest")
			T.expect({ vest.maxHealth, vest.damageReduction }).toEqual({ 160, 0.2 })
		end)
	end)

	T.describe("wiring", function()
		T.it("the shop sells ranks, the voyage reads them, the client shows them", function()
			local Server = game.ServerScriptService.Server
			local shop = source(Server.ShopService)
			T.expect(shop).toContain("if action == \"boost\" then")
			T.expect(shop).toContain("Boosts.nextRank(data.Boosts, boostId)")
			local economy = source(Server.Domains.Economy)
			T.expect(economy).toContain("Boosts.bonus(ranks, \"WeaponDamage\")")
			T.expect(economy).toContain("player:SetAttribute(\"Boost_ShellGainPct\"")
			T.expect(economy).toContain("if Weapons[weaponId] and Weapons[weaponId].archetype == \"Orbit\" then\n\t\treturn {}")
			T.expect(source(Server.LootService)).toContain("player:GetAttribute(\"Boost_ShellGainPct\")")
			T.expect(source(Server.PlayerData)).toContain("boosts = data.Boosts")
			T.expect(source(game.StarterPlayer.StarterPlayerScripts.Client.Shop)).toContain("{ id = \"Boosts\", label = \"Boosts\" }")
		end)
	end)
end
