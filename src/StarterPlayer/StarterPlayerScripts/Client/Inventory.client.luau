--!strict
-- Inventory (client): the BAG, the player's own locker and loadout. Opens anywhere once you're in the game: the BAG
-- button, the B key, or D-pad Up on a controller (the harbor's CODES button opens it at the code box).
--
-- Shows ONLY owned items. No shop, no prices, no buying. Equip / Unequip go to LoadoutService
-- (LoadoutRequest -> LoadoutResult); the profile arrives on GearData. Nothing here changes data.
--
-- MP.3: built on the menu pattern (UI/Tiles, D-041/D-042, like the Quartermaster, the bench and the Trader). Tabs:
-- KEEPER (your keeper with what the gear adds up to, one tile per equipped slot, and the code box), WEAPONS, ARMOR,
-- COSMETICS and SUPPLIES (ammo crates and voyage loot). The detail pane compares an item with what is equipped and
-- has one big EQUIP / UNEQUIP button. Studio only: player attribute HudSimulate is handled by Tiles.
-- MP.4: a LOGBOOK tab (S7.1's logbook had no page): found creatures as their models, the rest dimmed under
-- NOT FOUND YET, and each row's Pearl reward (paid by LogbookService; this page only shows it).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared:WaitForChild("Items")) :: any
local Weapons = require(Shared:WaitForChild("Weapons")) :: any
local Ammo = require(Shared:WaitForChild("Ammo")) :: any
local SoundFx = require(Shared:WaitForChild("SoundFx")) :: any
local StatPipeline = require(Shared:WaitForChild("StatPipeline")) :: any -- S5.7: the values previews and voyages share
local UiKit = require(script.Parent:WaitForChild("UiKit")) :: any
local Tiles = require(script.Parent:WaitForChild("UI"):WaitForChild("Tiles")) :: any
local ItemPreview = require(script.Parent:WaitForChild("ItemPreview")) :: any
local CodeBox = require(script.Parent:WaitForChild("CodeBox")) :: any
local Creatures = require(Shared:WaitForChild("Creatures")) :: any -- MP.4: the logbook page
local Upgrades = require(Shared:WaitForChild("Upgrades")) :: any
local Forecasts = require(Shared:WaitForChild("Forecasts")) :: any
local Logbook = require(Shared:WaitForChild("Definitions"):WaitForChild("Logbook")) :: any
local Chests = require(Shared:WaitForChild("Definitions"):WaitForChild("Chests")) :: any -- CHEST.1
local Cosmetics = require(Shared:WaitForChild("Definitions"):WaitForChild("Cosmetics")) :: any -- CHEST.2: the Robux chest
local MarketplaceService = game:GetService("MarketplaceService")
-- CHEST.2 (D-055): a chest bought with Robux is a paid random item, which Roblox restricts in some places; hidden
-- until PolicyService says this player may see it
local paidRandomAllowed = false
task.spawn(function()
	local ok, info = pcall(function()
		return game:GetService("PolicyService"):GetPolicyInfoForPlayerAsync(Players.LocalPlayer)
	end)
	paidRandomAllowed = ok and type(info) == "table" and info.ArePaidRandomItemsRestricted == false
end)
local function chestProduct(chestId: string): any
	return if paidRandomAllowed then Cosmetics.productFor(chestId) else nil
end

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local ItemModels = ReplicatedStorage:WaitForChild("ItemModels")
local player = Players.LocalPlayer

local STARTERS: { [string]: string } = { Primary = "DriftwoodHarpoon", Armor = "OilskinCoat", Beam = "BeamAmber" }
local REQUEST_TIMEOUT = 8
local SLOTS = {
	{ key = "Primary", label = "Primary weapon" },
	{ key = "Armor", label = "Armor" },
	{ key = "Beam", label = "Lamp beam colour" },
	{ key = "Housing", label = "Lamp housing" },
	{ key = "Coat", label = "Keeper coat" },
	{ key = "Lantern", label = "Lantern" },
	{ key = "Flag", label = "Ship flag" },
	{ key = "Pet", label = "Pet" }, -- PET.1
}
local TABS = {
	{ id = "Keeper", label = "Keeper" },
	{ id = "Weapons", label = "Weapons" },
	{ id = "Armor", label = "Armor" },
	{ id = "Cosmetics", label = "Cosmetics" },
	{ id = "Supplies", label = "Supplies" },
	{ id = "Logbook", label = "Logbook" },
}
local TAB_CATEGORIES: { [string]: { [string]: boolean } } = {
	Weapons = { Weapons = true },
	Armor = { Armor = true },
	Cosmetics = { Cosmetics = true },
	Supplies = { Ammunition = true, Materials = true, Chests = true }, -- CHEST.1: Chests
}

local profile: any = nil
local isOpen = false
local tab = "Keeper"
local selectedId: string? = nil
local pendingId: string? = nil
local chestPending: string? = nil -- CHEST.1: the chest being opened
local lastFind: any = nil -- CHEST.1: what the last chest held, shown on the chest

---------------------------------------------------------------------
-- FACTS
---------------------------------------------------------------------

local function count(itemId: string): number
	return if profile then (profile.counts[itemId] or 0) else 0
end
local function owns(itemId: string): boolean
	return profile ~= nil and (profile.owned[itemId] == true or count(itemId) > 0)
end
local EQUIPPED_FIELDS = { "equippedWeapon", "equippedArmor", "equippedBeam", "equippedHousing", "equippedCoat", "equippedLantern", "equippedFlag", "equippedPet" }
local function isEquipped(itemId: string): boolean
	if not profile then
		return false
	end
	for _, field in EQUIPPED_FIELDS do
		if profile[field] == itemId then
			return true
		end
	end
	return false
end
local function dps(weaponId: string): number
	local w = StatPipeline.weapon(weaponId)
	return w.damage / w.cooldown
end
local function equippedFor(slot: string): string?
	if not profile then
		return nil
	end
	return if slot == "Primary" then profile.equippedWeapon
		elseif slot == "Armor" then profile.equippedArmor
		elseif slot == "Beam" then (profile.equippedBeam or "BeamAmber")
		elseif slot == "Housing" or slot == "Coat" or slot == "Lantern" or slot == "Flag" or slot == "Pet" then profile["equipped" .. slot] -- L1.3; PET.1
		else nil
end
local function typeLabel(item: any): string
	if item.kind == "Weapon" then
		return "Primary weapon"
	elseif item.kind == "Armor" then
		return "Armor"
	elseif item.kind == "Ammo" then
		return "Cannon ammo"
	elseif item.kind == "Material" then
		return "Voyage loot"
	elseif item.kind == "Cosmetic" then
		local labels: { [string]: string } = { Beam = "Lamp beam colour", Housing = "Lamp housing", Coat = "Keeper coat", Lantern = "Lantern", Flag = "Ship flag" }
		return (labels[item.slot] or "Cosmetic") .. " \u{00B7} looks only"
	elseif item.kind == "Pet" then -- PET.1
		return "Pet \u{00B7} fetches Shells"
	elseif item.kind == "Chest" then -- CHEST.1
		return "Treasure chest \u{00B7} earned"
	end
	return item.category
end

-- the detail pane's stat lines, compared with what is equipped in the same slot (StatPipeline)
local function statLines(itemId: string): { any }
	local item = Items[itemId]
	local lines: { any } = {}
	local function add(labelText: string, value: number, now: number?, higherIsBetter: boolean, fmt: (number) -> string)
		if now ~= nil and now ~= value then
			table.insert(lines, { label = labelText, from = fmt(now), to = fmt(value), better = if higherIsBetter then value > now else value < now })
		else
			table.insert(lines, { label = labelText, value = fmt(value) })
		end
	end
	if item.kind == "Weapon" then
		local w = StatPipeline.weapon(itemId)
		local current = profile and profile.equippedWeapon
		local cw = if current and current ~= itemId and Weapons[current] then StatPipeline.weapon(current) else nil
		add("Damage per hit", w.damage, cw and cw.damage, true, tostring)
		add("Reload", w.cooldown, cw and cw.cooldown, false, function(v)
			return string.format("%.1f s", v)
		end)
		add("Targets per throw", w.maxTargets, cw and cw.maxTargets, true, tostring)
		add("Damage per second", math.floor(dps(itemId) + 0.5), if cw and current then math.floor(dps(current) + 0.5) else nil, true, tostring)
	elseif item.kind == "Armor" then
		local current = profile and profile.equippedArmor
		local ca = if current and current ~= itemId and Items[current] then StatPipeline.armor(current) else nil
		local mine = StatPipeline.armor(itemId)
		add("Health", mine.maxHealth, ca and ca.maxHealth, true, tostring)
		add("Damage blocked", math.floor(mine.damageReduction * 100 + 0.5), if ca then math.floor(ca.damageReduction * 100 + 0.5) else nil, true, function(v)
			return v .. "%"
		end)
	elseif item.kind == "Ammo" then
		local a = Ammo[item.ammoType]
		table.insert(lines, { label = "Crates", value = string.format("%d / %d", count(itemId), item.maxStack) })
		table.insert(lines, { label = "Shots per crate", value = tostring(a.shotsPerLoad) })
		table.insert(lines, { label = "Cannon damage", value = string.format("x%.1f", a.damageMultiplier) })
	elseif item.kind == "Material" then
		local n = count(itemId)
		table.insert(lines, { label = "Carried", value = tostring(n) })
		table.insert(lines, { label = "Trader pays each", value = (item.shellValue or 0) .. " Shells" })
		table.insert(lines, { label = "Worth now", value = (n * (item.shellValue or 0)) .. " Shells" })
	elseif item.kind == "Cosmetic" then
		table.insert(lines, { label = "Power", value = "none: looks only" })
	elseif item.kind == "Pet" then -- PET.1
		table.insert(lines, { label = "Fetches", value = "Shells" })
	elseif item.kind == "Chest" and Chests[itemId] then -- CHEST.1: the odds, shown before you open it
		table.insert(lines, { label = "In your bag", value = tostring(count(itemId)) })
		for _, row in Chests[itemId].loot do
			local name = if row.item and Items[row.item] then Items[row.item].name else (row.pearls or 0) .. " Pearls"
			local pct = row.chance * 100
			table.insert(lines, { label = name, value = (if pct < 1 or pct % 1 ~= 0 then string.format("%.1f%%", pct) else string.format("%d%%", pct)) .. " \u{00B7} " .. row.tier })
		end
	end
	return lines
end

---------------------------------------------------------------------
-- MENU
---------------------------------------------------------------------

local setOpen: (boolean, string?) -> () -- forward
local renderAll: () -> () -- forward
local equip: (string, string) -> () -- forward
local openChest: (string) -> () -- forward (CHEST.1)
local menu = Tiles.Menu({
	name = "Inventory",
	displayOrder = 18,
	title = "Bag",
	onClose = function()
		setOpen(false)
	end,
})

-- your keeper as the detail pane's picture: a copy of your character holding the equipped weapon
local function placeHeld(copy: Model, hand: BasePart, model: Instance)
	local held = model:Clone() :: any
	local bboxCf, size = held:GetBoundingBox()
	local long = math.max(size.X, size.Y, size.Z)
	-- stand long weapons upright in the hand like a staff; small ones keep their own pose
	local rot = CFrame.new()
	if long >= 2 then
		if size.X == long then
			rot = CFrame.Angles(0, 0, math.rad(90))
		elseif size.Z == long then
			rot = CFrame.Angles(math.rad(-90), 0, 0)
		end
	end
	local hrp = copy:FindFirstChild("HumanoidRootPart") :: BasePart?
	local yaw = if hrp then hrp.CFrame.Rotation else CFrame.new()
	local target = CFrame.new(hand.Position + Vector3.new(0, if long >= 2 then long * 0.22 else 0, 0)) * yaw * rot
	held:PivotTo(target * bboxCf:ToObjectSpace(held:GetPivot()))
	held.Parent = copy
end

local function avatarIcon(holder: Instance)
	local character = player.Character
	if not character or not profile then
		return
	end
	character.Archivable = true
	local copy = character:Clone()
	if not copy then
		return
	end
	for _, d in copy:GetDescendants() do
		if d:IsA("Tool") or d:IsA("BillboardGui") or d.Name == "CarriedOil" then
			d:Destroy()
		end
	end
	local hand = (copy:FindFirstChild("RightHand") or copy:FindFirstChild("Right Arm")) :: BasePart?
	local weaponItem = Items[profile.equippedWeapon]
	local weaponModel = weaponItem and ItemModels:FindFirstChild(weaponItem.model)
	if hand and weaponModel then
		pcall(placeHeld, copy, hand, weaponModel)
	end
	local preview = ItemPreview.new(holder, { rotatable = true, backdrop = false })
	preview:setModel(copy, "Avatar")
	copy:Destroy()
end

-- ICON1: `key` names the tile's picture in Shared/ItemIcons; the glyph shows when there is none
local function glyphIcon(kind: string, color: Color3, key: string?): (Instance) -> ()
	return function(holder: Instance)
		if key and Tiles.picture(holder, key) then
			return
		end
		Tiles.glyph(holder, kind, color)
	end
end

---------------------------------------------------------------------
-- TILES
---------------------------------------------------------------------

local function keeperTiles(): { any }
	local list: { any } = {
		{ id = "Keeper", name = "Your keeper", icon = glyphIcon("heart", Color3.fromRGB(240, 80, 90)) },
	}
	for _, slot in SLOTS do
		local itemId = equippedFor(slot.key)
		if itemId and Items[itemId] then
			table.insert(list, { id = "Slot_" .. slot.key, name = Items[itemId].name, icon = itemId, owned = true, ownedText = "Equipped" })
		elseif slot.key ~= "Primary" and slot.key ~= "Armor" then
			table.insert(list, { id = "Slot_" .. slot.key, name = slot.label, icon = glyphIcon("plus", Color3.fromRGB(120, 140, 160)) })
		end
	end
	local crates = count("FireShellCrate")
	if crates > 0 then
		table.insert(list, { id = "FireShellCrate", name = Items.FireShellCrate.name, icon = "FireShellCrate", qty = crates })
	end
	for _, chestId in Chests.ORDER do -- CHEST.1: unopened chests sit on the first page
		local n = count(chestId)
		if n > 0 or chestProduct(chestId) then -- CHEST.2: shown to buy one even when the bag holds none
			table.insert(list, { id = chestId, name = Items[chestId].name, icon = chestId, qty = if n > 0 then n else nil })
		end
	end
	table.insert(list, { id = "Codes", name = "Codes", icon = glyphIcon("check", Color3.fromRGB(255, 200, 80), "Codes") })
	table.insert(list, { id = "Settings", name = "Settings", icon = glyphIcon("info", Color3.fromRGB(150, 200, 255), "Settings") }) -- SET.1
	table.insert(list, { id = "Tutorial", name = "Tutorial", icon = glyphIcon("next", Color3.fromRGB(255, 205, 90)) }) -- TUT.1
	return list
end

local function itemTiles(): { any }
	local list = {}
	local cats = TAB_CATEGORIES[tab] or {}
	for _, itemId in Items.SHOP_ORDER do
		local item = Items[itemId]
		if cats[item.category] and owns(itemId) then
			local n = count(itemId)
			local equipped = isEquipped(itemId)
			table.insert(list, {
				id = itemId,
				name = item.name,
				icon = itemId,
				owned = equipped,
				ownedText = "Equipped",
				qty = if n > 0 then n else nil,
			})
		end
	end
	return list
end

---------------------------------------------------------------------
-- LOGBOOK (MP.4): what this keeper has found (the profile's Logbook, S7.1), one tile per entry
---------------------------------------------------------------------

local LOG_ENTRIES = Logbook.entries(Creatures, Upgrades, Forecasts)
local LOG_LABELS: { [string]: string } = {
	Creatures = "Creature",
	Bosses = "Big monster",
	Evolutions = "Evolution",
	Forecasts = "Forecast",
}
-- field notes for the creatures (display text only; the numbers live in Shared/Creatures)
local LOG_NOTES: { [string]: string } = {
	RockCrab = "Walks up the beach and claws at the tower. The wide beam shoves it back; the focused beam burns it.",
	SandSkitter = "Small, fast and never alone. One pass of the wide beam sweeps a whole swarm away.",
	SpitterEel = "Keeps its distance and spits at the spot you stood on. Step out of the green ring.",
	PufferMine = "Lights a fuse when you get close or when it reaches the tower, then bursts. Back away when it hisses.",
	GhostLantern = "Weapons and cannons pass right through it. Only the lamp's beam can hurt it, and it drinks the lamp's oil at the tower.",
	TideWitch = "Calls skitters out of the sea beside her. Stop her before the swarm grows.",
	CoralShaman = "Mends the small creatures around it. Take it down first.",
	BarnacleBrute = "So heavy the wide beam cannot shove it. Focus the light and bring the crew.",
	ShipwreckHermit = "A huge hermit in a wrecked hull. Bring the whole crew and every cannon.",
}

local function logFound(category: string, id: string): boolean
	local book = profile and profile.logbook
	return type(book) == "table" and book[Logbook.key(category, id)] == true
end

local function logName(category: string, id: string): string
	if category == "Creatures" or category == "Bosses" then
		return Creatures[id] and Creatures[id].displayName or id
	elseif category == "Evolutions" then
		for _, evo in Upgrades.EVOLUTIONS or {} do
			if evo.id == id then
				return evo.displayName
			end
		end
	elseif category == "Forecasts" then
		return Forecasts[id] and Forecasts[id].displayName or id
	end
	return id
end

local function logProgress(category: string): (number, number)
	local found = 0
	for _, id in LOG_ENTRIES[category] or {} do
		if logFound(category, id) then
			found += 1
		end
	end
	return found, #(LOG_ENTRIES[category] or {})
end

-- a found creature's tile shows the creature itself (the client's own template, no glow or health bar)
local function creatureIcon(id: string): (Instance) -> ()
	return function(holder: Instance)
		local templates = ReplicatedStorage:FindFirstChild("CreatureTemplates")
		local template = templates and templates:FindFirstChild(id)
		if not template then
			Tiles.glyph(holder, "alert", Color3.fromRGB(240, 200, 120))
			return
		end
		local view = UiKit.new("ViewportFrame", {
			Name = "CreatureView",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Ambient = Color3.fromRGB(170, 170, 180),
			LightColor = Color3.fromRGB(255, 245, 230),
		}, holder)
		local model = template:Clone()
		for _, d in model:GetDescendants() do
			if d:IsA("BillboardGui") or d:IsA("Light") then
				d:Destroy()
			end
		end
		model:PivotTo(CFrame.new())
		model.Parent = view
		local box, size = model:GetBoundingBox()
		local reach = math.max(size.X, size.Y, size.Z)
		local camera = Instance.new("Camera")
		camera.FieldOfView = 30
		-- creatures face -Z: look at them from the front, a little to the side and above
		camera.CFrame = CFrame.lookAt(box.Position + Vector3.new(reach * 0.5, reach * 0.4, -reach * 1.3), box.Position)
		camera.Parent = view
		view.CurrentCamera = camera
	end
end

local LOG_GLYPHS: { [string]: { kind: string, color: Color3 } } = {
	Evolutions = { kind = "diamond", color = Color3.fromRGB(255, 200, 80) },
	Forecasts = { kind = "warning", color = Color3.fromRGB(140, 200, 255) },
}

local function logIcon(category: string, id: string): (Instance) -> ()
	if category == "Creatures" or category == "Bosses" then
		return creatureIcon(id)
	end
	local g = LOG_GLYPHS[category]
	return glyphIcon(g.kind, g.color)
end

local function logbookTiles(): { any }
	local list: { any } = { { id = "LogSummary", name = "Your logbook", icon = glyphIcon("check", Color3.fromRGB(255, 200, 80), "LogSummary") } }
	for _, category in Logbook.ORDER do
		for _, id in LOG_ENTRIES[category] or {} do
			if logFound(category, id) then
				table.insert(list, { id = "Log_" .. category .. "_" .. id, name = logName(category, id), icon = logIcon(category, id) })
			else
				table.insert(list, { id = "Log_" .. category .. "_" .. id, name = "???", locked = "NOT FOUND YET", lockedIcon = "lock" })
			end
		end
	end
	return list
end

local function logbookSummaryDetail(): any
	local stats = {}
	local all, total = 0, 0
	for _, category in Logbook.ORDER do
		local def = Logbook[category]
		local found, count = logProgress(category)
		all += found
		total += count
		table.insert(stats, {
			label = def.displayName,
			value = string.format("%d / %d", found, count) .. (if found >= count then "  done" else string.format("  (+%d Pearls)", def.reward)),
		})
	end
	return {
		icon = glyphIcon("check", Color3.fromRGB(255, 200, 80), "LogSummary"),
		name = string.format("Your logbook  %d / %d", all, total),
		description = "Everything your crews have found on voyages. Finish a row to earn its Pearls, paid once.",
		stats = stats,
	}
end

local function logEntryDetail(tileId: string): any
	local category, id = string.match(tileId, "^Log_(%a+)_(.+)$")
	if not category or not id then
		return logbookSummaryDetail()
	end
	local def = Logbook[category]
	local note: string
	if category == "Creatures" or category == "Bosses" then
		note = LOG_NOTES[id] or ""
	elseif category == "Evolutions" then
		note = ""
		for _, evo in Upgrades.EVOLUTIONS or {} do
			if evo.id == id then
				note = evo.description or ""
			end
		end
	else
		note = Forecasts[id] and Forecasts[id].summary or ""
	end
	local found, count = logProgress(category)
	return {
		icon = logIcon(category, id),
		name = logName(category, id),
		description = LOG_LABELS[category] .. ", " .. def.how .. ". " .. note,
		stats = {
			{ label = def.displayName .. " found", value = string.format("%d / %d", found, count) },
			{ label = "Row reward", value = if found >= count then "Paid" else string.format("%d Pearls", def.reward) },
		},
	}
end

---------------------------------------------------------------------
-- DETAIL
---------------------------------------------------------------------

local function keeperDetail(): any
	local armor = if profile and Items[profile.equippedArmor] then StatPipeline.armor(profile.equippedArmor) else nil
	return {
		icon = avatarIcon,
		name = player.DisplayName,
		description = "What your gear adds up to. Pick a slot to change it.",
		stats = {
			{ label = "Health", value = tostring(armor and armor.maxHealth or 100) },
			{ label = "Damage blocked", value = (if armor then math.floor(armor.damageReduction * 100 + 0.5) else 0) .. "%" },
			{ label = "Weapon damage / s", value = if profile and Weapons[profile.equippedWeapon] then tostring(math.floor(dps(profile.equippedWeapon) + 0.5)) else "-" },
		},
	}
end

-- SET.1: Settings from the BAG (sound, storm sound, low effects); the panel itself lives in Menus
local function settingsDetail(): any
	return {
		icon = glyphIcon("info", Color3.fromRGB(150, 200, 255), "Settings"),
		name = "Settings",
		description = "Sound, storm sound and low effects for slower phones. Saved with your keeper.",
		action = { text = "Open", enabled = true, onPress = function()
			setOpen(false)
			local event = script.Parent:FindFirstChild("OpenSettings")
			if event and event:IsA("BindableEvent") then
				event:Fire()
			end
		end },
	}
end

local function codesDetail(): any
	return {
		icon = glyphIcon("check", Color3.fromRGB(255, 200, 80), "Codes"),
		name = "Codes",
		description = "Type a code from the game's page or a creator, then press Redeem. Each code works once.",
		extra = function(container: Instance, unit: any)
			local row = UiKit.new("Frame", { Name = "CodeRow", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, unit.min + 8) }, container)
			local box = UiKit.new("TextBox", {
				Name = "CodeBox",
				BackgroundColor3 = Color3.fromRGB(20, 34, 50),
				BorderSizePixel = 0,
				Size = UDim2.new(1, -(unit.min + 52), 0, unit.min),
				FontFace = UiKit.Font.BodyBold,
				TextSize = 28,
				TextColor3 = Color3.new(1, 1, 1),
				PlaceholderColor3 = Color3.fromRGB(150, 165, 185),
				PlaceholderText = "Type a code",
				Text = "",
				ClearTextOnFocus = false,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, row)
			UiKit.new("UICorner", { CornerRadius = UDim.new(0, 14) }, box)
			UiKit.new("UIStroke", { Thickness = 3, Color = Color3.fromRGB(10, 18, 28) }, box)
			UiKit.new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, box)
			local redeem = Tiles.bigButton(row, "Redeem")
			redeem.button.AnchorPoint = Vector2.new(1, 0)
			redeem.button.Position = UDim2.new(1, 0, 0, 0)
			redeem.button.Size = UDim2.fromOffset(unit.min + 40, unit.min) -- the field gets the room on phones
			redeem.paint({ face = Color3.fromRGB(255, 194, 61), edge = Color3.fromRGB(179, 123, 12), text = Color3.fromRGB(42, 21, 0) }, "Redeem")
			redeem.button.Activated:Connect(function()
				CodeBox.send(box.Text, menu.root)
			end)
		end,
	}
end

local function emptySlotDetail(slotKey: string): any
	local label = slotKey
	for _, slot in SLOTS do
		if slot.key == slotKey then
			label = slot.label
		end
	end
	return {
		icon = glyphIcon("plus", Color3.fromRGB(120, 140, 160)),
		name = label,
		description = "Nothing worn here yet. Cosmetics are looks only; the Quartermaster in the harbor sells them.",
	}
end

local function itemDetail(itemId: string): any
	local item = Items[itemId]
	local equipped = isEquipped(itemId)
	local description = item.description or ""
	if item.strengths then
		description ..= "\n+ " .. item.strengths
	end
	if item.tradeoffs then
		description ..= "\n\u{2212} " .. item.tradeoffs
	end
	local detail: any = {
		icon = itemId,
		name = item.name,
		description = typeLabel(item) .. ". " .. description,
		stats = statLines(itemId),
	}
	if item.kind == "Chest" then -- CHEST.1
		local n = count(itemId)
		if lastFind and lastFind.chest == itemId then
			detail.description ..= "\nLast opened: " .. lastFind.name .. " (" .. lastFind.tier .. ")" .. (if lastFind.duplicate then ", already yours, so " .. lastFind.pearls .. " Pearls instead." elseif lastFind.item then ". Equip it from Cosmetics." else ".")
		end
		detail.action = if chestPending then { text = "Opening...", enabled = false, reason = "Opening the chest..." }
			elseif n > 0 then { text = "Open", enabled = true, onPress = function()
				openChest(itemId)
			end }
			else { text = "Open", enabled = false, reason = "Beat the Kraken to earn the next one." }
		local product = chestProduct(itemId)
		if product then -- CHEST.2 (D-055): one more chest for Robux, same contents and odds as the free one
			detail.action2 = { text = "Buy one R$ " .. product.robux, enabled = true, variant = "robux", onPress = function()
				MarketplaceService:PromptProductPurchase(player, product.productId)
			end }
		end
		return detail
	end
	if not item.slot then
		detail.action = if item.kind == "Ammo"
			then { text = "Used by cannons", enabled = false, reason = "Used automatically when you reload a cannon. Nothing to equip." }
			else { text = "Sell at the Trader", enabled = false, reason = "Loot lasts one voyage. Sell it to the Trader on the lighthouse island for Shells." }
		return detail
	end
	local isStarter = STARTERS[item.slot] == itemId
	if pendingId then
		detail.action = { text = "Updating...", enabled = false, reason = "Updating your loadout..." }
	elseif equipped and isStarter then
		detail.action = { text = "Equipped", enabled = false, reason = "Starter gear stays on until you equip something else." }
	elseif equipped then
		detail.action = { text = "Unequip", enabled = true, variant = "robux", onPress = function()
			equip(itemId, "unequip")
		end }
	else
		detail.action = { text = "Equip", enabled = true, onPress = function()
			equip(itemId, "equip")
		end }
	end
	return detail
end

local function renderDetail()
	local id = selectedId
	if not profile then
		menu:setDetail({ name = "Opening your bag", description = "Fetching your gear from the harbor." })
	elseif id == "Keeper" then
		menu:setDetail(keeperDetail())
	elseif id == "Codes" then
		menu:setDetail(codesDetail())
	elseif id == "Settings" then
		menu:setDetail(settingsDetail())
	elseif id == "Tutorial" then -- TUT.1: play the first-time tutorial again
		menu:setDetail({
			icon = glyphIcon("next", Color3.fromRGB(255, 205, 90)),
			name = "Tutorial",
			description = "A quick guided tour: the Quartermaster, your BAG, boarding a ship, and how to keep the light on a voyage.",
			action = { text = "Play again", enabled = true, onPress = function()
				setOpen(false)
				local event = script.Parent:FindFirstChild("ReplayTutorial")
				if event and event:IsA("BindableEvent") then
					event:Fire()
				end
			end },
		})
	elseif tab == "Logbook" then
		menu:setDetail(if id and string.sub(id, 1, 4) == "Log_" then logEntryDetail(id) else logbookSummaryDetail())
	elseif id and string.sub(id, 1, 5) == "Slot_" then
		local slotKey = string.sub(id, 6)
		local itemId = equippedFor(slotKey)
		menu:setDetail(if itemId and Items[itemId] then itemDetail(itemId) else emptySlotDetail(slotKey))
	elseif id and Items[id] then
		menu:setDetail(itemDetail(id))
	else
		local empty = {
			Weapons = "Weapons you own show up here. The Quartermaster in the harbor sells more.",
			Armor = "Armor you own shows up here. The Quartermaster in the harbor sells more.",
			Cosmetics = "Looks-only items you own show up here: beam colours, housings, coats, lanterns and flags.",
			Supplies = "Fire Shell crates, Kraken Chests and voyage loot show up here. Loot lasts one voyage.",
		}
		menu:setDetail({ name = "Nothing here yet", description = empty[tab] or "" })
	end
end

renderAll = function()
	if not isOpen then
		return
	end
	menu:setResources({ { kind = "Pearls", amount = if profile then profile.pearls or 0 else 0 } })
	menu.subtitle.Text = if player:GetAttribute("SaveUnavailable") == true then "Saving is offline. Changes last until you leave." else ""
	if not profile then
		menu:setTiles({}, nil)
		renderDetail()
		return
	end
	local list = if tab == "Keeper" then keeperTiles() elseif tab == "Logbook" then logbookTiles() else itemTiles()
	local stillThere = false
	for _, t in list :: { any } do
		if t.id == selectedId then
			stillThere = true
		end
	end
	if not stillThere then
		selectedId = list[1] and list[1].id
	end
	menu:setTiles(list, selectedId)
	renderDetail()
end

menu.onSelect = function(id: string)
	selectedId = id
	renderDetail()
end

---------------------------------------------------------------------
-- EQUIP / UNEQUIP (the server decides)
---------------------------------------------------------------------

equip = function(itemId: string, action: string)
	if pendingId then
		return
	end
	local id = string.sub(HttpService:GenerateGUID(false), 1, 36)
	pendingId = id
	remotes.LoadoutRequest:FireServer(id, action, itemId)
	renderDetail()
	task.delay(REQUEST_TIMEOUT, function()
		if pendingId == id then
			pendingId = nil
			UiKit.Toast(menu.root, "No reply from the server. Your loadout didn't change. Try again.", "danger")
			renderAll()
		end
	end)
end

-- CHEST.1: open a chest (the server rolls and grants; this only asks and shows the find)
openChest = function(chestId: string)
	if chestPending then
		return
	end
	local id = string.sub(HttpService:GenerateGUID(false), 1, 36)
	chestPending = id
	remotes.ChestRequest:FireServer(id, chestId)
	renderDetail()
	task.delay(REQUEST_TIMEOUT, function()
		if chestPending == id then
			chestPending = nil
			UiKit.Toast(menu.root, "No reply from the server. Your chest is still in your bag. Try again.", "danger")
			renderAll()
		end
	end)
end

-- CHEST.1: the find, shown big over the bag (the moment to show off); tap NICE or wait to close it
local TIER_COLORS: { [string]: Color3 } = {
	Common = Color3.fromRGB(200, 210, 220),
	Uncommon = Color3.fromRGB(110, 220, 120),
	Rare = Color3.fromRGB(90, 170, 255),
	Epic = Color3.fromRGB(190, 110, 255),
	Legendary = Color3.fromRGB(255, 200, 60),
}
local function showFind(find: any)
	local old = player.PlayerGui:FindFirstChild("ChestReveal")
	if old then
		old:Destroy()
	end
	local gui = UiKit.new("ScreenGui", { Name = "ChestReveal", DisplayOrder = 30, IgnoreGuiInset = true, ResetOnSpawn = false }, player.PlayerGui)
	local dim = UiKit.new("TextButton", { Name = "Dim", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Size = UDim2.fromScale(1, 1) }, gui)
	local tierColor = TIER_COLORS[find.tier] or TIER_COLORS.Common
	local panel = UiKit.new("Frame", { Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(460, 430), BackgroundColor3 = Color3.fromRGB(22, 38, 58), BorderSizePixel = 0 }, gui)
	UiKit.new("UICorner", { CornerRadius = UDim.new(0, 24) }, panel)
	UiKit.new("UIStroke", { Thickness = 5, Color = tierColor }, panel)
	UiKit.new("UISizeConstraint", { MaxSize = Vector2.new(460, 430) }, panel)
	local fit = UiKit.new("UIScale", {}, panel)
	local function scaleToScreen()
		local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		fit.Scale = math.min(1, (view.X - 32) / 460, (view.Y - 32) / 430)
	end
	scaleToScreen()
	local function text(name: string, value: string, y: number, h: number, size: number, color: Color3, font: any)
		return UiKit.new("TextLabel", { Name = name, Text = value, BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, y), Size = UDim2.new(1, -40, 0, h), FontFace = font, TextSize = size, TextColor3 = color, TextWrapped = true }, panel)
	end
	text("Title", string.upper(Items[find.chest] and Items[find.chest].name or "Chest"), 14, 34, 26, Color3.fromRGB(255, 220, 140), UiKit.Font.Display)
	local holder = UiKit.new("Frame", { Name = "Icon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 52), Size = UDim2.fromOffset(170, 170) }, panel)
	if find.item and Items[find.item] then
		local preview = ItemPreview.new(holder, { backdrop = false })
		preview:setItem(find.item)
	elseif not Tiles.picture(holder, "BlackPearl") then
		Tiles.glyph(holder, "check", tierColor)
	end
	text("Name", tostring(find.name), 228, 44, 34, Color3.new(1, 1, 1), UiKit.Font.Display)
	text("Tier", string.upper(tostring(find.tier)), 272, 28, 24, tierColor, UiKit.Font.BodyBold)
	local note = if find.duplicate then string.format("Already yours, so you get %d Pearls instead.", find.pearls or 0)
		elseif find.item then "Yours to keep. Equip it from Cosmetics in your bag."
		else "Added to your Pearls."
	text("Note", note, 302, 40, 20, Color3.fromRGB(200, 215, 230), UiKit.Font.Body)
	local close = Tiles.bigButton(panel, "Nice")
	close.button.AnchorPoint = Vector2.new(0.5, 1)
	close.button.Position = UDim2.new(0.5, 0, 1, -22)
	close.button.Size = UDim2.fromOffset(220, 64)
	close.paint({ face = Color3.fromRGB(255, 194, 61), edge = Color3.fromRGB(179, 123, 12), text = Color3.fromRGB(42, 21, 0) }, "Nice!")
	local function done()
		if gui.Parent then
			gui:Destroy()
		end
	end
	close.button.Activated:Connect(done)
	dim.Activated:Connect(done)
	fit.Scale *= 0.6
	game:GetService("TweenService"):Create(fit, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = fit.Scale / 0.6 }):Play()
	task.delay(if find.tier == "Legendary" or find.tier == "Epic" then 8 else 5, done)
end

remotes.ChestResult.OnClientEvent:Connect(function(requestId, ok, result)
	if requestId ~= chestPending then
		return
	end
	chestPending = nil
	if not ok then
		SoundFx.play2D("denied")
		UiKit.Toast(menu.root, tostring(result), "danger")
	elseif type(result) == "table" then
		lastFind = result
		local rare = result.tier == "Epic" or result.tier == "Legendary"
		SoundFx.play2D(if rare and not result.duplicate then "lantern" else "click")
		showFind(result)
	end
	renderAll()
end)

remotes.LoadoutResult.OnClientEvent:Connect(function(requestId, ok, message)
	if requestId ~= pendingId then
		return -- the Quartermaster's own requests are answered there
	end
	pendingId = nil
	if isOpen then
		SoundFx.play2D(if ok then "lantern" else "denied")
		UiKit.Toast(menu.root, message or (if ok then "Loadout updated." else "That didn't work. Your loadout didn't change."), if ok then "success" else "danger")
		renderAll()
		if ok and selectedId then
			menu:pop(selectedId)
		end
	end
end)

remotes.GearData.OnClientEvent:Connect(function(data)
	profile = data
	if isOpen then
		renderAll()
		-- the server puts new armor on the character a moment after the data changes: redraw the keeper then
		task.delay(0.35, function()
			if isOpen and selectedId == "Keeper" then
				renderDetail()
			end
		end)
	end
end)

player:GetAttributeChangedSignal("SaveUnavailable"):Connect(renderAll)

---------------------------------------------------------------------
-- OPEN / CLOSE
---------------------------------------------------------------------

local function onTab(id: string)
	tab = id
	selectedId = nil
	renderAll()
end

setOpen = function(open: boolean, focus: string?)
	if open == isOpen then
		if open and focus then
			tab, selectedId = "Keeper", focus
			menu:setTabs(TABS, tab, onTab)
			renderAll()
		end
		return
	end
	isOpen = open
	player:SetAttribute("BagOpen", if open then true else nil) -- TUT.1: the tutorial's BAG step
	if open then
		tab = "Keeper"
		selectedId = focus or "Keeper"
		pendingId = nil
		chestPending = nil
		UiKit.pushModal("Inventory")
		menu:open()
		menu:setTabs(TABS, tab, onTab)
		renderAll()
		remotes.GearAction:FireServer("sync")
		ContextActionService:BindAction("CloseInventory", function(_, state)
			if state == Enum.UserInputState.Begin then
				setOpen(false)
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.ButtonB, Enum.KeyCode.Backspace)
		task.defer(function()
			if UiKit.usingGamepad() and selectedId and menu.tiles[selectedId] then
				GuiService.SelectedObject = menu.tiles[selectedId].tile
			end
		end)
	else
		menu:close()
		ContextActionService:UnbindAction("CloseInventory")
		GuiService.SelectedObject = nil
		UiKit.popModal("Inventory")
		-- the Quartermaster's shop may be opening right now: keep gameplay input locked for it
		local shop = player.PlayerGui:FindFirstChild("QuartermasterShop") :: ScreenGui?
		if shop and shop.Enabled then
			player:SetAttribute("MenuOpen", true)
		end
	end
end

-- Opening the Quartermaster's shop closes the bag
remotes.ShopOpen.OnClientEvent:Connect(function(open)
	if open then
		setOpen(false)
	end
end)

---------------------------------------------------------------------
-- BAG BUTTON (HUD, top right)
---------------------------------------------------------------------

-- Owner, Oct 13: a small round glass bag icon (mock-up) instead of the BAG bar. Touch screens: left of
-- the jump button. Mouse/keyboard: bottom-right, above the Shells pill, with a "B" hint.
local hud = UiKit.Screen("InventoryButton", 4)
local bagButton = UiKit.new("TextButton", {
	Name = "BagButton",
	Text = "",
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(12, 20, 40),
	BackgroundTransparency = 0.18,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -12, 1, -76),
	Size = UDim2.fromOffset(54, 54),
}, hud)
UiKit.round(bagButton, 27)
UiKit.border(bagButton, Color3.fromRGB(104, 156, 255), 1.5, 0.35)
UiKit.focusable(bagButton)
do
	-- drawn backpack: body, handle, pocket (white outlines)
	local icon = UiKit.new("Frame", { Name = "Icon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(24, 26) }, bagButton)
	local function outline(position, size, radius)
		local f = UiKit.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = position, Size = size }, icon)
		UiKit.round(f, radius)
		UiKit.border(f, Color3.fromRGB(240, 244, 255), 2, 0)
		return f
	end
	outline(UDim2.new(0.5, 0, 0, 0), UDim2.fromOffset(10, 7), 3) -- handle
	outline(UDim2.new(0.5, 0, 0, 5), UDim2.fromOffset(22, 21), 6) -- body
	outline(UDim2.new(0.5, 0, 0, 15), UDim2.fromOffset(12, 8), 2) -- pocket
end
local bagKey = UiKit.new("TextLabel", {
	Name = "Key",
	BackgroundColor3 = Color3.fromRGB(26, 52, 110),
	FontFace = UiKit.Font.LabelBold,
	TextSize = 12,
	TextColor3 = Color3.fromRGB(240, 244, 255),
	Text = "B",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -6, 0, 6),
	Size = UDim2.fromOffset(18, 18),
	ZIndex = 3,
}, bagButton)
UiKit.round(bagKey, 9)
bagButton.MouseEnter:Connect(function()
	bagButton.BackgroundColor3 = Color3.fromRGB(30, 48, 88)
end)
bagButton.MouseLeave:Connect(function()
	bagButton.BackgroundColor3 = Color3.fromRGB(12, 20, 40)
end)
bagButton.Activated:Connect(function()
	UiKit.click()
	setOpen(not isOpen)
end)
local function placeBag()
	local view = workspace.CurrentCamera.ViewportSize
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if touch and math.min(view.X, view.Y) <= 500 then
		-- phones: just left of the jump button (jump sits about 95..25 px from the right, 90..20 from the bottom)
		bagButton.Size = UDim2.fromOffset(52, 52)
		bagButton.Position = UDim2.new(1, -106, 1, -26)
	elseif touch then
		bagButton.Size = UDim2.fromOffset(62, 62)
		bagButton.Position = UDim2.new(1, -182, 1, -96)
	else
		bagButton.Size = UDim2.fromOffset(54, 54)
		bagButton.Position = UDim2.new(1, -12, 1, -76)
	end
	bagButton:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0.5, 0)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(placeBag)
placeBag()
local function refreshBagLabel()
	local keyboard = UserInputService.KeyboardEnabled and not UiKit.usingGamepad()
	bagKey.Visible = keyboard
	placeBag()
end
UserInputService.LastInputTypeChanged:Connect(refreshBagLabel)
refreshBagLabel()

-- Harbor UI: in the Bold look the bag is a chunky 3D button; on the harbor island a Pearls pill (top right) and a
-- CODES button (beside the bag, opens the BAG where the code box is) join it. Same bag position and touch size.
local Skin = UiKit.Skin
local harborExtras = {}
if Skin and Skin.Bold then
	Skin.Bold.button(bagButton, "secondary")
	for _, layer in { "BoldShadow", "BoldFace" } do
		local f = bagButton:FindFirstChild(layer)
		local c = f and f:FindFirstChildOfClass("UICorner")
		if c then
			c.CornerRadius = UDim.new(0.5, 0)
		end
	end
end
local pearlPill = UiKit.Currency(hud, "Pearls", if profile then profile.pearls or 0 else 0, { size = "lg" })
pearlPill.frame.Name = "PearlsPill"
pearlPill.frame.AnchorPoint = Vector2.new(1, 0)
pearlPill.frame.Position = UDim2.new(1, -12, 0, 12)
if Skin and Skin.Bold then
	pearlPill.frame.BackgroundColor3 = UiKit.Color.SurfacePrimary
	Skin.Bold.outline(pearlPill.frame, 3)
	local c = pearlPill.frame:FindFirstChildOfClass("UICorner")
	if c then
		c.CornerRadius = UDim.new(0.5, 0)
	end
end
remotes.GearData.OnClientEvent:Connect(function(data)
	if type(data) == "table" then
		pearlPill.set(data.pearls or 0)
	end
end)
local codesButton = UiKit.Button(hud, "Codes", {
	name = "CodesButton",
	variant = "primary",
	size = "sm",
	width = 96,
	onClick = function()
		setOpen(true, "Codes")
	end,
})
codesButton.AnchorPoint = Vector2.new(1, 1)
table.insert(harborExtras, pearlPill.frame)
table.insert(harborExtras, codesButton)
local function placeHarbor()
	local bag = bagButton.Position
	local size = bagButton.Size.X.Offset
	codesButton.Position = UDim2.new(1, bag.X.Offset - size - 14, 1, bag.Y.Offset - math.floor((size - 44) / 2))
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(placeHarbor)
placeHarbor()

local function refreshHud()
	hud.Enabled = player:GetAttribute("Ready") == true or player:GetAttribute("InLobby") == true
	if not hud.Enabled then
		setOpen(false)
	end
	local inHarbor = player:GetAttribute("InLobby") == true and player:GetAttribute("Ready") ~= true
	for _, extra in harborExtras do
		extra.Visible = inHarbor
	end
	placeHarbor()
end
player:GetAttributeChangedSignal("Ready"):Connect(refreshHud)
player:GetAttributeChangedSignal("InLobby"):Connect(refreshHud)
refreshHud()

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not hud.Enabled then
		return
	end
	if input.KeyCode == Enum.KeyCode.B or input.KeyCode == Enum.KeyCode.DPadUp then
		setOpen(not isOpen)
	end
end)

remotes.GearAction:FireServer("sync")
