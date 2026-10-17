--!strict
-- Definitions/Merchant (S6.2, owner request #4): the island Trader's day-phase stock. Everything is bought with
-- the crew's Shells, lasts only this voyage and is wiped at Results. MerchantService sells it; _Registry checks
-- it at boot. Prices: D-019 (unattended recommendation, to be tuned after the public test).
--   price       crew Shells
--   scope       "player" helps the buyer; "crew" helps everyone
--   effect      "boost" (a StatPipeline AdditivePct layer on `stat` for the rest of the voyage), "heal" (the
--               buyer to full health), "shield" (the tower takes `mult` damage until the next dawn),
--               "oil" (`amount` fuel straight into the lamp)
--   limit       most one player may buy in a voyage (nil = no limit; the effect itself refuses when useless)

export type MerchantDef = {
	id: string,
	displayName: string,
	description: string,
	price: number,
	scope: string,
	effect: string,
	stat: string?,
	add: number?,
	mult: number?,
	amount: number?,
	limit: number?,
}

local Merchant = {
	ORDER = { "DamageBoost", "SpeedBoost", "Heal", "OilBundle", "TowerShield" },
	-- the most a voyage's boosts may add to a stat (two purchases of +10%)
	BOOST_CAP = { WeaponDamage = 0.2, PlayerSpeed = 0.2 } :: { [string]: number },

	DamageBoost = {
		id = "DamageBoost",
		displayName = "Whetstone",
		description = "+10% weapon damage for the rest of this voyage",
		price = 50,
		scope = "player",
		effect = "boost",
		stat = "WeaponDamage",
		add = 0.1,
		limit = 2,
	} :: MerchantDef,
	SpeedBoost = {
		id = "SpeedBoost",
		displayName = "Sea Legs Tonic",
		description = "+10% walk speed for the rest of this voyage",
		price = 40,
		scope = "player",
		effect = "boost",
		stat = "PlayerSpeed",
		add = 0.1,
		limit = 2,
	} :: MerchantDef,
	Heal = {
		id = "Heal",
		displayName = "Kelp Poultice",
		description = "Heals you to full health",
		price = 15,
		scope = "player",
		effect = "heal",
	} :: MerchantDef,
	OilBundle = {
		id = "OilBundle",
		displayName = "Oil Bundle",
		description = "+40 fuel straight into the lamp",
		price = 30,
		scope = "crew",
		effect = "oil",
		amount = 40,
	} :: MerchantDef,
	TowerShield = {
		id = "TowerShield",
		displayName = "Tower Shield",
		description = "The tower takes half damage until dawn",
		price = 60,
		scope = "crew",
		effect = "shield",
		mult = 0.5,
	} :: MerchantDef,
}

return Merchant
