--!strict
-- _Registry (S5.4): checks every definition catalog at boot. The Definitions domain calls `assertValid`; a bad
-- definition stops the boot with one message that lists every problem ("Items.FlareGun.price: must be a
-- positive number, got -5"), so a broken catalog never reaches players. Pure: no Instances are created and
-- nothing is required except the catalogs themselves (`catalogs()`).

local Registry = {}

export type Catalogs = { [string]: any }

-- The catalogs as the game loads them
function Registry.catalogs(): Catalogs
	local Shared = script.Parent
	return {
		Ammo = require(Shared:WaitForChild("Ammo")) :: any,
		Creatures = require(Shared:WaitForChild("Creatures")) :: any,
		Forecasts = require(Shared:WaitForChild("Forecasts")) :: any,
		Items = require(Shared:WaitForChild("Items")) :: any,
		Upgrades = require(Shared:WaitForChild("Upgrades")) :: any,
		Weapons = require(Shared:WaitForChild("Weapons")) :: any,
		Voyages = require(Shared:WaitForChild("Definitions"):WaitForChild("Voyages")) :: any,
		Merchant = require(Shared:WaitForChild("Definitions"):WaitForChild("Merchant")) :: any, -- S6.2
		Boosts = require(Shared:WaitForChild("Definitions"):WaitForChild("Boosts")) :: any, -- S6.4
		Logbook = require(Shared:WaitForChild("Definitions"):WaitForChild("Logbook")) :: any, -- S7.1
		Objectives = require(Shared:WaitForChild("Definitions"):WaitForChild("Objectives")) :: any, -- S7.2
		Leaderboards = require(Shared:WaitForChild("Definitions"):WaitForChild("Leaderboards")) :: any, -- S7.3
		Specialties = require(Shared:WaitForChild("Definitions"):WaitForChild("Specialties")) :: any, -- S7.4
		Events = require(Shared:WaitForChild("Events")) :: any,
	}
end

-- Builds the list of problems; each check adds "Catalog.id.field: what is wrong"
local function checker()
	local problems: { string } = {}
	local c = {}

	function c.add(where: string, text: string)
		table.insert(problems, where .. ": " .. text)
	end
	local function show(v: any): string
		return if type(v) == "string" then string.format("%q", v) else tostring(v)
	end
	function c.str(where: string, v: any)
		if type(v) ~= "string" or v == "" then
			c.add(where, "must be a non-empty string, got " .. show(v))
		end
	end
	function c.num(where: string, v: any, min: number?, max: number?, integer: boolean?)
		if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then
			c.add(where, "must be a number, got " .. show(v))
		elseif min and v < min then
			c.add(where, string.format("must be at least %s, got %s", tostring(min), tostring(v)))
		elseif max and v > max then
			c.add(where, string.format("must be at most %s, got %s", tostring(max), tostring(v)))
		elseif integer and v % 1 ~= 0 then
			c.add(where, "must be a whole number, got " .. tostring(v))
		end
	end
	function c.pos(where: string, v: any)
		if type(v) ~= "number" or v ~= v or v <= 0 or v == math.huge then
			c.add(where, "must be a positive number, got " .. show(v))
		end
	end
	function c.bool(where: string, v: any, optional: boolean?)
		if not (type(v) == "boolean" or (optional and v == nil)) then
			c.add(where, "must be true or false, got " .. show(v))
		end
	end
	function c.color(where: string, v: any)
		if typeof(v) ~= "Color3" then
			c.add(where, "must be a Color3, got " .. typeof(v))
		end
	end
	function c.oneOf(where: string, v: any, allowed: { string })
		if not table.find(allowed, v) then
			c.add(where, "must be one of " .. table.concat(allowed, "/") .. ", got " .. show(v))
		end
	end
	-- an ordered id list: every id once, and each one defined
	function c.order(where: string, list: any, defs: any)
		if type(list) ~= "table" or #list == 0 then
			c.add(where, "must be a non-empty list of ids")
			return
		end
		local seen = {}
		for i, id in list do
			if seen[id] then
				c.add(where, string.format("duplicate id %s (position %d)", show(id), i))
			end
			seen[id] = true
			if type(defs) == "table" and type(defs[id]) ~= "table" then
				c.add(where, string.format("lists %s, which is not defined", show(id)))
			end
		end
	end
	-- a loot table: a list of { chance = n, ... } whose chances sum to 1
	function c.loot(where: string, list: any)
		if type(list) ~= "table" or #list == 0 then
			c.add(where, "must be a non-empty list of { chance = n } rows")
			return
		end
		local total = 0
		for i, row in list do
			if type(row) ~= "table" or type(row.chance) ~= "number" or row.chance < 0 then
				c.add(where .. "[" .. i .. "]", "must have a chance of 0 or more")
			else
				total += row.chance
			end
		end
		if math.abs(total - 1) > 1e-6 then
			c.add(where, string.format("chances must sum to 1, got %.4f", total))
		end
	end
	-- definitions are the table-valued entries; upper-case keys (ORDER, DEFAULT, SHOP_ORDER...) are settings
	function c.defs(catalog: any): { [string]: any }
		local out = {}
		if type(catalog) == "table" then
			for id, def in catalog do
				if type(id) == "string" and type(def) == "table" and string.upper(id) ~= id then
					out[id] = def
				end
			end
		end
		return out
	end
	-- any definition may carry a `loot` table: it must sum to 1
	function c.anyLoot(name: string, catalog: any)
		for id, def in c.defs(catalog) do
			if def.loot ~= nil then
				c.loot(name .. "." .. id .. ".loot", def.loot)
			end
		end
	end
	return c, problems
end

local RULES: { [string]: (c: any, cat: any, all: Catalogs) -> () } = {}

RULES.Ammo = function(c, Ammo)
	if type(Ammo.DEFAULT) ~= "string" or type(Ammo[Ammo.DEFAULT]) ~= "table" then
		c.add("Ammo.DEFAULT", "must name a defined ammo type")
	end
	for id, a in c.defs(Ammo) do
		local w = "Ammo." .. id
		c.str(w .. ".displayName", a.displayName)
		c.oneOf(w .. ".loadedFrom", a.loadedFrom, { "Oil", "Crate" })
		c.num(w .. ".shotsPerLoad", a.shotsPerLoad, 1, nil, true)
		c.pos(w .. ".damageMultiplier", a.damageMultiplier)
		c.pos(w .. ".splashMultiplier", a.splashMultiplier)
		c.color(w .. ".ballColor", a.ballColor)
		c.color(w .. ".boomColor", a.boomColor)
	end
end

RULES.Creatures = function(c, Creatures)
	for id, d in c.defs(Creatures) do
		local w = "Creatures." .. id
		c.str(w .. ".displayName", d.displayName)
		c.str(w .. ".art", d.art)
		c.pos(w .. ".health", d.health)
		c.pos(w .. ".speed", d.speed)
		c.num(w .. ".beamDamageMult", d.beamDamageMult, 0)
		c.pos(w .. ".bodyRadius", d.bodyRadius)
		c.pos(w .. ".attackRange", d.attackRange)
		c.num(w .. ".playerDamage", d.playerDamage, 0)
		c.pos(w .. ".attackInterval", d.attackInterval)
		c.num(w .. ".slamRadius", d.slamRadius, 0)
		c.num(w .. ".towerDps", d.towerDps, 0)
		c.num(w .. ".cannonDps", d.cannonDps, 0)
		c.pos(w .. ".scale", d.scale)
		c.bool(w .. ".big", d.big)
		c.bool(w .. ".pushable", d.pushable, true)
		c.bool(w .. ".swarm", d.swarm, true)
		-- S6.5: a monster with its own move warns for at least 0.6 s (architecture §14)
		if d.behaviour ~= nil then
			c.oneOf(w .. ".behaviour", d.behaviour, { "spitter", "mine", "ghost", "summoner", "healer" })
			c.num(w .. ".telegraph", d.telegraph, 0.6, 5)
			c.str(w .. ".telegraphSound", d.telegraphSound)
			c.str(w .. ".releaseSound", d.releaseSound)
			if d.behaviour == "spitter" then
				c.pos(w .. ".splashRadius", d.splashRadius)
				c.num(w .. ".towerRange", d.towerRange, 0)
			elseif d.behaviour == "mine" then
				c.pos(w .. ".triggerRadius", d.triggerRadius)
				c.pos(w .. ".blastRadius", d.blastRadius)
			elseif d.behaviour == "ghost" then
				c.num(w .. ".fuelDrain", d.fuelDrain, 0, 50)
			elseif d.behaviour == "summoner" then -- S6.6
				local summoned = Creatures[d.summonKind]
				if type(summoned) ~= "table" or summoned.big or summoned.behaviour == "summoner" then
					c.add(w .. ".summonKind", "must name a small creature that does not summon, got " .. tostring(d.summonKind))
				end
				c.num(w .. ".summonCount", d.summonCount, 1, 5, true)
			elseif d.behaviour == "healer" then -- S6.6
				c.pos(w .. ".healRadius", d.healRadius)
				c.num(w .. ".healShare", d.healShare, 0.01, 1)
			end
		end
		c.bool(w .. ".weaponImmune", d.weaponImmune, true)
		c.bool(w .. ".ignoresPlayers", d.ignoresPlayers, true)
		if d.shape ~= nil then
			c.oneOf(w .. ".shape", d.shape, { "eel", "puffer", "lantern", "witch", "shaman" })
			c.color(w .. ".color", d.color)
		end
		if d.appears ~= nil then
			local a = d.appears
			if type(a) ~= "table" then
				c.add(w .. ".appears", "must be { from, base, every, max }")
			else
				c.num(w .. ".appears.from", a.from, 1, nil, true)
				c.num(w .. ".appears.base", a.base, 0, nil, true)
				c.num(w .. ".appears.every", a.every, 1, nil, true)
				c.num(w .. ".appears.max", a.max, 1, 20, true)
			end
		end
		if d.loot ~= nil and type(d.loot) == "table" then
			for i, row in d.loot do
				if type(row) == "table" and type(row.drops) == "table" then
					for j, drop in row.drops do
						local where = w .. ".loot[" .. i .. "].drops[" .. j .. "]"
						c.oneOf(where .. "[1]", type(drop) == "table" and drop[1] or nil, { "Shells", "CrabClaw", "SeaGlass", "BlackPearl" })
						c.num(where .. "[2]", type(drop) == "table" and drop[2] or nil, 1, nil, true)
						c.num(where .. "[3]", type(drop) == "table" and drop[3] or nil, type(drop) == "table" and drop[2] or 1, nil, true)
					end
				else
					c.add(w .. ".loot[" .. i .. "]", "needs drops = { { kind, min, max } }")
				end
			end
		end
	end
	c.order("Creatures.BIG_POOL", Creatures.BIG_POOL, Creatures)
	for _, id in Creatures.BIG_POOL or {} do
		if type(Creatures[id]) == "table" and Creatures[id].big ~= true then
			c.add("Creatures.BIG_POOL", id .. " is not a big monster")
		end
	end
end

RULES.Forecasts = function(c, Forecasts)
	c.order("Forecasts.ORDER", Forecasts.ORDER, Forecasts)
	for id, f in c.defs(Forecasts) do
		local w = "Forecasts." .. id
		c.str(w .. ".displayName", f.displayName)
		c.str(w .. ".summary", f.summary)
		c.str(w .. ".short", f.short)
		for _, field in { "wideMult", "crabMult", "crabHpMult", "fuelMult" } do
			if f[field] ~= nil then
				c.pos(w .. "." .. field, f[field])
			end
		end
		if not table.find(Forecasts.ORDER or {}, id) then
			c.add(w, "is defined but missing from Forecasts.ORDER")
		end
	end
end

RULES.Items = function(c, Items, all)
	c.order("Items.SHOP_ORDER", Items.SHOP_ORDER, Items)
	local starters: { [string]: string } = {}
	for id, item in c.defs(Items) do
		local w = "Items." .. id
		c.str(w .. ".name", item.name)
		c.str(w .. ".description", item.description)
		c.oneOf(w .. ".kind", item.kind, { "Weapon", "Armor", "Ammo", "Material", "Cosmetic" })
		if item.price ~= nil then
			c.pos(w .. ".price", item.price)
		end
		if item.kind ~= "Material" and item.price == nil and item.starter ~= true then
			c.add(w, "needs a price (or starter = true)")
		end
		if item.starter == true and item.slot then
			if starters[item.slot] then
				c.add(w, "is a second starter for slot " .. item.slot .. " (first: " .. starters[item.slot] .. ")")
			end
			starters[item.slot] = id
		end
		if not table.find(Items.SHOP_ORDER or {}, id) then
			c.add(w, "is defined but missing from Items.SHOP_ORDER")
		end
		if item.kind == "Weapon" then
			c.oneOf(w .. ".slot", item.slot, { "Primary" })
			if type(all.Weapons) == "table" and type(all.Weapons[id]) ~= "table" then
				c.add(w, "is a weapon with no Weapons." .. id .. " stats")
			end
		elseif item.kind == "Armor" then
			c.oneOf(w .. ".slot", item.slot, { "Armor" })
			c.pos(w .. ".maxHealth", item.maxHealth)
			c.num(w .. ".damageReduction", item.damageReduction, 0, 0.9)
		elseif item.kind == "Ammo" then
			c.num(w .. ".maxStack", item.maxStack, 1, nil, true)
			if type(all.Ammo) == "table" and (type(item.ammoType) ~= "string" or type(all.Ammo[item.ammoType]) ~= "table") then
				c.add(w .. ".ammoType", "must name a defined Ammo type, got " .. tostring(item.ammoType))
			end
		elseif item.kind == "Material" then
			c.pos(w .. ".shellValue", item.shellValue)
			c.num(w .. ".maxStack", item.maxStack, 1, nil, true)
		elseif item.kind == "Cosmetic" then
			c.oneOf(w .. ".slot", item.slot, { "Beam" })
			local col = item.beamColor
			if type(col) ~= "table" or #col ~= 3 then
				c.add(w .. ".beamColor", "must be { r, g, b }")
			else
				for i = 1, 3 do
					c.num(w .. ".beamColor[" .. i .. "]", col[i], 0, 255, true)
				end
			end
		end
	end
	for _, slot in { "Primary", "Armor", "Beam" } do
		if not starters[slot] then
			c.add("Items", "has no starter item for slot " .. slot)
		end
	end
end

RULES.Weapons = function(c, Weapons, all)
	for id, wpn in c.defs(Weapons) do
		local w = "Weapons." .. id
		c.str(w .. ".displayName", wpn.displayName)
		c.pos(w .. ".damage", wpn.damage)
		c.pos(w .. ".cooldown", wpn.cooldown)
		c.pos(w .. ".range", wpn.range)
		c.pos(w .. ".hitRadius", wpn.hitRadius)
		c.num(w .. ".maxTargets", wpn.maxTargets, 1, nil, true)
		c.oneOf(w .. ".archetype", wpn.archetype, { "Thrown", "Orbit" }) -- S6.3
		if wpn.archetype == "Orbit" then
			c.num(w .. ".blades", wpn.blades, 1, 6, true)
			c.pos(w .. ".spin", wpn.spin)
		else
			c.oneOf(w .. ".projectile", wpn.projectile, { "spear", "flare" })
		end
		c.color(w .. ".color", wpn.color)
		c.bool(w .. ".voyageOnly", wpn.voyageOnly, true)
		local item = type(all.Items) == "table" and all.Items[id]
		if not wpn.voyageOnly and type(all.Items) == "table" and (type(item) ~= "table" or item.kind ~= "Weapon") then
			c.add(w, "has no Items." .. id .. " entry of kind Weapon")
		end
	end
end

RULES.Upgrades = function(c, Upgrades)
	c.order("Upgrades.ORDER", Upgrades.ORDER, Upgrades)
	for id, u in c.defs(Upgrades) do
		local w = "Upgrades." .. id
		c.str(w .. ".displayName", u.displayName)
		c.str(w .. ".description", u.description)
		if type(u.costs) ~= "table" or #u.costs == 0 then
			c.add(w .. ".costs", "must be a non-empty list")
		elseif type(u.values) ~= "table" or #u.values ~= #u.costs then
			c.add(w .. ".values", "must have one value per cost (" .. #u.costs .. ")")
		else
			for i, cost in u.costs do
				c.pos(w .. ".costs[" .. i .. "]", cost)
				c.num(w .. ".values[" .. i .. "]", u.values[i])
				if i > 1 and type(cost) == "number" and type(u.costs[i - 1]) == "number" and cost < u.costs[i - 1] then
					c.add(w .. ".costs", "must not go down from one level to the next")
				end
			end
		end
	end
	local seen = {}
	for i, evo in Upgrades.EVOLUTIONS or {} do
		local w = "Upgrades.EVOLUTIONS[" .. i .. "]"
		c.str(w .. ".id", evo.id)
		c.str(w .. ".displayName", evo.displayName)
		if type(evo.id) == "string" then
			if seen[evo.id] then
				c.add(w, "duplicate id " .. evo.id)
			end
			seen[evo.id] = true
		end
		if type(evo.needs) ~= "table" or #evo.needs == 0 then
			c.add(w .. ".needs", "must list the upgrades it needs")
		else
			for _, need in evo.needs do
				if type(Upgrades[need]) ~= "table" then
					c.add(w .. ".needs", "lists " .. tostring(need) .. ", which is not an upgrade")
				end
			end
		end
	end
end

RULES.Voyages = function(c, Voyages)
	c.order("Voyages.ORDER", Voyages.ORDER, Voyages)
	if type(Voyages.DEFAULT) ~= "string" or type(Voyages[Voyages.DEFAULT]) ~= "table" then
		c.add("Voyages.DEFAULT", "must name a defined voyage")
	end
	local grants: { [string]: boolean } = {}
	for _, v in c.defs(Voyages) do
		if type(v.unlocks) == "string" then
			grants[v.unlocks] = true
		end
	end
	for id, v in c.defs(Voyages) do
		local w = "Voyages." .. id
		if v.id ~= id then
			c.add(w .. ".id", "must equal its key, got " .. tostring(v.id))
		end
		c.str(w .. ".displayName", v.displayName)
		c.str(w .. ".short", v.short)
		c.num(w .. ".nights", v.nights, 1, nil, true)
		if type(v.bossNights) ~= "table" then
			c.add(w .. ".bossNights", "must be a list of nights")
		else
			local last = 0
			for i, n in v.bossNights do
				c.num(w .. ".bossNights[" .. i .. "]", n, 1, type(v.nights) == "number" and v.nights or nil, true)
				if type(n) == "number" and n <= last then
					c.add(w .. ".bossNights", "must go up night by night")
				end
				last = if type(n) == "number" then n else last
			end
		end
		if v.bossEveryNightFrom ~= nil then
			c.num(w .. ".bossEveryNightFrom", v.bossEveryNightFrom, 1, type(v.nights) == "number" and v.nights or nil, true)
		end
		if v.unlock ~= nil and not grants[v.unlock] then
			c.add(w .. ".unlock", "no voyage grants " .. tostring(v.unlock))
		end
		c.bool(w .. ".endless", v.endless, true)
		c.bool(w .. ".testOnly", v.testOnly, true)
		if v.testOnly and table.find(Voyages.ORDER or {}, id) then
			c.add(w, "is test-only but listed in Voyages.ORDER (the crew card)")
		end
	end
	if type(Voyages.DEFAULT) == "string" and type(Voyages[Voyages.DEFAULT]) == "table" and Voyages[Voyages.DEFAULT].unlock ~= nil then
		c.add("Voyages.DEFAULT", "must not need an unlock")
	end
end

-- S6.2: the island merchant's stock (boosts name a stat the pipeline knows and stay under the voyage cap)
local MERCHANT_STATS = { "WeaponDamage", "PlayerSpeed" }
RULES.Merchant = function(c, Merchant, all)
	c.order("Merchant.ORDER", Merchant.ORDER, Merchant)
	if type(Merchant.BOOST_CAP) ~= "table" then
		c.add("Merchant.BOOST_CAP", "must map a stat to its voyage cap")
	else
		for stat, cap in Merchant.BOOST_CAP do
			if not table.find(MERCHANT_STATS, stat) then
				c.add("Merchant.BOOST_CAP." .. tostring(stat), "is not a stat the merchant can boost")
			end
			c.num("Merchant.BOOST_CAP." .. tostring(stat), cap, 0, 0.5)
		end
	end
	for id, def in c.defs(Merchant) do
		local w = "Merchant." .. id
		if def.id ~= id then
			c.add(w .. ".id", "must equal its key, got " .. tostring(def.id))
		end
		c.str(w .. ".displayName", def.displayName)
		c.str(w .. ".description", def.description)
		c.num(w .. ".price", def.price, 1, 10000, true)
		c.oneOf(w .. ".scope", def.scope, { "player", "crew" })
		c.oneOf(w .. ".effect", def.effect, { "boost", "heal", "shield", "oil", "weapon" })
		if def.limit ~= nil then
			c.num(w .. ".limit", def.limit, 1, 10, true)
		end
		if def.effect == "boost" then
			c.oneOf(w .. ".stat", def.stat, MERCHANT_STATS)
			c.num(w .. ".add", def.add, 0.01, 0.5)
			if type(def.limit) ~= "number" then
				c.add(w .. ".limit", "a boost needs a limit")
			elseif type(Merchant.BOOST_CAP) == "table" and type(def.add) == "number" and def.add * def.limit > (Merchant.BOOST_CAP[def.stat] or 0) + 1e-9 then
				c.add(w, "limit × add is over Merchant.BOOST_CAP." .. tostring(def.stat))
			end
		elseif def.effect == "shield" then
			c.num(w .. ".mult", def.mult, 0, 0.99)
		elseif def.effect == "oil" then
			c.num(w .. ".amount", def.amount, 1, 200)
		elseif def.effect == "weapon" then -- S6.3: a voyage-only Orbit weapon, bought once
			local wpn = type(all.Weapons) == "table" and all.Weapons[def.weapon]
			if type(wpn) ~= "table" or wpn.archetype ~= "Orbit" or not wpn.voyageOnly then
				c.add(w .. ".weapon", "must name a voyage-only Orbit weapon, got " .. tostring(def.weapon))
			end
			if def.limit ~= 1 then
				c.add(w .. ".limit", "a weapon is bought once a voyage (limit = 1)")
			end
		end
		if not table.find(Merchant.ORDER or {}, id) then
			c.add(w, "is not listed in Merchant.ORDER")
		end
	end
end

-- S6.4: the Quartermaster's permanent boosts (small steps, a total cap, rising prices)
RULES.Boosts = function(c, Boosts)
	c.order("Boosts.ORDER", Boosts.ORDER, Boosts)
	c.num("Boosts.TOTAL_CAP", Boosts.TOTAL_CAP, 0.01, 0.15)
	for id, def in c.defs(Boosts) do
		local w = "Boosts." .. id
		if def.id ~= id then
			c.add(w .. ".id", "must equal its key, got " .. tostring(def.id))
		end
		c.str(w .. ".displayName", def.displayName)
		c.str(w .. ".description", def.description)
		c.oneOf(w .. ".stat", def.stat, { "ShellGainPct", "PlayerSpeed", "WeaponDamage" })
		c.num(w .. ".step", def.step, 0.005, 0.05)
		if type(def.prices) ~= "table" or #def.prices == 0 then
			c.add(w .. ".prices", "must list one Pearl price per rank")
		else
			local last = 0
			for i, price in def.prices do
				c.num(w .. ".prices[" .. i .. "]", price, 1, 1000, true)
				if type(price) == "number" and price < last then
					c.add(w .. ".prices", "must not go down rank by rank")
				end
				last = if type(price) == "number" then price else last
			end
		end
		if not table.find(Boosts.ORDER or {}, id) then
			c.add(w, "is not listed in Boosts.ORDER")
		end
	end
end

-- S7.1: the logbook's categories (their entries come from the other catalogs)
RULES.Logbook = function(c, Logbook)
	c.order("Logbook.ORDER", Logbook.ORDER, Logbook)
	for id, def in c.defs(Logbook) do
		local w = "Logbook." .. id
		if def.id ~= id then
			c.add(w .. ".id", "must equal its key, got " .. tostring(def.id))
		end
		c.oneOf(w .. ".id", id, { "Creatures", "Bosses", "Evolutions", "Forecasts" })
		c.str(w .. ".displayName", def.displayName)
		c.str(w .. ".how", def.how)
		c.num(w .. ".reward", def.reward, 0, 100, true)
	end
end

-- S7.2: the daily objective pool (each counts one bus event; no streak fields exist to check)
RULES.Objectives = function(c, Objectives)
	c.order("Objectives.ORDER", Objectives.ORDER, Objectives)
	for id, def in c.defs(Objectives) do
		local w = "Objectives." .. id
		if def.id ~= id then
			c.add(w .. ".id", "must equal its key, got " .. tostring(def.id))
		end
		c.str(w .. ".displayName", def.displayName)
		c.oneOf(w .. ".event", def.event, { "Refuelled", "NightSurvived", "CannonBuilt", "TowerRepaired", "CreatureKilled" })
		c.num(w .. ".target", def.target, 1, 1000, true)
		c.num(w .. ".reward", def.reward, 0, 20, true)
		c.bool(w .. ".reach", def.reach, true)
	end
end

-- S7.3: the harbor boards
RULES.Leaderboards = function(c, Leaderboards)
	c.order("Leaderboards.ORDER", Leaderboards.ORDER, Leaderboards)
	c.num("Leaderboards.TOP", Leaderboards.TOP, 1, 10, true)
	c.num("Leaderboards.FLUSH_SECONDS", Leaderboards.FLUSH_SECONDS, 5, 60)
	for id, def in c.defs(Leaderboards) do
		local w = "Leaderboards." .. id
		if def.id ~= id then
			c.add(w .. ".id", "must equal its key, got " .. tostring(def.id))
		end
		c.str(w .. ".title", def.title)
		c.str(w .. ".store", def.store)
		c.oneOf(w .. ".kind", def.kind, { "best", "weekly" })
		if def.kind == "best" then
			c.oneOf(w .. ".voyage", def.voyage, { "Standard", "Long", "Endless" })
		end
	end
end

-- S7.4: specialties (earned from role counters; small steps; a total cap)
RULES.Specialties = function(c, Specialties)
	c.order("Specialties.ORDER", Specialties.ORDER, Specialties)
	c.num("Specialties.TOTAL_CAP", Specialties.TOTAL_CAP, 0.01, 0.15)
	for id, def in c.defs(Specialties) do
		local w = "Specialties." .. id
		if def.id ~= id then
			c.add(w .. ".id", "must equal its key, got " .. tostring(def.id))
		end
		c.str(w .. ".displayName", def.displayName)
		c.str(w .. ".bonus", def.bonus)
		c.oneOf(w .. ".role", def.role, { "BeamKills", "WeaponKills", "OilDelivered", "Repairs" })
		c.num(w .. ".step", def.step, 0.005, 0.05)
		if type(def.thresholds) ~= "table" or #def.thresholds == 0 then
			c.add(w .. ".thresholds", "must list the count for each rank")
		else
			local last = 0
			for i, need in def.thresholds do
				c.num(w .. ".thresholds[" .. i .. "]", need, 1, nil, true)
				if type(need) == "number" and need <= last then
					c.add(w .. ".thresholds", "must go up rank by rank")
				end
				last = if type(need) == "number" then need else last
			end
		end
	end
end

RULES.Events = function(c, Events)
	for name, schema in Events do
		if type(schema) ~= "table" then
			c.add("Events." .. tostring(name), "must be a field -> type table")
		else
			for field, kind in schema do
				local base = if type(kind) == "string" and string.sub(kind, -1) == "?" then string.sub(kind, 1, -2) else kind
				if not table.find({ "number", "string", "boolean", "table" }, base) then
					c.add("Events." .. name .. "." .. tostring(field), "type must be number/string/boolean/table (optional with ?), got " .. tostring(kind))
				end
			end
		end
	end
end

-- Every problem in every catalog (empty when all is well), in a stable order
function Registry.check(all: Catalogs): { string }
	local c, problems = checker()
	local names = {}
	for name in all do
		table.insert(names, name)
	end
	table.sort(names)
	for _, name in names do
		local rule = RULES[name]
		local cat = all[name]
		if type(cat) ~= "table" then
			c.add(name, "catalog is missing")
		elseif rule then
			local ok, err = pcall(rule, c, cat, all)
			if not ok then
				c.add(name, "could not be checked: " .. tostring(err))
			end
			if name ~= "Events" then
				c.anyLoot(name, cat)
			end
		else
			c.add(name, "has no registry rules")
		end
	end
	table.sort(problems)
	return problems
end

-- How many definitions were checked (for the boot log)
function Registry.count(all: Catalogs): number
	local n = 0
	for name, cat in all do
		if name ~= "Events" and type(cat) == "table" then
			for id, def in cat do
				if type(id) == "string" and type(def) == "table" and string.upper(id) ~= id then
					n += 1
				end
			end
		end
	end
	return n
end

-- Stops the boot with every problem listed, or returns the number of definitions checked
function Registry.assertValid(all: Catalogs?): number
	local catalogs = all or Registry.catalogs()
	local problems = Registry.check(catalogs)
	if #problems > 0 then
		error(string.format("Definitions: %d problem%s; the server will not start until they are fixed:\n- %s", #problems, if #problems == 1 then "" else "s", table.concat(problems, "\n- ")), 0)
	end
	return Registry.count(catalogs)
end

return Registry
