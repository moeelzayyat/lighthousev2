-- Items: the ONE item catalog. Shop, Inventory, and the server all read from this list.
--
--   kind       "Weapon" (stats in Shared/Weapons), "Armor", "Ammo" (cannon ammo crates), "Material" (loot)
--   category   which Quartermaster shop tab / inventory filter it appears under
--   slot       loadout slot for equippable items: "Primary", "Armor", "Beam", or (L1.3) "Housing", "Coat", "Lantern", "Flag"
--   model      name of the 3D model in ReplicatedStorage.ItemModels (used for icons and previews)
--   price      Pearls to buy from the Quartermaster (nil = not sold)
--   sell       Pearls the Quartermaster pays for one (materials only)
--   maxStack   most a player can hold (stackable items only)
--   strengths / tradeoffs   short lines shown in the detail panels
--   starter    every player owns it from the start
--
-- Rule (from the design document): everything here is EARNED with Pearls. Nothing that
-- affects combat is sold for Robux; Robux will only buy cosmetics.

local Items = {
	SHOP_ORDER = {
		"DriftwoodHarpoon", "StormHarpoon", "FlareGun", "CoralLance", "TidecallerBlades", "WhalerHarpoon",
		"OilskinCoat", "KeepersCoat", "KelpweaveVest", "IronclawPlate",
		"FireShellCrate",
		"CrabClaw", "SeaGlass", "BlackPearl",
		"BeamAmber", "BeamSeaGlass", "BeamMoonlight", "BeamEmber", "BeamSharedLantern", "BeamKeepersGlow",
		"HousingDriftwood", "HousingBrass", "CoatStormBlue", "CoatKelpGreen", "LanternMoth", "LanternTide", "FlagGull", "FlagKraken", "FlagFounder", "FlagRescuer",
	},
	SHOP_CATEGORIES = { "Weapons", "Armor", "Ammunition", "Cosmetics" }, -- loot is sold to the Trader during a voyage, for shells
	TIERS = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }, -- display-only rarity (harbor UI); never changes a price or a stat
	INVENTORY_FILTERS = { "All", "Weapons", "Armor", "Ammunition", "Materials" },
	EXPENSIVE_PRICE = 60, -- owner-approved re-price Oct 12 2026 (was 500 with the old prices) -- purchases at or above this ask for confirmation

	-- WEAPONS (stats live in Shared/Weapons under the same id) -------------
	DriftwoodHarpoon = {
		kind = "Weapon", category = "Weapons", slot = "Primary", model = "DriftwoodHarpoon",
		name = "Driftwood Harpoon",
		tier = "Common", -- display only (harbor UI rarity)
		description = "Your trusty starter. Quick single throws.",
		strengths = "Fast reload, reliable aim",
		tradeoffs = "Low damage; one target at a time",
		starter = true,
	},
	StormHarpoon = {
		kind = "Weapon", category = "Weapons", slot = "Primary", model = "StormHarpoon",
		name = "Storm Harpoon",
		tier = "Uncommon", -- display only (harbor UI rarity)
		description = "Pierces through up to 3 creatures. Great against crab swarms.",
		strengths = "Hits up to 3 creatures per throw",
		tradeoffs = "Same damage per target as the starter",
		price = 30, -- was 400 (owner-approved re-price, launch R8)
	},
	FlareGun = {
		kind = "Weapon", category = "Weapons", slot = "Primary", model = "FlareGun",
		name = "Flare Gun",
		tier = "Uncommon", -- display only (harbor UI rarity)
		description = "Slow, but bursts on a whole group.",
		strengths = "Area blast hits up to 6 creatures",
		tradeoffs = "Slowest reload; weak against a single big target",
		price = 60, -- was 600 (owner-approved re-price, launch R8)
	},
	WhalerHarpoon = {
		kind = "Weapon", category = "Weapons", slot = "Primary", model = "WhalerHarpoon",
		name = "Whaler's Harpoon",
		tier = "Legendary", -- display only (harbor UI rarity)
		description = "Huge single hits for big monsters. Slow to reload, weak against swarms.",
		strengths = "Highest damage per hit; built for big monsters",
		tradeoffs = "Slow reload; only ever hits one creature",
		price = 140, -- was 1500
	},
	CoralLance = { -- S6.4 (D-021)
		kind = "Weapon", category = "Weapons", slot = "Primary", model = "CoralLance",
		name = "Coral Lance",
		tier = "Rare", -- display only (harbor UI rarity)
		description = "A heavy reef-grown spear. Each throw passes through two creatures.",
		strengths = "Hits 2 creatures per throw; more damage per hit than the Storm Harpoon",
		tradeoffs = "Slower reload",
		price = 90,
	},
	TidecallerBlades = { -- S6.4 (D-021): the permanent Orbit weapon
		kind = "Weapon", category = "Weapons", slot = "Primary", model = "TidecallerBlades",
		name = "Tidecaller Blades",
		tier = "Epic", -- display only (harbor UI rarity)
		description = "Three blades circle you and cut nearby creatures. Nothing to aim.",
		strengths = "No aiming: great on a phone; cuts up to 3 creatures around you",
		tradeoffs = "No thrown weapon while equipped; only reaches what is close",
		price = 110,
	},

	-- ARMOR (one equipped at a time) ---------------------------------------
	OilskinCoat = {
		kind = "Armor", category = "Armor", slot = "Armor", model = "OilskinCoat",
		name = "Oilskin Coat",
		tier = "Common", -- display only (harbor UI rarity)
		description = "Standard keeper's raincoat.",
		strengths = "Light and free",
		tradeoffs = "No damage protection",
		starter = true,
		maxHealth = 100,
		damageReduction = 0,
	},
	KeepersCoat = {
		kind = "Armor", category = "Armor", slot = "Armor", model = "KeepersCoat",
		name = "Keeper's Greatcoat",
		tier = "Uncommon", -- display only (harbor UI rarity)
		description = "Heavy wool and leather. More health, takes less damage.",
		strengths = "+40 health, 15% less damage",
		tradeoffs = "Costs Pearls you could spend on weapons",
		price = 35, -- was 500
		maxHealth = 140,
		damageReduction = 0.15,
	},
	KelpweaveVest = { -- S6.4 (D-021)
		kind = "Armor", category = "Armor", slot = "Armor", model = "KelpweaveVest",
		name = "Kelpweave Vest",
		tier = "Rare", -- display only (harbor UI rarity)
		description = "Woven sea kelp over a cork lining. Between the greatcoat and the plate.",
		strengths = "+60 health, 20% less damage",
		tradeoffs = "Costs more than the greatcoat",
		price = 80,
		maxHealth = 160,
		damageReduction = 0.2,
	},
	IronclawPlate = {
		kind = "Armor", category = "Armor", slot = "Armor", model = "IronclawPlate",
		name = "Ironclaw Plate",
		tier = "Legendary", -- display only (harbor UI rarity)
		description = "Forged from giant crab shell. For facing the big ones.",
		strengths = "+90 health, 30% less damage",
		tradeoffs = "Very expensive",
		price = 140, -- was 1500
		maxHealth = 190,
		damageReduction = 0.3,
	},

	-- CANNON AMMO (used automatically when you reload a cannon) ----------
	FireShellCrate = {
		kind = "Ammo", category = "Ammunition", model = "FireShellCrate",
		name = "Fire Shell Crate",
		tier = "Common", -- display only (harbor UI rarity)
		description = "Loads a cannon with fire shells: harder hits, bigger blasts. No oil needed.",
		strengths = "x1.6 damage, x1.4 blast, no oil run",
		tradeoffs = "Costs Pearls every time; 10 shots per crate",
		price = 8, -- was 60 (owner-approved re-price, launch R8)
		maxStack = 20,
		ammoType = "FireShell",
	},

	-- LOOT (from creatures). Run-scoped: cleared every voyage, like shells. Sold to the Trader for shells.
	CrabClaw = {
		kind = "Material", category = "Materials", model = "CrabClaw",
		name = "Crab Claw",
		description = "A common trophy from Rock Crabs. The Trader buys it for shells.",
		shellValue = 4, -- was 3 (+30% Shells, Oct 12)
		runScoped = true,
		maxStack = 999,
	},
	SeaGlass = {
		kind = "Material", category = "Materials", model = "SeaGlass",
		name = "Sea Glass",
		description = "Smooth, glowing glass. Rare. The Trader pays well for it.",
		shellValue = 33, -- was 25 (+30% Shells, Oct 12)
		runScoped = true,
		maxStack = 999,
	},
	BlackPearl = {
		kind = "Material", category = "Materials", model = "BlackPearl",
		name = "Black Pearl",
		description = "Extremely rare. The Trader pays a fortune in shells for it.",
		shellValue = 130, -- was 100 (+30% Shells, Oct 12)
		runScoped = true,
		maxStack = 999,
	},

	-- Beam colours (launch R15, owner-approved Oct 12 2026): LOOKS ONLY, bought with Pearls.
	-- The lamp shows the current Keeper's colour to the whole crew. No power, no Robux.
	BeamAmber = {
		kind = "Cosmetic", category = "Cosmetics", slot = "Beam",
		name = "Keeper's Amber",
		tier = "Common", -- display only (harbor UI rarity)
		description = "The lighthouse's own warm light.",
		strengths = "Shown to the crew while you hold the lamp",
		tradeoffs = "Looks only: no power",
		starter = true,
		beamColor = { 255, 226, 150 },
	},
	BeamSeaGlass = {
		kind = "Cosmetic", category = "Cosmetics", slot = "Beam",
		name = "Sea Glass Beam",
		tier = "Uncommon", -- display only (harbor UI rarity)
		description = "Pale green light, ground from sea glass lenses.",
		strengths = "Shown to the crew while you hold the lamp",
		tradeoffs = "Looks only: no power",
		price = 25,
		beamColor = { 150, 236, 206 },
	},
	BeamMoonlight = {
		kind = "Cosmetic", category = "Cosmetics", slot = "Beam",
		name = "Moonlight Beam",
		tier = "Uncommon", -- display only (harbor UI rarity)
		description = "A cold, silver-blue light for the darkest nights.",
		strengths = "Shown to the crew while you hold the lamp",
		tradeoffs = "Looks only: no power",
		price = 40,
		beamColor = { 196, 218, 255 },
	},
	BeamEmber = {
		kind = "Cosmetic", category = "Cosmetics", slot = "Beam",
		name = "Ember Beam",
		tier = "Uncommon", -- display only (harbor UI rarity)
		description = "Deep orange light, like coals in the keeper's stove.",
		strengths = "Shown to the crew while you hold the lamp",
		tradeoffs = "Looks only: no power",
		price = 60,
		beamColor = { 255, 152, 92 },
	},
	-- S7.5: never sold; given to both players when someone they invited shares a voyage with them (InviteService)
	BeamSharedLantern = {
		kind = "Cosmetic", category = "Cosmetics", slot = "Beam",
		name = "Shared Lantern",
		tier = "Rare", -- display only (harbor UI rarity)
		description = "A warm two-tone light, kept by keepers who brought a friend aboard.",
		strengths = "Shown to the crew while you hold the lamp",
		tradeoffs = "Looks only: no power. Earned by sailing with a friend you invited",
		reward = "invite",
		beamColor = { 255, 200, 120 },
	},
	-- L1.4: never sold; given by a creator code (Definitions/Codes, CodeService)
	BeamKeepersGlow = {
		kind = "Cosmetic", category = "Cosmetics", slot = "Beam",
		name = "Keeper's Glow",
		tier = "Rare", -- display only (harbor UI rarity)
		description = "A soft sea-green light, shared by the keepers who follow a lighthouse creator.",
		strengths = "Shown to the crew while you hold the lamp",
		tradeoffs = "Looks only: no power. Earned with a creator code",
		reward = "code",
		beamColor = { 140, 235, 200 },
	},
	-- L1.3: lamp housings, keeper coats, lanterns and ship flags. LOOKS ONLY. Bought with Pearls here; most can also
	-- be bought with Robux (Definitions/Cosmetics). `color` tints the housing round the lamp while you hold it, the
	-- armor you wear (coats), the lantern at your hip, or the ship's flag (the first keeper in the server with one).
	HousingDriftwood = {
		kind = "Cosmetic", category = "Cosmetics", slot = "Housing",
		name = "Driftwood Housing",
		tier = "Uncommon", -- display only (harbor UI rarity)
		description = "A lamp housing pieced together from the beach.",
		strengths = "Shown round the lamp while you hold it",
		tradeoffs = "Looks only: no power",
		price = 40,
		color = { 150, 115, 80 },
	},
	HousingBrass = {
		kind = "Cosmetic", category = "Cosmetics", slot = "Housing",
		name = "Polished Brass Housing",
		tier = "Rare", -- display only (harbor UI rarity)
		description = "Brass that catches the beam on the darkest night.",
		strengths = "Shown round the lamp while you hold it",
		tradeoffs = "Looks only: no power",
		price = 80,
		color = { 205, 165, 80 },
	},
	CoatStormBlue = {
		kind = "Cosmetic", category = "Cosmetics", slot = "Coat",
		name = "Storm Blue Coat",
		tier = "Uncommon", -- display only (harbor UI rarity)
		description = "A keeper's coat dyed the colour of the storm.",
		strengths = "Worn over your armor",
		tradeoffs = "Looks only: no power. Your armor's protection is unchanged",
		price = 50,
		color = { 60, 90, 150 },
	},
	CoatKelpGreen = {
		kind = "Cosmetic", category = "Cosmetics", slot = "Coat",
		name = "Kelp Green Coat",
		tier = "Uncommon", -- display only (harbor UI rarity)
		description = "Sea-green wool, smelling faintly of the tide.",
		strengths = "Worn over your armor",
		tradeoffs = "Looks only: no power. Your armor's protection is unchanged",
		price = 50,
		color = { 70, 125, 85 },
	},
	LanternMoth = {
		kind = "Cosmetic", category = "Cosmetics", slot = "Lantern",
		name = "Moth Lantern",
		tier = "Uncommon", -- display only (harbor UI rarity)
		description = "A hand lantern with a warm, papery glow.",
		strengths = "Carried at your hip",
		tradeoffs = "Looks only: no power, and it lights nothing",
		price = 60,
		color = { 240, 220, 170 },
	},
	LanternTide = {
		kind = "Cosmetic", category = "Cosmetics", slot = "Lantern",
		name = "Tide Lantern",
		tier = "Uncommon", -- display only (harbor UI rarity)
		description = "Blue glass that glows like the sea at night.",
		strengths = "Carried at your hip",
		tradeoffs = "Looks only: no power, and it lights nothing",
		price = 60,
		color = { 110, 180, 230 },
	},
	FlagGull = {
		kind = "Cosmetic", category = "Cosmetics", slot = "Flag",
		name = "Gull Flag",
		tier = "Uncommon", -- display only (harbor UI rarity)
		description = "Harbour white, for the ship's mast.",
		strengths = "Flown from the ship's mast",
		tradeoffs = "Looks only: no power. The ship flies the flag of the first keeper in the server who has one",
		price = 30,
		color = { 230, 235, 245 },
	},
	FlagKraken = {
		kind = "Cosmetic", category = "Cosmetics", slot = "Flag",
		name = "Kraken Flag",
		tier = "Rare", -- display only (harbor UI rarity)
		description = "Black as the deep: for crews who have seen it.",
		strengths = "Flown from the ship's mast",
		tradeoffs = "Looks only: no power. The ship flies the flag of the first keeper in the server who has one",
		price = 90,
		color = { 40, 40, 55 },
	},
	-- the supporter item: Robux only (a cosmetic, so allowed); listed in Definitions/Cosmetics
	FlagFounder = {
		kind = "Cosmetic", category = "Cosmetics", slot = "Flag",
		name = "Founder's Flag",
		tier = "Legendary", -- display only (harbor UI rarity)
		description = "Gold on the mast, for the keepers who helped relight the lighthouse.",
		strengths = "Flown from the ship's mast",
		tradeoffs = "Looks only: no power. The supporter item, bought with Robux",
		reward = "supporter",
		color = { 255, 200, 90 },
	},
	-- LO.3: earned once in the Shipwreck Rescue event (every castaway saved in one voyage); never sold
	FlagRescuer = {
		kind = "Cosmetic", category = "Cosmetics", slot = "Flag",
		name = "Rescuer's Flag",
		tier = "Epic", -- display only (harbor UI rarity)
		description = "Sewn from the wreck's own sail by the castaways you carried home.",
		strengths = "Flown from the ship's mast",
		tradeoffs = "Looks only: no power. Earned in the Shipwreck Rescue event",
		reward = "event",
		color = { 196, 70, 58 },
	},
}

return Items
