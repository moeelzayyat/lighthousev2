--!strict
-- LogbookService (S7.1, LiveOps domain): fills each player's logbook from the event bus and pays a category's
-- Pearls once when its last entry is found.
--   a creature   CreatureKilled (not big)  -> the crew on the island
--   a big monster BossDefeated              -> the crew on the island
--   an evolution EvolutionUnlocked          -> the crew on the island
--   a forecast   NightSurvived              -> that night's crew, under the voyage's forecast
-- Entries are saved in the profile's `Logbook` field ("Creatures:SpitterEel" -> true); the reward goes through
-- GrantService with the claim "logbook:<category>:<entries>", so it is paid once (and again only if the
-- category grows). The deps make it testable without a voyage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Logbook = require(Shared:WaitForChild("Definitions"):WaitForChild("Logbook"))
local Creatures = require(Shared:WaitForChild("Creatures")) :: any
local Upgrades = require(Shared:WaitForChild("Upgrades")) :: any
local Forecasts = require(Shared:WaitForChild("Forecasts")) :: any

local LogbookService = {}

export type Deps = {
	subscribe: (name: string, handler: (any) -> ()) -> any,
	publish: (name: string, payload: any) -> (),
	crew: () -> { any }, -- the players on the voyage now
	byUserIds: (ids: { number }) -> { any },
	mutate: (player: any, fn: (any) -> boolean) -> boolean,
	grant: (player: any, claimId: string, rewards: any, source: string) -> any,
	notify: (player: any, text: string) -> (),
	forecast: () -> string?,
}

-- the name a player reads for an entry
local function nameOf(category: string, id: string): string
	if category == "Creatures" or category == "Bosses" then
		return Creatures[id] and Creatures[id].displayName or id
	elseif category == "Evolutions" then
		for _, evo in Upgrades.EVOLUTIONS or {} do
			if evo.id == id then
				return evo.displayName
			end
		end
	elseif category == "Forecasts" then
		return Forecasts[id] and Forecasts[id].displayName or id
	end
	return id
end

function LogbookService.start(deps: Deps)
	local entries = Logbook.entries(Creatures, Upgrades, Forecasts)

	local function discover(players: { any }, category: string, id: string)
		for _, player in players do
			local isNew, finished = false, nil
			deps.mutate(player, function(data: any): boolean
				isNew, finished = Logbook.discover(data.Logbook, entries, category, id)
				return isNew
			end)
			if isNew then
				deps.publish("LogbookDiscovered", { UserId = player.UserId, EntryId = Logbook.key(category, id) })
				deps.notify(player, string.format("New in your logbook: %s.", nameOf(category, id)))
				if finished then
					local def = (Logbook :: any)[finished]
					deps.grant(player, string.format("logbook:%s:%d", finished, #entries[finished]), { Pearls = def.reward }, "logbook")
					deps.notify(player, string.format("Logbook: every %s found! +%d Pearls.", string.lower(def.displayName), def.reward))
				end
			end
		end
	end

	deps.subscribe("CreatureKilled", function(e)
		if not e.Big then
			discover(deps.crew(), "Creatures", e.DefId)
		end
	end)
	deps.subscribe("BossDefeated", function(e)
		discover(deps.crew(), "Bosses", e.DefId)
	end)
	deps.subscribe("EvolutionUnlocked", function(e)
		discover(deps.crew(), "Evolutions", e.Id)
	end)
	deps.subscribe("NightSurvived", function(e)
		local forecast = deps.forecast()
		if forecast and forecast ~= "" then
			discover(deps.byUserIds(e.Crew), "Forecasts", forecast)
		end
	end)
end

return LogbookService
