-- HudParts/Build (S5.6): builds every HUD element once, already in the night-navy glass variant (the HUD
-- calls this between UiKit.beginGlass and UiKit.endGlass). Returns the elements the HUD script binds.
-- Layout lives in HudParts/Layout, prompts in HudParts/Prompts, boss bars in HudParts/Bosses.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Client = script.Parent.Parent
local UiKit = require(Client:WaitForChild("UiKit"))
local ItemPreview = require(Client:WaitForChild("ItemPreview"))

local Build = {}

function Build.build()
	local state = ReplicatedStorage:WaitForChild("GameState")
	local lampAction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("LampAction")
	local C = UiKit.palette()
	local F = UiKit.Font
	local GLASS = UiKit.GLASS
	local w = {}

	---------------------------------------------------------------------
	-- Screens: the HUD (only while in the crew) and prompts (always, also in the harbor)
	---------------------------------------------------------------------

	local gui = UiKit.Screen("GameHUD", 5)
	local promptGui = UiKit.Screen("Prompts", 6)
	local function makeRoot(screen)
		local root = UiKit.new("Frame", { Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, screen)
		local outline = UiKit.border(root, C.TextMuted, 2)
		outline.Enabled = false
		return root
	end
	local hudRoot = makeRoot(gui)
	local promptRoot = makeRoot(promptGui)
	w.gui, w.promptGui, w.hudRoot, w.promptRoot = gui, promptGui, hudRoot, promptRoot

	local function cluster(name, anchor, position, align)
		local f = UiKit.new("Frame", {
			Name = name,
			BackgroundTransparency = 1,
			AnchorPoint = anchor,
			Position = position,
			Size = UDim2.fromOffset(300, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, hudRoot)
		UiKit.list(f, "y", 8, { HorizontalAlignment = align })
		return f
	end

	w.topLeft = cluster("TopLeft", Vector2.new(0, 0), UDim2.fromOffset(12, 10), Enum.HorizontalAlignment.Left)
	w.topCenter = cluster("TopCenter", Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 8), Enum.HorizontalAlignment.Center)
	w.topRight = cluster("TopRight", Vector2.new(1, 0), UDim2.new(1, -12, 0, 64), Enum.HorizontalAlignment.Right)

	-- a quiet backing plate so gauges stay legible over rain and lightning
	local function plate(parent, order, name)
		local p = UiKit.new("Frame", {
			Name = name or "Plate",
			BackgroundColor3 = C.SurfaceBase,
			BackgroundTransparency = 0.3,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = order,
		}, parent)
		UiKit.round(p, UiKit.Radius.panel)
		UiKit.border(p, C.BorderStructural, 1, 0.6)
		UiKit.pad(p, 10, 12, 10, 12)
		UiKit.list(p, "y", 10)
		return UiKit.glassPanel(p)
	end

	---------------------------------------------------------------------
	-- TOP LEFT: health, weapon, shells
	---------------------------------------------------------------------

	local leftPlate = plate(w.topLeft, 1, "SurvivorPlate")
	w.leftPlate = leftPlate
	w.health = UiKit.HealthGauge(leftPlate, { value = 100, max = 100, size = UDim2.new(1, 0, 0, 38), layoutOrder = 1 })
	do
		-- the heart cap is a round coral ring in glass
		local cap = leftPlate:FindFirstChild("Cap", true)
		if cap then
			local corner = cap:FindFirstChildOfClass("UICorner") or UiKit.round(cap, 0)
			corner.CornerRadius = UDim.new(0.5, 0)
			local s = cap:FindFirstChildOfClass("UIStroke")
			if s then
				s.Color = GLASS.heart
				s.Transparency = 0.05
				s.Thickness = 2
			end
		end
	end

	-- weapon in hand (one small static 3D preview, refreshed only when the weapon changes)
	local weaponRow = UiKit.new("Frame", { Name = "Weapon", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 2 }, leftPlate)
	local weaponWell = UiKit.Inset(weaponRow, { Name = "Well", BackgroundColor3 = Color3.fromRGB(22, 32, 46), Size = UDim2.fromOffset(44, 44), ClipsDescendants = true })
	UiKit.border(weaponWell, C.BorderStructural, 1, 0.55)
	w.weaponPreview = ItemPreview.new(weaponWell, {})
	w.weaponName = UiKit.Label(weaponRow, "", "H3", {
		Position = UDim2.fromOffset(54, 2),
		Size = UDim2.new(1, -54, 0, 20),
		AutomaticSize = Enum.AutomaticSize.None,
		TextSize = 16,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextWrapped = false,
	})
	w.weaponState = UiKit.Label(weaponRow, "", "Caption", {
		Position = UDim2.fromOffset(54, 23),
		Size = UDim2.new(1, -54, 0, 16),
		AutomaticSize = Enum.AutomaticSize.None,
		TextWrapped = false,
	})
	w.cooldownTrack = UiKit.new("Frame", {
		Name = "Cooldown",
		BackgroundColor3 = C.SurfaceInset,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 54, 1, 0),
		Size = UDim2.new(1, -54, 0, 3),
		Visible = false,
	}, weaponRow)
	w.cooldownFill = UiKit.new("Frame", { BackgroundColor3 = C.AccentLighthouse, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1) }, w.cooldownTrack)
	w.weaponScale = UiKit.new("UIScale", {}, weaponRow)
	w.weaponRow, w.weaponWell = weaponRow, weaponWell

	if Config.ECONOMY_ENABLED then
		w.shells = UiKit.Currency(leftPlate, "Shells", state:GetAttribute("Shells") or 0, { layoutOrder = 3 })
	end

	---------------------------------------------------------------------
	-- TOP CENTER: voyage status, lamp fuel, big-monster warning, boss bars
	---------------------------------------------------------------------

	local voyage = UiKit.new("Frame", {
		Name = "Voyage",
		BackgroundColor3 = C.SurfacePrimary,
		BackgroundTransparency = 0.1,
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 1,
	}, w.topCenter)
	UiKit.round(voyage, UiKit.Radius.panel)
	UiKit.border(voyage, C.BorderStructural, 1, 0.4)
	UiKit.pad(voyage, 0, 14, 0, 14)
	UiKit.list(voyage, "x", 10, { VerticalAlignment = Enum.VerticalAlignment.Center })
	UiKit.glassPanel(voyage)
	w.voyage = voyage
	w.voyageScale = UiKit.new("UIScale", {}, voyage)
	local pips = UiKit.new("Frame", { Name = "Nights", BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 12), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 1 }, voyage)
	UiKit.list(pips, "x", 6, { VerticalAlignment = Enum.VerticalAlignment.Center })
	w.pips, w.pipFrames = pips, {}
	-- Long runs (more than 7 nights) skip the night diamonds: "NIGHT 4 OF 13" says it, and 13 diamonds crowd phones
	pips.Visible = Config.NIGHTS_TO_WIN <= 7
	for i = 1, if Config.NIGHTS_TO_WIN <= 7 then Config.NIGHTS_TO_WIN else 0 do
		local holder = UiKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(12, 12), LayoutOrder = i }, pips)
		local d = UiKit.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(8, 8),
			Rotation = 45,
			BorderSizePixel = 0,
		}, holder)
		local stroke = UiKit.border(d, C.BorderStructural, 1.5, 0)
		w.pipFrames[i] = { d = d, stroke = stroke }
	end
	w.voyageTitle = UiKit.new("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		FontFace = F.LabelBold,
		TextSize = 18,
		TextColor3 = C.TextPrimary,
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
	}, voyage)
	w.voyageSub = UiKit.new("TextLabel", {
		Name = "Subtitle",
		BackgroundTransparency = 1,
		FontFace = F.Body,
		TextSize = 15,
		TextColor3 = C.TextSecondary,
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 3,
	}, voyage)
	w.timerChip = UiKit.Inset(voyage, { Name = "Timer", Size = UDim2.fromOffset(56, 26), LayoutOrder = 4 })
	w.timerText = UiKit.new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = F.Numeric,
		TextSize = 16,
		TextColor3 = C.TextPrimary,
		Size = UDim2.fromScale(1, 1),
	}, w.timerChip)

	w.fuelPlate = plate(w.topCenter, 2, "FuelPlate")
	w.fuel = UiKit.FuelGauge(w.fuelPlate, { value = 1, size = UDim2.new(1, 0, 0, 58), layoutOrder = 1 })

	local warning = UiKit.new("Frame", {
		Name = "BigWarning",
		BackgroundColor3 = C.SurfaceBase,
		BackgroundTransparency = 0.15,
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 3,
		Visible = false,
	}, w.topCenter)
	UiKit.round(warning, UiKit.Radius.card)
	UiKit.border(warning, C.StateDanger, 1.5, 0.2)
	UiKit.pad(warning, 0, 14, 0, 12)
	UiKit.list(warning, "x", 10, { VerticalAlignment = Enum.VerticalAlignment.Center })
	UiKit.Glyph(warning, "warning", C.StateDanger, 18).LayoutOrder = 1
	UiKit.new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = F.LabelBold,
		TextSize = 17,
		TextColor3 = C.StateDanger,
		Text = "SOMETHING BIG IS COMING",
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
	}, warning)
	w.warningSub = UiKit.new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = F.Body,
		TextSize = 15,
		TextColor3 = C.TextPrimary,
		Text = "Stay close to your crew.",
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 3,
	}, warning)
	UiKit.glassPanel(warning, true)
	warning.BackgroundColor3 = GLASS.dangerBg
	w.warning = warning

	w.bossList = UiKit.new("Frame", {
		Name = "Bosses",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(440, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 4,
	}, w.topCenter)
	UiKit.list(w.bossList, "y", 6)

	---------------------------------------------------------------------
	-- TOP RIGHT: tower, beam
	---------------------------------------------------------------------

	w.rightPlate = plate(w.topRight, 1, "LighthousePlate")
	w.tower = UiKit.TowerGauge(w.rightPlate, { value = 1, size = UDim2.new(1, 0, 0, 42), layoutOrder = 1 })

	local beamRow = UiKit.new("Frame", { Name = "Beam", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 2 }, w.rightPlate)
	UiKit.list(beamRow, "x", 8, { VerticalAlignment = Enum.VerticalAlignment.Center })
	w.beamRow = beamRow
	w.beamGlyph = UiKit.new("Frame", { Name = "BeamGlyph", BackgroundTransparency = 1, Size = UDim2.fromOffset(22, 18), LayoutOrder = 1 }, beamRow)
	w.beamText = UiKit.new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = F.LabelBold,
		TextSize = 16,
		TextColor3 = C.TextPrimary,
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
	}, beamRow)
	w.beamTag = UiKit.Tag(beamRow, "Burns fuel faster", "StateWarning", { layoutOrder = 3 })
	w.keeperText = UiKit.Label(w.rightPlate, "", "Micro", { LayoutOrder = 3, Visible = false })

	---------------------------------------------------------------------
	-- CENTER: blackout alarm (sits above the crosshair, never on it)
	---------------------------------------------------------------------

	local alarm = UiKit.new("Frame", {
		Name = "BlackoutAlarm",
		BackgroundColor3 = C.SurfaceBase,
		BackgroundTransparency = 0.08,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0.5, -70),
		Size = UDim2.fromOffset(460, 76),
		Visible = false,
	}, hudRoot)
	UiKit.round(alarm, UiKit.Radius.panel)
	w.alarmStroke = UiKit.border(alarm, C.StateDanger, 2, 0)
	local alarmLamp = UiKit.Glyph(alarm, "lamp", C.StateDanger, 34)
	alarmLamp.AnchorPoint = Vector2.new(0, 0.5)
	alarmLamp.Position = UDim2.new(0, 18, 0.5, 0)
	w.alarmTitle = UiKit.new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = F.LabelBold,
		TextSize = 24,
		TextColor3 = C.StateDanger,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "THE LAMP IS OUT",
		Position = UDim2.fromOffset(66, 10),
		Size = UDim2.new(1, -150, 0, 28),
	}, alarm)
	w.alarmBody = UiKit.new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = F.BodyMedium,
		TextSize = 15,
		TextColor3 = C.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Position = UDim2.fromOffset(66, 38),
		Size = UDim2.new(1, -150, 0, 32),
	}, alarm)
	w.alarmCount = UiKit.new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = F.Numeric,
		TextSize = 38,
		TextColor3 = C.TextPrimary,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -18, 0.5, 0),
		Size = UDim2.fromOffset(72, 44),
		TextXAlignment = Enum.TextXAlignment.Right,
	}, alarm)
	UiKit.glassPanel(alarm, true)
	alarm.BackgroundColor3 = GLASS.dangerBg
	w.alarm = alarm

	---------------------------------------------------------------------
	-- BOTTOM: cannon card, carried oil, interaction prompts (HudParts/Prompts), keeper controls
	---------------------------------------------------------------------

	local bottom = UiKit.new("Frame", {
		Name = "Bottom",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -100),
		Size = UDim2.fromOffset(320, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, promptRoot)
	UiKit.list(bottom, "y", 8, { HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Bottom })
	w.bottom = bottom

	local function card(name, order)
		local f = UiKit.new("Frame", {
			Name = name,
			BackgroundColor3 = C.SurfacePrimary,
			BackgroundTransparency = 0.08,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = order,
			Visible = false,
		}, bottom)
		UiKit.round(f, UiKit.Radius.panel)
		UiKit.border(f, C.BorderStructural, 1, 0.4)
		UiKit.pad(f, 10, 12, 10, 12)
		return f
	end

	-- context cards (cannon, carried oil) live in the right column under the lighthouse plate, so the
	-- bottom band only holds the action prompts and never grows up into the crosshair
	w.sideStack = UiKit.new("Frame", {
		Name = "SideStack",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 170),
		Size = UDim2.fromOffset(174, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
	}, promptRoot)
	UiKit.list(w.sideStack, "y", 6)

	-- cannon nearby
	local cannonCard = card("CannonCard", 1)
	UiKit.list(cannonCard, "y", 6)
	w.cannonHead = UiKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 1 }, cannonCard)
	w.cannonTitle = UiKit.Label(w.cannonHead, "Cannon", "Label", { Size = UDim2.new(0.6, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.None, TextWrapped = false, TextColor3 = C.TextPrimary })
	w.cannonHull = UiKit.new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = F.BodyMedium,
		TextSize = 14,
		TextColor3 = C.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0.4, 0, 1, 0),
	}, w.cannonHead)
	w.cannonAmmo = UiKit.ResourceGauge(cannonCard, { label = "Oil Shot", value = 1, color = "CatAmmunition", warnBelow = 0.3, dangerBelow = 0.01, ticks = 10, size = UDim2.new(1, 0, 0, 38), layoutOrder = 2 })
	UiKit.glassPanel(cannonCard)
	w.cannonCard = cannonCard

	-- carrying oil
	local carryCard = card("CarryCard", 2)
	UiKit.list(carryCard, "x", 10, { VerticalAlignment = Enum.VerticalAlignment.Center })
	UiKit.Glyph(carryCard, "lamp", C.AccentLighthouse, 22).LayoutOrder = 1
	local carryText = UiKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -40, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2 }, carryCard)
	UiKit.list(carryText, "y", 0)
	UiKit.Label(carryText, "Carrying oil", "H3", { LayoutOrder = 1, TextSize = 16 })
	UiKit.Label(carryText, "Pour it into the fuel tank, or reload a cannon.", "BodySmall", { LayoutOrder = 2 })
	UiKit.glassPanel(carryCard)
	w.carryCard = carryCard

	-- keeper controls (only for the player at the lamp)
	local keeperRow = UiKit.new("Frame", {
		Name = "KeeperControls",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 5,
		Visible = false,
	}, bottom)
	UiKit.list(keeperRow, "y", 6, { HorizontalAlignment = Enum.HorizontalAlignment.Center })
	w.keeperRow = keeperRow
	w.focusWarn = UiKit.Tag(keeperRow, "Focused beam burns fuel faster", "StateWarning", { layoutOrder = 1 })
	local keeperButtons = UiKit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 48), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2 }, keeperRow)
	UiKit.list(keeperButtons, "x", 10)
	-- 190 wide: the width the beam button has always shown (its old mirrored skin label widened it by 40)
	w.beamButton = UiKit.Button(keeperButtons, "Focus beam", { name = "ToggleBeam", variant = "secondary", minWidth = 190, layoutOrder = 1, onClick = function()
		lampAction:FireServer("toggleMode")
	end })
	w.leaveButton = UiKit.Button(keeperButtons, "Leave lamp", { name = "LeaveLamp", variant = "ghost", minWidth = 130, layoutOrder = 2, onClick = function()
		lampAction:FireServer("leave")
	end })

	---------------------------------------------------------------------
	-- GLASS HUD (owner, Oct 13 2026, from the owner's mock-up)
	-- Night-navy glass panels with a soft blue glow. Menus keep the wood skin; the in-game HUD, prompts
	-- and notices use glass. Layout: voyage chip in the top-bar row (top right), health top-left,
	-- BAG / tower / lamp down the right, lamp fuel (or the blackout banner) top-center, the action
	-- prompt above a weapon slot at the bottom, Shells bottom-right (phones: under health).
	---------------------------------------------------------------------

	-- top bar: the voyage chip sits in the Roblox top-bar row, top right (mock-up: "Night 2:38 AM")
	local topBarGui = UiKit.Screen("HudTopBar", 5)
	topBarGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	w.topBarGui = topBarGui
	w.topBar = UiKit.new("Frame", {
		Name = "TopBar",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 10),
		Size = UDim2.fromOffset(0, 44),
		AutomaticSize = Enum.AutomaticSize.X,
	}, topBarGui)
	voyage.Parent = w.topBar
	voyage.LayoutOrder = 1
	-- lamp fuel also moves up into the top-bar row, as a slim bar (owner, Oct 13: "too big")
	w.topFuelBar = UiKit.new("Frame", {
		Name = "TopFuel",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
	}, topBarGui)
	w.fuelPlate.Parent = w.topFuelBar

	-- sun by day, crescent moon by night
	w.sky = UiKit.new("Frame", { Name = "Sky", BackgroundTransparency = 1, Size = UDim2.fromOffset(26, 26), LayoutOrder = 0 }, voyage)
	w.orb = UiKit.new("Frame", {
		Name = "Orb",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(22, 22),
		BorderSizePixel = 0,
	}, w.sky)
	UiKit.round(w.orb, 11)
	w.bite = UiKit.new("Frame", {
		Name = "Bite",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 7, 0.5, -5),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = Color3.fromRGB(14, 22, 42),
		BorderSizePixel = 0,
	}, w.sky)
	UiKit.round(w.bite, 9)

	-- lamp state gets its own pill under the tower (red when the lamp is dark)
	local lampPill = UiKit.new("Frame", {
		Name = "LampPill",
		BackgroundColor3 = GLASS.bg,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
	}, w.topRight)
	UiKit.round(lampPill, GLASS.radius)
	w.lampStroke = UiKit.border(lampPill, GLASS.glow, 1.5, GLASS.glowT)
	UiKit.pad(lampPill, 9, 12, 9, 12)
	UiKit.list(lampPill, "y", 4)
	UiKit.glassPanel(lampPill)
	beamRow.Parent = lampPill
	w.keeperText.Parent = lampPill
	w.keeperText.LayoutOrder = 3
	w.lampPill = lampPill

	-- Shells: bottom-right pill on bigger screens; under health on phones
	if w.shells then
		local shellsPill = UiKit.new("Frame", {
			Name = "ShellsPill",
			BackgroundColor3 = GLASS.bg,
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -12, 1, -16),
			Size = UDim2.fromOffset(0, 50),
			AutomaticSize = Enum.AutomaticSize.X,
		}, hudRoot)
		UiKit.round(shellsPill, GLASS.radius)
		UiKit.border(shellsPill, GLASS.glow, 1.5, GLASS.glowT)
		UiKit.pad(shellsPill, 0, 6, 0, 4)
		UiKit.glassPanel(shellsPill)
		w.shells.frame.BackgroundTransparency = 1
		local s = w.shells.frame:FindFirstChildOfClass("UIStroke")
		if s then
			s.Enabled = false
		end
		w.shellsPill = shellsPill
	end

	-- weapon slot at the bottom (replaces Roblox's hotbar; tap, click or press 1 to draw / stow)
	local weaponSlot = UiKit.new("TextButton", {
		Name = "WeaponSlot",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = GLASS.bg,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.fromOffset(96, 104),
		Selectable = false,
	}, hudRoot)
	UiKit.round(weaponSlot, GLASS.radius)
	w.slotStroke = UiKit.border(weaponSlot, GLASS.glow, 2, 0.15)
	UiKit.glassPanel(weaponSlot)
	weaponRow.Parent = weaponSlot
	weaponRow.Size = UDim2.fromScale(1, 1)
	weaponRow.Position = UDim2.new()
	weaponWell.AnchorPoint = Vector2.new(0.5, 0)
	weaponWell.Position = UDim2.new(0.5, 0, 0, 8)
	weaponWell.BackgroundTransparency = 1
	do
		local s = weaponWell:FindFirstChildOfClass("UIStroke")
		if s then
			s.Enabled = false
		end
		local lip = weaponWell:FindFirstChild("Lip")
		if lip then
			lip.Visible = false
		end
	end
	w.weaponName.TextWrapped = true
	w.weaponName.TextTruncate = Enum.TextTruncate.None
	w.weaponName.TextXAlignment = Enum.TextXAlignment.Center
	w.weaponName.TextYAlignment = Enum.TextYAlignment.Center
	w.weaponName.LineHeight = 0.95
	w.weaponState.Visible = false
	w.cooldownTrack.AnchorPoint = Vector2.new(0, 1)
	w.cooldownTrack.Position = UDim2.new(0, 12, 1, -5)
	w.cooldownTrack.Size = UDim2.new(1, -24, 0, 3)
	w.slotKey = UiKit.new("TextLabel", {
		Name = "SlotKey",
		BackgroundTransparency = 1,
		FontFace = F.Numeric,
		TextSize = 15,
		TextColor3 = GLASS.text,
		Text = "1",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -7, 0, 4),
		Size = UDim2.fromOffset(14, 16),
	}, weaponSlot)
	w.weaponSlot = weaponSlot

	return w
end

return Build
