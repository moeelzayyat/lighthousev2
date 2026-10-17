-- Telemetry domain (S5.1/S5.2): analytics consume the bus before any player can join, devices are reported
-- once, and who left during a voyage is logged.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = script.Parent.Parent
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local EventLog = require(Server.EventLog)
local Analytics = require(Server.Analytics) -- R1.6: bus consumer -> Roblox AnalyticsService
local NetGuard = require(Server.NetGuard)

local Telemetry = { Name = "Telemetry" }

function Telemetry.Init(ctx)
	-- Telemetry consumes the bus before any player can join (funnel step 1 is PlayerJoined)
	Analytics.start(EventLog, Analytics.robloxSink(Config.EVENT_LOG_ENABLED))

	-- Each client reports its input type once per session (for the event log)
	local VALID_DEVICES = { Touch = true, Keyboard = true, Gamepad = true }
	local deviceReported = {}
	ctx.remotes.ReportDevice.OnServerEvent:Connect(function(player, device)
		if deviceReported[player] or not NetGuard.allow(player, "ReportDevice") then
			return
		end
		if VALID_DEVICES[device] then
			deviceReported[player] = true
			EventLog.setDevice(player, device)
		end
	end)

	local stateFolder = ctx.state
	Players.PlayerRemoving:Connect(function(player)
		deviceReported[player] = nil
		-- Playtest analytics: someone leaving in the middle of a run
		local phase = stateFolder:GetAttribute("Phase")
		EventLog.playerLeft(player, if not player:GetAttribute("InLobby") then "title" elseif not player:GetAttribute("Ready") then "harbor" else phase)
		if player:GetAttribute("Ready") and (phase == "Prologue" or phase == "Day" or phase == "Night") then
			EventLog.count("quits")
			EventLog.log("PlayerQuit", { player = player.Name, phase = phase, night = stateFolder:GetAttribute("Night") })
		end
	end)
end

return Telemetry
