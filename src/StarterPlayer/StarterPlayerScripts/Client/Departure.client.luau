-- Departure (client): boarding a ship's crew and sailing to the lighthouse.
-- Boarding batch: walking onto the ship joins its party (the server decides).
-- Departure revision: a full crew (4/4) departs automatically; a crew of 1 to 3 waits until a member uses
-- SAIL NOW at the ship's wheel (the prompt is shown only to crew members who can use it).
--
-- Mostly world-integrated, no big menu:
--   * the SHIP'S WHEEL sign (a billboard on the wheel) shows the departure state to everyone nearby
--   * the wheel prompt says Join / Leave for YOU (set locally; the server still decides)
--   * a small harbor status card (top centre) while you're ashore and not in the crew
--   * a crew card (top right) once you've joined: who's sailing, countdown, how to leave
--   * a travel card during the fade between the harbor and the island
-- Reads only replicated state: GameState Phase / TimeLeft / CrewCount / AboardCount and each
-- player's Ready / InLobby attributes. Joining and leaving stay the server's wheel prompt.
-- Built on UiKit v2.1 (Stage 6 of the UI redesign).
-- Studio only: player attribute HudSimulate draws the cards inside a simulated screen size.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local UiKit = require(script.Parent:WaitForChild("UiKit"))
local InputController = require(script.Parent:WaitForChild("InputController")) -- S2.6

local C, F = UiKit.Color, UiKit.Font
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local state = ReplicatedStorage:WaitForChild("GameState")
local player = Players.LocalPlayer

local RUN_PHASES = { Prologue = true, Day = true, Night = true }
local NEAR_SHIP = 160 -- studs from the ship: "you're at the harbor"
local MAX_ROSTER = 4

-- the ship whose party this player sees: their own, else the one they stand on, else the existing ship
local function shownShip()
	return player:GetAttribute("ShipId") or player:GetAttribute("NearShip") or "Ship1"
end

-- members of ONE ship's party (never the whole server)
local function crewList()
	local list = {}
	local shipId = shownShip()
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("ShipId") == shipId then
			table.insert(list, p)
		end
	end
	table.sort(list, function(a, b)
		if a == player then
			return true
		elseif b == player then
			return false
		end
		return a.DisplayName < b.DisplayName
	end)
	return list
end

local function clock(seconds)
	seconds = math.max(0, math.floor(seconds or 0))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function lobbyFolder()
	return Workspace:FindFirstChild("Lobby")
end

local function nearShip()
	local lobby = lobbyFolder()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not lobby or not root then
		return false
	end
	-- D-046: the harbor has several ships ("PirateShip", "PirateShip_Ship2", ...)
	for _, ship in lobby:GetChildren() do
		if ship:IsA("Model") and string.sub(ship.Name, 1, 10) == "PirateShip" and (root.Position - ship:GetPivot().Position).Magnitude < NEAR_SHIP then
			return true
		end
	end
	return false
end

local function inputKey()
	local mode = InputController.mode() -- S2.6
	if mode == "touch" then
		return "Tap"
	elseif mode == "gamepad" then
		return "X"
	end
	return "E"
end

---------------------------------------------------------------------
-- SCREENS
---------------------------------------------------------------------

local gui = UiKit.Screen("Departure", 4)
local root = UiKit.new("Frame", { Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, gui)
local rootOutline = UiKit.border(root, C.BorderFocus, 1, 0.4)
rootOutline.Enabled = false

-- harbor status card (ashore, not in the crew) -------------------------
local harbor = UiKit.Panel(root, { name = "HarborStatus", kind = "plain", variant = "primary", padding = 0, anchor = Vector2.new(0.5, 0) })
UiKit.border(harbor, C.BorderStructural, 1, 0.35)
harbor.Visible = false
harbor:FindFirstChild("Content"):Destroy()
local harborRule = UiKit.new("Frame", { Name = "Rule", BackgroundColor3 = C.AccentLighthouse, BorderSizePixel = 0, Size = UDim2.new(0, 4, 1, -16), Position = UDim2.fromOffset(10, 8) }, harbor)
UiKit.round(harborRule, 2)
local harborText = UiKit.new("Frame", { Name = "Text", BackgroundTransparency = 1 }, harbor)
UiKit.list(harborText, "y", 2, { VerticalAlignment = Enum.VerticalAlignment.Center })
local harborEyebrow = UiKit.Label(harborText, "", "Eyebrow", { Name = "State", LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.None, TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd })
local harborBody = UiKit.Label(harborText, "", "BodySmall", { Name = "Body", LayoutOrder = 2, TextColor3 = C.TextPrimary })
local harborKey = UiKit.new("Frame", { Name = "Key", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(96, 52) }, harbor)
local keycap = UiKit.new("TextLabel", {
	Name = "Keycap",
	BackgroundColor3 = C.SurfaceElevated,
	FontFace = F.LabelBold,
	TextSize = 16,
	TextColor3 = C.TextPrimary,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0),
	Size = UDim2.fromOffset(40, 30),
}, harborKey)
UiKit.round(keycap, UiKit.Radius.control)
UiKit.border(keycap, C.BorderBrassBright, 1, 0.25)
UiKit.Label(harborKey, "at the wheel", "Micro", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.new(1, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.None, TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = false })

-- crew card (you're in the crew, before the ship sails) ----------------
local crewCard = UiKit.Panel(root, { name = "CrewCard", kind = "plain", variant = "primary", padding = 0, anchor = Vector2.new(1, 0) })
UiKit.border(crewCard, C.AccentLighthouse, 1, 0.5)
crewCard.Visible = false
crewCard:FindFirstChild("Content"):Destroy() -- sized by its own content instead
-- VOTE.1: the card stops above the BAG / CODES / jump buttons and scrolls inside when its content is taller
local crewScroll = UiKit.new("ScrollingFrame", {
	Name = "Scroll",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ScrollBarThickness = 6,
	ScrollBarImageColor3 = C.TextSecondary,
	Selectable = false,
}, crewCard)
local crewBody = UiKit.new("Frame", { Name = "Body", BackgroundTransparency = 1 }, crewScroll)
UiKit.pad(crewBody, 12, 14, 12, 14)
UiKit.list(crewBody, "y", 6)
local crewEyebrow = UiKit.Label(crewBody, "Your crew", "Eyebrow", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.None, TextWrapped = false })
local crewHeadline = UiKit.new("TextLabel", {
	Name = "Headline",
	BackgroundTransparency = 1,
	FontFace = F.Heading,
	TextSize = 22,
	TextColor3 = C.TextPrimary,
	TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.new(1, 0, 0, 28),
	LayoutOrder = 2,
}, crewBody)
local roster = UiKit.new("Frame", { Name = "Roster", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3 }, crewBody)
UiKit.list(roster, "y", 2)
local rosterRows = {}
for i = 1, MAX_ROSTER + 1 do
	local row = UiKit.new("Frame", { Name = "Crew" .. i, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = i, Visible = false }, roster)
	local check = UiKit.Glyph(row, "check", C.StateSuccess, 12)
	check.AnchorPoint = Vector2.new(0, 0.5)
	check.Position = UDim2.new(0, 0, 0.5, 0)
	local name = UiKit.Label(row, "", "BodySmall", { Name = "Name", Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -80, 1, 0), AutomaticSize = Enum.AutomaticSize.None, TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd, TextYAlignment = Enum.TextYAlignment.Center, TextColor3 = C.TextPrimary })
	local tag = UiKit.Tag(row, "Ready", "StateSuccess", { name = "State" })
	tag.AnchorPoint = Vector2.new(1, 0.5)
	tag.Position = UDim2.new(1, 0, 0.5, 0)
	rosterRows[i] = { frame = row, name = name, tag = tag, check = check }
end
local aboardLine = UiKit.Label(crewBody, "", "Micro", { Name = "Aboard", LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.None, TextWrapped = false })
UiKit.new("Frame", { Name = "Rule", BackgroundColor3 = C.BorderStructural, BackgroundTransparency = 0.5, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1), LayoutOrder = 5 }, crewBody)
local leaveLine = UiKit.Label(crewBody, "", "Micro", { Name = "Leave", LayoutOrder = 6, TextColor3 = C.TextSecondary })
-- launch R11: invite a friend while the crew has room (no rewards, no repeats once used)
local SocialService = game:GetService("SocialService")
local canInvite = false
task.spawn(function()
	local ok, can = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
	canInvite = ok and can == true
end)
local invitedFromCrew = false
local crewInvite = UiKit.Button(crewBody, "Invite a friend", { name = "InviteButton", variant = "ghost", size = "sm", fill = true, layoutOrder = 7 })
crewInvite.Visible = false

-- launch R9: vote on the storm forecast before sailing (the server tallies when the ship leaves)
local Forecasts = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Forecasts"))
local forecastBox = UiKit.new("Frame", { Name = "Forecast", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, Visible = false }, crewBody)
UiKit.list(forecastBox, "y", 6)
UiKit.Label(forecastBox, "Vote: tonight's forecast", "Eyebrow", { LayoutOrder = 0 })
local forecastButtons = {}
for i = 1, 2 do
	local b = UiKit.Button(forecastBox, "", { name = "Forecast" .. i, variant = "secondary", size = "sm", fill = true, layoutOrder = i })
	b.TextSize = 15
	b.Activated:Connect(function()
		local id = state:GetAttribute(if i == 1 then "ForecastA" else "ForecastB")
		if Forecasts[id] then
			remotes:WaitForChild("ForecastVote"):FireServer(id)
		end
	end)
	forecastButtons[i] = b
end
local forecastNote = UiKit.Label(forecastBox, "", "Micro", { LayoutOrder = 3 })
local function renderForecastVote(crew)
	local a, b = state:GetAttribute("ForecastA"), state:GetAttribute("ForecastB")
	forecastBox.Visible = Forecasts[a] ~= nil and Forecasts[b] ~= nil
	if not forecastBox.Visible then
		return
	end
	local mine = player:GetAttribute("ForecastVote")
	-- phones: compact card (name + votes only, no note) so the crew card fits a 375 px tall screen
	local phone = UiKit.Breakpoint(root.AbsoluteSize) == "phone"
	forecastNote.Visible = not phone
	-- VOTE.1 (owner): the option with the most votes has gold text; your own vote has a gold ring; a tie has no leader
	local counts = {}
	for i, id in { a, b } do
		counts[i] = 0
		for _, p in crew do
			if p:GetAttribute("ForecastVote") == id then
				counts[i] += 1
			end
		end
	end
	local leader = if counts[1] > counts[2] then 1 elseif counts[2] > counts[1] then 2 else nil
	local tied = leader == nil and counts[1] > 0
	for i, id in { a, b } do
		local votes = counts[i]
		local button = forecastButtons[i]
		local text = if phone
			then string.upper(string.format("%s  (%d)", Forecasts[id].displayName, votes))
			else string.upper(string.format("%s \u{00B7} %s  (%d)", Forecasts[id].displayName, Forecasts[id].short, votes))
		if button.Text ~= text then
			button.Text = text
			button:SetAttribute("BaseText", text)
		end
		local chosen = mine == id
		button.BackgroundColor3 = C.SurfaceElevated
		button.TextColor3 = if leader == i then C.AccentLighthouse else C.TextPrimary
		button:SetAttribute("BaseTextColor", button.TextColor3)
		-- the Bold look draws the button with its own face and text (BoldFace, BoldText); paint those when present
		local boldText = button:FindFirstChild("BoldText")
		if boldText and boldText:IsA("TextLabel") then
			boldText.TextColor3 = if leader == i then C.AccentLighthouse else Color3.new(1, 1, 1)
		end
		local face = button:FindFirstChild("BoldFace")
		local ring = (face and face:FindFirstChildOfClass("UIStroke")) or button:FindFirstChildOfClass("UIStroke")
		if ring then
			if ring:GetAttribute("VoteBaseColor") == nil then
				ring:SetAttribute("VoteBaseColor", ring.Color)
				ring:SetAttribute("VoteBaseThickness", ring.Thickness)
			end
			ring.Enabled = true
			ring.Color = if chosen then C.AccentLighthouse else ring:GetAttribute("VoteBaseColor")
			ring.Thickness = if chosen then 4 else ring:GetAttribute("VoteBaseThickness")
		end
	end
	forecastNote.Text = if tied then "Tied: a coin toss when the ship sails."
		elseif mine then "Gold text leads. Majority wins when the ship sails."
		else "Pick one. No vote = the crew's choice."
end
-- S2.1: once any crew member holds the Long Voyage unlock (a Standard win) the card offers the voyage choice;
-- only holders can switch to the Long Voyage, everyone sees which one is picked. The server checks again.
local Voyages = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("Voyages"))
local LiveEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("LiveEvents")) -- LO.1
-- LO.1: an event voyage is offered to everyone while its event is on (server time)
local function eventOn(def)
	return def.event ~= nil and LiveEvents.isOn(def.event, Workspace:GetServerTimeNow())
end
local voyageBox = UiKit.new("Frame", { Name = "VoyageChoice", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, Visible = false }, crewBody)
UiKit.list(voyageBox, "y", 6)
UiKit.Label(voyageBox, "Voyage", "Eyebrow", { LayoutOrder = 0 })
-- MAP.1 (D-049): the island, under the voyages; shown once any crew member holds a map unlock (shared crew unlock)
local Maps = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("Maps"))
local mapLabel = UiKit.Label(voyageBox, "Island", "Eyebrow", { LayoutOrder = 20 })
local mapButtons = {}
for i, id in Maps.ORDER do
	local def = (Maps :: any)[id]
	local b = UiKit.Button(voyageBox, string.upper(def.displayName .. " \u{00B7} " .. def.short), { name = "Map" .. id, variant = "secondary", size = "sm", fill = true, layoutOrder = 20 + i })
	b.TextSize = 15
	b.Activated:Connect(function()
		remotes:WaitForChild("ChooseMap"):FireServer(id)
	end)
	mapButtons[id] = b
end
local voyageButtons = {}
for i, id in Voyages.ORDER do
	local def = Voyages[id]
	local b = UiKit.Button(voyageBox, string.upper(def.displayName .. " \u{00B7} " .. def.short), { name = "Voyage" .. id, variant = "secondary", size = "sm", fill = true, layoutOrder = i })
	b.TextSize = 15
	b.Activated:Connect(function()
		remotes:WaitForChild("ChooseVoyage"):FireServer(id)
	end)
	voyageButtons[id] = b
end
local function renderVoyageChoice(crew)
	local offered = false
	-- MAP.1: maps the crew can choose (any member's unlock counts for everyone)
	local function crewHolds(key: string): boolean
		for _, p in crew do
			if p:GetAttribute("Unlock_" .. key) == true then
				return true
			end
		end
		return false
	end
	local maps = Maps.availableFor(crewHolds)
	local mapsOffered = #maps > 1
	mapLabel.Visible = mapsOffered
	local chosenMap = Maps.resolve(state:GetAttribute("Ship_" .. shownShip() .. "_MapDef") or state:GetAttribute("MapDef"), crewHolds)
	for id, button in mapButtons do
		button.Visible = mapsOffered and table.find(maps, id) ~= nil
		local selected = chosenMap == id
		button.BackgroundColor3 = if selected then C.AccentLighthouse else C.SurfaceElevated
		button.TextColor3 = if selected then C.TextOnAccent else C.TextPrimary
	end
	for _, id in Voyages.ORDER do
		local def = Voyages[id]
		if def.unlock then
			for _, p in crew do
				if p:GetAttribute("Unlock_" .. def.unlock) == true then
					offered = true
				end
			end
		end
		if eventOn(def) then
			offered = true
		end
	end
	for _, button in voyageButtons do
		button.Visible = offered
	end
	voyageBox.Visible = offered or mapsOffered
	if not offered then
		return
	end
	-- D-046: in the harbor each ship has its own voyage choice
	local chosen = state:GetAttribute("Ship_" .. shownShip() .. "_VoyageDef") or state:GetAttribute("VoyageDef")
	for id, button in voyageButtons do
		local def = Voyages[id]
		local mine = def.unlock == nil or player:GetAttribute("Unlock_" .. def.unlock) == true
		button.Visible = def.event == nil or eventOn(def) -- LO.1: an event voyage only while its event is on
		local selected = chosen == id
		button.BackgroundColor3 = if selected then C.AccentLighthouse else C.SurfaceElevated
		button.TextColor3 = if selected then C.TextOnAccent elseif mine then C.TextPrimary else C.TextSecondary
		button.Active = mine
		button.AutoButtonColor = mine
	end
end

crewInvite.Activated:Connect(function()
	invitedFromCrew = true
	crewInvite.Visible = false
	pcall(SocialService.PromptGameInvite, SocialService, player)
end)

-- travel card (the fade between the harbor and the island) -------------
local travelGui = UiKit.Screen("TravelCard", 60, true)
local fader = UiKit.new("Frame", { Name = "Fade", BackgroundColor3 = C.SurfaceBase, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Visible = false }, travelGui)
local travelColumn = UiKit.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(520, 120) }, fader)
UiKit.list(travelColumn, "y", 8, { HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center })
local travelLamp = UiKit.Glyph(travelColumn, "lamp", C.AccentLighthouse, 26)
travelLamp.LayoutOrder = 1
local travelTitle = UiKit.Label(travelColumn, "", "H1", { Name = "Title", LayoutOrder = 2, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = C.AccentLighthouseSoft })
local travelSub = UiKit.Label(travelColumn, "", "Body", { Name = "Sub", LayoutOrder = 3, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = C.TextSecondary })
local travelTexts = { travelTitle, travelSub }

---------------------------------------------------------------------
-- THE SHIP'S WHEEL (world sign + your prompt text)
---------------------------------------------------------------------

-- one sign per ship's wheel (multi-ship phase 2: the harbor can have several ships; prompt attribute ShipId)
local wheels = {} -- { { prompt, shipId, sign, state, detail } }

local function makeSign(helmPrompt)
	local wheelSign = UiKit.new("BillboardGui", {
		Name = "WheelSign",
		Adornee = helmPrompt.Parent,
		Size = UDim2.fromOffset(240, 62),
		StudsOffsetWorldSpace = Vector3.new(0, 5.5, 0),
		AlwaysOnTop = true,
		MaxDistance = 90,
		LightInfluence = 0,
		ResetOnSpawn = false,
	}, player:WaitForChild("PlayerGui"))
	local plate = UiKit.new("Frame", { Name = "Plate", BackgroundColor3 = C.SurfacePrimary, BackgroundTransparency = 0.08, Size = UDim2.fromScale(1, 1) }, wheelSign)
	UiKit.round(plate, UiKit.Radius.card)
	UiKit.border(plate, C.BorderBrassBright, 1.5, 0.15)
	UiKit.Brackets(plate, C.AccentLighthouse, 8, 2, 0)
	local signState = UiKit.new("TextLabel", {
		Name = "State",
		BackgroundTransparency = 1,
		FontFace = F.LabelBold,
		TextSize = 22,
		TextColor3 = C.AccentLighthouse,
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(1, 0, 0, 26),
	}, plate)
	local signDetail = UiKit.new("TextLabel", {
		Name = "Detail",
		BackgroundTransparency = 1,
		FontFace = F.BodyMedium,
		TextSize = 15,
		TextColor3 = C.TextPrimary,
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 0, 22),
	}, plate)
	table.insert(wheels, { prompt = helmPrompt, shipId = helmPrompt:GetAttribute("ShipId") or "Ship1", sign = wheelSign, state = signState, detail = signDetail })
end

local function bindWheel()
	local lobby = lobbyFolder()
	if not lobby then
		return
	end
	for _, d in lobby:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Name == "HelmPrompt" then
			local known = false
			for _, w in wheels do
				if w.prompt == d then
					known = true
				end
			end
			if not known then
				makeSign(d)
			end
		end
	end
end

---------------------------------------------------------------------
-- VOYAGE CREW (boarding batch): during a voyage, only YOUR ship's crew is listed. Roblox's server-wide
-- player list is hidden while this panel shows and comes back in the harbor.
---------------------------------------------------------------------

local StarterGui = game:GetService("StarterGui")
local voyageCard = UiKit.Panel(root, { name = "VoyageCrew", kind = "plain", variant = "primary", padding = 0, anchor = Vector2.new(0, 0.5) })
UiKit.border(voyageCard, C.BorderStructural, 1, 0.35)
voyageCard.Visible = false
voyageCard.BackgroundTransparency = 0.15
voyageCard:FindFirstChild("Content"):Destroy()
voyageCard.AutomaticSize = Enum.AutomaticSize.Y
local voyageBody = UiKit.new("Frame", { Name = "Body", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, voyageCard)
UiKit.pad(voyageBody, 8, 10, 8, 10)
UiKit.list(voyageBody, "y", 2)
local voyageTitle = UiKit.Label(voyageBody, "CREW", "Eyebrow", { Name = "Title", LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.None, TextWrapped = false })
local voyageRows = {}
for i = 1, MAX_ROSTER do
	voyageRows[i] = UiKit.Label(voyageBody, "", "BodySmall", { Name = "Crew" .. i, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.None, TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd, TextColor3 = C.TextPrimary, Visible = false })
end
local playerListHidden = false
local function setPlayerListHidden(hide)
	if hide ~= playerListHidden and pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.PlayerList, not hide) then
		playerListHidden = hide
	end
end

local function renderVoyageCrew(show, crew, seats)
	voyageCard.Visible = show
	setPlayerListHidden(show) -- only once the crew panel is actually on screen
	if not show then
		return
	end
	voyageTitle.Text = "CREW · " .. seats
	local keeperId = state:GetAttribute("KeeperUserId") or 0
	for i, label in voyageRows do
		local p = crew[i]
		label.Visible = p ~= nil
		if p then
			local name = if p == player then p.DisplayName .. " (you)" else p.DisplayName
			label.Text = if p.UserId == keeperId then name .. " · Keeper" else name
		end
	end
end

---------------------------------------------------------------------
-- RENDER (a light poll: a few labels, four times a second)
---------------------------------------------------------------------

local function render()
	bindWheel()
	local phase = state:GetAttribute("Phase") or "Waiting"
	local left = state:GetAttribute("TimeLeft") or 0
	local crew = crewList()
	local crewCount = #crew
	local aboard = state:GetAttribute("AboardCount") or 0
	local ready = player:GetAttribute("Ready") == true
	local ashore = player:GetAttribute("InLobby") == true
	local sailing = phase == "Intermission"
	local underway = RUN_PHASES[phase] == true
	local key = inputKey()

	-- the wheel signs: everyone nearby reads the same departure state
	local capacity = state:GetAttribute("ShipCapacity") or 4
	local multi = state:GetAttribute("MultiShip") == true -- harbor with several ships, each with its own countdown
	local shipId = shownShip()
	-- one ship's departure state. Single-server game: the global Phase/TimeLeft; harbor: that ship's own countdown
	local function shipView(id)
		local count = if id == shipId then crewCount else (state:GetAttribute("Ship_" .. id .. "_Count") or 0)
		local view = { count = count, departure = state:GetAttribute("Ship_" .. id .. "_Departure") }
		if multi then
			local shipPhase = state:GetAttribute("Ship_" .. id .. "_Phase") or "Waiting"
			view.sailing = shipPhase == "Countdown"
			view.left = state:GetAttribute("Ship_" .. id .. "_TimeLeft") or 0
			view.underway = shipPhase == "Sailing"
			view.inPort = shipPhase == "Waiting"
		else
			view.sailing, view.left, view.underway, view.inPort = sailing, left, underway, phase == "Waiting"
		end
		return view
	end
	local mine = shipView(shipId)
	if multi then
		sailing, left, underway = mine.sailing, mine.left, mine.underway
	end
	local seats = string.format("%d/%d", crewCount, capacity)
	local full = crewCount >= capacity
	local departure = mine.departure -- "auto" | "manual" | "rematch" | nil
	local leaving = sailing and departure ~= nil
	for _, w in wheels do
		local v = shipView(w.shipId)
		local wSeats = string.format("%d/%d", v.count, capacity)
		if v.underway then
			w.state.Text = "AT SEA"
			w.detail.Text = wSeats .. " crew · next voyage soon"
			w.state.TextColor3 = C.AccentSea
		elseif v.sailing and v.departure ~= nil then
			w.state.Text = "LEAVING IN " .. clock(v.left)
			w.detail.Text = if v.count >= capacity then wSeats .. " crew · crew full" elseif v.departure == "manual" then wSeats .. " crew · SAIL NOW called" else wSeats .. " crew · walk aboard to join"
			w.state.TextColor3 = if v.left <= 5 then C.StateWarning else C.AccentLighthouse
		elseif v.count == 0 then
			w.state.Text = "WAITING FOR CREW"
			w.detail.Text = "0/" .. capacity .. " · walk aboard to join"
			w.state.TextColor3 = C.AccentLighthouse
		else
			w.state.Text = "CREW " .. wSeats
			w.detail.Text = "Waiting for crew · SAIL NOW at the wheel"
			w.state.TextColor3 = C.AccentLighthouse
		end
		-- SAIL NOW: only a member of this ship's party of 1 to 3, in port, before any departure has started
		-- (local visibility only; the server checks every press)
		w.prompt.Enabled = ready and player:GetAttribute("ShipId") == w.shipId and v.count >= 1 and v.count < capacity
			and v.departure == nil and v.inPort
		w.prompt.ActionText = string.format("Sail now (%s)", wSeats)
	end

	local hidden = player:GetAttribute("MenuOpen") == true
	local atHarbor = ashore and nearShip()

	-- harbor status card: ashore and not in the crew
	local showHarbor = ashore and not ready and not hidden
	local refused = player:GetAttribute("BoardRefused")
	harbor.Visible = showHarbor
	if showHarbor then
		keycap.Text = key
		if refused == "full" then
			harborEyebrow.Text = "CREW FULL · " .. seats
			harborEyebrow.TextColor3 = C.StateWarning
			harborBody.Text = "Crew full. Find another ship and sail, or wait here for the next voyage."
		elseif underway or refused == "sailed" then
			harborEyebrow.Text = "VOYAGE AT SEA · " .. seats .. " CREW"
			harborEyebrow.TextColor3 = C.AccentSea
			harborBody.Text = "The ship's crew is at sea. Wait here: the next voyage takes a new crew."
		elseif leaving then
			harborEyebrow.Text = string.upper(string.format("The ship leaves in %s · %s crew", clock(left), seats))
			harborEyebrow.TextColor3 = if left <= 5 then C.StateWarning else C.AccentLighthouse
			harborBody.Text = if full then "This crew is full. Wait here for the next voyage." else "Walk onto the ship to sail with them."
		else
			harborEyebrow.Text = (if crewCount == 0 then "HARBOR ISLAND · WAITING FOR CREW " else "HARBOR ISLAND · SHIP ") .. seats
			harborEyebrow.TextColor3 = C.AccentLighthouse
			harborBody.Text = "Walk the pier onto the ship to join its crew (up to " .. capacity .. "). The Quartermaster sells gear by the path."
		end
	end

	renderVoyageCrew(ready and RUN_PHASES[phase] == true, crew, seats)

	-- crew card: you're in the crew and the ship hasn't sailed yet
	local showCrew = ready and not underway and (sailing or phase == "Waiting") and not hidden
	crewCard.Visible = showCrew
	-- HX.6 (owner, phone): the crew card already shows your ship's countdown; on a phone your ship's wheel sign
	-- would sit under the card, so it hides while the card is up
	local phoneScreen = UiKit.Breakpoint(root.AbsoluteSize) == "phone"
	for _, w in wheels do
		w.sign.Enabled = not (showCrew and phoneScreen and w.shipId == player:GetAttribute("ShipId"))
	end
	if showCrew then
		crewEyebrow.Text = "YOUR CREW · " .. seats -- seats on this ship
		crewHeadline.Text = if leaving then (if atHarbor then "Sailing in " else "Next storm in ") .. clock(left) else "Waiting for crew"
		crewHeadline.TextColor3 = if leaving and left <= 5 then C.AccentLighthouseSoft else C.TextPrimary
		for i, row in rosterRows do
			local p = crew[i]
			if i <= MAX_ROSTER and p then
				row.frame.Visible = true
				row.check.Visible = true
				row.tag.Visible = true
				row.name.Text = if p == player then p.DisplayName .. " (you)" else p.DisplayName
			elseif i == MAX_ROSTER + 1 and crewCount > MAX_ROSTER then
				row.frame.Visible = true
				row.check.Visible = false
				row.tag.Visible = false
				row.name.Text = string.format("+%d more", crewCount - MAX_ROSTER)
			else
				row.frame.Visible = false
			end
		end
		local compact = UiKit.Breakpoint(root.AbsoluteSize) == "phone"
		crewInvite.Visible = canInvite and not invitedFromCrew and crewCount < 4 and not compact -- phones: invite lives on Results
		renderForecastVote(crew)
		renderVoyageChoice(crew)
		-- phones: the top timer already says when the ship sails, and the card must stay above the jump button
		local headline = crewBody:FindFirstChild("Headline")
		if headline then
			headline.Visible = not compact
		end
		leaveLine.Visible = not compact
		aboardLine.Visible = aboard > 0
		aboardLine.Text = string.format("%d more on the harbor, not in the crew", aboard)
		local onDeck = player:GetAttribute("BoardedByDeck") == true
		leaveLine.Text = if not onDeck then "Stay near the lighthouse. The next storm starts when the timer ends."
			elseif leaving and departure == "manual" then "SAIL NOW was called. Step off the ship to stay behind."
			elseif leaving then "The crew is full. Step off the ship to stay behind."
			else string.format("The ship sails when 4 are aboard, or use SAIL NOW at the ship's wheel (%s). Step off to leave the crew.", key)
	end
end

---------------------------------------------------------------------
-- LAYOUT
---------------------------------------------------------------------

-- VOTE.1: the crew card's height: its content, but never below the top of the BAG / CODES / jump buttons under it
local function obstacles(): { GuiObject }
	local list = {}
	local pg = player:FindFirstChild("PlayerGui")
	local inv = pg and pg:FindFirstChild("InventoryButton")
	for _, name in { "BagButton", "CodesButton" } do
		local b = inv and inv:FindFirstChild(name, true)
		if b and b:IsA("GuiObject") and b.Visible and (inv :: ScreenGui).Enabled then
			table.insert(list, b)
		end
	end
	local touch = pg and pg:FindFirstChild("TouchGui")
	local jump = touch and touch:FindFirstChild("JumpButton", true)
	if jump and jump:IsA("GuiObject") and jump.Visible and (touch :: ScreenGui).Enabled then
		table.insert(list, jump)
	end
	return list
end
local function fitCrewCard()
	if not crewCard.Visible then
		return
	end
	local top = crewCard.AbsolutePosition.Y
	local x0, x1 = crewCard.AbsolutePosition.X, crewCard.AbsolutePosition.X + crewCard.AbsoluteSize.X
	local limit = root.AbsolutePosition.Y + root.AbsoluteSize.Y - 12
	for _, o in obstacles() do
		local ox0, ox1 = o.AbsolutePosition.X, o.AbsolutePosition.X + o.AbsoluteSize.X
		if ox1 > x0 and ox0 < x1 and o.AbsolutePosition.Y > top then
			limit = math.min(limit, o.AbsolutePosition.Y - 10)
		end
	end
	local height = math.max(120, math.min(crewBody.AbsoluteSize.Y, limit - top))
	if crewCard.Size.Y.Offset ~= height then
		crewCard.Size = UDim2.fromOffset(crewCard.Size.X.Offset, height)
	end
end
crewBody:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitCrewCard)

-- QM.2 (owner 2026-10-20: the Pearls counter and the banner "combine" on a phone): the harbor card sits top centre,
-- but never reaches the Pearls counter in the top right (Client/Inventory's PearlsPill): when centring would touch
-- it, the card slides left and, if it must, gets narrower, always leaving a 12 px gap.
local pearlsPill: GuiObject? = nil
local function placeHarborCard()
	local size = root.AbsoluteSize
	if size.X <= 0 then
		return
	end
	local phone = UiKit.Breakpoint(size) == "phone"
	local hw = math.min(if phone then 460 else 600, size.X - 24)
	if not (pearlsPill and pearlsPill.Parent) then
		pearlsPill = player:WaitForChild("PlayerGui"):FindFirstChild("PearlsPill", true) :: GuiObject?
	end
	local right = size.X - 12
	local pill = pearlsPill
	if pill and pill.Visible and pill.AbsoluteSize.X > 0 then
		right = pill.AbsolutePosition.X - root.AbsolutePosition.X - 12
	end
	local left = (size.X - hw) / 2
	if left + hw > right then
		left = math.max(12, right - hw)
		hw = math.max(220, right - left)
	end
	harbor.AnchorPoint = Vector2.zero
	harbor.Size = UDim2.fromOffset(hw, if phone then 64 else 78)
	harbor.Position = UDim2.fromOffset(math.floor(left), if phone then 6 else 12)
end

local function layout()
	local size = root.AbsoluteSize
	if size.X <= 0 then
		return
	end
	local phone = UiKit.Breakpoint(size) == "phone"
	-- harbor card: top centre, where the HUD's voyage chip sits during a run
	placeHarborCard()
	local keyW = 0 -- boarding batch: no key to press, you walk aboard
	harborKey.Visible = false
	harborKey.Position = UDim2.new(1, -10, 0.5, 0)
	harborText.Position = UDim2.fromOffset(24, 4)
	harborText.Size = UDim2.new(1, -24 - keyW - 16, 1, -8)
	harborBody.TextSize = if phone then 13 else 15
	harborEyebrow.TextSize = if phone then 14 else 16
	-- crew card: top right, under the BAG button, clear of the HUD's centre cluster
	local cw = if phone then 230 else 300
	crewCard.Size = UDim2.fromOffset(cw, crewCard.Size.Y.Offset)
	crewCard.AutomaticSize = Enum.AutomaticSize.None -- VOTE.1: fitCrewCard sets the height
	crewCard.Position = UDim2.new(1, -12, 0, if phone then 52 else 120)
	crewBody.Size = UDim2.new(1, 0, 0, 0)
	crewBody.AutomaticSize = Enum.AutomaticSize.Y
	crewHeadline.TextSize = if phone then 18 else 22
	roster.Visible = not phone or #crewList() <= 2
	task.defer(fitCrewCard)
	travelColumn.Size = UDim2.fromOffset(math.min(520, size.X - 32), 120)
	-- voyage crew: left edge, above the phone thumbstick area
	voyageCard.Size = UDim2.fromOffset(if phone then 150 else 190, 0)
	voyageCard.Position = UDim2.new(0, if phone then 8 else 12, if phone then 0.36 else 0.4, 0)
end
root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
layout()

task.spawn(function()
	while true do
		render()
		fitCrewCard()
		placeHarborCard() -- the Pearls counter appears, hides and grows with its number
		task.wait(0.25)
	end
end)

---------------------------------------------------------------------
-- TRAVEL CARD (the server teleports ~0.35 s after Travel fires)
---------------------------------------------------------------------

local travelToken = 0
remotes:WaitForChild("Travel").OnClientEvent:Connect(function()
	travelToken += 1
	local mine = travelToken
	local phase = state:GetAttribute("Phase")
	if player:GetAttribute("Ready") then
		travelTitle.Text = "Lighthouse Island"
		travelSub.Text = if RUN_PHASES[phase] and phase ~= "Prologue" then "Rowing out to your crew. Keep the light alive." else "The storm is coming. Keep the light alive."
	else
		travelTitle.Text = "Harbor Island"
		travelSub.Text = "Back at the harbor. Walk onto the ship to sail again."
	end
	fader.Visible = true
	fader.BackgroundTransparency = 1
	for _, t in travelTexts do
		t.TextTransparency = 1
	end
	UiKit.tween(fader, 0.3, { BackgroundTransparency = 0 })
	task.delay(0.15, function()
		for _, t in travelTexts do
			UiKit.tween(t, 0.25, { TextTransparency = 0 })
		end
	end)
	task.delay(1.15, function()
		if mine ~= travelToken then
			return
		end
		for _, t in travelTexts do
			UiKit.tween(t, 0.2, { TextTransparency = 1 })
		end
		UiKit.tween(fader, 0.6, { BackgroundTransparency = 1 })
		task.delay(0.65, function()
			if mine == travelToken then
				fader.Visible = false
			end
		end)
	end)
end)

---------------------------------------------------------------------
-- STUDIO ONLY: simulated screen sizes (HudSimulate attribute)
---------------------------------------------------------------------

if RunService:IsStudio() then
	local SIZES = {
		smallPhone = Vector2.new(667, 375),
		largePhone = Vector2.new(932, 430),
		tablet = Vector2.new(1180, 820),
		laptop = Vector2.new(1366, 768),
	}
	local function applySimulation()
		local spec = SIZES[player:GetAttribute("HudSimulate") or ""]
		rootOutline.Enabled = spec ~= nil
		if spec then
			root.AnchorPoint = Vector2.new(0.5, 0.5)
			root.Position = UDim2.fromScale(0.5, 0.5)
			root.Size = UDim2.fromOffset(spec.X, spec.Y)
		else
			root.AnchorPoint = Vector2.zero
			root.Position = UDim2.new()
			root.Size = UDim2.fromScale(1, 1)
		end
		task.defer(layout)
	end
	player:GetAttributeChangedSignal("HudSimulate"):Connect(applySimulation)
	applySimulation()
end
