# API CONTRACTS — remotes and domain APIs

## Rules
- A remote exists only with a row here, a type guard and a token-bucket rate. From S5.1 remotes are created in the last boot phase under `ReplicatedStorage/Remotes`.
- `R` RemoteEvent · `U` UnreliableRemoteEvent. No RemoteFunctions (keep the existing request/result pattern).
- Rate = sustained/s · burst. Exceeding drops the request and increments `Telemetry.RateLimited`.
- Economic remotes carry `requestId` (≤ 40 chars) with a **capped** replay map (40 entries), checked before the rate limit (as `ShopService` does today).
- The server never trusts: damage, creature positions, amounts, item IDs it did not offer, rewards, or non-finite vectors.

## Client → Server (current 29 remotes, with the v2.0 guard column)
| Remote | Payload | Guard today | Guard required (R1.4) | Rate |
|---|---|---|---|---|
| `Attack` | `target: Vector3` | type, NaN, not Keeper, alive, equipped Tool attr, cooldown, range | + finite (±inf) check; + `Seq` for CombatResult | 6 / 10 |
| `BeamControl` | `angle: number` | keeper, finite | + 20 Hz cap | 20 / 30 |
| `LampAction` | `"leave" \| "toggleMode"` | keeper | OK | 4 / 6 |
| `LampShift` | `id, accepted: boolean` | pending id, phase Day, role | OK | 4 / 6 |
| `BuyUpgrade` | `id, requestId` | id string, 0.3 s | **+ Ready, run phase, bench distance ≤ 18, capped replay map** | 3 / 5 |
| `ShopRequest` | `requestId, action, itemId, qty` | full (replay, 0.2 s, open, distance ≤ 18, catalog, qty) | OK (reference implementation) | 5 / 8 |
| `TraderRequest` | `requestId, "sellAll"` | replay, 0.3 s, Ready, range | OK | 3 / 5 |
| `LoadoutRequest` | `requestId, action, itemId` | replay (unbounded), 0.2 s, ownership, slot | **cap replay map at 40** | 5 / 8 |
| `GearAction` | `"sync"` | action string | **0.25 s throttle** | 2 / 4 |
| `SetReady` | `ready: boolean` | boolean; true ignored | **0.5 s throttle; log once per session** | 2 / 3 |
| `VoteRematch` | – | Ready | OK | 2 / 3 |
| `EnterLobby` | – | – | OK | 1 / 2 |
| `ReportDevice` | `device` | whitelist | **once per session** | 1 / 1 |
| `CoachEvent` | `kind, id` | enums, 60/session | OK | 4 / 8 |
| `ForecastVote` | `choice: "A"\|"B"` | Ready, phase, enum | OK | 3 / 5 |
| `Travel` | (server→client fade) | – | – | – |
| `MerchantRequest` (new, S6.2) | `requestId, action, itemId, qty` | — | replay, Day phase, Ready, distance ≤ 18, stock, Shells | 5 / 8 |
| `ObjectiveClaim` (new, S7.2) | `objectiveId, claimId` | — | complete, unclaimed, GrantService | 2 / 3 |
| `CodeRedeem` (new, L1.4) | `code ≤ 32` | — | once per profile, expiry | 1 per 10 s |
| `Settings` (new, S5) | `key, value` | — | whitelist of keys | 5 / 10 |

## Server → Client
| Remote | Payload | Notes |
|---|---|---|
| `Notify`, `PlaySound`, `LootCollected`, `CrewFeed`, `CoachEvent` | as today | `PlaySound` client handler validates types (keep) |
| `UpgradeResult`, `ShopResult`, `LoadoutResult`, `TraderResult`, `MerchantResult` | `{requestId, ok, reason?, state?}` | replayed for duplicate requestIds |
| `RunResults` | results payload | |
| `GearData` | profile view | **never** includes `Grants`, `RedeemedCodes` |
| `CreatureSnapshot` (new, S4.2) | `buffer`: `[n][id u16, x f32, y f32, z f32, yaw u8, state u8, hpPct u8]` | 12 Hz, `U` |
| `CombatResult` (new, R1.4) | `{Seq, Hits}` | `U`, batched |
| `DawnPearl` (new, S2.2) | `{night, total}` | |
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
