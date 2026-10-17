--!strict
-- SpecialtyService (S7.4, LiveOps domain): counts each player's role events from the bus into the profile's
-- `Roles` (BeamKills, WeaponKills, OilDelivered, Repairs) and records the ranks those counts earn in
-- `Unlocks.Specialties`. Playing is the only way to earn a rank: nothing else writes either field. A new rank is
-- told to the player, and the profile push refreshes their bonuses (Economy's applyBoosts).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Specialties = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("Specialties")) :: any

local SpecialtyService = {}

export type Deps = {
	subscribe: (name: string, handler: (any) -> ()) -> any,
	byUserIds: (ids: { number }) -> { any },
	mutate: (player: any, fn: (any) -> boolean) -> boolean,
	notify: (player: any, text: string) -> (),
}

function SpecialtyService.start(deps: Deps)
	local function count(userId: any, role: string)
		if type(userId) ~= "number" then
			return
		end
		for _, player in deps.byUserIds({ userId }) do
			local raised: { string } = {}
			local ranks: { [string]: number } = {}
			deps.mutate(player, function(data: any): boolean
				data.Roles[role] = (data.Roles[role] or 0) + 1
				ranks = Specialties.ranks(data.Roles)
				for id, rank in ranks do
					if rank > (data.Unlocks.Specialties[id] or 0) then
						data.Unlocks.Specialties[id] = rank
						table.insert(raised, id)
					end
				end
				return #raised > 0 -- a new rank pushes the profile (and the bonuses refresh); counting alone does not
			end)
			for _, id in raised do
				local def = Specialties[id]
				deps.notify(player, string.format("Specialty earned: %s rank %d! +%d%% %s.", def.displayName, ranks[id], math.floor(ranks[id] * def.step * 100 + 0.5), def.bonus))
			end
		end
	end

	deps.subscribe("CreatureKilled", function(e)
		local source = tostring(e.Source)
		if string.sub(source, 1, 7) == "Weapon:" then
			count(e.KillerId, "WeaponKills")
		elseif source == "FocusedBeam" or source == "WideBeam" then
			count(e.KillerId, "BeamKills")
		end
	end)
	deps.subscribe("Refuelled", function(e)
		count(e.UserId, "OilDelivered")
	end)
	deps.subscribe("TowerRepaired", function(e)
		count(e.UserId, "Repairs")
	end)
	deps.subscribe("CannonBuilt", function(e)
		count(e.UserId, "Repairs") -- building a cannon is engineering too
	end)
end

return SpecialtyService
