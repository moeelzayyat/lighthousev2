--!strict
-- MapBuilder (MAP.1, D-049): dresses the island as the voyage's map (Definitions/Maps). The shape of the island, the
-- lighthouse and every gameplay part stay as built; a map swaps terrain materials over the island, the sea colour and
-- a colour tint, and adds its own dressing. The home isle's terrain is read once before the first change, so going
-- back to it (Sail again with another map, in Studio's one-place game) restores it exactly.
-- The current map is published as GameState attribute "Map" (Client.Storm turns rain into snow on a snowy map).

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Ground = require(Shared:WaitForChild("Ground"))
local Maps = require(Shared:WaitForChild("Definitions"):WaitForChild("Maps")) :: any

local MapBuilder = {}

local REGION_RADIUS = 150 -- studs around the island centre whose terrain a map may change (the harbor is far away)
local current = Maps.DEFAULT
local saved: { region: Region3, materials: any, occupancy: any }? = nil
local savedWater: Color3? = nil

local function islandRegion(): Region3
	local c = Config.ISLAND_CENTER
	return Region3.new(Vector3.new(c.X - REGION_RADIUS, -40, c.Z - REGION_RADIUS), Vector3.new(c.X + REGION_RADIUS, 72, c.Z + REGION_RADIUS)):ExpandToGrid(4)
end

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function part(props: { [string]: any }, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanTouch = false
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

-- Is there a gameplay part (tower, shed, dock, bench, pads...) within `r` studs of this point?
local function crowded(at: Vector3, r: number): boolean
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { Workspace.Terrain, Workspace:FindFirstChild("MapDecor") :: any }
	for _, hit in Workspace:GetPartBoundsInRadius(at, r, params) do
		if hit.Transparency < 1 or hit:FindFirstChildWhichIsA("ProximityPrompt") then
			return true
		end
	end
	return false
end

-- A snowy pine: a trunk and four stacked tiers, each with a snow cap (9 parts, the foliage does not collide)
local function pine(at: Vector3, scale: number, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "SnowPine"
	local trunkH = 4 * scale
	part({ Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(trunkH, 1.4 * scale, 1.4 * scale), CFrame = CFrame.new(at + Vector3.new(0, trunkH / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(92, 62, 40), Material = Enum.Material.Wood }, model)
	for i = 0, 3 do
		local w = (7.5 - i * 1.6) * scale
		local y = trunkH + i * 2.3 * scale
		part({ Name = "Tier" .. i, Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.2 * scale, w, w), CFrame = CFrame.new(at + Vector3.new(0, y + 1.1 * scale, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(38, 82, 64), Material = Enum.Material.Grass, CanCollide = false }, model)
		part({ Name = "Snow" .. i, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5 * scale, w * 0.82, w * 0.82), CFrame = CFrame.new(at + Vector3.new(0, y + 2.35 * scale, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(240, 246, 255), Material = Enum.Material.Snow, CanCollide = false }, model)
	end
	model.Parent = parent
end

-- A cluster of three ice crystals leaning out of the ground
local function crystals(at: Vector3, yaw: number, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "IceCrystals"
	for i, spec in { { 0, 0, 7, 0 }, { 1.6, 0.6, 4.5, 22 }, { -1.4, -0.8, 3.6, -26 } } do
		local h = spec[3]
		part({
			Name = "Crystal" .. i,
			Size = Vector3.new(1.5, h, 1.5),
			CFrame = CFrame.new(at) * CFrame.Angles(0, math.rad(yaw), 0) * CFrame.new(spec[1], h / 2 - 0.6, spec[2]) * CFrame.Angles(0, math.rad(45), math.rad(spec[4])),
			Color = Color3.fromRGB(176, 228, 255),
			Material = Enum.Material.Glass,
			Transparency = 0.25,
			Reflectance = 0.1,
			CanCollide = i == 1,
		}, model)
	end
	model.Parent = parent
end

-- Frost dressing: pines on the grass ring, crystal clusters on the beach. Fixed seed: the same layout every time.
local function frostDecor(parent: Instance)
	local c = Config.ISLAND_CENTER
	local rng = Random.new(4910)
	local pines, ice = 0, 0
	for _ = 1, 400 do
		if pines >= 16 and ice >= 12 then
			break
		end
		local angle = rng:NextNumber(0, math.pi * 2)
		local wantPine = pines < 16
		local r = if wantPine then rng:NextNumber(40, 80) else rng:NextNumber(86, 108)
		local x, z = c.X + math.cos(angle) * r, c.Z + math.sin(angle) * r
		local y, water = Ground.heightAt(x, z)
		local at = Vector3.new(x, y, z)
		if not water then
			if wantPine and y > Config.GROUND_Y - 4 and not crowded(at + Vector3.new(0, 4, 0), 12) then
				pine(at, rng:NextNumber(0.85, 1.25), parent)
				pines += 1
			elseif not wantPine and y > 0.5 and y < 6 and not crowded(at + Vector3.new(0, 3, 0), 8) then
				crystals(at, rng:NextNumber(0, 360), parent)
				ice += 1
			end
		end
	end
	return pines, ice
end

local function restore()
	local decor = Workspace:FindFirstChild("MapDecor")
	if decor then
		decor:Destroy()
	end
	local tint = Lighting:FindFirstChild("MapTint")
	if tint then
		tint:Destroy()
	end
	if saved then
		Workspace.Terrain:WriteVoxels(saved.region, 4, saved.materials, saved.occupancy)
	end
	if savedWater then
		Workspace.Terrain.WaterColor = savedWater
	end
	current = Maps.DEFAULT
end

-- Dresses the island as `mapId` (an unknown id means the home isle). Returns the map id now shown.
function MapBuilder.apply(mapId: string?): string
	local def = if type(mapId) == "string" then Maps[mapId] else nil
	if type(def) ~= "table" then
		def = Maps[Maps.DEFAULT]
	end
	local state = ReplicatedStorage:FindFirstChild("GameState")
	if def.id == current then
		if state then
			state:SetAttribute("Map", current)
		end
		return current
	end
	restore()
	if def.id ~= Maps.DEFAULT then
		local terrain = Workspace.Terrain
		if not saved then
			local region = islandRegion()
			local materials, occupancy = terrain:ReadVoxels(region, 4)
			saved = { region = region, materials = materials, occupancy = occupancy }
			savedWater = terrain.WaterColor
		end
		local region = (saved :: any).region
		for from, to in def.terrain or {} do
			terrain:ReplaceMaterial(region, 4, (Enum.Material :: any)[from], (Enum.Material :: any)[to])
		end
		if def.waterColor then
			terrain.WaterColor = rgb(def.waterColor)
		end
		if def.tint then
			local cc = Instance.new("ColorCorrectionEffect")
			cc.Name = "MapTint"
			cc.TintColor = rgb(def.tint)
			cc.Saturation = def.saturation or 0
			cc.Parent = Lighting
		end
		local decor = Instance.new("Folder")
		decor.Name = "MapDecor"
		decor.Parent = Workspace
		if def.decor == "frost" then
			frostDecor(decor)
		end
		current = def.id
	end
	if state then
		state:SetAttribute("Map", current)
	end
	return current
end

function MapBuilder.current(): string
	return current
end

return MapBuilder
