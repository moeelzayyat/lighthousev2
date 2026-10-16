# CURRENT PHASE

**Mode:** UNATTENDED (D-010); the owner asked to stop at publish substages and GO/NO-GO gates.
**Studio:** work in the **DEV experience "Lighthouse Keepers DEV"** only (D-013). DEV PlaceId **102473202766620**, GameId 10771322445 (created by the owner 2026-10-16 from `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_seed_2026-10-16.rbxl`). Production (PlaceId 132065051336560) is off limits until the rebuild is finished.
**Stage:** S2 — First session & voyage length
**Substage:** S2.2 — Dawn Pearl banking
**Status:** 🟨 In progress
**Last work:** S2.1 voyage definitions (Standard 7 nights default, Long 13 nights unlocked by a Standard win) built, tested (TestRunner 83/83 in DEV) and play-tested in DEV; 🟦 only on Script Analysis. R1.9 ✅ in DEV (owner's live save check).

## S2.2 checkpoint (from ROADMAP §4)
- Deliverables: `GrantService` grant at each dawn with claimId `voyageId:night<n>:userId`; HUD "+1 Pearl banked" with the lantern sound; Results shows the total banked.
- Passes when: leaving at night 5 keeps 4 Pearls on rejoin (mock store); replaying a dawn claim grants once.
- Verify: TestRunner, play test in DEV.
- Numbers stay owner-approved: 1 Pearl per night survived, +5 for a win (a Standard win still totals 12, Long 18). Only *when* Pearls are granted changes (architecture §2.4).

## Open owner items
- Script Analysis warning count for the touched modules (or permission to install `luau-analyze`).
- R1.7: optional 4-client Studio test (in DEV).
- R0.2 tag/archive old repo. (R0.4 version-history save withdrawn; R0.6 title change deferred to L1.5, D-013.)
