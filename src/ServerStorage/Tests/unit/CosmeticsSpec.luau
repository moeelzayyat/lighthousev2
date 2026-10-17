--!strict
-- B1.1: the cosmetics catalogue is looks only and nothing can be bought with Robux yet. The fairness test by
-- construction: _Registry refuses any field on a cosmetic that is not a look or a price, and refuses
-- ROBUX_ENABLED = true, so a power-for-Robux item cannot reach a boot.
return function(T: any)
	local Cosmetics = T.require(game.ReplicatedStorage.Shared.Definitions.Cosmetics)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)

	local function problemsWith(cosmetics: any): { string }
		local all = table.clone(Registry.catalogs())
		all.Cosmetics = cosmetics
		local out = {}
		for _, p in Registry.check(all) do
			if string.sub(p, 1, 10) == "Cosmetics." then
				table.insert(out, p)
			end
		end
		return out
	end

	T.describe("the catalogue", function()
		T.it("passes the registry and covers every slot the roadmap names", function()
			T.expect(problemsWith(Cosmetics)).toEqual({})
			local perSlot: { [string]: number } = {}
			for _, id in Cosmetics.ORDER do
				local slot = Cosmetics[id].slot
				perSlot[slot] = (perSlot[slot] or 0) + 1
			end
			for _, slot in { "Housing", "Coat", "Lantern", "Flag" } do
				T.expect((perSlot[slot] or 0) >= 2).toBe(true)
			end
			T.expect(#Cosmetics.BEAMS >= 4).toBe(true) -- beam colours already in Items
		end)

		T.it("every Robux item except the supporter flag can also be earned with Pearls", function()
			local robuxOnly = {}
			for _, id in Cosmetics.ORDER do
				local def = Cosmetics[id]
				if def.robux ~= nil and def.pearls == nil then
					table.insert(robuxOnly, id)
				end
			end
			T.expect(robuxOnly).toEqual({ "FlagFounder" })
		end)
	end)

	T.describe("fairness", function()
		T.it("a cosmetic carrying a stat fails the boot", function()
			local bad = table.clone(Cosmetics)
			local coat = table.clone(Cosmetics.CoatStormBlue) :: any
			coat.damage = 5
			coat.maxHealth = 20
			bad.CoatStormBlue = coat
			local problems = problemsWith(bad)
			T.expect(#problems).toBe(2)
			T.expect(problems[1]).toContain("looks only")
		end)

		T.it("Robux cannot be switched on before the owner approves L1.3", function()
			T.expect(Cosmetics.ROBUX_ENABLED).toBe(false)
			local bad = table.clone(Cosmetics)
			bad.ROBUX_ENABLED = true
			T.expect(problemsWith(bad)[1]).toContain("ROBUX_ENABLED")
		end)

		T.it("no game script prompts or processes a Robux purchase", function()
			local found = {}
			for _, root in { game.ServerScriptService, game.ReplicatedStorage, game.StarterPlayer, game.StarterGui, game.Workspace } do
				for _, inst in root:GetDescendants() do
					if inst:IsA("LuaSourceContainer") then
						local src = (inst :: any).Source :: string
						if string.find(src, "MarketplaceService", 1, true) or string.find(src, "ProcessReceipt", 1, true) then
							table.insert(found, inst:GetFullName())
						end
					end
				end
			end
			T.expect(found).toEqual({})
		end)
	end)
end
