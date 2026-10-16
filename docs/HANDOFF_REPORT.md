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
