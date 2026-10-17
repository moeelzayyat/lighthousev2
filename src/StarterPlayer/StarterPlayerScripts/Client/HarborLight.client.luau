--!strict
-- HarborLight (client, V6 visual overhaul): golden hour in the harbor. The server lights the whole place for the
-- voyage (GameState: an overcast day or a storm night); while this player stands on the harbor island, this device
-- shows a warm dusk instead, and gives the server's lighting back the moment they leave (or sail).
-- Purely visual and local to this device.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local localPlayer = Players.LocalPlayer
local HARBOR_RADIUS = 260 -- studs around the harbor spawn

local DUSK: { [string]: any } = {
	ClockTime = 17.7,
	Brightness = 2.2,
	Ambient = Color3.fromRGB(92, 78, 74),
	OutdoorAmbient = Color3.fromRGB(150, 120, 102),
}
local DUSK_ATMOSPHERE: { [string]: any } = {
	Density = 0.32,
	Offset = 0.2,
	Haze = 1.6,
	Glare = 0.35,
	Color = Color3.fromRGB(214, 164, 128),
	Decay = Color3.fromRGB(116, 86, 84),
}

local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Lighting:WaitForChild("Atmosphere")

-- the server's latest values for every property this script overrides
local server: { [Instance]: { [string]: any } } = { [Lighting] = {}, [atmosphere] = {} }
local presets: { [Instance]: { [string]: any } } = { [Lighting] = DUSK, [atmosphere] = DUSK_ATMOSPHERE }
local applying = false
local inHarbor = false

local function set(instance: Instance, values: { [string]: any })
	applying = true
	for property, value in values do
		(instance :: any)[property] = value
	end
	applying = false
end

for instance, preset in presets do
	for property in preset do
		server[instance][property] = (instance :: any)[property]
		instance:GetPropertyChangedSignal(property):Connect(function()
			if applying then
				return
			end
			-- a change from the server (a phase change or its tween): remember it, and keep the dusk while here
			server[instance][property] = (instance :: any)[property]
			if inHarbor then
				set(instance, { [property] = preset[property] })
			end
		end)
	end
end

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.5 then
		return
	end
	elapsed = 0
	local character = localPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local spawnAt = Config.LOBBY_SPAWN
	local here = root ~= nil and Vector2.new(root.Position.X - spawnAt.X, root.Position.Z - spawnAt.Z).Magnitude < HARBOR_RADIUS
	if here == inHarbor then
		return
	end
	inHarbor = here
	for instance, preset in presets do
		set(instance, if here then preset else server[instance])
	end
end)
