# CURRENT PHASE

**Mode:** UNATTENDED (D-010); the owner asked to stop at publish substages and GO/NO-GO gates.
**Stage:** R1 — Safety & structure
**Substage:** R1.9 — Production cutover (owner publishes)
**Status:** 🟦 Waiting for the owner's publish and live check
**Last work:** R1.1–R1.8 built and tested (TestRunner 74/74). Each is 🟦 only on Script Analysis (no analyzer available to Claude) and, for R1.3/R1.6/R1.7, a live or owner-run check.

## What the owner does now
Follow "R1.9 — READY FOR OWNER TO PUBLISH" at the bottom of `docs/HANDOFF_REPORT.md`: save a local `.rbxl`, publish, Shut down all servers, join, one voyage, leave, rejoin, report the Pearl counts.

## Then
Claude marks R1.3 and R1.9 ✅ from the owner's numbers, checks the Analytics funnel for R1.6 the next day, and starts S2.1 (voyage definitions).

## Open owner items
- Script Analysis warning count for the touched modules (or permission to install `luau-analyze`).
- R1.7: Max players 4; optional 4-client Studio test.
- R0.2 tag/archive old repo; R0.4 version-history save; R0.6 title change.

## Studio
Production window only: `list_roblox_studios` → PlaceId 132065051336560 → API access OFF before any Play. Studio always uses ProfileStore's mock store, so Studio play never touches real saves.
