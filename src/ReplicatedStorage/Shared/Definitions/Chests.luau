--!strict
-- Chests (CHEST.1, D-053): treasure chests for showing off (owner's idea, 2026-10-19, after a playtester's note
-- that Roblox players love to show off rare things).
--   * Earned only, never sold: a crew that beats the Kraken (Config.FINAL_BOSS) gets one Kraken Chest each,
--     at most one a day (UTC) per keeper, held up to `maxHeld`. HARD RULE 8: no paid random crates.
--   * Cosmetics and Pearls only, never power. The rare finds exist only in the chest.
--   * The odds are shown on the chest in the BAG. No timer: the next chest simply comes with the next Kraken
--     beaten on another day.
--   * A cosmetic you already own turns into `dupPearls` Pearls.
--   * Epic and Legendary finds are announced to the whole server.
-- `loot` rows are checked by _Registry (chances sum to 1; every item exists, is chest-only and has no power).

local Chests = {}

export type Row = { item: string?, pearls: number?, dupPearls: number?, chance: number, tier: string }
export type Chest = { name: string, maxHeld: number, loot: { Row } }

Chests.ORDER = { "KrakenChest" }

Chests.KrakenChest = {
	name = "Kraken Chest",
	maxHeld = 5,
	loot = {
		{ pearls = 25, chance = 0.60, tier = "Common" },
		{ item = "BeamAbyss", dupPearls = 40, chance = 0.22, tier = "Rare" },
		{ item = "CoatKrakenInk", dupPearls = 60, chance = 0.12, tier = "Epic" },
		{ item = "HousingLeviathan", dupPearls = 80, chance = 0.05, tier = "Epic" },
		{ item = "PetGoldenPuffin", dupPearls = 150, chance = 0.01, tier = "Legendary" },
	},
} :: Chest

-- The UTC day a chest is earned on ("2026-10-19"): one chest a day per keeper
function Chests.dayKey(t: number): string
	return os.date("!%Y-%m-%d", t) :: string
end

-- The row a roll in [0, 1) lands on
function Chests.roll(chest: Chest, r: number): Row
	local sum = 0
	for _, row in chest.loot do
		sum += row.chance
		if r < sum then
			return row
		end
	end
	return chest.loot[#chest.loot]
end

return Chests
