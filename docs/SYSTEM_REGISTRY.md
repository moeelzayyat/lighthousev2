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
| Big monsters (Barnacle Brute, Shipwreck Hermit) | Released; by crew size tested (not yet published) | S6.1 | S6.1: one per crew member on boss nights, evenly spread bearings (`WaveDirector.bossBearings`); a boss counts as 5 toward `MAX_CREATURES` (`Config.BOSS_SLOTS`, `CreatureService.load`); `BossesByCrewSpec` 5 tests |
| New monsters ×5 | Planned | S6.5–S6.6 | |
| Wave director (`nightPlan` pure) | Tested (not yet published) | R1.2 | `WaveDirector.nightPlan/bigNights/growth`; 12 tests vs pre-R1.2 reference |
| Pearl rule (`pearlsFor` pure) | Tested (not yet published) | R1.2 | `Voyage.pearlsFor`; 4 tests (win 7 = 12, win 13 = 18, loss n = n−1) |
| Loot drops, magnet, dawn window, tide | Released | S4.5 | |
| Bench upgrades (4) + evolutions (2) | Released | S5.7 | StatPipeline |
| Forecasts (3) + vote | Released | — | |
| Island merchant (voyage-only Shell items) | Tested (not yet published) | S6.2 | `Definitions/Merchant` (5 items, checked at boot), `MerchantService`, `MerchantRequest`/`MerchantResult`, Trader panel "Island stock" by day; wiped at Results; `MerchantSpec` 10 tests |
| Orbiting Blades | Planned | S6.3 | |
| Results (cause, Moment, your part, rewards, next goal) | Released; S2.5 Tested (not yet published) | S2.5 | Sail again leaves at once (0.78 s measured); Back to deck; larger "your part"; `RunCard` share line |
| Dawn Pearl banking | Tested (not yet published) | S2.2 | D-004; `DawnBanking` bus consumer of NightSurvived → GrantService claim `voyageId:night<n>:userId`; Results pays the remainder (`Voyage.resultPearls`); play-tested in DEV (7 banked + 5 = 12) |

## Crew and social
| System | Status | Target | Notes |
|---|---|---|---|
| Crew roster / ready / departure rules | Released | R1.7 | 4-player servers |
| Boarding (walk aboard), BoardingZone | Released | — | |
| First-voyage fast path | Released | — | |
| Coach prompts | Released; S2.3 forced oil prompt and S2.4 aim marker Tested (not yet published) | S2.3, S2.4 | S2.4: aim marker on the nearest creature from 30 s; prologue first crab comes out with the light |
| Crew feed + lamp flare | Released | — | |
| Lamp shift | Released (untested 2+) | S3 | |
| Invites (unrewarded) | Released | S7.5 | reward |
| Leaderboards | Planned | S7.3 | |
| Endless Storm (mode test arm) | Tested (not yet published) | S3.1b | test-only voyage; `ModeTest` 50/50 split of new accounts by UserId hash (D-017); flag `MODE_TEST_ENABLED` |
| Specialties | Planned | S7.4 | |
| Controller beam aim | Tested (not yet published; controller voyage pending, owner) | S2.6 | right stick aims (left too at the lamp), Y Focus, B Leave; `InputController.stickAngle` |

## Economy and progression
| System | Status | Target | Notes |
|---|---|---|---|
| Shells (crew pool) | Released | — | |
| Pearls (saved) | Released | R1.3 | GrantService |
| Quartermaster shop (idempotent) | Released | — | |
| Locker / loadouts | Released | R1.4 | handled cap |
| Trader (sell loot) | Released; merchant role tested (not yet published) | S6.2 | sells the merchant's stock by day |
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
| Event bus (EventLog) | Tested (not yet published) | R1.6, S5.3 | `EventBus` + catalog `Shared/Events`; 12 bus tests; publishers for funnel, voyage, Pearl and (S5.3) every catalogued voyage event; cross-service callbacks replaced by events (`BusEventsSpec`) |
| Analytics funnel | Implemented (live dashboard check pending, R1.9) | R1.6 | `Analytics` bus consumer → AnalyticsService; 4 tests; every step fired in Studio (DawnPearl from S2.2) |
| Feature flags / remote config | Planned | S5.1 | |
| Definitions registry | Tested (not yet published) | S5.4 | `Shared/_Registry` checks 8 catalogs (35 definitions) in the Definitions domain at boot; a bad definition stops the boot with every problem listed; `RegistrySpec` 8 tests |
| StatPipeline | Tested (not yet published) | S5.7 | `Shared/StatPipeline`: weapons, armor and bench upgrades; used by Attack, gear, UpgradeService and the shop, bag, bench and HUD previews; `StatPipelineSpec` 7 tests |
| Domain lifecycle | Tested (not yet published) | S5.1–S5.2 | `Server/Bootstrap` (asserted order, Inits then Starts, Boot log) + 10 `Server/Domains`; `Main` 14 lines; remotes exposed last; `BootstrapSpec` 8 tests |
| TestRunner | Implemented | R1.1 | `ServerStorage.Tests.TestRunner`; specs named `<Name>Spec` |
| Creature 20 Hz step + snapshots + interpolation | Tested (not yet published) | S4.2–S4.3 | `CreatureService` tables at 20 Hz; `Shared/CreatureSnapshot` 12 Hz; `Client/CreatureView` pooled models; 10.0 KB/s per client at 45 creatures |
| Ground height grid | Tested (not yet published) | S4.1 | `Shared/Ground` grid built at boot (World domain); 0 creature raycasts over night 1 |

## UI
| System | Status | Target | Notes |
|---|---|---|---|
| UiKit v2.1 (3.1k lines) | Released; split tested (not yet published) | S5.5 | S5.5: `Client/UiKit` (40-line facade) + `Client/UI/{Kit,Tokens,Primitives,Controls,Gauges,Dialogs}`; v1 API and the old `Gear.client` screen deleted (in `Backups.S5.5_before_2026-10-17`) |
| Pirate skin (UiSkin, Kenney atlas) | Released | — | |
| Glass HUD | Released; single pass tested (not yet published) | S5.6 | S5.6: glass built by UiKit at creation (`UiKit.beginGlass`/`Glass`), repaint pass deleted; `Hud.client` 711 lines + `HudParts/` |
| Menus / Shop / Inventory / Bench / Trader / Departure / Results / Coach | Released | S5.5 | |
| Phone layouts | Released | S4.4 | real-phone FPS |
| InputController (single) | Tested (not yet published) | S2.6 | replaces the input-mode copies in Coach, Hud, Menus, Departure, UiKit |

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
