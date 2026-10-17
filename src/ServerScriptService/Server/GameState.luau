-- GameState: runs the round loop.
-- Waiting -> Intermission -> Prologue (opening incident) -> (Day -> Night) x NIGHTS_TO_WIN -> Victory / Defeat
-- The current phase is published as attributes on ReplicatedStorage.GameState
-- so every client's HUD can read it.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Creatures = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Creatures"))
local SoundFx = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundFx"))
local EventLog = require(script.Parent.EventLog)
local VoyageCast = require(script.Parent.VoyageCast)
local Forecasts = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Forecasts"))
local Voyages = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("Voyages")) -- S2.1
local LiveEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("LiveEvents")) -- LO.1
local WaveDirector = require(script.Parent.WaveDirector) -- pure night plan (R1.2)
local Voyage = require(script.Parent.Voyage) -- pure Pearl rules (R1.2)
local DawnBanking = require(script.Parent.DawnBanking) -- S2.2: Pearls banked at each dawn
local NightSafety = require(script.Parent.NightSafety) -- S2.3: Night-1 safety reserve (pure)
local ModeTest = require(script.Parent.ModeTest) -- S3.1b: Standard vs Endless Storm (pure)
local GrantService = require(script.Parent.GrantService) -- R1.3: the only writer of Pearl income

local GameState = {}

local FORECAST_KEYS = { wideMult = "ForecastWideMult", crabMult = "ForecastCrabMult", crabHpMult = "ForecastCrabHpMult", fuelMult = "ForecastFuelMult" }

-- Note: when an Atmosphere exists, Roblox ignores the Fog settings, so fog is done with Atmosphere.
-- V1 (visual overhaul, Oct 17): an overcast sea day and a dark, foggy storm night in cold navy and teal,
-- so warm lights and the beam stand out; the haze also hides where the sea ends.
-- Was: day Brightness 2, Ambient 110/110/115, OutdoorAmbient 128/128/135; atmosphere Density 0.3, Haze 0.5, Color 199/215/230.
local DAY_LIGHTING = {
	ClockTime = 14,
	Brightness = 1.4,
	Ambient = Color3.fromRGB(96, 104, 112),
	OutdoorAmbient = Color3.fromRGB(118, 126, 136),
}
-- Was (Oct 13 pass): ClockTime 23.2, Brightness 1.6, Ambient 40/48/78, OutdoorAmbient 92/108/158 (a bright moonlit blue).
local NIGHT_LIGHTING = {
	ClockTime = 23.2,
	Brightness = 1.3,
	Ambient = Color3.fromRGB(34, 42, 58),
	OutdoorAmbient = Color3.fromRGB(70, 88, 112),
}
local DAY_ATMOSPHERE = {
	Density = 0.4,
	Offset = 0.2,
	Haze = 2.4,
	Glare = 0,
	Color = Color3.fromRGB(150, 164, 174),
	Decay = Color3.fromRGB(96, 112, 124),
}
-- Was (Oct 13 pass): Density 0.32, Haze 0.6, Color 52/72/122.
local NIGHT_ATMOSPHERE = {
	Density = 0.34,
	Offset = 0.3,
	Haze = 1.2,
	Glare = 0,
	Color = Color3.fromRGB(46, 64, 80),
	Decay = Color3.fromRGB(26, 36, 52),
}

-- UserIds of a player list (bus payloads carry ids, never Instances)
local function userIds(players)
	local ids = {}
	for _, player in players do
		table.insert(ids, player.UserId)
	end
	return ids
end

local function tweenProps(instance, goal, seconds)
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	TweenService:Create(instance, info, goal):Play()
end

local function getAtmosphere()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	return atmosphere
end

local function setLighting(isNight, seconds)
	if isNight then
		tweenProps(Lighting, NIGHT_LIGHTING, seconds)
		tweenProps(getAtmosphere(), NIGHT_ATMOSPHERE, seconds)
	else
		-- Jump to dawn so the sun rises forward instead of rewinding through the evening
		if Lighting.ClockTime > 14 then
			Lighting.ClockTime = 5.5
		end
		tweenProps(Lighting, DAY_LIGHTING, seconds)
		tweenProps(getAtmosphere(), DAY_ATMOSPHERE, seconds)
	end
end

-- deps = { lamp, tower, creatures, state, remotes, resetRound }
function GameState.run(deps)
	local lamp = deps.lamp
	local tower = deps.tower
	local creatures = deps.creatures
	local loot = deps.loot
	local upgrades = deps.upgrades
	local state = deps.state

	-- voyage announcements go to the voyage crew only, never to the harbor (multi-ship phase 1)
	local function notifyAll(text)
		VoyageCast.fire(deps.remotes.Notify, text)
	end

	local function setPhase(phase, night)
		state:SetAttribute("Phase", phase)
		state:SetAttribute("Night", night or 0)
		if phase ~= "Waiting" and phase ~= "Intermission" then
			EventLog.log("Phase", { phase = phase, night = night or 0, fuel = math.floor(lamp.getFuel()), tower = state:GetAttribute("Integrity") })
		end
		if phase == "Night" then
			EventLog.setNight(night)
		end
	end

	-- Only players who pressed Play on the title screen take part in runs
	local function readyPlayers()
		local list = {}
		for _, player in Players:GetPlayers() do
			if player:GetAttribute("Ready") then
				table.insert(list, player)
			end
		end
		return list
	end

	local function noPlayers()
		return #readyPlayers() == 0
	end

	-- Departure revision: a crew in the harbor no longer starts the countdown just by existing. The ship
	-- leaves only when ShipDeparture has a departure request (4/4 automatic, SAIL NOW, or Play Again).
	local function departureRequested()
		if deps.departure then
			return deps.departure.requested()
		end
		return not noPlayers()
	end
	local function departureCancelled()
		return not departureRequested()
	end

	-- Waits until condition() is true. Returns false if everyone left first.
	local function waitUntil(condition)
		while not condition() do
			if noPlayers() then
				return false
			end
			task.wait(0.25)
		end
		return true
	end

	-- Counts down, publishing TimeLeft. Returns true if it finished,
	-- false if shouldStop() returned true first.
	local function countdown(seconds, shouldStop)
		local endsAt = os.clock() + seconds
		while true do
			local left = endsAt - os.clock()
			state:SetAttribute("TimeLeft", math.max(0, math.ceil(left)))
			-- stop is checked BEFORE completion, so a cancel during the last wait is never reported as done
			if shouldStop and shouldStop() then
				return false
			end
			if left <= 0 then
				return true
			end
			task.wait(0.2)
		end
	end

	-- Spawns a wave of crabs spread over `window` seconds. Returns a function that stops it.
	local function startWave(total, window)
		local active = true
		task.spawn(function()
			local interval = window / math.max(total, 1)
			for _ = 1, total do
				while active and creatures.load() >= Config.MAX_CREATURES do
					task.wait(0.5)
				end
				if not active then
					return
				end
				creatures.spawnCrab()
				task.wait(interval)
			end
		end)
		return function()
			active = false
		end
	end

	-- Swarm (Oct 12 2026): packs of Sand Skitters through the night, on top of the Rock Crab wave.
	-- Waits when MAX_CREATURES are alive, so phones never get more than that at once.
	local function startSwarm(total, window)
		local active = true
		if not Config.SWARM_ENABLED or total <= 0 then
			return function() end
		end
		task.spawn(function()
			local packSize = Config.SWARM_PACK_SIZE or 3
			local interval = window / math.max(math.ceil(total / packSize), 1)
			local spawned = 0
			task.wait(2)
			while active and spawned < total do
				while active and creatures.load() >= Config.MAX_CREATURES do
					task.wait(0.5)
				end
				if not active then
					return
				end
				local bearing = math.random() * 360
				for _ = 1, math.min(packSize, total - spawned) do
					creatures.spawn("SandSkitter", bearing + math.random(-12, 12))
					spawned += 1
				end
				task.wait(interval)
			end
		end)
		return function()
			active = false
		end
	end

	-- S6.5: the night's special monsters (WaveDirector.specials), one at a time, shuffled, across `window`
	local function startSpecials(counts, window)
		local queue = {}
		for kind, n in counts do
			for _ = 1, n do
				table.insert(queue, kind)
			end
		end
		local active = true
		if #queue == 0 then
			return function() end
		end
		for i = #queue, 2, -1 do
			local j = math.random(1, i)
			queue[i], queue[j] = queue[j], queue[i]
		end
		task.spawn(function()
			local interval = window / (#queue + 1)
			task.wait(interval)
			for _, kind in queue do
				while active and creatures.load() >= Config.MAX_CREATURES do
					task.wait(0.5)
				end
				if not active then
					return
				end
				creatures.spawn(kind)
				task.wait(interval)
			end
		end)
		return function()
			active = false
		end
	end

	-- The opening incident: the lamp is failing, a storm hits, something huge is out there.
	-- It can't be lost; it teaches fuel, the lamp, and the beam by doing.
	local function runPrologue()
		setPhase("Prologue", 0)
		setLighting(true, 1.5)
		lamp.setFuel(Config.PROLOGUE_START_FUEL)
		lamp.setDraining(true)
		tower.setProtected(true)
		local started = os.clock()
		local function elapsed()
			return os.clock() - started
		end
		if Config.DEV_TEST_BIG_MONSTER ~= "" and Creatures[Config.DEV_TEST_BIG_MONSTER] then
			task.delay(8, creatures.spawn, Config.DEV_TEST_BIG_MONSTER, math.random() * 360)
		end

		notifyAll("The lamp is failing! Grab OIL from the barrels and pour it in the FUEL TANK behind the lighthouse.")
		if not waitUntil(function()
			return lamp.getFuel() > Config.PROLOGUE_START_FUEL + 5 or elapsed() > 30
		end) then
			return false
		end
		if lamp.getFuel() <= Config.PROLOGUE_START_FUEL + 5 then
			EventLog.log("Tutorial", { step = "refuel", result = "timed out, reserve used" })
			lamp.addFuel(40)
			notifyAll("The emergency reserve kicked in. Remember: no oil, no light.")
		else
			EventLog.log("Tutorial", { step = "refuel", result = "done", seconds = elapsed() })
		end
		-- S2.4: the first crab climbs out as soon as the light is back, just ahead of the sweep, so a new keeper has
		-- a target the moment they take the lamp (first beam hit within 45 s). The other opening crabs follow as before.
		creatures.spawnCrab(lamp.getBeam().angle + 40)
		EventLog.log("Tutorial", { step = "firstCrab", seconds = elapsed() })

		notifyAll("The light is back! Use the LAMP console at the tower door and sweep the rocks.")
		if not waitUntil(function()
			return lamp.getKeeper() ~= nil or elapsed() > 45
		end) then
			return false
		end

		task.wait(2)
		EventLog.log("Tutorial", { step = "lamp", result = if lamp.getKeeper() then "done" else "timed out", seconds = elapsed() })
		creatures.showSilhouette(lamp.getBeam().angle + 30)
		notifyAll("...something enormous is out there.")
		task.wait(5)

		for _ = 2, Config.PROLOGUE_CRABS do -- the first one came out with the light (S2.4)
			creatures.spawnCrab()
			task.wait(1.5)
		end
		if Config.SWARM_ENABLED then
			-- a first taste of the swarm: small skitters the wide beam sweeps away
			local bearing = lamp.getBeam().angle
			for i = 1, (Config.PROLOGUE_SWARM or 0) do
				creatures.spawn("SandSkitter", bearing + math.random(-20, 20))
				if i % 3 == 0 then
					task.wait(2)
				end
			end
		end
		notifyAll("Crabs! Keeper: the wide beam pushes them back, F burns them. Everyone else: click or tap a crab with your harpoon.")

		if not waitUntil(function()
			return creatures.count() == 0 or elapsed() > Config.PROLOGUE_MAX_SECONDS
		end) then
			return false
		end

		lamp.setDraining(false)
		tower.setProtected(false)
		tower.repair(math.huge) -- start the real run with a full-strength tower
		EventLog.log("Tutorial", { step = "crabs", result = if creatures.count() == 0 then "cleared" else "timed out", seconds = elapsed() })
		EventLog.first("opening completed")
		creatures.clearAll()
		notifyAll(if Config.ECONOMY_ENABLED
			then "You survived the first squall. Grab any loot, then spend Shells at the UPGRADE bench."
			else "You survived the first squall. The real storm comes tonight.")
		task.wait(3)
		return true
	end

	setLighting(false, 0)

	-- Storm forecasts (launch R9): two are offered while the crew gathers; the crew votes at the ship.
	local function applyForecast(id)
		local f = id and Forecasts[id]
		state:SetAttribute("Forecast", if f then id else "")
		for field, attribute in FORECAST_KEYS do
			state:SetAttribute(attribute, if f and f[field] then f[field] else 1)
		end
	end
	local function offerForecasts()
		applyForecast(nil)
		for _, p in Players:GetPlayers() do
			p:SetAttribute("ForecastVote", nil)
		end
		if not Config.FORECASTS_ENABLED then
			state:SetAttribute("ForecastA", "")
			state:SetAttribute("ForecastB", "")
			return
		end
		local pool = table.clone(Forecasts.ORDER)
		local a = table.remove(pool, math.random(#pool))
		local b = table.remove(pool, math.random(#pool))
		state:SetAttribute("ForecastA", a)
		state:SetAttribute("ForecastB", b)
	end
	local function chooseForecast(crew)
		local a, b = state:GetAttribute("ForecastA"), state:GetAttribute("ForecastB")
		if not Config.FORECASTS_ENABLED or not Forecasts[a] or not Forecasts[b] then
			applyForecast(nil)
			return nil, 0, 0
		end
		local votesA, votesB = 0, 0
		for _, p in crew do
			local v = p:GetAttribute("ForecastVote")
			if v == a then
				votesA += 1
			elseif v == b then
				votesB += 1
			end
		end
		local pick = if votesA > votesB then a elseif votesB > votesA then b elseif math.random() < 0.5 then a else b
		applyForecast(pick)
		return pick, votesA, votesB
	end

	-- Voyage isolation (R1.5): a script error inside one voyage ends that voyage only. It is logged once as
	-- ErrorReport, the island is made safe, and the crew goes back to the deck; the loop carries on.
	local function recoverFromError(departing, err)
		local message = tostring(err)
		warn("[GameState] voyage error: " .. message)
		EventLog.log("ErrorReport", {
			where = "voyage",
			phase = state:GetAttribute("Phase"),
			night = state:GetAttribute("Night"),
			error = string.sub(string.split(message, "\n")[1], 1, 200),
		})
		local steps = {
			function()
				lamp.setDraining(false)
			end,
			function()
				tower.setProtected(false)
			end,
			function()
				creatures.clearAll()
			end,
			function()
				state:SetAttribute("BigWarning", "")
				state:SetAttribute("Cause", "error")
			end,
			function()
				local results = EventLog.endRun("Error", "The voyage stopped because of a script error.")
				EventLog.Publish("VoyageEnded", {
					VoyageId = EventLog.voyageId(),
					Outcome = "Error",
					Cause = "error",
					NightReached = results and results.nightReached or 0,
					Crew = userIds(departing),
				})
			end,
			function()
				setLighting(false, 2)
			end,
		}
		for _, step in steps do
			local stepOk, stepErr = pcall(step)
			if not stepOk then
				warn("[GameState] recovery step failed: " .. tostring(stepErr))
			end
		end
		for _, player in departing do
			if player.Parent == Players then
				player:SetAttribute("Ready", false) -- frees the ship seat; the ship unlocks at Waiting
				pcall(deps.sendToShip, player)
				deps.remotes.Notify:FireClient(player, "Something went wrong on the voyage. You're back on the deck: sail again when you're ready.")
			end
		end
	end

	while true do
		setPhase("Waiting", 0)
		state:SetAttribute("Reason", "")
		state:SetAttribute("Cause", "")
		offerForecasts()
		while not departureRequested() do
			task.wait(0.25)
		end

		setPhase("Intermission", 0)
		-- only for players ashore who haven't joined (the crew sees its own countdown card)
		for _, p in Players:GetPlayers() do
			if not p:GetAttribute("Ready") and p:GetAttribute("InLobby") then
				deps.remotes.Notify:FireClient(p, string.format("The ship sails in %d seconds! Walk onto the ship to join the crew.", Config.INTERMISSION_SECONDS))
			end
		end
		-- Departure (batch 1 revision): the ship's party is frozen here and only those players sail.
		-- Departure revision: the countdown is cancelled when the request is withdrawn (4/4 dropped to 3, the
		-- SAIL NOW player left, the party emptied), and an empty snapshot never starts a voyage.
		local departing = {}
		-- the request is revalidated once more right before the party is frozen (no yield in between)
		-- S2.5: Sail again (a rematch) leaves at once: the crew is already together and chose to go
		local sailIn = if deps.departure and deps.departure.mode and deps.departure.mode() == "rematch" then 0 else Config.INTERMISSION_SECONDS
		if countdown(sailIn, departureCancelled) and departureRequested() then
			departing = if deps.departShip then deps.departShip() else readyPlayers()
		end
		if #departing > 0 then
			-- Voyage isolation (R1.5): the whole voyage runs protected; an error ends this voyage only.
			local ok, err = xpcall(function()
				deps.resetRound()
				local forecast, votesA, votesB = chooseForecast(departing)
				-- Voyage definition (S2.1): the crew's choice if a sailing member holds its unlock, else the default
				local def = Voyages[state:GetAttribute("VoyageDef")]
				if type(def) ~= "table" or not def.nights or def.testOnly then
					def = Voyages[Voyages.DEFAULT] -- (S3.1b: a test-only voyage is never carried over; ModeTest decides below)
				end
				if def.unlock then
					local allowed = false
					for _, player in departing do
						if player:GetAttribute("Unlock_" .. def.unlock) == true then
							allowed = true
						end
					end
					if not allowed then
						def = Voyages[Voyages.DEFAULT]
					end
				end
				if def.event and not LiveEvents.isOn(def.event, os.time()) then
					def = Voyages[Voyages.DEFAULT] -- LO.1: the event ended while the crew was choosing
				end
				-- S3.1b: a crew sailing the default sails Endless Storm when its tested members are all in that arm
				if def.id == Voyages.DEFAULT then
					local arms = {}
					for _, player in departing do
						local arm = player:GetAttribute("ModeArm")
						if type(arm) == "string" then
							table.insert(arms, arm)
						end
					end
					local tested = ModeTest.voyageFor(arms)
					if tested and type(Voyages[tested]) == "table" then
						def = Voyages[tested]
					end
				end
				local voyageConfig = WaveDirector.configFor(def, Config)
				state:SetAttribute("VoyageDef", def.id)
				state:SetAttribute("TotalNights", if def.endless then 0 else def.nights) -- 0 = Endless Storm (S3.1b)
				state:SetAttribute("ReserveUsed", false) -- S2.3
				local reserveUsed = false -- S2.3: the Night-1 reserve is used at most once per voyage
				EventLog.startRun(departing)
				EventLog.setVoyage(def.id, if def.endless then 0 else def.nights)
				if forecast then
					EventLog.setForecast(forecast)
					EventLog.log("Forecast", { id = forecast, votesA = votesA, votesB = votesB, a = state:GetAttribute("ForecastA"), b = state:GetAttribute("ForecastB") })
					if deps.lampVisuals then
						deps.lampVisuals()
					end
					task.delay(1.2, notifyAll, "Forecast: " .. Forecasts[forecast].displayName .. ". " .. Forecasts[forecast].summary)
				end
				-- The crew sails from the ship to the lighthouse island
				for _, player in departing do
					deps.sendToIsland(player)
				end
				task.wait(0.6)
				local result = "Victory"

				if not runPrologue() then
					result = "Abandoned"
				else
					-- Big monsters this run: the definition's schedule (Standard 4, 7; Long 4, 7 and every night
					-- from 8), one random kind per scheduled night, picked in schedule order. S6.1: that kind leads;
					-- the other crew members' bosses are random kinds.
					local bigNights = {}
					for _, n in WaveDirector.bossNightsFor(def, Config) do
						bigNights[n] = Creatures.BIG_POOL[math.random(1, #Creatures.BIG_POOL)]
					end
					for night = 1, def.nights do
						-- DAY: prepare
						setPhase("Day", night)
						setLighting(false, 4)
						notifyAll(if Config.ECONOMY_ENABLED
							then string.format("Day %d: stock up on oil, repair the tower, and spend Shells at the UPGRADE bench.", night)
							else string.format("Day %d: stock up on oil and repair the tower before dark.", night))
						-- Warn early if the lamp won't last the night
						if lamp.getFuel() < lamp.getMaxFuel() * 0.5 then
							task.delay(4, notifyAll, string.format("FUEL IS LOW (%d)! Carry oil to the FUEL TANK before night falls, or the light will go out.", math.floor(lamp.getFuel())))
						end
						if not countdown(Config.DAY_SECONDS, noPlayers) then
							result = "Abandoned"
							break
						end

						-- NIGHT: survive
						setPhase("Night", night)
						setLighting(true, 4)
						notifyAll(string.format("Night %d: the storm is here. Keep the light alive!", night))
						lamp.setDraining(true)
						-- Spawn counts from the pure night plan (growth, final-night crisis, swarm share by crew size)
						local plan = WaveDirector.nightPlan(night, #readyPlayers(), { crabMult = state:GetAttribute("ForecastCrabMult") }, voyageConfig, def)
						local stopWave = startWave(plan.crabs, Config.NIGHT_SECONDS * Config.SPAWN_WINDOW)
						local stopSwarm = startSwarm(plan.skitters, Config.NIGHT_SECONDS * (Config.SWARM_WINDOW or 0.85))
						local specials = WaveDirector.specials(night, Creatures) -- S6.5
						local stopSpecials = startSpecials(specials, Config.NIGHT_SECONDS * Config.SPAWN_WINDOW)
						EventLog.log("NightSpawns", { night = night, crabs = plan.crabs, skitters = plan.skitters, eels = specials.SpitterEel or 0, puffers = specials.PufferMine or 0, lanterns = specials.GhostLantern or 0 })

						-- Big sea monsters arrive partway through this night: one per crew member (S6.1)
						local bigKind = bigNights[night]
						if bigKind then
							task.delay(3, function()
								notifyAll("The sea is restless... something BIG is coming tonight. Stay close to your crew.")
								if state:GetAttribute("Phase") == "Night" and state:GetAttribute("Night") == night then
									state:SetAttribute("BigWarning", "approaching") -- HUD warning until it arrives
								end
							end)
							task.delay(Config.NIGHT_SECONDS * Config.BIG_SPAWN_DELAY, function()
								state:SetAttribute("BigWarning", "")
								if state:GetAttribute("Phase") ~= "Night" or state:GetAttribute("Night") ~= night then
									return -- the night already ended
								end
								local bearings = WaveDirector.bossBearings(#readyPlayers(), math.random() * 360)
								for i, bearing in bearings do
									local kind = if i == 1 then bigKind else Creatures.BIG_POOL[math.random(1, #Creatures.BIG_POOL)]
									creatures.spawn(kind, bearing)
									local rad = math.rad(bearing)
									SoundFx.playAt("monster", Vector3.new(-math.sin(rad) * 80, 5, -math.cos(rad) * 80))
									EventLog.log("BigMonsterSpawned", { kind = kind, night = night, bearing = math.floor(bearing), of = #bearings })
									EventLog.Publish("BossWarning", { VoyageId = EventLog.voyageId(), DefId = kind, Night = night })
								end
								notifyAll(if #bearings == 1
									then string.format("A %s climbs out of the sea! Big monsters hit hard: bring your best gear.", string.upper(Creatures[bigKind].displayName))
									else string.format("%d big monsters climb out of the sea, one for each Keeper! Split up and bring your best gear.", #bearings))
							end)
						end

						-- Night-1 safety (S2.3): a first-voyage crew's first blackout tonight is caught once by the reserve
						local function nightOneSafety()
							local runs = {}
							for _, p in readyPlayers() do
								table.insert(runs, p:GetAttribute("RunsCompleted") or 0)
							end
							if NightSafety.shouldRefill(night, lamp.getFuel(), reserveUsed, runs) then
								reserveUsed = true
								lamp.setFuel(lamp.getMaxFuel())
								state:SetAttribute("ReserveUsed", true)
								EventLog.log("NightOneReserve", { night = night, crew = #runs })
								EventLog.Publish("ReserveUsed", { VoyageId = EventLog.voyageId(), Reason = "night1safety" })
								for _, p in readyPlayers() do
									deps.remotes.CrewFeed:FireClient(p, { kind = "reserve" })
								end
							end
						end
						local survived = countdown(Config.NIGHT_SECONDS, function()
							nightOneSafety()
							return noPlayers()
								or lamp.darkSeconds >= Config.DARK_GRACE_SECONDS
								or tower.isBroken()
						end)

						stopWave()
						stopSwarm()
						stopSpecials()
						local wentDark = lamp.darkSeconds >= Config.DARK_GRACE_SECONDS
						lamp.setDraining(false)
						creatures.clearAll() -- at dawn, the survivors retreat into the sea

						if not survived then
							if noPlayers() then
								result = "Abandoned"
							else
								result = "Defeat"
								state:SetAttribute("Cause", if wentDark then "blackout" else "breach") -- for the results screen
								state:SetAttribute("Reason", if wentDark
									then string.format("The light went out: the lamp ran out of fuel and stayed dark for %d seconds.", Config.DARK_GRACE_SECONDS)
									else "The creatures broke into the lighthouse.")
							end
							break
						end
						local bonus = if Config.ECONOMY_ENABLED then Config.WAVE_BONUS_PER_NIGHT * night else 0
						upgrades.addShells(bonus, "waveBonus")
						EventLog.log("NightSurvived", { night = night, bonus = bonus, fuel = math.floor(lamp.getFuel()), tower = state:GetAttribute("Integrity") })
						EventLog.Publish("NightSurvived", { VoyageId = EventLog.voyageId(), Night = night, Crew = userIds(readyPlayers()) })
						-- Dawn loot window (Oct 12 2026): leftover loot stays on the beach most of the day at full
						-- value, then the tide brings what's left in at DAWN_LOOT_FRACTION. The last night ends the run,
						-- so there the tide comes quickly as before.
						local lootSeconds = if night < def.nights
							then math.min(Config.DAWN_LOOT_SECONDS or 25, Config.DAY_SECONDS - 3)
							else 10
						loot.keepFor(lootSeconds + 1)
						if night < def.nights and Config.ECONOMY_ENABLED then
							if loot.count() > 0 then
								notifyAll(string.format("Night %d survived! +%d shells wave bonus. Loot is still on the beach: grab it in the next %d seconds for full value. The tide brings the rest in at half.", night, bonus, lootSeconds))
							else
								notifyAll(string.format("Night %d survived! +%d shells wave bonus.", night, bonus))
							end
						elseif night < def.nights then
							notifyAll(string.format("Night %d survived! Dawn is coming.", night))
						end
						task.delay(lootSeconds, loot.tideCollect, Config.DAWN_LOOT_FRACTION) -- the tide brings leftover loot in at reduced value
						-- S5.3: the Economy's auto-sell (launch R10 switch, off by default) listens for this
						EventLog.Publish("DawnLootWindow", { VoyageId = EventLog.voyageId(), Seconds = lootSeconds })
					end
				end

				setPhase(result, state:GetAttribute("Night"))
				local results = EventLog.endRun(result, state:GetAttribute("Reason"))
				results.cause = state:GetAttribute("Cause") or ""
				EventLog.Publish("VoyageEnded", {
					VoyageId = EventLog.voyageId(),
					Outcome = result,
					Cause = results.cause,
					NightReached = results.nightReached,
					Crew = userIds(departing),
					Voyage = def.id, -- S3.1b: which mode the crew sailed
				})
				results.shellsLeft = upgrades.getShells()
				results.economy = Config.ECONOMY_ENABLED
				setLighting(false, 4)
				if result == "Victory" then
					notifyAll(string.format("You kept the light alive for all %d nights!", def.nights))
				elseif result == "Defeat" then
					notifyAll(state:GetAttribute("Reason") .. " The sea claims the island.")
				end

				-- Results screen and rematch vote. Players who don't choose Play Again go back to the title
				-- screen, which tells us whether people choose to replay (a key playtest question).
				local voters = readyPlayers()

				-- Pearl rewards (saved, personal). Night Pearls were banked at each dawn (S2.2, DawnBanking); Results
				-- pays what Voyage.resultPearls says is left (the victory bonus on a win), plus per-award Pearls here.
				-- results.pearls is the voyage total (banked + paid now); results.banked the dawn part.
				results.pearls = {}
				results.banked = {}
				results.crewSize = #voters -- S2.5: for the share line
				if result ~= "Abandoned" then
					local won = result == "Victory"
					local nightReached = if won then def.nights else results.nightReached
					for _, player in voters do
						local banked = DawnBanking.bankedFor(EventLog.voyageId(), player.UserId)
						local earned = Voyage.resultPearls(nightReached, won, banked, Config)
						for _, award in results.awards do
							if award.player == player.DisplayName then
								earned += Config.PEARLS_PER_AWARD
							end
						end
						if earned > 0 then
							GrantService.Grant(player, EventLog.voyageId() .. ":result:" .. player.UserId, { Pearls = earned }, "run")
						end
						deps.playerData.recordRun(player, result == "Victory", results.nightReached, def.id)
						if won and def.unlocks then
							deps.playerData.unlock(player, def.unlocks) -- S2.1: a Standard win unlocks the Long Voyage
						end
						results.pearls[player.Name] = banked + earned
						results.banked[player.Name] = banked
					end
				end
				DawnBanking.forget(EventLog.voyageId())
				-- Loot is run-scoped like shells: unsold loot is lost when the voyage ends
				for _, player in Players:GetPlayers() do
					deps.playerData.clearRunLoot(player)
				end
				if result ~= "Abandoned" and #voters > 0 then
					for _, player in voters do
						player:SetAttribute("WantsRematch", false)
					end
					for _, player in voters do -- the results screen is for this voyage's crew only
						if player.Parent then
							deps.remotes.RunResults:FireClient(player, results)
						end
					end
					EventLog.log("ResultsShown", { players = #voters })
					EventLog.log("RematchOffered", { players = #voters })
					countdown(Config.RESULT_SECONDS, function()
						for _, player in voters do
							if player.Parent and not player:GetAttribute("WantsRematch") then
								return false
							end
						end
						return true -- everyone voted: start right away
					end)
					local again = 0
					for _, player in voters do
						if player.Parent then
							local wants = player:GetAttribute("WantsRematch") == true
							EventLog.log("RematchChoice", { player = player.Name, choice = if wants then "play again" else "menu" })
							if wants then
								again += 1
								EventLog.Publish("SailAgain", { VoyageId = EventLog.voyageId(), UserId = player.UserId })
							else
								player:SetAttribute("Ready", false)
								deps.sendToShip(player) -- back to the lobby ship
							end
						end
					end
					EventLog.log("Rematch", { playAgain = again, of = #voters })
					if again > 0 and deps.departure then
						deps.departure.rematch() -- Play Again is a deliberate departure for the crew that chose it
					end
				else
					task.wait(3)
				end
			end, debug.traceback)
			if not ok then
				recoverFromError(departing, err)
			end
		end
	end
end

return GameState
