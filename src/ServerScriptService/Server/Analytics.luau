--!strict
-- Analytics (R1.6, Telemetry domain): a bus consumer only. Turns bus events into Roblox AnalyticsService calls:
--   * the onboarding funnel with fixed step names (docs/EVENTS.md): Joined, OnCrew, Landed, FirstAction,
--     FirstBeamHit, Night1Survived, DawnPearl (a player's first dawn-banked Pearl, S2.2), VoyageEnded, SailAgain
--   * "Left" and "VoyageEnded" as custom events with their phase / outcome
--   * Pearl sources and sinks as economy events with the ending balance
-- The sink is swappable so tests can record calls without touching AnalyticsService.

local Players = game:GetService("Players")

local Analytics = {}

Analytics.STEPS = {
	Joined = 1,
	OnCrew = 2,
	Landed = 3,
	FirstAction = 4,
	FirstBeamHit = 5,
	Night1Survived = 6,
	DawnPearl = 7,
	VoyageEnded = 8,
	SailAgain = 9,
} :: { [string]: number }

export type Sink = {
	funnel: (userId: number, step: number, stepName: string) -> (),
	economy: (userId: number, flow: string, amount: number, balance: number, transaction: string, sku: string?) -> (),
	custom: (userId: number, name: string, value: number?, field: string?) -> (),
}

type Bus = {
	Subscribe: (name: string, handler: ({ [string]: any }) -> ()) -> () -> (),
}

-- The real sink: AnalyticsService, each call in pcall (telemetry must never break gameplay).
function Analytics.robloxSink(debugPrint: boolean?): Sink
	local service = game:GetService("AnalyticsService") :: any
	-- A leaving player can no longer be found by UserId when the "Left" event arrives (handler order is not
	-- guaranteed), so players are remembered from join until 30 s after they leave.
	local known: { [number]: Player } = {}
	local function remember(player: Player)
		known[player.UserId] = player
	end
	Players.PlayerAdded:Connect(remember)
	for _, player in Players:GetPlayers() do
		remember(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		task.delay(30, function()
			if known[player.UserId] == player and player.Parent == nil then
				known[player.UserId] = nil
			end
		end)
	end)
	local function call(what: string, fn: (Player) -> (), userId: number)
		local player = known[userId] or Players:GetPlayerByUserId(userId)
		if not player then
			if debugPrint then
				print("[ANL] skipped " .. what .. " user=" .. userId .. " (not in this server)")
			end
			return
		end
		local ok, err = pcall(fn, player)
		if not ok then
			warn("[Analytics] " .. what .. " failed: " .. tostring(err))
		elseif debugPrint then
			print("[ANL] " .. what .. " user=" .. userId)
		end
	end
	return {
		funnel = function(userId: number, step: number, stepName: string)
			call("funnel " .. step .. " " .. stepName, function(player)
				service:LogOnboardingFunnelStepEvent(player, step, stepName)
			end, userId)
		end,
		economy = function(userId: number, flow: string, amount: number, balance: number, transaction: string, sku: string?)
			call("economy " .. flow .. " Pearls " .. amount .. " -> " .. balance .. " " .. transaction, function(player)
				service:LogEconomyEvent(player, (Enum.AnalyticsEconomyFlowType :: any)[flow], "Pearls", amount, balance, transaction, sku)
			end, userId)
		end,
		custom = function(userId: number, name: string, value: number?, field: string?)
			call("custom " .. name .. " " .. tostring(field or ""), function(player)
				local fields = if field then { [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = field } else nil
				service:LogCustomEvent(player, name, value or 1, fields)
			end, userId)
		end,
	}
end

local function transactionFor(source: string): string
	if source == "sell" then
		return Enum.AnalyticsEconomyTransactionType.Shop.Name
	end
	return Enum.AnalyticsEconomyTransactionType.Gameplay.Name
end

-- Subscribes the consumer to the bus. Returns the unsubscribe functions.
function Analytics.start(bus: Bus, sink: Sink): { () -> () }
	local subs = {}
	local function on(name: string, handler: ({ [string]: any }) -> ())
		table.insert(subs, bus.Subscribe(name, handler))
	end
	local function step(userId: number, name: string)
		sink.funnel(userId, Analytics.STEPS[name], name)
	end

	on("PlayerJoined", function(e)
		step(e.UserId, "Joined")
	end)
	on("PlayerJoinedCrew", function(e)
		step(e.UserId, "OnCrew")
	end)
	on("PlayerLanded", function(e)
		step(e.UserId, "Landed")
	end)
	on("FirstAction", function(e)
		step(e.UserId, "FirstAction")
	end)
	on("BeamHit", function(e)
		if e.First then
			step(e.KeeperId, "FirstBeamHit")
		end
	end)
	on("NightSurvived", function(e)
		if e.Night == 1 then
			for _, userId in e.Crew do
				step(userId, "Night1Survived")
			end
		end
	end)
	on("VoyageEnded", function(e)
		for _, userId in e.Crew do
			step(userId, "VoyageEnded")
			sink.custom(userId, "VoyageEnded", e.NightReached, e.Outcome .. ":" .. e.Cause)
		end
	end)
	on("SailAgain", function(e)
		step(e.UserId, "SailAgain")
	end)
	on("PlayerLeft", function(e)
		sink.custom(e.UserId, "Left", e.Night, e.Phase)
	end)
	local dawnSeen: { [number]: boolean } = {}
	on("PearlsGranted", function(e)
		if e.Source == "dawn" and not dawnSeen[e.UserId] then
			dawnSeen[e.UserId] = true
			step(e.UserId, "DawnPearl")
		end
		sink.economy(e.UserId, "Source", e.Amount, e.Balance, transactionFor(e.Source), e.Source)
	end)
	on("PearlsSpent", function(e)
		sink.economy(e.UserId, "Sink", e.Amount, e.Balance, Enum.AnalyticsEconomyTransactionType.Shop.Name, e.ItemId)
	end)
	return subs
end

return Analytics
