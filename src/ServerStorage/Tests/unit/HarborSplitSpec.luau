--!strict
-- D-046: the harbor and Lighthouse Isle are separate places. PlaceRole picks the job; the harbor runs one
-- countdown per ship and teleports each crew with its voyage and forecast votes; the isle reads that data
-- (only what the voyage re-checks anyway) and sails once the whole crew is in, or after the wait.
return function(T: any)
	local PlaceRole = T.require(game.ReplicatedStorage.Shared.PlaceRole)
	local HarborDepartures = T.require(game.ServerScriptService.Server.HarborDepartures)
	local IsleArrival = T.require(game.ServerScriptService.Server.IsleArrival)

	local function fakePlayer(id: number, vote: string?)
		local attrs: { [string]: any } = { ForecastVote = vote }
		return {
			UserId = id,
			Name = "P" .. id,
			Parent = true,
			GetAttribute = function(_self: any, k: string)
				return attrs[k]
			end,
			SetAttribute = function(_self: any, k: string, v: any)
				attrs[k] = v
			end,
			attrs = attrs,
		}
	end

	local function fakeState()
		local attrs: { [string]: any } = {}
		return {
			GetAttribute = function(_self: any, k: string)
				return attrs[k]
			end,
			SetAttribute = function(_self: any, k: string, v: any)
				attrs[k] = v
			end,
			attrs = attrs,
		}
	end

	T.describe("PlaceRole", function()
		T.it("is the one-place game until the isle place exists", function()
			T.expect(PlaceRole.resolve(111, 111, 0, nil)).toBe("single")
			T.expect(PlaceRole.resolve(111, 111, nil, nil)).toBe("single")
		end)
		T.it("is the isle on the isle place and the harbor anywhere else", function()
			T.expect(PlaceRole.resolve(222, 111, 222, nil)).toBe("isle")
			T.expect(PlaceRole.resolve(111, 111, 222, nil)).toBe("harbor")
		end)
		T.it("Studio (which cannot teleport) plays the one-place game", function()
			T.expect(PlaceRole.resolve(111, 111, 222, nil, true)).toBe("single")
			T.expect(PlaceRole.resolve(222, 111, 222, nil, true)).toBe("single")
		end)
		T.it("a Studio override wins", function()
			T.expect(PlaceRole.resolve(111, 111, 0, "harbor", true)).toBe("harbor")
			T.expect(PlaceRole.resolve(111, 111, 0, "isle")).toBe("isle")
			T.expect(PlaceRole.resolve(111, 111, 0, "nonsense")).toBe("single")
		end)
	end)

	-- a harbor with two ships and fakes for the roster, ShipDeparture and the teleport
	local function harbor()
		local w = {
			clock = 0,
			crews = { Ship1 = {} :: { any }, Ship2 = {} :: { any } },
			locked = {} :: { [string]: boolean },
			requests = {} :: { [string]: string? },
			sent = {} :: { any },
			teleportOk = true,
			state = fakeState(),
		}
		HarborDepartures.init({
			roster = {
				depart = function(id: string)
					w.locked[id] = true
					return table.clone(w.crews[id])
				end,
				unlock = function(id: string)
					w.locked[id] = false
				end,
			},
			departure = {
				requested = function(id: string)
					return w.requests[id] ~= nil
				end,
				mode = function(id: string)
					return w.requests[id]
				end,
				departed = function(id: string)
					w.requests[id] = nil
				end,
			},
			state = w.state :: any,
			shipIds = { "Ship1", "Ship2" },
			countdown = 10,
			voyageFor = function(id: string)
				return if id == "Ship2" then "Long" else nil
			end,
			forecast = function()
				return "FogBank", "SpringTide"
			end,
			teleport = function(players: { any }, data: any)
				table.insert(w.sent, { players = players, data = data })
				return w.teleportOk, if w.teleportOk then nil else "boom"
			end,
			notify = function() end,
			log = function() end,
			now = function()
				return w.clock
			end,
		}, true)
		return w
	end

	T.describe("HarborDepartures", function()
		T.it("each ship counts down on its own and sends only its own crew", function()
			local w = harbor()
			local a, b, c = fakePlayer(1, "FogBank"), fakePlayer(2), fakePlayer(3, "SpringTide")
			w.crews.Ship1 = { a, b }
			w.crews.Ship2 = { c }
			w.requests.Ship1 = "manual"
			HarborDepartures.step("Ship1")
			HarborDepartures.step("Ship2")
			T.expect(w.state.attrs.MultiShip).toBe(true)
			T.expect(w.state.attrs.Ship_Ship1_Phase).toBe("Countdown")
			T.expect(w.state.attrs.Ship_Ship1_TimeLeft).toBe(10)
			T.expect(w.state.attrs.Ship_Ship2_Phase).toBe("Waiting")
			w.clock = 4
			w.requests.Ship2 = "auto"
			HarborDepartures.step("Ship1")
			HarborDepartures.step("Ship2")
			T.expect(w.state.attrs.Ship_Ship1_TimeLeft).toBe(6)
			w.clock = 10
			HarborDepartures.step("Ship1")
			HarborDepartures.step("Ship2")
			T.expect(#w.sent).toBe(1) -- only Ship1's countdown has ended
			local first = w.sent[1]
			T.expect(#first.players).toBe(2)
			T.expect(first.data.shipId).toBe("Ship1")
			T.expect(first.data.crew[1]).toBe(1)
			T.expect(first.data.votes["1"]).toBe("FogBank")
			T.expect(first.data.votes["2"]).toBe(nil)
			T.expect(first.data.forecastA).toBe("FogBank")
			w.clock = 14
			HarborDepartures.step("Ship2")
			T.expect(#w.sent).toBe(2)
			T.expect(w.sent[2].data.voyage).toBe("Long")
			T.expect(w.sent[2].players[1]).toBe(c)
		end)

		T.it("a withdrawn request stops the countdown; the ship takes a new crew after a launch", function()
			local w = harbor()
			w.crews.Ship1 = { fakePlayer(1) }
			w.requests.Ship1 = "manual"
			HarborDepartures.step("Ship1")
			w.requests.Ship1 = nil
			w.clock = 3
			HarborDepartures.step("Ship1")
			T.expect(w.state.attrs.Ship_Ship1_Phase).toBe("Waiting")
			w.requests.Ship1 = "manual"
			HarborDepartures.step("Ship1")
			w.clock = 20
			HarborDepartures.step("Ship1")
			T.expect(#w.sent).toBe(1)
			T.expect(w.locked.Ship1).toBe(false) -- unlocked once the teleport was issued
			T.expect(w.state.attrs.Ship_Ship1_Phase).toBe("Waiting")
		end)

		T.it("a failed teleport frees the ship too; a rematch sails at once", function()
			local w = harbor()
			w.teleportOk = false
			w.crews.Ship2 = { fakePlayer(7) }
			w.requests.Ship2 = "rematch"
			HarborDepartures.step("Ship2")
			HarborDepartures.step("Ship2")
			T.expect(#w.sent).toBe(1)
			T.expect(w.locked.Ship2).toBe(false)
			T.expect(w.state.attrs.Ship_Ship2_Phase).toBe("Waiting")
		end)
	end)

	local KNOWN = {
		voyages = { Standard = { nights = 7 }, Long = { nights = 13 }, Test = { nights = 1, testOnly = true } },
		forecasts = { FogBank = {}, SpringTide = {}, LeakyStores = {} },
	}

	T.describe("IsleArrival", function()
		T.it("reads the harbor's data and drops anything it does not know", function()
			local plan = IsleArrival.parse({ TeleportData = { v = 1, crew = { 1, 2, "x" :: any }, voyage = "Long", forecastA = "FogBank", forecastB = "SpringTide", votes = { ["1"] = "FogBank", ["2"] = "Kraken" } } }, KNOWN)
			T.expect(plan ~= nil).toBe(true)
			local p = plan :: any
			T.expect(#p.crew).toBe(2)
			T.expect(p.voyage).toBe("Long")
			T.expect(p.votes["1"]).toBe("FogBank")
			T.expect(p.votes["2"]).toBe(nil)
			local bad = IsleArrival.parse({ TeleportData = { v = 1, crew = { 1 }, voyage = "Test", forecastA = "Nope", forecastB = "SpringTide" } }, KNOWN) :: any
			T.expect(bad.voyage).toBe(nil)
			T.expect(bad.forecastA).toBe(nil)
			T.expect(IsleArrival.parse({ TeleportData = "hello" }, KNOWN)).toBe(nil)
			T.expect(IsleArrival.parse(nil, KNOWN)).toBe(nil)
		end)

		local function isle(reserved: boolean)
			local w = { members = {} :: { any }, rematched = 0, refused = {} :: { any }, state = fakeState() }
			w.state.attrs.Phase = "Waiting"
			IsleArrival.init({
				roster = {
					members = function(_id: string)
						return w.members
					end,
					join = function(player: any, _id: string)
						table.insert(w.members, player)
						return true, "joined"
					end,
				},
				departure = {
					rematch = function(_id: string)
						w.rematched += 1
					end,
				},
				state = w.state :: any,
				shipId = "Ship1",
				wait = 20,
				known = KNOWN,
				reserved = function()
					return reserved
				end,
				toHarbor = function(player: any, _why: string)
					table.insert(w.refused, player)
				end,
				log = function() end,
			}, true)
			return w
		end

		local function data(crew: { number })
			return { TeleportData = { v = 1, crew = crew, voyage = "Long", forecastA = "FogBank", forecastB = "SpringTide", votes = { ["5"] = "SpringTide" } } }
		end

		T.it("sails as soon as the whole crew is in, with the harbor's choices", function()
			local w = isle(true)
			local a, b = fakePlayer(5), fakePlayer(6)
			IsleArrival.onJoin(a :: any, data({ 5, 6 }), 0)
			IsleArrival.step(1)
			T.expect(w.rematched).toBe(0) -- still waiting for player 6
			IsleArrival.onJoin(b :: any, data({ 5, 6 }), 2)
			IsleArrival.step(2)
			T.expect(w.rematched).toBe(1)
			T.expect(w.state.attrs.VoyageDef).toBe("Long")
			T.expect(w.state.attrs.ForecastA).toBe("FogBank")
			T.expect(a.attrs.ForecastVote).toBe("SpringTide")
			T.expect(a.attrs.InLobby).toBe(true)
			IsleArrival.step(3)
			T.expect(w.rematched).toBe(1) -- once only
		end)

		T.it("sails without a missing crew member after the wait", function()
			local w = isle(true)
			IsleArrival.onJoin(fakePlayer(5) :: any, data({ 5, 6 }), 0)
			IsleArrival.step(19)
			T.expect(w.rematched).toBe(0)
			IsleArrival.step(20)
			T.expect(w.rematched).toBe(1)
		end)

		T.it("sends a player in a server that is not reserved back to the harbor", function()
			local w = isle(false)
			IsleArrival.onJoin(fakePlayer(9) :: any, data({ 9 }), 0)
			T.expect(#w.refused).toBe(1)
			T.expect(#w.members).toBe(0)
			IsleArrival.step(30)
			T.expect(w.rematched).toBe(0)
		end)
	end)
end
