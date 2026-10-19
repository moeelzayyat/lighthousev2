--!strict
-- CHEST.1 (D-053): Kraken Chests. Earned (one a day for beating the Kraken), never sold; Pearls or chest-only looks,
-- never power; the odds add up and the rare find is about 1 in 100; opening is one chest for one find, once.
return function(T: any)
	local Items = T.require(game.ReplicatedStorage.Shared.Items)
	local Chests = T.require(game.ReplicatedStorage.Shared.Definitions.Chests)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)
	local GrantService = T.require(game.ServerScriptService.Server.GrantService)
	local ChestService = T.require(game.ServerScriptService.Server.ChestService)

	local DAY = 1792400000 -- a UTC moment in October 2026
	local function world(rolls: { number })
		local data: any = { Pearls = 0, Owned = {}, Counts = {}, Grants = {} }
		local clock = DAY
		local fail = false
		local deps: any = {
			grant = function(_player, claimId, rewards, _source)
				if fail then
					return "invalid"
				end
				return (GrantService.apply(data, claimId, rewards, clock))
			end,
			owns = function(_player, id)
				return data.Owned[id] == true
			end,
			count = function(_player, id)
				return data.Counts[id] or 0
			end,
			removeItem = function(_player, id, n)
				if (data.Counts[id] or 0) < n then
					return false
				end
				data.Counts[id] -= n
				if data.Counts[id] == 0 then
					data.Counts[id] = nil
				end
				return true
			end,
			addItem = function(_player, id, n)
				data.Counts[id] = (data.Counts[id] or 0) + n
			end,
			now = function()
				return clock
			end,
			random = function()
				return table.remove(rolls, 1) or 0
			end,
		}
		return data, deps, function(days: number)
			clock += days * 86400
		end, function(v: boolean)
			fail = v
		end
	end
	local keeper = { UserId = 501, DisplayName = "Tester", Name = "Tester" }

	T.describe("the Kraken Chest catalogue", function()
		T.it("passes the registry: earned, never sold, odds add up, finds are chest-only looks", function()
			local problems = {}
			for _, p in Registry.check(Registry.catalogs()) do
				if string.find(p, "Chest", 1, true) or string.find(p, "Abyss", 1, true) or string.find(p, "Kraken", 1, true) or string.find(p, "Leviathan", 1, true) or string.find(p, "Golden", 1, true) then
					table.insert(problems, p)
				end
			end
			T.expect(problems).toEqual({})
			T.expect(Items.KrakenChest.price).toBe(nil)
			local total, legendary = 0, 0
			for _, row in Chests.KrakenChest.loot do
				total += row.chance
				if row.tier == "Legendary" then
					legendary += row.chance
				end
				if row.item then
					local kind = Items[row.item].kind
					T.expect(kind == "Cosmetic" or kind == "Pet").toBe(true)
					T.expect(Items[row.item].price).toBe(nil)
				end
			end
			T.expect(math.abs(total - 1) < 1e-9).toBe(true)
			T.expect(legendary).toBe(0.01)
			T.expect(game.ReplicatedStorage.ItemModels:FindFirstChild("PetGoldenPuffin") ~= nil).toBe(true)
			-- CHEST.3: the 1% prize is a pet found only in the chest
			local prize = Chests.KrakenChest.loot[#Chests.KrakenChest.loot]
			T.expect(Items[prize.item].kind).toBe("Pet")
			T.expect(Items[prize.item].reward).toBe("chest")
			T.expect(prize.chance).toBe(0.01)
		end)

		T.it("the registry refuses a chest for sale and a weapon inside a chest", function()
			local all = Registry.catalogs()
			local items = table.clone(all.Items)
			items.KrakenChest = table.clone(items.KrakenChest)
			items.KrakenChest.price = 10
			local chests = table.clone(all.Chests)
			chests.KrakenChest = table.clone(chests.KrakenChest)
			chests.KrakenChest.loot = table.clone(chests.KrakenChest.loot)
			chests.KrakenChest.loot[2] = { item = "StormHarpoon", dupPearls = 40, chance = 0.22, tier = "Rare" }
			all.Items, all.Chests = items, chests
			local text = table.concat(Registry.check(all), "\n")
			T.expect(string.find(text, "Items.KrakenChest.price", 1, true) ~= nil).toBe(true)
			T.expect(string.find(text, "Chests.KrakenChest.loot[2].item", 1, true) ~= nil).toBe(true)
		end)

		T.it("the Robux chest (D-055) is the same chest, listed in the Robux catalogue, and its finds are never sold alone", function()
			local Cosmetics = T.require(game.ReplicatedStorage.Shared.Definitions.Cosmetics)
			T.expect(type(Cosmetics.KrakenChest)).toBe("table")
			T.expect(table.find(Cosmetics.ORDER, "KrakenChest") ~= nil).toBe(true)
			for _, row in Chests.KrakenChest.loot do
				if row.item then
					T.expect(Cosmetics[row.item]).toBe(nil)
				end
			end
		end)

		T.it("rolls land on the right rows", function()
			T.expect(Chests.roll(Chests.KrakenChest, 0).pearls).toBe(25)
			T.expect(Chests.roll(Chests.KrakenChest, 0.65).item).toBe("BeamAbyss")
			T.expect(Chests.roll(Chests.KrakenChest, 0.985).item).toBe("PetGoldenPuffin")
			T.expect(Chests.roll(Chests.KrakenChest, 0.995).item).toBe("PetLeviathanHatchling")
		end)
	end)

	T.describe("earning and opening", function()
		T.it("one chest a day for beating the Kraken, up to five held", function()
			local data, deps, advance = world({})
			T.expect(ChestService.earn(keeper, "KrakenChest", deps)).toBe("granted")
			T.expect(ChestService.earn(keeper, "KrakenChest", deps)).toBe("duplicate")
			T.expect(data.Counts.KrakenChest).toBe(1)
			advance(1)
			T.expect(ChestService.earn(keeper, "KrakenChest", deps)).toBe("granted")
			data.Counts.KrakenChest = 5
			advance(1)
			T.expect(ChestService.earn(keeper, "KrakenChest", deps)).toBe("full")
			T.expect(ChestService.earn(keeper, "NoSuchChest", deps)).toBe("invalid")
		end)

		T.it("opening takes one chest and gives one find; a look you own becomes Pearls", function()
			local data, deps = world({ 0, 0.995, 0.995 })
			data.Counts.KrakenChest = 3
			local ok, find = ChestService.open(keeper, "KrakenChest", "r1", deps)
			T.expect(ok).toBe(true)
			T.expect(find.pearls).toBe(25)
			T.expect(data.Pearls).toBe(25)
			T.expect(data.Counts.KrakenChest).toBe(2)
			ok, find = ChestService.open(keeper, "KrakenChest", "r2", deps)
			T.expect(find.item).toBe("PetLeviathanHatchling")
			T.expect(data.Owned.PetLeviathanHatchling).toBe(true)
			T.expect(ChestService.announcement("Tester", find) ~= nil).toBe(true)
			ok, find = ChestService.open(keeper, "KrakenChest", "r3", deps)
			T.expect(find.duplicate).toBe(true)
			T.expect(data.Pearls).toBe(25 + 200)
			T.expect(ChestService.announcement("Tester", find)).toBe(nil)
			T.expect(data.Counts.KrakenChest).toBe(nil)
			ok = ChestService.open(keeper, "KrakenChest", "r4", deps)
			T.expect(ok).toBe(false)
		end)

		T.it("a failed grant puts the chest back", function()
			local data, deps, _, setFail = world({ 0 })
			data.Counts.KrakenChest = 1
			setFail(true)
			local ok = ChestService.open(keeper, "KrakenChest", "r1", deps)
			T.expect(ok).toBe(false)
			T.expect(data.Counts.KrakenChest).toBe(1)
			T.expect(data.Pearls).toBe(0)
		end)
	end)
end
