-- UiKit · Tokens (S5.5): colours, fonts and type, spacing, radii, motion timings (and the optional art skin's remap).
-- Moved unchanged from UiKit; screens still require UiKit, which loads the parts in order. The design rules
-- are at the top of UiKit.


local Kit = require(script.Parent:WaitForChild("Kit"))
local UiKit, K = Kit.UiKit, Kit.K
local rgb = K.rgb

---------------------------------------------------------------------
-- TOKENS
---------------------------------------------------------------------

local Color = {
	SurfaceBase = rgb(9, 14, 24),
	SurfacePrimary = rgb(15, 23, 37), -- storm navy
	SurfaceSecondary = rgb(27, 37, 50), -- wet slate
	SurfaceElevated = rgb(37, 50, 66),
	SurfaceHover = rgb(46, 61, 80),
	SurfaceInset = rgb(10, 16, 27),
	Scrim = rgb(4, 7, 12),
	BorderStructural = rgb(128, 104, 64), -- weathered brass
	BorderBrassBright = rgb(201, 165, 104),
	BorderSubtle = rgb(48, 62, 80),
	BorderSelected = rgb(242, 193, 78),
	BorderFocus = rgb(241, 234, 219), -- controller focus is IVORY, selection is GOLD
	TextPrimary = rgb(241, 234, 219), -- warm ivory
	TextSecondary = rgb(192, 186, 172),
	TextMuted = rgb(156, 158, 160),
	TextOnAccent = rgb(30, 21, 6),
	AccentLighthouse = rgb(242, 193, 78),
	AccentLighthouseDeep = rgb(196, 140, 44),
	AccentLighthouseSoft = rgb(255, 226, 158),
	AccentSea = rgb(127, 167, 196),
	AccentSeaDeep = rgb(58, 92, 120),
	StateDanger = rgb(234, 114, 96), -- coral
	StateWarning = rgb(214, 128, 46), -- rust orange
	StateSuccess = rgb(112, 192, 144),
	StateDisabled = rgb(46, 54, 66),
	StateDisabledText = rgb(132, 138, 148),
	HealthTrail = rgb(255, 204, 186),
	Stone = rgb(206, 198, 180), -- tower masonry
	Pearl = rgb(230, 224, 242),
	Shell = rgb(236, 178, 128),
	CatWeapons = rgb(226, 140, 72),
	CatArmor = rgb(110, 156, 206),
	CatAmmunition = rgb(196, 164, 98),
	CatMaterials = rgb(126, 192, 160),
}
UiKit.Color = Color

UiKit.CATEGORY = {
	Weapons = "CatWeapons",
	Armor = "CatArmor",
	Ammunition = "CatAmmunition",
	Materials = "CatMaterials",
	Loot = "CatMaterials",
}

local function family(name)
	return "rbxasset://fonts/families/" .. name .. ".json"
end

local Fonts = {
	Display = Font.new(family("Merriweather"), Enum.FontWeight.Heavy),
	Heading = Font.new(family("Merriweather"), Enum.FontWeight.Bold),
	Label = Font.new(family("Oswald"), Enum.FontWeight.Medium),
	LabelBold = Font.new(family("Oswald"), Enum.FontWeight.Bold),
	Body = Font.new(family("BuilderSans"), Enum.FontWeight.Regular),
	BodyMedium = Font.new(family("BuilderSans"), Enum.FontWeight.Medium),
	BodyBold = Font.new(family("BuilderSans"), Enum.FontWeight.Bold),
	Numeric = Font.new(family("BuilderSans"), Enum.FontWeight.ExtraBold),
}
UiKit.Font = Fonts

-- Optional art skin (Config.UI_SKIN): warms the colour tokens before anything is built
local UiSkin = require(script.Parent.Parent:WaitForChild("UiSkin"))
UiSkin.remap(Color, Fonts)
UiKit.Skin = UiSkin

-- upper = true only for headings/labels. lineHeight for multi-line reading text.
local Type = {
	Display = { font = "Display", size = 56 },
	H1 = { font = "Heading", size = 30 },
	H2 = { font = "Heading", size = 23 },
	H3 = { font = "BodyBold", size = 18 },
	Eyebrow = { font = "Label", size = 16, color = "AccentLighthouse", upper = true },
	Label = { font = "Label", size = 15, color = "TextSecondary", upper = true }, -- instrument labels
	Body = { font = "Body", size = 17, lineHeight = 1.12 },
	BodySmall = { font = "Body", size = 15, color = "TextSecondary", lineHeight = 1.1 },
	Micro = { font = "BodyMedium", size = 13, color = "TextMuted" }, -- smallest readable size
	Caption = { font = "Label", size = 14, color = "TextMuted", upper = true },
	Number = { font = "Numeric", size = 22 },
}
UiKit.Type = Type

UiKit.Space = { xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32, xxxl = 48 }
UiKit.Radius = { panel = 6, card = 4, control = 4, tag = 2 }
UiKit.Motion = { fast = 0.12, base = 0.18, slow = 0.32 }
UiKit.TOUCH = 44

K.Color = Color
K.Fonts = Fonts
K.Type = Type
K.UiSkin = UiSkin

return true
