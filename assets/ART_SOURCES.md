# ART & ASSET SOURCES

Every asset, package and audio ID used in the place, recorded before it ships.

| Asset | Type | Asset ID | Origin | License | Owner / creator | Pinned | Used in | Status |
|---|---|---|---|---|---|---|---|---|
| Pirate UI skin atlas (`LK_PirateSkin_atlas.png`) | Image | 127395313470932 | Kenney UI Pack: RPG Expansion, packed by the project | CC0 (credit optional: "UI art: Kenney.nl") | Kenney / owner upload | 2026-10-12 | `Client.UiSkin` | Active |
| Fredoka One | Font | Roblox built-in | Roblox | Roblox | — | — | UiKit display font | Active |
| ProfileStore | Module (vendored source) | — (not a Creator Store insert) | github.com/MadStudioRoblox/ProfileStore, commit 45c9847cbcf1fc260369c50eb335aba7c35aecdd, file `ProfileStore.luau`, 64,654 bytes, SHA-256 AD43737203688B8E88CAB34EBE8C483000C157E53BFB41E35F1B49EE89D0C95F (same file the TASK-004 audit read in full) | Apache-2.0 (repository licence; keep this attribution) | loleris / MadStudio | 2026-10-16 | `ServerScriptService.Server.ProfileStore` (used by `PlayerData`) | Active (R1.3), byte-identical in Studio and `src/` |
| Creature models (Rock Crab, Barnacle Brute, Shipwreck Hermit) | Model | in place | project-built | owner | owner | — | `CreatureService` templates | Active |
| Gear models S6.4: `CoralLance` (the Storm Harpoon model recoloured), `KelpweaveVest` (the Keeper's Greatcoat mesh, texture removed, kelp green fabric), `TidecallerBlades` (3 parts round a hub, built in Studio) | Model | in place (`ReplicatedStorage.ItemModels`) | project-built from the place's own models | owner | owner | 2026-10-17 | shop and bag icons, tools, worn armor | Active (DEV) |
| Sounds (SoundFx catalog) | Audio | see `Shared/SoundFx` | Creator Store | per asset — **audit at B1.2** | — | — | `SoundFx` | Active, licence check pending |
| S6.5 monster sounds (`eelRear`, `eelSpit`, `pufferFuse`, `pufferBoom`, `ghostWail`, `ghostDrain`) | Audio | built-in `rbxasset://sounds/...` at their own pitch | ships with Roblox | Roblox built-in | — | 2026-10-17 | `SoundFx` | Active (DEV) |
| S6.5 monster bodies (Spitter Eel, Puffer Mine, Ghost Lantern) | Model | built at run time from plain parts (`CreatureService` template fallback, `shape`) | project-built | owner | owner | 2026-10-17 | `CreatureTemplates` | Active (DEV); replace with art later |
| Production place | Experience | place 132065051336560 / universe 10769064643 | owner | — | owner | — | — | Live |

## Store assets
| Asset | Variant | File | Uploaded ID | Status |
|---|---|---|---|---|
| Icon | A (beam vs Brute, no text) | `icons/icon_A_beam_vs_brute.png` | | made S2.7 (2026-10-17), not uploaded |
| Icon | B (same art, "KEEP THE LIGHT") | `icons/icon_B_keep_the_light.png` | | made S2.7, not uploaded (S3 icon test) |
| Thumbnail 1 — Brute burn | "BURN THE BRUTE" | `thumbnails/thumb_1_brute_burn.png` | | made S2.7, not uploaded |
| Thumbnail 2 — clutch refuel | "1% FUEL. RUN!" | `thumbnails/thumb_2_clutch_refuel.png` | | made S2.7, not uploaded |
| Thumbnail 3 — crew of four | "KEEP THE LIGHT TOGETHER" | `thumbnails/thumb_3_crew_of_four.png` | | made S2.7, not uploaded |

All five are Studio screen captures of the DEV build (project-built island, lighthouse, characters and creatures; staged with runtime-only scripts), cropped and captioned with Windows fonts Impact and Georgia Bold rendered into the image (no font file is shipped). Owner's own work; no third-party licence. Title and description text: `store/STORE_PAGE.md`.

## Rules
- Nothing purchased without owner approval. Free Creator Store models only with the licence checked and recorded.
- Never silently update a package; insert, test, add a row, mark the old row Superseded.
