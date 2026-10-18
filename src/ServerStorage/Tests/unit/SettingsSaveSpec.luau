--!strict
-- SET.2: Settings are saved between visits in the save's existing Settings fields. What a client sends is cleaned
-- (volumes 0..1 in steps of 0.1, low effects a boolean); anything malformed is refused.
return function(T: any)
	local PlayerData = T.require(game.ServerScriptService.Server.PlayerData)

	T.describe("saved settings", function()
		T.it("round and clamp the volumes", function()
			local a, b, c = PlayerData.cleanSettings(0.43, 1.7, true)
			T.expect(a).toBeCloseTo(0.4)
			T.expect(b).toBeCloseTo(1)
			T.expect(c).toBe(true)
			local d, e = PlayerData.cleanSettings(-3, 0.06, false)
			T.expect(d).toBeCloseTo(0)
			T.expect(e).toBeCloseTo(0.1)
		end)

		T.it("refuse anything malformed", function()
			T.expect((PlayerData.cleanSettings("loud", 1, true))).toBe(nil)
			T.expect((PlayerData.cleanSettings(1, 0 / 0, true))).toBe(nil)
			T.expect((PlayerData.cleanSettings(1, 1, "yes"))).toBe(nil)
		end)
	end)
end
