--!strict
-- ShoreFx (client, V3 visual overhaul): foam where the sea meets the island and its rocks, and spray thrown up
-- by the storm waves. Purely visual and local to this device; the server never sees it.
-- The shoreline is found from the terrain itself the first time this player is on the island, so it follows
-- any change to the island (V4) without a list to keep up to date.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local localPlayer = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("GameState")

local SOFT_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local SCAN_RADIUS = 280 -- studs around the island centre
local STEP = 6 -- grid spacing of the scan
local MIN_GAP = 11 -- keep shoreline points at least this far apart
local MAX_POINTS = if UserInputService.TouchEnabled then 40 else 90 -- the render budget (S4.4)

local function sequence(points: { { number } }): NumberSequence
	local keypoints = {}
	for _, point in points do
		table.insert(keypoints, NumberSequenceKeypoint.new(point[1], point[2]))
	end
	return NumberSequence.new(keypoints)
end

local function stormy(): boolean
	local phase = state:GetAttribute("Phase")
	return (phase == "Night" or phase == "Prologue") and localPlayer:GetAttribute("Ready") == true
end

-- Water cells next to land cells, on a grid around the island. Returns nothing useful until the island's
-- terrain has streamed in (then most of the grid hits nothing).
local function findShoreline(): { Vector3 }
	local center = Config.ISLAND_CENTER
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { Workspace.Terrain }
	local size = math.floor(SCAN_RADIUS * 2 / STEP)
	local cells: { [number]: number } = {} -- 1 water, 2 land
	local hits = 0
	for i = 0, size do
		for j = 0, size do
			local x = center.X - SCAN_RADIUS + i * STEP
			local z = center.Z - SCAN_RADIUS + j * STEP
			local hit = Workspace:Raycast(Vector3.new(x, 80, z), Vector3.new(0, -140, 0), params)
			if hit then
				hits += 1
				cells[i * 10000 + j] = if hit.Material == Enum.Material.Water then 1 else 2
			end
		end
		if i % 8 == 0 then
			task.wait()
		end
	end
	local points: { Vector3 } = {}
	if hits < size * size * 0.8 then
		return points
	end
	for i = 1, size - 1 do
		for j = 1, size - 1 do
			if cells[i * 10000 + j] == 1 then
				local nearLand = cells[(i + 1) * 10000 + j] == 2
					or cells[(i - 1) * 10000 + j] == 2
					or cells[i * 10000 + j + 1] == 2
					or cells[i * 10000 + j - 1] == 2
				if nearLand then
					local point = Vector3.new(center.X - SCAN_RADIUS + i * STEP, 0.5, center.Z - SCAN_RADIUS + j * STEP)
					local spaced = true
					for _, other in points do
						if (other - point).Magnitude < MIN_GAP then
							spaced = false
							break
						end
					end
					if spaced then
						table.insert(points, point)
					end
				end
			end
		end
	end
	-- thin evenly to the budget
	if #points > MAX_POINTS then
		local thinned = {}
		for index = 1, MAX_POINTS do
			table.insert(thinned, points[math.floor((index - 1) * #points / MAX_POINTS) + 1])
		end
		points = thinned
	end
	return points
end

local anchor = Instance.new("Part")
anchor.Name = "ShoreFx"
anchor.Anchored = true
anchor.CanCollide = false
anchor.CanQuery = false
anchor.CanTouch = false
anchor.Transparency = 1
anchor.Size = Vector3.new(1, 1, 1)
anchor.CFrame = CFrame.new(Config.ISLAND_CENTER.X, 0, Config.ISLAND_CENTER.Z)
anchor.Parent = Workspace

local foams: { ParticleEmitter } = {}
local sprays: { ParticleEmitter } = {}

local function build(points: { Vector3 })
	for _, point in points do
		local attachment = Instance.new("Attachment")
		attachment.WorldPosition = point
		attachment.Parent = anchor

		-- foam: slow, flat-ish puffs that churn at the waterline
		local foam = Instance.new("ParticleEmitter")
		foam.Name = "Foam"
		foam.Texture = SOFT_TEXTURE
		foam.Color = ColorSequence.new(Color3.fromRGB(214, 224, 232))
		foam.Size = sequence({ { 0, 2 }, { 1, 6.5 } })
		foam.Transparency = sequence({ { 0, 1 }, { 0.2, 0.55 }, { 1, 1 } })
		foam.Lifetime = NumberRange.new(2.5, 3.5)
		foam.Speed = NumberRange.new(0.5, 1.5)
		foam.SpreadAngle = Vector2.new(80, 80)
		foam.Rotation = NumberRange.new(0, 360)
		foam.RotSpeed = NumberRange.new(-15, 15)
		foam.Drag = 1
		foam.LightInfluence = 0.7
		foam.Rate = 0
		foam.Parent = attachment
		table.insert(foams, foam)

		-- spray: thrown up when a storm wave hits (emitted in bursts below)
		local spray = Instance.new("ParticleEmitter")
		spray.Name = "Spray"
		spray.Texture = SOFT_TEXTURE
		spray.Color = ColorSequence.new(Color3.fromRGB(220, 228, 236))
		spray.Size = sequence({ { 0, 1.2 }, { 1, 4 } })
		spray.Transparency = sequence({ { 0, 0.35 }, { 1, 1 } })
		spray.Lifetime = NumberRange.new(0.8, 1.3)
		spray.Speed = NumberRange.new(14, 22)
		spray.SpreadAngle = Vector2.new(20, 20)
		spray.Acceleration = Vector3.new(4, -35, 2)
		spray.Rotation = NumberRange.new(0, 360)
		spray.LightInfluence = 0.7
		spray.Rate = 0
		spray.Parent = attachment
		table.insert(sprays, spray)
	end
end

local function refresh()
	local storm = stormy()
	local low = localPlayer:GetAttribute("LowEffects") == true
	local rate = if low then 0 elseif storm then 0.8 else 0.25
	for _, foam in foams do
		foam.Rate = rate
	end
end

-- find the shoreline once this player is on the island (its terrain has streamed in by then)
task.spawn(function()
	while #foams == 0 do
		if localPlayer:GetAttribute("Ready") == true then
			local points = findShoreline()
			if #points > 0 then
				build(points)
				refresh()
				break
			end
		end
		task.wait(3)
	end
end)

state:GetAttributeChangedSignal("Phase"):Connect(refresh)
localPlayer:GetAttributeChangedSignal("Ready"):Connect(refresh)
localPlayer:GetAttributeChangedSignal("LowEffects"):Connect(refresh)

-- storm waves throw spray at a few random points along the shore
task.spawn(function()
	while true do
		task.wait(0.35)
		if #sprays > 0 and stormy() and not localPlayer:GetAttribute("LowEffects") then
			local bursts = if UserInputService.TouchEnabled then 1 else 2
			for _ = 1, bursts do
				sprays[math.random(1, #sprays)]:Emit(6)
			end
		end
	end
end)
