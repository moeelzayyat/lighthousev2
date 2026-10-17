-- Encounter domain (S5.1/S5.2): the lamp, the tower, the crew upgrades, creatures, loot and cannons; oil
-- carrying; attacks; the choices made before sailing (forecast, voyage); and the round loop itself.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Server = script.Parent.Parent
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Weapons = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Weapons"))
local SoundFx = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundFx"))
local Voyages = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("Voyages"))
local StatPipeline = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StatPipeline")) -- S5.7
local EventLog = require(Server.EventLog)
local PlayerData = require(Server.PlayerData)
local LampService = require(Server.LampService)
local GameState = require(Server.GameState)
local TowerService = require(Server.TowerService)
local CreatureService = require(Server.CreatureService)
local UpgradeService = require(Server.UpgradeService)
local LootService = require(Server.LootService)
local DefenseService = require(Server.DefenseService)
local VoyageCast = require(Server.VoyageCast)
local NetGuard = require(Server.NetGuard)
local OilCarry = require(Server.OilCarry)

local Encounter = { Name = "Encounter" }

---------------------------------------------------------------------
-- Oil carrying: grab a barrel from the pile, bring it to the fuel tank
---------------------------------------------------------------------

-- (S5.3: the barrel itself is `OilCarry`, which the cannons and the trip back to the ship use too)
local function hookOil(ctx)
	local refs, remotes, stateFolder = ctx.refs, ctx.remotes, ctx.state

	refs.oilPrompt.Triggered:Connect(function(player)
		if OilCarry.has(player) then
			LampService.notify(player, "You're already carrying oil. Take it to the fuel tank by the lighthouse.")
			return
		end
		OilCarry.give(player)
		EventLog.mark(player, "firstAction")
		EventLog.count("oilGrabbed", 1, player)
		EventLog.first("oil pickup")
		EventLog.log("OilGrabbed", { player = player.Name })
	end)

	refs.fuelPrompt.Triggered:Connect(function(player)
		if not OilCarry.has(player) then
			LampService.notify(player, "Grab oil from the barrels on the island first.")
			return
		end
		if LampService.getFuel() >= LampService.getMaxFuel() then
			LampService.notify(player, "The tank is already full.")
			return
		end
		local fuelBefore = LampService.getFuel()
		OilCarry.remove(player)
		LampService.addFuel(Config.FUEL_PER_REFILL)
		EventLog.Publish("Refuelled", {
			VoyageId = EventLog.voyageId(),
			UserId = player.UserId,
			Amount = LampService.getFuel() - fuelBefore,
			FuelBefore = fuelBefore,
			Night = stateFolder:GetAttribute("Phase") == "Night",
		})
		EventLog.count("refuels", 1, player)
		EventLog.first("lamp refuel")
		EventLog.log("Refueled", { player = player.Name, fuelBefore = math.floor(fuelBefore) })
		EventLog.mark(player, "fuel")
		SoundFx.playAt("refuel", refs.fuelPrompt.Parent.Position)
		-- Crew feedback (launch R4): a feed line for the crew and a client-only flare. No gameplay values change.
		local clutch = fuelBefore < LampService.getMaxFuel() * 0.1 and stateFolder:GetAttribute("Phase") == "Night"
		if clutch then
			EventLog.count("clutchSaves", 1, player)
			EventLog.log("SavedTheLight", { player = player.Name, fuelBefore = math.floor(fuelBefore) })
			EventLog.moment(1, string.format("%s saved the light at %d%% fuel", player.DisplayName, math.max(0, math.floor(fuelBefore / LampService.getMaxFuel() * 100))))
		end
		if Config.CREW_FEED_ENABLED then
			local gained = math.floor((LampService.getFuel() - fuelBefore) / LampService.getMaxFuel() * 100 + 0.5)
			for _, p in Players:GetPlayers() do
				if p:GetAttribute("Ready") then
					remotes.CrewFeed:FireClient(p, { kind = if clutch then "clutch" else "refuel", name = player.DisplayName, self = p == player, amount = gained })
				end
			end
		end
	end)
end

---------------------------------------------------------------------
-- Upgrade bench (crew Shells)
---------------------------------------------------------------------

-- R1.4: only a Ready crew member, during a voyage, standing at the bench may spend; duplicate requestIds
-- replay the first answer from a capped map (checked before the rate limit).
local BENCH_RANGE = 18
local BENCH_PHASES = { Prologue = true, Day = true, Night = true }

local function hookBench(ctx)
	local refs, remotes, stateFolder = ctx.refs, ctx.remotes, ctx.state
	local upgradeReplay = NetGuard.replayMap()
	local lastBuy = {}

	-- Upgrade bench: open the upgrade panel for whoever uses it
	refs.upgradePrompt.Triggered:Connect(function(player)
		remotes.OpenUpgrades:FireClient(player)
	end)

	-- Stripped-core playtest: remove the upgrade bench entirely
	if not Config.ECONOMY_ENABLED then
		refs.upgradePrompt.Parent:Destroy()
		local benchTop = refs.folder:FindFirstChild("BenchTop")
		if benchTop then
			benchTop:Destroy()
		end
		-- no loot drops in this mode, so the Trader has nothing to buy: no prompt, no sheet
		refs.traderPrompt.Enabled = false
	end

	local function benchRefusal(player)
		if player:GetAttribute("Ready") ~= true then
			return "Only the voyage crew can spend the crew's Shells."
		end
		if not BENCH_PHASES[stateFolder:GetAttribute("Phase")] then
			return "The bench only works during a voyage."
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local benchPart = refs.upgradePrompt.Parent
		if not root or not benchPart or (root.Position - benchPart.Position).Magnitude > BENCH_RANGE then
			return "Get closer to the UPGRADE bench."
		end
		return nil
	end

	-- requestId (optional, sent by the upgrade bench UI) gets a direct UpgradeResult reply
	remotes.BuyUpgrade.OnServerEvent:Connect(function(player, id, requestId)
		if typeof(id) ~= "string" or #id > 40 then
			return
		end
		if requestId ~= nil and not NetGuard.isRequestId(requestId) then
			return
		end
		if requestId then
			local previous = upgradeReplay.get(player, requestId)
			if previous then
				remotes.UpgradeResult:FireClient(player, requestId, previous[1], previous[2], id)
				return
			end
		end
		if not NetGuard.allow(player, "BuyUpgrade") then
			return
		end
		local now = os.clock()
		if (lastBuy[player] or 0) + 0.3 > now then
			if requestId then
				remotes.UpgradeResult:FireClient(player, requestId, false, "One upgrade at a time. Try again.", id)
			end
			return -- ignore double-clicks
		end
		lastBuy[player] = now
		local ok, message
		local refusal = benchRefusal(player)
		if refusal then
			ok, message = false, refusal
			EventLog.log("UpgradeRefused", { player = player.Name, id = id, reason = refusal })
		else
			ok, message = UpgradeService.buy(id)
		end
		if requestId then
			upgradeReplay.put(player, requestId, { ok, message })
			remotes.UpgradeResult:FireClient(player, requestId, ok, message, id)
		end
		if ok then
			EventLog.upgrade(id, UpgradeService.getLevel(id))
			EventLog.log("UpgradeBought", { player = player.Name, id = id, level = UpgradeService.getLevel(id) })
			EventLog.Publish("UpgradeBought", { VoyageId = EventLog.voyageId(), UserId = player.UserId, Id = id, Rank = UpgradeService.getLevel(id) })
			local benchPart = refs.upgradePrompt.Parent
			if benchPart then
				SoundFx.playAt("build", benchPart.Position)
			end
			VoyageCast.fire(remotes.Notify, player.DisplayName .. ": " .. message) -- island bench: crew only
		elseif not requestId then
			LampService.notify(player, message) -- the bench UI shows the reason itself
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastBuy[player] = nil
	end)
end

---------------------------------------------------------------------
-- Attacks: everyone can fight on foot (much weaker than the beam)
---------------------------------------------------------------------

-- Projectile visuals (cosmetic only; damage is decided on the server before this plays)
local function showProjectile(folder, weapon, from, to)
	local shot = Instance.new("Part")
	shot.Anchored = true
	shot.CanCollide = false
	shot.CanQuery = false
	shot.CanTouch = false
	shot.Color = weapon.color
	if weapon.projectile == "flare" then
		shot.Shape = Enum.PartType.Ball
		shot.Size = Vector3.new(1, 1, 1)
		shot.Material = Enum.Material.Neon
	else
		shot.Size = Vector3.new(0.3, 0.3, 3)
		shot.Material = Enum.Material.Metal
	end
	shot.CFrame = CFrame.lookAt(from, to)
	shot.Parent = folder
	SoundFx.playOn("throw", shot)

	local travel = TweenService:Create(shot, TweenInfo.new(0.15, Enum.EasingStyle.Linear), { CFrame = CFrame.lookAt(to, to + (to - from)) })
	travel.Completed:Connect(function()
		if weapon.projectile == "flare" then
			-- burst showing the area it hit
			local burst = TweenService:Create(shot, TweenInfo.new(0.3), {
				Size = Vector3.new(weapon.hitRadius * 2, weapon.hitRadius * 2, weapon.hitRadius * 2),
				Transparency = 1,
			})
			burst.Completed:Connect(function()
				shot:Destroy()
			end)
			burst:Play()
		else
			task.delay(0.3, function()
				shot:Destroy()
			end)
		end
	end)
	travel:Play()
end

local function hookAttack(ctx)
	local lastAttack = {}
	ctx.remotes.Attack.OnServerEvent:Connect(function(player, target)
		-- Validate everything the client sends (R1.4: NaN and +/-inf rejected, contract rate)
		if not NetGuard.isFiniteVector3(target) or not NetGuard.allow(player, "Attack") then
			return
		end
		if LampService.getKeeper() == player then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 then
			return
		end

		-- The server decides which weapon is used: whatever the player actually has equipped
		local tool = character:FindFirstChildOfClass("Tool")
		local weaponId = tool and tool:GetAttribute("WeaponId")
		local weapon = weaponId and Weapons[weaponId]
		if not weapon then
			return
		end
		-- S5.7: the numbers the shop shows; S6.2: plus the merchant's damage boost (a server-set attribute)
		local stats = StatPipeline.weapon(weaponId, { damage = { add = { player:GetAttribute("Boost_WeaponDamage") or 0 } } })

		local now = os.clock()
		if (lastAttack[player] or 0) + stats.cooldown > now then
			return
		end
		lastAttack[player] = now

		-- Clamp to the weapon's range
		local offset = target - root.Position
		if offset.Magnitude > stats.range then
			target = root.Position + offset.Unit * stats.range
		end

		local hits = CreatureService.damageArea(target, stats.hitRadius, stats.damage, stats.maxTargets, "Weapon:" .. weaponId, player)
		EventLog.count("attacks")
		EventLog.first("harpoon attack")
		EventLog.mark(player, "firstAction")
		if #hits > 0 then
			EventLog.mark(player, "strike")
			EventLog.count("attackHits")
			SoundFx.playAt("hit", hits[1])
		end
		showProjectile(ctx.refs.folder, weapon, root.Position + Vector3.new(0, 1.5, 0), hits[1] or target)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastAttack[player] = nil
	end)
end

---------------------------------------------------------------------
-- Before sailing: Play Again, the storm forecast vote, the voyage choice
---------------------------------------------------------------------

local function hookChoices(ctx)
	local remotes, stateFolder = ctx.remotes, ctx.state

	-- Results screen: Play Again
	remotes.VoteRematch.OnServerEvent:Connect(function(player)
		if not NetGuard.allow(player, "VoteRematch") then
			return
		end
		if player:GetAttribute("Ready") then
			player:SetAttribute("WantsRematch", true)
		end
	end)

	-- Storm forecast vote (launch R9): crew members pick one of the two offered forecasts before sailing
	remotes.ForecastVote.OnServerEvent:Connect(function(player, choice)
		if not NetGuard.allow(player, "ForecastVote") then
			return
		end
		local phase = stateFolder:GetAttribute("Phase")
		if not player:GetAttribute("Ready") or (phase ~= "Waiting" and phase ~= "Intermission") then
			return
		end
		if choice ~= stateFolder:GetAttribute("ForecastA") and choice ~= stateFolder:GetAttribute("ForecastB") then
			return
		end
		player:SetAttribute("ForecastVote", choice)
	end)

	-- Voyage choice (S2.1): a crew member who holds a voyage's unlock picks it before sailing. GameState checks
	-- the unlock again when the ship leaves (a member who has it must be sailing).
	remotes.ChooseVoyage.OnServerEvent:Connect(function(player, defId)
		if type(defId) ~= "string" or #defId > 20 or not NetGuard.allow(player, "ChooseVoyage") then
			return
		end
		local def = Voyages[defId]
		local phase = stateFolder:GetAttribute("Phase")
		if type(def) ~= "table" or not def.nights or def.testOnly or player:GetAttribute("Ready") ~= true then
			return
		end
		if phase ~= "Waiting" and phase ~= "Intermission" then
			return
		end
		if def.unlock and player:GetAttribute("Unlock_" .. def.unlock) ~= true then
			return
		end
		if stateFolder:GetAttribute("VoyageDef") ~= def.id then
			stateFolder:SetAttribute("VoyageDef", def.id)
			stateFolder:SetAttribute("TotalNights", def.nights)
			EventLog.log("VoyageChosen", { player = player.Name, voyage = def.id })
		end
	end)
end

---------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------

function Encounter.Init(ctx)
	local refs, remotes, stateFolder = ctx.refs, ctx.remotes, ctx.state
	LampService.init(refs, stateFolder, remotes)
	TowerService.init(stateFolder, refs.repairPrompt, LampService.notify)
	UpgradeService.init(stateFolder, LampService, TowerService)
	CreatureService.init(refs, LampService, TowerService, UpgradeService, DefenseService, stateFolder, remotes)
	LootService.init(refs.folder, UpgradeService, remotes, PlayerData)
	DefenseService.init(refs.folder, CreatureService, UpgradeService, function(text)
		VoyageCast.fire(remotes.Notify, text) -- cannon news is for the voyage crew, not the harbor
	end, LampService.notify)

	hookOil(ctx)
	hookBench(ctx)
	hookAttack(ctx)
	hookChoices(ctx)
end

function Encounter.Start(ctx)
	local function resetRound()
		-- Loot from the last voyage is gone, just like shells
		for _, player in Players:GetPlayers() do
			PlayerData.clearRunLoot(player)
		end
		LampService.reset()
		TowerService.reset()
		UpgradeService.reset()
		DefenseService.reset()
		CreatureService.clearAll()
		LootService.clearAll()
		for _, player in Players:GetPlayers() do
			OilCarry.remove(player)
		end
	end

	-- The round loop runs for the life of the server; it starts once boot has finished (Network last).
	task.defer(GameState.run, {
		lamp = LampService,
		tower = TowerService,
		creatures = CreatureService,
		playerData = PlayerData,
		sendToIsland = ctx.sendToIsland,
		sendToShip = ctx.sendToShip,
		loot = LootService,
		upgrades = UpgradeService,
		state = ctx.state,
		remotes = ctx.remotes,
		resetRound = resetRound,
		departure = ctx.departure,
		departShip = ctx.departShip,
		lampVisuals = LampService.refreshVisuals,
	})
end

return Encounter
