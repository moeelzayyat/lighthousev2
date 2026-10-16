--!strict
-- MigrationService (R1.3, Data domain): lifts any stored profile to schema v2 with type validation.
-- Pure: no Instances, no DataStores.
--   upgrade(data)  run on every load: v1-shaped tables are converted, everything is validated
--   fromV1(v1)     the v1 -> v2 lift (architecture §6.1). Under D-012 (fresh start) no live path reads the v1
--                  store; this stays tested so an import can be added later without new code.

local ProfileSchema = require(script.Parent.ProfileSchema)

local MigrationService = {}

local V1_FIELDS = {
	version = true,
	pearls = true,
	owned = true,
	counts = true,
	equippedArmor = true,
	equippedWeapon = true,
	equippedBeam = true,
	stats = true,
}

function MigrationService.isV1(data: any): boolean
	return type(data) == "table" and data.SchemaVersion == nil and (data.pearls ~= nil or data.owned ~= nil or data.version == 1)
end

function MigrationService.fromV1(v1: any): (ProfileSchema.Profile, { string })
	local t = ProfileSchema.template()
	if type(v1) ~= "table" then
		return t, { "v1: not a table, fresh profile" }
	end
	local stats = if type(v1.stats) == "table" then v1.stats else {}
	-- v2-only fields start from the template; v1 values are copied over it, then validated
	local data: any = t
	data.Pearls = v1.pearls
	data.Owned = if type(v1.owned) == "table" then table.clone(v1.owned) else nil
	data.Counts = if type(v1.counts) == "table" then table.clone(v1.counts) else nil
	data.Equipped = { Weapon = v1.equippedWeapon, Armor = v1.equippedArmor, Beam = v1.equippedBeam }
	data.Stats.Runs = stats.runs
	data.Stats.Victories = stats.victories
	data.Stats.BestNight = stats.bestNight
	-- unknown v1 fields are carried over unchanged (nothing a player had is silently dropped)
	for key, value in v1 do
		if type(key) == "string" and not V1_FIELDS[key] and data[key] == nil then
			data[key] = value
		end
	end
	local validated, fixes = ProfileSchema.validate(data)
	table.insert(fixes, 1, "migrated v1 -> v2")
	return validated, fixes
end

-- Run on every load. Returns the (possibly replaced) data and what was changed.
function MigrationService.upgrade(data: any): (ProfileSchema.Profile, { string })
	if MigrationService.isV1(data) then
		return MigrationService.fromV1(data)
	end
	return ProfileSchema.validate(data)
end

return MigrationService
