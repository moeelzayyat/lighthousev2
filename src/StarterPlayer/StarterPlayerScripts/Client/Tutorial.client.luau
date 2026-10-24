--!strict
-- Tutorial (TUT.1, D-059, owner 2026-10-20: "a solid easy tutorial mode for new comers"): a short guided walk for a
-- keeper whose save has not finished it (profile `tutorialDone`). One step at a time: a small card at the top with one
-- line and the key to press, a bouncing arrow over the thing to use (or a glow round a button), and an edge arrow when
-- that thing is off screen. Each step ends when the player does it; nothing is timed (no countdown pressure).
--   Harbor: welcome, the Quartermaster, the BAG, boarding a ship, the wheel.
--   Voyage: oil from the pile, into the fuel tank, striking a creature, picking up Shells, done.
-- "Skip" ends it for good; the BAG's Tutorial tile replays it (ReplayTutorial). The coach hints wait while it runs
-- (player attribute TutorialActive). Looks only: the server only stores that the tutorial is finished (TutorialDone).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local PlaceRole = require(Shared:WaitForChild("PlaceRole")) :: any
local UiKit = require(script.Parent:WaitForChild("UiKit")) :: any
local InputController = require(script.Parent:WaitForChild("InputController")) :: any
local C = UiKit.Color

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local state = ReplicatedStorage:WaitForChild("GameState")

local function replayEventOf(): BindableEvent
	local found = script.Parent:FindFirstChild("ReplayTutorial")
	if found and found:IsA("BindableEvent") then
		return found
	end
	local e = Instance.new("BindableEvent")
	e.Name = "ReplayTutorial"
	e.Parent = script.Parent
	return e
end
local replayEvent = replayEventOf()

---------------------------------------------------------------------
-- WHAT THE PLAYER HAS DONE (watched all the time, so a step already done passes at once)
---------------------------------------------------------------------

local did = { shop = false, attacked = false, shells = false, poured = false }
remotes:WaitForChild("ShopOpen").OnClientEvent:Connect(function(open)
	if open then
		did.shop = true
	end
end)
remotes:WaitForChild("LootCollected").OnClientEvent:Connect(function(kind)
	if kind == "Shells" then
		did.shells = true
	end
end)
local carrying = player:GetAttribute("CarryingOil") == true
player:GetAttributeChangedSignal("CarryingOil"):Connect(function()
	local now = player:GetAttribute("CarryingOil") == true
	if carrying and not now then
		did.poured = true
	end
	carrying = now
end)
local function watchTool(tool: Instance)
	if tool:IsA("Tool") then
		tool.Activated:Connect(function()
			did.attacked = true
		end)
	end
end
local function watchCharacter(character: Model)
	for _, child in character:GetChildren() do
		watchTool(child)
	end
	character.ChildAdded:Connect(watchTool)
end
if player.Character then
	watchCharacter(player.Character)
end
player.CharacterAdded:Connect(watchCharacter)

local function inRun(): boolean
	local phase = state:GetAttribute("Phase")
	return player:GetAttribute("Ready") == true and (phase == "Prologue" or phase == "Day" or phase == "Night")
end
local function isKeeper(): boolean
	return state:GetAttribute("KeeperUserId") == player.UserId
end

---------------------------------------------------------------------
-- TARGETS
---------------------------------------------------------------------

local function partOf(inst: Instance?): BasePart?
	if not inst then
		return nil
	end
	if inst:IsA("BasePart") then
		return inst
	end
	if inst:IsA("Model") then
		return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end
local function root(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end
-- the nearest descendant of `folder` whose name starts with `prefix`
local function nearest(folder: Instance?, prefix: string): BasePart?
	local me = root()
	if not folder or not me then
		return nil
	end
	local best, bestDistance = nil, math.huge
	for _, d in folder:GetDescendants() do
		if string.sub(d.Name, 1, #prefix) == prefix then
			local p = partOf(d)
			if p then
				local distance = (p.Position - me.Position).Magnitude
				if distance < bestDistance then
					best, bestDistance = p, distance
				end
			end
		end
	end
	return best
end
local function island(): Instance?
	return Workspace:FindFirstChild("Island")
end

---------------------------------------------------------------------
-- STEPS
---------------------------------------------------------------------

local X = Enum.KeyCode.ButtonX
type Step = {
	id: string,
	text: string,
	keys: { [string]: any }?,
	button: string?, -- a step the player ends with a button (no task)
	target: (() -> BasePart?)?,
	outline: (() -> Instance?)?, -- what gets the glow outline (default: the target)
	gui: (() -> GuiObject?)?,
	done: (() -> boolean)?,
}
local HARBOR: { Step } = {
	{ id = "welcome", text = "Welcome, Keeper! A quick tour so you know your way around. Follow the arrows.", button = "Let's go" },
	{
		id = "quartermaster",
		text = "Visit the Quartermaster. He sells weapons, armor, pets and more.",
		keys = { keyboard = "E", touch = "Tap", gamepad = X },
		target = function()
			local lobby = Workspace:FindFirstChild("Lobby")
			return partOf(lobby and lobby:FindFirstChild("ShopCounter", true))
		end,
		outline = function()
			local lobby = Workspace:FindFirstChild("Lobby")
			return lobby and lobby:FindFirstChild("ShopStall", true)
		end,
		done = function()
			return did.shop
		end,
	},
	{
		id = "bag",
		text = "Open your BAG to see your gear and put on what you buy.",
		keys = { keyboard = "B", touch = "Tap", gamepad = Enum.KeyCode.DPadUp },
		gui = function()
			local pg = player:FindFirstChild("PlayerGui")
			return pg and pg:FindFirstChild("BagButton", true) :: GuiObject?
		end,
		done = function()
			return player:GetAttribute("BagOpen") == true
		end,
	},
	{
		id = "board",
		text = "Walk onto a ship to join its crew. Up to 4 Keepers sail together.",
		target = function()
			return nearest(Workspace:FindFirstChild("Lobby"), "BoardingZone")
		end,
		outline = function() -- the ship itself
			local wheel = nearest(Workspace:FindFirstChild("Lobby"), "WheelStand")
			return wheel and wheel:FindFirstAncestorOfClass("Model")
		end,
		done = function()
			return player:GetAttribute("Ready") == true
		end,
	},
	{
		id = "sail",
		text = "Hold the ship's wheel to set sail now, or wait for more crew to come aboard.",
		keys = { keyboard = "E", touch = "Tap", gamepad = X },
		target = function()
			return nearest(Workspace:FindFirstChild("Lobby"), "WheelStand")
		end,
		done = function()
			return inRun()
		end,
	},
}
local VOYAGE: { Step } = {
	{
		id = "oil",
		text = "The lamp burns oil all night. Grab a barrel from the oil pile.",
		keys = { keyboard = "E", touch = "Tap", gamepad = X },
		target = function()
			local i = island()
			return partOf(i and i:FindFirstChild("OilPile", true))
		end,
		outline = function() -- the oil shed round the barrels
			local props = Workspace:FindFirstChild("IslandProps")
			return props and props:FindFirstChild("OilShed", true)
		end,
		done = function()
			return player:GetAttribute("CarryingOil") == true or did.poured or isKeeper()
		end,
	},
	{
		id = "tank",
		text = "Pour it into the fuel tank to keep the light burning.",
		keys = { keyboard = "E", touch = "Tap", gamepad = X },
		target = function()
			local i = island()
			return partOf(i and i:FindFirstChild("FuelTank", true))
		end,
		done = function()
			return did.poured or isKeeper()
		end,
	},
	{
		id = "strike",
		text = "When creatures come, strike them with your weapon.",
		keys = { keyboard = "Click", touch = "Tap", gamepad = Enum.KeyCode.ButtonR2 },
		done = function()
			-- a swing, or any hit the server credits to this player (TUT.2: the Orbiting Blades and guns never
			-- "activate" a tool, so the owner's blade kills did not count)
			return did.attacked or player:GetAttribute("StruckCreature") == true
		end,
	},
	{
		id = "shells",
		text = "Pick up the Shells they drop. Your crew spends them on cannons and upgrades.",
		target = function()
			local i = island()
			return nearest(i and i:FindFirstChild("Loot"), "Loot_Shells")
		end,
		outline = function() -- the whole Shell pickup, not one of its parts
			local i = island()
			local part = nearest(i and i:FindFirstChild("Loot"), "Loot_Shells")
			local parent = part and part.Parent
			if parent and parent:IsA("Model") and string.sub(parent.Name, 1, 11) == "Loot_Shells" then
				return parent
			end
			return part
		end,
		done = function()
			return did.shells
		end,
	},
	{ id = "finish", text = "You're ready, Keeper! Work with your crew and keep the light burning until dawn.", button = "Finish" },
}

---------------------------------------------------------------------
-- UI: the card, the arrow over the target, the glow round a button, the edge arrow
---------------------------------------------------------------------

local gui = UiKit.Screen("Tutorial", 9)
local card = UiKit.new("Frame", {
	Name = "Card",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 152),
	Size = UDim2.new(0, 560, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = C.SurfacePrimary,
	BackgroundTransparency = 0.04,
	Visible = false,
}, gui)
UiKit.round(card, 18)
UiKit.border(card, C.AccentLighthouse, 2, 0.1)
local cardPad = UiKit.pad(card, 14, 18, 14, 18) :: UIPadding
local cardList = UiKit.list(card, "y", 10) :: UIListLayout
local sizeLimit = UiKit.new("UISizeConstraint", { MaxSize = Vector2.new(560, math.huge) }, card)
local cardScale = UiKit.new("UIScale", { Name = "PhoneScale" }, card) -- PHONE.3: smaller on phones
local stepLabel = UiKit.Label(card, "", "Eyebrow", { Name = "Step", LayoutOrder = 1, TextColor3 = C.AccentLighthouse })
local textLabel = UiKit.Label(card, "", "H3", { Name = "Text", LayoutOrder = 2, TextWrapped = true, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
local row = UiKit.new("Frame", { Name = "Row", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 56), LayoutOrder = 3 }, card)
local keySlot = UiKit.new("Frame", { Name = "Key", BackgroundTransparency = 1, Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.fromScale(0, 0) }, row)
local buttons = UiKit.new("Frame", { Name = "Buttons", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(1, 0, 1, 0) }, row) -- right-aligned; full width so two buttons fit on a phone
UiKit.list(buttons, "x", 10, { HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center })

-- a world marker can't live inside a ScreenGui (it would not draw), so it sits straight in PlayerGui
local arrow = UiKit.new("BillboardGui", {
	Name = "TutorialArrow",
	AlwaysOnTop = false, -- drawn in the world (an always-on-top marker did not show in Studio's view); it floats above the target's top
	LightInfluence = 0,
	ResetOnSpawn = false,
	Size = UDim2.fromOffset(84, 96),
	SizeOffset = Vector2.new(0, 0.5), -- the marker's bottom (the arrow's tip) sits on the lift point
	StudsOffsetWorldSpace = Vector3.new(0, 7, 0),
	Enabled = false,
}, player:WaitForChild("PlayerGui"))
local arrowBadge = UiKit.new("Frame", {
	Name = "Badge",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(72, 72),
	BackgroundColor3 = C.AccentLighthouse,
	BorderSizePixel = 0,
}, arrow)
UiKit.round(arrowBadge, 36)
UiKit.border(arrowBadge, C.SurfacePrimary, 4, 0)
local arrowGlyph = UiKit.Glyph(arrowBadge, "next", C.SurfacePrimary, 44)
arrowGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
arrowGlyph.Position = UDim2.fromScale(0.5, 0.56)
arrowGlyph.Rotation = 90 -- pointing down at the target

local highlight = Instance.new("Highlight")
highlight.Name = "TutorialHighlight"
highlight.FillTransparency = 0.75
highlight.FillColor = Color3.fromRGB(255, 205, 90)
highlight.OutlineColor = Color3.fromRGB(255, 225, 140)
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Enabled = false
highlight.Parent = Workspace -- made on this client only; a Highlight inside a ScreenGui does not draw

local glow = UiKit.new("Frame", { Name = "ButtonGlow", BackgroundTransparency = 1, Visible = false, ZIndex = 50 }, gui)
UiKit.round(glow, 999)
local glowStroke = UiKit.border(glow, Color3.fromRGB(255, 205, 90), 4, 0)

local edge = UiKit.new("Frame", { Name = "EdgeArrow", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(56, 56), BackgroundColor3 = C.SurfacePrimary, BackgroundTransparency = 0.15, Visible = false }, gui)
UiKit.round(edge, 28)
UiKit.border(edge, C.AccentLighthouse, 2, 0)
local edgeGlyph = UiKit.Glyph(edge, "next", C.AccentLighthouse, 30)
edgeGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
edgeGlyph.Position = UDim2.fromScale(0.5, 0.5)

---------------------------------------------------------------------
-- RUNNING
---------------------------------------------------------------------

local steps: { Step } = {}
local index = 0
local running = false
local finishSent = false

local function setActive(on: boolean)
	player:SetAttribute("TutorialActive", if on then true else nil)
end

local function clear(container: Instance)
	for _, child in container:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local stop: () -> () -- forward
local function finish()
	if not finishSent then
		finishSent = true
		remotes:WaitForChild("TutorialDone"):FireServer(true)
	end
	stop()
end

local function show(step: Step)
	stepLabel.Text = string.format("TUTORIAL \u{00B7} STEP %d OF %d", index, #steps)
	textLabel.Text = step.text
	clear(keySlot)
	if step.keys then
		local mode = InputController.mode()
		if step.keys[mode] then
			UiKit.KeyHint(keySlot, step.keys, "", { input = mode })
		end
	end
	clear(buttons)
	if step.button then
		UiKit.Button(buttons, step.button, { variant = "primary", size = "lg", layoutOrder = 2, onClick = function()
			if index >= #steps then
				finish()
			else
				index += 1
				show(steps[index])
			end
		end })
	end
	UiKit.Button(buttons, "Skip", { variant = "ghost", size = "lg", layoutOrder = 1, onClick = finish })
	card.Visible = true
end

stop = function()
	running = false
	card.Visible = false
	arrow.Enabled = false
	highlight.Enabled = false
	highlight.Adornee = nil
	glow.Visible = false
	glow.Parent = gui
	edge.Visible = false
	setActive(false)
end

local function start(list: { Step })
	steps = list
	index = 1
	running = true
	setActive(true)
	show(steps[index])
end

-- the voyage part follows the harbor part in the one-place game (Studio, or before the isle place existed)
local function startFor(context: string)
	if context == "voyage" then
		start(VOYAGE)
	else
		local both = table.clone(HARBOR)
		for _, s in VOYAGE do
			table.insert(both, s)
		end
		start(if PlaceRole.get() == "harbor" then HARBOR else both)
	end
end

local lastCheck = 0
local target: BasePart?, button: GuiObject? = nil, nil
RunService.RenderStepped:Connect(function()
	if not running then
		return
	end
	local step = steps[index]
	if not step then
		stop()
		return
	end
	local now = os.clock()
	if now - lastCheck > 0.25 then
		lastCheck = now
		if step.done and step.done() then
			if index >= #steps then
				finish()
				return
			end
			index += 1
			show(steps[index])
			step = steps[index]
		end
		-- the arrow, the outline and the glow follow the current target (looked up four times a second)
		target = step.target and step.target() or nil
		local outlined = if step.outline then step.outline() else target
		arrow.Adornee = target
		arrow.Enabled = target ~= nil
		if target then
			local top = target.Position.Y + target.Size.Y / 2
			if outlined and outlined:IsA("Model") then -- above a small model's top (a stall, a shed); a ship is too tall
				local box, size = outlined:GetBoundingBox()
				if size.Y < 20 then
					top = math.max(top, box.Position.Y + size.Y / 2)
				end
			end
			arrow.StudsOffsetWorldSpace = Vector3.new(0, top - target.Position.Y + 1.5, 0)
		end
		highlight.Adornee = outlined
		highlight.Enabled = outlined ~= nil
		button = step.gui and step.gui() or nil
	end
	arrowBadge.Position = UDim2.new(0.5, 0, 0.5, math.sin(now * 5) * 8)
	if button and button.Visible then
		-- a pulsing ring just outside the button (inside its own screen, so it lines up on every device)
		if glow.Parent ~= button then
			glow.Parent = button
			glow.Position = UDim2.fromOffset(-8, -8)
			glow.Size = UDim2.new(1, 16, 1, 16)
		end
		glowStroke.Transparency = 0.2 + 0.4 * (0.5 + 0.5 * math.sin(now * 6))
		glow.Visible = true
	else
		glow.Visible = false
	end
	-- off screen: a round arrow at the edge of the screen, pointing toward the target
	local camera = Workspace.CurrentCamera
	if target and camera then
		local screen, onScreen = camera:WorldToViewportPoint(target.Position)
		local view = camera.ViewportSize
		if onScreen and screen.Z > 0 then
			edge.Visible = false
		else
			local center = view / 2
			local dir = Vector2.new(screen.X, screen.Y) - center
			if screen.Z < 0 then
				dir = -dir
			end
			if dir.Magnitude < 1 then
				dir = Vector2.new(0, 1)
			end
			dir = dir.Unit
			local margin = 48
			local scale = math.min((center.X - margin) / math.max(math.abs(dir.X), 1e-3), (center.Y - margin) / math.max(math.abs(dir.Y), 1e-3))
			local at = center + dir * scale
			-- never on top of the card: below it instead
			local cardAt, cardSize = card.AbsolutePosition, card.AbsoluteSize
			if at.X > cardAt.X - 32 and at.X < cardAt.X + cardSize.X + 32 and at.Y > cardAt.Y - 32 and at.Y < cardAt.Y + cardSize.Y + 32 then
				at = Vector2.new(at.X, cardAt.Y + cardSize.Y + 44)
			end
			edge.Position = UDim2.fromOffset(at.X, at.Y)
			edgeGlyph.Rotation = math.deg(math.atan2(dir.Y, dir.X))
			edge.Visible = true
		end
	else
		edge.Visible = false
	end
end)

-- the card sits on the left (the middle of the screen stays clear for the arrow and the target). On a phone it is
-- wider and shorter and sits just under the top banner, so it stays clear of the thumbstick in the bottom left
-- (iPhone 7 simulator: card 330x136 at y 82, 12 px under the 64 px harbor banner; thumbstick from y 223).
local function fit()
	local view = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local phone = UiKit.Breakpoint(view) == "phone"
	card.AnchorPoint = Vector2.new(0, 0)
	card.Position = UDim2.new(0, 16, 0, if phone then 82 else 152)
	sizeLimit.MaxSize = Vector2.new(if phone then math.clamp(view.X - 32, 300, 330) else 460, math.huge)
	textLabel.TextSize = if phone then 16 else 18
	-- PHONE.3 (owner 2026-10-24: "the tutorial UI is too big for phone"): the whole card at 78% on a phone
	-- (about 257 x 106 px on an iPhone 14, was 330 x 136); its buttons are then about 44 px tall
	cardScale.Scale = if phone then 0.78 else 1
	cardPad.PaddingTop = UDim.new(0, if phone then 10 else 14)
	cardPad.PaddingBottom = UDim.new(0, if phone then 10 else 14)
	cardList.Padding = UDim.new(0, if phone then 6 else 10)
end
fit()
if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
end

---------------------------------------------------------------------
-- WHEN IT STARTS
---------------------------------------------------------------------

local started = false
remotes:WaitForChild("GearData").OnClientEvent:Connect(function(profile)
	if started or type(profile) ~= "table" or not Config.COACH_ENABLED then
		return
	end
	started = true
	if profile.tutorialDone == true then
		return
	end
	startFor(if PlaceRole.get() == "isle" or inRun() then "voyage" else "harbor")
end)
task.defer(function()
	remotes:WaitForChild("GearAction"):FireServer("sync")
end)

-- the BAG's Tutorial tile: play it again from the start (harbor or voyage, wherever the player is)
replayEvent.Event:Connect(function()
	finishSent = true -- already finished once: replaying sends nothing
	for key in did do
		did[key] = false
	end
	startFor(if PlaceRole.get() == "isle" or inRun() then "voyage" else "harbor")
end)
