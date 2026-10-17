--!strict
-- OilCarry (S5.3): the oil barrel a player carries from the pile to the fuel tank or a cannon. The oil prompts
-- (Encounter), the cannons (DefenseService) and the trip back to the ship (Crew) all use this one module
-- instead of handing each other functions.

local OilCarry = {}

function OilCarry.has(player: Player): boolean
	return player:GetAttribute("CarryingOil") == true
end

function OilCarry.remove(player: Player)
	player:SetAttribute("CarryingOil", false)
	local character = player.Character
	local barrel = character and character:FindFirstChild("CarriedOil")
	if barrel then
		barrel:Destroy()
	end
end

function OilCarry.give(player: Player)
	player:SetAttribute("CarryingOil", true)

	-- Visual: a small barrel strapped to the player's back
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if character and root and root:IsA("BasePart") then
		local barrel = Instance.new("Part")
		barrel.Name = "CarriedOil"
		barrel.Shape = Enum.PartType.Cylinder
		barrel.Size = Vector3.new(2.2, 1.6, 1.6)
		barrel.Color = Color3.fromRGB(45, 40, 35)
		barrel.Material = Enum.Material.Metal
		barrel.CanCollide = false
		barrel.CanQuery = false
		barrel.Massless = true
		barrel.CFrame = root.CFrame * CFrame.new(0, 0, 1.3) * CFrame.Angles(0, 0, math.rad(90))
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = barrel
		weld.Parent = barrel
		barrel.Parent = character
	end
end

return OilCarry
