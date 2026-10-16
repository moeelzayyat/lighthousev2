# EVENTS — event bus catalog

Module: `EventLog` (Telemetry domain) exposes `Publish(name, payload)` / `Subscribe(name, handler)`. Publisher = authoritative domain only. Objectives, Logbook, Leaderboards, Results and Analytics only consume. Handlers in `pcall`; a consumer error is reported, never propagated. Payloads carry IDs and numbers, never Instances. `VoyageId` on every in-voyage event.

**R1.6 status:** the bus is `EventBus` (owned by `EventLog`, exposed as `EventLog.Publish/Subscribe`); the machine-readable catalog is `ReplicatedStorage/Shared/Events` and a publish that does not match it is rejected. Rows marked `R1.6 ✅` are published today: the funnel events come from `EventLog.mark/playerJoined/playerLeft/startRun` (called by the owning domain until the S5 domain split), voyage events from `GameState`, Pearl events from `PlayerData`. `PearlsGranted` has an extra `Balance` field; Since R1.3 `PearlsGranted` is published by `GrantService` with the `ClaimId`. Rows marked `S5.3` are catalogued but get their publisher when callback wiring moves to the bus. `VoyageEnded.Outcome` also takes `Abandoned` and `Error` (R1.5).

| Event | Payload | Publisher | Consumers | Since |
|---|---|---|---|---|
| `BootCompleted` | `{Services}` | Bootstrap | Analytics | S5.1 |
| `PlayerJoined` | `{UserId}` | Crew (EventLog.playerJoined) | Analytics (`Joined`) | R1.6 ✅ |
| `ProfileLoaded` | `{UserId, SchemaVersion, IsNew, Runs}` | Data (PlayerData) | AdminDataService (daily snapshot), later Route, Coach, Analytics | R1.3 ✅ |
| `PlayerJoinedCrew` | `{UserId, Route: "fast"\|"deck"}` | Crew | Analytics (`OnCrew`) | R1.6 ✅ |
| `VoyageStarted` | `{VoyageId, Definition, Crew: {UserId}, Forecast}` | Encounter | Analytics, Results | R1.6 ✅ |
| `PlayerLanded` | `{VoyageId, UserId}` | Encounter | Analytics (`Landed`), Coach | R1.6 ✅ |
| `FirstAction` | `{VoyageId, UserId, Kind: "oil"\|"attack"}` | Encounter | Analytics | R1.6 ✅ |
| `BeamHit` | `{VoyageId, KeeperId, CreatureId, Mode, First: boolean}` | Encounter (Lamp) | Analytics (`FirstBeamHit` when First), Objectives | R1.6 ✅ |
| `Refuelled` | `{VoyageId, UserId, Amount, FuelBefore, Night: boolean}` | Encounter (Lamp) | Feed, Results (clutch when FuelBefore < 10% at night), Objectives | S5.3 |
| `ReserveUsed` | `{VoyageId, Reason: "prologue"\|"night1safety"}` | Encounter (Lamp) | Coach, Analytics | S2.3 |
| `LampDark` / `LampLit` | `{VoyageId, Seconds?}` | Encounter (Lamp) | HUD, Analytics | S5.3 |
| `TowerRepaired` | `{VoyageId, UserId, Amount, IntegrityBefore}` | Encounter (Tower) | Feed, Results, Objectives | S5.3 |
| `CannonBuilt` / `CannonReloaded` / `CannonDestroyed` | `{VoyageId, UserId?, Pad, Level}` | Encounter (Defense) | Feed, Objectives, Analytics | S5.3 |
| `CreatureSpawned` | `{VoyageId, CreatureId, DefId, Big: boolean}` | Encounter | Analytics (sampled) | S5.3 |
| `CreatureKilled` | `{VoyageId, CreatureId, DefId, KillerId?, Source: "beam"\|"cannon"\|"harpoon"}` | Encounter | Loot, Results, Logbook, Objectives, Analytics | S5.3 |
| `BossWarning` / `BossDefeated` | `{VoyageId, DefId, FinalBlow?}` | Encounter | HUD, Results, Logbook | S5.3 |
| `LootCollected` | `{VoyageId, UserId, ItemId, Qty}` | Encounter (Loot) | Objectives, Analytics | S5.3 |
| `ShellsChanged` | `{VoyageId, Delta, Reason}` | Economy (ShellPool) | Analytics | S5.3 |
| `UpgradeBought` / `EvolutionUnlocked` | `{VoyageId, UserId, Id, Rank?}` | Encounter (Upgrades) | Results, Logbook, Objectives | S5.3 |
| `NightSurvived` | `{VoyageId, Night, Crew}` | Encounter | **Grant (dawn Pearl, `DawnBanking`, S2.2 ✅)**, Analytics (`Night1Survived`), Leaderboard | R1.6 ✅ |
| `DawnLootWindow` | `{VoyageId, Seconds}` | Encounter | HUD | S5.3 |
| `VoyageEnded` | `{VoyageId, Outcome: "Victory"\|"Defeat", Cause, NightReached, Crew, PerPlayer}` | Encounter | Results, Grant (victory bonus), Leaderboard, Objectives, Analytics | R1.6 ✅ |
| `RematchVoted` / `SailAgain` | `{VoyageId, UserId}` | Crew | Analytics | R1.6 ✅ |
| `PearlsGranted` | `{UserId, ClaimId, Amount, Balance, Source}` | Economy (GrantService) | Analytics (economy source; Source `"dawn"` → funnel `DawnPearl` once per player, S2.2) | R1.6 ✅ |
| `PearlsSpent` | `{UserId, Amount, Balance, ItemId?}` | Data (PlayerData.spendPearls) | Analytics (economy sink) | R1.6 ✅ |
| `ItemGranted` | `{UserId, ItemId, Source}` | Economy (Grant) | Logbook, Analytics | R1.3 |
| `ShopPurchase` / `MerchantPurchase` | `{UserId, ItemId, Price, Currency}` | Economy | Analytics | S5.3 |
| `ObjectiveCompleted` | `{UserId, ObjectiveId}` | LiveOps | Analytics | S7.2 |
| `LogbookDiscovered` | `{UserId, EntryId}` | LiveOps | Analytics | S7.1 |
| `InviteCompleted` | `{InviterId, InviteeId}` | Crew | Grant | S7.5 |
| `PurchaseGranted` | `{UserId, ProductId, ReceiptId}` | LiveOps | Analytics | L1.3 |
| `PlayerLeft` | `{UserId, Phase, Night?}` | Crew | Analytics (`Left`) | R1.6 ✅ |

## Funnel names (Roblox AnalyticsService; fixed for dashboard continuity)
`Joined` · `OnCrew` · `Landed` · `FirstAction` · `FirstBeamHit` · `Night1Survived` · `DawnPearl` · `VoyageEnded` · `SailAgain` · `Left`
