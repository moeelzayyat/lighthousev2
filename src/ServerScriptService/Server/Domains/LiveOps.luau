-- LiveOps domain (S5.1): the logbook (S7.1); later the daily objective, leaderboards and remote-config driven
-- content. It reacts to the voyage through the event bus only.

local Players = game:GetService("Players")

local Server = script.Parent.Parent
local EventLog = require(Server.EventLog)
local PlayerData = require(Server.PlayerData)
local GrantService = require(Server.GrantService)
local LampService = require(Server.LampService)
local LogbookService = require(Server.LogbookService) -- S7.1
local ObjectiveService = require(Server.ObjectiveService) -- S7.2

local LiveOps = { Name = "LiveOps" }

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
end

return LiveOps
