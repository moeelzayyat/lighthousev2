--!strict
-- PetView (PET.1, D-051): draws each player's pet (player attribute "Pet") as a small model that bobs over its
-- owner's shoulder and flies to the Shells orb the server sent it for (orb attribute PetClaim = the owner's UserId).
-- Looks only: the server (LootService, Shared/PetRules) decides which orb the pet brings back and when. One small model per player (render budget).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Items = require(Shared:WaitForChild("Items")) :: any
local ItemModels = ReplicatedStorage:WaitForChild("ItemModels")

type Pet = { id: string, model: Model, pos: Vector3 }
local pets: { [Player]: Pet } = {}

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

RunService.RenderStepped:Connect(function(dt: number)
	local now = os.clock()
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
			local fresh: Pet = { id = petId, model = model, pos = root.Position + Vector3.new(0, 4, 0) }
			pets[player] = fresh
			entry = fresh
		end
		local pet = entry :: Pet
		-- home: just over the right shoulder, bobbing; away: hovering over the orb it is fetching
		local home = (root.CFrame * CFrame.new(2.2, 2.6, 1)).Position + Vector3.new(0, math.sin(now * 3 + player.UserId % 7) * 0.3, 0)
		local target = fetching(player.UserId)
		local goal = if target then target + Vector3.new(0, 1.2, 0) else home
		if target then
			-- a little faster than the server's trip, so it is there when the orb is taken
			local step = goal - pet.pos
			local reach = Config.PET_SPEED * 1.2 * dt
			pet.pos = if step.Magnitude <= reach then goal else pet.pos + step.Unit * reach
		else
			pet.pos = pet.pos:Lerp(goal, math.clamp(dt * 6, 0, 1))
		end
		local ahead = if (goal - pet.pos).Magnitude > 0.3 then goal else pet.pos + root.CFrame.LookVector
		pet.model:PivotTo(CFrame.lookAt(pet.pos, Vector3.new(ahead.X, pet.pos.Y, ahead.Z)))
	end
	for player in pets do
		if player.Parent ~= Players then
			drop(player)
		end
	end
end)
