# PERFORMANCE BUDGETS

Targets from `architecture.md` §23. Measured cells hold real numbers only. Baselines are from `docs/legacy/IMPLEMENTATION_LOG.md` (Oct 12–13, Studio, solo).

## Server
| Metric | Target | Baseline (solo) | S4.2 | S4.6 | S6.1 | B1.4 |
|---|---|---|---|---|---|---|
| Game work per frame (ms) at 4 players, 45 creatures | ≤ 2 avg | 0.11 (swarm, solo) | | | | 1 client: `Stats.HeartbeatTimeMs` max 0.55 over 102 min (up to 50 creature slots, 22 big monsters); 60 FPS server physics throughout |
| Send per player (KB/s) at 45 creatures | ≤ 30 | ~50 (per-frame PivotTo) | 10.0 avg, 10.7 max snapshot bytes (45 creatures, 10 s, 1 client; the same packet goes to every client); `Stats.DataSendKbps` peak 16.7 (all server traffic) | | 6.26 avg, 6.75 max (4 bosses + 25 small = 45 slots, 29 creatures; 59.9 FPS) | |
| Send per player (KB/s), S6.5 mix at the cap | ≤ 30 | — | 4 eels + 5 puffers + 3 lanterns + 33 crabs/skitters (45 creatures): **9.59 avg, 10.41 max**; 59.9 FPS, lowest 1 s 60 (1 client, Studio PC) | | | |
| Runtime creature raycasts per frame | 0 | ~90 (2 per creature) | 0 (S4.1: 0 raycasts across prologue, day 1 and night 1, up to 31 creatures) | | | |
| Memory growth (MB/h, 3 voyages, 4 clients) | < 50 | not measured | | 1 client, 3 voyages, 47 min, whole Studio process: +46 MB overall (59 MB/h), of which +7 MB in minutes 21–47 (16 MB/h); Lua heap −41.6 MB; 0 errors. 4 clients pending (owner) | | 1 client, 5 voyages (Standard, Long, Standard, Long, Standard, all won), 102 min, whole Studio process (Edit + server + client): 3340 → 3488 MB, **+87 MB/h overall; +65 MB/h after a 33 MB step at minute 12; +48 MB/h over the last 30 min**. Lua heap 952 → 925 MB (−27). Server instance count flat (4547 → 4550 across a further voyage); client instances flat after the CreatureView fix (run 1 without it: +3,132 client instances per voyage while the window was not drawing). Growth sits in the engine's `Internal` tag, which Studio does not split by data model. 0 errors. A live server's memory graph is the real check (owner) |
| Save failures (unresolved) | 0 | unknown | | | | |

## Client
| Metric | Target | Baseline | S4.3 | S4.4 (phone) | B1.4 |
|---|---|---|---|---|---|
| FPS PC during night-7 swarm | 60 | not meaningful (unfocused Studio) | 60 (Studio PC, focused, 45 creatures, worst frame 18.6 ms) | | |
| FPS low-end Android (device: ______) | ≥ 30 | not measured | | owner check pending (S4.4/S4.7) | |
| Replicated instances per creature | ≤ 3 | 7 | 0 (drawn by the client; the server creature folder holds only the prologue silhouette) | | |
| Dynamic lights during a swarm | ≤ 4 (bosses) | up to ~20 | | 1 (S4.4: 45 creatures + a Barnacle Brute, 60 s; only big monsters carry a light) | |
| Transient sound/VFX parts per minute | ≤ 60 | hundreds (Part per sound) | | 0 new (S4.4: 119 kills and 119 sounds in 60 s used 1 pooled sound part with 24 attachments and 6 pooled burst balls; loot drops are S4.5) | |
| Rain particles/s (touch) | ≤ 300 | 315 | | 300 (S4.4 cap; set in code, not measured on a phone) | |

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

## Visual overhaul (V1–V8, 2026-10-17)
What the overhaul adds on each device, from the code (rates and caps are set in code; none of this is a phone measurement). Everything below is client-side; the server sends nothing new.

| Effect | Computer | Touch device | Low effects on | Script |
|---|---|---|---|---|
| Rain drops (storm, on the island) | 900/s | 300/s (S4.4 cap) | 0 | `Storm` |
| Rain sheets (4 boxes around the camera) | 4 × 70/s | 0 | 0 | `Storm` |
| Rain glints in the beam (storm, lamp lit) | 160/s | 60/s | 0 | `BeamFx` |
| Shore foam (points found once on the island) | 90 points × 0.8/s storm, 0.25/s calm | 40 points × 0.8/s | 0 | `ShoreFx` |
| Wave spray (storm) | 2 bursts × 6 every 0.35 s | 1 burst × 6 every 0.35 s | 0 | `ShoreFx` |
| Beam layers | 4 Beams (were 1) | 4 | 4 | `BeamFx` |
| Lightning bolt | 9 Neon parts, shown ~0.3 s per strike (every 7–16 s) | same | not shown (flash only) | `Storm` |
| Creature death / hit | 14 foam + 10 drops per death, 5 sparks per hit, from 1 shared part | same | same | `CreatureView` |
| Swaying / fluttering parts | 8 lanterns + 1 flag within 250 studs, moved every frame | same | same | `WindFx` |
| Static lights added | island: 9 PointLights (hut window, shed, 7 lanterns), no shadows; harbor: campfire (shadows) | same | same | place content |

Measured in Studio on this PC (DEV, 2026-10-17, prologue storm on the island, pinned camera): Automatic quality 60.2 FPS, 16.7 ms average, 17.8 ms p95; lowest quality (Level 1) 60.0 FPS, 16.7 ms, 17.9 ms p95. Studio is capped at 60 FPS here, so these show no regression on this PC and say nothing about phones. The client's workspace held 341 parts, 23 lights, 192 particle emitters (most idle at rate 0) and 5 beams at that moment. **Phone FPS: not measured** (no emulator or real phone reachable); the owner's real-phone check stands.
