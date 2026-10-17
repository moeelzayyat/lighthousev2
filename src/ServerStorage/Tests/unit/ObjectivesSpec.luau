--!strict
-- S7.2: one daily objective per player from the pool, paid once, and missing a day changes nothing (tested with
-- an advanced clock).
return function(T: any)
	local Objectives = T.require(game.ReplicatedStorage.Shared.Definitions.Objectives)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)
	local ObjectiveService = T.require(game.ServerScriptService.Server.ObjectiveService)

	local DAY = 86400
	local T0 = 1760659200 -- 2025-10-17 00:00 UTC
	local function source(inst: Instance): string
		return (inst :: any).Source
	end
	-- an account whose objective on the first test day is `id`
	local function userFor(id: string, now: number): number
		local day = Objectives.dayKey(now)
		for userId = 1, 500 do
			if Objectives.pick(userId, day) == id then
				return userId
			end
		end
		error("no account picks " .. id)
	end

	T.describe("the pool", function()
		T.it("passes the registry; one objective a day per account, from the pool", function()
			local problems = {}
			for _, p in Registry.check(Registry.catalogs()) do
				if string.sub(p, 1, 11) == "Objectives." then
					table.insert(problems, p)
				end
			end
			T.expect(problems).toEqual({})
			T.expect(Objectives.dayKey(T0)).toBe("2025-10-17")
			local seen: { [string]: boolean } = {}
			for d = 0, 29 do
				local id = Objectives.pick(42, Objectives.dayKey(T0 + d * DAY))
				T.expect(table.find(Objectives.ORDER, id) ~= nil).toBe(true)
				T.expect(Objectives.pick(42, Objectives.dayKey(T0 + d * DAY + 3600))).toBe(id) -- same all day
				seen[id] = true
			end
			local kinds = 0
			for _ in seen do
				kinds += 1
			end
			T.expect(kinds >= 3).toBe(true)
		end)
	end)

	T.describe("progress", function()
		T.it("counts its own event, finishes once, and pays once", function()
			local user = userFor("DeliverOil", T0)
			local state = { DayKey = "", Progress = {}, Claimed = {} }
			local done = nil
			for i = 1, 12 do
				local d = Objectives.count(state, user, T0 + i, "Refuelled", 1)
				if d then
					T.expect(done).toBe(nil)
					done = d
					T.expect(i).toBe(10)
				end
			end
			T.expect(done).toBe("DeliverOil")
			T.expect(Objectives.count(state, user, T0 + 20, "TowerRepaired", 1)).toBe(nil) -- another objective's event
			T.expect(state.Progress.DeliverOil).toBe(10)
		end)

		T.it("a night objective counts the night reached", function()
			local user = userFor("SurviveNight4", T0)
			local state = { DayKey = "", Progress = {}, Claimed = {} }
			T.expect(Objectives.count(state, user, T0, "NightSurvived", 2)).toBe(nil)
			T.expect(Objectives.count(state, user, T0, "NightSurvived", 1)).toBe(nil)
			T.expect(state.Progress.SurviveNight4).toBe(2)
			T.expect(Objectives.count(state, user, T0, "NightSurvived", 4)).toBe("SurviveNight4")
		end)

		T.it("missing a day changes nothing: a new day just starts a fresh objective", function()
			local user = userFor("DeliverOil", T0)
			local state = { DayKey = "", Progress = {}, Claimed = {} }
			for _ = 1, 6 do
				Objectives.count(state, user, T0, "Refuelled", 1)
			end
			local later = T0 + 3 * DAY -- two days skipped
			local id = Objectives.rollOver(state, user, later)
			T.expect(state.DayKey).toBe(Objectives.dayKey(later))
			T.expect(state.Progress).toEqual({})
			T.expect(state.Claimed).toEqual({})
			T.expect(id).toBe(Objectives.pick(user, Objectives.dayKey(later)))
			local keys = {}
			for k in state do
				table.insert(keys, k)
			end
			table.sort(keys)
			T.expect(keys).toEqual({ "Claimed", "DayKey", "Progress" }) -- no streak or missed-day counter anywhere
			-- the same account on the same day, after a gap, gets exactly what it would have got without the gap
			local fresh = { DayKey = "", Progress = {}, Claimed = {} }
			T.expect(Objectives.rollOver(fresh, user, later)).toBe(id)
		end)
	end)

	T.describe("from the bus", function()
		T.it("pays the Pearls once with a day-scoped claim", function()
			local user = userFor("RepairTower", T0)
			local player: any = { UserId = user, data = { Objectives = { DayKey = "", Progress = {}, Claimed = {} } }, attrs = {} }
			player.SetAttribute = function(self: any, k: string, v: any)
				self.attrs[k] = v
			end
			local handlers: { [string]: (any) -> () } = {}
			local grants = {}
			ObjectiveService.start({
				subscribe = function(name: string, h: (any) -> ())
					handlers[name] = h
					return nil
				end,
				publish = function() end,
				byUserIds = function()
					return { player }
				end,
				data = function()
					return player.data
				end,
				mutate = function(_p: any, fn: (any) -> boolean)
					fn(player.data)
					return true
				end,
				grant = function(_p: any, claimId: string, rewards: any)
					table.insert(grants, claimId .. " " .. rewards.Pearls)
					return "granted"
				end,
				notify = function() end,
				now = function()
					return T0 + 100
				end,
			})
			handlers.ProfileLoaded({ UserId = user })
			T.expect(player.attrs.ObjectiveText).toBe("Repair the tower 5 times")
			for _ = 1, 7 do
				handlers.TowerRepaired({ UserId = user })
			end
			T.expect(grants).toEqual({ "objective:2025-10-17:RepairTower 3" })
			T.expect(player.attrs.ObjectiveProgress).toBe(5)
			T.expect(player.attrs.ObjectiveDone).toBe(true)
		end)

		T.it("the LiveOps domain starts it; the event is in the catalog", function()
			T.expect(source(game.ServerScriptService.Server.Domains.LiveOps)).toContain("ObjectiveService.start({")
			local Events = T.require(game.ReplicatedStorage.Shared.Events)
			T.expect(Events.ObjectiveCompleted).toEqual({ UserId = "number", ObjectiveId = "string" })
		end)
	end)
end
