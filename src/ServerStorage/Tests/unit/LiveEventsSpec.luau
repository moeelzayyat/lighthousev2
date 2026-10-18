--!strict
-- LO.1: live events switch on and off by their server-time window, and an event voyage is offered only while its
-- event is on (the crew card, the server's ChooseVoyage check and the departure all ask LiveEvents).
return function(T: any)
	local LiveEvents = T.require(game.ReplicatedStorage.Shared.Definitions.LiveEvents)
	local Voyages = T.require(game.ReplicatedStorage.Shared.Definitions.Voyages)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)

	local function problems(events: any, voyages: any?): { string }
		local all = table.clone(Registry.catalogs())
		all.LiveEvents = events
		if voyages then
			all.Voyages = voyages
		end
		local out = {}
		for _, p in Registry.check(all) do
			if string.sub(p, 1, 11) == "LiveEvents." or string.sub(p, 1, 8) == "Voyages." then
				table.insert(out, p)
			end
		end
		return out
	end

	T.describe("windows", function()
		T.it("an event is on from its start (inclusive) to its end (exclusive)", function()
			local ev = LiveEvents.ShipwreckRescue
			T.expect(LiveEvents.isOn("ShipwreckRescue", ev.starts - 1)).toBe(false)
			T.expect(LiveEvents.isOn("ShipwreckRescue", ev.starts)).toBe(true)
			T.expect(LiveEvents.isOn("ShipwreckRescue", ev.ends - 1)).toBe(true)
			T.expect(LiveEvents.isOn("ShipwreckRescue", ev.ends)).toBe(false)
			T.expect(LiveEvents.isOn("NoSuchEvent", ev.starts)).toBe(false)
			T.expect(LiveEvents.active(ev.starts)).toEqual({ "ShipwreckRescue" })
			T.expect(LiveEvents.active(ev.ends)).toEqual({})
		end)
	end)

	T.describe("the catalogue", function()
		T.it("passes the registry; the Rescue voyage and its event name each other", function()
			T.expect(problems(LiveEvents)).toEqual({})
			T.expect(Voyages.Rescue.event).toBe("ShipwreckRescue")
			T.expect(LiveEvents.ShipwreckRescue.voyage).toBe("Rescue")
			T.expect(Voyages.Rescue.unlock).toBe(nil)
		end)

		T.it("a window that ends before it starts, or an event voyage with an unlock, fails the boot", function()
			local bad: any = table.clone(LiveEvents)
			bad.ShipwreckRescue = table.clone(LiveEvents.ShipwreckRescue)
			bad.ShipwreckRescue.ends = bad.ShipwreckRescue.starts - 10
			local found = table.concat(problems(bad), "\n")
			T.expect(found).toContain("LiveEvents.ShipwreckRescue.ends: must come after starts")
			local voyages = table.clone(Voyages)
			voyages.Rescue = table.clone(Voyages.Rescue)
			voyages.Rescue.unlock = "LongVoyage"
			T.expect(table.concat(problems(LiveEvents, voyages), "\n")).toContain("needs no unlock")
		end)
	end)

	T.describe("wiring", function()
		T.it("the crew card, ChooseVoyage and the departure all check the window", function()
			local departure = (game.StarterPlayer.StarterPlayerScripts.Client.Departure :: any).Source :: string
			local encounter = (game.ServerScriptService.Server.Domains.Encounter :: any).Source :: string
			local gameState = (game.ServerScriptService.Server.GameState :: any).Source :: string
			T.expect(departure).toContain("LiveEvents.isOn(def.event, Workspace:GetServerTimeNow())")
			T.expect(encounter).toContain("LiveEvents.isOn(def.event, os.time())")
			T.expect(gameState).toContain("LiveEvents.isOn(def.event, os.time())")
		end)
	end)
end
