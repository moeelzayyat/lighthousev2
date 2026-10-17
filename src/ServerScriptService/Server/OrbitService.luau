--!strict
-- OrbitService (S6.3, Encounter domain): the Orbit weapon archetype (Orbiting Blades first, sold by the island
-- merchant). Blades circle the player and cut the creatures they pass: no aiming, so it plays the same on a
-- phone. Every `cooldown` seconds each carrier damages up to `maxTargets` creatures within `hitRadius` of them
-- through CreatureService.damageArea; the numbers come from StatPipeline.weapon (with the merchant's damage
-- boost). Who carries blades: the server-set player attribute "OrbitWeapon". Each client draws the blades
-- (OrbitView); the server sends nothing extra.
--   step(now, carriers)  the cuts due now (pure apart from each carrier's next cut time; tested directly)
--   start(deps)          checks the crew 10 times a second and makes the cuts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Weapons = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Weapons")) :: any
local StatPipeline = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StatPipeline"))

local OrbitService = {}

export type Carrier = { key: any, weaponId: string, position: Vector3, damageBoost: number }
export type Cut = { key: any, position: Vector3, radius: number, damage: number, maxTargets: number, source: string }

local nextCut: { [any]: number } = {}

function OrbitService.step(now: number, carriers: { Carrier }): { Cut }
	local cuts: { Cut } = {}
	local seen: { [any]: boolean } = {}
	for _, c in carriers do
		local w = Weapons[c.weaponId]
		if w and w.archetype == "Orbit" then
			seen[c.key] = true
			local due = nextCut[c.key]
			if due == nil or now >= due then
				local stats = StatPipeline.weapon(c.weaponId, { damage = { add = { c.damageBoost } } })
				nextCut[c.key] = now + stats.cooldown
				table.insert(cuts, {
					key = c.key,
					position = c.position,
					radius = stats.hitRadius,
					damage = stats.damage,
					maxTargets = stats.maxTargets,
					source = "Weapon:" .. c.weaponId,
				})
			end
		end
	end
	for key in nextCut do
		if not seen[key] then
			nextCut[key] = nil -- blades gone (wiped, died, left the crew): the next carrying starts fresh
		end
	end
	return cuts
end

export type Deps = {
	players: () -> { Player },
	keeper: () -> Player?,
	damageArea: (position: Vector3, radius: number, amount: number, maxTargets: number, source: string, attacker: any) -> any,
}

function OrbitService.start(deps: Deps)
	local last = 0
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - last < 0.1 then
			return
		end
		last = now
		local carriers: { Carrier } = {}
		local keeper = deps.keeper()
		for _, player in deps.players() do
			local weaponId = player:GetAttribute("OrbitWeapon")
			-- the Keeper's hands are on the lamp (like attacks); only the crew on the island cuts
			if type(weaponId) == "string" and player:GetAttribute("Ready") == true and player ~= keeper then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
					local boost = player:GetAttribute("Boost_WeaponDamage")
					table.insert(carriers, { key = player, weaponId = weaponId, position = root.Position, damageBoost = if type(boost) == "number" then boost else 0 })
				end
			end
		end
		for _, cut in OrbitService.step(now, carriers) do
			deps.damageArea(cut.position, cut.radius, cut.damage, cut.maxTargets, cut.source, cut.key)
		end
	end)
end

return OrbitService
