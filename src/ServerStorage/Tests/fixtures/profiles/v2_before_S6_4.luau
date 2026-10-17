--!strict
-- A schema-v2 profile as saved before S6.4 added `Boosts`. Made-up values; no real player data.
return {
	SchemaVersion = 2,
	CreatedAt = 1760600000,
	LastSeenAt = 1760650000,
	Pearls = 64,
	Owned = { DriftwoodHarpoon = true, OilskinCoat = true, BeamAmber = true, StormHarpoon = true },
	Counts = { FireShellCrate = 2 },
	Equipped = { Weapon = "StormHarpoon", Armor = "OilskinCoat", Beam = "BeamAmber" },
	Stats = { Runs = 9, Victories = 1, BestNight = 7, BestNightLong = 0, NightsSurvived = 30, PlayDays = 3 },
	Logbook = {},
	Objectives = { DayKey = "", Progress = {}, Claimed = {} },
	Unlocks = { LongVoyage = true, Specialties = {} },
	Grants = { ["v1:night1:1"] = 1760640000 },
	RedeemedCodes = {},
	Settings = { Music = 1, Sfx = 1, Shake = true, Rain = true },
}
