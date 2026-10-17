--!strict
-- Trader (client): the salvage buyer on the lighthouse island.
--
-- Loot (crab claws, sea glass, black pearls) only lasts one voyage. The Trader turns it into Shells for the whole
-- crew. This is NOT a shop: no Pearls, no permanent items. S6.2: by day the Trader also sells the merchant's
-- voyage-only stock (Definitions/Merchant) for the crew's Shells (MerchantRequest -> MerchantResult).
-- The server opens it (TraderOpen, from the Trader's prompt) and does the selling (TraderRequest -> TraderResult,
-- "sellAll" only); it checks and applies everything. Shell values come from Shared/Items unchanged.
--
-- Built on the menu pattern (UI/Tiles, D-041/D-042, like the Quartermaster and the bench): two tabs, SALVAGE (one
-- tile per kind of loot carried, SELL ALL in the detail pane) and ISLAND STOCK (the merchant's tiles, dimmed under
-- "The Trader sells by day" at night). Critical lamp, tower and health states show as alerts while it is open.
-- Walking away (or dying) closes it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared:WaitForChild("Items")) :: any
local Merchant = require(Shared:WaitForChild("Definitions"):WaitForChild("Merchant")) :: any -- S6.2
local SoundFx = require(Shared:WaitForChild("SoundFx")) :: any
local UiKit = require(script.Parent:WaitForChild("UiKit")) :: any
local Tiles = require(script.Parent:WaitForChild("UI"):WaitForChild("Tiles")) :: any
local Vitals = require(script.Parent:WaitForChild("Vitals")) :: any

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local state = ReplicatedStorage:WaitForChild("GameState")
local player = Players.LocalPlayer

local REQUEST_TIMEOUT = 8
local WALK_AWAY = 16
local RULE = "Loot only lasts this voyage. Sell it here for Shells the whole crew can spend; anything unsold is gone when the run ends."

local LOOT: { string } = {}
for _, itemId in Items.SHOP_ORDER do
	if type(Items[itemId]) == "table" and Items[itemId].runScoped then
		table.insert(LOOT, itemId)
	end
end

-- the merchant's stock, drawn as glyphs (the stock has no 3D models)
local STOCK_GLYPH: { [string]: { string | Color3 } } = {
	OrbitingBlades = { "diamond", Color3.fromRGB(176, 113, 255) },
	DamageBoost = { "plus", Color3.fromRGB(255, 140, 60) },
	SpeedBoost = { "next", Color3.fromRGB(80, 210, 200) },
	Heal = { "heart", Color3.fromRGB(240, 80, 90) },
	OilBundle = { "lamp", Color3.fromRGB(255, 200, 80) },
	TowerShield = { "tower", Color3.fromRGB(110, 170, 255) },
	Salvage = { "info", Color3.fromRGB(80, 210, 200) }, -- the empty sack
}

local profile: any = nil
local tab = "Salvage"
local selectedId: string? = nil
local pendingSell: string? = nil
local awaitingCheck: number? = nil -- after a timeout: the sack's value before, while we re-check the server
local pendingBuy: { [string]: string } = {} -- itemId -> requestId while a purchase is in flight

local function merchantOpen(): boolean
	return state:GetAttribute("Phase") == "Day"
end
local function shells(): number
	return state:GetAttribute("Shells") or 0
end
local function count(itemId: string): number
	return if profile then (profile.counts[itemId] or 0) else 0
end
local function totalValue(): number
	local total = 0
	for _, itemId in LOOT do
		total += count(itemId) * (Items[itemId].shellValue or 0)
	end
	return total
end

local closeTrader: () -> () -- forward
local renderAll: () -> () -- forward
local menu = Tiles.Menu({
	name = "SalvageTrader",
	displayOrder = 18,
	title = "Trader",
	onClose = function()
		closeTrader()
	end,
})

local function glyphIcon(id: string): (Instance) -> ()
	local spec = STOCK_GLYPH[id] or { "plus", UiKit.Color.AccentLighthouse }
	return function(holder: Instance)
		Tiles.glyph(holder, spec[1] :: string, spec[2] :: Color3)
	end
end

---------------------------------------------------------------------
-- SELLING (everything at once; the server decides)
---------------------------------------------------------------------

local function sellAll()
	if pendingSell or totalValue() <= 0 then
		return
	end
	local requestId = HttpService:GenerateGUID(false)
	pendingSell = requestId
	awaitingCheck = nil
	renderAll()
	remotes.TraderRequest:FireServer(requestId, "sellAll")
	local valueBefore = totalValue()
	task.delay(REQUEST_TIMEOUT, function()
		if pendingSell == requestId then
			-- no reply: ask the server what really happened (a late reply is ignored)
			pendingSell = nil
			awaitingCheck = valueBefore
			menu.toast("The Trader didn't answer. Checking your sack...")
			remotes.GearAction:FireServer("sync")
			renderAll()
		end
	end)
end

local function sold(amount: number)
	SoundFx.play2D("lantern")
	UiKit.Toast(menu.root, string.format("Sold for %s Shells. The crew can spend them at the bench.", UiKit.formatNumber(amount)), "success")
end

---------------------------------------------------------------------
-- BUYING from the island stock (by day, the crew's Shells)
---------------------------------------------------------------------

local function stockReason(id: string): string?
	local def = Merchant[id]
	local owned = player:GetAttribute("Merchant_" .. id) or 0
	if not merchantOpen() then
		return "The Trader sells by day."
	elseif def.limit and owned >= def.limit then
		return "That's all the Trader has for you this voyage."
	elseif def.effect == "shield" and state:GetAttribute("TowerShield") then
		return "The tower is already shielded until dawn."
	elseif shells() < def.price then
		return string.format("The crew needs %d more Shells.", def.price - shells())
	elseif pendingBuy[id] then
		return "Buying..."
	end
	return nil
end

local function buyItem(id: string)
	if pendingBuy[id] or stockReason(id) then
		SoundFx.play2D("denied")
		return
	end
	local requestId = HttpService:GenerateGUID(false)
	pendingBuy[id] = requestId
	renderAll()
	remotes.MerchantRequest:FireServer(requestId, "buy", id, 1)
	task.delay(REQUEST_TIMEOUT, function()
		if pendingBuy[id] == requestId then
			pendingBuy[id] = nil -- the counts shown are the server's, so they show what really happened
			menu.toast("The Trader didn't answer. Check the stock and try again.")
			renderAll()
		end
	end)
end

---------------------------------------------------------------------
-- TILES AND DETAIL
---------------------------------------------------------------------

local function salvageTiles(): { any }
	local list = {}
	for _, itemId in LOOT do
		local n = count(itemId)
		if n > 0 then
			table.insert(list, {
				id = itemId,
				name = Items[itemId].name,
				icon = itemId,
				cost = { kind = "Shells", amount = n * (Items[itemId].shellValue or 0) },
				affordable = true,
				qty = n,
			})
		end
	end
	return list
end

local function stockTiles(): { any }
	local list = {}
	for _, id in Merchant.ORDER do
		local def = Merchant[id]
		local owned = player:GetAttribute("Merchant_" .. id) or 0
		local soldOut = def.limit ~= nil and owned >= def.limit
		table.insert(list, {
			id = id,
			name = def.displayName,
			icon = glyphIcon(id),
			cost = if soldOut then nil else { kind = "Shells", amount = def.price },
			affordable = shells() >= def.price,
			owned = soldOut,
			ownedText = "Bought",
			qty = if owned > 0 then owned else nil,
			locked = if merchantOpen() then nil else "The Trader sells by day",
		})
	end
	return list
end

local function salvageDetail(itemId: string?): any
	local total = totalValue()
	local action = {
		text = if pendingSell then "Selling..." else (if total > 0 then "Sell all" else "Nothing to sell"),
		enabled = total > 0 and pendingSell == nil,
		reason = if total <= 0 then "You aren't carrying any loot. Creatures drop crab claws, sea glass and black pearls." else "Selling...",
		onPress = sellAll,
	}
	if not itemId or not Items[itemId] then
		return {
			icon = glyphIcon("Salvage"),
			name = "Nothing to sell yet",
			description = RULE,
			stats = { { label = "Trader pays", value = string.format("%d Shells", total) } },
			action = action,
		}
	end
	local item = Items[itemId]
	local n = count(itemId)
	return {
		icon = itemId,
		name = item.name,
		description = RULE,
		stats = {
			{ label = "You carry", value = "\u{00D7}" .. n },
			{ label = "Each", value = string.format("%d Shells", item.shellValue or 0) },
			{ label = "All your salvage", value = string.format("%d Shells", total) },
		},
		cost = { kind = "Shells", amount = total, affordable = true },
		action = action,
	}
end

local function stockDetail(id: string): any
	local def = Merchant[id]
	local owned = player:GetAttribute("Merchant_" .. id) or 0
	local stats: { any } = {
		{ label = "For", value = if def.scope == "crew" then "the whole crew" else "you" },
		{ label = "Lasts", value = if def.effect == "shield" then "until dawn" elseif def.effect == "heal" or def.effect == "oil" then "right away" else "this voyage" },
	}
	if def.limit then
		table.insert(stats, { label = "Bought", value = string.format("%d / %d", owned, def.limit) })
	end
	local why = stockReason(id)
	return {
		icon = glyphIcon(id),
		name = def.displayName,
		description = def.description .. ".",
		stats = stats,
		cost = { kind = "Shells", amount = def.price, affordable = shells() >= def.price },
		action = {
			text = if pendingBuy[id] then "Buying..." else "Buy",
			enabled = why == nil,
			reason = why,
			onPress = function()
				buyItem(id)
			end,
		},
	}
end

local function renderDetail()
	if tab == "Salvage" then
		menu:setDetail(salvageDetail(selectedId))
	elseif selectedId and Merchant[selectedId] then
		menu:setDetail(stockDetail(selectedId))
	else
		menu:setDetail(nil)
	end
end

renderAll = function()
	if not menu.isOpen then
		return
	end
	menu:setResources({ { kind = "Shells", amount = shells() } })
	menu.subtitle.Text = if tab == "Salvage" then "\u{201C}Claws, glass, pearls. I'll take the lot.\u{201D}" else (if merchantOpen() then "Island stock, by day, for the crew's Shells" else "The Trader sells by day")
	if not profile then
		menu:setTiles({}, nil)
		menu:setDetail({ name = "Counting your salvage", description = RULE })
		return
	end
	local list = if tab == "Salvage" then salvageTiles() else stockTiles()
	local stillThere = false
	for _, t in list do
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
-- SERVER ANSWERS
---------------------------------------------------------------------

remotes:WaitForChild("TraderResult").OnClientEvent:Connect(function(requestId, ok, message, total)
	if requestId ~= pendingSell then
		return
	end
	pendingSell = nil
	if ok then
		sold(tonumber(total) or 0)
	else
		SoundFx.play2D("denied")
		menu.toast(message or "That didn't work. Nothing was sold.")
	end
	renderAll()
end)

remotes:WaitForChild("MerchantResult").OnClientEvent:Connect(function(requestId, ok, message)
	for id, pending in pendingBuy do
		if pending == requestId then
			pendingBuy[id] = nil
			if ok then
				SoundFx.play2D("lantern")
				renderAll()
				menu:pop(id)
			else
				SoundFx.play2D("denied")
				menu.toast(message or "That didn't work. No Shells were spent.")
				renderAll()
			end
			return
		end
	end
end)

remotes:WaitForChild("GearData").OnClientEvent:Connect(function(data)
	profile = data
	if awaitingCheck then
		-- the server's own data decides: the sack is empty -> the sale went through
		if totalValue() <= 0 then
			sold(awaitingCheck)
		else
			menu.toast("The Trader didn't answer. Nothing was sold. Try again.")
		end
		awaitingCheck = nil
	end
	renderAll()
end)

for _, name in { "Phase", "TowerShield", "Shells" } do
	state:GetAttributeChangedSignal(name):Connect(renderAll)
end
player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 9) == "Merchant_" then
		renderAll()
	end
end)

---------------------------------------------------------------------
-- OPEN / CLOSE
---------------------------------------------------------------------

local TABS = { { id = "Salvage", label = "Salvage" }, { id = "Stock", label = "Island stock" } }

closeTrader = function()
	if not menu.isOpen then
		return
	end
	menu:close()
	ContextActionService:UnbindAction("CloseTrader")
	GuiService.SelectedObject = nil
	UiKit.popModal("Trader")
end

local function openTrader()
	if menu.isOpen then
		return
	end
	table.clear(pendingBuy)
	pendingSell, awaitingCheck = nil, nil
	-- by day with nothing to sell, the stock is what the player came for
	tab = if merchantOpen() and totalValue() <= 0 then "Stock" else "Salvage"
	selectedId = nil
	UiKit.pushModal("Trader")
	menu:open()
	menu:setTabs(TABS, tab, function(id)
		tab = id
		selectedId = nil
		renderAll()
	end)
	menu:setAlerts(Vitals.criticalChips())
	renderAll()
	remotes.GearAction:FireServer("sync")
	ContextActionService:BindAction("CloseTrader", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			closeTrader()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonB, Enum.KeyCode.Backspace)
	task.defer(function()
		if UiKit.usingGamepad() and selectedId and menu.tiles[selectedId] then
			GuiService.SelectedObject = menu.tiles[selectedId].tile
		end
	end)
end

remotes:WaitForChild("TraderOpen").OnClientEvent:Connect(openTrader)

-- walking away (or dying) closes it; critical states show as alerts while it is open
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
	local trader = island and island:FindFirstChild("Trader") :: BasePart?
	if not rootPart or not humanoid or humanoid.Health <= 0 or not trader or (rootPart.Position - trader.Position).Magnitude > WALK_AWAY then
		closeTrader()
		return
	end
	menu:setAlerts(Vitals.criticalChips())
end)

remotes.GearAction:FireServer("sync")
