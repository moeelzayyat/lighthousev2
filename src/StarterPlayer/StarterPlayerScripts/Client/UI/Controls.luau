-- UiKit · Controls (S5.5): buttons, tooltip, input hints, tabs, settings controls, display (currency, tags, badges), item card.
-- Moved unchanged from UiKit; screens still require UiKit, which loads the parts in order. The design rules
-- are at the top of UiKit.

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local InputController = require(script.Parent.Parent:WaitForChild("InputController")) -- S2.6: the shared input mode

local Kit = require(script.Parent:WaitForChild("Kit"))
local UiKit, K = Kit.UiKit, Kit.K
local rgb = K.rgb
local Color = K.Color
local Fonts = K.Fonts
local Type = K.Type
local new = K.new
local tween = K.tween
local formatNumber = K.formatNumber
local numberWidth = K.numberWidth
local isShown = K.isShown
local click = K.click
local focusRing = K.focusRing

---------------------------------------------------------------------
-- BUTTONS
---------------------------------------------------------------------

local BUTTON_SIZES = { lg = { 56, 22 }, md = { 48, 19 }, sm = { 44, 17 } }
local BUTTON_VARIANTS = {
	primary = { bg = Color.AccentLighthouse, hover = Color.AccentLighthouseSoft, text = Color.TextOnAccent, stroke = Color.AccentLighthouseDeep, glass = true },
	secondary = { bg = Color.SurfaceElevated, hover = Color.SurfaceHover, text = Color.TextPrimary, stroke = Color.BorderStructural },
	ghost = { bg = Color.SurfaceSecondary, hover = Color.SurfaceSecondary, text = Color.TextSecondary, transparent = true },
	danger = { bg = rgb(56, 30, 32), hover = rgb(76, 38, 38), text = Color.StateDanger, stroke = Color.StateDanger },
}

local function attachFeedback(b)
	local scale = new("UIScale", { Name = "PressScale" }, b)
	b.MouseEnter:Connect(function()
		if not b:GetAttribute("Disabled") and b:GetAttribute("HoverColor") then
			tween(b, UiKit.Motion.fast, { BackgroundColor3 = b:GetAttribute("HoverColor") })
			if b:GetAttribute("GhostButton") then
				b.BackgroundTransparency = 0.4
			end
		end
	end)
	b.MouseLeave:Connect(function()
		if not b:GetAttribute("Disabled") and b:GetAttribute("BaseColor") then
			tween(b, UiKit.Motion.fast, { BackgroundColor3 = b:GetAttribute("BaseColor") })
			if b:GetAttribute("GhostButton") then
				b.BackgroundTransparency = 1
			end
		end
		tween(scale, UiKit.Motion.fast, { Scale = 1 })
	end)
	b.MouseButton1Down:Connect(function()
		if not b:GetAttribute("Disabled") then
			tween(scale, 0.06, { Scale = 0.97 })
		end
	end)
	b.MouseButton1Up:Connect(function()
		tween(scale, UiKit.Motion.fast, { Scale = 1 })
	end)
end

local function wireClick(b, opts)
	b.Activated:Connect(function()
		if b:GetAttribute("Disabled") then
			if opts.onDisabledClick then
				opts.onDisabledClick(b:GetAttribute("DisabledReason"))
			end
			return
		end
		if opts.silent ~= true then
			click()
		end
		if opts.onClick then
			opts.onClick()
		end
	end)
end

-- UiKit.Button(parent, "Buy", { variant = "primary" | "secondary" | "ghost" | "danger",
--     size = "lg" | "md" | "sm", width = 220 (fixed), minWidth = 150 (grows with text), fill = true,
--     onClick, onDisabledClick(reason) })
function UiKit.Button(parent, text, opts)
	opts = opts or {}
	local v = BUTTON_VARIANTS[opts.variant or "secondary"]
	local s = BUTTON_SIZES[opts.size or "md"]
	local b = new("TextButton", {
		Name = opts.name or "Button",
		AutoButtonColor = false,
		BackgroundColor3 = v.bg,
		BackgroundTransparency = if v.transparent then 1 else 0,
		Text = string.upper(text),
		FontFace = Fonts.LabelBold,
		TextSize = s[2],
		TextColor3 = v.text,
		Size = if opts.fill then UDim2.new(1, 0, 0, s[1]) else UDim2.fromOffset(opts.width or opts.minWidth or 120, s[1]),
		AutomaticSize = if opts.fill or opts.width then Enum.AutomaticSize.None else Enum.AutomaticSize.X,
		LayoutOrder = opts.layoutOrder or 0,
	}, parent)
	UiKit.round(b, UiKit.Radius.control)
	UiKit.pad(b, 0, 20, 0, 20)
	if v.stroke then
		UiKit.border(b, v.stroke, 1, if opts.variant == "primary" then 0 else 0.2)
	end
	if v.glass then
		new("UIGradient", { Name = "Glass", Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), rgb(226, 206, 170)) }, b)
	end
	b:SetAttribute("Variant", opts.variant or "secondary")
	b:SetAttribute("BaseColor", v.bg)
	b:SetAttribute("HoverColor", v.hover)
	b:SetAttribute("BaseTextColor", v.text)
	b:SetAttribute("BaseText", b.Text)
	if v.stroke then
		b:SetAttribute("BaseStrokeColor", v.stroke)
	end
	if v.transparent then
		b:SetAttribute("GhostButton", true)
	end
	if UiKit.isGlass() then
		-- S5.6: glass body for every variant (the HUD's keeper buttons)
		local G = UiKit.GLASS
		b.BackgroundColor3 = G.bg
		b.BackgroundTransparency = G.bgT
		b.TextColor3 = G.text
		b:SetAttribute("BaseColor", G.bg)
		b:SetAttribute("HoverColor", G.hover)
		b:SetAttribute("BaseTextColor", G.text)
		b:SetAttribute("GhostButton", nil)
		b:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 12)
		local s = b:FindFirstChildOfClass("UIStroke") or UiKit.border(b, G.glow, 1.5, G.glowT)
		s.Enabled = true
		s.Color = G.glow
		s.Transparency = G.glowT
		s.Thickness = 1.5
		if v.stroke then
			b:SetAttribute("BaseStrokeColor", G.glow)
		end
	end
	UiKit.focusable(b)
	attachFeedback(b)
	wireClick(b, opts)
	return b
end

function UiKit.IconButton(parent, glyph, opts)
	opts = opts or {}
	local b = new("TextButton", {
		Name = opts.name or "IconButton",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color.SurfaceElevated,
		BackgroundTransparency = if opts.quiet then 1 else 0,
		Size = UDim2.fromOffset(UiKit.TOUCH, UiKit.TOUCH),
		LayoutOrder = opts.layoutOrder or 0,
	}, parent)
	UiKit.round(b, UiKit.Radius.control)
	if not opts.quiet then
		UiKit.border(b, Color.BorderStructural, 1, 0.3)
	end
	local g = UiKit.Glyph(b, glyph, opts.color or Color.TextPrimary, opts.glyphSize or 16)
	g.AnchorPoint = Vector2.new(0.5, 0.5)
	g.Position = UDim2.fromScale(0.5, 0.5)
	b:SetAttribute("BaseColor", Color.SurfaceElevated)
	b:SetAttribute("HoverColor", Color.SurfaceHover)
	if opts.quiet then
		b:SetAttribute("GhostButton", true)
	end
	if opts.tip then
		UiKit.Tooltip(b, opts.tip)
	end
	UiKit.focusable(b)
	attachFeedback(b)
	wireClick(b, opts)
	return b
end

-- Disabled buttons stay focusable so controller players can read WHY (tooltip on focus)
function UiKit.SetDisabled(b, disabled, reason)
	b:SetAttribute("Disabled", disabled)
	b:SetAttribute("DisabledReason", if disabled then reason else nil)
	local glass = b:FindFirstChild("Glass")
	if glass then
		glass.Enabled = not disabled
	end
	local stroke = b:FindFirstChildOfClass("UIStroke")
	if disabled then
		b.BackgroundColor3 = Color.StateDisabled
		b.TextColor3 = Color.StateDisabledText
		if b:GetAttribute("GhostButton") then
			b.BackgroundTransparency = 1
		end
		if stroke then
			stroke.Color = Color.BorderSubtle
		end
	else
		b.BackgroundColor3 = b:GetAttribute("BaseColor") or b.BackgroundColor3
		b.TextColor3 = b:GetAttribute("BaseTextColor") or b.TextColor3
		if stroke and b:GetAttribute("BaseStrokeColor") then
			stroke.Color = b:GetAttribute("BaseStrokeColor")
		end
	end
	if reason then
		UiKit.Tooltip(b)
	end
end

-- Busy state for an action in flight: disabled, label replaced, a small lamp turning beside it
function UiKit.SetBusy(b, busy, text)
	UiKit.SetDisabled(b, busy)
	local spinner = b:FindFirstChild("BusyLamp")
	if busy then
		b.Text = string.upper(text or "Working...")
		if not spinner then
			spinner = new("Frame", {
				Name = "BusyLamp",
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, -14, 0.5, 0),
				Size = UDim2.fromOffset(14, 14),
			}, b)
			local beam = new("Frame", {
				BackgroundColor3 = Color.StateDisabledText,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(0.5, 0, 0, 2),
			}, spinner)
			local core = new("Frame", {
				BackgroundColor3 = Color.StateDisabledText,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(5, 5),
			}, spinner)
			UiKit.round(core, 3)
			_ = beam
			local connection
			connection = RunService.RenderStepped:Connect(function(dt)
				if not spinner.Parent then
					connection:Disconnect()
					return
				end
				spinner.Rotation = (spinner.Rotation + dt * 300) % 360
			end)
		end
	else
		b.Text = b:GetAttribute("BaseText") or b.Text
		if spinner then
			spinner:Destroy()
		end
	end
end

-- For the style guide and tests: show a component in a fixed interaction state
-- state: "hover" | "pressed" | "focus" | "selected" | "disabled" | "loading"
function UiKit.PreviewState(b, state)
	if state == "hover" then
		b.BackgroundColor3 = b:GetAttribute("HoverColor") or b.BackgroundColor3
		if b:GetAttribute("GhostButton") then
			b.BackgroundTransparency = 0.4
		end
	elseif state == "pressed" then
		b.BackgroundColor3 = b:GetAttribute("HoverColor") or b.BackgroundColor3
		local scale = b:FindFirstChild("PressScale")
		if scale then
			scale.Scale = 0.95
		end
	elseif state == "focus" then
		local ring = focusRing:Clone()
		ring.Name = "FocusPreview"
		ring.ZIndex = 6
		local padding = b:FindFirstChildOfClass("UIPadding")
		local left = if padding then padding.PaddingLeft.Offset else 0
		local right = if padding then padding.PaddingRight.Offset else 0
		local top = if padding then padding.PaddingTop.Offset else 0
		local bottom = if padding then padding.PaddingBottom.Offset else 0
		ring.Position = UDim2.fromOffset(-6 - left, -6 - top)
		ring.Size = UDim2.new(1, 12 + left + right, 1, 12 + top + bottom)
		ring.Parent = b
	elseif state == "disabled" then
		UiKit.SetDisabled(b, true, "Example of a disabled action with its reason.")
	elseif state == "loading" then
		UiKit.SetBusy(b, true, "Saving...")
	end
end

---------------------------------------------------------------------
-- TOOLTIP (mouse hover after a short pause, or controller focus). DisabledReason wins.
---------------------------------------------------------------------

function UiKit.Tooltip(obj, text)
	if text then
		obj:SetAttribute("Tip", text)
	end
	if obj:GetAttribute("TipWired") then
		return
	end
	obj:SetAttribute("TipWired", true)
	local tip
	local token = 0
	local function hide()
		token += 1
		if tip then
			tip:Destroy()
			tip = nil
		end
	end
	local function show()
		local message = obj:GetAttribute("DisabledReason") or obj:GetAttribute("Tip")
		local gui = obj:FindFirstAncestorOfClass("ScreenGui")
		if not message or message == "" or not gui then
			return
		end
		tip = new("TextLabel", {
			Name = "Tooltip",
			BackgroundColor3 = Color.SurfaceBase,
			TextColor3 = Color.TextPrimary,
			FontFace = Fonts.BodyMedium,
			TextSize = 15,
			LineHeight = 1.1,
			Text = message,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromOffset(250, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 400,
		}, gui)
		UiKit.round(tip, UiKit.Radius.control)
		UiKit.border(tip, Color.BorderStructural, 1)
		UiKit.pad(tip, 8, 10)
		local origin = obj.AbsolutePosition - gui.AbsolutePosition
		local x = math.clamp(origin.X, 8, math.max(8, gui.AbsoluteSize.X - 258))
		local y = origin.Y + obj.AbsoluteSize.Y + 8
		if y + 64 > gui.AbsoluteSize.Y then
			y = origin.Y - 60
		end
		tip.Position = UDim2.fromOffset(x, y)
	end
	obj.MouseEnter:Connect(function()
		hide()
		local mine = token
		task.delay(0.35, function()
			if mine == token then
				show()
			end
		end)
	end)
	obj.MouseLeave:Connect(hide)
	obj.SelectionGained:Connect(function()
		hide()
		show()
	end)
	obj.SelectionLost:Connect(hide)
	obj.Destroying:Connect(hide)
end

---------------------------------------------------------------------
-- INPUT HINT: a keycap that matches the player's current input (keyboard, controller, touch)
---------------------------------------------------------------------

-- keys = { keyboard = "E", gamepad = Enum.KeyCode.ButtonX, touch = "Tap" }; opts.input forces one
function UiKit.KeyHint(parent, keys, label, opts)
	opts = opts or {}
	local frame = new("Frame", {
		Name = "KeyHint",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = opts.layoutOrder or 0,
	}, parent)
	UiKit.list(frame, "x", 8, { VerticalAlignment = Enum.VerticalAlignment.Center })
	local cap = new("Frame", {
		Name = "Keycap",
		BackgroundColor3 = Color.SurfaceElevated,
		Size = UDim2.fromOffset(32, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 1,
	}, frame)
	UiKit.round(cap, UiKit.Radius.control)
	UiKit.border(cap, Color.BorderBrassBright, 1, 0.25)
	new("Frame", {
		Name = "KeyLip",
		BackgroundColor3 = Color.SurfaceBase,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 2, 1, 0),
		Size = UDim2.new(1, -4, 0, 3),
	}, cap)
	local capText = new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = Fonts.LabelBold,
		TextSize = 16,
		TextColor3 = Color.TextPrimary,
		Size = UDim2.new(0, 32, 1, -2),
		AutomaticSize = Enum.AutomaticSize.X,
	}, cap)
	UiKit.pad(capText, 0, 8, 0, 8)
	local capImage = new("ImageLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(24, 24),
		Visible = false,
	}, cap)
	UiKit.Label(frame, label, "Body", {
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		TextWrapped = false,
		TextYAlignment = Enum.TextYAlignment.Center,
		LayoutOrder = 2,
	})
	local function mode()
		if opts.input then
			return opts.input
		end
		return InputController.mode()
	end
	local function refresh()
		local m = mode()
		capImage.Visible = false
		capText.Visible = true
		if m == "gamepad" then
			local keyCode = keys.gamepad or Enum.KeyCode.ButtonX
			local image = UserInputService:GetImageForKeyCode(keyCode)
			if image and image ~= "" then
				capImage.Image = image
				capImage.Visible = true
				capText.Text = ""
				capText.Size = UDim2.new(0, 32, 1, -2)
			else
				capText.Text = keyCode.Name:gsub("Button", "")
			end
		elseif m == "touch" then
			capText.Text = string.upper(keys.touch or "Tap")
		else
			capText.Text = string.upper(keys.keyboard or "E")
		end
	end
	refresh()
	if not opts.input then
		local connection = UserInputService.LastInputTypeChanged:Connect(refresh)
		frame.Destroying:Connect(function()
			connection:Disconnect()
		end)
	end
	return frame
end

---------------------------------------------------------------------
-- TABS (L1/R1 on a controller). Underline + ivory text marks the selected tab.
---------------------------------------------------------------------

function UiKit.Tabs(parent, items, opts)
	opts = opts or {}
	local bar = new("Frame", { Name = "Tabs", BackgroundTransparency = 1, Size = opts.size or UDim2.new(1, 0, 0, 46), LayoutOrder = opts.layoutOrder or 0 }, parent)
	new("Frame", {
		Name = "Rule",
		BackgroundColor3 = Color.BorderSubtle,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
	}, bar)
	local row = new("ScrollingFrame", {
		Name = "Row",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 0,
		Selectable = false,
	}, bar)
	UiKit.list(row, "x", opts.gap or 2)
	local tabs = {}
	local self = { frame = bar, buttons = tabs, selected = nil }

	function self.set(id, silent)
		self.selected = id
		for tabId, t in tabs do
			local on = tabId == id
			t.button.TextColor3 = if on then Color.TextPrimary else Color.TextSecondary
			t.button.BackgroundTransparency = if on then 0.55 else 1
			t.underline.Visible = on
		end
		if not silent and opts.onChange then
			opts.onChange(id)
		end
	end

	for index, item in items do
		local accent = if item.color then (Color[item.color] or item.color) else Color.AccentLighthouse
		local b = new("TextButton", {
			Name = "Tab_" .. item.id,
			AutoButtonColor = false,
			BackgroundColor3 = Color.SurfaceSecondary,
			BackgroundTransparency = 1,
			Text = string.upper(item.label),
			FontFace = Fonts.LabelBold,
			TextSize = opts.textSize or 18,
			TextColor3 = Color.TextSecondary,
			Size = UDim2.fromOffset(opts.minWidth or 84, 45),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = index,
		}, row)
		UiKit.round(b, UiKit.Radius.tag)
		UiKit.pad(b, 0, 16, 0, 16)
		local underline = new("Frame", {
			Name = "Underline",
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 3),
			Position = UDim2.new(0, 0, 1, -3),
			Visible = false,
		}, b)
		UiKit.focusable(b)
		b.MouseEnter:Connect(function()
			if self.selected ~= item.id then
				b.TextColor3 = Color.TextPrimary
			end
		end)
		b.MouseLeave:Connect(function()
			if self.selected ~= item.id then
				b.TextColor3 = Color.TextSecondary
			end
		end)
		b.Activated:Connect(function()
			if self.selected ~= item.id then
				click()
				self.set(item.id)
			end
		end)
		tabs[item.id] = { button = b, underline = underline, index = index }
	end

	if opts.shoulders then
		local connection = UserInputService.InputBegan:Connect(function(input)
			if input.KeyCode ~= Enum.KeyCode.ButtonL1 and input.KeyCode ~= Enum.KeyCode.ButtonR1 then
				return
			end
			if not isShown(bar) then
				return
			end
			local current = tabs[self.selected] and tabs[self.selected].index or 1
			local step = if input.KeyCode == Enum.KeyCode.ButtonR1 then 1 else -1
			local nextIndex = (current - 1 + step) % #items + 1
			click()
			self.set(items[nextIndex].id)
		end)
		bar.Destroying:Connect(function()
			connection:Disconnect()
		end)
	end

	self.set(opts.selected or items[1].id, true)
	return self
end

---------------------------------------------------------------------
-- SETTINGS CONTROLS
---------------------------------------------------------------------

function UiKit.Toggle(parent, opts)
	opts = opts or {}
	local value = opts.value == true
	local b = new("TextButton", {
		Name = opts.name or "Toggle",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color.SurfaceInset,
		Size = UDim2.fromOffset(88, UiKit.TOUCH),
		LayoutOrder = opts.layoutOrder or 0,
	}, parent)
	UiKit.round(b, 22)
	local stroke = UiKit.border(b, Color.BorderStructural, 1.5, 0.3)
	local knob = new("Frame", {
		Name = "Knob",
		BackgroundColor3 = Color.TextSecondary,
		Size = UDim2.fromOffset(32, 32),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 6, 0.5, 0),
	}, b)
	UiKit.round(knob, 16)
	local word = new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = Fonts.LabelBold,
		TextSize = 15,
		Size = UDim2.new(0, 40, 1, 0),
	}, b)
	UiKit.focusable(b)
	local self = { button = b }
	local function render(animate)
		local t = if animate then UiKit.Motion.fast else 0
		if value then
			tween(knob, t, { Position = UDim2.new(1, -38, 0.5, 0), BackgroundColor3 = Color.TextOnAccent })
			tween(b, t, { BackgroundColor3 = Color.AccentLighthouse })
			stroke.Color = Color.AccentLighthouseDeep
			word.Text = "ON"
			word.TextColor3 = Color.TextOnAccent
			word.Position = UDim2.fromOffset(8, 0)
		else
			tween(knob, t, { Position = UDim2.new(0, 6, 0.5, 0), BackgroundColor3 = Color.TextSecondary })
			tween(b, t, { BackgroundColor3 = Color.SurfaceInset })
			stroke.Color = Color.BorderStructural
			word.Text = "OFF"
			word.TextColor3 = Color.TextMuted
			word.Position = UDim2.new(1, -46, 0, 0)
		end
	end
	function self.set(v, silent)
		value = v == true
		render(true)
		if not silent and opts.onChange then
			opts.onChange(value)
		end
	end
	function self.get()
		return value
	end
	b.Activated:Connect(function()
		click()
		self.set(not value)
	end)
	render(false)
	return self
end

function UiKit.Slider(parent, opts)
	opts = opts or {}
	local min, max, step = opts.min or 0, opts.max or 100, opts.step or 1
	local value = opts.value or min
	local format = opts.format or function(v)
		return tostring(v)
	end
	local frame = new("Frame", {
		Name = opts.name or "Slider",
		BackgroundTransparency = 1,
		Size = opts.size or UDim2.fromOffset(320, UiKit.TOUCH),
		LayoutOrder = opts.layoutOrder or 0,
	}, parent)
	local readout = new("TextLabel", {
		Name = "Value",
		BackgroundTransparency = 1,
		FontFace = Fonts.Numeric,
		TextSize = 19,
		TextColor3 = Color.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 58, 1, 0),
	}, frame)
	local self = { frame = frame }
	local minus = UiKit.IconButton(frame, "minus", { name = "Less", glyphSize = 14, silent = true })
	local plus = UiKit.IconButton(frame, "plus", { name = "More", glyphSize = 14, silent = true })
	plus.AnchorPoint = Vector2.new(1, 0)
	plus.Position = UDim2.new(1, -66, 0, 0)
	local track = new("TextButton", {
		Name = "Track",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(54, 0),
		Size = UDim2.new(1, -54 - 66 - 54, 1, 0),
		Selectable = false,
	}, frame)
	local rail = new("Frame", {
		BackgroundColor3 = Color.SurfaceInset,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 6),
	}, track)
	UiKit.round(rail, 3)
	UiKit.border(rail, Color.BorderStructural, 1, 0.45)
	local fill = new("Frame", { BackgroundColor3 = Color.AccentLighthouse, Size = UDim2.fromScale(0, 1) }, rail)
	UiKit.round(fill, 3)
	local knob = new("Frame", {
		BackgroundColor3 = Color.TextPrimary,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(20, 20),
	}, track)
	UiKit.round(knob, 10)
	UiKit.border(knob, Color.AccentLighthouseDeep, 2)

	function self.set(v, silent)
		v = math.clamp(math.floor((v - min) / step + 0.5) * step + min, min, max)
		local changed = v ~= value
		value = v
		local alpha = if max > min then (value - min) / (max - min) else 0
		fill.Size = UDim2.fromScale(alpha, 1)
		knob.Position = UDim2.fromScale(alpha, 0.5)
		readout.Text = format(value)
		if changed and not silent and opts.onChange then
			opts.onChange(value)
		end
	end
	function self.get()
		return value
	end
	minus.Activated:Connect(function()
		click()
		self.set(value - step)
	end)
	plus.Activated:Connect(function()
		click()
		self.set(value + step)
	end)
	local dragging = false
	local function setFromX(x)
		local alpha = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
		self.set(min + alpha * (max - min))
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	local moved = UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)
	local ended = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	frame.Destroying:Connect(function()
		moved:Disconnect()
		ended:Disconnect()
	end)
	value = nil
	self.set(opts.value or min, true)
	return self
end

-- A list row (no box): title + sentence-case description, control on the right, hairline below.
-- stacked = true puts the control under the text (narrow screens). last = true drops the hairline.
function UiKit.SettingRow(parent, title, description, opts)
	opts = opts or {}
	local controlWidth = opts.controlWidth or 320
	local row = new("Frame", {
		Name = opts.name or "SettingRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = opts.layoutOrder or 0,
	}, parent)
	local inner = new("Frame", {
		Name = "Inner",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, row)
	UiKit.pad(inner, 12, 0, 13, 0)
	local textColumn = new("Frame", {
		Name = "Text",
		BackgroundTransparency = 1,
		Size = if opts.stacked then UDim2.new(1, 0, 0, 0) else UDim2.new(1, -controlWidth - 20, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
	}, inner)
	UiKit.list(textColumn, "y", 2)
	UiKit.Label(textColumn, title, "H3", { LayoutOrder = 1 })
	if description then
		UiKit.Label(textColumn, description, "BodySmall", { LayoutOrder = 2 })
	end
	local slot = new("Frame", {
		Name = "Control",
		BackgroundTransparency = 1,
		Size = if opts.stacked then UDim2.new(1, 0, 0, UiKit.TOUCH) else UDim2.fromOffset(controlWidth, UiKit.TOUCH),
		LayoutOrder = 2,
	}, inner)
	if opts.stacked then
		UiKit.list(inner, "y", 10)
	else
		UiKit.list(inner, "x", 20, { VerticalAlignment = Enum.VerticalAlignment.Center })
	end
	if not opts.last then
		new("Frame", {
			Name = "Hairline",
			BackgroundColor3 = Color.BorderSubtle,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 1),
		}, row)
	end
	return row, slot
end

---------------------------------------------------------------------
-- DISPLAY: currency, tags, badges
---------------------------------------------------------------------

-- Pearl or Shell amount. Shows the word too (never icon alone). Width is reserved per digit
-- count so counters don't jitter. opts: size "md" | "lg", plain (no housing), showWord, color
function UiKit.Currency(parent, kind, amount, opts)
	opts = opts or {}
	local big = opts.size == "lg"
	local frame = new("Frame", {
		Name = kind .. "Display",
		BackgroundColor3 = Color.SurfaceInset,
		BackgroundTransparency = if opts.plain then 1 else 0,
		Size = UDim2.fromOffset(0, if big then 44 else 34),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = opts.layoutOrder or 0,
	}, parent)
	if not opts.plain then
		UiKit.round(frame, UiKit.Radius.control)
		UiKit.border(frame, Color.BorderStructural, 1, 0.3)
		UiKit.pad(frame, 0, 12, 0, 10)
	end
	UiKit.list(frame, "x", 7, { VerticalAlignment = Enum.VerticalAlignment.Center })
	UiKit.CurrencyIcon(frame, kind, if big then 22 else 17).LayoutOrder = 1
	local textSize = if big then 23 else (opts.textSize or 18)
	local number = new("TextLabel", {
		Name = "Amount",
		BackgroundTransparency = 1,
		FontFace = Fonts.Numeric,
		TextSize = textSize,
		TextColor3 = opts.color or Color.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromOffset(0, 24),
		LayoutOrder = 2,
	}, frame)
	new("TextLabel", {
		Name = "Word",
		BackgroundTransparency = 1,
		FontFace = Fonts.Label,
		TextSize = if big then 14 else 13,
		TextColor3 = Color.TextMuted,
		Text = string.upper(kind),
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 3,
		Visible = opts.showWord ~= false,
	}, frame)
	local self = { frame = frame, number = number }
	function self.set(n, flash)
		number.Text = formatNumber(n)
		number.Size = UDim2.fromOffset(numberWidth(number.Text, textSize), 24)
		if flash then
			number.TextColor3 = Color.AccentLighthouseSoft
			tween(number, UiKit.Motion.slow, { TextColor3 = opts.color or Color.TextPrimary })
		end
	end
	self.set(amount or 0)
	return self
end

-- Category / info chip. filled = solid with dark text; otherwise a tinted outline.
function UiKit.Tag(parent, text, colorName, opts)
	opts = opts or {}
	local color = Color[colorName] or colorName or Color.AccentSea
	local t = new("TextLabel", {
		Name = opts.name or "Tag",
		BackgroundColor3 = color,
		BackgroundTransparency = if opts.filled then 0 else 0.84,
		Text = string.upper(text),
		FontFace = Fonts.LabelBold,
		TextSize = 13,
		TextColor3 = if opts.filled then Color.TextOnAccent else color,
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = opts.layoutOrder or 0,
	}, parent)
	UiKit.round(t, UiKit.Radius.tag)
	UiKit.pad(t, 0, 7, 0, 7)
	if not opts.filled then
		UiKit.border(t, color, 1, 0.5)
	end
	return t
end

local function restyleTag(tag, text, color, filled)
	tag.Text = string.upper(text)
	tag.BackgroundColor3 = color
	tag.BackgroundTransparency = if filled then 0 else 0.84
	tag.TextColor3 = if filled then Color.TextOnAccent else color
	local stroke = tag:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = color
		stroke.Enabled = not filled
	elseif not filled then
		UiKit.border(tag, color, 1, 0.5)
	end
end

-- Item status badges. kind: "equipped" (strong) | "owned" (quiet) | "new" | "locked"
local BADGES = {
	equipped = { bg = Color.AccentLighthouse, bgT = 0, fg = Color.TextOnAccent, glyph = "check", label = "Equipped" },
	owned = { bg = Color.SurfaceBase, bgT = 0.25, fg = Color.TextSecondary, glyph = "check", glyphColor = Color.AccentSea, label = "Owned" },
	new = { bg = Color.SurfaceBase, bgT = 0.25, fg = Color.AccentLighthouseSoft, dot = true, label = "New" },
	locked = { bg = Color.SurfaceBase, bgT = 0.15, fg = Color.TextPrimary, glyph = "lock", label = "Locked" },
}
function UiKit.Badge(parent, kind, text, opts)
	opts = opts or {}
	local style = BADGES[kind]
	local b = new("Frame", {
		Name = "Badge_" .. kind,
		BackgroundColor3 = style.bg,
		BackgroundTransparency = style.bgT,
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = opts.layoutOrder or 0,
		ZIndex = 5,
	}, parent)
	UiKit.round(b, UiKit.Radius.tag)
	UiKit.pad(b, 0, 6, 0, 5)
	UiKit.list(b, "x", 4, { VerticalAlignment = Enum.VerticalAlignment.Center })
	if style.glyph then
		UiKit.Glyph(b, style.glyph, style.glyphColor or style.fg, 10).LayoutOrder = 1
	elseif style.dot then
		local d = new("Frame", { BackgroundColor3 = Color.AccentLighthouse, Size = UDim2.fromOffset(6, 6), LayoutOrder = 1 }, b)
		UiKit.round(d, 3)
	end
	new("TextLabel", {
		Name = "Text",
		BackgroundTransparency = 1,
		FontFace = Fonts.LabelBold,
		TextSize = 13,
		TextColor3 = style.fg,
		Text = string.upper(text or style.label),
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
	}, b)
	return b
end

---------------------------------------------------------------------
-- ITEM CARD (Shop and Inventory). Priority: visual > name > type > price > status.
---------------------------------------------------------------------

-- opts: itemId, name, category, subtitle, quantity, price = { kind, amount }, shortBy,
--       equipped, owned, selected, affordable, locked (reason string), isNew,
--       rarity = { label = "Rare", rank = 2 } (only if the game ever adds rarity),
--       onClick(itemId, card), size, layoutOrder
function UiKit.ItemCard(parent, opts)
	local ItemPreview = require(script.Parent.Parent:WaitForChild("ItemPreview"))
	local category = opts.category or "Materials"
	local catColor = Color[UiKit.CATEGORY[category] or "CatMaterials"]
	local card = new("TextButton", {
		Name = "Card_" .. tostring(opts.itemId),
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color.SurfaceSecondary,
		Size = opts.size or UDim2.fromOffset(156, 212),
		LayoutOrder = opts.layoutOrder or 0,
	}, parent)
	UiKit.round(card, UiKit.Radius.card)
	local stroke = UiKit.border(card, Color.BorderSubtle, 1, 1)
	UiKit.focusable(card)

	local well = UiKit.Inset(card, {
		Name = "Well",
		BackgroundColor3 = rgb(22, 32, 46),
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.new(1, -12, 1, -76),
		ClipsDescendants = true,
	})
	new("Frame", {
		Name = "CategoryRule",
		BackgroundColor3 = catColor,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 2),
		ZIndex = 4,
	}, well)
	local preview = ItemPreview.new(well, {})
	preview:setItem(opts.itemId)

	local badges = new("Frame", {
		Name = "Badges",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(5, 5),
		Size = UDim2.new(1, -10, 0, 20),
		ZIndex = 5,
	}, well)
	UiKit.list(badges, "x", 4)
	local equippedBadge = UiKit.Badge(badges, "equipped", nil, { layoutOrder = 1 })
	local ownedBadge = UiKit.Badge(badges, "owned", nil, { layoutOrder = 2 })
	local topRight = new("Frame", {
		Name = "TopRight",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -5, 0, 5),
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 5,
	}, well)
	UiKit.list(topRight, "x", 4, { HorizontalAlignment = Enum.HorizontalAlignment.Right })
	local quantity = new("TextLabel", {
		Name = "Quantity",
		BackgroundColor3 = Color.SurfaceBase,
		BackgroundTransparency = 0.2,
		FontFace = Fonts.Numeric,
		TextSize = 15,
		TextColor3 = Color.TextPrimary,
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		ZIndex = 5,
	}, topRight)
	UiKit.round(quantity, UiKit.Radius.tag)
	UiKit.pad(quantity, 0, 6, 0, 6)
	local newBadge = UiKit.Badge(topRight, "new", nil, { layoutOrder = 1 })

	local rarityMarks
	if opts.rarity then
		rarityMarks = new("Frame", {
			Name = "RarityMarks",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 6, 1, -7),
			Size = UDim2.fromOffset(0, 8),
			AutomaticSize = Enum.AutomaticSize.X,
			ZIndex = 5,
		}, well)
		UiKit.list(rarityMarks, "x", 3)
		for i = 1, opts.rarity.rank or 1 do
			new("Frame", {
				BackgroundColor3 = Color.BorderBrassBright,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(6, 6),
				Rotation = 45,
				LayoutOrder = i,
				ZIndex = 5,
			}, rarityMarks)
		end
	end

	local lockOverlay = new("Frame", {
		Name = "Locked",
		BackgroundColor3 = Color.Scrim,
		BackgroundTransparency = 0.35,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 6,
		Visible = false,
	}, well)
	local lockGlyph = UiKit.Glyph(lockOverlay, "lock", Color.TextPrimary, 18)
	lockGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
	lockGlyph.Position = UDim2.fromScale(0.5, 0.36)
	local lockReason = new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = Fonts.BodyMedium,
		TextSize = 13,
		TextColor3 = Color.TextPrimary,
		TextWrapped = true,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.56),
		Size = UDim2.new(1, -12, 0.4, 0),
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 6,
	}, lockOverlay)

	local name = new("TextLabel", {
		Name = "ItemName",
		BackgroundTransparency = 1,
		FontFace = Fonts.BodyBold,
		TextSize = 16,
		TextColor3 = Color.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = true,
		Text = opts.name or tostring(opts.itemId),
		Position = UDim2.new(0, 10, 1, -62),
		Size = UDim2.new(1, -20, 0, 20),
	}, card)
	new("UITextSizeConstraint", { MaxTextSize = 16, MinTextSize = 12 }, name)
	local typeLine = new("TextLabel", {
		Name = "Type",
		BackgroundTransparency = 1,
		FontFace = Fonts.Label,
		TextSize = 14,
		TextColor3 = catColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.upper((if opts.rarity then opts.rarity.label .. " · " else "") .. (opts.subtitle or category)),
		Position = UDim2.new(0, 10, 1, -30),
		Size = UDim2.new(1, -20, 0, 18),
	}, card)
	local priceRow, shortGlyph
	if opts.price then
		priceRow = UiKit.Currency(card, opts.price.kind, opts.price.amount, { plain = true, showWord = false, textSize = 17 })
		priceRow.frame.AnchorPoint = Vector2.new(1, 1)
		priceRow.frame.Position = UDim2.new(1, -10, 1, -8)
		priceRow.frame.Size = UDim2.fromOffset(0, 22)
		shortGlyph = UiKit.Glyph(priceRow.frame, "warning", Color.StateDanger, 13)
		shortGlyph.LayoutOrder = 0
	end
	local brackets = UiKit.Brackets(card, Color.AccentLighthouse, 12, 2, -4)

	local self = { frame = card, preview = preview, name = name, typeLine = typeLine }
	local state = {}
	local function render()
		local emphasized = state.selected or state.equipped
		stroke.Transparency = if emphasized then 0 else 1
		stroke.Color = if state.selected then Color.BorderSelected else Color.AccentLighthouseDeep
		stroke.Thickness = if state.selected then 2 else 1
		brackets.Visible = state.selected == true
		card.BackgroundColor3 = if state.selected then Color.SurfaceElevated else Color.SurfaceSecondary
		equippedBadge.Visible = state.equipped == true
		ownedBadge.Visible = state.owned == true and not state.equipped
		quantity.Visible = state.quantity ~= nil and state.quantity > 0
		newBadge.Visible = state.isNew == true
		lockOverlay.Visible = state.locked ~= nil
		lockReason.Text = state.locked or ""
		if priceRow then
			priceRow.frame.Visible = not state.owned and not state.locked
			priceRow.number.TextColor3 = if state.affordable then Color.TextPrimary else Color.TextSecondary
			shortGlyph.Visible = not state.affordable
		end
		if state.affordable == false and opts.shortBy then
			UiKit.Tooltip(card, string.format("You need %s more %s.", formatNumber(opts.shortBy), opts.price and opts.price.kind or "Pearls"))
		end
	end
	function self.setSelected(on)
		state.selected = on
		render()
	end
	function self.setEquipped(on)
		state.equipped = on
		render()
	end
	function self.setOwned(on)
		state.owned = on
		render()
	end
	function self.setAffordable(on)
		state.affordable = on
		render()
	end
	function self.setLocked(reason)
		state.locked = reason
		render()
	end
	function self.setNew(on)
		state.isNew = on
		render()
	end
	function self.setQuantity(n)
		state.quantity = n
		quantity.Text = if n then "x" .. formatNumber(n) else ""
		render()
	end
	card.MouseEnter:Connect(function()
		if not state.selected then
			card.BackgroundColor3 = Color.SurfaceHover
		end
	end)
	card.MouseLeave:Connect(render)
	card.Activated:Connect(function()
		click()
		if opts.onClick then
			opts.onClick(opts.itemId, self)
		end
	end)
	state.selected = opts.selected == true
	state.equipped = opts.equipped == true
	state.owned = opts.owned == true
	state.affordable = opts.affordable ~= false
	state.locked = opts.locked
	state.isNew = opts.isNew == true
	self.setQuantity(opts.quantity)
	return self
end

K.restyleTag = restyleTag

return true
