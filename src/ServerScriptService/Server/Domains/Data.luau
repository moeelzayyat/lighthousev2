-- Data domain (S5.1/S5.2): player profiles (ProfileStore) and the owner-only admin tools.

local Players = game:GetService("Players")

local Server = script.Parent.Parent
local EventLog = require(Server.EventLog)
local PlayerData = require(Server.PlayerData)
local GrantService = require(Server.GrantService) -- R1.3: the only writer of Pearl income
local AdminDataService = require(Server.AdminDataService) -- R1.8: inspect / grant / rollback
local NetGuard = require(Server.NetGuard)

local Data = { Name = "Data" }

function Data.Init(ctx)
	local remotes = ctx.remotes
	-- R1.8 admin tools: snapshots on every profile load (Studio keeps them in memory, never in a real store)
	AdminDataService.init({
		playerData = PlayerData,
		grant = GrantService,
		store = if game:GetService("RunService"):IsStudio()
			then AdminDataService.memoryStore()
			else game:GetService("DataStoreService"):GetDataStore(AdminDataService.SNAPSHOT_STORE),
		findPlayer = function(userId)
			return Players:GetPlayerByUserId(userId)
		end,
		now = os.time,
		log = EventLog.log,
		newId = function()
			return game:GetService("HttpService"):GenerateGUID(false)
		end,
	})
	EventLog.Subscribe("ProfileLoaded", function(e)
		AdminDataService.onProfileLoaded(e.UserId)
	end)
	PlayerData.init(remotes, ctx.notify)

	-- Admin channel (R1.8): owner only; everyone else is refused and logged by AdminDataService
	remotes.AdminRequest.OnServerEvent:Connect(function(player, requestId, action, targetUserId, arg)
		if not NetGuard.isRequestId(requestId) or not NetGuard.allow(player, "AdminRequest") then
			return
		end
		if type(action) ~= "string" or #action > 20 or not NetGuard.isFiniteNumber(targetUserId) then
			return
		end
		if arg ~= nil and not NetGuard.isFiniteNumber(arg) and (type(arg) ~= "string" or #arg > 20) then
			return
		end
		local ok, result = AdminDataService.handle(player.UserId, action, targetUserId, arg)
		remotes.AdminResult:FireClient(player, requestId, ok, if type(result) == "table" then result else tostring(result))
	end)
end

return Data
