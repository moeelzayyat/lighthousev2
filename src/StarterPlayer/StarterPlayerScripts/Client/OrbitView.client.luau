--!strict
-- OrbitView (S6.3): draws the Orbiting Blades around every player who carries them (the server-set player
-- attribute "OrbitWeapon"). Cosmetic only: the server does the cutting (OrbitService) and there is nothing to
-- aim. `blades` small parts per carrier (3), moved together each frame with one BulkMoveTo; no lights, no
-- sounds, nothing replicated.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Weapons = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Weapons")) :: any

local HEIGHT = -0.8 -- blades circle at hip height
local PARKED = CFrame.new(0, -500, 0) -- where a blade waits while its carrier has no character

local folder = Instance.new("Folder")
folder.Name = "OrbitViews"
folder.Parent = Workspace

type View = { weaponId: string, weapon: any, parts: { BasePart } }
local views: { [Player]: View } = {}

local function clear(player: Player)
	local view = views[player]
	if view then
		for _, part in view.parts do
			part:Destroy()
		end
		views[player] = nil
	end
end

local function build(player: Player, weaponId: string)
	local weapon = Weapons[weaponId]
	if not weapon or weapon.archetype ~= "Orbit" then
		return
	end
	local parts: { BasePart } = {}
	for i = 1, weapon.blades do
		local blade = Instance.new("Part")
		blade.Name = "Blade" .. i
		blade.Anchored = true
		blade.CanCollide = false
		blade.CanQuery = false
		blade.CanTouch = false
		blade.CastShadow = false
		blade.Size = Vector3.new(0.2, 0.5, 2.2)
		blade.Material = Enum.Material.Metal
		blade.Color = weapon.color
		blade.CFrame = PARKED
		blade.Parent = folder
		table.insert(parts, blade)
	end
	views[player] = { weaponId = weaponId, weapon = weapon, parts = parts }
end

local function sync(player: Player)
	local weaponId = player:GetAttribute("OrbitWeapon")
	local view = views[player]
	if view and view.weaponId ~= weaponId then
		clear(player)
	end
	if type(weaponId) == "string" and not views[player] then
		build(player, weaponId)
	end
end

local function watch(player: Player)
	player:GetAttributeChangedSignal("OrbitWeapon"):Connect(function()
		sync(player)
	end)
	sync(player)
end
Players.PlayerAdded:Connect(watch)
for _, player in Players:GetPlayers() do
	watch(player)
end
Players.PlayerRemoving:Connect(clear)

RunService.RenderStepped:Connect(function()
	if next(views) == nil then
		return
	end
	local t = os.clock()
	local parts: { BasePart } = {}
	local frames: { CFrame } = {}
	for player, view in views do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local count = #view.parts
		for i, blade in view.parts do
			local frame = PARKED
			if root and root:IsA("BasePart") then
				local center = root.Position + Vector3.new(0, HEIGHT, 0)
				local angle = math.rad(t * view.weapon.spin) + (i - 1) * 2 * math.pi / count
				local at = center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * view.weapon.range
				-- the long side runs along the circle
				frame = CFrame.lookAt(at, center) * CFrame.Angles(0, math.rad(90), 0)
			end
			table.insert(parts, blade)
			table.insert(frames, frame)
		end
	end
	Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
end)
