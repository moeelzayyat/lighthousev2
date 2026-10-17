--!strict
-- S6.3: the Orbit weapon archetype. Orbiting Blades cut the creatures around their carrier on a timer, with
-- numbers from StatPipeline; nothing is aimed; the island merchant sells them once a voyage.
return function(T: any)
	local OrbitService = T.require(game.ServerScriptService.Server.OrbitService)
	local Weapons = T.require(game.ReplicatedStorage.Shared.Weapons)
	local Merchant = T.require(game.ReplicatedStorage.Shared.Definitions.Merchant)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)

	local function source(inst: Instance): string
		return (inst :: any).Source
	end
	local HERE = Vector3.new(10, 5, -3)

	T.describe("the weapon", function()
		T.it("is an Orbit weapon sold only for a voyage; every other weapon is Thrown", function()
			local blades = Weapons.OrbitingBlades
			T.expect(blades.archetype).toBe("Orbit")
			T.expect(blades.voyageOnly).toBe(true)
			T.expect(blades.blades).toBe(3)
			for id, w in Weapons do
				if id ~= "OrbitingBlades" and id ~= "TidecallerBlades" then -- S6.4: Tidecaller is the permanent Orbit weapon
					T.expect(w.archetype).toBe("Thrown")
				end
			end
			local problems = {}
			for _, p in Registry.check(Registry.catalogs()) do
				if string.sub(p, 1, 8) == "Weapons." or string.sub(p, 1, 9) == "Merchant." then
					table.insert(problems, p)
				end
			end
			T.expect(problems).toEqual({})
		end)

		T.it("the merchant sells it once a voyage", function()
			local def = Merchant.OrbitingBlades
			T.expect(def.effect).toBe("weapon")
			T.expect(def.weapon).toBe("OrbitingBlades")
			T.expect(def.limit).toBe(1)
			T.expect(table.find(Merchant.ORDER, "OrbitingBlades")).toBe(1)
		end)
	end)

	T.describe("cutting", function()
		T.it("cuts at once, then every cooldown, with the pipeline's numbers", function()
			local p = {}
			local carriers = { { key = p, weaponId = "OrbitingBlades", position = HERE, damageBoost = 0 } }
			local first = OrbitService.step(100, carriers)
			T.expect(#first).toBe(1)
			T.expect(first[1].position).toBe(HERE)
			T.expect(first[1].radius).toBe(7)
			T.expect(first[1].damage).toBe(4)
			T.expect(first[1].maxTargets).toBe(3)
			T.expect(first[1].source).toBe("Weapon:OrbitingBlades")
			T.expect(first[1].key).toBe(p)
			T.expect(#OrbitService.step(100.3, carriers)).toBe(0)
			T.expect(#OrbitService.step(100.5, carriers)).toBe(1)
			-- 10 seconds at the 10 Hz check: 20 cuts (8 damage per second to each creature in reach)
			local n = 0
			for i = 1, 100 do
				n += #OrbitService.step(100.5 + i * 0.1, carriers)
			end
			T.expect(n >= 19 and n <= 20).toBe(true)
		end)

		T.it("the merchant's damage boost applies; thrown weapons never cut", function()
			local boosted = OrbitService.step(5, { { key = {}, weaponId = "OrbitingBlades", position = HERE, damageBoost = 0.2 } })
			T.expect(boosted[1].damage).toBeCloseTo(4.8)
			T.expect(#OrbitService.step(5, { { key = {}, weaponId = "DriftwoodHarpoon", position = HERE, damageBoost = 0 } })).toBe(0)
		end)

		T.it("a carrier who drops out is forgotten and cuts at once when back", function()
			local p = {}
			local carriers = { { key = p, weaponId = "OrbitingBlades", position = HERE, damageBoost = 0 } }
			T.expect(#OrbitService.step(50, carriers)).toBe(1)
			T.expect(#OrbitService.step(50.1, {})).toBe(0)
			T.expect(#OrbitService.step(50.2, carriers)).toBe(1)
		end)
	end)

	T.describe("wiring", function()
		T.it("the voyage starts the blades, the merchant gives them, the client only draws them", function()
			local Server = game.ServerScriptService.Server
			T.expect(source(Server.Domains.Encounter)).toContain("OrbitService.start({")
			T.expect(source(Server.Domains.Economy)).toContain("player:SetAttribute(\"OrbitWeapon\", orbit)")
			local view = source(game.StarterPlayer.StarterPlayerScripts.Client.OrbitView)
			T.expect(view).toContain("Workspace:BulkMoveTo(parts, frames")
			-- nothing to aim and nothing sent: no input and no remotes in the view
			T.expect(string.find(view, "UserInputService", 1, true)).toBe(nil)
			T.expect(string.find(view, "FireServer", 1, true)).toBe(nil)
		end)
	end)
end
