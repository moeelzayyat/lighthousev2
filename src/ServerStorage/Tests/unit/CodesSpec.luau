--!strict
-- L1.4: codes pay once per profile, through GrantService, and creator codes give a cosmetic only.
return function(T: any)
	local CodeService = T.require(game.ServerScriptService.Server.CodeService)
	local GrantService = T.require(game.ServerScriptService.Server.GrantService)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)
	local Codes = T.require(game.ReplicatedStorage.Shared.Definitions.Codes)

	-- one player with a real profile table; grants go through GrantService.apply (the claim logic itself)
	local function world(now: number?)
		local profile = { Pearls = 0, Owned = {}, Counts = {}, Grants = {}, RedeemedCodes = {} }
		local w = { profile = profile, logs = 0, loaded = true }
		w.deps = {
			data = function(_player: any)
				return if w.loaded then profile else nil
			end,
			mutate = function(_player: any, fn: (any) -> boolean, _saveNow: boolean?)
				fn(profile)
				return true
			end,
			grant = function(_player: any, claimId: string, rewards: any, _source: string)
				return (GrantService.apply(profile, claimId, rewards, 1000))
			end,
			now = function()
				return now or 1760700000
			end,
			log = function()
				w.logs += 1
			end,
		}
		return w
	end
	local player = { Name = "Tester", UserId = 7 }

	local function problems(codes: any): { string }
		local all = table.clone(Registry.catalogs())
		all.Codes = codes
		local out = {}
		for _, p in Registry.check(all) do
			if string.sub(p, 1, 6) == "Codes." or string.sub(p, 1, 6) == "Items." then
				table.insert(out, p)
			end
		end
		return out
	end

	T.describe("redeeming", function()
		T.it("a promo code pays its Pearls once, whatever its case and spaces", function()
			local w = world()
			local ok, message = CodeService.redeem(player, "  lighthouse ", w.deps)
			T.expect(ok).toBe(true)
			T.expect(message).toContain("10 Pearls")
			T.expect(w.profile.Pearls).toBe(10)
			T.expect((w.profile.RedeemedCodes :: any).LIGHTHOUSE).toBe(true)
			local again, why = CodeService.redeem(player, "LIGHTHOUSE", w.deps)
			T.expect(again).toBe(false)
			T.expect(why).toBe("You already used that code.")
			T.expect(w.profile.Pearls).toBe(10)
		end)

		T.it("still once after the 30-day claim prune (RedeemedCodes is kept for good)", function()
			local w = world()
			CodeService.redeem(player, "LIGHTHOUSE", w.deps)
			w.profile.Grants = {} -- as if GrantService had pruned the old claim
			local again = CodeService.redeem(player, "LIGHTHOUSE", w.deps)
			T.expect(again).toBe(false)
			T.expect(w.profile.Pearls).toBe(10)
		end)

		T.it("a claim already granted (a crash before RedeemedCodes was written) is not paid twice", function()
			local w = world()
			GrantService.apply(w.profile, "code:LIGHTHOUSE", { Pearls = 10 }, 1000)
			local ok, why = CodeService.redeem(player, "LIGHTHOUSE", w.deps)
			T.expect(ok).toBe(false)
			T.expect(why).toBe("You already used that code.")
			T.expect(w.profile.Pearls).toBe(10)
			T.expect((w.profile.RedeemedCodes :: any).LIGHTHOUSE).toBe(true)
		end)

		T.it("a creator code gives its cosmetic", function()
			local w = world()
			local ok, message = CodeService.redeem(player, "keeper", w.deps)
			T.expect(ok).toBe(true)
			T.expect(message).toContain("Keeper's Glow")
			T.expect((w.profile.Owned :: any).BeamKeepersGlow).toBe(true)
			T.expect(w.profile.Pearls).toBe(0)
		end)

		T.it("bad, unknown, expired and too-early codes change nothing", function()
			local w = world()
			for _, text in { "", "   ", "NOSUCHCODE", "LIGHT-HOUSE", string.rep("A", 33), string.rep("A", 100) } do
				local ok, why = CodeService.redeem(player, text, w.deps)
				T.expect(ok).toBe(false)
				T.expect(why).toBe("That code isn't valid.")
			end
			T.expect(CodeService.redeem(player, 42, w.deps)).toBe(false)
			w.loaded = false
			local ok, why = CodeService.redeem(player, "LIGHTHOUSE", w.deps)
			T.expect(ok).toBe(false)
			T.expect(why).toContain("still loading")
			T.expect(w.profile.Pearls).toBe(0)
			T.expect(w.profile.Grants).toEqual({})
			-- an expired code
			local w2 = world(1760700000)
			local deps2: any = w2.deps
			deps2.codes = { ORDER = { "Old" }, Old = { code = "LIGHTHOUSE", kind = "promo", reward = { Pearls = 10 }, expires = 1760000000, note = "test" } }
			local expired, text = CodeService.redeem(player, "LIGHTHOUSE", w2.deps)
			T.expect(expired).toBe(false)
			T.expect(text).toBe("That code has expired.")
			T.expect(w2.profile.Pearls).toBe(0)
		end)
	end)

	T.describe("the catalogue", function()
		T.it("passes the registry; a creator code giving power or Pearls fails the boot", function()
			T.expect(problems(Codes)).toEqual({})
			local bad = table.clone(Codes)
			bad.Keeper = { code = "KEEPER", kind = "creator", reward = { Items = { StormHarpoon = 1 }, Pearls = 5 }, note = "bad" }
			bad.Lower = { code = "lower", kind = "promo", reward = { Pearls = 500 }, note = "bad" }
			bad.Twin = { code = "LIGHTHOUSE", kind = "promo", reward = { Pearls = 5 }, note = "bad" }
			bad.ORDER = { "Lighthouse", "Keeper", "Lower", "Twin" }
			local found = table.concat(problems(bad), "\n")
			T.expect(found).toContain("must be a cosmetic")
			T.expect(found).toContain("gives a cosmetic and nothing else")
			T.expect(found).toContain("capital letters")
			T.expect(found).toContain("Codes.Lower.reward.Pearls")
			T.expect(found).toContain("used twice")
		end)

		T.it("the creator beam colour is earned, never sold", function()
			local item = T.require(game.ReplicatedStorage.Shared.Items).BeamKeepersGlow
			T.expect(item.reward).toBe("code")
			T.expect(item.price).toBe(nil)
		end)
	end)

	T.describe("wiring", function()
		T.it("LiveOps answers CodeRedeem through NetGuard at the contract rate", function()
			local liveOps = (game.ServerScriptService.Server.Domains.LiveOps :: any).Source :: string
			T.expect(liveOps).toContain("NetGuard.connect(ctx.remotes.CodeRedeem")
			T.expect(liveOps).toContain("NetGuard.allow(player, \"CodeRedeem\")")
			T.expect(T.require(game.ServerScriptService.Server.NetGuard).RATES.CodeRedeem).toEqual({ 0.1, 1 })
		end)
	end)
end
