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
