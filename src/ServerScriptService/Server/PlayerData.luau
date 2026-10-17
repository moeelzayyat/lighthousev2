--!strict
-- PlayerData (R1.3, Data domain): each player's saved profile on ProfileStore.
--
-- Store: LighthouseKeepers_PlayerData_v2, key player_<UserId>, schema v2 (ProfileSchema). D-012: fresh start,
-- nothing is imported from v1 and the v1 store is never read or written by this module.
-- ProfileStore gives the session lock, autosave, retries and BindToClose. In Studio the mock store is ALWAYS
-- used, so a Studio play test can never touch a real save.
--
-- Callers still read a v1-shaped view (pearls, owned, counts, equipped*, stats) through PlayerData.get and the
-- GearData push; it is rebuilt from the v2 data on every call (S5 moves callers to the v2 names).
-- Pearl income goes through GrantService (PlayerData.mutate); this module has no addPearls.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Items = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Items")) :: any
local EventLog = require(script.Parent.EventLog) :: any
local NetGuard = require(script.Parent.NetGuard)
local MigrationService = require(script.Parent.MigrationService)
local ProfileSchema = require(script.Parent.ProfileSchema)
local ModeTest = require(script.Parent.ModeTest) -- S3.1b
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local PlayerData = {}

PlayerData.STORE_NAME = "LighthouseKeepers_PlayerData_v2"

local profiles: { [Player]: any } = {} -- player -> ProfileStore profile (Data is the schema-v2 table)
local remotes: any = nil
local mode = "memory" -- "saved" (live store) or "memory" (Studio mock)

-- Called whenever a profile changes (Main uses this to refresh tools and armor)
PlayerData.onChanged = nil :: ((Player) -> ())?

local function keyFor(userId: number): string
	return "player_" .. userId
end

-- The v1-shaped read view the existing callers and client screens use
local function view(data: any): any
	return {
		version = data.SchemaVersion,
		pearls = data.Pearls,
		owned = data.Owned,
		counts = data.Counts,
		equippedArmor = data.Equipped.Armor,
		equippedWeapon = data.Equipped.Weapon,
		equippedBeam = data.Equipped.Beam,
		stats = { runs = data.Stats.Runs, victories = data.Stats.Victories, bestNight = data.Stats.BestNight },
	}
end

local function dataOf(player: Player): any
	local profile = profiles[player]
	return profile and profile.Data
end

local function push(player: Player)
	local data = dataOf(player)
	if data and remotes then
		remotes.GearData:FireClient(player, HttpService:JSONDecode(HttpService:JSONEncode(view(data))), mode == "saved")
	end
	local onChanged = PlayerData.onChanged
	if onChanged then
		onChanged(player)
	end
end

local function changed(player: Player, saveNow: boolean?)
	if saveNow then
		local profile = profiles[player]
		if profile and profile:IsActive() then
			profile:Save()
		end
	end
	push(player)
end

local function load(store: any, player: Player)
	local profile = store:StartSessionAsync(keyFor(player.UserId), {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if profile == nil then
		if player.Parent == Players then
			player:SetAttribute("ProfileState", "failed")
			EventLog.log("ProfileLoadFailed", { player = player.Name })
			player:Kick("Your save could not be opened right now. Please rejoin in a moment.")
		end
		return
	end
	profile:AddUserId(player.UserId)
	profile:Reconcile()
	local data, fixes = MigrationService.upgrade(profile.Data)
	profile.Data = data
	if #fixes > 0 then
		EventLog.log("ProfileFixed", { player = player.Name, fixes = #fixes, first = fixes[1] })
	end
	local now = os.time()
	local isNew = data.CreatedAt == 0
	if isNew then
		data.CreatedAt = now
	end
	if data.LastSeenAt == 0 or math.floor(data.LastSeenAt / 86400) < math.floor(now / 86400) then
		data.Stats.PlayDays += 1
	end
	data.LastSeenAt = now
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		if player.Parent == Players then
			player:Kick("Your save was opened on another server. Please rejoin.")
		end
	end)
	if player.Parent ~= Players then
		profile:EndSession()
		return
	end
	profiles[player] = profile
	-- Read-only signals for the first-voyage route and coach (launch R2/R3)
	player:SetAttribute("RunsCompleted", data.Stats.Runs)
	player:SetAttribute("ProfileState", mode)
	-- unlocks as Unlock_<Key> attributes (S2.1: the crew card offers the Long Voyage to holders)
	for key, value in data.Unlocks do
		if type(value) == "boolean" then
			player:SetAttribute("Unlock_" .. key, value)
		end
	end
	-- S3.1b: the account's arm in the mode test (no attribute = not in the test)
	local arm = ModeTest.armFor(player.UserId, data.CreatedAt, Config)
	player:SetAttribute("ModeArm", arm)
	push(player)
	EventLog.Publish("ProfileLoaded", { UserId = player.UserId, SchemaVersion = data.SchemaVersion, IsNew = isNew, Runs = data.Stats.Runs })
	if arm then
		EventLog.Publish("ModeAssigned", { UserId = player.UserId, Arm = arm })
	end
end

-- Replaces the whole v2 data (admin rollback only). The new data is validated first; saved immediately.
function PlayerData.replaceData(player: Player, newData: any): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	local data = MigrationService.upgrade(newData)
	profile.Data = data
	player:SetAttribute("RunsCompleted", data.Stats.Runs)
	changed(player, true)
	return true
end

---------------------------------------------------------------------
-- Public API (server only)
---------------------------------------------------------------------

-- A read-only v1-shaped view of the profile, or nil while loading
function PlayerData.get(player: Player): any
	local data = dataOf(player)
	return data and view(data)
end

-- The schema-v2 data (read only; write through mutate)
function PlayerData.data(player: Player): any
	return dataOf(player)
end

-- Runs fn(data) on the player's v2 data; if fn returns true the change is pushed (and saved now when saveNow).
-- Returns false when the profile is not loaded. GrantService is the only caller that changes Pearls this way.
function PlayerData.mutate(player: Player, fn: (any) -> boolean, saveNow: boolean?): boolean
	local data = dataOf(player)
	if not data then
		return false
	end
	if fn(data) then
		changed(player, saveNow)
	end
	return true
end

function PlayerData.owns(player: Player, itemId: string): boolean
	local data = dataOf(player)
	return data ~= nil and data.Owned[itemId] == true
end

function PlayerData.count(player: Player, itemId: string): number
	local data = dataOf(player)
	return if data then (data.Counts[itemId] or 0) else 0
end

-- Purchases and voyage loot (not rewards: rewards go through GrantService)
function PlayerData.addItem(player: Player, itemId: string, amount: number?)
	local data = dataOf(player)
	local item = Items[itemId]
	if not data or type(item) ~= "table" then
		return
	end
	if item.kind == "Weapon" or item.kind == "Armor" or item.kind == "Cosmetic" then
		data.Owned[itemId] = true
	else
		data.Counts[itemId] = (data.Counts[itemId] or 0) + (amount or 1)
	end
	changed(player)
end

-- Removes `amount` of a counted item. Returns true if the player had enough.
function PlayerData.removeItem(player: Player, itemId: string, amount: number?): boolean
	local data = dataOf(player)
	local n = amount or 1
	if not data or (data.Counts[itemId] or 0) < n then
		return false
	end
	data.Counts[itemId] -= n
	if data.Counts[itemId] <= 0 then
		data.Counts[itemId] = nil
	end
	changed(player)
	return true
end

function PlayerData.recordRun(player: Player, won: boolean, nightReached: number, voyage: string?)
	local data = dataOf(player)
	if not data then
		return
	end
	data.Stats.Runs += 1
	if won then
		data.Stats.Victories += 1
	end
	-- best night per voyage (S3.1b): Long has its own field; Endless Storm has no stored best yet (D-017)
	if voyage == "Long" then
		data.Stats.BestNightLong = math.max(data.Stats.BestNightLong, nightReached)
	elseif voyage ~= "Endless" then
		data.Stats.BestNight = math.max(data.Stats.BestNight, nightReached)
	end
	data.Stats.NightsSurvived += math.max(0, if won then nightReached else nightReached - 1)
	player:SetAttribute("RunsCompleted", data.Stats.Runs)
	changed(player, true)
end

-- Grants a boolean unlock (S2.1: "LongVoyage" after a Standard win). Saved now; mirrored as Unlock_<key>.
function PlayerData.unlock(player: Player, key: string): boolean
	local data = dataOf(player)
	if not data or type(data.Unlocks[key]) ~= "boolean" then
		return false
	end
	if not data.Unlocks[key] then
		data.Unlocks[key] = true
		player:SetAttribute("Unlock_" .. key, true)
		EventLog.log("Unlocked", { player = player.Name, key = key })
		changed(player, true)
	end
	return true
end

-- Spends Pearls if the player has enough. Returns true if spent. itemId (optional) names what was bought.
function PlayerData.spendPearls(player: Player, amount: number, itemId: string?): boolean
	local data = dataOf(player)
	if not data or amount < 0 or amount % 1 ~= 0 or data.Pearls < amount then
		return false
	end
	data.Pearls -= amount
	EventLog.Publish("PearlsSpent", { UserId = player.UserId, Amount = amount, Balance = data.Pearls, ItemId = itemId })
	changed(player, true)
	return true
end

-- slot is "Primary", "Armor" or "Beam"
function PlayerData.setEquipped(player: Player, slot: string, itemId: string)
	local data = dataOf(player)
	if not data then
		return
	end
	if slot == "Primary" then
		data.Equipped.Weapon = itemId
	elseif slot == "Armor" then
		data.Equipped.Armor = itemId
	elseif slot == "Beam" then
		data.Equipped.Beam = itemId
	end
	changed(player)
end

-- Re-sends the profile to the client (after a rejected request, so its display is correct)
function PlayerData.resync(player: Player)
	push(player)
end

-- Loot (claws, sea glass, black pearls) only lasts one voyage, like shells.
-- Returns a list of { itemId, count } that was removed (empty if none).
function PlayerData.clearRunLoot(player: Player): { { any } }
	local data = dataOf(player)
	local removed = {}
	if not data then
		return removed
	end
	for itemId, count in data.Counts do
		local item = Items[itemId]
		if type(item) == "table" and item.runScoped and count > 0 then
			table.insert(removed, { itemId, count })
			data.Counts[itemId] = nil
		end
	end
	if #removed > 0 then
		changed(player)
	end
	return removed
end

-- "saved" or "memory"
function PlayerData.mode(): string
	return mode
end

---------------------------------------------------------------------
-- Setup
---------------------------------------------------------------------

export type InitOptions = { store: any?, mode: string? }

-- options.store / options.mode are for tests (a ProfileStore-compatible store and its label).
function PlayerData.init(remoteFolder: any, _notify: any, options: InitOptions?)
	remotes = remoteFolder
	local store = options and options.store
	if store then
		mode = (options :: InitOptions).mode or "memory"
	else
		local ProfileStore = require(script.Parent.ProfileStore) :: any
		local live = ProfileStore.New(PlayerData.STORE_NAME, ProfileSchema.template())
		if RunService:IsStudio() then
			store = live.Mock -- Studio never opens a real save (hard rule 2)
			mode = "memory"
		else
			store = live
			mode = "saved"
		end
	end
	if mode ~= "saved" then
		-- the HUD shows a "progress isn't saving" warning to players
		for _, p in Players:GetPlayers() do
			p:SetAttribute("SaveUnavailable", true)
		end
		Players.PlayerAdded:Connect(function(p)
			p:SetAttribute("SaveUnavailable", true)
		end)
		EventLog.log("ProfileStoreMode", { mode = mode, store = PlayerData.STORE_NAME })
	end

	if remotes then
		remotes.GearAction.OnServerEvent:Connect(function(player, action)
			-- The only client request handled here: "send me my data".
			-- R1.4: contract rate (2/s, burst 4) so a client cannot spam full profile pushes.
			if action == "sync" and NetGuard.allow(player, "GearAction") then
				push(player)
			end
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		load(store, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(load, store, player)
	end
	Players.PlayerRemoving:Connect(PlayerData._unload)
end

-- Ends the player's session: final save with retries (ProfileStore also saves every profile on shutdown)
function PlayerData._unload(player: Player)
	local profile = profiles[player]
	profiles[player] = nil
	if profile then
		profile:EndSession()
	end
end

-- Test hook: load one player against a store
PlayerData._load = load

return PlayerData
