--!strict
-- EconomySim (L1.1): a pure model of a player's Pearl income and spending, run for N voyages. It reads the live
-- catalogs (Config, Voyages, Items, Boosts, Logbook, Objectives) so a change to any number shows up here.
-- No beta data exists yet (the beta has not run): crew sizes and how far crews get are ASSUMPTIONS, set in
-- `DEFAULT_MODEL` and printed with every report. Every Pearl source the game has is listed in `SOURCES`;
-- EconomySimSpec fails if a new GrantService caller appears that is not in that list.

local EconomySim = {}

-- Every way Pearls reach a profile (GrantService callers) and how the model counts it
EconomySim.SOURCES = {
	dawn = "1 Pearl per night survived (Config.PEARLS_PER_NIGHT), banked at each dawn",
	run = "the victory bonus at Results (Config.PEARLS_VICTORY_BONUS); a loss pays nothing more",
	["boss drop"] = "each big monster drops Pearls with BOSS_PEARL_CHANCE (MIN..MAX); one crew member picks it up",
	logbook = "once per finished category (Logbook rewards), never again",
	objective = "one daily objective a day (Objectives rewards)",
	sell = "Quartermaster sale of a Material with a `sell` price (no Material has one today: 0)",
	admin = "owner-only support grant (not income)",
	invite = "an item (the Shared Lantern), no Pearls",
	code = "a promo code's Pearls, once per profile (Definitions/Codes; finite)",
	robux = "a Robux receipt: a cosmetic item, no Pearls (L1.3)",
	rescue = "Shipwreck Rescue event voyage: 1 Pearl per 2 castaways saved (at most 4 a voyage) and the event flag once (LO.2)",
}

export type Model = {
	crew: { number }, -- chance of a crew of 1, 2, 3, 4
	dieAtNight: (night: number) -> number, -- chance the light goes out during this night
	longShare: number, -- once the Long Voyage is unlocked, the share of voyages that are Long
	voyagesPerDay: number, -- for the daily objective
	objectiveDone: number, -- chance the day's objective is finished
}

EconomySim.DEFAULT_MODEL = {
	crew = { 0.4, 0.3, 0.2, 0.1 },
	dieAtNight = function(night: number): number
		return math.min(0.5, 0.04 + 0.015 * night) -- about 1 in 3 Standard voyages is won
	end,
	longShare = 0.5,
	voyagesPerDay = 3,
	objectiveDone = 0.8,
} :: Model

type Catalogs = { Config: any, Voyages: any, Items: any, Boosts: any, Logbook: any, Objectives: any }

local function bossNightsOf(def: any): { [number]: boolean }
	local set = {}
	for _, n in def.bossNights do
		set[n] = true
	end
	if def.bossEveryNightFrom then
		for n = def.bossEveryNightFrom, def.nights do
			set[n] = true
		end
	end
	return set
end

-- The most Pearls one player can take from one voyage (every boss Pearl drop picked up by this player, at the
-- maximum roll). Bounded by nights × crew: no source pays per kill, per minute or per repeat.
function EconomySim.maxPerVoyage(c: Catalogs, defId: string, crew: number): number
	local def = c.Voyages[defId]
	local bosses = 0
	for _ in bossNightsOf(def) do
		bosses += crew -- S6.1: one big monster per crew member on a boss night
	end
	return (c.Config.PEARLS_PER_NIGHT or 0) * def.nights + (c.Config.PEARLS_VICTORY_BONUS or 0) + bosses * c.Config.BOSS_PEARL_MAX
end

-- Pearls the live shop can take: every priced item once and the boost ranks up to Boosts.TOTAL_CAP (cheapest
-- bonus per Pearl first)
function EconomySim.catalogueCost(c: Catalogs): (number, number)
	local items = 0
	for _, item in c.Items do
		if type(item) == "table" and type(item.price) == "number" then
			items += item.price
		end
	end
	local ranks = {}
	for _, id in c.Boosts.ORDER do
		local def = c.Boosts[id]
		for i, price in def.prices do
			table.insert(ranks, { price = price, step = def.step, id = id, rank = i })
		end
	end
	-- buy rank by rank in price order per boost until the cap (ranks of one boost must go in order)
	table.sort(ranks, function(a, b)
		return a.price / a.step < b.price / b.step or (a.price / a.step == b.price / b.step and a.rank < b.rank)
	end)
	local boosts, total, nextRank = 0, 0, {}
	for _, r in ranks do
		if (nextRank[r.id] or 1) == r.rank and total + r.step <= c.Boosts.TOTAL_CAP + 1e-9 then
			boosts += r.price
			total += r.step
			nextRank[r.id] = r.rank + 1
		end
	end
	return items, boosts
end

export type Report = {
	voyages: number,
	pearls: number,
	perVoyage: { mean: number, p50: number, p95: number, max: number },
	bound: number, -- the largest maxPerVoyage of any voyage simulated
	overBound: number, -- voyages that paid more than their bound (must be 0)
	wins: { Standard: number, Long: number },
	oneTime: number, -- logbook Pearls (finite)
	objectives: number,
	catalogue: { items: number, boosts: number },
	voyagesToBuyAll: number?, -- the voyage at which this player could have bought the whole live catalogue
}

function EconomySim.run(c: Catalogs, voyages: number, seed: number, model: Model?): Report
	local m = model or EconomySim.DEFAULT_MODEL
	local rng = Random.new(seed)
	local cfg = c.Config
	local items, boosts = EconomySim.catalogueCost(c)
	local perVoyage = table.create(voyages, 0)
	local total, bound, overBound, objectives = 0, 0, 0, 0
	local wins = { Standard = 0, Long = 0 }
	local unlocked = false
	local voyagesToBuyAll: number? = nil
	-- logbook: categories finish over the first voyages (the model pays each category once, early)
	local logbook = {}
	for _, id in c.Logbook.ORDER do
		table.insert(logbook, c.Logbook[id].reward)
	end
	local oneTime = 0
	local objectivePool = {}
	for _, id in c.Objectives.ORDER do
		table.insert(objectivePool, c.Objectives[id].reward)
	end
	for v = 1, voyages do
		local roll, crew = rng:NextNumber(), 4
		local acc = 0
		for size, chance in m.crew do
			acc += chance
			if roll <= acc then
				crew = size
				break
			end
		end
		local defId = if unlocked and rng:NextNumber() < m.longShare then "Long" else "Standard"
		local def = c.Voyages[defId]
		local bossSet = bossNightsOf(def)
		local survived, won = 0, false
		local pearls = 0
		for night = 1, def.nights do
			local alive = rng:NextNumber() >= m.dieAtNight(night)
			-- big monsters on this night drop Pearls whether or not the light holds afterwards
			if bossSet[night] then
				for _ = 1, crew do
					if rng:NextNumber() < cfg.BOSS_PEARL_CHANCE and rng:NextInteger(1, crew) == 1 then
						pearls += rng:NextInteger(cfg.BOSS_PEARL_MIN, cfg.BOSS_PEARL_MAX)
					end
				end
			end
			if not alive then
				break
			end
			survived = night
			pearls += cfg.PEARLS_PER_NIGHT or 0 -- banked at dawn
		end
		won = survived == def.nights
		if won then
			pearls += cfg.PEARLS_VICTORY_BONUS or 0
			wins[defId] += 1
			if def.unlocks then
				unlocked = true
			end
		end
		local limit = EconomySim.maxPerVoyage(c, defId, crew)
		bound = math.max(bound, limit)
		if pearls > limit then
			overBound += 1
		end
		perVoyage[v] = pearls
		-- one-time and daily sources (outside the per-voyage bound, both finite or capped per day)
		if #logbook > 0 and v % 3 == 0 then
			local reward = table.remove(logbook, 1) :: number
			oneTime += reward
			total += reward
		end
		if v % m.voyagesPerDay == 0 and rng:NextNumber() < m.objectiveDone then
			local reward = objectivePool[rng:NextInteger(1, #objectivePool)]
			objectives += reward
			total += reward
		end
		total += pearls
		if not voyagesToBuyAll and total >= items + boosts then
			voyagesToBuyAll = v
		end
	end
	local sorted = table.clone(perVoyage)
	table.sort(sorted)
	local sum = 0
	for _, p in perVoyage do
		sum += p
	end
	return {
		voyages = voyages,
		pearls = total,
		perVoyage = {
			mean = sum / voyages,
			p50 = sorted[math.max(1, math.floor(voyages * 0.5))],
			p95 = sorted[math.max(1, math.floor(voyages * 0.95))],
			max = sorted[voyages],
		},
		bound = bound,
		overBound = overBound,
		wins = wins,
		oneTime = oneTime,
		objectives = objectives,
		catalogue = { items = items, boosts = boosts },
		voyagesToBuyAll = voyagesToBuyAll,
	}
end

return EconomySim
