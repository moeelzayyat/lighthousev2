--!strict
-- Definitions/Cosmetics (B1.1): the cosmetic catalogue for the beta and relaunch. LOOKS ONLY: nothing here may
-- carry a stat (_Registry refuses one). Each item names its slot, its Pearl price (earnable in play) and, for the
-- Robux catalogue, a suggested Robux price and the developer product id the owner creates in Creator Hub (0 until
-- then). ROBUX_ENABLED stays false until the owner approves L1.3: no code prompts or processes a Robux purchase.
-- Beam colours already live in Shared/Items (bought with Pearls since launch R15); `beams` lists them here so the
-- catalogue is complete. Prices: D-030 (recommendation).

export type CosmeticDef = {
	id: string,
	displayName: string,
	slot: string, -- "Housing" | "Coat" | "Lantern" | "Flag"
	description: string,
	pearls: number?, -- Pearl price (nil = Robux only: allowed for cosmetics)
	robux: number?, -- suggested Robux price (nil = not in the Robux catalogue)
	productId: number, -- the owner's developer product (0 = not created yet)
	color: Color3,
}

local Cosmetics = {
	ROBUX_ENABLED = false, -- owner approval at L1.3; until then the Robux catalogue is a list only
	SLOTS = { "Beam", "Housing", "Coat", "Lantern", "Flag" },
	BEAMS = { "BeamAmber", "BeamSeaGlass", "BeamMoonlight", "BeamEmber", "BeamSharedLantern", "BeamKeepersGlow" }, -- in Shared/Items
	ORDER = { "HousingDriftwood", "HousingBrass", "CoatStormBlue", "CoatKelpGreen", "LanternMoth", "LanternTide", "FlagGull", "FlagKraken", "FlagFounder" },

	HousingDriftwood = { id = "HousingDriftwood", displayName = "Driftwood Housing", slot = "Housing", description = "A lamp housing pieced together from the beach.", pearls = 40, robux = 49, productId = 0, color = Color3.fromRGB(150, 115, 80) } :: CosmeticDef,
	HousingBrass = { id = "HousingBrass", displayName = "Polished Brass Housing", slot = "Housing", description = "Brass that catches the beam on the darkest night.", pearls = 80, robux = 99, productId = 0, color = Color3.fromRGB(205, 165, 80) } :: CosmeticDef,
	CoatStormBlue = { id = "CoatStormBlue", displayName = "Storm Blue Coat", slot = "Coat", description = "A keeper's coat dyed the colour of the storm.", pearls = 50, robux = 59, productId = 0, color = Color3.fromRGB(60, 90, 150) } :: CosmeticDef,
	CoatKelpGreen = { id = "CoatKelpGreen", displayName = "Kelp Green Coat", slot = "Coat", description = "Sea-green wool, smelling faintly of the tide.", pearls = 50, robux = 59, productId = 0, color = Color3.fromRGB(70, 125, 85) } :: CosmeticDef,
	LanternMoth = { id = "LanternMoth", displayName = "Moth Lantern", slot = "Lantern", description = "A hand lantern with paper moths circling the flame.", pearls = 60, robux = 75, productId = 0, color = Color3.fromRGB(240, 220, 170) } :: CosmeticDef,
	LanternTide = { id = "LanternTide", displayName = "Tide Lantern", slot = "Lantern", description = "Blue glass that glows like the sea at night.", pearls = 60, robux = 75, productId = 0, color = Color3.fromRGB(110, 180, 230) } :: CosmeticDef,
	FlagGull = { id = "FlagGull", displayName = "Gull Flag", slot = "Flag", description = "A white gull on harbour blue, for the ship's mast.", pearls = 30, robux = 39, productId = 0, color = Color3.fromRGB(230, 235, 245) } :: CosmeticDef,
	FlagKraken = { id = "FlagKraken", displayName = "Kraken Flag", slot = "Flag", description = "Tentacles on black: for crews who have seen the deep.", pearls = 90, robux = 99, productId = 0, color = Color3.fromRGB(40, 40, 55) } :: CosmeticDef,
	-- Robux only (supporter item: a cosmetic, so allowed under the owner's policy)
	FlagFounder = { id = "FlagFounder", displayName = "Founder's Flag", slot = "Flag", description = "For the keepers who helped relight the lighthouse.", robux = 149, productId = 0, color = Color3.fromRGB(255, 200, 90) } :: CosmeticDef,
}

return Cosmetics
