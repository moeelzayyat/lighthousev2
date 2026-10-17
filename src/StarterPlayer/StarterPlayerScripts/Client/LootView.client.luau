-- LootView (S4.5, client): makes the loot on the island look alive without the server moving it.
-- The server places each orb once (a short pop when it drops) and then leaves it still; it removes it when it is
-- collected or washes away. Here every landed orb bobs and spins in place, and an orb this player is close to
-- flies to them (the same magnet range and speed the server uses to decide the pickup). Only this client
-- sees these moves, so nothing about idle loot is replicated.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local player = Players.LocalPlayer
local lootFolder = Workspace:WaitForChild("Island"):WaitForChild("Loot")

local MAGNET_SPEED = 35 -- the server's LootService.MAGNET_SPEED

local orbs = {} -- orb -> { position, phase }

local function track(orb)
	if orb:IsA("BasePart") then
		orbs[orb] = { position = nil, phase = math.random() * 10 }
	end
end
for _, orb in lootFolder:GetChildren() do
	track(orb)
end
lootFolder.ChildAdded:Connect(track)
lootFolder.ChildRemoved:Connect(function(orb)
	orbs[orb] = nil
end)

RunService.RenderStepped:Connect(function(dt)
	if next(orbs) == nil then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local me = root and root.Position
	local now = os.clock()
	for orb, view in orbs do
		local landing = orb:GetAttribute("Landing")
		if orb:GetAttribute("Landed") ~= true or typeof(landing) ~= "Vector3" then
			continue -- still popping out (the server's short tween)
		end
		view.position = view.position or landing
		local distance = if me then (me - view.position).Magnitude else math.huge
		local cframe
		if distance <= Config.LOOT_MAGNET_RADIUS and distance > 0.01 then
			view.position += (me - view.position).Unit * math.min(MAGNET_SPEED * dt, distance)
			cframe = CFrame.new(view.position)
		else
			local bob = math.sin(now * 3 + view.phase) * 0.2
			cframe = CFrame.new(view.position + Vector3.new(0, bob, 0)) * CFrame.Angles(0, now * 2, 0)
		end
		orb.CFrame = cframe
		local pillar = orb:FindFirstChild("Pillar")
		if pillar then
			pillar.CFrame = cframe * CFrame.new(0, 7, 0)
		end
	end
end)
