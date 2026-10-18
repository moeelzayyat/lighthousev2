--!strict
-- WPN.1 (D-048): Chain Hook, Net Launcher and Lantern Bomb. They pass the registry, are sold by the Quartermaster
-- for Pearls (never Robux), stay well below the beam per creature, and their effects follow Shared/WeaponFx.
return function(T: any)
	local Weapons = T.require(game.ReplicatedStorage.Shared.Weapons)
	local Items = T.require(game.ReplicatedStorage.Shared.Items)
	local Config = T.require(game.ReplicatedStorage.Shared.Config)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)
	local WeaponFx = T.require(game.ReplicatedStorage.Shared.WeaponFx)

	local NEW: { [string]: string } = { ChainHook = "Chain", NetLauncher = "Net", LanternBomb = "Bomb" }

	T.describe("the new weapons", function()
		T.it("pass the registry and are Quartermaster items with a model", function()
			local problems = {}
			for _, p in Registry.check(Registry.catalogs()) do
				for id in NEW do
					if string.find(p, id, 1, true) then
						table.insert(problems, p)
					end
				end
			end
			T.expect(problems).toEqual({})
			for id, archetype in NEW do
				T.expect(Weapons[id].archetype).toBe(archetype)
				T.expect(Items[id].kind).toBe("Weapon")
				T.expect(type(Items[id].price)).toBe("number")
				T.expect(table.find(Items.SHOP_ORDER, id) ~= nil).toBe(true)
				T.expect(game.ReplicatedStorage.ItemModels:FindFirstChild(Items[id].model) ~= nil).toBe(true)
			end
		end)

		T.it("help but never outdo the wide beam on one creature", function()
			for id in NEW do
				local w = Weapons[id]
				T.expect(w.damage / w.cooldown < Config.WIDE_DPS).toBe(true)
			end
		end)

		T.it("the Chain Hook drags toward the thrower and stops short of them", function()
			local thrower = Vector3.new(0, 5, 0)
			T.expect(WeaponFx.pullPosition(Vector3.new(30, 2, 0), thrower, 14, 6)).toEqual(Vector3.new(16, 2, 0))
			T.expect(WeaponFx.pullPosition(Vector3.new(10, 2, 0), thrower, 14, 6)).toEqual(Vector3.new(6, 2, 0))
			T.expect(WeaponFx.pullPosition(Vector3.new(4, 2, 0), thrower, 14, 6)).toEqual(Vector3.new(4, 2, 0))
			T.expect(WeaponFx.canPull(true)).toBe(true)
			T.expect(WeaponFx.canPull(false)).toBe(false) -- big monsters are too heavy
		end)

		T.it("a net slows small creatures fully and big monsters by half", function()
			T.expect(WeaponFx.slowFor(false, 0.35)).toBeCloseTo(0.35)
			T.expect(WeaponFx.slowFor(true, 0.35)).toBeCloseTo(0.675)
		end)
	end)
end
