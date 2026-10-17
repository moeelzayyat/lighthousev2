--!strict
-- Shop (client): the Quartermaster's supply counter at the harbor.
--
-- ONLY the server opens it (the Quartermaster's Trade prompt) and it closes when the player walks away. Every
-- purchase is a request (ShopRequest -> ShopResult) and every equip a LoadoutRequest -> LoadoutResult; the server
-- validates price, Pearls, ownership, stack limits, range and duplicate requests. Nothing here changes data.
--
-- S2.5c (D-041/D-042): built on the menu pattern (UI/Tiles): big category buttons over a grid of equal tiles (icon,
-- name, cost), one tile always selected, the detail pane on the right with the stat change against what is
-- equipped and one big action button. A Pearl purchase asks for one more tap (CONFIRM) before it is sent.
-- Studio only: player attribute HudSimulate draws it inside a simulated screen size (handled by Tiles).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared:WaitForChild("Items")) :: any
local Weapons = require(Shared:WaitForChild("Weapons")) :: any
local Ammo = require(Shared:WaitForChild("Ammo")) :: any
local SoundFx = require(Shared:WaitForChild("SoundFx")) :: any
local StatPipeline = require(Shared:WaitForChild("StatPipeline")) :: any -- S5.7: the values previews and voyages share
local Boosts = require(Shared:WaitForChild("Definitions"):WaitForChild("Boosts")) :: any -- S6.4
local Cosmetics = require(Shared:WaitForChild("Definitions"):WaitForChild("Cosmetics")) :: any -- L1.3
local UiKit = require(script.Parent:WaitForChild("UiKit")) :: any
local Tiles = require(script.Parent:WaitForChild("UI"):WaitForChild("Tiles")) :: any

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer

local REQUEST_TIMEOUT = 8
local CONFIRM_SECONDS = 3

local profile: any = nil
local category = "Weapons"
local selectedId: string? = nil
local pendingId: string? = nil
local pendingDone: any = nil
local confirming: string? = nil
local confirmUntil = 0
local quantity = 1
local greeting = ""

---------------------------------------------------------------------
-- FACTS
---------------------------------------------------------------------

local function count(itemId: string): number
	return if profile then (profile.counts[itemId] or 0) else 0
end
local function owns(itemId: string): boolean
	return profile ~= nil and profile.owned[itemId] == true
end
local EQUIPPED_FIELDS = { "equippedWeapon", "equippedArmor", "equippedBeam", "equippedHousing", "equippedCoat", "equippedLantern", "equippedFlag" }
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
local function pearls(): number
	return if profile then profile.pearls or 0 else 0
end
local function boostRanks(): { [string]: number }
	return if profile and type(profile.boosts) == "table" then profile.boosts else {}
end
local function itemsIn(cat: string): { string }
	local list = {}
	for _, itemId in Items.SHOP_ORDER do
		local item = Items[itemId]
		if item.category == cat and (item.price or owns(itemId) or Cosmetics.productFor(itemId)) then
			table.insert(list, itemId)
		end
	end
	return list
end
local function ammoRoom(itemId: string): (number, number, number)
	local item = Items[itemId]
	local room = item.maxStack - count(itemId)
	local afford = if item.price and item.price > 0 then math.floor(pearls() / item.price) else 0
	return room, afford, math.max(0, math.min(room, afford))
end
local function equippedIn(item: any): string?
	if not profile then
		return nil
	end
	if item.kind == "Weapon" then
		return profile.equippedWeapon
	elseif item.kind == "Armor" then
		return profile.equippedArmor
	elseif item.kind == "Cosmetic" and item.slot == "Beam" then
		return profile.equippedBeam or "BeamAmber"
	elseif item.kind == "Cosmetic" then
		return profile["equipped" .. item.slot]
	end
	return nil
end

-- the detail pane's stat lines: what is equipped now -> this item (StatPipeline, the in-voyage values)
local function statLines(itemId: string): { any }
	local item = Items[itemId]
	local lines = {}
	local current = equippedIn(item)
	local compare = current ~= nil and current ~= itemId
	local function add(labelText: string, value: number, now: number?, higherIsBetter: boolean, fmt: (number) -> string)
		if compare and now ~= nil and now ~= value then
			table.insert(lines, { label = labelText, from = fmt(now), to = fmt(value), better = if higherIsBetter then value > now else value < now })
		else
			table.insert(lines, { label = labelText, value = fmt(value) })
		end
	end
	if item.kind == "Weapon" then
		local w = StatPipeline.weapon(itemId)
		local cw = if compare and current and Weapons[current] then StatPipeline.weapon(current) else nil
		add("Damage", w.damage, cw and cw.damage, true, tostring)
		add("Reload", w.cooldown, cw and cw.cooldown, false, function(v)
			return string.format("%.1f s", v)
		end)
		add("Targets", w.maxTargets, cw and cw.maxTargets, true, tostring)
	elseif item.kind == "Armor" then
		local a = StatPipeline.armor(itemId)
		local ca = if compare and current and Items[current] then StatPipeline.armor(current) else nil
		add("Health", a.maxHealth, ca and ca.maxHealth, true, tostring)
		add("Blocks", math.floor(a.damageReduction * 100 + 0.5), ca and math.floor(ca.damageReduction * 100 + 0.5), true, function(v)
			return v .. "%"
		end)
	elseif item.kind == "Ammo" then
		local a = Ammo[item.ammoType]
		table.insert(lines, { label = "Shots per crate", value = tostring(a.shotsPerLoad) })
		table.insert(lines, { label = "Cannon damage", value = string.format("x%.1f", a.damageMultiplier) })
		table.insert(lines, { label = "You carry", value = string.format("%d / %d", count(itemId), item.maxStack) })
	elseif item.kind == "Cosmetic" then
		table.insert(lines, { label = "Power", value = "none: looks only" })
	end
	return lines
end

---------------------------------------------------------------------
-- MENU
---------------------------------------------------------------------

local closeShop: (string?, boolean) -> () -- forward
local menu = Tiles.Menu({
	name = "QuartermasterShop",
	displayOrder = 20,
	title = "Quartermaster",
	onClose = function()
		closeShop(nil, false)
	end,
})

-- notices shown after the counter closes (e.g. "You walked away") and purchase confirmations
local noticeGui = UiKit.Screen("ShopNotice", 21)
local noticeRoot = UiKit.new("Frame", { Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, noticeGui)
noticeRoot:SetAttribute("NoticeTop", 40)

local TABS = { { id = "Weapons", label = "Weapons" }, { id = "Armor", label = "Armor" }, { id = "Ammunition", label = "Ammo" }, { id = "Boosts", label = "Boosts" }, { id = "Cosmetics", label = "Cosmetics" } }

local renderAll: () -> () -- forward

-- one request at a time; done(ok, message) is called with the server's answer (or a timeout)
local function send(action: string, itemId: string, qty: number, done: (boolean, string?) -> ()): boolean
	if pendingId then
		return false
	end
	local id = string.sub(HttpService:GenerateGUID(false), 1, 36)
	pendingId, pendingDone = id, done
	remotes.ShopRequest:FireServer(id, action, itemId, qty)
	task.delay(REQUEST_TIMEOUT, function()
		if pendingId == id then
			pendingId, pendingDone = nil, nil
			done(false, "The Quartermaster didn't answer. Nothing was spent. Try again in a moment.")
		end
	end)
	return true
end

local function afterRequest(ok: boolean, message: string?, itemId: string)
	renderAll()
	if ok then
		SoundFx.play2D("lantern")
		menu:pop(itemId)
	else
		SoundFx.play2D("denied")
	end
	if message then
		UiKit.Toast(noticeRoot, message, if ok then "success" else "danger")
	end
end

-- a Pearl purchase: the first tap turns the button into CONFIRM for a few seconds, the second sends it
local function confirmThen(itemId: string, run: () -> ())
	if confirming == itemId and os.clock() < confirmUntil then
		confirming = nil
		run()
		return
	end
	confirming, confirmUntil = itemId, os.clock() + CONFIRM_SECONDS
	SoundFx.play2D("click")
	renderAll()
	task.delay(CONFIRM_SECONDS + 0.05, function()
		if confirming == itemId and os.clock() >= confirmUntil then
			confirming = nil
			renderAll()
		end
	end)
end

local function equip(itemId: string)
	if pendingId then
		return
	end
	local id = string.sub(HttpService:GenerateGUID(false), 1, 36)
	pendingId = id
	pendingDone = function(ok, message)
		afterRequest(ok, message or (if ok then "Equipped." else "That didn't work. Your loadout didn't change."), itemId)
	end
	remotes.LoadoutRequest:FireServer(id, "equip", itemId)
	task.delay(REQUEST_TIMEOUT, function()
		if pendingId == id then
			pendingId, pendingDone = nil, nil
			afterRequest(false, "No answer. Your loadout didn't change. Try again.", itemId)
		end
	end)
	renderAll()
end

-- L1.3: the price Roblox reports for this player (managed pricing); the catalogue's price until it arrives
local livePrices: { [number]: any } = {}
local function priceFor(product: any): number
	local live = livePrices[product.productId]
	if live == nil then
		livePrices[product.productId] = false
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(product.productId, Enum.InfoType.Product)
			end)
			if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then
				livePrices[product.productId] = info.PriceInRobux
				renderAll()
			end
		end)
	end
	return if type(live) == "number" then live else product.robux
end

---------------------------------------------------------------------
-- TILES AND DETAIL
---------------------------------------------------------------------

local function boostIcon(holder: Instance)
	Tiles.glyph(holder, "plus", UiKit.Color.AccentLighthouse)
end

local function itemTiles(): { any }
	local list = {}
	local balance = pearls()
	for _, itemId in itemsIn(category) do
		local item = Items[itemId]
		local price = item.price or 0
		local owned = owns(itemId) and item.kind ~= "Ammo"
		local product = if item.kind == "Cosmetic" then Cosmetics.productFor(itemId) else nil
		local qty = if item.kind == "Ammo" then count(itemId) else nil
		table.insert(list, {
			id = itemId,
			name = item.name,
			icon = itemId,
			cost = if price > 0 and not owned then { kind = "Pearls", amount = price } else nil,
			cost2 = if product and not owned then ("R$ " .. priceFor(product)) else nil,
			affordable = balance >= price,
			owned = owned,
			ownedText = if isEquipped(itemId) then "Equipped" else "Owned",
			qty = if qty and qty > 0 then qty else nil,
		})
	end
	return list
end

local function boostTiles(): { any }
	local list = {}
	local ranks = boostRanks()
	for _, id in Boosts.ORDER do
		local def = Boosts[id]
		local rank = ranks[id] or 0
		local ok, price, reason = Boosts.nextRank(ranks, id)
		local top = rank >= #def.prices
		table.insert(list, {
			id = id,
			name = def.displayName,
			icon = boostIcon,
			cost = if ok and price then { kind = "Pearls", amount = price } else nil,
			affordable = ok and price ~= nil and pearls() >= price,
			owned = top,
			ownedText = "Max rank",
			qty = if rank > 0 then rank else nil,
			locked = if not ok and not top and reason then string.format("Boost limit +%d%% reached", math.floor(Boosts.TOTAL_CAP * 100 + 0.5)) else nil,
		})
	end
	return list
end

local function quantityStepper(container: Instance, unit: any, itemId: string)
	local _, _, max = ammoRoom(itemId)
	quantity = math.clamp(quantity, if max > 0 then 1 else 0, math.max(max, 0))
	local row = UiKit.new("Frame", { Name = "Quantity", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, unit.min + 8) }, container)
	UiKit.list(row, "x", 12, { HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center })
	local function stepButton(text: string, order: number, width: number, onPress: () -> ())
		local b = Tiles.bigButton(row, "Step_" .. text)
		b.button.LayoutOrder = order
		b.button.Size = UDim2.fromOffset(width, unit.min)
		b.paint({ face = Color3.fromRGB(36, 73, 110), edge = Color3.fromRGB(19, 40, 61), text = Color3.new(1, 1, 1) }, text)
		local pad = b.text:FindFirstChildOfClass("UIPadding")
		if pad then -- small square buttons: a bigger sign
			pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 4), UDim.new(0, 4)
		end
		b.button.Activated:Connect(onPress)
	end
	stepButton("-", 1, unit.min, function()
		quantity = math.max(1, quantity - 1)
		renderAll()
	end)
	local n = UiKit.Label(row, "\u{00D7}" .. quantity, "H2", { LayoutOrder = 2, Size = UDim2.fromOffset(unit.min + 20, unit.min), AutomaticSize = Enum.AutomaticSize.None, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextSize = 36 })
	n.Name = "Count"
	stepButton("+", 3, unit.min, function()
		local _, _, m = ammoRoom(itemId)
		quantity = math.min(math.max(m, 1), quantity + 1)
		renderAll()
	end)
	stepButton("Max", 4, unit.min + 40, function()
		local _, _, m = ammoRoom(itemId)
		quantity = math.max(1, m)
		renderAll()
	end)
end

local function itemDetail(itemId: string): any
	local item = Items[itemId]
	local balance = pearls()
	local price = item.price or 0
	local product = if item.kind == "Cosmetic" and not owns(itemId) then Cosmetics.productFor(itemId) else nil
	local detail: any = {
		icon = itemId,
		name = item.name,
		description = item.description,
		stats = statLines(itemId),
	}
	local busy = pendingId ~= nil
	if item.kind == "Ammo" then
		local room, afford, max = ammoRoom(itemId)
		local qty = math.max(quantity, 1)
		detail.cost = { kind = "Pearls", amount = price * qty, affordable = balance >= price * qty }
		detail.extra = function(container, unit)
			quantityStepper(container, unit, itemId)
		end
		local reason = if room <= 0 then string.format("Your stack is full (%d / %d). Use some in a cannon first.", count(itemId), item.maxStack)
			elseif afford <= 0 then string.format("Need %d more Pearls.", price - balance)
			elseif busy then "Finishing the last order..."
			else nil
		detail.action = {
			text = if confirming == itemId then "Confirm" else "Buy",
			enabled = reason == nil and max > 0,
			reason = reason,
			onPress = function()
				confirmThen(itemId, function()
					local n = math.max(1, quantity)
					send("buy", itemId, n, function(ok, message)
						afterRequest(ok, message, itemId)
					end)
					renderAll()
				end)
			end,
		}
	elseif owns(itemId) then
		local equipped = isEquipped(itemId)
		detail.action = {
			text = if equipped then "Equipped" else "Equip",
			enabled = not equipped and not busy,
			reason = if equipped then "You have this equipped." else "Finishing the last order...",
			onPress = function()
				equip(itemId)
			end,
		}
	else
		if price > 0 then
			detail.cost = { kind = "Pearls", amount = price, affordable = balance >= price }
			local reason = if balance < price then string.format("Need %d more Pearls. Earn them by surviving nights.", price - balance)
				elseif busy then "Finishing the last order..."
				else nil
			detail.action = {
				text = if confirming == itemId then "Confirm" else "Buy",
				enabled = reason == nil,
				reason = reason,
				onPress = function()
					confirmThen(itemId, function()
						send("buy", itemId, 1, function(ok, message)
							afterRequest(ok, message, itemId)
						end)
						renderAll()
					end)
				end,
			}
		end
		if product then
			local robux = {
				text = "R$ " .. priceFor(product),
				enabled = true,
				variant = "robux",
				onPress = function()
					MarketplaceService:PromptProductPurchase(player, product.productId)
				end,
			}
			if detail.action then
				detail.action2 = robux
			else
				detail.action = robux
			end
		end
		if not detail.action then
			detail.action = { text = "Earned", enabled = false, reason = "Earned in play, never sold." }
		end
	end
	return detail
end

local function boostDetail(id: string): any
	local def = Boosts[id]
	local ranks = boostRanks()
	local rank = ranks[id] or 0
	local ok, price, reason = Boosts.nextRank(ranks, id)
	local pct = function(r: number): string
		return "+" .. math.floor(def.step * r * 100 + 0.5) .. "%"
	end
	local stats: { any } = {
		{ label = "Rank", from = tostring(rank), to = tostring(math.min(rank + 1, #def.prices)), better = true },
		{ label = "Bonus", from = pct(rank), to = pct(math.min(rank + 1, #def.prices)), better = true },
		{ label = "All boosts", value = string.format("+%d%% of +%d%%", math.floor(Boosts.total(ranks) * 100 + 0.5), math.floor(Boosts.TOTAL_CAP * 100 + 0.5)) },
	}
	if not ok then
		stats = { { label = "Rank", value = string.format("%d / %d", rank, #def.prices) }, stats[3] }
	end
	local balance = pearls()
	local why = if not ok then reason elseif price and balance < price then string.format("Need %d more Pearls.", price - balance) elseif pendingId then "Finishing the last order..." else nil
	return {
		icon = boostIcon,
		name = def.displayName,
		description = def.description,
		stats = stats,
		cost = if ok and price then { kind = "Pearls", amount = price, affordable = balance >= price } else nil,
		action = {
			text = if not ok and rank >= #def.prices then "Max rank" elseif confirming == id then "Confirm" else "Upgrade",
			enabled = why == nil,
			reason = why,
			onPress = function()
				confirmThen(id, function()
					send("boost", id, 1, function(success, message)
						afterRequest(success, message, id)
					end)
					renderAll()
				end)
			end,
		},
	}
end

local function renderDetail()
	if not profile or not selectedId then
		menu:setDetail(nil)
		return
	end
	if category == "Boosts" then
		menu:setDetail(if Boosts[selectedId] then boostDetail(selectedId) else nil)
	else
		menu:setDetail(if Items[selectedId] then itemDetail(selectedId) else nil)
	end
end

renderAll = function()
	if not menu.isOpen then
		return
	end
	menu:setResources({ { kind = "Pearls", amount = pearls() } })
	menu.subtitle.Text = greeting
	if not profile then
		menu:setTiles({}, nil)
		menu:setDetail({ name = "Opening the counter", description = "The Quartermaster is checking your account." })
		return
	end
	local list = if category == "Boosts" then boostTiles() else itemTiles()
	local stillThere = false
	for _, t in list do
		if t.id == selectedId then
			stillThere = true
		end
	end
	if not stillThere then
		selectedId = list[1] and list[1].id
		quantity = 1
	end
	menu:setTiles(list, selectedId)
	renderDetail()
end

menu.onSelect = function(id: string)
	if id ~= selectedId then
		quantity = 1
		confirming = nil
	end
	selectedId = id
	renderDetail()
end

---------------------------------------------------------------------
-- OPEN / CLOSE (the server decides; walking away closes it)
---------------------------------------------------------------------

closeShop = function(reason: string?, fromServer: boolean)
	if not menu.isOpen then
		return
	end
	menu:close()
	confirming = nil
	ContextActionService:UnbindAction("CloseShop")
	GuiService.SelectedObject = nil
	UiKit.popModal("Shop")
	if not fromServer then
		remotes.ShopRequest:FireServer("close", "close")
	end
	if reason then
		UiKit.Toast(noticeRoot, reason, "info")
	end
end

local function openShop(text: string?)
	greeting = "\u{201C}" .. (text or "Need equipment for the next storm?") .. "\u{201D}"
	if menu.isOpen then
		menu.subtitle.Text = greeting
		return
	end
	UiKit.pushModal("Shop")
	menu:open()
	menu:setTabs(TABS, category, function(id)
		category = id
		selectedId = nil
		quantity = 1
		confirming = nil
		renderAll()
	end)
	renderAll()
	ContextActionService:BindAction("CloseShop", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			closeShop(nil, false)
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonB, Enum.KeyCode.Backspace)
	task.defer(function()
		if UiKit.usingGamepad() and selectedId and menu.tiles[selectedId] then
			GuiService.SelectedObject = menu.tiles[selectedId].tile
		end
	end)
end

remotes.ShopOpen.OnClientEvent:Connect(function(open, text)
	if open then
		openShop(text)
	else
		closeShop(text, true)
	end
end)

remotes.ShopResult.OnClientEvent:Connect(function(requestId, ok, message)
	if requestId ~= pendingId then
		return
	end
	local done = pendingDone
	pendingId, pendingDone = nil, nil
	if done then
		done(ok, message)
	end
end)

remotes.LoadoutResult.OnClientEvent:Connect(function(requestId, ok, message)
	if requestId ~= pendingId then
		return -- the BAG's own requests are answered there
	end
	local done = pendingDone
	pendingId, pendingDone = nil, nil
	if done then
		done(ok, message)
	end
end)

remotes.GearData.OnClientEvent:Connect(function(data)
	profile = data
	renderAll()
end)

remotes.GearAction:FireServer("sync")
