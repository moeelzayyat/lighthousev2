# Lighthouse Keepers

Co-op storm-survival game for Roblox, 1–4 players. A crew keeps a lighthouse lamp burning through a voyage of storm nights: one aims the beam, the rest carry oil, repair, build cannons and fight sea creatures. Shells inside a voyage; Pearls forever.

**Live:** PlaceId 132065051336560 · GameId 10769064643 · published by the owner.
**Repository:** https://github.com/moeelzayyat/lighthousev2 · **Local folder:** `C:\RobloxProjects\Lighthousev2`
**History:** the previous repository `moeelzayyat/lighthousekeepers` (archived) holds everything before v2.0; its `docs/` is copied here under `docs/legacy/`.

## Documents
| File | Purpose |
|---|---|
| `architecture.md` | Master architecture v2.0 (clean-sheet target + migration). The authority. |
| `CLAUDE.md` | Operating contract and the owner's hard rules. Read first every session. |
| `docs/AUDIT_2026-10-16.md` | Technical + player-psychology audit of the current build, with file:line findings and the verdict on the pending multi-ship batch. |
| `docs/ROADMAP.md` | Stages → substages → checkpoints, R0 to live ops. |
| `docs/CURRENT_PHASE.md` | The one substage in progress. |
| `docs/DECISION_LOG.md` | Decisions and owner approvals (D-001 is the place-model decision). |
| `docs/SYSTEM_REGISTRY.md` | Every system with its current status. |
| `docs/API_CONTRACTS.md` · `EVENTS.md` · `STATS.md` | Remotes, bus events, stats. |
| `docs/TEST_PLAN.md` · `PERFORMANCE_BUDGETS.md` · `LIVEOPS_PLAYBOOK.md` · `ART_BIBLE.md` | Testing, budgets, cadence, art. |
| `docs/HANDOFF_REPORT.md` | Append-only checkpoint records. |
| `docs/legacy/` | `progress.md`, `IMPLEMENTATION_LOG.md`, the audit and batch folders from before v2.0. History; read-only. |
| `src/` | Read-only Rojo export of the Studio tree, per checkpoint. |
| `assets/ART_SOURCES.md` | Every asset ID, origin, license. |

## Toolchain
Roblox Studio is the source of truth. Claude Code works through the Roblox Studio MCP on the owner's PC. Rojo is used **only** to export scripts into `src/` after each checkpoint. Tests run inside Studio (`ServerStorage/Tests/TestRunner`).

## Setup for a new Claude Code session
1. Open Lighthouse Keepers in **its own** Studio window (PlaceId 132065051336560). Keep Studio API access **off**.
2. In this folder: *"Read CLAUDE.md and docs/CURRENT_PHASE.md, then begin the current substage."*
3. Claude's first Studio action is `list_roblox_studios` and PlaceId verification.

## Migration from the old repo (R0.3)
From `moeelzayyat/lighthousekeepers`: copy `src/` (branch `main`, the live build's export) and `tests/` here; copy its `docs/` into `docs/legacy/` unchanged. In the old repo, tag `multiship-test` as `frozen-2026-10-16` and archive the repository. Nothing from the old `work/`, `backups/` or `vendor-review/` folders is copied.
