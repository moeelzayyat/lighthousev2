-- HudParts/Prompts (S5.6): the interaction prompt cards (one main action plus at most one alternative).
-- ProximityPrompts are drawn here in the shared style (Style = Custom); the engine still decides which
-- prompts are in range and handles keys, holds and triggering. Built in the HUD's glass variant.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Workspace = game:GetService("Workspace")

local Client = script.Parent.Parent
local UiKit = require(Client:WaitForChild("UiKit"))
local InputController = require(Client:WaitForChild("InputController"))

local Prompts = {}

-- bottom: the HUD's bottom band. Returns { primary, secondary, render(), shown (prompt -> true) }.
function Prompts.init(bottom)
	local state = ReplicatedStorage:WaitForChild("GameState")
	local player = Players.LocalPlayer
	local inputMode = InputController.mode
	local C = UiKit.palette()
	local F = UiKit.Font
	local GLASS = UiKit.GLASS

	-- prompt cards (primary + one secondary); the key chip sits at the right edge (mock-up:
	-- "Grab oil for the lamp  [TAP]")
	local function promptCard(name, order, compact)
		local b = UiKit.new("TextButton", {
			Name = name,
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = C.SurfacePrimary,
			BackgroundTransparency = 0.05,
			Size = UDim2.new(1, 0, 0, if compact then 46 else 56),
			LayoutOrder = order,
			Visible = false,
			Selectable = false,
			ClipsDescendants = true,
		}, bottom)
		UiKit.round(b, UiKit.Radius.panel)
		local stroke = UiKit.border(b, C.BorderStructural, 1, 0.3)
		local key = UiKit.new("Frame", {
			Name = "Key",
			BackgroundColor3 = GLASS.chip,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(54, if compact then 30 else 36),
		}, b)
		UiKit.round(key, 10)
		UiKit.border(key, GLASS.glow, 1, 0.2)
		local keyText = UiKit.new("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = F.LabelBold,
			TextSize = if compact then 15 else 17,
			TextColor3 = GLASS.text,
			Size = UDim2.fromScale(1, 1),
		}, key)
		local keyImage = UiKit.new("ImageLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.8),
			Visible = false,
		}, key)
		local action = UiKit.new("TextLabel", {
			Name = "Action",
			BackgroundTransparency = 1,
			FontFace = F.BodyBold,
			TextSize = if compact then 15 else 17,
			TextColor3 = C.TextPrimary,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.new(0, 16, 0, if compact then 5 else 8),
			Size = UDim2.new(1, -16 - 54 - 18, 0, 20),
		}, b)
		local object = UiKit.new("TextLabel", {
			Name = "Object",
			BackgroundTransparency = 1,
			FontFace = F.Body,
			TextSize = if compact then 13 else 14,
			TextColor3 = C.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.new(0, 16, 0, if compact then 24 else 30),
			Size = UDim2.new(1, -16 - 54 - 18, 0, 18),
		}, b)
		local hold = UiKit.new("Frame", {
			Name = "Hold",
			BackgroundColor3 = C.AccentLighthouse,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(0, 0, 0, 3),
			ZIndex = 3,
		}, b)
		UiKit.glassPanel(b)
		-- PH.2 (owner, phone): measuring labels so a phone card can be just as wide as its text (Layout sets FitMax)
		local function measure(label)
			return UiKit.new("TextLabel", {
				Name = "Measure" .. label.Name,
				BackgroundTransparency = 1,
				TextTransparency = 1,
				FontFace = label.FontFace,
				TextSize = label.TextSize,
				TextWrapped = false,
				Text = "",
				Size = UDim2.fromOffset(0, 0),
				AutomaticSize = Enum.AutomaticSize.X,
			}, b)
		end
		local cardObj = { button = b, stroke = stroke, keyText = keyText, keyImage = keyImage, action = action, object = object, hold = hold, prompt = nil, measureA = measure(action), measureB = measure(object) }
		local function fit()
			local maxW = b:GetAttribute("FitMax")
			if type(maxW) ~= "number" then
				return
			end
			-- text + left padding 16 + key chip 54 + gaps 22
			local want = math.max(cardObj.measureA.TextBounds.X, cardObj.measureB.TextBounds.X) + 16 + 54 + 22
			b.Size = UDim2.new(0, math.clamp(math.ceil(want), math.min(180, maxW), maxW), 0, b.Size.Y.Offset)
		end
		cardObj.fit = fit
		cardObj.measureA:GetPropertyChangedSignal("TextBounds"):Connect(fit)
		cardObj.measureB:GetPropertyChangedSignal("TextBounds"):Connect(fit)
		b:GetAttributeChangedSignal("FitMax"):Connect(fit)
		return cardObj
	end
	local primaryCard = promptCard("PrimaryPrompt", 3, false)
	local secondaryCard = promptCard("SecondaryPrompt", 4, true)

	local shownPrompts = {}
	local holdStart = {}

	local function claim(object)
		if object:IsA("ProximityPrompt") then
			object.Style = Enum.ProximityPromptStyle.Custom -- drawn by this script; the engine still handles input
		end
	end
	for _, d in Workspace:GetDescendants() do
		claim(d)
	end
	Workspace.DescendantAdded:Connect(claim)

	local function promptPosition(prompt)
		local parent = prompt.Parent
		if parent and parent:IsA("Attachment") then
			return parent.WorldPosition
		elseif parent and parent:IsA("BasePart") then
			return parent.Position
		elseif parent and parent:IsA("Model") then
			return parent:GetPivot().Position
		end
		return nil
	end

	local function keyName(keyCode)
		local names = { One = "1", Two = "2", Three = "3", Four = "4", Return = "ENTER", LeftShift = "SHIFT" }
		return names[keyCode.Name] or keyCode.Name
	end

	local function fillCard(cardObj, prompt)
		cardObj.prompt = prompt
		cardObj.button.Visible = prompt ~= nil
		cardObj.hold.Size = UDim2.new(0, 0, 0, 3)
		if not prompt then
			return
		end
		local holds = prompt.HoldDuration > 0
		cardObj.action.Text = if prompt.ActionText ~= "" then prompt.ActionText else "Interact"
		local objectText = prompt.ObjectText
		if holds then
			objectText = (if objectText ~= "" then objectText .. "  ·  " else "") .. "Hold"
		end
		cardObj.object.Text = objectText
		cardObj.measureA.Text = cardObj.action.Text -- PH.2
		cardObj.measureB.Text = objectText
		cardObj.fit()
		local mode = inputMode()
		cardObj.keyImage.Visible = false
		cardObj.keyText.Visible = true
		cardObj.keyText.TextSize = if mode == "keyboard" then 17 else 12
		if mode == "gamepad" then
			local image = UserInputService:GetImageForKeyCode(prompt.GamepadKeyCode)
			if image and image ~= "" then
				cardObj.keyImage.Image = image
				cardObj.keyImage.Visible = true
				cardObj.keyText.Visible = false
			else
				cardObj.keyText.Text = keyName(prompt.GamepadKeyCode):gsub("Button", "")
			end
		elseif mode == "touch" then
			cardObj.keyText.Text = if holds then "HOLD" else "TAP"
		else
			cardObj.keyText.Text = keyName(prompt.KeyboardKeyCode)
		end
	end

	local function renderPrompts()
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local list = {}
		for prompt in shownPrompts do
			if prompt.Parent and prompt.Enabled then
				table.insert(list, prompt)
			else
				shownPrompts[prompt] = nil
			end
		end
		if root then
			table.sort(list, function(a, b)
				local pa, pb = promptPosition(a), promptPosition(b)
				local da = if pa then (pa - root.Position).Magnitude else math.huge
				local db = if pb then (pb - root.Position).Magnitude else math.huge
				return da < db
			end)
		end
		-- one main action, plus at most one alternative (e.g. Upgrade + Reload at a cannon).
		-- None while you are the Keeper (the lamp view has its own controls) or once the voyage has ended.
		local phase = state:GetAttribute("Phase")
		if (state:GetAttribute("KeeperUserId") or 0) == player.UserId or phase == "Victory" or phase == "Defeat" then
			table.clear(list)
		end
		fillCard(primaryCard, list[1])
		fillCard(secondaryCard, list[2])
	end

	ProximityPromptService.PromptShown:Connect(function(prompt)
		claim(prompt)
		shownPrompts[prompt] = true
		renderPrompts()
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt)
		shownPrompts[prompt] = nil
		holdStart[prompt] = nil
		renderPrompts()
	end)
	ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, who)
		if who == player then
			holdStart[prompt] = os.clock()
		end
	end)
	ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt)
		holdStart[prompt] = nil
	end)
	ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
		if who ~= player then
			return
		end
		holdStart[prompt] = nil
		for _, cardObj in { primaryCard, secondaryCard } do
			if cardObj.prompt == prompt then
				cardObj.stroke.Color = C.AccentLighthouse
				cardObj.stroke.Transparency = 0
				task.delay(0.35, function()
					cardObj.stroke.Color = GLASS.glow
					cardObj.stroke.Transparency = 0.3
				end)
			end
		end
	end)

	-- touch / mouse: press and hold the card itself
	for _, cardObj in { primaryCard, secondaryCard } do
		cardObj.button.InputBegan:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) and cardObj.prompt then
				cardObj.pressed = cardObj.prompt
				cardObj.prompt:InputHoldBegin()
			end
		end)
		cardObj.button.InputEnded:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) and cardObj.pressed then
				cardObj.pressed:InputHoldEnd()
				cardObj.pressed = nil
			end
		end)
	end

	-- hold progress bars
	RunService.RenderStepped:Connect(function()
		for _, cardObj in { primaryCard, secondaryCard } do
			local prompt = cardObj.prompt
			local started = prompt and holdStart[prompt]
			if started and prompt.HoldDuration > 0 then
				cardObj.hold.Size = UDim2.new(math.clamp((os.clock() - started) / prompt.HoldDuration, 0, 1), 0, 0, 3)
			elseif cardObj.hold.Size.X.Scale ~= 0 then
				cardObj.hold.Size = UDim2.new(0, 0, 0, 3)
			end
		end
	end)

	return { primary = primaryCard, secondary = secondaryCard, render = renderPrompts, shown = shownPrompts }
end

return Prompts
