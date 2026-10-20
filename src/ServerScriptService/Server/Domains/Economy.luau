-- Economy domain (S5.1/S5.2): Pearls banked at dawn, the Quartermaster shop, loadouts, the gear a player
-- carries (weapon tools, worn armor), beam-colour cosmetics and the island Trader (selling loot, and from S6.2
-- the merchant's voyage-only stock).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local MarketplaceService = game:GetService("MarketplaceService") -- L1.3: ProcessReceipt (PurchaseService)
local Workspace = game:GetService("Workspace")

local Server = script.Parent.Parent
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Weapons = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Weapons"))
local Items = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Items"))
local SoundFx = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundFx"))
local StatPipeline = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StatPipeline")) -- S5.7
local EventLog = require(Server.EventLog)
local PlayerData = require(Server.PlayerData)
local GrantService = require(Server.GrantService)
local ChestService = require(Server.ChestService) -- CHEST.1
local DawnBanking = require(Server.DawnBanking) -- S2.2: Pearls banked at each dawn (bus consumer)
local ShopService = require(Server.ShopService)
local LoadoutService = require(Server.LoadoutService)
local UpgradeService = require(Server.UpgradeService)
local LampService = require(Server.LampService)
local VoyageCast = require(Server.VoyageCast)
local NetGuard = require(Server.NetGuard)
local MerchantService = require(Server.MerchantService) -- S6.2
local Merchant = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("Merchant"))
local Boosts = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("Boosts")) -- S6.4
local Specialties = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("Specialties")) -- S7.4
local PurchaseService = require(Server.PurchaseService) -- L1.3

local Economy = { Name = "Economy" }

---------------------------------------------------------------------
-- Gear: weapon tools and worn armor follow the saved loadout
---------------------------------------------------------------------

local ItemModels = ReplicatedStorage:WaitForChild("ItemModels")

-- Builds a weapon Tool from its 3D model in ReplicatedStorage.ItemModels.
-- The model's "Handle" part is what the character holds; every other part is welded to it.
local function buildWeaponTool(weaponId)
	local weapon = Weapons[weaponId]
	local item = Items[weaponId]
	local tool = Instance.new("Tool")
	tool.Name = weapon.displayName
	tool.CanBeDropped = false
	tool.ToolTip = "Click or tap a creature"
	tool:SetAttribute("WeaponId", weaponId)

	local model = item and item.model and ItemModels:FindFirstChild(item.model)
	if model then
		local copy = model:Clone()
		local handle = copy.PrimaryPart
		for _, part in copy:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.CanCollide = false
				part.Massless = true
				if part ~= handle then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = handle
					weld.Part1 = part
					weld.Parent = part
				end
			end
		end
		for _, child in copy:GetChildren() do
			child.Parent = tool
		end
		copy:Destroy()
		handle.Name = "Handle"
		-- GUN.1: a model whose barrel points the other way along its handle says how far to turn it in the hand
		local yaw = model:GetAttribute("GripYaw")
		if type(yaw) == "number" then
			tool.Grip = CFrame.Angles(0, math.rad(yaw), 0)
		end
	else
		-- Fallback if the model is missing: a plain stick
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.4, 0.4, 4.5)
		handle.Color = weapon.color
		handle.CanCollide = false
		handle.Massless = true
		handle.Parent = tool
	end
	return tool
end

-- Which weapon tools a player carries: just their equipped primary weapon
-- (or every weapon when the DEV_GIVE_ALL_WEAPONS testing switch is on).
local function weaponsFor(player)
	if Config.DEV_GIVE_ALL_WEAPONS then
		local list = {}
		for _, itemId in Items.SHOP_ORDER do
			if Weapons[itemId] and Weapons[itemId].archetype ~= "Orbit" then
				table.insert(list, itemId)
			end
		end
		return list
	end
	local profile = PlayerData.get(player)
	local weaponId = if profile then profile.equippedWeapon else Config.STARTER_WEAPON
	-- S6.4: an Orbit weapon is not a tool: OrbitService cuts with it (applyBoosts sets OrbitWeapon)
	if Weapons[weaponId] and Weapons[weaponId].archetype == "Orbit" then
		return {}
	end
	return { weaponId }
end

-- Puts the equipped armor model on the character's torso (purely visual; stats are applied separately)
local function wearArmor(character, itemId)
	local old = character:FindFirstChild("WornArmor")
	if old then
		old:Destroy()
	end
	local item = Items[itemId]
	local model = item and item.model and ItemModels:FindFirstChild(item.model)
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not model or not torso then
		return
	end
	local worn = model:Clone()
	worn.Name = "WornArmor"
	local handle = worn.PrimaryPart
	-- Fit the armor's width to the torso, keeping its proportions
	local scale = (torso.Size.X * 1.18) / handle.Size.X
	for _, part in worn:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Massless = true
		end
	end
	handle.Size *= scale
	-- Top of the armor lines up with the top of the torso (the model faces -Z like the character)
	handle.CFrame = torso.CFrame * CFrame.new(0, torso.Size.Y / 2 - handle.Size.Y / 2 + 0.15, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = torso
	weld.Part1 = handle
	weld.Parent = handle
	worn.Parent = character
end

-- L1.3: cosmetics the character wears ---------------------------------------
local COSMETIC_SLOTS = { "Housing", "Coat", "Lantern", "Flag" }
local PetRules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PetRules")) -- PET.1 (D-051)
local petNoteSent = {} -- PET.1: the "your puffin went home" note, once per session
local petOwned = {} -- PET.1: whether the player owned a pet at the last gear sync (a new one comes out at once)

-- A small lantern at the hip: glass in the lantern's colour between a cap and a base (no light: S4.4 budget)
local function buildLantern(character)
	local hip = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
	if not hip then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = "KeeperLantern"
	local at = hip.CFrame * CFrame.new(hip.Size.X / 2 + 0.3, -0.15, 0)
	local parts = {}
	for _, spec in { { "Glass", Vector3.new(0.36, 0.5, 0.36), 0, Enum.Material.Neon }, { "Cap", Vector3.new(0.48, 0.12, 0.48), 0.31, Enum.Material.Metal }, { "Base", Vector3.new(0.48, 0.12, 0.48), -0.31, Enum.Material.Metal } } do
		local part = Instance.new("Part")
		part.Name = spec[1]
		part.Size = spec[2]
		part.Material = spec[4]
		part.Color = Color3.fromRGB(70, 58, 44)
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		part.CFrame = at * CFrame.new(0, spec[3], 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hip
		weld.Part1 = part
		weld.Parent = part
		part.Parent = model
		parts[spec[1]] = part
	end
	model.PrimaryPart = parts.Glass
	model.Parent = character
	return model
end

-- Coat (the worn armor in the coat's colour) and lantern on the character, from the player's colour attributes
local function dressCosmetics(character, player)
	local coat = player:GetAttribute("CoatColor")
	local coatKey = if typeof(coat) == "Color3" then coat:ToHex() else ""
	if character:GetAttribute("WornCoat") ~= coatKey then
		character:SetAttribute("WornCoat", coatKey)
		local armorId = character:GetAttribute("WornArmorId")
		if armorId then
			wearArmor(character, armorId) -- a fresh copy, so taking the coat off brings back the armor's own look
		end
		local worn = character:FindFirstChild("WornArmor")
		if worn and typeof(coat) == "Color3" then
			for _, part in worn:GetDescendants() do
				if part:IsA("MeshPart") then
					part.TextureID = ""
				end
				if part:IsA("BasePart") then
					part.Color = coat
				end
			end
		end
	end
	local lanternColor = player:GetAttribute("LanternColor")
	local lantern = character:FindFirstChild("KeeperLantern")
	if typeof(lanternColor) ~= "Color3" then
		if lantern then
			lantern:Destroy()
		end
	else
		lantern = lantern or buildLantern(character)
		if lantern then
			lantern.Glass.Color = lanternColor
		end
	end
end

-- The highest point of the ship's mesh (the mast top), found once by looking straight down at it
local function mastTop(ship)
	local visual = ship:FindFirstChild("ShipVisual")
	if not (visual and visual:IsA("BasePart")) then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { visual }
	local best = nil
	local half = visual.Size / 2
	local couldQuery = visual.CanQuery
	visual.CanQuery = true -- the ship mesh is not queryable in play; only for these rays
	for i = 0, 24 do
		for j = 0, 24 do
			local local0 = Vector3.new(-half.X + visual.Size.X * i / 24, half.Y + 2, -half.Z + visual.Size.Z * j / 24)
			local origin = visual.CFrame:PointToWorldSpace(local0)
			local hit = Workspace:Raycast(origin, Vector3.new(0, -visual.Size.Y - 4, 0), params)
			if hit and (not best or hit.Position.Y > best.Y) then
				best = hit.Position
			end
		end
	end
	visual.CanQuery = couldQuery
	return best, visual
end

-- The ship flies the flag of the first player in the server who has one equipped (none: no flag)
local function refreshShipFlag()
	local lobby = Workspace:FindFirstChild("Lobby")
	local ship = lobby and lobby:FindFirstChild("PirateShip")
	if not ship then
		return
	end
	local color = nil
	for _, player in Players:GetPlayers() do
		local c = player:GetAttribute("FlagColor")
		if typeof(c) == "Color3" then
			color = c
			break
		end
	end
	local flag = ship:FindFirstChild("CosmeticFlag")
	if not color then
		if flag then
			flag:Destroy()
		end
		return
	end
	if not flag then
		local top, visual = mastTop(ship)
		if not top then
			return
		end
		-- hang it along the ship's length, just under the mast top
		local along = if visual.Size.Z >= visual.Size.X then visual.CFrame.LookVector else visual.CFrame.RightVector
		along = Vector3.new(along.X, 0, along.Z).Unit
		local center = top + Vector3.new(0, -2.2, 0) + along * 3.1
		flag = Instance.new("Part")
		flag.Name = "CosmeticFlag"
		flag.Size = Vector3.new(0.15, 3.6, 6)
		flag.CFrame = CFrame.lookAt(center, center + along)
		flag.Anchored = true
		flag.CanCollide = false
		flag.CanQuery = false
		flag.CanTouch = false
		flag.Material = Enum.Material.Fabric
		flag.Parent = ship
	end
	flag.Color = color
end

local function humanoidOf(player)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

-- Bonuses as server-set player attributes (Attack, OrbitService, LampService, LootService and the panels read
-- them): the island merchant's voyage boosts (S6.2) plus the Quartermaster's permanent boosts (S6.4), the Orbit
-- weapon carried (S6.3: the merchant's, else an equipped Orbit weapon), purchase counts and the walk speed.
local function applyBoosts(player)
	local data = PlayerData.data(player)
	local ranks = if data and type(data.Boosts) == "table" then data.Boosts else {}
	local roles = if data and type(data.Roles) == "table" then data.Roles else {} -- S7.4: specialties
	local damage = MerchantService.boost(player, "WeaponDamage") + Boosts.bonus(ranks, "WeaponDamage") + Specialties.bonus(roles, "Harpooner")
	local speed = MerchantService.boost(player, "PlayerSpeed") + Boosts.bonus(ranks, "PlayerSpeed") + Specialties.bonus(roles, "Oiler")
	local keeper, engineer = Specialties.bonus(roles, "Keeper"), Specialties.bonus(roles, "Engineer")
	player:SetAttribute("Spec_Keeper", if keeper > 0 then keeper else nil) -- CreatureService: beam damage while keeping
	player:SetAttribute("Spec_Engineer", if engineer > 0 then engineer else nil) -- TowerService: repair amount
	local shells = StatPipeline.compute("ShellGainPct", 0, { flat = { Boosts.bonus(ranks, "ShellGainPct") } })
	player:SetAttribute("Boost_WeaponDamage", if damage > 0 then damage else nil)
	player:SetAttribute("Boost_PlayerSpeed", if speed > 0 then speed else nil)
	player:SetAttribute("Boost_ShellGainPct", if shells > 0 then shells else nil)
	local orbit = nil -- S6.3: the voyage-only Orbit weapon this player carries (OrbitService, OrbitView)
	for _, id in Merchant.ORDER do
		local n = MerchantService.count(player, id)
		player:SetAttribute("Merchant_" .. id, if n > 0 then n else nil)
		if n > 0 and Merchant[id].effect == "weapon" then
			orbit = Merchant[id].weapon
		end
	end
	local equipped = data and data.Equipped.Weapon
	if orbit == nil and equipped and Weapons[equipped] and Weapons[equipped].archetype == "Orbit" then
		orbit = equipped -- S6.4: an equipped permanent Orbit weapon
	end
	player:SetAttribute("OrbitWeapon", orbit)
	local humanoid = humanoidOf(player)
	if humanoid and LampService.getKeeper() ~= player then
		humanoid.WalkSpeed = StatPipeline.compute("PlayerSpeed", StarterPlayer.CharacterWalkSpeed, { add = { speed } })
	end
end

-- Makes the player's tools and armor match their saved loadout.
-- Runs on spawn and whenever their profile changes (buying, equipping).
local function syncGear(player)
	-- Beam colour cosmetics (launch R15): the lamp reads this attribute when the player takes it (S5.3: was a
	-- LampService.colorFor callback)
	local profile = PlayerData.get(player)
	local beam = profile and Items[profile.equippedBeam]
	player:SetAttribute("BeamColor", if beam and beam.beamColor then Color3.fromRGB(beam.beamColor[1], beam.beamColor[2], beam.beamColor[3]) else nil)
	-- L1.3: the other cosmetics as colours the lamp, the ship and the character read
	for _, slot in COSMETIC_SLOTS do
		local cosmetic = profile and Items[profile["equipped" .. slot]]
		player:SetAttribute(slot .. "Color", if cosmetic and cosmetic.color then Color3.fromRGB(cosmetic.color[1], cosmetic.color[2], cosmetic.color[3]) else nil)
	end
	refreshShipFlag()
	-- PET.1 (D-051): the pet out with this player (its equipped pet, else a new player's loaner); LootService fetches
	-- Shells for it and Client/PetView draws it
	if profile then
		local ownsPet, firstPet = false, nil
		for itemId in profile.owned or {} do
			if Items[itemId] and Items[itemId].kind == "Pet" then
				ownsPet = true
				firstPet = firstPet or itemId
			end
		end
		-- a pet just bought (Pearls or Robux) comes out at once when no pet is out, so a borrowed one is not lost
		local equipped = profile.equippedPet
		if ownsPet and petOwned[player] == false and equipped == nil and firstPet then
			equipped = firstPet
			task.defer(PlayerData.setEquipped, player, "Pet", firstPet)
		end
		petOwned[player] = ownsPet
		local runs = profile.stats and profile.stats.runs or 0
		local pet, loan = PetRules.active(equipped, ownsPet, runs, Config.PET_LOAN_VOYAGES, function(id)
			return Items[id] ~= nil and Items[id].kind == "Pet"
		end)
		player:SetAttribute("Pet", pet)
		player:SetAttribute("PetLoan", if loan then true else nil)
		if PetRules.loanJustEnded(ownsPet, runs, Config.PET_LOAN_VOYAGES) and not petNoteSent[player] then
			petNoteSent[player] = true
			LampService.notify(player, "Your borrowed puffin flew home. Puffin Pal is at the Quartermaster.")
		end
	end

	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	local wanted = {}
	for _, weaponId in weaponsFor(player) do
		wanted[weaponId] = true
	end
	-- Remove tools for weapons no longer equipped, and note which ones we already have
	local have = {}
	local equippedTool = character and character:FindFirstChildOfClass("Tool")
	local wasHolding = equippedTool ~= nil
	for _, container in { backpack, character } do
		if container then
			for _, tool in container:GetChildren() do
				local id = tool:IsA("Tool") and tool:GetAttribute("WeaponId")
				if id then
					if wanted[id] then
						have[id] = true
					else
						tool:Destroy()
					end
				end
			end
		end
	end
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	for weaponId in wanted do
		if not have[weaponId] then
			local tool = buildWeaponTool(weaponId)
			tool.Parent = backpack
			-- if they were holding the old weapon, hand them the new one
			if wasHolding and humanoid and LampService.getKeeper() ~= player then
				humanoid:EquipTool(tool)
			end
		end
	end

	-- Armor: max health + damage reduction, and the visible model on the character
	local armorItem = profile and Items[profile.equippedArmor]
	if humanoid and armorItem then
		local armor = StatPipeline.armor(profile.equippedArmor) -- S5.7: the numbers the shop shows
		local ratio = if humanoid.MaxHealth > 0 then humanoid.Health / humanoid.MaxHealth else 1
		humanoid.MaxHealth = armor.maxHealth
		humanoid.Health = math.max(1, armor.maxHealth * ratio)
		player:SetAttribute("DamageReduction", armor.damageReduction)
		player:SetAttribute("ArmorName", armorItem.name)
		if character:GetAttribute("WornArmorId") ~= profile.equippedArmor then
			character:SetAttribute("WornArmorId", profile.equippedArmor)
			wearArmor(character, profile.equippedArmor)
			character:SetAttribute("WornCoat", nil) -- L1.3: the new armor takes the coat's colour again
		end
	end
	if character then
		dressCosmetics(character, player) -- L1.3
	end
	applyBoosts(player) -- S6.4: permanent boosts and an equipped Orbit weapon follow the profile
end

local function giveWeapons(player, character)
	local backpack = player:WaitForChild("Backpack", 5)
	if not backpack then
		return
	end
	character:WaitForChild("Humanoid", 5)
	syncGear(player)
	-- Equip the first weapon automatically so new players can fight right away
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local first = backpack:FindFirstChildOfClass("Tool")
	if humanoid and first and LampService.getKeeper() ~= player then
		humanoid:EquipTool(first)
	end
end

local function hookWeapons(player)
	player.CharacterAdded:Connect(function(character)
		giveWeapons(player, character)
	end)
	if player.Character then
		task.spawn(giveWeapons, player, player.Character)
	end
end

---------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------

function Economy.Init(ctx)
	local remotes = ctx.remotes

	-- Dawn Pearl banking (S2.2): NightSurvived -> GrantService for each crew member, saved at once; the client
	-- hears "+1 Pearl banked" through LootCollected("PearlBanked", amount).
	DawnBanking.start(EventLog, {
		config = Config,
		grant = function(userId, claimId, rewards)
			local player = Players:GetPlayerByUserId(userId)
			if not player then
				return "invalid"
			end
			return (GrantService.Grant(player, claimId, rewards, "dawn"))
		end,
		notify = function(userId, amount)
			local player = Players:GetPlayerByUserId(userId)
			if player then
				remotes.LootCollected:FireClient(player, "PearlBanked", amount)
			end
		end,
	})

	LoadoutService.init(remotes, PlayerData)
	-- L1.3: Robux purchases of cosmetics (the game's only ProcessReceipt; nothing is granted while
	-- Definitions/Cosmetics.ROBUX_ENABLED is off)
	local purchaseDeps = {
		playerByUserId = function(userId)
			return Players:GetPlayerByUserId(userId)
		end,
		loaded = function(player)
			return PlayerData.data(player) ~= nil
		end,
		grant = function(player, claimId, rewards, source)
			return (GrantService.Grant(player, claimId, rewards, source))
		end,
		log = EventLog.log,
		notify = LampService.notify,
		nameOf = function(itemId)
			return if Items[itemId] then Items[itemId].name else itemId
		end,
	}
	MarketplaceService.ProcessReceipt = function(receipt)
		local ok, result = pcall(PurchaseService.process, receipt, purchaseDeps)
		if ok and result == "granted" then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	Players.PlayerRemoving:Connect(function()
		task.defer(refreshShipFlag) -- L1.3: the flag passes to the next keeper who has one
	end)
	-- S5.3: tools, armor and beam colour follow the profile (was PlayerData.onChanged)
	EventLog.Subscribe("ProfileChanged", function(e)
		local player = Players:GetPlayerByUserId(e.UserId)
		if player then
			syncGear(player)
		end
	end)

	-- The Trader (lighthouse island): sells all of a player's loot for crew shells.
	-- Returns ok, message, shells paid.
	local function sellAllLoot(player)
		local profile = PlayerData.get(player)
		if not profile then
			return false, "Your data is still loading. Try again in a moment.", 0
		end
		-- Work out the value first, then clear (clearRunLoot removes exactly the run-scoped loot)
		local removed = PlayerData.clearRunLoot(player)
		if #removed == 0 then
			return false, "Nothing to sell. Bring claws, sea glass or pearls from the creatures.", 0
		end
		local total, parts = 0, {}
		for _, entry in removed do
			local item = Items[entry[1]]
			total += (item.shellValue or 0) * entry[2]
			table.insert(parts, string.format("%d %s", entry[2], item.name))
		end
		UpgradeService.addShells(total, "trader")
		SoundFx.playAt("build", ctx.refs.traderPrompt.Parent.Position)
		VoyageCast.fire(remotes.Notify, string.format("%s sold %s to the Trader for %d shells!", player.DisplayName, table.concat(parts, ", "), total)) -- island Trader: crew only
		EventLog.log("SoldLoot", { player = player.Name, shells = total })
		EventLog.count("lootSold", total) -- for the results screen
		return true, string.format("Sold for %d Shells.", total), total
	end
	ctx.sellAllLoot = sellAllLoot

	-- launch R10 (owner: keep OFF until Test B): with Config.AUTO_SELL_LOOT, each crew member's carried
	-- loot sells itself at dawn at the same Trader values, 2 s after the dawn loot window closes (S5.3: hears
	-- DawnLootWindow on the bus; GameState used to call it).
	EventLog.Subscribe("DawnLootWindow", function(e)
		if not (Config.AUTO_SELL_LOOT and Config.ECONOMY_ENABLED) then
			return
		end
		task.delay(e.Seconds + 2, function()
			for _, player in Players:GetPlayers() do
				if player:GetAttribute("Ready") then
					sellAllLoot(player)
				end
			end
		end)
	end)
end

function Economy.Start(ctx)
	local remotes, refs, state = ctx.remotes, ctx.refs, ctx.state
	ShopService.init(remotes, PlayerData, refs.shopCounter, refs.shopPrompt)
	-- CHEST.1 (D-053): a Kraken Chest for beating the Kraken, opened from the BAG
	ChestService.init(remotes, {
		grant = function(player, claimId, rewards, source)
			return (GrantService.Grant(player, claimId, rewards, source))
		end,
		owns = PlayerData.owns,
		count = PlayerData.count,
		removeItem = PlayerData.removeItem,
		addItem = PlayerData.addItem,
		now = os.time,
		random = math.random,
	}, LampService.notify, EventLog.log)

	Players.PlayerAdded:Connect(hookWeapons)
	for _, player in Players:GetPlayers() do
		hookWeapons(player)
	end

	-- The Trader's prompt opens its panel (client); selling is a request the server checks.
	local TRADER_RANGE = refs.traderPrompt.MaxActivationDistance + 6
	local traderHandled = {} -- player -> { id, ok, message, total } (a repeated request gets the same answer)
	local lastTrade = {}

	refs.traderPrompt.Triggered:Connect(function(player)
		if not player:GetAttribute("Ready") then
			return
		end
		PlayerData.resync(player) -- fresh loot counts for the panel
		remotes.TraderOpen:FireClient(player)
	end)

	NetGuard.connect(remotes.TraderRequest, function(player, requestId, action)
		if typeof(requestId) ~= "string" or #requestId == 0 or #requestId > 40 or action ~= "sellAll" then
			return
		end
		local memory = traderHandled[player]
		if memory and memory.id == requestId then
			remotes.TraderResult:FireClient(player, requestId, memory.ok, memory.message, memory.total)
			return
		end
		if not NetGuard.allow(player, "TraderRequest") then
			return
		end
		local now = os.clock()
		if (lastTrade[player] or 0) + 0.3 > now then
			remotes.TraderResult:FireClient(player, requestId, false, "One trade at a time. Try again.", 0)
			return
		end
		lastTrade[player] = now
		local ok, message, total
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not player:GetAttribute("Ready") then
			ok, message, total = false, "The Trader only buys from the crew during a voyage.", 0
		elseif not root or (root.Position - refs.traderPrompt.Parent.Position).Magnitude > TRADER_RANGE then
			ok, message, total = false, "You're too far from the Trader.", 0
		else
			ok, message, total = ctx.sellAllLoot(player)
		end
		traderHandled[player] = { id = requestId, ok = ok, message = message, total = total }
		if not ok then
			PlayerData.resync(player)
		end
		remotes.TraderResult:FireClient(player, requestId, ok, message, total)
	end)

	-- S6.2: the island merchant (the Trader's day job): voyage-only stock for the crew's Shells
	-- (applyBoosts, above, turns its purchases into player attributes)
	MerchantService.init({
		getShells = UpgradeService.getShells,
		trySpend = UpgradeService.trySpend,
		fuel = function()
			return LampService.getFuel(), LampService.getMaxFuel()
		end,
		addFuel = LampService.addFuel,
		health = function(player)
			local humanoid = humanoidOf(player)
			if humanoid and humanoid.Health > 0 then
				return humanoid.Health, humanoid.MaxHealth
			end
			return nil, nil
		end,
		heal = function(player)
			local humanoid = humanoidOf(player)
			if humanoid then
				humanoid.Health = humanoid.MaxHealth
			end
		end,
		applyBoosts = applyBoosts,
		setShield = function(on)
			state:SetAttribute("TowerShield", on)
		end,
		purchased = function(player, itemId, price)
			local def = Merchant[itemId]
			applyBoosts(player)
			EventLog.Publish("ShellsChanged", { VoyageId = EventLog.voyageId(), Delta = -price, Reason = "merchant" })
			EventLog.Publish("MerchantPurchase", { VoyageId = EventLog.voyageId(), UserId = player.UserId, ItemId = itemId, Price = price, Currency = "Shells" })
			EventLog.log("MerchantPurchase", { player = player.Name, item = itemId, price = price })
			EventLog.count("merchantShells", price)
			SoundFx.playAt("build", refs.traderPrompt.Parent.Position)
			if def.scope == "crew" then
				VoyageCast.fire(remotes.Notify, string.format("%s bought a %s for the crew: %s.", player.DisplayName, def.displayName, string.lower(def.description))) -- island merchant: crew only
			else
				LampService.notify(player, string.format("%s: %s.", def.displayName, def.description))
			end
		end,
	})
	-- wiped when a voyage starts and at Results; the shield drops at dawn
	EventLog.Subscribe("VoyageStarted", function()
		MerchantService.reset()
	end)
	EventLog.Subscribe("VoyageEnded", function()
		MerchantService.reset()
	end)
	EventLog.Subscribe("NightSurvived", function()
		MerchantService.endNight()
	end)
	local function hookBoosts(player)
		player.CharacterAdded:Connect(function()
			task.defer(applyBoosts, player) -- a new character walks at the boosted speed
		end)
	end
	Players.PlayerAdded:Connect(hookBoosts)
	for _, player in Players:GetPlayers() do
		hookBoosts(player)
	end

	NetGuard.connect(remotes.MerchantRequest, function(player, requestId, action, itemId, qty)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local result = MerchantService.process(player, requestId, action, itemId, qty, {
			phase = state:GetAttribute("Phase"),
			ready = player:GetAttribute("Ready") == true,
			distance = if root and root:IsA("BasePart") then (root.Position - refs.traderPrompt.Parent.Position).Magnitude else math.huge,
		})
		if result then
			remotes.MerchantResult:FireClient(player, requestId, result.ok, result.message, result.state)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		traderHandled[player] = nil
		lastTrade[player] = nil
		petNoteSent[player] = nil -- PET.1
		petOwned[player] = nil
		MerchantService.forget(player)
	end)
end

return Economy
