# PERFORMANCE BUDGETS

Targets from `architecture.md` §23. Measured cells hold real numbers only. Baselines are from `docs/legacy/IMPLEMENTATION_LOG.md` (Oct 12–13, Studio, solo).

## Server
| Metric | Target | Baseline (solo) | S4.2 | S4.6 | S6.1 | B1.4 |
|---|---|---|---|---|---|---|
| Game work per frame (ms) at 4 players, 45 creatures | ≤ 2 avg | 0.11 (swarm, solo) | | | | |
| Send per player (KB/s) at 45 creatures | ≤ 30 | ~50 (per-frame PivotTo) | | | | |
| Runtime creature raycasts per frame | 0 | ~90 (2 per creature) | 0 (S4.1: 0 raycasts across prologue, day 1 and night 1, up to 31 creatures) | | | |
| Memory growth (MB/h, 3 voyages, 4 clients) | < 50 | not measured | | | | |
| Save failures (unresolved) | 0 | unknown | | | | |

## Client
| Metric | Target | Baseline | S4.3 | S4.4 (phone) | B1.4 |
|---|---|---|---|---|---|
| FPS PC during night-7 swarm | 60 | not meaningful (unfocused Studio) | | | |
| FPS low-end Android (device: ______) | ≥ 30 | not measured | | | |
| Replicated instances per creature | ≤ 3 | 7 | | | |
| Dynamic lights during a swarm | ≤ 4 (bosses) | up to ~20 | | | |
| Transient sound/VFX parts per minute | ≤ 60 | hundreds (Part per sound) | | | |
| Rain particles/s (touch) | ≤ 300 | 315 | | | |

## First session
| Metric | Target | Baseline | S2.4 | S3 (live) |
|---|---|---|---|---|
| Join → control (new account, s) | ≤ 5 | 1.1 | | |
| Landed (s) | ≤ 15 | 12.0 | | |
| First beam hit, median (s) | ≤ 45 | 50.3 (scripted) | 37.7 (5 scripted runs, since control; before the change 44.5) | |
| Night-1 survival, 0-run unassisted | ≥ 50% | unknown | | |

## Probes (`ServerStorage/Tests/perf/`)
`HeartbeatProbe` (60 s avg/p95/p99 + creature count) · `SendProbe` (bytes/s per client from snapshot sizes) · `InstanceProbe` (replicated descendants per creature model) · `MemoryProbe` (every 60 s) · `FunnelProbe` (fresh-account timestamps). FPS: Studio `Shift+F5` for PC; the Roblox app developer stats on the owner's phone.

## Decisions driven by measurements
| Date | Measurement | Decision |
|---|---|---|
| 2026-10-12 | ~50 KB/s/player with swarm, solo | "near the comfortable limit; fix = client-side movement" (legacy) → S4.2/S4.3 |
