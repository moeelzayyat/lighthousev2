-- Hud (client): the production gameplay HUD, built on UiKit v2.1 in its night-navy glass variant (S5.6:
-- drawn as glass when built; no repaint pass).
--
-- Presentation only. Every value shown comes from an authoritative source:
--   GameState attributes  Phase, Night, TimeLeft, Reason (GameState) · Fuel, MaxFuel, DarkSeconds,
--                         BeamMode, KeeperUserId (LampService) · Integrity, MaxIntegrity (TowerService)
--                         Shells (UpgradeService) · BigWarning (GameState) · Bosses folder (CreatureService)
--   Player                Humanoid Health / MaxHealth · equipped Tool (WeaponId) · CarryingOil · SaveUnavailable
--   Cannon pads           CannonLevel, Ammo, MaxAmmo, AmmoName, CannonHealth (DefenseService)
--   Remotes               Notify (server messages) · LootCollected (pickups)
--   ProximityPrompts      drawn by HudParts/Prompts in the shared style (Style = Custom)
--
-- Parts (HudParts/): Build (every element), Prompts, Bosses, Layout (sizes and places, phones included),
-- Simulator (Studio only). This script binds values to them and wires the events.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Items = require(Shared:WaitForChild("Items"))
local Weapons = require(Shared:WaitForChild("Weapons"))
local SoundFx = require(Shared:WaitForChild("SoundFx"))
local StatPipeline = require(Shared:WaitForChild("StatPipeline")) -- S5.7
local UiKit = require(script.Parent:WaitForChild("UiKit"))
local InputController = require(script.Parent:WaitForChild("InputController")) -- S2.6
local Parts = script.Parent:WaitForChild("HudParts")
local Build = require(Parts:WaitForChild("Build"))
local Prompts = require(Parts:WaitForChild("Prompts"))
local Bosses = require(Parts:WaitForChild("Bosses"))
local Layout = require(Parts:WaitForChild("Layout"))

local state = ReplicatedStorage:WaitForChild("GameState")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local GLASS = UiKit.GLASS

local ISLAND_PHASES = { Prologue = true, Day = true, Night = true, Victory = true, Defeat = true }
local LIT_PHASES = { Prologue = true, Day = true, Night = true }

-- Our health gauge replaces Roblox's
task.spawn(function()
	for _ = 1, 20 do
		if pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Health, false) then
			return
		end
		task.wait(0.5)
	end
end)

-- Everything below is built in the glass variant (UiKit.endGlass at the end of the build section)
UiKit.beginGlass()
local C = UiKit.palette()
local w = Build.build()
local gui, hudRoot, promptRoot = w.gui, w.hudRoot, w.promptRoot
local health, fuel, tower, shells = w.health, w.fuel, w.tower, w.shells
local voyageTitle, voyageSub, voyageScale, timerChip, timerText = w.voyageTitle, w.voyageSub, w.voyageScale, w.timerChip, w.timerText
local pips, pipFrames = w.pips, w.pipFrames
local alarm, alarmStroke, alarmBody, alarmCount = w.alarm, w.alarmStroke, w.alarmBody, w.alarmCount
local beamRow, beamGlyph, beamText, beamTag, keeperText = w.beamRow, w.beamGlyph, w.beamText, w.beamTag, w.keeperText
local keeperRow, focusWarn, beamButton, leaveButton = w.keeperRow, w.focusWarn, w.beamButton, w.leaveButton
local weaponRow, weaponName, weaponState, weaponScale = w.weaponRow, w.weaponName, w.weaponState, w.weaponScale
local cooldownTrack, cooldownFill = w.cooldownTrack, w.cooldownFill
local cannonCard, cannonTitle, cannonHull, cannonAmmo = w.cannonCard, w.cannonTitle, w.cannonHull, w.cannonAmmo
local carryCard, sideStack = w.carryCard, w.sideStack

-- shared with HudParts/Layout and HudParts/Simulator
local S = { compact = false, simulated = nil, bossBars = {} }
local layout -- HudParts/Layout (set once the parts below exist)
local function applyLayout()
	if layout then
		layout.apply()
	end
end

local cards = Prompts.init(w.bottom)
local renderPrompts = cards.render

-- beam glyphs: WIDE = three rays fanning out, FOCUSED = one long ray (shape differs, not only color)
local function drawBeamGlyph(mode, color)
	beamGlyph:ClearAllChildren()
	local function ray(length, rotation, thick)
		local r = UiKit.new("Frame", {
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 3 + math.cos(math.rad(rotation)) * length / 2, 0.5, math.sin(math.rad(rotation)) * length / 2),
			Size = UDim2.fromOffset(length, thick),
			Rotation = rotation,
		}, beamGlyph)
		UiKit.round(r, thick)
	end
	if mode == "focused" then
		ray(19, 0, 4)
	elseif mode == "wide" then
		ray(17, -24, 2)
		ray(18, 0, 2)
		ray(17, 24, 2)
	elseif mode == "dark" then
		ray(16, 0, 2)
	end
	local dot = UiKit.new("Frame", {
		BackgroundColor3 = color,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(7, 7),
	}, beamGlyph)
	UiKit.round(dot, 4)
end

---------------------------------------------------------------------
-- BINDINGS
---------------------------------------------------------------------

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local inputMode = InputController.mode -- S2.6: one shared answer (was a local copy)

local function keySuffix(key, padKey)
	local mode = inputMode()
	if mode == "keyboard" then
		return "  ·  " .. key
	elseif mode == "gamepad" and padKey then
		return "  ·  " .. padKey -- batch 1: controller hints for the Keeper buttons
	end
	return ""
end

-- voyage status ------------------------------------------------------
local lastPhase
local function refreshVoyage()
	local phase = state:GetAttribute("Phase") or "Waiting"
	local night = state:GetAttribute("Night") or 0
	local total = state:GetAttribute("TotalNights") or Config.NIGHTS_TO_WIN -- S2.1: the voyage definition's length
	local timeLeft = state:GetAttribute("TimeLeft") or 0
	local title, sub, showTimer = "", "", true
	if phase == "Waiting" then
		title, sub, showTimer = "WAITING FOR KEEPERS", "Walk onto the ship to join the crew", false
	elseif phase == "Intermission" then
		title, sub = "SETTING SAIL", "The crew is boarding"
	elseif phase == "Prologue" then
		title, sub, showTimer = "THE STORM HITS", "Restore the light", false
	elseif phase == "Day" then
		title, sub = (if total > 0 then string.format("DAY %d OF %d", night, total) else string.format("DAY %d", night)), "Prepare for the night" -- total 0 = Endless Storm
	elseif phase == "Night" then
		title, sub = (if total > 0 then string.format("NIGHT %d OF %d", night, total) else string.format("NIGHT %d", night)), "Keep the light alive"
	elseif phase == "Victory" then
		title, sub, showTimer = "VICTORY", "The light survived", false
	elseif phase == "Defeat" then
		local reason = state:GetAttribute("Reason") or ""
		if #reason > 52 then
			reason = reason:sub(1, 50) .. "..."
		end
		title, sub, showTimer = "DEFEAT", reason, false
	end
	voyageTitle.Text = title
	voyageSub.Text = sub
	voyageTitle.TextColor3 = if phase == "Defeat" then C.StateDanger elseif phase == "Victory" then C.AccentLighthouse else C.TextPrimary
	timerChip.Visible = showTimer
	timerText.Text = formatTime(timeLeft)
	timerText.TextColor3 = if phase == "Night" and timeLeft <= 10 then C.AccentLighthouseSoft else C.TextPrimary
	pips.Visible = night > 0 and ISLAND_PHASES[phase] == true
	for i, pip in pipFrames do
		local done = i < night or (i == night and phase == "Victory")
		local current = i == night and (phase == "Night" or phase == "Day" or phase == "Defeat")
		pip.d.BackgroundTransparency = if done or (current and phase ~= "Day") then 0 else 1
		pip.d.BackgroundColor3 = if current then (if phase == "Defeat" then C.StateDanger else C.AccentLighthouse) else C.TextSecondary
		pip.stroke.Color = if current then C.AccentLighthouse elseif done then C.TextSecondary else GLASS.glow
	end
	if phase ~= lastPhase then
		if lastPhase ~= nil then
			voyageScale.Scale = 1.08 -- a short settle marks the transition
			UiKit.tween(voyageScale, UiKit.Motion.slow, { Scale = 1 })
		end
		lastPhase = phase
	end
end

-- lamp fuel, blackout alarm, beam ------------------------------------
local lastAlarmSecond
local function refreshAlarm()
	local dark = state:GetAttribute("DarkSeconds") or 0
	local phase = state:GetAttribute("Phase")
	if dark > 0 and LIT_PHASES[phase] then
		local left = math.max(0, math.ceil(Config.DARK_GRACE_SECONDS - dark))
		alarm.Visible = true
		if phase == "Prologue" then
			alarmBody.Text = "Carry oil to the fuel tank behind the lighthouse."
			alarmCount.Text = ""
		else
			alarmBody.Text = "Refuel the fuel tank or the voyage is lost."
			alarmCount.Text = left .. "s"
		end
		local beat = left % 2 == 0 -- one pulse per second, nothing continuous
		alarmStroke.Color = if beat then C.StateDanger else C.TextPrimary
		alarmCount.TextColor3 = if beat then C.StateDanger else C.TextPrimary
		if lastAlarmSecond ~= left then
			lastAlarmSecond = left
			SoundFx.play2D("denied", 1.4)
		end
	else
		alarm.Visible = false
		lastAlarmSecond = nil
	end
end

local function refreshBeam()
	local phase = state:GetAttribute("Phase")
	local mode = state:GetAttribute("BeamMode")
	local keeperId = state:GetAttribute("KeeperUserId") or 0
	local dark = (state:GetAttribute("DarkSeconds") or 0) > 0 or (state:GetAttribute("Fuel") or 0) <= 0
	beamRow.Visible = LIT_PHASES[phase] == true
	local text, glyph, color
	if dark then
		text, glyph, color = "LAMP DARK", "dark", C.StateDanger
	elseif keeperId == 0 then
		text, glyph, color = "BEAM · AUTO-SWEEP", "wide", C.AccentSea
	elseif mode == "focused" then
		text, glyph, color = "BEAM · FOCUSED", "focused", C.AccentLighthouse
	else
		text, glyph, color = "BEAM · WIDE", "wide", C.TextPrimary
	end
	beamText.Text = text
	beamText.TextColor3 = color
	drawBeamGlyph(glyph, color)
	beamTag.Visible = not dark and keeperId ~= 0 and mode == "focused"
	beamTag.Text = string.format("%sX FUEL", tostring(Config.FOCUSED_FUEL_MULTIPLIER or 2.5))
	local keeper = keeperId ~= 0 and Players:GetPlayerByUserId(keeperId)
	keeperText.Visible = (keeper and keeper ~= player and beamRow.Visible) == true
	keeperText.Text = if keeper then "Keeper: " .. keeper.DisplayName else ""
	-- keeper controls
	local me = keeperId == player.UserId
	keeperRow.Visible = me
	focusWarn.Visible = me and mode == "focused" and not S.compact
	beamButton.Text = (if mode == "focused" then "WIDE BEAM" else "FOCUS BEAM") .. keySuffix("F", "Y")
	beamButton:SetAttribute("BaseText", beamButton.Text)
	leaveButton.Text = "LEAVE LAMP" .. keySuffix("Q", "B")
	leaveButton:SetAttribute("BaseText", leaveButton.Text)
end

local function refreshFuel()
	local max = state:GetAttribute("MaxFuel") or Config.MAX_FUEL
	fuel.set((state:GetAttribute("Fuel") or 0) / math.max(1, max))
	refreshAlarm()
	refreshBeam()
end

local function refreshTower()
	local max = state:GetAttribute("MaxIntegrity") or Config.MAX_INTEGRITY
	tower.set((state:GetAttribute("Integrity") or 0) / math.max(1, max))
end

-- shells ----------------------------------------------------------------
local lastShells = state:GetAttribute("Shells") or 0
local function refreshShells()
	if shells then
		local n = state:GetAttribute("Shells") or 0
		shells.set(n, n > lastShells)
		lastShells = n
	end
end

-- player health -------------------------------------------------------
local humanoidConnections = {}
local function bindHumanoid(character)
	for _, c in humanoidConnections do
		c:Disconnect()
	end
	table.clear(humanoidConnections)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end
	health.setNote(nil)
	health.setMax(humanoid.MaxHealth)
	health.reset(humanoid.Health)
	table.insert(humanoidConnections, humanoid.HealthChanged:Connect(function(value)
		health.set(value)
	end))
	table.insert(humanoidConnections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		health.setMax(humanoid.MaxHealth)
		health.set(humanoid.Health)
	end))
	table.insert(humanoidConnections, humanoid.Died:Connect(function()
		health.setNote("HEALTH · DOWN")
		health.set(0)
	end))
end

-- weapon ---------------------------------------------------------------
local shownWeaponId
local cooldownConnection
local function findWeapon(container)
	if not container then
		return nil
	end
	for _, t in container:GetChildren() do
		if t:IsA("Tool") and t:GetAttribute("WeaponId") then
			return t
		end
	end
	return nil
end

local function startCooldown(id)
	local stats = Weapons[id] and StatPipeline.weapon(id)
	if not stats or not stats.cooldown or stats.cooldown <= 0 then
		return
	end
	local started, length = os.clock(), stats.cooldown
	cooldownTrack.Visible = true
	weaponState.Text = "RELOADING"
	weaponState.TextColor3 = C.AccentLighthouse
	if cooldownConnection then
		cooldownConnection:Disconnect()
	end
	cooldownConnection = RunService.RenderStepped:Connect(function()
		local alpha = (os.clock() - started) / length
		if alpha >= 1 then
			cooldownConnection:Disconnect()
			cooldownConnection = nil
			cooldownTrack.Visible = false
			weaponState.Text = "READY"
			weaponState.TextColor3 = C.AccentSea
			return
		end
		cooldownFill.Size = UDim2.fromScale(alpha, 1)
	end)
end

local function refreshWeapon()
	local held = findWeapon(player.Character)
	local stowed = if held then nil else findWeapon(player:FindFirstChildOfClass("Backpack"))
	local tool = held or stowed
	local isKeeper = (state:GetAttribute("KeeperUserId") or 0) == player.UserId
	weaponRow.Visible = tool ~= nil and not isKeeper
	if not tool then
		return
	end
	local id = tool:GetAttribute("WeaponId")
	if id ~= shownWeaponId then
		shownWeaponId = id
		w.weaponPreview:setItem(id)
		weaponName.Text = (Items[id] and Items[id].name) or tool.Name
		weaponScale.Scale = 1.06 -- switch feedback
		UiKit.tween(weaponScale, UiKit.Motion.base, { Scale = 1 })
	end
	if not tool:GetAttribute("HudHooked") then
		tool:SetAttribute("HudHooked", true)
		tool.Activated:Connect(function()
			if player:GetAttribute("MenuOpen") then
				return
			end
			startCooldown(tool:GetAttribute("WeaponId"))
		end)
	end
	weaponName.TextColor3 = if held then C.TextPrimary else C.TextSecondary
	if not cooldownConnection then
		weaponState.Text = if held then "IN HAND · READY"
			elseif inputMode() == "keyboard" then "STOWED · PRESS 1"
			else "STOWED · USE THE HOTBAR"
		weaponState.TextColor3 = if held then C.AccentSea else C.TextMuted
	end
end

-- cannon nearby ---------------------------------------------------------
local pads = {}
local function scanPads()
	table.clear(pads)
	local island = Workspace:FindFirstChild("Island")
	if not island then
		return
	end
	for _, d in island:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("CannonLevel") ~= nil then
			table.insert(pads, d)
		end
	end
end

local shownPad, shownAmmoType
local function refreshCannon()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local isKeeper = (state:GetAttribute("KeeperUserId") or 0) == player.UserId
	local best, bestDistance = nil, 14
	if root and not isKeeper and gui.Enabled then
		for _, pad in pads do
			if pad.Parent and (pad:GetAttribute("CannonLevel") or 0) > 0 then
				local distance = (pad.Position - root.Position).Magnitude
				if distance < bestDistance then
					best, bestDistance = pad, distance
				end
			end
		end
	end
	-- phones: the cannon's own floating label already shows its ammo, so the card stays hidden
	cannonCard.Visible = best ~= nil and not S.compact
	if not best then
		shownPad = nil
		return
	end
	local ammo, maxAmmo = best:GetAttribute("Ammo") or 0, math.max(1, best:GetAttribute("MaxAmmo") or 1)
	cannonTitle.Text = string.format("CANNON · LEVEL %d", best:GetAttribute("CannonLevel") or 1)
	local hull, hullMax = best:GetAttribute("CannonHealth") or 0, best:GetAttribute("CannonMaxHealth") or 0
	cannonHull.Text = if hullMax > 0 then string.format("Hull %d%%", math.floor(hull / hullMax * 100 + 0.5)) else ""
	cannonHull.TextColor3 = if hullMax > 0 and hull / hullMax < 0.35 then C.StateDanger else C.TextSecondary
	cannonAmmo.frame:FindFirstChild("Label").Text = string.upper(best:GetAttribute("AmmoName") or "Ammo")
	cannonAmmo.set(ammo / maxAmmo, if ammo == 0 then "EMPTY · BRING OIL" else string.format("%d / %d", ammo, maxAmmo))
	local ammoType = best:GetAttribute("AmmoType")
	if best == shownPad and ammoType ~= shownAmmoType then
		-- ammunition changed (for example Fire Shells loaded): flash the card frame once
		local stroke = cannonCard:FindFirstChildOfClass("UIStroke")
		stroke.Color = C.AccentLighthouse
		stroke.Transparency = 0
		task.delay(0.5, function()
			stroke.Color = GLASS.glow
			stroke.Transparency = 0.4
		end)
	end
	shownPad, shownAmmoType = best, ammoType
end

-- carried oil -------------------------------------------------------------
local function refreshCarry()
	local isKeeper = (state:GetAttribute("KeeperUserId") or 0) == player.UserId
	carryCard.Visible = gui.Enabled and player:GetAttribute("CarryingOil") == true and not isKeeper
		and not (S.compact and cannonCard.Visible)
	sideStack.Visible = carryCard.Visible or cannonCard.Visible
end

-- boss bars and the big-monster warning ---------------------------------
local function refreshWarning()
	w.warning.Visible = (state:GetAttribute("BigWarning") or "") ~= "" and next(S.bossBars) == nil and ISLAND_PHASES[state:GetAttribute("Phase")] == true
end
S.bossBars = Bosses.init(w.bossList, promptRoot, function()
	refreshWarning()
	task.defer(applyLayout)
end)

-- server messages and pickups (glass notices) --------------------------------
local function noticeKind(text)
	local lower = string.lower(text)
	if lower:find("lost") or lower:find("defeat") or lower:find("destroyed") or lower:find("broke") then
		return "danger"
	elseif lower:find("big") or lower:find("failing") or lower:find("low") or lower:find("hurry") or lower:find("warning") then
		return "warning"
	elseif lower:find("sold") or lower:find("survived") or lower:find("joined") or lower:find("pearl") or lower:find("bought") then
		return "success"
	end
	return "info"
end
local function toast(text, kind, opts)
	UiKit.Glass(function()
		UiKit.Toast(promptRoot, text, kind, opts)
	end)
end
local function pickup(opts)
	UiKit.Glass(function()
		UiKit.Pickup(hudRoot, opts)
	end)
end
remotes:WaitForChild("Notify").OnClientEvent:Connect(function(text)
	toast(text, noticeKind(text))
end)

remotes:WaitForChild("LootCollected").OnClientEvent:Connect(function(kind, value)
	if kind == "PearlBanked" then -- S2.2: this night's Pearls were banked (saved) at dawn
		local banked = tonumber(value) or 1
		SoundFx.play2D("lantern")
		pickup({ kind = "Pearls", amount = banked })
		toast(string.format("+%d Pearl%s banked", banked, if banked == 1 then "" else "s"), "success", { title = "Dawn" })
		return
	end
	SoundFx.play2D("loot", if kind == "Pearls" then 1.9 elseif kind == "BlackPearl" then 1.6 elseif kind == "SeaGlass" then 1.3 else 1)
	local amount = tonumber(value) or 1
	if kind == "Shells" then
		pickup({ kind = "Shells", amount = amount })
	elseif kind == "Pearls" then
		pickup({ kind = "Pearls", amount = amount })
	else
		local item = Items[kind]
		pickup({ kind = "loot", label = if item then item.name else kind, category = "Materials", amount = amount, key = "loot_" .. kind })
	end
end)

local warnedSave = false
local function refreshSaveWarning()
	if not warnedSave and gui.Enabled and player:GetAttribute("SaveUnavailable") then
		warnedSave = true
		toast("You can keep playing. Pearls earned now may not be kept.", "warning", { title = "Progress isn't saving", duration = 6 })
	end
end

---------------------------------------------------------------------
-- GLASS EXTRAS: top bar, sky, lamp pill, weapon slot (built in HudParts/Build)
---------------------------------------------------------------------

local function syncTopBar()
	w.topBarGui.Enabled = gui.Enabled
end
gui:GetPropertyChangedSignal("Enabled"):Connect(syncTopBar)
syncTopBar()

local function refreshSky()
	local phase = state:GetAttribute("Phase")
	local night = phase == "Night" or phase == "Prologue"
	w.orb.BackgroundColor3 = if night then Color3.fromRGB(232, 238, 255) else Color3.fromRGB(255, 204, 92)
	w.bite.Visible = night
	w.sky.Visible = ISLAND_PHASES[phase] == true
end
state:GetAttributeChangedSignal("Phase"):Connect(refreshSky)

local function toggleWeapon()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or player:GetAttribute("MenuOpen") then
		return
	end
	if (state:GetAttribute("KeeperUserId") or 0) == player.UserId then
		return -- hands on the lamp
	end
	if findWeapon(character) then
		humanoid:UnequipTools()
	else
		local tool = findWeapon(player:FindFirstChildOfClass("Backpack"))
		if tool then
			humanoid:EquipTool(tool)
		end
	end
end
w.weaponSlot.Activated:Connect(toggleWeapon)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.DPadDown then -- D-pad up opens the BAG
		toggleWeapon()
	end
end)

-- Roblox's own hotbar is replaced by the slot (Menus/Results respect this attribute)
player:SetAttribute("OwnWeaponSlot", true)
task.spawn(function()
	for _ = 1, 20 do
		if pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack, false) then
			return
		end
		task.wait(0.5)
	end
end)

local function refreshSlot()
	w.weaponSlot.Visible = weaponRow.Visible and not player:GetAttribute("MenuOpen")
	local held = findWeapon(player.Character) ~= nil
	w.slotStroke.Color = if held then C.AccentLighthouse else GLASS.glow
	w.slotStroke.Transparency = if held then 0.1 else 0.35
	w.slotKey.Visible = inputMode() == "keyboard"
end
weaponRow:GetPropertyChangedSignal("Visible"):Connect(refreshSlot)
weaponName:GetPropertyChangedSignal("TextColor3"):Connect(refreshSlot)
player:GetAttributeChangedSignal("MenuOpen"):Connect(refreshSlot)
UserInputService.LastInputTypeChanged:Connect(refreshSlot)

local function refreshLampPill()
	local phase = state:GetAttribute("Phase")
	w.lampPill.Visible = beamRow.Visible and ISLAND_PHASES[phase] == true
	local dark = beamText.TextColor3 == C.StateDanger
	w.lampPill.BackgroundColor3 = if dark then GLASS.dangerBg else GLASS.bg
	w.lampStroke.Color = if dark then GLASS.danger else GLASS.glow
	w.lampStroke.Transparency = if dark then 0.1 else GLASS.glowT
end
beamRow:GetPropertyChangedSignal("Visible"):Connect(refreshLampPill)
beamText:GetPropertyChangedSignal("TextColor3"):Connect(refreshLampPill)
state:GetAttributeChangedSignal("Phase"):Connect(refreshLampPill)

UiKit.endGlass()

---------------------------------------------------------------------
-- LAYOUT (HudParts/Layout) and VISIBILITY
---------------------------------------------------------------------

layout = Layout.init(w, S, cards, function()
	refreshSlot()
	refreshLampPill()
	refreshSky()
end)
local updateStacking = layout.stacking

local function refreshVisibility()
	gui.Enabled = player:GetAttribute("Ready") == true
	local onIsland = ISLAND_PHASES[state:GetAttribute("Phase")] == true
	w.fuelPlate.Visible = onIsland and not alarm.Visible
	w.rightPlate.Visible = onIsland
	w.bossList.Visible = onIsland and not (S.compact and alarm.Visible)
	w.bottom.Visible = not player:GetAttribute("MenuOpen")
	refreshWarning()
	refreshCarry()
	refreshSaveWarning()
	task.defer(applyLayout)
end

---------------------------------------------------------------------
-- WIRING
---------------------------------------------------------------------

state.AttributeChanged:Connect(function(name)
	if name == "Phase" or name == "Night" or name == "TimeLeft" or name == "Reason" then
		refreshVoyage()
		if name == "Phase" then
			refreshVisibility()
			refreshFuel()
			renderPrompts()
		end
	elseif name == "Fuel" or name == "MaxFuel" or name == "DarkSeconds" then
		refreshFuel()
		task.defer(updateStacking)
	elseif name == "Integrity" or name == "MaxIntegrity" then
		refreshTower()
	elseif name == "BeamMode" then
		refreshBeam()
	elseif name == "KeeperUserId" then
		refreshBeam()
		refreshWeapon()
		refreshCarry()
		renderPrompts()
	elseif name == "Shells" then
		refreshShells()
	elseif name == "BigWarning" then
		refreshWarning()
	end
end)

for _, attribute in { "Ready", "MenuOpen", "SaveUnavailable" } do
	player:GetAttributeChangedSignal(attribute):Connect(refreshVisibility)
end
player:GetAttributeChangedSignal("CarryingOil"):Connect(refreshCarry)

local function onCharacter(character)
	task.spawn(bindHumanoid, character)
	character.ChildAdded:Connect(refreshWeapon)
	character.ChildRemoved:Connect(refreshWeapon)
	refreshWeapon()
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then
	onCharacter(player.Character)
end
local function onBackpack(backpack)
	if backpack:IsA("Backpack") then
		backpack.ChildAdded:Connect(refreshWeapon)
		backpack.ChildRemoved:Connect(refreshWeapon)
		refreshWeapon()
	end
end
player.ChildAdded:Connect(onBackpack)
if player:FindFirstChildOfClass("Backpack") then
	onBackpack(player:FindFirstChildOfClass("Backpack"))
end

UserInputService.LastInputTypeChanged:Connect(function()
	refreshBeam()
	refreshWeapon()
	renderPrompts()
end)
hudRoot:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyLayout)
w.topCenter:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateStacking)
w.topRight:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateStacking)
sideStack:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateStacking)
sideStack:GetPropertyChangedSignal("Visible"):Connect(updateStacking)

-- light polling for things without change events (distance to cannons and prompts)
task.spawn(function()
	local sinceScan = math.huge
	while true do
		sinceScan += 0.2
		if sinceScan >= 3 then
			sinceScan = 0
			scanPads()
		end
		refreshCannon()
		refreshCarry()
		if next(cards.shown) then
			renderPrompts()
		end
		task.wait(0.2)
	end
end)

-- the BAG button (Inventory) is built glass already; lay out once it exists
task.spawn(function()
	if player:WaitForChild("PlayerGui"):WaitForChild("InventoryButton", 30) then
		task.defer(applyLayout)
	end
end)

refreshVoyage()
refreshFuel()
refreshTower()
refreshShells()
refreshVisibility()
applyLayout()

if RunService:IsStudio() then
	require(Parts:WaitForChild("Simulator")).init(w, S, applyLayout)
end
