--!strict
-- InputController (S2.6, client): the one answer to "what is the player using?" and the controller aim rule.
-- Replaces the inputMode() copies that Coach, Hud, Menus, Departure and UiKit each kept.
--   mode()                "keyboard" | "touch" | "gamepad" from the last input
--   usingGamepad()        the last input came from any controller
--   stickAngle(x, y)      beam angle for a thumbstick, or nil inside the dead zone

local UserInputService = game:GetService("UserInputService")

local InputController = {}

export type Mode = "keyboard" | "touch" | "gamepad"

-- a stick must be pushed this far (0..1) before it aims
InputController.STICK_DEADZONE = 0.35

function InputController.usingGamepad(): boolean
	local last = UserInputService:GetLastInputType()
	return string.sub(last.Name, 1, 7) == "Gamepad"
end

function InputController.mode(): Mode
	if UserInputService:GetLastInputType() == Enum.UserInputType.Touch then
		return "touch"
	elseif InputController.usingGamepad() then
		return "gamepad"
	end
	return "keyboard"
end

-- The Keeper camera looks toward -Z, so stick right = world +X and stick up = world -Z: the same angle rule as
-- aiming with the mouse (the beam points along -Z at angle 0). The right stick is the aim stick; the left one
-- also aims because walking is off at the lamp.
function InputController.stickAngle(x: number, y: number): number?
	if math.sqrt(x * x + y * y) < InputController.STICK_DEADZONE then
		return nil
	end
	return math.deg(math.atan2(-x, y))
end

return InputController
