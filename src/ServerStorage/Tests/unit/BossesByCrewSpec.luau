--!strict
-- S6.1: on a boss night one big monster per crew member arrives, from evenly spread bearings, and each one
-- counts as BOSS_SLOTS (5) toward MAX_CREATURES.
return function(T: any)
	local WaveDirector = T.require(game.ServerScriptService.Server.WaveDirector)
	local Config = T.require(game.ReplicatedStorage.Shared.Config)

	local function source(inst: Instance): string
		return (inst :: any).Source
	end

	T.describe("boss bearings", function()
		T.it("gives one boss per crew member, clamped to 1..4", function()
			for crew = 1, 4 do
				T.expect(#WaveDirector.bossBearings(crew, 0)).toBe(crew)
			end
			T.expect(#WaveDirector.bossBearings(0, 0)).toBe(1)
			T.expect(#WaveDirector.bossBearings(6, 0)).toBe(4)
		end)

		T.it("spreads the bosses evenly around the tower from the offset", function()
			T.expect(WaveDirector.bossBearings(1, 30)).toEqual({ 30 })
			T.expect(WaveDirector.bossBearings(2, 30)).toEqual({ 30, 210 })
			T.expect(WaveDirector.bossBearings(3, 0)).toEqual({ 0, 120, 240 })
			T.expect(WaveDirector.bossBearings(4, 300)).toEqual({ 300, 30, 120, 210 })
		end)
	end)

	T.describe("creature slots", function()
		T.it("a boss counts as 5 toward MAX_CREATURES", function()
			T.expect(Config.BOSS_SLOTS).toBe(5)
			T.expect(WaveDirector.slotsUsed(10, 0, Config)).toBe(10)
			T.expect(WaveDirector.slotsUsed(0, 1, Config)).toBe(5)
			-- a crew of 4 on a boss night: 4 bosses leave room for 25 small creatures
			T.expect(Config.MAX_CREATURES - WaveDirector.slotsUsed(0, 4, Config)).toBe(25)
		end)

		T.it("the spawn cap and every spawn stream's wait use the slot count", function()
			local Server = game.ServerScriptService.Server
			T.expect(source(Server.CreatureService)).toContain("not stats.big and CreatureService.load() >= Config.MAX_CREATURES")
			T.expect(source(Server.CreatureService)).toContain("bosses * ((Config.BOSS_SLOTS or 1) - 1)")
			local _, waits = string.gsub(source(Server.GameState), "creatures%.load%(%) >= Config%.MAX_CREATURES", "")
			T.expect(waits).toBe(3) -- the wave, the swarm and (S6.5) the special monsters
			T.expect(string.find(source(Server.GameState), "creatures.count() >= Config.MAX_CREATURES", 1, true)).toBe(nil)
		end)

		T.it("boss nights spawn one boss per ready crew member", function()
			T.expect(source(game.ServerScriptService.Server.GameState)).toContain("WaveDirector.bossBearings(#readyPlayers(), math.random() * 360)")
		end)
	end)
end
