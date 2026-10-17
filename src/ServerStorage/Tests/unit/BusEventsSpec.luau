--!strict
-- S5.3: callback wiring moved onto the event bus. The new events validate against the catalog, a handler
-- that does not yield has run by the time Publish returns (ShipDeparture relies on it), and no server module
-- still hands another one a callback.
return function(T: any)
	local EventBus = T.require(game.ServerScriptService.Server.EventBus)
	local Events = T.require(game.ReplicatedStorage.Shared.Events)

	local function newBus()
		local warnings = {}
		local bus = EventBus.new(Events, function(text: string)
			table.insert(warnings, text)
		end)
		return bus, warnings
	end

	local V = "v1"
	local samples: { [string]: any } = {
		BootCompleted = { Domains = { "Platform", "Network" } },
		CrewRosterChanged = { ShipId = "Ship1" },
		ProfileChanged = { UserId = 1 },
		Refuelled = { VoyageId = V, UserId = 1, Amount = 30, FuelBefore = 5, Night = true },
		ReserveUsed = { VoyageId = V, Reason = "night1safety" },
		LampDark = { VoyageId = V },
		LampLit = { VoyageId = V, Seconds = 3.5 },
		TowerRepaired = { VoyageId = V, UserId = 1, Amount = 20, IntegrityBefore = 60 },
		CannonBuilt = { VoyageId = V, UserId = 1, Pad = 2, Level = 1 },
		CannonReloaded = { VoyageId = V, UserId = 1, Pad = 2, Level = 1 },
		CannonDestroyed = { VoyageId = V, Pad = 2, Level = 2 },
		CreatureSpawned = { VoyageId = V, CreatureId = 7, DefId = "Crab", Big = false },
		CreatureKilled = { VoyageId = V, CreatureId = 7, DefId = "Crab", Source = "FocusedBeam", KillerId = 1, X = 1, Y = 2, Z = 3, Big = false },
		BossWarning = { VoyageId = V, DefId = "BarnacleBrute", Night = 4 },
		BossDefeated = { VoyageId = V, DefId = "BarnacleBrute" },
		LootCollected = { VoyageId = V, UserId = 1, ItemId = "Shells", Qty = 2 },
		ShellsChanged = { VoyageId = V, Delta = -40, Reason = "upgrade" },
		UpgradeBought = { VoyageId = V, UserId = 1, Id = "LensPower", Rank = 1 },
		EvolutionUnlocked = { VoyageId = V, Id = "OverchargedBeam" },
		DawnLootWindow = { VoyageId = V, Seconds = 25 },
		ShopPurchase = { UserId = 1, ItemId = "AmmoCrate", Price = 10, Currency = "Pearls" },
	}

	T.describe("catalog", function()
		T.it("accepts every S5.3 event with a real payload", function()
			local bus = newBus()
			for name, payload in samples do
				local ok, why = bus.validate(name, payload)
				if not ok then
					error(name .. ": " .. tostring(why))
				end
			end
		end)

		T.it("rejects a kill without a position and a payload that carries an Instance", function()
			local bus = newBus()
			T.expect((bus.validate("CreatureKilled", { VoyageId = V, CreatureId = 7, DefId = "Crab", Source = "Cannon", Big = false }))).toBe(false)
			T.expect((bus.validate("ProfileChanged", { UserId = 1, Player = workspace }))).toBe(false)
		end)
	end)

	T.describe("delivery", function()
		T.it("runs a handler that does not yield before Publish returns", function()
			local bus = newBus()
			local heard: string? = nil
			bus.Subscribe("CrewRosterChanged", function(e: any)
				heard = e.ShipId
			end)
			bus.Publish("CrewRosterChanged", { ShipId = "Ship1" })
			T.expect(heard).toBe("Ship1")
		end)

		T.it("keeps the publisher running when a handler fails", function()
			local bus, warnings = newBus()
			local after = 0
			bus.Subscribe("CreatureKilled", function()
				error("boom")
			end)
			bus.Subscribe("CreatureKilled", function()
				after += 1
			end)
			T.expect(bus.Publish("CreatureKilled", samples.CreatureKilled)).toBe(true)
			T.expect(after).toBe(1)
			T.expect(#warnings).toBe(1)
		end)
	end)

	T.describe("no callback wiring left (S5.3)", function()
		T.it("no server module assigns a callback on another or uses the old setters", function()
			local patterns = {
				"%.onKilled%s*=",
				"%.onChanged%s*=",
				"%.onChange%s*=",
				"%.colorFor%s*=",
				"setOilHandlers",
				"setCrateHandlers",
				"autoSell%s*=",
			}
			local found = {}
			for _, d in game.ServerScriptService.Server:GetDescendants() do
				if d:IsA("LuaSourceContainer") then
					local source = (d :: any).Source :: string
					for _, pattern in patterns do
						if string.find(source, pattern) then
							table.insert(found, d.Name .. " " .. pattern)
						end
					end
				end
			end
			T.expect(found).toEqual({})
		end)
	end)
end
