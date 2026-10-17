-- CreatureView (S4.3, client): draws the creatures from the server's snapshots (S4.2).
-- The server sends a binary snapshot 12 times a second (Shared/CreatureSnapshot); this script keeps a short
-- history per creature and draws it ~0.17 s in the past, interpolating between snapshots, so movement is smooth
-- at any frame rate. Models are cloned from ReplicatedStorage.CreatureTemplates (built by the server from the
-- art) into workspace.Island.Creatures (client-only children, named by kind, so the coach still finds them),
-- and pooled when a creature is gone. The walk bob, eye colour, health bar, beam tint, hit flash and the burst
-- when one is burned away are all drawn here; nothing about a creature is replicated as an instance.
-- S4.4 render budget: small creatures have no light (their eyes flash white when hit and orange when burning);
-- big monsters show their health on the shared boss bar, not over their heads; kill bursts reuse a few parts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Creatures = require(Shared:WaitForChild("Creatures"))
local Snap = require(Shared:WaitForChild("CreatureSnapshot"))
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CreatureSnapshot")
local templates = ReplicatedStorage:WaitForChild("CreatureTemplates")
local folder = Workspace:WaitForChild("Island"):WaitForChild("Creatures")

local INTERP_DELAY = 2 / 12 -- draw two snapshots behind, so there is almost always a pair to blend
local GONE_AFTER = 0.4 -- seconds without a snapshot before a creature is removed
local HISTORY = 6

local BURN_COLOR = Color3.fromRGB(255, 170, 60)
local HIT_COLOR = Color3.fromRGB(255, 255, 255)
local LIT_TINT = Color3.fromRGB(235, 150, 95)
local EYE_TOWER = Color3.fromRGB(255, 240, 120)
local EYE_CANNON = Color3.fromRGB(255, 150, 60)
local EYE_PLAYER = Color3.fromRGB(255, 60, 50)
local TELL_COLOR = Color3.fromRGB(255, 250, 220) -- S6.5: a monster about to use its move pulses this colour

local kinds = Snap.kinds(Creatures)
local views = {} -- id -> view
local pool = {} -- kind -> { model }
local BURST_POOL = 6
local bursts = {} -- reused kill-burst balls
local nextBurst = 0
-- V7: a creature dies in a burst of sea foam (ART_BIBLE), and a hit throws a few white sparks; one shared
-- emitter part each, moved to the spot and emitted once, so this costs no instances per creature
local FOAM_COLOR = Color3.fromRGB(226, 246, 242)
local SOFT_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local fxPart = Instance.new("Part")
fxPart.Name = "CreatureFx"
fxPart.Anchored = true
fxPart.CanCollide = false
fxPart.CanQuery = false
fxPart.CanTouch = false
fxPart.Transparency = 1
fxPart.Size = Vector3.new(2, 2, 2)
fxPart.Parent = Workspace -- not the creature folder: the coach counts what is in there
local function fxEmitter(name, props)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = name
	emitter.Rate = 0
	for key, value in props do
		emitter[key] = value
	end
	emitter.Parent = fxPart
	return emitter
end
local foam = fxEmitter("Foam", {
	Texture = SOFT_TEXTURE,
	Color = ColorSequence.new(FOAM_COLOR),
	LightEmission = 0.4,
	Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 6) }),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }),
	Lifetime = NumberRange.new(0.8, 1.2),
	Speed = NumberRange.new(8, 14),
	SpreadAngle = Vector2.new(180, 180),
	Drag = 4,
	Acceleration = Vector3.new(0, -10, 0),
	Rotation = NumberRange.new(0, 360),
})
local drops = fxEmitter("Drops", {
	Color = ColorSequence.new(FOAM_COLOR),
	LightEmission = 0.6,
	Size = NumberSequence.new(0.3),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
	Lifetime = NumberRange.new(0.5, 0.7),
	Speed = NumberRange.new(14, 22),
	SpreadAngle = Vector2.new(60, 60),
	Acceleration = Vector3.new(0, -60, 0),
})
local sparks = fxEmitter("Sparks", {
	Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
	LightEmission = 1,
	LightInfluence = 0,
	Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) }),
	Lifetime = NumberRange.new(0.15, 0.25),
	Speed = NumberRange.new(12, 20),
	SpreadAngle = Vector2.new(180, 180),
})
local function emitAt(position, emitter, count)
	fxPart.CFrame = CFrame.new(position)
	emitter:Emit(count)
end

local function has(state, bit)
	return state // bit % 2 == 1
end

local function newView(id, kindIndex)
	local kind = kinds[kindIndex + 1]
	local template = kind and templates:FindFirstChild(kind)
	if not template then
		return nil
	end
	local list = pool[kind]
	local model = list and table.remove(list)
	if not model then
		model = template:Clone()
	end
	local body = model.PrimaryPart
	local eyes = {}
	local glow = body:FindFirstChild("GlowEyes")
	if glow then
		for _, eye in glow:GetChildren() do
			if eye:IsA("Frame") then
				table.insert(eyes, eye)
			end
		end
	end
	local stats = Creatures[kind]
	local bar = body:FindFirstChild("HealthBar")
	if bar and stats and stats.big then
		bar.Enabled = false
		bar = nil -- the HUD's boss bar shows a big monster's health
	end
	local view = {
		id = id,
		kind = kind,
		model = model,
		body = body,
		eyes = eyes,
		bar = bar,
		fill = bar and bar:FindFirstChild("Fill", true),
		feedback = body:FindFirstChild("Feedback"),
		history = {},
		lastSeen = os.clock(),
		state = 0,
		hp = 1,
		phase = math.random() * 10,
		color = nil,
		eyeColor = nil,
		shownHp = -1,
		baseColor = template.PrimaryPart.Color, -- S6.5: each kind keeps its own colour (was always the crab's)
		inflates = stats ~= nil and stats.behaviour == "mine",
		scale = 1,
		tellSince = nil,
	}
	if bar then
		bar.Enabled = false
	end
	model.Parent = folder
	return view
end

local function burst(position)
	nextBurst = nextBurst % BURST_POOL + 1
	local puff = bursts[nextBurst]
	if not puff then
		puff = Instance.new("Part")
		puff.Name = "Burst"
		puff.Shape = Enum.PartType.Ball
		puff.Anchored = true
		puff.CanCollide = false
		puff.CanQuery = false
		puff.CanTouch = false
		puff.Material = Enum.Material.Neon
		puff.Color = FOAM_COLOR -- V7: sea foam (was the burn orange)
		puff.Parent = Workspace -- not the creature folder: the coach counts what is in there
		bursts[nextBurst] = puff
	end
	puff.Size = Vector3.new(2, 2, 2)
	puff.Transparency = 0.2
	puff.CFrame = CFrame.new(position)
	TweenService:Create(puff, TweenInfo.new(0.3), { Size = Vector3.new(6, 6, 6), Transparency = 1 }):Play()
	emitAt(position, foam, 14)
	emitAt(position, drops, 10)
end

local function release(view)
	views[view.id] = nil
	if has(view.state, Snap.DYING) then
		burst(view.body.Position)
	end
	view.model.Parent = nil
	if view.scale ~= 1 then
		view.model:ScaleTo(1) -- S6.5: a swollen Puffer Mine goes back to the pool at its normal size
	end
	if view.feedback then
		view.feedback.Enabled = false
	end
	pool[view.kind] = pool[view.kind] or {}
	table.insert(pool[view.kind], view.model)
end

remote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "buffer" then
		return
	end
	local t, list = Snap.decode(payload)
	if not t then
		return
	end
	local now = os.clock()
	for _, e in list do
		local view = views[e.id]
		if view and kinds[e.kind + 1] ~= view.kind then
			release(view) -- the id was reused for another creature
			view = nil
		end
		if not view then
			view = newView(e.id, e.kind)
			if not view then
				continue
			end
			views[e.id] = view
		end
		local history = view.history
		local last = history[#history]
		if not last or t > last.t then
			table.insert(history, { t = t, x = e.x, y = e.y, z = e.z, yaw = e.yaw })
			if #history > HISTORY then
				table.remove(history, 1)
			end
		end
		view.state = e.state
		view.hp = e.hp
		view.lastSeen = now
	end
end)

-- B1.4: gone creatures are also removed on Heartbeat, so a client that is not rendering (a minimised window, a
-- phone app in the background) does not pile up models; drawing stays on RenderStepped
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for _, view in views do
		if now - view.lastSeen > GONE_AFTER then
			release(view)
		end
	end
end)

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local renderT = Workspace:GetServerTimeNow() - INTERP_DELAY
	for _, view in views do
		if now - view.lastSeen > GONE_AFTER then
			release(view)
			continue
		end
		local state = view.state
		local x, y, z, yaw = Snap.sample(view.history, renderT)
		if has(state, Snap.MOVING) then
			y += math.abs(math.sin(now * 12 + view.phase)) * 0.25 -- walk bob
		end
		view.model:PivotTo(CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0))

		-- S6.5: the telegraph: the body pulses, the eyes go pale, a Puffer Mine swells over its fuse
		local tell = Snap.isTelegraph(state)
		if tell and not view.tellSince then
			view.tellSince = now
		elseif not tell then
			view.tellSince = nil
		end
		-- V7: a few white sparks the moment a hit lands
		local hit = has(state, Snap.HIT)
		if hit and not view.wasHit then
			emitAt(view.body.Position, sparks, 5)
		end
		view.wasHit = hit
		local color = if has(state, Snap.HIT) then HIT_COLOR
			elseif tell then (if math.sin(now * 25) > 0 then TELL_COLOR else view.baseColor)
			elseif has(state, Snap.BURNING) then BURN_COLOR
			elseif has(state, Snap.LIT) then LIT_TINT
			else view.baseColor
		if color ~= view.color then
			view.color = color
			view.body.Color = color
			if view.feedback then
				view.feedback.Enabled = color ~= view.baseColor
				view.feedback.Color = color
			end
		end
		local swell = if tell and view.inflates then 1 + math.min(1, now - view.tellSince) * 0.6 else 1
		if math.abs(swell - view.scale) > 0.02 then
			view.scale = swell
			view.model:ScaleTo(swell)
		end
		local eyeColor = if has(state, Snap.HIT) then HIT_COLOR
			elseif tell then TELL_COLOR
			elseif has(state, Snap.BURNING) then BURN_COLOR
			elseif has(state, Snap.TARGET_PLAYER) then EYE_PLAYER
			elseif has(state, Snap.TARGET_CANNON) then EYE_CANNON
			else EYE_TOWER
		if eyeColor ~= view.eyeColor then
			view.eyeColor = eyeColor
			for _, eye in view.eyes do
				eye.BackgroundColor3 = eyeColor
			end
		end
		if view.bar and math.abs(view.hp - view.shownHp) >= 0.02 then
			view.shownHp = view.hp
			view.bar.Enabled = view.hp < 1
			if view.fill then
				view.fill.Size = UDim2.fromScale(view.hp, 1)
			end
		end
	end
end)
