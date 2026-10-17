-- CodeBox (L1.4, LO.4): the "redeem a code" box: a text box and a Redeem button, used in Settings (title screen) and
-- in the BAG (so players who skip the title can use codes too). The server takes one code every 10 s; its answer
-- (CodeResult) shows as a notice on the screen the code was sent from.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UiKit = require(script.Parent:WaitForChild("UiKit"))

local C, new = UiKit.Color, UiKit.new
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local CodeBox = {}

local readyAt = 0 -- the server takes one code every 10 s
local answerRoot = nil -- where the last code was sent from
remotes:WaitForChild("CodeResult").OnClientEvent:Connect(function(ok, message)
	if type(message) == "string" and answerRoot then
		UiKit.Toast(answerRoot, message, if ok then "success" else "warning")
	end
end)

-- Sends a code (the BAG's menu-pattern box draws its own field and button); notices go to `toastRoot`
function CodeBox.send(text, toastRoot)
	if string.gsub(text, "%s", "") == "" then
		UiKit.Toast(toastRoot, "Type a code first.", "info")
		return
	end
	if os.clock() < readyAt then
		UiKit.Toast(toastRoot, "One code every 10 seconds. Try again in a moment.", "info")
		return
	end
	readyAt = os.clock() + 10
	answerRoot = toastRoot
	remotes.CodeRedeem:FireServer(text)
end

-- A box and a button filling `parent`'s width; notices go to `toastRoot`
function CodeBox.build(parent, toastRoot, layoutOrder)
	local row = new("Frame", {
		Name = "CodeBox",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, UiKit.TOUCH),
		LayoutOrder = layoutOrder or 1,
	}, parent)
	UiKit.list(row, "x", 8, { VerticalAlignment = Enum.VerticalAlignment.Center })
	local style = UiKit.Label(row, "", "Body")
	local box = new("TextBox", {
		Name = "CodeBox",
		BackgroundColor3 = C.SurfaceBase,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -118, 1, 0),
		FontFace = style.FontFace,
		TextSize = style.TextSize,
		TextColor3 = C.TextPrimary,
		PlaceholderColor3 = C.TextMuted,
		PlaceholderText = "Type a code",
		Text = "",
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
	}, row)
	style:Destroy()
	UiKit.round(box, 8)
	UiKit.border(box, C.BorderStructural, 1, 0.2)
	UiKit.pad(box, 0, 10, 0, 10)
	local redeem = UiKit.Button(row, "Redeem", { name = "RedeemButton", variant = "secondary", width = 110, layoutOrder = 2 })
	redeem.Activated:Connect(function()
		CodeBox.send(box.Text, toastRoot)
	end)
	return row
end

return CodeBox
