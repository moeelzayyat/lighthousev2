--!strict
-- S5.7: StatPipeline computes every stat the game shows and uses; previews equal in-voyage values, and the
-- owner-approved numbers come out unchanged.
return function(T: any)
	local StatPipeline = T.require(game.ReplicatedStorage.Shared.StatPipeline)
	local Weapons = T.require(game.ReplicatedStorage.Shared.Weapons)
	local Items = T.require(game.ReplicatedStorage.Shared.Items)
	local Upgrades = T.require(game.ReplicatedStorage.Shared.Upgrades)
	local Config = T.require(game.ReplicatedStorage.Shared.Config)

	T.describe("the formula", function()
		T.it("is (Base + ΣFlat) × (1 + ΣAdditivePct) × ΠMultipliers, then clamped", function()
			T.expect(StatPipeline.compute("MaxFuel", 100, { flat = { 10, 20 }, add = { 0.1 } })).toBeCloseTo(143)
			T.expect(StatPipeline.compute("WeaponDamage", 10, { add = { 0.5 }, mult = { 2 } })).toBeCloseTo(30)
			T.expect(StatPipeline.compute("MaxFuel", 1000)).toBe(200)
			T.expect(StatPipeline.compute("MaxFuel", 10)).toBe(60)
			T.expect(StatPipeline.compute("PlayerArmor", 0.9)).toBe(0.6)
		end)

		T.it("refuses an unknown stat and a layer the stat does not take", function()
			T.expect(function()
				StatPipeline.compute("Luck", 1)
			end).toThrow("unknown stat Luck")
			T.expect(function()
				StatPipeline.compute("PlayerArmor", 0.1, { add = { 0.1 } })
			end).toThrow("PlayerArmor takes no AdditivePct layer")
			T.expect(function()
				StatPipeline.compute("WeaponCooldown", 1, { mult = { 0.5 } })
			end).toThrow("WeaponCooldown takes no Multiplier layer")
		end)
	end)

	T.describe("today's numbers come out unchanged", function()
		T.it("every weapon", function()
			for id, w in Weapons do
				local s = StatPipeline.weapon(id)
				T.expect({ s.damage, s.cooldown, s.range, s.hitRadius, s.maxTargets }).toEqual({ w.damage, w.cooldown, w.range, w.hitRadius, w.maxTargets })
			end
		end)

		T.it("every armor", function()
			for id, item in Items do
				if type(item) == "table" and item.kind == "Armor" then
					local s = StatPipeline.armor(id)
					T.expect({ s.maxHealth, s.damageReduction }).toEqual({ item.maxHealth, item.damageReduction })
				end
			end
		end)

		T.it("every bench upgrade at every rank", function()
			local bases = { LensPower = 1, FuelTank = Config.MAX_FUEL, Walls = Config.MAX_INTEGRITY, ClockworkSweep = 0 }
			for _, id in Upgrades.ORDER do
				T.expect(StatPipeline.upgrade(id, 0)).toBe(bases[id])
				for rank, value in Upgrades[id].values do
					T.expect(StatPipeline.upgrade(id, rank)).toBeCloseTo(value)
				end
			end
		end)
	end)

	T.describe("previews equal in-voyage values", function()
		T.it("the bench preview equals what UpgradeService applies at every rank", function()
			local UpgradeService = T.require(game.ServerScriptService.Server.UpgradeService)
			local attrs: { [string]: any } = {}
			local state = {
				SetAttribute = function(_self: any, k: string, v: any)
					attrs[k] = v
				end,
				GetAttribute = function(_self: any, k: string)
					return attrs[k]
				end,
			}
			local lamp = { setMaxFuel = function() end, addFuel = function() end }
			local tower = { setMax = function() end, repair = function() end }
			UpgradeService.init(state, lamp, tower)
			UpgradeService.reset()
			UpgradeService.addShells(100000, "test")
			local bases = { LensPower = 1, FuelTank = Config.MAX_FUEL, Walls = Config.MAX_INTEGRITY, ClockworkSweep = 0 }
			for _, id in Upgrades.ORDER do
				T.expect(UpgradeService.value(id, bases[id])).toBe(StatPipeline.upgrade(id, 0))
				for rank = 1, #Upgrades[id].costs do
					local ok = UpgradeService.buy(id)
					T.expect(ok).toBe(true)
					T.expect(UpgradeService.value(id, bases[id])).toBe(StatPipeline.upgrade(id, rank))
				end
			end
		end)

		T.it("the shop, bag, HUD and voyage code all read StatPipeline", function()
			local Client = game.StarterPlayer.StarterPlayerScripts.Client
			local Server = game.ServerScriptService.Server
			local function source(inst: Instance): string
				return (inst :: any).Source
			end
			T.expect(source(Server.Domains.Encounter)).toContain("StatPipeline.weapon(weaponId, ")
			T.expect(source(Server.Domains.Economy)).toContain("StatPipeline.armor(profile.equippedArmor)")
			T.expect(source(Server.UpgradeService)).toContain("StatPipeline.upgrade(id, level)")
			for _, name in { "Shop", "Inventory" } do
				T.expect(source(Client[name])).toContain("StatPipeline.weapon(itemId)")
				T.expect(source(Client[name])).toContain("StatPipeline.armor(")
			end
			T.expect(source(Client.Bench)).toContain("StatPipeline.upgrade(id, level)")
			T.expect(source(Client.Hud)).toContain("StatPipeline.weapon(id)")
		end)
	end)
end
