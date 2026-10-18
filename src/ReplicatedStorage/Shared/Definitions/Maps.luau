--!strict
-- Definitions/Maps (MAP.1, D-049): the islands a crew can sail to. The voyage loop, the lighthouse and the shoreline
-- are the same on every map; a map changes the ground (terrain materials), the sea colour, the light and the dressing.
--   LighthouseIsle: the home isle (the place as built).
--   FrostIsle: Frostbite Isle, the same island under snow and ice, with snowfall instead of rain.
-- Shared crew unlocks: a map with `unlock` can be chosen for a ship when ANY crew member on it holds Unlocks[unlock];
-- the whole crew sails there. A win of the voyage named by `grantedBy` gives each crew member the unlock.
-- Validated by _Registry at boot (RULES.Maps).

export type MapDef = {
	id: string,
	displayName: string,
	short: string,
	unlock: string?, -- a crew member needs Unlocks[unlock] for the crew to choose it
	grantedBy: string?, -- a win of this voyage (Definitions/Voyages id) grants Unlocks[unlock]
	terrain: { [string]: string }?, -- terrain material swaps on the island (Enum.Material names), undone on the next map
	waterColor: { number }?, -- RGB
	tint: { number }?, -- ColorCorrection tint, RGB
	saturation: number?, -- ColorCorrection saturation (-1 .. 1)
	decor: string?, -- MapBuilder dressing set
	snow: boolean?, -- the storm's rain falls as snow (Client.Storm)
}

local Maps = {
	ORDER = { "LighthouseIsle", "FrostIsle" },
	DEFAULT = "LighthouseIsle",

	LighthouseIsle = {
		id = "LighthouseIsle",
		displayName = "Lighthouse Isle",
		short = "the home isle",
	} :: MapDef,

	FrostIsle = {
		id = "FrostIsle",
		displayName = "Frostbite Isle",
		short = "snow and ice",
		unlock = "FrostIsle",
		grantedBy = "Standard",
		terrain = { Grass = "Snow", LeafyGrass = "Snow", Ground = "Snow", Mud = "Ice", Sand = "Glacier" },
		waterColor = { 40, 98, 120 },
		tint = { 222, 236, 255 },
		saturation = -0.2,
		decor = "frost",
		snow = true,
	} :: MapDef,
}

-- Shared crew unlock (pure): the map a ship sails to. The chosen map if it needs no unlock or any crew member holds
-- it; otherwise the default. `holds(key)` answers for the whole crew.
function Maps.resolve(chosen: string?, holds: (string) -> boolean): string
	local def = if type(chosen) == "string" then (Maps :: any)[chosen] else nil
	if type(def) ~= "table" or type(def.id) ~= "string" then
		return Maps.DEFAULT
	end
	if def.unlock and not holds(def.unlock) then
		return Maps.DEFAULT
	end
	return def.id
end

-- The maps a crew can choose from (pure): every map whose unlock any member holds, in ORDER
function Maps.availableFor(holds: (string) -> boolean): { string }
	local list = {}
	for _, id in Maps.ORDER do
		local def = (Maps :: any)[id]
		if def.unlock == nil or holds(def.unlock) then
			table.insert(list, id)
		end
	end
	return list
end

return Maps
