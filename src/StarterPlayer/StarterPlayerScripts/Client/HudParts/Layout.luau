-- HudParts/Layout (S5.6): where every HUD element sits and how big it is, landscape first, responsive at
-- every size, inside the Roblox safe areas. Phones get the "compact" layout and the slim gauges.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Client = script.Parent.Parent
local UiKit = require(Client:WaitForChild("UiKit"))

local Layout = {}

local ISLAND_PHASES = { Prologue = true, Day = true, Night = true, Victory = true, Defeat = true }

-- w: the HUD elements (HudParts/Build); S: shared HUD state (S.compact is written here, S.simulated and
-- S.bossBars are read); after(): the HUD's own refreshes after a layout pass (weapon slot, lamp pill, sky).
-- Returns apply(), stacking(), isTouch().
function Layout.init(w, S, cards, after)
	local state = ReplicatedStorage:WaitForChild("GameState")
	local hudRoot, promptRoot = w.hudRoot, w.promptRoot
	local topCenter, topRight = w.topCenter, w.topRight
	local alarm, bottom, sideStack = w.alarm, w.bottom, w.sideStack

	local function updateStacking()
		-- notices start under the top-center cluster (and the alarm), pickups under the top-right cluster
		local top = hudRoot.AbsolutePosition.Y
		alarm.AnchorPoint = Vector2.new(0.5, 0)
		local alarmOn = alarm.Visible
		local noticeTop
		-- Glass HUD (Oct 13): the voyage pill lives in the top bar row, so top-center is the lamp's slot.
		-- When the lamp goes out, the alarm banner takes the top and the fuel gauge steps aside (every size).
		local onIsland = ISLAND_PHASES[state:GetAttribute("Phase")] == true
		w.voyage.Visible = true
		w.fuelPlate.Visible = onIsland and not alarmOn
		w.bossList.Visible = onIsland and not (S.compact and alarmOn)
		alarm.Position = UDim2.new(0.5, 0, 0, 8)
		topCenter.Position = UDim2.new(0.5, 0, 0, if alarmOn then 8 + alarm.AbsoluteSize.Y + 6 else 8)
		if S.compact then
			-- phones: one notice at a time, at the top (under the alarm when it shows)
			noticeTop = if alarmOn then 8 + alarm.AbsoluteSize.Y + 6 else 8
		else
			local centerBottom = topCenter.AbsolutePosition.Y + topCenter.AbsoluteSize.Y - top
			noticeTop = centerBottom + 8
		end
		promptRoot:SetAttribute("NoticeTop", if w.gui.Enabled then noticeTop else 140)
		-- keep notices already on screen in the right place after a layout change (e.g. rotation)
		local toastStack = promptRoot:FindFirstChild("ToastStack")
		if toastStack then
			toastStack.Position = UDim2.new(0.5, 0, 0, promptRoot:GetAttribute("NoticeTop"))
			toastStack.Size = UDim2.fromOffset(promptRoot:GetAttribute("NoticeWidth") or math.clamp(promptRoot.AbsoluteSize.X * 0.5, 260, 400), 0)
		end
		local rightBottom = topRight.AbsolutePosition.Y + topRight.AbsoluteSize.Y - top
		sideStack.Position = UDim2.new(1, -12, 0, rightBottom + 8)
		if sideStack.Visible then
			rightBottom = sideStack.AbsolutePosition.Y + sideStack.AbsoluteSize.Y - top
		end
		hudRoot:SetAttribute("PickupTop", rightBottom + 10)
	end

	local function isTouch()
		if S.simulated then
			return S.simulated.touch
		end
		return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	end

	-- SLIM (owner, Oct 13: "the lamp fuel bar is too big… make the side bars take less area on mobile")
	local function gaugeParts(g)
		local cap = g:FindFirstChild("Cap")
		local body
		for _, c in g:GetChildren() do
			if c:IsA("Frame") and c ~= cap then
				body = c
			end
		end
		return cap, body
	end
	local function scaleCap(cap, s)
		if cap then
			local sc = cap:FindFirstChild("SlimScale") or UiKit.new("UIScale", { Name = "SlimScale" }, cap)
			sc.Scale = s
		end
	end
	local function scaleText(root, s)
		for _, d in root:GetDescendants() do
			if d:IsA("TextLabel") then
				if d:GetAttribute("BaseTextSize") == nil then
					d:SetAttribute("BaseTextSize", d.TextSize)
				end
				d.TextSize = math.floor(d:GetAttribute("BaseTextSize") * s + 0.5)
			end
		end
	end
	local function setPad(frame, v, h)
		local p = frame:FindFirstChildOfClass("UIPadding")
		if p then
			p.PaddingTop, p.PaddingBottom = UDim.new(0, v), UDim.new(0, v)
			p.PaddingLeft, p.PaddingRight = UDim.new(0, h), UDim.new(0, h)
		end
	end
	local function slimGauge(g, height, capBase, bodyX, barName, barHeight, textScale)
		g.Size = UDim2.new(1, 0, 0, height)
		local cap, body = gaugeParts(g)
		scaleCap(cap, height / capBase)
		if body then
			body.Position = UDim2.fromOffset(bodyX, 0)
			body.Size = UDim2.new(1, -bodyX, 1, 0)
			local bar = body:FindFirstChild(barName)
			if bar then
				bar.Size = UDim2.new(1, 0, 0, barHeight)
				local mark = bar:FindFirstChild("CriticalMark")
				if mark then
					mark.Size = UDim2.fromOffset(2, barHeight + 4) -- stays inside the gauge, clear of the label
				end
			end
			scaleText(body, textScale)
		end
	end

	local function slimLayout()
		local compact = S.compact
		-- health (left) and tower (right): smaller on phones
		if compact then
			slimGauge(w.health.frame, 28, 38, 34, "Track", 9, 0.85)
			slimGauge(w.tower.frame, 28, 42, 34, "Blocks", 10, 0.85)
		else
			slimGauge(w.health.frame, 38, 38, 46, "Track", 14, 1)
			slimGauge(w.tower.frame, 42, 42, 50, "Blocks", 20, 1)
		end
		local sideW = if compact then 146 else topRight.Size.X.Offset
		w.topLeft.Size = UDim2.fromOffset(if compact then 150 else w.topLeft.Size.X.Offset, 0)
		topRight.Size = UDim2.fromOffset(sideW, 0)
		sideStack.Size = UDim2.fromOffset(sideW, 0)
		setPad(w.leftPlate, if compact then 6 else 10, if compact then 9 else 12)
		setPad(w.rightPlate, if compact then 6 else 10, if compact then 9 else 12)
		setPad(w.lampPill, if compact then 5 else 9, if compact then 9 else 12)
		scaleText(w.lampPill, if compact then 0.82 else 1)
		if w.shells then
			scaleText(w.shells.frame, if compact then 0.85 else 1)
			if compact then
				w.shells.frame.Size = UDim2.fromOffset(0, 22)
			end
		end
		-- voyage chip
		w.voyageTitle.TextSize = if compact then 14 else 18
		w.timerText.TextSize = if compact then 14 else 16
		-- lamp fuel: one slim line in the top-bar row (all sizes)
		local fuelFrame = w.fuel.frame
		fuelFrame.Size = UDim2.new(1, 0, 0, 30)
		local cap, body = gaugeParts(fuelFrame)
		scaleCap(cap, 30 / 58)
		if body then
			body.Position = UDim2.fromOffset(38, 0)
			body.Size = UDim2.new(1, -38, 1, 0)
			for _, c in body:GetChildren() do
				if c.Name == "Scale" then
					c.Visible = false
				elseif c.Name == "Reservoir" then
					c.Position = UDim2.fromOffset(0, 19)
					c.Size = UDim2.new(1, 0, 0, 9)
				elseif c:IsA("GuiObject") then
					c.Size = UDim2.new(c.Size.X.Scale, c.Size.X.Offset, 0, 16)
				end
			end
			scaleText(body, 0.8)
		end
		setPad(w.fuelPlate, 6, 10)
		local vw = w.topBarGui.AbsoluteSize.X
		if vw > 0 then
			local leftEdge = 270 -- Roblox's own top-bar buttons end about here
			local rightEdge = vw - (w.topBar.AbsoluteSize.X + 24)
			local fw = math.clamp(rightEdge - leftEdge - 16, 160, if compact then 230 else 340)
			w.fuelPlate.Size = UDim2.fromOffset(fw, 0)
			local center = vw / 2
			if center - fw / 2 < leftEdge + 8 or center + fw / 2 > rightEdge - 8 then
				center = (leftEdge + rightEdge) / 2
			end
			w.topFuelBar.Position = UDim2.new(0, center, 0, 10)
		end
	end

	local function glassLayout()
		local size = hudRoot.AbsoluteSize
		local compact = S.compact
		w.voyageSub.Visible = false
		w.voyage.Size = UDim2.fromOffset(0, if compact then 38 else 44)
		-- weapon slot
		local slotW, slotH, well = 96, 106, 56
		if compact then
			slotW, slotH, well = 74, 80, 40
		end
		w.weaponSlot.Size = UDim2.fromOffset(slotW, slotH)
		w.weaponSlot.Position = UDim2.new(0.5, 0, 1, if compact then -6 else -12)
		w.weaponWell.Size = UDim2.fromOffset(well, well)
		w.weaponWell.Position = UDim2.new(0.5, 0, 0, if compact then 4 else 8)
		w.weaponName.TextSize = if compact then 12 else 14
		w.weaponName.Position = UDim2.new(0, 4, 1, if compact then -32 else -40)
		w.weaponName.Size = UDim2.new(1, -8, 0, if compact then 26 else 32)
		-- Shells: bottom-right above the jump button (bigger screens), under health on phones
		if w.shellsPill then
			if compact then
				w.shells.frame.Parent = w.leftPlate
				w.shells.frame.LayoutOrder = 3
				w.shells.frame.Size = UDim2.fromOffset(0, 30)
				w.shellsPill.Visible = false
			else
				w.shells.frame.Parent = w.shellsPill
				w.shells.frame.Size = UDim2.fromOffset(0, 50)
				w.shellsPill.Visible = true
				local lift = 16
				if isTouch() then
					lift = if math.min(size.X, size.Y) <= 500 then 100 else 228
				end
				w.shellsPill.Position = UDim2.new(1, -12, 1, -lift)
			end
		end
		slimLayout()
		after()
	end

	local function applyLayout()
		local size = hudRoot.AbsoluteSize
		if size.X <= 0 then
			return
		end
		local bp = UiKit.Breakpoint(size)
		local touch = isTouch()
		S.compact = bp == "phone"
		local compact = S.compact
		local leftW, fuelW, rightW, bossW, alarmW
		if compact then
			leftW, fuelW, rightW, bossW, alarmW = 178, 210, 174, 234, 300
		elseif bp == "tablet" then
			leftW, fuelW, rightW, bossW, alarmW = 250, 320, 250, 360, 420
		else
			leftW, fuelW, rightW, bossW, alarmW = 290, 380, 290, 440, 460
		end
		w.topLeft.Size = UDim2.fromOffset(leftW, 0)
		topRight.Size = UDim2.fromOffset(rightW, 0)
		topCenter.Size = UDim2.fromOffset(math.max(fuelW, bossW) + 24, 0)
		w.fuelPlate.Size = UDim2.fromOffset(fuelW + 24, 0)
		w.bossList.Size = UDim2.fromOffset(bossW, 0)
		promptRoot:SetAttribute("NoticeLimit", if compact then 1 else nil)
		promptRoot:SetAttribute("NoticeWidth", if compact then 260 else nil)
		hudRoot:SetAttribute("PickupLimit", if compact then 2 else nil)
		-- boss bars: slimmer on phones; two or more sit side by side so the column stays short
		local bossCount = 0
		for _ in S.bossBars do
			bossCount += 1
		end
		local bossLayout = w.bossList:FindFirstChildOfClass("UIListLayout")
		local sideBySide = compact and bossCount > 1
		bossLayout.FillDirection = if sideBySide then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
		for _, bar in w.bossList:GetChildren() do
			local bossName, bossReadout, track = bar:FindFirstChild("BossName"), bar:FindFirstChild("BossReadout"), bar:FindFirstChild("Track")
			if bossName and bossReadout and track then
				bar.Size = if sideBySide then UDim2.new(0.5, -3, 0, 0) else UDim2.new(1, 0, 0, 0)
				bossName.TextSize = if compact then 14 else 17
				bossReadout.TextSize = if compact then 13 else 15
				bossName.Size = UDim2.new(bossName.Size.X.Scale, bossName.Size.X.Offset, 0, if compact then 16 else 20)
				bossReadout.Size = UDim2.new(0, 0, 0, if compact then 16 else 20)
				track.Position = UDim2.fromOffset(0, if compact then 20 else 26)
				track.Size = UDim2.new(1, 0, 0, if compact then 8 else 12)
				local pad = bar:FindFirstChildOfClass("UIPadding")
				if pad then
					pad.PaddingTop = UDim.new(0, if compact then 6 else 8)
					pad.PaddingBottom = UDim.new(0, if compact then 6 else 9)
					pad.PaddingLeft = UDim.new(0, if compact then 8 else 12)
					pad.PaddingRight = UDim.new(0, if compact then 8 else 12)
				end
			end
		end
		alarm.Size = UDim2.fromOffset(alarmW, if compact then 60 else 76)
		w.alarmBody.TextSize = if compact then 13 else 15
		w.alarmTitle.TextSize = if compact then 20 else 24
		w.voyageSub.Visible = not compact
		w.warningSub.Visible = not compact
		w.voyage.Size = UDim2.fromOffset(0, if compact then 34 else 40)
		-- the weapon now lives in its own slot at the bottom (glassLayout sizes it)
		-- prompts: between the joystick zone (left 40%) and the jump button; above the hotbar on desktop
		local bottomLayout = bottom:FindFirstChildOfClass("UIListLayout")
		if compact then
			-- from just right of the joystick zone (40% width) to the right edge; ends above the jump button
			bottom.AnchorPoint = Vector2.new(0, 1)
			bottom.Position = UDim2.new(0.4, 8, 1, -92)
			bottom.Size = UDim2.new(0.6, -20, 0, 0)
			bottomLayout.FillDirection = Enum.FillDirection.Horizontal
			bottomLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			for _, c in { cards.primary, cards.secondary } do
				c.button.Size = UDim2.new(0.5, -4, 0, 52)
			end
		else
			bottom.AnchorPoint = Vector2.new(0.5, 1)
			bottom.Size = UDim2.fromOffset(330, 0)
			bottom.Position = if touch then UDim2.new(0.6, 0, 1, -220) else UDim2.new(0.5, 0, 1, -126) -- above the weapon slot
			bottomLayout.FillDirection = Enum.FillDirection.Vertical
			bottomLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			cards.primary.button.Size = UDim2.new(1, 0, 0, 56)
			cards.secondary.button.Size = UDim2.new(1, 0, 0, 46)
		end
		w.cannonCard.Parent = sideStack
		w.carryCard.Parent = sideStack
		sideStack.Size = UDim2.fromOffset(rightW, 0)
		w.cannonHead.Visible = not compact -- phones: ammo row only (level is on the upgrade prompt)
		-- the top-right cluster starts at the top (Oct 13: the BAG bar became a round icon at the bottom right)
		topRight.Position = UDim2.new(1, -12, 0, 8)
		glassLayout()
		updateStacking()
	end

	return { apply = applyLayout, stacking = updateStacking, isTouch = isTouch }
end

return Layout
