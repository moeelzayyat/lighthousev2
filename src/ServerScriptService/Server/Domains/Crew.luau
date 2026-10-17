-- Crew domain (S5.1/S5.2): players joining, the title screen and the ship's deck, the ship party (roster,
-- boarding, departure), the first-voyage route, coach prompts, and moving players between ship and island.
-- One place, one crew per server (D-001).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = script.Parent.Parent
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local EventLog = require(Server.EventLog)
local LampService = require(Server.LampService)
local ShipRoster = require(Server.ShipRoster)
local ShipBoarding = require(Server.ShipBoarding)
local ShipDeparture = require(Server.ShipDeparture)
local NetGuard = require(Server.NetGuard)

local Crew = { Name = "Crew" }

local SHIP_ID = "Ship1" -- the existing pirate ship
local SHIP_IDS = { SHIP_ID }
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
		ctx.removeCarriedOil(player)
		if LampService.getKeeper() == player then
			LampService.setKeeper(nil, "leave")
		end
		task.spawn(moveCharacterTo, player, lobbyRefs.spawn.CFrame)
	end
	ctx.sendToShip = sendToShip

	-- Coach prompts (launch R3) report shown/done for the playtest log. Known ids only, rate limited.
	local COACH_IDS = { oil = true, tank = true, lamp = true, aim = true, focus = true, repair = true, bench = true }
	local coachBudget = {} -- player -> events left this session
	remotes.CoachEvent.OnServerEvent:Connect(function(player, kind, id)
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
	remotes.EnterLobby.OnServerEvent:Connect(function(player)
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
	remotes.SetReady.OnServerEvent:Connect(function(player, ready)
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
	ShipRoster.init(stateFolder, Config.MAX_CREW or 4, SHIP_IDS)

	-- Boarding: standing in the ship's BoardingZone joins its party (no button). Boarding never starts a
	-- departure. ShipDeparture does: automatically at 4/4, or when a crew member of a party of 1 to 3 uses
	-- SAIL NOW at the ship's wheel.
	ShipBoarding.init({
		roster = ShipRoster,
		zones = { [SHIP_ID] = lobbyRefs.boardingZone },
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
	})

	-- The server checks everything; the client only shows the prompt to members who can use it.
	lobbyRefs.helmPrompt.Triggered:Connect(function(player)
		if not player:GetAttribute("InLobby") then
			return
		end
		local ok, reason = ShipDeparture.sailNow(player, SHIP_ID)
		if not ok then
			LampService.notify(player, SAIL_REFUSED[reason] or "You can't sail right now.")
			EventLog.log("SailNowRefused", { player = player.Name, reason = reason, ship = SHIP_ID })
		end
	end)

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
