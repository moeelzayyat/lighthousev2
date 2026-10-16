# CURRENT PHASE

**Mode:** UNATTENDED (D-010); the owner asked to stop at publish substages and GO/NO-GO gates.
**Studio:** work in the **DEV experience "Lighthouse Keepers DEV"** only (D-013). DEV PlaceId **102473202766620**, GameId 10771322445 (created by the owner 2026-10-16 from `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_seed_2026-10-16.rbxl`). Production (PlaceId 132065051336560) is off limits until the rebuild is finished.
**Stage:** S2 — First session & voyage length
**Substage:** S2.3 — Night-1 safety
**Status:** 🟨 In progress
**Last work:** S2.2 dawn Pearl banking built, tested (TestRunner 92/92 in DEV) and play-tested in DEV (7 banked + 5 at Results = 12); 🟦 only on Script Analysis. Before that, S2.1 voyage definitions (Standard 7 nights default, Long 13 nights unlocked by a Standard win) built, tested (TestRunner 83/83 in DEV) and play-tested in DEV; 🟦 only on Script Analysis. R1.9 ✅ in DEV (owner's live save check).

## S2.3 checkpoint (from ROADMAP §4)
- Deliverables: for a player with `Stats.Runs == 0`, the emergency reserve refills once on the first Night-1 blackout; the coach oil prompt is forced; a feed line.
- Passes when: a 0-run player who never carries oil survives Night 1 once and loses Night 2; a 1-run player gets no refill.
- Verify: play test with two accounts (Studio test players on the mock store).

## Open owner items
- Script Analysis warning count for the touched modules (or permission to install `luau-analyze`).
- R1.7: optional 4-client Studio test (in DEV).
- R0.2 tag/archive old repo. (R0.4 version-history save withdrawn; R0.6 title change deferred to L1.5, D-013.)
