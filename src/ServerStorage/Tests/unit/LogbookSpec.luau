--!strict
-- S7.1: the logbook: entries come from the catalogs, each is discovered once, and a category's Pearls are paid
-- once when its last entry is found.
return function(T: any)
	local Logbook = T.require(game.ReplicatedStorage.Shared.Definitions.Logbook)
	local Creatures = T.require(game.ReplicatedStorage.Shared.Creatures)
	local Upgrades = T.require(game.ReplicatedStorage.Shared.Upgrades)
	local Forecasts = T.require(game.ReplicatedStorage.Shared.Forecasts)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)
	local LogbookService = T.require(game.ServerScriptService.Server.LogbookService)

	local entries = Logbook.entries(Creatures, Upgrades, Forecasts)
	local function source(inst: Instance): string
		return (inst :: any).Source
	end

	-- a fake bus and two crew members
	local function world()
		local w = { handlers = {} :: { [string]: (any) -> () }, published = {} :: { string }, grants = {} :: { string }, notes = 0 }
		local a = { UserId = 1, data = { Logbook = {} } }
		local b = { UserId = 2, data = { Logbook = {} } }
		w.a, w.b = a, b
		LogbookService.start({
			subscribe = function(name: string, handler: (any) -> ())
				w.handlers[name] = handler
				return nil
			end,
			publish = function(name: string, payload: any)
				table.insert(w.published, name .. " " .. payload.UserId .. " " .. payload.EntryId)
			end,
			crew = function()
				return { a, b }
			end,
			byUserIds = function(ids: { number })
				local list = {}
				for _, id in ids do
					table.insert(list, if id == 1 then a else b)
				end
				return list
			end,
			mutate = function(player: any, fn: (any) -> boolean)
				fn(player.data)
				return true
			end,
			grant = function(player: any, claimId: string, rewards: any, _source: string)
				table.insert(w.grants, player.UserId .. " " .. claimId .. " " .. rewards.Pearls)
				return "granted"
			end,
			notify = function()
				w.notes += 1
			end,
			forecast = function()
				return "FogBank"
			end,
		})
		return w
	end

	T.describe("the entries", function()
		T.it("come from the catalogs and pass the registry", function()
			T.expect(#entries.Creatures).toBe(7)
			T.expect(table.find(entries.Creatures, "SpitterEel") ~= nil).toBe(true)
			T.expect(entries.Bosses).toEqual({ "BarnacleBrute", "ShipwreckHermit" })
			T.expect(entries.Evolutions).toEqual({ "ClockworkBastion", "OverchargedBeam" })
			T.expect(#entries.Forecasts).toBe(3)
			local problems = {}
			for _, p in Registry.check(Registry.catalogs()) do
				if string.sub(p, 1, 8) == "Logbook." then
					table.insert(problems, p)
				end
			end
			T.expect(problems).toEqual({})
		end)

		T.it("each is discovered once; the last one finishes its category", function()
			local book = {}
			T.expect((Logbook.discover(book, entries, "Bosses", "BarnacleBrute"))).toBe(true)
			T.expect((Logbook.discover(book, entries, "Bosses", "BarnacleBrute"))).toBe(false)
			T.expect((Logbook.discover(book, entries, "Bosses", "NotAMonster"))).toBe(false)
			local isNew, finished = Logbook.discover(book, entries, "Bosses", "ShipwreckHermit")
			T.expect(isNew).toBe(true)
			T.expect(finished).toBe("Bosses")
			T.expect(book["Bosses:BarnacleBrute"]).toBe(true)
		end)
	end)

	T.describe("from the bus", function()
		T.it("kills fill the crew's logbooks and the category pays once", function()
			local w = world()
			for _, id in entries.Creatures do
				w.handlers.CreatureKilled({ DefId = id, Big = false })
			end
			for _, id in entries.Creatures do
				w.handlers.CreatureKilled({ DefId = id, Big = false }) -- again: nothing new
			end
			T.expect(#w.published).toBe(14)
			T.expect(w.grants).toEqual({ "1 logbook:Creatures:7 15", "2 logbook:Creatures:7 15" })
			T.expect(w.a.data.Logbook["Creatures:RockCrab"]).toBe(true)
			-- a big monster's kill is not a creature entry; its defeat is a boss entry
			w.handlers.CreatureKilled({ DefId = "BarnacleBrute", Big = true })
			T.expect(w.a.data.Logbook["Creatures:BarnacleBrute"]).toBe(nil)
			w.handlers.BossDefeated({ DefId = "BarnacleBrute" })
			T.expect(w.a.data.Logbook["Bosses:BarnacleBrute"]).toBe(true)
		end)

		T.it("evolutions and survived forecasts are entries too", function()
			local w = world()
			w.handlers.EvolutionUnlocked({ Id = "OverchargedBeam" })
			w.handlers.NightSurvived({ Night = 1, Crew = { 2 } })
			T.expect(w.a.data.Logbook["Evolutions:OverchargedBeam"]).toBe(true)
			T.expect(w.b.data.Logbook["Forecasts:FogBank"]).toBe(true)
			T.expect(w.a.data.Logbook["Forecasts:FogBank"]).toBe(nil)
			T.expect(w.notes).toBe(3)
		end)
	end)

	T.describe("wiring", function()
		T.it("the LiveOps domain starts it on the bus", function()
			T.expect(source(game.ServerScriptService.Server.Domains.LiveOps)).toContain("LogbookService.start({")
			local Events = T.require(game.ReplicatedStorage.Shared.Events)
			T.expect(Events.LogbookDiscovered).toEqual({ UserId = "number", EntryId = "string" })
		end)
	end)
end
