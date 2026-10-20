-- Weapons: every on-foot weapon is one entry here. Adding a weapon = adding an entry.
--
--   damage      damage per hit, to each creature hit
--   cooldown    seconds between attacks
--   range       max throw/shot distance
--   hitRadius   how close to a creature the shot must land
--   maxTargets  how many creatures one shot can hit (1 = single target)
--   archetype   "Thrown" (aimed: a click or tap throws a spear or fires a flare) or "Orbit" (S6.3: blades
--               circle the player and cut what they pass; nothing to aim)
--   projectile  "spear" or "flare" (the visual of a Thrown weapon); "hook", "net", "bomb" for WPN.1; GUN.1: "bullet"
--               (a fast tracer with a muzzle flash) and "shot" (a spray of pellets over the area it hits)
--   WPN.1 (D-048), aimed like Thrown, each with one effect (Shared/WeaponFx):
--     "Chain" pullDistance, pullStopAt   drags the hooked creature toward the thrower (not big monsters)
--     "Net"   slowFactor, slowSeconds    slows every creature hit (big monsters feel half)
--     "Bomb"  fuse                       lands, waits `fuse` seconds, then blasts hitRadius
--   For an Orbit weapon: range = the blades' circle radius, cooldown = seconds between cuts, blades = how many
--   are drawn, spin = degrees per second. voyageOnly = sold only by the island merchant for one voyage (no
--   Items entry, never owned).
--
-- Balance rule: on-foot weapons do much less damage per second than the lamp
-- (wide beam 12/s, focused 35/s). They help; the beam carries.

local Weapons = {
	DriftwoodHarpoon = {
		displayName = "Driftwood Harpoon",
		damage = 8,
		cooldown = 0.9, -- about 9 damage per second
		range = 50,
		hitRadius = 5,
		maxTargets = 1,
		archetype = "Thrown",
		projectile = "spear",
		color = Color3.fromRGB(120, 85, 55),
	},
	StormHarpoon = {
		displayName = "Storm Harpoon",
		damage = 9,
		cooldown = 0.9, -- same single-target damage, but pierces up to 3 crabs
		range = 60,
		hitRadius = 6,
		maxTargets = 3,
		archetype = "Thrown",
		projectile = "spear",
		color = Color3.fromRGB(80, 140, 220),
	},
	FlareGun = {
		displayName = "Flare Gun",
		damage = 11,
		cooldown = 1.8, -- slower, but bursts on a group
		range = 70,
		hitRadius = 8,
		maxTargets = 6,
		archetype = "Thrown",
		projectile = "flare",
		color = Color3.fromRGB(230, 90, 50),
	},
	WhalerHarpoon = {
		displayName = "Whaler's Harpoon",
		damage = 45,
		cooldown = 1.6, -- about 28 damage per second, but only ever one target: built for big monsters
		range = 55,
		hitRadius = 5,
		maxTargets = 1,
		archetype = "Thrown",
		projectile = "spear",
		color = Color3.fromRGB(150, 160, 175),
	},
	-- S6.3 (owner request #3): no aiming, good on phones; the island merchant sells it for one voyage (D-020)
	OrbitingBlades = {
		displayName = "Orbiting Blades",
		damage = 4,
		cooldown = 0.5, -- a cut every half second: 8 damage per second to each of up to 3 creatures close by
		range = 7,
		hitRadius = 7,
		maxTargets = 3,
		archetype = "Orbit",
		blades = 3,
		spin = 220,
		voyageOnly = true,
		color = Color3.fromRGB(200, 215, 230),
	},
	-- S6.4: Quartermaster gear (D-021)
	CoralLance = {
		displayName = "Coral Lance",
		damage = 13,
		cooldown = 1.3, -- 10 damage per second, and the throw passes through a second creature
		range = 55,
		hitRadius = 5,
		maxTargets = 2,
		archetype = "Thrown",
		projectile = "spear",
		color = Color3.fromRGB(235, 120, 105),
	},
	TidecallerBlades = { -- the permanent Orbit weapon: weaker than the merchant's voyage blades, and no thrown weapon
		displayName = "Tidecaller Blades",
		damage = 3,
		cooldown = 0.5, -- 6 damage per second to each of up to 3 creatures close by
		range = 7,
		hitRadius = 7,
		maxTargets = 3,
		archetype = "Orbit",
		blades = 3,
		spin = 200,
		color = Color3.fromRGB(90, 200, 190),
	},
	-- WPN.1 (the owner's Oct 13 list: "Later: chain hook, net launcher, lantern bomb"; architecture §15 archetypes).
	-- Aimed like a harpoon; each adds one effect (rules in Shared/WeaponFx). Numbers chosen unattended (D-048), revisable.
	ChainHook = {
		displayName = "Chain Hook",
		damage = 10,
		cooldown = 1.4, -- about 7 damage per second, and the hooked creature is yanked toward you
		range = 45,
		hitRadius = 5,
		maxTargets = 1,
		archetype = "Chain",
		projectile = "hook",
		pullDistance = 14, -- studs it is dragged toward the thrower (big monsters are too heavy)
		pullStopAt = 6, -- it stops this far from the thrower
		color = Color3.fromRGB(110, 115, 125),
	},
	NetLauncher = {
		displayName = "Net Launcher",
		damage = 3,
		cooldown = 3, -- little damage: the net holds a group for the beam and the crew
		range = 55,
		hitRadius = 9,
		maxTargets = 6,
		archetype = "Net",
		projectile = "net",
		slowFactor = 0.35, -- netted creatures move at 35% speed (big monsters feel half: 67.5%)
		slowSeconds = 3,
		color = Color3.fromRGB(205, 180, 120),
	},
	-- GUN.1 (owner 2026-10-20 "let's add guns and stuff that are attractive"): aimed like a harpoon (Thrown), fired
	-- as bullets. Numbers chosen unattended (D-057), revisable; every one stays under the lamp's damage per second.
	FlintlockPistol = {
		displayName = "Flintlock Pistol",
		damage = 6,
		cooldown = 0.55, -- about 11 damage per second: quick light shots at one target
		range = 60,
		hitRadius = 4,
		maxTargets = 1,
		archetype = "Thrown",
		projectile = "bullet",
		color = Color3.fromRGB(255, 220, 140),
	},
	Blunderbuss = {
		displayName = "Blunderbuss",
		damage = 8,
		cooldown = 1.5, -- a short-range spray: up to 5 creatures in a wide circle
		range = 28,
		hitRadius = 8,
		maxTargets = 5,
		archetype = "Thrown",
		projectile = "shot",
		color = Color3.fromRGB(255, 190, 90),
	},
	HarpoonGun = {
		displayName = "Harpoon Gun",
		damage = 14,
		cooldown = 1.2, -- about 12 damage per second, through up to 3 creatures, from far away
		range = 80,
		hitRadius = 5,
		maxTargets = 3,
		archetype = "Thrown",
		projectile = "spear",
		color = Color3.fromRGB(95, 105, 115),
	},
	StormMusket = {
		displayName = "Storm Musket",
		damage = 32,
		cooldown = 2.2, -- about 15 damage per second to one target, at the longest range
		range = 95,
		hitRadius = 4,
		maxTargets = 1,
		archetype = "Thrown",
		projectile = "bullet",
		color = Color3.fromRGB(110, 170, 255),
	},
	LanternBomb = {
		displayName = "Lantern Bomb",
		damage = 30, -- one blast takes down a Rock Crab
		cooldown = 4.5, -- under 7 damage per second to each of up to 8 creatures, after a short fuse
		range = 45,
		hitRadius = 10,
		maxTargets = 8,
		archetype = "Bomb",
		projectile = "bomb",
		fuse = 0.9, -- seconds between landing and the blast
		color = Color3.fromRGB(255, 170, 60),
	},
}

return Weapons
