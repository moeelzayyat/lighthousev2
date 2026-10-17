--!strict
-- Definitions/Logbook (S7.1): what a player can discover, and the Pearls for finishing each category. The entries
-- come from the catalogs themselves, so a new creature is a new entry: "Creatures:<id>", "Bosses:<id>",
-- "Evolutions:<id>", "Forecasts:<id>" (the profile's `Logbook` field: key -> true). Rewards: D-025.
--   how      how an entry is found (shown in the notice)
--   reward   Pearls when the last entry of the category is found (GrantService claim "logbook:<category>:<count>")

export type CategoryDef = { id: string, displayName: string, how: string, reward: number }

local Logbook = {
	ORDER = { "Creatures", "Bosses", "Evolutions", "Forecasts" },

	Creatures = { id = "Creatures", displayName = "Creatures", how = "defeated by your crew", reward = 15 } :: CategoryDef,
	Bosses = { id = "Bosses", displayName = "Big monsters", how = "brought down by your crew", reward = 10 } :: CategoryDef,
	Evolutions = { id = "Evolutions", displayName = "Evolutions", how = "forged in a voyage", reward = 10 } :: CategoryDef,
	Forecasts = { id = "Forecasts", displayName = "Forecasts", how = "a night survived under it", reward = 5 } :: CategoryDef,
}

function Logbook.key(category: string, id: string): string
	return category .. ":" .. id
end

-- Every entry of every category, sorted, from the creature, upgrade and forecast catalogs
function Logbook.entries(creatures: any, upgrades: any, forecasts: any): { [string]: { string } }
	local out: { [string]: { string } } = { Creatures = {}, Bosses = {}, Evolutions = {}, Forecasts = {} }
	for id, def in creatures do
		if type(def) == "table" and def.health ~= nil then
			table.insert(out[if def.big then "Bosses" else "Creatures"], id)
		end
	end
	for _, evo in upgrades.EVOLUTIONS or {} do
		table.insert(out.Evolutions, evo.id)
	end
	for _, id in forecasts.ORDER or {} do
		table.insert(out.Forecasts, id)
	end
	for _, list in out do
		table.sort(list)
	end
	return out
end

-- Marks an entry found in a profile's logbook. Returns whether it was new and, when it was the last one of its
-- category, that category (whose reward is then paid once).
function Logbook.discover(book: { [string]: boolean }, entries: { [string]: { string } }, category: string, id: string): (boolean, string?)
	local list = entries[category]
	if not list or not table.find(list, id) then
		return false, nil
	end
	local key = Logbook.key(category, id)
	if book[key] then
		return false, nil
	end
	book[key] = true
	for _, other in list do
		if not book[Logbook.key(category, other)] then
			return true, nil
		end
	end
	return true, category
end

return Logbook
