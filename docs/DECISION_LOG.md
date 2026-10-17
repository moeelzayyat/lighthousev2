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
## D-014 — The Night-1 reserve refills the lamp to full
2026-10-16 · S2.3 · **Status: Accepted (unattended, recommendation)** — flagged for the owner in the S2.3 record
Architecture §3 says the emergency reserve "refills the lamp once" on the first Night-1 blackout but gives no amount. Measured in DEV: a first-time solo player who never carries oil reaches nightfall with an **empty lamp** (the prologue's 40-fuel reserve burns out before the prologue ends). One barrel (`FUEL_PER_REFILL` = 40) would last 48 s at the solo wide-beam rate (0.84/s) plus the 10 s dark grace, short of the 90 s night, so the roadmap check ("survives Night 1 once and loses Night 2") cannot pass with it.
Decision: the reserve fills the lamp to `MAX_FUEL` (100). No new number is added; it uses the existing maximum. Measured result: Night 1 survived with 24 fuel left at dawn, Night 2 lost to a blackout 39 s in. To change it, the owner names a different amount.
## CP — S2.3 passed (🟦 Script Analysis) · 2026-10-16 · auto-approved (unattended) · DEV only
## CP — S2.4 passed (🟦 Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · 4 valid scripted runs, median 37.65 s
## D-015 — Full unattended mode: decisions are taken, logged and revised later
2026-10-17 · **Status: Accepted (owner)**
Owner (project chat, 2026-10-17 02:52 UTC): "I want a full unattended experience please remember that, when there is a decision required just recommend one and execute it and we can revise later".
Decision: no thread waits on a question. Every decision that comes up is taken on the recommendation, logged here as "Accepted (unattended, recommendation)" and listed in the next result for the owner to revise. Only steps that need the owner's hands stop the run (publishing, saving a `.rbxl`, keeping the DEV Studio window focused for play tests). Publishing stays the owner's step (CLAUDE.md hard rule 1).
## CP — S2.5 passed (🟦 Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · Sail again → new voyage 0.78 s
## CP — S2.6 passed (🟦 Script Analysis; controller voyage is an owner check) · 2026-10-17 · auto-approved (unattended) · DEV only
## CP — S2.7 files made (🟦 owner upload) · 2026-10-17 · auto-approved (unattended) · icons A/B, 3 thumbnails, description in assets/
## S2.8 — READY FOR OWNER TO PUBLISH (DEV) · 2026-10-17 · package in HANDOFF_REPORT.md · waiting on the owner's publish and live checks
## D-016 — S3 public test runs on the DEV experience, made public
2026-10-17 · S3 · **Status: Accepted (unattended, recommendation)** — flagged for the owner
S3 needs real players for 2–3 weeks, but D-013 keeps production untouched until the rebuild is finished. Options: (1) make the DEV experience public for the test; (2) publish the rebuild to production early; (3) skip S3 and go to S4.
Decision (recommended): (1). The owner sets Lighthouse Keepers DEV to Public for S3 (Game Settings → Permissions), applies the S2.7 store page there, and points the S3.1 diagnostic ads at it. Production stays untouched (D-013 holds), and S3's real-player data still gates S4 as the roadmap requires. DEV saves are the DEV experience's own (`LighthouseKeepers_PlayerData_v2` in DEV), so testers' progress does not carry to production at relaunch (consistent with D-012's fresh start). To revise: choose (2) or (3).
## D-017 — Mode test design (S3.1b): split by account id, no save field
2026-10-17 · S3.1b · **Status: Accepted (unattended, recommendation)**
- Who is tested: accounts whose profile was created on or after `MODE_TEST_START` (2026-10-17 00:00 UTC), i.e. new accounts. Older accounts keep the Standard voyage.
- Split: 50/50 by a hash of the UserId (`ModeTest.armFor`), so an account keeps its arm forever and the save schema does not change (no new field).
- Mixed crews: a crew sails Endless Storm only when every tested member is in the Endless arm; otherwise it sails the default (a crew member's own choice of the Long voyage always wins). Analysis uses the per-account `ModeArm` custom event and the per-voyage `VoyageMode` event.
- Endless Storm: the Standard curve continued, big monsters on nights 4 and 7 and every night from 8 (Long's rule), no final-night crisis, no victory; dawn Pearls as usual (1 per night), no victory bonus; the night reached is the score. No stored personal best yet (a schema field waits for S7.3 leaderboards); `Stats.BestNight` is no longer raised by Endless voyages, and Long voyages now raise `Stats.BestNightLong` (the field existed but was unused).
- Flag: `Config.MODE_TEST_ENABLED = true` in the DEV build that S3 runs on (D-016). Turn it off to end the test.
To revise: change the start time, the split rule, or the Endless boss rule.
## CP — S3.1 (owner: diagnostic ads, icon/title A/B through Creator Hub) · not code · 2026-10-17 · queued in the handoff for the owner
## CP — S3.1b built (🟦 Script Analysis; live per-arm numbers pending) · 2026-10-17 · auto-approved (unattended) · DEV only
## D-018 — S3 GO/NO-GO taken provisionally: GO to S4, with no live data
2026-10-17 · S3.6 · **Status: Accepted (unattended, provisional — no live data)** — flagged for the owner
Owner (project chat, 2026-10-17 03:18 UTC): "I'm going to bed so keep going even in s3 go/no go gate, keep going don't wait on my input".
The roadmap's GO thresholds (Night-1 survival ≥ 50 %, rematch ≥ 60 %, beam modes used on purpose ≥ 70 %, falling first-play bounce, an oil/cannon highlight) need the public test, which has not started (S2.8 is not published yet). Decision: take the GO path provisionally and build S4 (performance and mobile), which every outcome of S3 needs anyway. The 7-night Standard voyage stays the default; the mode test keeps running once S3 is live. When S3 data arrives, the owner reads the gate for real: a NO-GO sends the work back to S2 (S4 work is kept); if Endless Storm wins the mode test, S4 adds the day-phase work pass the roadmap names.
## D-019 — Island merchant stock and prices (S6.2)
2026-10-17 · S6.2 · **Status: Accepted (unattended, recommendation)** — flagged for the owner; tune after the public test
New gameplay numbers (architecture §2.5 names the items, not the prices). Recommendation taken: Whetstone +10% weapon damage 50 Shells and Sea Legs Tonic +10% walk speed 40 Shells (each at most twice a voyage, cap +20%); Kelp Poultice full heal 15; Oil Bundle +40 lamp fuel 30; Tower Shield half tower damage until dawn 60 (one at a time). Priced against the bench (level 1 costs 25–40, a voyage starts with 120 Shells) so a crew chooses between the bench and the merchant. Sold by day only, near the Trader, to the crew; everything wiped at Results. Idempotency uses a capped requestId replay map in `MerchantService`, not `GrantService` claims: merchant items are never saved to the profile, and `GrantService` writes saved Pearls and items only (architecture §11 says "via GrantService"; this is the deviation, logged). To revise: say so.
## D-020 — Orbiting Blades numbers and price (S6.3)
2026-10-17 · S6.3 · **Status: Accepted (unattended, recommendation)** — flagged for the owner; tune after the public test
New gameplay numbers. Recommendation taken: 3 blades on a 7-stud circle; a cut every 0.5 s for 4 damage to each of up to 3 creatures within 7 studs (8 damage per second per creature, about the Driftwood Harpoon's 8.9 single-target rate, so it helps in a crowd without beating the beam); takes the merchant's damage boost; sold by the island merchant once a voyage for 80 Shells. Not saved and not in the Quartermaster shop (`voyageOnly`); permanent variants are S6.4. The Keeper's blades rest while they run the lamp (like attacks). To revise: say so.
## D-021 — Quartermaster boosts, new gear and the profile field `Boosts` (S6.4)
2026-10-17 · S6.4 · **Status: Accepted (unattended, recommendation)** — flagged for the owner; tune after the public test
The roadmap row names "new profile fields with defaults"; the field is new to architecture §6.1, so it is logged here. Taken: profile field `Boosts` (boost id → rank), default `{}`, kept at schema v2 (an added field with a default, not a version bump; a save without it loads with `{}` and no repair). Boosts (Pearls, rank by rank): Shell Pouch +2% Shells from loot (20/30/40/50/60), Sea Boots +1% walk speed (15/20/25/30/40), Sharpened Steel +1% weapon damage (20/30/40/50/60); all together capped at +15%, so a player maxes at most two lines. Gear: Coral Lance (Thrown, 13 damage / 1.3 s, 2 targets, 90 Pearls), Tidecaller Blades (permanent Orbit weapon, 3 damage / 0.5 s to up to 3 within 7 studs, no thrown weapon while equipped, 110 Pearls), Kelpweave Vest (160 health, 20% less damage, 80 Pearls). Everything is earned with Pearls; nothing is sold for Robux (rule 8). Owner to-do: add `Boosts` to architecture §6.1 if kept. To revise: say so.

## D-022 — Saved timestamps were reset on every load (bug fix, S6.4)
2026-10-17 · S6.4 · **Status: Accepted (unattended, recommendation)** — flagged for the owner (validation change)
Found while writing the S6.4 migration fixture: `ProfileSchema.validate` checked `CreatedAt` and `LastSeenAt` with the count check, whose ceiling is 1e9; real timestamps (`os.time()`, about 1.76e9) failed it and were set to 0 on every load. Effects: every session looked like a brand-new player (`ProfileLoaded IsNew = true`, `CreatedAt` rewritten), `PlayDays` grew by one each session, and the S3.1b mode test treated every account as new. Fix: timestamps are whole numbers from 0 to 1e11. Live data so far is DEV only. To revise: say so.
## D-023 — Spitter Eel, Puffer Mine, Ghost Lantern: numbers and when they come (S6.5)
2026-10-17 · S6.5 · **Status: Accepted (unattended, recommendation)** — flagged for the owner; tune after the public test
Taken: Spitter Eel (40 HP; from 22 studs it marks the spot a player stands on, 0.8 s later 12 damage within 4 studs; at the tower 3 per spit from 26 studs out); Puffer Mine (25 HP; a player within 6 studs or the tower lights a 1 s fuse, then 30 damage within 8 studs and 8 to the tower if close; shot first, it drops loot instead); Ghost Lantern (60 HP, floats, weapons and cannons pass through it, the beam does double damage; at the tower it drinks 6 fuel every 3 s after a 0.9 s glow). Nights: eels from night 2 (1, +1 every 2 nights, max 4), puffers from night 3 (2, +1 every 2, max 5), lanterns from night 5 (1, +1 every 3, max 3), on top of the crab wave and the swarm and within the 45-slot cap. Bodies are plain-part shapes and built-in sounds at new pitches until art exists. An eel picks on a player within its 22-stud range (it needs to, or it only ever spits at the tower). Observed and not changed: the existing proximity threat for crabs never builds up (each 0.2 added per step is cleared by the fade's 0.5 floor), so crabs only turn on players who hit them; changing that would make crabs far more aggressive, so it is left for the owner. To revise: say so.
## D-024 — Tide Witch and Coral Shaman: numbers and when they come (S6.6)
2026-10-17 · S6.6 · **Status: Accepted (unattended, recommendation)** — flagged for the owner; tune after the public test
Taken: Tide Witch (45 HP; stops on the beach 40 studs from the tower and, every 7 s after a 1 s chant, calls 3 Sand Skitters out beside her, within the creature cap); Coral Shaman (70 HP; stops 24 studs out and, every 5 s after a 0.8 s chime, mends every small creature within 14 studs by 30% of its health; never a big monster). Both only ever go for the lighthouse and do no damage themselves: the counter is to reach and kill them (harpoons, cannons, the beam). Nights: witches from night 4 (1, +1 every 3 nights, max 2), shamans from night 6 (1, +1 every 3, max 2). To revise: say so.
## D-025 — Logbook: what counts as found, and the rewards (S7.1)
2026-10-17 · S7.1 · **Status: Accepted (unattended, recommendation)** — flagged for the owner
Taken: a creature is found when the crew defeats one (every crew member on the island gets it), a big monster when the crew brings one down, an evolution when the crew forges it, a forecast when a player survives a night under it. Finishing a category pays once through GrantService: Creatures 15 Pearls, Big monsters 10, Evolutions 10, Forecasts 5 (claim `logbook:<category>:<entries>`, so a category that grows later can pay again). The profile's existing `Logbook` field (architecture §6.1) holds the entries. A logbook page to browse them is not built yet (notices only); it is a small follow-up. To revise: say so.
## D-026 — Daily objective: the pool, rewards, and no claim button (S7.2)
2026-10-17 · S7.2 · **Status: Accepted (unattended, recommendation)** — flagged for the owner
Taken: five objectives (deliver 10 oil 3 Pearls, survive night 4 4, build 2 cannons 3, repair the tower 5 times 3, defeat 40 creatures 3); one a day per account, picked from the account and the UTC date; it counts only the player's own events (and the night reached for "survive night 4"); finishing pays automatically once (GrantService claim `objective:<day>:<id>`). No streak, no penalty, nothing carried between days (rule 10). The planned `ObjectiveClaim` remote is not built: paying on completion needs no client request, so there is nothing to guard or replay. Today's objective is on player attributes and a join notice; a HUD line is a small follow-up. To revise: say so.
## D-027 — Leaderboards: what they rank, where they live, how often (S7.3)
2026-10-17 · S7.3 · **Status: Accepted (unattended, recommendation)** — flagged for the owner
Taken: three boards on one stand across the path from the Quartermaster: best night on the Standard Voyage, best night on the Long Voyage, nights survived this week (all voyages). Every survived night counts for the crew who survived it. Scores go to ordered data stores in live servers (`LK_BestNight_Standard_v1`, `LK_BestNight_Long_v1`, `LK_WeeklyNights_v1_<week>`), written and re-read every 30 s (updates within 60 s); the weekly board starts a new store each Monday 00:00 UTC (the old week's store is left, nothing is deleted). Studio always uses an in-memory store, so a play test never writes a board. Endless Storm has no board (D-017 kept it out of saves too). To revise: say so.
## D-028 — Specialties: what earns them, their bonuses, and the profile field `Roles` (S7.4)
2026-10-17 · S7.4 · **Status: Accepted (unattended, recommendation)** — flagged for the owner
Taken: Keeper (kills by the beam: 50 / 250 / 1000 → +2% beam damage per rank while keeping), Harpooner (weapon kills: 50 / 250 / 1000 → +2% weapon damage), Oiler (oil delivered: 25 / 100 / 300 → +2% walk speed), Engineer (repairs and cannons built: 20 / 80 / 250 → +2% repair). All together capped at +15% (architecture §7.2), so a player who masters everything still gets at most +15% in all. Earned only by play: the counters live in a new profile field `Roles` (default {}, added silently like `Boosts`), the ranks in the existing `Unlocks.Specialties`. Nothing is sold (rule 8). To revise: say so.
## D-029 — Invite reward: what the Shared Lantern is and what counts (S7.5)
2026-10-17 · S7.5 · **Status: Accepted (unattended, recommendation)** — flagged for the owner
Taken: the Shared Lantern is a beam colour (the only cosmetic slot the game draws today; lantern skins come with the B1.1 cosmetics), earned, never sold. It goes to both players when one joined the server from the other's invite (Roblox join data `ReferredByPlayerId`) and they are in the same voyage when it ends, having survived at least one night (so sailing and quitting at once does not count). One GrantService claim per pair (`invite:<lower>:<higher>`), so it is paid once. The invite link only lasts for the session the friend joined in. To revise: say so.
## D-030 — Cosmetics catalogue and suggested prices (B1.1)
2026-10-17 · B1.1 · **Status: Accepted (unattended, recommendation)** — flagged for the owner
Taken: nine looks-only cosmetics: Driftwood and Polished Brass lamp housings, Storm Blue and Kelp Green keeper coats, Moth and Tide lanterns, Gull, Kraken and Founder's flags. Each can be earned with Pearls (30–90, about one to three good voyages) and is also offered for Robux at a suggested 39–99; the Founder's Flag (149 Robux) is the supporter item and the only Robux-only one. The five beam colours stay as they are (Pearls; the Shared Lantern is invite-only). The registry refuses a stat on any cosmetic and refuses switching Robux on, so nothing can be sold until the owner approves L1.3 and changes `ROBUX_ENABLED` himself. Wearing the new slots in game is not built (it comes with L1.3 if the owner approves). To revise names, prices or the list: say so.
## D-031 — How the security suite reaches the live handlers (B1.3)
2026-10-17 · B1.3 · **Status: Accepted (unattended, recommendation)**
Taken: every client→server handler now connects through `NetGuard.connect`, which in Studio (only) also exposes the handler as a BindableFunction under `ServerStorage.NetHooks`, so TestRunner can call exactly what a client's FireServer reaches, as the real harbor player or a fake non-owner, and compare the profile before and after. No guard, rate or rule changed; live servers never create the hooks (`RunService:IsStudio()`), and ServerStorage is never visible to clients. The alternative (a client-side bot firing remotes) cannot run inside TestRunner. To revise: say so.
## D-032 — B1 GO/NO-GO taken provisionally: GO to L1, with no beta data
2026-10-17 · B1.6 · **Status: Accepted (unattended, provisional — no beta data)** — flagged for the owner
Owner (project chat, 2026-10-17): keep going through the GO/NO-GO gates while he is away ("keep going even in s3 go/no go gate, keep going don't wait on my input"). The B1 GO needs a closed-beta cohort (B1.5: 30–100 testers, D1 play days, co-play share, rematch ≥ 60 %, Night-1 survival ≥ 50 %), which has not run because nothing since S2.8 is published. Known blocking bugs: none (the soak found one client clean-up bug and it is fixed). Decision: take GO provisionally and build the L1 pieces that do not need the live build (economy simulation, data audit, codes, store and community documents, the release checklist). L1.3 (switching on Robux products) is NOT done: it needs the owner's approval. When beta data arrives, the owner reads this gate for real; a NO-GO keeps the L1 work and goes back to fix what the beta found.
## D-033 — Economy: no price or reward change before beta data (L1.1)
2026-10-17 · L1.1 · **Status: Accepted (unattended, recommendation)**
A 10,000-voyage model of the live numbers (assumed crews and survival, stated in the L1.1 record) gives about 11 Pearls a voyage (p95 28, highest 50; the hard bound for one voyage is 146), the whole live catalogue (538 Pearls of gear and beam colours plus 320 Pearls of boost ranks to the +15 % cap) after about 62–83 voyages, or 33 for a crew that never loses. Every Pearl source is per night, per voyage, once per category or once a day: nothing pays per kill, per minute or per repeat, so inflow cannot run away. Decision: change nothing now; tune `pearlsFor`, prices and the merchant from the beta's real numbers. To revise: say so.
## D-034 — Codes and their rewards (L1.4)
2026-10-17 · L1.4 · **Status: Accepted (unattended, recommendation)** — flagged for the owner
Taken: two codes to start. LIGHTHOUSE (promo, 10 Pearls, about one voyage) for the relaunch; KEEPER as the creator-code template, giving a new beam colour, the Keeper's Glow (looks only, never sold). The owner adds one row per creator (their code, the same or a new cosmetic) and can give any code an end date. Each code pays once per profile, kept forever in `RedeemedCodes`. The code box is in Settings, which a returning player reaches from the title screen (a first-time player goes straight to the ship and has no codes to use yet). One code every 10 seconds per player (the contract rate). To revise: say so.
## D-035 — Store art at the relaunch (L1.5)
2026-10-17 · L1.5 · **Status: Accepted (unattended, recommendation)**
No icon test has run (S3 waits for live players), so the final icon is A (the beam burning a Brute, no text) with more contrast and a vignette. Five thumbnails, led by the lighthouse at night ("SURVIVE 7 NIGHTS"). The trailer has no music: Claude cannot license audio; the owner adds a track from the Creator Store's licensed audio if it is used as a video ad. The store description now names the new monsters and the return systems. To revise: say so.
## D-036 — How Robux cosmetics work (L1.3)
2026-10-17 · L1.3 · **Status: Accepted (owner approved L1.3; details are the recommendation)** — flagged for the owner
Owner (project chat, 2026-10-17 13:17 UTC): "Approve L1.3". Taken: housings, coats, lanterns and flags became items like the beam colours (owned, equipped, sold for Pearls; the Founder's Flag is the Robux-only supporter item). The profile gets optional `Equipped.Housing/Coat/Lantern/Flag` (the §6.1 schema already had Coat, Lantern and Flag; Housing added; an equipped item that is not owned or does not fit comes off at load). What each looks like: the Keeper's housing as eight bars round the lantern room while they hold the lamp; a coat recolours the armor you wear (protection unchanged); a small lantern at your hip that lights nothing; the ship flies the flag of the first player in the server who has one. Robux prices: the B1.1 list plus Sea Glass 29, Moonlight 39, Ember 59 for the beam colours. Each receipt is granted once (claim `receipt:<PurchaseId>`). The selling switch `ROBUX_ENABLED` is left off: Claude's safety check would not switch on selling from a forwarded approval, the products do not exist yet, and with ids of 0 nothing could be sold anyway. To revise any of it: say so.
## D-037 — First live-ops cycle: the Shipwreck Rescue event (LO.1–LO.4)
2026-10-17 · LO · **Status: Accepted (unattended, recommendation)** — flagged for the owner
Owner (thread, 2026-10-17): "Skip the test for now, keep going into the plan ahead." Taken: stage LO's first monthly item, the Shipwreck Rescue event voyage (architecture §11; the owner's Prototype B idea). The event runs 2026-10-17 to 2026-11-07 (UTC) in `Definitions/LiveEvents`; while it is on, every crew can choose the 5-night Rescue voyage on the crew card (no unlock). A wreck lies on the shore with 8 castaways; a crew member carries one at a time (not with oil) to a lit shelter by the lighthouse; each one brought in pays the crew 15 Shells. A carrier who falls drops theirs back at the wreck (no loss, no timer: rule 10). At the end of the voyage each crew member gets 1 Pearl per 2 castaways saved (at most 4) and, once ever, the Rescuer's Flag when all 8 were saved. The voyage's own Pearls follow the usual rules (5 nights + 5 for a win). Also: the shop card's type line stops before the price, and the code box is in the BAG for players who skip the title. To revise any number, the window, or the event itself: say so.
## D-038 — New sea and sky lighting (visual overhaul V1)
2026-10-17 · Visual overhaul · **Status: Accepted (unattended, recommendation)** — flagged for the owner, who judges the look
The owner (2026-10-17) rejected the current visuals ("looks like garbage"; "I'm the one who can decide what's look good for players"). The coordinator relayed the plan in `research/visual_overhaul_plan.md` as top priority, starting with V1 (sea and sky). The ART_BIBLE lighting values were owner-approved earlier, so the change is logged here. Taken: the terrain sea is extended from an 800-stud square to 3,072 studs on every side (water to y = 0, sand floor at -36 to -40, the same as before), so its edge is gone. Night: Brightness 1.6 → 1.3, Ambient 40/48/78 → 34/42/58, OutdoorAmbient 92/108/158 → 70/88/112, atmosphere density 0.32 → 0.34, offset 0.3, haze 0.6 → 1.2, colour 52/72/122 → 46/64/80, decay 26/36/52. Day: Brightness 2 → 1.4, ambients a little greyer, atmosphere density 0.3 → 0.4, offset 0.2, haze 0.5 → 2.4, colour 199/215/230 → 150/164/174. On each voyage crew member's device the storm also raises the waves (size 0.35 → 0.85, speed 14 → 26), closes the clouds (cover 0.8, dark) and hides the stars; calm weather has overcast clouds (cover 0.78). No gameplay value changed. Not done yet: a real storm-cloud skybox (needs the free CC0 Cloudy Skyboxes pack downloaded and uploaded to the owner's account, which waits for the owner's yes). To revise or roll back: say so (backup `ServerStorage.Backups.VIS_V1_before_2026-10-17` holds the old scripts and values).
## D-039 — One palette and a cooler colour grade (visual overhaul V5)
2026-10-17 · Visual overhaul · **Status: Accepted (unattended, recommendation)** — flagged for the owner, who judges the look
The plan's V5 asks for one style. Taken: the terrain material colours are moved to one cold palette (values in ART_BIBLE: mossy greens, wet blue-grey stone, dark earth, muted sand; they apply to both islands), and the `GlassPop` colour correction loses its +12% saturation (now 0), gets contrast +0.1 and a slight cool tint, so the cartoon tower, textured props and terrain sit together and the amber lights stand out. Props built in V4 already use wood, slate, cobble and metal; the remaining "plastic" parts are textured meshes and were left alone. Roblox's material set (2022 vs older materials) is a place setting a script cannot change; left as it is. To revise or roll back: say so (old colours and the old `GlassPop` are in `ServerStorage.Backups.VIS_V5_before_2026-10-17`).
## D-040 — Harbor UI Look A "Bold" and display-only rarity tiers
2026-10-17 · Harbor UI · **Status: Accepted (unattended, recommendation)** — flagged for the owner, who judges the look and can pick Look B
The owner asked for new harbor UI ("Let's start with the harbor isle, we need new UI for shops and leaderboard etc"). The coordinator relayed the design spec (`research/harbor_ui_spec.md`): build Look A "Bold" by default. Taken: `Config.UI_SKIN` "pirate" → "bold", so every UiKit screen (shop, BAG, menus, dialogs, the harbor board and HUD buttons) uses the new look; the in-voyage glass HUD is not touched. Every item gets a display-only rarity tier. The spec fixed the weapons (Driftwood Common, Storm and Flare Uncommon, Coral Lance Rare, Tidecaller Epic, Whaler's Legendary); armour and cosmetics on the same price bands: free starters Common; up to 60 Pearls Uncommon; 80–90 Rare; 140 Legendary; reward items by how hard they are to get (invite and code Rare, the event flag Epic, the supporter flag Legendary); Fire Shell Crate Common. Tiers change no price, stat or save field. To switch to Look B, revise a tier, or go back to the pirate look: say so (`Config.UI_SKIN`; the old scripts are in `ServerStorage.Backups.HUI_before_2026-10-17`).
## CP — S4.1 passed (🟦 Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · 0 creature raycasts over night 1
## CP — S4.2 + S4.3 passed (🟦 Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · 10.0 KB/s per client at 45 creatures; 60 FPS
## CP — S4.4 passed (🟦 Script Analysis; phone FPS pending, owner) · 2026-10-17 · auto-approved (unattended) · DEV only · 1 light in a 45-creature swarm; 0 new sound/burst parts
## CP — S4.5 passed (🟦 Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · 0 server orb moves after landing
## CP — S4.6 measured (🟦: 1 client; 16 MB/h after warm-up, 59 MB/h overall incl. warm-up; 0 errors) · 2026-10-17 · auto-approved (unattended) · DEV only
## CP — S4.7 publish package written (🟦, waits for the owner's DEV publish and phone check) · 2026-10-17 · DEV only
## CP — S5.1 + S5.2 passed (🟦 Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · Main 1073 → 14 lines; TestRunner 127/127; every remote answered
- Accepted (unattended, recommendation): remotes are created by Platform and exposed (parented) by Network last, instead of created last, because handlers connect during Init. To revise: say so.
## CP — S5.3 passed (🟦 Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · 6 callbacks → bus; 20 publishers; TestRunner 132/132
- Accepted (unattended, recommendation): the Bootstrap `ctx` keeps handing the round loop its ship/travel functions once at boot (composition root); only service-to-service callback assignment is removed. `LampService.colorFor` became a player attribute rather than an event (it is a lookup, not a reaction). To revise: say so.
## CP — S5.4 passed (🟦 Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · 35 definitions checked at boot; a broken price stops the boot with a clear message; TestRunner 140/140
- Accepted (unattended, recommendation): catalogs stay in `Shared/` (no move under `Definitions/`); `_Registry` sits at `Shared/_Registry` as the architecture names it. To revise: say so.
## CP — S5.5 passed (🟦 Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · UiKit 3,115 → 40 lines + 5 parts; 20/20 screens and 10/10 guide pages unchanged; v1 API and Gear.client deleted
## CP — S5.6 passed (🟦 Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · glass built natively (repaint pass deleted); Hud.client 2,044 → 711 lines; 84/84 HUD snapshots identical apart from 2 intended changes
- Accepted (unattended, recommendation): gauge caps and the fuel track stay navy in the glass HUD (the old repaint let them turn brown after the first update), and the keeper beam button draws its own label (keeps its 190 px width). To revise: say so.
## CP — S5.7 passed (🟦 Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · StatPipeline for weapons, armor and bench upgrades; previews == voyage values; no number changed; TestRunner 147/147
- Accepted (unattended, recommendation): STATS.md cap for WeaponRange raised 40 → 100 so the pipeline keeps today's approved ranges (50–70). To revise: say so.
## CP — S5.8 publish package written (🟦, waits for the owner's DEV publish) · 2026-10-17 · DEV only · S5 exit: 147 tests, Main 15 lines; warnings unmeasured
## CP — S6.1 passed (🟦 4-client run, Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · one boss per crew member, evenly spread; boss = 5 slots of MAX_CREATURES; 4 bosses + 25 small at 6.3 KB/s, 60 FPS; TestRunner 152/152
## CP — S6.2 passed (🟦 Shell-sink telemetry, Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · merchant sells 5 voyage-only items for crew Shells; replay-safe; wiped at Results; TestRunner 162/162
## CP — S6.3 passed (🟦 real phone check, Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · Orbiting Blades: 6 crabs cut down in 11.8 s with no input; TestRunner 168/168
## CP — S6.4 passed (🟦 Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · boosts capped at +15% (cap test), migration fixture, 2 weapons + 1 armor; D-022 timestamp fix; TestRunner 177/177
## CP — S6.5 passed (🟦 blind test, Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · 3 monsters with telegraphs 0.75–1.00 s measured; 45-creature mix at 9.6 KB/s, 60 FPS; TestRunner 182/182
## CP — S6.6 passed (🟦 blind test, Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · Tide Witch summons, Coral Shaman mends; telegraphs 0.75–1.08 s measured; 45-creature mix at 9.6 KB/s, 60 FPS; TestRunner 182/182
## CP — S6.7 publish package written (🟦, waits for the owner's DEV publish and the Prototype B session) · 2026-10-17 · DEV only · S6 exit: all six requests Tested
## CP — S7.1 passed (🟦 Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · logbook from the bus; discover once, reward once (live: 7 creatures → +15 Pearls once); TestRunner 187/187
## CP — S7.2 passed (🟦 Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · daily objective, paid once, a missed day changes nothing (advanced-clock test); TestRunner 193/193
## CP — S7.3 passed in Studio (🟦 live ordered stores, Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · board shows a survived night 19.7 s later; weekly reset by store name; TestRunner 197/197
## CP — S7.4 passed (🟦 Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · specialties from role stats only; +15% cap test; TestRunner 202/202
## CP — S7.5 passed (🟦 a real two-account invite, Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · Shared Lantern once per pair; TestRunner 207/207
## CP — S7.6 publish package written (🟦, waits for the owner's DEV publish) · 2026-10-17 · DEV only · S7 return systems complete
## CP — B1.1 passed in Studio (🟦 owner creates the products, Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · 9 cosmetics as definitions, looks only by registry; Robux off; TestRunner 212/212
## CP — B1.3 passed (🟦 Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · §24 security tests automated against the live handlers; TestRunner 218/218
## CP — B1.4 soak passed in Studio (🟦 4 clients, 2 phones, live memory graph) · 2026-10-17 · auto-approved (unattended) · DEV only · 102 min, 5 voyages, 0 errors; client clean-up bug fixed
## CP — B1.5 cohort 🟦 (owner: invite 30–100 testers after the DEV publish) · 2026-10-17
## CP — B1.6 GO/NO-GO taken provisionally (D-032) · 2026-10-17 · owner's standing instruction · no beta data
## CP — L1.1 passed (🟦 beta data) · 2026-10-17 · auto-approved (unattended) · DEV only · 10,000-voyage model, inflow bounded; no number changed (D-033); TestRunner 226/226
## CP — L1.2 passed · 2026-10-17 · auto-approved (unattended) · DEV only · migration chain on 6 fixture saves, idempotent, JSON round trip; rollback drill green (AdminDataSpec); TestRunner 226/226
## CP — L1.3 waits for the owner's approval (🟦; nothing enabled) · 2026-10-17
## CP — L1.4 passed (🟦 Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · codes once per profile; Settings code box clicked through in a play test; TestRunner 234/234
## CP — L1.5 store files made (🟦 the owner uploads) · 2026-10-17 · DEV only · final icon, 5 thumbnails, 29.5 s trailer, description
## CP — L1.6 community written (🟦 the owner sets up Discord and fills the creator list) · 2026-10-17 · docs/COMMUNITY.md
## CP — L1.7 release checklist written (🟦 READY FOR OWNER: production relaunch) · 2026-10-17 · restore point "L1 RC" in DEV
## CP — L1.3 built and tested in DEV (🟦 product ids, the switch, a real test purchase) · 2026-10-17 · owner approved L1.3 · TestRunner 240/240
## Robux selling switch on · 2026-10-17 16:05 UTC · owner in the thread: "switch on Robux sales" · `ROBUX_ENABLED = true` in DEV; nothing is on sale until the developer product ids are filled in · TestRunner 240/240
## CP — L1.3 passed live · 2026-10-17 16:43 UTC · owner published DEV (backup `backups\LighthouseKeepers_DEV_L1RC_2026-10-17.rbxl`) and reports "Purchase worked" for a real Robux purchase
## DEV published by the owner · 2026-10-17 · covers the S2.8, S4.7, S5.8, S6.7 and S7.6 packages; their live checks are still to be reported
## CP — LO.1–LO.4 passed (🟦 Script Analysis) · 2026-10-17 · auto-approved (unattended) · DEV only · event windows, Shipwreck Rescue voyage played to a win (8/8 saved, +4 Pearls, Rescuer's Flag once), shop card label, codes in the BAG; TestRunner 249/249
## CP — LO.5 publish package written (🟦, waits for the owner's DEV publish) · 2026-10-17
## LO.5 published by the owner · 2026-10-17 17:19 UTC · DEV only · backup `backups/LighthouseKeepers_DEV_LO1_2026-10-17.rbxl` (1.0 MB) · live checks pending
## CP — V1 sea and sky passed (🟦 Script Analysis; the owner judges the look) · 2026-10-17 · auto-approved (unattended) · DEV only · sea edge gone, storm night and overcast day; TestRunner 249/249
## CP — V2 the beam passed (🟦 Script Analysis; the owner judges the look) · 2026-10-17 · auto-approved (unattended) · DEV only · soft layered beam and rain glints, client only; TestRunner 249/249; 0 errors
## CP — V3 storm effects passed (🟦 Script Analysis; the owner judges the look) · 2026-10-17 · auto-approved (unattended) · DEV only · rain fixed and heavier, rain sheets, lightning bolt and flash, shore foam and spray; beam dimmed beside the camera; TestRunner 249/249; 0 errors; 60 FPS
## CP — V4 island rebuild passed (🟦 Script Analysis; the owner judges the look; his preVisual .rbxl save is still to come) · 2026-10-17 · auto-approved (unattended) · DEV only · rocky islet, coves, paths, hut, oil shed, dock, lanterns; creatures, ground grid and oil prompt re-checked; TestRunner 249/249; 0 errors
## CP — V5 one material style passed (🟦 Script Analysis; the owner judges the look) · 2026-10-17 · auto-approved (unattended) · DEV only · terrain palette and colour grade; TestRunner 249/249; 0 errors
## CP — V6 harbor at dusk passed (🟦 Script Analysis; the owner judges the look) · 2026-10-17 · auto-approved (unattended) · DEV only · golden hour in the harbor on each device, amber lanterns, campfire, sign above the awning, palms, pier; TestRunner 249/249; 0 errors
## CP — V7 hit and death feel passed (🟦 Script Analysis; the owner judges the feel) · 2026-10-17 · auto-approved (unattended) · DEV only · foam death burst, hit sparks, camera shake, low-oil lamp flicker; TestRunner 249/249; 0 errors
## CP — V8 phone check (🟦: Studio numbers and budget table recorded; device emulator and real phone not reachable, the real-phone FPS check is the owner's) · 2026-10-17 · DEV only · TestRunner 249/249
## CP — Harbor UI (HUI.1–HUI.5) passed (🟦 Script Analysis; the owner judges the look) · 2026-10-17 · auto-approved (unattended) · DEV only · Look A Bold, rarity tiers, new shop, HARBOR LEGENDS board, harbor HUD; TestRunner 250/250; 0 errors; no server, remote, price or save change
## D-041 — Menu pattern: grid + detail pane with big buttons
2026-10-17 · S2.5c / S5.5 · Accepted
Context: the owner showed the *99 Nights in the Forest* crafting screen and said players like the big buttons. The current menus (3.1k-line UiKit with a second restyle pass) have phone text overflow (D-011) and no shared layout.
Decision: one menu pattern for every full-screen menu — equal square tiles (icon → name → icon+number cost), one tile always selected, a fixed right-hand detail pane with one line, stat delta and one 112 px action button, locked items dimmed under a single reason divider, resource totals in the header, a huge red close top-right, hotbar and night strip visible behind. Full spec in `docs/ART_BIBLE.md` *Menu pattern*. Built as `UiKit/Tiles` on the Quartermaster shop and workbench in **S2.5c**; folded into the UiKit split in S5.5; `StatPipeline` previews in S5.7. Pirate skin kept for the header; panel body uses the HUD glass tokens. Rule 5 (no second restyle pass) stands: screens are rebuilt on the pattern or left alone.
Approved by: owner (2026-10-17)
Note: written as D-012 in the owner's file; D-012 was already taken, so it is D-041 (the file's own instruction).
## D-042 — The Bold look is the game's UI look; S2.5c builds the D-041 menu pattern in it
2026-10-17 · Harbor UI / S2.5c · **Status: Accepted by the owner** (thread, 2026-10-17 21:15 UTC: "Yeah and I like the bold style you gave me earlier we can use it"). Revises the unattended version below, which planned a return to the pirate skin at S2.5c: the skin stays `"bold"`; at S2.5c the shop and workbench take the D-041 *layout* (tiles, detail pane, big action button, sizes) in the Bold colours and fonts instead of the pirate header and glass body.
Unattended version, superseded:
D-041 (menu pattern: pirate wood header, glass body, 5/3-column tiles, 112 px action button) arrived after the harbor UI was built in Look A "Bold" (D-040: `Config.UI_SKIN = "bold"`, 3-column cards). Taken: the Bold harbor UI stays as it is for now (no second restyle pass, D-041 rule 1); when S2.5c runs in roadmap order, the Quartermaster shop and the workbench are rebuilt on the D-041 pattern and `Config.UI_SKIN` goes back to "pirate" as the pattern specifies. To switch back to pirate now instead: say so (one setting).
