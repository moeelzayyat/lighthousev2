# Harbor ship: collision, stairs and gangway (SHIP.1, 2026-10-18)

The ship's visible hull is one MeshPart (`ServerStorage.Art.PirateShip.ShipVisual`, 39 × 66 × 71 studs, CanCollide off).
Everything players stand on or bump into is a plain Part inside the same model. Coordinates below are in the
art's own space (pivot at 0,0,0, bow toward −Z); `LobbyBuilder` places the ship at world (0, 0, 420) facing the island.

## Why it changed

- The old invisible floors were 2–4 studs off the decks you see: the main deck floor stood 2.3 above the
  planks, the forecastle and quarterdeck floors 3.7 and 3.3 below theirs, so players walked inside the hull.
- The old side walls were straight boxes at x = ±14.5: in the air beside the narrow bow, nothing below the deck,
  nothing at the stern. The pier's landing ran straight through the stern into the hull.

## Measured (Studio, neon test planes and ray casts against the hull)

| Deck | Top (Y) | Z range | Rail top |
|---|---|---|---|
| Main deck | 8.3 | −16 … +12 | ~10.6 |
| Forecastle | 16.3 | −27.5 … −16 | ~18 |
| Quarterdeck | 16.9 | +12 … +34 | ~21 |

Hull outline (outside, half-width at deck height), Z → X: −27.8 → 0, −27 → 2, −25 → 4, −22 → 7, −19 → 9, −16 → 11.3,
−13 → 13, −10 → 14, +12 → 14, +17 → 13.5, +20 → 13, +26 → 13, +29 → 10.5, +32 → 6, +34 → 3.5, +35.6 → 0.

## What is in the model now

- `Colliders` (all invisible):
  - Floors named `MainDeckFloor`, `ForecastleFloor`, `QuarterdeckFloor` (the name matters: LobbyBuilder's deck ray cast and the BoardingZone read them), cut in bands so none sticks out of the hull.
  - `HullWall` × 30 along the outline, 1.2 thick, from Y −6 to the rail top: 10.8 on the main deck (players can still jump the low rail into the sea), 19.1 at the forecastle, 20.6 at the quarterdeck.
  - `HullBottom` bands at Y −6.5, so swimmers can't come up inside.
  - `ForecastleFront`, `QuarterdeckFront` (the raised decks' faces), `DeckEdge` guards along the raised decks' front edges with gaps at the stair tops.
  - `DeckHouse` (the small windowed house on the quarterdeck, Z 19.3 … 23.2) and two `Mast` cylinders at Z −1.4 and +10.3.
  - `GangwayGuard` along the gangway's inner edge.
- `Stairs`: `QuarterdeckStairs` (x 8.5, Z 0 → 12) and `ForecastleStairs` (x 8.5, Z −4 → −16). Visible wooden steps without collision over an invisible `StairRamp`.
- `Gangway` (visible, WoodPlanks in the pier's colour): a landing beside the pier (Z 36 … 39.5), a walkway outside the port side (x −17.5, 4 wide, from Y 13.6 down to 11.2), a plank over the low rail at Z 6, and a short step down onto the main deck. Pilings and an outer hand rail.
- `WheelStand` (the SAIL NOW prompt) moved up to the quarterdeck: (0, 18.9, 28).
- `Workspace.LobbyIslandDecor.PierLanding` shortened to Z 455.9 … 458.5 (world) so it ends at the stern instead of inside it.

## Checked (play test in DEV, 2026-10-18)

Walking pier → gangway → deck → stairs → quarterdeck works and sets Ready (PC and the iPhone 17 Pro in the Device Simulator).
Walking or swimming at the hull from any side stops at the hull; the stern, the bow, the raised decks' faces, the masts and the deck house all stop the player.
