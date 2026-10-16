# CURRENT PHASE

**Stage:** R0 — Re-baseline
**Substage:** R0.1 — Decision D-001 (place model)
**Status:** ⬜ Not started
**Last checkpoint passed:** none

## What this substage is
The owner decides the place model before any code moves:
- **Option A (recommended):** one place, one crew per server (server size 4). Freeze the Harbor/Isle split. Protect production with ProfileStore in R1.
- **Option B:** continue the two-place split in the test experience, applying the five corrections in `docs/AUDIT_2026-10-16.md §6` first.

The recommendation and its reasons are in `architecture.md` §4.4 and `DECISION_LOG.md` D-001 (status: Proposed).

## Passes when
D-001 has a status of Accepted (A or B) with the owner's line in `docs/DECISION_LOG.md`.

## Then
R0.2 freezes the `multiship-test` branch (Option A) or re-scopes R1 around the corrections (Option B — Claude rewrites R1.3/R1.7 in `ROADMAP.md` before proceeding).

## Repository
`https://github.com/moeelzayyat/lighthousev2` at `C:\RobloxProjects\Lighthousev2`. The old repo and folder are history only.

## Studio
No Studio changes in R0.1. When Studio work starts at R0.4: production window only, PlaceId 132065051336560 verified, API access OFF.
