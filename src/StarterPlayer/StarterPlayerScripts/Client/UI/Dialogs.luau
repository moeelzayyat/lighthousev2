-- UiKit · Dialogs (S5.5): feedback (notices, pickups), dialogs and motion.
-- Moved unchanged from UiKit; screens still require UiKit, which loads the parts in order. The design rules
-- are at the top of UiKit.

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Kit = require(script.Parent:WaitForChild("Kit"))
local UiKit, K = Kit.UiKit, Kit.K
local rgb = K.rgb
local Color = K.Color
local Fonts = K.Fonts
local new = K.new
local tween = K.tween
local formatNumber = K.formatNumber
local usingGamepad = K.usingGamepad

---------------------------------------------------------------------
-- FEEDBACK: notices (top center) and pickups (right edge). Both stay clear of the screen center
-- (aiming), the lower middle (interaction prompts) and menu close buttons (top right).
-- Kinds differ by glyph AND color AND title.
---------------------------------------------------------------------

local NOTICE_KINDS = {
	success = { color = Color.StateSuccess, glyph = "check" },
	good = { color = Color.StateSuccess, glyph = "check" },
	warning = { color = Color.StateWarning, glyph = "warning" },
	danger = { color = Color.StateDanger, glyph = "close" },
	bad = { color = Color.StateDanger, glyph = "close" },
	error = { color = Color.StateDanger, glyph = "close" },
	info = { color = Color.AccentSea, glyph = "info" },
}
UiKit.NOTICE_LIMIT = 3
UiKit.PICKUP_LIMIT = 4

local order = 0
local function nextOrder()
	order += 1
	return order
end

local function trim(stack, limit)
	local items = {}
	for _, child in stack:GetChildren() do
		if child:IsA("GuiObject") then
			table.insert(items, child)
		end
	end
	table.sort(items, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	while #items >= limit do
		table.remove(items, 1):Destroy()
	end
end

local function fadeOut(frame)
	local scale = frame:FindFirstChild("EnterScale")
	if scale then
		tween(scale, UiKit.Motion.fast, { Scale = 0.94 })
	end
	task.delay(UiKit.Motion.fast, function()
		frame:Destroy()
	end)
end

-- UiKit.Toast(container, "message", "success" | "warning" | "danger" | "info", { title, duration })
-- Gauge/bar headers: the number keeps its full width, the label gets what is left and truncates.
function UiKit.fitHeader(label, readout)
	readout.AutomaticSize = Enum.AutomaticSize.X
	readout.Size = UDim2.new(0, 0, readout.Size.Y.Scale, readout.Size.Y.Offset)
	label.TextTruncate = Enum.TextTruncate.AtEnd
	local function fit()
		label.Size = UDim2.new(1, -(readout.AbsoluteSize.X + 6), label.Size.Y.Scale, label.Size.Y.Offset)
	end
	readout:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
end

function UiKit.Toast(container, message, kind, opts)
	opts = opts or {}
	local style = NOTICE_KINDS[kind or "info"] or NOTICE_KINDS.info
	local stack = container:FindFirstChild("ToastStack")
	if not stack then
		stack = new("Frame", {
			Name = "ToastStack",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 12),
			Size = UDim2.fromOffset(340, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 200,
		}, container)
		UiKit.list(stack, "y", 8, { HorizontalAlignment = Enum.HorizontalAlignment.Center })
	end
	stack.Size = UDim2.fromOffset(container:GetAttribute("NoticeWidth") or math.clamp(container.AbsoluteSize.X * 0.5, 260, 400), 0)
	stack.Position = UDim2.new(0.5, 0, 0, container:GetAttribute("NoticeTop") or 12)
	trim(stack, container:GetAttribute("NoticeLimit") or UiKit.NOTICE_LIMIT)
	local t = new("Frame", {
		Name = "Toast",
		BackgroundColor3 = Color.SurfaceElevated,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = nextOrder(),
		ZIndex = 200,
	}, stack)
	t:SetAttribute("Kind", kind)
	UiKit.round(t, UiKit.Radius.card)
	UiKit.border(t, style.color, 1, 0.5)
	new("Frame", { Name = "Rule", BackgroundColor3 = style.color, BorderSizePixel = 0, Size = UDim2.new(0, 4, 1, 0), ZIndex = 201 }, t)
	local inner = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, t)
	UiKit.pad(inner, 10, 14, 10, 16)
	local glyph = UiKit.Glyph(inner, style.glyph, style.color, 16)
	glyph.Position = UDim2.fromOffset(0, 2)
	local column = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(28, 0),
		Size = UDim2.new(1, -28, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, inner)
	UiKit.list(column, "y", 1)
	if opts.title then
		UiKit.Label(column, opts.title, "H3", { LayoutOrder = 1, TextSize = 16 })
	end
	UiKit.Label(column, message, "BodySmall", { LayoutOrder = 2, TextColor3 = Color.TextPrimary })
	local scale = new("UIScale", { Name = "EnterScale", Scale = 0.96 }, t)
	tween(scale, UiKit.Motion.fast, { Scale = 1 })
	task.delay(opts.duration or 3.2, function()
		if t.Parent then
			fadeOut(t)
		end
	end)
	return t
end

-- Loot and currency pickups: small rows on the right edge. The same key merges while visible,
-- so ten crab claws read as one "x10" row. Shells and loot say THIS VOYAGE; Pearls say KEPT.
-- opts: kind "Shells" | "Pearls" | "loot", amount, label (loot name), category, key
function UiKit.Pickup(container, opts)
	local feed = container:FindFirstChild("PickupFeed")
	if not feed then
		feed = new("Frame", {
			Name = "PickupFeed",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -16, 0.36, 0),
			Size = UDim2.fromOffset(0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			ZIndex = 190,
		}, container)
		UiKit.list(feed, "y", 6, { HorizontalAlignment = Enum.HorizontalAlignment.Right })
	end
	if container:GetAttribute("PickupTop") then
		feed.Position = UDim2.new(1, -16, 0, container:GetAttribute("PickupTop"))
	end
	local kind = opts.kind or "loot"
	local key = opts.key or (kind .. "_" .. tostring(opts.label))
	local amount = opts.amount or 1
	local function amountText(n)
		return if kind == "loot" then "x" .. formatNumber(n) else "+" .. formatNumber(n)
	end
	local existing = feed:FindFirstChild("Pickup_" .. key)
	if existing then
		local total = existing:GetAttribute("Amount") + amount
		existing:SetAttribute("Amount", total)
		existing:SetAttribute("Expire", os.clock() + 2.6)
		existing:FindFirstChild("Amount", true).Text = amountText(total)
		local scale = existing:FindFirstChild("EnterScale")
		scale.Scale = 1.06
		tween(scale, UiKit.Motion.fast, { Scale = 1 })
		return existing
	end
	trim(feed, container:GetAttribute("PickupLimit") or UiKit.PICKUP_LIMIT)
	local accent = if kind == "Shells" then Color.Shell
		elseif kind == "Pearls" then Color.Pearl
		else Color[UiKit.CATEGORY[opts.category or "Materials"] or "CatMaterials"]
	local row = new("Frame", {
		Name = "Pickup_" .. key,
		BackgroundColor3 = Color.SurfaceBase,
		BackgroundTransparency = 0.12,
		Size = UDim2.fromOffset(200, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = nextOrder(),
	}, feed)
	row:SetAttribute("Amount", amount)
	row:SetAttribute("Expire", os.clock() + 2.6)
	UiKit.round(row, UiKit.Radius.card)
	new("Frame", { Name = "Rule", BackgroundColor3 = accent, BorderSizePixel = 0, Size = UDim2.new(0, 3, 1, 0) }, row)
	local inner = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X }, row)
	UiKit.pad(inner, 0, 12, 0, 12)
	UiKit.list(inner, "x", 8, { VerticalAlignment = Enum.VerticalAlignment.Center })
	if kind == "Shells" or kind == "Pearls" then
		UiKit.CurrencyIcon(inner, kind, 18).LayoutOrder = 1
	else
		UiKit.Glyph(inner, "diamond", accent, 14).LayoutOrder = 1
	end
	new("TextLabel", {
		Name = "Amount",
		BackgroundTransparency = 1,
		FontFace = Fonts.Numeric,
		TextSize = 17,
		TextColor3 = if kind == "Pearls" then Color.Pearl else Color.TextPrimary,
		Text = amountText(amount),
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
	}, inner)
	new("TextLabel", {
		Name = "What",
		BackgroundTransparency = 1,
		FontFace = Fonts.BodyMedium,
		TextSize = 15,
		TextColor3 = Color.TextPrimary,
		Text = if kind == "loot" then opts.label or "Loot" else kind,
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 3,
	}, inner)
	new("TextLabel", {
		Name = "Note",
		BackgroundTransparency = 1,
		FontFace = Fonts.Label,
		TextSize = 13,
		TextColor3 = if kind == "Pearls" then Color.AccentSea else Color.TextMuted,
		Text = if kind == "Pearls" then "KEPT" else "THIS VOYAGE",
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 4,
	}, inner)
	local scale = new("UIScale", { Name = "EnterScale", Scale = 0.94 }, row)
	tween(scale, UiKit.Motion.fast, { Scale = 1 })
	task.spawn(function()
		while row.Parent do
			if os.clock() > row:GetAttribute("Expire") then
				fadeOut(row)
				return
			end
			task.wait(0.2)
		end
	end)
	return row
end

---------------------------------------------------------------------
-- DIALOGS
---------------------------------------------------------------------

local function makeScrim(container)
	local scrim = new("TextButton", {
		Name = "DialogScrim",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color.Scrim,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 300,
		Selectable = false,
	}, container)
	tween(scrim, UiKit.Motion.base, { BackgroundTransparency = 0.3 })
	return scrim
end

-- A plain confirmation. opts: eyebrow, title, body, confirmText, cancelText, kind "default" | "danger",
-- onConfirm, onCancel. Escape / B cancels.
function UiKit.Dialog(container, opts)
	opts = opts or {}
	local scrim = makeScrim(container)
	local danger = opts.kind == "danger"
	local height = opts.height or 216
	local panel, content = UiKit.Panel(scrim, {
		name = "Dialog",
		kind = "dialog",
		frameColor = if danger then Color.StateDanger else nil,
		eyebrow = opts.eyebrow,
		title = opts.title,
		titleStyle = "H2",
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.new(0.92, 0, 0, height),
	})
	new("UISizeConstraint", { MaxSize = Vector2.new(470, height) }, panel)
	UiKit.Label(content, opts.body or "", "Body", { TextColor3 = Color.TextSecondary })
	local row = new("Frame", {
		Name = "Actions",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 48),
	}, content)
	UiKit.list(row, "x", 10, { HorizontalAlignment = Enum.HorizontalAlignment.Right })
	local name = "Dialog" .. tostring(os.clock())
	UiKit.pushModal(name)
	scrim.Destroying:Connect(function()
		UiKit.popModal(name) -- never leave input locked if something else removes the dialog
	end)
	local closed = false
	local connection
	local function close(confirmed)
		if closed then
			return
		end
		closed = true
		if connection then
			connection:Disconnect()
		end
		UiKit.popModal(name)
		GuiService.SelectedObject = nil
		tween(scrim, UiKit.Motion.fast, { BackgroundTransparency = 1 })
		panel.Visible = false
		task.delay(UiKit.Motion.fast, function()
			scrim:Destroy()
		end)
		if confirmed and opts.onConfirm then
			opts.onConfirm()
		elseif not confirmed and opts.onCancel then
			opts.onCancel()
		end
	end
	local cancel = UiKit.Button(row, opts.cancelText or "Cancel", { name = "CancelButton", variant = "secondary", layoutOrder = 1, onClick = function()
		close(false)
	end })
	local confirm = UiKit.Button(row, opts.confirmText or "Confirm", { name = "ConfirmButton", variant = if danger then "danger" else "primary", layoutOrder = 2, onClick = function()
		close(true)
	end })
	connection = UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
			close(false)
		end
	end)
	if usingGamepad() then
		GuiService.SelectedObject = if danger then cancel else confirm
	end
	UiKit.Open(panel)
	return { close = close, confirm = confirm, cancel = cancel, panel = panel }
end

-- An item-specific purchase decision.
-- opts: itemId, name, description, category, effect "gameplay" | "cosmetic", eyebrow,
--       price = { kind = "Pearls", amount }, balance, owned,
--       onPurchase(done)  -> call done(true) or done(false, "what went wrong, in plain words")
-- States: default, insufficient, owned, pending, success, error. Returns { setState, close, ... }.
function UiKit.PurchaseDialog(container, opts)
	local ItemPreview = require(script.Parent.Parent:WaitForChild("ItemPreview"))
	local phone = UiKit.Breakpoint(container.AbsoluteSize) == "phone"
	local price = opts.price
	local currency = price.kind
	local balance = opts.balance or 0
	local height = math.min(if phone then 300 else 340, container.AbsoluteSize.Y - 24)
	local scrim = makeScrim(container)
	local panel, content = UiKit.Panel(scrim, {
		name = "PurchaseDialog",
		kind = "dialog",
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.new(0.94, 0, 0, height),
		padding = if phone then 16 else 22,
	})
	new("UISizeConstraint", { MaxSize = Vector2.new(if phone then 500 else 548, height) }, panel)

	local wellSize = if phone then 96 else 128
	local well = UiKit.Inset(content, { Name = "Well", BackgroundColor3 = rgb(22, 32, 46), Size = UDim2.fromOffset(wellSize, wellSize), ClipsDescendants = true })
	local preview = ItemPreview.new(well, {})
	preview:setItem(opts.itemId)
	local info = new("Frame", {
		Name = "Info",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(wellSize + 16, 0),
		Size = UDim2.new(1, -(wellSize + 16), 0, wellSize),
	}, content)
	UiKit.list(info, "y", 5)
	UiKit.Label(info, opts.eyebrow or "Quartermaster", "Eyebrow", { LayoutOrder = 1 })
	UiKit.Label(info, opts.name or "", "H2", { LayoutOrder = 2, TextSize = if phone then 20 else 23 })
	local tags = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 3 }, info)
	UiKit.list(tags, "x", 6)
	if opts.effect == "cosmetic" then
		UiKit.Tag(tags, "Cosmetic only", "CatAmmunition", { layoutOrder = 1 })
	else
		UiKit.Tag(tags, "Affects gameplay", "AccentSea", { layoutOrder = 1 })
	end
	if opts.category then
		UiKit.Tag(tags, opts.category, UiKit.CATEGORY[opts.category] or "AccentSea", { layoutOrder = 2 })
	end
	if opts.description then
		UiKit.Label(info, opts.description, "BodySmall", { LayoutOrder = 4, TextTruncate = Enum.TextTruncate.AtEnd, AutomaticSize = Enum.AutomaticSize.None, Size = UDim2.new(1, 0, 0, if phone then 18 else 38) })
	end

	-- the ledger: price, balance, balance after
	local areaTop = wellSize + 12
	local ledger = UiKit.Inset(content, { Name = "Ledger", Position = UDim2.fromOffset(0, areaTop), Size = UDim2.new(1, 0, 0, 84) })
	UiKit.pad(ledger, 8, 14, 8, 14)
	UiKit.list(ledger, "y", 2)
	local function ledgerRow(labelText, layoutOrder)
		local r = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = layoutOrder }, ledger)
		UiKit.Label(r, labelText, "BodySmall", { Size = UDim2.new(0.5, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.None, TextYAlignment = Enum.TextYAlignment.Center })
		local value = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X }, r)
		UiKit.list(value, "x", 6, { VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right })
		return value
	end
	UiKit.Currency(ledgerRow("Price", 1), currency, price.amount, { plain = true, textSize = 17 })
	local balanceDisplay = UiKit.Currency(ledgerRow("Your " .. currency, 2), currency, balance, { plain = true, textSize = 17 })
	local afterSlot = ledgerRow("After purchase", 3)
	local afterDisplay = UiKit.Currency(afterSlot, currency, math.max(0, balance - price.amount), { plain = true, textSize = 17 })
	local shortLabel = new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = Fonts.BodyBold,
		TextSize = 15,
		TextColor3 = Color.StateDanger,
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		Visible = false,
		LayoutOrder = 0,
	}, afterSlot)

	-- the status strip replaces the ledger after a result
	local status = UiKit.Inset(content, { Name = "Status", Position = UDim2.fromOffset(0, areaTop), Size = UDim2.new(1, 0, 0, 84), Visible = false })
	UiKit.pad(status, 10, 14, 10, 14)
	local statusGlyphHolder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(22, 22) }, status)
	local statusText = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -34, 1, 0) }, status)
	UiKit.list(statusText, "y", 2)
	local statusTitle = UiKit.Label(statusText, "", "H3", { LayoutOrder = 1 })
	local statusBody = UiKit.Label(statusText, "", "BodySmall", { LayoutOrder = 2 })

	local actions = new("Frame", { Name = "Actions", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 48) }, content)
	UiKit.list(actions, "x", 10, { HorizontalAlignment = Enum.HorizontalAlignment.Right })

	local api = { panel = panel, state = nil }
	local modalName = "Purchase" .. tostring(os.clock())
	UiKit.pushModal(modalName)
	scrim.Destroying:Connect(function()
		UiKit.popModal(modalName)
	end)
	local closed = false
	local connection
	local cancel, primary

	local function close(bought)
		if closed or api.state == "pending" then
			return
		end
		closed = true
		connection:Disconnect()
		UiKit.popModal(modalName)
		GuiService.SelectedObject = nil
		tween(scrim, UiKit.Motion.fast, { BackgroundTransparency = 1 })
		panel.Visible = false
		task.delay(UiKit.Motion.fast, function()
			scrim:Destroy()
		end)
		if opts.onClose then
			opts.onClose(bought == true)
		end
	end
	api.close = close

	local function showStatus(kind, title, body)
		ledger.Visible = false
		status.Visible = true
		statusGlyphHolder:ClearAllChildren()
		local style = NOTICE_KINDS[kind]
		UiKit.Glyph(statusGlyphHolder, style.glyph, style.color, 20)
		statusTitle.Text = title
		statusTitle.TextColor3 = style.color
		statusBody.Text = body
	end

	function api.setState(state, message)
		api.state = state
		-- keep the main button's width steady while its label changes (no jumping layout)
		if primary.AbsoluteSize.X > 0 then
			primary.Size = UDim2.fromOffset(math.max(primary.AbsoluteSize.X, 150), primary.Size.Y.Offset)
		end
		UiKit.SetBusy(primary, false)
		UiKit.SetDisabled(primary, false)
		UiKit.SetDisabled(cancel, false)
		cancel.Visible = true
		cancel.Text = "CANCEL"
		ledger.Visible = true
		status.Visible = false
		shortLabel.Visible = false
		afterDisplay.frame.Visible = true
		local buyText = string.format("Buy for %s %s", formatNumber(price.amount), currency)
		primary.Text = string.upper(buyText)
		primary:SetAttribute("BaseText", primary.Text)
		if state == "insufficient" then
			local short = price.amount - balance
			UiKit.SetDisabled(primary, true, string.format("You need %s more %s. Earn them by surviving nights.", formatNumber(short), currency))
			primary.Text = string.upper(string.format("Need %s more", formatNumber(short)))
			afterDisplay.frame.Visible = false
			shortLabel.Visible = true
			shortLabel.Text = string.format("Short by %s", formatNumber(short))
		elseif state == "owned" then
			UiKit.SetDisabled(primary, true, "You already own this. Find it in your BAG.")
			primary.Text = "ALREADY OWNED"
		elseif state == "pending" then
			UiKit.SetBusy(primary, true, "Buying...")
			UiKit.SetDisabled(cancel, true)
		elseif state == "success" then
			balanceDisplay.set(balance - price.amount)
			showStatus("success", "Bought", string.format("%s %s You have %s %s left.", opts.name or "The item", opts.successText or "is in your bag. Equip it from the BAG.", formatNumber(balance - price.amount), currency))
			cancel.Visible = false
			primary.Text = "DONE"
		elseif state == "error" then
			showStatus("error", "Purchase didn't go through", message or "Nothing was spent. Try again in a moment.")
			cancel.Text = "CLOSE"
			primary.Text = "TRY AGAIN"
		end
		if usingGamepad() then
			GuiService.SelectedObject = if primary:GetAttribute("Disabled") or state == "pending" then cancel else primary
		end
	end

	cancel = UiKit.Button(actions, "Cancel", { name = "CancelButton", variant = "secondary", layoutOrder = 1, onClick = function()
		close(false)
	end })
	primary = UiKit.Button(actions, "Buy", { name = "PrimaryButton", variant = "primary", minWidth = 150, layoutOrder = 2, onClick = function()
		if api.state == "success" then
			close(true)
		elseif api.state == "default" or api.state == "error" then
			api.setState("pending")
			if opts.onPurchase then
				opts.onPurchase(function(ok, why)
					if closed then
						return
					end
					if ok then
						api.setState("success")
					else
						api.setState("error", why)
					end
				end)
			end
		end
	end })
	api.cancel = cancel
	api.primary = primary

	connection = UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
			close(api.state == "success")
		end
	end)

	if opts.owned then
		api.setState("owned")
	elseif balance < price.amount then
		api.setState("insufficient")
	else
		api.setState("default")
	end
	UiKit.Open(panel)
	return api
end

-- Designed states instead of blank space. kind: loading | empty | error | success | offline
function UiKit.StateView(parent, kind, opts)
	opts = opts or {}
	local frame = new("Frame", {
		Name = "State_" .. kind,
		BackgroundTransparency = 1,
		Size = opts.size or UDim2.fromScale(1, 1),
		LayoutOrder = opts.layoutOrder or 0,
	}, parent)
	local column = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -32, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, frame)
	UiKit.list(column, "y", 8, { HorizontalAlignment = Enum.HorizontalAlignment.Center })
	local color = ({
		loading = Color.AccentLighthouse,
		empty = Color.AccentSea,
		error = Color.StateDanger,
		success = Color.StateSuccess,
		offline = Color.StateWarning,
	})[kind] or Color.AccentSea
	local ring = new("Frame", { Name = "Emblem", BackgroundTransparency = 1, Size = UDim2.fromOffset(48, 48), LayoutOrder = 1 }, column)
	UiKit.round(ring, 24)
	UiKit.border(ring, color, 2, if kind == "empty" then 0.45 else 0)
	if kind == "loading" then
		local lamp = new("Frame", {
			BackgroundColor3 = color,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(10, 10),
			ZIndex = 2,
		}, ring)
		UiKit.round(lamp, 5)
		local spinner = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, ring)
		local beam = new("Frame", {
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 0, 0.5, -2),
			Size = UDim2.new(0.5, -4, 0, 4),
		}, spinner)
		new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }, beam)
		local connection = RunService.RenderStepped:Connect(function(dt)
			if frame.Parent and frame.Visible then
				spinner.Rotation = (spinner.Rotation + dt * 160) % 360
			end
		end)
		frame.Destroying:Connect(function()
			connection:Disconnect()
		end)
	else
		local glyphKind = ({ empty = "diamond", error = "close", success = "check", offline = "warning" })[kind] or "diamond"
		local g = UiKit.Glyph(ring, glyphKind, color, if glyphKind == "diamond" then 14 else 18)
		g.AnchorPoint = Vector2.new(0.5, 0.5)
		g.Position = UDim2.fromScale(0.5, 0.5)
	end
	if opts.title then
		UiKit.Label(column, opts.title, "H3", { LayoutOrder = 2, TextXAlignment = Enum.TextXAlignment.Center })
	end
	if opts.body then
		UiKit.Label(column, opts.body, "BodySmall", { LayoutOrder = 3, TextXAlignment = Enum.TextXAlignment.Center })
	end
	if opts.actionText then
		UiKit.Button(column, opts.actionText, { variant = "secondary", size = "sm", layoutOrder = 4, onClick = opts.onAction })
	end
	return frame
end

---------------------------------------------------------------------
-- MOTION: small rise + settle on open, quick dip on close. Nothing loops or floats.
---------------------------------------------------------------------

function UiKit.Open(frame)
	local rest = frame:GetAttribute("RestPosition")
	if not rest then
		rest = frame.Position
		frame:SetAttribute("RestPosition", rest)
	end
	frame.Visible = true
	local scale = frame:FindFirstChild("OpenScale") or new("UIScale", { Name = "OpenScale" }, frame)
	scale.Scale = 0.97
	frame.Position = rest + UDim2.fromOffset(0, 10)
	tween(scale, UiKit.Motion.base, { Scale = 1 })
	tween(frame, UiKit.Motion.base, { Position = rest })
end

function UiKit.Close(frame, onDone)
	local rest = frame:GetAttribute("RestPosition") or frame.Position
	local scale = frame:FindFirstChild("OpenScale") or new("UIScale", { Name = "OpenScale" }, frame)
	tween(scale, UiKit.Motion.fast, { Scale = 0.98 })
	task.delay(UiKit.Motion.fast, function()
		frame.Visible = false
		frame.Position = rest
		scale.Scale = 1
		if onDone then
			onDone()
		end
	end)
end

-- WCAG contrast ratio between two colors (used by the style guide's contrast check)
function UiKit.contrast(a, b)
	local function lum(c)
		local function ch(v)
			return if v <= 0.03928 then v / 12.92 else ((v + 0.055) / 1.055) ^ 2.4
		end
		return 0.2126 * ch(c.R) + 0.7152 * ch(c.G) + 0.0722 * ch(c.B)
	end
	local l1, l2 = lum(a), lum(b)
	if l1 < l2 then
		l1, l2 = l2, l1
	end
	return (l1 + 0.05) / (l2 + 0.05)
end


return true
