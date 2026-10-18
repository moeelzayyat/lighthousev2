-- Creatures: stats for every creature type. Adding a monster = adding an entry here
-- (plus its 3D model in ServerStorage.Art under the same `art` name).
--
--   health          hit points
--   speed           studs per second
--   pushable        can the wide beam shove it back?
--   beamDamageMult  how much beam damage it takes (0.5 = half)
--   bodyRadius      how big it is, for hits (weapon/cannon hits count within hitRadius + this)
--   attackRange     how close it gets to a player or cannon before attacking
--   playerDamage    damage per attack on players (armor reduces it)
--   attackInterval  seconds between attacks on players
--   slamRadius      0 = bites one player; > 0 = slams every player within this many studs
--   towerDps / cannonDps   damage per second to the tower / a cannon while attacking it
--   scale           size of the 3D model (sets the art's size relative to its file)
--   big             big monsters get a boss bar, an announcement, and big loot
-- S6.5 (owner request #5, D-023): monsters with their own move, shown at least 0.6 s before it goes off
--   behaviour       "spitter" (spits at a marked spot from range), "mine" (lights a fuse when a player comes
--                   close or it reaches the tower, then bursts), "ghost" (only the beam hurts it; it drains the
--                   lamp's fuel at the tower); S6.6: "summoner" (calls `summonCount` `summonKind` out of the sea
--                   beside it), "healer" (mends the small creatures within `healRadius` by `healShare` of their health)
--   ignoresPlayers  always goes for the lighthouse
--   telegraph       seconds of warning (the TELEGRAPH snapshot state and telegraphSound), then releaseSound
--   towerRange / towerHit / cannonHit / splashRadius / triggerRadius / blastRadius / fuelDrain   the move's numbers
--   weaponImmune    weapons and cannons pass through it (the beam is the counter)
--   hover           studs above the ground
--   appears         { from = night, base, every, max }: how many join each night (WaveDirector.specials)
--   loot            rows { chance, drops = { { kind, min, max } } }: one row is rolled; chances sum to 1
--   shape, color    the simple model drawn when ServerStorage.Art has no model for it
-- D-047: minRadius   never comes closer to the tower than this (the Kraken stays in the shallows)
--         finalBoss   the big monster of a voyage's last night (Config.FINAL_BOSS names it; never in BIG_POOL)

local Creatures = {
	RockCrab = {
		displayName = "Rock Crab",
		art = "RockCrab",
		health = 30,
		speed = 6,
		pushable = true,
		beamDamageMult = 1,
		bodyRadius = 1,
		attackRange = 3.5,
		playerDamage = 6,
		attackInterval = 1.0,
		slamRadius = 0,
		towerDps = 0.6,
		cannonDps = 2,
		scale = 1,
		big = false,
	},

	-- Swarm crab (Oct 12 2026, owner asked for constant action): small, fast, fragile. Comes in packs
	-- all night so the wide beam and harpoons always have targets. Worth little loot (economy unchanged).
	SandSkitter = {
		displayName = "Sand Skitter",
		art = "SandSkitter", -- its own ForgeGUI model since ART.2 (was the Rock Crab's, smaller)
		health = 6, -- was 10 in the first test: the beam must sweep them, not grind them
		speed = 8.5,
		pushable = true,
		beamDamageMult = 1.3, -- the wide beam sweeps them away
		bodyRadius = 0.6,
		attackRange = 3,
		playerDamage = 3,
		attackInterval = 0.9,
		slamRadius = 0,
		towerDps = 0.12, -- was 0.25: a solo test lost the tower 25 s into night 1
		cannonDps = 1,
		scale = 0.6,
		big = false,
		swarm = true,
	},

	BarnacleBrute = {
		displayName = "Barnacle Brute",
		art = "BarnacleBrute",
		health = 700,
		speed = 3,
		pushable = false, -- too heavy for the beam to shove
		beamDamageMult = 0.5, -- armored shell
		bodyRadius = 5,
		attackRange = 7,
		playerDamage = 28,
		attackInterval = 2.6,
		slamRadius = 8, -- ground slam hits everyone nearby
		towerDps = 5,
		cannonDps = 14,
		scale = 1,
		big = true,
	},

	ShipwreckHermit = {
		displayName = "Shipwreck Hermit",
		art = "ShipwreckHermit",
		health = 480,
		speed = 4.5,
		pushable = false,
		beamDamageMult = 0.75,
		bodyRadius = 4.5,
		attackRange = 6,
		playerDamage = 20,
		attackInterval = 1.8,
		slamRadius = 5,
		towerDps = 4,
		cannonDps = 10,
		scale = 1,
		big = true,
	},

	-- S6.5: keeps its distance and spits at the spot a player (or the tower) stood on: step out of the green ring
	SpitterEel = {
		displayName = "Spitter Eel",
		art = "SpitterEel",
		shape = "eel",
		color = Color3.fromRGB(70, 150, 120),
		health = 40,
		speed = 5,
		pushable = true,
		beamDamageMult = 1,
		bodyRadius = 1.2,
		attackRange = 22,
		towerRange = 16,
		playerDamage = 12,
		attackInterval = 2.8,
		slamRadius = 0,
		towerDps = 0,
		towerHit = 3,
		cannonDps = 0,
		cannonHit = 6,
		scale = 1,
		big = false,
		behaviour = "spitter",
		telegraph = 0.8,
		splashRadius = 4,
		telegraphSound = "eelRear",
		releaseSound = "eelSpit",
		appears = { from = 2, base = 1, every = 2, max = 4 },
		loot = {
			{ chance = 0.75, drops = { { "Shells", 4, 6 } } },
			{ chance = 0.2, drops = { { "Shells", 4, 6 }, { "SeaGlass", 1, 1 } } },
			{ chance = 0.05, drops = { { "Shells", 4, 6 }, { "BlackPearl", 1, 1 } } },
		},
	},

	-- S6.5: drifts in slowly; swells for a second when a player comes close, then bursts: shoot it first or back off
	PufferMine = {
		displayName = "Puffer Mine",
		art = "PufferMine",
		shape = "puffer",
		color = Color3.fromRGB(225, 185, 90),
		health = 25,
		speed = 2.5,
		pushable = true,
		beamDamageMult = 1.2,
		bodyRadius = 1.4,
		attackRange = 3,
		playerDamage = 30,
		attackInterval = 5,
		slamRadius = 0,
		towerDps = 0,
		towerHit = 8,
		cannonDps = 0,
		cannonHit = 10,
		scale = 1,
		big = false,
		behaviour = "mine",
		telegraph = 1.0,
		triggerRadius = 6,
		blastRadius = 8,
		telegraphSound = "pufferFuse",
		releaseSound = "pufferBoom",
		appears = { from = 3, base = 2, every = 2, max = 5 },
		loot = {
			{ chance = 0.8, drops = { { "Shells", 3, 5 } } },
			{ chance = 0.2, drops = { { "Shells", 3, 5 }, { "CrabClaw", 1, 1 } } },
		},
	},

	-- S6.5: floats to the lighthouse and drinks the lamp's oil; harpoons and cannons pass through it: burn it
	GhostLantern = {
		displayName = "Ghost Lantern",
		art = "GhostLantern",
		shape = "lantern",
		color = Color3.fromRGB(170, 255, 210),
		health = 60,
		speed = 4,
		pushable = false,
		beamDamageMult = 2,
		bodyRadius = 1.2,
		hover = 3,
		weaponImmune = true,
		attackRange = 3,
		playerDamage = 0,
		attackInterval = 3,
		slamRadius = 0,
		towerDps = 0,
		cannonDps = 0,
		scale = 1,
		big = false,
		behaviour = "ghost",
		ignoresPlayers = true,
		telegraph = 0.9,
		fuelDrain = 6,
		telegraphSound = "ghostWail",
		releaseSound = "ghostDrain",
		appears = { from = 5, base = 1, every = 3, max = 3 },
		loot = {
			{ chance = 0.6, drops = { { "Shells", 6, 9 } } },
			{ chance = 0.4, drops = { { "Shells", 6, 9 }, { "SeaGlass", 1, 1 } } },
		},
	},

	-- S6.6: stays back on the beach and, after a 1 s chant, calls three Sand Skitters out of the sea: take her out first
	TideWitch = {
		displayName = "Tide Witch",
		art = "TideWitch",
		shape = "witch",
		color = Color3.fromRGB(95, 85, 170),
		health = 45,
		speed = 3,
		pushable = true,
		beamDamageMult = 1,
		bodyRadius = 1.1,
		attackRange = 3,
		towerRange = 30,
		ignoresPlayers = true,
		playerDamage = 0,
		attackInterval = 7,
		slamRadius = 0,
		towerDps = 0,
		cannonDps = 0,
		scale = 1,
		big = false,
		behaviour = "summoner",
		telegraph = 1.0,
		summonKind = "SandSkitter",
		summonCount = 3,
		telegraphSound = "witchChant",
		releaseSound = "witchTide",
		appears = { from = 4, base = 1, every = 3, max = 2 },
		loot = {
			{ chance = 0.6, drops = { { "Shells", 5, 8 } } },
			{ chance = 0.4, drops = { { "Shells", 5, 8 }, { "SeaGlass", 1, 1 } } },
		},
	},

	-- S6.6: walks behind the crowd and, after a 0.8 s chime, mends every small creature near it: burn it first
	CoralShaman = {
		displayName = "Coral Shaman",
		art = "CoralShaman",
		shape = "shaman",
		color = Color3.fromRGB(240, 120, 130),
		health = 70,
		speed = 3.5,
		pushable = true,
		beamDamageMult = 1,
		bodyRadius = 1.3,
		attackRange = 3,
		towerRange = 14,
		ignoresPlayers = true,
		playerDamage = 0,
		attackInterval = 5,
		slamRadius = 0,
		towerDps = 0,
		cannonDps = 0,
		scale = 1,
		big = false,
		behaviour = "healer",
		telegraph = 0.8,
		healRadius = 14,
		healShare = 0.3,
		telegraphSound = "shamanChime",
		releaseSound = "shamanMend",
		appears = { from = 6, base = 1, every = 3, max = 2 },
		loot = {
			{ chance = 0.5, drops = { { "Shells", 5, 8 }, { "CrabClaw", 1, 1 } } },
			{ chance = 0.5, drops = { { "Shells", 5, 8 }, { "SeaGlass", 1, 1 } } },
		},
	},

	-- D-047 (the owner's 12 Oct idea list: "Final boss: the Kraken"): the big monster of a voyage's LAST night. It rises
	-- in the shallows and stays there (minRadius); every 4 s a tentacle marks a spot (a Keeper near the shore,
	-- a cannon, or the tower) and slams it 1.2 s later. Beat it from the beach: harpoons, cannons, the sniper tower,
	-- the beam. Loot: the big-monster pile (no new economy numbers).
	Kraken = {
		displayName = "The Kraken",
		art = "Kraken",
		health = 1200, -- for a crew of 1; GameState adds Config.FINAL_BOSS_HEALTH_PER_EXTRA per extra Keeper
		speed = 3,
		pushable = false,
		beamDamageMult = 0.6,
		bodyRadius = 8,
		attackRange = 40,
		towerRange = 100,
		minRadius = 110,
		hover = -4, -- sits low in the water: head and tentacles above it
		playerDamage = 30,
		attackInterval = 4,
		slamRadius = 0,
		towerDps = 0,
		towerHit = 4, -- 1 a second at most: a crew that repairs or kills it keeps the tower
		cannonDps = 0,
		cannonHit = 20,
		scale = 1,
		big = true,
		finalBoss = true,
		behaviour = "spitter",
		telegraph = 1.2,
		splashRadius = 7,
		telegraphSound = "krakenRise",
		releaseSound = "krakenSlam",
	},
}

-- Big monsters that can be picked for a run
Creatures.BIG_POOL = { "BarnacleBrute", "ShipwreckHermit" }

return Creatures
