--!strict
-- v1 profile fixtures (the flat LighthouseKeepers_PlayerData_v1 shape written by the pre-R1.3 PlayerData).
-- Made-up values; no real player data.
return {
	full = {
		version = 1,
		pearls = 37,
		owned = { DriftwoodHarpoon = true, OilskinCoat = true, BeamAmber = true, StormHarpoon = true },
		counts = { FireShellCrate = 3 },
		equippedArmor = "OilskinCoat",
		equippedWeapon = "StormHarpoon",
		equippedBeam = "BeamAmber",
		stats = { runs = 12, victories = 2, bestNight = 13 },
	},
	-- an Oct-11 save: no equippedBeam, no stats.victories
	missingFields = {
		version = 1,
		pearls = 5,
		owned = { DriftwoodHarpoon = true, OilskinCoat = true },
		counts = {},
		equippedArmor = "OilskinCoat",
		equippedWeapon = "DriftwoodHarpoon",
		stats = { runs = 1, bestNight = 2 },
	},
	stringPearls = {
		version = 1,
		pearls = "25",
		owned = { DriftwoodHarpoon = true, OilskinCoat = true },
		counts = { FireShellCrate = -2, NoSuchItem = 4 },
		equippedArmor = "OilskinCoat",
		equippedWeapon = "GoldenHarpoonNotOwned",
		equippedBeam = "BeamAmber",
		stats = { runs = "x", victories = 0, bestNight = 3 },
	},
	unknownFields = {
		version = 1,
		pearls = 9,
		owned = { DriftwoodHarpoon = true, OilskinCoat = true },
		counts = {},
		equippedArmor = "OilskinCoat",
		equippedWeapon = "DriftwoodHarpoon",
		equippedBeam = "BeamAmber",
		stats = { runs = 4, victories = 0, bestNight = 5 },
		futureThing = { a = 1 },
	},
}
