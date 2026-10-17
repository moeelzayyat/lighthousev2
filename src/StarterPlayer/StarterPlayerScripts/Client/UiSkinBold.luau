-- UiSkinBold (client, harbor UI, Look A "Bold"): the chunky cartoon skin, switched on by Config.UI_SKIN = "bold".
-- Deep navy panels with thick dark outlines, big rounded corners, "3D" buttons (a darker copy sits a few pixels
-- below the face), Luckiest Guy for titles and buttons and Fredoka One for everything else, and five display-only
-- rarity colours. Like the pirate skin it only restyles what UiKit builds: layouts and behaviour are untouched,
-- and nothing built in the glass variant (the in-voyage HUD) is touched.

local Bold = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- the look's tokens (screens read these through UiKit.Skin.style)
local S = {
	name = "bold",
	outline = rgb(7, 17, 27), -- #07111B
	panel = rgb(22, 48, 74), -- #16304A
	header = rgb(29, 61, 94), -- #1D3D5E
	card = rgb(16, 37, 57), -- #102539
	inset = rgb(12, 28, 44),
	muted = rgb(185, 210, 234), -- #B9D2EA
	title = rgb(255, 194, 61), -- amber titles
	panelRadius = 22,
	cardRadius = 18,
	buttonRadius = 14,
	stroke = 4,
	depth = 6, -- how far the darker copy sits below a button
	rarity = {
		Common = rgb(138, 160, 180), -- #8AA0B4
		Uncommon = rgb(79, 201, 122), -- #4FC97A
		Rare = rgb(74, 163, 255), -- #4AA3FF
		Epic = rgb(176, 113, 255), -- #B071FF
		Legendary = rgb(255, 176, 46), -- #FFB02E
	},
	buttons = {
		primary = { face = rgb(255, 194, 61), shadow = rgb(179, 123, 12), text = rgb(42, 21, 0) }, -- amber
		buy = { face = rgb(62, 207, 110), shadow = rgb(26, 127, 62), text = rgb(255, 255, 255), stroke = true }, -- green
		danger = { face = rgb(229, 83, 61), shadow = rgb(143, 38, 23), text = rgb(255, 255, 255), stroke = true }, -- red
		secondary = { face = rgb(36, 73, 110), shadow = rgb(19, 40, 61), text = rgb(255, 255, 255), stroke = true }, -- idle tab
		disabled = { face = rgb(52, 70, 90), shadow = rgb(28, 40, 54), text = rgb(140, 160, 180) },
	},
}
Bold.style = S

function Bold.fonts()
	local luckiest = Font.fromEnum(Enum.Font.LuckiestGuy)
	local fredoka = Font.fromEnum(Enum.Font.FredokaOne)
	return luckiest, fredoka
end

-- Recolour the shared tokens and swap the fonts (runs before any UI is built)
function Bold.remap(Color, Fonts)
	Color.SurfaceBase = rgb(11, 26, 41)
	Color.SurfacePrimary = S.panel
	Color.SurfaceSecondary = S.card
	Color.SurfaceElevated = S.header
	Color.SurfaceHover = rgb(36, 73, 110)
	Color.SurfaceInset = S.inset
	Color.Scrim = rgb(4, 10, 18)
	Color.BorderStructural = S.outline
	Color.BorderBrassBright = S.title
	Color.BorderSubtle = rgb(36, 73, 110)
	Color.BorderSelected = rgb(255, 255, 255)
	Color.BorderFocus = rgb(255, 255, 255)
	Color.TextPrimary = rgb(255, 255, 255)
	Color.TextSecondary = S.muted
	Color.TextMuted = rgb(140, 170, 198)
	Color.TextOnAccent = rgb(42, 21, 0)
	Color.AccentLighthouse = S.title
	Color.AccentLighthouseDeep = rgb(179, 123, 12)
	Color.AccentLighthouseSoft = rgb(255, 214, 120)
	Color.StateSuccess = rgb(62, 207, 110)
	Color.StateDanger = rgb(229, 83, 61)
	Color.StateWarning = rgb(255, 154, 61)
	Color.StateDisabled = rgb(44, 64, 86)
	Color.StateDisabledText = rgb(140, 160, 180)
	local luckiest, fredoka = Bold.fonts()
	Fonts.Display = luckiest
	Fonts.Heading = luckiest
	Fonts.LabelBold = luckiest
	Fonts.Label = fredoka
	Fonts.Body = fredoka
	Fonts.BodyMedium = fredoka
	Fonts.BodyBold = fredoka
	Fonts.Numeric = fredoka
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function outline(parent, thickness, color)
	local s = parent:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = color or S.outline
	s.Thickness = thickness or S.stroke
	s.Transparency = 0
	s.Enabled = true
	s.Parent = parent
	return s
end
Bold.outline = outline
Bold.corner = corner

-- A dark text outline so white or amber text stays readable on any face (Roblox scale: about 3 px)
function Bold.textStroke(label, thickness)
	local s = Instance.new("UIStroke")
	s.Name = "TextOutline"
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Color = S.outline
	s.Thickness = thickness or 2.5
	s.Parent = label
	return s
end

local function lighten(c, t)
	return c:Lerp(Color3.new(1, 1, 1), t)
end

-- Make a TextButton a chunky 3D button. specName picks the colours; returns paint(specName) to recolour later.
local painted = setmetatable({}, { __mode = "k" })
function Bold.button(b, specName)
	if painted[b] then
		return painted[b]
	end
	local pad = b:FindFirstChildOfClass("UIPadding")
	local l = if pad then pad.PaddingLeft.Offset else 0
	local r = if pad then pad.PaddingRight.Offset else 0
	local t = if pad then pad.PaddingTop.Offset else 0
	local bt = if pad then pad.PaddingBottom.Offset else 0
	-- A button that sized itself to its text (AutomaticSize X) would keep growing around the wider face layers;
	-- size it to its text ourselves instead (never narrower than it was built)
	if b.AutomaticSize == Enum.AutomaticSize.X or b.AutomaticSize == Enum.AutomaticSize.XY then
		local minWidth = b.Size.X.Offset
		b.AutomaticSize = Enum.AutomaticSize.None
		local function fit()
			b.Size = UDim2.new(0, math.max(minWidth, math.ceil(b.TextBounds.X) + l + r), b.Size.Y.Scale, b.Size.Y.Offset)
		end
		b:GetPropertyChangedSignal("TextBounds"):Connect(fit)
		fit()
	end
	local function layer(name, z)
		local f = Instance.new("Frame")
		f.Name = name
		f.BorderSizePixel = 0
		f.Size = UDim2.new(1, l + r, 1, t + bt)
		f.Position = UDim2.fromOffset(-l, -t)
		f.ZIndex = z
		f.Active = false
		corner(f, S.buttonRadius)
		outline(f, 3)
		f.Parent = b
		return f
	end
	local shadow = layer("BoldShadow", -6)
	shadow.Position = UDim2.fromOffset(-l, -t + S.depth)
	local face = layer("BoldFace", -5)
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.BorderSizePixel = 0
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.82
	shine.Position = UDim2.fromOffset(5, 3)
	shine.Size = UDim2.new(1, -10, 0.38, 0)
	shine.ZIndex = -4
	corner(shine, S.buttonRadius - 4)
	shine.Parent = face
	b.BackgroundTransparency = 1
	b:SetAttribute("GhostButton", nil)
	local stroke = b:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Enabled = false
	end
	local glass = b:FindFirstChild("Glass")
	if glass then
		glass.Enabled = false
	end

	-- the text is drawn above the face (children always draw over their parent)
	local text = Instance.new("TextLabel")
	text.Name = "BoldText"
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.ZIndex = 3
	text.Parent = b
	local textOutline = Bold.textStroke(text, 2)
	-- long labels shrink until they fit the face (never larger than the button's own text size)
	local function fitText()
		local size = b.TextSize
		text.TextSize = size
		local width = text.AbsoluteSize.X
		while width > 0 and size > 10 and text.TextBounds.X > width do
			size -= 1
			text.TextSize = size
		end
	end
	text:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitText)

	local current = specName
	local hovered, down = false, false
	local function sync()
		local spec = S.buttons[if b:GetAttribute("Disabled") then "disabled" else current] or S.buttons.secondary
		text.Text = b.Text
		text.FontFace = b.FontFace
		text.TextWrapped = b.TextWrapped
		text.RichText = b.RichText
		text.TextXAlignment = b.TextXAlignment
		text.TextTruncate = b.TextTruncate
		fitText()
		text.TextColor3 = spec.text
		textOutline.Enabled = spec.stroke == true
		face.BackgroundColor3 = if hovered and not b:GetAttribute("Disabled") then lighten(spec.face, 0.12) else spec.face
		shadow.BackgroundColor3 = spec.shadow
		local press = if down and not b:GetAttribute("Disabled") then S.depth - 2 else 0
		face.Position = UDim2.fromOffset(-l, -t + press)
		text.Position = UDim2.fromOffset(0, press)
	end
	for _, p in { "Text", "FontFace", "TextSize", "TextScaled", "TextWrapped", "RichText", "TextXAlignment" } do
		b:GetPropertyChangedSignal(p):Connect(sync)
	end
	b:GetAttributeChangedSignal("Disabled"):Connect(sync)
	b.TextTransparency = 1
	b.MouseEnter:Connect(function()
		hovered = true
		sync()
	end)
	b.MouseLeave:Connect(function()
		hovered, down = false, false
		sync()
	end)
	b.MouseButton1Down:Connect(function()
		down = true
		sync()
	end)
	b.MouseButton1Up:Connect(function()
		down = false
		sync()
	end)
	local function paint(name)
		current = name
		sync()
	end
	painted[b] = paint
	sync()
	return paint
end

local HIDE = { Brackets = true, Beacon = true, Tick = true, LensArc = true, Lamp = true }

-- A panel: navy fill, thick dark outline, big corners; the instrument details are hidden
function Bold.panel(panel)
	local kind = panel:GetAttribute("PanelKind")
	local c = panel:FindFirstChildOfClass("UICorner")
	if c then
		c.CornerRadius = UDim.new(0, if kind == "plain" then S.cardRadius else S.panelRadius)
	end
	outline(panel, if kind == "plain" then 3 else 5)
	local grad = panel:FindFirstChildOfClass("UIGradient")
	if grad then
		grad.Enabled = false
	end
	for _, child in panel:GetChildren() do
		if HIDE[child.Name] then
			child.Visible = false
		end
	end
end

-- Wrap UiKit constructors (called once, at the end of UiKit)
function Bold.install(UiKit)
	UiKit.Radius.panel = S.panelRadius
	UiKit.Radius.card = 12
	UiKit.Radius.control = 12

	local Panel = UiKit.Panel
	UiKit.Panel = function(parent, opts)
		local panel, content, header = Panel(parent, opts)
		if not UiKit.isGlass() then
			Bold.panel(panel)
		end
		return panel, content, header
	end

	local Button = UiKit.Button
	UiKit.Button = function(parent, text, opts)
		local b = Button(parent, text, opts)
		local variant = b:GetAttribute("Variant")
		if not UiKit.isGlass() and S.buttons[variant] then
			Bold.button(b, variant)
		end
		return b
	end

	local IconButton = UiKit.IconButton
	UiKit.IconButton = function(parent, glyph, opts)
		local b = IconButton(parent, glyph, opts)
		if UiKit.isGlass() then
			return b
		end
		if glyph == "close" then
			Bold.button(b, "danger")
			local g = b:FindFirstChildWhichIsA("GuiObject")
			if g and g.Name ~= "BoldShadow" then
				g.ZIndex = 4
			end
			for _, child in b:GetChildren() do
				if child:IsA("GuiObject") and not string.find(child.Name, "^Bold") then
					child.ZIndex = 4
				end
			end
		elseif not (opts and opts.quiet) then
			Bold.button(b, "secondary")
			for _, child in b:GetChildren() do
				if child:IsA("GuiObject") and not string.find(child.Name, "^Bold") then
					child.ZIndex = 4
				end
			end
		end
		return b
	end

	-- tabs: chunky blocks, amber when selected, navy when idle
	local Tabs = UiKit.Tabs
	UiKit.Tabs = function(parent, items, opts)
		local self = Tabs(parent, items, opts)
		if UiKit.isGlass() then
			return self
		end
		local rule = self.frame:FindFirstChild("Rule")
		if rule then
			rule.Visible = false
		end
		local paints = {}
		for id, t in self.buttons do
			t.underline.BackgroundTransparency = 1
			paints[id] = Bold.button(t.button, "secondary")
		end
		local set = self.set
		function self.set(id, silent)
			set(id, silent)
			for tabId, paint in paints do
				paint(if tabId == id then "primary" else "secondary")
			end
		end
		self.set(self.selected, true)
		return self
	end
end

return Bold
