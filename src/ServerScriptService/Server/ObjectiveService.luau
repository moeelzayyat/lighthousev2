--!strict
-- ObjectiveService (S7.2, LiveOps domain): each player's daily objective (Definitions/Objectives). It counts the
-- player's own events from the bus (oil delivered, nights survived, cannons built, repairs, kills), pays the
-- Pearls once through GrantService when the objective is done, and shows today's objective as player attributes
-- (ObjectiveText, ObjectiveProgress, ObjectiveTarget). A new UTC day starts a fresh objective; nothing is lost
-- or counted for missing a day. Progress lives in the profile's `Objectives` field.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Objectives = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("Objectives")) :: any

local ObjectiveService = {}

export type Deps = {
	subscribe: (name: string, handler: (any) -> ()) -> any,
	publish: (name: string, payload: any) -> (),
	byUserIds: (ids: { number }) -> { any },
	data: (player: any) -> any,
	mutate: (player: any, fn: (any) -> boolean) -> boolean,
	grant: (player: any, claimId: string, rewards: any, source: string) -> any,
	notify: (player: any, text: string) -> (),
	now: () -> number,
}

-- Today's objective on the player (the HUD and menus can read these)
local function show(player: any, state: any)
	local id = Objectives.pick(player.UserId, state.DayKey)
	local def = Objectives[id]
	player:SetAttribute("ObjectiveText", def.displayName)
	player:SetAttribute("ObjectiveProgress", state.Progress[id] or 0)
	player:SetAttribute("ObjectiveTarget", def.target)
	player:SetAttribute("ObjectiveDone", state.Claimed[id] == true)
end

function ObjectiveService.start(deps: Deps)
	local function count(players: { any }, eventName: string, amount: number)
		for _, player in players do
			local done: string? = nil
			local state: any = nil
			deps.mutate(player, function(data: any): boolean
				done = Objectives.count(data.Objectives, player.UserId, deps.now(), eventName, amount)
				state = data.Objectives
				return done ~= nil -- push and save only when it is done; progress is kept in the profile either way
			end)
			if state then
				show(player, state)
			end
			if done then
				local def = Objectives[done]
				deps.grant(player, string.format("objective:%s:%s", state.DayKey, done), { Pearls = def.reward }, "objective")
				deps.publish("ObjectiveCompleted", { UserId = player.UserId, ObjectiveId = done })
				deps.notify(player, string.format("Daily objective done: %s! +%d Pearls.", def.displayName, def.reward))
			end
		end
	end
	local function one(e: any, field: string): { any }
		local id = e[field]
		return if type(id) == "number" then deps.byUserIds({ id }) else {}
	end

	deps.subscribe("ProfileLoaded", function(e)
		for _, player in deps.byUserIds({ e.UserId }) do
			local data = deps.data(player)
			if data then
				Objectives.rollOver(data.Objectives, player.UserId, deps.now())
				show(player, data.Objectives)
				local id = Objectives.pick(player.UserId, data.Objectives.DayKey)
				if not data.Objectives.Claimed[id] then
					deps.notify(player, string.format("Today's objective: %s (+%d Pearls).", Objectives[id].displayName, Objectives[id].reward))
				end
			end
		end
	end)
	deps.subscribe("Refuelled", function(e)
		count(one(e, "UserId"), "Refuelled", 1)
	end)
	deps.subscribe("NightSurvived", function(e)
		count(deps.byUserIds(e.Crew), "NightSurvived", e.Night)
	end)
	deps.subscribe("CannonBuilt", function(e)
		count(one(e, "UserId"), "CannonBuilt", 1)
	end)
	deps.subscribe("TowerRepaired", function(e)
		count(one(e, "UserId"), "TowerRepaired", 1)
	end)
	deps.subscribe("CreatureKilled", function(e)
		count(one(e, "KillerId"), "CreatureKilled", 1)
	end)
end

return ObjectiveService
