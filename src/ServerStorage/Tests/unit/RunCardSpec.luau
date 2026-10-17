--!strict
-- S2.5: the share line on the Results screen.
return function(T: any)
	local RunCard = T.require(game.ReplicatedStorage.Shared.RunCard)

	T.describe("RunCard.text", function()
		T.it("a win names the voyage, nights, time and crew", function()
			local text = RunCard.text({ result = "Victory", nightReached = 7, totalNights = 7, voyage = "Standard", duration = 935, crewSize = 2, crew = { {} } })
			T.expect(text).toBe("Lighthouse Keepers \u{00B7} The light held: 7 of 7 nights \u{00B7} Standard Voyage \u{00B7} 15:35 \u{00B7} crew of 2")
		end)

		T.it("a loss names the night it was lost on; a crew of one is solo", function()
			local text = RunCard.text({ result = "Defeat", nightReached = 2, totalNights = 13, voyage = "Long", duration = 283, crew = { {} } })
			T.expect(text).toBe("Lighthouse Keepers \u{00B7} Lost on night 2 of 13 \u{00B7} Long Voyage \u{00B7} 4:43 \u{00B7} solo")
		end)

		T.it("missing fields still give a readable line", function()
			T.expect(RunCard.text({})).toBe("Lighthouse Keepers \u{00B7} Lost on night 1 of 0 \u{00B7} 0:00")
			T.expect(RunCard.text({ result = "Victory", totalNights = 7, voyage = "Nope", duration = 61 })).toBe("Lighthouse Keepers \u{00B7} The light held: 7 of 7 nights \u{00B7} 1:01")
		end)
	end)
end
