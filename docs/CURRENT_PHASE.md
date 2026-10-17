# CURRENT PHASE

**Mode:** FULL UNATTENDED (D-010, D-015): decisions are taken on the recommendation and logged; the run stops only at publish substages, GO/NO-GO gates and steps that need the owner's hands.
**Studio:** work in the **DEV experience "Lighthouse Keepers DEV"** only (D-013). DEV PlaceId **102473202766620**, GameId 10771322445 (created by the owner 2026-10-16 from `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_seed_2026-10-16.rbxl`). Production (PlaceId 132065051336560) is off limits until the rebuild is finished.
**Stage:** S4 — Performance & mobile (S3 provisional GO, D-018)
**Substage:** S4.4 — Render budget; S2.8 waits for the owner's DEV publish; S3 waits for live players
**Status:** 🟨 In progress
**Last work:** S4.2 + S4.3 creature snapshots and client drawing (10.0 KB/s per client at 45 creatures, 60 FPS, smooth). Before that, S4.1 ground grid (0 creature raycasts over night 1; heights within 0.2 studs where creatures walk). Before that, S3.1b mode test built and play-tested in DEV (Endless Storm voyage to night 9; TestRunner 111/111); S3 gate taken provisionally (D-018). Before that, S2.7 store files made (icons A/B, 3 thumbnails, description in `assets/`); S2.8 publish package written (READY FOR OWNER TO PUBLISH, DEV). Before that, S2.6 controller aim (InputController; right stick aims) built and tested (TestRunner 103/103); 🟦 on Script Analysis and the owner's controller voyage. Before that, S2.5 Results and replay built and play-tested in DEV (Sail again → new voyage 0.78 s); 🟦 only on Script Analysis. Before that, S2.4 first beam hit built and measured in DEV (scripted first-time player: 37.0 to 38.1 s, before 44.5 s; harness in `tests/first_beam_hit_bot.luau`); 🟦 only on Script Analysis. Before that, S2.3 Night-1 safety built, tested (TestRunner 96/96 in DEV) and play-tested in DEV as a 0-run and a 1-run player; 🟦 only on Script Analysis; D-014 (reserve fills the lamp to full) flagged for the owner. Before that, S2.2 dawn Pearl banking built, tested (TestRunner 92/92 in DEV) and play-tested in DEV (7 banked + 5 at Results = 12); 🟦 only on Script Analysis. Before that, S2.1 voyage definitions (Standard 7 nights default, Long 13 nights unlocked by a Standard win) built, tested (TestRunner 83/83 in DEV) and play-tested in DEV; 🟦 only on Script Analysis. R1.9 ✅ in DEV (owner's live save check).

## What the owner does now (S2.8, DEV only)
Follow "S2.8 — READY FOR OWNER TO PUBLISH" at the end of `docs/HANDOFF_REPORT.md`: save `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_S2_2026-10-17.rbxl`, publish the DEV window, shut down servers, upload the S2.7 store files, run the live checks, report the Pearl counts. Then, for S3 (D-016): set the DEV experience to Public and start the S3.1 diagnostic ads (owner-only: ads cost Robux).

## S4.4 checkpoint (from ROADMAP §6)
- Deliverables: neon eyes, shared boss bar, no per-creature lights, client hit flash; rain per device; sound pool.
- Passes when: ≤ 3 replicated instances per creature; ≥ 30 FPS on the owner's phone during a night-7 swarm.
- Verify: real phone (owner).

## Open owner items
- S3 (D-016, D-018): after the S2.8 publish, set Lighthouse Keepers DEV to Public and run the S3.1 diagnostic ads; S3.2 playtest sessions with real phones. The S3 gate was taken provisionally with no data.
- S2.6: play one DEV voyage with a controller only (steps in the S2.6 record in HANDOFF_REPORT.md).
- Keep the DEV Studio window focused during play tests (Studio drops to 15 fps when it is not the focused window and in-game prompts stop responding).
- D-014: the Night-1 reserve fills the lamp to full (100). Say a different amount to change it.
- Script Analysis warning count for the touched modules (or permission to install `luau-analyze`).
- R1.7: optional 4-client Studio test (in DEV).
- R0.2 tag/archive old repo. (R0.4 version-history save withdrawn; R0.6 title change deferred to L1.5, D-013.)
