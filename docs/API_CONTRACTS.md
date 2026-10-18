# API CONTRACTS — remotes and domain APIs

## Rules
- A remote exists only with a row here, a type guard and a token-bucket rate. From S5.1 remotes are created in the last boot phase under `ReplicatedStorage/Remotes`.
- `R` RemoteEvent · `U` UnreliableRemoteEvent. No RemoteFunctions (keep the existing request/result pattern).
- Rate = sustained/s · burst. Exceeding drops the request and increments `Telemetry.RateLimited`.
- Economic remotes carry `requestId` (≤ 40 chars) with a **capped** replay map (40 entries), checked before the rate limit (as `ShopService` does today).
- The server never trusts: damage, creature positions, amounts, item IDs it did not offer, rewards, or non-finite vectors.

## Client → Server (the 17 client→server remotes of the current 32; guards implemented in R1.4 via `NetGuard`)
Every handler calls `NetGuard.allow(player, remote)` (per-player token bucket at the Rate below; counters `Allowed_<Remote>` / `Limited_<Remote>` on the `NetGuard` ModuleScript). Economic remotes check the replay map first, then the rate.
B1.3: every handler is connected with `NetGuard.connect(remote, handler)`; no other `OnServerEvent` exists (checked by `SecuritySpec`). In Studio only, each handler is also exposed as `ServerStorage.NetHooks.<Remote>` (a BindableFunction) plus `NetHooks._Profile` (a read-only JSON copy of a profile) for the security suite; live servers never create them, and ServerStorage never replicates to clients.
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
| `ChooseVoyage` (S2.1) | `defId` | string ≤ 20, a known voyage definition that is not test-only (S3.1b: Endless Storm is refused); Ready; phase Waiting/Intermission; the sender holds the definition's unlock (`Unlock_<key>`); GameState re-checks at departure that a sailing member holds it | 2 / 3 |
| `AdminRequest` (R1.8) | `requestId, action, targetUserId, arg?` | requestId ≤ 40; action string ≤ 20; finite targetUserId; arg number or string ≤ 20; **owner UserId only** (`AdminDataService.OWNER_IDS`), anyone else refused and logged `AdminRejected`; actions inspect / grant (1–1000 Pearls, target online) / rollback (YYYY-MM-DD snapshot) | 1 / 3 |
| `MerchantRequest` (S6.2 ✅) | `requestId, action, itemId, qty` | requestId ≤ 40; action `"buy"`; itemId a string ≤ 40 in `Merchant.ORDER`; qty exactly 1; capped replay map (checked before the rate); Ready; phase Day; distance to the Trader ≤ 18; the item's per-voyage limit; the effect would do something (hurt for Heal, lamp not full for Oil, no shield up for Shield); crew Shells | 5 / 8 |
| `ObjectiveClaim` (S7.2: not built, D-026) | — | the reward is paid by the server the moment the objective is done (GrantService claim `objective:<day>:<id>`), so no client request exists to guard | — |
| `CodeRedeem` (L1.4, implemented) | `text: string` (≤ 64 raw; letters and digits ≤ 32 after spaces are removed) | type and length, then the bucket; `CodeService.redeem`: known code, not expired, profile loaded, not in `RedeemedCodes`; reward through `GrantService` (claim `code:<CODE>`), then `RedeemedCodes[code] = true` (never pruned); answers with `CodeResult` | 0.1 / 1 (one per 10 s) |
| `SniperAction` (D-044, implemented) | `"fire", point: Vector3` or `"leave"` | the bucket first; `fire`: finite vector, the sender is the one up the sniper tower (server state), alive, not the Keeper, the rifle's cooldown (1 s, server clock); the server traces the shot from the rifle's muzzle towards the point against the creature table (`CreatureService.damageRay`, first creature along the line within its body + 2.5 studs, range 220, Ghost Lanterns immune); `leave`: only the climber | 3 / 5 |
| `Settings` (new, S5) | `key, value` | whitelist of keys | 5 / 10 |

Deferred from this table: `Attack.Seq` + `CombatResult` (architecture §7.1 feel work) — not in the R1.4 roadmap row; lands with client prediction in S4.

## All 34 current remotes
Client → server (18): `AdminRequest`, `Attack`, `ChooseVoyage`, `BeamControl`, `LampAction`, `LampShift` (both directions), `BuyUpgrade`, `ShopRequest`, `TraderRequest`, `MerchantRequest` (S6.2), `LoadoutRequest`, `GearAction`, `SetReady`, `VoteRematch`, `EnterLobby`, `ReportDevice`, `CoachEvent` (both directions), `ForecastVote`.
Server → client only (17): `AdminResult`, `Notify`, `LootCollected`, `OpenUpgrades`, `PlaySound`, `RunResults`, `GearData`, `ShopOpen`, `ShopResult`, `LoadoutResult`, `Travel`, `UpgradeResult`, `TraderOpen`, `TraderResult`, `MerchantResult` (S6.2), `CrewFeed`, `CodeResult` (L1.4). They have no server handler, so client input on them is ignored.

## Server → Client
| Remote | Payload | Notes |
|---|---|---|
| `Notify`, `PlaySound`, `LootCollected`, `CrewFeed`, `CoachEvent` | as today; `LootCollected` kinds: loot item ids, `Shells`, `Pearls`, and `PearlBanked` (S2.2, amount banked at dawn); `CrewFeed` kinds: `refuel`, `clutch`, `reserve` (S2.3, the Night-1 reserve refilled the lamp) | `PlaySound` client handler validates types (keep) |
| `CodeResult` (L1.4) | `ok, message` | one answer per accepted `CodeRedeem` |
| `UpgradeResult`, `ShopResult`, `LoadoutResult`, `TraderResult`, `MerchantResult` | `{requestId, ok, reason?, state?}` (`MerchantResult`: `requestId, ok, message, {itemId, count, shells}`) | replayed for duplicate requestIds |
| `AdminResult` (R1.8) | `requestId, ok, result` (table for inspect, message otherwise) | owner only in practice |
| `RunResults` | results payload (S2.2 adds `banked`, S2.5 `crewSize`) | |
| `GearData` | profile view (MP.4: also `logbook`, the found entries "Category:Id" -> true, read-only) | **never** includes `Grants`, `RedeemedCodes` |
| `CreatureSnapshot` (S4.2, `UnreliableRemoteEvent`) | `buffer`: header `[serverTime f64][n u16]`, then per creature `[id u16][kind u8][x f32][y f32][z f32][yaw u8][state u8][hp u8]` (18 bytes; `kind` added so a client can draw a creature from its first packet); at most 50 creatures per packet (910 bytes) | 12 Hz, `U`, to every client; the client checks `typeof` = buffer and the length (`CreatureSnapshot.decode`). Created by the Platform domain with the other remotes (S5.1) |
| `CombatResult` (new, S4) | `{Seq, Hits}` | `U`, batched |
| ~~`DawnPearl` (new, S2.2)~~ | — | S2.2 used the existing `LootCollected` instead: `LootCollected("PearlBanked", amount)`; `RunResults` carries `banked[playerName]` |
| `LeaderboardUpdate` (new, S7.3) | `{board, rows}` | 60 s |
| `GameState` attributes | Phase, Night, TimeLeft, Reason, Cause, Fuel, MaxFuel, DarkSeconds, BeamMode, KeeperUserId, Integrity, MaxIntegrity, Shells, BigWarning, Forecast*, Upgrade_*, Evo_*; VoyageDef, TotalNights (S2.1); ReserveUsed (S2.3) | unchanged otherwise |

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

### Roblox callbacks (L1.3)
| Callback | Owner | Guard |
|---|---|---|
| `MarketplaceService.ProcessReceipt` | Economy domain → `PurchaseService.process` (the only assignment in the game; `CosmeticsSpec` checks) | Robux switch on; product id listed in `Definitions/Cosmetics` (cosmetics only, by `_Registry`); buyer in the server with a loaded save, else `NotProcessedYet`; grant through GrantService with claim `receipt:<PurchaseId>` (a repeated receipt answers `PurchaseGranted` without a second grant) |
| `MarketplaceService:PromptProductPurchase` (client) | `Shop.client` Robux button | only for an item `Cosmetics.productFor` returns (switch on, product id set, not owned) |
