# SYSTEM REGISTRY

Status: `Planned` · `In Development` · `Implemented` · `Tested` (has TestRunner coverage or a recorded play test under v2.0) · `Released` (live in production). Items are never removed. "Target" = substage where v2.0 work on it lands. Statuses below reflect the live build as of 2026-10-16 (`Released` = in the published game) — most released systems still need v2.0 tests before they can be marked `Tested`.

## Encounter (voyage)
| System | Status | Target | Notes |
|---|---|---|---|
| Voyage phase loop (Waiting→Prologue→Day/Night→Results→Rematch) | Released; isolation Tested (not yet published) | R1.5, S2.1 | R1.5: each voyage in `xpcall`, `ErrorReport`, crew back to the deck; VoyageDefinition at S2.1 |
| Standard Voyage (7 nights) | Tested (not yet published) | S2.1 | D-003; `Definitions/Voyages`; bosses 4, 7; win = 12 Pearls, unlocks Long (play-tested in DEV) |
| Long Voyage (13 nights, unlock) | Tested (not yet published) | S2.1 | now the unlock (`Unlocks.LongVoyage`, `ChooseVoyage`); bosses 4, 7, 10, 13 and every night from 8; win = 18 Pearls |
| Lamp beam (wide/focused, fuel, auto-sweep, idle release) | Released | S4 | server pin of the Keeper |
| Fuel / oil carry / emergency reserve | Released; Night-1 safety Tested (not yet published) | S2.3 | `NightSafety`: first Night-1 blackout of a crew with a 0-run member refills the lamp to full once (D-014); coach oil prompt forced; feed line |
| Tower integrity / repair | Released | — | |
| Harpoons (4) | Released | R1.4 | finite checks |
| Armor (3) | Released | — | |
| Cannons (build/upgrade/reload/ammo/health) | Released | S4 | |
| Aggro / threat | Released | — | |
| Rock Crab, Sand Skitter swarm | Released | S4 | render budget |
| Big monsters (Barnacle Brute, Shipwreck Hermit) | Released | S6.1 | by crew size |
| New monsters ×5 | Planned | S6.5–S6.6 | |
| Wave director (`nightPlan` pure) | Tested (not yet published) | R1.2 | `WaveDirector.nightPlan/bigNights/growth`; 12 tests vs pre-R1.2 reference |
| Pearl rule (`pearlsFor` pure) | Tested (not yet published) | R1.2 | `Voyage.pearlsFor`; 4 tests (win 7 = 12, win 13 = 18, loss n = n−1) |
| Loot drops, magnet, dawn window, tide | Released | S4.5 | |
| Bench upgrades (4) + evolutions (2) | Released | S5.7 | StatPipeline |
| Forecasts (3) + vote | Released | — | |
| Island merchant (voyage-only Shell items) | Planned | S6.2 | |
| Orbiting Blades | Planned | S6.3 | |
| Results (cause, Moment, your part, rewards, next goal) | Released | S2.5 | Sail again |
| Dawn Pearl banking | Tested (not yet published) | S2.2 | D-004; `DawnBanking` bus consumer of NightSurvived → GrantService claim `voyageId:night<n>:userId`; Results pays the remainder (`Voyage.resultPearls`); play-tested in DEV (7 banked + 5 = 12) |

## Crew and social
| System | Status | Target | Notes |
|---|---|---|---|
| Crew roster / ready / departure rules | Released | R1.7 | 4-player servers |
| Boarding (walk aboard), BoardingZone | Released | — | |
| First-voyage fast path | Released | — | |
| Coach prompts | Released | S2.3 | |
| Crew feed + lamp flare | Released | — | |
| Lamp shift | Released (untested 2+) | S3 | |
| Invites (unrewarded) | Released | S7.5 | reward |
| Leaderboards | Planned | S7.3 | |
| Specialties | Planned | S7.4 | |
| Controller beam aim | Planned | S2.6 | |

## Economy and progression
| System | Status | Target | Notes |
|---|---|---|---|
| Shells (crew pool) | Released | — | |
| Pearls (saved) | Released | R1.3 | GrantService |
| Quartermaster shop (idempotent) | Released | — | |
| Locker / loadouts | Released | R1.4 | handled cap |
| Trader (sell loot) | Released | S6.2 | merchant role |
| Beam colours (Pearls) | Released | — | |
| Quartermaster permanent boosts + gear | Planned | S6.4 | |
| Logbook | Planned | S7.1 | |
| Daily objective | Planned | S7.2 | |

## Platform and data
| System | Status | Target | Notes |
|---|---|---|---|
| ProfileStore persistence, schema v2, migration | Tested (not yet published) | R1.3 | D-002, D-012: store `LighthouseKeepers_PlayerData_v2`, fresh start; Studio always uses the mock |
| GrantService (idempotent) | Tested (not yet published) | R1.3 | only writer of Pearl income (voyage result, boss drops, selling, admin) |
| AdminDataService (inspect/grant/rollback) | Tested (not yet published) | R1.8 | owner-only; 7 daily snapshots in `LighthouseKeepers_Snapshots_v2` |
| Remote contract registry + guards + buckets | Tested (not yet published) | R1.4 | `NetGuard` on all 15 client→server remotes; 11 tests + Play spam test |
| Event bus (EventLog) | Tested (not yet published) | R1.6 | `EventBus` + catalog `Shared/Events`; 7 bus tests; publishers for funnel, voyage and Pearl events |
| Analytics funnel | Implemented (live dashboard check pending, R1.9) | R1.6 | `Analytics` bus consumer → AnalyticsService; 4 tests; every step fired in Studio (DawnPearl from S2.2) |
| Feature flags / remote config | Planned | S5.1 | |
| Definitions registry | Planned | S5.4 | |
| StatPipeline | Planned | S5.7 | |
| Domain lifecycle | Planned | S5.1 | |
| TestRunner | Implemented | R1.1 | `ServerStorage.Tests.TestRunner`; specs named `<Name>Spec` |
| Creature 20 Hz step + snapshots + interpolation | Planned | S4.2–S4.3 | |
| Ground height grid | Planned | S4.1 | |

## UI
| System | Status | Target | Notes |
|---|---|---|---|
| UiKit v2.1 (3.1k lines) | Released | S5.5 | split |
| Pirate skin (UiSkin, Kenney atlas) | Released | — | |
| Glass HUD | Released | S5.6 | single pass |
| Menus / Shop / Inventory / Bench / Trader / Departure / Results / Coach | Released | S5.5 | |
| Phone layouts | Released | S4.4 | real-phone FPS |
| InputController (single) | Planned | S2.6 | |

## Live ops and monetization
| System | Status | Target | Notes |
|---|---|---|---|
| Cosmetics for Robux (housings, coats, lanterns, flags) | Planned | B1.1 / L1.3 | owner approval |
| Supporter pack | Planned | L1.3 | |
| Codes | Planned | L1.4 | |
| Seasons / events (Shipwreck Rescue) | Planned | LO | |
| Store assets (title, icon, thumbnails, trailer) | Planned | R0.6, S2.7, L1.5 | |

## Frozen (not in scope; history only)
| System | Status | Notes |
|---|---|---|
| Harbor/Isle place split, reserved servers, teleports, manifests, custom SessionLock, hand-off/reclaim | Frozen | branch `multiship-test` tag `frozen-2026-10-16`; audit §6 corrections recorded; revive only per architecture §4.4. R1.7: PlaceRole, Voyages, IsleAdmission, HarborDepartures moved out of the live tree into `ServerStorage.Backups.R1.7_before_2026-10-16`; flags deleted from Config; SessionLock moved to `ServerStorage.Backups.R1.3_before_2026-10-16` at R1.3 |
