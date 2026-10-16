# TEST PLAN

## Where tests run
| Kind | Runner | When |
|---|---|---|
| Unit / integration | `ServerStorage/Tests/TestRunner` via `execute_luau` | before every checkpoint |
| Persistence | TestRunner against `ProfileStore.Mock` (never the real store) | R1.3 onward, every schema change |
| Play test | `start_stop_play` + `get_console_output` (+ `screen_capture`), **API off in the production window** | every substage with gameplay/UI |
| Multi-client | Studio Test → Clients: 4 | crew flows, bosses by crew, soak |
| Security | TestRunner `security/` + scripted spam via `execute_luau` | R1.4, S5.2, B1.3 |
| Performance | probe scripts in `ServerStorage/Tests/perf/`; real phone | S4, B1.4 |
| Outside players | Prototype A/B sessions per `docs/legacy/PLAYTEST_KIT.md` | S3, S6.7, B1.5 |

## TestRunner contract
```lua
local T = require(game.ServerStorage.Tests.TestRunner)
T.describe("nightPlan", function()
  T.it("night 1, crew 4, no forecast", function()
    T.expect(Wave.nightPlan(1, 4, nil, Config)).toEqual({ crabs = 14, skitters = 42, boss = nil })
  end)
end)
T.run()
```
`describe/it/beforeEach/afterEach`, async `it`, `toBe/toEqual/toBeCloseTo/toThrow/toBeNil/toBeTruthy/toBeGreaterThan`, `T.mock.service(name, impl)`, `T.clock()` for advanced-time tests.

## Required coverage by substage
### R1
- `nightPlan`: nights 1,4,7,10,13 × crew 1–4 × forecasts (none, Fog, Spring tide, Leaky) = reference table in `STATS.md`; `MAX_CREATURES` respected.
- `pearlsFor`: win 7 = 12, win 13 = 18, loss at night n = n−1.
- Migration v1→v2 on fixtures: full v1 profile; missing fields; `pearls = "25"` (string) → default + logged; unknown fields preserved.
- `GrantService`: same claimId twice → one grant; concurrent claims serialised.
- ProfileStore mock: load, change, release, reload = same; `BindToClose` saves; quick rejoin keeps Pearls.
- Remote guards: every remote with invalid types / ±inf / out-of-range rejected; token buckets allow N, reject N+1, refill; replay maps return the previous result and are capped at 40.
- `BuyUpgrade`: non-Ready, wrong phase, far from bench → rejected.
- Voyage isolation: injected error → voyage ends with cause `Error`, next voyage starts.
- Bus: subscribe/publish/receive; throwing handler isolated; wrong payload rejected in strict mode.

### S2
- VoyageDefinition: Standard and Long schedules; Long offered only with the unlock; win sets the unlock.
- Dawn grant claimId `voyageId:night:userId` idempotent; leaving at night 5 → 4 Pearls on reload (mock).
- Night-1 safety: 0-run → one refill; 1-run → none; second blackout → no refill.
- Prologue timing: first crab in arc by 35 s (simulated clock).

### S4
- Ground grid vs raycast samples within 0.2 studs at 200 random points.
- Snapshot codec round-trip (id, position, yaw, state, hp).
- Interpolation: no position jump > speed × dt at 12 Hz input.
- Perf probes record: send/player, instances/creature, FPS (PC + phone), memory over 3 voyages.

### S5
- Lifecycle order assertion; remotes absent before the last phase.
- Registry: broken definition fails boot; loot tables sum to 1; duplicate IDs rejected.
- StatPipeline: one test per `STATS.md` row; caps; preview == in-voyage.
- UI: screenshot parity at PC / 667×375 / 932×430 before vs after the split.

### S6–S7
- Bosses by crew: count = crew, bearings distinct, budget hold.
- Merchant: replay, Day-only, Shell deduction, wipe at Results.
- Boost caps: Quartermaster ≤ +15% total; merchant ≤ +25%, voyage-only.
- Logbook/objective: once from events; advanced clock → missing a day changes nothing; leaderboard reset.

### B1 / L1
- Security suite: 50× spam per remote; non-crew Shell spend; admin probe from a non-whitelisted user.
- Receipts idempotent; codes once; migration chain; rollback drill; 10,000-voyage economy simulation.

## Play-test scripts
Each substage's "Verify" column names the steps. Record device(s), console error count, screenshots, numbers. **Never describe an emulator test as a real-phone test.** Note when a Studio run changed the owner's real save.
