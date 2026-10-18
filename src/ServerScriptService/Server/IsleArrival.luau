--!strict
-- IsleArrival (D-046, isle role): a crew teleported from the harbor arrives in its own Lighthouse Isle server.
-- Each arriving player joins the ship's party (no walking aboard), and as soon as the whole crew is in (or after
-- Config.ISLE_ARRIVAL_WAIT seconds) the voyage starts at once with the voyage and forecast votes chosen in the
-- harbor. GameState runs the voyage exactly as before; Sail again stays on this server.
--
-- The teleport data is only trusted for choices the voyage re-checks anyway (GameState re-checks the voyage's
-- unlock; forecasts must be known ids). A player who arrives in a server that is not reserved (someone who
-- teleported themselves) is sent back to the harbor.

local IsleArrival = {}

type Plan = { crew: { number }, voyage: string?, forecastA: string?, forecastB: string?, votes: { [string]: string } }

-- pure: the voyage plan from a player's join data, or nil if it is not a harbor launch
function IsleArrival.parse(joinData: any, known: { voyages: { [string]: any }, forecasts: { [string]: any } }): Plan?
	local data = type(joinData) == "table" and joinData.TeleportData
	if type(data) ~= "table" or data.v ~= 1 or type(data.crew) ~= "table" then
		return nil
	end
	local crew = {}
	for i, id in data.crew do
		if type(id) == "number" and i <= 4 then
			table.insert(crew, id)
		end
	end
	local voyage = data.voyage
	if type(voyage) ~= "string" or type(known.voyages[voyage]) ~= "table" or known.voyages[voyage].testOnly then
		voyage = nil
	end
	local a, b = data.forecastA, data.forecastB
	if not (type(a) == "string" and known.forecasts[a] and type(b) == "string" and known.forecasts[b]) then
		a, b = nil, nil
	end
	local votes = {}
	if type(data.votes) == "table" and a then
		for userId, v in data.votes do
			if type(userId) == "string" and (v == a or v == b) then
				votes[userId] = v
			end
		end
	end
	return { crew = crew, voyage = voyage, forecastA = a, forecastB = b, votes = votes }
end

type Deps = {
	roster: any, -- ShipRoster
	departure: any, -- ShipDeparture
	state: Instance,
	shipId: string,
	wait: number,
	known: { voyages: { [string]: any }, forecasts: { [string]: any } },
	reserved: () -> boolean, -- is this a reserved (harbor-launched) server?
	toHarbor: (player: Player, why: string) -> (),
	log: (kind: string, data: { [string]: any }) -> (),
}

local deps: Deps = nil :: any
local plan: Plan? = nil
local firstArrival: number? = nil
local launched = false

local function present(): { Player }
	return deps.roster.members(deps.shipId)
end

local function allIn(): boolean
	if not plan or #plan.crew == 0 then
		return true
	end
	local here = {}
	for _, p in present() do
		here[p.UserId] = true
	end
	for _, id in plan.crew do
		if not here[id] then
			return false
		end
	end
	return true
end

-- the harbor's choices, applied right before the ship "sails" (GameState offers its own forecasts when it waits)
local function applyPlan()
	local p = plan
	if not p then
		return
	end
	if p.voyage then
		deps.state:SetAttribute("VoyageDef", p.voyage)
	end
	if p.forecastA and p.forecastB then
		deps.state:SetAttribute("ForecastA", p.forecastA)
		deps.state:SetAttribute("ForecastB", p.forecastB)
		for _, player in present() do
			player:SetAttribute("ForecastVote", p.votes[tostring(player.UserId)])
		end
	end
end

-- one check (the poll calls this; tests call it with their own clock)
function IsleArrival.step(clock: number)
	if launched or not firstArrival or #present() == 0 then
		return
	end
	local phase = deps.state:GetAttribute("Phase")
	if phase ~= "Waiting" and phase ~= "Intermission" then
		return -- (a full crew of 4 may already have started the automatic countdown: the plan still applies)
	end
	if allIn() or clock - firstArrival >= deps.wait then
		launched = true
		applyPlan()
		deps.log("IsleLaunch", { crew = #present(), expected = if plan then #plan.crew else 0, waited = math.floor(clock - firstArrival) })
		deps.departure.rematch(deps.shipId) -- a deliberate departure: it sails at once
	end
end

function IsleArrival.onJoin(player: Player, joinData: any, clock: number)
	local parsed = IsleArrival.parse(joinData, deps.known)
	if not deps.reserved() then
		deps.toHarbor(player, "not reserved")
		return
	end
	if parsed and not plan then
		plan = parsed
	end
	firstArrival = firstArrival or clock
	player:SetAttribute("InLobby", true)
	deps.roster.join(player, deps.shipId)
end

function IsleArrival.launched(): boolean
	return launched
end

-- d: see Deps. manual = true (tests): no poll.
function IsleArrival.init(d: Deps, manual: boolean?)
	deps = d
	plan, firstArrival, launched = nil, nil, false
	if manual then
		return
	end
	task.spawn(function()
		while not launched do
			task.wait(0.5)
			local ok, err = pcall(IsleArrival.step :: any, os.clock())
			if not ok then
				warn("[IsleArrival] " .. tostring(err))
			end
		end
	end)
end

return IsleArrival
