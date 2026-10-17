--!strict
-- LO.2/LO.3: the Shipwreck Rescue count and its rewards. One castaway at a time per carrier (not with oil), a
-- carrier who falls drops theirs back at the wreck, 1 Pearl per 2 saved, and the Rescuer's Flag only when every
-- castaway was saved.
return function(T: any)
	local RescueService = T.require(game.ServerScriptService.Server.RescueService)
	local Voyages = T.require(game.ReplicatedStorage.Shared.Definitions.Voyages)
	local Items = T.require(game.ReplicatedStorage.Shared.Items)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)

	T.describe("carrying", function()
		T.it("one castaway per carrier, never with oil; delivered ones are saved", function()
			local r = RescueService.new(3)
			T.expect(RescueService.pickUp(r, 1, false)).toBe(nil)
			T.expect(RescueService.pickUp(r, 1, false)).toContain("already carrying")
			T.expect(RescueService.pickUp(r, 2, true)).toContain("oil")
			T.expect(r.left).toBe(2)
			T.expect(RescueService.deliver(r, 2)).toBe(false) -- not carrying
			T.expect(RescueService.deliver(r, 1)).toBe(true)
			T.expect(RescueService.deliver(r, 1)).toBe(false) -- once
			T.expect(r.saved).toBe(1)
		end)

		T.it("a carrier who falls drops the castaway back at the wreck; nothing runs out", function()
			local r = RescueService.new(2)
			RescueService.pickUp(r, 1, false)
			RescueService.pickUp(r, 2, false)
			T.expect(RescueService.pickUp(r, 3, false)).toContain("Everyone has left")
			T.expect(RescueService.drop(r, 1)).toBe(true)
			T.expect(RescueService.drop(r, 1)).toBe(false)
			T.expect(r.left).toBe(1)
			T.expect(RescueService.pickUp(r, 3, false)).toBe(nil)
		end)
	end)

	T.describe("rewards", function()
		T.it("1 Pearl per 2 saved, the flag only when all are saved", function()
			local def = Voyages.Rescue.rescue
			local r = RescueService.new(def.castaways)
			T.expect(RescueService.reward(r, def)).toEqual({})
			for i = 1, 5 do
				RescueService.pickUp(r, i, false)
				RescueService.deliver(r, i)
			end
			T.expect(RescueService.reward(r, def)).toEqual({ Pearls = 2 })
			for i = 6, def.castaways do
				RescueService.pickUp(r, i, false)
				RescueService.deliver(r, i)
			end
			T.expect(RescueService.reward(r, def)).toEqual({ Pearls = def.castaways // 2, Items = { FlagRescuer = 1 } })
			T.expect(def.castaways // 2 <= 6).toBe(true) -- a bounded Pearl source
		end)

		T.it("the Rescuer's Flag is a cosmetic earned in the event, never sold; the voyage passes the registry", function()
			local flag = Items.FlagRescuer
			T.expect(flag.kind).toBe("Cosmetic")
			T.expect(flag.reward).toBe("event")
			T.expect(flag.price).toBe(nil)
			local problems = {}
			for _, p in Registry.check(Registry.catalogs()) do
				if string.sub(p, 1, 8) == "Voyages." or string.sub(p, 1, 6) == "Items." then
					table.insert(problems, p)
				end
			end
			T.expect(problems).toEqual({})
		end)
	end)

	T.describe("wiring", function()
		T.it("the Encounter domain starts it; oil cannot be grabbed while carrying a castaway", function()
			local encounter = (game.ServerScriptService.Server.Domains.Encounter :: any).Source :: string
			T.expect(encounter).toContain("RescueService.start({")
			T.expect(encounter).toContain("player:GetAttribute(\"CarryingCastaway\")")
		end)
	end)
end
