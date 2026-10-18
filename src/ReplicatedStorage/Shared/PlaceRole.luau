--!strict
-- PlaceRole (D-046): which job this server does. One place file is published to two places in the experience.
--   "harbor": the shared harbor island with several ships; a ship's crew is teleported to its own isle server.
--   "isle":   one crew's voyage on Lighthouse Isle (a reserved server); afterwards players go back to the harbor.
--   "single": the isle place does not exist yet (Config.ISLE_PLACE_ID = 0): one place, one ship, as before.
-- Config.PLACE_ROLE_OVERRIDE ("harbor" | "isle") forces a role for Studio tests.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local PlaceRole = {}

-- pure: the role for a place id and settings (tests call this directly)
function PlaceRole.resolve(placeId: number, harborPlaceId: number?, islePlaceId: number?, override: string?): string
	if override == "harbor" or override == "isle" then
		return override
	end
	if type(islePlaceId) ~= "number" or islePlaceId == 0 then
		return "single"
	end
	if placeId == islePlaceId then
		return "isle"
	end
	return "harbor"
end

function PlaceRole.get(): string
	return PlaceRole.resolve(game.PlaceId, Config.HARBOR_PLACE_ID, Config.ISLE_PLACE_ID, Config.PLACE_ROLE_OVERRIDE)
end

function PlaceRole.isHarbor(): boolean
	return PlaceRole.get() == "harbor"
end

function PlaceRole.isIsle(): boolean
	return PlaceRole.get() == "isle"
end

return PlaceRole
