--!strict
-- S7.3: the harbor boards: a survived night reaches the board at the next flush (every 30 s, so within 60 s);
-- best nights only go up; the weekly board writes to a new store each Monday 00:00 UTC.
return function(T: any)
	local Leaderboards = T.require(game.ReplicatedStorage.Shared.Definitions.Leaderboards)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)
	local LeaderboardService = T.require(game.ServerScriptService.Server.LeaderboardService)

	local MONDAY = 1760918400 -- 2025-10-20 00:00 UTC, a Monday
	local function source(inst: Instance): string
		return (inst :: any).Source
	end

	-- in-memory stores and a fake clock
	local function world(voyage: string)
		local w = { now = MONDAY + 3600, stores = {} :: { [string]: { [string]: number } }, shown = {} :: { [string]: { string } }, handler = nil :: any, loop = nil :: any }
		LeaderboardService.start({
			subscribe = function(_name: string, h: (any) -> ())
				w.handler = h
				return nil
			end,
			storeFor = function(name: string)
				w.stores[name] = w.stores[name] or {}
				local s = w.stores[name]
				return {
					raise = function(key: string, value: number)
						s[key] = math.max(s[key] or 0, value)
					end,
					add = function(key: string, delta: number)
						s[key] = (s[key] or 0) + delta
					end,
					top = function(_n: number)
						local rows = {}
						for key, value in s do
							table.insert(rows, { key = key, value = value })
						end
						table.sort(rows, function(a, b)
							return a.value > b.value
						end)
						return rows
					end,
				}
			end,
			voyage = function()
				return voyage
			end,
			now = function()
				return w.now
			end,
			nameOf = function(userId: number)
				return "P" .. userId
			end,
			show = function(id: string, _title: string, rows: { string })
				w.shown[id] = rows
			end,
			every = function(seconds: number, fn: () -> ())
				T.expect(seconds <= 30).toBe(true) -- written and re-read at least twice a minute
				w.loop = fn
			end,
		})
		return w
	end

	T.describe("the boards", function()
		T.it("pass the registry; the weekly store changes on Monday 00:00 UTC", function()
			local problems = {}
			for _, p in Registry.check(Registry.catalogs()) do
				if string.sub(p, 1, 13) == "Leaderboards." then
					table.insert(problems, p)
				end
			end
			T.expect(problems).toEqual({})
			local weekly = Leaderboards.WeeklyNights
			local thisWeek = Leaderboards.storeName(weekly, MONDAY)
			T.expect(Leaderboards.storeName(weekly, MONDAY + 6 * 86400 + 86399)).toBe(thisWeek) -- Sunday 23:59:59
			T.expect(Leaderboards.storeName(weekly, MONDAY - 1) ~= thisWeek).toBe(true)
			T.expect(Leaderboards.storeName(weekly, MONDAY + 7 * 86400) ~= thisWeek).toBe(true)
			T.expect(Leaderboards.storeName(Leaderboards.BestNightStandard, MONDAY)).toBe("LK_BestNight_Standard_v1")
		end)
	end)

	T.describe("scores", function()
		T.it("a survived night shows at the next flush; best only goes up", function()
			local w = world("Standard")
			w.handler({ Night = 3, Crew = { 11, 12 } })
			w.handler({ Night = 2, Crew = { 11 } })
			T.expect(w.shown.BestNightStandard).toBe(nil) -- nothing written before the flush
			w.loop()
			T.expect(w.shown.BestNightStandard).toEqual({ "1. P11  3", "2. P12  3" })
			T.expect(w.shown.BestNightLong).toEqual({})
			table.sort(w.shown.WeeklyNights)
			T.expect(w.shown.WeeklyNights).toEqual({ "1. P11  2", "2. P12  1" })
			w.handler({ Night = 1, Crew = { 11 } })
			w.loop()
			T.expect(w.shown.BestNightStandard[1]).toBe("1. P11  3") -- a lower night never lowers it
		end)

		T.it("the weekly board starts empty in a new week; best nights stay", function()
			local w = world("Standard")
			w.handler({ Night = 5, Crew = { 21 } })
			w.loop()
			T.expect(#w.shown.WeeklyNights).toBe(1)
			w.now += 7 * 86400
			w.loop()
			T.expect(w.shown.WeeklyNights).toEqual({})
			T.expect(w.shown.BestNightStandard).toEqual({ "1. P21  5" })
		end)
	end)

	T.describe("wiring", function()
		T.it("LiveOps starts it with a Studio-only memory store; the lobby has the board", function()
			local liveOps = source(game.ServerScriptService.Server.Domains.LiveOps)
			T.expect(liveOps).toContain("LeaderboardService.start({")
			T.expect(liveOps).toContain("if RunService:IsStudio() then")
			T.expect(source(game.ServerScriptService.Server.LobbyBuilder)).toContain("leaderboard = board, -- S7.3")
		end)
	end)
end
