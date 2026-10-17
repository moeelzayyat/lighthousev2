# V4 island rebuild: what was changed in the DEV place (2026-10-17)

These are edit-time changes to the DEV place (terrain and parts), not scripts, so the `src/` mirror does not carry them. This file records exactly what was done so it can be checked or redone.

## Backup
`ServerStorage.Backups.VIS_V4_before_2026-10-17`:
- `IslandTerrain_cells_-64_-12_-64_to_63_19_63` (TerrainRegion of the voyage island, studs x/z -256..256, y -48..80).
  Undo: `workspace.Terrain:PasteRegion(<that TerrainRegion>, Vector3int16.new(-64, -12, -64), true)`.
- `Decor` (the edit-time Decor folder as it was; V4 did not change it).
To remove the props: delete `Workspace.IslandProps`.

## Terrain (voxels, 4-stud resolution, region x/z -112..112, y -8..28)
Heights on the plateau (radius < 74, where the tower, pads, oil, bench, trader and spawn stand) are unchanged. Only materials there changed.
- **Plateau surface:** grass replaced by a mix: Mud on the worn paths (within 2.6 studs of a path line), Ground at path edges (to 4.5), Rock patches (`noise(x/14, z/14, 7.7) > 0.36`), Ground (`noise(x/38, z/38, 1.3) > 0.25`), LeafyGrass elsewhere.
- **Paths** (x, z polylines): south cove (0,92) → (2,60) → spawn (0,24) → (-10,13) → tower door (-15,2); spawn → (22,24) → oil (44,21); spawn → bench (-14,26); (4,30) → trader (18,40); door → (-20,-18) → hut (-23,-34).
- **Rocky rim** (radius 73–95): up to 7 studs of Basalt, Slate or Rock added on top of the old sand slope (`smooth(73,80,r) * (1 - smooth(86,95,r)) * clamp(noise(x/15, z/15, 3.3) + 0.55, 0, 1.2) * 7`), and the sand surface there repainted to rock.
- **Coves** (no rim, sand kept): bearings 90° (south, toward the harbor), 215° and 331° (the two edit-time wreck props), each ±14° with a soft edge to ±24°.
- **Outer shore** (radius 98–112): sand mostly repainted to wet rock outside the coves.
Measured after: GroundGrid 445,474 samples in 3.2 s (was 398,974 in 3.1 s); a creature's grid height matched a terrain raycast within 0.03 studs over Night 1.

## Props (`Workspace.IslandProps`, 65 parts, 9 PointLights, no scripts)
- **KeepersHut** at (-25, ground, -45), front facing the tower: cobble floor, plank walls, door, a warm lit window (PointLight 16 studs), slate pitched roof, stone chimney, woodpile, a flag on a 16-stud pole (tag `Flutter`).
- **OilShed** over the oil barrels at (50, ground, 21), open toward the tower: 4 posts, back wall, sloped slate roof, sign, a hanging lantern (tag `Sway`). The "Grab Oil" prompt still works under it (tested).
- **Dock** at the south cove: a 32-stud plank pier from z = 96 to 128 on pilings, a rowboat tied alongside, a lantern at the end.
- **PathLanterns:** 6 posts with hanging amber lanterns (PointLight 12 studs, no shadows) along the south path, the oil path and the hut path.
Every swinging part carries a `SwayPivot` attribute (the world point it hangs from); `Client/WindFx` moves them on each device.
