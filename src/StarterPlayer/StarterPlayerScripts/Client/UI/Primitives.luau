-- UiKit · Primitives (S5.5): basic helpers (new, tween, numbers, click sound), focus ring, modals, text, glyphs, structure (panels, insets, sections).
-- Moved unchanged from UiKit; screens still require UiKit, which loads the parts in order. The design rules
-- are at the top of UiKit.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputController = require(script.Parent.Parent:WaitForChild("InputController")) -- S2.6: the shared input mode

local Kit = require(script.Parent:WaitForChild("Kit"))
local UiKit, K = Kit.UiKit, Kit.K
local rgb = K.rgb
local Color = K.Color
local Fonts = K.Fonts
local Type = K.Type

---------------------------------------------------------------------
-- GLASS VARIANT (S5.6): the in-game HUD's night-navy glass, drawn when an element is built. Between
-- UiKit.beginGlass() and UiKit.endGlass(), or inside UiKit.Glass(fn), surfaces the art skin warmed go back
-- to their navy originals, brass outlines become the blue glow, and buttons get glass bodies instead of
-- the wood art. Builders that recolour later read UiKit.palette(), captured when they were built.
---------------------------------------------------------------------

local GLASS = {
	bg = rgb(12, 20, 40),
	bgT = 0.18,
	glow = rgb(104, 156, 255),
	glowT = 0.45,
	text = rgb(240, 244, 255),
	hover = rgb(30, 48, 88),
	heart = rgb(255, 76, 110),
	danger = rgb(255, 70, 104),
	dangerBg = rgb(58, 12, 30),
	chip = rgb(26, 52, 110),
	radius = 14,
}
UiKit.GLASS = GLASS

local function colorKey(c)
	return string.format("%d,%d,%d", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local NAVY = {} -- warm skin colour -> its navy original
local GlassColor = setmetatable({}, { __index = Color })
for _, token in { "SurfaceBase", "SurfacePrimary", "SurfaceSecondary", "SurfaceElevated", "SurfaceHover", "SurfaceInset", "BorderSubtle", "StateDisabled" } do
	NAVY[colorKey(Color[token])] = K.BaseColor[token]
	GlassColor[token] = K.BaseColor[token]
end
local BRASS = colorKey(Color.BorderStructural)

local glassDepth = 0
function UiKit.beginGlass()
	glassDepth += 1
end
function UiKit.endGlass()
	glassDepth = math.max(0, glassDepth - 1)
end
function UiKit.isGlass()
	return glassDepth > 0
end
-- Builds inside fn in the glass variant; returns what fn returns
function UiKit.Glass(fn)
	glassDepth += 1
	local results = table.pack(pcall(fn))
	glassDepth -= 1
	if not results[1] then
		error(results[2], 0)
	end
	return table.unpack(results, 2, results.n)
end
-- The colour tokens a builder should use now (the glass palette inside a glass build)
function UiKit.palette()
	return if glassDepth > 0 then GlassColor else Color
end

local function glassify(inst)
	if inst:IsA("GuiObject") then
		local navy = NAVY[colorKey(inst.BackgroundColor3)]
		if navy then
			inst.BackgroundColor3 = navy
		end
	elseif inst:IsA("UIStroke") and colorKey(inst.Color) == BRASS then
		inst.Color = GLASS.glow
	end
end

-- A HUD panel in glass: navy body, rounder corners, the glow outline (keepStroke: leave the outline as is)
-- and a soft top-lit sheen
function UiKit.glassPanel(frame, keepStroke)
	frame.BackgroundColor3 = GLASS.bg
	frame.BackgroundTransparency = GLASS.bgT
	local corner = frame:FindFirstChildOfClass("UICorner") or UiKit.round(frame, GLASS.radius)
	corner.CornerRadius = UDim.new(0, GLASS.radius)
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if stroke and not keepStroke then
		stroke.Color = GLASS.glow
		stroke.Transparency = GLASS.glowT
		stroke.Thickness = 1.5
	end
	if not frame:FindFirstChild("GlassSheen") then
		UiKit.new("UIGradient", {
			Name = "GlassSheen",
			Rotation = 90,
			Color = ColorSequence.new(Color3.new(1, 1, 1), rgb(150, 164, 196)),
		}, frame)
	end
	return frame
end

---------------------------------------------------------------------
-- BASIC HELPERS
---------------------------------------------------------------------

local function new(className, props, parent)
	local inst = Instance.new(className)
	if props then
		for key, value in props do
			inst[key] = value
		end
	end
	if glassDepth > 0 then
		glassify(inst)
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end
UiKit.new = new

local function apply(inst, props)
	if props then
		for key, value in props do
			inst[key] = value
		end
	end
	if glassDepth > 0 then
		glassify(inst)
	end
	return inst
end

local function tween(obj, time, props, style)
	local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end
UiKit.tween = tween

function UiKit.round(parent, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or UiKit.Radius.card) }, parent)
end

function UiKit.border(parent, color, thickness, transparency)
	return new("UIStroke", {
		Color = color or Color.BorderSubtle,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

function UiKit.pad(parent, top, right, bottom, left)
	right = right or top
	bottom = bottom or top
	left = left or right
	return new("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right),
		PaddingBottom = UDim.new(0, bottom),
		PaddingLeft = UDim.new(0, left),
	}, parent)
end

function UiKit.list(parent, direction, gap, props)
	return apply(new("UIListLayout", {
		FillDirection = if direction == "x" then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		Padding = UDim.new(0, gap or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, parent), props)
end

local function formatNumber(n)
	local s = tostring(math.floor(n or 0))
	local negative = s:sub(1, 1) == "-"
	if negative then
		s = s:sub(2)
	end
	local result = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if result:sub(1, 1) == "," then
		result = result:sub(2)
	end
	return (if negative then "-" else "") .. result
end
UiKit.formatNumber = formatNumber

-- Width reserved for a number so counters don't jitter as digits change
local function numberWidth(text, size)
	local _, commas = text:gsub(",", "")
	return math.ceil((#text - commas) * size * 0.6 + commas * size * 0.3) + 2
end
UiKit.numberWidth = numberWidth

local function isShown(gui)
	local node = gui
	while node do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		end
		if node:IsA("LayerCollector") then
			return node.Enabled
		end
		node = node.Parent
	end
	return false
end
UiKit.isShown = isShown

local SoundFx
local function click()
	if SoundFx == nil then
		local ok, mod = pcall(function()
			return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundFx"))
		end)
		SoundFx = if ok then mod else false
	end
	if SoundFx then
		pcall(SoundFx.play2D, "click")
	end
end
UiKit.click = click

local function usingGamepad()
	return InputController.usingGamepad()
end
UiKit.usingGamepad = usingGamepad

-- "phone" | "tablet" | "desktop" for a screen or container size (defaults to the camera)
function UiKit.Breakpoint(size)
	size = size or workspace.CurrentCamera.ViewportSize
	if size.X < 760 or size.Y < 500 then -- landscape phones are at most ~430 px tall
		return "phone"
	elseif size.X < 1180 or size.Y < 700 then
		return "tablet"
	end
	return "desktop"
end

-- fullBleed = true covers the whole screen (backdrops, cinematic screens)
function UiKit.Screen(name, displayOrder, fullBleed)
	return new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = displayOrder or 10,
		ScreenInsets = if fullBleed then Enum.ScreenInsets.None else Enum.ScreenInsets.CoreUISafeInsets,
	}, Players.LocalPlayer:WaitForChild("PlayerGui"))
end

-- Reserved corners on touch screens while gameplay controls are visible (thumbstick, jump).
-- HUD elements must stay out of these; menus hide the touch controls instead (see pushModal).
UiKit.TOUCH_RESERVED = {
	bottomLeft = Vector2.new(260, 220),
	bottomRight = Vector2.new(220, 220),
}

---------------------------------------------------------------------
-- FOCUS (controller / keyboard). Ivory double-spaced ring, distinct from gold selection.
---------------------------------------------------------------------

local focusRing = new("Frame", {
	Name = "FocusRing",
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 12, 1, 12),
	Position = UDim2.fromOffset(-6, -6),
})
UiKit.round(focusRing, UiKit.Radius.panel + 2)
UiKit.border(focusRing, Color.BorderFocus, 2.5)
UiKit.FocusRing = focusRing

function UiKit.focusable(obj)
	obj.Selectable = true
	obj.SelectionImageObject = focusRing
	return obj
end

---------------------------------------------------------------------
-- MODALS: MenuOpen attribute for gameplay scripts; touch controls hide while a menu is open
---------------------------------------------------------------------

local openModals = {}
local function refreshModal()
	local anyOpen = next(openModals) ~= nil
	Players.LocalPlayer:SetAttribute("MenuOpen", anyOpen)
	pcall(function()
		-- batch 1 (GP-43): closing a menu must not bring the joystick back while this player is the Keeper
		local gameState = game:GetService("ReplicatedStorage"):FindFirstChild("GameState")
		local isKeeper = gameState ~= nil and gameState:GetAttribute("KeeperUserId") == Players.LocalPlayer.UserId
		GuiService.TouchControlsEnabled = not anyOpen and not isKeeper
	end)
end
function UiKit.pushModal(name)
	openModals[name] = true
	refreshModal()
end
function UiKit.popModal(name)
	openModals[name] = nil
	refreshModal()
end

---------------------------------------------------------------------
-- TEXT
---------------------------------------------------------------------

function UiKit.Label(parent, text, styleName, props)
	local style = Type[styleName or "Body"] or Type.Body
	local label = new("TextLabel", {
		Name = styleName or "Body",
		BackgroundTransparency = 1,
		FontFace = Fonts[style.font],
		TextSize = style.size,
		TextColor3 = Color[style.color or "TextPrimary"],
		Text = if style.upper then string.upper(text) else text,
		TextWrapped = true,
		RichText = true,
		LineHeight = style.lineHeight or 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, parent)
	return apply(label, props)
end

---------------------------------------------------------------------
-- GLYPHS (drawn, no image uploads)
-- close, back, next, plus, minus, check, alert, warning, info, diamond, lock, heart, lamp, tower
---------------------------------------------------------------------

function UiKit.Glyph(parent, kind, color, size)
	size = size or 18
	color = color or Color.TextPrimary
	local box = new("Frame", { Name = "Glyph", BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size) }, parent)
	box:SetAttribute("Kind", kind)
	local thick = math.max(2, math.floor(size / 8 + 0.5))
	local function bar(length, rotation, x, y)
		local b = new("Frame", {
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(length, thick),
			Position = UDim2.fromScale(x or 0.5, y or 0.5),
			Rotation = rotation,
		}, box)
		UiKit.round(b, thick)
		return b
	end
	local function block(w, h, x, y, radius, rotation)
		local b = new("Frame", {
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(w, h),
			Position = UDim2.fromScale(x, y),
			Rotation = rotation or 0,
		}, box)
		if radius then
			UiKit.round(b, radius)
		end
		return b
	end
	local function dot(x, y, d)
		local b = new("Frame", {
			BackgroundColor3 = color,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromOffset(d, d),
		}, box)
		UiKit.round(b, d)
		return b
	end
	if kind == "close" then
		bar(size * 1.15, 45)
		bar(size * 1.15, -45)
	elseif kind == "plus" then
		bar(size, 0)
		bar(size, 90)
	elseif kind == "minus" then
		bar(size, 0)
	elseif kind == "back" then
		bar(size * 0.62, -45, 0.42, 0.31)
		bar(size * 0.62, 45, 0.42, 0.69)
	elseif kind == "next" then
		bar(size * 0.62, 45, 0.58, 0.31)
		bar(size * 0.62, -45, 0.58, 0.69)
	elseif kind == "check" then
		bar(size * 0.45, 45, 0.3, 0.6)
		bar(size * 0.85, -50, 0.6, 0.46)
	elseif kind == "alert" then
		bar(size * 0.55, 90, 0.5, 0.36)
		dot(0.5, 0.86, thick + 1)
	elseif kind == "info" then
		dot(0.5, 0.16, thick + 1)
		bar(size * 0.55, 90, 0.5, 0.64)
	elseif kind == "warning" then
		local d = new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.7, 0.7),
			Rotation = 45,
		}, box)
		UiKit.round(d, 2)
		UiKit.border(d, color, math.max(1.5, thick * 0.75))
		bar(size * 0.3, 90, 0.5, 0.43)
		dot(0.5, 0.68, thick)
	elseif kind == "diamond" then
		block(0.6, 0.6, 0.5, 0.5, nil, 45)
	elseif kind == "lock" then
		local body = block(0.8, 0.55, 0.5, 0.72, 2)
		body.AnchorPoint = Vector2.new(0.5, 0.5)
		local hoop = new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.fromScale(0.56, 0.7),
		}, box)
		UiKit.round(hoop, size)
		UiKit.border(hoop, color, thick)
	elseif kind == "heart" then
		dot(0.31, 0.37, math.floor(size * 0.52))
		dot(0.69, 0.37, math.floor(size * 0.52))
		block(0.52, 0.52, 0.5, 0.56, 2, 45)
	elseif kind == "lamp" then
		-- a beacon: lens ring with a lit core, beams reaching out to both sides
		local ring = new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.46, 0.46),
		}, box)
		UiKit.round(ring, size)
		UiKit.border(ring, color, math.max(1.5, thick * 0.8))
		dot(0.5, 0.5, math.floor(size * 0.2))
		for _, side in { -1, 1 } do
			bar(size * 0.2, 0, 0.5 + side * 0.4, 0.5)
			bar(size * 0.16, side * 30, 0.5 + side * 0.36, 0.24)
			bar(size * 0.16, side * -30, 0.5 + side * 0.36, 0.76)
		end
	elseif kind == "tower" then
		block(0.5, 0.56, 0.5, 0.7)
		block(0.68, 0.08, 0.5, 0.4)
		block(0.32, 0.2, 0.5, 0.26)
		block(0.46, 0.08, 0.5, 0.12)
	end
	return box
end

function UiKit.SetGlyphColor(glyph, color)
	for _, d in glyph:GetDescendants() do
		if d:IsA("Frame") and d.BackgroundTransparency < 1 then
			d.BackgroundColor3 = color
		elseif d:IsA("UIStroke") then
			d.Color = color
		end
	end
end

local function pearlIcon(parent, size)
	local p = new("Frame", { Name = "PearlIcon", BackgroundColor3 = Color.Pearl, Size = UDim2.fromOffset(size, size) }, parent)
	UiKit.round(p, size)
	new("UIGradient", { Rotation = 45, Color = ColorSequence.new(Color3.new(1, 1, 1), rgb(160, 150, 196)) }, p)
	UiKit.border(p, rgb(110, 100, 140), 1, 0.4)
	local glint = new("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.fromOffset(math.max(3, size * 0.26), math.max(3, size * 0.26)),
		Position = UDim2.fromScale(0.22, 0.18),
	}, p)
	UiKit.round(glint, size)
	return p
end

local function shellIcon(parent, size)
	local holder = new("Frame", { Name = "ShellIcon", BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size) }, parent)
	local clipHeight = math.floor(size * 0.66)
	local clip = new("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = UDim2.fromOffset(size, clipHeight),
		Position = UDim2.fromOffset(0, math.floor(size * 0.08)),
	}, holder)
	local fan = new("Frame", { BackgroundColor3 = Color.Shell, Size = UDim2.fromOffset(size, size) }, clip)
	UiKit.round(fan, size)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), rgb(200, 170, 150)) }, fan)
	local ribLength = clipHeight * 0.85
	for _, angle in { -40, -14, 14, 40 } do
		local r = math.rad(angle)
		new("Frame", {
			BackgroundColor3 = rgb(150, 96, 60),
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(math.max(1, size / 14), ribLength),
			Position = UDim2.fromOffset(size / 2 + math.sin(r) * ribLength / 2, clipHeight - math.cos(r) * ribLength / 2),
			Rotation = angle,
		}, clip)
	end
	local hinge = new("Frame", {
		BackgroundColor3 = rgb(196, 130, 86),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(math.floor(size * 0.4), math.max(3, math.floor(size * 0.2))),
		Position = UDim2.new(0.5, 0, 0, math.floor(size * 0.08) + clipHeight - 1),
	}, holder)
	UiKit.round(hinge, 2)
	return holder
end

function UiKit.CurrencyIcon(parent, kind, size)
	if kind == "Pearls" then
		return pearlIcon(parent, size or 18)
	end
	return shellIcon(parent, size or 18)
end

---------------------------------------------------------------------
-- STRUCTURE
---------------------------------------------------------------------

-- Instrument corner brackets (L-shapes). inset < 0 draws them outside the parent.
function UiKit.Brackets(parent, color, arm, thick, inset)
	arm = arm or 12
	thick = thick or 2
	inset = inset or 0
	local holder = new("Frame", {
		Name = "Brackets",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -inset * 2, 1, -inset * 2),
		Position = UDim2.fromOffset(inset, inset),
		ZIndex = 4,
	}, parent)
	for _, c in { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } } do
		local anchor = Vector2.new(c[1], c[2])
		new("Frame", {
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			AnchorPoint = anchor,
			Position = UDim2.fromScale(c[1], c[2]),
			Size = UDim2.fromOffset(arm, thick),
			ZIndex = 4,
		}, holder)
		new("Frame", {
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			AnchorPoint = anchor,
			Position = UDim2.fromScale(c[1], c[2]),
			Size = UDim2.fromOffset(thick, arm),
			ZIndex = 4,
		}, holder)
	end
	return holder
end

-- The beacon line: lamp light fading along the top edge, with brass gauge ticks beneath
local function beacon(panel)
	local beam = new("Frame", {
		Name = "Beacon",
		BackgroundColor3 = Color.AccentLighthouse,
		BorderSizePixel = 0,
		Size = UDim2.new(0.5, 0, 0, 2),
		Position = UDim2.fromOffset(22, 0),
		ZIndex = 3,
	}, panel)
	new("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
	}, beam)
	for i = 0, 12 do
		new("Frame", {
			Name = "Tick",
			BackgroundColor3 = Color.BorderBrassBright,
			BackgroundTransparency = math.min(0.92, 0.3 + i * 0.05),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(22 + i * 10, 2),
			Size = UDim2.fromOffset(1, if i % 4 == 0 then 6 else 3),
			ZIndex = 3,
		}, panel)
	end
end

-- The lens arc: a shallow brass dome rising from a dialog's top edge, with the lamp at its heart
local function lensArc(panel, color)
	local clip = new("Frame", {
		Name = "LensArc",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, 1),
		Size = UDim2.fromOffset(84, 16),
		ZIndex = 3,
	}, panel)
	local disc = new("Frame", { BackgroundColor3 = Color.SurfacePrimary, Size = UDim2.fromOffset(84, 84), ZIndex = 3 }, clip)
	UiKit.round(disc, 42)
	UiKit.border(disc, color or Color.BorderStructural, 1.5)
	local lamp = new("Frame", {
		Name = "Lamp",
		BackgroundColor3 = color or Color.AccentLighthouse,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, -4),
		Size = UDim2.fromOffset(7, 7),
		ZIndex = 4,
	}, panel)
	UiKit.round(lamp, 4)
	return clip
end

-- A panel.
--   kind: "housing" (menus, default) | "dialog" (decisions) | "plain" (a quiet sub-area)
--   variant: surface color "primary" | "secondary" | "elevated"
--   beam: beacon line on top (housing only, main menu panel only)
--   eyebrow / title / titleStyle, onClose, compact (phones: one header line)
-- Returns panel, content, header.
function UiKit.Panel(parent, opts)
	opts = table.clone(opts or {})
	if opts.compact then
		opts.eyebrow = nil
		opts.titleStyle = "H3"
		opts.padding = opts.padding or UiKit.Space.md
	end
	local kind = opts.kind or (if opts.brass == false then "plain" else "housing")
	local background = ({
		primary = Color.SurfacePrimary,
		secondary = Color.SurfaceSecondary,
		elevated = Color.SurfaceElevated,
	})[opts.variant or (if kind == "plain" then "secondary" else "primary")]
	local panel = new("Frame", {
		Name = opts.name or "Panel",
		BackgroundColor3 = background,
		BorderSizePixel = 0,
		Size = opts.size or UDim2.fromOffset(480, 320),
		Position = opts.position or UDim2.new(),
		AnchorPoint = opts.anchor or Vector2.zero,
		LayoutOrder = opts.layoutOrder or 0,
	}, parent)
	panel:SetAttribute("PanelKind", kind)
	UiKit.round(panel, opts.radius or UiKit.Radius.panel)
	if kind ~= "plain" then
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), rgb(196, 202, 212)) }, panel)
	end
	if kind == "housing" then
		UiKit.border(panel, Color.BorderStructural, 1, 0.45)
		UiKit.Brackets(panel, Color.BorderBrassBright, 14, 2, 0)
		if opts.beam then
			beacon(panel)
		end
	elseif kind == "dialog" then
		UiKit.border(panel, opts.frameColor or Color.BorderStructural, 1.5, 0.2)
		lensArc(panel, opts.frameColor)
	end

	local pad = opts.padding or UiKit.Space.xl
	local header
	local headerHeight = opts.headerHeight or 0
	if opts.title or opts.eyebrow then
		header = new("Frame", {
			Name = "Header",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -pad * 2 - (if opts.onClose then 52 else 0), 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Position = UDim2.fromOffset(pad, pad - 2),
		}, panel)
		UiKit.list(header, "y", 2)
		if opts.eyebrow then
			UiKit.Label(header, opts.eyebrow, "Eyebrow", { LayoutOrder = 1 })
		end
		if opts.title then
			UiKit.Label(header, opts.title, opts.titleStyle or "H1", { LayoutOrder = 2 })
		end
		if not opts.headerHeight then
			local titleSize = if opts.title then Type[opts.titleStyle or "H1"].size + 8 else 0
			headerHeight = (if opts.eyebrow then 19 else 0) + titleSize + (if opts.compact then UiKit.Space.sm else UiKit.Space.lg)
		end
	end
	if opts.onClose then
		local close = UiKit.IconButton(panel, "close", { name = "Close", quiet = true, onClick = opts.onClose })
		close.AnchorPoint = Vector2.new(1, 0)
		close.Position = if opts.compact then UDim2.new(1, -4, 0, 4) else UDim2.new(1, -pad + 10, 0, pad - 12)
		close.ZIndex = 5
	end
	local content = new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(pad, pad + headerHeight),
		Size = UDim2.new(1, -pad * 2, 1, -pad * 2 - headerHeight),
	}, panel)
	return panel, content, header
end

-- A recessed instrument face: no border, a hairline shadow under its top edge
function UiKit.Inset(parent, props)
	local f = new("Frame", { Name = "Inset", BackgroundColor3 = Color.SurfaceInset, BorderSizePixel = 0 }, parent)
	UiKit.round(f, UiKit.Radius.card)
	new("Frame", {
		Name = "Lip",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(3, 0),
		Size = UDim2.new(1, -6, 0, 1),
		ZIndex = 2,
	}, f)
	return apply(f, props)
end

-- A group without a box: label, then a brass rule running to a small diamond.
-- Children go straight into the returned frame (LayoutOrder 1+).
function UiKit.Section(parent, title, opts)
	opts = opts or {}
	local s = new("Frame", {
		Name = opts.name or title,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = opts.layoutOrder or 0,
	}, parent)
	UiKit.list(s, "y", opts.gap or 12)
	local head = new("Frame", { Name = "SectionHead", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 0 }, s)
	local label = UiKit.Label(head, title, "Eyebrow", {
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		TextWrapped = false,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	local rule = new("Frame", {
		Name = "Rule",
		BackgroundColor3 = Color.BorderStructural,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(1, 0, 0, 1),
	}, head)
	local tip = new("Frame", {
		BackgroundColor3 = Color.BorderStructural,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(5, 5),
		Rotation = 45,
	}, head)
	local function layout()
		local w = label.AbsoluteSize.X + 12
		rule.Position = UDim2.new(0, w, 0.5, 0)
		rule.Size = UDim2.new(1, -w - 8, 0, 1)
	end
	label:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	layout()
	_ = tip
	return s
end

function UiKit.Divider(parent, props)
	local d = new("Frame", { Name = "Divider", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 12) }, parent)
	for _, side in { 0, 1 } do
		new("Frame", {
			BackgroundColor3 = Color.BorderStructural,
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(side, 0.5),
			Position = UDim2.fromScale(side, 0.5),
			Size = UDim2.new(0.5, -9, 0, 1),
		}, d)
	end
	new("Frame", {
		BackgroundColor3 = Color.BorderBrassBright,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(6, 6),
		Rotation = 45,
	}, d)
	return apply(d, props)
end

function UiKit.Scroll(parent, props)
	local s = new("ScrollingFrame", {
		Name = "Scroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Color.BorderStructural,
		ScrollBarImageTransparency = 0.15,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		Selectable = false,
	}, parent)
	return apply(s, props)
end

K.new = new
K.tween = tween
K.formatNumber = formatNumber
K.numberWidth = numberWidth
K.isShown = isShown
K.click = click
K.usingGamepad = usingGamepad
K.focusRing = focusRing

return true
