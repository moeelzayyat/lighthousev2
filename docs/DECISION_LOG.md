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

## D-011 — Tester feedback 2026-10-16 ("Lighthouse: Game improvements")
2026-10-16 · R1/S2/S6 · Accepted (owner-relayed tester document; triaged)
**Accepted, added to the roadmap:** crabs clipping through walls; UI text overflow on phones; shops/interactables floating or sinking (→ R1.10). Floating damage numbers and hit feedback (→ S2.5). Seagull airstrike, 3 per voyage (→ S4.9). Tower upgrade rebalance so no upgrade is the obvious pick; repairs limited per night (→ S4.10, numbers tuned after S3). Enemy roster seed for S6.5–S6.6: Toxic, Burning, Slowing, Exploding, Fast crabs, Lobster, Crawfish, Horseshoe Crab, Spider Crab (each with one clear purpose). Night-13 boss as a distinct milestone (→ S6.1). Tower skins and beam designs as cosmetics (→ B1.1). VIP = cosmetic aura + chat title only (→ L1.3).
**Accepted with a change:** permanent upgrade tree — honeycomb UI accepted; bonuses capped at +15% total across stats (not +50%), fewer levels, no "earnings" stat (→ S7.4 Specialties).
**Rejected (conflict with the owner's monetization rules and the fairness test):** paid revive; 2× earnings pass; premium weapon/armor set stronger than standard gear; Robux-only chests with power drops; direct Robux→currency; a second premium currency.
**Noted:** the document validates the beam as the strongest feature. It contains no behavioural data (Night-1 survival, beam-mode use, rematch); the next tester session should use `docs/legacy/PLAYTEST_KIT.md`'s observer sheet.
