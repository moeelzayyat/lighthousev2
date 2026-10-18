--!strict
-- SniperService (owner's idea 2026-10-17, D-044, Encounter domain): the sniper tower on the voyage island.
-- One crew member at a time climbs it (the prompt at its foot). Up there they cannot walk, the creatures cannot
-- reach them, and they shoot a scoped rifle: the client only says where it aims (SniperAction "fire", a point);
-- the server traces the shot from the rifle against the creature table and applies the damage (one creature,
-- the first along the line). "leave", falling, the lamp, or the voyage ending brings them back down.
-- The rules (`rayHit`, `canClimb`, `canFire`) are pure and tested on their own; `start` adds the tower and wiring.

local SniperService = {}

SniperService.VOYAGE_PHASES = { Prologue = true, Day = true, Night = true } :: { [string]: boolean }

-- Pure: how far along a shot (origin + direction * t) passes within `radius` of `centre`, or nil when it misses
-- or the point is behind the rifle or beyond `range`. `direction` is a unit vector.
function SniperService.rayHit(origin: Vector3, direction: Vector3, range: number, centre: Vector3, radius: number): number?
	local t = (centre - origin):Dot(direction)
	if t <= 0 or t > range then
		return nil
	end
	if (origin + direction * t - centre).Magnitude > radius then
		return nil
	end
	return t
end

export type Climber = { ready: boolean, alive: boolean, keeper: boolean, carryingOil: boolean }

-- Pure: why a player may not climb now, or nil
function SniperService.canClimb(phase: string, occupied: boolean, who: Climber): string?
	if not SniperService.VOYAGE_PHASES[phase] or not who.ready then
		return "The sniper tower is for the voyage crew."
	elseif not who.alive then
		return "You can't climb right now."
	elseif who.keeper then
		return "Hand over the lamp first."
	elseif who.carryingOil then
		return "Your hands are full of oil. Take it to the fuel tank first."
	elseif occupied then
		return "Someone is already up the tower."
	end
	return nil
end

-- Pure: may this shot be fired (the rifle's cooldown, the shooter is the one up the tower)
function SniperService.canFire(isOccupant: boolean, lastShot: number?, now: number, cooldown: number): boolean
	return isOccupant and (lastShot == nil or now - lastShot >= cooldown)
end

---------------------------------------------------------------------
-- The tower and the wiring
---------------------------------------------------------------------

export type Stats = { damage: number, cooldown: number, range: number }

export type Deps = {
	island: Instance, -- the voyage island folder (the tower is built into it)
	remote: RemoteEvent, -- SniperAction
	at: Vector3, -- the tower's flat position
	deckY: number?, -- ISL.1: when the tower stands in the sea, the height of the wooden deck under it (a bridge runs to the shore)
	height: number, -- studs from the ground to the platform
	aimPad: number, -- studs added to a creature's body radius when tracing a shot
	groundY: (x: number, z: number) -> number,
	center: Vector3, -- the lighthouse (the ladder faces it)
	stats: () -> Stats,
	phase: () -> string,
	isKeeper: (player: Player) -> boolean,
	carryingOil: (player: Player) -> boolean,
	allow: (player: Player) -> boolean, -- the remote's token bucket
	connect: (remote: RemoteEvent, handler: (Player, ...any) -> ()) -> (),
	isFiniteVector3: (v: any) -> boolean,
	damageRay: (origin: Vector3, direction: Vector3, range: number, pad: number, amount: number, source: string, attacker: Player) -> Vector3?,
	walkSpeed: (player: Player) -> number,
	notify: (player: Player, text: string) -> (),
	playAt: (sound: string, position: Vector3) -> (),
	log: (name: string, fields: { [string]: any }) -> (),
	count: (name: string) -> (),
	first: (what: string) -> (),
	mark: (player: Player, step: string, kind: string?) -> (),
}

local WOOD = Color3.fromRGB(112, 84, 58)
local DARK_WOOD = Color3.fromRGB(78, 58, 42)
local METAL = Color3.fromRGB(52, 56, 62)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- ISL.1: the deck the tower stands on out in the sea (on pilings), and a small bridge from its lighthouse edge to
-- the first dry ground toward the lighthouse
local PILING = 24 -- studs the pilings reach down into the sea

local function buildDeck(model: Model, deps: Deps, frame: CFrame, half: number, ladderZ: number)
	local front, back = ladderZ - 5.5, half + 2.4 -- -Z is the lighthouse side; the front holds the ladder's foot
	local width = half * 2 + 5
	local middle = (front + back) / 2
	part(model, "Deck", Vector3.new(width, 1, back - front), frame * CFrame.new(0, -0.5, middle), WOOD, Enum.Material.WoodPlanks)
	for _, sx in { -1, 1 } do
		for _, z in { front + 0.6, middle, back - 0.6 } do
			part(model, "Piling", Vector3.new(1, PILING, 1), frame * CFrame.new(sx * (width / 2 - 0.6), -PILING / 2, z), DARK_WOOD, Enum.Material.Wood)
		end
		part(model, "DeckRail", Vector3.new(0.3, 0.3, back - front), frame * CFrame.new(sx * (width / 2 - 0.2), 2.6, middle), DARK_WOOD, Enum.Material.Wood)
		for _, z in { front + 0.2, back - 0.2 } do
			part(model, "DeckPost", Vector3.new(0.4, 2.8, 0.4), frame * CFrame.new(sx * (width / 2 - 0.2), 1.4, z), DARK_WOOD, Enum.Material.Wood)
		end
	end
	part(model, "DeckRail", Vector3.new(width, 0.3, 0.3), frame * CFrame.new(0, 2.6, back - 0.2), DARK_WOOD, Enum.Material.Wood)

	-- the bridge: from the deck's front edge toward the lighthouse until the ground is dry
	local edge = (frame * CFrame.new(0, 0, front)).Position
	local toCenter = frame.LookVector
	local landing: Vector3? = nil
	for step = 1, 40 do
		local p = edge + toCenter * step
		local y = deps.groundY(p.X, p.Z)
		if y >= edge.Y - 1 then
			landing = Vector3.new(p.X, y, p.Z) + toCenter * 1.5 -- a little onto the sand
			break
		end
	end
	if not landing then
		warn("[SniperService] no shore within 40 studs of the tower's deck; no bridge built")
		return
	end
	local length = (landing - edge).Magnitude
	local along = CFrame.lookAt(edge:Lerp(landing, 0.5), landing)
	part(model, "Bridge", Vector3.new(4, 0.6, length + 0.6), along * CFrame.new(0, -0.3, 0), WOOD, Enum.Material.WoodPlanks)
	local spans = math.max(1, math.ceil(length / 5))
	for _, sx in { -1, 1 } do
		part(model, "BridgeRail", Vector3.new(0.3, 0.3, length), along * CFrame.new(sx * 1.9, 2.6, 0), DARK_WOOD, Enum.Material.Wood)
		for i = 0, spans do
			part(model, "BridgePost", Vector3.new(0.4, 2.8, 0.4), along * CFrame.new(sx * 1.9, 1.3, length / 2 - length * i / spans), DARK_WOOD, Enum.Material.Wood)
		end
	end
	for i = 1, spans - 1 do
		local p = edge:Lerp(landing, i / spans)
		part(model, "Piling", Vector3.new(0.9, PILING, 0.9), CFrame.new(p.X, p.Y - 0.6 - PILING / 2, p.Z), DARK_WOOD, Enum.Material.Wood)
	end
end

-- Builds the tower; returns the model, the prompt at its foot, where a climber stands, where they come down and
-- the rifle's muzzle
local function build(deps: Deps): (Model, ProximityPrompt, CFrame, CFrame, Vector3)
	local x, z = deps.at.X, deps.at.Z
	local ground = deps.groundY(x, z)
	local deckY = deps.deckY
	local inSea = deckY ~= nil and ground < deckY
	local g = if deckY and inSea then deckY else ground
	local h = deps.height
	local base = Vector3.new(x, g, z)
	local toCenter = Vector3.new(deps.center.X - x, 0, deps.center.Z - z).Unit
	local frame = CFrame.lookAt(base, base + toCenter) -- -Z faces the lighthouse (the ladder side)
	local model = Instance.new("Model")
	model.Name = "SniperTower"

	-- four legs leaning in a little, braces, the platform with rails, a roof
	local half = 3.6
	for _, corner in { Vector3.new(-1, 0, -1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, 1) } do
		local foot = frame * CFrame.new(corner.X * (half + 0.6), 0, corner.Z * (half + 0.6))
		local top = frame * CFrame.new(corner.X * half, h, corner.Z * half)
		local mid = foot.Position:Lerp(top.Position, 0.5)
		local length = (top.Position - foot.Position).Magnitude
		part(model, "Leg", Vector3.new(1.2, length, 1.2), CFrame.lookAt(mid, top.Position) * CFrame.Angles(math.rad(90), 0, 0), DARK_WOOD, Enum.Material.Wood)
	end
	for _, y in { h * 0.35, h * 0.7 } do
		for _, side in { { 0, -1, 0 }, { 0, 1, 0 }, { -1, 0, 90 }, { 1, 0, 90 } } do
			local inset = half + 0.6 * (1 - y / h)
			part(model, "Brace", Vector3.new(inset * 2 + 0.4, 0.5, 0.5), frame * CFrame.new(side[1] * inset, y, side[2] * inset) * CFrame.Angles(0, math.rad(side[3]), 0), WOOD, Enum.Material.Wood)
		end
	end
	local platform = part(model, "Platform", Vector3.new(half * 2 + 2, 1, half * 2 + 2), frame * CFrame.new(0, h, 0), WOOD, Enum.Material.WoodPlanks)
	for _, side in { { 0, 1, 0 }, { -1, 0, 90 }, { 1, 0, 90 } } do -- no rail on the ladder side
		part(model, "Rail", Vector3.new(half * 2 + 2, 0.4, 0.4), frame * CFrame.new(side[1] * (half + 0.8), h + 3, side[2] * (half + 0.8)) * CFrame.Angles(0, math.rad(side[3]), 0), DARK_WOOD, Enum.Material.Wood)
		part(model, "RailLow", Vector3.new(half * 2 + 2, 0.3, 0.3), frame * CFrame.new(side[1] * (half + 0.8), h + 1.6, side[2] * (half + 0.8)) * CFrame.Angles(0, math.rad(side[3]), 0), DARK_WOOD, Enum.Material.Wood)
	end
	for _, corner in { Vector3.new(-1, 0, -1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, 1) } do
		part(model, "Post", Vector3.new(0.6, 8, 0.6), frame * CFrame.new(corner.X * (half + 0.7), h + 4.5, corner.Z * (half + 0.7)), DARK_WOOD, Enum.Material.Wood)
	end
	part(model, "Roof", Vector3.new(half * 2 + 4, 0.6, half * 2 + 4), frame * CFrame.new(0, h + 8.8, 0), Color3.fromRGB(150, 40, 36), Enum.Material.WoodPlanks)

	-- the ladder on the lighthouse side
	local ladderZ = -(half + 1.3)
	for _, sx in { -1, 1 } do
		part(model, "LadderRail", Vector3.new(0.35, h + 3, 0.35), frame * CFrame.new(sx * 1.1, (h + 3) / 2, ladderZ), DARK_WOOD, Enum.Material.Wood)
	end
	for y = 1.5, h + 1, 1.5 do
		part(model, "Rung", Vector3.new(2.2, 0.25, 0.25), frame * CFrame.new(0, y, ladderZ), WOOD, Enum.Material.Wood)
	end

	-- the rifle on its swivel at the sea-side rail, and a lantern for the night
	local muzzleCf = frame * CFrame.new(0, h + 3.4, half + 1.4)
	part(model, "RifleMount", Vector3.new(0.6, 2.4, 0.6), frame * CFrame.new(0, h + 2, half + 0.8), METAL, Enum.Material.Metal)
	local barrel = part(model, "Rifle", Vector3.new(0.35, 0.35, 4.2), muzzleCf * CFrame.new(0, 0, -1.6), METAL, Enum.Material.Metal)
	part(model, "Scope", Vector3.new(0.45, 0.45, 1.4), muzzleCf * CFrame.new(0, 0.4, -2.2), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
	barrel.CanCollide = false
	local lantern = part(model, "Lantern", Vector3.new(0.8, 1.1, 0.8), frame * CFrame.new(half + 0.7, h + 7.6, -(half + 0.7)), Color3.fromRGB(255, 200, 120), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 190, 110)
	light.Range = 18
	light.Brightness = 1.4
	light.Parent = lantern
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanQuery = d == platform -- shots and aims pass through the frame
		end
	end

	if inSea then
		buildDeck(model, deps, frame, half, ladderZ)
	end

	-- the climb prompt at the foot of the ladder
	local foot = part(model, "ClimbSpot", Vector3.new(3, 0.4, 3), frame * CFrame.new(0, 0.2, ladderZ - 1.6), WOOD, Enum.Material.WoodPlanks)
	foot.CanCollide = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ClimbPrompt"
	prompt.ActionText = "Climb"
	prompt.ObjectText = "Sniper tower"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = foot

	model.Parent = deps.island
	local stand = frame * CFrame.new(0, h + 3.5, half - 0.6) * CFrame.Angles(0, math.rad(180), 0) -- facing the sea
	local down = frame * CFrame.new(0, 3, ladderZ - 3.5)
	return model, prompt, stand, down, muzzleCf.Position
end

function SniperService.start(deps: Deps)
	local model, prompt, stand, down, muzzle = build(deps)
	local occupant: Player? = nil
	local lastShot: { [Player]: number } = {}
	local saved: { [Player]: { number } } = {} -- jump power and height before climbing

	local function humanoidOf(player: Player): Humanoid?
		local character = player.Character
		return character and character:FindFirstChildOfClass("Humanoid")
	end

	local function leave(player: Player, reason: string, moveDown: boolean)
		if occupant ~= player then
			return
		end
		occupant = nil
		prompt.Enabled = true
		player:SetAttribute("OnSniperTower", nil)
		local humanoid = humanoidOf(player)
		local character = player.Character
		if humanoid then
			humanoid.WalkSpeed = deps.walkSpeed(player)
			local jump = saved[player]
			humanoid.JumpPower = if jump then jump[1] else 50
			humanoid.JumpHeight = if jump then jump[2] else 7.2
		end
		saved[player] = nil
		if moveDown and character and humanoid and humanoid.Health > 0 then
			character:PivotTo(down)
		end
		deps.log("SniperLeft", { player = player.Name, reason = reason })
	end

	prompt.Triggered:Connect(function(player: Player)
		local humanoid = humanoidOf(player)
		local why = SniperService.canClimb(deps.phase(), occupant ~= nil, {
			ready = player:GetAttribute("Ready") == true,
			alive = humanoid ~= nil and humanoid.Health > 0,
			keeper = deps.isKeeper(player),
			carryingOil = deps.carryingOil(player),
		})
		if why or not humanoid or not player.Character then
			deps.notify(player, why or "You can't climb right now.")
			return
		end
		occupant = player
		prompt.Enabled = false
		humanoid:UnequipTools() -- hands on the rifle, not a weapon
		saved[player] = { humanoid.JumpPower, humanoid.JumpHeight }
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
		player.Character:PivotTo(stand)
		player:SetAttribute("OnSniperTower", true)
		deps.first("climbed the sniper tower")
		deps.log("SniperClimbed", { player = player.Name })
	end)

	deps.connect(deps.remote, function(player: Player, action: any, point: any)
		if not deps.allow(player) then
			return
		end
		if action == "leave" then
			leave(player, "leave", true)
			return
		elseif action ~= "fire" or not deps.isFiniteVector3(point) then
			return
		end
		local humanoid = humanoidOf(player)
		local now = os.clock()
		local stats = deps.stats()
		if not humanoid or humanoid.Health <= 0 or deps.isKeeper(player) then
			return
		end
		if not SniperService.canFire(occupant == player, lastShot[player], now, stats.cooldown) then
			return
		end
		local offset = (point :: Vector3) - muzzle
		if offset.Magnitude < 1 then
			return
		end
		lastShot[player] = now
		local direction = offset.Unit
		local hit = deps.damageRay(muzzle, direction, stats.range, deps.aimPad, stats.damage, "Sniper", player)
		deps.count("sniperShots")
		if hit then
			deps.count("sniperHits")
		end
		deps.first("sniper shot")
		deps.mark(player, "firstAction", "sniper")
		deps.playAt("sniper", muzzle)

		-- a tracer everyone sees for a moment
		local to = hit or (muzzle + direction * math.min(stats.range, offset.Magnitude))
		local length = (to - muzzle).Magnitude
		local tracer = Instance.new("Part")
		tracer.Name = "SniperTracer"
		tracer.Anchored = true
		tracer.CanCollide = false
		tracer.CanQuery = false
		tracer.CanTouch = false
		tracer.CastShadow = false
		tracer.Material = Enum.Material.Neon
		tracer.Color = Color3.fromRGB(255, 236, 170)
		tracer.Transparency = 0.25
		tracer.Size = Vector3.new(0.12, 0.12, length)
		tracer.CFrame = CFrame.lookAt(muzzle:Lerp(to, 0.5), to)
		tracer.Parent = model
		task.delay(0.09, function()
			tracer:Destroy()
		end)
	end)

	-- Down when they fall, the lamp takes them, they leave the crew, or the voyage ends
	task.spawn(function()
		while true do
			task.wait(0.5)
			local player = occupant
			if player then
				local humanoid = humanoidOf(player)
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if player.Parent == nil or not humanoid or humanoid.Health <= 0 or not root then
					leave(player, "gone", false)
				elseif not SniperService.VOYAGE_PHASES[deps.phase()] or player:GetAttribute("Ready") ~= true then
					leave(player, "voyage", false)
				elseif deps.isKeeper(player) then
					leave(player, "lamp", false)
				elseif (root.Position - stand.Position).Magnitude > 8 then
					leave(player, "moved", false)
				end
			end
		end
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
		if occupant == player then
			occupant = nil
			prompt.Enabled = true
		end
		lastShot[player] = nil
		saved[player] = nil
	end)
end

return SniperService
