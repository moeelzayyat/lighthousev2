--!strict
-- Definitions/Voyages (S2.1, D-003): the voyages a crew can sail. GameState runs one definition per voyage.
--   Standard: 7 nights, big monsters on nights 4 and 7; a win (7 + 5 = 12 Pearls) unlocks the Long Voyage.
--   Long: 13 nights, big monsters on 4, 7, 10, 13 and every night from 8; a win pays 13 + 5 = 18 Pearls.
--   Endless (S3.1b, test only): nights until the light goes out, the same curve and bosses as Long; the night
--   reached is the score. ModeTest gives it to a crew; it is never offered on the crew card.
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
	endless: boolean?, -- no last night: the voyage ends when the light goes out (S3.1b)
	testOnly: boolean?, -- given only by ModeTest, never chosen on the crew card (S3.1b)
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

	Endless = {
		id = "Endless",
		displayName = "Endless Storm",
		short = "until the light goes out",
		nights = 999, -- a cap, never reached: an Endless voyage ends when the light goes out
		bossNights = { 4, 7 },
		bossEveryNightFrom = 8,
		endless = true,
		testOnly = true,
	} :: VoyageDef,
}

return Voyages
