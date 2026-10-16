# STATS — pipeline and registry

```
Final = clamp((Base + ΣFlat) × (1 + ΣAdditivePct) × ΠMultipliers, Min, Max)
```
`StatPipeline` (S5.7) is the single place these are computed: shop previews, bench previews, merchant boosts and in-voyage values all use it. Current values are the owner-approved numbers from `Config` and `Shared/Weapons`, `Armor`, `Upgrades`.

| StatId | Unit | Base | Layers allowed | Min | Max | Sources |
|---|---|---|---|---|---|---|
| `PlayerMaxHealth` | HP | 100 | Flat, AdditivePct | 50 | 300 | armor, specialties |
| `PlayerArmor` | % damage reduction | armor def | Flat | 0 | 60% | armor |
| `PlayerSpeed` | studs/s | 16 | AdditivePct | 12 | 22 | merchant speed boost (voyage), Quartermaster boost (cap +5%) |
| `WeaponDamage` | per hit | weapon def | AdditivePct, Multiplier | 1 | 200 | Quartermaster damage boost (cap +5%), merchant boost (voyage) |
| `WeaponCooldown` | s | weapon def | AdditivePct (reduction) | 0.2 | 5 | — |
| `WeaponRange` | studs | weapon def | AdditivePct | 4 | 40 | — |
| `BeamWideDps` | DPS | 12 | AdditivePct, Multiplier | 6 | 40 | Lens Power (bench), Fog bank forecast (−30% wide) |
| `BeamFocusDps` | DPS | 35 | AdditivePct, Multiplier | 15 | 100 | Lens Power |
| `BeamWideHalfAngle` | deg | 18 | Flat | 10 | 30 | — |
| `FuelDrain` | fuel/s | 1.2 × crewMult | AdditivePct, Multiplier | 0.5 | 4 | Leaky stores (+25%), Fuel Tank (bench), Overcharged Beam (focus −25%) |
| `MaxFuel` | fuel | 100 | Flat, AdditivePct | 60 | 200 | Fuel Tank |
| `FocusFuelMult` | × | 2.5 | Multiplier | 1.2 | 2.5 | Overcharged Beam |
| `RepairAmount` | integrity | 20 | AdditivePct, Multiplier | 10 | 60 | Reinforced Walls, Clockwork Bastion (+50%) |
| `MaxIntegrity` | integrity | 100 | Flat, AdditivePct | 60 | 250 | Reinforced Walls |
| `AutoSweepSpeed` | deg/s | 25 | AdditivePct | 10 | 60 | Clockwork Sweep |
| `CannonDamage` | per shot | level table | AdditivePct | 5 | 60 | — |
| `CannonRange` | studs | level table | AdditivePct | 25 | 60 | — |
| `ShellGainPct` | % | 0 | AdditivePct | 0 | +15% | Quartermaster Shell boost (cap +10%), specialties |
| `LootMagnetRadius` | studs | 10 | Flat, AdditivePct | 6 | 24 | specialties |
| `CrabCount(night)` | int | `nightPlan` | Multiplier | — | `MAX_CREATURES` | Spring tide (+40% at −20% HP) |
| `CreatureHealthMult` | × | 1 | Multiplier | 0.5 | 2 | Spring tide, Long Voyage |

## Night plan (pure, R1.2) — must reproduce today's numbers exactly
```
growth(n) = min(n-1, GROWTH_FULL_UNTIL-1) + max(0, n-GROWTH_FULL_UNTIL) × GROWTH_LATE_RATE
crabs(n)  = (CRABS_BASE + CRABS_PER_NIGHT × growth(n)) × (final ? 1.5 : 1) × forecastCrabMult
skitters(n, crew) = (SWARM_BASE + SWARM_PER_NIGHT × growth(n)) × SWARM_BY_CREW[crew] × forecastMult
boss(n)   = per VoyageDefinition schedule; count = crew size (S6.1)
```
Reference table (crew 4, no forecast): night 1 → 14 / 42 · 4 → 34 / 82 · 7 → 46 / 106 · 10 → 58 / 130 · 13 → 70×1.5=105 / 154.

## Pearl rules (pure, R1.2 / S2.2)
`pearlsFor(nightsSurvived, won, def) = nightsSurvived × PEARLS_PER_NIGHT + (won and PEARLS_VICTORY_BONUS or 0)` → Standard win 12, Long win 18. Dawn banking (S2.2, implemented): `Voyage.dawnPearls(n)` = `PEARLS_PER_NIGHT` (+ the legacy step × n) per `NightSurvived`; Results pays `Voyage.resultPearls` = `pearlsFor − banked` (the victory bonus on a win). Boss drops: 50% chance of 2–4, unchanged.

## Caps (owner policy)
Permanent Quartermaster boosts total ≤ +15% across Shells/speed/damage (D-pending S6.4). Specialties ≤ +10% each, one active. Voyage-only merchant boosts ≤ +25%, wiped at Results.
