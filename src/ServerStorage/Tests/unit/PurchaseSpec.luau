--!strict
-- L1.3: a Robux receipt is granted once. The same receipt again (Roblox retries, another server) answers "granted"
-- without a second grant; unknown products, the switch off, an absent buyer or an unloaded save answer "notYet"
-- (Roblox asks again later) and change nothing.
return function(T: any)
	local PurchaseService = T.require(game.ServerScriptService.Server.PurchaseService)
	local GrantService = T.require(game.ServerScriptService.Server.GrantService)
	local Cosmetics = T.require(game.ReplicatedStorage.Shared.Definitions.Cosmetics)

	-- a catalogue with the switch on and one product, so the tests do not depend on the live switch or ids
	local function catalog(enabled: boolean)
		local c = table.clone(Cosmetics)
		c.ROBUX_ENABLED = enabled
		c.ORDER = { "LanternTide" }
		c.LanternTide = { robux = 75, productId = 555 }
		c.itemFor = function(productId: number)
			return if enabled and productId == 555 then "LanternTide" else nil
		end
		return c
	end

	local function world(enabled: boolean)
		local profile = { Pearls = 0, Owned = {}, Counts = {}, Grants = {} }
		local buyer = { Name = "Buyer", UserId = 42 }
		local w = { profile = profile, present = true, loaded = true, grants = 0, notes = 0 }
		w.deps = {
			playerByUserId = function(userId: number)
				return if w.present and userId == 42 then buyer else nil
			end,
			loaded = function(_player: any)
				return w.loaded
			end,
			grant = function(_player: any, claimId: string, rewards: any, _source: string)
				local status = GrantService.apply(profile, claimId, rewards, 1000)
				if status == "granted" then
					w.grants += 1
				end
				return status
			end,
			log = function() end,
			notify = function()
				w.notes += 1
			end,
			nameOf = function(id: string)
				return id
			end,
			cosmetics = catalog(enabled),
		}
		return w
	end

	local function receipt(id: string, product: number?): any
		return { PurchaseId = id, PlayerId = 42, ProductId = product or 555, CurrencySpent = 75 }
	end

	T.describe("receipts", function()
		T.it("a receipt grants its cosmetic once, however often it arrives", function()
			local w = world(true)
			T.expect(PurchaseService.process(receipt("r-1"), w.deps)).toBe("granted")
			T.expect(PurchaseService.process(receipt("r-1"), w.deps)).toBe("granted")
			T.expect(PurchaseService.process(receipt("r-1"), w.deps)).toBe("granted")
			T.expect(w.grants).toBe(1)
			T.expect(w.notes).toBe(1)
			T.expect((w.profile.Owned :: any).LanternTide).toBe(true)
			T.expect(w.profile.Grants["receipt:r-1"] ~= nil).toBe(true)
		end)

		T.it("an absent buyer or an unloaded save waits (notYet) and is granted when it comes back", function()
			local w = world(true)
			w.present = false
			T.expect(PurchaseService.process(receipt("r-2"), w.deps)).toBe("notYet")
			w.present, w.loaded = true, false
			T.expect(PurchaseService.process(receipt("r-2"), w.deps)).toBe("notYet")
			T.expect(w.grants).toBe(0)
			w.loaded = true
			T.expect(PurchaseService.process(receipt("r-2"), w.deps)).toBe("granted")
			T.expect(w.grants).toBe(1)
		end)

		T.it("unknown products, the switch off and malformed receipts grant nothing", function()
			local w = world(true)
			T.expect(PurchaseService.process(receipt("r-3", 999), w.deps)).toBe("notYet")
			T.expect(PurchaseService.process({ PurchaseId = 5, PlayerId = 42, ProductId = 555 }, w.deps)).toBe("notYet")
			T.expect(PurchaseService.process(nil, w.deps)).toBe("notYet")
			local off = world(false)
			T.expect(PurchaseService.process(receipt("r-4"), off.deps)).toBe("notYet")
			T.expect(w.grants + off.grants).toBe(0)
		end)

		T.it("two different receipts for the same product are two purchases", function()
			local w = world(true)
			PurchaseService.process(receipt("r-5"), w.deps)
			PurchaseService.process(receipt("r-6"), w.deps)
			T.expect(w.grants).toBe(2) -- the item stays owned once; both receipts are honoured
			T.expect((w.profile.Owned :: any).LanternTide).toBe(true)
		end)
	end)
end
