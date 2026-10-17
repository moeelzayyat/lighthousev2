-- UiKit (client): the ONE shared visual system for every Lighthouse Keepers menu.
--
-- Direction: lighthouse machinery. Storm-navy surfaces, wet-slate panels, weathered brass
-- structure, warm lamp light for primary actions, ivory text, sea-blue information, coral
-- danger, rust warnings. Identity comes from instrument details (corner brackets, a beacon
-- line with gauge ticks, a lens arc on dialogs, compass ticks on gauges), never from ropes,
-- wood, parchment, skulls or glow.
--
-- CONTAINER TREATMENTS (each has its own silhouette; do not box everything):
--   Panel kind "housing"  menus: quiet brass frame, corner brackets, beacon line on top
--   Panel kind "dialog"   decisions: lens arc rising from the top edge, no brackets
--   UiKit.Inset           instrument faces: recessed, borderless (wells, tracks, ledgers)
--   UiKit.Section         groups: a label and a rule, NO box
--   UiKit.SettingRow      lists: rows split by hairline dividers, NO box
--   UiKit.ItemCard        items: slate card, borderless until selected/equipped
--   Gauges                HUD instruments: icon cap + track, one silhouette per resource
--
-- ORIENTATION (owner decision, Oct 10 2026): phone gameplay is locked to LandscapeSensor
-- (StarterGui.ScreenOrientation). Design and verify production screens for landscape phones
-- (667x375 to 932x430), tablet, desktop and widescreen. Keep every layout responsive and
-- safe-area aware anyway: the lock is not a fixed resolution, and narrow reflow must still work.
--
-- TEXT CASE: CAPS only for short headings, categories, buttons, warnings and instrument labels.
-- Descriptions, explanations, errors, confirmations and help are sentence case.
--
-- PARTS (S5.5): Client/UI/Tokens, Primitives, Controls, Gauges, Dialogs, loaded here in that order and merged
-- into this one table, so every screen keeps `require(UiKit)`. The v1 API (THEME, make, button, toast, ...) and
-- the old Gear screen were removed: nothing used them.

local UI = script.Parent:WaitForChild("UI")
local Kit = require(UI:WaitForChild("Kit"))
local UiKit = Kit.UiKit

for _, part in { "Tokens", "Primitives", "Controls", "Gauges", "Dialogs" } do
	require(UI:WaitForChild(part))
end

Kit.K.UiSkin.install(UiKit) -- wraps Panel / Button / IconButton / ItemCard when the skin is on

return UiKit
