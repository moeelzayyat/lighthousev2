--!strict
-- HarborDepartures (D-046, harbor role): each ship in the harbor runs its own countdown and sends its own crew
-- to a Lighthouse Isle server. ShipDeparture still decides WHEN a ship wants to leave (4/4, SAIL NOW); this
-- module replaces GameState's single "Intermission" countdown for the harbor, where there is no voyage loop.
--
-- Per ship, replicated on the GameState folder for the client (Departure.client reads these when MultiShip):
--   Ship_<id>_Phase    = "Waiting" | "Countdown" | "Sailing"
--   Ship_<id>_TimeLeft = whole seconds left in the countdown
-- When a countdown ends with the request still valid, the party is frozen (ShipRoster.depart) and handed to
-- deps.teleport(players, data). The ship takes a new crew as soon as the teleport has been issued (or failed).

local HarborDepartures = {}

type Deps = {
	roster: any, -- ShipRoster
	departure: any, -- ShipDeparture
	state: Instance, -- the GameState folder
	shipIds: { string },
	countdown: number, -- seconds
	voyageFor: (shipId: string) -> string?, -- the ship's chosen voyage id
	mapFor: ((shipId: string) -> string?)?, -- MAP.1: the ship's chosen map id
	forecast: () -> (string?, string?), -- the harbor's current offer (A, B)
	teleport: (players: { Player }, data: { [string]: any }) -> (boolean, string?),
	notify: (player: Player, text: string) -> (),
	log: (kind: string, data: { [string]: any }) -> (),
	now: (() -> number)?, -- tests: a fake clock
}

local deps: Deps = nil :: any
local ships: { [string]: { phase: string, endsAt: number } } = {}

local function now(): number
	return if deps.now then deps.now() else os.clock()
end

local function publish(id: string)
	local s = ships[id]
	deps.state:SetAttribute("Ship_" .. id .. "_Phase", s.phase)
	deps.state:SetAttribute("Ship_" .. id .. "_TimeLeft", if s.phase == "Countdown" then math.max(0, math.ceil(s.endsAt - now())) else 0)
end

-- what the isle server needs to run this crew's voyage
local function voyageData(id: string, sailing: { Player }): { [string]: any }
	local a, b = deps.forecast()
	local crew, votes = {}, {}
	for _, p in sailing do
		table.insert(crew, p.UserId)
		local v = p:GetAttribute("ForecastVote")
		if type(v) == "string" then
			votes[tostring(p.UserId)] = v
		end
	end
	return {
		v = 1,
		shipId = id,
		crew = crew,
		voyage = deps.voyageFor(id),
		map = if deps.mapFor then deps.mapFor(id) else nil, -- MAP.1
		forecastA = a,
		forecastB = b,
		votes = votes,
	}
end

local function launch(id: string)
	local sailing = deps.roster.depart(id) -- freezes the party; only these players sail
	deps.departure.departed(id)
	ships[id].phase = "Sailing"
	publish(id)
	if #sailing == 0 then
		deps.roster.unlock(id)
		ships[id].phase = "Waiting"
		publish(id)
		return
	end
	local data = voyageData(id, sailing)
	deps.log("HarborLaunch", { ship = id, crew = #sailing, voyage = data.voyage or "" })
	task.spawn(function()
		local ok, why = deps.teleport(sailing, data)
		if not ok then
			deps.log("HarborLaunchFailed", { ship = id, why = why or "" })
			for _, p in sailing do
				if p.Parent ~= nil then
					deps.notify(p, "The ship couldn't reach Lighthouse Isle. You're back on the deck: sail again when you're ready.")
				end
			end
		end
		-- the ship is free for a new crew either way (a failed crew can board and sail again)
		deps.roster.unlock(id)
		ships[id].phase = "Waiting"
		publish(id)
	end)
end

-- one step for one ship (the poll calls this; tests call it directly)
function HarborDepartures.step(id: string)
	local s = ships[id]
	if s.phase == "Sailing" then
		return
	end
	local wanted = deps.departure.requested(id)
	if s.phase == "Waiting" then
		if wanted then
			local sailIn = if deps.departure.mode(id) == "rematch" then 0 else deps.countdown
			s.phase = "Countdown"
			s.endsAt = now() + sailIn
			publish(id)
		end
	elseif s.phase == "Countdown" then
		if not wanted then
			s.phase = "Waiting"
			publish(id)
		elseif now() >= s.endsAt then
			launch(id)
		else
			publish(id)
		end
	end
end

function HarborDepartures.phase(id: string): string?
	local s = ships[id]
	return s and s.phase
end

-- d: see Deps. manual = true (tests): no poll loop.
function HarborDepartures.init(d: Deps, manual: boolean?)
	deps = d
	ships = {}
	deps.state:SetAttribute("MultiShip", true)
	for _, id in d.shipIds do
		ships[id] = { phase = "Waiting", endsAt = 0 }
		publish(id)
	end
	if manual then
		return
	end
	task.spawn(function()
		while true do
			task.wait(0.25)
			for _, id in d.shipIds do
				local ok, err = pcall(HarborDepartures.step :: any, id)
				if not ok then
					warn("[HarborDepartures] " .. tostring(err))
				end
			end
		end
	end)
end

return HarborDepartures
