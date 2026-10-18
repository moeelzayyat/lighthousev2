-- Crew domain (S5.1/S5.2): players joining, the title screen and the ship's deck, the ship party (roster,
-- boarding, departure), the first-voyage route, coach prompts, and moving players between ship and island.
-- D-046: the role of this place (Shared/PlaceRole). Harbor: several ships, each crew teleported to its own isle
-- server (HarborDepartures). Isle: the arriving crew sails at once (IsleArrival) and goes back to the harbor after.
-- Single (no isle place yet): one place, one ship, as before.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Server = script.Parent.Parent
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local EventLog = require(Server.EventLog)
local LampService = require(Server.LampService)
local ShipRoster = require(Server.ShipRoster)
local ShipBoarding = require(Server.ShipBoarding)
local ShipDeparture = require(Server.ShipDeparture)
local NetGuard = require(Server.NetGuard)
local OilCarry = require(Server.OilCarry)
local HarborDepartures = require(Server.HarborDepartures)
local IsleArrival = require(Server.IsleArrival)
local PlaceRole = require(ReplicatedStorage.Shared:WaitForChild("PlaceRole"))
local Forecasts = require(ReplicatedStorage.Shared:WaitForChild("Forecasts"))
local Voyages = require(ReplicatedStorage.Shared:WaitForChild("Definitions"):WaitForChild("Voyages"))

local Crew = { Name = "Crew" }

local SHIP_ID = "Ship1" -- the existing pirate ship (the only ship outside the harbor role)
local SHIP_IDS = { SHIP_ID }
local ROLE = PlaceRole.get()

-- D-046: TeleportService with retries. Studio cannot teleport: callers log and say so instead.
local function teleportTo(placeId, players, options)
	if RunService:IsStudio() then
		return false, "studio"
	end
	local lastErr = nil
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			TeleportService:TeleportAsync(placeId, players, options)
		end)
		if ok then
			return true, nil
		end
		lastErr = tostring(err)
		task.wait(attempt * 2)
	end
	return false, lastErr
end
local RUN_PHASES = { Prologue = true, Day = true, Night = true }

-- The ship's wheel: SAIL NOW for a party of 1 to 3 (a full party departs automatically)
local SAIL_REFUSED = {
	["not crew"] = "Walk onto the ship to join its crew first.",
	sailed = "The ship is at sea with its crew. Wait here for the next voyage.",
	already = "The ship is already preparing to sail.",
	full = "The crew is full: the ship sails automatically.",
}

---------------------------------------------------------------------
-- First-voyage route (launch R2)
---------------------------------------------------------------------

-- A player whose profile loaded cleanly with 0 completed runs skips the title and lands on the ship's deck,
-- where the wheel signs them up (batch 1 revision: they are no longer put in a crew automatically). Everyone
-- else gets the title. A failed or slow profile load ALWAYS gets the title: never guess someone is new.
-- The client waits for the Route attribute before showing anything.
local function chooseRoute(player)
	local started = os.clock()
	while player.Parent == Players and player:GetAttribute("ProfileState") == nil and os.clock() - started < 6 do
		task.wait(0.2)
	end
	if player.Parent ~= Players then
		return
	end
	local profileState = player:GetAttribute("ProfileState")
	-- D-046: on Lighthouse Isle the crew came from the harbor; they sail as soon as everyone is in
	if ROLE == "isle" then
		EventLog.setRoute(player, "isle")
		player:SetAttribute("Route", "fast")
		player:SetAttribute("InLobby", true)
		return
	end
	local fast = Config.FIRST_VOYAGE_FAST_PATH == true
		and (profileState == "saved" or profileState == "memory")
		and player:GetAttribute("RunsCompleted") == 0
		and not player:GetAttribute("InLobby")
	EventLog.setRoute(player, if fast then "fast" elseif profileState == "failed" then "failed-load" elseif profileState == nil then "slow-load" else "title")
	if not fast then
		player:SetAttribute("Route", "title")
		return
	end
	-- wait for a character so the crew can be rowed out
	while player.Parent == Players and not (player.Character and player.Character:FindFirstChild("HumanoidRootPart")) and os.clock() - started < 20 do
		task.wait(0.2)
	end
	if player.Parent ~= Players then
		return
	end
	player:SetAttribute("Route", "fast")
	player:SetAttribute("InLobby", true)
	EventLog.log("EnteredLobby", { player = player.Name, via = "first voyage" })
	task.wait(0.4)
	if player.Parent == Players and not player:GetAttribute("Ready") then
		LampService.notify(player, "The storm is coming and the light needs keepers. Walk onto the ship to join the crew.")
	end
end

---------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------

function Crew.Init(ctx)
	local remotes, stateFolder, lobbyRefs = ctx.remotes, ctx.state, ctx.lobbyRefs

	-- Lobby ship: getting from the deck to the island and back
	local function moveCharacterTo(player, target)
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			remotes.Travel:FireClient(player) -- short fade on their screen
			task.wait(0.35)
			character:PivotTo(target + Vector3.new(math.random(-4, 4), 3, math.random(-4, 4)))
		end
	end

	ctx.sendToIsland = function(player)
		task.spawn(function()
			moveCharacterTo(player, lobbyRefs.islandArrival)
			EventLog.mark(player, "landed")
		end)
	end

	local function sendToShip(player)
		OilCarry.remove(player)
		if LampService.getKeeper() == player then
			LampService.setKeeper(nil, "leave")
		end
		-- D-046: leaving a voyage on Lighthouse Isle means going back to the harbor
		if ROLE == "isle" then
			task.spawn(function()
				local ok, why = teleportTo(Config.HARBOR_PLACE_ID, { player })
				EventLog.log("IsleToHarbor", { player = player.Name, ok = ok, why = why or "" })
				if not ok and player.Parent == Players then
					if why == "studio" then
						LampService.notify(player, "(Studio) This is where you would go back to the harbor.")
						moveCharacterTo(player, lobbyRefs.spawn.CFrame)
					else
						player:Kick("The harbor could not be reached. Rejoin Lighthouse Keepers to get back to it.")
					end
				end
			end)
			return
		end
		task.spawn(moveCharacterTo, player, lobbyRefs.spawn.CFrame)
	end
	ctx.sendToShip = sendToShip

	-- Coach prompts (launch R3) report shown/done for the playtest log. Known ids only, rate limited.
	local COACH_IDS = { oil = true, tank = true, lamp = true, aim = true, focus = true, repair = true, bench = true }
	local coachBudget = {} -- player -> events left this session
	NetGuard.connect(remotes.CoachEvent, function(player, kind, id)
		if not NetGuard.allow(player, "CoachEvent") then
			return
		end
		if (kind ~= "shown" and kind ~= "done") or not COACH_IDS[id] then
			return
		end
		local left = coachBudget[player] or 60
		if left <= 0 then
			return
		end
		coachBudget[player] = left - 1
		EventLog.mark(player, (if kind == "shown" then "promptShown:" else "promptDone:") .. id)
	end)

	-- Title screen "Play": you're now on the ship
	NetGuard.connect(remotes.EnterLobby, function(player)
		if not NetGuard.allow(player, "EnterLobby") then
			return
		end
		if not player:GetAttribute("InLobby") then
			player:SetAttribute("InLobby", true)
			EventLog.log("EnteredLobby", { player = player.Name })
		end
	end)

	-- Results screen "Main Menu" (or leaving the crew): back to the ship. SetReady(true) is ignored: joining
	-- the crew happens at the ship's wheel. R1.4: one handler, contract rate, PlayerToMenu logged once per
	-- session.
	local menuLogged = {}
	NetGuard.connect(remotes.SetReady, function(player, ready)
		if ready ~= false or not NetGuard.allow(player, "SetReady") then
			return
		end
		player:SetAttribute("Ready", false)
		if not menuLogged[player] then
			menuLogged[player] = true
			EventLog.log("PlayerToMenu", { player = player.Name })
		end
		if LampService.getKeeper() == player then
			LampService.setKeeper(nil, "leave")
		end
		sendToShip(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		coachBudget[player] = nil
		menuLogged[player] = nil
	end)

	-- Ship party: the server is the crew (D-001). The one ship takes a party of at most Config.MAX_CREW.
	-- ShipRoster is the only thing that puts a player in a crew (Ready = true).
	local ships = lobbyRefs.ships or { [SHIP_ID] = { helmPrompt = lobbyRefs.helmPrompt, boardingZone = lobbyRefs.boardingZone } }
	if ROLE == "harbor" then
		SHIP_IDS = {}
		for k = 1, 16 do
			if ships["Ship" .. k] then
				table.insert(SHIP_IDS, "Ship" .. k)
			end
		end
	end
	ctx.shipIds = SHIP_IDS
	ShipRoster.init(stateFolder, Config.MAX_CREW or 4, SHIP_IDS)

	-- Boarding: standing in the ship's BoardingZone joins its party (no button). Boarding never starts a
	-- departure. ShipDeparture does: automatically at 4/4, or when a crew member of a party of 1 to 3 uses
	-- SAIL NOW at the ship's wheel.
	ShipBoarding.init({
		roster = ShipRoster,
		zones = (function()
			local zones = {}
			for _, id in SHIP_IDS do
				zones[id] = ships[id].boardingZone
			end
			return zones
		end)(),
		notify = LampService.notify,
		log = EventLog.log,
		mark = EventLog.mark,
		canBoard = function(player)
			-- pressed Play (not on the title screen)
			return player:GetAttribute("InLobby") == true
		end,
	})
	ShipDeparture.init({
		roster = ShipRoster,
		state = stateFolder,
		shipIds = SHIP_IDS,
		notify = LampService.notify,
		log = EventLog.log,
		subscribe = EventLog.Subscribe, -- S5.3: CrewRosterChanged
	})

	-- The server checks everything; the client only shows the prompt to members who can use it.
	for _, id in SHIP_IDS do
		ships[id].helmPrompt.Triggered:Connect(function(player)
			if not player:GetAttribute("InLobby") then
				return
			end
			local ok, reason = ShipDeparture.sailNow(player, id)
			if not ok then
				LampService.notify(player, SAIL_REFUSED[reason] or "You can't sail right now.")
				EventLog.log("SailNowRefused", { player = player.Name, reason = reason, ship = id })
			end
		end)
	end

	-- D-046: the harbor sends each crew to its own Lighthouse Isle server
	if ROLE == "harbor" then
		HarborDepartures.init({
			roster = ShipRoster,
			departure = ShipDeparture,
			state = stateFolder,
			shipIds = SHIP_IDS,
			countdown = Config.INTERMISSION_SECONDS,
			voyageFor = function(id)
				return stateFolder:GetAttribute("Ship_" .. id .. "_VoyageDef")
			end,
			forecast = function()
				return stateFolder:GetAttribute("ForecastA"), stateFolder:GetAttribute("ForecastB")
			end,
			teleport = function(players, data)
				if RunService:IsStudio() then
					for _, p in players do
						LampService.notify(p, "(Studio) Your crew would now be teleported to its own Lighthouse Isle server.")
						p:SetAttribute("Ready", false)
					end
					return false, "studio"
				end
				local ok, code = pcall(function()
					return TeleportService:ReserveServer(Config.ISLE_PLACE_ID)
				end)
				if not ok then
					return false, "reserve: " .. tostring(code)
				end
				local options = Instance.new("TeleportOptions")
				options.ReservedServerAccessCode = code
				options:SetTeleportData(data)
				local sent, why = teleportTo(Config.ISLE_PLACE_ID, players, options)
				if not sent then
					for _, p in players do
						if p.Parent == Players then
							p:SetAttribute("Ready", false)
						end
					end
				end
				return sent, why
			end,
			notify = LampService.notify,
			log = EventLog.log,
		})
		TeleportService.TeleportInitFailed:Connect(function(player, result, message)
			EventLog.log("TeleportFailed", { player = player.Name, result = tostring(result), message = string.sub(tostring(message), 1, 120) })
			if player.Parent == Players then
				player:SetAttribute("Ready", false)
				LampService.notify(player, "The ship couldn't reach Lighthouse Isle. You're back on the deck: sail again when you're ready.")
			end
		end)
	elseif ROLE == "isle" then
		IsleArrival.init({
			roster = ShipRoster,
			departure = ShipDeparture,
			state = stateFolder,
			shipId = SHIP_ID,
			wait = Config.ISLE_ARRIVAL_WAIT or 20,
			known = { voyages = Voyages, forecasts = Forecasts },
			reserved = function()
				return RunService:IsStudio() or (game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0)
			end,
			toHarbor = function(player, why)
				EventLog.log("IsleRefused", { player = player.Name, why = why })
				task.spawn(function()
					local ok = teleportTo(Config.HARBOR_PLACE_ID, { player })
					if not ok and player.Parent == Players then
						player:Kick("Lighthouse Isle is reached by ship from the harbor. Rejoin Lighthouse Keepers.")
					end
				end)
			end,
			log = EventLog.log,
		})
	end

	-- What the round loop needs from the ship
	ctx.departure = {
		requested = function()
			return ShipDeparture.requested(SHIP_ID)
		end,
		rematch = function()
			ShipDeparture.rematch(SHIP_ID)
		end,
		mode = function()
			return ShipDeparture.mode(SHIP_ID)
		end,
	}
	ctx.departShip = function()
		local sailing = ShipRoster.depart(SHIP_ID) -- freezes the party; only these players sail
		ShipBoarding.departed(sailing) -- their seats no longer depend on standing on the deck
		ShipDeparture.departed(SHIP_ID) -- the departure request is used up
		return sailing
	end
end

function Crew.Start(ctx)
	local stateFolder, lobbyRefs = ctx.state, ctx.lobbyRefs

	local function onPlayerAdded(player)
		EventLog.playerJoined(player)
		player:SetAttribute("CarryingOil", false)
		player:SetAttribute("Ready", false) -- starts on the title screen
		player:SetAttribute("InLobby", false)
		player.CharacterAdded:Connect(function()
			player:SetAttribute("CarryingOil", false)
			-- Everyone spawns on the ship. Crew members who die mid-run go straight back to the island.
			if player:GetAttribute("Ready") and RUN_PHASES[stateFolder:GetAttribute("Phase")] then
				task.delay(0.3, function()
					local character = player.Character
					if character and character:FindFirstChild("HumanoidRootPart") then
						character:PivotTo(lobbyRefs.islandArrival + Vector3.new(math.random(-4, 4), 3, math.random(-4, 4)))
					end
				end)
			end
		end)
		task.spawn(chooseRoute, player)
		if ROLE == "isle" then
			local ok, joinData = pcall(function()
				return player:GetJoinData()
			end)
			IsleArrival.onJoin(player, if ok then joinData else nil, os.clock())
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
		player:LoadCharacter() -- respawn anyone who loaded in before the island existed
	end

	-- Keep a live count of the crew for the ship's status banner
	task.spawn(function()
		while true do
			local crew, aboard = 0, 0
			for _, player in Players:GetPlayers() do
				if player:GetAttribute("Ready") then
					crew += 1
				elseif player:GetAttribute("InLobby") then
					aboard += 1
				end
			end
			stateFolder:SetAttribute("CrewCount", crew)
			stateFolder:SetAttribute("AboardCount", aboard)
			task.wait(0.5)
		end
	end)
end

return Crew
