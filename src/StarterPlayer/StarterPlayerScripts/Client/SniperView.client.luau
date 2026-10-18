--!strict
-- SniperView (client, D-044): the view from the sniper tower (the owner's idea). While the server says this
-- player is up the tower (player attribute OnSniperTower), the camera is first person at the rifle with a
-- crosshair in the middle. A click (PC), the FIRE button (touch) or R2 (controller) sends where the crosshair
-- points; the server traces the shot and applies the damage. Right mouse, the ZOOM button or L2 zooms in.
-- E, the CLIMB DOWN button or B brings the player back down. Nothing here decides a hit.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StatPipeline = require(Shared:WaitForChild("StatPipeline")) :: any
local SoundFx = require(Shared:WaitForChild("SoundFx")) :: any
local UiKit = require(script.Parent:WaitForChild("UiKit")) :: any
local Tiles = require(script.Parent:WaitForChild("UI"):WaitForChild("Tiles")) :: any

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SniperAction") :: RemoteEvent

local NORMAL_FOV = 60
local SCOPE_FOV = 20
local stats = StatPipeline.sniper()

local mounted = false
local scoped = false
local lastShot = -math.huge
local saved: { [string]: any } = {}
local gui: ScreenGui? = nil
local parts: { [string]: any } = {}

local function camera(): Camera
	return Workspace.CurrentCamera :: Camera
end

-- Where the crosshair points: the first thing the camera's centre line meets (not this player or the tower)
local function aimPoint(): Vector3
	local cf = camera().CFrame
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude: { Instance } = {}
	if player.Character then
		table.insert(exclude, player.Character)
	end
	local island = Workspace:FindFirstChild("Island")
	local tower = island and island:FindFirstChild("SniperTower")
	if tower then
		table.insert(exclude, tower)
	end
	params.FilterDescendantsInstances = exclude
	local hit = Workspace:Raycast(cf.Position, cf.LookVector * (stats.range + 40), params)
	return if hit then hit.Position else cf.Position + cf.LookVector * stats.range
end

local function setScope(on: boolean)
	if not mounted then
		return
	end
	scoped = on
	TweenService:Create(camera(), TweenInfo.new(0.12), { FieldOfView = if on then SCOPE_FOV else NORMAL_FOV }):Play()
	UserInputService.MouseDeltaSensitivity = if on then 0.35 else (saved.sensitivity or 1)
	if parts.ring then
		parts.ring.Visible = on
	end
	if parts.zoom then
		parts.zoom.paint({ face = if on then Color3.fromRGB(255, 194, 61) else Color3.fromRGB(36, 73, 110), edge = if on then Color3.fromRGB(179, 123, 12) else Color3.fromRGB(19, 40, 61), text = if on then Color3.fromRGB(42, 21, 0) else Color3.new(1, 1, 1) }, "Zoom")
	end
end

local function fire()
	if not mounted then
		return
	end
	local now = os.clock()
	if now - lastShot < stats.cooldown then
		SoundFx.play2D("denied", 1.4)
		return
	end
	lastShot = now
	remote:FireServer("fire", aimPoint())
	-- the crosshair kicks; the bar under it refills while the rifle reloads
	if parts.cross then
		parts.cross.Size = UDim2.fromOffset(46, 46)
		TweenService:Create(parts.cross, TweenInfo.new(0.18), { Size = UDim2.fromOffset(34, 34) }):Play()
	end
	if parts.reload then
		parts.reload.Size = UDim2.fromScale(0, 1)
		TweenService:Create(parts.reload, TweenInfo.new(stats.cooldown, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 1) }):Play()
	end
end

local function climbDown()
	if mounted then
		remote:FireServer("leave")
	end
end

local function build(): ScreenGui
	local screen = UiKit.Screen("SniperView", 15, true)
	local root = UiKit.new("Frame", { Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, screen)

	-- the scope: a dark ring round a clear circle (shown while zoomed)
	local ring = UiKit.new("Frame", { Name = "ScopeRing", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.82, 0.82), Visible = false }, root)
	UiKit.new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, ring)
	UiKit.new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, ring)
	UiKit.new("UIStroke", { Thickness = 2400, Color = Color3.new(0, 0, 0), Transparency = 0.12 }, ring)
	UiKit.new("UIStroke", { Name = "Rim", Thickness = 3, Color = Color3.fromRGB(20, 20, 20) }, UiKit.new("Frame", { Name = "RimHolder", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, ring))
	parts.ring = ring

	-- the crosshair: four ticks round a dot, and the reload bar under it
	local cross = UiKit.new("Frame", { Name = "Crosshair", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(34, 34) }, root)
	local tick = Color3.fromRGB(255, 236, 170)
	for _, spec in { { 0.5, 0, 0.5, 0, 3, 0.36 }, { 0.5, 1, 0.5, 1, 3, 0.36 }, { 0, 0.5, 0, 0.5, 0.36, 3 }, { 1, 0.5, 1, 0.5, 0.36, 3 } } do
		local bar = UiKit.new("Frame", { BackgroundColor3 = tick, BorderSizePixel = 0, AnchorPoint = Vector2.new(spec[3], spec[4]), Position = UDim2.fromScale(spec[1], spec[2]), Size = UDim2.new(if spec[5] == 3 then 0 else spec[5], if spec[5] == 3 then 3 else 0, if spec[6] == 3 then 0 else spec[6], if spec[6] == 3 then 3 else 0) }, cross)
		UiKit.new("UIStroke", { Thickness = 1, Color = Color3.new(0, 0, 0) }, bar)
	end
	local dot = UiKit.new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 90, 70), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(5, 5) }, cross)
	UiKit.new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, dot)
	parts.cross = cross
	local bar = UiKit.new("Frame", { Name = "Reload", BackgroundColor3 = Color3.fromRGB(20, 30, 40), BackgroundTransparency = 0.3, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 30), Size = UDim2.fromOffset(60, 6) }, root)
	UiKit.new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, bar)
	local fill = UiKit.new("Frame", { Name = "Fill", BackgroundColor3 = tick, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, bar)
	UiKit.new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)
	parts.reload = fill

	-- buttons: CLIMB DOWN for everyone; FIRE and ZOOM on touch screens
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	-- PH.1: on a short touch screen (a phone held sideways) the buttons sit lower and smaller, so CLIMB DOWN stays
	-- clear of the Roblox top bar; the joystick and jump button are hidden while up the tower (see mount)
	local short = touch and camera().ViewportSize.Y <= 500
	local down = Tiles.bigButton(root, "ClimbDown")
	down.button.AnchorPoint = Vector2.new(1, 1) -- right side, clear of the HUD's top bar and the hotbar
	down.button.Position = if short then UDim2.new(1, -24, 1, -142) else UDim2.new(1, -28, 1, -300)
	down.button.Size = if short then UDim2.fromOffset(190, 56) else UDim2.fromOffset(220, 64)
	down.paint({ face = Color3.fromRGB(220, 40, 40), edge = Color3.fromRGB(140, 20, 20), text = Color3.new(1, 1, 1) }, "Climb down")
	down.button.Activated:Connect(climbDown)
	if touch then
		local fireButton = Tiles.bigButton(root, "Fire")
		fireButton.button.AnchorPoint = Vector2.new(1, 1)
		fireButton.button.Position = if short then UDim2.new(1, -24, 1, -24) else UDim2.new(1, -28, 1, -150)
		fireButton.button.Size = if short then UDim2.fromOffset(104, 104) else UDim2.fromOffset(120, 120)
		fireButton.paint({ face = Color3.fromRGB(120, 220, 60), edge = Color3.fromRGB(70, 150, 30), text = Color3.new(1, 1, 1) }, "Fire")
		fireButton.button.Activated:Connect(fire)
		local zoom = Tiles.bigButton(root, "Zoom")
		zoom.button.AnchorPoint = Vector2.new(1, 1)
		zoom.button.Position = if short then UDim2.new(1, -140, 1, -34) else UDim2.new(1, -164, 1, -150)
		zoom.button.Size = if short then UDim2.fromOffset(84, 84) else UDim2.fromOffset(96, 96)
		zoom.button.Activated:Connect(function()
			setScope(not scoped)
		end)
		parts.zoom = zoom
	else
		local hint = UiKit.Label(root, if UiKit.usingGamepad() then "R2 shoot · L2 zoom · B climb down" else "Click to shoot · Right-click to zoom · E to climb down", "Body", {
			Name = "Hint",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -150),
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		UiKit.new("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0) }, hint)
	end
	screen.Parent = player:WaitForChild("PlayerGui")
	return screen
end

local function mount()
	if mounted then
		return
	end
	mounted = true
	pcall(function() -- PH.1: no joystick or jump button up the tower (nobody walks there); FIRE and ZOOM take that corner
		GuiService.TouchControlsEnabled = false
	end)
	local cam = camera()
	saved.cameraMode = player.CameraMode
	saved.fov = cam.FieldOfView
	saved.sensitivity = UserInputService.MouseDeltaSensitivity
	saved.minZoom = player.CameraMinZoomDistance
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	cam.FieldOfView = NORMAL_FOV
	parts = {}
	gui = build()
	setScope(false)
	ContextActionService:BindActionAtPriority("SniperFire", function(_, state)
		if state == Enum.UserInputState.Begin then
			fire()
		end
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
	ContextActionService:BindActionAtPriority("SniperZoom", function(_, state)
		if state == Enum.UserInputState.Begin then
			setScope(true)
		elseif state == Enum.UserInputState.End then
			setScope(false)
		end
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL2)
	ContextActionService:BindActionAtPriority("SniperDown", function(_, state)
		if state == Enum.UserInputState.Begin then
			climbDown()
		end
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.KeyCode.E, Enum.KeyCode.ButtonB)
end

local function unmount()
	if not mounted then
		return
	end
	setScope(false)
	mounted = false
	pcall(function()
		GuiService.TouchControlsEnabled = player:GetAttribute("MenuOpen") ~= true
	end)
	ContextActionService:UnbindAction("SniperFire")
	ContextActionService:UnbindAction("SniperZoom")
	ContextActionService:UnbindAction("SniperDown")
	player.CameraMode = saved.cameraMode or Enum.CameraMode.Classic
	-- pull the camera back out of first person, then give the player their own zoom again
	local minZoom = saved.minZoom or 0.5
	player.CameraMinZoomDistance = 12
	task.delay(0.2, function()
		player.CameraMinZoomDistance = minZoom
	end)
	camera().FieldOfView = saved.fov or 70
	UserInputService.MouseDeltaSensitivity = saved.sensitivity or 1
	if gui then
		gui:Destroy()
		gui = nil
	end
	parts = {}
end

player:GetAttributeChangedSignal("OnSniperTower"):Connect(function()
	if player:GetAttribute("OnSniperTower") then
		mount()
	else
		unmount()
	end
end)
player.CharacterRemoving:Connect(unmount)
