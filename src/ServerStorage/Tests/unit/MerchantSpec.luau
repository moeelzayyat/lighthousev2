--!strict
-- S6.2: the island merchant sells Definitions/Merchant stock for crew Shells, by day, to the crew, near the
-- Trader; boosts are capped; a repeated requestId is answered once; everything is wiped at Results.
return function(T: any)
	local MerchantService = T.require(game.ServerScriptService.Server.MerchantService)
	local Merchant = T.require(game.ReplicatedStorage.Shared.Definitions.Merchant)
	local Registry = T.require(game.ReplicatedStorage.Shared._Registry)
	local StatPipeline = T.require(game.ReplicatedStorage.Shared.StatPipeline)
	local Weapons = T.require(game.ReplicatedStorage.Shared.Weapons)

	local function source(inst: Instance): string
		return (inst :: any).Source
	end

	-- a fake voyage: crew Shells, the lamp, one player's health; records what happened
	local function setup(shells: number)
		MerchantService.reset() -- the previous test's purchases go back through the previous fake
		local w = { shells = shells, fuel = 50, maxFuel = 100, hp = 60, maxHp = 100, shield = false, applied = 0, bought = {} :: { string } }
		MerchantService.init({
			getShells = function()
				return w.shells
			end,
			trySpend = function(amount: number)
				if w.shells < amount then
					return false
				end
				w.shells -= amount
				return true
			end,
			fuel = function()
				return w.fuel, w.maxFuel
			end,
			addFuel = function(amount: number)
				w.fuel = math.min(w.maxFuel, w.fuel + amount)
			end,
			health = function(_player: any)
				return w.hp, w.maxHp
			end,
			heal = function(_player: any)
				w.hp = w.maxHp
			end,
			applyBoosts = function(_player: any)
				w.applied += 1
			end,
			setShield = function(on: boolean)
				w.shield = on
			end,
			purchased = function(_player: any, itemId: string, _price: number)
				table.insert(w.bought, itemId)
			end,
		})
		return w
	end
	local DAY = { phase = "Day", ready = true, distance = 5 }
	local n = 0
	local function rid(): string
		n += 1
		return "req" .. n
	end
	local function buy(player: any, itemId: string, env: any?)
		return MerchantService.process(player, rid(), "buy", itemId, 1, env or DAY)
	end

	T.describe("the stock", function()
		T.it("passes the boot registry, and a boost over its cap is refused", function()
			local all = Registry.catalogs()
			local problems = {}
			for _, p in Registry.check(all) do
				if string.sub(p, 1, 9) == "Merchant." then
					table.insert(problems, p)
				end
			end
			T.expect(problems).toEqual({})
			local bad = table.clone(all)
			bad.Merchant = table.clone(Merchant)
			bad.Merchant.DamageBoost = table.clone(Merchant.DamageBoost)
			bad.Merchant.DamageBoost.limit = 3
			T.expect(table.concat(Registry.check(bad), "\n")).toContain("Merchant.DamageBoost: limit × add is over Merchant.BOOST_CAP.WeaponDamage")
		end)
	end)

	T.describe("selling", function()
		T.it("sells by day, to the crew, near the Trader only", function()
			local w = setup(500)
			local p = {}
			T.expect(buy(p, "Heal", { phase = "Night", ready = true, distance = 5 }).message).toBe("The Trader sells by day. Come back after dawn.")
			T.expect(buy(p, "Heal", { phase = "Day", ready = false, distance = 5 }).message).toBe("The Trader only sells to the crew during a voyage.")
			T.expect(buy(p, "Heal", { phase = "Day", ready = true, distance = 30 }).message).toBe("You're too far from the Trader.")
			T.expect(buy(p, "Nope").message).toBe("The Trader doesn't sell that.")
			T.expect(w.shells).toBe(500)
			T.expect(buy(p, "Heal").ok).toBe(true)
			T.expect(w.shells).toBe(500 - Merchant.Heal.price)
			T.expect(w.hp).toBe(100)
		end)

		T.it("spends the crew's Shells and refuses when there are not enough", function()
			local w = setup(45)
			local r = buy({}, "DamageBoost")
			T.expect(r.ok).toBe(false)
			T.expect(r.message).toBe("Need 50 Shells (the crew has 45).")
			T.expect(w.shells).toBe(45)
			T.expect(buy({}, "OilBundle").ok).toBe(true)
			T.expect(w.shells).toBe(15)
			T.expect(w.fuel).toBe(90)
		end)

		T.it("ignores malformed requests", function()
			setup(500)
			T.expect(MerchantService.process({}, "", "buy", "Heal", 1, DAY)).toBe(nil)
			T.expect(MerchantService.process({}, rid(), "steal", "Heal", 1, DAY)).toBe(nil)
			T.expect(MerchantService.process({}, rid(), "buy", 5, 1, DAY)).toBe(nil)
			T.expect(MerchantService.process({}, rid(), "buy", "Heal", 99, DAY)).toBe(nil)
		end)

		T.it("answers a repeated requestId once: the second copy spends nothing", function()
			local w = setup(500)
			local p = {}
			local first = MerchantService.process(p, "same-id", "buy", "DamageBoost", 1, DAY)
			local again = MerchantService.process(p, "same-id", "buy", "DamageBoost", 1, DAY)
			T.expect(first.ok).toBe(true)
			T.expect(again).toBe(first)
			T.expect(w.shells).toBe(450)
			T.expect(MerchantService.count(p, "DamageBoost")).toBe(1)
		end)

		T.it("a failing effect still answers the requestId once (no second purchase)", function()
			local w = setup(500)
			local p = {}
			MerchantService.init({
				getShells = function()
					return w.shells
				end,
				trySpend = function(amount: number)
					w.shells -= amount
					return true
				end,
				fuel = function()
					return 0, 100
				end,
				addFuel = function() end,
				health = function()
					return 50, 100
				end,
				heal = function() end,
				applyBoosts = function() end,
				setShield = function() end,
				purchased = function()
					error("telemetry broke")
				end,
			})
			local first = MerchantService.process(p, "boom-id", "buy", "SpeedBoost", 1, DAY)
			local again = MerchantService.process(p, "boom-id", "buy", "SpeedBoost", 1, DAY)
			T.expect(first.ok).toBe(false)
			T.expect(again).toBe(first)
			T.expect(w.shells).toBe(460)
			T.expect(MerchantService.count(p, "SpeedBoost")).toBe(1)
		end)
	end)

	T.describe("effects", function()
		T.it("boosts stack to their cap and stop at the limit", function()
			local w = setup(1000)
			local p = {}
			T.expect(buy(p, "DamageBoost").ok).toBe(true)
			T.expect(MerchantService.boost(p, "WeaponDamage")).toBeCloseTo(0.1)
			T.expect(buy(p, "DamageBoost").ok).toBe(true)
			T.expect(MerchantService.boost(p, "WeaponDamage")).toBeCloseTo(0.2)
			local third = buy(p, "DamageBoost")
			T.expect(third.ok).toBe(false)
			T.expect(third.message).toBe("That's all the Whetstone the Trader has for you this voyage.")
			T.expect(MerchantService.boost(p, "PlayerSpeed")).toBe(0)
			T.expect(MerchantService.boost({}, "WeaponDamage")).toBe(0)
			T.expect(w.applied).toBe(2)
			-- the boost reaches the hit through the stat pipeline
			for id, weapon in Weapons do
				local boosted = StatPipeline.weapon(id, { damage = { add = { MerchantService.boost(p, "WeaponDamage") } } })
				T.expect(boosted.damage).toBeCloseTo(math.min(200, weapon.damage * 1.2))
			end
			T.expect(StatPipeline.compute("PlayerSpeed", 16, { add = { 0.2 } })).toBeCloseTo(19.2)
		end)

		T.it("heal, oil and shield refuse when they would do nothing", function()
			local w = setup(1000)
			local p = {}
			w.hp = 100
			T.expect(buy(p, "Heal").message).toBe("You're already at full health.")
			w.fuel = 100
			T.expect(buy(p, "OilBundle").message).toBe("The lamp is already full.")
			T.expect(buy(p, "TowerShield").ok).toBe(true)
			T.expect(w.shield).toBe(true)
			T.expect(buy({}, "TowerShield").message).toBe("The tower is already shielded until dawn.")
			T.expect(w.shells).toBe(1000 - Merchant.TowerShield.price)
			MerchantService.endNight()
			T.expect(w.shield).toBe(false)
			T.expect(MerchantService.shielded()).toBe(false)
		end)

		T.it("everything is wiped at Results", function()
			local w = setup(1000)
			local p = {}
			buy(p, "SpeedBoost")
			buy(p, "TowerShield")
			T.expect(MerchantService.boost(p, "PlayerSpeed")).toBeCloseTo(0.1)
			MerchantService.reset()
			T.expect(MerchantService.boost(p, "PlayerSpeed")).toBe(0)
			T.expect(MerchantService.count(p, "SpeedBoost")).toBe(0)
			T.expect(w.shield).toBe(false)
			T.expect(w.applied).toBe(2) -- once at purchase, once to restore normal speed
		end)
	end)

	T.describe("wiring", function()
		T.it("the voyage reads the boosts and the shield, and the remote has a contract", function()
			local Server = game.ServerScriptService.Server
			local economy = source(Server.Domains.Economy)
			T.expect(economy).toContain("EventLog.Subscribe(\"VoyageEnded\", function()\n\t\tMerchantService.reset()")
			T.expect(economy).toContain("EventLog.Subscribe(\"NightSurvived\", function()\n\t\tMerchantService.endNight()")
			T.expect(economy).toContain("remotes.MerchantRequest.OnServerEvent")
			T.expect(source(Server.Domains.Encounter)).toContain("player:GetAttribute(\"Boost_WeaponDamage\")")
			T.expect(source(Server.LampService)).toContain("keeper:GetAttribute(\"Boost_PlayerSpeed\")")
			T.expect(source(Server.TowerService)).toContain("amount *= Merchant.TowerShield.mult")
			T.expect(source(Server.Domains.Platform)).toContain("\"MerchantRequest\", \"MerchantResult\"")
			local NetGuard = T.require(Server.NetGuard)
			T.expect(NetGuard.RATES.MerchantRequest).toEqual({ 5, 8 })
		end)
	end)
end
