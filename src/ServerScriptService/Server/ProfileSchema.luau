--!strict
-- ProfileSchema (R1.3, Data domain): the saved profile, schema v2 (architecture §6.1), and its type validation.
-- Pure: no Instances, no DataStores. ProfileStore keeps `Data` in this shape in LighthouseKeepers_PlayerData_v2.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Items = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Items")) :: any
local Boosts = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("Boosts")) :: any

local ProfileSchema = {}

ProfileSchema.VERSION = 2
ProfileSchema.GRANT_TTL_SECONDS = 30 * 86400 -- claim ids are kept 30 days (architecture §6.1)

export type Profile = {
	SchemaVersion: number,
	CreatedAt: number,
	LastSeenAt: number,
	Pearls: number,
	Owned: { [string]: boolean },
	Counts: { [string]: number },
	Equipped: { Weapon: string, Armor: string, Beam: string, Housing: string?, Lantern: string?, Coat: string?, Flag: string? },
	Stats: { Runs: number, Victories: number, BestNight: number, BestNightLong: number, NightsSurvived: number, PlayDays: number },
	Logbook: { [string]: boolean },
	Objectives: { DayKey: string, Progress: { [string]: number }, Claimed: { [string]: boolean } },
	Unlocks: { LongVoyage: boolean, FrostIsle: boolean, Specialties: { [string]: number } }, -- MAP.1: FrostIsle
	Grants: { [string]: number },
	RedeemedCodes: { [string]: boolean },
	Settings: { Music: number, Sfx: number, Shake: boolean, Rain: boolean },
	Boosts: { [string]: number }, -- S6.4 (D-021): Quartermaster boost id -> rank bought; added with default {}
	Roles: { [string]: number }, -- S7.4 (D-028): role counters that earn specialties; added with default {}
	TutorialDone: boolean, -- TUT.1 (D-059): the first-time tutorial was finished or skipped
}

ProfileSchema.DEFAULT_WEAPON = "DriftwoodHarpoon"
ProfileSchema.DEFAULT_ARMOR = "OilskinCoat"
ProfileSchema.DEFAULT_BEAM = "BeamAmber"

local function starters(): { [string]: boolean }
	local owned = {}
	for id, item in Items do
		if type(item) == "table" and item.starter then
			owned[id] = true
		end
	end
	return owned
end

-- A fresh profile (ProfileStore template). Every call returns new tables.
function ProfileSchema.template(): Profile
	return {
		SchemaVersion = ProfileSchema.VERSION,
		CreatedAt = 0,
		LastSeenAt = 0,
		Pearls = 0,
		Owned = starters(),
		Counts = {},
		Equipped = { Weapon = ProfileSchema.DEFAULT_WEAPON, Armor = ProfileSchema.DEFAULT_ARMOR, Beam = ProfileSchema.DEFAULT_BEAM },
		Stats = { Runs = 0, Victories = 0, BestNight = 0, BestNightLong = 0, NightsSurvived = 0, PlayDays = 0 },
		Logbook = {},
		Objectives = { DayKey = "", Progress = {}, Claimed = {} },
		Unlocks = { LongVoyage = false, FrostIsle = false, Specialties = {} },
		Grants = {},
		RedeemedCodes = {},
		Settings = { Music = 1, Sfx = 1, Shake = true, Rain = true },
		Boosts = {},
		Roles = {},
		TutorialDone = false,
	}
end

local function isCount(x: any): boolean
	return type(x) == "number" and x == x and x >= 0 and x < 1e9 and x % 1 == 0
end

-- Checks every field's type, repairs what is wrong with the default and returns what it fixed
-- ("field: reason"). Unknown top-level fields are kept untouched. Mutates and returns `data`.
function ProfileSchema.validate(data: any): (Profile, { string })
	local fixes: { string } = {}
	local t = ProfileSchema.template()
	if type(data) ~= "table" then
		table.insert(fixes, "profile: not a table, replaced")
		return t, fixes
	end
	local function fix(field: string, why: string, value: any)
		table.insert(fixes, field .. ": " .. why)
		return value
	end
	-- timestamps (os.time(), about 1.76e9 in 2026). D-022: they used the count check, whose 1e9 ceiling reset every
	-- real timestamp to 0 on load, so CreatedAt and LastSeenAt never survived a session
	for _, field in { "CreatedAt", "LastSeenAt" } do
		local v = data[field]
		if not (type(v) == "number" and v == v and v >= 0 and v < 1e11 and v % 1 == 0) then
			data[field] = fix(field, "not a whole number", 0)
		end
	end
	if not isCount(data.Pearls) then
		data.Pearls = fix("Pearls", "not a whole number >= 0 (" .. typeof(data.Pearls) .. ")", t.Pearls)
	end
	-- Owned: itemId -> true for items in the catalog; starters always owned
	if type(data.Owned) ~= "table" then
		data.Owned = fix("Owned", "not a table", {})
	end
	for id, v in data.Owned do
		if type(id) ~= "string" or v ~= true or type(Items[id]) ~= "table" then
			data.Owned[id] = nil
			fix("Owned." .. tostring(id), "unknown item or not true", nil)
		end
	end
	for id in t.Owned do
		data.Owned[id] = true
	end
	-- Counts: itemId -> whole number > 0
	if type(data.Counts) ~= "table" then
		data.Counts = fix("Counts", "not a table", {})
	end
	for id, n in data.Counts do
		if type(id) ~= "string" or type(Items[id]) ~= "table" or not isCount(n) or n == 0 then
			data.Counts[id] = nil
			fix("Counts." .. tostring(id), "unknown item or bad count", nil)
		end
	end
	-- Equipped: must be owned
	if type(data.Equipped) ~= "table" then
		data.Equipped = fix("Equipped", "not a table", table.clone(t.Equipped))
	end
	for slot, default in { Weapon = t.Equipped.Weapon, Armor = t.Equipped.Armor, Beam = t.Equipped.Beam } do
		local id = data.Equipped[slot]
		if type(id) ~= "string" or not data.Owned[id] then
			data.Equipped[slot] = fix("Equipped." .. tostring(slot), "missing or not owned", default)
		end
	end
	-- L1.3: cosmetic slots are optional (nil = none); the item must be owned and fit the slot
	for _, slot in { "Housing", "Coat", "Lantern", "Flag", "Pet" } do -- PET.1: Pet
		local id = data.Equipped[slot]
		if id ~= nil then
			local item = type(id) == "string" and data.Owned[id] and Items[id]
			if not item or item.slot ~= slot then
				data.Equipped[slot] = nil
				fix("Equipped." .. tostring(slot), "not owned or not a " .. slot, nil)
			end
		end
	end
	-- Stats
	if type(data.Stats) ~= "table" then
		data.Stats = fix("Stats", "not a table", table.clone(t.Stats))
	end
	for field, default in t.Stats do
		if not isCount(data.Stats[field]) then
			data.Stats[field] = fix("Stats." .. tostring(field), "not a whole number", default)
		end
	end
	-- Tables that only need to exist with the right shape
	for _, field in { "Logbook", "Grants", "RedeemedCodes" } do
		if type(data[field]) ~= "table" then
			data[field] = fix(field, "not a table", {})
		end
	end
	if type(data.Objectives) ~= "table" or type(data.Objectives.Progress) ~= "table" or type(data.Objectives.Claimed) ~= "table" then
		data.Objectives = fix("Objectives", "bad shape", t.Objectives)
	elseif type(data.Objectives.DayKey) ~= "string" then
		data.Objectives.DayKey = fix("Objectives.DayKey", "not a string", "")
	end
	if type(data.Unlocks) ~= "table" or type(data.Unlocks.Specialties) ~= "table" then
		data.Unlocks = fix("Unlocks", "bad shape", t.Unlocks)
	elseif type(data.Unlocks.LongVoyage) ~= "boolean" then
		data.Unlocks.LongVoyage = fix("Unlocks.LongVoyage", "not a boolean", false)
	end
	-- MAP.1 (D-049): a profile saved before Frostbite Isle existed gets it silently (a new field, not a repair):
	-- whoever already won a Standard voyage (LongVoyage) has earned it the same way
	if type(data.Unlocks) == "table" and type(data.Unlocks.FrostIsle) ~= "boolean" then
		data.Unlocks.FrostIsle = data.Unlocks.LongVoyage == true
	end
	if type(data.Settings) ~= "table" then
		data.Settings = fix("Settings", "not a table", table.clone(t.Settings))
	end
	for field, default in t.Settings do
		if type(data.Settings[field]) ~= type(default) then
			data.Settings[field] = fix("Settings." .. tostring(field), "wrong type", default)
		end
	end
	-- Boosts (S6.4): a profile saved before the field existed gets {} silently (a new field, not a repair);
	-- unknown ids and bad ranks are dropped; ranks over the total cap come off the last boosts first
	if data.Boosts == nil then
		data.Boosts = {}
	elseif type(data.Boosts) ~= "table" then
		data.Boosts = fix("Boosts", "not a table", {})
	end
	for id, rank in data.Boosts do
		local def = type(id) == "string" and table.find(Boosts.ORDER, id) and Boosts[id]
		if not def or not isCount(rank) or rank == 0 or rank > #def.prices then
			data.Boosts[id] = nil
			fix("Boosts." .. tostring(id), "unknown boost or bad rank", nil)
		end
	end
	for i = #Boosts.ORDER, 1, -1 do
		local id = Boosts.ORDER[i]
		while (data.Boosts[id] or 0) > 0 and Boosts.total(data.Boosts) > Boosts.TOTAL_CAP + 1e-9 do
			data.Boosts[id] -= 1
			if data.Boosts[id] == 0 then
				data.Boosts[id] = nil
			end
			fix("Boosts." .. id, "over the total cap, lowered", nil)
		end
	end
	-- Roles (S7.4): counters that earn specialties; a profile saved before the field existed gets {} silently
	if data.Roles == nil then
		data.Roles = {}
	elseif type(data.Roles) ~= "table" then
		data.Roles = fix("Roles", "not a table", {})
	end
	for role, n in data.Roles do
		if type(role) ~= "string" or not isCount(n) then
			data.Roles[role] = nil
			fix("Roles." .. tostring(role), "not a whole number", nil)
		end
	end
	-- TUT.1 (D-059): a profile saved before the tutorial existed gets it silently (a new field, not a repair): whoever
	-- already finished a voyage does not need it
	if type(data.TutorialDone) ~= "boolean" then
		data.TutorialDone = type(data.Stats) == "table" and type(data.Stats.Runs) == "number" and data.Stats.Runs > 0
	end
	if data.SchemaVersion ~= ProfileSchema.VERSION then
		data.SchemaVersion = fix("SchemaVersion", "was " .. tostring(data.SchemaVersion), ProfileSchema.VERSION)
	end
	return data :: Profile, fixes
end

return ProfileSchema
