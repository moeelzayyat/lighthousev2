-- Weapons: every on-foot weapon is one entry here. Adding a weapon = adding an entry.
--
--   damage      damage per hit, to each creature hit
--   cooldown    seconds between attacks
--   range       max throw/shot distance
--   hitRadius   how close to a creature the shot must land
--   maxTargets  how many creatures one shot can hit (1 = single target)
--   archetype   "Thrown" (aimed: a click or tap throws a spear or fires a flare) or "Orbit" (S6.3: blades
--               circle the player and cut what they pass; nothing to aim)
--   projectile  "spear" or "flare" (the visual of a Thrown weapon)
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
}

return Weapons
