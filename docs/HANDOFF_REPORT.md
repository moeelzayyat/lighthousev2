# HANDOFF REPORT

Append-only. One record per checkpoint (template: `ROADMAP.md` §14). Newest at the bottom. Historical per-task packages live in `docs/legacy/audits` and `docs/legacy/batches`.

---

## v2.0 re-baseline — 2026-10-16
Audit completed (`docs/AUDIT_2026-10-16.md`). Architecture v2.0, roadmap and operating docs written. No Studio changes. Live build: the owner-published departure build (confirm at R0.5). Pending multi-ship batch 763dc4d: accept with corrections, frozen under D-001 Option A.
Current substage: **R0.1 — Decision D-001.**

---

CHECKPOINT: R0.1 Decision D-001
DATE: 2026-10-16
STUDIO / TESTRUNNER / ANALYSIS / PLAY TEST / NUMBERS: n.a. (decision record only, no code)
OWNER APPROVAL: D-001 accepted by the owner 2026-10-16; checkpoint auto-approved (D-010)   PUBLISHED BY OWNER: n.a.
NEXT: R0.2

CHECKPOINT: R0.2 Freeze old repo (🟦 owner action)
DATE: 2026-10-16
Claude does not write to the old repo (CLAUDE.md rule 10). For the owner, when convenient: tag the old repo's `multiship-test` branch as `frozen-2026-10-16`, archive `moeelzayyat/lighthousekeepers` on GitHub (Settings, General, Archive), and keep test experience 10771229467 private and untouched. Then note "R0.2 done" in `DECISION_LOG.md`. Nothing downstream depends on it.
NEXT: R0.3

CHECKPOINT: R0.3 New repository
DATE: 2026-10-16
Verified against `architecture.md` §4.3: root files present; `docs/` has all 13 named files plus `legacy/`; `src/` export; `assets/ART_SOURCES.md`, `icons/`, `thumbnails/`; `tests/`; `.gitignore` excludes place/model files, `backups/`, `work/`, `vendor-review/`. Commits 9e52ab0 and c4770f6 on `origin/main`. Gap: `docs/legacy/ICON_BRIEF.md` (cited by `ART_BIBLE.md`) was not carried over; `ART_BIBLE.md` now holds the brief.
OWNER APPROVAL: auto-approved (D-010)
NEXT: R0.4

CHECKPOINT: R0.4 Studio baseline (🟦 owner action: version-history save and local file)
DATE: 2026-10-16
STUDIO INSTANCE: `list_roblox_studios` listed Deadzone (72812275891657), Lighthouse Keepers - Staging (132065051336560) and Outlaw City (132163592957463). Only 132065051336560 was touched; `execute_luau` confirmed PlaceId 132065051336560, GameId 10769064643, PlaceVersion 172 (Team Create session).
API ACCESS: OFF. A read-only probe on a throwaway store name returned "Studio access to APIs is not allowed" (error 7). No Play during R0.
EXPORT: 49/49 scripts fingerprinted in Studio and compared with `src/`: identical (`docs/STUDIO_MANIFEST.md`). The existing `src/` is the baseline export.
EDITS: none.
OWNER, when convenient (the Studio MCP has no save command): in the production window, File > Save to Roblox (not Publish) to create the `R0 baseline` version-history point, and File > Save to File As `LighthouseKeepers_R0_baseline_2026-10-16.rbxl`.
PROCESS NOTE: because the MCP cannot make version-history saves, checkpoint step 5 from here on is the `ServerStorage.Backups.<ID>_before_<date>` folder (kept by Team Create); the version-history save is requested from the owner at each publish substage.
NEXT: R0.5

CHECKPOINT: R0.5 Live build identity
DATE: 2026-10-16
Studio production tree equals old `main` 854f4e9, 0 drift (D-011). Multi-ship modules present but flagged off.
OWNER APPROVAL: auto-approved (D-010)
NEXT: R0.6

CHECKPOINT: R0.6 Title and icon brief
DATE: 2026-10-16
`ART_BIBLE.md` store section finalised under D-009. Owner actions (Creator Hub / Game Settings; Claude cannot do these): set the experience title to title A, `Lighthouse Keepers 🌊 Keep the Light` (removes "- Staging"); set Max players to 4 in Game Settings (required by R1.7). Icon A and B are produced at S2.7 (Studio AI image generation first, contractor as fallback).
OWNER APPROVAL: auto-approved (D-010)
NEXT: R1.1

CHECKPOINT: R1.1 TestRunner (🟦 step 2 pending: Script Analysis tool)
DATE: 2026-10-16
STUDIO INSTANCE: placeId 132065051336560 verified · API access: OFF before Play (probe: "Studio access to APIs is not allowed")
BACKUP: ServerStorage.Backups.R1.1_before_2026-10-16 (note only: R1.1 adds ServerStorage.Tests and modifies no existing script) · version-history save: owner, batched to R1.9
DELIVERED: ServerStorage.Tests/{TestRunner, unit/TestRunnerSpec, integration/, fixtures/profiles/}. API: describe/it(name, fn, timeout?)/beforeEach/afterEach; async tests (each test runs in its own thread, 5 s default timeout); expect().toBe/toEqual/toBeCloseTo/toThrow/toBeNil/toBeTruthy/toBeFalsy/toBeGreaterThan/toBeLessThan/(OrEqual)/toContain; T.mock.service/get/fn; T.clock(); T.require(module) for fresh clones. Spec convention: ModuleScripts named `<Name>Spec` (MCP paths cannot address names containing dots) returning `function(T)`. Studio caches `require` across `execute_luau` calls, so `run()` reloads itself from a clone when its source has changed.
TESTRUNNER (Edit): `3 passed, 0 failed` (0.13 s). Negative check with a temporary spec: 3 deliberate failures reported (wrong value, 0.3 s timeout, raised error), temp spec deleted.
SCRIPT ANALYSIS: NOT MEASURED. The Studio MCP cannot read the Script Analysis panel and `luau-analyze` is not installed; owner asked for permission to install it. Modules are `--!strict`.
PLAY TEST: Play started (API off confirmed first); Server datamodel: `require(TestRunner).run()` → `3 passed, 0 failed`; game booted to Phase=Waiting, fast-path route for the Studio player. Console: 0 errors from game scripts. Expected lines: DataStore 403 StudioAccessToApisNotAllowed → PlayerData in memory only (so the owner's real save was not read or written); Roblox CorePackages UIBlox "FoundationProvider not found" warnings (engine, not ours). Play stopped.
NUMBERS: 3 tests; run time 0.13 s.
MIRROR: `src/ServerStorage/Tests/` (2 files, FNV-1a identical to Studio: TestRunner 12745 chars c26f4619, TestRunnerSpec 1501 chars 1fb28743).
OWNER APPROVAL: pending step 2 (would be auto-approved under D-010)
NEXT: R1.2

CHECKPOINT: R1.2 Pure logic extraction (🟦 step 2 pending: Script Analysis tool)
DATE: 2026-10-16
STUDIO INSTANCE: placeId 132065051336560 verified · API access: OFF before Play (probe: "Studio access to APIs is not allowed")
BACKUP: ServerStorage.Backups.R1.2_before_2026-10-16 (GameState, 22857 chars)
DELIVERED: `ServerScriptService.Server.WaveDirector` (`--!strict`, pure: `growth`, `bigNights`, `nightPlan(night, crewSize, forecast, config) -> {crabs, skitters, boss?}`), `ServerScriptService.Server.Voyage` (`--!strict`, pure: `pearlsFor(night, won, config)`). `GameState` now calls them for the big-night schedule, the night spawn counts and the end-of-voyage Pearls; random boss kinds, per-award Pearls and all timing stay in `GameState`. No gameplay number changed.
REFERENCE: before editing, a verbatim copy of the old GameState formula was run against the live Config for nights 1/4/7/10/13 × crew 1–4 × forecasts none/FogBank/SpringTide/LeakyStores; that table is frozen in `WaveDirectorSpec` (crew 4, no forecast: 14/42, 34/82, 46/106, 58/130, 105/154; matches `STATS.md`). Big nights: 13, 10, 7, 4.
TESTRUNNER (Edit): `19 passed, 0 failed` (0.13 s) — TestRunner 3, WaveDirector 12, Voyage 4.
SCRIPT ANALYSIS: NOT MEASURED (no analyzer available; see R1.1). Debt: `GameState` itself is not `--!strict` (legacy module, dissolved at S5.2); adding the pragma before an analyzer can list the warnings would break the zero-warning rule blindly.
PLAY TEST: Play (API off; ProfileState=memory, SaveUnavailable=true, so the owner's real save was not read or written). Studio player boarded the ship, SAIL NOW at the wheel → Intermission → Prologue → Day 1 → Night 1 → Defeat by blackout at 2:13 (no oil carried, by design). Console: `NightSpawns crabs=14 night=1 skitters=17` (= reference, crew 1); results path ran (`RunsCompleted` 0 → 1, which follows the Pearl grant in the same loop); 0 errors from game scripts (only the expected DataStore 403 notice and engine UIBlox warnings). Play stopped.
NUMBERS: 19 tests; night-1 solo spawn 14 crabs / 17 skitters; first voyage Defeat at 2:13; GameState 22857 → 21661 chars.
MIRROR: GameState, WaveDirector, Voyage, VoyageSpec, WaveDirectorSpec; all 56 Studio scripts FNV-1a identical to `src/` after the export.
OWNER APPROVAL: pending step 2 (would be auto-approved under D-010)
NEXT: R1.3

CHECKPOINT: R1.3 ProfileStore — 🟥 BLOCKED on owner decision D-012
DATE: 2026-10-16
Finding: architecture §19 ("same store, existing values load unchanged") would wipe every existing player's save: ProfileStore overwrites any non-ProfileStore record with an empty profile (source-verified at commit 45c9847, `docs/legacy/audits/TASK-004/SOURCE_VERIFICATION_ADDENDUM.md`). Changing §19 is a stop-and-ask item, so R1.3 waits for the owner.
Recommendation (D-012): a new store `LighthouseKeepers_PlayerData_v2` with a one-time, read-only import from v1 on each player's first load; v1 frozen as the safety copy.
No Studio changes for R1.3. Meanwhile the run continues with R1.4 (remote contracts), which does not depend on persistence.

CHECKPOINT: R1.4 Remote contracts (🟦 step 2 pending: Script Analysis tool)
DATE: 2026-10-16
STUDIO INSTANCE: placeId 132065051336560 verified · API access: OFF before Play (probe: "Studio access to APIs is not allowed")
BACKUP: ServerStorage.Backups.R1.4_before_2026-10-16 (Main [disabled copy], LampService, LoadoutService, PlayerData, ShopService)
DELIVERED: `ServerScriptService.Server.NetGuard` (`--!strict`): per-player token buckets with the contract rates, capped replay maps, finite/requestId guards, counters as attributes. All 15 client→server handlers call it. BuyUpgrade now requires a Ready crew member, a voyage phase (Prologue/Day/Night) and ≤ 18 studs from the bench, with a capped replay map. LoadoutRequest replay map capped at 40 (was unbounded). ShopService replay moved to NetGuard (the old table shared its `order` key with request ids). SetReady: the two handlers merged into one; PlayerToMenu logged once per session. ReportDevice once per session. Attack rejects ±inf. `API_CONTRACTS.md` lists all 29 remotes.
TESTRUNNER (Edit): `30 passed, 0 failed` (0.13 s) — adds NetGuardSpec (11): rates equal the contract for all 15 remotes; 50 calls in one instant accept exactly the burst; 50 calls over 1 s accept ≤ burst + rate; refill and cap; per-player buckets; replay map returns the first result, caps at 40, cannot be corrupted by key names; NaN/±inf/non-Vector3 rejected.
PLAY TEST (API off; ProfileState=memory, so the owner's real save was not touched):
 1. Harbor, not crew: client fired every client→server remote 50× (Attack 150× with +inf/−inf/NaN targets). Server counters: Attack 0 allowed (rejected by the finite guard); BeamControl/LampAction 0 (not Keeper); SetReady(true) 0 (ignored); ReportDevice 0 extra (already reported once); BuyUpgrade 5/50, ShopRequest 8/50, TraderRequest 5/50, LoadoutRequest 8/50, LampShift 6/50, CoachEvent 8/50, ForecastVote 5/50, VoteRematch 3/50, EnterLobby 2/50 = exactly each burst; GearAction 7 allowed incl. the client's own startup syncs. Shells 0 → 0.
 2. Voyage (Prologue), crew, 44 studs from the bench: BuyUpgrade refused "Get closer to the UPGRADE bench."; Shells 120 → 120.
 3. Voyage, at the bench, Ready forced false (test only, restored): 50× BuyUpgrade → 5 processed, all refused "Only the voyage crew can spend the crew's Shells."; Shells 120 → 120. (Clearing Ready mid-voyage abandoned that voyage, as designed; a new one was started.)
 4. Voyage, crew at the bench: one BuyUpgrade(Walls) → Shells 120 → 95, Upgrade_Walls 1; the same requestId replayed 5× → same answer, Shells stay 95.
 Console: 0 errors from game scripts.
NUMBERS: 30 tests; per-remote accepted counts above; Main 36114 → 38430 chars.
DEBT: `Attack.Seq`/`CombatResult` (architecture §7.1) not in the R1.4 roadmap row → moved to S4 in `API_CONTRACTS.md`. Touched legacy modules (Main, LampService, LoadoutService, PlayerData, ShopService) are not `--!strict` yet (same reason as GameState in R1.2).
MIRROR: 7 files FNV-1a identical to Studio.
OWNER APPROVAL: pending step 2 (would be auto-approved under D-010)
NEXT: R1.5

CHECKPOINT: R1.5 Voyage isolation (🟦 step 2 pending: Script Analysis tool)
DATE: 2026-10-16
STUDIO INSTANCE: placeId 132065051336560 verified · API access: OFF before Play (probe: "Studio access to APIs is not allowed")
BACKUP: ServerStorage.Backups.R1.5_before_2026-10-16 (GameState)
DELIVERED: `GameState.run` runs each voyage (reset → forecast → prologue → nights → results → rematch) inside `xpcall(…, debug.traceback)`. On an error `recoverFromError` warns once with the traceback, logs one `ErrorReport {where, phase, night, error}`, then (each step in its own pcall) stops the lamp drain, unprotects the tower, clears creatures, sets Cause "error", closes the run summary as `Result: Error`, returns the lighting to day, and for every crew member still in the server sets Ready false (frees the ship seat), sends them to the deck and tells them "Something went wrong on the voyage. You're back on the deck: sail again when you're ready." The loop then returns to Waiting. Body otherwise unchanged (re-indented one level).
TESTRUNNER (Edit): `30 passed, 0 failed`.
PLAY TEST (API off; memory profile): voyage 1 sailed; during Day 1 the state attribute `ForecastCrabMult` was set to a string (TEST ONLY injection; the next Waiting phase resets it to 1) so the night plan throws as Night 1 begins (phase = Night). Console: exactly one `[GameState] voyage error … WaveDirector:70: attempt to perform arithmetic (mul) on number and string` warning with traceback, one `ErrorReport … night=1 phase=Night where=voyage`, run summary `Result: Error`. 36 s later: Phase Waiting, Ready false, ShipId nil, player on the deck, ship unlocked, 0 creatures. Voyage 2: boarded, SAIL NOW, Prologue → Day 1 → Night 1 with `NightSpawns crabs=14 night=1 skitters=17` (normal). 0 errors from game scripts.
NUMBERS: error → crew back on the deck in < 36 s (observed at the first poll); next voyage reached Night 1 normally.
NOTE: Pearls for nights survived before an error are not paid (Pearls are paid at Results until dawn banking lands at S2.2).
DEBT: injection was at the start of Night 1, not halfway through it; the recovery path is the same.
MIRROR: GameState FNV-1a identical to Studio (23553 chars, a9e44ee7).
OWNER APPROVAL: pending step 2 (would be auto-approved under D-010)
NEXT: R1.6

CHECKPOINT: R1.6 Event bus + funnel (🟦 waits on: live dashboard check after the R1.9 publish; Script Analysis tool)
DATE: 2026-10-16
STUDIO INSTANCE: placeId 132065051336560 verified · API access: OFF before Play (probe: "Studio access to APIs is not allowed")
BACKUP: ServerStorage.Backups.R1.6_before_2026-10-16 (Main [disabled copy], EventLog, GameState, PlayerData, ShopService)
DELIVERED: `EventBus` (`--!strict`: typed Publish/Subscribe, catalog validation, Instances rejected, handlers isolated in their own thread + pcall, warn once per event name, stats); catalog `ReplicatedStorage.Shared.Events` (`--!strict`); `EventLog.Publish/Subscribe/voyageId/busStats`; `Analytics` (`--!strict`) consumes the bus and calls `LogOnboardingFunnelStepEvent` (Joined 1, OnCrew 2, Landed 3, FirstAction 4, FirstBeamHit 5, Night1Survived 6, DawnPearl 7 [S2.2], VoyageEnded 8, SailAgain 9), `LogCustomEvent` (VoyageEnded with outcome:cause, Left with phase) and `LogEconomyEvent` (Pearls Source/Sink with ending balance). Publishers: PlayerJoined/PlayerJoinedCrew/PlayerLanded/FirstAction/BeamHit/PlayerLeft/VoyageStarted from EventLog; NightSurvived/VoyageEnded/SailAgain from GameState (VoyageEnded also on the R1.5 error path); PearlsGranted/PearlsSpent from PlayerData (ShopService passes the item id). `EVENTS.md` updated.
TESTRUNNER (Edit): `41 passed, 0 failed` (0.27 s) — adds EventBusSpec (11): delivery and order, unsubscribe, throwing handler isolated (warned once), yielding handler does not block the publisher, unknown/missing/mistyped/Instance payloads rejected, unknown subscription throws, catalog types valid, first-session funnel mapping, first-beam-hit and per-crew Night1Survived, economy source/sink with balance, fixed step names.
PLAY TEST (API off; memory profile; Studio player = the owner's account, so these events carry the owner's UserId): two driven voyages (oil + repair loop through the client prompts, then the lamp aimed at the nearest creature) and a self-kick. Studio printed "AnalyticsService: … event fired" and `[ANL]` for: funnel 1 Joined, 2 OnCrew, 3 Landed, 4 FirstAction, 5 FirstBeamHit, 6 Night1Survived (after surviving Night 1 with 25 repairs), 8 VoyageEnded (+ custom Defeat:breach), 9 SailAgain (Play Again on Results), economy Source Pearls 1 → 1 Gameplay (1 Pearl for reaching night 2), custom Left harbor (after the self-kick). Not seen: DawnPearl (no publisher until S2.2). Bug found and fixed in the same substage: "Left" was skipped because the leaving player could not be resolved by UserId; the sink now remembers players from join until 30 s after leaving. 0 errors from game scripts (engine-level DataStore 403 notice and UIBlox warnings only).
NUMBERS: 41 tests; 9 of 10 funnel/custom names observed in Studio; 0 bus rejections, 0 handler errors in the play sessions.
LIVE CHECK FOR THE OWNER (after the R1.9 publish): Creator Hub → Lighthouse Keepers → Analytics → Funnels (onboarding) should show steps 1–6, 8, 9 within 24 h; Economy should show Pearls sources/sinks. Then R1.6 can be marked ✅.
MIRROR: 61 scripts FNV-1a identical to Studio.
OWNER APPROVAL: pending (live dashboard + step 2)
NEXT: R1.7

CHECKPOINT: R1.7 Multi-ship removal from Main (🟦 waits on: owner's 4-client Studio test + Max players 4; Script Analysis tool)
DATE: 2026-10-16
STUDIO INSTANCE: placeId 132065051336560 verified · API access: OFF before Play (probe: "Studio access to APIs is not allowed")
BACKUP: ServerStorage.Backups.R1.7_before_2026-10-16 (Main [disabled copy], Config). The four multi-ship modules (PlaceRole, Voyages, IsleAdmission, HarborDepartures) were MOVED into the same folder, out of the live tree.
DELIVERED: `Main` no longer requires PlaceRole/Voyages/IsleAdmission/HarborDepartures; the ROLE switch, extra-ship build, isle branches, Voyages/Harbor/Isle wiring, `MultiShip` attribute and `InTransit` check are gone; GameState gets the single-ship departure directly. Config: MULTI_SHIP_ENABLED, TELEPORT_ENABLED, PLACE_ROLE_OVERRIDE, HARBOR_PLACE_ID, ISLE_PLACE_ID, ISLE_ARRIVAL_WAIT, ISLE_STUDIO_TEST deleted (no `MULTISHIP_TEST` block existed on this branch). The client `Departure` reads `MultiShip == true`, which is now nil → single-ship UI (unchanged behaviour). Main 38694 → 36078 chars.
TESTRUNNER (Edit): `46 passed, 0 failed` — adds ShipDepartureSpec (5) on a fake roster: 4/4 sails automatically; SAIL NOW for a crew of 2, only by a crew member, "already" for a second call; SAIL NOW refused at 4/4 ("full"); an automatic departure cancels when 4 drops to 3; SAIL NOW cancels when its caller leaves.
PLAY TEST (solo, API off): boot clean (only the engine DataStore 403 notice and Analytics info lines); none of the four modules in ServerScriptService; one ship in the Lobby; attributes Ship_Ship1_* and ShipCapacity = 4 only; boarded, SAIL NOW, Prologue started.
NOT DONE BY CLAUDE (owner): the roadmap's 4-client check needs Studio's multi-client test, which the MCP cannot start, and the 5th-client refusal needs Game Settings → Max players = 4. Owner steps: (1) Game Settings → Places → Max players 4, save; (2) Test tab → Clients and Servers → 4 players → Start; walk all 4 onto the ship → it sails automatically; (3) restart with 2 players, one uses SAIL NOW → it sails with 2; (4) a 5th client cannot join the server once Max players is 4. Record pass/fail in this file.
MIRROR: Main, Config, ShipDepartureSpec FNV-1a identical; the four module files removed from `src/` (58 scripts, matches Studio).
OWNER APPROVAL: pending (4-client check + step 2)
NEXT: R1.8 (blocked behind R1.3: AdminDataService needs ProfileStore) → then R1.9 publish package

CHECKPOINT: R1.3 ProfileStore (🟦 step 2 pending: Script Analysis; live part closes at R1.9)
DATE: 2026-10-16
STUDIO INSTANCE: placeId 132065051336560 verified · API access: OFF before every Play (probe: "Studio access to APIs is not allowed")
BACKUP: ServerStorage.Backups.R1.3_before_2026-10-16 (Main [disabled copy], PlayerData, ShopService, LoadoutService, GameState, LootService, SessionLock; the live SessionLock was moved here too)
DECISION: D-012 accepted by the owner as a fresh start: ProfileStore on `LighthouseKeepers_PlayerData_v2`, no import; v1 is never read, written or deleted by the new code.
DELIVERED:
 - `ProfileStore` vendored from GitHub commit 45c9847 (64,654 bytes, SHA-256 AD437372…C95F, identical to the file the TASK-004 audit read); copied into Studio in six pieces, each FNV-checked; final Studio source byte-identical. Pinned in `assets/ART_SOURCES.md` (Apache-2.0).
 - `ProfileSchema` (schema v2 template + type validation), `MigrationService` (v1→v2 lift kept and tested; `upgrade` runs on every load), `GrantService` (idempotent claims, 30-day prune; the only writer of Pearl income), `PlayerData` rewritten on ProfileStore (session lock, `Cancel` on leave, kick when a save cannot be opened, immediate save after Pearl changes, purchases and runs, `EndSession` on leave, ProfileStore's own `BindToClose`; **Studio always uses `ProfileStore.Mock`**). Callers keep a v1-shaped read view (`PlayerData.get`, GearData), so no client code changed.
 - Pearl income rerouted: voyage result (`<voyageId>:result:<userId>`), boss drops (`<voyageId>:drop:<serial>:<userId>`), Quartermaster sell (`sell:<guid>`), admin grants. `ProfileLoaded` bus event added.
TESTRUNNER (Edit): `74 passed, 0 failed` (0.58 s). Adds ProfileSpec (14: schema, v1 fixtures incl. `pearls = "25"` becomes 0 and is reported, unknown fields kept, GrantService once-only, serialised, items, invalid, prune), PlayerDataSpec (7, stand-in store: new profile, quick rejoin keeps Pearls, replayed claim once, immediate save, held save gives a kick not a blank profile, left-while-loading, bad types repaired), ProfileStoreMockSpec (3, **real ProfileStore.Mock**: new profile, quick rejoin on the same server keeps Pearls and the claim, spend/buy round trip).
PLAY TEST (API off; mock store; Studio player = owner account, nothing saved): boot logged `ProfileStoreMode mode=memory store=LighthouseKeepers_PlayerData_v2`; ProfileState=memory, SaveUnavailable=true, fast route. Studio was not rendering (0 frames; window unfocused), so ProximityPrompts could not be driven; departure and night-1 survival were driven by runtime-only TEMPTEST scripts that called the live modules (ShipDeparture.sailNow; LampService.addFuel and TowerService.repair until dawn 1), destroyed afterwards. Result: Night 1 survived, Defeat on night 2, `Grant claim=<voyage>:result:11752219158 pearls=1 source=run total=1`, economy event, RunsCompleted 1, Play Again gave SailAgain. Console: no game-script errors; the only red line is ProfileStore's own Studio probe being refused (`StudioAccessToApisNotAllowed … ____PS`), which is the API-off safety working. No TEMPTEST objects left in the place.
NUMBERS: 74 tests; 1 Pearl for reaching night 2 (unchanged rule); ProfileStore 64,654 bytes; PlayerData 10,259 → 11,222 chars.
NOT VERIFIED YET (needs the live game, R1.9): real-store session lock across servers, `BindToClose` on a real shutdown, Pearls kept across a real rejoin.
MIRROR: 69 scripts, every touched file FNV-identical to Studio; `src/.gitattributes` keeps ProfileStore byte-exact; SessionLock removed from `src/`.
OWNER APPROVAL: D-012 owner; checkpoint pending step 2 and the R1.9 live check
NEXT: R1.8

CHECKPOINT: R1.8 Admin tools (🟦 step 2 pending: Script Analysis)
DATE: 2026-10-16
DELIVERED: `AdminDataService` (`--!strict`): `handle(caller, action, target, arg)` for inspect, grant and rollback, owner-only (UserId 11752219158), refusals logged `AdminRejected`; daily snapshots (first of the UTC day, 7 newest) in `LighthouseKeepers_Snapshots_v2`, written on each `ProfileLoaded` (Studio: in-memory store); rollback applies now if the player is online (current state snapshotted first, data validated, saved) or at the next load. Remotes `AdminRequest` / `AdminResult` (contract row, guards, NetGuard 1/3). Usable from the live server console too.
TESTRUNNER: included in the 74. AdminDataSpec (5): 7-day retention, stranger rejected and logged, online rollback restores the snapshot (99 Pearls), offline rollback applied at next load, inspect and bad-input refusals.
PLAY TEST (same session, runtime-only TEMPTEST probe on the live instance): inspect showed online and snapshot day 2026-10-16; caller UserId 1 got "not allowed" (and a logged warning); owner grant 3 took Pearls 1 → 4; rollback to 2026-10-16 took Pearls back to 0 (the load-time snapshot).
OWNER APPROVAL: pending step 2
NEXT: R1.9 (publish, owner)

=====================================================================
R1.9 — READY FOR OWNER TO PUBLISH (🟦, Claude does not publish)
=====================================================================
What ships (everything since the live build 854f4e9): R1.2 night-plan and Pearl modules (numbers unchanged), R1.4 remote rate limits and bench checks, R1.5 voyage isolation, R1.6 event bus and Analytics funnel, R1.7 harbor/isle code removed, **R1.3 ProfileStore on a NEW save store (everyone, the owner included, starts at 0 Pearls; D-012)**, R1.8 admin tools. TestRunner 74/74.
Before you publish:
 1. In the production Studio window: File → Save to File As → `Documents\LighthouseKeepers_before_R1.9_2026-10-16.rbxl` (extension `.rbxl`). This is the rollback copy.
 2. (Optional, closes checkpoint step 2 for R1.1–R1.8) View → Script Analysis: look at ProfileStore, ProfileSchema, MigrationService, GrantService, PlayerData, AdminDataService, NetGuard, EventBus, Analytics, WaveDirector, Voyage, Events and the Tests folder; tell Claude the warning count.
 3. (R1.7) Game Settings → Places → Max players = 4. Optionally Test → Clients and Servers → 4 players: walking all 4 onto the ship sails it automatically.
Publish:
 4. File → Publish to Roblox.
 5. Creator Hub → Lighthouse Keepers → Servers → **Shut down all servers** (not "Migrate"), so no old server keeps writing the old store.
Live check (about 10 minutes):
 6. Join the live game. Expect 0 Pearls, starter gear, the first-voyage fast path.
 7. Play one voyage to Results (losing on night 2 or later pays at least 1 Pearl). Note the Pearl count on the Results screen.
 8. Leave and rejoin within 30 seconds: the same Pearl count must be there.
 9. Tell Claude: Pearls after step 7, Pearls after step 8, anything odd. Claude then marks R1.3 and R1.9 ✅ and checks the Analytics funnel (R1.6) the next day.
If something is wrong: Creator Hub → place → Version History → restore the previous version, then Shut down all servers. Players then see their old (frozen v1) progress again; nothing earned on the new store is lost, it is only hidden until a republish.
Claude's state: stopped here, as the owner asked ("stop only at publish substages"). Studio is not being edited, so what you publish is exactly what was tested.

=====================================================================
R1.9 RE-PLANNED (D-013) — set up the DEV experience, then publish R1 to DEV
The "READY FOR OWNER TO PUBLISH" package above is WITHDRAWN: do not publish the production window.
=====================================================================
Owner steps to create the DEV experience (about 5 minutes):
 1. In the open production Studio window ("Lighthouse Keepers - Staging", PlaceId 132065051336560): File → Save to File As → `Documents\LighthouseKeepers_DEV_seed_2026-10-16.rbxl`. This copy has all of today's work (R0–R1.8, tests, backups). Nothing here is live.
 2. Close the production Studio window. Do not publish it.
 3. File → Open from File → `Documents\LighthouseKeepers_DEV_seed_2026-10-16.rbxl`.
 4. File → Publish to Roblox As… → "Create new experience" → Name: `Lighthouse Keepers DEV` → Create.
 5. In that window: Home → Game Settings → Permissions → Private (only you). Places → Max players = 4. Security → leave "Enable Studio Access to API Services" OFF. Save.
 6. Keep the "Lighthouse Keepers DEV" window open and in front (Studio stops drawing frames when it is minimised, which blocks play tests), and tell Claude it is ready. Claude reads the new PlaceId from `list_roblox_studios` and records it in `CURRENT_PHASE.md`.
R1.9 live check in DEV (after Claude has re-run the tests in the DEV window):
 7. In the DEV window: File → Publish to Roblox (this publishes DEV only).
 8. Creator Hub → Lighthouse Keepers DEV → Play. Expect 0 Pearls (DEV's own new store).
 9. Play one voyage to Results (losing on night 2 or later pays at least 1 Pearl); leave; rejoin within 30 seconds; the Pearl count must be the same. Tell Claude both numbers.
Production: untouched until relaunch (L1.7), when the finished build is published there and D-012's fresh start applies to players.

R1.9 (DEV) — DEV experience verified · 2026-10-16
- Owner saved `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_seed_2026-10-16.rbxl` (git-ignored folder) and published it as a new experience: **Lighthouse Keepers DEV, PlaceId 102473202766620, GameId 10771322445**. The production window is closed; `list_roblox_studios` shows only Deadzone, Lighthouse Keepers DEV and Outlaw City.
- DEV window checks: PlaceId asserted; Studio API access OFF (probe refused, error 7); 68 scripts, every FNV-1a hash identical to `src/` (SessionLock already removed); 37 backup folders carried over.
- TestRunner in DEV: `74 passed, 0 failed` (0.57 s).
- Play test in DEV: Studio rendering (61 frames/s), ProfileState=memory (mock store), fast route, boarded, SAIL NOW, Prologue started; console: only ProfileStore's refused Studio probe (API off), 0 game-script errors.
- "Publish to Roblox As" already put this exact build live in DEV, so no further publish is needed for the live check. Waiting on the owner's numbers (steps 8–9 of the R1.9 DEV plan).

CHECKPOINT: R1.9 DEV cutover — live check ✅ · 2026-10-16
Owner (thread, 19:30 UTC): played Lighthouse Keepers DEV in the normal Roblox player, finished a voyage, closed the game, reopened: "pearl stayed". The exact count was not given. This confirms on a real DEV server: ProfileStore session start, Pearl grant through GrantService, save on leave, reload on rejoin. Production untouched (D-013).
R1 exit numbers: TestRunner 74 (≥ 60) ✓ · cutover check ✓ (DEV) · funnel: check the DEV Analytics dashboard after 24 h · Script Analysis: still unmeasured (owner item).
NEXT: S2.1 in the DEV window.

CHECKPOINT: S2.1 Voyage definitions — 🟦 (Script Analysis unmeasured; everything else passed)
DATE: 2026-10-16
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (ProfileStore's Studio probe refused)
BACKUP: ServerStorage.Backups.S2.1_before_2026-10-16 (Main, GameState, PlayerData, WaveDirector, EventLog, NetGuard, Hud, Departure, NetGuardSpec)
BUILT:
- `ReplicatedStorage.Shared.Definitions.Voyages`: Standard (7 nights, big monsters 4 and 7, a win unlocks `LongVoyage`) and Long (13 nights, big monsters 4, 7, 10, 13 and every night from 8; needs the unlock). Default Standard.
- `WaveDirector.bossNightsFor(def, config)` and `configFor(def, config)`; `nightPlan` takes an optional definition (old Config schedule kept when none is given).
- `GameState` runs one definition per voyage: picks the crew's choice only if a sailing member holds its unlock (else Standard), sets `VoyageDef` / `TotalNights` on the state folder, uses the definition's length for the night loop, final-night crisis, dawn loot and Pearl rule, and grants `def.unlocks` to every crew member on a win.
- `PlayerData.unlock(player, key)` (saved at once, mirrored as `Unlock_<key>` attributes, also set on load); `EventLog.setVoyage` puts the voyage id and length into the summary and results.
- New remote `ChooseVoyage(defId)` (Ready, phase Waiting/Intermission, unlock held; 2/s, burst 3). Crew card shows the voyage choice only to holders; HUD night counter reads `TotalNights`.
TESTRUNNER (DEV): 83 passed, 0 failed. New: `VoyageDefinitionsSpec` (definitions well formed; Standard bosses {4,7}; Long {4,7,8,9,10,11,12,13}; none when big monsters are off; Standard night 7 = 69 crabs, night 6 = 42; Long night 13 = 105 crabs, night 1 = 42 skitters; configFor leaves Config untouched; Pearls 12 / 18) and the PlayerData unlock test (saved, mirrored, survives a rejoin on the mock store).
SCRIPT ANALYSIS: not measured (owner item, same as R1).
PLAY TEST (DEV, Studio play on the owner's account, mock store): full Standard voyage with SAIL NOW → Victory, 7 of 7 nights, 15 min 35 s. Big monsters on night 4 (ShipwreckHermit) and night 7 (BarnacleBrute) only. Night 7 had 96 crabs (Spring Tide forecast ×1.5 plus the final-night crisis). Grant `…:result:11752219158` paid 12 Pearls; `Unlocked LongVoyage` logged. The crew card's voyage choice was hidden before the win and shown after; `ChooseVoyage("Long")` during Intermission set `VoyageDef=Long` and the next voyage started with `TotalNights=13`. Console: only ProfileStore's refused Studio probe (API off), 0 game-script errors. Play stopped; the TEMPTEST keep-alive script was runtime-only and is gone.
NUMBERS: Standard win = 12 Pearls (measured); voyage length 15:35 with SAIL NOW; night-7 crabs 96 with Spring Tide.
MIRROR: 70 scripts in DEV, every FNV-1a hash identical to `src/`.
OWNER APPROVAL: auto-approved (unattended, D-010)   PUBLISHED BY OWNER: n.a. (S2 publishes at S2.8, to DEV)
NOTES / DEBT: Long Voyage gameplay past night 1 was not played through (13 nights ≈ 30 min); its plan is covered by tests. `VoyageService` from the roadmap row is `GameState` taking a definition until the S5 domain split.
NEXT: S2.2 Dawn Pearl banking.

CHECKPOINT: S2.2 Dawn Pearl banking — 🟦 (Script Analysis unmeasured; everything else passed)
DATE: 2026-10-16
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S2.2_before_2026-10-16 (GameState, Voyage, Analytics, Hud, Results, SoundFx, VoyageSpec, PlayerDataSpec, EventBusSpec)
BUILT:
- `DawnBanking` (new, Economy domain): a bus consumer of `NightSurvived`. Each crew member gets that night's Pearls through `GrantService.Grant` (source "dawn", saved at once) with claimId `voyageId:night<n>:userId`; it keeps a per-voyage tally (a replayed dawn is counted once) and tells the client.
- `Voyage.dawnPearls(night)`, `Voyage.resultPearls(night, won, banked)`, `Voyage.dawnClaimId(...)`: the dawns add up to the same night Pearls as before; Results pays only what is left (the +5 victory bonus on a win, nothing on a loss). Totals unchanged: Standard win 12, Long win 18, loss at night n = n − 1.
- `GameState` Results: `results.pearls` = voyage total (banked + paid now), new `results.banked`; the tally is dropped after Results.
- Client: `LootCollected("PearlBanked", amount)` → lantern chime (new `SoundFx.lantern`), Pearl pickup and a "+1 Pearl banked" toast titled "Dawn". Results' Pearl tile reads "7 banked at dawn · yours to keep". The planned `DawnPearl` server→client remote was not needed (API_CONTRACTS updated).
- Analytics: a player's first dawn-banked Pearl is the `DawnPearl` funnel step (step 7), once per player.
TESTRUNNER (DEV): 92 passed, 0 failed. New: `DawnBankingSpec` (7: dawn sum = night Pearls, Results remainder 5 / 0 / 5, triangular step, claim id format, each dawn grants every crew member and notifies, a replayed dawn grants and counts once, a refused grant banks nothing, driven by NightSurvived on the bus), EventBusSpec "first dawn Pearl is the DawnPearl step, once", PlayerDataSpec "leaving at night 5 keeps the 4 Pearls banked at dawn; a replayed dawn grants once" (mock store).
SCRIPT ANALYSIS: not measured (owner item).
PLAY TEST (DEV, Studio play on the owner's account, mock store, TEMPTEST keep-alive script runtime-only): Standard voyage, SAIL NOW → Victory 7 of 7, 15:35. Server Pearls at each Day start: 0, 1, 2, 3, 4, 5, 6; console shows 7 dawn grants `664fbfa9:night1..7:11752219158` (1 each), then the Results grant `664fbfa9:result:11752219158` = 5 → 12 total. Client received 7 "PearlBanked"; RunResults pearls = 12, banked = 7; tile text "7 banked at dawn · yours to keep". Funnel: `funnel 7 DawnPearl` logged once at dawn 1. Console: ProfileStore's refused Studio write (API off) and Roblox CorePackages UIBlox warnings only; 0 game-script errors. Play stopped; 0 TEMPTEST scripts remain.
NUMBERS: dawn grant = 1 Pearl per night survived; Standard win = 7 banked + 5 at Results = 12 (measured); first dawn Pearl at 214 s into the voyage (night 1 dawn, with the 94 s prologue).
MIRROR: 72 scripts in DEV, every FNV-1a hash identical to `src/`.
OWNER APPROVAL: auto-approved (unattended, D-010)   PUBLISHED BY OWNER: n.a. (S2 publishes at S2.8, to DEV)
NOTES / DEBT: the leave-at-night-5 case is proven on the mock store (roadmap asks for mock); a live check fits the S2.8 DEV publish. Toast title and wording are new UI text, not gameplay numbers.
NEXT: S2.3 Night-1 safety.

CHECKPOINT: S2.3 Night-1 safety — 🟦 (Script Analysis unmeasured; everything else passed)
DATE: 2026-10-16
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before each Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S2.3_before_2026-10-16 (GameState, Coach)
BUILT:
- `NightSafety.shouldRefill(night, fuel, used, crewRuns)` (new, pure, Encounter): true only on Night 1, at a blackout (fuel 0), once per voyage, when a sailing crew member has 0 completed voyages.
- `GameState`: checked every 0.2 s during the night; on true the lamp is refilled to its maximum (D-014), `ReserveUsed` is set on the state folder, `NightOneReserve` is logged and every crew member's feed gets `CrewFeed{kind="reserve"}`.
- Coach client: feed line "The reserve saved the light — carry oil!" with the lamp flare and refuel sound; after the reserve the "Grab oil for the lamp" prompt is forced for the rest of the night (also for the keeper) and is un-retired so it shows again.
DECISION FLAGGED FOR THE OWNER: D-014, the reserve fills the lamp to full (100). One barrel (40) cannot carry a solo first voyager through the 90 s night because the lamp is empty at nightfall. Accepted as the recommendation under D-010; say a different amount to change it.
TESTRUNNER (DEV): 96 passed, 0 failed. New `NightSafetySpec` (4): the refill rule's cases (Night 1 only, blackout only, once, first voyager only, empty crew), and a lamp model with the live numbers: 0-run solo with an empty lamp survives Night 1 and loses Night 2; 1-run solo loses Night 1; a late Night-1 blackout is caught; a 4-player first-voyage crew reaches dawn 1.
SCRIPT ANALYSIS: not measured (owner item).
PLAY TEST 1 (DEV, owner's account, mock store, 0 completed voyages; TEMPTEST script kept the tower standing and never touched the fuel): SAIL NOW, nobody carried oil. Lamp at 0 when Night 1 began (123.8 s); `NightOneReserve crew=1 night=1` at once, lamp relit at 100. Client: one reserve feed event, feed line shown, "Grab oil for the lamp" prompt shown after the reserve. Night 1 survived (dawn at 213.8 s, 24 fuel left, 1 Pearl banked). Night 2: lamp dark at 273.0 s, Defeat (blackout) at 283.2 s. Reserve used once.
PLAY TEST 2 (DEV, same account, mock profile given 1 completed voyage by a TEMPTEST script before sailing; memory mode, nothing saved): lamp at 0 at nightfall, no reserve (`ReserveUsed=false`), Defeat (blackout) 10 s into Night 1.
"Two accounts" here means the same Studio account with a 0-run and a 1-run mock profile; a second real account was not used.
Console in both runs: ProfileStore's refused Studio write (API off) and Roblox CorePackages UIBlox warnings only; 0 game-script errors. Play stopped; 0 TEMPTEST scripts remain.
NUMBERS: fuel at Night-1 start for a never-oil first voyager = 0 (both runs); with the reserve, Night 1 ends with 24 fuel; Night 2 blackout loss 39 s into the night; without it, Night 1 lost at 10 s.
MIRROR: 74 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (e7014ef0).
OWNER APPROVAL: auto-approved (unattended, D-010)   PUBLISHED BY OWNER: n.a. (S2 publishes at S2.8, to DEV)
NEXT: S2.4 First beam hit ≤ 45 s.

CHECKPOINT: S2.4 First beam hit ≤ 45 s — 🟦 (Script Analysis unmeasured; 4 valid runs of 5, see below)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S2.4_before_2026-10-16 (GameState, Coach)
BUILT:
- Prologue: the first opening crab now climbs out as soon as the light is back (after the refuel step, or the 30 s reserve), 40° ahead of the sweep, so a new keeper has a target the moment they take the lamp. The other opening crabs follow as before (total still `PROLOGUE_CRABS` = 3). Logged as `Tutorial step=firstCrab`.
- Coach: from 30 s after the client starts, the "Aim the light at the crabs" prompt also puts the coach marker on the creature nearest the tower, and moves it on when that creature is gone.
- No new gameplay numbers (30 s is the roadmap's own value).
MEASUREMENT: `tests/first_beam_hit_bot.luau`, a scripted first-time player (no shortcuts): it walks onto the ship, uses the wheel, then follows the coach order (oil, tank, lamp, aim at the nearest creature) with a 1 s pause per step and pathfinding around the tower. Times are seconds since the script took control (about 1 s after the join on the fast path; the Studio tool call itself delays the start, so raw `sinceJoin` is corrected by the offset `PlayerReady.sinceJoin − BOT_Ready`).
- Before (same script, old prologue): first beam hit 44.5 s.
- After, valid runs (Studio drawing at 60 fps): 38.1 · 37.0 · 37.7 · 37.6 s. First crab in the beam's path at 33.8 · 32.8 · 33.4 · 33.2 s (target ≤ 35 s). Landing about 22 s after control (boarding + wheel + 10 s countdown).
- Void runs (not counted): one where the script's character got stuck on scenery; three where Studio was not the focused window (0 or 15 fps), and ProximityPrompts do not respond at that rate. A run now counts only when the frame rate stays ≥ 40.
- Median: 4 valid runs, median 37.65 s. A 5th valid run could not be made because Studio kept dropping to 15 fps, but even a total miss as the 5th run leaves the median of 5 at 37.7 s, so the ≤ 45 s check is met.
- Aim marker checked directly in Play: with the player at the lamp after 30 s, `PlayerGui.Coach.CoachMarker` was adorned to `Island.Creatures.RockCrab.Body` and the "Aim the light at the crabs" chip was shown.
TESTRUNNER (DEV): 96 passed, 0 failed (no new pure logic in this substage).
SCRIPT ANALYSIS: not measured (owner item).
PLAY TEST: every run above was a DEV Play on the owner's account with the mock store. Console: ProfileStore's refused Studio write (API off) and Roblox CorePackages UIBlox warnings only; 0 game-script errors. Play stopped; 0 TEMPTEST scripts remain.
MIRROR: 74 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (53f856fb).
OWNER APPROVAL: auto-approved (unattended, D-010)   PUBLISHED BY OWNER: n.a. (S2 publishes at S2.8, to DEV)
NOTES / DEBT: the measurement is a script, not a person; the S3 public test's funnel (`FirstBeamHit` step) gives the real number. Keep the DEV window focused during scripted runs.
NEXT: S2.5 Results and replay.

CHECKPOINT: S2.5 Results and replay — 🟦 (Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S2.5_before_2026-10-17 (GameState, Main, ShipDeparture, Results)
BUILT:
- Sail again leaves at once: a rematch departure skips the 10 s "setting sail" countdown (`ShipDeparture.mode`, `GameState` uses 0 s for mode "rematch"; every other departure still counts down `INTERMISSION_SECONDS` = 10). With a crew of 2 to 4, the Results screen still waits for everyone's choice (up to `RESULT_SECONDS` = 25) as before.
- "Back to harbor" is now "Back to deck" (same action: leave the crew, back on the ship's deck).
- "Your part" line enlarged (Body 17 instead of BodySmall 15).
- Run card: `Shared/RunCard.text(results)` builds one share line, shown on Results in a selectable, read-only text box, e.g. "Lighthouse Keepers · Lost on night 1 of 7 · Standard Voyage · 2:14 · solo". Results now carry `crewSize`.
TESTRUNNER (DEV): 99 passed, 0 failed. New `RunCardSpec` (3: win line, loss/solo line, missing fields).
SCRIPT ANALYSIS: not measured (owner item).
PLAY TEST (DEV, owner's account, mock store; TEMPTEST scripts runtime-only): a 1-voyage mock profile sailed with SAIL NOW, lost Night 1 (blackout, 2:14). Results showed the buttons "SAIL AGAIN" and "BACK TO DECK" and the run card line. Sent the Sail again vote (the button's exact remote call): **tap → next voyage's Prologue in 0.78 s** (target ≤ 3 s); log shows `RematchChoice play again`, funnel step 9 `SailAgain`, `DepartureStarted mode=rematch`, `RunStarted`. The second voyage was lost too; Back to deck (its exact remote call) set Ready=false and put the player back on the ship (`PlayerToMenu`). Console: only ProfileStore's refused Studio write (API off) and Roblox CorePackages UIBlox warnings; 0 game-script errors. Play stopped; 0 TEMPTEST scripts remain.
NOTES: the `crewSize` field was added after the play test and is covered by `RunCardSpec` only; the share line itself was seen in play. Taps were sent as the buttons' remote calls, not mouse clicks.
NUMBERS: Sail again → new voyage 0.78 s.
MIRROR: 76 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (4e71147a).
OWNER APPROVAL: auto-approved (unattended, D-010)   PUBLISHED BY OWNER: n.a. (S2 publishes at S2.8, to DEV)
NEXT: S2.6 Controller aim.

S2.4 addendum · 2026-10-17: the S2.6 regression run (same scripted player, Studio at ≥ 44 fps throughout) gave a 5th valid first beam hit: 38.2 s. Five valid runs: 37.0 · 37.6 · 37.7 · 38.1 · 38.2 s, **median 37.7 s** (≤ 45 s).

CHECKPOINT: S2.6 Controller aim — 🟦 (Script Analysis unmeasured; the full controller voyage needs the owner's hands)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S2.6_before_2026-10-17 (Coach, Hud, Menus, Departure, UiKit, Main)
BUILT:
- `StarterPlayerScripts.Client.InputController` (new, `--!strict`): `mode()` ("keyboard" | "touch" | "gamepad"), `usingGamepad()` (any controller, not only Gamepad1/2), `stickAngle(x, y)` (the aim rule, dead zone 0.35 as before).
- Replaced the input-mode copies in Coach, Hud, Menus, Departure (`inputKey`) and UiKit (`usingGamepad`, KeyHint mode). Main's stick aim now goes through `InputController.stickAngle`.
- Controller layout: the right stick is the aim stick (the coach's aim hint now shows the right stick; the left stick still aims because walking is off at the lamp); Y toggles Focus, B leaves the lamp (both already existed and are unchanged); X uses prompts (unchanged).
TESTRUNNER (DEV): 103 passed, 0 failed. New `InputControllerSpec` (4): stick directions, stick angle equals the mouse rule for the same world direction, dead zone, mode names.
SCRIPT ANALYSIS: not measured (owner item).
PLAY TEST (DEV, owner's account, mock store): keyboard/mouse regression with the scripted first-time player at ≥ 44 fps: boarded, sailed, refuelled, took the lamp, first beam hit 38.2 s; Coach, Hud, Menus, Departure and Results all loaded; `InputController.mode()` = keyboard; 0 client and 0 game-script errors (server console: only ProfileStore's refused Studio write, API off). Play stopped.
NOT DONE (needs the owner's hands): "full voyage completed with a controller in Studio". Studio's VirtualInputManager has no gamepad events (`SendGamepadButtonEvent` / `SendGamepadAxisEvent` do not exist), so a controller cannot be simulated from a script. Owner check: plug in a controller (or Studio → Test → Device → Controller emulator), press Play in the DEV window, and play one voyage with the controller only: left stick walks, X uses prompts (oil, tank, lamp, wheel), right stick aims the beam, Y focuses, B leaves the lamp. Tell Claude if anything cannot be done with the controller.
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)   PUBLISHED BY OWNER: n.a. (S2 publishes at S2.8, to DEV)
MIRROR: 78 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (07398fea).
NEXT: S2.7 Store presence.

CHECKPOINT: S2.7 Store presence — 🟦 (files made; the owner uploads them)
DATE: 2026-10-17
MADE (all in `assets/`):
- Icons 512 × 512: `icons/icon_A_beam_vs_brute.png` (no text) and `icons/icon_B_keep_the_light.png` (same art, "KEEP THE LIGHT").
- Thumbnails 1920 × 1080 (16:9): `thumbnails/thumb_1_brute_burn.png`, `thumb_2_clutch_refuel.png`, `thumb_3_crew_of_four.png` (the three shots architecture §27 names).
- Title options and the description: `store/STORE_PAGE.md` (title A "Lighthouse Keepers 🌊 Keep the Light" first; description 788 characters, no anxiety wording).
- How: staged in a DEV Play session with runtime-only TEMPTEST scripts (sail, keeper at the lamp, a Barnacle Brute in a focused beam, fuel held at 1–2 %, three copies of the player's character as the crew), captured with the Studio screen-capture tool, cropped and captioned with PIL. Recorded in `assets/ART_SOURCES.md` (own work). Play stopped; 0 TEMPTEST scripts remain.
- No game script changed in S2.7 (mirror unchanged).
OWNER STEPS (DEV experience, part of the S2.8 package below): Creator Hub → Lighthouse Keepers DEV → Configure: upload icon A; upload the three thumbnails in order; set the description from `STORE_PAGE.md`; title "Lighthouse Keepers DEV" can stay for DEV (D-013: the real title goes on production at L1.5).
NEXT: S2.8 publish package.

=====================================================================
S2.8 — READY FOR OWNER TO PUBLISH (DEV experience only)
=====================================================================
What is in this build (since the R1.9 DEV publish): S2.1 7-night Standard voyage + Long voyage unlock · S2.2 Pearls banked at every dawn · S2.3 Night-1 reserve for first voyages (D-014: refills to full) · S2.4 first crab comes with the light + aim marker · S2.5 Sail again leaves at once, Back to deck, share line · S2.6 InputController, right-stick aim. TestRunner in DEV: 103 passed, 0 failed. Every substage play-tested in DEV (records above).
Before publishing:
 1. In the DEV Studio window: File → Save to File As → `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_S2_2026-10-17.rbxl` (restore point for this publish).
 2. Home → Game Settings → Security → "Enable Studio Access to API Services" stays OFF.
Publish:
 3. File → Publish to Roblox (this is the DEV experience, PlaceId 102473202766620; production is not touched).
 4. Creator Hub → Lighthouse Keepers DEV → Servers → Shut down all servers.
 5. (S2.7) Configure: icon A, the three thumbnails, the description (see above).
Live checks (about 20 minutes, owner's account in the normal Roblox player):
 6. Dawn banking: note your Pearl count, then play a voyage past night 2: each dawn shows "+1 Pearl banked" with a chime. Leave during night 3 and rejoin: your Pearls are 2 higher than before the voyage.
 7. Sail again: finish a voyage (win or lose); tap Sail again; the next voyage starts at once.
 8. Fast path and Night-1 safety only show for an account with 0 finished voyages in DEV. The owner's account already has voyages, so use a second (alt) account if available: it lands on the crew at once; if it never carries oil, the lamp is refilled once in Night 1 ("The reserve saved the light — carry oil!") and it reaches dawn 1. Skip this step if there is no alt account; it is covered by the Studio tests in the S2.3 record.
 9. (S2.6, optional) With a controller: right stick aims, Y focuses, B leaves the lamp, X uses prompts.
 10. Tell Claude: the Pearl counts in step 6, anything odd, and whether step 8/9 were done.
If something is wrong: Creator Hub → DEV place → Version History → restore the previous version, then Shut down all servers.
Claude's state: S2.8 set to 🟦; work continues on the next substage that does not need the live build.

CHECKPOINT: S3.1 Diagnostic traffic — 🟦 (owner only: buying ads and the Creator Hub icon/title A/B are the owner's hands)
DATE: 2026-10-17
OWNER STEPS (after the S2.8 DEV publish and D-016): Lighthouse Keepers DEV → Game Settings → Permissions → Public. Creator Hub → DEV → Ads Manager: a small sponsored campaign as a diagnostic (not for ranking), running for at least 48 h. Creator Hub thumbnail/icon personalization (if offered) with icon A and icon B from `assets/icons/`; title A first (`assets/store/STORE_PAGE.md`). Read "Playthrough" per variant in Creator Analytics after 48 h and tell Claude the numbers.

CHECKPOINT: S3.1b Mode test (build) — 🟦 (Script Analysis unmeasured; the 7-day per-arm numbers need live players)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S3.1b_before_2026-10-17 (Voyages, Config, Events, RunCard, PlayerData, GameState, Main, Analytics, Hud, Results)
BUILT (D-017):
- `ModeTest` (new, pure): `armFor(userId, createdAt, config)` splits accounts created from `MODE_TEST_START` (2026-10-17 00:00 UTC) 50/50 by a hash of the UserId; `voyageFor(arms)` gives Endless only when every tested crew member is in the Endless arm.
- `Definitions/Voyages.Endless`: Endless Storm (test-only, never on the crew card; ChooseVoyage refuses it): no last night, big monsters on 4, 7 and every night from 8, no final-night crisis, no victory, dawn Pearls as usual.
- `PlayerData`: sets the `ModeArm` attribute at load and publishes `ModeAssigned`; `recordRun` keeps `BestNight` for Standard, `BestNightLong` for Long, none for Endless.
- `GameState`: a crew sailing the default gets `ModeTest.voyageFor`; `TotalNights` = 0 for Endless; `VoyageEnded` carries `Voyage`.
- Analytics: `ModeArm` (per account) and `VoyageMode` (per voyage, nights reached) custom events. HUD shows "NIGHT 8" (no "of"); Results shows "Endless Storm · reached night N"; the share line says the same.
- Flag: `Config.MODE_TEST_ENABLED = true`.
TESTRUNNER (DEV): 111 passed, 0 failed. New `ModeTestSpec` (7) and an analytics test (ModeArm and VoyageMode events).
SCRIPT ANALYSIS: not measured (owner item).
PLAY TEST (DEV, owner's account, mock store; a TEMPTEST script gave this account the Endless arm and kept lamp and tower alive to night 9): `Voyage nights=0 voyage=Endless`; HUD "DAY 1" / "NIGHT 8"; nights 1 to 8 survived with no victory at night 7; big monsters on nights 4, 7, 8 and 9; lost on night 9 (breach) after 18:35; Results: voyage Endless, total 0, night 9, 8 Pearls (8 dawns), track "Endless Storm · reached night 9 · 18:35", share "Lighthouse Keepers · Endless Storm: reached night 9 · 18:35 · solo"; analytics `VoyageEnded Defeat:breach` and `VoyageMode Endless`. Console: only ProfileStore's refused Studio write (API off) and Roblox CorePackages UIBlox warnings; 0 game-script errors. (In Studio the mock profile is new each Play, so the account got an arm; the owner's live DEV profile predates the start time and stays on Standard.)
MIRROR: 80 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (96fd4aa2).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)
NEXT: S3.2–S3.5 need live players (queued for the owner); S3.6 gate taken provisionally (D-018); then S4.1.

CHECKPOINT: S3.2–S3.5 — 🟦 not started (they need the public test running with real players: playtest sessions with real phones, two weekly iterations on live data, the signal read, the role check). Queued for the owner; Claude picks them up when the DEV experience has players and data.

CHECKPOINT: S3.6 Go/no-go — provisional GO (D-018, no live data). Work continues with S4.

CHECKPOINT: S4.1 Ground grid — 🟦 (Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S4.1_before_2026-10-17 (Ground, Config, Main)
BUILT:
- `Shared/Ground` (now `--!strict`): `buildGrid(cx, cz, radius)` samples the terrain once into a 1-stud grid, and every cell whose corners differ by more than 0.3 studs gets a 4 × 4 sub-grid (slopes, rocks); `heightAt` reads the grid inside it (bilinear) and raycasts only outside it; `sample` is the old raycast; `Ground.raycasts` counts raycasts for the probe.
- `Main` builds the grid at boot (`Config.GROUND_GRID_RADIUS` = 128 around the island centre; creatures spawn at 92 and the beam reaches 105) in a background thread; logs `GroundGrid`.
- No creature, loot or lamp code changed: they already call `Ground.heightAt`.
MEASURED:
- Accuracy (Edit, real terrain, 3000 random points over the whole 256 × 256 area): 0 points off by more than 0.2 studs within radius 95 (where creatures walk); 12 of 3000 (0.4 %) beyond, all at radius 100–140 on sea-stack edges (max 3.0 studs). A plain 1-stud grid had 26/2000 points over 0.2 (max 9.4); 2-stud 80/2000.
- Boot: in Play the grid was ready 2.7 s after boot (398,974 samples including sub-grids; it yields every 32 rows). Memory not measured separately (S4.6 soak measures growth).
- Probe (DEV Play, SAIL NOW, TEMPTEST keep-alive): `Ground.raycasts` did not change from the end of boot through the prologue, day 1 and night 1 (0 raycasts, up to 31 creatures).
TESTRUNNER (DEV): 113 passed, 0 failed. New `GroundSpec` (2): 300 grid reads across the shoreline make 0 raycasts and match raycasts within 0.2 studs; outside the grid a read raycasts.
SCRIPT ANALYSIS: not measured (owner item).
PLAY TEST: console showed only ProfileStore's refused Studio write (API off) and Roblox CorePackages UIBlox warnings; 0 game-script errors. Play stopped; 0 TEMPTEST scripts remain.
MIRROR: 81 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (a608ef19).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)
NEXT: S4.2 20 Hz step + snapshots.

CHECKPOINT: S4.2 20 Hz step + snapshots — 🟦 (Script Analysis unmeasured; measured with 1 client, see notes)
CHECKPOINT: S4.3 Client interpolation — 🟦 (Script Analysis unmeasured)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S4.2_before_2026-10-17 (CreatureService)
BUILT (one batch: the server stops drawing creatures, so the client must draw them in the same change):
- `CreatureService`: creatures are tables only. A fixed 1/20 s simulation step (at most 3 steps behind); `place` keeps a world position and yaw instead of moving a model; damage, targeting, loot and sounds use `worldPos`. 12 times a second `sendSnapshot` sends every creature (and the ones just killed, with the DYING flag for 0.3 s) over the new `UnreliableRemoteEvent` `Remotes.CreatureSnapshot`, in packets of at most 50. The art templates (eyes, health bar, feedback light) are built once and published to `ReplicatedStorage.CreatureTemplates`. `CreatureService.bytesSent` counts bytes for the probe.
- `Shared/CreatureSnapshot` (new, `--!strict`, pure): 18-byte entries (id, kind, x, y, z, yaw, state flags, hp), encode/decode with a length check, the creature-kind list, and `sample` (interpolation with short-way yaw, no extrapolation).
- `Client/CreatureView` (new LocalScript): keeps the last 6 snapshots per creature, draws it 2/12 s in the past (interpolated), adds the walk bob, eye colour, health bar, beam tint, hit flash and the kill burst; pools models per kind; a creature missing for 0.4 s is removed. Models go into `workspace.Island.Creatures` on the client (named by kind), so the coach and the aim marker still find them.
- Contract: `CreatureSnapshot` row updated (the `kind` byte and the header were added to the planned layout).
TESTRUNNER (DEV): 119 passed, 0 failed. New `CreatureSnapshotSpec` (6): round trip of every field, 50 creatures = 910 bytes (one packet), a short buffer decodes to nothing, the kind list, interpolation halfway with yaw through 0, hold before/after.
SCRIPT ANALYSIS: not measured (owner item).
PLAY TEST / PROBES (DEV, owner's account, mock store, TEMPTEST keep-alive and probe scripts, runtime only):
- Server: the island's creature folder held 4 instances all night (the prologue silhouette), i.e. 0 replicated instances per creature.
- Send (S4.2): 31 creatures on night 1 gave 6.8 KB/s of snapshots; topped up to the 45-creature cap on night 2: **10.0 KB/s average, 10.7 KB/s max** over 10 s (target ≤ 30; the old per-frame model moves were ~50). `Stats.DataSendKbps` peaked at 16.7 (all server traffic). Measured with one client; the same packet is sent to each client, so per-client send does not grow with the crew. A 4-client run is part of S4.6.
- Client (S4.3): 45 creatures drawn, 60 FPS, worst frame 18.6 ms (Studio PC, window focused). Smoothness: walking creatures moved on every rendered frame (0 still frames out of 180 in 3 s) with the largest frame step 1.3–1.4 × the average (stepping at 12 Hz would show about 4 still frames in 5 and 5 × jumps). One crab that stopped mid-sample is excluded.
- Gameplay still works: the first crab is drawn in the prologue; a harpoon strike on a crab at the tower registered (`step=strike`); the coach's lamp prompt saw the creatures; night 1 survived; 0 client errors; server console only ProfileStore's refused Studio write (API off) and CorePackages UIBlox warnings. Play stopped; 0 TEMPTEST scripts remain.
MIRROR: 84 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (9c0f6415).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)
NEXT: S4.4 Render budget.

CHECKPOINT: S4.4 Render budget — 🟦 (Script Analysis unmeasured; phone FPS is the owner's check)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S4.4_before_2026-10-17 (CreatureService, CreatureView, SoundFx, Storm)
BUILT:
- No per-creature lights: only big monsters' templates carry the feedback PointLight; small creatures show a hit (white) and burning (orange) by their eyes (client hit flash).
- Shared boss bar: big monsters no longer show an over-the-head health bar; the HUD's boss list (already there) is the one bar.
- Sound pool: client 3D sounds play from a ring of 24 Attachments on one invisible part (`SoundFx.slotAt`) instead of creating a part per sound.
- Kill bursts reuse 6 pooled neon balls (outside the creature folder, so the coach does not count them).
- Rain per device: touch devices are capped at 300 drops/s (was 315); PC unchanged; "Low effects" still turns rain off.
- Not done as written: "neon eyes". The eyes stay a client-side billboard (two frames): with S4.3 they are no longer replicated, and neon parts would need per-art eye positions. Logged here as the recommendation (D-015).
MEASURED (DEV Play, owner's account, mock store; TEMPTEST scripts held 45 creatures plus a Barnacle Brute on night 1 and killed one every 0.5 s):
- Replicated instances per creature: 0 (S4.3).
- Over 60 s: 119 kills, 119 sounds, 0 new sound or burst parts (1 sound anchor with 24 attachments and 6 burst balls in total); enabled lights at most 1 (the Brute's); client 60 FPS minimum each second with 46 models; 0 client errors; server console only ProfileStore's refused Studio write (API off) and CorePackages UIBlox warnings.
- New non-creature parts in that minute were loot drops (166, e.g. Loot_Shells), which S4.5 handles.
- Phone FPS during a night-7 swarm: not measured (needs the owner's phone; queued).
TESTRUNNER (DEV): 119 passed, 0 failed (no new pure logic).
SCRIPT ANALYSIS: not measured (owner item).
MIRROR: 84 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (32f19f1d).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)
NEXT: S4.5 Loot.

CHECKPOINT: S4.5 Loot — 🟦 (Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S4.5_before_2026-10-17 (LootService)
BUILT:
- `LootService`: an orb is placed once (the short pop tween when it drops, then the `Landing` and `Landed` attributes) and never moved again on the server; the magnet only moves the server's own copy of the position that decides the pickup (same range and speed as before).
- `Client/LootView` (new LocalScript): landed orbs bob and spin in place; an orb within this player's magnet range flies to them; the rare-loot pillar follows the orb. Local moves only.
MEASURED (DEV Play, owner's account, mock store; TEMPTEST script killed one creature a second on night 1):
- 23 orbs dropped; **0 server-side CFrame changes after landing** (replication only on spawn, its pop, and removal).
- Client: idle orbs bob (position changes frame to frame); walking to an orb collected it and sent `LootCollected` (Shells 4, then a Crab Claw pulled in on the way).
- 0 client errors; server console only ProfileStore's refused Studio write (API off) and CorePackages UIBlox warnings. Play stopped; 0 TEMPTEST scripts remain.
TESTRUNNER (DEV): 119 passed, 0 failed (no new pure logic).
SCRIPT ANALYSIS: not measured (owner item).
MIRROR: 85 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (c0cf620c).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)
NEXT: S4.6 4-client soak.

CHECKPOINT: S4.6 Soak — 🟦 (1 client, not 4; the 4-client run is the owner's; Script Analysis unmeasured)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: none needed (no code changed; the soak driver was a runtime-only TEMPTEST script)
RUN: DEV Play, owner's account, mock store. A TEMPTEST server script kept the lamp lit and the tower standing, pressed Play Again after each result, and read memory every 60 s. **3 Standard voyages back to back, 47 minutes, 3 victories, 6 big monsters** (a Shipwreck Hermit on nights 4 and 7 of each voyage), up to 96 crabs on a night-7 swarm.
MEASURED (Studio runs Edit, server and client in one process, so these are whole-Studio numbers):
- Lua heap: 876.3 MB at the start, 834.7 MB at the end (**−41.6 MB**; it peaked at 899.4 MB in voyage 2 and fell when the garbage collector ran).
- Total process memory: 2892 → 2938 MB, **+46 MB in 47 min (59 MB/h overall)**. Almost all of it came in the first 20 minutes (2885 → 2931, warm-up: pools, templates, sound and texture caches); **minutes 21–47 grew 7 MB (16 MB/h)**. The steady-state rate is under the 50 MB/h target; the overall rate is not, so the record stays 🟦 until a 4-client run (or a live server's memory graph) confirms it.
- Errors: **0 server, 0 client** (LogService history); client 5 warnings (CorePackages). Creature folder empty after the last voyage; 0 TEMPTEST scripts remain after Stop.
- Not measured: 4 clients (one Studio window cannot run 4 clients and the soak driver at once; needs the owner's Test → Clients and Servers run); the MicroProfiler.
TESTRUNNER: not rerun (no code change since S4.5: 119 passed, 0 failed).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)
NEXT: S4.7 publish package, then S5.1.


=====================================================================
S4.7 — READY FOR OWNER TO PUBLISH (DEV experience only)
=====================================================================
What is in this build (since the S2.8 package): S3.1b mode test (Endless Storm for half of new accounts, behind `MODE_TEST_ENABLED`) · S4.1 ground grid · S4.2/S4.3 creatures drawn on the client from 12 Hz snapshots (10 KB/s per player at 45 creatures) · S4.4 render budget (lights on big monsters only, pooled sounds and bursts, rain cap on phones) · S4.5 loot drawn on the client. If S2.8 was not published yet, this one package covers both: publish once.
Before publishing:
 1. In the DEV Studio window: File → Save to File As → `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_S4_2026-10-17.rbxl`.
 2. Game Settings → Security → "Enable Studio Access to API Services" stays OFF.
Publish:
 3. File → Publish to Roblox (DEV experience, PlaceId 102473202766620; production is not touched).
 4. Creator Hub → Lighthouse Keepers DEV → Servers → Shut down all servers.
Live checks (about 20 minutes):
 5. Phone (S4.4/S4.7): play to night 7 if you can (or the busiest night you reach), with Performance Stats on (in the game: Roblox menu → Settings → Performance Stats). Tell Claude the lowest FPS you see during a swarm and the phone model.
 6. PC: creatures move smoothly (no stutter), crabs light up in the beam, a burned crab bursts, loot bobs and flies to you, a Barnacle Brute shows its health on the bar at the top, not over its head.
 7. Optional (S4.6, 4 players): Studio → Test → Clients and Servers → 4 players → Start; play one voyage; tell Claude whether anything errors.
 8. Tell Claude: the phone FPS and model, anything odd.
If something is wrong: Creator Hub → DEV place → Version History → restore the previous version, then Shut down all servers.
Claude's state: S4.7 set to 🟦; work continues with S5.

CHECKPOINT: S5.1 Lifecycle + S5.2 Dissolve Main — 🟦 (Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S5.1_before_2026-10-17 (Main, CreatureService)
BUILT (one batch: Main could not shrink without the domains, and the domains replace Main's code):
- `Server/Bootstrap` (new, `--!strict`): `ORDER` = Platform → Telemetry → Data → Definitions → Economy → World → Encounter → Crew → LiveOps → Network (architecture §5.2). `check` refuses an unknown domain, a domain out of order or repeated, and a list that does not end with Network; `run` checks, runs every `Init` in order, then every `Start` in order, and logs `Boot order=...`. A wrong order runs nothing.
- `Server/Domains/*` (10 new modules, each `{ Name, Init?, Start? }`, sharing one `ctx`):
  - Platform: the GameState folder and every remote (including the `CreatureSnapshot` unreliable remote), built unparented; `ctx.notify`.
  - Telemetry: analytics start, `ReportDevice`, quit logging.
  - Data: admin tools, `PlayerData.init`, `AdminRequest`.
  - Definitions, LiveOps: empty slots (S5.4 `_Registry`; S6/S7 content).
  - Economy: dawn banking, loadouts, gear (weapon tools, worn armor, `PlayerData.onChanged`), beam colour, the Trader (`TraderRequest`, auto-sell); Start: the shop and weapon hooks.
  - World: island and ship builds (`ctx.refs`, `ctx.lobbyRefs`); Start: the ground grid.
  - Encounter: lamp, tower, upgrades, creatures (now given the remotes folder), loot, cannons; oil carrying; the bench and `BuyUpgrade`; `Attack`; `VoteRematch`, `ForecastVote`, `ChooseVoyage`; Start: the round loop (`task.defer(GameState.run)`).
  - Crew: ship travel, `CoachEvent`, `EnterLobby`, `SetReady`, roster/boarding/departure and the wheel, the first-voyage route, player join and the crew count.
  - Network: Start parents the remotes folder, so clients see the remotes only after every handler is connected.
- `Main`: 1073 lines → **14 lines** (requires the domains in `ORDER` and calls `Bootstrap.run`).
- `CreatureService.init` takes the remotes folder (7th argument) instead of waiting for `ReplicatedStorage.Remotes`, which no longer exists until boot ends.
- No behaviour change intended: a line-by-line check of the old Main against the domains leaves only rewritten wiring (require paths, `ctx` hand-offs, the merged route `PlayerAdded`).
- Deviation (recommendation, D-015): architecture says "remotes created only after every Start"; they are created in Platform and **exposed** (parented) last, because the handlers must connect to them during Init. Clients cannot reach them earlier.
- Not done: `--!strict` on the 10 domain modules (they wrap untyped services; strict typing lands with the bus wiring in S5.3 and the stat pipeline in S5.7). Feature flags / remote config stay Planned (no roadmap row in S5.1).
TESTRUNNER (DEV): **127 passed, 0 failed** (119 + new `BootstrapSpec` 8: the order, a module for every domain and nothing else, the real order accepted, Economy/World swapped trips "Economy must start before World", Platform/Telemetry swapped trips, Network not last / repeated / unknown domains trip, Inits before Starts with one shared ctx and one Boot log, a wrong order runs nothing, one-phase domains).
PLAY TEST (DEV, owner's account, mock store; a TEMPTEST client script, runtime only):
- Boot log: `Boot order=Platform:Init Telemetry:Init Data:Init Definitions:Init Economy:Init World:Init Encounter:Init Crew:Init LiveOps:Init Network:Init Platform:Start Telemetry:Start Data:Start Definitions:Start Economy:Start World:Start Encounter:Start Crew:Start LiveOps:Start Network:Start`; 33 remotes exposed; ground grid built in 2.5 s.
- Every client→server remote moved out of Main, plus the ones in unchanged services, answered: EnterLobby (InLobby), ReportDevice (Device logged), GearAction (GearData), LoadoutRequest (LoadoutResult "already equipped"), ShopRequest (ShopResult "Talk to the Quartermaster"), AdminRequest (AdminResult; AdminInspect logged), TraderRequest (TraderResult, before and as crew), CoachEvent (promptShown:oil marked), boarding (Ready), ChooseVoyage (Long → 13 nights → back to Standard 7, with the unlock attribute set at runtime), ForecastVote (vote counted at departure), the wheel (Prologue), oil prompt (CarryingOil), fuel prompt (Refueled 5 → full), Trader prompt (TraderOpen), bench prompt (OpenUpgrades), BuyUpgrade (Lens Power level 1), Attack (`step=strike` hit), lamp console (Keeper), LampAction toggleMode (BeamMode changed) and leave, BeamControl, VoteRematch (WantsRematch), SetReady(false) (back to the ship, voyage abandoned).
- Server→client seen: AdminResult, CreatureSnapshot (412), CrewFeed, GearData, LoadoutResult, Notify, OpenUpgrades, PlaySound, ShopResult, TraderOpen, TraderResult, Travel, UpgradeResult.
- Errors: 0 client; server only ProfileStore's refused Studio write (API off). Play stopped; 0 TEMPTEST scripts remain.
SCRIPT ANALYSIS: not measured (owner item).
MIRROR: 97 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (2455f1ec).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)
NEXT: S5.3 Callback wiring → bus.

CHECKPOINT: S5.3 Callback wiring → bus — 🟦 (Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S5.3_before_2026-10-17 (16 scripts: Events, Main, CreatureService, DefenseService, Domains.Crew/Economy/Encounter, GameState, LampService, LootService, PlayerData, ShipDeparture, ShipRoster, ShopService, TowerService, UpgradeService)
BUILT:
- Callbacks replaced (none left; `BusEventsSpec` greps every server script for them):
  - `CreatureService.onKilled` → `CreatureKilled` on the bus; `LootService` subscribes and drops loot where it fell.
  - `PlayerData.onChanged` → `ProfileChanged`; the Economy domain re-syncs tools, armor and beam colour.
  - `ShipRoster.onChange` → `CrewRosterChanged`; `ShipDeparture` subscribes when given `subscribe` (the Crew domain passes the bus; the unit test does not).
  - The dawn auto-sell callback (`deps.autoSell`) → GameState publishes `DawnLootWindow`; the Economy sells 2 s after it closes (still behind `AUTO_SELL_LOOT`, off).
  - `LampService.colorFor` → the player's `BeamColor` attribute, kept current by the Economy's gear sync; the lamp reads it when a Keeper takes over.
  - `DefenseService.setOilHandlers/setCrateHandlers` → new `Server/OilCarry` (`--!strict`: has/give/remove, used by the oil prompts, the cannons and the trip back to the ship) and direct calls to `PlayerData.count/removeItem` for shop ammo crates.
- New publishers for every catalogued `S5.3` event: Refuelled, ReserveUsed, LampDark/LampLit, TowerRepaired, CannonBuilt/Reloaded/Destroyed, CreatureSpawned, CreatureKilled, BossWarning/BossDefeated, LootCollected, ShellsChanged (with a reason), UpgradeBought, EvolutionUnlocked, DawnLootWindow, ShopPurchase, BootCompleted; new rows CrewRosterChanged and ProfileChanged. MerchantPurchase moves to S6.2 (no merchant yet). `EVENTS.md` and `Shared/Events` updated together.
- Kept as composition, not callbacks: the Bootstrap `ctx` hands the round loop its ship and travel functions (`sendToIsland`, `sendToShip`, `departure`, `departShip`) and `notify`. They are wiring done once at boot by the composition root, not one service assigning into another; logged as the recommendation (D-015).
TESTRUNNER (DEV): **132 passed, 0 failed** (127 + new `BusEventsSpec` 5: every new event validates with a real payload; a kill without a position and an Instance payload are rejected; a non-yielding handler has run when Publish returns; a failing handler does not stop the next one or the publisher; no server script assigns `.onKilled/.onChanged/.onChange/.colorFor/autoSell` or calls the old setters).
PLAY TEST (DEV, owner's account, mock store; TEMPTEST server script counted bus events, runtime only):
- Boarded, sailed (CrewRosterChanged ×3), oil → tank (Refuelled), built a cannon (CannonBuilt), bought Lens Power (UpgradeBought, ShellsChanged −30 "upgrade"). On night 1 the cannon fired, then a carried barrel reloaded it (CannonReloaded; the barrel left the player's back through `OilCarry`). A scripted harpoon strike killed 10 creatures, cannons more: CreatureKilled 29, CreatureSpawned 40, **14 loot orbs dropped through the bus subscription**, LootCollected 3, ProfileChanged 3 (loot into the inventory; tools and armor still in place: Driftwood Harpoon, Oilskin Coat; `BeamColor` set). The Night-1 reserve caught a blackout (LampDark, ReserveUsed, LampLit). Dawn: NightSurvived, DawnLootWindow, ShellsChanged +13 "waveBonus".
- 0 bus rejections or handler errors; 0 client errors; server only ProfileStore's refused Studio write (API off). Play stopped; 0 TEMPTEST scripts remain.
SCRIPT ANALYSIS: not measured (owner item).
MIRROR: 99 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (eaf10b51).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)
NEXT: S5.4 Definitions registry.

CHECKPOINT: S5.4 Definitions registry — 🟦 (Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S5.4_before_2026-10-17 (Domains.Definitions)
BUILT:
- `ReplicatedStorage/Shared/_Registry` (new, `--!strict`, pure): rules for every catalog the game loads (Ammo, Creatures, Forecasts, Items, Upgrades, Weapons, Voyages, and the bus `Events` catalog). It checks types and ranges of every field the game reads; that every id in an order list (SHOP_ORDER, ORDER, BIG_POOL) is defined and listed once; duplicate evolution ids; cross-catalog links (an item of kind Weapon has `Weapons` stats and back; an ammo crate names a defined ammo type; a voyage's unlock is granted by another voyage; the default voyage needs no unlock; a test-only voyage is not on the crew card); one starter per slot; and that any definition's `loot` table sums to 1. Every problem comes back as `Catalog.id.field: what is wrong`.
- `Domains/Definitions` Init calls `Registry.assertValid()`: on any problem the boot stops with one message listing them all ("Definitions: N problems; the server will not start until they are fixed"), before the island is built or the remotes are exposed. On success it logs `Definitions checked=35`.
- Notes: no catalog has a weighted loot table today (drops are per-item chances in `Config`), so the sum-to-1 rule is in place for the first one and proven by the test. A key written twice inside one Lua table cannot be seen at run time (the second silently wins); duplicate ids are caught where they can exist (order lists, evolution ids). The catalogs stay where they are (`Shared/*`, `Shared/Definitions/Voyages`); moving them under `Definitions/` would touch every client and server require for no behaviour change.
TESTRUNNER (DEV): **140 passed, 0 failed** (132 + new `RegistrySpec` 8: the real catalogs have no problems and 35 definitions; a negative price names `Items.FlareGun.price`; duplicate ids in SHOP_ORDER and EVOLUTIONS; a loot table summing to 0.9 fails and 1.0 passes; weapon/item, ammo and unlock links; ranges (a boss night past the last night, NaN health, 150% damage reduction, an unknown event field type); `assertValid` lists every problem in one message).
PLAY TEST ×2 (DEV, owner's account, mock store):
1. Good catalogs: `Definitions checked=35`, then the full boot order; remotes exposed; phase Waiting; 0 client errors; server only ProfileStore's refused Studio write (API off).
2. Broken sample (`Items.FlareGun.price` set to −5 in Studio, marked `--TEMPTEST`): the server stopped at boot with "Definitions: 1 problem; the server will not start until they are fixed: - Items.FlareGun.price: must be a positive number, got -5"; no island built, no remotes exposed. Play stopped and the price restored to 60 at once (0 `TEMPTEST` lines in any game script afterwards).
SCRIPT ANALYSIS: not measured (owner item).
MIRROR: 101 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (c9f9576e).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)
NEXT: S5.5 UiKit split.

CHECKPOINT: S5.5 UiKit split — 🟦 (Script Analysis unmeasured; real-phone look is part of the owner's S4.7 check)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S5.5_before_2026-10-17 (UiKit, Gear.client)
BUILT:
- `Client/UI/` (new): `Kit` (the one UiKit table and the helpers the parts share), `Tokens` (colour, fonts, type, spacing, radii, motion), `Primitives` (new/tween/number helpers, click sound, focus ring, modals, text, glyphs, panels and structure), `Controls` (buttons, tooltip, input hints, tabs, settings controls, currency/tags/badges, item card), `Gauges` (HUD gauges), `Dialogs` (notices, pickups, dialogs, motion). The section code moved unchanged; only `script.Parent` paths and the shared-helper hand-over (`K.new`, `K.tween`, ...) are new.
- `Client/UiKit`: 3,115 → 40 lines. It loads the five parts in order and applies the art skin, so every screen keeps `require(UiKit)` with no change.
- Deleted: the v1 API (THEME, make, corner, stroke, text, button, setEnabled, tag, toast, layoutFor, CATEGORY_COLORS, MIN_TOUCH; nothing in the game used them) and `Gear.client` (the old disabled GEAR screen, replaced by Shop and Inventory). Both are in the backup folder.
VERIFIED "renders unchanged" (DEV Play, owner's account, mock store; TEMPTEST client scripts, runtime only):
- Every ScreenGui's whole tree (class, name, position, size, anchor, colours, transparency, text, text colour/size, font, images, corners, strokes, padding, lists, z-index, visibility) hashed before and after: **20 of 20 screens identical** (Coach, Departure, GameHUD, HudTopBar, Inventory, InventoryButton/Scrim, LighthouseHUD, Menus, Prompts, QuartermasterShop/Scrim, Results, ResultsContent, SalvageTrader, ShopNotice, TravelCard, UpgradeBench, Freecam, StyleSheet). Two samples 2 s apart matched, so the hashes are stable.
- The UiKit style guide (every component) on all 5 tabs at desktop size and at phone size (667 × 375): an A/B in the same Studio (original UiKit restored for one Play, then the split) gave **10 of 10 identical hashes**, once the two animated loading spinners were left out (their rotation changes every frame, so they differ between any two runs). Before/after screenshots of the phone-size Controls page match.
- 0 client errors.
TESTRUNNER (DEV): 140 passed, 0 failed (no new pure logic).
SCRIPT ANALYSIS: not measured (owner item).
MIRROR: 106 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (1f7647b1).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)
NEXT: S5.6 HUD single pass.

CHECKPOINT: S5.6 HUD single pass — 🟦 (Script Analysis unmeasured; the real phone look is part of the owner's S4.7 check)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S5.6_before_2026-10-17 (Hud, UiSkin, UI.Tokens, UI.Primitives, UI.Controls, UI.Gauges)
BUILT:
- Glass is now a UiKit build variant, not a repaint. Between `UiKit.beginGlass()`/`endGlass()` (or inside `UiKit.Glass(fn)`) every element is created as night-navy glass: surfaces the wood skin warmed get their navy originals (kept as `K.BaseColor` before the skin remaps the tokens), brass outlines get the blue glow, buttons get glass bodies, and the wood art is never attached (`UiSkin` wrappers skip glass builds). `UiKit.palette()` gives builders the glass tokens for later recolours (the gauges use it); `UiKit.glassPanel` styles a HUD panel at build time; `UiKit.GLASS` holds the glass colours.
- The HUD's `glassTree`/`restyle`/`deskin`/`glassStroke` pass (and its DescendantAdded hooks on four screens and the BAG button) is deleted. Boss bars, notices and pickups are built inside `UiKit.Glass`.
- `Hud.client`: 2,044 → **711 lines**. New `Client/HudParts/`: `Build` (every element, already glass), `Prompts` (prompt cards and their logic), `Bosses` (boss bars), `Layout` (sizes, places, phones, slim gauges), `Simulator` (Studio only).
VERIFIED "HUD identical" (DEV Play, owner's account, mock store; TEMPTEST scripts held fuel, tower and health still, runtime only):
- A recorder hashed every element of the HUD screens (GameHUD, Prompts, HudTopBar, InventoryButton: position, size, absolute size and position, colours, transparency, text, fonts, strokes, corners, padding, gradients) in 7 states inside one prologue (deck, crew, prologue, carrying oil, keeper with focused beam, boss bar, blackout alarm) at 4 sizes (the real window and the HUD simulator's small phone 667×375, tablet 1180×820 and laptop 1366×768): 84 snapshots, each stable across two samples; the old HUD reproduced its own hashes in a second run.
- New HUD vs old: **84 of 84 identical** once the two intended changes below are mapped back (exact hash match). A/B runs of the old code in the same Studio located every difference.
- Intended changes (visible, small):
  1. The health and lamp-fuel gauge caps and the fuel track stay navy glass. The old repaint ran once, so the first time a gauge recoloured (any health or fuel change) these went back to the wood skin's brown (34,24,17).
  2. The keeper's FOCUS/WIDE BEAM button draws its own label. The old one hid its text under a mirrored skin label drawn 2 px higher; that label had also widened the button to 190 px, so the new button keeps `minWidth = 190` and the keeper row is unchanged.
- 0 client errors; server only ProfileStore's refused Studio write (API off). Play stopped; 0 TEMPTEST scripts remain.
TESTRUNNER (DEV): 140 passed, 0 failed (no new pure logic).
SCRIPT ANALYSIS: not measured (owner item).
MIRROR: 111 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (3fd957e4).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)
NEXT: S5.7 Stat pipeline.

CHECKPOINT: S5.7 Stat pipeline — 🟦 (Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S5.7_before_2026-10-17 (UpgradeService, Domains.Encounter, Domains.Economy, Hud, Shop, Inventory, Bench)
BUILT:
- `ReplicatedStorage/Shared/StatPipeline` (new, `--!strict`): `compute(stat, base, {flat, add, mult})` = clamp((Base + ΣFlat) × (1 + ΣAdditivePct) × ΠMultipliers, Min, Max), refusing unknown stats and layers a stat does not take; `weapon(id)`, `armor(id)`, `upgrade(id, rank)`. Stat rows and caps from `docs/STATS.md` (11 stats today).
- In the voyage: the server's Attack uses `StatPipeline.weapon` (cooldown, range, hit radius, damage, targets); gear uses `StatPipeline.armor` (max health, damage reduction); `UpgradeService.value` uses `StatPipeline.upgrade` (lens, fuel tank, walls, clockwork sweep).
- Previews: the shop and the bag compare weapons and armor through the same functions; the bench shows now → next with `StatPipeline.upgrade`; the HUD's reload bar reads the weapon's cooldown from it.
- No number changed. `STATS.md`: `WeaponRange` max raised from 40 to 100 (the table's cap was below every approved weapon range, 50–70; clamping would have shortened every weapon); new rows `WeaponHitRadius`, `WeaponMaxTargets`, `BeamDamageMult`, `AutoSweepDps`.
TESTRUNNER (DEV): **147 passed, 0 failed** (140 + new `StatPipelineSpec` 7: the formula and clamps; unknown stat and wrong layer refused; every weapon, armor and bench rank equals today's catalog value; the bench preview equals what UpgradeService applies at every rank of every upgrade; the shop, bag, bench, HUD and voyage code all read StatPipeline).
PLAY TEST (DEV, owner's account, mock store; runtime-only client steps): the bench showed "Beam damage 100% → 125% · Max fuel 100 → 130 · Tower strength 100 → 150 · Auto-sweep damage 0/s → 4/s" (the catalog values); a harpoon strike on the first crab registered (`step=strike`); armor applied (Oilskin Coat, 100 HP, 0% reduction). 0 client errors; server only ProfileStore's refused Studio write (API off). Play stopped; 0 TEMPTEST scripts remain.
SCRIPT ANALYSIS: not measured (owner item).
MIRROR: 113 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (f174838b).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)
NEXT: S5.8 publish package (owner), then S6.1.

=====================================================================
S5.8 — READY FOR OWNER TO PUBLISH (DEV experience only)
=====================================================================
What is in this build (since the S4.7 package): S5.1–S5.7, the domain split. The server now starts ten domains in a checked order (Main is 15 lines), services react to each other through the event bus, every catalog is checked at boot, UiKit is split into five parts, the glass HUD is built natively (the HUD looks the same: the health and fuel gauge caps now stay navy instead of turning brown, and the keeper's beam button draws its own label), and one stat pipeline feeds the shop, bag and bench previews and the voyage. No gameplay number changed. If S2.8 or S4.7 were not published yet, this one package covers them: publish once.
S5 exit: TestRunner 147 tests (≥ 120) ✓ · Main 15 lines (≤ 80) ✓ · Script Analysis warnings: not measured (owner item, see below).
Before publishing:
 1. In the DEV Studio window: File → Save to File As → `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_S5_2026-10-17.rbxl`.
 2. Game Settings → Security → "Enable Studio Access to API Services" stays OFF.
 3. Optional, 1 minute: View → Script Analysis, tick "Show warnings", and note the number of warnings for `ServerScriptService.Server` and `StarterPlayerScripts.Client` (tell Claude the two numbers).
Publish:
 4. File → Publish to Roblox (DEV experience, PlaceId 102473202766620; production is not touched).
 5. Creator Hub → Lighthouse Keepers DEV → Servers → Shut down all servers.
Live checks (about 20 minutes, on a phone if you can):
 6. Join: the title, the ship and the HUD look as before; the bag and shop show weapon and armor numbers; the bench shows "now → next".
 7. Play a voyage to night 2 or further: notices, pickups and the boss bar look as before; a harpoon strike damages a crab; Pearls bank at dawn.
 8. Phone (from S4.7): the lowest FPS you see during a big swarm, and the phone model.
 9. Tell Claude: anything that looks different from before, the phone FPS, the Script Analysis numbers.
If something is wrong: Creator Hub → DEV place → Version History → restore the previous version, then Shut down all servers.
Claude's state: S5.8 set to 🟦; work continues with S6.1.

CHECKPOINT: S6.1 Bosses by crew + Long Voyage boss nights — 🟦 (4-client run and Script Analysis are the owner's; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S6.1_before_2026-10-17 (GameState, CreatureService, WaveDirector, Config) · restore point "S6.1 passed"
BUILT:
- Boss nights: one big monster per ready crew member (1–4). The night's scheduled kind leads; the others are random kinds. Bearings are evenly spread from a random start (`WaveDirector.bossBearings`: 4 crew → 90° apart). One notice for the crew ("4 big monsters climb out of the sea, one for each Keeper!"); a `BigMonsterSpawned` log line and a `BossWarning` event per boss. Bosses arrive at full health (no scaling; tuned after the public test, architecture §6).
- Creature cap: a boss counts as 5 toward `MAX_CREATURES` 45 (`Config.BOSS_SLOTS = 5`, `CreatureService.load()`); bosses always arrive, crabs and skitter packs wait while the slots are full. With 4 bosses up, 25 small creatures fit.
- Long Voyage boss nights (4, 7, 10, 13 and every night from 8) were already built in S2.1; each of those nights now gets one boss per crew member.
- New gameplay value: `BOSS_SLOTS = 5` is the number named in architecture §6 and the roadmap row, not a new decision.
TESTRUNNER (DEV): **152 passed, 0 failed** (147 + new `BossesByCrewSpec` 5: one boss per crew member clamped 1..4; even spread; a boss = 5 slots and 4 bosses leave 25; the spawn cap and both wave waits use the slot count; boss nights read the ready crew).
PLAY TEST (DEV, owner's account, mock store; runtime-only TEMPTEST scripts):
- Real voyage path, solo (Standard voyage with night 1 made a boss night at runtime): `BigMonsterSpawned bearing=270 kind=ShipwreckHermit night=1 of=1`, one HUD boss row.
- 4 bosses (the crew-of-4 bearings 281/11/101/191) + small creatures to the cap: 4 bosses, 25 small spawned, 35 refused, 29 alive, slots 45/45; 4 HUD boss rows.
- Budget at that cap, 10 s, 1 client: snapshots **6.26 KB/s average, 6.75 KB/s max** (S4: 10.0 / 10.7 at 45 creatures; target ≤ 30); **59.9 FPS average, lowest 1 s 60** (S4: 60). Fewer creatures on screen than S4's 45 because bosses take 5 slots each.
- With 4 bosses during a real night 1 (1 + 3 added): 21 alive, slots 37; the undefended tower fell to the 4 bosses (expected on night 1 with one player).
- 0 script errors (server only ProfileStore's refused Studio write, API off; Roblox's own UIBlox warnings). Play stopped; 0 TEMPTEST scripts remain.
NOT MEASURED HERE: a real 4-client boss night (owner: Test → Clients and Servers → 4 players, sail, reach night 4, count 4 boss bars and note any lag); Script Analysis.
MIRROR: 114 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (a11900c7).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)
NEXT: S6.2 island merchant.

CHECKPOINT: S6.2 Island merchant — 🟦 (Shell-sink telemetry needs live voyages; Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S6.2_before_2026-10-17 (StatPipeline, Events, _Registry, NetGuard, Platform, TowerService, LampService, Encounter, Economy, EventLog, StatPipelineSpec, Trader) · restore point "S6.2 passed"
BUILT:
- `Shared/Definitions/Merchant` (new): Whetstone +10% weapon damage (50), Sea Legs Tonic +10% walk speed (40) (each twice a voyage, cap +20%), Kelp Poultice full heal (15), Oil Bundle +40 lamp fuel (30), Tower Shield half tower damage until dawn (60). Prices are D-019 (recommendation, flagged). `_Registry` checks the catalog at boot (40 definitions now).
- `Server/MerchantService` (new, `--!strict`): the rules (Day phase, crew, within 18 studs of the Trader, per-voyage limit, the effect must do something, crew Shells), a capped requestId replay map (a repeated request gets the first answer and spends nothing, even if an effect fails), boosts as capped AdditivePct layers, the shield until dawn, a wipe on VoyageStarted and VoyageEnded.
- Wiring: `MerchantRequest`/`MerchantResult` remotes (contract row, type guard, token bucket 5/8); weapon hits read the damage boost through `StatPipeline.weapon` (new `PlayerSpeed` stat row); walk speed re-applied on respawn and when the Keeper leaves the lamp; `TowerService` halves damage while the shield is up; `MerchantPurchase` event and `ShellsChanged` reason `merchant`; the run summary shows merchant Shells.
- Trader panel: an "Island stock" section by day with a BUY button per item, owned count (n/2), and the server's reason when it can't be bought.
TESTRUNNER (DEV): **162 passed, 0 failed** (152 + new `MerchantSpec` 10: the catalog passes the registry and an over-cap boost is refused; day/crew/range checks; Shells spent and refused; malformed requests ignored; a repeated requestId spends once; a failing effect still answers once; boosts stack to +20% and stop; heal/oil/shield refuse when useless; the shield drops at dawn; everything wiped at Results; wiring) + `NetGuardSpec` contract row.
PLAY TEST (DEV, owner's account, mock store; runtime-only TEMPTEST scripts; the Trader panel was opened by the server's own TraderOpen and purchases sent as the panel sends them):
- Day 1 with the real 120 starting Shells: Whetstone 120 → 70; the same requestId again answered "Bought Whetstone." with 70 left (no second purchase); Sea Legs Tonic → 30, walk speed 16 → 17.6; Kelp Poultice → 15, health 59 → 100; Oil Bundle refused "Need 30 Shells (the crew has 15)."; the panel showed "Whetstone (1/2)" and disabled the rows the crew could not afford with that reason.
- With 200 test Shells added: Oil Bundle fuel 0 → 40; Tower Shield on; a second shield refused; 10 damage took the shielded tower 100 → 95; after a dawn event the shield dropped and 10 damage took 95 → 85.
- A harpoon attack with one Whetstone hit for 8.8 (Driftwood Harpoon base 8, +10%).
- Crew left the island (Abandoned): every boost and count attribute cleared, walk speed back to 16, shield off. Run summary: "Shells spent: 195 (merchant 195)".
- A first run found a bug (a missing run counter made every successful purchase error after spending, so a repeated request bought again); fixed (counter added; the answer is now remembered even if an effect fails) and covered by a test before this run. 0 errors in the final run (server only ProfileStore's refused Studio write, API off; Roblox's own UIBlox warnings). Play stopped; 0 TEMPTEST scripts remain.
- The test's fake dawn event also ran dawn Pearl banking on the mock profile (memory store, nothing saved).
NOT MEASURED: the Shell sink (late-run Shell balance down ≥ 40% vs baseline) needs live voyages: compare `shellsLeft` and "merchant" in the run summaries before and after the publish. The panel's look was not checked on screen (Studio was not drawing frames during this run); its rows, texts and sizes were read back (5 rows 442×62 in a 485×535 sheet).
MIRROR: 117 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (35d04467).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015); prices D-019 flagged
NEXT: S6.3 Orbiting Blades (first sold by the merchant).

CHECKPOINT: S6.3 Orbiting Blades — 🟦 (a real phone check and Script Analysis are the owner's; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S6.3_before_2026-10-17 (Weapons, _Registry, Merchant, MerchantService, Economy, Encounter) · restore point "S6.3 passed"
BUILT:
- `Shared/Weapons`: every weapon now names its archetype (the four harpoons and the flare gun are `Thrown`); new `OrbitingBlades` (`Orbit`, `voyageOnly`): 3 blades on a 7-stud circle, a cut every 0.5 s for 4 damage to up to 3 creatures within 7 studs. Numbers and price: D-020 (recommendation, flagged). `_Registry` checks archetypes, blade fields, that only voyage-only weapons may skip an Items entry, and that a merchant weapon is a voyage-only Orbit weapon bought once (42 definitions at boot).
- `Server/OrbitService` (new, `--!strict`, Encounter domain): 10 times a second it finds each crew member carrying blades (server-set `OrbitWeapon` attribute, alive, not at the lamp) and makes the cuts that are due through `CreatureService.damageArea`, with numbers from `StatPipeline.weapon` (the merchant's damage boost applies). Kills count as `Weapon:OrbitingBlades`.
- `Client/OrbitView` (new): draws the blades around every carrier, 3 anchored non-colliding parts per carrier moved with one `BulkMoveTo` a frame; no input, no remotes, no lights.
- The island merchant sells Orbiting Blades first in its list, once a voyage, 80 Shells; wiped at Results with the rest.
TESTRUNNER (DEV, run in a Play server): **168 passed, 0 failed** (162 + new `OrbitSpec` 7: Orbit archetype and registry; merchant item once a voyage; a cut at once then every 0.5 s with the pipeline's numbers (19–20 cuts in 10 s); the damage boost applies (4.8); thrown weapons never cut; a carrier who drops out restarts; wiring and a view with no input and no remotes) + `MerchantSpec`. In Edit mode the run showed 3 stale failures because Studio keeps the pre-edit `Weapons` module cached in Edit; a fresh Play server ran clean, so from now on the checkpoint TestRunner runs in a Play server.
PLAY TEST (DEV, owner's account, mock store; runtime-only TEMPTEST scripts):
- Day 1, real 120 Shells: bought Orbiting Blades (120 → 40); a second purchase refused ("That's all the Orbiting Blades the Trader has for you this voyage."); the Trader sheet showed "Orbiting Blades (1/1) BOUGHT" (screenshot checked).
- The blades: 3 parts circling the player at 7.00 studs, moving every frame (screenshot checked, 46 FPS while drawing).
- 6 Rock Crabs spawned and the player was moved next to them with no attack input: all 6 killed in 11.8 s; run summary "Kills: 6 [Weapon:OrbitingBlades 6]", "Weapon attacks: 0".
- Crew left (Abandoned): `OrbitWeapon` cleared, 0 blades left on the client.
- 0 script errors (server only ProfileStore's refused Studio write, API off; Roblox's own UIBlox warnings). Play stopped; 0 TEMPTEST scripts remain.
NOT MEASURED HERE: a real phone (the blades need no input at all, so touch adds nothing to test, but the owner's phone check stands); Script Analysis.
MIRROR: 120 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (b735fa45).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015); numbers D-020 flagged
NEXT: S6.4 Quartermaster boosts and gear.

CHECKPOINT: S6.4 Quartermaster boosts & gear — 🟦 (Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S6.4_before_2026-10-17 (StatPipeline, Weapons, Items, _Registry, ProfileSchema, PlayerData, ShopService, LootService, Economy, Shop) · restore point "S6.4 passed"
BUILT:
- `Shared/Definitions/Boosts` (new): Shell Pouch (+2% Shells from loot a rank), Sea Boots (+1% walk speed), Sharpened Steel (+1% weapon damage), 5 ranks each for Pearls; all together capped at +15% (D-021). `_Registry` checks it at boot (50 definitions now).
- Profile: new field `Boosts` (id → rank), default `{}`; a save without it loads with `{}` and no repair; unknown ids and bad ranks are dropped; ranks over the cap come down. Still schema v2 (D-021).
- `ShopService` action `boost` (the next rank: cap, top rank, Pearls; the same replay map and range checks as buying gear); `ShopPurchase` event with `Boost:<id>`.
- Effects: Economy's `applyBoosts` adds the Quartermaster ranks to the merchant's (damage, walk speed) and sets `Boost_ShellGainPct`; `LootService` gives the collector that share of each Shell pickup (fractions round up by chance).
- Gear: Coral Lance, Tidecaller Blades (the permanent Orbit weapon: equipped, it gives no tool and OrbitService cuts with it), Kelpweave Vest; models in `ReplicatedStorage.ItemModels` built from the place's own models (`assets/ART_SOURCES.md`).
- Shop: a Boosts tab listing each boost with its rank, the next price, and the reason when it can't be bought.
- Bug fix D-022: saved timestamps were reset to 0 on every load (CreatedAt/LastSeenAt over the 1e9 count ceiling).
TESTRUNNER (DEV, Play server): **177 passed, 0 failed** (168 + new `BoostsSpec` 9: registry clean with the new gear; the cap test (5 Shell Pouch + 5 Sea Boots = +15%, then Sharpened Steel refused "Your boosts together are at the +15% limit."); the migration fixture (a v2 save from before S6.4 loads with `Boosts = {}`, no repairs, every other field identical); a v1 save gets `{}`; bad and over-cap ranks repaired; real timestamps survive (D-022); the new gear; wiring) + `OrbitSpec` updated for the second Orbit weapon.
PLAY TEST (DEV, owner's account, mock store; runtime-only TEMPTEST scripts; 400 + 300 test Pearls granted on the mock profile):
- Quartermaster opened through its prompt; the Boosts tab clicked with the mouse: Shell Pouch bought 5 times and Sea Boots 5 times by clicking BUY (400 → 70 Pearls); Sharpened Steel then showed "AT THE LIMIT" with the cap message (screenshots checked). Server: `Boosts` SeaBoots 5, ShellPouch 5; attributes Shell gain 0.10, speed boost 0.05; walk speed 16.8.
- Bought and equipped Tidecaller Blades and Kelpweave Vest: no tool in the backpack, `OrbitWeapon = TidecallerBlades`, 3 blades drawn, max health 160, armor "Kelpweave Vest" (screenshot checked).
- Voyage: 20 kills by Tidecaller Blades with no attack input ("Kills: 20 [Weapon:TidecallerBlades 20]"); with the Shell gain pinned to 100% for the test, every Shell pickup came in doubled (6, 8, 6, 10).
- 0 script errors (server only ProfileStore's refused Studio write, API off; Roblox's own UIBlox warnings). The real player's load no longer logs a CreatedAt repair. Play stopped; 0 TEMPTEST scripts remain.
MIRROR: 123 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (d6904beb). The 3 new item models live in the place (not in the script mirror).
OWNER: please save `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_S6-4_2026-10-17.rbxl` from the DEV window when convenient (the item models are only in the place file). Optional: add `Boosts` to architecture §6.1.
OWNER APPROVAL: auto-approved (unattended, D-010/D-015); numbers and the profile field D-021, bug fix D-022 flagged
NEXT: S6.5 new monsters ×3 (Spitter Eel, Puffer Mine, Ghost Lantern).

CHECKPOINT: S6.5 New monsters ×3 — 🟦 (the blind test is the owner's/a tester's; Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S6.5_before_2026-10-17 (Creatures, _Registry, CreatureSnapshot, SoundFx, WaveDirector, GameState, LootService, CreatureService, BossesByCrewSpec, RegistrySpec, CreatureView) · restore point "S6.5 passed"
BUILT:
- `Shared/Creatures`: Spitter Eel, Puffer Mine, Ghost Lantern with a `behaviour`, a telegraph, two sounds each, a loot table and an `appears` schedule (D-023). `_Registry` checks them (telegraph at least 0.6 s, the move's numbers, schedule, loot rows); 53 definitions at boot.
- `CreatureService`: telegraphed moves: an eel marks the spot (a green ring) and spits 0.8 s later; a puffer lights a 1 s fuse near a player or the tower and bursts; a lantern drains the lamp at the tower after a 0.9 s glow and ignores weapons and cannons. While telegraphing a monster stands still and the snapshot sends TELEGRAPH (both target bits; no protocol change).
- `CreatureView`: the telegraph is drawn (the body pulses pale, the eyes go pale, a puffer swells over its fuse); each kind keeps its own colour.
- `WaveDirector.specials` + `GameState`: the special monsters join their nights on the schedule, inside the 45-slot cap; `LootService` rolls each monster's loot table.
TESTRUNNER (DEV, Play server): **182 passed, 0 failed** (177 + new `MonstersSpec` 6: registry clean; telegraph ≥ 0.6 s with its own sounds; loot sums to 1; the night schedule (night 1 none … night 13 eels 4, puffers 5, lanterns 3); TELEGRAPH round trip; wiring) + `BossesByCrewSpec` (3 spawn streams) and `RegistrySpec` (loot rows now name their drops).
PLAY TEST (DEV, owner's account, mock store; runtime-only TEMPTEST scripts):
- Spitter Eel vs a player standing still: 6 rings, all on the player; 5 spits landed, 60 damage (12 each). Stepping 9 studs away when a ring appeared: 5 rings, 1 hit (likely a spit already in flight from the standing phase).
- Puffer Mine reaching a standing player: burst after the fuse, player 100 → 70; a puffer shot before it got close dropped a loot orb.
- Ghost Lantern: a weapon hit at it hit nothing (it stayed); at the tower it drank the lamp 60 → 54.
- Telegraphs measured on the client from snapshots (1/12 s steps): eel 0.75–0.92 s (11), puffer 1.00 s (1), lantern 0.83–1.00 s (8); all ≥ 0.6.
- Budget: 4 eels + 5 puffers + 3 lanterns + 33 small creatures (45): **9.59 KB/s average, 10.41 max**, **59.9 FPS, lowest 1 s 60** (S4: 10.0 KB/s, 60 FPS). Screenshot checked (lanterns glowing, eel, puffer, a spit ring).
- First runs found the eels only ever spat at the tower; fixed (an eel picks on a player within its range). Noticed, not changed (D-023): crab proximity threat never builds up, so crabs only chase players who hit them.
- 0 script errors (server only ProfileStore's refused Studio write, API off; Roblox's own UIBlox warnings). Play stopped; 0 TEMPTEST scripts remain.
NOT TESTED HERE: the blind test (a tester names each monster's behaviour); a beam kill of a Ghost Lantern (the beam path is unchanged and applies double damage by `beamDamageMult`); the night schedule live (unit-tested; the test voyages stayed on day 1).
MIRROR: 124 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (f0ccde62).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015); numbers D-023 flagged
NEXT: S6.6 new monsters ×2 (Tide Witch, Coral Shaman).

CHECKPOINT: S6.6 New monsters ×2 — 🟦 (the blind test is the owner's/a tester's; Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S6.6_before_2026-10-17 (Creatures, _Registry, SoundFx, CreatureService, MonstersSpec) · restore point "S6.6 passed"
BUILT:
- `Shared/Creatures`: Tide Witch (`summoner`) and Coral Shaman (`healer`), each with a telegraph, two sounds, a loot table, an `appears` schedule and a plain-part body (D-024); `ignoresPlayers` replaces the Ghost Lantern special case. `_Registry` checks the summoned kind (small, not a summoner), the summon count, the heal radius and share (55 definitions at boot).
- `CreatureService`: the witch's chant ends in 3 Sand Skitters climbing out beside her (inside the 45-slot cap); the shaman's chime ends in +30% health for small creatures within 14 studs.
TESTRUNNER (DEV, Play server): **182 passed, 0 failed** (`MonstersSpec` now covers all five monsters: registry, telegraph ≥ 0.6 s with unique sounds, loot, the night schedule up to night 13 with witches and shamans).
PLAY TEST (DEV, owner's account, mock store; runtime-only TEMPTEST scripts):
- Tide Witch alone: creature count every 2 s 1,1,…,1 (walking in), then 4, then 7: three skitters each chant, every 7 s.
- Coral Shaman with 5 Rock Crabs at the tower knocked to 50%: the 3 crabs within its reach went 0.50 → 0.80 → 1.00 over two chimes; the 2 out of reach stayed at 0.50.
- Telegraphs measured on the client: witch 0.99–1.08 s (6), shaman 0.75–0.83 s (6).
- Budget: 2 witches + 2 shamans + 4 eels + 5 puffers + 3 lanterns + small creatures to 45: **9.59 KB/s average, 10.41 max, 60.0 FPS, lowest 1 s 60** (screenshot checked).
- 0 script errors (server only ProfileStore's refused Studio write, API off; Roblox's own UIBlox warnings). Play stopped; 0 TEMPTEST scripts remain.
NOT TESTED HERE: the blind test; the night schedule live (unit-tested).
MIRROR: 124 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (9f61386e).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015); numbers D-024 flagged
NEXT: S6.7 publish package (owner), then S7.1 Logbook.

=====================================================================
S6.7 — READY FOR OWNER TO PUBLISH (DEV experience only)
=====================================================================
What is in this build (since the S5.8 package): S6.1–S6.6, the owner's six requests. Boss nights bring one big monster per crew member; the Trader sells voyage-only items by day (boosts, heal, oil, tower shield, Orbiting Blades); the Quartermaster sells permanent boosts (capped at +15% together), the Coral Lance, Tidecaller Blades and the Kelpweave Vest; five new monsters arrive from night 2 on (Spitter Eel, Puffer Mine, Ghost Lantern, Tide Witch, Coral Shaman), each warning before its move. Also a save fix: saved timestamps no longer reset on every join (D-022). If S2.8, S4.7 or S5.8 were not published yet, this one package covers them all: publish once.
New numbers to review (all recommendations, logged): D-019 merchant prices, D-020 Orbiting Blades, D-021 boosts and gear, D-023 and D-024 monsters.
S6 exit: all six requests are Tested in `docs/SYSTEM_REGISTRY.md` ✓ · TestRunner 182 · Script Analysis warnings: not measured (owner item).
Before publishing:
 1. In the DEV Studio window: File → Save to File As → `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_S6_2026-10-17.rbxl` (the new item models live only in the place file).
 2. Game Settings → Security → "Enable Studio Access to API Services" stays OFF.
 3. Optional, 1 minute: View → Script Analysis, tick "Show warnings", note the warning count for `ServerScriptService.Server` and `StarterPlayerScripts.Client`.
Publish:
 4. File → Publish to Roblox (DEV experience, PlaceId 102473202766620; production is not touched).
 5. Creator Hub → Lighthouse Keepers DEV → Servers → Shut down all servers.
Live checks (Prototype B session, about 30 minutes, with friends if you can):
 6. Quartermaster: the Boosts tab shows three boosts and stops at +15%; the Coral Lance, Tidecaller Blades and Kelpweave Vest are on the shelves.
 7. A voyage to night 4 or further: on day 1 the Trader sheet lists the island stock; buy something and see it work; from night 2 an eel's green ring shows where it will spit; from night 3 puffers swell before they burst; night 4 is a boss night (one boss per crew member) and the first Tide Witch.
 8. With 2–4 players: the number of bosses on a boss night matches the crew.
 9. Play again after Results (the S6 pass mark is rematch ≥ 60% of crews; the Results screen's "Sail again" count is in the run summaries).
 10. Tell Claude: anything confusing or broken, whether each new monster's move was clear without being told (that is the blind test for S6.5/S6.6), phone FPS on the busiest night, and the Script Analysis count.
If something is wrong: Creator Hub → DEV place → Version History → restore the previous version, then Shut down all servers.
Claude's state: S6.7 set to 🟦; work continues with S7.1 (Logbook).

CHECKPOINT: S7.1 Logbook — 🟦 (Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S7.1_before_2026-10-17 (Events, _Registry, LiveOps) · restore point "S7.1 passed"
BUILT:
- `Shared/Definitions/Logbook` (new): four categories (Creatures, Big monsters, Evolutions, Forecasts) and their Pearls (D-025); the entries come from the creature, upgrade and forecast catalogs, so new monsters join automatically (7 creatures, 2 big monsters, 2 evolutions, 3 forecasts today). `_Registry` checks it (59 definitions at boot).
- `Server/LogbookService` (new, `--!strict`, LiveOps domain): hears CreatureKilled, BossDefeated, EvolutionUnlocked and NightSurvived on the bus; marks the profile's `Logbook`; publishes `LogbookDiscovered`; tells the player "New in your logbook: …"; pays a finished category once through GrantService.
- The LiveOps domain now starts it (its first job).
TESTRUNNER (DEV, Play server): **187 passed, 0 failed** (182 + new `LogbookSpec` 5: entries from the catalogs, registry clean; discover once and the last one finishes the category; kills fill both crew members' logbooks and the category pays once each even when the kills repeat; a big monster's kill is a boss entry, not a creature; evolutions and survived forecasts; wiring).
PLAY TEST (DEV, owner's account, mock store; runtime-only TEMPTEST scripts): during a voyage, one of each small creature was killed (the Ghost Lantern's kill put on the bus as the beam would, since weapons pass through it): the logbook held all 7 creature entries and Pearls went 0 → 15 (`Grant claim=logbook:Creatures:7 pearls=15`); two more Rock Crab kills changed nothing (7 entries, 15 Pearls). 0 script errors. Play stopped; 0 TEMPTEST scripts remain.
NOT BUILT: a logbook page to browse the entries (notices only for now; flagged in D-025).
MIRROR: 127 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (856025b8).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015); rewards D-025 flagged
NEXT: S7.2 Daily objective.

CHECKPOINT: S7.2 Daily objective — 🟦 (Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S7.2_before_2026-10-17 (Events, _Registry, LiveOps) · restore point "S7.2 passed"
BUILT:
- `Shared/Definitions/Objectives` (new): five objectives (D-026), `dayKey` (UTC), `pick` (the same all day for an account), `rollOver` (a new day starts a fresh objective and resets only today's progress), `count`. `_Registry` checks it (64 definitions at boot).
- `Server/ObjectiveService` (new, `--!strict`, LiveOps domain): counts the player's own Refuelled, NightSurvived, CannonBuilt, TowerRepaired and CreatureKilled events; pays once through GrantService; publishes `ObjectiveCompleted`; a join notice "Today's objective: …"; player attributes ObjectiveText / Progress / Target / Done.
- The `ObjectiveClaim` remote in API_CONTRACTS is not built: the reward pays itself (D-026).
TESTRUNNER (DEV, Play server): **193 passed, 0 failed** (187 + new `ObjectivesSpec` 6: registry clean; one objective a day from the pool, the same all day, at least 3 different ones over 30 days; counts its own event and finishes once at 10/10; "survive night 4" counts the night reached; **a missed day changes nothing**: with the clock moved 3 days on, the state holds only DayKey, Progress and Claimed (no streak or missed-day counter), progress starts fresh and the objective is exactly what a player without the gap would get; the service pays once with the claim `objective:2025-10-17:RepairTower` after 7 repairs; wiring).
PLAY TEST (DEV, owner's account, mock store; runtime-only TEMPTEST scripts): today's objective on the real account was "Defeat 40 creatures" (0/40 on the player attributes); 45 Sand Skitters killed by the player during a voyage: 40/40, done, Pearls 0 → 3 once (`Grant claim=objective:2026-10-17:DefeatCreatures pearls=3`). 0 script errors. Play stopped; 0 TEMPTEST scripts remain.
NOT BUILT: a HUD line or menu card for the objective (attributes and notices only).
MIRROR: 130 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (8e42701f).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015); pool and rewards D-026 flagged
NEXT: S7.3 Leaderboards.

CHECKPOINT: S7.3 Leaderboards — 🟦 (the live ordered data stores can only be checked after the owner publishes DEV; Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S7.3_before_2026-10-17 (LobbyBuilder, LiveOps, _Registry) · restore point "S7.3 passed"
BUILT:
- `Shared/Definitions/Leaderboards` (new): three boards, top 10, a 30 s flush, `weekIndex` (weeks start Monday 00:00 UTC) and `storeName` (the weekly board's store name carries the week). `_Registry` checks it.
- `Server/LeaderboardService` (new, `--!strict`, LiveOps domain): NightSurvived raises each crew member's best night on the voyage being sailed and adds a night to their week; every 30 s it writes what is pending and re-reads every board.
- LiveOps: ordered data stores in live servers (UpdateAsync keeps the higher night, IncrementAsync adds nights, GetSortedAsync reads the top 10, all in pcall), an in-memory store in Studio, display names cached.
- LobbyBuilder: a wooden board with three columns across the path from the Quartermaster's stall (D-027).
TESTRUNNER (DEV, Play server): **197 passed, 0 failed** (193 + new `LeaderboardsSpec` 4: registry clean; the weekly store name holds from Monday 00:00 to Sunday 23:59:59 and changes on the next Monday; a survived night shows only after the flush and the flush runs at least every 30 s; a lower night never lowers a best; a new week starts the weekly board empty while best nights stay; wiring).
PLAY TEST (DEV, owner's account; Studio memory store; runtime-only TEMPTEST script): a survived night put on the bus for the player showed on the harbor board **19.7 s** later ("Best night: Standard 1. Lighthouse8282 3", "Nights this week 1. Lighthouse8282 1", Long "No one yet. Be the first!"); the board was seen in a screenshot. 0 script errors. Play stopped; 0 TEMPTEST scripts remain.
NOT TESTED HERE: the live ordered data stores (Studio never writes them). After publishing DEV: survive a night, wait a minute, and check the board on the harbor island; on Monday 00:00 UTC the weekly column should start empty.
MIRROR: 133 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (1a7cc08d).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015); D-027 flagged
NEXT: S7.4 Specialties.

CHECKPOINT: S7.4 Specialties — 🟦 (Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S7.4_before_2026-10-17 (ProfileSchema, Economy, CreatureService, TowerService, LiveOps, _Registry, BoostsSpec) · restore point "S7.4 passed"
BUILT:
- `Shared/Definitions/Specialties` (new): Keeper, Harpooner, Oiler, Engineer with thresholds, +2% a rank and the +15% total cap (D-028); `rankFor`, `ranks` (cap applied), `bonus`. `_Registry` checks it.
- `Server/SpecialtyService` (new, `--!strict`, LiveOps domain): beam kills, weapon kills, oil delivered, repairs and cannons built from the bus → the profile's `Roles` counters → ranks in `Unlocks.Specialties`; a new rank is told to the player and pushes the profile (counting alone does not).
- Profile: new field `Roles` (default {}, silent for older saves; bad counts dropped).
- Bonuses: Harpooner and Oiler join the weapon-damage and walk-speed layers in Economy's applyBoosts; Keeper raises the beam's damage while that player keeps the lamp (CreatureService); Engineer raises that player's repairs (TowerService).
TESTRUNNER (DEV, Play server): **202 passed, 0 failed** (197 + new `SpecialtiesSpec` 5: registry clean; ranks follow the thresholds; **cap test**: every role maxed gives Keeper 3, Harpooner 3, Oiler 1, Engineer 0 = +14% ≤ +15%; **unlock from stats only**: 24 deliveries give nothing, the 25th gives Oiler rank 1 (one profile push), cannon kills do not count, and no other server module writes `Unlocks.Specialties` or the `Roles` counters; older saves get `Roles = {}` with no repair; wiring) + `BoostsSpec` updated for the new field.
PLAY TEST (DEV, owner's account, mock store; runtime-only TEMPTEST script): 50 kills with a harpoon by the player: `Roles.WeaponKills = 50`, Harpooner rank 1, the player's weapon-damage boost 0.02. 0 script errors. Play stopped; 0 TEMPTEST scripts remain.
MIRROR: 136 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (d7de9898).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015); D-028 flagged
NEXT: S7.5 Invite reward.

CHECKPOINT: S7.5 Invite reward — 🟦 (a real invite needs two accounts and the published DEV; Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.S7.5_before_2026-10-17 (Items, _Registry, LiveOps) · restore point "S7.5 passed"
BUILT:
- `Shared/Items`: Shared Lantern beam colour (`BeamSharedLantern`, `reward = "invite"`, no price); `_Registry` allows earned items without a price and refuses a price on them (72 definitions at boot).
- `Server/InviteService` (new, `--!strict`, LiveOps domain): at the end of a voyage that reached night 1, each crew member who joined from another crew member's invite and that inviter get the Shared Lantern through GrantService, claim `invite:<lower>:<higher>`, with a notice.
- LiveOps reads each joining player's `ReferredByPlayerId` from the join data.
TESTRUNNER (DEV, Play server): **207 passed, 0 failed** (202 + new `InviteSpec` 5: the item is earned, never sold, registry clean; three shared voyages give both players the item once and two notices in total (the claim is idempotent; the third crew member gets nothing); the inviter must be in the crew and the voyage must reach night 1; the claim id is the same for either order; wiring).
PLAY TEST (DEV): boot clean with the new item and service ("Definitions checked=72"; the only errors are the expected refused Studio data-store calls with API access off). A real invite cannot be made in Studio.
OWNER CHECK (after publishing DEV): invite a friend from the crew card or Results, sail together past night 1, and both of you should see the notice and find "Shared Lantern" under Cosmetics in the BAG.
MIRROR: 138 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (36f9ca1b).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015); D-029 flagged
NEXT: S7.6 publish package.

=====================================================================
S7.6 — READY FOR OWNER TO PUBLISH (DEV experience only)
=====================================================================
What is in this build (since the S6.7 package): S7.1–S7.5, the return systems. A logbook fills itself as you defeat monsters, bring down big monsters, forge evolutions and survive forecasts (Pearls for each finished category); one daily objective per player (a few Pearls, no streaks); a leaderboard board on the harbor island (best night Standard and Long, nights this week); specialties earned by playing a role (Keeper, Harpooner, Oiler, Engineer; small bonuses, +15% together at most); the Shared Lantern beam colour for you and a friend you invited after a voyage together. If S2.8, S4.7, S5.8 or S6.7 were not published yet, this one package covers them all: publish once.
New numbers to review (recommendations, logged): D-025 logbook rewards, D-026 daily objectives, D-027 leaderboards, D-028 specialties, D-029 invite reward.
Before publishing:
 1. In the DEV Studio window: File → Save to File As → `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_S7_2026-10-17.rbxl`.
 2. Game Settings → Security → "Enable Studio Access to API Services" stays OFF. (Live servers use data stores without that setting.)
 3. Optional: View → Script Analysis, note the warning counts for `ServerScriptService.Server` and `StarterPlayerScripts.Client`.
Publish:
 4. File → Publish to Roblox (DEV experience, PlaceId 102473202766620; production is not touched).
 5. Creator Hub → Lighthouse Keepers DEV → Servers → Shut down all servers.
Live checks (about 20 minutes):
 6. Join: a notice tells you today's objective; the harbor board stands across the path from the Quartermaster.
 7. Sail and survive a night: within a minute the board shows your best night and your nights this week; you hear "New in your logbook: …" for new monsters.
 8. With a friend: send an invite, sail together past night 1, both get the Shared Lantern.
 9. Tell Claude: anything that looks wrong, the objective you got and whether it paid, and the board after a night.
If something is wrong: Creator Hub → DEV place → Version History → restore the previous version, then Shut down all servers.
Claude's state: S7.6 set to 🟦; work continues with B1 (closed beta preparation): B1.1 cosmetics as definitions (nothing sold or enabled), B1.3 the anti-exploit suite, B1.4 a 1-client soak.

CHECKPOINT: B1.1 Cosmetics pipeline — 🟦 (creating the developer products is the owner's step; Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.B1.1_before_2026-10-17 (_Registry) · restore point "B1.1 passed"
BUILT:
- `Shared/Definitions/Cosmetics` (new, `--!strict`): `ROBUX_ENABLED = false`; slots Beam (the 5 existing beam colours in `Shared/Items`), Housing, Coat, Lantern, Flag; 9 new items with a Pearl price, a suggested Robux price and `productId = 0`.
- `_Registry`: the Cosmetics catalogue is checked at boot (81 definitions). Only look and price fields are allowed on a cosmetic, so a stat, a power or a rank fails the boot; `ROBUX_ENABLED` must be false; every beam named must be a beam colour in Items.
- No code prompts or processes a Robux purchase (no MarketplaceService anywhere; a test checks this). Wearing the new slots is not drawn yet.
TESTRUNNER (DEV, Play server): **212 passed, 0 failed** (207 + new `CosmeticsSpec` 5: catalogue passes the registry and covers every slot; every Robux item but the supporter flag is also earnable; a coat given damage and health fails the boot with 2 problems; `ROBUX_ENABLED = true` fails the boot; no game script uses MarketplaceService or ProcessReceipt).
PLAY TEST (DEV): boot clean ("Definitions checked=81"; the only errors are the expected refused Studio data-store calls with API access off).
PRODUCTS (suggested; the owner creates them, nothing is enabled):
| Item | Slot | Pearls | Robux |
|---|---|---|---|
| Driftwood Housing | Housing | 40 | 49 |
| Polished Brass Housing | Housing | 80 | 99 |
| Storm Blue Coat | Coat | 50 | 59 |
| Kelp Green Coat | Coat | 50 | 59 |
| Moth Lantern | Lantern | 60 | 75 |
| Tide Lantern | Lantern | 60 | 75 |
| Gull Flag | Flag | 30 | 39 |
| Kraken Flag | Flag | 90 | 99 |
| Founder's Flag (supporter) | Flag | — | 149 |
FAIRNESS TEST (architecture §20, re-answered):
- Non-payers reach every goal: yes. Every Robux item is a look; every one except the Founder's Flag is also earnable with Pearls; no goal, voyage, weapon, armor, upgrade, boost or specialty can be bought.
- No PvP: yes. Nothing a player buys touches another player.
- Parent over the shoulder: yes. Fixed prices, no random paid crates, no timers, no paid revives, nothing pushes a purchase (nothing is even shown for sale yet).
- Odds: not applicable (nothing random is sold).
- Enforced by construction: `_Registry` refuses a stat field on a cosmetic and refuses `ROBUX_ENABLED = true`; `CosmeticsSpec` keeps both true.
OWNER STEPS (when you want them; nothing is switched on): Creator Hub → Lighthouse Keepers DEV → Monetization → Developer Products → create one product per row above at the Robux price you choose, then send Claude the product ids. They stay unused until you approve L1.3.
MIRROR: 140 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (51232cad).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015); D-030 flagged
NEXT: B1.2 age rating is the owner's (questionnaire in Creator Hub); B1.3 anti-exploit suite.

CHECKPOINT: B1.3 Anti-exploit suite — 🟦 (Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.B1.3_before_2026-10-17 (Crew, Data, Economy, Encounter, Telemetry, LampService, LoadoutService, PlayerData, ShopService, NetGuard, MerchantSpec) · restore point "B1.3 passed"
BUILT:
- `NetGuard.connect(remote, handler)` / `NetGuard.expose(name, fn)`: all 18 client→server handlers connect through it (18 call sites changed from `OnServerEvent:Connect`, nothing else in them). In Studio only, each handler is also a BindableFunction `ServerStorage.NetHooks.<Remote>`; the Data domain adds `NetHooks._Profile` (a read-only JSON copy of a profile). Live servers never create these (D-031).
- `Tests/integration/SecuritySpec` (new, 6 tests, run in a Play server against the live handlers as the real harbor player or a fake non-owner):
  1. every contract remote has a live hook and nothing in ServerScriptService connects `OnServerEvent`/`OnServerInvoke` around NetGuard;
  2. invalid IDs (unknown items/upgrades/voyages/forecasts/prompts/shifts, the invite-only Shared Lantern, a negative quantity, a table for an id, a 500-character request id, an item not owned, a merchant quantity of 1e9): each reaches the decision (Allowed counters rise) and the profile, crew Shells, upgrade ranks, voyage choice and Ready are unchanged;
  3. non-finite vectors and numbers (NaN, ±inf aims; NaN/±inf beam angles; a NaN admin target) are dropped before the rate limit (Allowed counters unchanged) and nothing changes;
  4. non-crew Shell spend: a harbor player's bench upgrade is refused ("Only the voyage crew can spend the crew's Shells.", logged) and the merchant refuses; Shells and ranks unchanged;
  5. admin probing: a non-owner's grant, rollback and inspect on the owner's account are refused and logged (`AdminRejected`); Pearls unchanged;
  6. 50× spam on every remote: accepted ≤ burst + refill on each, and the profile is unchanged.
TESTRUNNER (DEV, Play server): **218 passed, 0 failed** (212 + `SecuritySpec` 6; `MerchantSpec` wiring check follows the new form).
NUMBERS (NetGuard counters after the suite, real player): Attack 10 accepted / 40 limited (burst 10); ShopRequest 12 / 42 (8 + 4 decided invalid-ID requests); LoadoutRequest 11 / 42; MerchantRequest 10 / 42; BuyUpgrade 7 / 45; AdminRequest 6 / 48; CoachEvent 9 / 42; LampShift 7 / 44; ForecastVote 6 / 45; ChooseVoyage 5 / 47; SetReady 3 / 47; VoteRematch 3 / 47; EnterLobby 2 / 48; GearAction 7 / 46 (includes the client's own syncs). BeamControl, LampAction (not Keeper), TraderRequest (unknown action) and ReportDevice (already reported) are dropped before the bucket, so they count 0.
PLAY TEST (DEV): boot clean, 0 errors (only the expected refused Studio data-store calls with API access off, and the test's own warnings: `[AdminDataService] refused …`, the MerchantSpec's deliberate "telemetry broke").
MIRROR: 141 scripts in DEV, digest of all FNV-1a hashes identical to `src/` (06b583ca).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015); D-031 logged
NEXT: B1.4 soak (1 client in Studio; 4 clients and 2 real phones are the owner's).

CHECKPOINT: B1.4 Soak — 🟦 (1 client in Studio; the 4-client run, 2 real phones and a live server's memory graph are the owner's; Script Analysis unmeasured)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before every Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.B1.4_before_2026-10-17 (CreatureView) · restore point "B1.4 passed"
RUN 1 (runtime-only TEMPTEST driver: keep-alive lamp and tower, Sail again on Results, Long Voyage chosen for voyages 2 and 4): **5 voyages, all won (Standard 7, Long 13, Standard 7, Long 13, Standard 7), 102.3 min, 22 big monsters, up to 50 creature slots, 0 server errors, 0 client errors.** Studio's client was not drawing (the screen had gone to sleep: 0 RenderStepped frames), and the run exposed a bug: **CreatureView removed gone creatures only on RenderStepped, so a client that is not drawing (a minimised window, a phone app in the background) kept every creature model of the voyage (+3,132 client instances in one voyage; 2,348 models left in the folder after 5 voyages).** They would all be removed at once when drawing resumed (checked: 0 orphans), but memory grew meanwhile.
FIX: `CreatureView.client` also removes gone creatures on Heartbeat (drawing stays on RenderStepped). No number changed.
RUN 2 (same driver, display kept awake, client drawing at 60 FPS, with the fix): **5 voyages, all won, 102.3 min, 22 big monsters, up to 50 slots, 0 server errors, 0 client errors**; creature folder empty between voyages; client instances 8,294 at the end (run 1: 31,969).
MEASURED (run 2; Studio runs Edit, server and client in one process, so memory is whole-Studio):
- Total process memory 3340 → 3488 MB: +87 MB/h overall; +65 MB/h after a 33 MB step at minute 12; +48 MB/h over the last 30 minutes. Lua heap 952 → 925 MB (−27). Server instances flat (4,547 → 4,550 over a further voyage). The growth is in the engine's `Internal` memory, which Studio does not split by data model, so the budget (< 50 MB/h on a server) cannot be confirmed in Studio: it stays 🟦 for a live server's memory graph.
- Server send (`Stats.DataSendKbps`, all traffic, 1 client): 7–16 KB/s per-minute averages, 56.7 peak (budget ≤ 30 per player is for snapshot bytes; S6.5 measured 9.6 at the cap).
- `Stats.HeartbeatTimeMs` max 0.55 ms; server physics 60 FPS throughout.
TESTRUNNER (DEV, Play server): **226 passed, 0 failed** (218 + `EconomySimSpec` 5 + `DataAuditSpec` 3; see L1.1/L1.2).
OWNER CHECKS: (1) Studio → Test → Clients and Servers → 4 players, sail one voyage, note errors; (2) two phones in the published DEV game, read FPS on a night-7 swarm (Settings → Performance Stats); (3) after publishing DEV: Creator Hub → Lighthouse Keepers DEV → Analytics → Performance → Server memory over a 2-hour session with players.
MIRROR: 145 scripts in DEV, digest identical to `src/` (02d33a36; includes L1.1/L1.2).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)

CHECKPOINT: B1.5 Cohort — 🟦 (owner's step)
OWNER STEPS: after publishing DEV (S7.6 package), invite 30–100 testers (friends, a Discord, a Roblox group); collect feedback with a short form (what was confusing, what was fun, any bug); Claude triages the bug list daily once it exists.

CHECKPOINT: B1.6 GO/NO-GO — taken provisionally (D-032), per the owner's standing instruction to keep going through gates. No beta data. Known blocking bugs: none.

CHECKPOINT: L1.1 Economy balance — passed in Studio (🟦 real beta data)
BUILT: `ServerStorage/Tests/sim/EconomySim` (pure model reading the live Config, Voyages, Items, Boosts, Logbook and Objectives) and `EconomySimSpec` (5 tests: every GrantService source in the game is known to the model; no Material sells for Pearls and nothing pays per kill; nothing pays per kill (checked separately); one voyage's bound is nights + victory bonus + one max boss drop per boss (Standard solo 20, Long with 4 crew 146); 2,000 simulated voyages never pass their bound; boost ranks stop at the +15 % cap).
MODEL ASSUMPTIONS (no beta data yet): crew of 1/2/3/4 at 40/30/20/10 %; the light goes out on night n with chance 0.04 + 0.015·n (about 1 Standard voyage in 3 is won); once the Long Voyage is unlocked, half the voyages are Long; 3 voyages a day; the daily objective done 80 % of days.
10,000 VOYAGES (execute_luau, three seeds): **mean 10.7–10.9 Pearls a voyage, median 9–10, p95 27–28, highest 50 (bound 146), 0 voyages over their bound**; logbook one-time Pearls 40; objectives about 0.85 a voyage. Live catalogue: 538 Pearls (gear and beam colours) + 320 (boost ranks to the cap) = 858, affordable after **62–83 voyages** (about 3–4 weeks at 3 a day); a crew that never loses: mean 22.4, after 33 voyages; solo: mean 10.8, after 79.
DECISION: D-033, no change before beta data.

CHECKPOINT: L1.2 Data audit — passed
BUILT: fixture `profiles/v2_full_B1` (every field at B1, made-up values) and `DataAuditSpec` (3 tests: all 6 fixture saves (4 v1 shapes: full, missing fields, string Pearls, unknown fields; v2 before S6.4; v2 full at B1) load to a valid profile with every current field, load again with no fix, and survive a JSON round trip; the full B1 profile loads with no fixes and keeps Boosts, Roles, Unlocks and Equipped; older saves keep Pearls, items and stats). Rollback drill: `AdminDataSpec` online and offline rollback restore the snapshot (green in the same run).
TESTRUNNER: 226 passed, 0 failed.

CHECKPOINT: L1.3 Monetization — 🟦 WAITS FOR THE OWNER (nothing enabled)
What is ready: the cosmetics list with suggested Robux prices (B1.1 record); the registry refuses a stat on any cosmetic and refuses `ROBUX_ENABLED = true`; no code prompts or processes a purchase.
What L1.3 would build once you approve: `PurchaseService` with an idempotent `ProcessReceipt` (each receipt id granted once through GrantService), the cosmetic products and a supporter pack wired to your product ids, wearing the new cosmetic slots, test purchases in Studio. Say "approve L1.3" (and send the product ids) to start it.

CHECKPOINT: L1.4 Codes — 🟦 (Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.L1.4_before_2026-10-17 (Items, Cosmetics, _Registry, Platform, NetGuard, LiveOps, NetGuardSpec, SecuritySpec, EconomySim, Menus) · restore point "L1.4 passed"
BUILT:
- `Shared/Definitions/Codes` (new): LIGHTHOUSE (promo, 10 Pearls) and KEEPER (creator template: the Keeper's Glow beam colour). `_Registry` checks codes at boot (84 definitions): capital letters and digits ≤ 32, no code twice, promo Pearls 1–25, creator codes give one cosmetic and nothing else, an end date if any.
- `Shared/Items`: Keeper's Glow beam colour (`reward = "code"`, no price); the registry allows `reward = "code"`.
- `Server/CodeService` (new, `--!strict`): normalise (case and spaces), find, check expiry, profile loaded, `RedeemedCodes`; grant through GrantService (claim `code:<CODE>`), then write `RedeemedCodes` (kept forever, unlike the 30-day claims). A claim already granted is not paid twice.
- Remotes `CodeRedeem` (NetGuard 0.1/1: one per 10 s) and `CodeResult`, connected in the LiveOps domain through `NetGuard.connect`; `SecuritySpec` spams it with the others.
- Settings → Codes: a code box and a Redeem button; the answer shows as a notice.
- `EconomySim` knows the new Pearl source (`code`, finite).
TESTRUNNER (DEV, Play server): **234 passed, 0 failed** (226 + `CodesSpec` 8: promo pays once whatever the case and spaces; still once after the claim prune; a claim granted before a crash is not paid twice; the creator code gives its beam colour; bad, unknown, too-long, not-loaded and expired codes change nothing; the catalogue passes the registry and a creator code giving a harpoon and Pearls, a lowercase code with 500 Pearls and a duplicate code all fail; the beam colour is never sold; LiveOps wiring and the contract rate).
PLAY TEST (DEV, the title route forced for the test with a `--TEMPTEST` Config value, reverted and checked: 0 TEMPTEST scripts left): Title → Settings → Codes; typed "lighthouse", clicked Redeem: `Grant claim=code:LIGHTHOUSE pearls=10 … source=code total=10`, `CodeRedeemed`; 10 s later Redeem again: the notice "You already used that code." and no second grant. Boot clean ("Definitions checked=84"; only the expected refused Studio data-store calls with API access off).
MIRROR: 148 scripts in DEV, digest identical to `src/` (a9e5eed3).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015); D-034 flagged
OWNER STEPS (when you want them): for each creator, ask Claude to add a row to `Definitions/Codes` with their code; announce LIGHTHOUSE with the relaunch.
NEXT: L1.5 store final (art; uploading is the owner's), L1.6 community documents, L1.7 release checklist.

CHECKPOINT: L1.5 Store final — 🟦 (uploading is the owner's)
DATE: 2026-10-17
BUILT: `assets/icons/icon_final_A.png` (512²); `assets/thumbnails/thumb_4_seven_nights.png` and `thumb_5_new_monsters.png` (1920 × 1080; with S2.7's three, five in all); `assets/store/trailer_30s.mp4` (29.5 s, 1920 × 1080, 30 fps, H.264, 7.6 MB, no sound; eight captioned shots, push-ins and crossfades); `assets/store/STORE_PAGE.md` (order of thumbnails, the new 876-character description). New shots were captured in a DEV play test (scripted camera, HUD hidden, monsters spawned by runtime-only scripts, all removed by Stop). D-035.
OWNER STEPS: Creator Hub → the experience → Places/Store page: upload the icon, the five thumbnails in the STORE_PAGE order, the description; optionally the trailer (add music first if it will be a video ad).

CHECKPOINT: L1.6 Community — 🟦 (Discord set-up and creator names are the owner's)
BUILT: `docs/COMMUNITY.md`: Discord channels, roles and moderation; the pinned bug template; the support macro (inspect → decide → rollback or grant → record → reply) on the R1.8 admin channel; creator codes; who to look for and a message template for 20+ creators.

=====================================================================
L1.7 — READY FOR OWNER: RELAUNCH CHECKLIST (production; the owner publishes)
=====================================================================
This moves the rebuilt game from the DEV experience to production (PlaceId 132065051336560). Claude has not touched production. Do it only after the DEV build has been published and played (S7.6 package, B1.5 testers) and you are happy with it.
Before:
 1. In the DEV Studio window: File → Save to File As → `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_L1RC_2026-10-17.rbxl` (the restore point "L1 RC" is set in DEV).
 2. Production rollback copy: Creator Hub → production experience → Places → the place → Version History: note the current version number (that version is the rollback target).
 3. Game Settings (DEV window) → Security → "Enable Studio Access to API Services" stays OFF.
 4. Decide L1.3 (Robux cosmetics). If not approved, nothing is sold; that is fine for the relaunch.
 5. Saves: production players start fresh on `LighthouseKeepers_PlayerData_v2` (D-012); the old `…_v1` store stays untouched as a frozen copy.
Publish:
 6. In the DEV Studio window: File → Publish to Roblox As… → choose the production experience "Lighthouse Keepers" (PlaceId 132065051336560) → Overwrite. (This publishes the DEV place file into the production place.)
 7. Creator Hub → production experience → Servers → Shut down all servers.
 8. Upload the L1.5 store files to the production experience; set the title (STORE_PAGE.md, A).
 9. Game Settings → Places → max players 4 (one crew per server, D-001) if not already.
Live checks (30 minutes, on-call window):
 10. Join production: the title screen (or the first voyage for a new account) appears; Pearls show 0 (fresh start).
 11. Sail a voyage to night 1, leave, rejoin: the dawn Pearl is still there.
 12. Redeem LIGHTHOUSE in Settings → Codes: +10 Pearls; again → "You already used that code."
 13. After a survived night: the harbor board shows you within a minute.
 14. Creator Hub → Analytics → Errors: no new error with more than a handful of hits.
If something is wrong: Creator Hub → production place → Version History → restore the version noted in step 2 → Shut down all servers. Then tell Claude what you saw.
After: post the changelog in Discord (#changelog), announce LIGHTHOUSE, and tell Claude "relaunched" so live ops (stage LO) can start: daily error triage for 30 days, the weekly update cadence (docs/LIVEOPS_PLAYBOOK.md).

CHECKPOINT: L1.3 Monetization — 🟦 (built and tested with the selling switch off; waits for the owner's product ids and the switch)
DATE: 2026-10-17
OWNER APPROVAL: "Approve L1.3" (project chat, 2026-10-17 13:17 UTC)
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF before Play (probe refused, error 7)
BACKUP: ServerStorage.Backups.L1.3_before_2026-10-17 (Items, Cosmetics, _Registry, ProfileSchema, PlayerData, LoadoutService, Economy, LampService, Shop, Inventory, ItemPreview, CosmeticsSpec, EconomySim) · restore point "L1.3 built (Robux off)"
BUILT:
- `Shared/Items`: 9 cosmetics (2 lamp housings, 2 keeper coats, 2 lanterns, 3 ship flags) with slots and colours; all but the Founder's Flag sold for Pearls (30–90). `_Registry` checks the new slots and colours.
- Profile: optional `Equipped.Housing/Coat/Lantern/Flag` (`ProfileSchema` validates: owned and the right slot, else it comes off); `PlayerData` view and `setEquipped`; `LoadoutService` equips and takes them off (no starter).
- Wearing (server, Economy domain and LampService): housing = 8 bars round the lantern room in the Keeper's colour (measured on the tower); coat = the worn armor recoloured; lantern = a small glass lantern at the hip (no light, S4.4 budget); flag = a flag at the ship's mast top, from the first player in the server who has one.
- `Definitions/Cosmetics` is now the Robux catalogue (12 products: 3 beam colours, 2 housings, 2 coats, 2 lanterns, 3 flags incl. the supporter Founder's Flag), each `{ robux, productId = 0 }`; `_Registry` allows only cosmetics and only those two fields; `ROBUX_ENABLED = false`.
- `Server/PurchaseService` (new): answers `ProcessReceipt` (wired in the Economy domain, the game's only one): grant once per receipt (`receipt:<PurchaseId>`), `NotProcessedYet` when the buyer is away or not loaded, nothing for unknown products or with the switch off.
- Shop: the Cosmetics tab lists them with labels per slot; a Robux button ("R$ 59") beside the Pearl price, or alone for the Founder's Flag, shown only when `Cosmetics.productFor` says it is on sale. BAG: four new equipped slots. Item previews: small drawings in each item's colour.
TESTRUNNER (DEV, Play server): **240 passed, 0 failed** (234 − old `CosmeticsSpec` 5 + new `CosmeticsSpec` 7 + `PurchaseSpec` 4: one receipt granted once however often it arrives; an absent buyer or unloaded save waits and is granted later; unknown products, switch off and malformed receipts grant nothing; two receipts are two purchases; a stat, a weapon or an earned item on the Robux list fails the boot; only the Economy domain answers receipts and only the shop prompts; equipped cosmetics must be owned and fit).
PLAY TEST (DEV; items given by a runtime-only script on the mock profile, removed after): equipped through the live LoadoutRequest handler; the coat showed on the armor, the Tide lantern at the hip, 8 brass bars round the lantern room while holding the lamp, the Kraken flag at the main mast top; the BAG shows the four new slots; the Quartermaster's Cosmetics tab lists all of them with Pearl prices. 0 server and 0 client errors.
MIRROR: 150 scripts in DEV, digest identical to `src/` (98ec9d18).
OWNER STEPS (to start selling):
 1. Creator Hub → Lighthouse Keepers DEV → Monetization → Developer Products → create one product per row (name, price in Robux; an icon is optional):
    Sea Glass Beam 29 · Moonlight Beam 39 · Ember Beam 59 · Driftwood Housing 49 · Polished Brass Housing 99 · Storm Blue Coat 59 · Kelp Green Coat 59 · Moth Lantern 75 · Tide Lantern 75 · Gull Flag 39 · Kraken Flag 99 · Founder's Flag 149.
 2. Send Claude the 12 product ids (name → id).
 3. Reply "switch on Robux sales" in the thread (or set `ROBUX_ENABLED = true` in `ReplicatedStorage.Shared.Definitions.Cosmetics` yourself). Claude then fills in the ids, runs TestRunner, and makes a Studio test purchase (Studio purchases are free test purchases) to check the item arrives once.
 4. Publish DEV, buy one cheap item for real, check it arrives once; then the same in production at the relaunch (production needs its own products: L1.7).

L1.3 FOLLOW-UP · 2026-10-17 · product ids and selling switch
- The owner created the 12 developer products in Lighthouse Keepers DEV and said "switch on Robux sales". `ROBUX_ENABLED = true`; ids read from the experience with MarketplaceService:GetDeveloperProductsAsync (read-only; names and Robux prices matched the list) and filled into `Definitions/Cosmetics`.
- TestRunner (DEV, Play server): 240 passed, 0 failed.
- Shop: the Cosmetics tab shows "R$ 49" beside the Pearl price for Driftwood Housing; clicking it calls PromptProductPurchase (click registered), but Studio's purchase dialog did not appear in this session (Studio API access is off; no dialog, no error). Not verified: the Roblox purchase dialog itself.
- Receipt path with the real product id (runtime-only script through the real PurchaseService, GrantService and catalogue, mock profile): first receipt `granted` and Driftwood Housing owned; the same receipt again `granted` with no second claim (1 receipt claim).
OWNER CHECK: in the published DEV game (after the S7.6 publish), open the Quartermaster → Cosmetics → a cheap item (Sea Glass Beam, 29) → R$ button → buy. It should arrive in your BAG once, with a "Thank you!" notice.
MIRROR: 150 scripts, digest identical to `src/`.

L1.3 LIVE · 2026-10-17 16:43 UTC · the owner saved `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_L1RC_2026-10-17.rbxl`, published DEV and made a real Robux purchase: "Purchase worked". L1.3 ✅. The DEV publish also carries every earlier package (S2.8–S7.6); their live checks (leaderboard after a night, daily objective notice, invite reward, codes, phone FPS) are still to be reported.

CHECKPOINT: LO.1–LO.4 First live-ops cycle (Shipwreck Rescue) — 🟦 (Script Analysis unmeasured; everything else passed)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified (new Studio session after the owner's publish; its scripts matched the mirror before any change) · API access: found ON after the purchase test; the owner turned it off before any Play (probe refused)
BACKUP: ServerStorage.Backups.LO.1_before_2026-10-17, LO.2_before_2026-10-17, LO.4_before_2026-10-17 · restore point "LO cycle 1 passed"
BUILT:
- LO.1 `Shared/Definitions/LiveEvents` (new): events with a UTC window (`isOn`, `active`); `ShipwreckRescue` 2026-10-17 → 2026-11-07. `Voyages.Rescue` (5 nights, big monsters on 3 and 5, `event = "ShipwreckRescue"`). The crew card shows it to everyone while the event is on; ChooseVoyage and the departure check the window again on the server. `_Registry` checks events and event voyages both ways.
- LO.2 `Server/RescueService` (new, `--!strict`, Encounter domain): on a Rescue voyage a wreck (planks, keel, broken mast, sail) appears on the shore with a "CASTAWAYS · SAVED" sign; "Carry a castaway" gives the player a castaway on their back (not while carrying oil; oil cannot be grabbed while carrying one); "Bring them inside" at the lit shelter by the lighthouse saves them (+15 crew Shells, a crew notice, bus event `CastawayRescued`). A carrier who falls or leaves drops theirs back at the wreck. At the end (not abandoned): 1 Pearl per 2 saved (claim `<voyage>:rescue:<userId>`) and, when all were saved, the Rescuer's Flag (claim `event:ShipwreckRescue:FlagRescuer`, once per profile). The wreck and shelter are removed at the end.
- LO.3 `Items.FlagRescuer` (Flag cosmetic, `reward = "event"`, never sold).
- LO.4 the shop/bag item card's type line is cut before the price (it ran under it); `Client/CodeBox` (new) is the shared code box, used in Settings and now in the BAG ("Codes" section).
TESTRUNNER (DEV, Play server): **249 passed, 0 failed** (240 + `LiveEventsSpec` 4: window edges, registry both ways, a bad window or an event voyage with an unlock fails, wiring; `RescueSpec` 5: one per carrier and never with oil, drop returns to the wreck, rewards 1 per 2 and the flag only at 8/8, the flag is earned not sold, wiring).
PLAY TEST (DEV, runtime-only driver for the voyage and keep-alive; prompts used through the client's real ProximityPrompts): Rescue voyage chosen and sailed; the wreck and shelter appeared; 8 castaways carried and brought in (crew Shells 120 → 240); the voyage was won on night 5; then `Grant … source=rescue pearls=4`, `Grant claim=event:ShipwreckRescue:FlagRescuer`, the usual dawn and result Pearls; the wreck was gone afterwards. Found and fixed during the test: the shelter sat inside the tower door's "Repair Tower" prompt range, so the repair prompt won; it now sits 16 studs out. 0 errors (only the expected refused Studio data-store calls).
MIRROR: 155 scripts in DEV, digest identical to `src/` (1462302e).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015); D-037 flagged

=====================================================================
LO.5 — READY FOR OWNER TO PUBLISH (DEV experience only)
=====================================================================
What is in this build (since your last DEV publish): the Shipwreck Rescue event (until 7 November): a 5-night event voyage on the crew card, a wreck with 8 castaways to carry to the lighthouse, Pearls for rescuing and the Rescuer's Flag for saving all 8; the shop's card labels no longer run under prices; codes can be redeemed from the BAG.
Before publishing:
 1. In the DEV Studio window: File → Save to File As → `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_LO1_2026-10-17.rbxl`.
 2. Game Settings → Security → "Enable Studio Access to API Services" stays OFF.
Publish:
 3. File → Publish to Roblox (DEV experience, PlaceId 102473202766620).
 4. Creator Hub → Lighthouse Keepers DEV → Servers → Shut down all servers.
Live checks:
 5. On the ship's crew card, "Shipwreck Rescue · 5 nights · event" is offered; pick it and sail.
 6. Carry a castaway from the wreck on the shore to the lit shelter by the lighthouse; the crew sees "… brought a castaway to safety (1/8)".
 7. Open the BAG: a "Codes" box sits under "Your keeper".
If something is wrong: Creator Hub → DEV place → Version History → restore the previous version, then Shut down all servers.

LO.5 PUBLISHED · 2026-10-17 17:19 UTC · the owner saved `backups/LighthouseKeepers_DEV_LO1_2026-10-17.rbxl` and published DEV. Live checks (crew card offers Shipwreck Rescue; a castaway carried to the shelter; the BAG's Codes box) still to be reported.

CHECKPOINT: V1 Sea and sky (visual overhaul) — 🟦 (Script Analysis unmeasured; the owner judges the look from the screenshots)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF (probe refused, error 7)
BACKUP: ServerStorage.Backups.VIS_V1_before_2026-10-17 (GameState, Storm, and a note with the old terrain and lighting values) · restore point "VIS_V1 before"
BUILT:
- Terrain: the sea was an 800-stud square around the voyage island, and its jagged edge showed at night. It now reaches 3,072 studs on every side (water from y = -36 to 0 over a sand floor, the same profile as before). To undo: fill Air outside the 800-stud square from y = -50 to 0.
- `GameState` (server lighting): a darker, hazier storm night and an overcast day (values in D-038). The haze hides where the sea ends.
- `Storm.client`: in the storm the sea's waves rise (0.35 → 0.85, speed 14 → 26), the clouds close over (cover 0.8) and the stars go; calm weather is overcast. Local to each device, so the harbor's own weather is unchanged.
TESTRUNNER (DEV, Play server): **249 passed, 0 failed**. (A first run in the same Play session showed 2 Security failures because my test helper was sailing the same real player at the same moment; the clean run after it passed.)
PLAY TEST (DEV): a voyage sailed with the runtime helper; prologue storm and Day 1 seen with a pinned camera; 0 errors in the output (only the expected refused Studio data-store calls and Roblox's own UIBlox warnings). Client 60 FPS in Studio. Whole-Studio TerrainVoxels memory 96 MB in Play (not separable from the old terrain; the phone check is V8).
SCREENSHOTS: `assets/screens/visual_v1/` (before and after, night and day).
MIRROR: 155 scripts in DEV; GameState and Storm hashes identical to `src/` (e3423a70, 436709a3).
OWNER: judge the screenshots; say yes or no to downloading the free CC0 Cloudy Skyboxes pack for a real storm-cloud sky.
OWNER APPROVAL: auto-approved (unattended, D-010/D-015); D-038 flagged

CHECKPOINT: V2 The beam (visual overhaul) — 🟦 (Script Analysis unmeasured; the owner judges the look from the screenshots)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF
BACKUP: ServerStorage.Backups.VIS_V2_before_2026-10-17 (V2 adds one new script and touches no existing one) · restore point "VIS_V2 before"
BUILT:
- `Client/BeamFx` (new LocalScript, `--!strict`): the beam was one flat, fairly opaque ribbon (a white wedge with hard edges that cut into the ground). On each device it is now 4 layers that copy the server's beam every frame: a wide haze, a middle and an inner layer drawn with Roblox's built-in soft smoke texture (feathered edges), and a narrow bright core. All fade out before the end of the beam. In the storm, rain glints fall through the beam (160/s on computers, 60/s on touch devices, none with Low effects). The server's beam (angle, width, colour, on/off) and its hits are unchanged; the existing SpotLight and light pools still light the ground where it lands.
TESTRUNNER (DEV, Play server): **249 passed, 0 failed**.
PLAY TEST (DEV): voyage sailed with the runtime helper, the lamp kept fuelled by a runtime-only helper for the pictures; prologue storm seen from two pinned cameras; client 60 FPS in Studio; 0 client errors, 0 server errors apart from the expected refused Studio data-store calls.
SCREENSHOTS: `assets/screens/visual_v2/`.
MIRROR: BeamFx hash identical in DEV and `src/` (b64e4eed).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)

CHECKPOINT: V3 Storm effects (visual overhaul) — 🟦 (Script Analysis unmeasured; phone FPS is V8; the owner judges the look)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF
BACKUP: ServerStorage.Backups.VIS_V3_before_2026-10-17 (Storm, and a note) · restore point "VIS_V3 before"
BUILT:
- `Storm.client`: the rain was nearly invisible because a positive squash flattened every drop into a faint horizontal dash; drops are now vertical streaks, bigger and brighter (phones keep the lower drop rate). New rain sheets: long faint streaks in four boxes 170 studs around the camera so the storm shows across the sea (computers only). Lightning now also strikes: a 9-segment bolt into the sea 180–450 studs away, flickering twice, and a cold flash over the whole scene through this device's own colour correction (the bolt is skipped with Low effects).
- `ShoreFx` (new LocalScript, `--!strict`): finds the shoreline from the terrain (water next to land, every 11 studs) the first time the player is on the island; slow foam puffs churn there (stronger in the storm) and storm waves throw spray at random points. 90 points on computers, 40 on touch devices, none with Low effects.
- `BeamFx` (V2) adjusted: the layers are lighter (the beam was a solid white wall when the camera stood beside it) and dim further when the camera is next to the beam; the server's beam is now only read, and all four layers are drawn locally. Rain glints in the beam fixed the same way as the rain.
- Not done: lanterns and flags swaying. The voyage island has none yet; this moves to V4, when the hut, path lanterns and flags are built.
TESTRUNNER (DEV, Play server): **249 passed, 0 failed**.
PLAY TEST (DEV): voyage sailed with the runtime helper, lamp kept fuelled by a runtime-only helper; the prologue storm seen from pinned cameras; 90 shoreline points found; 0 client errors, 0 server errors apart from the expected refused Studio data-store calls; client 60 FPS in Studio. The lightning picture is one frame held still by a runtime-only helper (the real flash lasts about a third of a second). After the play test the bolt distance was shortened from 350–800 to 180–450 studs (farther bolts were lost in the haze); that change was parse-checked, not play-tested.
SCREENSHOTS: `assets/screens/visual_v3/`.
MIRROR: Storm 455fe39f, BeamFx ac09e486, ShoreFx 9f0eff9c, identical in DEV and `src/`.
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)

CHECKPOINT: V4 Island rebuild (visual overhaul) — 🟦 (Script Analysis unmeasured; the owner judges the look; the owner's file save below is outstanding)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF
BACKUP: ServerStorage.Backups.VIS_V4_before_2026-10-17 (a TerrainRegion copy of the whole island and the Decor folder) · restore points "VIS_V4 before", "V4 terrain repaint 2", "V4 props". OWNER: in the DEV Studio window, File → Save to File As → `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_preVisual_2026-10-17.rbxl` (asked in the thread; V4 went ahead on the in-Studio terrain copy, per unattended mode).
BUILT (details and exact rules in `assets/world/v4_island_build.md`):
- Terrain: the lawn-green plateau is now moss, earth and rock patches with worn mud paths (spawn → tower door, → oil, → bench, → trader, → hut, and up from the south cove). Heights where play happens (radius under 74 studs) are unchanged. The sand ring became a craggy rock rim up to 7 studs high, with three sand coves (south toward the harbor, and at the two wreck props).
- Props (`Workspace.IslandProps`, edit-time parts, 9 small lights): keeper's hut with a lit window and a flag, an oil shed over the barrels, a dock with a rowboat at the south cove, 6 path lanterns.
- `WindFx` (new LocalScript, `--!strict`): tagged lanterns swing and the flag flutters, harder in the storm; only within 250 studs of the camera.
- Not done: a raised tower mound (the tower and lamp are placed at a fixed height, so raising the ground under them would bury the base; left for a later code change if wanted).
TESTRUNNER (DEV, Play server): **249 passed, 0 failed**.
PLAY TEST (DEV): voyage sailed with the runtime helper; prologue crabs (9) and Night 1 creatures (17) climbed over the new rim and reached the tower; a creature's ground-grid height matched a terrain raycast within 0.03 studs; GroundGrid 445,474 samples in 3.2 s (was 398,974 in 3.1 s); the "Grab Oil" prompt under the shed worked (CarryingOil = true); the flag moved; 0 client and 0 server errors (apart from the expected refused Studio data-store calls and one error from my own monitoring helper, fixed and rerun); client 60 FPS in Studio.
SCREENSHOTS: `assets/screens/visual_v4/`.
MIRROR: WindFx f04ac3c5 identical in DEV and `src/`. Terrain and props are place content (not in the mirror); they reach players with the owner's next DEV publish.
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)

CHECKPOINT: V5 One material style (visual overhaul) — 🟦 (Script Analysis unmeasured; the owner judges the look)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF
BACKUP: ServerStorage.Backups.VIS_V5_before_2026-10-17 (every terrain material colour as it was, and the old `GlassPop`) · restore points "VIS_V5 before", "V5 palette"
BUILT (place settings, no scripts; D-039):
- Terrain material colours on one cold palette (both islands): mossy greens instead of bright lawn green, wet blue-grey rock, dark earth and mud, muted sand.
- `GlassPop` colour correction: saturation +0.12 → 0, contrast +0.06 → +0.1, a slight cool tint.
- Surveyed every visible part in play: V4 props are wood, slate, cobble and metal; the remaining Plastic/SmoothPlastic parts are textured meshes (tower, barrels, crates, palms, ship, trader, bench), left alone.
- Not possible from a script: switching Roblox's material set; it stays as the owner set it.
TESTRUNNER (DEV, Play server): **249 passed, 0 failed**.
PLAY TEST (DEV): the harbor seen from the player's own camera; 0 client and 0 server errors (apart from the expected refused Studio data-store calls).
SCREENSHOTS: `assets/screens/visual_v5/` (the palette pair is Studio's bright edit view, for colour only).
MIRROR: no script changed.
OWNER APPROVAL: auto-approved (unattended, D-010/D-015); D-039 flagged

CHECKPOINT: V6 Harbor at dusk (visual overhaul) — 🟦 (Script Analysis unmeasured; the owner judges the look)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF
BACKUP: ServerStorage.Backups.VIS_V6_before_2026-10-17 (LobbyIslandDecor and IslandBuilder as they were) · restore points "VIS_V6 before", "V6 harbor props"
BUILT:
- `HarborLight` (new LocalScript, `--!strict`): one Lighting serves the whole place, so the harbor's golden hour is applied on each device while the player stands within 260 studs of the harbor spawn (ClockTime 17.7, warm ambients and haze). It remembers every value the server sends meanwhile and hands the server's lighting back the moment the player leaves; checked: after sailing, the client on the island had exactly the server's storm-night values.
- `LobbyIslandDecor` (place content): the 8 lanterns were white glowing cubes; now amber glass with iron caps and bases and amber light. The campfire was a grey block and four crossed sticks; now a ring of 9 stones, a teepee of 5 logs, flames, embers and smoke (Roblox's built-in particle textures) and a light that flickers (`WindFx`, tag `Flicker`); the 4 seat logs stay. 10 more palms (copies of the place's own palm) at the island's edges. Two iron bollards and a rope coil on the pier landing.
- `IslandBuilder`: the Quartermaster's sign sits above the stall's awning (the shelves hid half of it).
- `WindFx`: flickering firelight for parts tagged `Flicker`.
TESTRUNNER (DEV, Play server): **249 passed, 0 failed**.
PLAY TEST (DEV): the harbor at dusk from the player's own camera and at the campfire; a voyage sailed with the runtime helper: on the island the client's lighting matched the server's (ClockTime 23.2, Brightness 1.3, atmosphere 0.34); 0 client and 0 server errors (apart from the expected refused Studio data-store calls); client 60 FPS in Studio.
SCREENSHOTS: `assets/screens/visual_v6/`.
MIRROR: HarborLight b65d106c, WindFx 5077ac63, IslandBuilder cdf59062, identical in DEV and `src/`. Harbor dressing is place content; it reaches players with the owner's next DEV publish.
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)

CHECKPOINT: V7 Hit and death feel (visual overhaul) — 🟦 (Script Analysis unmeasured; the owner judges the feel)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF
BACKUP: ServerStorage.Backups.VIS_V7_before_2026-10-17 (CreatureView, BeamFx) · restore point "VIS_V7 before"
BUILT (all on the client; no gameplay value changed):
- `CreatureView`: a creature now dies in a burst of sea foam (ART_BIBLE): a pale foam ball plus 14 foam puffs and 10 droplets from one shared emitter part (was an orange ball). When a hit lands, 5 white sparks fly (the white body flash was already there). Still no instances per creature.
- `HitFx` (new LocalScript, `--!strict`): a small camera shake when a cannon fires within 70 studs of the camera, scaled by distance, and when this player loses 8 or more health in one hit; it fades in about 0.4 s and is off with Low effects.
- `BeamFx`: under 15% oil the lamp's light and beam stutter (occasional dips); the fuel itself is untouched.
TESTRUNNER (DEV, Play server): **249 passed, 0 failed**.
PLAY TEST (DEV): voyage sailed with the runtime helper; a runtime-only helper damaged the nearest creatures: the shared effect part moved to 8 hit spots and 3 foam bursts were drawn in 20 s; the player hurt by 20 health by the helper: the camera turned up to 0.23° between frames while the player stood still (a steady camera turns 0°); the lamp held at 9% oil by the helper: its light ranged 0.75–2.78 against a steady 3; 0 client and 0 server errors (apart from the expected refused Studio data-store calls).
SCREENSHOT: `assets/screens/visual_v7/after_foam_burst_staged.jpg` is staged: the same foam emitter fired several times in a row so the screenshot catches it (one real death is a single, shorter puff).
MIRROR: HitFx e875eb19, CreatureView a79702a8, BeamFx caab8fb4, identical in DEV and `src/`.
OWNER APPROVAL: auto-approved (unattended, D-010/D-015)

CHECKPOINT: V8 Phone check (visual overhaul) — 🟦 (a real-phone check is the owner's; Studio's device emulator was not reachable from the tools)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF
DONE:
- Screenshots of the island storm night at Studio's lowest graphics quality (Level 1) and at Automatic: `assets/screens/visual_v8/`. The beam, lanterns, hut and shed all still read at Level 1.
- Studio frame times (this PC, capped at 60): Automatic 60.2 FPS / 16.7 ms avg / 17.8 ms p95; Level 1 60.0 FPS / 16.7 ms / 17.9 ms. The quality setting was put back to Automatic afterwards.
- The per-device budget of everything V1–V7 added, in `docs/PERFORMANCE_BUDGETS.md` ("Visual overhaul"): touch devices get a third of the rain, no rain sheets, fewer glints, 40 instead of 90 shore points and half the spray; Low effects turns all particle extras off.
NOT DONE: an FPS number on a phone or in the emulator. Nothing here is a phone measurement.
OWNER (when you next publish DEV): on a phone, sail a voyage and watch the first storm night; say whether it stays smooth. If not, the first things to cut are the shore foam points and the rain sheets (already off on phones).
TESTRUNNER (DEV, Play server): **249 passed, 0 failed**. 0 client errors.

=====================================================================
VISUAL OVERHAUL V1–V8 — summary for the owner
=====================================================================
V1 sea and sky · V2 the beam · V3 storm effects · V4 island rebuild · V5 one palette · V6 harbor at dusk · V7 hit and death feel · V8 phone check (🟦). Decisions D-038 (lighting) and D-039 (palette) are flagged for you. Every step has a backup in `ServerStorage.Backups.VIS_<step>_before_2026-10-17` and before/after screenshots in `assets/screens/visual_<step>/`. Scripts are mirrored in `src/`; the terrain, the island props and the harbor dressing are place content and reach players with your next DEV publish.
Still asked of you: save `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_preVisual_2026-10-17.rbxl` (a copy of the place as it is now is also useful: `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_visual_2026-10-17.rbxl`); say yes or no to the free storm-sky download; judge the look.

CHECKPOINT: Harbor UI (HUI.1–HUI.5), Look A "Bold" — 🟦 (Script Analysis unmeasured; the owner judges the look and may pick Look B)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF
BACKUP: ServerStorage.Backups.HUI_before_2026-10-17 (Config, Items, _Registry, RegistrySpec, UI.Controls, UiSkin, Shop, Inventory, Hud, LobbyBuilder, LiveOps) · restore points "HUI before", "HUI passed"
BUILT (spec: project file `research/harbor_ui_spec.md`; D-040):
- `Client/UiSkinBold` (new) + `UiSkin` + `Config.UI_SKIN = "bold"`: the Bold look as a UiKit skin (one switch): navy #16304A panels, #07111B outlines 3–5 px, corners 18–26, 3D buttons (amber primary, green buy, red close, navy idle tab) with a darker copy 6 px below that presses down, Luckiest Guy titles and buttons, Fredoka One text, rarity colours. Auto-sized buttons are sized to their text; long labels shrink to fit.
- `Items` + `_Registry`: a display-only `tier` on all 27 items, checked at boot (`Items.TIERS`); `RegistrySpec` +1 test.
- `UI.Controls`: `UiKit.ShopCard` (rarity tag, item in a ring of its rarity colour, price/Robux/EQUIPPED/OWNED plate, white outline when selected), a `buy` button variant, vertical tabs.
- `Shop.client`: tab rail | 3-column cards | detail panel (rarity tag, preview framed in the rarity colour, stat bars measured against the best on the shelf, +/- against what is equipped, big green BUY next to the Robux button). Phone: rail + grid, tap for the detail view with Back. ShopRequest/ShopResult and the Robux purchase flow are unchanged.
- `Client/HarborBoard` (new) + `LobbyBuilder`: "HARBOR LEGENDS" drawn on each device from the rows the server already writes into the board (the plain face is hidden on the device): a gold/silver/bronze podium for the top 3, rows 4–10, a "your rank" strip (from the names already on the boards), and a full-screen view from a "View the boards" prompt. No new remote, so no API_CONTRACTS row. The board is 16 x 9.5 studs (was 13 x 7.5).
- `Inventory.client`: the bag button is a chunky 3D button (same place and size); on the harbor island a Pearls pill (top right) and a CODES button (opens the BAG, where the code box is) appear; both hide on a voyage.
TESTRUNNER (DEV, Play server): **250 passed, 0 failed** (249 + the tier test).
PLAY TEST (DEV): the shop opened through the Quartermaster's real prompt; Weapons and Cosmetics tabs, card selection, the BUY and Robux buttons (a runtime-only helper gave 120 Pearls in Studio's memory store so the green BUY shows; API access off, nothing saved); the small-phone layout (667 x 375) grid and detail view; the board drawn from sample rows a runtime-only helper wrote into its labels; the full-screen board from its prompt; the BAG opened from CODES; 0 client and 0 server errors.
SCREENSHOTS: `assets/screens/harbor_ui/` (before and after: shop weapons, shop cosmetics, phone, board; plus the full-screen board and the harbor HUD).
MIRROR: 162 scripts in DEV, digest identical to `src/` (8fa221ea).
NOT DONE: Look B "Captain's Ledger" (waits for the owner's pick); the CODES button opens the BAG but does not scroll to the code box.
OWNER APPROVAL: auto-approved (unattended, D-010/D-015); D-040 flagged

CHECKPOINT: First 10 minutes as a new player, pass 1 (scripted, one Studio account) — 🟦 (not a real-player test; Script Analysis unmeasured)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF
BACKUP: the Coach script before this change is in git (commit 57e04ac); the Studio backup folder `ServerStorage.Backups.NP_before_2026-10-17` was made after the edit and holds only that note (a lapse: the copy should have been taken first) · restore point "NP coach helm"
WHAT A FIRST-TIMER MEETS (fresh profile, Studio memory store, keyboard):
- Join → harbor: the goal line ("Walk the pier onto the ship…") is clear; the ship is straight ahead. Walking from the spawn onto the deck took 7.0 s.
- **On the deck, alone: nothing pointed at the wheel.** A solo first-timer waits on a full-crew rule (the ship sails at 4/4 or on SAIL NOW at the wheel); the only guidance was a toast and a line on the crew card. **Fixed:** the coach now shows "Take the wheel to set sail" with its marker on the wheel after 6 s aboard, for first-voyage players in the harbor with no departure running; it disappears as soon as a departure starts (checked).
- SAIL NOW → island: 10.5 s countdown, then the prologue; the coach chain (oil → tank → lamp → aim) showed in order with markers.
- Open (not fixed): on boarding, the camera faces the mast and cargo, so the wheel and its marker are behind the player; a camera turn toward the wheel when a first-timer boards would help. Holding E works; scripted `InputHoldBegin` on hold prompts (the fuel tank) did not trigger and is a test-driver limit, not a game bug (a real E key press refuelled).
TESTRUNNER (DEV, Play server): **250 passed, 0 failed**. 0 client and 0 server errors.
MIRROR: Coach c8b43d2c identical in DEV and `src/`.
OWNER: a real first session (a friend who has never played) is still the test that counts; this pass only removes what a script can find.

CHECKPOINT: Harbor island enlargement — ✅ in DEV (owner's ask; the owner judges the look)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF
BACKUP: ServerStorage.Backups.HARBOR_before_2026-10-17 · restore points "HARBOR before", "HARBOR grown", "HARBOR dressed"
BUILT: the harbor island grew from 16,912 to 48,096 studs² of land (2.8×), mostly to the south, east and west; the pier side is unchanged; 22 palms and 7 rocks around the new edge; the middle of the new south half is open for NPCs. Details: `assets/world/harbor_island_size.md`.
TESTRUNNER (DEV, Play server): **250 passed, 0 failed**. PLAY TEST: spawn, walk to the far south edge (golden-hour lighting holds), 0 errors.
SCREENSHOTS: `assets/screens/harbor_size/`.
NO SCRIPT CHANGED: place content only; it reaches players with the owner's next DEV publish.

CHECKPOINT: S2.5c — Menu pattern v1 (grid + detail pane) — 🟦 (Script Analysis unmeasured; phone sizes are simulated layouts, not Device Simulator; the owner judges the look)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF (GetAsync probe refused with error 7 before the first Play)
BACKUP: ServerStorage.Backups.S2.5c_before_2026-10-17 (Shop, Bench, CosmeticsSpec) · restore points "S2.5c before", "S2.5c passed"
BUILT:
- `Client/UI/Tiles.luau` (new, --!strict): the D-041 menu pattern in the Bold look (D-042): header with title, resources and a big red close; category buttons; a grid of equal tiles (icon, name on up to two lines, cost; owned/equipped check; level badge); one tile always selected; locked tiles dimmed under one reason divider; the detail pane (big icon, name, gold description, stat lines "now → this" in green/red, cost) and one big action button (a second one for Robux). UI scale clamp(height/1080, 0.55, 1); every tap target is at least 56 screen pixels.
- Quartermaster shop (`Shop.client.luau`, rewritten on Tiles): Weapons, Armor, Ammo, Boosts, Cosmetics. Stat lines compare with what is equipped (StatPipeline). Ammo has − / + / MAX. A Pearl purchase needs a second tap (CONFIRM, D-043). Owned items get EQUIP. Cosmetics show Pearls and Robux (Robux via the existing PromptProductPurchase / PurchaseService path).
- Workbench (`Bench.client.luau`, rewritten on Tiles): one tile per upgrade (level badge, Shells cost, red when short, "Maxed"), the two evolutions dimmed under "MAX BOTH UPGRADES TO FORGE"; detail shows level and value now → next (StatPipeline); one tap buys; keys 1–4 still buy. Fixed on the way: the bench stayed open over the results screen when a voyage was lost; it now closes when the voyage ends.
- No server script, remote, price, stat or save field changed. `CosmeticsSpec` reads the new shop code (same guarantee: the only purchase prompt is for the product the Cosmetics catalogue lists).
TESTRUNNER (DEV, Play server): **250 passed, 0 failed** (5.37 s).
PLAY TEST (DEV, keyboard, Studio memory store with TEMPTEST Pearls; this is the owner's account in DEV, not production): opened the shop from the Quartermaster; bought the Storm Harpoon (Buy → CONFIRM → 300 → 270 Pearls, owned, then equipped; checked on the server profile); bought a Shell Pouch rank (300 → 280 Pearls, rank 1); ammo quantity ×3 = 24 Pearls; sailed and bought two Lens Power upgrades at the bench (Shells 120 → 30, level 2, both checked on the server). Console: 0 errors from game scripts in the last run (an earlier run showed a detail-pane error, fixed before this record).
SIZES (Studio, screen pixels): PC window 2004×985 (UI scale 0.91): smallest tap 56.5 px (ammo − button), 0 labels overflowing, the detail pane fits without scrolling. Simulated 926×428 (iPhone 13 Pro Max size) and 667×375 (iPhone 7 size): smallest tap 56.1 px (close), 0 labels overflowing on every shop tab and the bench; the detail pane scrolls on phones (D-043). These are the game's own simulated layouts (`HudSimulate`); Device Simulator is not reachable from the tools.
NUMBERS: none of the game's numbers changed.
SCREENSHOTS: `assets/screens/s25c/` (00_ = the first draft before the fixes; PC shop tabs, the CONFIRM step, after the purchase, Robux cosmetic, ammo, boosts, the bench before and after two upgrades, phone 667×375).
MIRROR: 163 scripts in DEV, digest identical to `src/` (cd53c796).
NOT DONE / OPEN: Script Analysis count (not reachable from the tools); a real phone; the owner's look verdict. Other menus (BAG, merchant, locker) keep their current layout (S2.5c scope).
OWNER APPROVAL: auto-approved (unattended, D-010/D-015); D-043 flagged

VISUAL + HARBOR UI + S2.5c — READY FOR OWNER TO PUBLISH (DEV experience only)
=====================================================================
What is in this build (since your last DEV publish, LO.5): the visual overhaul V1–V8 (a sea with no edge, a dark storm night, the layered beam, rain and lightning, the rebuilt rocky island, golden hour in the harbor, foam death bursts and hit sparks); the Bold harbor UI (HARBOR LEGENDS board, Pearls pill, CODES button); the new Quartermaster shop and workbench (S2.5c: tiles, detail pane, big buttons, a second tap to confirm a Pearl purchase); the coach and camera pointing a solo first-timer at the wheel; the harbor island 2.8× bigger. No price, stat, remote or save field changed.
Before publishing:
 1. In the DEV Studio window: File → Save to File As → `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_VIS_2026-10-17.rbxl`.
 2. Game Settings → Security → "Enable Studio Access to API Services" stays OFF.
Publish:
 3. File → Publish to Roblox (DEV experience, PlaceId 102473202766620).
 4. Creator Hub → Lighthouse Keepers DEV → Servers → Shut down all servers.
Live checks (on a computer, then on your phone):
 5. Join: the harbor is at golden hour; the Pearls pill shows your real Pearls (not 0).
 6. Walk to the Quartermaster, press Trade: the new shop opens. Buy something cheap (Buy, then Confirm); the Pearls go down by the price and the item says Owned. Equip it.
 7. Board alone and sail (the coach's "Take the wheel to set sail" only shows for an account on its first voyage; a friend's new account will see it).
 8. On the island at night: the storm is dark, the beam is soft with a bright core, rain shows. Kill a crab: a foam burst.
 9. Open the workbench (Upgrade Bench prompt): tiles, one tap buys an upgrade.
 10. On your phone: the shop's buttons are easy to hit and no words are cut off; the game runs smoothly at night (this is also V8's real-phone check). Tell me the phone model and how smooth it felt.
 11. The LO.5 checks still to report: the crew card offers "Shipwreck Rescue"; a castaway carried to the shelter; the BAG's Codes box.
If something is wrong: Creator Hub → DEV place → Version History → restore the previous version, then Shut down all servers.
VIS.P step 1 done · 2026-10-17 22:19 UTC · the owner saved `backups/LighthouseKeepers_DEV_VIS_2026-10-17.rbxl` (1.1 MB, checked on disk). Publish and live checks still to come.

VIS.P PUBLISHED · 2026-10-17 · the owner published DEV with the new look and reports "All going good" for the live checks (the LO.5 checks were in the same list). Not reported: the phone model and how smooth it felt (V8 stays 🟦 for that).

CHECKPOINT: S3 measures for the public test — 🟦 (Script Analysis unmeasured; the numbers need live players)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF (probe refused, error 7)
BACKUP: ServerStorage.Backups.S3TEL_before_2026-10-17 (Events, EventLog, CreatureService, Encounter, GameState, Analytics, EventBusSpec) · restore points "S3TEL before", "S3TEL passed"
WHY: two S3 gate numbers had no source. The S3.5 role check ("a non-Keeper made the moment of the storm in ≥ 30% of voyages") was not sent anywhere, and "both beam modes used" relied on observer sheets alone.
BUILT (telemetry only; no gameplay, price, remote or save change):
- `EventLog.moment(priority, text, kind)`: each moment of the storm now says who made it (`beam` = the Keeper, `oil`, `weapon`, `cannon`, `crew`). The boss kill takes its kind from the killing blow's damage tag; "saved the light" is `oil`; the tower and evolutions are `crew`. `VoyageEnded` carries `MomentKind` (catalog and `EVENTS.md` updated).
- `Analytics`: at the end of a voyage, each crew member gets the custom event `MomentKind`. Each player with a beam kill gets `BeamModes` (`wide`, `focused` or `both`, from `CreatureKilled` damage tags).
- `docs/PLAYTEST_KIT.md` (new): S3.2 session checklist, an observer sheet per player, the S3 gate table with where each number is read in Creator Hub, the real-phone checklist. The old repo's kit was never brought over.
TESTRUNNER (DEV, Play server): **251 passed, 0 failed** (1 new: kinds and beam modes reach analytics; repeated end events don't double-count).
PLAY TEST (DEV): sailed, killed creatures with both beam tags as the player (runtime helper), added a moment, left the voyage. Console: `[ANL] custom MomentKind oil` and `[ANL] custom BeamModes both`, and the run summary listed `FocusedBeam 3, WideBeam 3`. No errors from game scripts (one error came from my first helper script, which used a wrong call; the game itself was not involved).
STRICT: EventLog, CreatureService, Encounter and GameState are older modules without `--!strict`. They were left as they were, as in earlier substages; the edits are one-line arguments.
MIRROR: 163 scripts in DEV, digest identical to `src/` (3c3c2715).
OWNER: to start S3, see "S3 — START THE PUBLIC TEST" below.

S3 — START THE PUBLIC TEST (owner; DEV experience only; production stays untouched)
=====================================================================
D-016: the public test runs on DEV, made public. Testers' DEV progress does not carry over to production at the relaunch.
 0. Publish DEV once more first, so the live game sends the new S3 measures: File → Save to File As → `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_S3_2026-10-17.rbxl`; Studio API access stays OFF; File → Publish to Roblox (DEV); Creator Hub → Servers → Shut down all servers. This publish also brings the sniper tower (SNP.1, D-044).
 1. Make Lighthouse Keepers DEV **Public**: in the DEV Studio window, Game Settings → Permissions → Public (or the experience's Public/Private switch in Creator Hub).
 2. The store page on DEV: icon and thumbnails from `assets/` (L1.5 files), description and title A from `assets/store/STORE_PAGE.md`.
 3. Creator Hub → DEV → Ads Manager: a small sponsored campaign of your choosing. Run it for at least 48 hours, as a diagnostic, not for ranking. If thumbnail or icon testing is offered, use icon A and icon B from `assets/icons/`.
 4. Run the S3.2 sessions with `docs/PLAYTEST_KIT.md`: 5 or more, a real phone in each, one with no verbal help.
 5. After 48 hours and then weekly: send Claude the Creator Hub numbers listed in the kit's §3 and the observer sheets. Claude makes the weekly change (S3.3) and writes the review (S3.4). The GO/NO-GO (S3.6) is yours.
To end the test: set DEV back to Private, and turn the mode test off (`Config.MODE_TEST_ENABLED = false`, ask Claude).

CHECKPOINT: SNP.1 Sniper tower (the owner's idea) — 🟦 (Script Analysis unmeasured; no screenshot: Studio's 3D view drew only white for every capture this time, in Edit too, while the HUD drew normally; the owner judges it in play)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF (probe refused, error 7)
BACKUP: ServerStorage.Backups.SNIPER_before_2026-10-17 (Config, StatPipeline, SoundFx, CreatureService, Platform, NetGuard, Encounter, EventLog, NetGuardSpec, SecuritySpec) · restore points "SNIPER before", "SNIPER passed"
BUILT (D-044):
- `SniperService` (new, server, --!strict): builds the tower into the island at boot (legs, braces, platform with rails, roof, ladder, rifle on a swivel, a lantern), the climb prompt, the climber's state, and the `SniperAction` handler: the shot is traced from the muzzle along the aimed line against the creature table (`CreatureService.damageRay`, first creature only) and a tracer flashes for everyone. Pure rules (`rayHit`, `canClimb`, `canFire`) are unit-tested.
- `SniperView` (new, client, --!strict): first-person view, crosshair with a reload bar, hold right mouse / L2 (or ZOOM on touch) to zoom to FOV 20 with a dark scope ring, click / R2 / FIRE to shoot, E / B / CLIMB DOWN to come down.
- `CreatureService`: `damageRay`; a player up the tower is not a valid target. `Encounter`: wires it; on-foot attacks are refused while up the tower. `Config.SNIPER_*`, `StatPipeline.sniper()` + 3 STATS rows, the `sniper` sound (the cannon's asset, sharper), `SniperAction` in the remotes, its rate (3/5) and its contract row; run summary counts "Sniper tower shots".
TESTRUNNER (DEV, Play server): **258 passed, 0 failed** (7 new in SniperSpec; NetGuard and Security specs list the new remote).
PLAY TEST (DEV, one player, keyboard, runtime helpers to sail and to publish a target position): climbed with E (first person, walk speed 0); 12 shots in the prologue: 9 kills (6 Sand Skitters at 1 shot each, 3 Rock Crabs at 2 shots each in a Spring Tide); in a second run 9 tracers seen on the client for 9 shots; stayed up through the start of Night 1 firing 30 more shots (19 kills in total): health stayed at 100 while up the tower; climbed down with E: walk speed 16, jump power 50, at the foot of the ladder, the prompt back on. The first run found a bug (the run counters for sniper shots did not exist, so the tracer and sound after the damage never ran): fixed, then 0 errors from game scripts.
NUMBERS: D-044 (all new; no existing number changed).
MIRROR: 166 scripts in DEV, digest identical to `src/` (1e1412bc).
NOT DONE: screenshots (Studio's 3D view was blank white for captures); a phone and a controller test; the tower's look is the owner's call.
OWNER: in the next DEV publish (the S3 step 0 package now also carries the sniper tower), climb the tower on the island's west side and tell me if the numbers feel right.
S3 step 0 save done · 2026-10-17 22:47 UTC · the owner saved `backups/LighthouseKeepers_DEV_S3_2026-10-17.rbxl` (1.1 MB, checked on disk). The owner uploaded a thumbnail and icon to DEV; the store page still showed the default image at 22:47 (likely image review pending). Publish not yet reported.
S3 step 0 PUBLISHED · 2026-10-17 23:16 UTC · the owner published DEV (project chat: "DEV published"); the S3 measures (MomentKind, BeamModes) and the sniper tower (SNP.1) are live on DEV. The owner reports the DEV icon and thumbnails now show. Next: S3 steps 1–5 (owner) and the owner's live check of the sniper tower.

CHECKPOINT: MP.2 Trader on the menu pattern — ✅ in DEV (Script Analysis unmeasured; the loot tiles' 3D icons were not visible in Studio captures because Studio's 3D view drew white; the owner judges the look)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF
BACKUP: ServerStorage.Backups.TRADER_before_2026-10-17 (Trader, Bench, Tiles) · restore points "TRADER before", "TRADER passed"
WHY: the roadmap waits on the public test; the owner liked the new shop, and the Trader was the next menu every voyage opens (the S2.5c record left it on the old layout).
BUILT:
- `Trader.client` rewritten on `UI/Tiles` (--!strict): SALVAGE tab (a tile per kind of loot carried with its count and value; the detail pane shows the loot rule, what each pays and the total; one SELL ALL button: the server only sells everything) and ISLAND STOCK tab (the merchant's six items as glyph tiles with their Shell price, how many bought, for you or the whole crew, how long it lasts; dimmed under "The Trader sells by day" at night; one tap buys, Shells being the crew's voyage pool like the bench). A sale shows "Sold for N Shells"; by day with nothing to sell it opens on the stock.
- `UI/Tiles`: `menu:setAlerts` draws critical states (lamp dark or low fuel, tower breaching, health critical; `Vitals.criticalChips`) as pills under the header. The new workbench had lost the old bench's vitals row in S2.5c: it now shows them too.
- No server script, remote, price or save field changed (TraderRequest "sellAll", MerchantRequest "buy" as before).
TESTRUNNER (DEV, Play server): **258 passed, 0 failed**.
PLAY TEST (DEV, one player, runtime helpers to sail and to give loot in the Studio memory store): opened the Trader with E; 5 crab claws, 2 sea glass, 1 black pearl shown (20, 66, 130 Shells); SELL ALL: crew Shells 120 → 336 (+216), the sack empty; at night the stock was dimmed under its divider; by day bought the Oil Bundle: Shells 336 → 306, lamp fuel 0 → 40. The FUEL 4% · CRITICAL and LAMP DARK alerts showed while it was open. 0 errors from game scripts.
SIZES: PC window 2004×985: smallest tap 58.4 px; simulated 926×428 and 667×375: smallest tap 56.1 px; no text overflowing at any size.
SCREENSHOTS: `assets/screens/trader_menu/`.
MIRROR: 166 scripts in DEV, digest identical to `src/` (9c75663d).
OWNER: it reaches players with the next DEV publish.

CHECKPOINT: MP.3 the BAG on the menu pattern — ✅ in DEV (Script Analysis unmeasured; the keeper picture and item icons could not be checked in Studio captures: its 3D view drew white; the owner judges the look)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF
BACKUP: ServerStorage.Backups.BAG_before_2026-10-17 (Inventory, CodeBox) · restore points "BAG before", "BAG passed"
BUILT:
- `Inventory.client` rewritten on `UI/Tiles` (--!strict): KEEPER tab (your keeper: a turnable copy of your character holding the equipped weapon, with health, damage blocked and weapon damage per second; one tile per equipped slot, empty cosmetic slots shown; Fire Shell crates; Codes), WEAPONS, ARMOR, COSMETICS, SUPPLIES (crates and voyage loot). The detail pane compares with what is equipped (StatPipeline) and has one EQUIP / UNEQUIP button (starter gear stays on until something else is equipped; crates and loot explain where they are used).
- The harbor HUD part is unchanged: the BAG button, B / D-pad Up, the Pearls pill and CODES (which now opens the BAG straight at the code box).
- `CodeBox.send`: the code-sending rule (one code every 10 s) shared by the title screen box and the BAG's new box.
- No server script or remote changed.
TESTRUNNER (DEV, Play server): **258 passed, 0 failed**.
PLAY TEST (DEV, harbor, Studio memory store; runtime helper gave a Storm Harpoon, a Storm Blue Coat and 3 crates): B opened it on KEEPER; equipped the Storm Harpoon (server profile: weapon StormHarpoon), equipped then unequipped the Storm Blue Coat (coat CoatStormBlue, then none); typed LIGHTHOUSE and pressed Redeem: "Code redeemed: 10 Pearls!" (50 → 60). 0 errors from game scripts.
SIZES: PC 2004×985: smallest tap 56.5 px; simulated 926×428 and 667×375: smallest tap 56.1 px, no text overflowing; the code field was narrow on 667×375 and was widened after the screenshot.
KNOWN: the code field is redrawn when new profile data arrives, so a half-typed code can clear then (rare: data arrives on changes).
SCREENSHOTS: `assets/screens/bag_menu/`.
MIRROR: 166 scripts in DEV, digest identical to `src/` (8a3c7939).
NEXT: the owner's two island changes, ISL.1 (sniper tower into the water with a bridge) and ISL.2 (lighthouse island about 50% bigger).

CHECKPOINT: ISL.2 lighthouse island about 50% bigger + ISL.1 sniper tower in the sea with a small bridge (the owner's asks, 2026-10-17 23:42) — ✅ in DEV (Script Analysis unmeasured; the owner judges the look)
DATE: 2026-10-17
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF (probe: error 7)
BACKUP: ServerStorage.Backups.ISL_before_2026-10-17 (the terrain region, IslandProps, Decor, Config, SniperService, Encounter, LampService, IslandBuilder) · restore points "ISL before", "ISL passed"
BUILT (numbers in D-045, all revisable):
- Terrain stretched outward from 44 studs: land above the sea 32,076 → 47,672 square studs (x1.49 measured), flat ground x1.43; the middle (lighthouse, shop, bench, Trader) unchanged. Outer sea rocks, the dock, the path lanterns, the keeper's hut, the oil shed (and the oil pile with it), crates and wrecks moved out to match.
- Creatures climb out of the sea at 117 studs (was 92); ground grid 140 (635,136 samples, built in 3.1-4.0 s at boot in Studio, in the background); the beam's visual reaches the new shore (measured end 115 studs out at sea level).
- Sniper tower: in the sea off the east beach on a wooden deck with pilings and rails; an 11-stud bridge to the sand, built automatically toward the lighthouse; rifle range 250.
- `GroundSpec` tolerance changed as recorded in D-045 (99% within 0.2 studs, none over 1 stud).
TESTRUNNER (DEV, Play server): **258 passed, 0 failed**.
PLAY TEST (DEV, Studio memory store; runtime helper kept the lamp fuelled and, in the second run, the tower repaired): the tower and bridge were built (Deck, Bridge, 8 pilings); walked from the beach over the bridge to the climb spot (MoveTo reached); climbed (OnSniperTower set); 14 shots at creatures 127-139 studs away: 8 kills (3 Rock Crabs, 5 Sand Skitters). Night 1 with nobody defending: creatures walked in from the new ring and reached the tower (the tower fell, as expected with no defence). 0 errors from game scripts.
SCREENSHOTS: `assets/screens/island/` (before and after from above; the tower in the sea; the deck and bridge).
MIRROR: 166 scripts in DEV, digest identical to `src/` (ef2b0250).
OWNER: the next DEV publish carries the Trader and BAG menus, the bigger island and the tower in the sea. Before it: File → Save to File As → `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_ISL_2026-10-17.rbxl`; Studio API access stays OFF; then File → Publish to Roblox (DEV only).

CHECKPOINT: ART.1 ForgeGUI models for the five block-built monsters — ✅ in DEV (Script Analysis unmeasured; the owner judges the look)
DATE: 2026-10-18
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF (probe failed as expected)
BACKUP: ServerStorage.Backups.ART5_before_2026-10-18 (Art listing, CreatureService) · restore points "ART5 before", "ART5 passed"
BUILT:
- Inserted the owner's five ForgeGUI models (asset ids in `assets/ART_SOURCES.md`). Each is one MeshPart with one SurfaceAppearance (about 1 stud as uploaded), so each creature still draws one part (rule 9). Placed in `ServerStorage.Art` under the art names, without the package link: Spitter Eel 4.0 studs tall, Puffer Mine 3.4, Ghost Lantern 2.6 (it hovers 3 up), Tide Witch 3.8, Coral Shaman 3.4.
- Facing: the eel already faced forward; the puffer, ghost, witch and shaman faced sideways and got `YawOffset` -90 (checked front-on in Edit and in play).
- Glow eyes: the night-time glow eyes floated above the new heads, so `CreatureService` now reads two optional art attributes, `EyeAt` (where the art's eyes are) and `EyeSize`, and puts the eyes on the face; creatures without them are unchanged.
TESTRUNNER (DEV, Play server): **258 passed, 0 failed**.
PLAY TEST (DEV, Studio memory store; runtime helper kept the lamp and tower up and spawned each new monster in Day 1 and Night 1): all five drew from the new models, one part each, faced the way they walked, eyes on their faces; the ghost floated as before. 0 errors from game scripts.
SCREENSHOTS: `assets/screens/creatures_forgegui/` (lineup_front.jpg; front_*.jpg in Edit; game_day_*.jpg and game_night_all.jpg in play).
MIRROR: 166 scripts in DEV, digest identical to `src/` (893de206). The meshes live in the place (`ServerStorage.Art`), not in `src/`.
OWNER: judge the five looks; any one can go back to its block shape by deleting it from `ServerStorage.Art`. They ship with the next DEV publish.

CHECKPOINT: F10.2 First 10 minutes, pass 2: the opening on the bigger island — ✅ in DEV (scripted first-timer, not a person; Script Analysis unmeasured)
DATE: 2026-10-18
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF (probe failed as expected)
BACKUP: ServerStorage.Backups.F10_before_2026-10-18 (IslandBuilder, OilShed) · restore points "F10 before", "F10 passed"
MEASURED with `tests/first_beam_hit_bot.luau` (fresh Studio memory profile; it boards, takes the wheel, then follows the coach: oil → tank → lamp → aim; times since the script took control, corrected by the PlayerReady offset; every run at 60 fps):
- Bigger island as built in ISL.2: first beam hit **41.1 s** (pass 1 on the old island: median 37.7 s). Cause: the oil pile had moved out with its shed, so the opening walk (landing → oil → fuel tank) was 14 studs longer (125 instead of 110).
- FIXED: the oil pile and the oil shed are back at their old spot (pile at (48, 20), `IslandBuilder`); the bigger island's ground there is still flat at the lighthouse's height.
- After the fix: **39.0 · 38.2 · 36.8 s, median 38.2 s** (target ≤ 45 s). Landing about 22 s after control as before; oil about 8 s after landing.
- The creature ring moving out (92 → 117) does not slow the first beam hit: the first crab comes out with the light just ahead of the sweep, and beam damage does not depend on distance.
TESTRUNNER (DEV, Play server): **258 passed, 0 failed**. 0 errors from game scripts in the runs.
STILL OPEN from pass 1: on boarding, the camera faces the mast and cargo, so the wheel is behind a first-timer (a camera turn toward the wheel would help).
MIRROR: 166 scripts in DEV, digest identical to `src/` (9c6f282d).
NEXT: (c) the ForgeGUI crab and skitter models when the coordinator sends their ids; then (a) the older screens on the menu pattern.

CHECKPOINT: ART.2 ForgeGUI crab and skitter — ✅ in DEV (Script Analysis unmeasured; the owner judges the look)
DATE: 2026-10-18
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF (probe failed as expected)
BACKUP: ServerStorage.Backups.ART7_before_2026-10-18 (the earlier RockCrab mesh, Creatures) · restore points "ART7 before", "ART7 passed"
BUILT:
- Rock Crab (107087579544073) and Sand Skitter (99470346593772): ForgeGUI generations made to look like the owner's designs; they are not the owner's own .glb files, which he can still import by hand (File → Import 3D) and drop into `ServerStorage.Art` under the same name.
- Each is one MeshPart with one SurfaceAppearance, so each creature still draws one part. Sized to the old crab's footprint (3.13 studs across; the skitter keeps its 0.6 scale), `YawOffset` -90 (both faced sideways), glow eyes placed on the face with `EyeAt`/`EyeSize`.
- `Creatures.SandSkitter.art` is now "SandSkitter" (it used the Rock Crab's model, smaller). No gameplay number changed.
TESTRUNNER (DEV, Play server): **258 passed, 0 failed**.
PLAY TEST (DEV, Studio memory store; runtime helper spawned a crab and two skitters by day): one part each, facing the way they walk, eyes on the face. 0 errors from game scripts.
SCREENSHOTS: `assets/screens/creatures_forgegui/` (game_day_rock_crab.jpg, game_day_sand_skitter.jpg; edit_raw_*_side.jpg show them as they arrived).
MIRROR: 166 scripts in DEV, digest identical to `src/` (8a8fede1).
NEXT: the logbook page in the BAG (MP.4).

CHECKPOINT: MP.4 Logbook page on the menu pattern — ✅ in DEV (Script Analysis unmeasured; phone sizes are simulated layouts; the owner judges the look)
DATE: 2026-10-18
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF (probe failed as expected)
BACKUP: ServerStorage.Backups.MP4_before_2026-10-18 (Inventory, PlayerData, Tiles) · restore points "MP4 before", "MP4 passed"
SCOPE: of the older screens, only the logbook fits the menu pattern (it had no page); Settings and Results stay as they are (logged in DECISION_LOG).
BUILT:
- BAG → LOGBOOK tab (`Inventory.client`): "Your logbook" tile first (found / total for Creatures, Big monsters, Evolutions, Forecasts, with each row's Pearls: 15 / 10 / 10 / 5), then every found entry (creatures drawn as their own models from `CreatureTemplates`; evolutions and forecasts as icons), then the rest dimmed under NOT FOUND YET. The detail pane gives the entry's kind, how it is found, a field note (creatures), the evolution's or forecast's own text, the row's progress and its reward ("Paid" once complete).
- `PlayerData` adds `logbook` (found entries) to the `GearData` view; API_CONTRACTS row updated. Rewards are still paid only by LogbookService; this page only shows them.
- `UI/Tiles`: on phones the tab gap is 6 instead of 14 so six tabs stay at least 56 px wide (the first measure gave 55.0 px on a 667×375 layout).
TESTRUNNER (DEV, Play server): **258 passed, 0 failed**.
PLAY TEST (DEV, Studio memory store; runtime helper marked 7 entries found): B opened the BAG, LOGBOOK showed 7 / 14 with 4 / 7, 1 / 2, 1 / 2, 1 / 3; Rock Crab's detail showed its model, note, 4 / 7 and 15 Pearls. Smallest tap: real 724×507 window 56.1 px; simulated pc 64.0, laptop 56.2, large phone 56.1, small phone 56.1 px; no text overflowing at any size. 0 errors from game scripts.
SCREENSHOTS: `assets/screens/logbook_menu/` (the two 724×507 shots were taken before the creature icons were drawn a little larger).
KNOWN: on a 667×375 phone the six tab labels are small (the longest word, COSMETICS, decides the shared size).
MIRROR: 166 scripts in DEV, digest identical to `src/` (00f8d658).
NEXT: nothing left on the coordinator's list (b, c, a done); the DEV publish waits for the owner.

CHECKPOINT: PH.1 Phone pass — ✅ in DEV as a SIMULATED LAYOUT test (not an emulator, not a phone; Script Analysis unmeasured)
DATE: 2026-10-18
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF (probe failed as expected)
BACKUP: ServerStorage.Backups.PH1_before_2026-10-18 (Layout, SniperView, Gauges, Results) · restore points "PH1 before", "PH1 passed"
METHOD: Studio's Device Emulator cannot be switched from a script, so every screen was drawn with the game's Studio-only layout simulator (HudSimulate: 667×375 small phone, 932×430 large phone, 1180×820 tablet; touch layout on; the joystick start area (left 40 % × bottom 45 %) and the jump button (70 px or 120 px, Roblox's own placement) drawn). A script measured every visible button and text box (size, inside the screen, over the joystick area, over the jump button) and every text that did not fit. States: harbor, island prologue near the bench, night with the tower breaching, the lamp keeper's controls, Results; the Tiles menus (shop, bench, Trader, BAG) were measured in S2.5c/MP.2–MP.4 (≥ 56 px).
FOUND AND FIXED:
- HEALTH (read "HEAL…") and BEAM · AUTO-SWEEP (ran past its pill) on phones: the phone plates are 172 px wide (were 150/146).
- Prompt cards side by side cut "Upgrade Lighthouse" to "Upgrade…" on a small phone: on phones they stack, full width, 50 px tall.
- "TOWER · BREACHING" / "HEALTH · CRITICAL" cut off on phones: a gauge narrower than 120 px shows the state alone ("BREACHING").
- Sniper tower on a short touch screen: CLIMB DOWN sat 11 px from the top (under the Roblox top bar); now FIRE 104 px at the bottom right, ZOOM 84 px beside it, CLIMB DOWN 190×56 above them (top edge 177 px down on a 375 px screen); the joystick and jump button are hidden while up the tower (nobody walks there), and come back on climbing down unless a menu is open.
- Results: the share line was a 20 px text box (now 44 px); the crew card "Everyone pitched in / No single job stood out" was cut off on phones (now "All hands / Everyone pitched in"); the tablet's Pearls note now reads "Survive nights for Pearls".
AFTER (measured): small phone, large phone and tablet: every button and text box ≥ 44 px; none over the joystick area or the jump button; no fixed text cut off. Only player names cut off with "…" (e.g. "Lighthouse8282 (you)" on the crew card), by design.
CHECKED BY GEOMETRY (these screens do not take the simulator): the BAG button on a phone is 52 px, 11 px left of the jump button; CODES 52 px further left; on a tablet the BAG is 62 px, 12 px left of the 120 px jump button. Results and every menu hide the joystick and jump button while open (UiKit.pushModal), as does the lamp keeper's view.
FOR THE OWNER ON A REAL PHONE (cannot be checked in Studio): (1) the LAMP FUEL bar and the voyage title sit in the Roblox top bar (HudTopBar): check they do not cover the Roblox menu, chat or leaderboard buttons on your phone; (2) climb the sniper tower and check FIRE, ZOOM and CLIMB DOWN reach your thumb and the joystick is gone; (3) the six BAG tabs are small on a 667-wide phone: check you can read them; (4) the frame rate during a night-7 swarm.
TESTRUNNER (DEV, Play server): **258 passed, 0 failed**. 0 errors from game scripts.
SCREENSHOTS: `assets/screens/phone_pass/` (before/after small phone island and results, night breach, lamp keeper, tablet).
MIRROR: 166 scripts in DEV, digest identical to `src/` (acaa324e).
NEXT: SND.1 sound licence audit.

CHECKPOINT: SND.1 Sound licence audit — ✅ in DEV (the owner listens to the two new loops after the next DEV publish)
DATE: 2026-10-18
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF
BACKUP: ServerStorage.Backups.SND1_before_2026-10-18 (Storm) · restore points "SND1 before", "SND1 passed"
FOUND: the place has no Sound instances; every sound comes from `Shared/SoundFx` or `Client/Storm`. 8 uploaded audio ids and 10 built-in Roblox sound files. Each uploaded id was looked up with MarketplaceService:GetProductInfo (name, uploader, description):
- 6 from ProSoundEffects (Roblox's licensed sound-effects library; each says "Courtesy of Pro Sound Effects"): cannon/sniper 9114361763, wind 9120610116, thunder 9120016241 / 9120016037 / 9120016256, beam hum 9126086336. Cleared.
- 2 from private uploaders with no source given: storm waves 3159087887 ("Waves", camcool12354) and storm rain 365362615 ("Rain sound effect", InfiniteYield). Not clearly cleared → REPLACED.
- Built-in `rbxasset://sounds/...` files ship with the Roblox client. Cleared.
REPLACED: waves → 9119677305 "Surf Ocean Wave Impact On Zuma Beach 4 (SFX)"; rain → 9112793875 "Heavy Rain 3 (SFX)" (both ProSoundEffects). Loudness matched by measurement (average PlaybackLoudness over 40 s: old waves 103.8 / new 58.8, old rain 82.2 / new 19.9), so `Storm.client` raises them by 1.8× and 4× (calm waves now volume 0.81).
CHECKED: in Play the three storm loops load and play with the new ids; TestRunner **258 passed, 0 failed**; 0 errors.
NOTE: the licence status is inferred from the uploader account and the asset descriptions on Roblox; nothing was bought or downloaded.
FOR THE OWNER: listen to the harbor/island waves and a night's rain after the next DEV publish; say if either is too loud or too quiet.
MIRROR: 166 scripts in DEV, digest identical to `src/` (501ceba5).
NEXT: SA.1 Script Analysis clean-up.

CHECKPOINT: PH.1b Phone pass in Studio's Device Simulator — ✅ in DEV (a simulator, not a phone)
DATE: 2026-10-18
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF · Device Simulator reset to default afterwards
BACKUP: SniperView is in ServerStorage.Backups.PH1_before_2026-10-18 · restore point "PH1b passed"
METHOD: StudioDeviceSimulatorService (landscape) → Play → sail → island prologue by the bench; a script measured every visible button against Roblox's own TouchGui jump button and thumbstick (their real positions on that device).
RESULTS (island HUD):
- Samsung Galaxy A06, viewport 705×338: 3 buttons, all ≥ 44 px, none over the jump button (70 px at 610,190) or the thumbstick, nothing off screen.
- iPhone 17 Pro, viewport 750×381: same; jump 70 px at 655,233.
- iPad 10th generation, viewport 1179×819: same; jump 120 px at 1009,551.
- Only text cut off: the crew card's player name ("Lighthouse8282 (you)" → "…", by design) on the two phones.
FOUND AND FIXED: the sniper tower on the iPhone showed the desktop layout (the simulator reports a keyboard as well as touch, so touch is not detected) and CLIMB DOWN, placed 300 px up, sat over the top bar. CLIMB DOWN now goes to the bottom right on any screen under 500 px tall (touch: above FIRE and ZOOM). Checked: CLIMB DOWN 190×56 at the bottom right of the iPhone screen, joystick and jump button hidden while up the tower.
LIMIT: in the simulator a touch device also reports a keyboard, so the game's touch-only layouts (FIRE/ZOOM buttons, touch prompt sizes) show only on a real phone; those were checked in PH.1's layout simulator.
TESTRUNNER (DEV, Play server): **258 passed, 0 failed**. 0 errors.
SCREENSHOTS: `assets/screens/phone_pass/emulator_*.jpg`.
MIRROR: 166 scripts in DEV, digest identical to `src/` (fcca71bc).
NEXT: SA.1 Script Analysis clean-up.

CHECKPOINT: SA.1 Script Analysis clean-up — ✅ in DEV (counted with luau-lsp, not Studio's panel)
DATE: 2026-10-18
STUDIO INSTANCE: Lighthouse Keepers DEV, placeId 102473202766620 verified · API access: OFF
BACKUP: ServerStorage.Backups.SA1_before_2026-10-18 (the 13 scripts touched) · restore points "SA1 before", "SA1 passed"
HOW IT WAS COUNTED: Studio's Script Analysis panel cannot be read by a script, but luau-lsp 1.70.1 is already installed at `C:\Users\q_n\tools\luau-lsp\1.70.1` with the Roblox type definitions. Commands (nothing downloaded): `rojo sourcemap src\default.project.json -o sourcemap.json` (Rojo 7.7.1 from Aftman's tool storage), then `luau-lsp analyze --platform roblox --sourcemap sourcemap.json --defs=globalTypes.None.d.luau <every .luau under src except ItemDrafts>`.
BEFORE: 812 findings: 791 type errors and 21 lint warnings (11 unused locals, 6 unused functions, 2 shadowed locals, 2 unused imports).
FIXED (no behaviour change):
- EventLog: its per-run counter table had no type, so every counter it set was a "key not found" (550). Typed as a map.
- StatPipeline (56): the optional modifier tables are typed where they default to {}.
- Shop and BAG stat lines, RescueService's carried-castaway parts, CreatureService's player target: types written out.
- Results: `renderGoal` was a global used before it was defined; now a forward-declared local.
- Dead code removed: two `groundAt` helpers (CreatureService, LootService; the ground grid replaced them), five unused helpers and seven unused locals in `Main.client`, unused locals in Coach, LobbyBuilder and UI/Controls (a shadowed `s` renamed). ShopService's old `sell` (selling moved to the Trader) is kept and marked unused.
AFTER: 165 findings (162 type errors, 3 lint): 21 in the vendored ProfileStore (left as shipped), 24 in ProfileSchema and 2 in PlayerData (the save path; left alone on purpose), 26 in test specs, and the rest mostly the analyzer not following `pcall(handler, ...)` returns (EventBus, NetGuard, TestRunner) and `for … in x or {}` loops (UI files), plus Controls' item card (19) and UiSkin's Config key (8).
TESTRUNNER (DEV, Play server): **258 passed, 0 failed**. PLAY TEST: a voyage to night 1, 12 creatures killed, tower breached, Results drawn with the next goal; 0 errors on server and client.
MIRROR: 166 scripts in DEV, digest identical to `src/` (25595dce).
NEXT: the readiness list (PH.1, SND.1, SA.1) is done; the DEV publish waits for the owner.
