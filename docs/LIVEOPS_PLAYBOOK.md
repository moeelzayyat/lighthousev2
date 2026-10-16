# LIVE-OPS PLAYBOOK

Applies from the R1.9 cutover onward (the game is already live).

## Cadence
| Cadence | Content | Checkpoint |
|---|---|---|
| Daily (first 30 days after relaunch) | Error triage, hotfixes | Top error < 24 h |
| Weekly (Friday) | One of: monster, weapon, forecast, merchant item, QoL, balance | Shipped; changelog; restore point; mirror; **owner publishes** |
| Monthly | Boss, Shipwreck Rescue event voyage, cosmetic set | Signal review |
| Seasonal (8–10 weeks) | Themed storm season, cosmetics, leaderboard reset | L1 checklist |
| Quarterly | Economy, data, performance re-baseline; roadmap revision | Docs |

Floor: biweekly, announced in-game and in the community. Never skip silently.

## Release procedure (every update)
1. Content in `Definitions/*` / `Config` wherever possible.
2. TestRunner green; Script Analysis zero warnings.
3. Play test PC + phone emulator; console zero errors; **API off** confirmed.
4. Migration fixture if the schema changed; migration tests green.
5. `ServerStorage.Backups.<ID>_before_<date>`; restore point `release-YYYY-MM-DD`; mirror export + commit.
6. Hand to the owner: "ready to publish" with the checklist. **Owner publishes**; for schema or persistence changes the owner uses **Shut down all servers**.
7. Watch errors and the funnel for 30 minutes after publish.
8. Changelog posted.
9. Blocking error → owner restores the restore point and republishes (target < 15 min); fix forward.

## Signal review (weekly)
| Signal | Action threshold |
|---|---|
| Playthrough | icon/thumbnail test if down 2 weeks |
| First-play bounce (<60 s, 61–180 s) | FTUE change if up 2 weeks |
| Night-1 survival (new accounts) | < 50% → safety/coach pass |
| Sail again / rematch | < 60% → results/length review |
| D1 / D2–7 / D8–28 play days | content/return review |
| Co-play days, party size | squad incentive review |
| Non-Keeper "Moment of the storm" share | < 30% → role hero-moment pass |
| Late-voyage Shell balance | > 400 at night 6 → merchant/sink tuning |
| Pearl inflow/outflow | inflow > outflow by 20% for 2 weeks → price/sink review |
| Top 5 errors | next daily slot |

## Support
Lost-item reports → `AdminDataService.Inspect` → snapshot rollback or grant → logged. Never `RemoveAsync`. Creator codes via `CodeService`. Chat uses Roblox filtering; no custom unfiltered text input.

## Rollback
Code: restore point + owner republish. Data: `AdminDataService.Rollback(userId, snapshotDate)` (7-day retention). Every rollback is a decision-log entry with cause and prevention.
