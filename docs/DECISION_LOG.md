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
2026-10-16 · R0 · **Status: Proposed (owner decision pending)**
Context: Since the Oct 13 publish, development has gone into splitting the game into Harbor and Isle places with reserved servers, teleports, a MemoryStore manifest and a custom session lock. The live game has no visible players and has never had an outside playtest. The multi-ship code carries two HIGH findings (audit §2.2 #1, #2). The only cross-server problem that exists today — a quick rejoin while a save is in flight — is solved by ProfileStore without any of that machinery.
Decision (recommended): **One place. Server size 4. The server is the crew.** The `multiship-test` branch is tagged `frozen-2026-10-16` and left as history; the test experience 10771229467 stays private and untouched. Production adopts ProfileStore in R1.
Alternatives: (B) finish the split after applying the five corrections in audit §6 — estimated 4–6 more weeks before players see anything new; (C) 8-player servers with two crews instanced in one place — rejected: the island is Studio terrain and cannot be instanced by CFrame offset.
Consequences: no shared 60-player harbor; friends join via Join or private servers; public matchmaking fills to 4. Scaling trigger: ≥ 30% of joins rejected for full servers for a week → revisit (architecture §4.4).
Approved by: ______ (owner)

## D-002 — Persistence: ProfileStore in production, schema v2
2026-10-16 · R1 · Accepted (design; owner approval of the cutover procedure required at R1.9)
Context: production saves use a blind `UpdateAsync` overwrite with no lock and one attempt on leave (audit #3).
Decision: ProfileStore on the existing store name and keys; v1→v2 migration with type validation; `GrantService` as the only writer of Pearls/items; cutover by publish + "Shut down all servers".
Alternatives: keep the custom `SessionLock` (rejected: thinner than ProfileStore on retries, budget, steal, close; adds maintenance).
Consequences: the custom lock, hand-off and reclaim code leave the live path.

## D-003 — Default voyage length 7 nights; 13-night Long Voyage unlocked by a win
2026-10-16 · S2 · Proposed (changes an owner-approved number: 13 nights, Oct 13)
Context: 13 nights ≈ 27 minutes per voyage; phone sessions end before Results; the first win is a long commitment for the segment.
Decision: Standard Voyage 7 nights (bosses 4, 7; win = 12 Pearls); Long Voyage 13 nights (bosses 4, 7, 10, 13 and every night from 8; win = 18 Pearls, the owner's number) unlocked by one Standard win.
Consequences: Pearls per minute unchanged; the owner's "add 10 more days" is kept as the Long Voyage.
Approved by: ______ (owner)

## D-004 — Pearls banked at each dawn
2026-10-16 · S2 · Proposed (changes when, not how many)
Decision: the per-night Pearl is granted and saved at that dawn (idempotent claim); victory bonus and boss drops unchanged.
Consequences: a player who leaves mid-voyage keeps the nights survived; losing never pays 0 after dawn 1.
Approved by: ______ (owner)

## D-005 — Night-1 safety reserve for 0-run players
2026-10-16 · S2 · Proposed
Decision: for players with 0 completed runs, the emergency reserve refills once on the first Night-1 blackout, with the coach pointing at oil. Returning players unaffected.
Approved by: ______ (owner)

## D-006 — Process: checkpoint protocol replaces per-task auditor packages
2026-10-16 · R0 · Proposed
Context: 13 audit tasks and ~400 documents were produced to validate one save path; every task waited on an external relay.
Decision: the 8-step checkpoint protocol (`ROADMAP.md §0`) is the only process; the owner's hard rules stay verbatim in `CLAUDE.md`; independent review happens at stage gates only (R1.9, S3, B1, L1). Historical packages move to `docs/legacy/`.
Approved by: ______ (owner)

## D-007 — Studio-native toolchain; Rojo export-only
2026-10-16 · R0 · Accepted
Decision: Studio is the source of truth; Rojo exports `src/` after each checkpoint (existing workflow kept); TestRunner in Studio; no Rojo sync, no CI.

## D-008 — Pending batch 763dc4d (isle arrival and return)
2026-10-16 · R0 · Recorded
Verdict: accept with corrections (audit §6). Under D-001 Option A the batch is frozen with the branch, not published; the corrections are the record of what must be true before the branch is ever revived.

## D-009 — Title and icon
2026-10-16 · R0.6 · Proposed
Decision: remove "- Staging" from the public title immediately (owner action); A/B the two titles in `architecture.md` §27 at S3; icon from `docs/legacy/ICON_BRIEF.md` reconciled with the pirate skin (the brief predates it).
Approved by: ______ (owner)
