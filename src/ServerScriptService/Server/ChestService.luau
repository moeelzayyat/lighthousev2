--!strict
-- ChestService (CHEST.1, D-053, Economy domain): Kraken Chests. Rules in Shared/Definitions/Chests.
--   earn: when the Kraken (Config.FINAL_BOSS) is beaten, each crew member gets a chest through GrantService with the
--         claim "chest:<chestId>:<UTC day>", so a second Kraken the same day gives nothing more (no timer shown).
--   open: ChestRequest(requestId, chestId) from the BAG. The server rolls, takes one chest and grants the find
--         through GrantService (claim "chestopen:<UserId>:<requestId>"); a duplicate request replays its answer.
-- Pure functions take their deps, so specs run them without remotes or saves.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Chests = require(Shared:WaitForChild("Definitions"):WaitForChild("Chests")) :: any
local Items = require(Shared:WaitForChild("Items")) :: any
local Config = require(Shared:WaitForChild("Config")) :: any

local ChestService = {}

export type Deps = {
	grant: (player: any, claimId: string, rewards: any, source: string) -> string,
	owns: (player: any, itemId: string) -> boolean,
	count: (player: any, itemId: string) -> number,
	removeItem: (player: any, itemId: string, n: number) -> boolean,
	addItem: (player: any, itemId: string, n: number) -> (),
	now: () -> number,
	random: () -> number,
}

ChestService.SHOW_OFF_TIERS = { Epic = true, Legendary = true } :: { [string]: boolean }

-- "granted" (a chest is in the BAG), "duplicate" (today's chest was already earned), "full" or "invalid"
function ChestService.earn(player: any, chestId: string, deps: Deps): string
	local chest = Chests[chestId]
	if type(chest) ~= "table" or not table.find(Chests.ORDER, chestId) then
		return "invalid"
	end
	if deps.count(player, chestId) >= chest.maxHeld then
		return "full"
	end
	return deps.grant(player, "chest:" .. chestId .. ":" .. Chests.dayKey(deps.now()), { Items = { [chestId] = 1 } }, "chest")
end

export type Find = { chest: string, item: string?, name: string, tier: string, pearls: number, duplicate: boolean }

-- Opens one chest: (true, find) or (false, message for the player)
function ChestService.open(player: any, chestId: string, requestId: string, deps: Deps): (boolean, any)
	local chest = Chests[chestId]
	if type(chest) ~= "table" or not table.find(Chests.ORDER, chestId) then
		return false, "That isn't a chest."
	end
	if deps.count(player, chestId) < 1 then
		return false, "You have no " .. chest.name .. " to open. Beat the Kraken to earn one."
	end
	local row = Chests.roll(chest, deps.random())
	local find: Find = { chest = chestId, item = row.item, name = "", tier = row.tier, pearls = 0, duplicate = false }
	local rewards: any
	if row.item == nil then
		find.pearls = row.pearls or 0
		find.name = find.pearls .. " Pearls"
		rewards = { Pearls = find.pearls }
	elseif deps.owns(player, row.item) then
		find.duplicate = true
		find.pearls = row.dupPearls or 0
		find.name = Items[row.item].name
		rewards = { Pearls = find.pearls }
	else
		find.name = Items[row.item].name
		rewards = { Items = { [row.item] = 1 } }
	end
	if not deps.removeItem(player, chestId, 1) then
		return false, "You have no " .. chest.name .. " to open."
	end
	local status = deps.grant(player, "chestopen:" .. tostring(player.UserId) .. ":" .. requestId, rewards, "chest")
	if status ~= "granted" then
		deps.addItem(player, chestId, 1) -- nothing was given: the chest goes back
		return false, "The chest is stuck. Your chest is safe; try again in a moment."
	end
	return true, find
end

-- The server-wide line for a rare find (nil for ordinary ones)
function ChestService.announcement(displayName: string, find: Find): string?
	if find.duplicate or not ChestService.SHOW_OFF_TIERS[find.tier] then
		return nil
	end
	local chestName = Chests[find.chest] and Chests[find.chest].name or "chest"
	return string.format("%s opened a %s and found the %s (%s)!", displayName, chestName, find.name, find.tier)
end

-- Wiring (Economy domain): the Kraken kill, the ChestRequest remote
function ChestService.init(remotes: any, deps: Deps, notify: (player: any, text: string) -> (), log: (name: string, fields: any) -> ())
	local Server = script.Parent
	local EventLog = require(Server:WaitForChild("EventLog")) :: any
	local NetGuard = require(Server:WaitForChild("NetGuard")) :: any
	local VoyageCast = require(Server:WaitForChild("VoyageCast")) :: any
	local replay = NetGuard.replayMap()

	EventLog.Subscribe("BossDefeated", function(e)
		if e.DefId ~= Config.FINAL_BOSS then
			return
		end
		for _, player in VoyageCast.crew() do
			local status = ChestService.earn(player, "KrakenChest", deps)
			log("ChestEarned", { player = player.Name, status = status })
			if status == "granted" then
				notify(player, "You beat the Kraken! A Kraken Chest is in your BAG.")
			elseif status == "duplicate" then
				notify(player, "You already earned today's Kraken Chest. Beat the Kraken on another day for the next one.")
			elseif status == "full" then
				notify(player, "Your BAG holds 5 Kraken Chests already. Open one to make room.")
			end
		end
	end)

	NetGuard.connect(remotes.ChestRequest, function(player, requestId, chestId)
		if not NetGuard.isRequestId(requestId) or type(chestId) ~= "string" or #chestId > 40 then
			return
		end
		local previous = replay.get(player, requestId)
		if previous then
			remotes.ChestResult:FireClient(player, requestId, previous[1], previous[2])
			return
		end
		if not NetGuard.allow(player, "ChestRequest") then
			return
		end
		local ok, result = ChestService.open(player, chestId, requestId, deps)
		replay.put(player, requestId, { ok, result })
		remotes.ChestResult:FireClient(player, requestId, ok, result)
		if ok then
			log("ChestOpened", { player = player.Name, chest = chestId, find = result.item or "Pearls", tier = result.tier, duplicate = result.duplicate })
			local line = ChestService.announcement(player.DisplayName, result)
			if line then
				for _, other in Players:GetPlayers() do
					notify(other, line)
				end
			end
		end
	end)
end

return ChestService
