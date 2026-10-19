--!strict
-- PetView (PET.1, D-051): draws each player's pet (player attribute "Pet") as a small model beside its owner and
-- moves it to the Shells orb the server sent it for (orb attribute PetClaim = the owner's UserId).
-- Looks only: the server (LootService, Shared/PetRules) decides which orb the pet brings back and when. One small model per player (render budget).
-- PET.2 (D-054): each pet moves its own way (Items `petMotion`): "fly" bobs over the right shoulder, "float" drifts
-- higher over the left shoulder with a slow sway, "walk" follows at your feet on the ground. `petGlow` = { r, g, b }
-- adds a soft light.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Items = require(Shared:WaitForChild("Items")) :: any
local ItemModels = ReplicatedStorage:WaitForChild("ItemModels")

type Pet = { id: string, model: Model, pos: Vector3, motion: string, half: number }
local pets: { [Player]: Pet } = {}

local groundRay = RaycastParams.new()
groundRay.FilterType = Enum.RaycastFilterType.Exclude

local function makePet(petId: string): Model?
	local item = Items[petId]
	local template = item and ItemModels:FindFirstChild(item.model or petId)
	if not template or not template:IsA("Model") then
		return nil
	end
	local model = template:Clone()
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	local glow = item.petGlow
	if type(glow) == "table" and model.PrimaryPart and not model.PrimaryPart:FindFirstChildWhichIsA("PointLight") then
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(glow[1], glow[2], glow[3])
		light.Range = 10
		light.Brightness = 1.5
		light.Parent = model.PrimaryPart
	end
	model.Name = "Pet_" .. petId
	model.Parent = Workspace
	return model
end

local function drop(player: Player)
	local entry = pets[player]
	if entry then
		entry.model:Destroy()
		pets[player] = nil
	end
end

-- where the orb this player's pet was sent for lies, or nil
local function fetching(userId: number): Vector3?
	local island = Workspace:FindFirstChild("Island")
	local loot = island and island:FindFirstChild("Loot")
	if not loot then
		return nil
	end
	for _, orb in loot:GetChildren() do
		if orb:GetAttribute("PetClaim") == userId then
			local at = orb:GetAttribute("Landing")
			return if typeof(at) == "Vector3" then at else (orb :: BasePart).Position
		end
	end
	return nil
end

-- the ground under a point (characters and pets ignored), or nil over the sea
local function groundY(at: Vector3, ignore: { Instance }): number?
	groundRay.FilterDescendantsInstances = ignore
	local hit = Workspace:Raycast(at + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0), groundRay)
	return if hit then hit.Position.Y else nil
end

RunService.RenderStepped:Connect(function(dt: number)
	local now = os.clock()
	local ignore: { Instance } = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	for _, entry in pets do
		table.insert(ignore, entry.model)
	end
	for _, player in Players:GetPlayers() do
		local petId = player:GetAttribute("Pet")
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if type(petId) ~= "string" or not root then
			drop(player)
			continue
		end
		local entry = pets[player]
		if not entry or entry.id ~= petId then
			drop(player)
			local model = makePet(petId)
			if not model then
				continue
			end
			local motion = Items[petId].petMotion or "fly"
			local fresh: Pet = { id = petId, model = model, pos = root.Position + Vector3.new(0, 4, 0), motion = motion, half = model:GetExtentsSize().Y / 2 }
			pets[player] = fresh
			entry = fresh
		end
		local pet = entry :: Pet
		local phase = now + player.UserId % 7
		-- home: where it waits beside its owner; away: over the orb it is fetching
		local home: Vector3
		if pet.motion == "float" then
			home = (root.CFrame * CFrame.new(-2.4, 3.4, 1)).Position + Vector3.new(0, math.sin(phase * 1.6) * 0.6, 0)
		elseif pet.motion == "walk" then
			home = (root.CFrame * CFrame.new(2.6, 0, 2)).Position
		else
			home = (root.CFrame * CFrame.new(2.2, 2.6, 1)).Position + Vector3.new(0, math.sin(phase * 3) * 0.3, 0)
		end
		local target = fetching(player.UserId)
		local goal = if target then target + Vector3.new(0, if pet.motion == "walk" then 0 else 1.2, 0) else home
		if target then
			-- a little faster than the server's trip, so it is there when the orb is taken
			local step = goal - pet.pos
			local reach = Config.PET_SPEED * 1.2 * dt
			pet.pos = if step.Magnitude <= reach then goal else pet.pos + step.Unit * reach
		else
			pet.pos = pet.pos:Lerp(goal, math.clamp(dt * (if pet.motion == "float" then 3.5 else 6), 0, 1))
		end
		if pet.motion == "walk" then
			-- on the ground, with a little hop while it moves
			local y = groundY(pet.pos, ignore)
			local moving = (goal - pet.pos).Magnitude > 0.5
			local hop = if moving then math.abs(math.sin(now * 12)) * 0.25 else 0
			pet.pos = Vector3.new(pet.pos.X, (y or (root.Position.Y - 2.5)) + pet.half + hop, pet.pos.Z)
		end
		local ahead = if (goal - pet.pos).Magnitude > 0.3 then goal else pet.pos + root.CFrame.LookVector
		local facing = CFrame.lookAt(pet.pos, Vector3.new(ahead.X, pet.pos.Y, ahead.Z))
		if pet.motion == "float" then
			facing *= CFrame.Angles(0, 0, math.sin(phase * 1.1) * 0.12) -- a slow sway
		end
		pet.model:PivotTo(facing)
	end
	for player in pets do
		if player.Parent ~= Players then
			drop(player)
		end
	end
end)
