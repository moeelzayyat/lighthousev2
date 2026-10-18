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
	TidecallerBlades = "rbxassetid://139899207751386",
	-- armor and ammo (Claude-drawn)
	OilskinCoat = "rbxassetid://114074436530125",
	KeepersCoat = "rbxassetid://94339926459043",
	KelpweaveVest = "rbxassetid://97891374327995",
	IronclawPlate = "rbxassetid://131837581985487",
	FireShellCrate = "rbxassetid://76691933271523",
	-- loot (Sealoot pack)
	CrabClaw = "rbxassetid://125494313308190",
	SeaGlass = "rbxassetid://78566778258629",
	BlackPearl = "rbxassetid://117189862331089",
	-- cosmetics (Claude-drawn)
	BeamAmber = "rbxassetid://116090183262825",
	BeamSeaGlass = "rbxassetid://102490477434070",
	BeamMoonlight = "rbxassetid://81571281305906",
	BeamEmber = "rbxassetid://105007451360115",
	BeamSharedLantern = "rbxassetid://83228195674142",
	BeamKeepersGlow = "rbxassetid://96464902613251",
	HousingDriftwood = "rbxassetid://75465142387655",
	HousingBrass = "rbxassetid://94796303291915",
	CoatStormBlue = "rbxassetid://110363693204788",
	CoatKelpGreen = "rbxassetid://132502189617087",
	LanternMoth = "rbxassetid://102162800434776",
	LanternTide = "rbxassetid://94479891019422",
	FlagGull = "rbxassetid://97803221222199",
	FlagKraken = "rbxassetid://100752905653856",
	FlagFounder = "rbxassetid://98378099554182",
	FlagRescuer = "rbxassetid://73939053590853",
	-- the Trader's island stock (Claude-drawn)
	OrbitingBlades = "rbxassetid://106009642656255",
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
	-- menu spots (Sealoot pack)
	Codes = "rbxassetid://96013858620736",
	LogSummary = "rbxassetid://95524164604917",
	Salvage = "rbxassetid://137083461181210",
}

return ItemIcons
