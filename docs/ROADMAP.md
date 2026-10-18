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
| S7 | Return systems | 6 | 2 | Standard | 🟦 |
| B1 | **Closed beta** | 6 | 3 | **GO/NO-GO** | 🟦 |
| L1 | Relaunch | 7 | 2 | Checklist | 🟦 |
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
| S2.5c 🟦 | Menu pattern v1 (grid + detail pane) | `UiKit/Tiles` (TileGrid, Tile, DetailPane, BigButton, ReasonDivider) per `ART_BIBLE.md` *Menu pattern*; Quartermaster shop and workbench rebuilt on it (other screens untouched); locked items dimmed under one reason divider; big red close; hotbar visible | Screenshots PC 1920×1080 + Device Simulator iPhone 7 and 13 Pro Max: tile 180/150 px, action button 112/96 px, no tap target < 56 px on-device, no text overflow; a purchase from the new shop grants via the existing path (TestRunner unchanged); 0 Script Analysis warnings | `screen_capture`, TestRunner, play test |
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
| S3.2 🟦 | Prototype A sessions | 5+ sessions, 2–4 players, ≥ 1 real phone each, one with no verbal help; `PLAYTEST_KIT.md` thresholds (kit rewritten 2026-10-17) | Observer sheets filled; run summaries pasted | Owner |
| S3.3 🟦 | Weekly iteration ×2 | Two data-driven passes (FTUE, difficulty, oil role, vote clarity); hypothesis + result logged | Shipped within the week each | `DECISION_LOG.md` |
| S3.4 🟦 | Signal read | First-play bounce (<60 s, 61–180 s), D1 play days, co-play days, qualified sessions; funnel conversion per step | Written review | Document |
| S3.5 🟦 | Role check | Per-role contribution from "your part": share of voyages where a non-Keeper had the Moment of the storm | ≥ 30% | Telemetry (custom event `MomentKind`, built 2026-10-17) |
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
| S7.2 🟦 | Daily objective | Pool in `Definitions/Objectives`; one per day; no streak | Missing a day changes nothing (test with advanced clock) | TestRunner |
| S7.3 🟦 | Leaderboards | Best Night (Standard/Long), weekly nights survived | Updates within 60 s; reset on schedule | Play test |
| S7.4 🟦 | Specialties | Keeper/Oiler/Engineer/Harpooner earned by role stats; capped bonuses | Cap test; unlock from stats only | TestRunner |
| S7.5 🟦 | Invite reward | Shared Lantern cosmetic after first shared voyage, once per pair | Idempotent | TestRunner |
| S7.6 🟦 | Publish (owner) | | Live check | Owner |

→ B1.1.

---

## 10. Stage B1 — CLOSED BETA (3 weeks) — GO/NO-GO

| ID | Substage | Deliverables | Passes when | Verify |
|---|---|---|---|---|
| B1.1 🟦 | Cosmetics pipeline | Beam colours (existing), lamp housings, keeper coats, lantern skins, ship flags as definitions; Robux products created but **not enabled** | Products listed; fairness test re-answered in writing | Owner |
| B1.2 🟦 | Age rating & compliance | Questionnaire; Creator Hub policy check | Rating approved | Dashboard |
| B1.3 🟦 | Anti-exploit suite | §24 security tests automated | All green | TestRunner |
| B1.4 🟦 | Soak | 4-client, 2-hour, all modes; 2 real phones | Budgets met | Profiler, devices |
| B1.5 🟦 | Cohort | 30–100 invited testers; feedback form; bug tracker | ≥ 30 active; bugs triaged daily | Tracker |
| B1.6 🟦 | Go/no-go | | Logged | Owner |

**GO (to L1) when:** 0 blocking bugs; D1 play days and co-play share recorded as baseline; rematch ≥ 60%; Night-1 survival ≥ 50%. **NO-GO:** blocking bugs or retention below S3 numbers.

---

## 11. Stage L1 — Relaunch (2 weeks)

| ID | Substage | Deliverables | Passes when | Verify |
|---|---|---|---|---|
| L1.1 🟦 | Economy balance | From beta data; `pearlsFor`, prices, merchant; 10,000-voyage simulation | No unbounded inflow | `execute_luau` sim |
| L1.2 ✅ | Data audit | Migration chain on all fixtures; rollback drill | Rollback restores | TestRunner |
| L1.3 ✅ | Monetization (owner approval) | Enable cosmetic products; supporter pack; `ProcessReceipt` idempotent | Test purchases; duplicate receipt once | Studio |
| L1.4 🟦 | Codes | `CodeService`; creator codes with a cosmetic | Once per profile | TestRunner |
| L1.5 🟦 | Store final | Winning icon polished; 5 thumbnails; 30-s trailer; description | Uploaded | Dashboard |
| L1.6 🟦 | Community | Discord; support macro (inspect/grant/rollback); creator list (20+) | Written | Document |
| L1.7 🟦 | Release checklist | Restore point `L1 RC`; rollback steps; on-call window; **owner publishes** | Signed | Owner |

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

### LO cycle 1 (2026-10-17, built in DEV ahead of the production relaunch, on the owner's word "keep going into the plan ahead")
| ID | Substage | Deliverables | Passes when | Verify |
|---|---|---|---|---|
| LO.1 ✅ | Event windows | `Definitions/LiveEvents` (server-time windows); an event voyage offered on the crew card, by ChooseVoyage and at departure only while its event is on | Window edges tested; registry checks events and voyages both ways | TestRunner |
| LO.2 ✅ | Shipwreck Rescue | `Rescue` voyage (5 nights, event `ShipwreckRescue`); `RescueService`: a wreck with 8 castaways, carried one at a time to a shelter; Shells per rescue; 1 Pearl per 2 saved | Count, drop and rewards tested; a full Rescue voyage played | TestRunner + play test |
| LO.3 ✅ | Event cosmetic | Rescuer's Flag (`reward = "event"`), given once when every castaway is saved | Granted once at the end of a won voyage | Play test |
| LO.4 ✅ | Small fixes | Shop card type line no longer runs under the price; the code box also in the BAG | Seen in Studio | Play test |
| LO.5 ✅ | Publish (owner) | Package in HANDOFF_REPORT.md; published 2026-10-17 | Live check (owner: all good, 2026-10-17) | Owner |

### Visual overhaul (2026-10-17, ahead of the relaunch; the owner rejected the current look; plan: project file `research/visual_overhaul_plan.md`)
The owner judges every step from before/after screenshots (`assets/screens/visual_<step>/`) and can keep or veto it.
| ID | Step | Deliverables | Passes when | Verify |
|---|---|---|---|---|
| V1 ✅ | Sea and sky | The sea reaches 3,072 studs out (was 800, a visible edge); an overcast day and a dark, hazy storm night; storm waves and cloud cover on the voyage crew's devices | No sea edge in view; night still dark enough for the beam; TestRunner green | Screenshots + TestRunner |
| V2 ✅ | The beam | `Client/BeamFx`: the server's beam restyled on each device into 4 layers (soft haze with feathered edges, a bright core), fading out before it reaches the ground; rain glints falling through the beam in the storm (60/s on touch, off with Low effects). The server's angle, width and hits are unchanged | Screenshots; 0 errors; TestRunner green | Screenshots + TestRunner |
| V3 ✅ | Storm effects | Rain that reads (its streaks were flat horizontal dashes: fixed), distant rain sheets (computers only), a lightning bolt over the sea and a cold flash across the whole scene, foam at the waterline of the island and rocks and wave spray (found from the terrain; 90 points, 40 on touch). Swaying lanterns and flags move to V4, when the island gets them | Screenshots; 0 errors; 60 FPS in Studio; TestRunner green | Screenshots + TestRunner |
| V4 ✅ | Island rebuild | Plateau repainted (moss, earth, rock, worn paths; heights unchanged where play happens), a craggy rock rim with 3 sand coves, a keeper's hut with a flag, an oil shed over the barrels, a dock, 6 path lanterns; lanterns swing and the flag flutters (`Client/WindFx`). Record: `assets/world/v4_island_build.md`. Not done: a raised tower mound (the tower stands at a fixed height). The owner's `backups\LighthouseKeepers_DEV_preVisual_2026-10-17.rbxl` was asked for; a Studio copy of the island terrain is the backup meanwhile | Creatures cross the rim and reach the tower (Night 1, 17 creatures); ground grid within 0.03 studs of the terrain; oil prompt works under the shed; TestRunner green | Play test |
| V5 ✅ | One material style | One terrain palette (mossy greens, wet blue-grey stone, dark earth, muted sand) on both islands; colour grade without the extra saturation and slightly cool. Props already use wood, slate and metal; the remaining "plastic" is textured meshes, unchanged. Not possible from a script: switching Roblox's material set (the place setting is the owner's) | Screenshots; 0 errors; TestRunner green | Screenshots + TestRunner |
| V6 ✅ | Harbor at dusk | `Client/HarborLight`: golden hour on each device while the player is on the harbor island (the server's voyage lighting is given back on leaving); amber lanterns with iron caps; a campfire with a stone ring, a log teepee, flames, embers, smoke and flickering light; the Quartermaster sign lifted above the awning (`IslandBuilder`); 10 more palms; pier bollards and rope | Screenshots; the island still gets the server's storm night after sailing; 0 errors; TestRunner green | Screenshots + TestRunner |
| V7 ✅ | Hit and death feel | `CreatureView`: a sea-foam death burst (foam and droplets from one shared emitter; was an orange ball) and white sparks when a hit lands (the white body flash was already there); `HitFx`: a small camera shake for a cannon firing within 70 studs and for a hit of 8+ health on this player (off with Low effects); `BeamFx`: the lamp stutters under 15% oil | Play test: sparks and bursts seen, shake measured, flicker measured; 0 errors; TestRunner green | Play test |
| V8 🟦 | Phone check | Screenshots at the lowest graphics quality and at Automatic; Studio frame times at both (capped at 60 on this PC, so they prove nothing for phones); the visual budget per device in `PERFORMANCE_BUDGETS.md` ("Visual overhaul"). Not done: Studio's device emulator (not reachable from the tools) and a real phone (the owner's) | Numbers recorded; a real-phone FPS check by the owner | Owner (real phone) |

### Harbor UI (2026-10-17, the owner's ask "Let's start with the harbor isle, we need new UI for shops and leaderboard etc"; spec: project file `research/harbor_ui_spec.md`)
| ID | Step | Deliverables | Passes when | Verify |
|---|---|---|---|---|
| HUI.1 ✅ | Look A "Bold" skin | `Client/UiSkinBold` (navy panels, thick dark outlines, big corners, 3D buttons, Luckiest Guy + Fredoka One, rarity colours), switched by `Config.UI_SKIN = "bold"` (was "pirate"); a Look B would be one more skin and the same switch | Every UiKit screen draws in the new look with 0 errors | Screenshots |
| HUI.2 ✅ | Rarity tiers | Display-only `tier` on every item (`Items.TIERS`), checked by `_Registry` (D-040); no price or stat changed | Registry refuses a missing or unknown tier; TestRunner green | TestRunner |
| HUI.3 ✅ | Quartermaster shop | Tab rail (Weapons, Armor, Ammo, Boosts, Cosmetics), 3-column cards (`UiKit.ShopCard`: rarity tag, item in a rarity ring, price / Robux / EQUIPPED / OWNED plate), detail panel with stat bars and +/- against what is equipped, big green BUY beside the Robux button; phone: rail + grid, tap for the detail view | Same ShopRequest/ShopResult and MarketplaceService flow; screenshots wide and phone | Play test |
| HUI.4 ✅ | Harbor board | `Client/HarborBoard`: "HARBOR LEGENDS" face with a podium for the top 3 and rows 4–10 per board, a "your rank" strip, and a full-screen view from a prompt on the board. It reads the rows the server already writes (no new remote); the board is 16 x 9.5 studs (was 13 x 7.5) | Rows, podium and rank drawn from sample rows; 0 errors | Play test |
| HUI.5 ✅ | Harbor HUD | Chunky bag button (same spot and size), a Pearls pill (top right) and a CODES button (opens the BAG with the code box), shown on the harbor island only | Shown in the harbor, hidden on a voyage | Play test |
| VIS.P ✅ | Publish the new look (owner) | Package "VISUAL + HARBOR UI + S2.5c — READY FOR OWNER TO PUBLISH" in HANDOFF_REPORT.md: V1–V8, HUI.1–HUI.5, the first-10-minutes pass, the bigger harbor island, S2.5c | Live checks in the package; the LO.5 live checks ride along | Owner |
| SNP.1 🟦 | Sniper tower (the owner's idea, 2026-10-17) | `SniperService` (tower built on the island's west side at boot, climb prompt, server-traced rifle shots, `SniperAction` remote), `SniperView` (first-person scope, crosshair, zoom, FIRE/ZOOM/CLIMB DOWN on touch), D-044 numbers | One shot kills a Sand Skitter, a Rock Crab takes 3 (2 in a Spring Tide); the climber is out of reach; TestRunner green | TestRunner, play test; the owner judges it after the next DEV publish |
| MP.2 ✅ | Trader on the menu pattern | `Trader.client` rebuilt on `UI/Tiles` (D-041/D-042): SALVAGE tab (one tile per kind of loot, SELL ALL in the detail pane) and ISLAND STOCK tab (the merchant's six items, dimmed under "The Trader sells by day" at night); `Tiles` alerts row (critical lamp, tower, health) used by the Trader and the workbench | Sell all and a day purchase through the existing TraderRequest / MerchantRequest paths; smallest tap ≥ 56 px, no text overflow | Play test, TestRunner |
| MP.3 ✅ | The BAG on the menu pattern | `Inventory.client` rebuilt on `UI/Tiles`: KEEPER tab (your keeper with what the gear adds up to, one tile per equipped slot, the code box), WEAPONS, ARMOR, COSMETICS, SUPPLIES; stat changes against what is equipped; EQUIP / UNEQUIP; the harbor's BAG and CODES buttons unchanged (CODES opens it at the code box); `CodeBox.send` shared | Equip, unequip and a code through the existing LoadoutRequest / CodeRedeem paths; smallest tap ≥ 56 px, no text overflow | Play test, TestRunner |
| ISL.1 ✅ | Sniper tower out in the water (owner, 2026-10-17 23:42) | The tower stands in the sea off the east beach on a wooden deck with pilings; a small bridge (about 11 studs) runs from the deck to the sand (`Config.SNIPER_TOWER_AT`, `SNIPER_DECK_Y`, D-045) | Climbing, the shots and creature paths still work; screenshots before/after | Play test |
| ISL.2 ✅ | Lighthouse island about 50% bigger (owner, 2026-10-17 23:42) | Land area x1.49 measured: the terrain stretched outward from 44 studs (the middle with the lighthouse, shop, bench and Trader unchanged), the outer rocks, dock, lanterns, hut, oil shed and wrecks moved out with it; creature spawn ring 92 to 117, ground grid 128 to 140, beam reach to the new shore (D-045) | Creatures still reach the tower, cannons and the beam still cover the shore, the ground grid matches; screenshots before/after | Play test, TestRunner |
| ART.1 ✅ | ForgeGUI models for the five block-built monsters (coordinator note, 2026-10-18) | Spitter Eel, Puffer Mine, Ghost Lantern, Tide Witch and Coral Shaman use the owner's ForgeGUI models from `ServerStorage.Art` (one textured mesh each), sized and turned to face forward; art attributes `EyeAt`/`EyeSize` put the night-time glow eyes on each face | Each creature draws one part; TestRunner green; day and night pictures for the owner | Play test, TestRunner; the owner judges the look |
| F10.2 ✅ | First 10 minutes, pass 2: the opening on the bigger island (coordinator pick, 2026-10-18) | The scripted first-timer (`tests/first_beam_hit_bot.luau`) re-run on the bigger island; the oil pile and its shed went back to their old spot near the lighthouse (they had moved out 14 studs with the island) | First beam hit ≤ 45 s (S2.4); median near pass 1's 37.7 s | 3 valid scripted runs, TestRunner |
| ART.2 ✅ | ForgeGUI crab and skitter (coordinator, 2026-10-18) | The Rock Crab gets a new ForgeGUI model and the Sand Skitter its own (it was a small Rock Crab): one textured mesh each, sized to the old crab's footprint, turned to face forward, glow eyes on the face; `Creatures.SandSkitter.art` = "SandSkitter" | One part per creature; TestRunner green; pictures for the owner | Play test, TestRunner; the owner judges the look |
| MP.4 ✅ | Logbook page on the menu pattern (coordinator pick (a), 2026-10-18) | S7.1's logbook had no page: a LOGBOOK tab in the BAG (`Inventory.client`): a summary tile (found / total per row and each row's Pearls), found creatures shown as their own models, evolutions and forecasts as icons, the rest dimmed under NOT FOUND YET; field notes per creature. `GearData` now carries the found entries. `UI/Tiles`: a narrower tab gap on phones so six tabs stay ≥ 56 px. Settings and Results stay as they are (not item lists; D-041 rebuild-or-leave) | Smallest tap ≥ 56 px at every simulated size, no text overflow; the reward stays LogbookService's | Play test, TestRunner |
| PH.1 ✅ | Phone pass (coordinator pick, readiness gap, 2026-10-18) | The HUD, the lamp-keeper controls, the prompt cards and Results checked at 667×375, 932×430 and 1180×820 in the game's layout simulator (touch layout on, joystick and jump zones drawn); fixes: wider phone plates (HEALTH, BEAM · AUTO-SWEEP fit), prompt cards stacked full width on phones, gauge notes drop their prefix on a narrow gauge (BREACHING), the sniper's touch buttons lower on short screens and the joystick and jump button hidden up the tower, Results' share line 44 px tall and two cut-off texts shortened | Every tap ≥ 44 px, nothing over the joystick or jump zones, no fixed text cut off; a simulated layout, not a phone (the real-phone check is the owner's) | Simulated layouts, TestRunner |
| PH.1b ✅ | Phone pass in Studio's Device Simulator (follow-up) | The island HUD on Samsung Galaxy A06 (800×360), iPhone 17 Pro (874×402) and iPad 10th generation (1180×820) in the Device Simulator, measured against Roblox's own jump button and thumbstick; the sniper tower on the iPhone; fix: CLIMB DOWN sat off the top of any screen under 500 px tall when touch is not detected (the simulator reports a keyboard too) | Every tap ≥ 44 px, none over the jump button or thumbstick, nothing off screen | Device Simulator, TestRunner |
| SND.1 ✅ | Sound licence audit (coordinator pick) | Every sound in the game listed in `assets/ART_SOURCES.md` with its source (MarketplaceService:GetProductInfo) and licence: 8 uploaded ids, 6 from Pro Sound Effects (Roblox's licensed library), 2 from private uploaders of unknown origin (storm waves, storm rain) replaced with Pro Sound Effects recordings, volume matched by measured loudness; the rest are built-in Roblox sounds | No sound of unclear origin left | GetProductInfo, PlaybackLoudness, TestRunner |
| SA.1 ✅ | Script Analysis clean-up (coordinator pick) | First full count of the game's Luau warnings with luau-lsp 1.70.1 `analyze` (already on this PC; Roblox definitions, Rojo sourcemap of `src/`): 812 → 165. One untyped counter table in EventLog was 550 of them; StatPipeline, the stat-line lists, the Results forward reference and 16 unused locals/functions fixed; nothing the game does changed | Count recorded; TestRunner green; a voyage to Results with 0 errors | luau-lsp analyze, TestRunner, play test |

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
