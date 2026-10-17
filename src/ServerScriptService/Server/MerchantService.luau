--!strict
-- MerchantService (S6.2, Economy domain): the island Trader's day job. Sells the Definitions/Merchant stock for
-- the crew's Shells; everything lasts this voyage only and is wiped when a voyage starts or ends.
--   process(player, requestId, action, itemId, qty, env)  one MerchantRequest -> Result (nil = ignored)
--   boost(player, stat)   this voyage's boost on a stat: an AdditivePct layer, capped by Merchant.BOOST_CAP
--   count(player, itemId) how many the player bought this voyage
--   shielded()            true while the tower shield is up (until the next dawn)
--   endNight()            dawn: the shield drops
--   reset()               wipes every purchase and effect
-- The caller supplies `env` (phase, crew, distance) and `deps` (Shells, lamp, player effects) so the rules run
-- in tests without a voyage. A requestId is answered once; a repeat gets the first answer (capped replay map).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Merchant = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Definitions"):WaitForChild("Merchant")) :: any
local NetGuard = require(script.Parent.NetGuard)

local MerchantService = {}

MerchantService.RANGE = 18 -- studs from the Trader (docs/API_CONTRACTS.md)

export type Env = { phase: string?, ready: boolean, distance: number }
export type Deps = {
	getShells: () -> number,
	trySpend: (amount: number) -> boolean,
	fuel: () -> (number, number), -- current, max
	addFuel: (amount: number) -> (),
	health: (player: any) -> (number?, number?), -- current, max (nil without a living character)
	heal: (player: any) -> (),
	applyBoosts: (player: any) -> (),
	setShield: (on: boolean) -> (),
	purchased: (player: any, itemId: string, price: number) -> (),
}
export type Result = { ok: boolean, message: string, state: { itemId: string, count: number, shells: number } }

local deps: Deps? = nil
local bought: { [any]: { [string]: number } } = {}
local shield = false
local replay = NetGuard.replayMap()

function MerchantService.init(d: Deps)
	deps = d
end

function MerchantService.count(player: any, itemId: string): number
	local mine = bought[player]
	return if mine then mine[itemId] or 0 else 0
end

function MerchantService.boost(player: any, stat: string): number
	local total = 0
	local mine = bought[player]
	if mine then
		for itemId, n in mine do
			local def = Merchant[itemId]
			if def and def.effect == "boost" and def.stat == stat then
				total += (def.add or 0) * n
			end
		end
	end
	return math.min(total, Merchant.BOOST_CAP[stat] or 0)
end

function MerchantService.shielded(): boolean
	return shield
end

function MerchantService.endNight()
	if shield then
		shield = false
		if deps then
			deps.setShield(false)
		end
	end
end

-- Wipes every purchase; boosts are re-applied (back to normal) for everyone who had one
function MerchantService.reset()
	local had = {}
	for player in bought do
		table.insert(had, player)
	end
	table.clear(bought)
	shield = false
	if deps then
		deps.setShield(false)
		for _, player in had do
			deps.applyBoosts(player)
		end
	end
end

function MerchantService.forget(player: any)
	bought[player] = nil
	replay.forget(player)
end

local function decide(d: Deps, player: any, itemId: string, env: Env): Result
	local n = MerchantService.count(player, itemId)
	local function fail(message: string): Result
		return { ok = false, message = message, state = { itemId = itemId, count = n, shells = d.getShells() } }
	end
	local def = Merchant[itemId]
	if type(def) ~= "table" or not table.find(Merchant.ORDER, itemId) then
		return fail("The Trader doesn't sell that.")
	end
	if not env.ready then
		return fail("The Trader only sells to the crew during a voyage.")
	end
	if env.phase ~= "Day" then
		return fail("The Trader sells by day. Come back after dawn.")
	end
	if env.distance > MerchantService.RANGE then
		return fail("You're too far from the Trader.")
	end
	if def.limit and n >= def.limit then
		return fail(string.format("That's all the %s the Trader has for you this voyage.", def.displayName))
	end
	if def.effect == "heal" then
		local hp, max = d.health(player)
		if not hp or not max then
			return fail("You need to be on your feet to use that.")
		elseif hp >= max then
			return fail("You're already at full health.")
		end
	elseif def.effect == "oil" then
		local fuel, max = d.fuel()
		if fuel >= max - 0.5 then
			return fail("The lamp is already full.")
		end
	elseif def.effect == "shield" and shield then
		return fail("The tower is already shielded until dawn.")
	end
	if not d.trySpend(def.price) then
		return fail(string.format("Need %d Shells (the crew has %d).", def.price, d.getShells()))
	end
	local mine = bought[player]
	if not mine then
		mine = {}
		bought[player] = mine
	end
	mine[itemId] = n + 1
	if def.effect == "boost" or def.effect == "weapon" then
		d.applyBoosts(player) -- boosts and the Orbit weapon are server-set player attributes
	elseif def.effect == "heal" then
		d.heal(player)
	elseif def.effect == "oil" then
		d.addFuel(def.amount)
	elseif def.effect == "shield" then
		shield = true
		d.setShield(true)
	end
	d.purchased(player, itemId, def.price)
	return { ok = true, message = string.format("Bought %s.", def.displayName), state = { itemId = itemId, count = n + 1, shells = d.getShells() } }
end

-- One MerchantRequest. Malformed requests and requests over the rate are ignored (nil).
function MerchantService.process(player: any, requestId: any, action: any, itemId: any, qty: any, env: Env): Result?
	local d = deps
	if not d or not NetGuard.isRequestId(requestId) or action ~= "buy" or type(itemId) ~= "string" or #itemId > 40 or qty ~= 1 then
		return nil
	end
	local seen = replay.get(player, requestId)
	if seen then
		return seen[1] :: any
	end
	if not NetGuard.allow(player, "MerchantRequest") then
		return nil
	end
	-- a failing effect must not let the same requestId buy twice: the answer is remembered either way
	local ok, result = pcall(decide, d, player, itemId, env)
	if not ok then
		warn("MerchantService: " .. tostring(result))
		result = { ok = false, message = "The Trader fumbled that. Check the sheet before trying again.", state = { itemId = itemId, count = MerchantService.count(player, itemId), shells = d.getShells() } }
	end
	replay.put(player, requestId, { result })
	return result
end

return MerchantService
