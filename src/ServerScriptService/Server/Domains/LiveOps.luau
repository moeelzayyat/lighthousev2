-- LiveOps domain (S5.1): the logbook (S7.1); later the daily objective, leaderboards and remote-config driven
-- content. It reacts to the voyage through the event bus only.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

local Server = script.Parent.Parent
local EventLog = require(Server.EventLog)
local PlayerData = require(Server.PlayerData)
local GrantService = require(Server.GrantService)
local LampService = require(Server.LampService)
local LogbookService = require(Server.LogbookService) -- S7.1
local ObjectiveService = require(Server.ObjectiveService) -- S7.2
local LeaderboardService = require(Server.LeaderboardService) -- S7.3

local LiveOps = { Name = "LiveOps" }

-- S7.3: a board's ordered data store. Studio always uses an in-memory one (a play test never writes a board).
local stores = {}
local function storeFor(name)
	if stores[name] then
		return stores[name]
	end
	local store
	if RunService:IsStudio() then
		local scores = {}
		store = {
			raise = function(key, value)
				scores[key] = math.max(scores[key] or 0, value)
			end,
			add = function(key, delta)
				scores[key] = (scores[key] or 0) + delta
			end,
			top = function(n)
				local rows = {}
				for key, value in scores do
					table.insert(rows, { key = key, value = value })
				end
				table.sort(rows, function(a, b)
					return a.value > b.value
				end)
				return { table.unpack(rows, 1, math.min(n, #rows)) }
			end,
		}
	else
		local ds = DataStoreService:GetOrderedDataStore(name)
		store = {
			raise = function(key, value)
				pcall(function()
					ds:UpdateAsync(key, function(old)
						if old and old >= value then
							return nil
						end
						return value
					end)
				end)
			end,
			add = function(key, delta)
				pcall(function()
					ds:IncrementAsync(key, delta)
				end)
			end,
			top = function(n)
				local rows = {}
				pcall(function()
					for _, entry in ds:GetSortedAsync(false, n):GetCurrentPage() do
						table.insert(rows, { key = entry.key, value = entry.value })
					end
				end)
				return rows
			end,
		}
	end
	stores[name] = store
	return store
end

local names = {}
local function nameOf(userId)
	if names[userId] then
		return names[userId]
	end
	local player = Players:GetPlayerByUserId(userId)
	local name = if player then player.DisplayName else nil
	if not name then
		local ok, result = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		name = if ok then result else "Keeper"
	end
	names[userId] = name
	return name
end

function LiveOps.Init(ctx)
	local state = ctx.state
	-- S7.1: the logbook hears kills, bosses, evolutions and survived nights on the bus
	LogbookService.start({
		subscribe = EventLog.Subscribe,
		publish = EventLog.Publish,
		crew = function()
			local list = {}
			for _, player in Players:GetPlayers() do
				if player:GetAttribute("Ready") then
					table.insert(list, player)
				end
			end
			return list
		end,
		byUserIds = function(ids)
			local list = {}
			for _, id in ids do
				local player = Players:GetPlayerByUserId(id)
				if player then
					table.insert(list, player)
				end
			end
			return list
		end,
		mutate = function(player, fn)
			return PlayerData.mutate(player, fn)
		end,
		grant = GrantService.Grant,
		notify = LampService.notify,
		forecast = function()
			return state:GetAttribute("Forecast")
		end,
	})
	-- S7.2: the daily objective counts the player's own events and pays once a day; no streaks
	ObjectiveService.start({
		subscribe = EventLog.Subscribe,
		publish = EventLog.Publish,
		byUserIds = function(ids)
			local list = {}
			for _, id in ids do
				local player = Players:GetPlayerByUserId(id)
				if player then
					table.insert(list, player)
				end
			end
			return list
		end,
		data = PlayerData.data,
		mutate = function(player, fn)
			return PlayerData.mutate(player, fn)
		end,
		grant = GrantService.Grant,
		notify = LampService.notify,
		now = os.time,
	})
	-- S7.3: the harbor boards (best night per voyage, nights this week), written and re-read every 30 s
	local board = ctx.lobbyRefs and ctx.lobbyRefs.leaderboard
	LeaderboardService.start({
		subscribe = EventLog.Subscribe,
		storeFor = storeFor,
		voyage = function()
			return state:GetAttribute("VoyageDef")
		end,
		now = os.time,
		nameOf = nameOf,
		show = function(boardId, title, rows)
			local column = board and board:FindFirstChild("Boards") and board.Boards:FindFirstChild(boardId)
			if not column then
				return
			end
			column.Title.Text = title
			for i = 1, 10 do
				column["Row" .. i].Text = rows[i] or (if i == 1 and #rows == 0 then "No one yet. Be the first!" else "")
			end
		end,
		every = function(seconds, fn)
			task.spawn(function()
				while true do
					task.wait(seconds)
					fn()
				end
			end)
		end,
	})
end

return LiveOps
