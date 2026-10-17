--!strict
-- S2.6: controller aim. The stick gives the same beam angle as pointing the mouse in that direction.
return function(T: any)
	local InputController = T.require(game.StarterPlayer.StarterPlayerScripts.Client.InputController)

	local function near(a: number?, b: number): boolean
		return a ~= nil and math.abs(((a - b + 180) % 360) - 180) < 1e-6
	end

	T.describe("stickAngle", function()
		T.it("up aims at the sea in front (angle 0), right at +X (-90), left at -X (90), down behind (180)", function()
			T.expect(near(InputController.stickAngle(0, 1), 0)).toBe(true)
			T.expect(near(InputController.stickAngle(1, 0), -90)).toBe(true)
			T.expect(near(InputController.stickAngle(-1, 0), 90)).toBe(true)
			T.expect(near(InputController.stickAngle(0, -1), 180)).toBe(true)
		end)

		T.it("matches the mouse rule atan2(-dx, -dz) for the same world direction", function()
			-- stick (x, y) points at world (dx, dz) = (x, -y)
			for _, v in { { 0.6, 0.7 }, { -0.9, 0.2 }, { 0.3, -0.8 } } do
				local x, y = v[1], v[2]
				local mouse = math.deg(math.atan2(-x, y))
				T.expect(near(InputController.stickAngle(x, y), mouse)).toBe(true)
			end
		end)

		T.it("inside the dead zone the stick does not aim", function()
			T.expect(InputController.stickAngle(0, 0)).toBeNil()
			T.expect(InputController.stickAngle(0.2, 0.2)).toBeNil()
			T.expect(InputController.stickAngle(0.35, 0) ~= nil).toBe(true)
		end)

		T.it("mode is one of the three names", function()
			local m = InputController.mode()
			T.expect(m == "keyboard" or m == "touch" or m == "gamepad").toBe(true)
		end)
	end)
end
