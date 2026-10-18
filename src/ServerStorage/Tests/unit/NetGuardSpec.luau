--!strict
-- R1.4: remote contract guards. Rates must match docs/API_CONTRACTS.md; 50x spam is held to the contract.

-- Client -> server remotes and their contract rate {sustained/s, burst} (API_CONTRACTS.md, R1.4)
local CONTRACT: { [string]: { number } } = {
	Attack = { 6, 10 },
	BeamControl = { 20, 30 },
	LampAction = { 4, 6 },
	LampShift = { 4, 6 },
	BuyUpgrade = { 3, 5 },
	ShopRequest = { 5, 8 },
	TraderRequest = { 3, 5 },
	LoadoutRequest = { 5, 8 },
	GearAction = { 2, 4 },
	SetReady = { 2, 3 },
	VoteRematch = { 2, 3 },
	EnterLobby = { 1, 2 },
	ReportDevice = { 1, 1 },
	CoachEvent = { 4, 8 },
	ForecastVote = { 3, 5 },
	AdminRequest = { 1, 3 },
	ChooseVoyage = { 2, 3 },
	MerchantRequest = { 5, 8 }, -- S6.2
	CodeRedeem = { 0.1, 1 }, -- L1.4
	SniperAction = { 3, 5 }, -- D-044
}

return function(T: any)
	local NetGuard = T.require(game.ServerScriptService.Server.NetGuard)
	local clock = T.clock(1000)

	T.beforeEach(function()
		clock.set(1000)
		NetGuard.now = clock.now
	end)

	T.describe("rates", function()
		T.it("every client-to-server remote has exactly its contract rate", function()
			for remote, rate in CONTRACT do
				T.expect(NetGuard.RATES[remote]).toEqual(rate)
			end
			for remote in NetGuard.RATES do
				T.expect(CONTRACT[remote] ~= nil).toBe(true)
			end
		end)

		T.it("an unknown remote fails loudly instead of passing unguarded", function()
			T.expect(function()
				NetGuard.allow({}, "NoSuchRemote")
			end).toThrow("no contract rate")
		end)
	end)

	T.describe("50x spam", function()
		T.it("in one instant, each remote accepts exactly its burst", function()
			for remote, rate in CONTRACT do
				local player = {}
				local accepted = 0
				for _ = 1, 50 do
					if NetGuard.allow(player, remote) then
						accepted += 1
					end
				end
				if accepted ~= rate[2] then
					error(string.format("%s accepted %d of 50, burst is %d", remote, accepted, rate[2]))
				end
			end
		end)

		T.it("spread over 1 second (50 Hz), accepted <= burst + rate", function()
			for remote, rate in CONTRACT do
				clock.set(2000)
				local player = {}
				local accepted = 0
				for _ = 1, 50 do
					if NetGuard.allow(player, remote) then
						accepted += 1
					end
					clock.advance(0.02)
				end
				if accepted > rate[2] + rate[1] then
					error(string.format("%s accepted %d in 1 s, limit %d", remote, accepted, rate[2] + rate[1]))
				end
			end
		end)

		T.it("refills at the sustained rate and caps at the burst", function()
			local b = NetGuard.newBucket(3, 5, 0)
			for _ = 1, 5 do
				T.expect(NetGuard.take(b, 0)).toBe(true)
			end
			T.expect(NetGuard.take(b, 0)).toBe(false)
			T.expect(NetGuard.take(b, 1 / 3 + 1e-9)).toBe(true) -- one token after 1/3 s
			T.expect(NetGuard.take(b, 1 / 3 + 1e-9)).toBe(false)
			-- a long pause refills to the burst, not beyond
			local n = 0
			for _ = 1, 20 do
				if NetGuard.take(b, 100) then
					n += 1
				end
			end
			T.expect(n).toBe(5)
		end)

		T.it("players have separate buckets; forget clears a player", function()
			local a, b = {}, {}
			T.expect(NetGuard.allow(a, "ReportDevice")).toBe(true)
			T.expect(NetGuard.allow(a, "ReportDevice")).toBe(false)
			T.expect(NetGuard.allow(b, "ReportDevice")).toBe(true)
			NetGuard.forget(a)
			T.expect(NetGuard.allow(a, "ReportDevice")).toBe(true)
		end)
	end)

	T.describe("replay map", function()
		T.it("returns the first result for a repeated requestId", function()
			local map = NetGuard.replayMap()
			local p = {}
			T.expect(map.get(p, "r1")).toBeNil()
			map.put(p, "r1", { true :: any, "bought" })
			T.expect(map.get(p, "r1")).toEqual({ true :: any, "bought" })
			T.expect(map.get({}, "r1")).toBeNil() -- per player
		end)

		T.it("is capped at 40 per player, oldest dropped first", function()
			local map = NetGuard.replayMap()
			local p = {}
			for i = 1, 50 do
				map.put(p, "req" .. i, { true :: any, i })
			end
			T.expect(map.size(p)).toBe(40)
			T.expect(map.get(p, "req10")).toBeNil()
			T.expect(map.get(p, "req11")).toEqual({ true :: any, 11 })
			T.expect(map.get(p, "req50")).toEqual({ true :: any, 50 })
		end)

		T.it("a requestId named like an internal key cannot corrupt it", function()
			local map = NetGuard.replayMap()
			local p = {}
			map.put(p, "order", { false :: any, "x" })
			map.put(p, "results", { false :: any, "y" })
			map.put(p, "next", { true :: any, "z" })
			T.expect(map.get(p, "order")).toEqual({ false :: any, "x" })
			T.expect(map.size(p)).toBe(3)
		end)
	end)

	T.describe("type guards", function()
		T.it("vectors: NaN and +/-inf rejected", function()
			local inf = math.huge
			T.expect(NetGuard.isFiniteVector3(Vector3.new(1, 2, 3))).toBe(true)
			T.expect(NetGuard.isFiniteVector3(Vector3.new(inf, 0, 0))).toBe(false)
			T.expect(NetGuard.isFiniteVector3(Vector3.new(0, -inf, 0))).toBe(false)
			T.expect(NetGuard.isFiniteVector3(Vector3.new(0, 0, 0 / 0))).toBe(false)
			T.expect(NetGuard.isFiniteVector3({ X = 1, Y = 2, Z = 3 })).toBe(false)
			T.expect(NetGuard.isFiniteVector3(nil)).toBe(false)
		end)

		T.it("numbers and request ids", function()
			T.expect(NetGuard.isFiniteNumber(90)).toBe(true)
			T.expect(NetGuard.isFiniteNumber(math.huge)).toBe(false)
			T.expect(NetGuard.isFiniteNumber(0 / 0)).toBe(false)
			T.expect(NetGuard.isFiniteNumber("90")).toBe(false)
			T.expect(NetGuard.isRequestId("abc")).toBe(true)
			T.expect(NetGuard.isRequestId("")).toBe(false)
			T.expect(NetGuard.isRequestId(string.rep("x", 41))).toBe(false)
			T.expect(NetGuard.isRequestId(42)).toBe(false)
		end)
	end)
end
