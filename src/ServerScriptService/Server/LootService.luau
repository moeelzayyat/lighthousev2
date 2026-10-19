-- LootService: loot that pops out of dead creatures.
--
-- Every crab drops Shells. Some drop rare loot with a colored light pillar:
--   Sea Glass   (blue, rare)    worth SEA_GLASS_VALUE shells
--   Black Pearl (purple, epic)  worth BLACK_PEARL_VALUE shells + server announcement
--
-- Loot flies to any player who comes close and goes into the crew's shared pool.
-- Uncollected loot washes away after LOOT_LIFETIME seconds, and at dawn,
-- so someone has to run out into the dark to grab it.
-- S4.5: the server places an orb once (a short pop when it drops), then never moves it: the bob, the spin and the
-- flight to a nearby player are drawn by each client (Client/LootView). The server still decides the pickup from
-- the same magnet range and speed, so loot replicates only when it spawns and when it is collected.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local EventLog = require(script.Parent.EventLog)
local GrantService = require(script.Parent.GrantService) -- R1.3: Pearl drops are idempotent claims
local VoyageCast = require(script.Parent.VoyageCast)
local Ground = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Ground"))
local Creatures = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Creatures"))
local PetRules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PetRules")) -- PET.1 (D-051)

local LootService = {}

-- `item` = goes into the collecting player's saved inventory (see Shared/Items) instead of the crew's shells
local KINDS = {
	Shells = { color = Color3.fromRGB(255, 225, 205), size = 0.9, pillar = nil },
	CrabClaw = { color = Color3.fromRGB(230, 120, 80), size = 0.8, pillar = nil, item = "CrabClaw" },
	SeaGlass = { color = Color3.fromRGB(90, 190, 255), size = 1.3, pillar = Color3.fromRGB(90, 190, 255), name = "Sea Glass", item = "SeaGlass" },
	BlackPearl = { color = Color3.fromRGB(170, 90, 255), size = 1.6, pillar = Color3.fromRGB(170, 90, 255), name = "a BLACK PEARL", item = "BlackPearl" },
	-- Pearls (the permanent currency) dropped by big monsters: added straight to the collector's saved Pearls
	Pearls = { color = Color3.fromRGB(245, 240, 255), size = 1.4, pillar = Color3.fromRGB(255, 245, 210), name = "Pearls", pearls = true },
}
local MAGNET_SPEED = 35
local nextPetPick: { [Player]: number } = {} -- PET.1: when each player's pet fetches its next orb
local petTrip: { [Player]: { drop: any, at: number } } = {} -- PET.1: the orb each pet is flying to, and when it gets there

local folder
local upgrades
local remotes
local playerData
local drops = {}
local dropSerial = 0 -- per-server id for each drop (part of its Pearl claim id)

local function makePart(name, size, color, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Shape = shape or Enum.PartType.Block
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	return part
end

local function spawnDrop(kind, value, position)
	local info = KINDS[kind]
	local orb = makePart("Loot_" .. kind, Vector3.new(info.size, info.size, info.size), info.color, Enum.PartType.Ball)
	orb.CFrame = CFrame.new(position)
	orb.Parent = folder

	local pillar
	if info.pillar then
		pillar = makePart("Pillar", Vector3.new(0.5, 14, 0.5), info.pillar)
		pillar.Transparency = 0.45
		pillar.Parent = orb
	end

	-- Pop out in a little arc, then rest on the ground
	local angle = math.random() * math.pi * 2
	local landing = position + Vector3.new(math.cos(angle) * 3, 0, math.sin(angle) * 3)
	landing = Vector3.new(landing.X, Ground.heightAt(landing.X, landing.Z) + info.size / 2 + 0.2, landing.Z)
	dropSerial += 1
	local drop = {
		serial = dropSerial,
		kind = kind,
		value = value,
		orb = orb,
		pillar = pillar,
		position = landing,
		bornAt = os.clock(),
		landed = false,
	}
	orb:SetAttribute("Landing", landing) -- where clients draw it once it has landed (S4.5)
	local pop = TweenService:Create(orb, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = CFrame.new(landing),
	})
	pop.Completed:Connect(function()
		drop.landed = true
		orb:SetAttribute("Landed", true)
	end)
	pop:Play()
	if pillar then
		pillar.CFrame = CFrame.new(landing + Vector3.new(0, 7, 0))
	end
	table.insert(drops, drop)
end

-- Called whenever a creature dies. Big monsters drop a big pile of loot.
function LootService.dropFrom(position, kind)
	if not Config.ECONOMY_ENABLED then
		return
	end
	local stats = kind and Creatures[kind]
	-- S6.5: a creature with its own loot table rolls one row of it
	if stats and stats.loot then
		local roll, sum = math.random(), 0
		for _, row in stats.loot do
			sum += row.chance
			if roll <= sum then
				for _, d in row.drops do
					spawnDrop(d[1], math.random(d[2], d[3]), position)
				end
				break
			end
		end
		return
	end
	if stats and stats.swarm then
		-- swarm crabs: a Shell now and then, no rare loot (keeps the economy where it was)
		if math.random() < (Config.SWARM_SHELL_CHANCE or 0.2) then
			spawnDrop("Shells", 1, position)
		end
		return
	end
	if stats and stats.big then
		spawnDrop("Shells", Config.BIG_LOOT_SHELLS, position)
		spawnDrop("SeaGlass", 1, position)
		spawnDrop("CrabClaw", 1, position)
		spawnDrop("CrabClaw", 1, position)
		if math.random() < Config.BIG_PEARL_CHANCE then
			spawnDrop("BlackPearl", 1, position)
		end
		if math.random() < Config.BOSS_PEARL_CHANCE then
			spawnDrop("Pearls", math.random(Config.BOSS_PEARL_MIN, Config.BOSS_PEARL_MAX), position)
		end
		VoyageCast.fire(remotes.Notify, "The monster is down! Grab its loot!")
		return
	end
	spawnDrop("Shells", math.random(Config.SHELLS_PER_CRAB_MIN, Config.SHELLS_PER_CRAB_MAX), position)
	if math.random() < Config.CRAB_CLAW_CHANCE then
		spawnDrop("CrabClaw", 1, position)
	end

	local roll = math.random()
	if roll < Config.BLACK_PEARL_CHANCE then
		spawnDrop("BlackPearl", 1, position)
	elseif roll < Config.BLACK_PEARL_CHANCE + Config.SEA_GLASS_CHANCE then
		spawnDrop("SeaGlass", 1, position)
	end
end

local function removeAt(index)
	local drop = table.remove(drops, index)
	drop.orb:Destroy()
end

local function collect(index, player)
	local drop = drops[index]
	local info = KINDS[drop.kind]
	if info.pearls then
		-- Permanent currency straight into this player's saved Pearls
		GrantService.Grant(player, EventLog.voyageId() .. ":drop:" .. drop.serial .. ":" .. player.UserId, { Pearls = drop.value }, "boss drop")
		EventLog.log("BossPearls", { player = player.Name, amount = drop.value })
		remotes.LootCollected:FireClient(player, drop.kind, drop.value)
		EventLog.Publish("LootCollected", { VoyageId = EventLog.voyageId(), UserId = player.UserId, ItemId = drop.kind, Qty = drop.value })
		VoyageCast.fire(remotes.Notify, string.format("%s picked up %d Pearls from the monster!", player.DisplayName, drop.value))
		removeAt(index)
		return
	end
	local amount = drop.value
	if info.item then
		-- Personal loot: into this player's saved inventory
		playerData.addItem(player, info.item, drop.value)
		EventLog.loot(drop.kind, 0, player)
	else
		-- S6.4: the collector's Shell Pouch (Quartermaster boost) adds its share; fractions round up by chance
		local gain = player:GetAttribute("Boost_ShellGainPct")
		if type(gain) == "number" and gain > 0 then
			local exact = drop.value * (1 + gain)
			amount = math.floor(exact) + (if math.random() < exact % 1 then 1 else 0)
		end
		upgrades.addShells(amount, "loot")
		EventLog.loot(drop.kind, amount, player)
	end
	if drop.kind == "SeaGlass" or drop.kind == "BlackPearl" then
		EventLog.log("RareLoot", { player = player.Name, kind = drop.kind })
	end
	remotes.LootCollected:FireClient(player, drop.kind, amount)
	EventLog.Publish("LootCollected", { VoyageId = EventLog.voyageId(), UserId = player.UserId, ItemId = drop.kind, Qty = amount })
	if drop.kind == "BlackPearl" then
		VoyageCast.fire(remotes.Notify, string.format("%s found %s!", player.DisplayName, info.name))
	elseif drop.kind == "SeaGlass" then
		VoyageCast.fire(remotes.Notify, string.format("%s found %s!", player.DisplayName, info.name))
	end
	removeAt(index)
end

-- How many loot orbs are lying around right now
function LootService.count()
	return #drops
end

-- Dawn (Oct 12 2026, owner: loot vanished as soon as the night ended): every orb still on the
-- ground gets at least `seconds` more before it washes away, so the crew can go and collect it.
function LootService.keepFor(seconds)
	local now = os.clock()
	for _, drop in drops do
		local remaining = Config.LOOT_LIFETIME - (now - drop.bornAt)
		if remaining < seconds then
			drop.bornAt = now - (Config.LOOT_LIFETIME - seconds)
		end
	end
end

function LootService.clearAll()
	for index = #drops, 1, -1 do
		removeAt(index)
	end
end

-- At dawn the tide carries leftover loot to the crew at a fraction of its value,
-- so a solo Keeper who couldn't leave the lamp still gets something.
-- Returns the number of shells added.
function LootService.tideCollect(fraction)
	local total = 0
	for _, drop in drops do
		if drop.kind == "Shells" then -- personal items aren't carried in by the tide
			total += drop.value
		end
	end
	LootService.clearAll()
	local shells = math.floor(total * fraction)
	if shells > 0 then
		upgrades.addShells(shells, "tide")
		EventLog.loot("Tide", shells)
		EventLog.log("TideLoot", { shells = shells, fullValue = total })
		VoyageCast.fire(remotes.Notify, string.format("The tide brought in %d shells from uncollected loot.", shells))
	end
	return shells
end

local function onHeartbeat(dt)
	if #drops == 0 then
		return
	end

	-- Collect living players' positions once per frame
	local players = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			table.insert(players, { player = player, position = root.Position })
		end
	end

	local now = os.clock()
	-- PET.1 (D-051): a pet brings back one Shells orb at a time from around its owner (it goes to the crew, as if
	-- the owner picked it up)
	for _, entry in players do
		local player = entry.player
		local trip = petTrip[player]
		if trip then
			-- the pet is on its way: the orb counts when it gets there (unless someone picked it up first)
			local index = table.find(drops, trip.drop)
			if not index then
				petTrip[player] = nil
			elseif now >= trip.at then
				petTrip[player] = nil
				nextPetPick[player] = now + Config.PET_PICK_INTERVAL
				collect(index, player)
			end
		elseif player:GetAttribute("Pet") and now >= (nextPetPick[player] or 0) then
			local index = PetRules.pick(entry.position, drops :: any, Config.PET_RANGE)
			if index then
				local drop = drops[index]
				drop.claimed = true
				drop.orb:SetAttribute("PetClaim", player.UserId) -- Client/PetView flies this player's pet to it
				petTrip[player] = { drop = drop, at = now + (drop.position - entry.position).Magnitude / Config.PET_SPEED }
			end
		end
	end
	for index = #drops, 1, -1 do
		local drop = drops[index]
		if now - drop.bornAt > Config.LOOT_LIFETIME then
			removeAt(index)
		elseif drop.landed then
			-- Find the nearest player within magnet range
			local nearest, nearestDistance = nil, Config.LOOT_MAGNET_RADIUS
			for _, entry in players do
				local distance = (entry.position - drop.position).Magnitude
				if distance < nearestDistance then
					nearest, nearestDistance = entry, distance
				end
			end

			if nearest and nearestDistance <= Config.LOOT_PICKUP_RADIUS then
				collect(index, nearest.player)
			elseif nearest then
				-- pulled toward the player (the client draws the flight; the orb itself stays put here)
				local step = math.min(MAGNET_SPEED * dt, nearestDistance)
				drop.position += (nearest.position - drop.position).Unit * step
			end
		end
	end
end

function LootService.init(islandFolder, upgradeService, remoteFolder, playerDataService)
	upgrades = upgradeService
	remotes = remoteFolder
	playerData = playerDataService
	folder = Instance.new("Folder")
	folder.Name = "Loot"
	folder.Parent = islandFolder
	RunService.Heartbeat:Connect(onHeartbeat)
	Players.PlayerRemoving:Connect(function(player)
		nextPetPick[player] = nil -- PET.1
		petTrip[player] = nil
	end)
	-- S5.3: a killed creature drops its loot (was CreatureService.onKilled)
	EventLog.Subscribe("CreatureKilled", function(e)
		LootService.dropFrom(Vector3.new(e.X, e.Y, e.Z), e.DefId)
	end)
end

return LootService
