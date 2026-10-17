--!strict
-- A schema-v2 profile using every field that exists at B1 (Boosts S6.4, Logbook S7.1, Objectives S7.2, Roles and
-- Unlocks.Specialties S7.4, the invite item S7.5). Made-up values; no real player data.
return {
	SchemaVersion = 2,
	CreatedAt = 1760600000,
	LastSeenAt = 1760700000,
	Pearls = 212,
	Owned = { DriftwoodHarpoon = true, OilskinCoat = true, BeamAmber = true, StormHarpoon = true, CoralLance = true, KelpweaveVest = true, BeamSharedLantern = true },
	Counts = { FireShellCrate = 3 },
	Equipped = { Weapon = "CoralLance", Armor = "KelpweaveVest", Beam = "BeamSharedLantern" },
	Stats = { Runs = 41, Victories = 9, BestNight = 7, BestNightLong = 13, NightsSurvived = 220, PlayDays = 12 },
	Logbook = { Creatures = { "RockCrab", "SandSkitter", "SpitterEel" }, Bosses = { "ShipwreckHermit" } },
	Objectives = { DayKey = "2026-10-17", Progress = { DeliverOil = 6 }, Claimed = { ["2026-10-16"] = true } },
	Unlocks = { LongVoyage = true, Specialties = { Harpooner = 1, Keeper = 2 } },
	Grants = { ["v1:night1:1"] = 1760690000, ["logbook:Bosses:1"] = 1760695000 },
	RedeemedCodes = {},
	Settings = { Music = 0.5, Sfx = 1, Shake = false, Rain = true },
	Boosts = { ShellPouch = 3, SeaBoots = 2, SharpSteel = 1 },
	Roles = { BeamKills = 312, WeaponKills = 71, OilDelivered = 40, Repairs = 12 },
}
