--!strict
-- Bench (client): the in-run UPGRADE BENCH.
--
-- Shells only (the crew's shared pool, reset every voyage). No Pearls here, ever.
-- The server opens it (OpenUpgrades, from the bench prompt) and validates every purchase
-- (BuyUpgrade -> UpgradeResult). Upgrade values and prices come from Shared/Upgrades unchanged.
--
-- S2.5c (D-041/D-042): built on the menu pattern (UI/Tiles): one tile per upgrade (level badge, Shells cost, a
-- check when maxed), the evolutions dimmed under one "max both" divider until forged, the detail pane with the
-- value now -> next (StatPipeline) and one big UPGRADE button. One tap buys (Shells are for this voyage only);
-- keys 1-4 still buy straight away. Walking away (or dying) closes it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Upgrades = require(Shared:WaitForChild("Upgrades")) :: any
local StatPipeline = require(Shared:WaitForChild("StatPipeline")) :: any -- S5.7: the values previews and voyages share
local SoundFx = require(Shared:WaitForChild("SoundFx")) :: any
local UiKit = require(script.Parent:WaitForChild("UiKit")) :: any
local Tiles = require(script.Parent:WaitForChild("UI"):WaitForChild("Tiles")) :: any
local Vitals = require(script.Parent:WaitForChild("Vitals")) :: any -- the lamp, tower and health while it is open

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local state = ReplicatedStorage:WaitForChild("GameState")
local player = Players.LocalPlayer

local REQUEST_TIMEOUT = 6
local WALK_AWAY = 16
local VOYAGE_PHASES = { Prologue = true, Day = true, Night = true }

-- what each upgrade does, in the player's words (presentation only)
local BENEFIT: { [string]: any } = {
	LensPower = { label = "Beam damage", fmt = function(v: number): string
		return math.floor(v * 100 + 0.5) .. "%"
	end, glyph = "lamp" },
	FuelTank = { label = "Max fuel", fmt = tostring, extra = "Also refills 30 fuel.", glyph = "plus" },
	Walls = { label = "Tower strength", fmt = tostring, extra = "Also repairs 50.", glyph = "tower" },
	ClockworkSweep = { label = "Auto-sweep damage", fmt = function(v: number): string
		return v .. "/s"
	end, glyph = "next" },
}

local selectedId: string? = nil
local pendingId: string? = nil
local pendingUpgrade: string? = nil

local function shells(): number
	return state:GetAttribute("Shells") or 0
end
local function levelOf(id: string): number
	return state:GetAttribute("Upgrade_" .. id) or 0
end

local closeBench: () -> () -- forward
local buy: (string) -> () -- forward
local menu = Tiles.Menu({
	name = "UpgradeBench",
	displayOrder = 18,
	title = "Upgrade Bench",
	onClose = function()
		closeBench()
	end,
})

-- ICON1: `key` names the tile's picture in Shared/ItemIcons; the glyph shows when there is none
local function glyphIcon(kind: string, color: Color3?, key: string?): (Instance) -> ()
	return function(holder: Instance)
		if key and Tiles.picture(holder, key) then
			return
		end
		Tiles.glyph(holder, kind, color or UiKit.Color.AccentLighthouse)
	end
end

local function clockText(): string
	local phase = state:GetAttribute("Phase") or ""
	local night = state:GetAttribute("Night") or 0
	if phase == "Day" then
		return string.format("Day %d · crew Shells, this voyage only", night)
	elseif phase == "Night" then
		return string.format("Night %d · the storm is on", night)
	end
	return "Crew Shells · this voyage only"
end

---------------------------------------------------------------------
-- TILES AND DETAIL
---------------------------------------------------------------------

local function tiles(): { any }
	local list = {}
	local balance = shells()
	for _, id in Upgrades.ORDER do
		local upgrade = Upgrades[id]
		local level = levelOf(id)
		local maxed = level >= #upgrade.costs
		local price = if maxed then 0 else upgrade.costs[level + 1]
		table.insert(list, {
			id = id,
			name = upgrade.displayName,
			icon = glyphIcon(BENEFIT[id] and BENEFIT[id].glyph or "plus", nil, id),
			cost = if maxed then nil else { kind = "Shells", amount = price },
			affordable = balance >= price,
			owned = maxed,
			ownedText = "Maxed",
			qty = if level > 0 then level else nil,
		})
	end
	if Config.EVOLUTIONS_ENABLED == true then
		for _, evo in Upgrades.EVOLUTIONS or {} do
			local forged = state:GetAttribute("Evo_" .. evo.id) == true
			table.insert(list, {
				id = "Evo_" .. evo.id,
				name = evo.displayName,
				icon = glyphIcon("diamond", Color3.fromRGB(176, 113, 255), "Evolution"),
				owned = forged,
				ownedText = "Forged",
				locked = if forged then nil else "Max both upgrades to forge",
			})
		end
	end
	return list
end

local function evolution(id: string): any
	for _, evo in Upgrades.EVOLUTIONS or {} do
		if "Evo_" .. evo.id == id then
			return evo
		end
	end
	return nil
end

local function upgradeDetail(id: string): any
	local upgrade = Upgrades[id]
	local b = BENEFIT[id]
	local level = levelOf(id)
	local maxLevel = #upgrade.costs
	local maxed = level >= maxLevel
	local price = if maxed then 0 else upgrade.costs[level + 1]
	local balance = shells()
	local stats: { any } = { { label = "Level", from = tostring(level), to = tostring(math.min(level + 1, maxLevel)), better = true } }
	if maxed then
		stats = { { label = "Level", value = string.format("%d / %d", level, maxLevel) } }
	end
	if b then
		local now = StatPipeline.upgrade(id, level)
		if maxed then
			table.insert(stats, { label = b.label, value = b.fmt(now) })
		else
			table.insert(stats, { label = b.label, from = b.fmt(now), to = b.fmt(StatPipeline.upgrade(id, level + 1)), better = true })
		end
	end
	local reason = if maxed then upgrade.displayName .. " is fully upgraded for this voyage."
		elseif balance < price then string.format("The crew needs %d more Shells.", price - balance)
		elseif pendingId then "Fitting the last upgrade..."
		else nil
	return {
		icon = glyphIcon(b and b.glyph or "plus", nil, id),
		name = upgrade.displayName,
		description = upgrade.description .. (if b and b.extra and not maxed then ". " .. b.extra else ""),
		stats = stats,
		cost = if maxed then nil else { kind = "Shells", amount = price, affordable = balance >= price },
		action = {
			text = if maxed then "Maxed" elseif pendingUpgrade == id then "Fitting..." else "Upgrade",
			enabled = reason == nil,
			reason = reason,
			onPress = function()
				buy(id)
			end,
		},
	}
end

local function evolutionDetail(id: string): any
	local evo = evolution(id)
	if not evo then
		return nil
	end
	local forged = state:GetAttribute("Evo_" .. evo.id) == true
	local stats = {}
	for _, need in evo.needs do
		local max = #Upgrades[need].costs
		table.insert(stats, { label = Upgrades[need].displayName, value = string.format("%d / %d", levelOf(need), max) })
	end
	return {
		icon = glyphIcon("diamond", Color3.fromRGB(176, 113, 255), "Evolution"),
		name = evo.displayName,
		description = evo.description .. ".",
		stats = stats,
		action = {
			text = if forged then "Forged" else "Max both",
			enabled = false,
			reason = if forged then "Forged: it is working for the rest of the voyage." else "Max both upgrades and it forges itself.",
		},
	}
end

local function render()
	if not menu.isOpen then
		return
	end
	menu:setResources({ { kind = "Shells", amount = shells() } })
	menu.subtitle.Text = clockText()
	local list = tiles()
	if not selectedId then
		selectedId = list[1] and list[1].id
	end
	menu:setTiles(list, selectedId)
	if selectedId and Upgrades[selectedId] then
		menu:setDetail(upgradeDetail(selectedId))
	elseif selectedId then
		menu:setDetail(evolutionDetail(selectedId))
	end
end

menu.onSelect = function(id: string)
	selectedId = id
	if Upgrades[id] then
		menu:setDetail(upgradeDetail(id))
	else
		menu:setDetail(evolutionDetail(id))
	end
end

---------------------------------------------------------------------
-- BUYING (one request at a time; the server decides)
---------------------------------------------------------------------

buy = function(id: string)
	if not menu.isOpen or pendingId then
		return
	end
	local upgrade = Upgrades[id]
	local level = levelOf(id)
	if level >= #upgrade.costs or shells() < upgrade.costs[level + 1] then
		SoundFx.play2D("denied")
		menu.toast(if level >= #upgrade.costs then "Fully upgraded for this voyage." else string.format("The crew needs %d more Shells.", upgrade.costs[level + 1] - shells()))
		return
	end
	local requestId = HttpService:GenerateGUID(false)
	pendingId, pendingUpgrade = requestId, id
	selectedId = id
	render()
	remotes.BuyUpgrade:FireServer(id, requestId)
	task.delay(REQUEST_TIMEOUT, function()
		if pendingId == requestId then
			-- no reply: trust the replicated level, never guess (a late reply is ignored)
			pendingId, pendingUpgrade = nil, nil
			if levelOf(id) <= level then
				menu.toast("No answer from the bench. Nothing was fitted. Try again.")
			end
			render()
		end
	end)
end

remotes:WaitForChild("UpgradeResult").OnClientEvent:Connect(function(requestId, ok, message, id)
	if requestId ~= pendingId then
		return
	end
	pendingId, pendingUpgrade = nil, nil
	if ok then
		SoundFx.play2D("lantern")
	else
		SoundFx.play2D("denied")
		menu.toast(message or "That didn't work. Nothing was spent.")
	end
	render()
	if ok and id then
		menu:pop(id)
	end
end)

---------------------------------------------------------------------
-- OPEN / CLOSE
---------------------------------------------------------------------

closeBench = function()
	if not menu.isOpen then
		return
	end
	menu:close()
	ContextActionService:UnbindAction("CloseBench")
	ContextActionService:UnbindAction("BenchKeys")
	GuiService.SelectedObject = nil
	UiKit.popModal("Bench")
end

local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four }

local function openBench()
	if menu.isOpen then
		return
	end
	UiKit.pushModal("Bench")
	menu:open()
	menu:setAlerts(Vitals.criticalChips())
	render()
	ContextActionService:BindAction("CloseBench", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			closeBench()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonB, Enum.KeyCode.Backspace)
	-- 1-4 buy straight away (and don't switch tools while the bench is open)
	ContextActionService:BindActionAtPriority("BenchKeys", function(_, inputState, input)
		if inputState == Enum.UserInputState.Begin then
			for index, key in KEYS do
				if input.KeyCode == key and Upgrades.ORDER[index] then
					buy(Upgrades.ORDER[index])
				end
			end
		end
		return Enum.ContextActionResult.Sink
	end, false, 3000, table.unpack(KEYS))
	task.defer(function()
		if UiKit.usingGamepad() and selectedId and menu.tiles[selectedId] then
			GuiService.SelectedObject = menu.tiles[selectedId].tile
		end
	end)
end

remotes:WaitForChild("OpenUpgrades").OnClientEvent:Connect(openBench)

state.AttributeChanged:Connect(function(name)
	if not menu.isOpen then
		return
	end
	if name == "Phase" and not VOYAGE_PHASES[state:GetAttribute("Phase") or ""] then
		closeBench() -- the voyage ended (results take the screen)
		return
	end
	if name == "Shells" or name == "Phase" or name == "Night" or string.sub(name, 1, 8) == "Upgrade_" or string.sub(name, 1, 4) == "Evo_" then
		render()
	end
end)

-- walking away (or dying) closes the bench
local lastTick = 0
RunService.Heartbeat:Connect(function()
	if not menu.isOpen then
		return
	end
	local now = os.clock()
	if now - lastTick < 0.25 then
		return
	end
	lastTick = now
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local island = Workspace:FindFirstChild("Island")
	local bench = island and island:FindFirstChild("UpgradeBench") :: BasePart?
	if not rootPart or not humanoid or humanoid.Health <= 0 or not bench or (rootPart.Position - bench.Position).Magnitude > WALK_AWAY then
		closeBench()
		return
	end
	menu:setAlerts(Vitals.criticalChips())
end)
