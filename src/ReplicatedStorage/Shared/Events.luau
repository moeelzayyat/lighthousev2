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

	-- Encounter (voyage)
	VoyageStarted = { VoyageId = "string", Crew = "table", Forecast = "string?" },
	PlayerLanded = { VoyageId = "string", UserId = "number" },
	FirstAction = { VoyageId = "string?", UserId = "number", Kind = "string" },
	BeamHit = { VoyageId = "string?", KeeperId = "number", First = "boolean", CreatureId = "number?", Mode = "string?" },
	NightSurvived = { VoyageId = "string", Night = "number", Crew = "table" },
	VoyageEnded = { VoyageId = "string", Outcome = "string", Cause = "string", NightReached = "number", Crew = "table" },

	-- Data
	ProfileLoaded = { UserId = "number", SchemaVersion = "number", IsNew = "boolean", Runs = "number" },

	-- Economy (Pearls are per player and saved)
	PearlsGranted = { UserId = "number", Amount = "number", Balance = "number", Source = "string", ClaimId = "string?" },
	PearlsSpent = { UserId = "number", Amount = "number", Balance = "number", ItemId = "string?" },
}

return Events
