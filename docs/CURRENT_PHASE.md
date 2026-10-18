# CURRENT PHASE

**Mode:** FULL UNATTENDED (D-010, D-015): decisions are taken on the recommendation and logged; the run stops only at publish substages, GO/NO-GO gates and steps that need the owner's hands.
**Standing menu rules (owner, 2026-10-17, D-041):** every substage that touches a screen: (1) a menu created or rebuilt follows the *Menu pattern* in `ART_BIBLE.md` exactly (rebuild or leave alone, never layer); (2) at the checkpoint, `screen_capture` at PC 1920×1080 and Device Simulator iPhone 7 and 13 Pro Max, no tap target below 56 px on-device, no text overflow, recorded in the handoff; (3) purchases keep the existing server grant path, no new remote without its `API_CONTRACTS.md` row.
**Studio:** work in the **DEV experience "Lighthouse Keepers DEV"** only (D-013). DEV PlaceId **102473202766620**, GameId 10771322445 (created by the owner 2026-10-16 from `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_seed_2026-10-16.rbxl`). Production (PlaceId 132065051336560) is off limits until the rebuild is finished.
**Stage:** HX harbor/isle split and 4 ships (D-046, owner 2026-10-18). **The S3 public test is on hold until HX is built and live-checked.**
**Substage:** S3.1 🟦: DEV is published with the S3 measures and the sniper tower (2026-10-17 23:16 UTC). The owner starts the public test ("S3 — START THE PUBLIC TEST" steps 1–5 at the end of `docs/HANDOFF_REPORT.md`; the Maturity & Compliance questionnaire first). Claude picks up S3.3 and S3.4 when live numbers arrive; S3.6 is a GO/NO-GO gate (stop). Open: the owner's live check of the sniper tower (SNP.1); V8's real-phone report; crab and skitter art from ForgeGUI (the coordinator is fetching it).
**Status:** 🟦 HX.5: the owner publishes the same file to both places (steps in HANDOFF "HX.5 — READY FOR OWNER TO PUBLISH"), then the live check. Studio note: the DEV window now runs as the harbor (4 ships); test a voyage with `PLACE_ROLE_OVERRIDE = "isle"` (TEMPTEST, revert).
**Last work:** SA.2 (2026-10-18): Script Analysis 103 → 18 distinct warnings (the 18 are in the vendored ProfileStore). Before it: SET.1 Settings from the BAG, WPN.1 (D-048) three weapons, KRAKEN.1 (D-047) the Kraken. TestRunner 276/276; digest 174 scripts ccecd045. One publish to both places carries all of it (save `backups/LighthouseKeepers_DEV_SET_2026-10-18.rbxl`). Waiting on the owner: yes/no to upload shop icons; whether to build a second map now (the plan holds it until playtests ask).

## What the owner does now (DEV only) — HX first: create the Lighthouse Isle place and send its PlaceId. Do NOT start the public test yet (D-046).
Start the public test: follow "S3 — START THE PUBLIC TEST" at the end of `docs/HANDOFF_REPORT.md`.

## Earlier packages (already published by the owner on 2026-10-17; live checks still to report)
Follow "S7.6 — READY FOR OWNER TO PUBLISH" at the end of `docs/HANDOFF_REPORT.md` (one publish covers S2.8, S4.7, S5.8, S6 and S7; save `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_S7_2026-10-17.rbxl` first; the S6.7 package's live checks still apply), then the S2.8 store-file steps in "S2.8 — READY FOR OWNER TO PUBLISH": save `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_S2_2026-10-17.rbxl`, publish the DEV window, shut down servers, upload the S2.7 store files, run the live checks, report the Pearl counts. Then, for S3 (D-016): set the DEV experience to Public and start the S3.1 diagnostic ads (owner-only: ads cost Robux).

## Next checkpoint
None for Claude until the owner acts. When the owner publishes DEV or production, Claude finishes the matching 🟦 live checks (S2.8, S4.7, S5.8, S6.7, S7.6, R1.9-style save check, L1.7) and starts stage LO after the relaunch.

## Open owner items
- L1.7: the relaunch checklist at the end of `docs/HANDOFF_REPORT.md` ("L1.7 — READY FOR OWNER"); save `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_L1RC_2026-10-17.rbxl` first.
- L1.5: upload the icon, five thumbnails, description (and optionally the trailer) from `assets/`.
- L1.6: set up Discord (docs/COMMUNITY.md) and fill in the creator list.
- L1.3 ✅: a real Robux purchase worked in the published DEV game (2026-10-17). DEV is published: the live checks of S2.8–S7.6 are next (a survived night on the harbor board, the daily objective notice, an invite with a friend, code LIGHTHOUSE).
- B1.4: 4-client Studio run; two phones on a night-7 swarm; the live server memory graph after publishing DEV.
- B1.5: invite 30–100 testers after the DEV publish.
- B1.1: create the developer products listed in the B1.1 record (HANDOFF_REPORT.md) when you want them, and send Claude the ids; nothing is enabled. D-030 to review.
- B1.2: age rating: Creator Hub → Lighthouse Keepers DEV → Audience → Maturity & Compliance questionnaire (cartoon sea monsters; no blood, gambling or purchases yet).
- S7.3: after publishing DEV, survive a night and check the harbor board within a minute (live ordered data stores).
- S6.5: blind test: have a tester play nights 2–6 and name what each new monster does (Spitter Eel, Puffer Mine, Ghost Lantern); D-023 to review.
- S6.4: save `C:\RobloxProjects\Lighthousev2\backups\LighthouseKeepers_DEV_S6-4_2026-10-17.rbxl` (new item models live only in the place); D-021 and D-022 to review.
- S6.2: merchant prices are D-019 (recommendation); after live voyages, compare the run summaries' `Shells spent (merchant n)` and Shells left with earlier runs.
- S6.1: optional 4-client boss night (Test → Clients and Servers → 4 players, sail, reach night 4): 4 boss bars, note any lag.
- S4.6: optional 4-client Studio run (Test → Clients and Servers → 4 players, one voyage); say whether anything errors.
- S4.4: during a night-7 swarm, read the FPS on your phone (in the game: Roblox menu → Settings → Performance Stats on; the FPS shows in the corner) and tell Claude the number and the phone model.
- S3 (D-016, D-018): after the S2.8 publish, set Lighthouse Keepers DEV to Public and run the S3.1 diagnostic ads; S3.2 playtest sessions with real phones. The S3 gate was taken provisionally with no data.
- S2.6: play one DEV voyage with a controller only (steps in the S2.6 record in HANDOFF_REPORT.md).
- Keep the DEV Studio window focused during play tests (Studio drops to 15 fps when it is not the focused window and in-game prompts stop responding).
- D-014: the Night-1 reserve fills the lamp to full (100). Say a different amount to change it.
- Script Analysis warning count for the touched modules (or permission to install `luau-analyze`).
- R1.7: optional 4-client Studio test (in DEV).
- R0.2 tag/archive old repo. (R0.4 version-history save withdrawn; R0.6 title change deferred to L1.5, D-013.)
