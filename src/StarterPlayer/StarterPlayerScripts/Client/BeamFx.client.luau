--!strict
-- BeamFx (client, V2 visual overhaul): makes the lighthouse beam read as light instead of a flat wedge.
-- The server still owns the beam: its angle, width, colour and on/off live on Island.BeamEmitter.LightBeam
-- (LampService). This script only restyles that beam on this device and adds softer layers that copy it,
-- so it changes nothing about where the beam hits or what it does.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("GameState")

-- Layers from the widest haze to a narrow bright core. Added together (LightEmission 1) they give a bright
-- middle; the wide layers use Roblox's built-in soft smoke texture so their edges feather out instead of
-- ending in a hard line, and every layer fades out before the end so the beam never cuts into the ground.
local SOFT_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
type Layer = { name: string, width: number, alpha: { { number } }, brightness: number, soft: boolean }
local LAYERS: { Layer } = {
	{ name = "Haze", width = 1, alpha = { { 0, 0.3 }, { 0.6, 0.45 }, { 0.88, 0.85 }, { 1, 1 } }, brightness = 1, soft = true },
	{ name = "Mid", width = 0.62, alpha = { { 0, 0.25 }, { 0.55, 0.4 }, { 0.85, 0.85 }, { 1, 1 } }, brightness = 1, soft = true },
	{ name = "Inner", width = 0.32, alpha = { { 0, 0.15 }, { 0.5, 0.4 }, { 0.82, 0.85 }, { 1, 1 } }, brightness = 1.2, soft = true },
	{ name = "Core", width = 0.09, alpha = { { 0, 0.05 }, { 0.3, 0.45 }, { 0.7, 0.9 }, { 1, 1 } }, brightness = 1.6, soft = false },
}

local function sequence(points: { { number } }): NumberSequence
	local keypoints = {}
	for _, point in points do
		table.insert(keypoints, NumberSequenceKeypoint.new(point[1], point[2]))
	end
	return NumberSequence.new(keypoints)
end

local function style(beam: Beam, layer: Layer)
	beam.Transparency = sequence(layer.alpha)
	beam.Texture = if layer.soft then SOFT_TEXTURE else ""
	beam.TextureMode = Enum.TextureMode.Stretch
	beam.TextureLength = 1
end

local island = Workspace:WaitForChild("Island")
local emitter = island:WaitForChild("BeamEmitter") :: BasePart
local main = emitter:WaitForChild("LightBeam") :: Beam

-- the server's beam becomes the haze layer
style(main, LAYERS[1])
main.Width0 = 2
main.Segments = 20

local extra: { { beam: Beam, layer: Layer } } = {}
for index = 2, #LAYERS do
	local layer = LAYERS[index]
	local beam = main:Clone()
	beam.Name = "LightBeam" .. layer.name
	style(beam, layer)
	beam.Width0 = if layer.name == "Core" then 0.8 else 1.4
	beam.Parent = emitter
	table.insert(extra, { beam = beam, layer = layer })
end

---------------------------------------------------------------------
-- Rain caught in the light: bright streaks that fall through the beam during the storm
---------------------------------------------------------------------

local glintBox = Instance.new("Part")
glintBox.Name = "BeamGlints"
glintBox.Anchored = true
glintBox.CanCollide = false
glintBox.CanQuery = false
glintBox.CanTouch = false
glintBox.Transparency = 1
glintBox.Size = Vector3.new(20, 6, 70)
glintBox.Parent = Workspace

local glints = Instance.new("ParticleEmitter")
glints.Name = "Glints"
glints.Shape = Enum.ParticleEmitterShape.Box
glints.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
glints.EmissionDirection = Enum.NormalId.Bottom
glints.Orientation = Enum.ParticleOrientation.VelocityParallel
glints.Speed = NumberRange.new(70, 90)
glints.Lifetime = NumberRange.new(0.18, 0.3)
glints.Size = NumberSequence.new(0.1)
glints.Squash = NumberSequence.new(3)
glints.Transparency = sequence({ { 0, 1 }, { 0.3, 0.2 }, { 0.7, 0.3 }, { 1, 1 } })
glints.LightEmission = 1
glints.LightInfluence = 0
glints.Acceleration = Vector3.new(6, 0, 3) -- the same wind slant as the rain
glints.Rate = 0
glints.Parent = glintBox

local function stormy(): boolean
	local phase = state:GetAttribute("Phase")
	return (phase == "Night" or phase == "Prologue") and localPlayer:GetAttribute("Ready") == true
end

RunService.Heartbeat:Connect(function()
	local lit = main.Enabled
	for _, entry in extra do
		local beam, layer = entry.beam, entry.layer
		beam.Enabled = lit
		beam.Color = main.Color
		beam.Width1 = math.max(main.Width1 * layer.width, 2)
		beam.Brightness = main.Brightness * layer.brightness
	end

	-- the glints sit in the first two-thirds of the beam, where it is still bright
	local width = main.Width1
	glintBox.Size = Vector3.new(math.max(width * 0.35, 6), 8, 70)
	glintBox.CFrame = emitter.CFrame * CFrame.new(0, 0, -45)
	local on = lit and stormy() and not localPlayer:GetAttribute("LowEffects")
	glints.Color = main.Color
	-- touch devices get fewer (the S4.4 render budget)
	glints.Rate = if not on then 0 elseif UserInputService.TouchEnabled then 60 else 160
end)
