--!strict
-- HitFx (client, V7 visual overhaul): a small camera shake when a cannon fires close by and when this player
-- takes a big hit. Off with Low effects. Purely visual and local to this device.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local CANNON_RANGE = 70 -- studs: a cannon firing closer than this shakes the camera a little
local BIG_HIT = 8 -- health lost in one hit that counts as a big hit

local trauma = 0 -- 0..1, decays quickly; the shake grows with its square

local function kick(amount: number)
	if localPlayer:GetAttribute("LowEffects") then
		return
	end
	trauma = math.min(1, trauma + amount)
end

-- cannon shots: the server adds a short-lived "Flash" part at the muzzle (DefenseService)
task.spawn(function()
	local defenses = Workspace:WaitForChild("Island"):WaitForChild("Defenses")
	defenses.ChildAdded:Connect(function(child: Instance)
		if child.Name == "Flash" and child:IsA("BasePart") then
			local distance = (child.Position - camera.CFrame.Position).Magnitude
			if distance < CANNON_RANGE then
				kick(0.35 * (1 - distance / CANNON_RANGE))
			end
		end
	end)
end)

-- big hits on this player
local function watch(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local last = humanoid.Health
	humanoid.HealthChanged:Connect(function(health)
		local drop = last - health
		last = health
		if drop >= BIG_HIT then
			kick(math.min(0.6, drop / 40))
		end
	end)
end
if localPlayer.Character then
	task.spawn(watch, localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(watch)

-- after the camera has moved this frame, nudge it; the camera rebuilds its own position every frame, so nothing drifts
RunService:BindToRenderStep("HitFxShake", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
	if trauma <= 0 then
		return
	end
	local t = os.clock()
	local s = trauma * trauma
	local pitch = math.rad(1.2 * s * math.noise(t * 25, 1.7))
	local yaw = math.rad(1.2 * s * math.noise(t * 25, 5.3))
	local roll = math.rad(0.8 * s * math.noise(t * 25, 9.1))
	camera.CFrame = camera.CFrame * CFrame.Angles(pitch, yaw, roll)
	trauma = math.max(0, trauma - dt * 2.5)
end)
