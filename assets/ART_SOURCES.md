# ART & ASSET SOURCES

Every asset, package and audio ID used in the place, recorded before it ships.

| Asset | Type | Asset ID | Origin | License | Owner / creator | Pinned | Used in | Status |
|---|---|---|---|---|---|---|---|---|
| Pirate UI skin atlas (`LK_PirateSkin_atlas.png`) | Image | 127395313470932 | Kenney UI Pack: RPG Expansion, packed by the project | CC0 (credit optional: "UI art: Kenney.nl") | Kenney / owner upload | 2026-10-12 | `Client.UiSkin` | Active |
| Fredoka One | Font | Roblox built-in | Roblox | Roblox | — | — | UiKit display font | Active |
| Luckiest Guy | Font | Roblox built-in | Roblox | Roblox | — | 2026-10-17 | Harbor UI Look A titles and buttons (`Client.UiSkinBold`) | Active (DEV) |
| Soft smoke texture (`rbxasset://textures/particles/smoke_main.dds`) | Texture | Roblox built-in (ships with the client) | Roblox | Roblox | — | 2026-10-17 | `Client.BeamFx` (soft edges of the lighthouse beam, V2) | Active (DEV) |
| Fire and sparkle textures (`rbxasset://textures/particles/fire_main.dds`, `sparkles_main.dds`) | Texture | Roblox built-in (ships with the client) | Roblox | Roblox | — | 2026-10-17 | harbor campfire (V6) | Active (DEV) |
| Harbor dressing V6 (campfire stones and logs, lantern caps, pier bollards and rope, 10 more palms copied from the place's own palm) | Parts | in place (`Workspace.LobbyIslandDecor`) | project-built in Studio | owner | owner | 2026-10-17 | the harbor | Active (DEV) |
| Spitter Eel creature model (`ServerStorage.Art.SpitterEel`: one MeshPart + SurfaceAppearance, 3.12 x 4.00 x 3.42, YawOffset 0) | Model (MeshPart) | 97748243928045 | ForgeGUI generation (connector, style low-poly cartoon), uploaded to Roblox | owner's generation, owner's account | owner (@Lighthouse8282) | 2026-10-18 | `CreatureService` creature template | Active (DEV) |
| Puffer Mine creature model (`ServerStorage.Art.PufferMine`: one MeshPart + SurfaceAppearance, 3.05 x 3.40 x 3.25, YawOffset -90) | Model (MeshPart) | 101833487650327 | ForgeGUI generation (connector, style low-poly cartoon), uploaded to Roblox | owner's generation, owner's account | owner (@Lighthouse8282) | 2026-10-18 | `CreatureService` creature template | Active (DEV) |
| Ghost Lantern creature model (`ServerStorage.Art.GhostLantern`: one MeshPart + SurfaceAppearance, 2.29 x 2.60 x 1.64, YawOffset -90) | Model (MeshPart) | 84379251494791 | ForgeGUI generation (connector, style low-poly cartoon), uploaded to Roblox | owner's generation, owner's account | owner (@Lighthouse8282) | 2026-10-18 | `CreatureService` creature template | Active (DEV) |
| Tide Witch creature model (`ServerStorage.Art.TideWitch`: one MeshPart + SurfaceAppearance, 2.51 x 3.80 x 2.73, YawOffset -90) | Model (MeshPart) | 99564367360876 | ForgeGUI generation (connector, style low-poly cartoon), uploaded to Roblox | owner's generation, owner's account | owner (@Lighthouse8282) | 2026-10-18 | `CreatureService` creature template | Active (DEV) |
| Coral Shaman creature model (`ServerStorage.Art.CoralShaman`: one MeshPart + SurfaceAppearance, 2.34 x 3.40 x 3.20, YawOffset -90) | Model (MeshPart) | 98577385777864 | ForgeGUI generation (connector, style low-poly cartoon), uploaded to Roblox | owner's generation, owner's account | owner (@Lighthouse8282) | 2026-10-18 | `CreatureService` creature template | Active (DEV) |
| Rock Crab creature model (`ServerStorage.Art.RockCrab`: one MeshPart + SurfaceAppearance, 2.81 x 1.71 x 3.13, YawOffset -90) | Model (MeshPart) | 107087579544073 | ForgeGUI generation made to look like the owner's crab design (not the owner's own .glb), uploaded to Roblox | owner's generation, owner's account | owner (@Lighthouse8282) | 2026-10-18 | `CreatureService` creature template | Active (DEV); replaces the earlier RockCrab mesh (kept in `ServerStorage.Backups.ART7_before_2026-10-18`) |
| Sand Skitter creature model (`ServerStorage.Art.SandSkitter`: one MeshPart + SurfaceAppearance, 2.32 x 1.67 x 3.13 before the skitter's 0.6 scale, YawOffset -90) | Model (MeshPart) | 99470346593772 | ForgeGUI generation made to look like the owner's skitter design, uploaded to Roblox | owner's generation, owner's account | owner (@Lighthouse8282) | 2026-10-18 | `CreatureService` creature template | Active (DEV) |
| Island props V4 (`Workspace.IslandProps`: keeper's hut, oil shed, dock, path lanterns, flag) and island terrain paint | Parts and terrain | in place | project-built in Studio (record: `assets/world/v4_island_build.md`) | owner | owner | 2026-10-17 | the voyage island | Active (DEV) |
| ProfileStore | Module (vendored source) | — (not a Creator Store insert) | github.com/MadStudioRoblox/ProfileStore, commit 45c9847cbcf1fc260369c50eb335aba7c35aecdd, file `ProfileStore.luau`, 64,654 bytes, SHA-256 AD43737203688B8E88CAB34EBE8C483000C157E53BFB41E35F1B49EE89D0C95F (same file the TASK-004 audit read in full) | Apache-2.0 (repository licence; keep this attribution) | loleris / MadStudio | 2026-10-16 | `ServerScriptService.Server.ProfileStore` (used by `PlayerData`) | Active (R1.3), byte-identical in Studio and `src/` |
| Creature models (Rock Crab, Barnacle Brute, Shipwreck Hermit) | Model | in place | project-built | owner | owner | — | `CreatureService` templates | Active |
| Gear models S6.4: `CoralLance` (the Storm Harpoon model recoloured), `KelpweaveVest` (the Keeper's Greatcoat mesh, texture removed, kelp green fabric), `TidecallerBlades` (3 parts round a hub, built in Studio) | Model | in place (`ReplicatedStorage.ItemModels`) | project-built from the place's own models | owner | owner | 2026-10-17 | shop and bag icons, tools, worn armor | Active (DEV) |
| Sounds (SoundFx catalog) | Audio | see `Shared/SoundFx` | Creator Store | per asset — **audit at B1.2** | — | — | `SoundFx` | Active, licence check pending |
| S6.5/S6.6 monster sounds (`eelRear`, `eelSpit`, `pufferFuse`, `pufferBoom`, `ghostWail`, `ghostDrain`, `witchChant`, `witchTide`, `shamanChime`, `shamanMend`) | Audio | built-in `rbxasset://sounds/...` at their own pitch | ships with Roblox | Roblox built-in | — | 2026-10-17 | `SoundFx` | Active (DEV) |
| S6.5/S6.6 monster bodies (Spitter Eel, Puffer Mine, Ghost Lantern, Tide Witch, Coral Shaman) | Model | built at run time from plain parts (`CreatureService` template fallback, `shape`) | project-built | owner | owner | 2026-10-17 | `CreatureTemplates` | Active (DEV); replace with art later |
| Production place | Experience | place 132065051336560 / universe 10769064643 | owner | — | owner | — | — | Live |

## Store assets
| Asset | Variant | File | Uploaded ID | Status |
|---|---|---|---|---|
| Icon | A (beam vs Brute, no text) | `icons/icon_A_beam_vs_brute.png` | | made S2.7 (2026-10-17), not uploaded |
| Icon | B (same art, "KEEP THE LIGHT") | `icons/icon_B_keep_the_light.png` | | made S2.7, not uploaded (S3 icon test) |
| Thumbnail 1 — Brute burn | "BURN THE BRUTE" | `thumbnails/thumb_1_brute_burn.png` | | made S2.7, not uploaded |
| Thumbnail 2 — clutch refuel | "1% FUEL. RUN!" | `thumbnails/thumb_2_clutch_refuel.png` | | made S2.7, not uploaded |
| Thumbnail 3 — crew of four | "KEEP THE LIGHT TOGETHER" | `thumbnails/thumb_3_crew_of_four.png` | | made S2.7, not uploaded |
| Icon (final) | A, more contrast + vignette | `icons/icon_final_A.png` | | made L1.5 (2026-10-17), not uploaded |
| Thumbnail 4 — seven nights | "SURVIVE 7 NIGHTS" | `thumbnails/thumb_4_seven_nights.png` | | made L1.5, not uploaded |
| Thumbnail 5 — new monsters | "NEW MONSTERS EVERY NIGHT" | `thumbnails/thumb_5_new_monsters.png` | | made L1.5, not uploaded |
| Trailer | 29.5 s, 1920 × 1080, no sound | `store/trailer_30s.mp4` | | made L1.5, not uploaded |

L1.5: the two new thumbnails and the trailer's new shots are DEV Studio captures (night and day, staged with runtime-only scripts: a scripted camera, HUD hidden, monsters spawned with `CreatureService.spawn`); the trailer is made from those and the S2.7 captures with Python (Pillow) and ffmpeg, captions in Impact and Georgia Bold, no music. All five S2.7 files are Studio screen captures of the DEV build (project-built island, lighthouse, characters and creatures; staged with runtime-only scripts), cropped and captioned with Windows fonts Impact and Georgia Bold rendered into the image (no font file is shipped). Owner's own work; no third-party licence. Title and description text: `store/STORE_PAGE.md`.

## Rules
- Nothing purchased without owner approval. Free Creator Store models only with the licence checked and recorded.
- Never silently update a package; insert, test, add a row, mark the old row Superseded.
