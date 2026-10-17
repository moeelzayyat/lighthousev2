# EVENTS — event bus catalog

Module: `EventLog` (Telemetry domain) exposes `Publish(name, payload)` / `Subscribe(name, handler)`. Publisher = authoritative domain only. Objectives, Logbook, Leaderboards, Results and Analytics only consume. Handlers in `pcall`; a consumer error is reported, never propagated. Payloads carry IDs and numbers, never Instances. `VoyageId` on every in-voyage event.

**R1.6 status:** the bus is `EventBus` (owned by `EventLog`, exposed as `EventLog.Publish/Subscribe`); the machine-readable catalog is `ReplicatedStorage/Shared/Events` and a publish that does not match it is rejected. Rows marked `R1.6 ✅` are published today: the funnel events come from `EventLog.mark/playerJoined/playerLeft/startRun` (called by the owning domain until the S5 domain split), voyage events from `GameState`, Pearl events from `PlayerData`. `PearlsGranted` has an extra `Balance` field; Since R1.3 `PearlsGranted` is published by `GrantService` with the `ClaimId`. Rows marked `S5.3` are catalogued but get their publisher when callback wiring moves to the bus. `VoyageEnded.Outcome` also takes `Abandoned` and `Error` (R1.5).

**S5.3 status:** every `S5.3` row now has its publisher (marked `S5.3 ✅`), and the callbacks that wired one service to another are gone: `CreatureService.onKilled` → `CreatureKilled` (Loot drops), `PlayerData.onChanged` → `ProfileChanged` (Economy gear sync), `ShipRoster.onChange` → `CrewRosterChanged` (ShipDeparture), the dawn auto-sell callback → `DawnLootWindow` (Economy), `LampService.colorFor` → the player's `BeamColor` attribute (kept current by Economy), `DefenseService.setOilHandlers/setCrateHandlers` → the shared `OilCarry` module and the Data domain's `PlayerData.count/removeItem`. The bus starts each handler with `task.spawn`, which runs it at once, so a handler that does not yield has finished when `Publish` returns (`BusEventsSpec`). Payload field names are exactly the catalog's (`ReplicatedStorage/Shared/Events`); `VoyageId` is `EventLog.voyageId()` (`"none"` before the first voyage).

| Event | Payload | Publisher | Consumers | Since |
|---|---|---|---|---|
| `BootCompleted` | `{Domains}` (the boot order) | Main, after `Bootstrap.run` | Analytics (later) | S5.3 ✅ |
| `PlayerJoined` | `{UserId}` | Crew (EventLog.playerJoined) | Analytics (`Joined`) | R1.6 ✅ |
| `ProfileChanged` | `{UserId}` | Data (PlayerData, on every profile change pushed to the client) | Economy (tools, armor, `BeamColor`) | S5.3 ✅ |
| `CrewRosterChanged` | `{ShipId}` | Crew (ShipRoster) | Crew (ShipDeparture re-checks the countdown) | S5.3 ✅ |
| `ProfileLoaded` | `{UserId, SchemaVersion, IsNew, Runs}` | Data (PlayerData) | AdminDataService (daily snapshot), later Route, Coach, Analytics | R1.3 ✅ |
| `PlayerJoinedCrew` | `{UserId, Route: "fast"\|"deck"}` | Crew | Analytics (`OnCrew`) | R1.6 ✅ |
| `VoyageStarted` | `{VoyageId, Definition, Crew: {UserId}, Forecast}` | Encounter | Analytics, Results | R1.6 ✅ |
| `PlayerLanded` | `{VoyageId, UserId}` | Encounter | Analytics (`Landed`), Coach | R1.6 ✅ |
| `FirstAction` | `{VoyageId, UserId, Kind: "oil"\|"attack"}` | Encounter | Analytics | R1.6 ✅ |
| `BeamHit` | `{VoyageId, KeeperId, CreatureId, Mode, First: boolean}` | Encounter (Lamp) | Analytics (`FirstBeamHit` when First), Objectives | R1.6 ✅ |
| `Refuelled` | `{VoyageId, UserId, Amount, FuelBefore, Night: boolean}` | Encounter (fuel tank prompt) | Feed, Results (clutch when FuelBefore < 10% at night), Objectives | S5.3 ✅ |
| `ReserveUsed` | `{VoyageId, Reason: "prologue"\|"night1safety"}` | Encounter (GameState, Night-1 safety) | Coach, Analytics | S5.3 ✅ |
| `LampDark` / `LampLit` | `{VoyageId}` / `{VoyageId, Seconds?}` (how long it was dark) | Encounter (Lamp) | HUD, Analytics | S5.3 ✅ |
| `TowerRepaired` | `{VoyageId, UserId, Amount, IntegrityBefore}` | Encounter (Tower) | Feed, Results, Objectives | S5.3 ✅ |
| `CannonBuilt` / `CannonReloaded` / `CannonDestroyed` | `{VoyageId, UserId?, Pad, Level}` (no `UserId` on Destroyed) | Encounter (Defense) | Feed, Objectives, Analytics | S5.3 ✅ |
| `CreatureSpawned` | `{VoyageId, CreatureId, DefId, Big: boolean}` | Encounter (CreatureService) | Analytics (sampled) | S5.3 ✅ |
| `CreatureKilled` | `{VoyageId, CreatureId, DefId, Source, KillerId?, X, Y, Z, Big: boolean}` (`Source` is the damage tag as recorded: `WideBeam`, `FocusedBeam`, `Cannon`, `Weapon:<id>`; X/Y/Z where it fell) | Encounter (CreatureService) | **Loot (drops, S5.3 ✅)**, Results, Logbook, Objectives, Analytics | S5.3 ✅ |
| `BossWarning` / `BossDefeated` | `{VoyageId, DefId, Night}` / `{VoyageId, DefId, FinalBlow?}` | Encounter (GameState / CreatureService) | HUD, Results, Logbook | S5.3 ✅ |
| `LootCollected` | `{VoyageId, UserId, ItemId, Qty}` | Encounter (Loot) | Objectives, Analytics | S5.3 ✅ |
| `ShellsChanged` | `{VoyageId, Delta, Reason}` (`loot`, `tide`, `waveBonus`, `trader`, `upgrade`, `merchant`) | Encounter (UpgradeService holds the crew pool today) | Analytics | S5.3 ✅ |
| `UpgradeBought` / `EvolutionUnlocked` | `{VoyageId, UserId, Id, Rank}` / `{VoyageId, Id}` | Encounter (bench / UpgradeService) | Results, Logbook, Objectives | S5.3 ✅ |
| `NightSurvived` | `{VoyageId, Night, Crew}` | Encounter | **Grant (dawn Pearl, `DawnBanking`, S2.2 ✅)**, Analytics (`Night1Survived`), Leaderboard | R1.6 ✅ |
| `DawnLootWindow` | `{VoyageId, Seconds}` | Encounter (GameState) | **Economy (auto-sell, launch R10 switch, S5.3 ✅)**, HUD | S5.3 ✅ |
| `VoyageEnded` | `{VoyageId, Outcome: "Victory"\|"Defeat", Cause, NightReached, Crew, PerPlayer, Voyage?}` (S3.1b: `Voyage` = the definition sailed) | Encounter | Results, Grant (victory bonus), Leaderboard, Objectives, Analytics | R1.6 ✅ |
| `RematchVoted` / `SailAgain` | `{VoyageId, UserId}` | Crew | Analytics | R1.6 ✅ |
| `ModeAssigned` | `{UserId, Arm}` | Data (PlayerData, from `ModeTest`) | Analytics (custom `ModeArm`) | S3.1b ✅ |
| `PearlsGranted` | `{UserId, ClaimId, Amount, Balance, Source}` | Economy (GrantService) | Analytics (economy source; Source `"dawn"` → funnel `DawnPearl` once per player, S2.2) | R1.6 ✅ |
| `PearlsSpent` | `{UserId, Amount, Balance, ItemId?}` | Data (PlayerData.spendPearls) | Analytics (economy sink) | R1.6 ✅ |
| `ItemGranted` | `{UserId, ItemId, Source}` | Economy (Grant) | Logbook, Analytics | R1.3 |
| `ShopPurchase` | `{UserId, ItemId, Price, Currency}` | Economy (ShopService) | Analytics | S5.3 ✅ |
| `MerchantPurchase` | `{VoyageId?, UserId, ItemId, Price, Currency}` | Economy (MerchantService via `Domains/Economy`) | Analytics | S6.2 ✅ (with `ShellsChanged` reason `merchant`) |
| `ObjectiveCompleted` | `{UserId, ObjectiveId}` | LiveOps (ObjectiveService) | Analytics | S7.2 ✅ |
| `LogbookDiscovered` | `{UserId, EntryId}` | LiveOps (LogbookService) | Analytics | S7.1 ✅ |
| `InviteCompleted` | `{InviterId, InviteeId}` | Crew | Grant | S7.5 |
| `PurchaseGranted` | `{UserId, ProductId, ReceiptId}` | LiveOps | Analytics | L1.3 |
| `PlayerLeft` | `{UserId, Phase, Night?}` | Crew | Analytics (`Left`) | R1.6 ✅ |

## Funnel names (Roblox AnalyticsService; fixed for dashboard continuity)
`Joined` · `OnCrew` · `Landed` · `FirstAction` · `FirstBeamHit` · `Night1Survived` · `DawnPearl` · `VoyageEnded` · `SailAgain` · `Left`
