-- TowerService: the lighthouse's integrity. Creatures chew on it; players repair it.
-- If integrity reaches 0, creatures break in and the run is lost.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local EventLog = require(script.Parent.EventLog)
local SoundFx = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundFx"))
local Merchant = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("Merchant"))

local TowerService = {}

local state
local maxIntegrity = Config.MAX_INTEGRITY
local integrity = Config.MAX_INTEGRITY
local protected = false -- during the opening incident the tower takes no damage (TOWER.1)

local function push()
	state:SetAttribute("Integrity", math.ceil(integrity))
	state:SetAttribute("MaxIntegrity", maxIntegrity)
end

function TowerService.init(stateFolder, repairPrompt, notify)
	state = stateFolder
	push()

	repairPrompt.Triggered:Connect(function(player)
		if integrity >= maxIntegrity then
			notify(player, "The tower is already in good shape.")
			return
		end
		local before = integrity
		-- evolution (Shared.Upgrades.EVOLUTIONS): Clockwork Bastion restores 50% more per repair
		-- S7.4: the Engineer specialty adds its share to the repairer's repairs
		TowerService.repair(Config.REPAIR_AMOUNT * (if state:GetAttribute("Evo_ClockworkBastion") then 1.5 else 1) * (1 + (player:GetAttribute("Spec_Engineer") or 0)))
		EventLog.count("repairs", 1, player)
	EventLog.mark(player, "repair")
		EventLog.first("repair")
		EventLog.log("Repaired", { player = player.Name, integrity = math.ceil(integrity) })
		EventLog.Publish("TowerRepaired", { VoyageId = EventLog.voyageId(), UserId = player.UserId, Amount = integrity - before, IntegrityBefore = before })
		SoundFx.playAt("repair", repairPrompt.Parent.Position)
	end)
end

function TowerService.damage(amount)
	if state:GetAttribute("TowerShield") then
		amount *= Merchant.TowerShield.mult -- S6.2: the merchant's shield, until dawn
	end
	if protected then
		return -- TOWER.1 (D-060, owner 2026-10-24: "the lighthouse heals itself"): the opening squall can't hurt the
		-- tower at all (it used to dent it and then restore it to full at Day 1, which looked like healing)
	end
	local floor = 0
	local before = integrity / maxIntegrity
	integrity = math.max(floor, integrity - amount)
	local after = integrity / maxIntegrity
	if not protected then
		EventLog.towerLow(after)
	end
	for _, threshold in { 0.75, 0.5, 0.25 } do
		if before > threshold and after <= threshold then
			EventLog.log("TowerBelow", { percent = threshold * 100 })
		end
	end
	push()
end

function TowerService.repair(amount)
	integrity = math.min(maxIntegrity, integrity + amount)
	push()
end

function TowerService.setMax(amount)
	maxIntegrity = amount
	integrity = math.min(integrity, maxIntegrity)
	push()
end

function TowerService.isBroken()
	return integrity <= 0
end

function TowerService.setProtected(on)
	protected = on
end

function TowerService.reset()
	maxIntegrity = Config.MAX_INTEGRITY
	integrity = maxIntegrity
	protected = false
	push()
end

return TowerService
