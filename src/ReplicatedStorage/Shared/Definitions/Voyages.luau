--!strict
-- Definitions/Voyages (S2.1, D-003): the voyages a crew can sail. GameState runs one definition per voyage.
--   Standard: 7 nights, big monsters on nights 4 and 7; a win (7 + 5 = 12 Pearls) unlocks the Long Voyage.
--   Long: 13 nights, big monsters on 4, 7, 10, 13 and every night from 8; a win pays 13 + 5 = 18 Pearls.
-- Validated by VoyageDefinitionsSpec today and by _Registry at boot from S5.4.

export type VoyageDef = {
	id: string,
	displayName: string,
	short: string,
	nights: number,
	bossNights: { number },
	bossEveryNightFrom: number?, -- every night from this one to the last also has a big monster
	unlock: string?, -- a crew member needs Unlocks[unlock] to choose it
	unlocks: string?, -- a win grants Unlocks[unlocks]
}

local Voyages = {
	ORDER = { "Standard", "Long" },
	DEFAULT = "Standard",

	Standard = {
		id = "Standard",
		displayName = "Standard Voyage",
		short = "7 nights",
		nights = 7,
		bossNights = { 4, 7 },
		unlocks = "LongVoyage",
	} :: VoyageDef,

	Long = {
		id = "Long",
		displayName = "Long Voyage",
		short = "13 nights",
		nights = 13,
		bossNights = { 4, 7, 10, 13 },
		bossEveryNightFrom = 8,
		unlock = "LongVoyage",
	} :: VoyageDef,
}

return Voyages
