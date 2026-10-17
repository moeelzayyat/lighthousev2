--!strict
-- Ground: the height of the terrain (or the water surface) at a point.
-- Used so creatures, loot, and beam lights follow the actual island surface.
-- S4.1: the island area is sampled once at boot into a height grid (Ground.buildGrid): 1-stud cells, and cells
-- with a slope get a finer 4 x 4 sub-grid, so heights match a raycast within 0.2 studs where creatures walk.
-- heightAt reads the grid there, so creatures moving every step never raycast. Outside the grid (the lobby,
-- the far sea) it still raycasts, as before.

local Workspace = game:GetService("Workspace")

local Ground = {}

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { Workspace.Terrain }
params.IgnoreWater = false

local solidParams = RaycastParams.new()
solidParams.FilterType = Enum.RaycastFilterType.Include
solidParams.FilterDescendantsInstances = { Workspace.Terrain }
solidParams.IgnoreWater = true

Ground.raycasts = 0 -- raycasts made since boot (probe: stays flat while creatures move once the grid is built)
Ground.CELL = 1 -- studs between grid samples
Ground.REFINE_SPREAD = 0.3 -- a cell whose corners differ by more than this gets a sub-grid
Ground.SUB = 4 -- sub-grid divisions per side

-- Raycasts the surface height at (x, z) and whether that surface is water.
-- Solid ground and the water surface are measured separately, so leftover water inside
-- filled-in terrain (it happens where land was added over old sea) can't fool it.
function Ground.sample(x: number, z: number): (number, boolean)
	Ground.raycasts += 2
	local origin, down = Vector3.new(x, 300, z), Vector3.new(0, -400, 0)
	local solid = Workspace:Raycast(origin, down, solidParams)
	local any = Workspace:Raycast(origin, down, params)
	if solid and (not any or any.Material ~= Enum.Material.Water or solid.Position.Y >= any.Position.Y - 0.05) then
		return solid.Position.Y, false
	end
	if any then
		return any.Position.Y, any.Material == Enum.Material.Water
	end
	return 0, true
end

type Grid = {
	x0: number,
	z0: number,
	cell: number,
	n: number,
	h: { number },
	water: { boolean },
	fine: { [number]: { number } }, -- cell index -> (SUB + 1)^2 heights
}
local grid: Grid? = nil

-- Samples a square of side 2 * radius around (cx, cz). Call once at boot, after the terrain is in place.
-- Returns the number of raycast samples taken.
function Ground.buildGrid(cx: number, cz: number, radius: number): number
	local cell, sub = Ground.CELL, Ground.SUB
	local n = math.floor(2 * radius / cell) + 1
	local x0, z0 = cx - radius, cz - radius
	local h, water = table.create(n * n, 0), table.create(n * n, false)
	local samples = 0
	for iz = 0, n - 1 do
		for ix = 0, n - 1 do
			local y, w = Ground.sample(x0 + ix * cell, z0 + iz * cell)
			h[iz * n + ix + 1] = y
			water[iz * n + ix + 1] = w
			samples += 1
		end
		if iz % 32 == 0 then
			task.wait() -- keep the server responsive while the grid is built
		end
	end
	local fine: { [number]: { number } } = {}
	local m = sub + 1
	for iz = 0, n - 2 do
		for ix = 0, n - 2 do
			local i = iz * n + ix + 1
			local a, b, c, d = h[i], h[i + 1], h[i + n], h[i + n + 1]
			if math.max(a, b, c, d) - math.min(a, b, c, d) > Ground.REFINE_SPREAD then
				local f = table.create(m * m, 0)
				for sz = 0, sub do
					for sx = 0, sub do
						f[sz * m + sx + 1] = (Ground.sample(x0 + (ix + sx / sub) * cell, z0 + (iz + sz / sub) * cell))
						samples += 1
					end
				end
				fine[i] = f
			end
		end
		if iz % 32 == 0 then
			task.wait()
		end
	end
	grid = { x0 = x0, z0 = z0, cell = cell, n = n, h = h, water = water, fine = fine }
	return samples
end

function Ground.clearGrid()
	grid = nil
end

function Ground.hasGrid(): boolean
	return grid ~= nil
end

-- Returns the surface height at (x, z), and whether that surface is water. Inside the grid: bilinear
-- interpolation (in the cell's sub-grid when it has one); water if the nearest corner is water.
-- Outside: a raycast.
function Ground.heightAt(x: number, z: number): (number, boolean)
	local g = grid
	if g then
		local fx, fz = (x - g.x0) / g.cell, (z - g.z0) / g.cell
		local ix, iz = math.floor(fx), math.floor(fz)
		if ix >= 0 and iz >= 0 and ix < g.n - 1 and iz < g.n - 1 then
			local tx, tz = fx - ix, fz - iz
			local i = iz * g.n + ix + 1
			local nearest = i + (if tx >= 0.5 then 1 else 0) + (if tz >= 0.5 then g.n else 0)
			local f = g.fine[i]
			if f then
				local sub = Ground.SUB
				local m = sub + 1
				local gx, gz = tx * sub, tz * sub
				local jx, jz = math.min(math.floor(gx), sub - 1), math.min(math.floor(gz), sub - 1)
				local ux, uz = gx - jx, gz - jz
				local k = jz * m + jx + 1
				return (f[k] * (1 - ux) + f[k + 1] * ux) * (1 - uz) + (f[k + m] * (1 - ux) + f[k + m + 1] * ux) * uz, g.water[nearest]
			end
			local a, b, c, d = g.h[i], g.h[i + 1], g.h[i + g.n], g.h[i + g.n + 1]
			return (a * (1 - tx) + b * tx) * (1 - tz) + (c * (1 - tx) + d * tx) * tz, g.water[nearest]
		end
	end
	return Ground.sample(x, z)
end

return Ground
