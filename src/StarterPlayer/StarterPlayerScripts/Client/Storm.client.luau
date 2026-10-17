-- Storm (client): rain, storm clouds, ambient sound, lightning and thunder.
-- Purely visual/audio and runs on each player's device, so it costs the server nothing.
-- The storm is on during the opening incident and at night; calm during the day.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local state = ReplicatedStorage:WaitForChild("GameState")
local camera = Workspace.CurrentCamera
local SoundFx = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SoundFx"))
local localPlayer = game:GetService("Players").LocalPlayer

-- Sounds (free Creator Store audio; swap the IDs here to change them)
local SOUND_IDS = {
	waves = "rbxassetid://3159087887",
	wind = "rbxassetid://9120610116",
	rain = "rbxassetid://365362615",
	thunder = { "rbxassetid://9120016241", "rbxassetid://9120016037", "rbxassetid://9120016256" },
}

local function makeSound(name, id, looped)
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Looped = looped
	sound.Volume = 0
	sound.SoundGroup = SoundFx.getGroup("Ambience")
	sound.Parent = SoundService
	return sound
end

local waves = makeSound("StormWaves", SOUND_IDS.waves, true)
local wind = makeSound("StormWind", SOUND_IDS.wind, true)
local rain = makeSound("StormRain", SOUND_IDS.rain, true)
waves:Play()
wind:Play()
rain:Play()

local thunderSounds = {}
for index, id in SOUND_IDS.thunder do
	thunderSounds[index] = makeSound("Thunder" .. index, id, false)
	thunderSounds[index].Volume = 0.7
end

---------------------------------------------------------------------
-- Rain: an invisible box above the camera that emits stretched raindrops
---------------------------------------------------------------------

local rainBox = Instance.new("Part")
rainBox.Name = "RainEmitter"
rainBox.Size = Vector3.new(140, 1, 140)
rainBox.Transparency = 1
rainBox.Anchored = true
rainBox.CanCollide = false
rainBox.CanQuery = false
rainBox.CanTouch = false
rainBox.Parent = Workspace

local drops = Instance.new("ParticleEmitter")
drops.Name = "Rain"
drops.Shape = Enum.ParticleEmitterShape.Box
drops.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
drops.EmissionDirection = Enum.NormalId.Bottom
drops.Orientation = Enum.ParticleOrientation.VelocityParallel
drops.Speed = NumberRange.new(90, 110)
drops.Lifetime = NumberRange.new(0.6, 0.8)
drops.Size = NumberSequence.new(0.3)
-- V3: a negative squash stretches each drop along its fall into a streak (it was positive, which flattened
-- the drops into faint horizontal dashes); bigger and brighter so the rain reads
drops.Squash = NumberSequence.new(-2.5)
drops.Transparency = NumberSequence.new(0.4)
drops.Color = ColorSequence.new(Color3.fromRGB(205, 218, 236))
drops.LightEmission = 0.35
drops.Acceleration = Vector3.new(6, 0, 3) -- a little wind slant
drops.Rate = 0
drops.Parent = rainBox

-- V3: rain sheets: long faint streaks in four boxes around the camera (never on top of it), so the storm
-- is visible across the sea too. Computers only: phones keep the lighter rain (the S4.4 render budget).
local SHEET_OFFSETS = { Vector3.new(170, 70, 0), Vector3.new(-170, 70, 0), Vector3.new(0, 70, 170), Vector3.new(0, 70, -170) }
local sheetBoxes = {}
local sheetEmitters = {}
for index, _ in SHEET_OFFSETS do
	local box = Instance.new("Part")
	box.Name = "RainSheets" .. index
	box.Size = Vector3.new(220, 1, 220)
	box.Transparency = 1
	box.Anchored = true
	box.CanCollide = false
	box.CanQuery = false
	box.CanTouch = false
	box.Parent = Workspace
	local sheet = Instance.new("ParticleEmitter")
	sheet.Name = "Sheets"
	sheet.Shape = Enum.ParticleEmitterShape.Box
	sheet.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	sheet.EmissionDirection = Enum.NormalId.Bottom
	sheet.Orientation = Enum.ParticleOrientation.VelocityParallel
	sheet.Speed = NumberRange.new(110, 130)
	sheet.Lifetime = NumberRange.new(1.2, 1.5)
	sheet.Size = NumberSequence.new(2.5)
	sheet.Squash = NumberSequence.new(-2.8)
	sheet.Transparency = NumberSequence.new(0.8)
	sheet.Color = ColorSequence.new(Color3.fromRGB(190, 205, 225))
	sheet.LightEmission = 0.15
	sheet.Acceleration = Vector3.new(6, 0, 3)
	sheet.Rate = 0
	sheet.Parent = box
	sheetBoxes[index] = box
	sheetEmitters[index] = sheet
end

RunService.RenderStepped:Connect(function()
	local position = camera.CFrame.Position
	rainBox.CFrame = CFrame.new(position.X, position.Y + 45, position.Z)
	local ground = Vector3.new(position.X, 0, position.Z)
	for index, offset in SHEET_OFFSETS do
		sheetBoxes[index].CFrame = CFrame.new(ground + offset)
	end
end)

---------------------------------------------------------------------
-- Clouds
---------------------------------------------------------------------

local clouds = Workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
clouds.Parent = Workspace.Terrain

-- V1: the sea swells and the sky closes over in the storm (both are local to this device)
local sky = Lighting:FindFirstChildOfClass("Sky")
local CALM = {
	clouds = { Cover = 0.78, Density = 0.55, Color = Color3.fromRGB(176, 182, 190) },
	volumes = { waves = 0.45, wind = 0, rain = 0 },
	rainRate = 0,
	sea = { WaterWaveSize = 0.35, WaterWaveSpeed = 14 },
	stars = 1500,
}
local STORM = {
	clouds = { Cover = 0.8, Density = 0.6, Color = Color3.fromRGB(96, 106, 120) },
	volumes = { waves = 0.25, wind = 0.35, rain = 0.5 },
	rainRate = 900,
	sea = { WaterWaveSize = 0.85, WaterWaveSpeed = 26 },
	stars = 0,
}

local stormy = nil
local function setStorm(on)
	if stormy == on then
		return
	end
	stormy = on
	local preset = if on then STORM else CALM
	local info = TweenInfo.new(4, Enum.EasingStyle.Sine)
	TweenService:Create(clouds, info, preset.clouds):Play()
	TweenService:Create(Workspace.Terrain, info, preset.sea):Play()
	if sky then
		sky.StarCount = preset.stars
	end
	TweenService:Create(waves, info, { Volume = preset.volumes.waves }):Play()
	TweenService:Create(wind, info, { Volume = preset.volumes.wind }):Play()
	TweenService:Create(rain, info, { Volume = preset.volumes.rain }):Play()
	-- "Low effects" (Settings menu) turns off the rain particles for weaker phones.
	-- Phones and tablets get a lighter storm by default (about a third of the drops, slightly bigger so it
	-- still reads as heavy rain): 900 drops/s was the heaviest thing on screen for mobile GPUs (Oct 12).
	local touch = game:GetService("UserInputService").TouchEnabled
	drops.Size = NumberSequence.new(if touch then 0.36 else 0.3)
	-- S4.4: touch devices are capped at 300 drops/s (the render budget)
	drops.Rate = if localPlayer:GetAttribute("LowEffects") then 0 elseif touch then math.min(300, math.floor(preset.rainRate * 0.35)) else preset.rainRate
	for _, sheet in sheetEmitters do
		sheet.Rate = if localPlayer:GetAttribute("LowEffects") or touch or preset.rainRate == 0 then 0 else 70
	end
end

localPlayer:GetAttributeChangedSignal("LowEffects"):Connect(function()
	local current = stormy
	stormy = nil
	setStorm(current)
end)

-- the storm (rain, thunder) is on the lighthouse island: only the voyage crew is in it, not the harbor
local function refresh()
	local phase = state:GetAttribute("Phase")
	setStorm((phase == "Night" or phase == "Prologue") and localPlayer:GetAttribute("Ready") == true)
end
state:GetAttributeChangedSignal("Phase"):Connect(refresh)
localPlayer:GetAttributeChangedSignal("Ready"):Connect(refresh)
refresh()

---------------------------------------------------------------------
-- Focused-beam laser hum: plays from the lamp while the focused beam is on
---------------------------------------------------------------------

task.spawn(function()
	local lampCore = Workspace:WaitForChild("Island"):WaitForChild("LampCore")
	local laser = Instance.new("Sound")
	laser.Name = "FocusedBeamHum"
	laser.SoundId = "rbxassetid://9126086336" -- Pro Sound Effects: pulsing energy tone
	laser.Looped = true
	laser.Volume = 0
	laser.PlaybackSpeed = 1.25
	laser.RollOffMode = Enum.RollOffMode.InverseTapered
	laser.RollOffMinDistance = 60
	laser.RollOffMaxDistance = 500
	laser.SoundGroup = SoundFx.getGroup("SFX")
	laser.Parent = lampCore

	local on = false
	local function refresh()
		local focused = state:GetAttribute("BeamMode") == "focused"
			and (state:GetAttribute("Fuel") or 0) > 0
			and (state:GetAttribute("KeeperUserId") or 0) ~= 0
			and localPlayer:GetAttribute("Ready") == true -- the island lamp is heard by the voyage crew only
		if focused == on then
			return
		end
		on = focused
		if on then
			if not laser.IsPlaying then
				laser:Play()
			end
			TweenService:Create(laser, TweenInfo.new(0.25), { Volume = 0.6 }):Play()
		else
			local fade = TweenService:Create(laser, TweenInfo.new(0.35), { Volume = 0 })
			fade.Completed:Connect(function()
				if not on then
					laser:Stop()
				end
			end)
			fade:Play()
		end
	end
	for _, attribute in { "BeamMode", "Fuel", "KeeperUserId" } do
		state:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
	localPlayer:GetAttributeChangedSignal("Ready"):Connect(refresh)
	refresh()
end)

---------------------------------------------------------------------
-- Lightning: a double flash, then thunder a moment later (sound travels slower than light)
---------------------------------------------------------------------

-- V3: the flash also washes the whole scene (sea included) in cold light through this device's own colour
-- correction, and a bolt strikes the sea somewhere out past the island.
local flashTint = Instance.new("ColorCorrectionEffect")
flashTint.Name = "LightningFlash"
flashTint.TintColor = Color3.fromRGB(205, 220, 255)
flashTint.Brightness = 0
flashTint.Enabled = true
flashTint.Parent = Lighting

local BOLT_SEGMENTS = 9
local boltParts = {}
for index = 1, BOLT_SEGMENTS do
	local part = Instance.new("Part")
	part.Name = "LightningBolt" .. index
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(215, 225, 255)
	part.Transparency = 1
	part.Parent = Workspace
	boltParts[index] = part
end

local function showBolt(visible)
	for _, part in boltParts do
		part.Transparency = if visible then 0 else 1
	end
end

local function placeBolt()
	local origin = camera.CFrame.Position
	local angle = math.random() * math.pi * 2
	local distance = math.random(180, 450) -- farther than this the night haze hides it
	local base = Vector3.new(origin.X + math.cos(angle) * distance, 0, origin.Z + math.sin(angle) * distance)
	local top = base + Vector3.new(math.random(-60, 60), 420, math.random(-60, 60))
	local previous = top
	for index, part in boltParts do
		local point = top:Lerp(base, index / BOLT_SEGMENTS)
		if index < BOLT_SEGMENTS then
			point += Vector3.new(math.random(-25, 25), 0, math.random(-25, 25))
		end
		part.Size = Vector3.new(3, 3, (point - previous).Magnitude)
		part.CFrame = CFrame.lookAt((previous + point) / 2, point)
		previous = point
	end
end

local function flash()
	if not localPlayer:GetAttribute("LowEffects") then
		placeBolt()
		showBolt(true)
		task.delay(0.08, showBolt, false)
		task.delay(0.15, showBolt, true)
		task.delay(0.3, showBolt, false)
	end
	Lighting.ExposureCompensation = 1.6
	flashTint.Brightness = 0.35
	TweenService:Create(Lighting, TweenInfo.new(0.12), { ExposureCompensation = 0 }):Play()
	TweenService:Create(flashTint, TweenInfo.new(0.12), { Brightness = 0 }):Play()
	task.wait(0.18)
	Lighting.ExposureCompensation = 1.1
	flashTint.Brightness = 0.22
	TweenService:Create(Lighting, TweenInfo.new(0.4), { ExposureCompensation = 0 }):Play()
	TweenService:Create(flashTint, TweenInfo.new(0.5), { Brightness = 0 }):Play()
end

task.spawn(function()
	while true do
		task.wait(math.random(7, 16))
		if stormy then
			task.spawn(flash)
			local thunder = thunderSounds[math.random(1, #thunderSounds)]
			task.delay(math.random(3, 15) / 10, function()
				thunder.PlaybackSpeed = math.random(90, 110) / 100
				thunder:Play()
			end)
		end
	end
end)
