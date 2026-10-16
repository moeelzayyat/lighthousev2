--!strict
-- R1.6: the typed event bus (architecture §5.3) and the Analytics consumer.
return function(T: any)
	local EventBus = T.require(game.ServerScriptService.Server.EventBus)
	local Events = T.require(game.ReplicatedStorage.Shared.Events)
	local Analytics = T.require(game.ServerScriptService.Server.Analytics)

	local function quietBus()
		local warnings = {}
		local bus = EventBus.new(Events, function(text: string)
			table.insert(warnings, text)
		end)
		return bus, warnings
	end

	T.describe("bus", function()
		T.it("delivers a valid publish to every subscriber, in order", function()
			local bus = quietBus()
			local got = {}
			bus.Subscribe("PlayerJoined", function(e)
				table.insert(got, "a" .. e.UserId)
			end)
			bus.Subscribe("PlayerJoined", function(e)
				table.insert(got, "b" .. e.UserId)
			end)
			T.expect(bus.Publish("PlayerJoined", { UserId = 7 })).toBe(true)
			T.expect(got).toEqual({ "a7", "b7" })
		end)

		T.it("unsubscribe stops delivery", function()
			local bus = quietBus()
			local n = 0
			local off = bus.Subscribe("PlayerJoined", function()
				n += 1
			end)
			bus.Publish("PlayerJoined", { UserId = 1 })
			off()
			bus.Publish("PlayerJoined", { UserId = 1 })
			T.expect(n).toBe(1)
		end)

		T.it("a throwing handler is isolated: others still run, the publisher is unaffected", function()
			local bus, warnings = quietBus()
			local reached = false
			bus.Subscribe("PlayerJoined", function()
				error("consumer bug")
			end)
			bus.Subscribe("PlayerJoined", function()
				reached = true
			end)
			T.expect(bus.Publish("PlayerJoined", { UserId = 1 })).toBe(true)
			bus.Publish("PlayerJoined", { UserId = 2 })
			T.expect(reached).toBe(true)
			T.expect(bus.stats.handlerErrors).toBe(2)
			T.expect(#warnings).toBe(1) -- warned once per event name, not per failure
		end)

		T.it("a yielding handler does not block the publisher", function()
			local bus = quietBus()
			local finished = false
			bus.Subscribe("PlayerJoined", function()
				task.wait(0.05)
				finished = true
			end)
			local t0 = os.clock()
			bus.Publish("PlayerJoined", { UserId = 1 })
			T.expect(os.clock() - t0).toBeLessThan(0.02)
			T.expect(finished).toBe(false)
			task.wait(0.1)
			T.expect(finished).toBe(true)
		end)

		T.it("rejects unknown events, missing or mistyped fields and Instances", function()
			local bus = quietBus()
			local n = 0
			bus.Subscribe("PearlsGranted", function()
				n += 1
			end)
			T.expect(bus.Publish("NoSuchEvent", {})).toBe(false)
			T.expect(bus.Publish("PearlsGranted", { UserId = 1, Amount = 5, Source = "run" })).toBe(false) -- no Balance
			T.expect(bus.Publish("PearlsGranted", { UserId = 1, Amount = "5", Balance = 5, Source = "run" })).toBe(false)
			T.expect(bus.Publish("PearlsGranted", { UserId = 1, Amount = 5, Balance = 5, Source = "run", ClaimId = workspace })).toBe(false)
			T.expect(bus.Publish("VoyageStarted", { VoyageId = "v", Crew = { workspace } })).toBe(false)
			T.expect(bus.Publish("PearlsGranted", { UserId = 1, Amount = 5, Balance = 5, Source = "run" })).toBe(true)
			T.expect(n).toBe(1)
			T.expect(bus.stats.rejected).toBe(5)
		end)

		T.it("cannot subscribe to an event that is not in the catalog", function()
			local bus = quietBus()
			T.expect(function()
				bus.Subscribe("Typo", function() end)
			end).toThrow("unknown event")
		end)

		T.it("every catalog field type is a known type", function()
			local known = { number = true, string = true, boolean = true, table = true }
			for name, schema in Events do
				for field, typeName in schema do
					local base = string.gsub(typeName, "%?$", "")
					if not known[base] then
						error(name .. "." .. field .. " has unknown type " .. typeName)
					end
				end
			end
		end)
	end)

	T.describe("Analytics consumer", function()
		local function recordingSink()
			local calls = {}
			local sink = {
				funnel = function(userId: number, step: number, name: string)
					table.insert(calls, string.format("funnel %d %d %s", userId, step, name))
				end,
				economy = function(userId: number, flow: string, amount: number, balance: number, tx: string, sku: string?)
					table.insert(calls, string.format("economy %d %s %d %d %s %s", userId, flow, amount, balance, tx, tostring(sku)))
				end,
				custom = function(userId: number, name: string, value: number?, field: string?)
					table.insert(calls, string.format("custom %d %s %s %s", userId, name, tostring(value), tostring(field)))
				end,
			}
			return sink, calls
		end

		T.it("maps a first session onto the fixed funnel steps", function()
			local bus = quietBus()
			local sink, calls = recordingSink()
			Analytics.start(bus, sink)
			bus.Publish("PlayerJoined", { UserId = 5 })
			bus.Publish("PlayerJoinedCrew", { UserId = 5, Route = "fast" })
			bus.Publish("PlayerLanded", { VoyageId = "v1", UserId = 5 })
			bus.Publish("FirstAction", { VoyageId = "v1", UserId = 5, Kind = "fuel" })
			bus.Publish("BeamHit", { VoyageId = "v1", KeeperId = 5, First = true })
			bus.Publish("NightSurvived", { VoyageId = "v1", Night = 1, Crew = { 5 } })
			bus.Publish("NightSurvived", { VoyageId = "v1", Night = 2, Crew = { 5 } })
			bus.Publish("VoyageEnded", { VoyageId = "v1", Outcome = "Defeat", Cause = "blackout", NightReached = 3, Crew = { 5 } })
			bus.Publish("SailAgain", { VoyageId = "v1", UserId = 5 })
			bus.Publish("PlayerLeft", { UserId = 5, Phase = "harbor", Night = 3 })
			T.expect(calls).toEqual({
				"funnel 5 1 Joined",
				"funnel 5 2 OnCrew",
				"funnel 5 3 Landed",
				"funnel 5 4 FirstAction",
				"funnel 5 5 FirstBeamHit",
				"funnel 5 6 Night1Survived",
				"funnel 5 8 VoyageEnded",
				"custom 5 VoyageEnded 3 Defeat:blackout",
				"funnel 5 9 SailAgain",
				"custom 5 Left 3 harbor",
			})
		end)

		T.it("only the first beam hit counts, and Night1Survived goes to every crew member", function()
			local bus = quietBus()
			local sink, calls = recordingSink()
			Analytics.start(bus, sink)
			bus.Publish("BeamHit", { KeeperId = 1, First = false })
			bus.Publish("NightSurvived", { VoyageId = "v", Night = 1, Crew = { 1, 2, 3 } })
			T.expect(calls).toEqual({ "funnel 1 6 Night1Survived", "funnel 2 6 Night1Survived", "funnel 3 6 Night1Survived" })
		end)

		T.it("Pearl sources and sinks become economy events with the ending balance", function()
			local bus = quietBus()
			local sink, calls = recordingSink()
			Analytics.start(bus, sink)
			bus.Publish("PearlsGranted", { UserId = 9, Amount = 12, Balance = 40, Source = "run" })
			bus.Publish("PearlsGranted", { UserId = 9, Amount = 3, Balance = 43, Source = "sell" })
			bus.Publish("PearlsSpent", { UserId = 9, Amount = 25, Balance = 18, ItemId = "StormHarpoon" })
			T.expect(calls).toEqual({
				"economy 9 Source 12 40 Gameplay run",
				"economy 9 Source 3 43 Shop sell",
				"economy 9 Sink 25 18 Shop StormHarpoon",
			})
		end)

		T.it("S2.2: a player's first dawn-banked Pearl is the DawnPearl step, once", function()
			local bus = quietBus()
			local sink, calls = recordingSink()
			Analytics.start(bus, sink)
			bus.Publish("PearlsGranted", { UserId = 4, Amount = 1, Balance = 1, Source = "dawn", ClaimId = "v:night1:4" })
			bus.Publish("PearlsGranted", { UserId = 4, Amount = 1, Balance = 2, Source = "dawn", ClaimId = "v:night2:4" })
			T.expect(calls).toEqual({
				"funnel 4 7 DawnPearl",
				"economy 4 Source 1 1 Gameplay dawn",
				"economy 4 Source 1 2 Gameplay dawn",
			})
		end)

		T.it("funnel step names are the fixed dashboard names", function()
			T.expect(Analytics.STEPS).toEqual({
				Joined = 1,
				OnCrew = 2,
				Landed = 3,
				FirstAction = 4,
				FirstBeamHit = 5,
				Night1Survived = 6,
				DawnPearl = 7,
				VoyageEnded = 8,
				SailAgain = 9,
			})
		end)
	end)
end
