--!strict
-- GUN.1 (D-057): the guns. Bought with Pearls (weapon power is never sold for Robux), fired like a thrown weapon
-- (the server picks what is hit), each with its 3D model, and none stronger than the lamp's focused beam.
return function(T: any)
	local Items = T.require(game.ReplicatedStorage.Shared.Items)
	local Weapons = T.require(game.ReplicatedStorage.Shared.Weapons)
	local Cosmetics = T.require(game.ReplicatedStorage.Shared.Definitions.Cosmetics)
	local Config = T.require(game.ReplicatedStorage.Shared.Config)
	local GUNS = { "FlintlockPistol", "Blunderbuss", "HarpoonGun", "StormMusket" }

	T.describe("the guns", function()
		T.it("are sold for Pearls only, in the shop, each with its model", function()
			for _, id in GUNS do
				local item = Items[id]
				T.expect(item.kind).toBe("Weapon")
				T.expect(type(item.price) == "number" and item.price > 0).toBe(true)
				T.expect(Cosmetics[id]).toBe(nil)
				T.expect(table.find(Items.SHOP_ORDER, id) ~= nil).toBe(true)
				T.expect(game.ReplicatedStorage.ItemModels:FindFirstChild(item.model) ~= nil).toBe(true)
			end
		end)

		T.it("fire like aimed weapons and stay under the focused beam's damage per second", function()
			for _, id in GUNS do
				local w = Weapons[id]
				T.expect(w.archetype).toBe("Thrown")
				T.expect(w.projectile == "bullet" or w.projectile == "shot" or w.projectile == "spear").toBe(true)
				T.expect(w.damage / w.cooldown < Config.FOCUSED_DPS).toBe(true)
			end
			-- the Blunderbuss trades range for a group
			T.expect(Weapons.Blunderbuss.range < Weapons.FlintlockPistol.range).toBe(true)
			T.expect(Weapons.Blunderbuss.maxTargets > 1).toBe(true)
		end)
	end)
end
