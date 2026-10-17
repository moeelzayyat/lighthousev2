--!strict
-- UiKit · Kit (S5.5): the one UiKit table and the helpers its parts share (tokens, `new`, `tween`, ...). The
-- parts (Tokens, Primitives, Controls, Gauges, Dialogs) fill both in order when `UiKit` is first required.

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

return {
	UiKit = {} :: any,
	K = { rgb = rgb } :: any,
}
