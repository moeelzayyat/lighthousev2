--!strict
-- S2.2: Pearls banked at each dawn. Totals stay the owner-approved ones (1 per night, +5 for a win);
-- only the moment of granting moves from Results to each dawn.
return function(T: any)
	local DawnBanking = T.require(game.ServerScriptService.Server.DawnBanking)
	local Voyage = T.require(game.ServerScriptService.Server.Voyage)
	local EventBus = T.require(game.ServerScriptService.Server.EventBus)
	local Events = T.require(game.ReplicatedStorage.Shared.Events)
	local Config = T.require(game.ReplicatedStorage.Shared.Config)

	-- A grant that behaves like GrantService: a claim id is applied once.
	local function fakeDeps()
		local claims: { [string]: boolean } = {}
		local log = { grants = {} :: { string }, notified = {} :: { string }, pearls = {} :: { [number]: number } }
		local deps = {
			config = Config,
			grant = function(userId: number, claimId: string, rewards: { Pearls: number }): string
				if claims[claimId] then
					return "duplicate"
				end
				claims[claimId] = true
				table.insert(log.grants, claimId)
				log.pearls[userId] = (log.pearls[userId] or 0) + rewards.Pearls
				return "granted"
			end,
			notify = function(userId: number, amount: number)
				table.insert(log.notified, userId .. "+" .. amount)
			end,
		}
		return deps, log
	end

	T.describe("Voyage dawn rules", function()
		T.it("dawn Pearls add up to the voyage's night Pearls; Results pays only what is left", function()
			local banked = 0
			for n = 1, 7 do
				banked += Voyage.dawnPearls(n, Config)
			end
			T.expect(banked).toBe(7)
			T.expect(Voyage.resultPearls(7, true, banked, Config)).toBe(5) -- Standard win: 7 + 5 = 12
			T.expect(Voyage.resultPearls(5, false, 4, Config)).toBe(0) -- lost on night 5: 4 already banked
			T.expect(Voyage.resultPearls(13, true, 13, Config)).toBe(5) -- Long win: 13 + 5 = 18
			T.expect(Voyage.resultPearls(3, false, 0, Config)).toBe(2) -- nothing banked (left before dawn): Results pays as before
			T.expect(Voyage.resultPearls(1, false, 3, Config)).toBe(0) -- never negative
		end)

		T.it("the legacy triangular step is banked night by night too", function()
			local c = table.clone(Config)
			c.PEARLS_PER_NIGHT = 0
			c.PEARLS_NIGHT_STEP = 1
			c.PEARLS_VICTORY_BONUS = 0
			local banked = 0
			for n = 1, 4 do
				banked += Voyage.dawnPearls(n, c)
			end
			T.expect(banked).toBe(Voyage.pearlsFor(5, false, c))
		end)

		T.it("claim id is voyageId:night<n>:userId", function()
			T.expect(Voyage.dawnClaimId("c9dff3a0", 3, 11752219158)).toBe("c9dff3a0:night3:11752219158")
		end)
	end)

	T.describe("DawnBanking", function()
		T.it("each dawn grants every crew member that night's Pearl and tells their client", function()
			local deps, log = fakeDeps()
			for n = 1, 4 do
				DawnBanking.bank("vA", n, { 5, 6 }, deps)
			end
			T.expect(log.pearls[5]).toBe(4)
			T.expect(log.pearls[6]).toBe(4)
			T.expect(DawnBanking.bankedFor("vA", 5)).toBe(4)
			T.expect(log.grants[1]).toBe("vA:night1:5")
			T.expect(#log.notified).toBe(8)
			T.expect(log.notified[1]).toBe("5+1")
			DawnBanking.forget("vA")
			T.expect(DawnBanking.bankedFor("vA", 5)).toBe(0)
		end)

		T.it("a replayed dawn grants once and is counted once", function()
			local deps, log = fakeDeps()
			DawnBanking.bank("vB", 1, { 7 }, deps)
			DawnBanking.bank("vB", 2, { 7 }, deps)
			DawnBanking.bank("vB", 2, { 7 }, deps) -- replay
			T.expect(log.pearls[7]).toBe(2)
			T.expect(#log.grants).toBe(2)
			T.expect(#log.notified).toBe(2)
			T.expect(DawnBanking.bankedFor("vB", 7)).toBe(2)
			DawnBanking.forget("vB")
		end)

		T.it("a refused grant (player gone, no profile) banks nothing", function()
			local deps, log = fakeDeps()
			deps.grant = function(): string
				return "invalid"
			end
			DawnBanking.bank("vC", 1, { 8 }, deps)
			T.expect(DawnBanking.bankedFor("vC", 8)).toBe(0)
			T.expect(#log.notified).toBe(0)
		end)

		T.it("is driven by NightSurvived on the bus", function()
			local deps, log = fakeDeps()
			local bus = EventBus.new(Events, function() end)
			local stop = DawnBanking.start(bus, deps)
			bus.Publish("NightSurvived", { VoyageId = "vD", Night = 1, Crew = { 9 } })
			T.expect(log.grants).toEqual({ "vD:night1:9" })
			T.expect(DawnBanking.bankedFor("vD", 9)).toBe(1)
			stop()
			DawnBanking.forget("vD")
		end)
	end)
end
