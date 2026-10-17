--!strict
-- Events (R1.6): the typed catalog of event-bus events (docs/EVENTS.md). The bus rejects any publish whose
-- name is not here or whose payload does not match: field -> type, where "?" marks an optional field.
-- Payloads carry ids and numbers, never Instances. Add a row here and in EVENTS.md before publishing.

export type Schema = { [string]: string }

local Events: { [string]: Schema } = {
	-- Crew / platform
	PlayerJoined = { UserId = "number" },
	PlayerJoinedCrew = { UserId = "number", Route = "string?" },
	PlayerLeft = { UserId = "number", Phase = "string", Night = "number?" },
	SailAgain = { VoyageId = "string", UserId = "number" },
	ModeAssigned = { UserId = "number", Arm = "string" }, -- S3.1b: the account's arm in the mode test
	BootCompleted = { Domains = "table" }, -- S5.3: Main, after Bootstrap.run
	CrewRosterChanged = { ShipId = "string" }, -- S5.3: ShipRoster -> ShipDeparture (was ShipRoster.onChange)

	-- Encounter (voyage)
	VoyageStarted = { VoyageId = "string", Crew = "table", Forecast = "string?" },
	PlayerLanded = { VoyageId = "string", UserId = "number" },
	FirstAction = { VoyageId = "string?", UserId = "number", Kind = "string" },
	BeamHit = { VoyageId = "string?", KeeperId = "number", First = "boolean", CreatureId = "number?", Mode = "string?" },
	NightSurvived = { VoyageId = "string", Night = "number", Crew = "table" },
	VoyageEnded = { VoyageId = "string", Outcome = "string", Cause = "string", NightReached = "number", Crew = "table", Voyage = "string?" },
	-- S5.3: voyage events that had no publisher, and the kill that loot used to hear through a callback
	Refuelled = { VoyageId = "string", UserId = "number", Amount = "number", FuelBefore = "number", Night = "boolean" },
	ReserveUsed = { VoyageId = "string", Reason = "string" },
	LampDark = { VoyageId = "string" },
	LampLit = { VoyageId = "string", Seconds = "number?" },
	TowerRepaired = { VoyageId = "string", UserId = "number", Amount = "number", IntegrityBefore = "number" },
	CannonBuilt = { VoyageId = "string", UserId = "number?", Pad = "number", Level = "number" },
	CannonReloaded = { VoyageId = "string", UserId = "number?", Pad = "number", Level = "number" },
	CannonDestroyed = { VoyageId = "string", Pad = "number", Level = "number" },
	CreatureSpawned = { VoyageId = "string", CreatureId = "number", DefId = "string", Big = "boolean" },
	CreatureKilled = { VoyageId = "string", CreatureId = "number", DefId = "string", Source = "string", KillerId = "number?", X = "number", Y = "number", Z = "number", Big = "boolean" },
	BossWarning = { VoyageId = "string", DefId = "string", Night = "number" },
	BossDefeated = { VoyageId = "string", DefId = "string", FinalBlow = "number?" },
	LootCollected = { VoyageId = "string", UserId = "number", ItemId = "string", Qty = "number" },
	ShellsChanged = { VoyageId = "string", Delta = "number", Reason = "string" },
	UpgradeBought = { VoyageId = "string", UserId = "number", Id = "string", Rank = "number" },
	EvolutionUnlocked = { VoyageId = "string", Id = "string" },
	DawnLootWindow = { VoyageId = "string", Seconds = "number" },

	-- Data
	ProfileLoaded = { UserId = "number", SchemaVersion = "number", IsNew = "boolean", Runs = "number" },
	ProfileChanged = { UserId = "number" }, -- S5.3: PlayerData -> Economy gear sync (was PlayerData.onChanged)

	-- Economy (Pearls are per player and saved)
	PearlsGranted = { UserId = "number", Amount = "number", Balance = "number", Source = "string", ClaimId = "string?" },
	PearlsSpent = { UserId = "number", Amount = "number", Balance = "number", ItemId = "string?" },
	ShopPurchase = { UserId = "number", ItemId = "string", Price = "number", Currency = "string" },
}

return Events
