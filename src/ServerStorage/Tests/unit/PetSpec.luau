--!strict
-- PET.1 (D-051): the Shell-fetching pet. It is earnable for Pearls (so it may also be sold for Robux), it is not
-- offered for Robux until its product exists, new players borrow it for their first voyages, and it only fetches
-- landed Shells within its reach.
return function(T: any)
	local Items = T.require(game.ReplicatedStorage.Shared.Items)
	local Cosmetics = T.require(game.ReplicatedStorage.Shared.Definitions.Cosmetics)
	local Config = T.require(game.ReplicatedStorage.Shared.Config)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)
	local PetRules = T.require(game.ReplicatedStorage.Shared.PetRules)

	local function isPet(id: string): boolean
		return Items[id] ~= nil and Items[id].kind == "Pet"
	end

	T.describe("the pet", function()
		T.it("is earnable for Pearls, passes the registry, and is sold for Robux through its product", function()
			local problems = {}
			for _, p in Registry.check(Registry.catalogs()) do
				if string.find(p, "PetPuffin", 1, true) then
					table.insert(problems, p)
				end
			end
			T.expect(problems).toEqual({})
			T.expect(Items.PetPuffin.kind).toBe("Pet")
			T.expect(Items.PetPuffin.price > 0).toBe(true)
			T.expect(Cosmetics.productFor("PetPuffin").productId).toBe(3720011582)
			T.expect(Cosmetics.itemFor(3720011582)).toBe("PetPuffin")
			T.expect(game.ReplicatedStorage.ItemModels:FindFirstChild(Items.PetPuffin.model) ~= nil).toBe(true)
		end)

		T.it("is lent to new players for their first voyages, with no timer, then goes home", function()
			local n = Config.PET_LOAN_VOYAGES
			local pet, loan = PetRules.active(nil, false, 0, n, isPet)
			T.expect(pet).toBe("PetPuffin")
			T.expect(loan).toBe(true)
			pet = PetRules.active(nil, false, n, n, isPet)
			T.expect(pet).toBe(nil)
			T.expect(PetRules.loanJustEnded(false, n, n)).toBe(true)
			T.expect(PetRules.loanJustEnded(false, n + 1, n)).toBe(false)
			local owned, ownedLoan = PetRules.active("PetPuffin", true, 50, n, isPet)
			T.expect(owned).toBe("PetPuffin")
			T.expect(ownedLoan).toBe(false)
			T.expect((PetRules.active(nil, true, 0, n, isPet))).toBe(nil) -- owns one but left it off: no loaner
		end)

		T.it("is kept as owned (not counted) when bought or granted", function()
			local GrantService = T.require(game.ServerScriptService.Server.GrantService)
			local data: any = { Pearls = 0, Owned = {}, Counts = {}, Grants = {} }
			T.expect((GrantService.apply(data, "receipt:pet1", { Items = { PetPuffin = 1 } }, 0))).toBe("granted")
			T.expect(data.Owned.PetPuffin).toBe(true)
			T.expect(data.Counts.PetPuffin).toBe(nil)
		end)

		T.it("every pet is earnable, has its model and a known way to move, and fetches like Puffin Pal (PET.2)", function()
			local n = 0
			for id, item in Items do
				if type(item) == "table" and item.kind == "Pet" then
					n += 1
					T.expect((type(item.price) == "number" and item.price > 0) or item.reward == "chest").toBe(true)
					T.expect(game.ReplicatedStorage.ItemModels:FindFirstChild(item.model or id) ~= nil).toBe(true)
					T.expect(item.petMotion == nil or item.petMotion == "fly" or item.petMotion == "float" or item.petMotion == "walk").toBe(true)
					-- no pet has its own reach, speed or loot: PetRules and Config are the same for all
					T.expect(item.range == nil and item.speed == nil and item.fetches == nil).toBe(true)
				end
			end
			T.expect(n >= 5).toBe(true)
		end)

		T.it("fetches only landed Shells, the nearest one within reach that no other pet is fetching", function()
			local owner = Vector3.new(0, 0, 0)
			local drops = {
				{ kind = "SeaGlass", position = Vector3.new(1, 0, 0), landed = true },
				{ kind = "Shells", position = Vector3.new(2, 0, 0), landed = false },
				{ kind = "Shells", position = Vector3.new(10, 0, 0), landed = true },
				{ kind = "Shells", position = Vector3.new(6, 0, 0), landed = true },
				{ kind = "Shells", position = Vector3.new(40, 0, 0), landed = true },
			}
			T.expect(PetRules.pick(owner, drops, 24)).toBe(4)
			T.expect(PetRules.pick(owner, { drops[5] }, 24)).toBe(nil)
			drops[4].claimed = true -- another pet is already flying to it
			T.expect(PetRules.pick(owner, drops, 24)).toBe(3)
		end)
	end)
end
