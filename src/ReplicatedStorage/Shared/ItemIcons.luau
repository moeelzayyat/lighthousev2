--!strict
-- ItemIcons (ICON1): the drawn picture for each item, by item id (Shared/Items and Definitions/Merchant ids).
-- Item icons v1: project-drawn vector art in the Bold look, 512x512 PNGs (assets/icons/ in the project files).
-- UI/Tiles shows the picture on shop, workbench, Trader and BAG tiles and in their detail panes; an item with no
-- entry keeps its 3D preview or glyph. Values are rbxassetid:// image ids uploaded from Studio.

local ItemIcons: { [string]: string } = {}

return ItemIcons
