# Lighthouse Keepers — Production Roadmap
## From the current published build to relaunch and live operations

**Companion to:** `architecture.md` v2.0 · **Audit:** `docs/AUDIT_2026-10-16.md`
**Toolchain:** Roblox Studio + Studio MCP; Rojo export-only mirror in `src/`; TestRunner in Studio.
**Estimates:** owner directs ~5 days/week; ranges are calendar weeks. To relaunch (L1): **~16–20 weeks**. Checkpoints are fixed; durations are guesses.

---

## 0. How to use this document

### Status values
`⬜ Not started` · `🟨 In progress` · `🟦 Checkpoint pending` · `✅ Passed` · `🟥 Blocked`

### Checkpoint protocol — every substage, all 8, in order
1. **Tests:** full `TestRunner` run via `execute_luau`; summary pasted; zero failures.
2. **Static:** zero Script Analysis warnings in every module touched.
3. **Play test:** steps run via `start_stop_play`; `get_console_output` zero errors; `screen_capture` where UI is involved. **Production window: Studio API access confirmed OFF before Play.**
4. **Numbers:** every metric named in the checkpoint measured and written down.
5. **Restore point:** Studio version-history save `<ID> passed` plus `ServerStorage.Backups.<ID>_before_<date>` made *before* the edits.
6. **Mirror:** Rojo export to `src/`, committed with the substage ID (never force-push; never push `.rbxl`, backups, `work/`, `vendor-review/`, credentials).
7. **Handoff record** appended to `docs/HANDOFF_REPORT.md`.
8. **Approval** line in `docs/DECISION_LOG.md` — in unattended mode (D-010) this is `auto-approved (unattended)` for every substage except publish substages and GO/NO-GO gates, which wait for the owner. **Publishing is a separate owner action** and is never part of a checkpoint Claude performs.

### Studio safety (every substage, before the first action)
`list_roblox_studios` → identify the instance by PlaceId **132065051336560** → never act on another instance (DEADZONE, Outlaw City) → production window: API access OFF before any Play.

### Stage gates
A stage exits when every substage is ✅ and its exit numbers are recorded. **GO/NO-GO** gates (S3, B1) can stop the project or send it back.

---

## 1. Master tracker

| Stage | Name | Substages | Est. weeks | Gate | Status |
|---|---|---|---|---|---|
| R0 | Re-baseline | 6 | 0.5 | Decision | 🟨 (R0.2, R0.4 wait on owner actions) |
| R1 | Safety & structure | 9 | 2 | Numeric + owner publish | 🟨 |
| S2 | First session & voyage length | 8 | 1.5 | Numeric + owner publish | 🟦 (S2.8 DEV publish waits for the owner) |
| S3 | **Public test** | 6 | 2–3 live | **GO/NO-GO** | 🟨 provisional GO (D-018); live test on DEV (D-016) not started |
| S4 | Performance & mobile | 7 | 2 | Numeric | 🟨 |
| S5 | Domain split & UI refactor | 8 | 2–3 | Standard | 🟦 |
| S6 | Content (owner's six requests) | 7 | 4–5 | Standard | 🟦 |
| S7 | Return systems | 6 | 2 | Standard | 🟨 |
| B1 | **Closed beta** | 6 | 3 | **GO/NO-GO** | ⬜ |
| L1 | Relaunch | 7 | 2 | Checklist | ⬜ |
| LO | Live operations | ongoing | — | Cadence | ⬜ |

---

## 2. Stage R0 — Re-baseline (3 days)

Purpose: freeze the old direction, record the decisions, set up the new working files. No Studio code changes.

| ID | Substage | Deliverables | Passes when | Verify |
|---|---|---|---|---|
| R0.1 ✅ | Decision D-001 | **Accepted 2026-10-16 (Option A).** Record only. | Line in `DECISION_LOG.md` | — |
| R0.2 🟦 | Freeze old repo | In `moeelzayyat/lighthousekeepers`: `multiship-test` tagged `frozen-2026-10-16`; repository archived; test experience 10771229467 left private and untouched | Tag pushed; archive flag set | Owner (GitHub) |
| R0.3 ✅ | New repository | `moeelzayyat/lighthousev2` cloned to `C:\RobloxProjects\Lighthousev2`; `src/` and `tests/` copied from the old repo's `main`; old `docs/` copied to `docs/legacy/`; this docs set at the root | Tree matches `architecture.md` §4.3; first commit pushed | Repo |
| R0.4 🟦 | Studio baseline | In the production window (API off): `list_roblox_studios` verified; full script export to `src/` at the current live build; restore point `R0 baseline`; local `.rbxl` saved by the owner | Export committed; restore point exists | Studio, repo |
| R0.5 ✅ | Live build identity | Compare the Studio production scripts with `src/` (old `main` 854f4e9) via `script_read` hashes; record which build is live and any drift | Line in `DECISION_LOG.md`; drift listed | Studio (read-only, API off) |
| R0.6 ✅ | Title and icon brief | D-009 accepted: write the owner instruction to rename the experience and set max players 4 in the handoff record; store section of `ART_BIBLE.md` finalised; icon production via Studio AI image generation attempted first, contractor as fallback | Instruction written; `ART_BIBLE.md` final | — |

**R0 exit:** all ✅; `CURRENT_PHASE.md` = R1.1.

---

## 3. Stage R1 — Safety & structure (2 weeks)

Purpose: protect production saves, close the validation gaps, add the test harness and the bus, remove the multi-ship code from the live path. Ends with an owner publish.

| ID | Substage | Deliverables | Passes when | Verify |
|---|---|---|---|---|
| R1.1 🟦 | TestRunner | `ServerStorage/Tests/TestRunner` (`describe/it/expect`, async, mocks); 3 sample tests | `execute_luau` prints `3 passed, 0 failed` | TestRunner |
| R1.2 🟦 | Pure logic extraction | `WaveDirector.nightPlan(night, crew, forecast, config)` and `Voyage.pearlsFor(night, won, config)` extracted from `GameState` with no Instances; `GameState` calls them | Tests: nights 1/4/7/13 × crew 1–4 × 3 forecasts match today's numbers exactly (table in `TEST_PLAN.md`); win 7 = 12, win 13 = 18 | TestRunner |
| R1.3 🟦 | ProfileStore | Inserted and pinned; `PlayerDataService` on ProfileStore (`LighthouseKeepers_PlayerData_v1`, same keys); schema v2 + `MigrationService` with v1 fixture and type validation; `GrantService.Grant(claimId, rewards)` as the only Pearl/item writer; `SessionLock`/handoff/reclaim code removed from the live path | Mock-store tests: v1 fixture loads as v2 with values intact; a non-number `pearls` becomes default and is logged; duplicate claimId grants once; quick rejoin keeps Pearls; `BindToClose` saves. Owner's real profile **not touched** (Studio API off) | TestRunner (ProfileStore.Mock) |
| R1.4 🟦 | Remote contracts | `docs/API_CONTRACTS.md` complete for all 29 remotes; type guards and token buckets; `BuyUpgrade` gets Ready + phase + bench distance + capped replay map; `GearAction`, `SetReady(false)`, `ReportDevice` throttled; `Attack` finite checks; Loadout `handled` capped | Security tests: 50× spam on each remote → state changes ≤ rate; non-crew Shell spend rejected; ±inf target rejected | TestRunner |
| R1.5 🟦 | Voyage isolation | `GameState.run` body in `pcall` per voyage; on error: log, reset, crew back to the deck with a message | Injected error mid-night → next voyage starts cleanly; console shows one `ErrorReport` | Play test |
| R1.6 🟦 | Event bus + funnel | `EventLog` exposes typed `Publish/Subscribe`; `docs/EVENTS.md` catalog; `AnalyticsService` wrapper emits the funnel (`Joined`…`Left`) and economy events | Play test shows each funnel step in the Analytics dashboard within 24 h | Analytics |
| R1.7 🟦 | Multi-ship removal from `Main` | Harbor/isle role switch, `Voyages`, `IsleAdmission`, `HarborDepartures`, `PlaceRole` removed from production `Main`; `MULTI_SHIP_ENABLED`/`TELEPORT_ENABLED` and the `MULTISHIP_TEST` block deleted from Config; server size set to **4** in Game Settings (owner) | Boot log shows no multi-ship services; a 4-client Studio test: 4/4 auto-sail, SAIL NOW at 2, a 5th client cannot join | Play test (4 clients) |
| R1.8 🟦 | Admin tools | `AdminDataService`: inspect, grant, rollback to a 7-day snapshot store; whitelisted channel (owner UserId only) | Rollback of a mock profile restores the snapshot; a non-whitelisted call is rejected and logged | TestRunner |
| R1.9 ✅ | DEV cutover (owner publishes to the DEV experience, D-013; production cutover moves to L1.7) | Owner publishes; **"Shut down all servers"**; owner joins, profile loads with Pearls intact; one voyage; leave; rejoin; Pearls intact | Owner's live check recorded with the before/after Pearl count | Owner |

**R1 exit numbers:** TestRunner ≥ 60 tests, 0 failures; 0 Script Analysis warnings in touched modules; cutover check passed; funnel visible. → S2.1.

---

## 4. Stage S2 — First session & voyage length (1.5 weeks)

| ID | Substage | Deliverables | Passes when | Verify |
|---|---|---|---|---|
| S2.1 🟦 | Voyage definitions | `Definitions/Voyages`: Standard (7 nights, bosses 4/7) and Long (13 nights, bosses 4/7/10/13, boss every night from 8); `VoyageService` takes a definition; Long unlocked by a Standard win (`Unlocks.LongVoyage`) | `nightPlan` tests for both; a Standard win sets the unlock; the crew card offers Long only when a member has it | TestRunner, play test |
| S2.2 🟦 | Dawn Pearl banking | `GrantService` at each dawn with claimId `voyageId:night:userId`; HUD "+1 Pearl banked" with the lantern sound; Results shows the total banked | Leaving at night 5 keeps 4 Pearls on rejoin (mock); replay of a dawn claim grants once | TestRunner, play test |
| S2.3 🟦 | Night-1 safety | For `Stats.Runs == 0`: the emergency reserve refills once on the first Night-1 blackout; coach oil prompt forced; feed line | A 0-run player who never carries oil survives Night 1 once and loses Night 2; a 1-run player gets no refill | Play test ×2 accounts |
| S2.4 🟦 | First beam hit ≤ 45 s | Prologue tightened: first crab reaches the beam arc by 35 s; coach aim marker at 30 s if no hit | 5 fresh-account runs, unassisted script: median first beam hit ≤ 45 s | Console timestamps |
| S2.5 🟦 | Results and replay | One-tap **Sail again** (same crew, same server) and **Back to deck**; "your part" tile enlarged; run card text for sharing | Sail again starts a new voyage in ≤ 3 s | Play test |
| S2.6 🟦 | Controller aim | Right-stick beam aim; Focus/Leave on buttons; `InputController` replaces the four `inputMode()` copies | Full voyage completed with a controller in Studio | Play test |
| S2.7 🟦 | Store presence | Real title published (owner); icon A and B exported; 3 thumbnails 16:9; description updated | Files in `assets/`; owner uploaded | Owner |
| S2.8 🟦 | Publish (owner) | Owner publishes S2; restart servers | Live check: fast path, Night-1 safety, dawn banking seen on the owner's account | Owner |

**S2 exit numbers:** first beam hit ≤ 45 s median; Night-1 survival for a 0-run unassisted script = 100% (by construction); dawn grant idempotency test green. → S3.1.

---

## 5. Stage S3 — PUBLIC TEST (2–3 weeks live) — GO/NO-GO

Purpose: real players answer whether the loop retains, before content work.

| ID | Substage | Deliverables | Passes when | Verify |
|---|---|---|---|---|
| S3.1 🟦 | Diagnostic traffic | Small sponsored campaign (ads = diagnostics, not ranking); flags for icon A/B and title A/B/C ("13 Nights at the Lighthouse 🔦") | Playthrough visible per variant after 48 h | Creator analytics |
| S3.1b 🟦 | Mode test | Feature flag: half of new accounts get the 7-night Standard Voyage, half get Endless Storm (Best Night score, same difficulty curve) | Rematch rate and D1 play days per arm after 7 days; the winner becomes the default; if Endless wins, S4 adds a day-phase work pass (scavenging, building) | Telemetry |
| S3.2 🟦 | Prototype A sessions | 5+ sessions, 2–4 players, ≥ 1 real phone each, one with no verbal help; `PLAYTEST_KIT.md` thresholds | Observer sheets filled; run summaries pasted | Owner |
| S3.3 🟦 | Weekly iteration ×2 | Two data-driven passes (FTUE, difficulty, oil role, vote clarity); hypothesis + result logged | Shipped within the week each | `DECISION_LOG.md` |
| S3.4 🟦 | Signal read | First-play bounce (<60 s, 61–180 s), D1 play days, co-play days, qualified sessions; funnel conversion per step | Written review | Document |
| S3.5 🟦 | Role check | Per-role contribution from "your part": share of voyages where a non-Keeper had the Moment of the storm | ≥ 30% | Telemetry |
| S3.6 🟨 | Go/no-go | Written decision | Logged | Owner |

**GO (to S4) when, over the final 7 days:** Night-1 survival (unassisted new accounts) ≥ 50% · Sail again / rematch ≥ 60% of finished voyages · both beam modes used on purpose ≥ 70% (observer sheets) · first-play bounce lower in week 2 than week 1 · at least one tester describes an oil/cannon moment as the highlight.
**NO-GO (back to S2):** Night-1 survival < 30% after two passes, or rematch < 40%. **Shelve review:** the beam is not understood by most testers after two passes.

---

## 6. Stage S4 — Performance & mobile (2 weeks)

| ID | Substage | Deliverables | Passes when | Verify |
|---|---|---|---|---|
| S4.1 🟦 | Ground grid | Island height grid built at boot; `Ground.heightAt` reads the grid | 0 runtime raycasts from creatures (probe); heights within 0.2 studs of raycast samples | TestRunner, probe |
| S4.2 🟦 | 20 Hz step + snapshots | `SimulationStep` at 20 Hz; `buffer` snapshots over `UnreliableRemoteEvent` at 12 Hz, interest = whole island | Server send ≤ 30 KB/s per player at 45 creatures, 4 clients | Network probe |
| S4.3 🟦 | Client interpolation | Pooled models interpolate between snapshots; procedural walk/scuttle | No visible stepping at 12 Hz; 60 FPS PC | Play test |
| S4.4 🟦 | Render budget | Neon eyes, shared boss bar, no per-creature lights, client hit flash; rain per device; sound pool | ≤ 3 replicated instances per creature; ≥ 30 FPS on the owner's phone during a night-7 swarm | Real phone |
| S4.5 🟦 | Loot | Idle orbs static; bob on approach client-side | Orb replication only on spawn/pickup | Network probe |
| S4.6 🟦 | 4-client soak | 3 consecutive voyages, 4 clients, 2 bosses | Memory growth < 50 MB/h; 0 errors | Profiler |
| S4.7 🟦 | Publish (owner) | | Live phone check by the owner | Owner |

**S4 exit numbers:** send/player, FPS PC/phone, instances/creature, memory growth — all recorded in `PERFORMANCE_BUDGETS.md`. → S5.1.

---

## 7. Stage S5 — Domain split & UI refactor (2–3 weeks)

| ID | Substage | Deliverables | Passes when | Verify |
|---|---|---|---|---|
| S5.1 🟦 | Lifecycle | `Bootstrap` with 8 domains, `Init/Start`, asserted order, remotes created last | Boot log ordered; a swapped phase trips the assertion in a test | TestRunner |
| S5.2 🟦 | Dissolve `Main` | Remote handlers, oil carrying, tool building, routing, trader moved into their domains; `Main` ≤ 80 lines | Every remote still works (contract tests); diff reviewed | TestRunner, play test |
| S5.3 🟦 | Callback wiring → bus | `CreatureService.onKilled`, `PlayerData.onChanged`, `ShipRoster.onChange` etc. replaced by bus events | `EVENTS.md` complete; no cross-domain function assignment remains (`script_grep`) | Review |
| S5.4 🟦 | Definitions registry | `_Registry` validates all catalogs; loot tables must sum to 1; duplicate IDs fail boot | Broken sample fails boot with a clear message | Play test ×2 |
| S5.5 🟦 | UiKit split | `Tokens/Primitives/Controls/Gauges/Dialogs`; dead v1 API deleted; `Gear.client` deleted | Every screen renders unchanged (screenshot diff at PC + phone) | `screen_capture` |
| S5.6 🟦 | HUD single pass | Glass variant native to gauges; `glassTree`/`restyle` deleted | HUD identical at PC/phone/tablet sizes; `Hud.client` ≤ 900 lines | `screen_capture` |
| S5.7 🟦 | Stat pipeline | `StatPipeline` with `STATS.md` rows and caps; shop previews use it | Preview == in-voyage value test | TestRunner |
| S5.8 🟦 | Publish (owner) | | Live check | Owner |

**S5 exit:** TestRunner ≥ 120 tests; `Main` ≤ 80 lines; 0 warnings. → S6.1.

---

## 8. Stage S6 — Content: the owner's six requests (4–5 weeks)

| ID | Substage | Deliverables | Passes when | Verify |
|---|---|---|---|---|
| S6.1 🟦 | Bosses by crew + Long Voyage boss nights | One big monster per crew member on boss nights, different bearings; boss counts as 5 toward `MAX_CREATURES` | 4-client boss night: 4 bosses, budget within S4 numbers | Play test, profiler |
| S6.2 🟦 | Island merchant | Trader's day-phase stock from `Definitions/Merchant`: speed/damage boosts (capped), heal, tower shield, oil bundle; all wiped at Results | Purchases idempotent; wipe verified; Shell sink measured (late-run Shell balance down ≥ 40% vs baseline) | TestRunner, telemetry |
| S6.3 🟦 | Orbiting Blades | `Orbit` weapon archetype; merchant item first | Works on phone with no aiming; damage via `StatPipeline` | Play test |
| S6.4 🟦 | Quartermaster boosts & gear | Permanent capped boosts (+15% total cap), 2 new weapons, 1 armor; new profile fields with defaults | Migration fixture; cap test | TestRunner |
| S6.5 🟦 | New monsters ×3 | Spitter Eel, Puffer Mine, Ghost Lantern: telegraph ≥ 0.6 s, sound, loot table | Blind tester identifies each behaviour; budgets hold | Blind test |
| S6.6 🟦 | New monsters ×2 | Tide Witch, Coral Shaman | same | Blind test |
| S6.7 🟦 | Publish (owner) + playtest | Prototype B session | Rematch ≥ 60% maintained | Owner |

**S6 exit:** all six requests Implemented and Tested in the registry. → S7.1.

---

## 9. Stage S7 — Return systems (2 weeks)

| ID | Substage | Deliverables | Passes when | Verify |
|---|---|---|---|---|
| S7.1 🟦 | Logbook | Creatures, bosses, evolutions, forecasts; discovery from bus; category rewards | Discover once; reward once | TestRunner |
| S7.2 | Daily objective | Pool in `Definitions/Objectives`; one per day; no streak | Missing a day changes nothing (test with advanced clock) | TestRunner |
| S7.3 | Leaderboards | Best Night (Standard/Long), weekly nights survived | Updates within 60 s; reset on schedule | Play test |
| S7.4 | Specialties | Keeper/Oiler/Engineer/Harpooner earned by role stats; capped bonuses | Cap test; unlock from stats only | TestRunner |
| S7.5 | Invite reward | Shared Lantern cosmetic after first shared voyage, once per pair | Idempotent | TestRunner |
| S7.6 | Publish (owner) | | Live check | Owner |

→ B1.1.

---

## 10. Stage B1 — CLOSED BETA (3 weeks) — GO/NO-GO

| ID | Substage | Deliverables | Passes when | Verify |
|---|---|---|---|---|
| B1.1 | Cosmetics pipeline | Beam colours (existing), lamp housings, keeper coats, lantern skins, ship flags as definitions; Robux products created but **not enabled** | Products listed; fairness test re-answered in writing | Owner |
| B1.2 | Age rating & compliance | Questionnaire; Creator Hub policy check | Rating approved | Dashboard |
| B1.3 | Anti-exploit suite | §24 security tests automated | All green | TestRunner |
| B1.4 | Soak | 4-client, 2-hour, all modes; 2 real phones | Budgets met | Profiler, devices |
| B1.5 | Cohort | 30–100 invited testers; feedback form; bug tracker | ≥ 30 active; bugs triaged daily | Tracker |
| B1.6 | Go/no-go | | Logged | Owner |

**GO (to L1) when:** 0 blocking bugs; D1 play days and co-play share recorded as baseline; rematch ≥ 60%; Night-1 survival ≥ 50%. **NO-GO:** blocking bugs or retention below S3 numbers.

---

## 11. Stage L1 — Relaunch (2 weeks)

| ID | Substage | Deliverables | Passes when | Verify |
|---|---|---|---|---|
| L1.1 | Economy balance | From beta data; `pearlsFor`, prices, merchant; 10,000-voyage simulation | No unbounded inflow | `execute_luau` sim |
| L1.2 | Data audit | Migration chain on all fixtures; rollback drill | Rollback restores | TestRunner |
| L1.3 | Monetization (owner approval) | Enable cosmetic products; supporter pack; `ProcessReceipt` idempotent | Test purchases; duplicate receipt once | Studio |
| L1.4 | Codes | `CodeService`; creator codes with a cosmetic | Once per profile | TestRunner |
| L1.5 | Store final | Winning icon polished; 5 thumbnails; 30-s trailer; description | Uploaded | Dashboard |
| L1.6 | Community | Discord; support macro (inspect/grant/rollback); creator list (20+) | Written | Document |
| L1.7 | Release checklist | Restore point `L1 RC`; rollback steps; on-call window; **owner publishes** | Signed | Owner |

---

## 12. Stage LO — Live operations

| Cadence | Content | Checkpoint |
|---|---|---|
| Daily (first 30 days) | Error triage, hotfixes | Top error < 24 h |
| Weekly (Friday) | One of: monster, weapon, forecast, merchant item, QoL, balance | Shipped; changelog; restore point; mirror |
| Monthly | Boss, event voyage (Shipwreck Rescue), cosmetic set | Signal review |
| Seasonal (8–10 weeks) | Themed storm season, cosmetics, leaderboard reset | L1 checklist reused |
| Quarterly | Economy, data and performance re-baseline; roadmap revision | Docs updated |

Floor: biweekly, announced. Scaling trigger for a shared harbor: `architecture.md` §4.4.

---

## 13. Risk register

| Risk | Signal | Response |
|---|---|---|
| Pearls lost in cutover | Any save complaint in R1.9 week | Rollback from snapshot store; fix; re-publish |
| Loop doesn't retain | S3 rematch < 40% after 2 passes | NO-GO; revise roles/length in S2 |
| Oil role is a chore | S3.5 < 30% non-Keeper moments | Hero-moment pass: clutch refuel slow-mo, Oiler specialty earlier |
| Phone FPS | S4.4 < 30 FPS after render budget | Lower `MAX_CREATURES` on touch servers (server-side cap by device mix) |
| Process regression | Per-task audit packages reappear | The checkpoint protocol is the only process; reviews at gates only |
| Wrong Studio window | Any action on another PlaceId | Stop; re-identify; log the incident |
| Owner bandwidth | Any stage > 150% of estimate | Cut content breadth (S6 monsters) before cutting checkpoints |

---

## 14. Checkpoint record template

```text
CHECKPOINT: <ID> <Substage name>
DATE:
STUDIO INSTANCE: placeId 132065051336560 verified · API access: OFF before Play
BACKUP: ServerStorage.Backups.<ID>_before_<date> · restore point "<ID> passed"
TESTRUNNER: <N passed / M failed>  (summary pasted below)
SCRIPT ANALYSIS: <0 warnings | list>
PLAY TEST: <steps> → <result>, console errors: <0 | list>
NUMBERS: <metric = value> ...
MIRROR COMMIT: <hash>
OWNER APPROVAL: <yes / date>   PUBLISHED BY OWNER: <yes / no / n.a.>
NOTES / DEBT:
NEXT: <next ID>
```

---

**Mode:** unattended (D-010)
**Current substage:** S2.2 (see docs/CURRENT_PHASE.md)
**Last checkpoint passed:** R0.6
