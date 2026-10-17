--!strict
-- HarborBoard (client, harbor UI): draws the harbor leaderboard as "HARBOR LEGENDS". The server still writes the
-- three boards into the board's own SurfaceGui (LiveOps → LeaderboardService: a title and ten "N. Name  score"
-- rows per board); this script reads those labels, hides the plain face on this device and draws a podium for the
-- top 3 (gold, silver, bronze), rows 4–10 and a "your rank" strip. A prompt on the board opens the same boards
-- full screen. Nothing new is sent between the server and the client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Leaderboards = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("Leaderboards")) :: any

local UiKit = require(script.Parent:WaitForChild("UiKit"))

local C, F = UiKit.Color, UiKit.Font
local style = (UiKit.Skin and UiKit.Skin.style) or {}
local OUTLINE: Color3 = style.outline or C.BorderStructural
local TITLE: Color3 = style.title or C.AccentLighthouse
local localPlayer = Players.LocalPlayer

local BOARDS = { "BestNightStandard", "BestNightLong", "WeeklyNights" }
local MEDALS = {
	{ color = Color3.fromRGB(255, 196, 46), dark = Color3.fromRGB(160, 110, 10) }, -- gold
	{ color = Color3.fromRGB(200, 212, 226), dark = Color3.fromRGB(110, 124, 140) }, -- silver
	{ color = Color3.fromRGB(214, 138, 82), dark = Color3.fromRGB(128, 72, 36) }, -- bronze
}

type Entry = { rank: number, name: string, score: number }

local function new(className: string, props: { [string]: any }, parent: Instance?): any
	local inst = Instance.new(className)
	for key, value in props do
		(inst :: any)[key] = value
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(parent: Instance, radius: number)
	new("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(parent: Instance, thickness: number, color: Color3?)
	new("UIStroke", { Thickness = thickness, Color = color or OUTLINE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
end

local function textOutline(label: Instance, thickness: number)
	new("UIStroke", { Thickness = thickness, Color = OUTLINE, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, label)
end

local function text(parent: Instance, props: { [string]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		FontFace = F.Body,
		TextColor3 = C.TextPrimary,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	}
	for key, value in props do
		defaults[key] = value
	end
	return new("TextLabel", defaults, parent)
end

-- "3. Ana  12" -> { rank = 3, name = "Ana", score = 12 }
local function parse(line: string): Entry?
	local rank, name, score = string.match(line, "^(%d+)%. (.-)%s%s+(%d+)$")
	if rank and name and score then
		return { rank = tonumber(rank) :: number, name = name, score = tonumber(score) :: number }
	end
	return nil
end

-- the boards as the server last wrote them
local function read(column: Instance): (string, { Entry })
	-- the title comes from the shared definitions (the server writes its label only at the first flush)
	local def = Leaderboards[column.Name]
	local titleLabel = column:FindFirstChild("Title") :: TextLabel?
	local entries = {}
	for i = 1, 10 do
		local row = column:FindFirstChild("Row" .. i) :: TextLabel?
		local entry = row and parse(row.Text)
		if entry then
			table.insert(entries, entry)
		end
	end
	return if def then def.title elseif titleLabel then titleLabel.Text else "", entries
end

-- One board: its title, a podium for the top 3, rows 4–10. `big` = the full-screen view.
local function drawBoard(parent: Instance, title: string, entries: { Entry }, big: boolean)
	local frame = new("Frame", { Name = "Board", BackgroundColor3 = C.SurfaceSecondary, Size = UDim2.fromScale(1, 1) }, parent)
	corner(frame, if big then 18 else 16)
	stroke(frame, if big then 4 else 5)
	text(frame, {
		Name = "Title",
		Text = string.upper(title),
		FontFace = F.Heading,
		TextColor3 = TITLE,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromScale(0.05, 0.03),
		Size = UDim2.fromScale(0.9, 0.11),
	})
	-- podium: 2nd | 1st (tallest) | 3rd
	local podium = new("Frame", { Name = "Podium", BackgroundTransparency = 1, Position = UDim2.fromScale(0.05, 0.15), Size = UDim2.fromScale(0.9, 0.42) }, frame)
	local SLOTS = { { rank = 2, x = 0, h = 0.72 }, { rank = 1, x = 1 / 3, h = 0.9 }, { rank = 3, x = 2 / 3, h = 0.6 } }
	for _, slot in SLOTS do
		local medal = MEDALS[slot.rank]
		local entry = entries[slot.rank]
		local block = new("Frame", {
			Name = "Place" .. slot.rank,
			BackgroundColor3 = if entry then medal.color else C.SurfaceInset,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(slot.x, 3, 1, 0),
			Size = UDim2.new(1 / 3, -6, slot.h, 0),
		}, podium)
		corner(block, 10)
		stroke(block, 3)
		text(block, {
			Name = "Rank",
			Text = tostring(slot.rank),
			FontFace = F.Display,
			TextColor3 = if entry then medal.dark else C.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromScale(0, 0.04),
			Size = UDim2.fromScale(1, 0.34),
		})
		text(block, {
			Name = "PlayerName",
			Text = if entry then entry.name else "—",
			FontFace = F.BodyBold,
			TextColor3 = if entry then Color3.fromRGB(24, 18, 8) else C.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromScale(0.06, 0.42),
			Size = UDim2.fromScale(0.88, 0.24),
		})
		text(block, {
			Name = "Score",
			Text = if entry then tostring(entry.score) else "",
			FontFace = F.Numeric,
			TextColor3 = if entry then Color3.fromRGB(24, 18, 8) else C.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromScale(0.1, 0.68),
			Size = UDim2.fromScale(0.8, 0.24),
		})
	end
	-- rows 4–10
	local list = new("Frame", { Name = "Rows", BackgroundTransparency = 1, Position = UDim2.fromScale(0.05, 0.6), Size = UDim2.fromScale(0.9, 0.38) }, frame)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, list)
	if #entries == 0 then
		text(list, { Name = "Empty", Text = "No one yet. Be the first!", TextColor3 = C.TextSecondary, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 0.2) })
	end
	for i = 4, 10 do
		local entry = entries[i]
		if entry then
			local row = new("Frame", { Name = "Row" .. i, BackgroundColor3 = C.SurfaceInset, BackgroundTransparency = if i % 2 == 0 then 0 else 0.4, Size = UDim2.new(1, 0, 1 / 7, -2), LayoutOrder = i }, list)
			corner(row, 6)
			text(row, { Text = string.format("%d.  %s", entry.rank, entry.name), Position = UDim2.fromScale(0.04, 0.1), Size = UDim2.fromScale(0.72, 0.8) })
			text(row, { Text = tostring(entry.score), FontFace = F.Numeric, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromScale(0.76, 0.1), Size = UDim2.fromScale(0.2, 0.8) })
		end
	end
	return frame
end

-- "Your rank": the best place this player holds on any board shown (the boards list display names)
local function yourRank(columns: { [string]: Instance }): string
	local me = localPlayer.DisplayName
	local best: { rank: number, title: string }? = nil
	for _, id in BOARDS do
		local column = columns[id]
		if column then
			local title, entries = read(column)
			for _, entry in entries do
				if entry.name == me and (best == nil or entry.rank < best.rank) then
					best = { rank = entry.rank, title = title }
				end
			end
		end
	end
	if best then
		return string.format("YOU: #%d on %s", best.rank, best.title)
	end
	return "Survive a night on a voyage to get on the boards"
end

local function drawAll(container: Instance, columns: { [string]: Instance }, big: boolean)
	for _, child in container:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local header = text(container, {
		Name = "Header",
		Text = "HARBOR LEGENDS",
		FontFace = F.Display,
		TextColor3 = TITLE,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromScale(0.1, 0.02),
		Size = UDim2.fromScale(0.8, 0.13),
	})
	textOutline(header, if big then 3 else 4)
	local row = new("Frame", { Name = "Boards", BackgroundTransparency = 1, Position = UDim2.fromScale(0.02, 0.16), Size = UDim2.fromScale(0.96, 0.7) }, container)
	for i, id in BOARDS do
		local column = columns[id]
		local slot = new("Frame", { Name = id, BackgroundTransparency = 1, Position = UDim2.new((i - 1) / 3, 4, 0, 0), Size = UDim2.new(1 / 3, -8, 1, 0) }, row)
		if column then
			local title, entries = read(column)
			drawBoard(slot, title, entries, big)
		end
	end
	local strip = new("Frame", { Name = "YourRank", BackgroundColor3 = C.SurfaceElevated, Position = UDim2.fromScale(0.2, 0.885), Size = UDim2.fromScale(0.6, 0.09) }, container)
	corner(strip, 12)
	stroke(strip, 3)
	text(strip, { Name = "Text", Text = yourRank(columns), FontFace = F.BodyBold, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromScale(0.04, 0.12), Size = UDim2.fromScale(0.92, 0.76) })
end

---------------------------------------------------------------------
-- the board in the world
---------------------------------------------------------------------

local lobby = Workspace:WaitForChild("Lobby")
local board = lobby:WaitForChild("LeaderboardBoard") :: BasePart
local serverFace = board:WaitForChild("Boards") :: SurfaceGui
local columns: { [string]: Instance } = {}
for _, id in BOARDS do
	columns[id] = serverFace:WaitForChild(id)
end
serverFace.Enabled = false -- this device draws the board instead (the server keeps writing the rows)

local face = new("SurfaceGui", {
	Name = "HarborLegends",
	Adornee = board,
	Face = Enum.NormalId.Front,
	SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
	PixelsPerStud = 50,
	LightInfluence = 0,
	ResetOnSpawn = false,
}, localPlayer:WaitForChild("PlayerGui"))
local faceRoot = new("Frame", { Name = "Root", BackgroundColor3 = C.SurfacePrimary, Size = UDim2.fromScale(1, 1) }, face)
corner(faceRoot, 24)
stroke(faceRoot, 8)

---------------------------------------------------------------------
-- full screen, from a prompt on the board
---------------------------------------------------------------------

local screen = UiKit.Screen("HarborLegends", 18)
screen.Enabled = false
local scrim = new("TextButton", { Name = "Scrim", Text = "", AutoButtonColor = false, BackgroundColor3 = C.Scrim, BackgroundTransparency = 0.3, Size = UDim2.fromScale(1, 1) }, screen)
local panel = UiKit.Panel(screen, { name = "LegendsPanel", kind = "housing", padding = 0, anchor = Vector2.new(0.5, 0.5), position = UDim2.fromScale(0.5, 0.5), size = UDim2.fromScale(0.86, 0.86) })
new("UIAspectRatioConstraint", { AspectRatio = 16 / 9.5 }, panel)
local panelBody = new("Frame", { Name = "Body", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, panel)
local function close()
	screen.Enabled = false
	UiKit.popModal("HarborLegends")
end
local closeButton = UiKit.IconButton(panel, "close", { name = "Close", tip = "Close", onClick = close })
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -14, 0, 14)
closeButton.ZIndex = 5
scrim.Activated:Connect(close)

-- the server writes 33 labels at a time; draw once after they have all landed
local queued = false
local function redraw()
	if queued then
		return
	end
	queued = true
	task.delay(0.2, function()
		queued = false
		drawAll(faceRoot, columns, false)
		if screen.Enabled then
			drawAll(panelBody, columns, true)
		end
	end)
end

local prompt = new("ProximityPrompt", {
	Name = "ViewBoards",
	ActionText = "View the boards",
	ObjectText = "Harbor Legends",
	HoldDuration = 0,
	MaxActivationDistance = 14,
	RequiresLineOfSight = false,
}, board)
prompt.Triggered:Connect(function()
	screen.Enabled = true
	UiKit.pushModal("HarborLegends")
	redraw()
end)

-- redraw whenever the server writes a title or a row
for _, column in columns do
	for _, label in column:GetChildren() do
		if label:IsA("TextLabel") then
			label:GetPropertyChangedSignal("Text"):Connect(redraw)
		end
	end
end
redraw()
