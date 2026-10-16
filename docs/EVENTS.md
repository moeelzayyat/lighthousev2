# EVENTS — event bus catalog

Module: `EventLog` (Telemetry domain) exposes `Publish(name, payload)` / `Subscribe(name, handler)`. Publisher = authoritative domain only. Objectives, Logbook, Leaderboards, Results and Analytics only consume. Handlers in `pcall`; a consumer error is reported, never propagated. Payloads carry IDs and numbers, never Instances. `VoyageId` on every in-voyage event.

| Event | Payload | Publisher | Consumers | Since |
|---|---|---|---|---|
| `BootCompleted` | `{Services}` | Bootstrap | Analytics | S5.1 |
| `ProfileLoaded` | `{UserId, SchemaVersion, IsNew, Runs}` | Data | Route, Coach, Analytics | R1.3 |
| `PlayerJoinedCrew` | `{UserId, Route: "fast"\|"deck"}` | Crew | Analytics (`OnCrew`) | R1.6 |
| `VoyageStarted` | `{VoyageId, Definition, Crew: {UserId}, Forecast}` | Encounter | Analytics, Results | R1.6 |
| `PlayerLanded` | `{VoyageId, UserId}` | Encounter | Analytics (`Landed`), Coach | R1.6 |
| `FirstAction` | `{VoyageId, UserId, Kind: "oil"\|"attack"}` | Encounter | Analytics | R1.6 |
| `BeamHit` | `{VoyageId, KeeperId, CreatureId, Mode, First: boolean}` | Encounter (Lamp) | Analytics (`FirstBeamHit` when First), Objectives | R1.6 |
| `Refuelled` | `{VoyageId, UserId, Amount, FuelBefore, Night: boolean}` | Encounter (Lamp) | Feed, Results (clutch when FuelBefore < 10% at night), Objectives | R1.6 |
| `ReserveUsed` | `{VoyageId, Reason: "prologue"\|"night1safety"}` | Encounter (Lamp) | Coach, Analytics | S2.3 |
| `LampDark` / `LampLit` | `{VoyageId, Seconds?}` | Encounter (Lamp) | HUD, Analytics | R1.6 |
| `TowerRepaired` | `{VoyageId, UserId, Amount, IntegrityBefore}` | Encounter (Tower) | Feed, Results, Objectives | R1.6 |
| `CannonBuilt` / `CannonReloaded` / `CannonDestroyed` | `{VoyageId, UserId?, Pad, Level}` | Encounter (Defense) | Feed, Objectives, Analytics | R1.6 |
| `CreatureSpawned` | `{VoyageId, CreatureId, DefId, Big: boolean}` | Encounter | Analytics (sampled) | R1.6 |
| `CreatureKilled` | `{VoyageId, CreatureId, DefId, KillerId?, Source: "beam"\|"cannon"\|"harpoon"}` | Encounter | Loot, Results, Logbook, Objectives, Analytics | R1.6 |
| `BossWarning` / `BossDefeated` | `{VoyageId, DefId, FinalBlow?}` | Encounter | HUD, Results, Logbook | R1.6 |
| `LootCollected` | `{VoyageId, UserId, ItemId, Qty}` | Encounter (Loot) | Objectives, Analytics | R1.6 |
| `ShellsChanged` | `{VoyageId, Delta, Reason}` | Economy (ShellPool) | Analytics | R1.6 |
| `UpgradeBought` / `EvolutionUnlocked` | `{VoyageId, UserId, Id, Rank?}` | Encounter (Upgrades) | Results, Logbook, Objectives | R1.6 |
| `NightSurvived` | `{VoyageId, Night, Crew}` | Encounter | **Grant (dawn Pearl)**, Analytics (`Night1Survived`), Leaderboard | S2.2 |
| `DawnLootWindow` | `{VoyageId, Seconds}` | Encounter | HUD | R1.6 |
| `VoyageEnded` | `{VoyageId, Outcome: "Victory"\|"Defeat", Cause, NightReached, Crew, PerPlayer}` | Encounter | Results, Grant (victory bonus), Leaderboard, Objectives, Analytics | R1.6 |
| `RematchVoted` / `SailAgain` | `{VoyageId, UserId}` | Crew | Analytics | S2.5 |
| `PearlsGranted` | `{UserId, ClaimId, Amount, Source}` | Economy (Grant) | HUD (`DawnPearl`), Analytics | R1.3 |
| `ItemGranted` | `{UserId, ItemId, Source}` | Economy (Grant) | Logbook, Analytics | R1.3 |
| `ShopPurchase` / `MerchantPurchase` | `{UserId, ItemId, Price, Currency}` | Economy | Analytics | R1.6 / S6.2 |
| `ObjectiveCompleted` | `{UserId, ObjectiveId}` | LiveOps | Analytics | S7.2 |
| `LogbookDiscovered` | `{UserId, EntryId}` | LiveOps | Analytics | S7.1 |
| `InviteCompleted` | `{InviterId, InviteeId}` | Crew | Grant | S7.5 |
| `PurchaseGranted` | `{UserId, ProductId, ReceiptId}` | LiveOps | Analytics | L1.3 |
| `PlayerLeft` | `{UserId, Phase, Night?}` | Crew | Analytics (`Left`) | R1.6 |

## Funnel names (Roblox AnalyticsService; fixed for dashboard continuity)
`Joined` · `OnCrew` · `Landed` · `FirstAction` · `FirstBeamHit` · `Night1Survived` · `DawnPearl` · `VoyageEnded` · `SailAgain` · `Left`
