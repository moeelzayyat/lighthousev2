-- CreatureService: spawns and moves creatures, applies the beam to them, and runs their AGGRO.
--
-- Aggro (threat): every creature keeps a threat score for each possible target:
--   "tower"      gains threat when the lighthouse beam damages the creature (and always has a base amount)
--   a player   gains threat when that player hurts the creature, or stands close to it
--   a cannon   gains threat when that cannon hits the creature
-- Threat slowly fades. The creature walks to the target with the most threat and attacks it:
--   tower  -> chews on it (tower breached = run lost)
--   cannon -> chews on it until it's destroyed
--   player -> bites (armor reduces the damage); players can die
-- Eye color shows intent: yellow = tower, orange = a cannon, red = a player.
--
-- S4.2/S4.3: creatures are tables stepped at 20 Hz. The server keeps no creature models: 12 times a second it
-- sends every creature's position and state as one binary snapshot (Shared/CreatureSnapshot, an
-- UnreliableRemoteEvent), and each client draws them (Client/CreatureView) from the templates published in
-- ReplicatedStorage.CreatureTemplates.
-- Beam rules: wide beam pushes them away from the lighthouse; focused beam stops and burns them.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local EventLog = require(script.Parent.EventLog)
local SniperService = require(script.Parent.SniperService) -- D-044: the rifle's shot line
local Ground = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Ground"))
local SoundFx = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundFx"))
local Creatures = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Creatures"))
local CreatureSnapshot = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CreatureSnapshot"))

local CreatureService = {}

local CRAB_COLOR = Color3.fromRGB(176, 64, 44)
local CLAW_COLOR = Color3.fromRGB(150, 50, 35)
local EYE_COLOR = Color3.fromRGB(255, 240, 120) -- the template's eyes; the client recolours them (S4.3)

local refs
local lamp
local tower
local upgrades
local defense

local creatures = {}
local templates = {} -- creature type -> template model
local state -- GameState folder (the boss bar reads BossName / BossHealth / BossMax)
local center = Config.ISLAND_CENTER

local STEP = 1 / 20 -- simulation step (S4.2)
local SEND_INTERVAL = 1 / 12 -- snapshots per second (S4.2)
local kinds = CreatureSnapshot.kinds(Creatures)
local kindIndex = {}
for i, name in kinds do
	kindIndex[name] = i - 1
end
local nextId = 0
local dying = {} -- killed creatures, sent a few more times with the DYING flag so clients play the burst
local snapshotRemote -- UnreliableRemoteEvent Remotes.CreatureSnapshot
CreatureService.bytesSent = 0 -- probe: snapshot bytes sent to each client since boot

-- Same convention as the beam: bearing 0 points along -Z
local function directionFor(bearing)
	local rad = math.rad(bearing)
	return Vector3.new(-math.sin(rad), 0, -math.cos(rad))
end

local function makeModelPart(model, name, size, offset, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CFrame = CFrame.new(offset)
	part.Parent = model
	return part
end

-- Builds (once) the model template for a creature type from its art in ServerStorage.Art
local function buildTemplate(kind)
	local stats = Creatures[kind]
	local model = Instance.new("Model")
	model.Name = kind
	local art = ServerStorage:FindFirstChild("Art") and ServerStorage.Art:FindFirstChild(stats.art)
	local body
	if art then
		body = art:Clone()
		body.Name = "Body"
		body.Size *= stats.scale
		body.Anchored = true
		body.CanCollide = false
		body.CanQuery = false
		body.CanTouch = false
		body.CFrame = CFrame.new()
		body.Parent = model
		-- Pivot sits 0.7 studs above the ground; turn the model to face -Z
		local lift = body.Size.Y / 2 - 0.7
		body.PivotOffset = (CFrame.new(0, lift, 0) * CFrame.Angles(0, math.rad(art:GetAttribute("YawOffset") or 0), 0)):Inverse()
		-- Textured models can't be recolored, so hit/burn feedback on big monsters is a colored glow. S4.4: only big
		-- monsters carry a light (the render budget allows about 4 during a swarm); small ones flash their eyes.
		if stats.big then
			local feedback = Instance.new("PointLight")
			feedback.Name = "Feedback"
			feedback.Range = 7 + stats.bodyRadius * 2
			feedback.Brightness = 4
			feedback.Enabled = false
			feedback.Parent = body
		end
	else
		-- Fallback: simple parts (scaled for big monsters); S6.5: the new monsters' own shapes
		local s = stats.bodyRadius
		if stats.shape == "eel" then
			body = makeModelPart(model, "Body", Vector3.new(1.1, 1.1, 4.6) * s, Vector3.zero, stats.color)
			makeModelPart(model, "Head", Vector3.new(1.5, 1.3, 1.4) * s, Vector3.new(0, 0.35, -2.6) * s, stats.color)
		elseif stats.shape == "puffer" then
			body = makeModelPart(model, "Body", Vector3.new(2.4, 2.4, 2.4) * s, Vector3.zero, stats.color)
			body.Shape = Enum.PartType.Ball
			local spikes = makeModelPart(model, "Spikes", Vector3.new(2.9, 2.9, 2.9) * s, Vector3.zero, stats.color, Enum.Material.ForceField)
			spikes.Shape = Enum.PartType.Ball
		elseif stats.shape == "lantern" then
			body = makeModelPart(model, "Body", Vector3.new(1.6, 1.6, 1.6) * s, Vector3.zero, stats.color, Enum.Material.Neon)
			body.Shape = Enum.PartType.Ball
			body.Transparency = 0.25
			makeModelPart(model, "Cage", Vector3.new(0.4, 0.6, 0.4) * s, Vector3.new(0, 1.2, 0) * s, Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
		elseif stats.shape == "witch" then -- S6.6
			body = makeModelPart(model, "Body", Vector3.new(1.6, 3.2, 1.6) * s, Vector3.zero, stats.color, Enum.Material.Fabric)
			local head = makeModelPart(model, "Head", Vector3.new(1.2, 1.2, 1.2) * s, Vector3.new(0, 2.2, 0) * s, Color3.fromRGB(200, 215, 230))
			head.Shape = Enum.PartType.Ball
		elseif stats.shape == "shaman" then -- S6.6
			body = makeModelPart(model, "Body", Vector3.new(2, 2.2, 2) * s, Vector3.zero, stats.color, Enum.Material.Slate)
			makeModelPart(model, "Staff", Vector3.new(0.3, 3.2, 0.3) * s, Vector3.new(1.3, 0.6, 0) * s, Color3.fromRGB(120, 85, 55), Enum.Material.Wood)
		else
			body = makeModelPart(model, "Body", Vector3.new(3.2, 1.4, 2.6) * s, Vector3.new(0, 0, 0), CRAB_COLOR)
			makeModelPart(model, "ClawL", Vector3.new(0.9, 0.9, 1.2) * s, Vector3.new(-1.3, 0.1, -1.7) * s, CLAW_COLOR)
			makeModelPart(model, "ClawR", Vector3.new(0.9, 0.9, 1.2) * s, Vector3.new(1.3, 0.1, -1.7) * s, CLAW_COLOR)
		end
	end
	model.PrimaryPart = body
	local height = body.Size.Y
	local bigScale = if stats.big then 3 else 1

	-- Glowing eyes drawn as a billboard: fog and darkness don't hide them
	local eyes = Instance.new("BillboardGui")
	eyes.Name = "GlowEyes"
	eyes.Size = UDim2.new(2.4 * bigScale, 0, 0.9 * bigScale, 0) -- in studs, so they shrink with distance
	eyes.StudsOffset = Vector3.new(0, if stats.big then height * 0.25 else 1.3, 0)
	eyes.LightInfluence = 0
	eyes.MaxDistance = 400
	eyes.Parent = body
	for _, x in { 0.12, 0.62 } do
		local eye = Instance.new("Frame")
		eye.Size = UDim2.fromScale(0.26, 0.7)
		eye.Position = UDim2.fromScale(x, 0.15)
		eye.BackgroundColor3 = EYE_COLOR
		eye.BorderSizePixel = 0
		eye.Parent = eyes
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = eye
	end
	-- Textured art can say where its own eyes are (art attributes EyeAt, in studs in the art's own frame, and
	-- EyeSize), so the glow sits on the face instead of above the head
	local eyeAt = art and art:GetAttribute("EyeAt")
	if typeof(eyeAt) == "Vector3" then
		local spot = Instance.new("Attachment")
		spot.Name = "EyeSpot"
		spot.Position = eyeAt * stats.scale
		spot.Parent = body
		eyes.Adornee = spot
		eyes.StudsOffset = Vector3.zero
		local eyeSize = art:GetAttribute("EyeSize")
		if type(eyeSize) == "number" then
			eyes.Size = UDim2.new(2.4 * bigScale * eyeSize, 0, 0.9 * bigScale * eyeSize, 0)
		end
	end

	-- Health bar, shown once the creature has taken damage
	local bar = Instance.new("BillboardGui")
	bar.Name = "HealthBar"
	bar.Size = UDim2.new(3 * bigScale, 0, 0.35 * bigScale, 0)
	bar.StudsOffset = Vector3.new(0, if stats.big then height * 0.6 + 1 else 2.4, 0)
	bar.LightInfluence = 0
	bar.MaxDistance = 250
	bar.Enabled = false
	bar.Parent = body
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	back.BorderSizePixel = 0
	back.Parent = bar
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(240, 80, 60)
	fill.BorderSizePixel = 0
	fill.Parent = back

	return model
end

local function getTemplate(kind)
	if not templates[kind] then
		templates[kind] = buildTemplate(kind)
	end
	return templates[kind]
end

-- Where the creature stands (world position on the ground) and which way it faces; the client adds the walk bob
local function place(crab)
	local surface, inWater = Ground.heightAt(crab.pos.X, crab.pos.Z)
	crab.inWater = inWater
	local heightOffset = (if inWater then -0.5 else 0.7) + (crab.stats.hover or 0) -- half-submerged in the sea; S6.5: a Ghost Lantern floats
	crab.worldPos = Vector3.new(crab.pos.X, surface + heightOffset, crab.pos.Z)
	local face = crab.facing or Vector3.new(center.X, 0, center.Z)
	local dx, dz = face.X - crab.pos.X, face.Z - crab.pos.Z
	if dx * dx + dz * dz > 0.0025 then
		crab.yaw = math.deg(math.atan2(-dx, -dz))
	end
end

---------------------------------------------------------------------
-- Aggro helpers
---------------------------------------------------------------------

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

-- Where a target is (flat), or nil if it no longer exists
local function targetPosition(target)
	if target == "tower" then
		return Vector3.new(center.X, 0, center.Z)
	elseif typeof(target) == "Instance" then
		local character = (target :: any).Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return root and flat(root.Position)
	elseif type(target) == "table" and target.position then
		return flat(target.position)
	end
	return nil
end

local function targetValid(target)
	if target == "tower" then
		return true
	elseif typeof(target) == "Instance" then
		if target.Parent ~= Players or not target:GetAttribute("Ready") then
			return false
		end
		if target:GetAttribute("OnSniperTower") then
			return false -- D-044: out of reach up the sniper tower
		end
		local character = (target :: any).Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		return humanoid ~= nil and humanoid.Health > 0
	elseif type(target) == "table" then
		return (target.level or 0) > 0 -- a built cannon
	end
	return false
end

local function addThreat(crab, target, amount)
	if target ~= nil and amount > 0 then
		crab.threat[target] = (crab.threat[target] or 0) + amount
	end
end

-- Picks the target with the most threat; only switches if the new one clearly beats the current one
local function chooseTarget(crab)
	local best, bestScore = "tower", crab.threat.tower or 0
	for target, score in crab.threat do
		if target ~= "tower" and score > bestScore and targetValid(target) then
			best, bestScore = target, score
		end
	end
	local current = crab.target
	if current and current ~= best and targetValid(current) then
		if bestScore < (crab.threat[current] or 0) * Config.THREAT_SWITCH_RATIO then
			return current
		end
	end
	return best
end

-- Eye colour shows intent (drawn by the client): the snapshot carries which kind of target it is after
local function setEyes(crab, target)
	crab.targetBits = if target == "tower" then 0
		elseif typeof(target) == "Instance" then CreatureSnapshot.TARGET_PLAYER
		else CreatureSnapshot.TARGET_CANNON
end

-- A bite or slam on a player: armor reduces it; records deaths
local function bitePlayer(player, crabPosition, damage, cause)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local reduction = player:GetAttribute("DamageReduction") or 0
	humanoid:TakeDamage(damage * (1 - reduction))
	SoundFx.playAt("hit", crabPosition)
	if humanoid.Health <= 0 then
		EventLog.count("deaths", 1, player)
		EventLog.log("PlayerDied", { player = player.Name, cause = cause })
	end
end

-- One snapshot entry for a live creature
local function entryFor(crab, now)
	local p = crab.worldPos
	local state = if crab.telegraphUntil then CreatureSnapshot.TELEGRAPH else (crab.targetBits or 0) -- S6.5
	if crab.moving then
		state += CreatureSnapshot.MOVING
	end
	if crab.lit then
		state += CreatureSnapshot.LIT
	end
	if crab.burning then
		state += CreatureSnapshot.BURNING
	end
	if crab.flashUntil > now then
		state += CreatureSnapshot.HIT
	end
	if crab.inWater then
		state += CreatureSnapshot.IN_WATER
	end
	return {
		id = crab.id,
		kind = crab.kindIndex,
		x = p.X,
		y = p.Y,
		z = p.Z,
		yaw = crab.yaw or 0,
		state = state,
		hp = math.clamp(crab.health / crab.maxHealth, 0, 1),
	}
end

-- Burned away: the sound plays from here; the client draws the burst when it sees the DYING flag
local function burst(crab)
	SoundFx.playAt("crabDeath", crab.worldPos)
	local entry = entryFor(crab, os.clock())
	entry.state = bit32.bor(entry.state, CreatureSnapshot.DYING)
	entry.hp = 0
	table.insert(dying, { entry = entry, untilT = os.clock() + 0.3 })
end

local function removeAt(index, reason)
	local crab = table.remove(creatures, index)
	if reason == "killed" then
		EventLog.kill(crab.lastSource, if typeof(crab.lastAttacker) == "Instance" then crab.lastAttacker else nil)
		burst(crab)
		if crab.stats.big then
			EventLog.log("BigMonsterKilled", { kind = crab.kind, by = crab.lastSource })
			local monster = string.gsub(tostring(crab.kind), "(%l)(%u)", "%1 %2") -- "BarnacleBrute" -> "Barnacle Brute"
			local attacker = if typeof(crab.lastAttacker) == "Instance" then crab.lastAttacker else nil
			-- S3.5: the moment's kind says which role made it (beam = the keeper)
			local source = tostring(crab.lastSource)
			local kind = if string.find(source, "Beam", 1, true) then "beam" elseif source == "Cannon" then "cannon" else "weapon"
			if attacker and crab.lastSource == "FocusedBeam" then
				EventLog.moment(2, attacker.DisplayName .. " burned down the " .. monster .. " with the focused beam", "beam")
			elseif attacker then
				EventLog.moment(2, attacker.DisplayName .. " landed the final blow on the " .. monster, kind)
			else
				EventLog.moment(2, "The crew brought down the " .. monster, "crew")
			end
		end
		-- S5.3: loot (and later results, the logbook and objectives) react to the kill on the bus
		local killer = if typeof(crab.lastAttacker) == "Instance" and crab.lastAttacker:IsA("Player") then crab.lastAttacker.UserId else nil
		EventLog.Publish("CreatureKilled", {
			VoyageId = EventLog.voyageId(),
			CreatureId = crab.id,
			DefId = crab.kind,
			Source = tostring(crab.lastSource or "unknown"),
			KillerId = killer,
			X = crab.worldPos.X,
			Y = crab.worldPos.Y,
			Z = crab.worldPos.Z,
			Big = crab.stats.big == true,
		})
		if crab.stats.big then
			EventLog.Publish("BossDefeated", { VoyageId = EventLog.voyageId(), DefId = crab.kind, FinalBlow = killer })
		end
	end
	if crab.bossEntry then
		-- tell the HUD how this monster left, then remove its entry a moment later
		crab.bossEntry:SetAttribute("Outcome", reason)
		crab.bossEntry:SetAttribute("Health", if reason == "killed" then 0 else crab.bossEntry:GetAttribute("Health"))
		task.delay(0.6, game.Destroy, crab.bossEntry)
	end
	if crab.stats.big and state then
		-- keep the legacy single boss bar pointing at another live big monster, if there is one
		local other
		for _, c in creatures do
			if c.stats.big then
				other = c
				break
			end
		end
		if other then
			state:SetAttribute("BossName", other.stats.displayName)
			state:SetAttribute("BossMax", other.maxHealth)
			state:SetAttribute("BossHealth", math.max(0, math.ceil(other.health)))
		else
			state:SetAttribute("BossName", "")
		end
	end
end

---------------------------------------------------------------------
-- S6.5: telegraphed moves (Spitter Eel, Puffer Mine, Ghost Lantern). Each one shows itself for at least 0.6 s
-- (the snapshot's TELEGRAPH state and a sound; a spit also marks where it will land) before it goes off.
---------------------------------------------------------------------

local function markSpot(spot, radius, seconds)
	local mark = Instance.new("Part")
	mark.Name = "SpitMark"
	mark.Shape = Enum.PartType.Cylinder
	mark.Size = Vector3.new(0.2, radius * 2, radius * 2)
	mark.CFrame = CFrame.new(spot.X, Ground.heightAt(spot.X, spot.Z) + 0.15, spot.Z) * CFrame.Angles(0, 0, math.rad(90))
	mark.Anchored = true
	mark.CanCollide = false
	mark.CanQuery = false
	mark.CanTouch = false
	mark.CastShadow = false
	mark.Material = Enum.Material.Neon
	mark.Color = Color3.fromRGB(150, 230, 90)
	mark.Transparency = 0.45
	mark.Parent = workspace
	task.delay(seconds, function()
		mark:Destroy()
	end)
end

local function startMove(crab, target, now)
	local stats = crab.stats
	crab.telegraphUntil = now + stats.telegraph
	crab.moveTarget = target
	if stats.behaviour == "spitter" then
		local towerCenter = Vector3.new(center.X, 0, center.Z)
		local spot = targetPosition(target) or towerCenter
		if target == "tower" then
			-- the near side of the tower, facing the eel
			local away = flat(crab.pos) - towerCenter
			spot = towerCenter + (if away.Magnitude > 0.01 then away.Unit else Vector3.new(0, 0, 1)) * Config.TOWER_ATTACK_RADIUS
		end
		crab.moveSpot = spot
		markSpot(spot, stats.splashRadius, stats.telegraph)
	end
	SoundFx.playAt(stats.telegraphSound, crab.worldPos)
end

-- S6.6: a summoned creature climbs out next to its summoner instead of at the shore line
local function spawnNear(kind, pos, i)
	if CreatureService.spawn(kind) then
		local summoned = creatures[#creatures]
		local angle = i * 2.1
		summoned.pos = flat(pos) + Vector3.new(math.cos(angle), 0, math.sin(angle)) * 3
		place(summoned)
	end
end

-- The move goes off. Returns true when the creature is used up (a Puffer Mine bursts).
local function releaseMove(crab, players)
	local stats = crab.stats
	local target = crab.moveTarget
	if stats.behaviour == "spitter" then
		local spot = crab.moveSpot
		for _, entry in players do
			if entry.pos and spot and (entry.pos - spot).Magnitude <= stats.splashRadius then
				bitePlayer(entry.player, crab.worldPos, stats.playerDamage, stats.displayName)
			end
		end
		if target == "tower" then
			tower.damage(stats.towerHit or 0)
		elseif type(target) == "table" and defense then
			defense.damageCannon(target, stats.cannonHit or 0)
		end
	elseif stats.behaviour == "mine" then
		for _, entry in players do
			if entry.pos and (entry.pos - crab.pos).Magnitude <= stats.blastRadius then
				bitePlayer(entry.player, crab.worldPos, stats.playerDamage, stats.displayName)
			end
		end
		if crab.radius <= Config.TOWER_ATTACK_RADIUS + stats.blastRadius then
			tower.damage(stats.towerHit or 0)
		end
		if type(target) == "table" and defense then
			defense.damageCannon(target, stats.cannonHit or 0)
		end
		EventLog.log("PufferBurst", { radius = math.floor(crab.radius) })
		burst(crab)
	elseif stats.behaviour == "ghost" then
		lamp.setFuel(math.max(0, lamp.getFuel() - (stats.fuelDrain or 0)))
	elseif stats.behaviour == "summoner" then
		-- S6.6: called out of the sea beside the witch, within the creature cap
		for i = 1, stats.summonCount do
			if CreatureService.load() >= Config.MAX_CREATURES then
				break
			end
			spawnNear(stats.summonKind, crab.pos, i)
		end
		EventLog.log("WitchSummoned", { count = stats.summonCount })
	elseif stats.behaviour == "healer" then
		-- S6.6: mends the small creatures around it (never a big monster)
		for _, other in creatures do
			if not other.stats.big and (other.pos - crab.pos).Magnitude <= stats.healRadius then
				other.health = math.min(other.maxHealth, other.health + other.maxHealth * stats.healShare)
			end
		end
	end
	SoundFx.playAt(stats.releaseSound, crab.worldPos)
	crab.moveSpot, crab.moveTarget = nil, nil
	return stats.behaviour == "mine"
end

-- Spawns a creature of the given type (see Shared/Creatures) climbing out of the sea
-- healthMult (D-047): scales a big monster's health (the Kraken grows with the crew); small creatures ignore it
function CreatureService.spawn(kind, bearing, healthMult)
	local stats = Creatures[kind]
	if not stats then
		return false
	end
	-- Bosses always arrive; small creatures wait while the slots (a boss counts as BOSS_SLOTS, S6.1) are full
	if not stats.big and CreatureService.load() >= Config.MAX_CREATURES then
		return false
	end
	bearing = bearing or math.random() * 360
	nextId = nextId % 65535 + 1
	local crab = {
		id = nextId,
		kind = kind,
		kindIndex = kindIndex[kind] or 0,
		stats = stats,
		bearing = bearing,
		pos = flat(center + directionFor(bearing) * Config.CREATURE_SPAWN_RADIUS),
		radius = Config.CREATURE_SPAWN_RADIUS,
		threat = { tower = Config.THREAT_BASE_TOWER },
		target = "tower",
		targetBits = 0,
		nextBite = 0,
		health = stats.health * (if stats.big then (healthMult or 1) else (state:GetAttribute("ForecastCrabHpMult") or 1)),
		maxHealth = stats.health * (if stats.big then (healthMult or 1) else (state:GetAttribute("ForecastCrabHpMult") or 1)),
		moving = true,
		lit = false,
		burning = false,
		flashUntil = 0,
	}
	place(crab)
	table.insert(creatures, crab)
	EventLog.Publish("CreatureSpawned", { VoyageId = EventLog.voyageId(), CreatureId = crab.id, DefId = kind, Big = stats.big == true })
	if stats.big and state then
		state:SetAttribute("BossName", stats.displayName)
		state:SetAttribute("BossMax", crab.maxHealth)
		state:SetAttribute("BossHealth", crab.maxHealth)
		-- HUD boss list: GameState.Bosses holds one entry per live big monster
		local bosses = state:FindFirstChild("Bosses")
		if not bosses then
			bosses = Instance.new("Folder")
			bosses.Name = "Bosses"
			bosses.Parent = state
		end
		local entry = Instance.new("Configuration")
		entry.Name = kind .. "_" .. string.format("%d", os.clock() * 1000)
		entry:SetAttribute("DisplayName", stats.displayName)
		entry:SetAttribute("Health", crab.maxHealth)
		entry:SetAttribute("Max", crab.maxHealth)
		entry.Parent = bosses
		crab.bossEntry = entry
	end
	return true
end

-- Rock Crabs (kept for existing callers)
function CreatureService.spawnCrab(bearing)
	return CreatureService.spawn("RockCrab", bearing)
end

-- Damages up to `maxTargets` creatures within `radius` of `position` (measured flat),
-- closest first. Returns a list of the positions that were hit (empty if none).
-- `source` names what dealt the damage (for the event log).
function CreatureService.damageArea(position, radius, amount, maxTargets, source, attacker)
	local candidates = {}
	for index, crab in creatures do
		if crab.stats.weaponImmune then
			continue -- S6.5: a Ghost Lantern only feels the lamp's beam
		end
		local offset = crab.worldPos - position
		local distance = Vector3.new(offset.X, 0, offset.Z).Magnitude
		if distance <= radius + crab.stats.bodyRadius then
			table.insert(candidates, { index = index, distance = distance })
		end
	end
	table.sort(candidates, function(a, b)
		return a.distance < b.distance
	end)

	local hits = {}
	local killed = {}
	for n = 1, math.min(maxTargets, #candidates) do
		local crab = creatures[candidates[n].index]
		table.insert(hits, crab.worldPos)
		crab.health -= amount
		crab.lastSource = source or "Unknown"
		crab.lastAttacker = attacker
		-- Aggro: whoever hurt it becomes more interesting to it
		if typeof(attacker) == "Instance" then
			addThreat(crab, attacker, amount * Config.THREAT_WEAPON_MULT)
		elseif type(attacker) == "table" then
			addThreat(crab, attacker, amount * Config.THREAT_CANNON_MULT)
		end
		crab.flashUntil = os.clock() + 0.12
		if crab.health <= 0 then
			table.insert(killed, candidates[n].index)
		end
	end

	-- Remove dead creatures from the highest index down so the list stays valid
	table.sort(killed, function(a, b)
		return a > b
	end)
	for _, index in killed do
		removeAt(index, "killed")
	end
	return hits
end

-- D-044: a rifle shot from the sniper tower: damages the first creature along the line (one creature).
-- Returns where it was hit, or nil for a miss.
function CreatureService.damageRay(origin, direction, range, pad, amount, source, attacker)
	local best, bestT = nil, math.huge
	for _, crab in creatures do
		if not crab.stats.weaponImmune then
			local centre = crab.worldPos + Vector3.new(0, crab.stats.bodyRadius, 0)
			local t = SniperService.rayHit(origin, direction, range, centre, crab.stats.bodyRadius + pad)
			if t and t < bestT then
				best, bestT = crab, t
			end
		end
	end
	if not best then
		return nil
	end
	local hits = CreatureService.damageArea(best.worldPos, 0, amount, 1, source, attacker)
	return hits[1]
end

-- Finds the creature within `range` of `position` that is closest to the tower
-- (the biggest threat). Returns its position, or nil.
function CreatureService.findTarget(position, range)
	local best, bestRadius = nil, math.huge
	for _, crab in creatures do
		local offset = crab.worldPos - position
		if Vector3.new(offset.X, 0, offset.Z).Magnitude <= range and crab.radius < bestRadius then
			best, bestRadius = crab, crab.radius
		end
	end
	return best and best.worldPos
end

function CreatureService.count()
	return #creatures
end

-- S6.1: slots in use toward MAX_CREATURES; a big monster counts as Config.BOSS_SLOTS (5)
function CreatureService.load()
	local bosses = 0
	for _, crab in creatures do
		if crab.stats.big then
			bosses += 1
		end
	end
	return #creatures + bosses * ((Config.BOSS_SLOTS or 1) - 1)
end

function CreatureService.clearAll()
	for index = #creatures, 1, -1 do
		removeAt(index, "cleared")
	end
end

-- The opening-incident reveal: something enormous rises out of the sea, then sinks.
function CreatureService.showSilhouette(bearing)
	local base = center + directionFor(bearing) * 170

	local model = Instance.new("Model")
	model.Name = "Silhouette"
	local head = makeModelPart(model, "Head", Vector3.new(60, 60, 60), Vector3.new(0, 0, 0), Color3.fromRGB(12, 14, 20))
	head.Shape = Enum.PartType.Ball
	local eyeColor = Color3.fromRGB(190, 255, 120)
	makeModelPart(model, "EyeL", Vector3.new(5, 2, 2), Vector3.new(-9, 12, -27), eyeColor, Enum.Material.Neon)
	makeModelPart(model, "EyeR", Vector3.new(5, 2, 2), Vector3.new(9, 12, -27), eyeColor, Enum.Material.Neon)
	model.PrimaryPart = head
	model.Parent = refs.creatureFolder

	-- Tween a number and move the model with it (models can't be tweened directly)
	local height = Instance.new("NumberValue")
	height.Value = -45
	local function apply()
		local position = Vector3.new(base.X, height.Value, base.Z)
		model:PivotTo(CFrame.lookAt(position, Vector3.new(center.X, height.Value, center.Z)))
	end
	height.Changed:Connect(apply)
	apply()

	task.spawn(function()
		local rise = TweenService:Create(height, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Value = -6 })
		rise:Play()
		rise.Completed:Wait()
		task.wait(3.5)
		local sink = TweenService:Create(height, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { Value = -45 })
		sink:Play()
		sink.Completed:Wait()
		model:Destroy()
		height:Destroy()
	end)
end

-- One simulation step (S4.2: fixed 1/20 s)
local function step(dt)
	if #creatures == 0 then
		return
	end

	local beam = lamp.getBeam()
	local halfAngle = if beam.mode == "focused" then Config.FOCUSED_HALF_ANGLE else Config.WIDE_HALF_ANGLE * (state:GetAttribute("ForecastWideMult") or 1)
	local now = os.clock()
	local keeper = lamp.getKeeper()
	local keeperBonus = keeper and keeper:GetAttribute("Spec_Keeper") or 0 -- S7.4: the Keeper specialty
	local lens = upgrades.value("LensPower", 1) * (1 + keeperBonus) -- beam damage multiplier
	local sweepDps = upgrades.value("ClockworkSweep", 0) -- automatic sweep damage
	local towerCenter = Vector3.new(center.X, 0, center.Z)
	local decay = 1 - Config.THREAT_DECAY * dt

	-- Players who can be targeted this frame (in the run and alive)
	local players = {}
	for _, player in Players:GetPlayers() do
		if targetValid(player) then
			table.insert(players, { player = player, pos = targetPosition(player) })
		end
	end

	for index = #creatures, 1, -1 do
		local crab = creatures[index]
		local stats = crab.stats
		local fromCenter = crab.pos - towerCenter
		crab.radius = fromCenter.Magnitude
		crab.bearing = math.deg(math.atan2(-fromCenter.X, -fromCenter.Z))
		local inBeam = beam.lit and math.abs(lamp.angleDelta(beam.angle, crab.bearing)) <= halfAngle

		-- Threat fades (the tower never drops below its base), and players standing close add threat
		for target, score in crab.threat do
			if target ~= "tower" then
				local faded = score * decay
				crab.threat[target] = if faded < 0.5 or not targetValid(target) then nil else faded
			end
		end
		crab.threat.tower = math.max(Config.THREAT_BASE_TOWER, crab.threat.tower * decay)
		local sight = if stats.behaviour == "spitter" then stats.attackRange else 10 + stats.bodyRadius
		for _, entry in players do
			if entry.pos and (entry.pos - crab.pos).Magnitude < sight and stats.behaviour == "spitter" then
				-- S6.5: an eel prefers a player in spitting range over the tower (enough to switch, and it outlasts the fade)
				crab.threat[entry.player] = math.max(crab.threat[entry.player] or 0, Config.THREAT_BASE_TOWER * Config.THREAT_SWITCH_RATIO * 1.2)
			elseif entry.pos and (entry.pos - crab.pos).Magnitude < sight then
				addThreat(crab, entry.player, Config.THREAT_PROXIMITY * dt)
			end
		end

		-- Beam effects (beam damage builds threat on the TOWER)
		local speedFactor = 1
		local pushed = false
		local burning = false
		local lit = false
		local beamDamage = 0
		if inBeam then
			if beam.manual and beam.mode == "focused" then
				speedFactor = 0
				burning = true
				beamDamage = Config.FOCUSED_DPS * lens * dt
				crab.lastSource = "FocusedBeam"
				crab.lastAttacker = lamp.getKeeper()
			elseif beam.manual then
				-- heavy monsters can't be shoved; the wide beam just slows them
				pushed = stats.pushable
				if not stats.pushable then
					speedFactor = 0.6
				end
				lit = true
				beamDamage = Config.WIDE_DPS * lens * dt
				crab.lastSource = "WideBeam"
				crab.lastAttacker = lamp.getKeeper()
			else
				speedFactor = Config.AUTO_SWEEP_SLOW
				lit = true
				beamDamage = sweepDps * dt
				if sweepDps > 0 then
					crab.lastSource = "Sweep"
					crab.lastAttacker = nil
				end
			end
		end
		if beamDamage > 0 then
			beamDamage *= stats.beamDamageMult
			crab.health -= beamDamage
			addThreat(crab, "tower", beamDamage * Config.THREAT_BEAM_MULT)
			if beam.manual then
				EventLog.beamHit(crab.lastAttacker) -- onboarding telemetry: first beam hit per Keeper
			end
		end

		crab.burning = burning
		crab.lit = lit

		if crab.health <= 0 then
			removeAt(index, "killed")
			continue
		end

		-- S6.5: a telegraphing monster stands still until its move goes off
		if crab.telegraphUntil then
			crab.moving = false
			if now >= crab.telegraphUntil then
				crab.telegraphUntil = nil
				if releaseMove(crab, players) then
					removeAt(index, "exploded")
					continue
				end
			end
			place(crab)
			continue
		end

		-- Choose a target and move toward it / attack it (S6.5/S6.6: some monsters only ever want the lighthouse)
		local target = if stats.ignoresPlayers then "tower" else chooseTarget(crab)
		crab.target = target
		setEyes(crab, target)
		local goal = targetPosition(target) or towerCenter
		crab.facing = goal
		crab.moving = false

		-- S6.5: a Puffer Mine lights its fuse when a player comes close or it reaches the tower
		if stats.behaviour == "mine" then
			local near = crab.radius <= Config.TOWER_ATTACK_RADIUS + 1
			for _, entry in players do
				if entry.pos and (entry.pos - crab.pos).Magnitude <= stats.triggerRadius then
					near = true
				end
			end
			if near then
				startMove(crab, target, now)
				place(crab)
				continue
			end
		end

		if pushed then
			-- wide beam shoves it straight away from the lighthouse
			local away = if crab.radius > 0.01 then fromCenter.Unit else Vector3.new(0, 0, 1)
			crab.pos += away * Config.WIDE_PUSH_SPEED * dt
			crab.moving = true
		elseif speedFactor > 0 then
			local toGoal = goal - crab.pos
			local distance = toGoal.Magnitude
			local reached
			if target == "tower" then
				reached = crab.radius <= Config.TOWER_ATTACK_RADIUS + (stats.towerRange or 0) -- S6.5: an eel spits from range
			else
				reached = distance <= stats.attackRange
			end
			if not reached then
				local stopAt = if target == "tower" then 0 else stats.attackRange * 0.8
				local step = math.min(stats.speed * speedFactor * dt, math.max(0, distance - stopAt))
				if distance > 0.01 then
					crab.pos += toGoal.Unit * step
				end
				crab.moving = step > 0
			elseif stats.behaviour then
				-- S6.5: its own move, telegraphed first
				if now >= crab.nextBite then
					crab.nextBite = now + stats.attackInterval
					startMove(crab, target, now)
				end
			else
				-- Attack
				if target == "tower" then
					tower.damage(stats.towerDps * dt)
				elseif typeof(target) == "Instance" then
					if now >= crab.nextBite then
						crab.nextBite = now + stats.attackInterval
						if stats.slamRadius > 0 then
							-- ground slam: everyone near the target gets hit
							local center3 = targetPosition(target) or crab.pos
							for _, entry in players do
								if entry.pos and (entry.pos - center3).Magnitude <= stats.slamRadius then
									bitePlayer(entry.player, crab.worldPos, stats.playerDamage, stats.displayName)
								end
							end
							SoundFx.playAt("cannonImpact", crab.worldPos)
						else
							bitePlayer(target, crab.worldPos, stats.playerDamage, stats.displayName)
						end
					end
				elseif defense then
					defense.damageCannon(target, stats.cannonDps * dt)
				end
			end
		end

		-- Never walk inside the tower
		local offset = crab.pos - towerCenter
		if offset.Magnitude < Config.TOWER_ATTACK_RADIUS then
			crab.pos = towerCenter + (if offset.Magnitude > 0.01 then offset.Unit else Vector3.new(0, 0, 1)) * Config.TOWER_ATTACK_RADIUS
		end
		-- D-047: the Kraken stays in the shallows (never closer to the tower than its minRadius)
		local minRadius = stats.minRadius
		if minRadius then
			local fromTower = crab.pos - towerCenter
			if fromTower.Magnitude < minRadius then
				crab.pos = towerCenter + (if fromTower.Magnitude > 0.01 then fromTower.Unit else Vector3.new(0, 0, 1)) * minRadius
			end
		end
		crab.radius = (crab.pos - towerCenter).Magnitude

		if crab.radius > Config.CREATURE_SPAWN_RADIUS + 1 then
			removeAt(index, "fled") -- pushed back into the sea
		else
			place(crab)
			-- keep the boss bar up to date
			if stats.big and state then
				local shown = math.max(0, math.ceil(crab.health))
				if state:GetAttribute("BossName") == stats.displayName and state:GetAttribute("BossHealth") ~= shown then
					state:SetAttribute("BossHealth", shown)
				end
				if crab.bossEntry and crab.bossEntry:GetAttribute("Health") ~= shown then
					crab.bossEntry:SetAttribute("Health", shown)
				end
			end
		end
	end
end

-- Sends every creature (and the ones just burned away) to every client, in packets of at most 50
local function sendSnapshot()
	local now = os.clock()
	local entries = table.create(#creatures + #dying)
	for _, crab in creatures do
		table.insert(entries, entryFor(crab, now))
	end
	for i = #dying, 1, -1 do
		if dying[i].untilT < now then
			table.remove(dying, i)
		else
			table.insert(entries, dying[i].entry)
		end
	end
	if #entries == 0 or not snapshotRemote then
		return
	end
	local serverTime = workspace:GetServerTimeNow()
	local per = CreatureSnapshot.MAX_PER_PACKET
	for first = 1, #entries, per do
		local packet = CreatureSnapshot.encode(entries, serverTime, first, math.min(first + per - 1, #entries))
		CreatureService.bytesSent += buffer.len(packet)
		snapshotRemote:FireAllClients(packet)
	end
end

local stepAccumulator, sendAccumulator = 0, 0
local function onHeartbeat(dt)
	stepAccumulator = math.min(stepAccumulator + dt, STEP * 3) -- never more than 3 steps behind
	while stepAccumulator >= STEP do
		stepAccumulator -= STEP
		step(STEP)
	end
	sendAccumulator += dt
	if sendAccumulator >= SEND_INTERVAL then
		sendAccumulator %= SEND_INTERVAL
		sendSnapshot()
	end
end

-- The creature models clients draw: built once from the art and published for every client
local function publishTemplates()
	local published = Instance.new("Folder")
	published.Name = "CreatureTemplates"
	for _, kind in kinds do
		local template = getTemplate(kind):Clone()
		template.Name = kind
		template.Parent = published
	end
	published.Parent = ReplicatedStorage
end

-- defenseService is used to damage cannons that creatures attack
-- remotesFolder: the Remotes folder (S5.1: the Platform domain builds it before it is exposed to clients)
function CreatureService.init(islandRefs, lampService, towerService, upgradeService, defenseService, stateFolder, remotesFolder)
	refs = islandRefs
	lamp = lampService
	tower = towerService
	upgrades = upgradeService
	defense = defenseService
	state = stateFolder
	if state then
		state:SetAttribute("BossName", "")
	end
	publishTemplates()
	local remotes = remotesFolder or ReplicatedStorage:WaitForChild("Remotes")
	snapshotRemote = remotes:FindFirstChild("CreatureSnapshot")
	if not snapshotRemote then
		snapshotRemote = Instance.new("UnreliableRemoteEvent")
		snapshotRemote.Name = "CreatureSnapshot"
		snapshotRemote.Parent = remotes
	end
	RunService.Heartbeat:Connect(onHeartbeat)
end

return CreatureService
