--!strict
-- Definitions/Boosts (S6.4, owner request #6): the Quartermaster's permanent boosts, bought with Pearls rank by
-- rank and saved in the profile (`Boosts`: id -> rank). Small steps; all boosts together stop at TOTAL_CAP
-- (+15%), so a player chooses what to grow. Pearls are earned in play; nothing here is sold for Robux.
-- Prices and steps: D-021 (unattended recommendation, to be tuned after the public test).
--   stat     the StatPipeline stat the boost feeds (ShellGainPct is Shells from loot this player picks up)
--   step     the bonus each rank adds
--   prices   Pearls for rank 1, 2, ... (the number of prices is the number of ranks)

export type BoostDef = {
	id: string,
	displayName: string,
	description: string,
	stat: string,
	step: number,
	prices: { number },
}

local Boosts = {
	ORDER = { "ShellPouch", "SeaBoots", "SharpSteel" },
	TOTAL_CAP = 0.15,

	ShellPouch = {
		id = "ShellPouch",
		displayName = "Shell Pouch",
		description = "+2% Shells from loot you pick up, per rank",
		stat = "ShellGainPct",
		step = 0.02,
		prices = { 20, 30, 40, 50, 60 },
	} :: BoostDef,
	SeaBoots = {
		id = "SeaBoots",
		displayName = "Sea Boots",
		description = "+1% walk speed, per rank",
		stat = "PlayerSpeed",
		step = 0.01,
		prices = { 15, 20, 25, 30, 40 },
	} :: BoostDef,
	SharpSteel = {
		id = "SharpSteel",
		displayName = "Sharpened Steel",
		description = "+1% weapon damage, per rank",
		stat = "WeaponDamage",
		step = 0.01,
		prices = { 20, 30, 40, 50, 60 },
	} :: BoostDef,
}

local function def(id: string): BoostDef?
	local d = (Boosts :: any)[id]
	return if type(d) == "table" and table.find(Boosts.ORDER, id) then d else nil
end

-- What all of a profile's ranks add together (0 to TOTAL_CAP)
function Boosts.total(ranks: { [string]: number }): number
	local sum = 0
	for id, rank in ranks do
		local d = def(id)
		if d then
			sum += d.step * rank
		end
	end
	return sum
end

-- What a profile's ranks add to one stat
function Boosts.bonus(ranks: { [string]: number }, stat: string): number
	local sum = 0
	for id, rank in ranks do
		local d = def(id)
		if d and d.stat == stat then
			sum += d.step * rank
		end
	end
	return sum
end

-- Whether the next rank of `id` can be bought: ok, its price, the reason when not
function Boosts.nextRank(ranks: { [string]: number }, id: string): (boolean, number?, string?)
	local d = def(id)
	if not d then
		return false, nil, "The Quartermaster doesn't sell that."
	end
	local rank = ranks[id] or 0
	if rank >= #d.prices then
		return false, nil, d.displayName .. " is at its top rank."
	end
	if Boosts.total(ranks) + d.step > Boosts.TOTAL_CAP + 1e-9 then
		return false, nil, string.format("Your boosts together are at the +%d%% limit.", math.floor(Boosts.TOTAL_CAP * 100 + 0.5))
	end
	return true, d.prices[rank + 1], nil
end

return Boosts
