# STATS — pipeline and registry

```
Final = clamp((Base + ΣFlat) × (1 + ΣAdditivePct) × ΠMultipliers, Min, Max)
```
`StatPipeline` (S5.7) is the single place these are computed: shop previews, bench previews, merchant boosts and in-voyage values all use it. Current values are the owner-approved numbers from `Config` and `Shared/Weapons`, `Armor`, `Upgrades`.

**S5.7 status:** `ReplicatedStorage/Shared/StatPipeline` implements the rows marked ✅ (the others get their code with their features: speed, cannons, Shell gain, loot magnet, creature multipliers). It returns today's numbers unchanged (`StatPipelineSpec`). Bench ranks enter as a Flat layer (Fuel Tank, Reinforced Walls, Clockwork Sweep: the rank value minus the base) or a Multiplier (Lens Power); the rank values stay in `Shared/Upgrades`.

| StatId | Unit | Base | Layers allowed | Min | Max | Sources |
|---|---|---|---|---|---|---|
| `PlayerMaxHealth` ✅ | HP | armor def (100 / 140 / 190) | Flat, AdditivePct | 50 | 300 | armor, specialties |
| `PlayerArmor` ✅ | % damage reduction | armor def | Flat | 0 | 60% | armor |
| `PlayerSpeed` ✅ | studs/s | 16 | AdditivePct | 12 | 22 | merchant speed boost (voyage, +10% each, cap +20%: 17.6 / 19.2), Quartermaster Sea Boots (+1% a rank, cap +5%) |
| `WeaponDamage` ✅ | per hit | weapon def | AdditivePct, Multiplier | 1 | 200 | Quartermaster Sharpened Steel (+1% a rank, cap +5%), merchant boost (voyage, +10% each, cap +20%) |

**Quartermaster boosts (S6.4):** all three together stop at **+15%** (`Boosts.TOTAL_CAP`): a player can max two lines at most, so the boosts are a choice. Ranks are saved in the profile (`Boosts`).
| `WeaponCooldown` ✅ | s | weapon def | AdditivePct (reduction) | 0.2 | 5 | — |
| `WeaponRange` ✅ | studs | weapon def (50–70) | AdditivePct | 4 | 100 (S5.7: was 40, below every weapon's approved range) | — |
| `WeaponHitRadius` ✅ | studs | weapon def | AdditivePct | 1 | 20 | — |
| `WeaponMaxTargets` ✅ | creatures | weapon def | Flat | 1 | 10 | — |
| `BeamDamageMult` ✅ | × | 1 | Multiplier | 1 | 3 | Lens Power (1.25 / 1.5 / 1.75) |
| `AutoSweepDps` ✅ | DPS | 0 | Flat | 0 | 30 | Clockwork Sweep (4 / 8 / 12) |
| `BeamWideDps` | DPS | 12 | AdditivePct, Multiplier | 6 | 40 | Lens Power (bench), Fog bank forecast (−30% wide) |
| `BeamFocusDps` | DPS | 35 | AdditivePct, Multiplier | 15 | 100 | Lens Power |
| `BeamWideHalfAngle` | deg | 18 | Flat | 10 | 30 | — |
| `FuelDrain` | fuel/s | 1.2 × crewMult | AdditivePct, Multiplier | 0.5 | 4 | Leaky stores (+25%), Fuel Tank (bench), Overcharged Beam (focus −25%) |
| `MaxFuel` ✅ | fuel | 100 | Flat, AdditivePct | 60 | 200 | Fuel Tank (130 / 160 / 190) |
| `FocusFuelMult` | × | 2.5 | Multiplier | 1.2 | 2.5 | Overcharged Beam |
| `RepairAmount` | integrity | 20 | AdditivePct, Multiplier | 10 | 60 | Reinforced Walls, Clockwork Bastion (+50%) |
| `MaxIntegrity` ✅ | integrity | 100 | Flat, AdditivePct | 60 | 250 | Reinforced Walls (150 / 200 / 250) |
| `AutoSweepSpeed` | deg/s | 25 | AdditivePct | 10 | 60 | Clockwork Sweep |
| `CannonDamage` | per shot | level table | AdditivePct | 5 | 60 | — |
| `CannonRange` | studs | level table | AdditivePct | 25 | 60 | — |
| `SniperDamage` ✅ | per shot | 12 (`Config.SNIPER_DAMAGE`, D-044) | AdditivePct | 1 | 100 | — (no boost yet) |
| `SniperCooldown` ✅ | s | 1.0 | AdditivePct | 0.3 | 5 | — |
| `SniperRange` ✅ | studs | 220 | AdditivePct | 50 | 300 | — |
| `ShellGainPct` ✅ | share of loot Shells | 0 | Flat (S6.4: a share, so it adds as Flat on a 0 base) | 0 | +15% | Quartermaster Shell Pouch (+2% a rank, 5 ranks = +10%), specialties; fractions round up by chance (`LootService`) |
| `LootMagnetRadius` | studs | 10 | Flat, AdditivePct | 6 | 24 | specialties |
| `CrabCount(night)` | int | `nightPlan` | Multiplier | — | `MAX_CREATURES` | Spring tide (+40% at −20% HP) |
| `CreatureHealthMult` | × | 1 | Multiplier | 0.5 | 2 | Spring tide, Long Voyage |

## Night plan (pure, R1.2) — must reproduce today's numbers exactly
```
growth(n) = min(n-1, GROWTH_FULL_UNTIL-1) + max(0, n-GROWTH_FULL_UNTIL) × GROWTH_LATE_RATE
crabs(n)  = (CRABS_BASE + CRABS_PER_NIGHT × growth(n)) × (final ? 1.5 : 1) × forecastCrabMult
skitters(n, crew) = (SWARM_BASE + SWARM_PER_NIGHT × growth(n)) × SWARM_BY_CREW[crew] × forecastMult
boss(n)   = per VoyageDefinition schedule; count = crew size 1..4 (S6.1, implemented: WaveDirector.bossBearings, evenly spread bearings)
slots     = small creatures + bosses × BOSS_SLOTS (5) ≤ MAX_CREATURES (45); bosses always arrive, small ones wait (S6.1)
```
Reference table (crew 4, no forecast): night 1 → 14 / 42 · 4 → 34 / 82 · 7 → 46 / 106 · 10 → 58 / 130 · 13 → 70×1.5=105 / 154.

## Pearl rules (pure, R1.2 / S2.2)
`pearlsFor(nightsSurvived, won, def) = nightsSurvived × PEARLS_PER_NIGHT + (won and PEARLS_VICTORY_BONUS or 0)` → Standard win 12, Long win 18. Dawn banking (S2.2, implemented): `Voyage.dawnPearls(n)` = `PEARLS_PER_NIGHT` (+ the legacy step × n) per `NightSurvived`; Results pays `Voyage.resultPearls` = `pearlsFor − banked` (the victory bonus on a win). Boss drops: 50% chance of 2–4, unchanged.

## Caps (owner policy)
Permanent Quartermaster boosts total ≤ +15% across Shells/speed/damage (D-pending S6.4). Specialties ≤ +10% each, one active. Voyage-only merchant boosts ≤ +25%, wiped at Results.
