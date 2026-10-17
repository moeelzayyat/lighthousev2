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
--                   lamp's fuel at the tower)
--   telegraph       seconds of warning (the TELEGRAPH snapshot state and telegraphSound), then releaseSound
--   towerRange / towerHit / cannonHit / splashRadius / triggerRadius / blastRadius / fuelDrain   the move's numbers
--   weaponImmune    weapons and cannons pass through it (the beam is the counter)
--   hover           studs above the ground
--   appears         { from = night, base, every, max }: how many join each night (WaveDirector.specials)
--   loot            rows { chance, drops = { { kind, min, max } } }: one row is rolled; chances sum to 1
--   shape, color    the simple model drawn when ServerStorage.Art has no model for it

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
		art = "RockCrab", -- same model, smaller
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
}

-- Big monsters that can be picked for a run
Creatures.BIG_POOL = { "BarnacleBrute", "ShipwreckHermit" }

return Creatures
