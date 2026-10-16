# ART & ASSET SOURCES

Every asset, package and audio ID used in the place, recorded before it ships.

| Asset | Type | Asset ID | Origin | License | Owner / creator | Pinned | Used in | Status |
|---|---|---|---|---|---|---|---|---|
| Pirate UI skin atlas (`LK_PirateSkin_atlas.png`) | Image | 127395313470932 | Kenney UI Pack: RPG Expansion, packed by the project | CC0 (credit optional: "UI art: Kenney.nl") | Kenney / owner upload | 2026-10-12 | `Client.UiSkin` | Active |
| Fredoka One | Font | Roblox built-in | Roblox | Roblox | — | — | UiKit display font | Active |
| ProfileStore | Module (vendored source) | — (not a Creator Store insert) | github.com/MadStudioRoblox/ProfileStore, commit 45c9847cbcf1fc260369c50eb335aba7c35aecdd, file `ProfileStore.luau`, 64,654 bytes, SHA-256 AD43737203688B8E88CAB34EBE8C483000C157E53BFB41E35F1B49EE89D0C95F (same file the TASK-004 audit read in full) | Apache-2.0 (repository licence; keep this attribution) | loleris / MadStudio | 2026-10-16 | `ServerScriptService.Server.ProfileStore` (used by `PlayerData`) | Active (R1.3), byte-identical in Studio and `src/` |
| Creature models (Rock Crab, Barnacle Brute, Shipwreck Hermit) | Model | in place | project-built | owner | owner | — | `CreatureService` templates | Active |
| Sounds (SoundFx catalog) | Audio | see `Shared/SoundFx` | Creator Store | per asset — **audit at B1.2** | — | — | `SoundFx` | Active, licence check pending |
| Production place | Experience | place 132065051336560 / universe 10769064643 | owner | — | owner | — | — | Live |

## Store assets
| Asset | Variant | File | Uploaded ID | Status |
|---|---|---|---|---|
| Icon | A (amber/navy) | `icons/icon_A.png` | | not made |
| Icon | B (white/teal) | `icons/icon_B.png` | | not made |
| Thumbnail 1 — clutch refuel | — | `thumbnails/t1_refuel.png` | | not made |
| Thumbnail 2 — Brute burn | — | `thumbnails/t2_brute.png` | | not made |
| Thumbnail 3 — crew deck | — | `thumbnails/t3_crew.png` | | not made |

## Rules
- Nothing purchased without owner approval. Free Creator Store models only with the licence checked and recorded.
- Never silently update a package; insert, test, add a row, mark the old row Superseded.
