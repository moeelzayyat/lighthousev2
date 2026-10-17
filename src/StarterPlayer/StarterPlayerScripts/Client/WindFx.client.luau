--!strict
-- WindFx (client, V4 visual overhaul): hanging lanterns swing and flags flutter in the wind, harder in the storm.
-- Parts opt in with a CollectionService tag ("Sway" for lanterns, "Flutter" for flags) and a SwayPivot
-- attribute (the world point they hang from). Purely visual and local to this device.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("GameState")
local camera = Workspace.CurrentCamera

local NEAR = 250 -- only parts this close to the camera move
local SWAY_DEGREES = 10
local FLUTTER_DEGREES = 22

type Item = { part: BasePart, base: CFrame, pivot: Vector3, phase: number, flutter: boolean }
local items: { [BasePart]: Item } = {}

local function add(instance: Instance, flutter: boolean)
	if not instance:IsA("BasePart") or items[instance] then
		return
	end
	local pivot = instance:GetAttribute("SwayPivot")
	if typeof(pivot) ~= "Vector3" then
		return
	end
	items[instance] = { part = instance, base = instance.CFrame, pivot = pivot, phase = math.random() * math.pi * 2, flutter = flutter }
end

local function remove(instance: Instance)
	if instance:IsA("BasePart") then
		items[instance] = nil
	end
end

for tag, flutter in { Sway = false, Flutter = true } do
	for _, instance in CollectionService:GetTagged(tag) do
		add(instance, flutter)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
		add(instance, flutter)
	end)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(remove)
end

local function stormy(): boolean
	local phase = state:GetAttribute("Phase")
	return (phase == "Night" or phase == "Prologue") and localPlayer:GetAttribute("Ready") == true
end

local strength = 0.35
RunService.RenderStepped:Connect(function(dt)
	-- ease between calm and storm wind, with slow gusts on top
	local target = if stormy() then 1 else 0.35
	strength += (target - strength) * math.min(1, dt * 0.5)
	local t = os.clock()
	local gust = strength * (0.65 + 0.35 * math.sin(t * 0.7))
	local eye = camera.CFrame.Position
	for part, item in items do
		if (item.pivot - eye).Magnitude < NEAR then
			local rotation
			if item.flutter then
				local yaw = math.rad(FLUTTER_DEGREES * gust * math.sin(t * 3.1 + item.phase))
				local roll = math.rad(4 * gust * math.sin(t * 5.3 + item.phase))
				rotation = CFrame.Angles(0, yaw, roll)
			else
				local swing = math.rad(SWAY_DEGREES * gust * math.sin(t * 2.2 + item.phase))
				local wobble = math.rad(SWAY_DEGREES * 0.4 * gust * math.sin(t * 1.7 + item.phase * 1.3))
				rotation = CFrame.Angles(wobble, 0, swing)
			end
			part.CFrame = CFrame.new(item.pivot) * rotation * CFrame.new(-item.pivot) * item.base
		end
	end
end)
