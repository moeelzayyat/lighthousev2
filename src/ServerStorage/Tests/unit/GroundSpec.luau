--!strict
-- S4.1: the ground grid. Where creatures walk, heights read from the grid match a raycast within 0.2 studs,
-- and reading the grid makes no raycasts.
return function(T: any)
	local Ground = T.require(game.ReplicatedStorage.Shared.Ground)
	local Config = T.require(game.ReplicatedStorage.Shared.Config)

	T.describe("grid", function()
		T.it("matches raycasts within 0.2 studs across the beach, and reads without raycasting", function()
			-- a 40 x 40 patch across the shoreline (grass, beach, shallow sea)
			local cx, cz = Config.ISLAND_CENTER.X + Config.ISLAND_RADIUS, Config.ISLAND_CENTER.Z
			Ground.clearGrid()
			local samples = Ground.buildGrid(cx, cz, 20)
			T.expect(samples > 41 * 41 - 1).toBe(true)
			local rng = Random.new(3)
			local points = {}
			for _ = 1, 300 do
				table.insert(points, { rng:NextNumber(cx - 19, cx + 19), rng:NextNumber(cz - 19, cz + 19) })
			end
			local before = Ground.raycasts
			local fromGrid = {}
			for i, p in points do
				fromGrid[i] = (Ground.heightAt(p[1], p[2]))
			end
			T.expect(Ground.raycasts).toBe(before) -- 300 lookups, no raycast
			local worst = 0
			for i, p in points do
				worst = math.max(worst, math.abs(fromGrid[i] - (Ground.sample(p[1], p[2]))))
			end
			if worst > 0.2 then
				error(string.format("worst difference %.3f studs", worst))
			end
			Ground.clearGrid()
		end)

		T.it("outside the grid it still raycasts", function()
			Ground.clearGrid()
			Ground.buildGrid(0, 0, 4)
			local before = Ground.raycasts
			Ground.heightAt(500, 500)
			T.expect(Ground.raycasts).toBe(before + 2)
			Ground.clearGrid()
		end)
	end)
end
