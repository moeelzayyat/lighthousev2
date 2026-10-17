-- HudParts/Simulator (S5.6, STUDIO ONLY): layout simulator. Set the player attribute HudSimulate to
-- "smallPhone", "largePhone", "tablet" or "laptop" to draw the real HUD inside a screen of that exact size
-- (touch devices also show the Roblox joystick and jump-button zones). "" turns it off. Never runs live.

local Players = game:GetService("Players")

local Client = script.Parent.Parent
local UiKit = require(Client:WaitForChild("UiKit"))

local Simulator = {}

local SIZES = {
	smallPhone = { size = Vector2.new(667, 375), touch = true },
	largePhone = { size = Vector2.new(932, 430), touch = true },
	tablet = { size = Vector2.new(1180, 820), touch = true },
	laptop = { size = Vector2.new(1366, 768), touch = false },
}

-- S.simulated is set to the chosen size (nil when off); relayout() runs after every change
function Simulator.init(w, S, relayout)
	local player = Players.LocalPlayer
	local C = UiKit.Color
	local zones = {}
	local function zone(label, anchor, position, size)
		local z = UiKit.new("Frame", {
			Name = "TouchZone_" .. label,
			BackgroundColor3 = C.StateDanger,
			BackgroundTransparency = 0.85,
			AnchorPoint = anchor,
			Position = position,
			Size = size,
			Visible = false,
		}, w.promptRoot)
		UiKit.border(z, C.StateDanger, 1, 0.3)
		UiKit.Label(z, label, "Caption", { Position = UDim2.fromOffset(6, 4), Size = UDim2.new(1, -12, 0, 16), AutomaticSize = Enum.AutomaticSize.None, TextColor3 = C.StateDanger })
		table.insert(zones, z)
	end
	zone("Joystick start area", Vector2.new(0, 1), UDim2.fromScale(0, 1), UDim2.fromScale(0.4, 0.45))
	zone("Jump", Vector2.new(0, 0), UDim2.new(1, -95, 1, -90), UDim2.fromOffset(70, 70))
	local jumpZone = zones[#zones]
	local function applySimulation()
		local spec = SIZES[player:GetAttribute("HudSimulate") or ""]
		S.simulated = spec
		for _, root in { w.hudRoot, w.promptRoot } do
			root:FindFirstChildOfClass("UIStroke").Enabled = spec ~= nil
			if spec then
				root.AnchorPoint = Vector2.new(0.5, 0.5)
				root.Position = UDim2.fromScale(0.5, 0.5)
				root.Size = UDim2.fromOffset(spec.size.X, spec.size.Y)
			else
				root.AnchorPoint = Vector2.zero
				root.Position = UDim2.new()
				root.Size = UDim2.fromScale(1, 1)
			end
		end
		for _, z in zones do
			z.Visible = spec ~= nil and spec.touch
		end
		if spec then
			local small = math.min(spec.size.X, spec.size.Y) <= 500
			jumpZone.Position = if small then UDim2.new(1, -95, 1, -90) else UDim2.new(1, -170, 1, -210)
			jumpZone.Size = if small then UDim2.fromOffset(70, 70) else UDim2.fromOffset(120, 120)
		end
		task.defer(relayout)
	end
	player:GetAttributeChangedSignal("HudSimulate"):Connect(applySimulation)
end

return Simulator
