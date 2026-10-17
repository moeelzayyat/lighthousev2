--!strict
-- UiKit · Tiles (S2.5c, D-041/D-042): the menu pattern "grid + detail pane" from ART_BIBLE *Menu pattern*, in the
-- Bold look. A self-contained module on the current UiKit (screens require it next to UiKit; S5.5-style folding
-- into Primitives/Dialogs comes later).
--
--   local menu = Tiles.Menu({ name, displayOrder, title, onClose })
--   menu:setResources({ { kind = "Pearls", amount = 12 } })      -- header: icon + number, Pearls first
--   menu:setTabs({ { id, label } }, selectedId, onChange)          -- optional row of big category buttons
--   menu:setTiles(list, selectedId)                                 -- see TILE below; locked tiles group under dividers
--   menu:setDetail(detail)                                          -- see DETAIL below
--   menu:open() / menu:close() / menu:pop(id) / menu.isOpen / menu.onSelect(id) (set by the screen)
--
-- TILE   { id, name, icon = itemId | function(holder), cost = { kind, amount }?, affordable, qty, owned, ownedText,
--          locked = "NEEDS ..."?, lockedIcon = kind? }
-- DETAIL { icon = itemId | function(holder), name, description, stats = { { label, from?, to?, better?, value? } },
--          cost = { kind, amount, affordable }?, extra = function(container, unit)?,
--          action = { text, enabled, reason, onPress, variant? }, action2 = same? }
--
-- Sizes are reference units at 1920x1080; a UIScale = clamp(viewportY / 1080, 0.55, 1) maps them to the device.
-- Every tap target is at least 56 device pixels (sizes grow on small screens when the scale would shrink them).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Client = script.Parent.Parent
local UiKit = require(Client:WaitForChild("UiKit"))
local ItemPreview = require(Client:WaitForChild("ItemPreview"))
local SoundFx = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundFx"))

local C, F = UiKit.Color, UiKit.Font
local Skin = UiKit.Skin
local style = (Skin and Skin.style) or {}
local OUTLINE = style.outline or C.BorderStructural
local player = Players.LocalPlayer

local Tiles = {}

local REF_H = 1080
local MIN_TAP = 56 -- device pixels
local TILE = {
	normal = Color3.fromRGB(28, 34, 52),
	stroke = Color3.fromRGB(70, 80, 110),
	selected = Color3.fromRGB(255, 214, 0),
	hover = Color3.fromRGB(140, 160, 210),
	owned = Color3.fromRGB(190, 150, 30),
	short = Color3.fromRGB(230, 70, 70),
	gold = Color3.fromRGB(255, 230, 80),
}
local ACTION = {
	go = { face = Color3.fromRGB(120, 220, 60), edge = Color3.fromRGB(70, 150, 30), text = Color3.fromRGB(255, 255, 255) },
	robux = { face = Color3.fromRGB(255, 194, 61), edge = Color3.fromRGB(179, 123, 12), text = Color3.fromRGB(42, 21, 0) },
	off = { face = Color3.fromRGB(90, 90, 100), edge = Color3.fromRGB(58, 58, 66), text = Color3.fromRGB(235, 235, 240) },
}
local SIMULATE = { smallPhone = Vector2.new(667, 375), largePhone = Vector2.new(926, 428), tablet = Vector2.new(1180, 820), laptop = Vector2.new(1366, 768), pc = Vector2.new(1920, 1080) }

local function new(className: string, props: { [string]: any }, parent: Instance?): any
	local inst: any = Instance.new(className)
	for k, v in props do
		inst[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end
local function corner(parent: Instance, r: number): any
	return new("UICorner", { CornerRadius = UDim.new(0, r) }, parent)
end
local function stroke(parent: Instance, thickness: number, color: Color3?, mode: Enum.ApplyStrokeMode?): any
	return new("UIStroke", { Thickness = thickness, Color = color or OUTLINE, ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border }, parent)
end
local function textOutline(label: Instance, thickness: number?): any
	return stroke(label, thickness or 2.5, OUTLINE, Enum.ApplyStrokeMode.Contextual)
end
-- one line, measured down from maxSize until it fits (TextScaled would break a long word in two); cap() lowers the start
local function fitOneLine(text: any, maxSize: number, minSize: number, cap: (() -> number?)?): () -> number
	local function fit(): number
		local size = math.min(maxSize, (if cap then cap() else nil) or maxSize)
		text.TextSize = size
		while size > minSize and text.AbsoluteSize.X > 0 and not text.TextFits do
			size -= 1
			text.TextSize = size
		end
		return size
	end
	text:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	text:GetPropertyChangedSignal("Text"):Connect(fit)
	return fit
end
local function label(parent: Instance, props: { [string]: any }): any
	local base: { [string]: any } = { BackgroundTransparency = 1, FontFace = F.Body, TextColor3 = C.TextPrimary, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center }
	for k, v in props do
		base[k] = v
	end
	return new("TextLabel", base, parent)
end
local function icon(holder: Instance, spec: any): any
	if typeof(spec) == "function" then
		spec(holder)
	elseif type(spec) == "string" then
		local preview = ItemPreview.new(holder, { backdrop = false })
		preview:setItem(spec)
		return preview
	end
	return nil
end

-- a big button: a face over a darker bottom edge, label in Luckiest Guy uppercase; presses down 0.96 for 0.06 s
local function bigButton(parent: Instance, name: string): any
	local b = new("TextButton", { Name = name, Text = "", AutoButtonColor = false, BackgroundTransparency = 1 }, parent)
	local edge = new("Frame", { Name = "Edge", BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(0, 8) }, b)
	local face = new("Frame", { Name = "Face", BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, b)
	local r = corner(edge, 28)
	corner(face, 28)
	stroke(edge, 4)
	stroke(face, 4)
	local shine = new("Frame", { Name = "Shine", BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.82, Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0.36, 0) }, face)
	corner(shine, 20)
	-- one line, measured down from 48 until it fits (TextScaled would break a long word in two)
	local text = label(face, { Name = "Label", FontFace = F.Display, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), TextSize = 48, TextWrapped = false })
	new("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18), PaddingTop = UDim.new(0.18, 0), PaddingBottom = UDim.new(0.18, 0) }, text)
	local capSize: number? = nil
	local fitLabel = fitOneLine(text, 48, 12, function()
		return capSize
	end)
	local textStroke = textOutline(text, 2.5)
	local scale = new("UIScale", {}, b)
	UiKit.focusable(b)
	b.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.06), { Scale = 0.96 }):Play()
	end)
	b.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.06), { Scale = 1 }):Play()
	end)
	b.MouseLeave:Connect(function()
		scale.Scale = 1
	end)
	local self: any = { button = b, face = face, edge = edge, text = text, corner = r }
	-- fit(cap): refit the label no bigger than cap (a row of tabs shares one size); returns the size used
	function self.fit(cap: number?): number
		capSize = cap
		return fitLabel()
	end
	function self.paint(spec: any, labelText: string?)
		face.BackgroundColor3 = spec.face
		edge.BackgroundColor3 = spec.edge
		text.TextColor3 = spec.text
		-- dark text (on the gold face) reads without the dark outline; light text keeps it
		local c = spec.text :: Color3
		textStroke.Transparency = if 0.3 * c.R + 0.59 * c.G + 0.11 * c.B < 0.4 then 1 else 0
		text.Text = string.upper(labelText or text.Text)
	end
	return self
end
Tiles.bigButton = bigButton

-- a UiKit glyph centred in an icon holder: 64 on a tile, half the holder in the detail pane (which resizes it)
function Tiles.glyph(holder: Instance, kind: string, color: Color3): any
	local g = UiKit.Glyph(holder, kind, color, 64)
	g.AnchorPoint = Vector2.new(0.5, 0.5)
	g.Position = UDim2.fromScale(0.5, 0.5)
	local s = new("UIScale", {}, g)
	local function fit()
		s.Scale = math.max(1, (holder :: any).Size.X.Offset * 0.5 / 64)
	end
	holder:GetPropertyChangedSignal("Size"):Connect(fit)
	fit()
	return g
end

function Tiles.Menu(opts: any): any
	local menu: any = { isOpen = false, tiles = {}, selected = nil }

	local gui = UiKit.Screen(opts.name, opts.displayOrder or 20, true)
	gui.Enabled = false
	local scrim = new("TextButton", { Name = "Scrim", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, Size = UDim2.fromScale(1, 1), Selectable = false }, gui)
	local host = new("Frame", { Name = "Host", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, gui)
	local root = new("Frame", { Name = "Root", BackgroundTransparency = 1 }, host)
	local uiScale = new("UIScale", {}, root)
	menu.gui, menu.root, menu.host = gui, root, host

	local panel = new("Frame", { Name = "Panel", BackgroundColor3 = style.panel or C.SurfacePrimary, AnchorPoint = Vector2.new(0.5, 0) }, root)
	corner(panel, 24)
	stroke(panel, 5)
	local panelScale = new("UIScale", {}, panel)
	menu.panel = panel

	-- header strip: title | resources | huge red close (overlapping the corner)
	local header = new("Frame", { Name = "Header", BackgroundColor3 = style.header or C.SurfaceElevated, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 72) }, panel)
	corner(header, 24)
	new("Frame", { Name = "SquareEdge", BackgroundColor3 = header.BackgroundColor3, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 24) }, header)
	local title = label(header, { Name = "Title", Text = string.upper(opts.title or ""), FontFace = F.Display, TextSize = 40, TextColor3 = style.title or C.AccentLighthouse, Position = UDim2.fromOffset(28, 0), Size = UDim2.new(0.34, 0, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
	textOutline(title, 3)
	local resources = new("Frame", { Name = "Resources", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X }, header)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 56), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, resources)
	local subtitle = label(header, { Name = "Subtitle", Text = "", FontFace = F.BodyBold, TextSize = 24, TextColor3 = C.TextSecondary, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -150, 0, 6), Size = UDim2.new(0.3, -150, 1, -12), TextWrapped = true, TextScaled = true })
	new("UITextSizeConstraint", { MaxTextSize = 24, MinTextSize = 14 }, subtitle)
	menu.subtitle = subtitle

	local close = new("TextButton", { Name = "Close", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(220, 40, 40), AnchorPoint = Vector2.new(1, 0), ZIndex = 10 }, panel)
	corner(close, 24)
	stroke(close, 5)
	local x = label(close, { Name = "X", Text = "X", FontFace = F.Display, TextSize = 48, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 11 })
	textOutline(x, 3)
	UiKit.focusable(close)
	menu.closeButton = close

	-- body: tabs + grid on the left, the detail pane on the right
	local left = new("Frame", { Name = "GridColumn", BackgroundTransparency = 1 }, panel)
	local tabsRow = new("Frame", { Name = "Tabs", BackgroundTransparency = 1, Visible = false }, left)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, tabsRow)
	local grid = new("ScrollingFrame", { Name = "Grid", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 10, ScrollBarImageColor3 = C.TextSecondary, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Selectable = false }, left)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 20), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
	new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 18), PaddingBottom = UDim.new(0, 12) }, grid)
	menu.grid = grid

	local pane = new("Frame", { Name = "DetailPane", BackgroundColor3 = Color3.fromRGB(12, 26, 40), BackgroundTransparency = 0 }, panel)
	corner(pane, 20)
	stroke(pane, 4)
	local paneScroll = new("ScrollingFrame", { Name = "Info", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Selectable = false }, pane)
	local paneList = new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, paneScroll)
	new("UIPadding", { PaddingTop = UDim.new(0, 16), PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 22), PaddingBottom = UDim.new(0, 10) }, paneScroll)
	local bigIcon = new("Frame", { Name = "Icon", BackgroundTransparency = 1, LayoutOrder = 1, ClipsDescendants = true }, paneScroll)
	-- the big icon gives up height first so the cost stays in view above the button (never below 120; then it scrolls)
	local maxIcon = 320
	local function fitIcon()
		local k = uiScale.Scale * panelScale.Scale -- reference units -> screen pixels
		if k <= 0 or paneScroll.AbsoluteSize.Y <= 0 then
			return
		end
		local rest = paneList.AbsoluteContentSize.Y - bigIcon.Size.Y.Offset * k
		local size = math.clamp(math.floor((paneScroll.AbsoluteSize.Y - rest) / k) - 26, if menu.unit and menu.unit.phone then 72 else 120, maxIcon) -- (unit is declared below)
		if size ~= bigIcon.Size.Y.Offset then
			bigIcon.Size = UDim2.fromOffset(size, size)
		end
	end
	paneList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fitIcon)
	paneScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitIcon)
	local dName = label(paneScroll, { Name = "ItemName", FontFace = F.Display, TextSize = 44, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 52), TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Center })
	fitOneLine(dName, 44, 16)
	textOutline(dName, 3)
	local dDesc = label(paneScroll, { Name = "Description", FontFace = F.BodyBold, TextSize = 28, TextColor3 = TILE.gold, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center })
	new("UITextSizeConstraint", { MaxTextSize = 28 }, dDesc)
	local statsBox = new("Frame", { Name = "Stats", BackgroundTransparency = 1, LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, paneScroll)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, statsBox)
	local costRow = new("Frame", { Name = "Cost", BackgroundTransparency = 1, LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 64) }, paneScroll)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center }, costRow)
	local extra = new("Frame", { Name = "Extra", BackgroundTransparency = 1, LayoutOrder = 6, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, paneScroll)
	local actions = new("Frame", { Name = "Actions", BackgroundTransparency = 1 }, pane)
	local action2 = bigButton(actions, "Action2")
	local action = bigButton(actions, "Action")
	menu.action, menu.action2, menu.pane = action, action2, pane

	local unit: any = { tile = 180, cols = 5, button = 112, close = 96, icon = 320, tab = 72, phone = false }
	menu.unit = unit
	local current: any = { detail = nil, tabs = nil, list = nil }
	local tipFrame: any = nil -- one toast at a time
	local function toast(text: string)
		if tipFrame then
			tipFrame:Destroy()
		end
		tipFrame = new("TextLabel", {
			Name = "Reason",
			BackgroundColor3 = Color3.fromRGB(40, 20, 20),
			Text = text,
			FontFace = F.BodyBold,
			TextSize = 28,
			TextColor3 = Color3.new(1, 1, 1),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -16),
			Size = UDim2.new(0.9, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true,
			ZIndex = 20,
		}, pane)
		corner(tipFrame, 14)
		stroke(tipFrame, 3, Color3.fromRGB(230, 70, 70))
		new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, tipFrame)
		local mine = tipFrame
		task.delay(2.5, function()
			if mine.Parent then
				mine:Destroy()
			end
		end)
	end
	menu.toast = toast

	---------------------------------------------------------------- alerts
	-- What is critical right now (the storm doesn't pause while a menu is open): pills under the header,
	-- red for danger, amber for a warning. { { text, level } }; an empty list hides the row.
	local alertsRow = new("Frame", { Name = "Alerts", BackgroundTransparency = 1, Visible = false }, panel)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, alertsRow)
	local alertKey = ""
	function menu:setAlerts(list: { any }?)
		local items = list or {}
		local parts = {}
		for _, a in items do
			table.insert(parts, tostring(a.level) .. ":" .. tostring(a.text))
		end
		local key = table.concat(parts, "|")
		if key == alertKey then
			return
		end
		local relayout = (key == "") ~= (alertKey == "")
		alertKey = key
		for _, c in alertsRow:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		for i, a in items do
			local danger = a.level == "danger"
			local pill = label(alertsRow, { Name = "Alert" .. i, Text = string.upper(tostring(a.text)), FontFace = F.Display, TextSize = 26, TextColor3 = if danger then Color3.new(1, 1, 1) else Color3.fromRGB(42, 21, 0), BackgroundTransparency = 0, BackgroundColor3 = if danger then Color3.fromRGB(220, 40, 40) else Color3.fromRGB(255, 194, 61), Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = i })
			corner(pill, 14)
			stroke(pill, 3)
			new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, pill)
		end
		alertsRow.Visible = #items > 0
		if relayout then
			menu:layout()
		end
	end

	---------------------------------------------------------------- resources
	local resourceWidgets: { any } = {}
	function menu:setResources(list: { any })
		for _, w in resourceWidgets do
			w:Destroy()
		end
		table.clear(resourceWidgets)
		for i, r in list do
			local pair = new("Frame", { Name = r.kind, BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 56), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = i }, resources)
			new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center }, pair)
			UiKit.CurrencyIcon(pair, r.kind, 48).LayoutOrder = 1
			local n = label(pair, { Name = "Amount", Text = tostring(r.amount), FontFace = F.Display, TextSize = 36, Size = UDim2.fromOffset(0, 48), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2 })
			textOutline(n, 2.5)
			table.insert(resourceWidgets, pair)
		end
	end

	---------------------------------------------------------------- tabs
	local tabButtons: { [string]: any } = {}
	function menu:setTabs(items: { any }?, selectedId: string?, onChange: any)
		current.tabs = { items = items, selected = selectedId, onChange = onChange }
		for _, t in tabButtons do
			t.button:Destroy()
		end
		table.clear(tabButtons)
		tabsRow.Visible = items ~= nil and #items > 0
		for i, item in items or {} do
			local b = bigButton(tabsRow, "Tab_" .. item.id)
			b.button.LayoutOrder = i
			b.text.Text = string.upper(item.label)
			b.paint(if item.id == selectedId then ACTION.robux else { face = Color3.fromRGB(36, 73, 110), edge = Color3.fromRGB(19, 40, 61), text = Color3.new(1, 1, 1) })
			b.button.Activated:Connect(function()
				if current.tabs.selected ~= item.id then
					SoundFx.play2D("click")
					current.tabs.selected = item.id
					menu:setTabs(items, item.id, onChange)
					onChange(item.id)
				end
			end)
			tabButtons[item.id] = b
		end
		menu:layout()
	end

	---------------------------------------------------------------- tiles
	local blocks: { any } = {}
	local function makeTile(parent: Instance, t: any, order: number): any
		local tile = new("TextButton", { Name = "Tile_" .. tostring(t.id), Text = "", AutoButtonColor = false, BackgroundColor3 = TILE.normal, LayoutOrder = order }, parent)
		corner(tile, 20)
		local s = stroke(tile, 2, TILE.stroke)
		local glow = new("UIStroke", { Name = "Glow", Thickness = 8, Color = TILE.selected, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, new("Frame", { Name = "GlowRing", BackgroundTransparency = 1, Size = UDim2.new(1, 4, 1, 4), Position = UDim2.fromOffset(-2, -2) }, tile))
		local tScale = new("UIScale", {}, tile)
		if t.owned then
			local fill = new("Frame", { Name = "OwnedFill", BackgroundColor3 = TILE.owned, BackgroundTransparency = 0.6, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, tile)
			corner(fill, 20)
		end
		-- phone tiles are small on screen: a smaller icon, a bigger name
		local phoneTile = unit.phone == true
		local holder = new("Frame", { Name = "Icon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.05, 0), Size = UDim2.fromScale(if phoneTile then 0.38 else 0.46, if phoneTile then 0.38 else 0.46), ClipsDescendants = true }, tile)
		local preview = icon(holder, t.icon)
		-- the whole name, on up to two lines (shrinks before it would cut off)
		local name = label(tile, { Name = "ItemName", Text = t.name or "", FontFace = F.BodyBold, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, if phoneTile then 0.44 else 0.52, 0), Size = UDim2.new(1, -10, if phoneTile then 0.36 else 0.28, 0), TextWrapped = true, TextScaled = true, LineHeight = 0.9 })
		new("UITextSizeConstraint", { MaxTextSize = if phoneTile then 18 else 24, MinTextSize = 12 }, name) -- screen pixels (TextScaled)
		textOutline(name, 2)
		local costRowT = new("Frame", { Name = "Cost", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.81, 0), Size = UDim2.new(1, -14, 0.15, 0) }, tile)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center }, costRowT)
		if t.owned then
			label(costRowT, { Text = "\u{2713} " .. string.upper(t.ownedText or "OWNED"), FontFace = F.Display, TextSize = 26, TextColor3 = TILE.gold, Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X })
		elseif t.cost then
			UiKit.CurrencyIcon(costRowT, t.cost.kind, 28).LayoutOrder = 1
			local n = label(costRowT, { Text = tostring(t.cost.amount), FontFace = F.Display, TextSize = 28, TextColor3 = if t.affordable == false then TILE.short else Color3.new(1, 1, 1), Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2 })
			textOutline(n, 2)
		end
		for i, c2 in t.cost2 and { t.cost2 } or {} do
			local n = label(costRowT, { Text = c2, FontFace = F.Display, TextSize = 24, TextColor3 = Color3.fromRGB(120, 220, 60), Size = UDim2.fromOffset(0, 30), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 10 + i })
			textOutline(n, 2)
		end
		if t.qty then
			local badge = label(tile, { Name = "Qty", Text = "\u{00D7}" .. tostring(t.qty), FontFace = F.Display, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(36, 73, 110), Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(36, 36), ZIndex = 3 })
			corner(badge, 18)
			stroke(badge, 2)
		end
		if t.locked then
			tile.BackgroundTransparency = 0.35
			s.Transparency = 0.65
			name.TextTransparency = 0.65
			for _, d in costRowT:GetDescendants() do
				if d:IsA("TextLabel") then
					d.TextTransparency = 0.45
				end
			end
			if preview and preview.viewport then
				preview.viewport.ImageColor3 = Color3.fromRGB(110, 110, 110)
				preview.viewport.ImageTransparency = 0.65
			end
			for _, d in holder:GetDescendants() do
				if d:IsA("GuiObject") and not d:IsA("ViewportFrame") then
					d.BackgroundTransparency = math.max(d.BackgroundTransparency, 0.65)
				end
			end
		end
		local entry: any = { tile = tile, stroke = s, glow = glow, scale = tScale, data = t }
		local function paint()
			local selected = menu.selected == t.id
			s.Color = if selected then TILE.selected else TILE.stroke
			s.Thickness = if selected then 4 else 2
			glow.Transparency = if selected then 0.55 else 1
			TweenService:Create(tScale, TweenInfo.new(0.08), { Scale = if selected and not t.locked then 1.04 else 1 }):Play()
		end
		entry.paint = paint
		if not unit.phone then
			tile.MouseEnter:Connect(function()
				if menu.selected ~= t.id and not t.locked then
					s.Color = TILE.hover
				end
			end)
			tile.MouseLeave:Connect(paint)
		end
		tile.Activated:Connect(function()
			SoundFx.play2D("click", 1.3)
			menu:select(t.id)
		end)
		UiKit.focusable(tile)
		paint()
		menu.tiles[t.id] = entry
		return entry
	end

	-- a purchase pops its tile; the grid is often rebuilt right after (new data), so the pop also plays on the
	-- rebuilt tile for a moment
	local popId: string?, popAt = nil, 0
	local function applyPop()
		local e = popId and menu.tiles[popId]
		if e and os.clock() - popAt < 1.5 then
			e.scale.Scale = 1.1
			TweenService:Create(e.scale, TweenInfo.new(0.15), { Scale = if menu.selected == popId then 1.04 else 1 }):Play()
		end
	end
	function menu:pop(id: string)
		popId, popAt = id, os.clock()
		applyPop()
	end

	local function gridBlock(order: number): any
		local block = new("Frame", { Name = "Block" .. order, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order }, grid)
		new("UIGridLayout", { Name = "Layout", CellPadding = UDim2.fromOffset(20, 20), CellSize = UDim2.fromOffset(unit.tile, unit.tile), SortOrder = Enum.SortOrder.LayoutOrder }, block)
		table.insert(blocks, block)
		return block
	end

	function menu:setTiles(list: { any }, selectedId: string?)
		current.list = list
		for _, b in blocks do
			b:Destroy()
		end
		table.clear(blocks)
		table.clear(menu.tiles)
		-- unlocked tiles first, then one divider per lock reason with its tiles under it
		local open: { any }, lockedBy: { [string]: { any } }, reasons: { string } = {}, {}, {}
		for _, t in list do
			if t.locked then
				if not lockedBy[t.locked] then
					lockedBy[t.locked] = {}
					table.insert(reasons, t.locked)
				end
				table.insert(lockedBy[t.locked], t)
			else
				table.insert(open, t)
			end
		end
		local order = 1
		if #open > 0 then
			local block = gridBlock(order)
			for i, t in open do
				makeTile(block, t, i)
			end
			order += 1
		end
		for _, reason in reasons do
			local divider = new("Frame", { Name = "Divider", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 56), LayoutOrder = order }, grid)
			table.insert(blocks, divider)
			new("Frame", { Name = "Line", BackgroundColor3 = TILE.gold, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 4) }, divider)
			local d = label(divider, { Name = "Reason", Text = string.upper(reason), FontFace = F.Display, TextSize = 32, TextColor3 = TILE.gold, Size = UDim2.new(1, 0, 1, -6), TextTruncate = Enum.TextTruncate.AtEnd })
			textOutline(d, 2.5)
			order += 1
			local block = gridBlock(order)
			for i, t in lockedBy[reason] do
				makeTile(block, t, i)
			end
			order += 1
		end
		if selectedId and menu.tiles[selectedId] then
			menu.selected = selectedId
		elseif not (menu.selected and menu.tiles[menu.selected]) then
			menu.selected = list[1] and list[1].id
		end
		for _, e in menu.tiles do
			e.paint()
		end
		menu:layout()
		applyPop()
	end

	function menu:select(id: string?)
		menu.selected = id
		for _, e in menu.tiles do
			e.paint()
		end
		if menu.onSelect then
			menu.onSelect(id)
		end
	end

	---------------------------------------------------------------- detail pane
	local paneParts: { any } = {}
	local actionHandlers: { [string]: any } = {}
	local function wireAction(b: any, spec: any, key: string)
		actionHandlers[key] = spec
		if not spec then
			b.button.Visible = false
			return
		end
		b.button.Visible = true
		b.paint(if spec.enabled then (ACTION[spec.variant or "go"] or ACTION.go) else ACTION.off, spec.text)
	end
	action.button.Activated:Connect(function()
		local spec = actionHandlers.action
		if not spec then
			return
		end
		if not spec.enabled then
			SoundFx.play2D("denied")
			if spec.reason then
				toast(spec.reason)
			end
			return
		end
		spec.onPress()
	end)
	action2.button.Activated:Connect(function()
		local spec = actionHandlers.action2
		if not spec then
			return
		end
		if not spec.enabled then
			SoundFx.play2D("denied")
			if spec.reason then
				toast(spec.reason)
			end
			return
		end
		spec.onPress()
	end)

	function menu:setDetail(detail: any)
		current.detail = detail
		for _, w in paneParts do
			w:Destroy()
		end
		table.clear(paneParts)
		for _, c in bigIcon:GetChildren() do
			c:Destroy()
		end
		if not detail then
			dName.Text = ""
			dDesc.Text = ""
			wireAction(action, nil, "action")
			wireAction(action2, nil, "action2")
			return
		end
		icon(bigIcon, detail.icon)
		dName.Text = string.upper(detail.name or "")
		dDesc.Text = detail.description or ""
		for i, st in detail.stats or {} do
			local row = new("Frame", { Name = "Stat" .. i, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = i }, statsBox)
			table.insert(paneParts, row)
			fitOneLine(label(row, { Text = st.label, FontFace = F.BodyBold, TextSize = 28, Size = UDim2.new(0.5, 0, 1, 0), TextColor3 = C.TextSecondary }), 28, 14)
			local value
			if st.to ~= nil then
				local arrowColor = if st.better == nil then Color3.new(1, 1, 1) elseif st.better then Color3.fromRGB(120, 220, 60) else Color3.fromRGB(230, 70, 70)
				local hexColor = string.format("#%02X%02X%02X", arrowColor.R * 255, arrowColor.G * 255, arrowColor.B * 255)
				value = string.format("%s <font color=\"%s\">\u{2192} %s</font>", tostring(st.from), hexColor, tostring(st.to))
			else
				value = tostring(st.value or "")
			end
			fitOneLine(label(row, { Text = value, RichText = true, FontFace = F.Display, TextSize = 28, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.5, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Right }), 28, 14)
		end
		if detail.cost then
			local ic = UiKit.CurrencyIcon(costRow, detail.cost.kind, 56)
			ic.LayoutOrder = 1
			table.insert(paneParts, ic)
			local n = label(costRow, { Text = tostring(detail.cost.amount), FontFace = F.Display, TextSize = 48, TextColor3 = if detail.cost.affordable == false then TILE.short else Color3.new(1, 1, 1), Size = UDim2.fromOffset(0, 56), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2 })
			textOutline(n, 3)
			table.insert(paneParts, n)
		end
		costRow.Visible = detail.cost ~= nil
		for _, c in extra:GetChildren() do
			if not c:IsA("UIBase") then
				c:Destroy()
			end
		end
		if detail.extra then
			detail.extra(extra, unit)
		end
		wireAction(action, detail.action, "action")
		wireAction(action2, detail.action2, "action2")
		menu:layout()
	end

	---------------------------------------------------------------- layout
	local function viewport()
		local spec = SIMULATE[player:GetAttribute("HudSimulate") or ""]
		if RunService:IsStudio() and spec then
			return spec, true
		end
		local cam = Workspace.CurrentCamera
		return (cam and cam.ViewportSize) or Vector2.new(1920, 1080), false
	end

	function menu:layout()
		local vp, simulated = viewport()
		local scale = math.clamp(vp.Y / REF_H, 0.55, 1)
		local W, H = vp.X / scale, vp.Y / scale
		uiScale.Scale = scale
		root.Size = UDim2.fromOffset(W, H)
		root.AnchorPoint = Vector2.new(0.5, 0.5)
		root.Position = UDim2.fromScale(0.5, 0.5)
		if simulated then
			host.Size = UDim2.fromOffset(vp.X, vp.Y)
			host.AnchorPoint = Vector2.new(0.5, 0.5)
			host.Position = UDim2.fromScale(0.5, 0.5)
		else
			host.Size = UDim2.fromScale(1, 1)
			host.AnchorPoint = Vector2.zero
			host.Position = UDim2.new()
		end
		local minRef = math.ceil(MIN_TAP / scale) -- 56 device pixels in reference units
		local phone = vp.X < 1000
		unit.phone = phone
		unit.cols = if phone then 3 else 5
		unit.button = math.max(if phone then 96 else 112, minRef)
		unit.close = math.max(if phone then 80 else 96, minRef)
		unit.tab = math.max(64, minRef)
		unit.icon = if phone then 200 else 320
		unit.min = minRef

		-- the panel: centred, its bottom at least 120 above the screen bottom on bigger screens (the hotbar stays visible)
		local pw = if phone then math.floor(W * 0.96) else math.min(1560, W - 64)
		local ph = if phone then math.floor(H * 0.94) else math.min(900, H - 120 - 40)
		panel.Size = UDim2.fromOffset(pw, ph)
		panel.Position = UDim2.new(0.5, 0, 0, if phone then math.floor((H - ph) / 2) else math.max(24, H - 120 - ph))
		local headerH = 72
		header.Size = UDim2.new(1, 0, 0, headerH)
		close.Size = UDim2.fromOffset(unit.close, unit.close)
		close.Position = UDim2.new(1, 24, 0, -24)
		subtitle.Visible = not phone
		title.Size = UDim2.new(if phone then 0.3 else 0.34, 0, 1, 0)

		local pad = 24
		local alertsH = if alertsRow.Visible then 52 else 0
		alertsRow.Position = UDim2.fromOffset(pad, headerH + 12)
		alertsRow.Size = UDim2.new(1, -pad * 2, 0, 40)
		local bodyTop = headerH + 20 + alertsH
		local bodyH = ph - bodyTop - pad
		local paneW = math.floor(pw * (if phone then 0.36 else 0.38))
		local leftW = pw - paneW - pad * 3
		left.Position = UDim2.fromOffset(pad, bodyTop)
		left.Size = UDim2.fromOffset(leftW, bodyH)
		local tabsH = if tabsRow.Visible then unit.tab + 14 else 0
		tabsRow.Size = UDim2.new(1, 0, 0, unit.tab + 10)
		local count = 0
		for _ in tabButtons do
			count += 1
		end
		for _, t in tabButtons do
			t.button.Size = UDim2.fromOffset(math.floor((leftW - 14 * (count - 1)) / count), unit.tab)
			local tabPad = t.text:FindFirstChildOfClass("UIPadding")
			if tabPad then -- narrow phone tabs: the word gets the room
				tabPad.PaddingLeft, tabPad.PaddingRight = UDim.new(0, if phone then 6 else 18), UDim.new(0, if phone then 6 else 18)
			end
		end
		task.defer(function() -- one text size for the whole row: the longest word decides
			local common = 48
			for _, t in tabButtons do
				common = math.min(common, t.fit(nil))
			end
			for _, t in tabButtons do
				t.fit(common)
			end
		end)
		grid.Position = UDim2.fromOffset(0, tabsH)
		grid.Size = UDim2.new(1, 0, 1, -tabsH)

		-- tiles: 180 (PC) / 150 (phone), never more columns than fit
		local tileSize = if phone then 150 else 180
		local usable = leftW - 8 - 18 - 10
		local cols = math.max(1, math.min(unit.cols, math.floor((usable + 20) / (tileSize + 20))))
		if cols < unit.cols then
			tileSize = math.max(math.floor((usable - 20 * (unit.cols - 1)) / unit.cols), minRef)
			cols = math.max(1, math.min(unit.cols, math.floor((usable + 20) / (tileSize + 20))))
		end
		unit.tile = tileSize
		for _, b in blocks do
			local layoutObj = b:FindFirstChild("Layout")
			if layoutObj then
				layoutObj.CellSize = UDim2.fromOffset(tileSize, tileSize)
			end
		end

		pane.Position = UDim2.fromOffset(pw - pad - paneW, bodyTop)
		pane.Size = UDim2.fromOffset(paneW, bodyH)
		local hasSecond = actionHandlers.action2 ~= nil
		local actionsH = unit.button + 8 + (if hasSecond then unit.button + 14 else 0)
		actions.Position = UDim2.new(0, 18, 1, -actionsH - 18)
		actions.Size = UDim2.new(1, -36, 0, actionsH)
		action2.button.Size = UDim2.new(1, 0, 0, unit.button)
		action2.button.Position = UDim2.fromOffset(0, 0)
		action.button.Size = UDim2.new(1, 0, 0, unit.button)
		action.button.Position = UDim2.fromOffset(0, if hasSecond then unit.button + 14 else 0)
		paneScroll.Size = UDim2.new(1, 0, 1, -actionsH - 26)
		maxIcon = math.min(unit.icon, paneW - 44)
		bigIcon.Size = UDim2.fromOffset(maxIcon, maxIcon)
		task.defer(fitIcon)
	end

	---------------------------------------------------------------- open / close
	local function doClose()
		if opts.onClose then
			opts.onClose()
		end
	end
	close.Activated:Connect(function()
		SoundFx.play2D("click", 0.8)
		doClose()
	end)
	scrim.Activated:Connect(doClose)

	function menu:open()
		if menu.isOpen then
			return
		end
		menu.isOpen = true
		gui.Enabled = true
		menu:layout()
		SoundFx.play2D("click")
		panelScale.Scale = 0.92
		TweenService:Create(panelScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		scrim.BackgroundTransparency = 1
		TweenService:Create(scrim, TweenInfo.new(0.12), { BackgroundTransparency = 0.55 }):Play()
	end
	function menu:close()
		if not menu.isOpen then
			return
		end
		menu.isOpen = false
		gui.Enabled = false
	end

	-- a new screen size can change the minimum tap size: the detail's extras (built from unit) are rebuilt then
	local function relayout()
		if not menu.isOpen then
			return
		end
		local before, wasPhone = unit.min, unit.phone
		menu:layout()
		if unit.phone ~= wasPhone and current.list then
			menu:setTiles(current.list, menu.selected)
		end
		if unit.min ~= before and current.detail then
			menu:setDetail(current.detail)
		end
	end
	local cam = Workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(relayout)
	end
	player:GetAttributeChangedSignal("HudSimulate"):Connect(relayout)
	return menu
end

-- Smallest tap target in a menu, in device pixels (for checkpoint checks)
function Tiles.smallestTap(menu: any): (number, string?)
	local smallest, which: string? = math.huge, nil
	for _, d in menu.gui:GetDescendants() do
		if d:IsA("GuiButton") and d.Visible and d.Name ~= "Scrim" and d.AbsoluteSize.X > 0 then
			local m = math.min(d.AbsoluteSize.X, d.AbsoluteSize.Y)
			if m < smallest then
				smallest, which = m, d:GetFullName()
			end
		end
	end
	return smallest, which
end

return Tiles
