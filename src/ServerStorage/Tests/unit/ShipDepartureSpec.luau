--!strict
-- R1.7: departure rules for the one-crew server (architecture §12): 4/4 sails automatically, SAIL NOW for a
-- crew of 1-3, a full crew dropping below 4 cancels. Uses a fake roster; no Instances, no Players.
return function(T: any)
	local function setup()
		local ShipDeparture = T.require(game.ServerScriptService.Server.ShipDeparture)
		local crew: { any } = {}
		local attributes: { [string]: any } = {}
		local roster = {
			CAPACITY = 4,
			members = function(_shipId: string)
				return crew
			end,
			isLocked = function(_shipId: string)
				return false
			end,
			shipOf = function(player: any)
				return if table.find(crew, player) then "Ship1" else nil
			end,
		}
		ShipDeparture.init({
			roster = roster,
			state = {
				SetAttribute = function(_self: any, k: string, v: any)
					attributes[k] = v
				end,
			},
			shipIds = { "Ship1" },
			notify = function() end,
			log = function() end,
			manual = true, -- no background loop in tests
		})
		local function player(name: string)
			return { Name = name, DisplayName = name, Parent = true }
		end
		return ShipDeparture, crew, attributes, player
	end

	T.describe("ShipDeparture (one crew per server)", function()
		T.it("a full crew of 4 sails automatically", function()
			local D, crew, attributes, player = setup()
			for i = 1, 3 do
				table.insert(crew, player("p" .. i))
			end
			T.expect(D.requested("Ship1")).toBe(false)
			table.insert(crew, player("p4"))
			T.expect(D.requested("Ship1")).toBe(true)
			T.expect(attributes.Ship_Ship1_Departure).toBe("auto")
		end)

		T.it("SAIL NOW works for a crew of 2 and only for a crew member", function()
			local D, crew, attributes, player = setup()
			local a, b, outsider = player("a"), player("b"), player("x")
			table.insert(crew, a)
			table.insert(crew, b)
			local ok, why = D.sailNow(outsider, "Ship1")
			T.expect(ok).toBe(false)
			T.expect(why).toBe("not crew")
			ok, why = D.sailNow(a, "Ship1")
			T.expect(ok).toBe(true)
			T.expect(D.requested("Ship1")).toBe(true)
			T.expect(attributes.Ship_Ship1_Departure).toBe("manual")
			ok, why = D.sailNow(b, "Ship1")
			T.expect(why).toBe("already")
		end)

		T.it("SAIL NOW is refused for a full crew (it sails by itself)", function()
			local D, crew, _, player = setup()
			for i = 1, 4 do
				table.insert(crew, player("p" .. i))
			end
			local ok, why = D.sailNow(crew[1], "Ship1")
			T.expect(ok).toBe(false)
			T.expect(why).toBe("full")
		end)

		T.it("an automatic departure is cancelled when the crew drops below 4", function()
			local D, crew, _, player = setup()
			for i = 1, 4 do
				table.insert(crew, player("p" .. i))
			end
			T.expect(D.requested("Ship1")).toBe(true)
			table.remove(crew)
			T.expect(D.requested("Ship1")).toBe(false)
		end)

		T.it("SAIL NOW is cancelled when its caller leaves the crew", function()
			local D, crew, _, player = setup()
			local a, b = player("a"), player("b")
			table.insert(crew, a)
			table.insert(crew, b)
			D.sailNow(a, "Ship1")
			table.remove(crew, 1)
			T.expect(D.requested("Ship1")).toBe(false)
		end)
	end)
end
