--!strict
-- Definitions/Cosmetics (B1.1, L1.3): the Robux catalogue. LOOKS ONLY. The cosmetics themselves are items in
-- Shared/Items (kind "Cosmetic": beam colours, lamp housings, keeper coats, lanterns, ship flags; owned and equipped
-- like any item, most of them also sold for Pearls). This list says which of them can also be bought with Robux:
-- the price shown and the developer product the owner created in Creator Hub. A product id of 0 means the product
-- does not exist yet, so that item is not offered for Robux. _Registry refuses anything here that is not a cosmetic
-- and any field that is not a price or a product id. PurchaseService grants a bought item through GrantService,
-- once per receipt. Prices: D-030, D-036.
-- ROBUX_ENABLED is the one switch for selling with Robux. It stays false until the owner sets it (or tells Claude
-- to) once the developer products exist; while it is false no purchase is prompted and no receipt is granted.

export type Product = { robux: number, productId: number }

local Cosmetics = {
	ROBUX_ENABLED = false,
	ORDER = {
		"BeamSeaGlass", "BeamMoonlight", "BeamEmber",
		"HousingDriftwood", "HousingBrass", "CoatStormBlue", "CoatKelpGreen",
		"LanternMoth", "LanternTide", "FlagGull", "FlagKraken", "FlagFounder",
	},

	BeamSeaGlass = { robux = 29, productId = 0 } :: Product,
	BeamMoonlight = { robux = 39, productId = 0 } :: Product,
	BeamEmber = { robux = 59, productId = 0 } :: Product,
	HousingDriftwood = { robux = 49, productId = 0 } :: Product,
	HousingBrass = { robux = 99, productId = 0 } :: Product,
	CoatStormBlue = { robux = 59, productId = 0 } :: Product,
	CoatKelpGreen = { robux = 59, productId = 0 } :: Product,
	LanternMoth = { robux = 75, productId = 0 } :: Product,
	LanternTide = { robux = 75, productId = 0 } :: Product,
	FlagGull = { robux = 39, productId = 0 } :: Product,
	FlagKraken = { robux = 99, productId = 0 } :: Product,
	FlagFounder = { robux = 149, productId = 0 } :: Product, -- the supporter item: Robux only (a cosmetic, so allowed)
}

-- The item a developer product buys, or nil
function Cosmetics.itemFor(productId: number): string?
	if productId == 0 then
		return nil
	end
	for _, itemId in Cosmetics.ORDER do
		local p = (Cosmetics :: any)[itemId]
		if p and p.productId == productId then
			return itemId
		end
	end
	return nil
end

-- The product a player can buy this item with right now, or nil
function Cosmetics.productFor(itemId: string): Product?
	local p = (Cosmetics :: any)[itemId]
	if Cosmetics.ROBUX_ENABLED and type(p) == "table" and p.productId > 0 then
		return p
	end
	return nil
end

return Cosmetics
