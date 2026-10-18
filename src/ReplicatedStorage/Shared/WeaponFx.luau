--!strict
-- WeaponFx (WPN.1, D-048): the pure rules behind the aimed weapons' effects, so CreatureService and the tests share them.
--   Chain (Chain Hook)  drags the hooked creature toward the thrower
--   Net (Net Launcher)  slows every creature it lands on for a few seconds
--   Bomb (Lantern Bomb) lands, burns its fuse, then blasts (timing in Encounter; damage via CreatureService.damageArea)

local WeaponFx = {}

-- Where a hooked creature ends up: dragged up to `distance` studs toward `toward` along the ground, stopping
-- `stopAt` studs short of it. Height is kept (the creature's own ground placement sets it).
function WeaponFx.pullPosition(pos: Vector3, toward: Vector3, distance: number, stopAt: number): Vector3
	local flat = Vector3.new(toward.X - pos.X, 0, toward.Z - pos.Z)
	local gap = flat.Magnitude
	local move = math.min(distance, math.max(0, gap - stopAt))
	if move <= 0 or gap < 0.01 then
		return pos
	end
	return pos + flat.Unit * move
end

-- A net's speed factor on a creature: big monsters feel half of it
function WeaponFx.slowFor(big: boolean?, slowFactor: number): number
	if big then
		return 1 - (1 - slowFactor) / 2
	end
	return slowFactor
end

-- Can a Chain Hook move it? Only what the wide beam can shove (big monsters are too heavy)
function WeaponFx.canPull(pushable: boolean?): boolean
	return pushable == true
end

return WeaponFx
