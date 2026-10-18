-- UiKit · Gauges (S5.5): HUD gauges: one family, four silhouettes.
-- Moved unchanged from UiKit; screens still require UiKit, which loads the parts in order. The design rules
-- are at the top of UiKit.


local Kit = require(script.Parent:WaitForChild("Kit"))
local UiKit, K = Kit.UiKit, Kit.K
local rgb = K.rgb
local Color = K.Color
local Fonts = K.Fonts
local new = K.new
local tween = K.tween
local restyleTag = K.restyleTag

-- PH.1: on a narrow gauge (phones) a state note keeps only the state, e.g. "TOWER · BREACHING" -> "BREACHING"
local function noteText(label, text)
	if label.AbsoluteSize.X > 0 and label.AbsoluteSize.X < 120 then
		return string.match(text, " · (.+)$") or text
	end
	return text
end

---------------------------------------------------------------------
-- GAUGES: one family, four silhouettes. Shared: icon cap (Inset), Label text, numeric readout.
---------------------------------------------------------------------

local function gaugeCap(frame, size, glyphKind, glyphColor, glyphSize)
	local cap = UiKit.Inset(frame, { Name = "Cap", Size = UDim2.fromOffset(size, size) })
	UiKit.border(cap, Color.BorderStructural, 1, 0.55)
	local glyph = UiKit.Glyph(cap, glyphKind, glyphColor, glyphSize)
	glyph.AnchorPoint = Vector2.new(0.5, 0.5)
	glyph.Position = UDim2.fromScale(0.5, 0.5)
	return cap, glyph
end

local function readoutLabel(parent, size)
	return new("TextLabel", {
		Name = "Readout",
		BackgroundTransparency = 1,
		FontFace = Fonts.Numeric,
		TextSize = size,
		TextColor3 = Color.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Right,
		Size = UDim2.fromOffset(0, size + 2),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 9,
	}, parent)
end

-- GENERIC RESOURCE (secondary resources only, e.g. cannon ammo)
-- opts: label, value 0..1, text, color (token), warnBelow, dangerBelow, ticks
function UiKit.ResourceGauge(parent, opts)
	opts = opts or {}
	local frame = new("Frame", {
		Name = opts.name or "ResourceGauge",
		BackgroundTransparency = 1,
		Size = opts.size or UDim2.new(1, 0, 0, 38),
		LayoutOrder = opts.layoutOrder or 0,
	}, parent)
	UiKit.Label(frame, opts.label or "", "Label", {
		Size = UDim2.new(0.6, 0, 0, 16),
		AutomaticSize = Enum.AutomaticSize.None,
		TextWrapped = false,
	})
	local readout = new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = Fonts.Numeric,
		TextSize = 15,
		TextColor3 = Color.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0.4, 0, 0, 16),
	}, frame)
	local track = UiKit.Inset(frame, {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 10),
	})
	local fill = new("Frame", { BackgroundColor3 = Color.AccentLighthouse, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1) }, track)
	UiKit.round(fill, 3)
	local ticks = opts.ticks or 10
	for i = 1, ticks - 1 do
		new("Frame", {
			BackgroundColor3 = Color.SurfaceBase,
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(i / ticks, 0),
			Size = UDim2.new(0, 2, 1, 0),
			ZIndex = 3,
		}, track)
	end
	local self = { frame = frame }
	function self.set(v, text)
		v = math.clamp(v or 0, 0, 1)
		fill.Size = UDim2.fromScale(v, 1)
		local color = Color[opts.color or "AccentSea"]
		if opts.dangerBelow and v < opts.dangerBelow then
			color = Color.StateDanger
		elseif opts.warnBelow and v < opts.warnBelow then
			color = Color.StateWarning
		end
		fill.BackgroundColor3 = color
		readout.Text = text or string.format("%d%%", math.floor(v * 100 + 0.5))
	end
	self.set(opts.value or 0, opts.text)
	return self
end
UiKit.Gauge = UiKit.ResourceGauge

-- PLAYER HEALTH: compact survival instrument. Coral fill, a pale trailing segment shows recent
-- damage, a brass marker at 25% shows where "critical" begins.
function UiKit.HealthGauge(parent, opts)
	opts = opts or {}
	local P = UiKit.palette() -- S5.6: glass HUD keeps navy surfaces when the gauge recolours
	local max = opts.max or 100
	local frame = new("Frame", {
		Name = "HealthGauge",
		BackgroundTransparency = 1,
		Size = opts.size or UDim2.fromOffset(300, 38),
		LayoutOrder = opts.layoutOrder or 0,
	}, parent)
	local cap, heart = gaugeCap(frame, 38, "heart", Color.StateDanger, 18)
	local body = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(46, 0), Size = UDim2.new(1, -46, 1, 0) }, frame)
	local label = UiKit.Label(body, "Health", "Label", { Size = UDim2.new(0.7, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.None, TextWrapped = false })
	local readout = new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = Fonts.Numeric,
		TextSize = 15,
		TextColor3 = Color.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0.3, 0, 0, 16),
	}, body)
	UiKit.fitHeader(label, readout)
	local track = UiKit.Inset(body, {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 14),
	})
	local trail = new("Frame", { Name = "Trail", BackgroundColor3 = Color.HealthTrail, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 2 }, track)
	UiKit.round(trail, 3)
	local fill = new("Frame", { Name = "Fill", BackgroundColor3 = Color.StateDanger, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 3 }, track)
	UiKit.round(fill, 3)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), rgb(200, 190, 190)) }, fill)
	new("Frame", {
		Name = "CriticalMark",
		BackgroundColor3 = Color.BorderBrassBright,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.25, 0, 1, 2),
		Size = UDim2.fromOffset(2, 20),
		ZIndex = 4,
	}, track)
	local self = { frame = frame }
	local shown
	local token = 0
	function self.set(v)
		v = math.clamp(v, 0, max)
		local alpha = v / max
		local before = shown
		shown = alpha
		fill.Size = UDim2.fromScale(alpha, 1) -- damage reads instantly; the trail catches up
		if before and alpha < before then
			trail.Size = UDim2.fromScale(before, 1)
			token += 1
			local mine = token
			task.delay(0.35, function()
				if mine == token then
					tween(trail, 0.3, { Size = UDim2.fromScale(alpha, 1) })
				end
			end)
		else
			trail.Size = UDim2.fromScale(alpha, 1)
		end
		readout.Text = string.format("%d / %d", math.ceil(v), max)
		local critical = alpha <= 0.25
		cap.BackgroundColor3 = if critical then Color.StateDanger else P.SurfaceInset
		UiKit.SetGlyphColor(heart, if critical then Color.TextOnAccent else Color.StateDanger)
		label.Text = noteText(label, (self :: any).note or (if critical then "HEALTH · CRITICAL" else "HEALTH"))
		label.TextColor3 = if critical or (self :: any).note then Color.StateDanger else Color.TextSecondary
	end
	-- the maximum can change (armor); the current value is kept
	function self.setMax(newMax)
		max = math.max(1, newMax)
	end
	-- a short override for the label, e.g. "HEALTH · DOWN"; nil restores the normal label
	function self.setNote(text)
		self.note = text
	end
	-- jump straight to a value with no trailing segment (respawn, new run)
	function self.reset(v)
		shown = nil
		token += 1
		self.set(v)
	end
	self.set(opts.value or max)
	return self
end

-- LIGHTHOUSE FUEL: the main objective instrument. Taller, lamp cap, compass-style scale above
-- the reservoir, quarter marks, and four stages: steady, LOW, CRITICAL, BLACKOUT.
function UiKit.FuelGauge(parent, opts)
	opts = opts or {}
	local P = UiKit.palette()
	local frame = new("Frame", {
		Name = "FuelGauge",
		BackgroundTransparency = 1,
		Size = opts.size or UDim2.fromOffset(380, 58),
		LayoutOrder = opts.layoutOrder or 0,
	}, parent)
	local cap, lamp = gaugeCap(frame, 58, "lamp", Color.AccentLighthouse, 30)
	local body = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(68, 0), Size = UDim2.new(1, -68, 1, 0) }, frame)
	local label = UiKit.Label(body, "Lamp fuel", "Label", {
		Size = UDim2.new(0.5, 0, 0, 20),
		AutomaticSize = Enum.AutomaticSize.None,
		TextWrapped = false,
		TextSize = 16,
		TextColor3 = Color.TextPrimary,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	local right = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
	}, body)
	UiKit.list(right, "x", 8, { VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right })
	local stateTag = UiKit.Tag(right, "Low", "StateWarning", { layoutOrder = 1 })
	local percent = readoutLabel(right, 20)
	local scale = new("Frame", { Name = "Scale", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 6) }, body)
	for i = 0, 20 do
		local major = i % 5 == 0
		new("Frame", {
			BackgroundColor3 = Color.BorderBrassBright,
			BackgroundTransparency = if major then 0.3 else 0.62,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(i / 20, 1),
			Size = UDim2.fromOffset(if major then 2 else 1, if major then 6 else 3),
		}, scale)
	end
	local track = UiKit.Inset(body, { Name = "Reservoir", Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 18) })
	local fill = new("Frame", { Name = "Fill", BackgroundColor3 = Color.AccentLighthouse, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 2 }, track)
	UiKit.round(fill, 3)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), rgb(205, 185, 150)) }, fill)
	for _, q in { 0.25, 0.5, 0.75 } do
		new("Frame", {
			BackgroundColor3 = Color.SurfaceBase,
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(q, 0),
			Size = UDim2.new(0, 2, 1, 0),
			ZIndex = 3,
		}, track)
	end
	local self = { frame = frame }
	function self.set(v)
		v = math.clamp(v or 0, 0, 1)
		fill.Size = UDim2.fromScale(v, 1)
		percent.Text = string.format("%d%%", math.floor(v * 100 + 0.5))
		fill.Visible = v > 0
		track.BackgroundColor3 = if v <= 0 then Color.Scrim else P.SurfaceInset
		local stage
		if v <= 0 then
			stage = "blackout"
			restyleTag(stateTag, "Blackout", Color.StateDanger, true)
		elseif v < 0.15 then
			stage = "critical"
			fill.BackgroundColor3 = Color.StateDanger
			restyleTag(stateTag, "Critical", Color.StateDanger, true)
		elseif v < 0.3 then
			stage = "low"
			fill.BackgroundColor3 = Color.StateWarning
			restyleTag(stateTag, "Low", Color.StateWarning, false)
		else
			stage = "steady"
			fill.BackgroundColor3 = Color.AccentLighthouse
		end
		stateTag.Visible = stage ~= "steady"
		UiKit.SetGlyphColor(lamp, if stage == "blackout" then Color.TextMuted else Color.AccentLighthouse)
		cap.BackgroundColor3 = if stage == "blackout" then P.SurfaceBase else P.SurfaceInset
		label.TextColor3 = if stage == "blackout" or stage == "critical" then Color.StateDanger else Color.TextPrimary
		self.stage = stage
	end
	self.set(opts.value or 1)
	return self
end

-- TOWER INTEGRITY: segmented masonry. Lost blocks go dark and show a crack; a block that just
-- broke flashes coral once.
function UiKit.TowerGauge(parent, opts)
	opts = opts or {}
	local P = UiKit.palette()
	local segments = opts.segments or 10
	local frame = new("Frame", {
		Name = "TowerGauge",
		BackgroundTransparency = 1,
		Size = opts.size or UDim2.fromOffset(320, 42),
		LayoutOrder = opts.layoutOrder or 0,
	}, parent)
	gaugeCap(frame, 42, "tower", Color.Stone, 24)
	local body = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(50, 0), Size = UDim2.new(1, -50, 1, 0) }, frame)
	local label = UiKit.Label(body, "Tower", "Label", { Size = UDim2.new(0.7, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.None, TextWrapped = false })
	local readout = new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = Fonts.Numeric,
		TextSize = 15,
		TextColor3 = Color.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0.3, 0, 0, 16),
	}, body)
	UiKit.fitHeader(label, readout)
	local blocksFrame = new("Frame", { Name = "Blocks", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 20) }, body)
	local blocks = {}
	for i = 1, segments do
		local block = UiKit.Inset(blocksFrame, {
			Name = "Block" .. i,
			Position = UDim2.new((i - 1) / segments, 0, 0, 0),
			Size = UDim2.new(1 / segments, -3, 1, 0),
		})
		block:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 2)
		local fill = new("Frame", { Name = "Stone", BackgroundColor3 = Color.Stone, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 2 }, block)
		UiKit.round(fill, 2)
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), rgb(170, 165, 155)) }, fill)
		local crack = new("Frame", { Name = "Crack", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3, Visible = false }, block)
		new("Frame", {
			BackgroundColor3 = Color.BorderStructural,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.42, 0.34),
			Size = UDim2.new(0, 2, 0.6, 0),
			Rotation = 28,
			ZIndex = 3,
		}, crack)
		new("Frame", {
			BackgroundColor3 = Color.BorderStructural,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.56, 0.72),
			Size = UDim2.new(0, 2, 0.5, 0),
			Rotation = -24,
			ZIndex = 3,
		}, crack)
		blocks[i] = { frame = block, fill = fill, crack = crack, amount = 1 }
	end
	local self = { frame = frame }
	local initialized = false
	function self.set(v)
		v = math.clamp(v or 0, 0, 1)
		for i, b in blocks do
			local amount = math.clamp(v * segments - (i - 1), 0, 1)
			local justBroke = initialized and b.amount > 0 and amount == 0
			b.amount = amount
			b.fill.Size = UDim2.fromScale(amount, 1)
			b.fill.Visible = amount > 0
			b.crack.Visible = amount == 0
			if justBroke then
				b.frame.BackgroundColor3 = Color.StateDanger
				tween(b.frame, 0.45, { BackgroundColor3 = P.SurfaceInset })
			end
		end
		initialized = true
		readout.Text = string.format("%d%%", math.floor(v * 100 + 0.5))
		local breaching = v < 0.3
		label.Text = noteText(label, if breaching then "TOWER · BREACHING" else "TOWER")
		label.TextColor3 = if breaching then Color.StateDanger else Color.TextSecondary
	end
	self.set(opts.value or 1)
	return self
end


return true
