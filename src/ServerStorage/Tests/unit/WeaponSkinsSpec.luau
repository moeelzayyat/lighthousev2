--!strict
-- WSKIN.1 (D-058): Robux weapons with the same power as a Pearl weapon. Each one hits exactly like its base (the
-- registry refuses any difference), the base is sold for Pearls, it is in the Robux catalogue and nowhere for Pearls.
return function(T: any)
	local Items = T.require(game.ReplicatedStorage.Shared.Items)
	local Weapons = T.require(game.ReplicatedStorage.Shared.Weapons)
	local Cosmetics = T.require(game.ReplicatedStorage.Shared.Definitions.Cosmetics)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)
	local SKINS = { GoldenDragonPistol = "FlintlockPistol", KrakenBlaster = "Blunderbuss" }

	T.describe("Robux weapons", function()
		T.it("hit exactly like a Pearl weapon and are sold only for Robux", function()
			for id, baseId in SKINS do
				local w, base = Weapons[id], Weapons[baseId]
				T.expect(w.skinOf).toBe(baseId)
				for _, field in { "damage", "cooldown", "range", "hitRadius", "maxTargets", "archetype", "projectile" } do
					T.expect(w[field]).toBe(base[field])
				end
				T.expect(Items[id].kind).toBe("Weapon")
				T.expect(Items[id].price).toBe(nil)
				T.expect(type(Items[baseId].price) == "number").toBe(true)
				T.expect(type(Cosmetics[id])).toBe("table")
				T.expect(game.ReplicatedStorage.ItemModels:FindFirstChild(Items[id].model) ~= nil).toBe(true)
			end
		end)

		T.it("the registry refuses a Robux weapon that hits harder than its base", function()
			local all = Registry.catalogs()
			local weapons = table.clone(all.Weapons)
			weapons.GoldenDragonPistol = table.clone(weapons.GoldenDragonPistol)
			weapons.GoldenDragonPistol.damage = 60
			all.Weapons = weapons
			local text = table.concat(Registry.check(all), "\n")
			T.expect(string.find(text, "Weapons.GoldenDragonPistol.damage", 1, true) ~= nil).toBe(true)
		end)
	end)
end
