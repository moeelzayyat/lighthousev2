--!strict
-- Definitions/Codes (L1.4): codes a player types in Settings → Codes. Each code pays once per profile (the
-- profile's RedeemedCodes, kept for good) through GrantService. Creator codes give a cosmetic only (never power);
-- promo codes give a few Pearls. A code is matched without case or spaces. `expires` (os.time, UTC) ends a
-- code; nil = no end. The codes and rewards are D-034 (recommendation): the owner renames KEEPER for each
-- creator and adds more rows like it. Checked by _Registry at boot.

export type CodeDef = {
	code: string, -- what the player types: capital letters and digits, at most 32
	kind: string, -- "promo" | "creator"
	reward: { Pearls: number?, Items: { [string]: number }? },
	expires: number?,
	note: string,
}

local Codes = {
	ORDER = { "Lighthouse", "Keeper" },

	Lighthouse = { code = "LIGHTHOUSE", kind = "promo", reward = { Pearls = 10 }, note = "relaunch welcome" } :: CodeDef,
	Keeper = { code = "KEEPER", kind = "creator", reward = { Items = { BeamKeepersGlow = 1 } }, note = "template creator code: one row per creator, each giving the creator beam colour" } :: CodeDef,
}

return Codes
