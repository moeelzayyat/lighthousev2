--!strict
-- RescueService (LO.2, Encounter domain): the Shipwreck Rescue event voyage (D-037). When a voyage whose definition
-- has `rescue` starts, a wreck lies on the shore with `rescue.castaways` castaways inside. A crew member carries one
-- at a time (not while carrying oil) to the shelter by the lighthouse door: each one brought in pays the crew
-- `rescue.shells` Shells. A carrier who falls drops theirs back at the wreck; nothing is lost and nothing runs out.
-- At the end of the voyage (not an abandoned one) every crew member gets 1 Pearl for every 2 castaways saved
-- (GrantService, claim "<voyage>:rescue:<userId>"), and, when every castaway was saved, the event's reward item
-- (`rescue.reward`, claim "event:<event>:<item>", once per profile).
-- `Rescue` (pure: the count and the rewards) is tested on its own; `start` adds the wreck, prompts and visuals.

local RescueService = {}

export type Rescue = { total: number, left: number, saved: number, carriers: { [number]: boolean } }

-- Pure: one voyage's castaways
function RescueService.new(total: number): Rescue
	return { total = total, left = total, saved = 0, carriers = {} }
end

-- A crew member takes one from the wreck. Returns nil, or why not.
function RescueService.pickUp(r: Rescue, userId: number, carryingOil: boolean): string?
	if r.carriers[userId] then
		return "You're already carrying a castaway. Bring them to the shelter by the lighthouse."
	elseif carryingOil then
		return "Your hands are full of oil. Take it to the fuel tank first."
	elseif r.left <= 0 then
		return "Everyone has left the wreck."
	end
	r.left -= 1
	r.carriers[userId] = true
	return nil
end

-- They reach the shelter. Returns true when a castaway was brought in.
function RescueService.deliver(r: Rescue, userId: number): boolean
	if not r.carriers[userId] then
		return false
	end
	r.carriers[userId] = nil
	r.saved += 1
	return true
end

-- They fell or left: the castaway goes back to the wreck.
function RescueService.drop(r: Rescue, userId: number): boolean
	if not r.carriers[userId] then
		return false
	end
	r.carriers[userId] = nil
	r.left += 1
	return true
end

-- What each crew member gets at the end of the voyage
function RescueService.reward(r: Rescue, def: any): { Pearls: number?, Items: { [string]: number }? }
	local reward: any = {}
	local pearls = math.floor(r.saved / 2)
	if pearls > 0 then
		reward.Pearls = pearls
	end
	if r.saved >= r.total and def.reward then
		reward.Items = { [def.reward] = 1 }
	end
	return reward
end

export type Deps = {
	subscribe: (name: string, handler: (any) -> ()) -> any,
	publish: (name: string, payload: any) -> (),
	voyageDef: () -> any, -- the voyage being sailed (Definitions/Voyages)
	island: Instance, -- the island folder (wreck and shelter go here)
	center: Vector3, -- the lighthouse
	shelterAt: Vector3, -- by the tower door
	shoreRadius: number,
	groundY: (x: number, z: number) -> number,
	isCrew: (player: Player) -> boolean,
	playerByUserId: (userId: number) -> Player?,
	carryingOil: (player: Player) -> boolean,
	notify: (player: Player, text: string) -> (),
	announce: (text: string) -> (),
	addShells: (amount: number, reason: string) -> (),
	grant: (player: Player, claimId: string, rewards: any, source: string) -> string,
	state: Instance,
}

local function prompt(parent: Instance, action: string, object: string): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = 0.4
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local function part(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.Parent = parent
	return p
end

local function label(parent: BasePart, text: string): TextLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(220, 34)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 140
	billboard.Parent = parent
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(255, 214, 120)
	t.TextStrokeTransparency = 0.4
	t.Text = text
	t.Parent = billboard
	return t
end

-- A castaway on a carrier's back: a small wrapped figure (body + head), looks only
local function carry(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (character and root and root:IsA("BasePart")) then
		return
	end
	local model = Instance.new("Model")
	model.Name = "CarriedCastaway"
	for _, spec in { { "Body", Vector3.new(1.3, 1.8, 0.9), CFrame.new(0, 0.1, 1.2), Color3.fromRGB(170, 140, 100) }, { "Head", Vector3.new(0.9, 0.9, 0.9), CFrame.new(0, 1.35, 1.2), Color3.fromRGB(240, 200, 160) } } do
		local p = Instance.new("Part")
		p.Name = spec[1]
		p.Size = spec[2]
		p.Color = spec[4]
		p.Material = Enum.Material.Fabric
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CFrame = root.CFrame * spec[3]
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = p
		weld.Parent = p
		p.Parent = model
	end
	model.Parent = character
end

local function uncarry(player: Player)
	local character = player.Character
	local model = character and character:FindFirstChild("CarriedCastaway")
	if model then
		model:Destroy()
	end
	player:SetAttribute("CarryingCastaway", nil)
end

function RescueService.start(deps: Deps)
	local current: Rescue? = nil
	local def: any = nil
	local built: { Instance } = {}
	local countLabel: TextLabel? = nil

	local function refresh()
		local r = current
		if r and countLabel then
			countLabel.Text = string.format("CASTAWAYS %d \u{00B7} SAVED %d/%d", r.left, r.saved, r.total)
		end
		deps.state:SetAttribute("RescueSaved", if r then r.saved else nil)
		deps.state:SetAttribute("RescueTotal", if r then r.total else nil)
	end

	local function clear()
		for _, inst in built do
			inst:Destroy()
		end
		table.clear(built)
		countLabel = nil
		local r = current
		if r then
			for userId in r.carriers do
				local player = deps.playerByUserId(userId)
				if player then
					uncarry(player)
				end
			end
		end
		current = nil
		refresh()
	end

	local function build()
		-- the wreck on the shore, on the side away from the harbor
		local angle = math.rad(200)
		local x = deps.center.X + math.cos(angle) * deps.shoreRadius
		local z = deps.center.Z + math.sin(angle) * deps.shoreRadius
		local y = deps.groundY(x, z)
		local base = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(deps.center.X, y, deps.center.Z))
		local wreck = Instance.new("Model")
		wreck.Name = "Shipwreck"
		local wood = Color3.fromRGB(96, 66, 42)
		local hull = part("Hull", Vector3.new(9, 3, 18), base * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(14)), wood, Enum.Material.WoodPlanks, wreck)
		part("Keel", Vector3.new(2, 1.5, 20), base * CFrame.new(-2.5, 0.4, 0) * CFrame.Angles(0, 0, math.rad(14)), Color3.fromRGB(70, 48, 30), Enum.Material.Wood, wreck)
		part("Mast", Vector3.new(0.9, 11, 0.9), base * CFrame.new(1.5, 5, -2) * CFrame.Angles(math.rad(-25), 0, math.rad(30)), Color3.fromRGB(80, 56, 36), Enum.Material.Wood, wreck)
		part("Sail", Vector3.new(0.2, 4, 6), base * CFrame.new(4, 2, 3) * CFrame.Angles(0, 0, math.rad(70)), Color3.fromRGB(225, 215, 190), Enum.Material.Fabric, wreck)
		wreck.PrimaryPart = hull
		wreck.Parent = deps.island
		table.insert(built, wreck)
		countLabel = label(hull, "")
		local take = prompt(hull, "Carry a castaway", "Shipwreck")

		-- the shelter: a lantern-lit spot by the lighthouse door
		local s = deps.shelterAt
		local sy = deps.groundY(s.X, s.Z)
		local shelter = part("RescueShelter", Vector3.new(5, 0.4, 5), CFrame.new(s.X, sy + 0.2, s.Z), Color3.fromRGB(255, 214, 120), Enum.Material.Neon, deps.island)
		shelter.Transparency = 0.5
		table.insert(built, shelter)
		label(shelter, "SHELTER")
		local bring = prompt(shelter, "Bring them inside", "Shelter")

		take.Triggered:Connect(function(player)
			local r = current
			if not r or not deps.isCrew(player) then
				return
			end
			local why = RescueService.pickUp(r, player.UserId, deps.carryingOil(player))
			if why then
				deps.notify(player, why)
				return
			end
			player:SetAttribute("CarryingCastaway", true)
			carry(player)
			deps.notify(player, "Bring them to the shelter by the lighthouse door.")
			refresh()
		end)
		bring.Triggered:Connect(function(player)
			local r = current
			if not r or not RescueService.deliver(r, player.UserId) then
				return
			end
			uncarry(player)
			deps.addShells(def.rescue.shells, "rescue")
			deps.announce(string.format("%s brought a castaway to safety (%d/%d).", player.DisplayName, r.saved, r.total))
			deps.publish("CastawayRescued", { UserId = player.UserId, Saved = r.saved, Total = r.total })
			refresh()
		end)
	end

	deps.subscribe("VoyageStarted", function(_e)
		clear()
		def = deps.voyageDef()
		if type(def) ~= "table" or type(def.rescue) ~= "table" then
			return
		end
		current = RescueService.new(def.rescue.castaways)
		build()
		refresh()
	end)

	deps.subscribe("VoyageEnded", function(e)
		local r = current
		if r and e.Outcome ~= "Abandoned" then
			local reward = RescueService.reward(r, def.rescue)
			for _, userId in e.Crew or {} do
				local player = deps.playerByUserId(userId)
				if player then
					if reward.Pearls then
						deps.grant(player, string.format("%s:rescue:%d", e.VoyageId, userId), { Pearls = reward.Pearls }, "rescue")
					end
					if reward.Items then
						for itemId in reward.Items do
							if deps.grant(player, string.format("event:%s:%s", def.event, itemId), { Items = { [itemId] = 1 } }, "rescue") == "granted" then
								deps.notify(player, "Every castaway saved! The event's reward is in your BAG.")
							end
						end
					end
				end
			end
		end
		clear()
	end)

	-- a carrier who falls or leaves drops their castaway back at the wreck
	local function dropFor(player: Player)
		local r = current
		if r and RescueService.drop(r, player.UserId) then
			uncarry(player)
			refresh()
		end
	end
	local Players = game:GetService("Players")
	local function hook(player: Player)
		player.CharacterRemoving:Connect(function()
			dropFor(player)
		end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do
		hook(player)
	end
	Players.PlayerRemoving:Connect(dropFor)
end

return RescueService
