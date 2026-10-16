# API CONTRACTS — remotes and domain APIs

## Rules
- A remote exists only with a row here, a type guard and a token-bucket rate. From S5.1 remotes are created in the last boot phase under `ReplicatedStorage/Remotes`.
- `R` RemoteEvent · `U` UnreliableRemoteEvent. No RemoteFunctions (keep the existing request/result pattern).
- Rate = sustained/s · burst. Exceeding drops the request and increments `Telemetry.RateLimited`.
- Economic remotes carry `requestId` (≤ 40 chars) with a **capped** replay map (40 entries), checked before the rate limit (as `ShopService` does today).
- The server never trusts: damage, creature positions, amounts, item IDs it did not offer, rewards, or non-finite vectors.

## Client → Server (the 17 client→server remotes of the current 32; guards implemented in R1.4 via `NetGuard`)
Every handler calls `NetGuard.allow(player, remote)` (per-player token bucket at the Rate below; counters `Allowed_<Remote>` / `Limited_<Remote>` on the `NetGuard` ModuleScript). Economic remotes check the replay map first, then the rate.
| Remote | Payload | Guard (R1.4, implemented) | Rate |
|---|---|---|---|
| `Attack` | `target: Vector3` | finite vector (NaN, ±inf rejected), not Keeper, alive, equipped Tool attr, cooldown, range clamp | 6 / 10 |
| `BeamControl` | `angle: number` | keeper only, finite number | 20 / 30 |
| `LampAction` | `"leave" \| "toggleMode"` | keeper only | 4 / 6 |
| `LampShift` | `id, accepted: boolean` | pending id, phase Day, role | 4 / 6 |
| `BuyUpgrade` | `id ≤ 40, requestId?` | requestId ≤ 40; capped replay map (40) before the rate; 0.3 s; **Ready crew only; phase Prologue/Day/Night; ≤ 18 studs from the bench**; refusals logged `UpgradeRefused` | 3 / 5 |
| `ShopRequest` | `requestId, action, itemId, qty` | replay map (40, now `NetGuard.replayMap`), 0.2 s, open, distance ≤ 18, catalog, qty; `close` also rate-limited | 5 / 8 |
| `TraderRequest` | `requestId, "sellAll"` | last-request replay, 0.3 s, Ready, range | 3 / 5 |
| `LoadoutRequest` | `requestId, action, itemId` | replay map **capped at 40** (was unbounded), 0.2 s, ownership, slot | 5 / 8 |
| `GearAction` | `"sync"` | action string | 2 / 4 |
| `SetReady` | `ready: boolean` | only `false` acts (true ignored: the crew is joined at the wheel); **one handler (was two)**; `PlayerToMenu` logged once per session | 2 / 3 |
| `VoteRematch` | – | Ready | 2 / 3 |
| `EnterLobby` | – | – | 1 / 2 |
| `ReportDevice` | `device` | whitelist; **once per session** | 1 / 1 |
| `CoachEvent` | `kind, id` | enums, 60/session | 4 / 8 |
| `ForecastVote` | `choice` | Ready, phase Waiting/Intermission, one of the two offered | 3 / 5 |
| `ChooseVoyage` (S2.1) | `defId` | string ≤ 20, a known voyage definition; Ready; phase Waiting/Intermission; the sender holds the definition's unlock (`Unlock_<key>`); GameState re-checks at departure that a sailing member holds it | 2 / 3 |
| `AdminRequest` (R1.8) | `requestId, action, targetUserId, arg?` | requestId ≤ 40; action string ≤ 20; finite targetUserId; arg number or string ≤ 20; **owner UserId only** (`AdminDataService.OWNER_IDS`), anyone else refused and logged `AdminRejected`; actions inspect / grant (1–1000 Pearls, target online) / rollback (YYYY-MM-DD snapshot) | 1 / 3 |
| `MerchantRequest` (new, S6.2) | `requestId, action, itemId, qty` | replay, Day phase, Ready, distance ≤ 18, stock, Shells | 5 / 8 |
| `ObjectiveClaim` (new, S7.2) | `objectiveId, claimId` | complete, unclaimed, GrantService | 2 / 3 |
| `CodeRedeem` (new, L1.4) | `code ≤ 32` | once per profile, expiry | 1 per 10 s |
| `Settings` (new, S5) | `key, value` | whitelist of keys | 5 / 10 |

Deferred from this table: `Attack.Seq` + `CombatResult` (architecture §7.1 feel work) — not in the R1.4 roadmap row; lands with client prediction in S4.

## All 32 current remotes
Client → server (17): `AdminRequest`, `Attack`, `ChooseVoyage`, `BeamControl`, `LampAction`, `LampShift` (both directions), `BuyUpgrade`, `ShopRequest`, `TraderRequest`, `LoadoutRequest`, `GearAction`, `SetReady`, `VoteRematch`, `EnterLobby`, `ReportDevice`, `CoachEvent` (both directions), `ForecastVote`.
Server → client only (15): `AdminResult`, `Notify`, `LootCollected`, `OpenUpgrades`, `PlaySound`, `RunResults`, `GearData`, `ShopOpen`, `ShopResult`, `LoadoutResult`, `Travel`, `UpgradeResult`, `TraderOpen`, `TraderResult`, `CrewFeed`. They have no server handler, so client input on them is ignored.

## Server → Client
| Remote | Payload | Notes |
|---|---|---|
| `Notify`, `PlaySound`, `LootCollected`, `CrewFeed`, `CoachEvent` | as today; `LootCollected` kinds: loot item ids, `Shells`, `Pearls`, and `PearlBanked` (S2.2, amount banked at dawn) | `PlaySound` client handler validates types (keep) |
| `UpgradeResult`, `ShopResult`, `LoadoutResult`, `TraderResult`, `MerchantResult` | `{requestId, ok, reason?, state?}` | replayed for duplicate requestIds |
| `AdminResult` (R1.8) | `requestId, ok, result` (table for inspect, message otherwise) | owner only in practice |
| `RunResults` | results payload | |
| `GearData` | profile view | **never** includes `Grants`, `RedeemedCodes` |
| `CreatureSnapshot` (new, S4.2) | `buffer`: `[n][id u16, x f32, y f32, z f32, yaw u8, state u8, hpPct u8]` | 12 Hz, `U` |
| `CombatResult` (new, S4) | `{Seq, Hits}` | `U`, batched |
| ~~`DawnPearl` (new, S2.2)~~ | — | S2.2 used the existing `LootCollected` instead: `LootCollected("PearlBanked", amount)`; `RunResults` carries `banked[playerName]` |
| `LeaderboardUpdate` (new, S7.3) | `{board, rows}` | 60 s |
| `GameState` attributes | Phase, Night, TimeLeft, Reason, Cause, Fuel, MaxFuel, DarkSeconds, BeamMode, KeeperUserId, Integrity, MaxIntegrity, Shells, BigWarning, Forecast*, Upgrade_*, Evo_* | unchanged |

## Domain APIs (server-internal, from S5.1)
| Domain | Public surface |
|---|---|
| Platform | `Flags.Get`, `Config.Get`, `Time.Now` |
| Telemetry | `Bus.Publish/Subscribe`, `Analytics.Funnel`, `Analytics.Economy`, `Errors.Report` |
| Data | `Profiles.Get(player) → Profile?`, `Profiles.OnLoaded`, `Admin.Inspect/Grant/Rollback` |
| Economy | `Grant.Grant(player, claimId, rewards)`, `Wallet.Pearls`, `ShellPool.*`, `Inventory.*`, `Loadout.*`, `Shop.Process`, `Merchant.Process` |
| World | `Island.Build`, `Harbor.Build`, `Ground.HeightAt`, `Lighting.Apply(phase)` |
| Encounter | `Voyage.Start(def)/End`, `Wave.NightPlan`, `Creatures.*`, `Lamp.*`, `Tower.*`, `Defense.*`, `Loot.*`, `Upgrades.*`, `Forecast.*`, `Results.Compute` |
| Crew | `Crew.*` (sole writer of `Ready`), `Route.Choose`, `Coach.*`, `Feed.Say`, `LampShift.*`, `Leaderboard.Submit/Read` |
| LiveOps | `Objectives.*`, `Logbook.Discover`, `Cosmetics.*`, `Purchases.Process`, `Codes.Redeem`, `Season.Current` |
