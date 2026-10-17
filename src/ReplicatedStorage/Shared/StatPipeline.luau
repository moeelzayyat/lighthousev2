--!strict
-- StatPipeline (S5.7): the one place a stat's value is worked out, on the server for the voyage and on the
-- client for shop, inventory and bench previews, so a preview always shows the value that will apply.
--
--   Final = clamp((Base + ΣFlat) × (1 + ΣAdditivePct) × ΠMultipliers, Min, Max)
--
-- Every stat has a row in docs/STATS.md (unit, the layers it accepts, its caps). Bases are the owner-approved
-- numbers in Weapons, Items (armor), Upgrades and Config; this module changes none of them.

local Shared = script.Parent
local Config = require(Shared:WaitForChild("Config")) :: any
local Weapons = require(Shared:WaitForChild("Weapons")) :: any
local Items = require(Shared:WaitForChild("Items")) :: any
local Upgrades = require(Shared:WaitForChild("Upgrades")) :: any

local StatPipeline = {}

export type Mods = { flat: { number }?, add: { number }?, mult: { number }? }
export type StatDef = { unit: string, min: number, max: number, flat: boolean?, add: boolean?, mult: boolean? }

-- docs/STATS.md, the rows the game computes today (the other rows get their code with their features)
StatPipeline.STATS = {
	PlayerMaxHealth = { unit = "HP", min = 50, max = 300, flat = true, add = true },
	PlayerArmor = { unit = "damage reduction", min = 0, max = 0.6, flat = true },
	PlayerSpeed = { unit = "studs/s", min = 12, max = 22, add = true }, -- S6.2: merchant speed boost
	ShellGainPct = { unit = "share", min = 0, max = 0.15, flat = true }, -- S6.4: Quartermaster Shell Pouch
	WeaponDamage = { unit = "per hit", min = 1, max = 200, add = true, mult = true },
	WeaponCooldown = { unit = "s", min = 0.2, max = 5, add = true },
	WeaponRange = { unit = "studs", min = 4, max = 100, add = true },
	WeaponHitRadius = { unit = "studs", min = 1, max = 20, add = true },
	WeaponMaxTargets = { unit = "creatures", min = 1, max = 10, flat = true },
	BeamDamageMult = { unit = "×", min = 1, max = 3, mult = true },
	AutoSweepDps = { unit = "DPS", min = 0, max = 30, flat = true },
	MaxFuel = { unit = "fuel", min = 60, max = 200, flat = true, add = true },
	MaxIntegrity = { unit = "integrity", min = 60, max = 250, flat = true, add = true },
	SniperDamage = { unit = "per shot", min = 1, max = 100, add = true }, -- D-044: the sniper tower's rifle
	SniperCooldown = { unit = "s", min = 0.3, max = 5, add = true },
	SniperRange = { unit = "studs", min = 50, max = 300, add = true },
} :: { [string]: StatDef }

local function sum(list: { number }?): number
	local total = 0
	for _, v in list or {} do
		total += v
	end
	return total
end

-- Applies the pipeline to one stat. Errors on an unknown stat or a layer the stat does not accept.
function StatPipeline.compute(statId: string, base: number, mods: Mods?): number
	local def = StatPipeline.STATS[statId]
	assert(def, "StatPipeline: unknown stat " .. tostring(statId))
	local m = mods or {}
	assert(m.flat == nil or def.flat, "StatPipeline: " .. statId .. " takes no Flat layer")
	assert(m.add == nil or def.add, "StatPipeline: " .. statId .. " takes no AdditivePct layer")
	assert(m.mult == nil or def.mult, "StatPipeline: " .. statId .. " takes no Multiplier layer")
	local value = (base + sum(m.flat)) * (1 + sum(m.add))
	for _, x in m.mult or {} do
		value *= x
	end
	return math.clamp(value, def.min, def.max)
end

export type WeaponStats = { damage: number, cooldown: number, range: number, hitRadius: number, maxTargets: number }

-- A weapon's stats as they apply in a voyage (Attack on the server) and as the shop shows them
function StatPipeline.weapon(weaponId: string, mods: { [string]: Mods }?): WeaponStats
	local w = Weapons[weaponId]
	assert(w, "StatPipeline: unknown weapon " .. tostring(weaponId))
	local m = mods or {}
	return {
		damage = StatPipeline.compute("WeaponDamage", w.damage, m.damage),
		cooldown = StatPipeline.compute("WeaponCooldown", w.cooldown, m.cooldown),
		range = StatPipeline.compute("WeaponRange", w.range, m.range),
		hitRadius = StatPipeline.compute("WeaponHitRadius", w.hitRadius, m.hitRadius),
		maxTargets = StatPipeline.compute("WeaponMaxTargets", w.maxTargets, m.maxTargets),
	}
end

export type SniperStats = { damage: number, cooldown: number, range: number }

-- D-044: the sniper tower's rifle as it applies in a voyage (no boost touches it yet)
function StatPipeline.sniper(): SniperStats
	return {
		damage = StatPipeline.compute("SniperDamage", Config.SNIPER_DAMAGE),
		cooldown = StatPipeline.compute("SniperCooldown", Config.SNIPER_COOLDOWN),
		range = StatPipeline.compute("SniperRange", Config.SNIPER_RANGE),
	}
end

export type ArmorStats = { maxHealth: number, damageReduction: number }

-- An armor's stats as they apply to the wearer and as the shop and bag show them
function StatPipeline.armor(itemId: string, mods: { [string]: Mods }?): ArmorStats
	local a = Items[itemId]
	assert(a and a.kind == "Armor", "StatPipeline: unknown armor " .. tostring(itemId))
	local m = mods or {}
	return {
		maxHealth = StatPipeline.compute("PlayerMaxHealth", a.maxHealth, m.maxHealth),
		damageReduction = StatPipeline.compute("PlayerArmor", a.damageReduction, m.damageReduction),
	}
end

-- Crew bench upgrades: the stat each one changes, its value with no ranks, and how a rank enters the pipeline
-- (the rank values themselves stay in Shared/Upgrades)
local UPGRADE_STATS: { [string]: { stat: string, base: () -> number, layer: string } } = {
	LensPower = { stat = "BeamDamageMult", base = function() return 1 end, layer = "mult" },
	FuelTank = { stat = "MaxFuel", base = function() return Config.MAX_FUEL end, layer = "flat" },
	Walls = { stat = "MaxIntegrity", base = function() return Config.MAX_INTEGRITY end, layer = "flat" },
	ClockworkSweep = { stat = "AutoSweepDps", base = function() return 0 end, layer = "flat" },
}
StatPipeline.UPGRADE_STATS = UPGRADE_STATS

-- The value an upgrade's stat has at a rank (0 = not bought); the bench preview and the voyage both use it
function StatPipeline.upgrade(upgradeId: string, rank: number): number
	local spec = UPGRADE_STATS[upgradeId]
	assert(spec and Upgrades[upgradeId], "StatPipeline: unknown upgrade " .. tostring(upgradeId))
	local base = spec.base()
	if rank <= 0 then
		return base
	end
	local level = Upgrades[upgradeId].values[math.min(rank, #Upgrades[upgradeId].values)]
	if spec.layer == "mult" then
		return StatPipeline.compute(spec.stat, base, { mult = { level } })
	end
	return StatPipeline.compute(spec.stat, base, { flat = { level - base } })
end

return StatPipeline
