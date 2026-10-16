# STUDIO MANIFEST

Script fingerprints of the production Studio tree (PlaceId 132065051336560), used to detect drift between Studio (source of truth) and the `src/` mirror. Hash: FNV-1a 32-bit over the source with CRLF normalised to LF, computed in Studio via `execute_luau` and over `src/**/*.luau` locally with the same algorithm. ServerStorage (Backups, Tests) is not part of this list.

## R0.4 / R0.5 baseline (2026-10-16)
Studio PlaceVersion 172; 49 scripts (ReplicatedStorage 9, ServerScriptService 23, StarterPlayer 17); **0 drift** against `src/` (old repo `main` 854f4e9).

| Script | Chars | FNV-1a |
|---|---|---|
| `ReplicatedStorage.Shared.Ammo` | 1348 | `60debe08` |
| `ReplicatedStorage.Shared.Config` | 12150 | `344770ee` |
| `ReplicatedStorage.Shared.Creatures` | 2889 | `9be65520` |
| `ReplicatedStorage.Shared.Forecasts` | 1084 | `76659560` |
| `ReplicatedStorage.Shared.Ground` | 1314 | `5cba8a32` |
| `ReplicatedStorage.Shared.Items` | 7059 | `616683c2` |
| `ReplicatedStorage.Shared.SoundFx` | 5210 | `3c579c80` |
| `ReplicatedStorage.Shared.Upgrades` | 1840 | `e7bbf50f` |
| `ReplicatedStorage.Shared.Weapons` | 1593 | `87980f79` |
| `ServerScriptService.Server.CreatureService` | 25292 | `896c0611` |
| `ServerScriptService.Server.DefenseService` | 18379 | `9574bee4` |
| `ServerScriptService.Server.EventLog` | 13774 | `3c27d316` |
| `ServerScriptService.Server.GameState` | 22857 | `bf9edfd3` |
| `ServerScriptService.Server.HarborDepartures` | 3699 | `7c37e693` |
| `ServerScriptService.Server.IslandBuilder` | 17291 | `4d4421ed` |
| `ServerScriptService.Server.IsleAdmission` | 6375 | `a1bfbf01` |
| `ServerScriptService.Server.LampService` | 14418 | `c6bb9547` |
| `ServerScriptService.Server.LoadoutService` | 3292 | `a4d5c698` |
| `ServerScriptService.Server.LobbyBuilder` | 12299 | `3249ee93` |
| `ServerScriptService.Server.LootService` | 9988 | `4470f7db` |
| `ServerScriptService.Server.Main` | 36114 | `cff3c1f4` |
| `ServerScriptService.Server.PlaceRole` | 998 | `cbaea4d9` |
| `ServerScriptService.Server.PlayerData` | 10259 | `50a8d549` |
| `ServerScriptService.Server.SessionLock` | 7910 | `0ce2312e` |
| `ServerScriptService.Server.ShipBoarding` | 6008 | `d2410004` |
| `ServerScriptService.Server.ShipDeparture` | 5234 | `1286b0cf` |
| `ServerScriptService.Server.ShipRoster` | 5215 | `c1956bc4` |
| `ServerScriptService.Server.ShopService` | 7876 | `4251afa0` |
| `ServerScriptService.Server.TowerService` | 2416 | `4be07595` |
| `ServerScriptService.Server.UpgradeService` | 3993 | `9666fa84` |
| `ServerScriptService.Server.VoyageCast` | 1022 | `97b8a147` |
| `ServerScriptService.Server.Voyages` | 10985 | `da758712` |
| `StarterPlayer.StarterPlayerScripts.Client.Bench` | 25050 | `dad12bfa` |
| `StarterPlayer.StarterPlayerScripts.Client.Coach` | 20235 | `9abe4a7c` |
| `StarterPlayer.StarterPlayerScripts.Client.Departure` | 27972 | `9cfccb64` |
| `StarterPlayer.StarterPlayerScripts.Client.Gear` | 12576 | `0cf4c2d9` |
| `StarterPlayer.StarterPlayerScripts.Client.Hud` | 74395 | `808ca9a8` |
| `StarterPlayer.StarterPlayerScripts.Client.Inventory` | 40775 | `a967d10f` |
| `StarterPlayer.StarterPlayerScripts.Client.ItemPreview` | 13534 | `0bf57dc7` |
| `StarterPlayer.StarterPlayerScripts.Client.Main` | 10167 | `609f33a3` |
| `StarterPlayer.StarterPlayerScripts.Client.Menus` | 45318 | `1c200deb` |
| `StarterPlayer.StarterPlayerScripts.Client.Results` | 24994 | `632038d1` |
| `StarterPlayer.StarterPlayerScripts.Client.Shop` | 32498 | `8f420ee8` |
| `StarterPlayer.StarterPlayerScripts.Client.Storm` | 7763 | `f36fe053` |
| `StarterPlayer.StarterPlayerScripts.Client.Trader` | 22276 | `cf157b96` |
| `StarterPlayer.StarterPlayerScripts.Client.UiKit` | 107579 | `518813ba` |
| `StarterPlayer.StarterPlayerScripts.Client.UiSkin` | 9624 | `090d2bf5` |
| `StarterPlayer.StarterPlayerScripts.Client.UiStyleSheet` | 27927 | `72b94e7e` |
| `StarterPlayer.StarterPlayerScripts.Client.Vitals` | 3984 | `bd7ef551` |
