# Harbor island enlargement (2026-10-17, owner's ask: "Harbor isle needs to be at least twice bigger incase we put additional npc and stuff")

Edit-time terrain and props in the DEV place (not in the `src/` mirror).

- Land area: 16,912 → 48,096 studs² (2.8×), measured by raycasting a 4-stud grid from x −200..200, z 320..760; 40,208 studs² of it is the flat top (above y 8.5).
- Shape: a rounded island centred on (0, 585), radius 125 studs with a ±7% wobble; flat top at y = 10 out to 84% of the radius, then a beach down to y = −2. The north shore (z < 474: the pier and the ship at z 420) fades back to its old shape, so boarding is unchanged. Only columns lower than the new shape were raised; the old island top, the spawn, the shop, the board and the pier were not touched.
- Materials: LeafyGrass top with Ground patches (noise), Ground and Sand on the slopes, Rock underneath (the V5 palette).
- Dressing: 22 palms (copies of the place's own palm) around the new south, east and west edges, 7 low slate rocks near the new shore. The middle of the new south half is left open for future NPCs and buildings.
- Backup: `ServerStorage.Backups.HARBOR_before_2026-10-17` (TerrainRegion of cells x −40..39, y −12..11, z 100..199 and the old `LobbyIslandDecor`). Undo: `workspace.Terrain:PasteRegion(<region>, Vector3int16.new(-40, -12, 100), true)` and restore the decor folder.
- Checked in play: spawn at (−3, 15, 520) as before; the harbor's golden-hour lighting holds at the far south edge (clock 17.7 at (39, 21, 679)); TestRunner 250/250; 0 errors.
