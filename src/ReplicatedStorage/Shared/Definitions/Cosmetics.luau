--!strict
-- Definitions/Cosmetics (B1.1, L1.3): the Robux catalogue. LOOKS ONLY. The cosmetics themselves are items in
-- Shared/Items (kind "Cosmetic": beam colours, lamp housings, keeper coats, lanterns, ship flags; owned and equipped
-- like any item, most of them also sold for Pearls). This list says which of them can also be bought with Robux:
-- the price shown and the developer product the owner created in Creator Hub. A product id of 0 means the product
-- does not exist yet, so that item is not offered for Robux. _Registry refuses anything here that is not a cosmetic
-- and any field that is not a price or a product id. PurchaseService grants a bought item through GrantService,
-- once per receipt. Prices: D-030, D-036.
-- ROBUX_ENABLED is the one switch for selling with Robux; while it is false no purchase is prompted and no receipt
-- is granted. The owner switched it on in the thread on 2026-10-17 ("switch on Robux sales"); an item is still only
-- for sale once its productId is set.

export type Product = { robux: number, productId: number }

local Cosmetics = {
	ROBUX_ENABLED = true,
	ORDER = {
		"BeamSeaGlass", "BeamMoonlight", "BeamEmber",
		"HousingDriftwood", "HousingBrass", "CoatStormBlue", "CoatKelpGreen",
		"LanternMoth", "LanternTide", "FlagGull", "FlagKraken", "FlagFounder",
		"PetPuffin",
	},

	BeamSeaGlass = { robux = 29, productId = 3719247063 } :: Product,
	BeamMoonlight = { robux = 39, productId = 3719247106 } :: Product,
	BeamEmber = { robux = 59, productId = 3719247149 } :: Product,
	HousingDriftwood = { robux = 49, productId = 3719246592 } :: Product,
	HousingBrass = { robux = 99, productId = 3719246658 } :: Product,
	CoatStormBlue = { robux = 59, productId = 3719246701 } :: Product,
	CoatKelpGreen = { robux = 59, productId = 3719246762 } :: Product,
	LanternMoth = { robux = 75, productId = 3719246814 } :: Product,
	LanternTide = { robux = 75, productId = 3719246864 } :: Product,
	FlagGull = { robux = 39, productId = 3719246928 } :: Product,
	FlagKraken = { robux = 99, productId = 3719246972 } :: Product,
	FlagFounder = { robux = 149, productId = 3719247016 } :: Product,
	-- PET.1 (D-051): convenience, so it is also sold for Pearls (Items.PetPuffin); productId 0 until the owner creates
	-- the developer product, so it is not offered for Robux yet
	PetPuffin = { robux = 99, productId = 0 } :: Product, -- the supporter item: Robux only (a cosmetic, so allowed)
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
