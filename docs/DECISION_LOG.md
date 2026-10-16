# DECISION LOG

Append-only. Format:
```
## D-### — <title>
Date · Stage · Status: Proposed | Accepted | Superseded by D-###
Context / Decision / Alternatives / Consequences / Approved by
```
Checkpoint approvals are one line: `## CP — <ID> passed · <date> · approved by owner · published by owner: yes/no`.

Owner-approved gameplay numbers from before v2.0 are recorded in `docs/legacy/progress.md §6` and remain in force unless superseded here.

---

## D-001 — Place model: one crew per server; Harbor/Isle split frozen
2026-10-16 · R0 · **Status: Accepted (Option A)**
Context: Since the Oct 13 publish, development has gone into splitting the game into Harbor and Isle places with reserved servers, teleports, a MemoryStore manifest and a custom session lock. The live game has no visible players and has never had an outside playtest. The multi-ship code carries two HIGH findings (audit §2.2 #1, #2). The only cross-server problem that exists today — a quick rejoin while a save is in flight — is solved by ProfileStore without any of that machinery.
Decision (recommended): **One place. Server size 4. The server is the crew.** The `multiship-test` branch is tagged `frozen-2026-10-16` and left as history; the test experience 10771229467 stays private and untouched. Production adopts ProfileStore in R1.
Alternatives: (B) finish the split after applying the five corrections in audit §6 — estimated 4–6 more weeks before players see anything new; (C) 8-player servers with two crews instanced in one place — rejected: the island is Studio terrain and cannot be instanced by CFrame offset.
Consequences: no shared 60-player harbor; friends join via Join or private servers; public matchmaking fills to 4. Scaling trigger: ≥ 30% of joins rejected for full servers for a week → revisit (architecture §4.4).
Approved by: owner (2026-10-16, unattended-mode approval of all six recommendations)

## D-002 — Persistence: ProfileStore in production, schema v2
2026-10-16 · R1 · Accepted (design; owner approval of the cutover procedure required at R1.9)
Context: production saves use a blind `UpdateAsync` overwrite with no lock and one attempt on leave (audit #3).
Decision: ProfileStore on the existing store name and keys; v1→v2 migration with type validation; `GrantService` as the only writer of Pearls/items; cutover by publish + "Shut down all servers".
Alternatives: keep the custom `SessionLock` (rejected: thinner than ProfileStore on retries, budget, steal, close; adds maintenance).
Consequences: the custom lock, hand-off and reclaim code leave the live path.

## D-003 — Default voyage length 7 nights; 13-night Long Voyage unlocked by a win
2026-10-16 · S2 · Accepted (supersedes the 13-night default of Oct 13; 13 nights kept as Long Voyage)
Context: 13 nights ≈ 27 minutes per voyage; phone sessions end before Results; the first win is a long commitment for the segment.
Decision: Standard Voyage 7 nights (bosses 4, 7; win = 12 Pearls); Long Voyage 13 nights (bosses 4, 7, 10, 13 and every night from 8; win = 18 Pearls, the owner's number) unlocked by one Standard win.
Consequences: Pearls per minute unchanged; the owner's "add 10 more days" is kept as the Long Voyage.
Approved by: owner (2026-10-16, unattended-mode approval of all six recommendations)

## D-004 — Pearls banked at each dawn
2026-10-16 · S2 · Accepted
Decision: the per-night Pearl is granted and saved at that dawn (idempotent claim); victory bonus and boss drops unchanged.
Consequences: a player who leaves mid-voyage keeps the nights survived; losing never pays 0 after dawn 1.
Approved by: owner (2026-10-16, unattended-mode approval of all six recommendations)

## D-005 — Night-1 safety reserve for 0-run players
2026-10-16 · S2 · Accepted
Decision: for players with 0 completed runs, the emergency reserve refills once on the first Night-1 blackout, with the coach pointing at oil. Returning players unaffected.
Approved by: owner (2026-10-16, unattended-mode approval of all six recommendations)

## D-006 — Process: checkpoint protocol replaces per-task auditor packages
2026-10-16 · R0 · Accepted
Context: 13 audit tasks and ~400 documents were produced to validate one save path; every task waited on an external relay.
Decision: the 8-step checkpoint protocol (`ROADMAP.md §0`) is the only process; the owner's hard rules stay verbatim in `CLAUDE.md`; independent review happens at stage gates only (R1.9, S3, B1, L1). Historical packages move to `docs/legacy/`.
Approved by: owner (2026-10-16, unattended-mode approval of all six recommendations)

## D-007 — Studio-native toolchain; Rojo export-only
2026-10-16 · R0 · Accepted
Decision: Studio is the source of truth; Rojo exports `src/` after each checkpoint (existing workflow kept); TestRunner in Studio; no Rojo sync, no CI.

## D-008 — Pending batch 763dc4d (isle arrival and return)
2026-10-16 · R0 · Recorded
Verdict: accept with corrections (audit §6). Under D-001 Option A the batch is frozen with the branch, not published; the corrections are the record of what must be true before the branch is ever revived.

## D-009 — Title and icon
2026-10-16 · R0.6 · Accepted
Decision: remove "- Staging" from the public title immediately (owner action); A/B the two titles in `architecture.md` §27 at S3; icon from `docs/legacy/ICON_BRIEF.md` reconciled with the pirate skin (the brief predates it).
Approved by: owner (2026-10-16, unattended-mode approval of all six recommendations)

## D-010 — Unattended mode
2026-10-16 · R0 · Accepted
Context: the owner wants the project to run without per-substage approval.
Decision: checkpoint step 8 (owner approval) is replaced by an automatic log line for every substage **except** the publish substages (R1.9, S2.8, S4.7, S5.8, S6.7, S7.6, L1.7) and the GO/NO-GO gates (S3.6, B1.6), which still stop and wait for the owner. When the run reaches a publish substage it writes the publish package ("ready for the owner to publish" with the checklist) and **continues with the next substage that does not depend on the live build**. Decisions D-001, D-003, D-004, D-005, D-006, D-009 are pre-approved. Any *new* decision that would otherwise stop the run is made by the recommendation in `architecture.md`, logged here as `Accepted (unattended, recommendation)`, and flagged in `HANDOFF_REPORT.md` for the owner to reverse. Hard rules in `CLAUDE.md` are untouched: no publish, no production writes, API off, correct Studio window.
Approved by: owner (2026-10-16)

## CP — R0.1 passed · 2026-10-16 · auto-approved (unattended)
## CP — R0.3 passed · 2026-10-16 · auto-approved (unattended)

## D-011 — Live build identity (R0.5)
2026-10-16 · R0 · Recorded
Finding: the production Studio tree (PlaceVersion 172) is byte-identical to `src/` from the old repo's `main` 854f4e9: 49 of 49 scripts match by length and FNV-1a hash (`docs/STUDIO_MANIFEST.md`). Drift: none. The multi-ship modules (`HarborDepartures`, `IsleAdmission`, `PlaceRole`, `SessionLock`, `ShipBoarding`, `ShipDeparture`, `ShipRoster`, `Voyages`, `VoyageCast`) are present with `MULTI_SHIP_ENABLED = false` and `TELEPORT_ENABLED = false`; they leave the live path at R1.3/R1.7. Studio cannot see which version is published; if the owner published something after 854f4e9 was exported, R0.5 is re-run.
## CP — R0.5 passed · 2026-10-16 · auto-approved (unattended)
## CP — R0.6 passed · 2026-10-16 · auto-approved (unattended)

## D-012 — ProfileStore cannot use the v1 store in place (deviation from architecture §19)
2026-10-16 · R1.3 · **Status: Proposed (owner decision required: §19 deviation, CLAUDE.md "stop and ask")**
Context: architecture §19 and D-002 say "ProfileStore on `LighthouseKeepers_PlayerData_v1`, same keys; the existing values load unchanged". The line-by-line source review of ProfileStore at commit 45c9847 (`docs/legacy/audits/TASK-004/SOURCE_VERIFICATION_ADDENDUM.md` §2.1, lines 531–586 and 1493–1505 of the library) shows the opposite: a stored value without ProfileStore's `Data/MetaData/GlobalUpdates` wrapper is treated as invalid and **overwritten with an empty template profile** on the first session start, even if the load is cancelled. Every live v1 record is a flat table, so an in-place adoption would wipe each existing player's Pearls and items on their first join after the cutover. `GetAsync` through the library cannot read v1 either (it returns the template).
Decision (recommended, from `PERSISTENCE_COMPAT_AND_ROLLBACK.md` §2): ProfileStore on a **new store `LighthouseKeepers_PlayerData_v2`** (same key `player_<UserId>`). On a profile's first session, `MigrationService` reads the v1 record with a plain read-only `GetAsync`, lifts it to schema v2 (type-validated), marks `Import = {State = "done", From = 1, At = os.time()}` inside the same profile, and saves. If the v1 read fails the player is not let in (retry message) and nothing is marked. v1 is never written again and stays frozen as the safety copy. Everything else in §19 is unchanged (session lock, `BindToClose`, `GrantService`, cutover by "Shut down all servers").
Alternatives: (B) keep the custom `PlayerData` on v1 and harden it (lock, retries, budget), no ProfileStore — more own code to maintain, rejected by D-002. (C) Rewrite every v1 record into ProfileStore's wrapper ourselves — a mass production write that copies the library's internal format; rejected.
Consequences: rollback to the old build shows players their frozen v1 progress (anything earned after the cutover is invisible until restored); the cutover stays one-way after the R1.9 soak. Tests run on `ProfileStore.Mock` only.
Approved by: ______ (owner)

## D-012 — decision
2026-10-16 · R1.3 · **Status: Accepted (owner, variant: fresh start)**
Owner (thread, 2026-10-16 16:58 UTC): "I don't care about saves, you can wipe them I don't care".
Decision taken (simplest path that keeps the hard rules): ProfileStore on a **new store `LighthouseKeepers_PlayerData_v2`**, key `player_<UserId>`, **no import from v1**. Every player, the owner included, starts from the schema-v2 defaults after the R1.9 publish. v1 (`LighthouseKeepers_PlayerData_v1`) is **not deleted and never written again**; it stays as a frozen copy, so an import can still be added later if the owner changes his mind (`MigrationService.fromV1` is kept and tested for that case). No `RemoveAsync`, no production write by Claude.
Consequence for R1.3's pass list: "v1 fixture loads as v2" is kept as a unit test of `MigrationService` but no live path calls it; "quick rejoin keeps Pearls" and `BindToClose` are tested on the mock store.

## D-013 — Development moves to a separate DEV experience; production is left alone until the rebuild is finished
2026-10-16 · R1.9 · **Status: Accepted (owner)**
Owner (project chat, 2026-10-16 18:53 UTC): "Work on a separate experience and leave the production experience alone until we finish it" and "If you want me to save .rbxl file always give me the file name so you remember what is what".
Decision: all Studio work, play tests and publish substages move to a new private experience, **"Lighthouse Keepers DEV"**, seeded from a local copy of the production place as it is now (it already holds the unpublished R0–R1.8 work). The production experience (PlaceId 132065051336560) gets no more edits, Play, scripts, saves or publishes from Claude, and Claude stops asking the owner to publish there; production receives the finished build only at relaunch (L1.7). Every `.rbxl` request names the exact file and folder (CLAUDE.md hard rule 12).
Consequences:
- R1.9 is re-planned as "publish R1 to DEV and check saves live in DEV" (DEV has its own DataStores, so the real ProfileStore session lock, rejoin and shutdown save can be tested without any risk to players). The production cutover (fresh start of D-012) happens at relaunch.
- The production place's Team Create copy still contains the unpublished R1 work and the ServerStorage backups made today; players are unaffected because nothing was published. It must not be published from that window before relaunch.
- Earlier owner asks that touched production are withdrawn or deferred: R0.4 "Save to Roblox" restore point (withdrawn; the DEV seed `.rbxl` replaces it), R0.6 title change (deferred to L1.5), R1.7 Max players = 4 (do it in DEV now; production at L1.7).
- The frozen LK test experience 10771229467 and SaveTest 10770892134 are not reused.
- CLAUDE.md hard rule 4 now verifies the DEV PlaceId; rules 11 and 12 added.
## CP — R1.9 passed (DEV) · 2026-10-16 · live save check by the owner ("pearl stayed") · published by owner to DEV: yes · production: untouched (D-013)
## CP — S2.1 passed (🟦 Script Analysis) · 2026-10-16 · auto-approved (unattended) · DEV only
## CP — S2.2 passed (🟦 Script Analysis) · 2026-10-16 · auto-approved (unattended) · DEV only
