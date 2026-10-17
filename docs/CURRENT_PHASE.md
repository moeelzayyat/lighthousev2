# CURRENT PHASE

**Mode:** FULL UNATTENDED (D-010, D-015): decisions are taken on the recommendation and logged; the run stops only at publish substages, GO/NO-GO gates and steps that need the owner's hands.
**Studio:** work in the **DEV experience "Lighthouse Keepers DEV"** only (D-013). DEV PlaceId **102473202766620**, GameId 10771322445 (created by the owner 2026-10-16 from `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_seed_2026-10-16.rbxl`). Production (PlaceId 132065051336560) is off limits until the rebuild is finished.
**Stage:** S2 — First session & voyage length
**Substage:** S2.6 — Controller aim
**Status:** 🟨 In progress
**Last work:** S2.5 Results and replay built and play-tested in DEV (Sail again → new voyage 0.78 s); 🟦 only on Script Analysis. Before that, S2.4 first beam hit built and measured in DEV (scripted first-time player: 37.0 to 38.1 s, before 44.5 s; harness in `tests/first_beam_hit_bot.luau`); 🟦 only on Script Analysis. Before that, S2.3 Night-1 safety built, tested (TestRunner 96/96 in DEV) and play-tested in DEV as a 0-run and a 1-run player; 🟦 only on Script Analysis; D-014 (reserve fills the lamp to full) flagged for the owner. Before that, S2.2 dawn Pearl banking built, tested (TestRunner 92/92 in DEV) and play-tested in DEV (7 banked + 5 at Results = 12); 🟦 only on Script Analysis. Before that, S2.1 voyage definitions (Standard 7 nights default, Long 13 nights unlocked by a Standard win) built, tested (TestRunner 83/83 in DEV) and play-tested in DEV; 🟦 only on Script Analysis. R1.9 ✅ in DEV (owner's live save check).

## S2.6 checkpoint (from ROADMAP §4)
- Deliverables: right-stick beam aim; Focus and Leave on controller buttons; `InputController` replaces the four `inputMode()` copies.
- Passes when: a full voyage is completed with a controller in Studio.
- Verify: play test.

## Open owner items
- Keep the DEV Studio window focused during play tests (Studio drops to 15 fps when it is not the focused window and in-game prompts stop responding).
- D-014: the Night-1 reserve fills the lamp to full (100). Say a different amount to change it.
- Script Analysis warning count for the touched modules (or permission to install `luau-analyze`).
- R1.7: optional 4-client Studio test (in DEV).
- R0.2 tag/archive old repo. (R0.4 version-history save withdrawn; R0.6 title change deferred to L1.5, D-013.)
