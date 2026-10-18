--!strict
-- D-044: the sniper tower (the owner's idea). A shot is traced along a line from the rifle and hits within the
-- creature's body plus the aim pad; only the voyage crew climbs, one at a time, never the Keeper or someone
-- carrying oil; the rifle keeps its cooldown; one shot kills a Sand Skitter and a Rock Crab takes three.
return function(T: any)
	local SniperService = T.require(game.ServerScriptService.Server.SniperService)
	local StatPipeline = T.require(game.ReplicatedStorage.Shared.StatPipeline)
	local Creatures = T.require(game.ReplicatedStorage.Shared.Creatures)
	local NetGuard = T.require(game.ServerScriptService.Server.NetGuard)

	T.describe("the shot", function()
		local origin = Vector3.new(0, 30, 0)
		local east = Vector3.new(1, 0, 0)
		T.it("hits along the line within the radius, not behind the rifle or past its range", function()
			T.expect(SniperService.rayHit(origin, east, 220, Vector3.new(100, 30, 2), 2.5)).toBe(100)
			T.expect(SniperService.rayHit(origin, east, 220, Vector3.new(100, 30, 3), 2.5)).toBe(nil) -- 3 off the line
			T.expect(SniperService.rayHit(origin, east, 220, Vector3.new(-50, 30, 0), 2.5)).toBe(nil) -- behind
			T.expect(SniperService.rayHit(origin, east, 220, Vector3.new(230, 30, 0), 2.5)).toBe(nil) -- too far
		end)

		T.it("follows a shot down from the tower to the ground", function()
			local target = Vector3.new(80, 1, 20)
			local direction = (target - origin).Unit
			local t = SniperService.rayHit(origin, direction, 220, target + Vector3.new(0, 0.5, 0), 1 + 2.5)
			T.expect(t ~= nil).toBe(true)
		end)
	end)

	T.describe("climbing and firing", function()
		local crew = { ready = true, alive = true, keeper = false, carryingOil = false }
		T.it("the voyage crew climbs, one at a time, during the voyage", function()
			T.expect(SniperService.canClimb("Night", false, crew)).toBe(nil)
			T.expect(SniperService.canClimb("Day", false, crew)).toBe(nil)
			T.expect(SniperService.canClimb("Night", true, crew)).toContain("already up")
			T.expect(SniperService.canClimb("Waiting", false, crew)).toContain("voyage crew")
			T.expect(SniperService.canClimb("Night", false, { ready = false, alive = true, keeper = false, carryingOil = false })).toContain("voyage crew")
		end)

		T.it("not the Keeper, not with oil in hand", function()
			T.expect(SniperService.canClimb("Night", false, { ready = true, alive = true, keeper = true, carryingOil = false })).toContain("lamp")
			T.expect(SniperService.canClimb("Night", false, { ready = true, alive = true, keeper = false, carryingOil = true })).toContain("oil")
		end)

		T.it("only the one up the tower fires, and the rifle keeps its cooldown", function()
			T.expect(SniperService.canFire(true, nil, 10, 1)).toBe(true)
			T.expect(SniperService.canFire(true, 9.5, 10, 1)).toBe(false)
			T.expect(SniperService.canFire(true, 9, 10, 1)).toBe(true)
			T.expect(SniperService.canFire(false, nil, 10, 1)).toBe(false)
		end)
	end)

	T.describe("the numbers (D-044)", function()
		T.it("one shot kills a Sand Skitter; a Rock Crab takes three (two in a Spring Tide)", function()
			local s = StatPipeline.sniper()
			T.expect(math.ceil(Creatures.SandSkitter.health / s.damage)).toBe(1)
			T.expect(math.ceil(Creatures.RockCrab.health / s.damage)).toBe(3)
			T.expect(math.ceil(Creatures.RockCrab.health * 0.8 / s.damage)).toBe(2)
			T.expect(s.cooldown).toBe(1)
			T.expect(s.range).toBe(250)
		end)

		T.it("its remote has a rate (contract row)", function()
			T.expect(NetGuard.RATES.SniperAction ~= nil).toBe(true)
		end)
	end)
end
