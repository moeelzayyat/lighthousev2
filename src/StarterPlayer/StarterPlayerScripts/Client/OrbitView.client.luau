--!strict
-- OrbitView (S6.3): draws the Orbiting Blades around every player who carries them (the server-set player
-- attribute "OrbitWeapon"). Cosmetic only: the server does the cutting (OrbitService) and there is nothing to
-- aim. Each blade is the pirate cutlass in ReplicatedStorage.ItemModels.OrbitCutlass (BLADE1, owner 2026-10-20:
-- "looks bad, like no 3D model"): two parts, the steel-and-gold body and the glowing edge (tinted per weapon, with a
-- short trail), so 6 parts per carrier, all moved together each frame with one BulkMoveTo; no lights, no sounds,
-- nothing replicated.

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

local template = ReplicatedStorage:WaitForChild("ItemModels"):WaitForChild("OrbitCutlass") :: Model
-- the edge's glow per weapon (the weapon's own colour is the steel-grey it always had)
local GLOW: { [string]: Color3 } = {
	OrbitingBlades = Color3.fromRGB(90, 230, 255), -- sea glow
	TidecallerBlades = Color3.fromRGB(70, 255, 190), -- tide green
}

type View = { weaponId: string, weapon: any, parts: { BasePart }, offsets: { CFrame } }
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
	local offsets: { CFrame } = {}
	local body = template.PrimaryPart :: BasePart
	local glow = GLOW[weaponId] or weapon.color
	for i = 1, weapon.blades do
		for _, source in template:GetChildren() do
			if source:IsA("BasePart") then
				local piece = source:Clone()
				piece.Name = "Blade" .. i .. source.Name
				piece.Anchored = true
				piece.CanCollide = false
				piece.CanQuery = false
				piece.CanTouch = false
				piece.CastShadow = false
				if source.Name == "Glow" then
					piece.Color = glow
					local trail = piece:FindFirstChildOfClass("Trail")
					if trail then
						trail.Color = ColorSequence.new(glow)
					end
				end
				piece.CFrame = PARKED
				piece.Parent = folder
				table.insert(parts, piece)
				-- where this piece sits on the blade (the body is the blade's own frame)
				table.insert(offsets, body.CFrame:ToObjectSpace(source.CFrame))
			end
		end
	end
	views[player] = { weaponId = weaponId, weapon = weapon, parts = parts, offsets = offsets }
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
		local count = view.weapon.blades
		local perBlade = #view.parts // count
		for k, piece in view.parts do
			local i = (k - 1) // perBlade + 1
			local frame = PARKED
			if root and root:IsA("BasePart") then
				local center = root.Position + Vector3.new(0, HEIGHT, 0)
				local angle = math.rad(t * view.weapon.spin) + (i - 1) * 2 * math.pi / count
				local at = center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * view.weapon.range
				-- the blade lies flat along the circle, its glowing edge facing out and its tip leading the spin
				frame = CFrame.lookAt(at, center) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(math.pi, 0, 0) * view.offsets[k]
			end
			table.insert(parts, piece)
			table.insert(frames, frame)
		end
	end
	Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
end)
