--!strict
-- ItemIcons (ICON1): the picture for each item, upgrade and menu spot, by id (Shared/Items, Definitions/Merchant,
-- Upgrades, Definitions/Boosts ids, plus Codes, LogSummary, Salvage and Evolution). Sources: assets/ART_SOURCES.md.
-- UI/Tiles shows the picture on shop, workbench, Trader and BAG tiles and in their detail panes; an id with no
-- entry keeps its 3D preview or glyph. Uploaded from DEV Studio on 2026-10-18 (owner's account, owner's OK).

local ItemIcons: { [string]: string } = {
	-- weapons (Claude-drawn)
	DriftwoodHarpoon = "rbxassetid://129043938053690",
	StormHarpoon = "rbxassetid://72593835839775",
	FlareGun = "rbxassetid://120317518318819",
	WhalerHarpoon = "rbxassetid://102524032311475",
	CoralLance = "rbxassetid://130837359535096",
	ChainHook = "rbxassetid://115967038527506", -- WPN.1 (drawn)
	NetLauncher = "rbxassetid://87999335166597", -- WPN.1 (drawn)
	LanternBomb = "rbxassetid://116793316938234", -- WPN.1 (drawn)
	TidecallerBlades = "rbxassetid://76994631120741", -- BLADE1: Claude-built cutlass render, tide glow
	-- armor and ammo (Claude-drawn)
	OilskinCoat = "rbxassetid://114074436530125",
	KeepersCoat = "rbxassetid://131656108776329", -- ICON3: Fancy GUI Kit chestplate (purple) (owner's pick)
	KelpweaveVest = "rbxassetid://124053449421528", -- ICON3: Fancy GUI Kit chestplate (green) (owner's pick)
	IronclawPlate = "rbxassetid://137830247927584", -- ICON3: Fancy GUI Kit helmet (red) (owner's pick)
	FireShellCrate = "rbxassetid://76691933271523",
	-- loot (Claude-drawn)
	CrabClaw = "rbxassetid://121044171653520",
	SeaGlass = "rbxassetid://89799167872846",
	BlackPearl = "rbxassetid://102509802032581",
	-- cosmetics (Claude-drawn)
	BeamAmber = "rbxassetid://119109547863812", -- ICON3: Fancy GUI Kit gem (yellow) (owner's pick)
	BeamSeaGlass = "rbxassetid://109723220449796", -- ICON3: Fancy GUI Kit gem (green) (owner's pick)
	BeamMoonlight = "rbxassetid://111225726755713", -- ICON3: Fancy GUI Kit gem (blue) (owner's pick)
	BeamEmber = "rbxassetid://87696380334290", -- ICON3: Fancy GUI Kit gem (red) (owner's pick)
	BeamSharedLantern = "rbxassetid://83228195674142",
	BeamKeepersGlow = "rbxassetid://96464902613251",
	HousingDriftwood = "rbxassetid://75465142387655",
	HousingBrass = "rbxassetid://94796303291915",
	CoatStormBlue = "rbxassetid://110363693204788",
	CoatKelpGreen = "rbxassetid://132502189617087",
	LanternMoth = "rbxassetid://71280815821669", -- ICON3: RPG Craft Resources 4053 (owner's pick)
	LanternTide = "rbxassetid://84668867223781", -- ICON3: RPG Craft Resources 4054 (owner's pick)
	FlagGull = "rbxassetid://97803221222199",
	FlagKraken = "rbxassetid://100752905653856",
	FlagFounder = "rbxassetid://98378099554182",
	FlagRescuer = "rbxassetid://73939053590853",
	-- the Trader's island stock (Claude-drawn)
	OrbitingBlades = "rbxassetid://84779757358778", -- BLADE1: Claude-built cutlass render, sea glow
	DamageBoost = "rbxassetid://91291437009736",
	SpeedBoost = "rbxassetid://73509206717343",
	Heal = "rbxassetid://113402768992113",
	OilBundle = "rbxassetid://90694405901185",
	TowerShield = "rbxassetid://116118202435402",
	-- workbench upgrades and evolutions (Fancy GUI Kit, Polyperfect)
	LensPower = "rbxassetid://133499829500810",
	FuelTank = "rbxassetid://85759209785678",
	Walls = "rbxassetid://80888825885313",
	ClockworkSweep = "rbxassetid://99189367717481",
	Evo_OverchargedBeam = "rbxassetid://81067366997095",
	Evo_ClockworkBastion = "rbxassetid://130684053274835",
	-- shop boosts (Fancy GUI Kit; Sea Boots: Layer Lab, the kit has no boots)
	ShellPouch = "rbxassetid://136304543316792",
	SeaBoots = "rbxassetid://93253580577782",
	SharpSteel = "rbxassetid://130874696589207",
	-- menu spots (Fancy GUI Kit)
	Codes = "rbxassetid://109335607792459",
	Settings = "rbxassetid://104401437368963", -- SET.1: Fancy GUI Kit gear (dot)
	LogSummary = "rbxassetid://139867160924968",
	Salvage = "rbxassetid://103025507172963",
}

return ItemIcons
