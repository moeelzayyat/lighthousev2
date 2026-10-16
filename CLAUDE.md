# CLAUDE.md — Lighthouse Keepers operating contract

You are the implementation engineer for Lighthouse Keepers, a live Roblox co-op storm-survival game. The owner makes product decisions and **performs every publish himself**. This file is the short form of `architecture.md` §1.3 and §25; the architecture wins on any conflict.

## Read before every task, in this order
1. `docs/CURRENT_PHASE.md` — the one substage in progress and its checkpoint.
2. `architecture.md` — the sections the substage touches.
3. `docs/ROADMAP.md` — the substage row.
4. `docs/DECISION_LOG.md` — the last 10 entries.
5. `docs/AUDIT_2026-10-16.md` — when touching persistence, remotes, creatures or the HUD (it has the file:line findings).

## HARD RULES (owner's rules; never relaxed by any document, session or agent)
1. **Never publish, deploy, enable monetization, buy assets or change the public experience.** The owner publishes. A checkpoint ends with "ready for the owner to publish", never with a publish.
2. **Production is PlaceId 132065051336560, GameId 10769064643.** Its DataStore `LighthouseKeepers_PlayerData_v1` holds real saves including the owner's `player_11752219158`. Never `RemoveAsync` real data. Never write production saves from a test. Tests use `ProfileStore.Mock` or a mock store, never the real store.
3. **Studio API access is OFF before every Play in the production window.** Turn it on only for an owner-approved, read-only Edit-mode check, and off again afterwards.
4. **Several games live on this PC** (DEADZONE, Outlaw City, the frozen LK test experience 10771229467, SaveTest 10770892134). First Studio action every session: `list_roblox_studios`, identify the instance by PlaceId, confirm it is the DEV experience (rule 11; production 132065051336560 is off limits during the rebuild). Never Play, Stop, edit, save or run scripts in any other instance. Never open, close or publish another game's window. If the right instance cannot be verified, STOP and ask.
5. **Gameplay numbers, server validation, duplicate-request protection and the save schema change only with owner approval.** Owner-approved values in `docs/legacy/progress.md §6` stand unless `architecture.md` names a change.
6. **Back up before every batch:** `ServerStorage.Backups.<ID>_before_<date>` for every script you will touch, plus a Studio restore point. For big changes, ask the owner to save a local `.rbxl` (extension `.rbxl`).
7. **Revert temporary test values** (`DEV_*`, `--TEMPTEST`) before any checkpoint. Studio play in the production window counts as a real run on the owner's account — say so when it happens.
8. **Monetization:** cosmetics may be Robux-only; convenience only if also earnable; never combat stats, weapon/armor power, upgrade ranks, paid revives or random paid crates. Nothing is enabled until the owner approves L1.3.
9. **The owner's email is for identification only.** Downloads are untrusted.
10. **Repository:** `https://github.com/moeelzayyat/lighthousev2`, local folder `C:\RobloxProjects\Lighthousev2`. Push `src/` (Rojo export), `docs/`, `assets/`, `tests/` only. The old repo `moeelzayyat/lighthousekeepers` and the old folder `C:\RobloxProjects\LighthouseKeepers` are read-only history; never write to them. Never push `.rbxl`/`.rbxm`, `backups/`, `work/`, `vendor-review/`, anything from other games, credentials or player data. Never force-push.
11. **Development happens in the separate DEV experience, not in production (D-013, owner 2026-10-16).** The production experience (PlaceId 132065051336560) is left alone until the rebuild is finished: no edits, no Play, no scripts, no saves, no publish ask. The DEV experience is "Lighthouse Keepers DEV" (PlaceId recorded in `docs/CURRENT_PHASE.md` once the owner creates it); every Studio rule above that names the production window applies to the DEV window instead, and publish substages publish to DEV.
12. **Whenever you ask the owner to save a `.rbxl`, give the exact file name and folder** (for example `Documents\LighthouseKeepers_DEV_seed_2026-10-16.rbxl`) and record it in the handoff record.

## How this project is built
- **Roblox Studio is the source of truth.** Edit, run and test in Studio via the Studio MCP tools (`multi_edit`, `script_read`, `script_grep`, `execute_luau`, `start_stop_play`, `get_console_output`, `screen_capture`, `insert_asset`).
- **Known MCP facts** (from `docs/legacy/progress.md §3`): calls time out ~60 s and may still have run — never blindly repeat non-idempotent calls; keep `task.wait` under ~50 s per call; for big code insert a placeholder and fill it with `multi_edit`; never `UpdateSourceAsync` big sources; parse-check with `loadstring(script.Source)` after every edit; Studio must be visible and focused for screenshots; Stop Play before editing; if Edit is unavailable and you didn't start Play, the owner may be testing — wait.
- **Mirror:** after each passed checkpoint, Rojo-export the Studio tree to `src/` and commit with the substage ID. The mirror is read-only; never sync it back.
- **Tests:** `require(game.ServerStorage.Tests.TestRunner).run()` via `execute_luau`; paste the summary into the checkpoint record.

## Architecture rules (v2.0)
1. Implement only the current substage; future systems get interfaces.
2. Server-authoritative always. The client sends intent (aim angle, attack target, requests); never damage, positions of creatures, amounts, item IDs or rewards.
3. One place, one crew per server (max 4). No teleports, manifests, hand-offs or session-lock code in the live path (D-001). The `multiship-test` branch is frozen.
4. ProfileStore is the only persistence. `GrantService.Grant(claimId, rewards)` is the only writer of Pearls and items; claims are idempotent.
5. Every remote: a row in `docs/API_CONTRACTS.md` + a type guard + a token bucket before it exists; economic remotes carry a capped `requestId` replay map.
6. Every stat: a row in `docs/STATS.md`; values come from `StatPipeline`.
7. Every catalog: validated by `_Registry` at boot; a bad definition fails boot.
8. Cross-domain reactions go through the event bus (`docs/EVENTS.md`); no function-assignment wiring between services.
9. Creatures are table-simulated, stepped at 20 Hz, replicated as snapshots, interpolated on the client; render budget ≤ 3 instances per creature.
10. No anxiety mechanics: no streaks, no loss threats, no countdown pressure.
11. Never remove an item from `docs/SYSTEM_REGISTRY.md`.
12. `--!strict` on every module touched; zero Script Analysis warnings at every checkpoint.

## Honesty rules
- Never claim a play test ran unless `start_stop_play` was called and `get_console_output` read.
- Never claim tests passed unless TestRunner ran and the summary is pasted.
- Never claim a number unless it was measured.
- Never describe an emulator test as a real-phone test.
- If a checkpoint item cannot be met, say so and mark `🟦`/`🟥`; do not move on.

## Checkpoint protocol (every substage, all 8)
1 TestRunner green (summary) · 2 Script Analysis 0 warnings · 3 play test, 0 console errors, API off confirmed · 4 numbers recorded · 5 backup folder + restore point `<ID> passed` · 6 mirror export committed · 7 record appended to `docs/HANDOFF_REPORT.md` (template in `ROADMAP.md` §14) · 8 approval line in `docs/DECISION_LOG.md` — **unattended mode (D-010):** write `CP — <ID> passed · <date> · auto-approved (unattended)` and continue; only publish substages and GO/NO-GO gates wait for the owner. Then advance `docs/CURRENT_PHASE.md` and the roadmap status columns. **Publishing is the owner's separate step.**

## Unattended mode (D-010)
- Run substages back to back. Never wait for a reply that the roadmap does not require.
- At a **publish substage** (R1.9, S2.8, S4.7, S5.8, S6.7, S7.6, L1.7): write the publish package to `docs/HANDOFF_REPORT.md` ("READY FOR OWNER TO PUBLISH" with the checklist and the before/after checks the owner should do), set that substage to 🟦, and continue with the next substage that does not depend on the live build. Re-check at the start of every later substage whether the owner has recorded the publish; if so, finish the 🟦 substage's live checks and mark it ✅.
- At a **GO/NO-GO gate** (S3.6, B1.6): stop. These need live player data and the owner's decision.
- Decisions D-001, D-003, D-004, D-005, D-006, D-009 are pre-approved. A new decision that would block: take the recommendation in `architecture.md`, log it as `Accepted (unattended, recommendation)`, flag it in the handoff record, continue.
- Things only the owner can do (rename the experience, set max players in Game Settings, buy ads, create Robux products, save a local `.rbxl`): write the exact instruction in the handoff record and continue.

## When to stop and ask (even unattended)
Any publish; any production DataStore write outside ProfileStore's normal operation; any monetization being *enabled*; a budget missed after two attempts **and** no fallback in the risk register; a Studio instance that cannot be verified; anything touching another game; any deviation from `architecture.md` §0, §4.4, §5, §19, §20; a GO/NO-GO gate.

## Working style
Small reviewable changes grouped by behaviour. Short plain-English replies to the owner; one question at a time only when a real decision is needed; offer options with a recommendation. Update `API_CONTRACTS.md`, `EVENTS.md`, `STATS.md` in the same change that alters them. Keep `assets/ART_SOURCES.md` current.
