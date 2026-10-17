# ART BIBLE — v1 (records what exists; adds the store assets)

## Direction (as built, owner-approved)
- **Menus:** wooden "pirate" skin — Kenney UI Pack RPG Expansion (CC0), one atlas (`LK_PirateSkin_atlas.png`, image 127395313470932), display font **Fredoka One**. `Config.UI_SKIN = "pirate"`.
- **In-game HUD:** glassy navy panels (12,20,40 at 18% transparency, 1.5 px blue glow stroke, 14 px corners) from the owner's mock-up. Phones: left column 150 px, right 146 px, 28 px gauges, cannon card hidden.
- **Lighting (V1, D-038):** a dark, hazy storm night in cold navy and teal (ClockTime 23.2, Brightness 1.3, OutdoorAmbient 70/88/112, atmosphere density 0.34, offset 0.3, haze 1.2, colour 46/64/80) and an overcast sea day (Brightness 1.4, atmosphere density 0.4, haze 2.4, grey-teal); storm cloud cover 0.8 and no stars in the storm; the sea reaches 3,072 studs so its edge is lost in the haze. Was: moonlit blue nights (ClockTime 23.2, Brightness 1.6, blue ambients, atmosphere density 0.32), moon 18, stars 4,000, bloom for lanterns, `GlassPop` colour correction (+12% sat, +6% contrast). Night stays dark enough that the beam matters.
- **World:** Studio terrain island and sea; code-built tower, pads, barrels, harbor ship, Quartermaster stall. Creature models are simple meshes; Sand Skitter = Rock Crab at 60%.

## Rules going forward
1. **The beam is the hero of every image.** Icon, thumbnails and trailer frames show the beam cutting the storm.
2. Readability on a 6-inch phone at the overhead lamp camera: creature silhouettes distinct by shape before colour; bosses two-tone.
3. Render budget per creature ≤ 3 instances; no per-creature lights (architecture §8).
4. No gore: creatures dissolve into sea-foam particles.
5. HUD: one layout pass with `variant = "glass"`; menus keep wood. No second restyle pass.

## Store assets (R0.6 → S2.7 → L1.5)
- **Title A:** `Lighthouse Keepers 🌊 Keep the Light` · **Title B:** `Lighthouse Keepers: Storm Survival` · **Title C:** `13 Nights at the Lighthouse 🔦` (number-as-goal, the pattern of the category's winners). Remove "- Staging" immediately. **Live title until S3: A**; S3.1 tests A/B/C with diagnostic ads.
- **Icon:** the lighthouse at the left third, beam sweeping right across rain, lighting the Barnacle Brute rising from the sea; three small survivors on the rocks (one carrying a barrel). Two palettes: A amber beam / navy storm; B white beam / teal storm. Text-free. Reconciled with the pirate skin (R0.6): lighthouse and storm painterly, not cartoon; survivors may wear the keeper coats; no wood UI frame inside the icon. This paragraph replaces `ICON_BRIEF.md`, which was not carried into this repo.
- **Thumbnails 16:9:** 1 clutch refuel with the lamp at 1% and the red banner; 2 focused beam burning the Brute with the boss bar; 3 four-crew deck with the forecast vote card; 4 (L1) cannon line at night; 5 (L1) "THE LIGHT HELD" dawn.
- **Trailer (30 s, L1):** storm hits → light restored → oil run at 3% → Brute burn → dawn Pearl → "Keep the light."

## Cosmetic lines (B1.1)
Beam colours (existing: Keeper's Amber, Sea Glass, Moonlight, Ember) · lamp housings · keeper coats · lantern skins · ship flags · emotes. Pearls for some, Robux for others; never power.

## Owner approval
- [x] Store direction approved · 2026-10-16 (D-009)
- [x] Icon producer decided · 2026-10-16: Studio AI image generation first (S2.7), contractor if it fails the brief
