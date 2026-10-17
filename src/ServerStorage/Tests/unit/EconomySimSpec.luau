--!strict
-- L1.1: no unbounded Pearl inflow. Every Pearl source is known to the simulation, every voyage's Pearls stay under
-- a bound made of nights × crew, and the one-time and daily sources are finite. The 10,000-voyage report itself
-- is run with execute_luau and pasted into the checkpoint record.
return function(T: any)
	local EconomySim = T.require(game.ServerStorage.Tests.sim.EconomySim)
	local Shared = game.ReplicatedStorage.Shared
	local catalogs = {
		Config = T.require(Shared.Config),
		Voyages = T.require(Shared.Definitions.Voyages),
		Items = T.require(Shared.Items),
		Boosts = T.require(Shared.Definitions.Boosts),
		Logbook = T.require(Shared.Definitions.Logbook),
		Objectives = T.require(Shared.Definitions.Objectives),
	}

	T.describe("Pearl sources", function()
		T.it("every GrantService source in the game is one the simulation counts", function()
			local unknown = {}
			for _, inst in game.ServerScriptService:GetDescendants() do
				if inst:IsA("LuaSourceContainer") then
					local src = (inst :: any).Source :: string
					-- the last string argument of a Grant(...) call is its source
					for source in string.gmatch(src, "Grant%b()") do
						local name = string.match(source, "\"([%w ]+)\"%)$")
						if name and EconomySim.SOURCES[name] == nil then
							table.insert(unknown, inst.Name .. ": " .. name)
						end
					end
					for name in string.gmatch(src, "grant%([^\n]-\"([%w ]+)\"%)") do
						if EconomySim.SOURCES[name] == nil then
							table.insert(unknown, inst.Name .. ": " .. name)
						end
					end
				end
			end
			T.expect(unknown).toEqual({})
		end)

		T.it("nothing pays Pearls per kill or per sale today", function()
			T.expect(catalogs.Config.PEARLS_PER_AWARD).toBe(0)
			T.expect(catalogs.Config.PEARLS_NIGHT_STEP).toBe(0)
			for id, item in catalogs.Items do
				if type(item) == "table" and item.kind == "Material" then
					if item.sell ~= nil then
						error(id .. " sells for Pearls; add it to the simulation")
					end
				end
			end
		end)
	end)

	T.describe("bounds", function()
		T.it("one voyage pays at most nights + victory bonus + one max boss drop per boss", function()
			-- Standard solo: 7 + 5 + 2 bosses x 4; Long with 4 crew: 13 + 5 + 8 boss nights x 4 bosses x 4
			T.expect(EconomySim.maxPerVoyage(catalogs, "Standard", 1)).toBe(20)
			T.expect(EconomySim.maxPerVoyage(catalogs, "Long", 4)).toBe(146)
		end)

		T.it("2,000 simulated voyages never pass their bound, and the one-time Pearls are finite", function()
			local report = EconomySim.run(catalogs, 2000, 7)
			T.expect(report.overBound).toBe(0)
			T.expect(report.perVoyage.max <= report.bound).toBe(true)
			local logbookTotal = 0
			for _, id in catalogs.Logbook.ORDER do
				logbookTotal += catalogs.Logbook[id].reward
			end
			T.expect(report.oneTime <= logbookTotal).toBe(true)
			T.expect(report.voyagesToBuyAll ~= nil).toBe(true)
		end)

		T.it("the boost ranks bought stop at the +15% cap", function()
			local _, boosts = EconomySim.catalogueCost(catalogs)
			T.expect(boosts > 0).toBe(true)
			local all = 0
			for _, id in catalogs.Boosts.ORDER do
				for _, price in catalogs.Boosts[id].prices do
					all += price
				end
			end
			T.expect(boosts < all).toBe(true) -- the cap leaves some ranks unbought
		end)
	end)
end
