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
