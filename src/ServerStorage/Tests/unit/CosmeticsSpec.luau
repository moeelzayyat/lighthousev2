--!strict
-- B1.1, L1.3: cosmetics are looks only. Housings, coats, lanterns and flags are items with their own slots; the Robux
-- catalogue (Definitions/Cosmetics) can list only cosmetics, and only a price and a product id, so a power-for-Robux
-- item cannot reach a boot (the fairness test by construction). Only PurchaseService answers receipts and only the
-- shop prompts a purchase, through Cosmetics.productFor.
return function(T: any)
	local Cosmetics = T.require(game.ReplicatedStorage.Shared.Definitions.Cosmetics)
	local Items = T.require(game.ReplicatedStorage.Shared.Items)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)
	local ProfileSchema = T.require(game.ServerScriptService.Server.ProfileSchema)

	local function problemsWith(cosmetics: any): { string }
		local all = table.clone(Registry.catalogs())
		all.Cosmetics = cosmetics
		local out = {}
		for _, p in Registry.check(all) do
			if string.sub(p, 1, 10) == "Cosmetics." or string.sub(p, 1, 6) == "Items." then
				table.insert(out, p)
			end
		end
		return out
	end

	T.describe("the catalogue", function()
		T.it("passes the registry and every new slot has items", function()
			T.expect(problemsWith(Cosmetics)).toEqual({})
			local perSlot: { [string]: number } = {}
			for _, id in Items.SHOP_ORDER do
				local item = Items[id]
				if item.kind == "Cosmetic" then
					perSlot[item.slot] = (perSlot[item.slot] or 0) + 1
				end
			end
			for _, slot in { "Beam", "Housing", "Coat", "Lantern", "Flag" } do
				T.expect((perSlot[slot] or 0) >= 2).toBe(true)
			end
		end)

		T.it("everything sold for Robux is a cosmetic (or a pet also sold for Pearls), and all but the supporter flag can be earned with Pearls", function()
			local robuxOnly = {}
			for _, id in Cosmetics.ORDER do
				local item = Items[id]
				T.expect(item.kind == "Cosmetic" or (item.kind == "Pet" and type(item.price) == "number")).toBe(true) -- PET.1
				if item.price == nil then
					table.insert(robuxOnly, id)
				end
			end
			T.expect(robuxOnly).toEqual({ "FlagFounder" })
		end)
	end)

	T.describe("fairness", function()
		T.it("a stat on a Robux product, a weapon for Robux or an earned item for Robux fails the boot", function()
			local bad = table.clone(Cosmetics)
			bad.CoatStormBlue = { robux = 59, productId = 0, damage = 5 }
			bad.StormHarpoon = { robux = 99, productId = 0 }
			bad.BeamSharedLantern = { robux = 49, productId = 0 }
			bad.ORDER = table.clone(Cosmetics.ORDER)
			table.insert(bad.ORDER, "StormHarpoon")
			table.insert(bad.ORDER, "BeamSharedLantern")
			local found = table.concat(problemsWith(bad), "\n")
			T.expect(found).toContain("Cosmetics.CoatStormBlue.damage")
			T.expect(found).toContain("Cosmetics.StormHarpoon: is not a cosmetic")
			T.expect(found).toContain("Cosmetics.BeamSharedLantern: is earned")
		end)

		T.it("nothing is for sale while the switch is off or the product does not exist", function()
			-- this spec's own copy of the module, changed and put back
			local savedSwitch, savedId = Cosmetics.ROBUX_ENABLED, Cosmetics.HousingBrass.productId
			Cosmetics.ROBUX_ENABLED = true
			Cosmetics.HousingBrass.productId = 0
			T.expect(Cosmetics.productFor("HousingBrass")).toBe(nil) -- no product yet
			Cosmetics.HousingBrass.productId = 123456
			T.expect(Cosmetics.productFor("HousingBrass").robux).toBe(99)
			T.expect(Cosmetics.itemFor(123456)).toBe("HousingBrass")
			Cosmetics.ROBUX_ENABLED = false
			T.expect(Cosmetics.productFor("HousingBrass")).toBe(nil) -- switch off
			T.expect(Cosmetics.productFor("StormHarpoon")).toBe(nil) -- never listed
			Cosmetics.ROBUX_ENABLED, Cosmetics.HousingBrass.productId = savedSwitch, savedId
		end)

		T.it("only PurchaseService answers receipts and only the shop prompts a purchase", function()
			local receipts, prompts = {}, {}
			for _, root in { game.ServerScriptService, game.ReplicatedStorage, game.StarterPlayer, game.StarterGui, game.Workspace } do
				for _, inst in root:GetDescendants() do
					if inst:IsA("LuaSourceContainer") then
						local src = (inst :: any).Source :: string
						if string.find(src, "ProcessReceipt =", 1, true) then
							table.insert(receipts, inst.Name)
						end
						if string.find(src, ":Prompt", 1, true) and string.find(src, "Purchase", 1, true) then
							table.insert(prompts, inst.Name)
						end
					end
				end
			end
			T.expect(receipts).toEqual({ "Economy" }) -- the Economy domain hands receipts to PurchaseService
			T.expect(prompts).toEqual({ "Shop" })
			local shop = (game.StarterPlayer.StarterPlayerScripts.Client.Shop :: any).Source :: string
			-- S2.5c: the one prompt is for the product the Cosmetics catalogue lists for that item (nil when Robux is off)
			T.expect(shop).toContain("Cosmetics.productFor(itemId)")
			T.expect(shop).toContain("PromptProductPurchase(player, product.productId)")
			local _, prompted = string.gsub(shop, ":Prompt", "")
			T.expect(prompted).toBe(1)
		end)
	end)

	T.describe("wearing", function()
		T.it("an equipped cosmetic must be owned and fit its slot, or it comes off at load", function()
			local data = ProfileSchema.template()
			data.Owned.CoatStormBlue = true
			data.Equipped.Coat = "CoatStormBlue"
			data.Equipped.Flag = "FlagKraken" -- not owned
			data.Equipped.Lantern = "CoatStormBlue" -- owned, wrong slot
			local fixed, fixes = ProfileSchema.validate(data)
			T.expect(fixed.Equipped.Coat).toBe("CoatStormBlue")
			T.expect(fixed.Equipped.Flag).toBe(nil)
			T.expect(fixed.Equipped.Lantern).toBe(nil)
			T.expect(#fixes).toBe(2)
		end)

		T.it("the server dresses coats, lanterns, the lamp housing and the ship flag from colour attributes", function()
			local economy = (game.ServerScriptService.Server.Domains.Economy :: any).Source :: string
			local lamp = (game.ServerScriptService.Server.LampService :: any).Source :: string
			T.expect(economy).toContain("dressCosmetics(character, player)")
			T.expect(economy).toContain("refreshShipFlag()")
			T.expect(lamp).toContain("HousingColor")
		end)
	end)
end
