-- Platform domain (S5.1/S5.2): the shared state folder the HUD reads, and the remotes (built here, exposed to
-- clients last by the Network domain). Feature flags, remote config and server time land here later.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Voyages = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("Voyages"))

local REMOTES = { "BeamControl", "LampAction", "Notify", "Attack", "LootCollected", "OpenUpgrades", "BuyUpgrade", "ReportDevice", "PlaySound", "SetReady", "VoteRematch", "RunResults", "GearData", "GearAction", "ShopOpen", "ShopRequest", "ShopResult", "LoadoutRequest", "LoadoutResult", "EnterLobby", "Travel", "UpgradeResult", "TraderOpen", "TraderRequest", "TraderResult", "CrewFeed", "LampShift", "CoachEvent", "ForecastVote", "AdminRequest", "AdminResult", "ChooseVoyage", "ChooseMap", "SaveSettings", "MerchantRequest", "MerchantResult", "CodeRedeem", "CodeResult", "SniperAction", "ChestRequest", "ChestResult" }

local Platform = { Name = "Platform" }

function Platform.Init(ctx)
	-- Shared state the HUD reads (attributes replicate to every client automatically)
	local stateFolder = Instance.new("Folder")
	stateFolder.Name = "GameState"
	stateFolder:SetAttribute("Phase", "Waiting")
	stateFolder:SetAttribute("Night", 0)
	stateFolder:SetAttribute("TimeLeft", 0)
	stateFolder:SetAttribute("Fuel", Config.MAX_FUEL)
	stateFolder:SetAttribute("DarkSeconds", 0)
	stateFolder:SetAttribute("KeeperUserId", 0)
	stateFolder:SetAttribute("Integrity", Config.MAX_INTEGRITY)
	stateFolder:SetAttribute("BeamMode", "wide")
	stateFolder:SetAttribute("Reason", "")
	stateFolder:SetAttribute("Shells", 0)
	stateFolder:SetAttribute("MaxFuel", Config.MAX_FUEL)
	stateFolder:SetAttribute("MaxIntegrity", Config.MAX_INTEGRITY)
	stateFolder:SetAttribute("VoyageDef", Voyages.DEFAULT) -- S2.1: the crew's voyage choice
	stateFolder:SetAttribute("TotalNights", Voyages[Voyages.DEFAULT].nights)
	stateFolder.Parent = ReplicatedStorage
	ctx.state = stateFolder

	-- Client <-> server messages. Handlers connect during boot; the folder is parented last (Network).
	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	for _, name in REMOTES do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotes
	end
	local snapshot = Instance.new("UnreliableRemoteEvent") -- S4.2: creature snapshots (CreatureService)
	snapshot.Name = "CreatureSnapshot"
	snapshot.Parent = remotes
	ctx.remotes = remotes

	-- a message line on one player's screen
	ctx.notify = function(player, text)
		remotes.Notify:FireClient(player, text)
	end
end

return Platform
