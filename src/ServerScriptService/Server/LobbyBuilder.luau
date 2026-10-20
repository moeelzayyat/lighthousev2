-- LobbyBuilder: the lobby is a small island with a pirate ship parked at its shore.
-- Players spawn on the island; the ship (reached by the pier) is how the crew sails to the lighthouse.
--
-- Players arrive on the deck after pressing Play. On deck:
--   * the Quartermaster (shop) - moved here from the island
--   * the ship's wheel - "Join the crew" readies you for the next run (or joins a run in progress)
-- The run island's spawn is turned into an arrival point; the ship is the only spawn.
--
-- The ship comes from ServerStorage.Art.PirateShip. If it's missing, a simple deck is built instead.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Ground = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Ground"))

local LobbyBuilder = {}

local function makePart(name, size, cframe, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.WoodPlanks
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Finds the walkable deck height at a point by casting a ray down onto the ship's floors
-- (only parts named like "...Floor" or "Deck", so masts, sails, and rigging are ignored)
local function deckHeightAt(ship, position)
	local floors = {}
	for _, part in ship:GetDescendants() do
		if part:IsA("BasePart") and (part.Name:find("Floor") or part.Name == "Deck") then
			table.insert(floors, part)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = if #floors > 0 then floors else { ship }
	local hit = Workspace:Raycast(position + Vector3.new(0, 80, 0), Vector3.new(0, -160, 0), params)
	return hit and hit.Position.Y
end

function LobbyBuilder.build(islandRefs)
	local old = Workspace:FindFirstChild("Lobby")
	if old then
		old:Destroy()
	end
	local lobby = Instance.new("Folder")
	lobby.Name = "Lobby"
	lobby.Parent = Workspace

	local center = Config.LOBBY_POSITION
	-- The ship's bow points at the island
	local facing = CFrame.lookAt(Vector3.new(center.X, 0, center.Z), Vector3.new(Config.ISLAND_CENTER.X, 0, Config.ISLAND_CENTER.Z))

	local ship
	local art = ServerStorage:FindFirstChild("Art") and ServerStorage.Art:FindFirstChild("PirateShip")
	if art then
		ship = art:Clone()
		ship.Name = "PirateShip"
		ship:PivotTo(facing * CFrame.new(0, art:GetAttribute("WaterlineOffset") or 0, 0) * CFrame.Angles(0, math.rad(art:GetAttribute("YawOffset") or 0), 0))
		for _, part in ship:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end
		ship.Parent = lobby
	else
		-- Fallback: a plain wooden deck with railings
		ship = Instance.new("Model")
		ship.Name = "PirateShip"
		local deck = makePart("Deck", Vector3.new(24, 2, 70), facing * CFrame.new(0, 4, 0), Color3.fromRGB(120, 85, 55), Enum.Material.WoodPlanks, ship)
		makePart("Hull", Vector3.new(22, 8, 66), facing * CFrame.new(0, -1, 0), Color3.fromRGB(70, 45, 30), Enum.Material.Wood, ship)
		for _, x in { -11.5, 11.5 } do
			makePart("Rail", Vector3.new(1, 3, 70), facing * CFrame.new(x, 6.5, 0), Color3.fromRGB(95, 65, 40), Enum.Material.Wood, ship)
		end
		ship.PrimaryPart = deck
		ship.Parent = lobby
	end

	-- Deck height at the middle of the ship, and toward the back (wheel) and front (shop)
	local function deckPoint(localX, localZ)
		local flat = (facing * CFrame.new(localX, 0, localZ)).Position
		local y = deckHeightAt(ship, flat) or 6
		return Vector3.new(flat.X, y, flat.Z)
	end
	local middle = deckPoint(0, 0)
	local back = deckPoint(0, Config.LOBBY_WHEEL_OFFSET)

	-- Spawn on the deck (the only spawn in the game)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "DeckSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 0.4, 8)
	local spawnXZ = Config.LOBBY_SPAWN
	local spawnPos = Vector3.new(spawnXZ.X, Ground.heightAt(spawnXZ.X, spawnXZ.Z) + 0.2, spawnXZ.Z)
	spawn.CFrame = CFrame.lookAt(spawnPos, Vector3.new(center.X, spawnPos.Y, center.Z)) -- face the ship
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = lobby
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end

	-- The island's old spawn becomes the crew's arrival point
	local islandSpawn = islandRefs.folder:FindFirstChild("SpawnLocation")
	local arrival = if islandSpawn then islandSpawn.CFrame else CFrame.new(0, Config.GROUND_Y + 3, 24)
	if islandSpawn then
		islandSpawn.Enabled = false
	end

	-- The ship's wheel: "Join the crew" (uses the ship model's own wheel if it has one)
	local wheel = ship:FindFirstChild("WheelStand", true) or ship:FindFirstChild("WheelHub", true)
	if not wheel then
		wheel = makePart("WheelPost", Vector3.new(1.2, 3.4, 1.2), CFrame.new(back + Vector3.new(0, 1.7, 0)) * facing.Rotation, Color3.fromRGB(90, 60, 38), Enum.Material.Wood, lobby)
		local ring = makePart("Wheel", Vector3.new(0.4, 4, 4), CFrame.new(back + Vector3.new(0, 3.6, 0)) * facing.Rotation * CFrame.new(0, 0, -0.7) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(150, 105, 60), Enum.Material.Wood, lobby)
		ring.Shape = Enum.PartType.Cylinder
	end
	-- Departure revision: the wheel is the crew's SAIL NOW (1 to 3 aboard); boarding is by the BoardingZone
	local helmPrompt = Instance.new("ProximityPrompt")
	helmPrompt.Name = "HelmPrompt"
	helmPrompt.ActionText = "Sail now"
	helmPrompt.ObjectText = "Ship's Wheel"
	helmPrompt.KeyboardKeyCode = Enum.KeyCode.E
	helmPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	helmPrompt.HoldDuration = 0.3
	helmPrompt.MaxActivationDistance = 12
	helmPrompt.RequiresLineOfSight = false
	helmPrompt.Parent = wheel
	-- (the wheel's departure sign is drawn per player by Client.Departure since UI Stage 6)

	-- BoardingZone (departure revision): an invisible box over the ship's walkable decks only (the parts
	-- named "...Floor" or "Deck"), from just under the lowest deck to 8 studs above the highest. Standing
	-- in it is what puts a player in this ship's party; the pier, the water and the shore are outside it.
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, part in ship:GetDescendants() do
		if part:IsA("BasePart") and (part.Name:find("Floor") or part.Name == "Deck") then
			local h = part.Size / 2
			for _, c in { Vector3.new(1, 1, 1), Vector3.new(1, 1, -1), Vector3.new(1, -1, 1), Vector3.new(1, -1, -1), Vector3.new(-1, 1, 1), Vector3.new(-1, 1, -1), Vector3.new(-1, -1, 1), Vector3.new(-1, -1, -1) } do
				local v = facing:PointToObjectSpace(part.CFrame:PointToWorldSpace(h * c))
				lo = lo:Min(v)
				hi = hi:Max(v)
			end
		end
	end
	if lo.X == math.huge then -- no named floors: fall back to the deck around the ship's middle
		lo, hi = facing:PointToObjectSpace(middle) - Vector3.new(10, 1, 30), facing:PointToObjectSpace(middle) + Vector3.new(10, 0, 30)
	end
	hi += Vector3.new(0, 8, 0)
	local boardingZone = Instance.new("Part")
	boardingZone.Name = "BoardingZone"
	boardingZone.Anchored = true
	boardingZone.CanCollide = false
	boardingZone.CanQuery = false
	boardingZone.CanTouch = false
	boardingZone.CastShadow = false
	boardingZone.Transparency = 1
	boardingZone.Size = hi - lo
	boardingZone.CFrame = facing * CFrame.new((lo + hi) / 2)
	boardingZone:SetAttribute("ShipId", "Ship1")
	boardingZone.Parent = lobby

	-- The Quartermaster's market stall stands on the lobby island beside the path to the pier,
	-- its counter facing the path, the Quartermaster behind it.
	local keeper = islandRefs.folder:FindFirstChild("Quartermaster")
	local counter = islandRefs.shopCounter
	local stall = islandRefs.folder:FindFirstChild("ShopStall")
	local shopXZ = Config.LOBBY_SHOP
	local shopSpot = Vector3.new(shopXZ.X, Ground.heightAt(shopXZ.X, shopXZ.Z), shopXZ.Z)
	-- -Z points at the path to the pier, where players walk past
	local shopFacing = CFrame.lookAt(shopSpot, Vector3.new(0, shopSpot.Y, shopXZ.Z))
	if stall then
		local _, stallSize = stall:GetBoundingBox()
		-- QM.2 (owner 2026-10-20, "Quartermaster still floating"): the stall model's planked counter front and
		-- awning already face -Z, the path. The old extra 180-degree turn put the shelves on the path side and the
		-- Quartermaster out at the back on a box, so from the path he seemed to hover behind the stall.
		stall:PivotTo(shopFacing * CFrame.new(0, stallSize.Y / 2, 0))
		stall.Parent = lobby
	end
	if keeper then
		-- Between the counter (centre 2 studs toward the path) and the back shelves (1.15 behind shopSpot), looking
		-- at the players (the model faces -Z), standing on the stall's plank floor. 20% larger than the art so his
		-- head and shoulders clear the tall counter, like the shopkeeper he is.
		local FLOOR = 0.6
		local floor = Instance.new("Part")
		floor.Name = "StallFloor"
		floor.Anchored = true
		floor.Size = Vector3.new(8.6, FLOOR, 2.7)
		floor.Material = Enum.Material.WoodPlanks
		floor.Color = Color3.fromRGB(110, 78, 50)
		floor.CFrame = shopFacing * CFrame.new(0, FLOOR / 2, 0.4)
		floor.Parent = lobby
		keeper.Size *= 1.2
		keeper.CFrame = shopFacing * CFrame.new(0, FLOOR + keeper.Size.Y / 2, -0.4)
		keeper.Parent = lobby
	end
	counter.CFrame = shopFacing * CFrame.new(0, 2.5, -3)
	counter.Parent = lobby

	-- S7.3: the leaderboard board across the path from the stall, facing the path (LeaderboardService fills it)
	local boardBase = Vector3.new(-shopXZ.X, Ground.heightAt(-shopXZ.X, shopXZ.Z), shopXZ.Z)
	-- harbor UI: a bigger board (was 13 x 7.5) for the "HARBOR LEGENDS" face each client draws (Client/HarborBoard)
	local boardCenter = boardBase + Vector3.new(0, 6.2, 0)
	local board = makePart("LeaderboardBoard", Vector3.new(16, 9.5, 0.6), CFrame.lookAt(boardCenter, Vector3.new(0, boardCenter.Y, shopXZ.Z)), Color3.fromRGB(70, 50, 35), Enum.Material.Wood, lobby)
	for _, side in { -1, 1 } do
		makePart("BoardPost", Vector3.new(0.6, 11, 0.6), board.CFrame * CFrame.new(side * 7.7, -1.3, 0.5), Color3.fromRGB(90, 62, 40), Enum.Material.Wood, lobby)
	end
	local surface = Instance.new("SurfaceGui")
	surface.Name = "Boards"
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 50
	surface.LightInfluence = 0
	surface.Parent = board
	for i, id in { "BestNightStandard", "BestNightLong", "WeeklyNights" } do
		local column = Instance.new("Frame")
		column.Name = id
		column.BackgroundTransparency = 1
		column.Position = UDim2.new((i - 1) / 3, 8, 0, 8)
		column.Size = UDim2.new(1 / 3, -16, 1, -16)
		column.Parent = surface
		local list = Instance.new("UIListLayout")
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, 2)
		list.Parent = column
		for row = 0, 10 do
			local label = Instance.new("TextLabel")
			label.Name = if row == 0 then "Title" else "Row" .. row
			label.LayoutOrder = row
			label.BackgroundTransparency = 1
			label.Size = UDim2.new(1, 0, 0, if row == 0 then 40 else 28)
			label.Font = if row == 0 then Enum.Font.FredokaOne else Enum.Font.GothamMedium
			label.TextSize = if row == 0 then 24 else 19
			label.TextColor3 = if row == 0 then Color3.fromRGB(255, 220, 140) else Color3.fromRGB(245, 235, 215)
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.Text = if row == 0 then "..." else ""
			label.Parent = column
		end
	end

	return {
		folder = lobby,
		spawn = spawn,
		helmPrompt = helmPrompt,
		boardingZone = boardingZone,
		islandArrival = arrival,
		deckCenter = middle,
		leaderboard = board, -- S7.3
	}
end

-- D-046 (harbor role): more ships around the harbor island. Each is a copy of the first ship (with its collision,
-- stairs and gangway) and of the first ship's pier, turned around the island's middle to its bearing in
-- Config.HARBOR_SHIP_ANGLES and moved in or out so the pier meets the shore there. Each ship has its OWN
-- BoardingZone and wheel prompt (SAIL NOW). Returns { [shipId] = { helmPrompt, boardingZone, ship } }.
local HARBOR_MIDDLE = Vector3.new(0, 0, 575) -- the harbor island's middle (measured; the first ship is due north)
local PIER_PARTS = {
	PierLanding = true, PierRamp = true, PierDock = true, Rail = true, RailPost = true, Post = true,
	Bollard = true, RopeCoil = true, Lantern = true, LanternBase = true, LanternCap = true, LanternPost = true,
}

-- distance from the harbor's middle to the first water along a bearing (0 = north, 90 = west)
local function shoreRadius(degrees)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { Workspace.Terrain }
	local r = math.rad(degrees)
	local dir = Vector3.new(-math.sin(r), 0, -math.cos(r))
	for d = 40, 240, 2 do
		local at = HARBOR_MIDDLE + dir * d
		local hit = Workspace:Raycast(at + Vector3.new(0, 200, 0), Vector3.new(0, -400, 0), params)
		if hit and hit.Material == Enum.Material.Water then
			return d
		end
	end
	return nil
end

function LobbyBuilder.buildExtraShips(lobbyRefs, angles)
	local lobby = lobbyRefs.folder
	local first = lobby:FindFirstChild("PirateShip")
	lobbyRefs.helmPrompt:SetAttribute("ShipId", "Ship1")
	lobbyRefs.boardingZone:SetAttribute("ShipId", "Ship1")
	local built = { Ship1 = { helmPrompt = lobbyRefs.helmPrompt, boardingZone = lobbyRefs.boardingZone, ship = first } }

	-- the first ship's pier (static harbor decor between the shore and the ship's stern)
	local pier = {}
	local decor = Workspace:FindFirstChild("LobbyIslandDecor")
	local stern = lobbyRefs.boardingZone.Position
	if decor then
		for _, part in decor:GetChildren() do
			if part:IsA("BasePart") and PIER_PARTS[part.Name] then
				local p = part.Position
				if math.abs(p.X - stern.X) < 8 and p.Z > stern.Z + 20 and p.Z < stern.Z + 70 then
					table.insert(pier, part)
				end
			end
		end
	end
	local home = shoreRadius(0) or 116

	for k = 2, #angles do
		local id = "Ship" .. k
		local push = (shoreRadius(angles[k]) or home) - home
		local turn = CFrame.new(HARBOR_MIDDLE) * CFrame.Angles(0, math.rad(angles[k]), 0) * CFrame.new(0, 0, -push) * CFrame.new(-HARBOR_MIDDLE)

		local ship = first:Clone()
		ship.Name = "PirateShip_" .. id
		for _, d in ship:GetDescendants() do
			if d:IsA("ProximityPrompt") then
				d:Destroy()
			end
		end
		ship:PivotTo(turn * first:GetPivot())
		ship.Parent = lobby

		local pierFolder = Instance.new("Folder")
		pierFolder.Name = "Pier_" .. id
		for _, part in pier do
			local copy = part:Clone()
			copy.CFrame = turn * part.CFrame
			copy.Parent = pierFolder
		end
		pierFolder.Parent = lobby

		local zone = lobbyRefs.boardingZone:Clone()
		zone.Name = "BoardingZone_" .. id
		zone.CFrame = turn * lobbyRefs.boardingZone.CFrame
		zone:SetAttribute("ShipId", id)
		zone.Parent = lobby

		local wheel = ship:FindFirstChild("WheelStand", true) or ship:FindFirstChild("WheelHub", true)
		if not wheel then
			local post = lobbyRefs.helmPrompt.Parent
			wheel = makePart("WheelPost_" .. id, post.Size, turn * post.CFrame, post.Color, post.Material, lobby)
		end
		local prompt = lobbyRefs.helmPrompt:Clone()
		prompt.Enabled = true
		prompt:SetAttribute("ShipId", id)
		prompt.Parent = wheel

		built[id] = { helmPrompt = prompt, boardingZone = zone, ship = ship }
	end
	return built
end

return LobbyBuilder
