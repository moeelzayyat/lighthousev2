-- HudParts/Bosses (S5.6): one boss bar per live big monster (never an empty bar), from GameState.Bosses
-- (CreatureService). Bars are built in the HUD's glass variant when the monster appears.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = script.Parent.Parent
local UiKit = require(Client:WaitForChild("UiKit"))

local Bosses = {}

-- bossList: the frame the bars go in; toastRoot: where "defeated" notices show; onChange(): called after a
-- bar is added or removed. Returns the live bars (entry -> { frame }).
function Bosses.init(bossList, toastRoot, onChange)
	local state = ReplicatedStorage:WaitForChild("GameState")
	local C = UiKit.palette()
	local F = UiKit.Font
	local bossBars = {}

	local function makeBossBar(entry)
		local frame = UiKit.new("Frame", {
			Name = "Boss_" .. entry.Name,
			BackgroundColor3 = C.SurfaceBase,
			BackgroundTransparency = 0.15,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, bossList)
		UiKit.round(frame, UiKit.Radius.card)
		UiKit.border(frame, C.StateDanger, 1, 0.5)
		UiKit.pad(frame, 8, 12, 9, 12)
		local name = UiKit.new("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = F.LabelBold,
			TextSize = 17,
			TextColor3 = C.TextPrimary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(0.7, 0, 0, 20),
		}, frame)
		local readout = UiKit.new("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = F.Numeric,
			TextSize = 15,
			TextColor3 = C.TextPrimary,
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.new(0.3, 0, 0, 20),
		}, frame)
		name.Name = "BossName"
		readout.Name = "BossReadout"
		UiKit.fitHeader(name, readout)
		local track = UiKit.Inset(frame, { Name = "Track", Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 12) })
		local trail = UiKit.new("Frame", { BackgroundColor3 = C.HealthTrail, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 2 }, track)
		UiKit.round(trail, 3)
		local fill = UiKit.new("Frame", { BackgroundColor3 = C.StateDanger, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 3 }, track)
		UiKit.round(fill, 3)
		for i = 1, 9 do
			UiKit.new("Frame", {
				BackgroundColor3 = C.SurfaceBase,
				BackgroundTransparency = 0.3,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(i / 10, 0),
				Size = UDim2.new(0, 2, 1, 0),
				ZIndex = 4,
			}, track)
		end
		local bar = { frame = frame }
		local shownAlpha, token = nil, 0
		local displayName = entry:GetAttribute("DisplayName") or "Big monster"
		local function update()
			local h = entry:GetAttribute("Health") or 0
			local m = math.max(1, entry:GetAttribute("Max") or 1)
			local alpha = math.clamp(h / m, 0, 1)
			fill.Size = UDim2.fromScale(alpha, 1)
			if shownAlpha and alpha < shownAlpha then
				trail.Size = UDim2.fromScale(shownAlpha, 1)
				token += 1
				local mine = token
				task.delay(0.35, function()
					if mine == token then
						UiKit.tween(trail, 0.3, { Size = UDim2.fromScale(alpha, 1) })
					end
				end)
			else
				trail.Size = UDim2.fromScale(alpha, 1)
			end
			shownAlpha = alpha
			readout.Text = string.format("%d / %d", h, m)
			local outcome = entry:GetAttribute("Outcome")
			if outcome == "killed" then
				name.Text = string.upper(displayName) .. " · DEFEATED"
				name.TextColor3 = C.StateSuccess
			elseif outcome == "fled" then
				name.Text = string.upper(displayName) .. " · RETREATED"
				name.TextColor3 = C.TextSecondary
			else
				name.Text = string.upper(displayName)
			end
		end
		entry.AttributeChanged:Connect(function(attribute)
			update()
			if attribute == "Outcome" and entry:GetAttribute("Outcome") == "killed" then
				UiKit.Glass(function()
					UiKit.Toast(toastRoot, displayName .. " was driven off for good.", "success", { title = "Big monster defeated" })
				end)
			end
		end)
		update()
		bossBars[entry] = bar
	end

	local function removeBossBar(entry)
		local bar = bossBars[entry]
		if bar then
			bar.frame:Destroy()
			bossBars[entry] = nil
		end
	end

	local function bindBosses(folder)
		for _, entry in folder:GetChildren() do
			UiKit.Glass(function()
				makeBossBar(entry)
			end)
		end
		folder.ChildAdded:Connect(function(entry)
			UiKit.Glass(function()
				makeBossBar(entry)
			end)
			onChange()
		end)
		folder.ChildRemoved:Connect(function(entry)
			removeBossBar(entry)
			onChange()
		end)
	end
	if state:FindFirstChild("Bosses") then
		bindBosses(state.Bosses)
	end
	state.ChildAdded:Connect(function(child)
		if child.Name == "Bosses" then
			bindBosses(child)
		end
	end)

	return bossBars
end

return Bosses
