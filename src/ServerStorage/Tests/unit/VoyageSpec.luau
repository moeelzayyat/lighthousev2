--!strict
-- R1.2: Voyage.pearlsFor reproduces the pre-R1.2 GameState payout (1 per night survived + 5 for a win).
return function(T: any)
	local Voyage = T.require(game.ServerScriptService.Server.Voyage)
	local Config = T.require(game.ReplicatedStorage.Shared.Config)

	-- verbatim pre-R1.2 formula (GameState.luau 532-537 at 854f4e9), used as the oracle
	local function today(nightReached: number, won: boolean, c: any): number
		local survived = if won then c.NIGHTS_TO_WIN else math.max(0, nightReached - 1)
		local earned = (c.PEARLS_PER_NIGHT or 0) * survived + (c.PEARLS_NIGHT_STEP or 0) * survived * (survived + 1) / 2
		if won then
			earned += c.PEARLS_VICTORY_BONUS
		end
		return earned
	end

	T.describe("pearlsFor", function()
		T.it("win 7 = 12, win 13 = 18", function()
			T.expect(Voyage.pearlsFor(7, true, Config)).toBe(12)
			T.expect(Voyage.pearlsFor(13, true, Config)).toBe(18)
		end)

		T.it("loss at night n pays n - 1 (never negative)", function()
			for n = 1, 13 do
				T.expect(Voyage.pearlsFor(n, false, Config)).toBe(n - 1)
			end
			T.expect(Voyage.pearlsFor(0, false, Config)).toBe(0)
		end)

		T.it("matches the pre-R1.2 GameState payout for every night and outcome", function()
			for n = 0, 13 do
				T.expect(Voyage.pearlsFor(n, false, Config)).toBe(today(n, false, Config))
			end
			-- GameState passes NIGHTS_TO_WIN as the night reached on a win
			T.expect(Voyage.pearlsFor(Config.NIGHTS_TO_WIN, true, Config)).toBe(today(Config.NIGHTS_TO_WIN, true, Config))
		end)

		T.it("keeps the legacy triangular step when PEARLS_NIGHT_STEP is set", function()
			local c = table.clone(Config)
			c.PEARLS_PER_NIGHT = 0
			c.PEARLS_NIGHT_STEP = 1
			c.PEARLS_VICTORY_BONUS = 0
			c.NIGHTS_TO_WIN = 3
			T.expect(Voyage.pearlsFor(3, true, c)).toBe(6)
			T.expect(Voyage.pearlsFor(3, false, c)).toBe(today(3, false, c))
		end)
	end)
end
