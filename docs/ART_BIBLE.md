# ART BIBLE — v1.1 (records what exists; adds the store assets and the menu pattern)

## Direction (as built, owner-approved)
- **Menus:** wooden "pirate" skin — Kenney UI Pack RPG Expansion (CC0), one atlas (`LK_PirateSkin_atlas.png`, image 127395313470932), display font **Fredoka One**. `Config.UI_SKIN = "pirate"`.
- **In-game HUD:** glassy navy panels (12,20,40 at 18% transparency, 1.5 px blue glow stroke, 14 px corners) from the owner's mock-up. Phones: left column 150 px, right 146 px, 28 px gauges, cannon card hidden.
- **Lighting (V1, D-038):** a dark, hazy storm night in cold navy and teal (ClockTime 23.2, Brightness 1.3, OutdoorAmbient 70/88/112, atmosphere density 0.34, offset 0.3, haze 1.2, colour 46/64/80) and an overcast sea day (Brightness 1.4, atmosphere density 0.4, haze 2.4, grey-teal); storm cloud cover 0.8 and no stars in the storm; the sea reaches 3,072 studs so its edge is lost in the haze. Was: moonlit blue nights (ClockTime 23.2, Brightness 1.6, blue ambients, atmosphere density 0.32), moon 18, stars 4,000, bloom for lanterns, `GlassPop` colour correction (+12% sat, +6% contrast). Night stays dark enough that the beam matters.
- **Harbor (V6):** golden hour on the player's device while they are on the harbor island (ClockTime 17.7, Brightness 2.2, warm ambients, atmosphere colour 214/164/128); lanterns amber glass with iron caps; the campfire is the harbor's warm centre.
- **Palette (V5, D-039):** terrain Grass 70/92/64, LeafyGrass 62/86/60, Ground 98/84/68, Mud 76/64/54, Rock 94/100/108, Slate 72/80/92, Basalt 58/63/72, Sand 184/168/136, Cobblestone 108/110/112; `GlassPop` now saturation 0, contrast +0.1, tint 240/246/255. Props: wood, slate, cobble and metal; warm amber (255/176/84) only for lights.
- **World:** Studio terrain island and sea; code-built tower, pads, barrels, harbor ship, Quartermaster stall. Creature models are simple meshes; Sand Skitter = Rock Crab at 60%.

## Rules going forward
1. **The beam is the hero of every image.** Icon, thumbnails and trailer frames show the beam cutting the storm. In game (V2) it is a soft shaft with a bright core and feathered edges, never a flat wedge, and it fades out before it touches the ground; its pool of light shows where it lands.
2. Readability on a 6-inch phone at the overhead lamp camera: creature silhouettes distinct by shape before colour; bosses two-tone.
3. Render budget per creature ≤ 3 instances; no per-creature lights (architecture §8).
4. No gore: creatures dissolve into sea-foam particles.
5. HUD: one layout pass with `variant = "glass"`; menus keep the pirate wood header with a glass body (see *Menu pattern*). No second restyle pass: a screen is rebuilt on the pattern or left alone, never layered.

## Store assets (R0.6 → S2.7 → L1.5)
- **Title A:** `Lighthouse Keepers 🌊 Keep the Light` · **Title B:** `Lighthouse Keepers: Storm Survival` · **Title C:** `13 Nights at the Lighthouse 🔦` (number-as-goal, the pattern of the category's winners). Remove "- Staging" immediately. **Live title until S3: A**; S3.1 tests A/B/C with diagnostic ads.
- **Icon:** the lighthouse at the left third, beam sweeping right across rain, lighting the Barnacle Brute rising from the sea; three small survivors on the rocks (one carrying a barrel). Two palettes: A amber beam / navy storm; B white beam / teal storm. Text-free. Reconciled with the pirate skin (R0.6): lighthouse and storm painterly, not cartoon; survivors may wear the keeper coats; no wood UI frame inside the icon. This paragraph replaces `ICON_BRIEF.md`, which was not carried into this repo.
- **Thumbnails 16:9:** 1 clutch refuel with the lamp at 1% and the red banner; 2 focused beam burning the Brute with the boss bar; 3 four-crew deck with the forecast vote card; 4 (L1) cannon line at night; 5 (L1) "THE LIGHT HELD" dawn.
- **Trailer (30 s, L1):** storm hits → light restored → oil run at 3% → Brute burn → dawn Pearl → "Keep the light."

## Menu pattern — "grid + detail pane" (owner-chosen 2026-10-17; D-041)
Reference: the crafting screen of *99 Nights in the Forest*. The owner's note: **people like the big buttons.** Every full-screen menu in the game — Quartermaster shop, workbench, locker/loadout, island merchant, specialties (skill tree), cosmetics — is built on this one pattern. Nothing is restyled a second time: the pattern **replaces** a screen, it is never layered on top of it (rule 5 stands).

**Look (owner, D-042, 2026-10-17):** the pattern is built in the Bold skin (`Config.UI_SKIN = "bold"`: navy panels, thick dark outlines, chunky 3D buttons, Luckiest Guy and Fredoka One). Where the layout table below says pirate wood header or glass body, use the Bold panel and header instead; every size and rule stays.

### Why it works (the rules we keep)
1. **One tile is always selected.** Highlighted tile → the same item enlarged in the detail pane → name → one-line description → cost → one big action button. The player never wonders what they just tapped.
2. **Every tile is the same shape and the same stack:** icon → name → cost. The eye learns the layout once and scans the whole grid.
3. **Cost is an icon + a number, never a word.** Readable at 9 years old; translates for free.
4. **Locked items stay visible, dimmed, with one loud reason line** (`NEEDS RANK 2`, `NEEDS NIGHT 3`, `NEEDS A STANDARD WIN`). Seeing the locked thing is the hook.
5. **Resource totals sit at the top of the panel** so "can I afford it?" is answered without leaving the menu.
6. **The close button is huge, red, top-right.** Panic-exit always works on a phone.
7. **The menu is an overlay, not a mode:** the night strip and hotbar stay visible behind it; the world stays visible through the panel.
8. **Icons are hand-drawn style on a dark panel** so the panel never fights the world behind it.

### Two things we do better than the reference
- **Show the stat change in the detail pane** (`Damage 12 → 14`, `Beam width +10%`) computed by `StatPipeline` (S5.7) — the preview is the in-voyage value, never a second formula.
- **The detail pane stays in the same place on phone** (right side, narrower) so the action button is never pushed off-screen. The reference stacks it below the grid on small devices and loses the CRAFT button.

### Layout spec (reference units at 1920×1080; `UIScale = clamp(viewportY / 1080, 0.55, 1.0)`)
| Element | Spec |
|---|---|
| Panel | Centered, 1560×900, 24 px corners, body = glass navy `(12,20,40)` at 18% transparency with the 1.5 px blue glow stroke (same tokens as the HUD); header strip = pirate wood from the Kenney atlas, 72 px tall, title in Fredoka One 40 px. Skin stays `"pirate"`; only the panel body is dark. |
| Resource bar | Top-center of the panel, inside the header: up to 4 pairs of `icon 48 px + number Fredoka One 36 px`, 56 px gap. Pearls 🫧 always first. |
| Close | 96×96, `(220,40,40)`, white `X` 48 px, top-right corner overlapping the panel edge by 24 px. |
| Grid | Left 62% of the panel width. 5 columns on PC, 3 on phone (viewport width < 1000 after scale). Tile **180×180**, 20 px gutter, 20 px corners. Scroll vertical only; scrollbar 10 px on the right of the grid. |
| Tile stack | icon 96×96 centered at y = 20 → name Fredoka One 24 px, 1 line, TextScaled off, truncates with `…` → cost row: icon 28 px + number 28 px (two costs side by side if needed). Quantity badge `×N` top-left, 36 px circle, when the item comes in stacks. |
| Tile states | **Normal:** fill `(28,34,52)`, stroke 2 px `(70,80,110)`. **Selected:** stroke 4 px `(255,214,0)` + 4 px outer glow; tile scales to 1.04 over 0.08 s. **Owned/placed:** fill `(190,150,30)` at 40%, badge ✓. **Locked:** everything at 35% opacity, grayscale icon, cost still visible, no scale on hover. **Can't afford:** normal tile, cost number `(230,70,70)`. **Hover (PC only):** stroke `(140,160,210)`. |
| Section divider | One full-width yellow line above a locked group: Fredoka One 32 px, uppercase, the reason + the icon of the thing needed (`NEEDS WORKBENCH 2 🔨`). One divider per reason; locked tiles grouped under it, never scattered among unlocked ones. |
| Detail pane | Right 38%. Enlarged icon 320×320 at the top (plain, no frame), name Fredoka One 44 px, description 28 px max 2 lines `(255,230,80)` on the dark body, stat lines 28 px (`Damage 12 → 14`, arrow green when better, red when worse), cost row icon 56 + number 48 `(230,70,70)` if unaffordable else white. |
| Action button | Bottom of the detail pane, full pane width, **112 px tall**, 28 px corners, `(120,220,60)` fill with a 2-tone bottom edge 8 px darker, label Fredoka One 48 px uppercase (`BUY`, `UPGRADE`, `EQUIP`, `CRAFT`). Disabled: gray `(90,90,100)`, label unchanged, reason toast on tap ("Need 3 more Pearls"). Press: scale 0.96 for 0.06 s then back. |
| Hotbar | Unchanged, visible under the panel bottom edge (panel bottom ≥ 120 px above the viewport bottom). |
| Phone (667×375 logical and up) | Same structure: panel 96% width, grid 3 columns of 150 px tiles, detail pane 36% width with icon 200 px, button 96 px tall, close 80 px. **No tap target below 56 px on-device after UIScale.** Checked at iPhone 7 and 13 Pro Max in Device Simulator at every checkpoint that touches a menu. |
| Motion | Panel opens with scale 0.92 → 1 over 0.12 s and fade; tiles have no entrance animation (fast open beats pretty open). Purchase success: tile pops 1.1 → 1 over 0.15 s, +Pearl counter ticks, lantern chime. |
| Sound | open/close click, select tick, buy chime, denied thunk — all from the existing Roblox-owned set in `assets/ART_SOURCES.md`. |

### Reference screens (for taste, not copying)
Plants vs. Zombies (wave bar with flags — the night strip), Don't Starve (day clock dial — the dawn countdown), Overcooked (every teammate's state visible — the crew panel), Pet Simulator 99 (reward pop-ups — dawn banking), Dead Rails (how little HUD a wave needs), Doors (HUD recedes in tension), Hades / Vampire Survivors (3-card choice — specialties), Sea of Thieves / Dredge (lantern-against-the-dark mood). *99 Nights in the Forest* is the direct category comparator and the bar players will measure the menus against.

### Where it is built
- **S2.5c — Menu pattern v1:** `UiKit/Tiles` (TileGrid, Tile, DetailPane, BigButton, ReasonDivider) as a self-contained module on the current UiKit; applied to the **Quartermaster shop** and the **workbench** first (the two screens every first session opens). Other screens keep their current layout until S5.
- **S5.5 — UiKit split:** `Tiles` becomes part of `Primitives`/`Dialogs`; locker, merchant, specialties and cosmetics move onto the pattern as they are touched (S6.2, S7.4, B1.1).
- `StatPipeline` previews in the detail pane land in **S5.7** (before that the pane shows the definition's base numbers).

## Cosmetic lines (B1.1)
Beam colours (existing: Keeper's Amber, Sea Glass, Moonlight, Ember) · lamp housings · keeper coats · lantern skins · ship flags · emotes. Pearls for some, Robux for others; never power.

## Owner approval
- [x] Store direction approved · 2026-10-16 (D-009)
- [x] Icon producer decided · 2026-10-16: Studio AI image generation first (S2.7), contractor if it fails the brief
