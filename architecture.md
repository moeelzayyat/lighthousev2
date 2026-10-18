# LIGHTHOUSE KEEPERS
## Master Game Architecture & Production Specification

**Document Version:** 2.0 (clean-sheet; supersedes `progress.md` as the design authority and the Harbor/Isle split plan)
**Status:** Approved design baseline — implementation begins at Stage R1 (Re-foundation)
**Platform:** Roblox (phone, PC, console)
**Language:** Luau (`--!strict`)
**Development Environment:** Claude Code + Roblox Studio MCP on the owner's PC; Studio is the source of truth; Git holds docs and a read-only script mirror
**Architecture:** Server-authoritative, one crew per server, domain-structured, event-bus driven, data-driven content, ProfileStore persistence
**Production Stages:** Re-foundation → Public Test → Content → Closed Beta → Relaunch → Live Operations

---

# 0. WHAT THIS REPLACES AND WHY

The current game is a complete, playable co-op survival loop with a unique core verb. The code that runs it is a 991-line entry script wiring 23 services through hidden callbacks, a 3,100-line UI kit with a dead API inside it, production saves that can lose Pearls on a quick rejoin, no tests in the repository, and a half-built two-place split with reserved servers, teleports and a hand-written session lock that carries two HIGH-severity bugs. The full audit is in `docs/AUDIT_2026-10-16.md`.

| Area | Current | v2.0 |
|---|---|---|
| Place model | One place in production; Harbor + Isle split with reserved servers in test | **Superseded by D-046 (2026-10-18):** a shared harbor place with 4 ships and a Lighthouse Isle place (one reserved server per crew, max 4). Teleports carry only the crew's choices; ProfileStore is the only save path (no manifests, no hand-offs). See §4.4. |
| Persistence | Blind `UpdateAsync` overwrite, no lock, single save attempt (prod); custom metadata lock (test) | **ProfileStore** in production with session locking, retries, `BindToClose`; schema v2 with type validation (§19) |
| Code structure | God `Main`, implicit init order, callback wiring | 8 domains, `Init/Start` lifecycle, typed event bus (§5) |
| Remotes | 29 created by name in a loop, handled anywhere, uneven validation | Contract registry; guard + rate limit per remote; created last (§18) |
| Simulation | Table sim + anchored models (good); per-frame `PivotTo` replication, 2 BillboardGuis + PointLight per creature, 2 raycasts per creature per frame | Table sim kept; 20 Hz server step with client interpolation; cached ground grid; render budget per creature (§8) |
| UI | 3.1k-line UiKit + 2k-line HUD with a second "glass" restyle pass stacked on top | UiKit split into five modules; one layout pass with variants; dead v1 API and `Gear.client` deleted (§21) |
| Run length | 13 nights ≈ 27 min, fixed | **7-night voyage (~15 min) default; 13-night Long Voyage unlocked by a win** (§2.3) |
| First session | Fast path (good); a new solo phone player loses Night 1 with 0 Pearls in ~2.5 min | Night-1 safety reserve for 0-run players; Pearls banked at each dawn; first beam hit ≤ 45 s (§3) |
| Return | Results "next goal" only | Dawn-banked Pearls, daily objective (no streak), Logbook collection, Best Night leaderboard (§13) |
| Telemetry | `EventLog` prints a run summary to Output | `EventLog` becomes the event bus; funnel wired to Roblox `AnalyticsService` (§22) |
| Tests | None in repo | `TestRunner` in `ServerStorage/Tests`; pure `nightPlan`, `pearlsFor`, economy and lock-free save logic (§24) |
| Store presence | "Lighthouse Keepers - Staging", no icon test | Real title, icon A/B, 16:9 thumbnails (§27) |
| Process | Per-task auditor packages, 13-task save audits, external relay per task | Checkpoint protocol; independent review at stage gates only; owner's hard rules kept verbatim (§25) |

**Owner-approved numbers and policies are preserved** unless this document explicitly changes them (the only changes: default voyage length, dawn Pearl banking, Night-1 safety, Shell sinks). Everything in `progress.md §6` that is not named here stands.

---

# 1. PROJECT MISSION

Lighthouse Keepers is a 1–4 player co-op storm-survival game for Roblox. A crew keeps a lighthouse lamp burning through a voyage of storm nights: one player aims the beam, the others carry oil, repair the tower, build and reload cannons, and fight sea creatures with harpoons. Shells are spent inside a voyage; Pearls are kept forever and spent at the Quartermaster.

## 1.1 Pillars
1. **The light is the game.** The beam is the weapon, the resource and the thing everyone is protecting. Every role exists to keep it lit.
2. **Every role is a hero sometimes.** The oil carrier's clutch refuel at 3% fuel is as big a moment as the Keeper's boss burn, and the game says so.
3. **We nearly lost it.** Voyages are tense, short enough to finish on a phone, and losing still pays.

## 1.2 Viral thesis (Roblox discovery signals)
- **Click:** an icon that shows the beam cutting through a storm at something enormous rising from the sea. A title that says what it is.
- **Stay:** control in ~1 s, first beam hit ≤ 45 s, no 0-reward defeat in the first 3 minutes for a new player.
- **Return:** Pearls banked at every dawn; a 15-minute voyage; one daily objective with no streak; a Logbook to fill; a Best Night board.
- **Bring friends:** the game is co-op by design; the crew card, forecast vote, lamp shift and "your part" are social; invite rewards both players with a lantern cosmetic after a shared voyage.
- **Clip:** the last-second refuel with the lamp at 1%; the focused beam finishing a Barnacle Brute; "THE LIGHT HELD" at dawn.
- **Pay fairly:** cosmetics only for Robux (beam colours, lamp housings, keeper coats, lantern skins, ship flags); convenience only if earnable; never power.

## 1.3 Non-negotiable requirements (owner's rules, kept verbatim in spirit)
- Never publish, deploy, enable monetization, buy assets or modify the public experience without explicit owner approval. The owner publishes.
- Production saves are protected: no test ever writes the production DataStore; never `RemoveAsync` real data; Studio API access is **off** before every Play in the production window.
- Gameplay numbers, server validation, duplicate-request protection and the save schema change only with owner approval.
- Back up before every batch (Studio restore point + `ServerStorage.Backups.<Name>_before_<date>`).
- Multiple games live on the same PC (DEADZONE, Outlaw City). Identify the Studio instance by PlaceId before every action; never touch another game's window, files or repo.
- Every gameplay transaction is server-authoritative. Monetization never sells power. No anxiety mechanics.
- Development proceeds through measured checkpoints; players see the game at Stage S3, within ~4 weeks.

---

# 2. GAMEPLAY VISION

## 2.1 Core loop
```text
JOIN (server = one crew, ≤ 4)
  ↓ new player: fast path onto the deck · returning player: harbor deck
Crew card: forecast vote → SAIL (auto at 4/4, SAIL NOW for 1–3)
  ↓
Prologue: the storm hits, restore the light, first fight (≤ 60 s)
  ↓
Night N: beam · oil · repair · cannons · harpoons · loot
  ↓ dawn: Pearls for the night BANKED (saved) · loot window · bench
  ↓
… 7 nights (Long Voyage: 13) · bosses on 4 and 7 (Long: 4, 7, 10, 13)
  ↓
Results: cause · Moment of the storm · your part · rewards · next goal
  ↓ one tap: Sail again (same crew) · Back to harbor
Harbor: Quartermaster (Pearls) · locker · Logbook · daily objective
  ↺
```
Voyage length: 7 nights × (30 s day + 90 s night) + prologue ≈ **15 minutes**. Long Voyage ≈ 27 minutes.

## 2.2 Roles (emergent, not classes)
| Role | Verb | Hero moment (surfaced by the crew feed, results and a client slow-mo) |
|---|---|---|
| Keeper | aim wide / focus | "burned the Brute down" · "held the whole pack back" |
| Oiler | carry oil → tank | "clutch refuel at 3%" |
| Engineer | build / reload cannons | "cannon line held the east beach" |
| Harpooner | strike creatures, pull aggro | "pulled the Hermit off the tower" |
| Repairer | hold at the door | "last-stand repair at 12%" |

Roles are chosen by doing, never locked. Specialties (owner's earlier idea, §13) are optional permanent bonuses to a role, earnable only.

## 2.3 Voyage structure (design change)
- **Standard Voyage: 7 nights.** Bosses on nights 4 and 7. Win = 7 + 5 Pearls = 12.
- **Long Voyage: 13 nights.** Unlocked by one Standard win. Bosses on 4, 7, 10, 13; from night 8 every night has a boss (owner request #2). Win = 13 + 5 = 18 (owner's number kept).
- Difficulty growth per `progress.md` (full growth to night 3, then half rate; final night ×1.5 crabs); swarm by crew size unchanged.
- **Bosses by crew size** (owner request #1): on a boss night, one big monster per crew member, from different bearings, full health; tuned after the public test.

## 2.4 Pearls (design change: dawn banking)
Pearls for a survived night are **granted and saved at that dawn**, not at Results. A player who leaves at night 5 keeps 4 Pearls. Victory bonus and boss Pearl drops stay at their current rules. Anti-exploit: the dawn grant is idempotent per `(voyageId, night, userId)`.

## 2.5 Shells and sinks
Starting Shells 120; income as approved (+30% pass). New sinks so bench choices keep mattering: the **island merchant** (owner request #4, the Trader's new job on day phases) sells voyage-only items for Shells — temporary weapons (Orbiting Blades first, request #3), speed boost, damage boost, heal, tower shield, oil bundle; all wiped at Results.

## 2.6 Camera and controls
Unchanged from the current build (fixed overhead at the lamp; third person elsewhere; phone joystick hidden at the lamp; weapon slot replaces the hotbar). Additions required before relaunch: **controller beam aim** (right stick) and Focus/Leave on controller buttons; `InputController` module replaces the four duplicated `inputMode()` implementations.

---

# 3. FIRST SESSION DESIGN (FTUE)

| Time | What happens | Measured |
|---|---|---|
| 0:00 | Loading cover with one line: "Keep the light burning." | load time |
| 0:01 | 0-run player: fast path, already on the crew (existing, 1.1 s) | time to control |
| 0:12 | Lands on the island; prologue storm; coach marker on the oil pile | landed |
| ≤0:45 | First manual beam hit on a crab (coach: aim marker) | **first beam hit ≤ 45 s** |
| 1:30 | Night 1. **Night-1 safety:** for 0-run players, the emergency reserve refills the lamp **once** on the first blackout in Night 1, with the coach pointing at the oil barrels and the feed saying "The reserve saved the light — carry oil!" | Night-1 survival |
| 3:30 | Dawn 1: **+1 Pearl banked** on screen with the lantern sound | first Pearl |
| ~15:00 | Results; one-tap Sail again | second voyage started |

Rules: nothing in the first 60 s requires reading (markers and input chips carry it); no blocking pop-ups; a new player **cannot** finish their first voyage with 0 Pearls unless they leave before dawn 1.

---

# 4. TECHNICAL ARCHITECTURE

## 4.1 Core principles
1. Server-authoritative simulation; the client sends intent and renders.
2. One crew per server; no cross-server state except DataStore profiles and leaderboards.
3. Eight domains with an explicit lifecycle and a typed event bus; no hidden callback wiring.
4. Data-driven content: creatures, weapons, items, upgrades, forecasts, merchant stock, objectives, cosmetics are definitions validated at boot.
5. ProfileStore persistence; idempotent grants.
6. Pure game-logic modules (night plan, Pearl rules, economy) that run without Instances, so they can be unit-tested.
7. Performance budgets measured per checkpoint, phone first.
8. Telemetry from the bus to Roblox AnalyticsService from Stage R1.
9. Backward-compatible saves; every schema change ships with a migration and a fixture.
10. Milestone-gated with numeric exit criteria.

## 4.2 Toolchain (Studio-native)
| Tool | Purpose |
|---|---|
| Roblox Studio + Studio MCP | All editing, running, testing. Claude uses `list_roblox_studios` first every time and verifies PlaceId **132065051336560** (prod) before any action. |
| Studio Version History + `ServerStorage.Backups` | Restore point `<ID> passed` at every checkpoint; named backup folder before every batch. |
| Rojo **export only** | `src/` in Git is a read-only mirror exported after each checkpoint (the existing workflow). Never synced back into Studio. |
| `ServerStorage/Tests/TestRunner` | In-house `describe/it/expect` harness, run via `execute_luau`; summary pasted into every checkpoint. |
| ProfileStore (Creator Store, version pinned in `assets/ART_SOURCES.md`) | Production persistence from Stage R1. |
| Luau `--!strict` + Script Analysis | Zero warnings is a checkpoint condition for every module touched. |
| Studio API access | **Off** by default in the production window; on only for approved read-only Edit-mode checks, then off. |

No Rojo two-way sync, no Wally, no CI. Headless CI is replaced by the TestRunner run before every checkpoint.

## 4.3 Repository and Studio layout
```text
LIGHTHOUSE_KEEPERS/            (Git)
├── CLAUDE.md  architecture.md  README.md  .gitignore
├── docs/      ROADMAP · CURRENT_PHASE · DECISION_LOG · SYSTEM_REGISTRY · API_CONTRACTS · EVENTS · STATS
│              TEST_PLAN · PERFORMANCE_BUDGETS · LIVEOPS_PLAYBOOK · ART_BIBLE · HANDOFF_REPORT · AUDIT_2026-10-16
│              legacy/ (progress.md, IMPLEMENTATION_LOG.md, the batch and audit folders — history, read-only)
├── src/       read-only Rojo export of the Studio tree, per checkpoint
└── assets/    ART_SOURCES.md · icons/ · thumbnails/

Studio:
ReplicatedStorage/Shared/      Types/ Definitions/{Creatures,Weapons,Armor,Items,Upgrades,Forecasts,Merchant,Objectives,Cosmetics,Voyages}
                               _Registry · Stats/ · Net/ · Events/ · Config/ · Util/
ServerScriptService/Server/    Bootstrap · Domains/{Platform,Telemetry,Data,Economy,World,Encounter,Crew,LiveOps} · Admin/
StarterPlayer/StarterPlayerScripts/Client/   Bootstrap · Controllers/{Input,Camera,Interp} · UI/{Tokens,Primitives,Controls,Gauges,Dialogs,Screens/*} · Effects/ · Render/
ServerStorage/Tests/           TestRunner · unit/ · integration/ · fixtures/profiles/
ServerStorage/Backups/         <Name>_before_<date>
```

## 4.4 Place and server model
**D-046 (2026-10-18, owner) supersedes the text below.** Two places, one place file: the **harbor** (start place, about 24 players, 4 ships around the harbor island, `HarborDepartures`) and **Lighthouse Isle** (one reserved server per crew, max 4, `IsleArrival` + the unchanged voyage loop). The role comes from the PlaceId (`Shared/PlaceRole`). Teleport data carries the ship id, crew ids, voyage and forecast votes, and the isle re-checks it. ProfileStore handles a player moving between servers; the old session lock, manifest, hand-off and reclaim code stays out.

The original v2.0 text (kept for history):
**One place. Server size 4. The server is the crew.** The harbor is the crew's own deck: a player who joins mid-voyage is rowed out (existing behaviour); public matchmaking fills servers to 4; friends use Join or private servers. `MAX_CREW = 4`.

Why: a 60-player social harbor is empty at today's traffic and expensive at tomorrow's; reserved servers, teleports, manifests and save hand-offs add four failure modes before the first fight; ProfileStore already solves the only real cross-server problem (rejoin while a save is in flight).

**Future scaling trigger (logged, not planned):** if ≥ 30% of joins for a week are rejected because servers are full and the owner wants a shared harbor, revive the frozen `multiship-test` branch with the corrections in the audit. Until then it is history.

---

# 5. DOMAINS, LIFECYCLE, EVENT BUS

## 5.1 Eight domains
| # | Domain | Services | Owns |
|---|---|---|---|
| 1 | **Platform** | `FeatureFlagService`, `RemoteConfigService`, `TimeService` | flags, tunables from a Config DataStore, server time |
| 2 | **Telemetry** | `AnalyticsService` (wraps Roblox AnalyticsService), `ErrorReportService`, `EventLog` (bus + run summary) | funnel, run summary, errors |
| 3 | **Data** | `PlayerDataService` (ProfileStore), `MigrationService`, `AdminDataService` | profiles, migrations, inspect/grant/rollback |
| 4 | **Economy** | `WalletService` (Pearls), `ShellPoolService` (crew Shells), `InventoryService`, `LoadoutService`, `ShopService` (Quartermaster), `MerchantService` (island, voyage-only), `GrantService` (idempotent) | currencies, items, grants |
| 5 | **World** | `IslandBuilder`, `HarborBuilder`, `Ground` (cached height grid), `LightingService` | world construction, lighting tables |
| 6 | **Encounter** | `VoyageService` (phase loop), `WaveDirector`, `CreatureService`, `LampService`, `TowerService`, `DefenseService`, `LootService`, `UpgradeService` (bench + evolutions), `ForecastService`, `ResultsService` | everything inside a voyage |
| 7 | **Crew** | `CrewService` (roster, ready, departure rules), `RouteService` (fast path / harbor deck), `CoachService`, `CrewFeedService`, `LampShiftService`, `LeaderboardService` | who is sailing and the social layer |
| 8 | **LiveOps** | `ObjectiveService` (daily), `LogbookService` (collection), `CosmeticService`, `PurchaseService`, `CodeService`, `SeasonService` | retention and monetization |

Services within a domain may call each other; cross-domain reactions go through the bus; cross-domain calls go through the domain API in `API_CONTRACTS.md`.

## 5.2 Lifecycle
```lua
export type Service = { Name: string, Init: (self) -> (), Start: (self) -> () }
```
Boot order: Platform → Telemetry → Data → Definitions (`_Registry` validates; boot refuses on failure) → Economy → World → Encounter → Crew → LiveOps → **Network exposure last** (remotes created only after every `Start`). Bootstrap asserts the order and logs it.

## 5.3 Event bus
`EventLog` already counts events; it becomes the bus. Typed events, authoritative publisher only; Objectives, Logbook, Leaderboards, Analytics and Results **only consume**. Catalog in `docs/EVENTS.md`. Handlers run in `pcall`; a consumer error never breaks the publisher.

---

# 6. STATE OWNERSHIP

## 6.1 Profile (schema v2)
```lua
export type Profile = {
    SchemaVersion: number,                 -- 2
    CreatedAt: number, LastSeenAt: number,
    Pearls: number,
    Owned: {[string]: boolean},            -- itemId
    Counts: {[string]: number},            -- stackables (crates)
    Equipped: { Weapon: string, Armor: string, Beam: string, Lantern: string?, Coat: string?, Flag: string? },
    Stats: { Runs: number, Victories: number, BestNight: number, BestNightLong: number, NightsSurvived: number, PlayDays: number },
    Logbook: {[string]: boolean},          -- creatures, evolutions, forecasts, bosses discovered
    Objectives: { DayKey: string, Progress: {[string]: number}, Claimed: {[string]: boolean} },
    Unlocks: { LongVoyage: boolean, Specialties: {[string]: number} },
    Grants: {[string]: number},            -- claimId -> timestamp (dawn Pearls, boss drops, codes, invites); pruned at 30 days
    RedeemedCodes: {[string]: boolean},
    Settings: { Music: number, Sfx: number, Shake: boolean, Rain: boolean },
}
```
Migration v1→v2: copy `pearls/owned/counts/equippedWeapon/equippedArmor/equippedBeam/stats`, type-validate every field (a non-number `pearls` becomes the default and is logged), add the rest with defaults. Fixture in `ServerStorage/Tests/fixtures/profiles/v1.luau`.

## 6.2 Voyage state (discarded at Results)
`VoyageId`, phase, night, timers, fuel, beam mode, keeper, integrity, crew Shell pool, bench ranks, evolutions, cannons, forecast, bosses spawned, per-player voyage stats (kills, oil delivered, repairs, beam damage, clutch saves), merchant purchases. Replicated as `GameState` attributes as today.

## 6.3 Client presentation state
Never authoritative: HUD layout, interpolation buffers, coach markers, modal stack, settings cache.

---

# 7. COMBAT, BEAM, DEFENSE

## 7.1 Authority and feel
- **Attack** (harpoon): client sends `{Seq, T, Target}`; server validates finite vector, equipped Tool attribute, cooldown, range from the server root, and resolves hits; client plays the swing instantly and shows damage numbers on the server's `CombatResult`.
- **Beam**: client sends the aim angle at ≤ 20 Hz; server owns beam angle, mode, fuel and damage. The client renders the beam visual from the server angle with interpolation and predicts its own aim locally for responsiveness. The Keeper is pinned **server-side** (distance check from the console; snap back).
- **Cannons**: server-only auto-fire; `MaxTargets` on splash.
- Damage tags: `Harpoon`, `Beam`, `Cannon`, `Fire`. Creature resistances per tag in definitions.

## 7.2 Stat pipeline
```
Final = clamp((Base + ΣFlat) × (1 + ΣAdditivePct) × ΠMultipliers, Min, Max)
```
Sources: weapon/armor definitions (Base/Flat), bench upgrades (AdditivePct), evolutions and forecasts (Multiplier), merchant boosts (AdditivePct, voyage-only), specialties (AdditivePct, capped at +15% total). All stats in `docs/STATS.md` with caps. One module computes shop previews and in-voyage values.

---

# 8. CREATURE SIMULATION AND RENDERING

- **Server:** keep the table simulation (no Humanoids). Step at **20 Hz** (`SimulationStep`), not every Heartbeat. Ground height from a **precomputed grid** over the island (built once at boot from terrain raycasts); no per-creature raycasts at runtime. Threat/aggro model unchanged.
- **Replication:** positions packed with `buffer` over an `UnreliableRemoteEvent` at 10–15 Hz; **clients interpolate** pooled models. Anchored `PivotTo` replication is removed.
- **Render budget per creature (client):** one mesh, neon eye parts (no BillboardGui), health shown only while damaged and only for bosses/elites (one shared billboard), hit flash via a client tween; **no PointLight** except bosses. Rain capped per device; sounds pooled (no Part-per-sound).
- **Loot:** idle orbs do not move; the bob is a client-side animation on pickup range.
- **Caps:** `MAX_CREATURES = 45` includes bosses (a boss counts as 5); per-night plan computed by a pure `WaveDirector.nightPlan(night, crewSize, forecast, config)`.

---

# 9. VOYAGE LOOP (Encounter domain)

`VoyageService` runs: Waiting → Countdown → Prologue → (Day → Night)×N → Results → Rematch. Each voyage runs inside `pcall`; on an error the voyage ends with a logged cause and the crew returns to the deck. Phase timings from `Config`. `ResultsService` computes awards, Moment of the storm and "your part" from the bus, not from service internals. `pearlsFor(night, won, config)` and `nightPlan` are pure functions with tests.

**Dawn:** `GrantService.Grant(claimId = voyageId..":night"..n..":"..userId, {Pearls = 1})`; loot window 25 s; bench; forecasts applied; lighting tween.

---

# 10. ECONOMY DEFINITIONS

All catalogs are definitions with boot validation: `Items` (weapons, armor, ammo, cosmetics; prices; `shellValue`), `Upgrades` (+ evolutions), `Creatures` (+ `BIG_POOL`, resistances, loot tables summing to 1), `Forecasts`, `Merchant` (voyage-only stock, Shell prices, boost caps), `Objectives` (daily pool), `Cosmetics` (Robux products and Pearl items). Owner-approved prices from `progress.md §4` are the seed.

---

# 11. QUARTERMASTER, LOCKER, MERCHANT

- **Quartermaster** (Pearls, permanent): existing flow with idempotent `requestId`, distance and open-state checks; adds capped permanent boosts (owner request #6: +Shells, +speed, +damage in small steps, cap +15%) and more gear.
- **Locker**: equip/unequip with ownership and slot validation; `handled` map capped.
- **Merchant** (Shells, voyage-only, day phases): Trader's new job; stock from `Definitions/Merchant`; everything wiped at Results; purchases via `GrantService` with voyage-scoped claim IDs.

---

# 12. CREW, ROUTES, SOCIAL

- `CrewService`: roster, ready, departure rules (4/4 auto, SAIL NOW 1–3, below 4 cancels), forecast vote, rematch vote. Single writer of `Ready`.
- `RouteService`: fast path for 0-run players; harbor deck for returning players; no title screen in the critical path (title is a menu, not a gate).
- `CoachService` / `CrewFeedService` / `LampShiftService`: as built; feed lines become bus consumers.
- **Invite reward:** both players receive the "Shared Lantern" cosmetic after their first shared voyage (one-time, idempotent).
- **Leaderboards:** Best Night (Standard), Best Night (Long), Weekly Nights Survived — `OrderedDataStore`, refreshed every 60 s.

---

# 13. PROGRESSION AND RETURN

- **Pearls** (dawn-banked), Quartermaster gear and cosmetics, Long Voyage unlock, **Specialties** (Keeper, Oiler, Engineer, Harpooner: earned by role stats, small capped bonuses).
- **Logbook:** creatures, bosses, evolutions, forecasts discovered; category rewards (Pearls, a cosmetic).
- **Daily objective:** one per day from a pool ("Deliver 10 oil", "Survive night 4", "Build 2 cannons"), small Pearl reward, **no streak, no penalty**.
- Nothing is taken from a player who doesn't log in.

---

# 14. FORECASTS, EVOLUTIONS, BOSSES

As built (3 forecasts, 2 evolutions, Barnacle Brute, Shipwreck Hermit), all as definitions. Roadmap adds: bosses by crew size, boss every night from 8 on Long Voyage, and new monsters one at a time (Spitter Eel, Tide Witch, Puffer Mine, Ghost Lantern, Coral Shaman) each with its own telegraph, sound and loot table (owner request #5). Bosses: telegraph ≥ 0.6 s, 2 phases, a readable counter (focused beam, cannon, harpoon pull).

---

# 15. WEAPONS

Harpoons as built; `Orbiting Blades` (no aiming; good on phones) first as a merchant item, then permanent variants. Weapon definitions carry archetype (`Thrown`, `Orbit`, `Chain`, `Net`, `Bomb`), damage per level, cooldown, range, tags.

---

# 16. CAMPAIGN / MODES

Standard Voyage · Long Voyage · (later) **Shipwreck Rescue** event voyage (owner's Prototype B idea) · Endless Storm (leaderboard) · seasonal variants. All run on `VoyageService` with a `VoyageDefinition` (nights, boss schedule, growth, forecast pool, reward table).

---

# 17. LIVE OPS

Daily objective pool, weekly leaderboard reset, seasonal cosmetic sets, codes (once per profile, expiry), events behind feature flags with server-time windows. Weekly update on Fridays; biweekly floor.

---

# 18. NETWORK CONTRACTS

Every remote: a row in `docs/API_CONTRACTS.md` (payload, guard, rate), a type guard, a per-player token bucket, creation in the last boot phase. Idempotent `requestId` with a **capped** replay map on every economic remote (Quartermaster, Locker, Bench, Merchant, Trader). Movement sanity for the Keeper. Admin commands on a separate whitelisted channel. Current gaps closed in Stage R1: `BuyUpgrade` (Ready + phase + bench distance + replay map), `GearAction` throttle, `SetReady(false)` throttle, `ReportDevice` once, finite-vector checks on `Attack`.

---

# 19. PERSISTENCE

- **ProfileStore** (`LighthouseKeepers_PlayerData_v1`, same store name, same keys): session lock, auto-save, `BindToClose`, retries, budget handling. The existing values load unchanged; `MigrationService` lifts v1→v2 on first load.
- **Cutover:** publish with ProfileStore → "Shut down all servers" (not Migrate) so no old writer survives → confirm on the owner's own profile → done. No code path ever runs the old save path again.
- `GrantService.Grant(claimId, rewards)` is the only writer of Pearls/items; duplicates return the previous result.
- `AdminDataService`: inspect, grant, rollback to a 7-day snapshot store. Needed before any public test.
- Test DataStores: tests use ProfileStore's mock (`ProfileStore.Mock`) in Studio; never the production store.

---

# 20. MONETIZATION (owner policy, Oct 11, unchanged)

Robux buys: beam colours, lamp housings, keeper coats, lantern skins, ship flags, emotes; a supporter pack; convenience only if the same item is earnable. Never: combat stats, weapon/armor power, upgrade ranks, revives, random paid crates. Fairness test (non-payers reach every goal; no PvP; parent-over-the-shoulder; odds n/a) passes by construction. Nothing is enabled until the owner approves Stage L1.

---

# 21. UI ARCHITECTURE

- **UiKit split** into `Tokens`, `Primitives` (Screen, Panel, Inset, Section, Scroll, Label, Button, IconButton, Tabs), `Controls` (Slider, Toggle, SettingRow, KeyHint), `Gauges` (Health, Fuel, Tower, Resource — with a `variant = "glass" | "wood" | "slim"` option), `Dialogs` (Dialog, PurchaseDialog, Toast, Pickup). The dead v1 API and `Gear.client` are deleted. The "glass" restyle pass is folded into the constructors; `glassTree`/`restyle` are deleted.
- `UiSkin` stays as the wood skin for menus; HUD uses the glass variant natively.
- One `InputController` and one `Breakpoint` source; the four duplicated `inputMode()` functions are removed.
- Every screen verified at 667×375 and on a controller before a phase exits.

---

# 22. TELEMETRY

Bus → `AnalyticsService` funnel: `Joined`, `OnCrew`, `Landed`, `FirstAction`, `FirstBeamHit`, `Night1Survived`, `DawnPearl`, `VoyageEnded{cause,night}`, `SailAgain`, `Left{phase}`. Economy events for Pearl sources/sinks. Error reports via `ErrorReportService`. The run summary print stays (`EVENT_LOG_ENABLED`) for Studio.

---

# 23. PERFORMANCE BUDGETS (measured)

| Metric | Target | Baseline (Oct 12, solo) |
|---|---|---|
| Server game work per frame | ≤ 2 ms avg at 4 players, 45 creatures, 2 bosses | 0.11 ms (solo, swarm) |
| Server send per player | ≤ 30 KB/s at 4 players, 45 creatures | ~50 KB/s (per-frame PivotTo) |
| Client FPS PC / low-end Android | 60 / ≥ 30 during a night-7 swarm | not measured on device |
| Replicated instances per creature | ≤ 3 (model + eyes + optional bar) | 7 (model, 2 billboards ×2 frames, light) |
| Join → control (new account) | ≤ 5 s | 1.1 s |
| First beam hit (new account, unassisted) | ≤ 45 s median | 50.3 s (scripted) |
| Save failure rate | 0 unresolved | unknown (no retry) |
| Memory growth (2-hour, 3 voyages) | < 50 MB/h | not measured |

---

# 24. TESTING

- **TestRunner** in `ServerStorage/Tests` (`describe/it/expect`, async, mocks).
- **Unit:** `nightPlan`, `pearlsFor`, `StatPipeline`, Shop/Merchant/Locker validation, `GrantService` idempotency, migration v1→v2 on fixtures, token buckets, codec round-trips, objective progress from events.
- **Integration (mock ProfileStore):** dawn grant once; quick rejoin keeps Pearls; `BindToClose` saves; results awards from bus events.
- **Play tests per substage** with console read and screenshots; 4-client Studio test for crew flows.
- **Security:** spam at 50× rate, invalid IDs, non-finite vectors, non-crew Shell spend, admin probing.
- **Performance:** 45-creature night probe, 4-client soak, real-phone FPS.

---

# 25. OPERATING CONTRACT

Claude Code implements; the owner decides product and publishes. `CLAUDE.md` is the short form. Checkpoint protocol (8 steps) at every substage; independent review only at stage gates (R1 cutover, S3 GO/NO-GO, L1). The owner's hard rules in §1.3 are never relaxed by any document or session.

---

# 26. MIGRATION FROM THE CURRENT CODE

The game is not rewritten. Content, art, lighting, HUD and gameplay numbers are kept. The code is **re-founded in place**, one domain at a time, each step shippable:

1. **R1 Safety & structure:** ProfileStore + schema v2 + GrantService + AdminData; remote contracts and the validation gaps; `VoyageService` pcall; TestRunner with the first pure functions extracted (`nightPlan`, `pearlsFor`); EventLog → bus; funnel to AnalyticsService. Multi-ship code removed from `Main` (branch frozen). Publish (owner).
2. **S2 First session & length:** 7-night default, Long Voyage unlock, Night-1 safety, dawn banking, title/icon, controller aim.
3. **S3 Public test** (GO/NO-GO).
4. **S4 Performance:** 20 Hz step, grid ground, interpolation, render budget, sound pool.
5. **S5 Domain split:** `Main` dissolved into domains with lifecycle; UiKit split; dead code deleted.
6. **S6 Content** (owner's six requests in order), **S7 Return systems**, **B1 Closed beta**, **L1 Relaunch**, **LO live ops**.

Detailed substages and checkpoints: `docs/ROADMAP.md`.

---

# 27. GROWTH ARCHITECTURE

| Official signal | Driven by | Measured |
|---|---|---|
| Playthrough | Real title; icon showing the beam vs the sea monster; 16:9 thumbnails (clutch refuel, Brute burn, 4-crew deck) | S3 icon A/B via diagnostic ads |
| First-play bounce | Fast path; first beam hit ≤ 45 s; Night-1 safety | funnel |
| Play days | Dawn-banked Pearls, daily objective (no streak), Logbook, weekly board, Friday updates | Analytics |
| Playtime (capped 60 min) | 15-minute voyages; one-tap Sail again | sessions |
| Co-play days | crew card, vote, lamp shift, invite reward, private servers | party size |
| Spend days | cosmetics worth showing (beam, lantern, coat, flag) | receipts |

Title: **"Lighthouse Keepers 🌊 Keep the Light"** (A) vs **"Lighthouse Keepers: Storm Survival"** (B) vs **"13 Nights at the Lighthouse 🔦"** (C — the number-as-goal pattern of *99 Nights in the Forest* and *Survive The Night*, the category's current winners). The emoji/bracket tag rotates with updates.

**Category evidence (2026-10-16):** co-op night survival is the largest co-op fantasy on Roblox (*99 Nights in the Forest*: ~290K CCU, 25.8B visits since March 2025); new entrants in the lineage are being discovered (*Survive The Night*: ~5.6K CCU on 9.3M visits). No lighthouse-defense incumbent found. Winners share: a number as the goal, meaningful day phases (gather/build), roles, pets/cosmetics for return, seasonal events, a dread hook. S3 therefore tests **fixed 7-night voyage vs Endless Storm ladder (Best Night as score)** as the main mode, and lengthens day phases if the ladder wins.

---

# 28. INITIAL ASSIGNMENT — STAGE R1

See `docs/ROADMAP.md` §3 and `docs/CURRENT_PHASE.md` (R1.1). Nothing is published by Claude; every production change is published by the owner after the checkpoint.

**Current approved stage: R1 — Re-foundation.**

**End of Master Architecture Document — v2.0**
