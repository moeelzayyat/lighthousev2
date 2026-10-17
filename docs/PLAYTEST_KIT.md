# Playtest kit (S3.2 sessions and the S3 gate)

For the owner and anyone running a session on **Lighthouse Keepers DEV** (PlaceId 102473202766620). Production stays untouched (D-013). The S3 gate thresholds come from `ROADMAP.md` §5. This file replaces the old repo's kit, which was not brought over.

## 1. Session checklist (S3.2: 5+ sessions)
- 2–4 players per session. At least one plays on a **real phone** in every session.
- In at least one session, nobody explains anything ("no verbal help"). Watch and take notes only.
- Use accounts that have never played DEV whenever you can. A new account is on its first voyage, and the coach and Night-1 safety only show for it.
- Book about 45 minutes: joining, one full Standard voyage (7 nights), Results, and the Sail again choice.
- Before you start, note the date, the players, their devices and whether they had played before.
- After the session, fill in one observer sheet (§2) per player. Paste the Results screen or the run card into the sheet.

## 2. Observer sheet (one per player)
| Question | Answer |
|---|---|
| Player, device (phone model / PC / controller), played before? | |
| Seconds from spawn to boarding the ship (the coach points at the wheel when a first-timer is alone on the deck) | |
| Did they find the oil, the fuel tank and the lamp without help? Where did they get stuck? | |
| First beam hit: did they aim at creatures on purpose? | |
| **Used both beam modes on purpose** (switched to the focused beam for a big monster, wide for a swarm)? yes / no | |
| Survived Night 1? | |
| Took another role (oil runs, cannon, repairs, harpoon) without being told? Which? | |
| Moment of the storm on the Results screen: what was it, and who made it? | |
| Pressed **Sail again**? yes / no (if no: why they stopped) | |
| Highlight in their own words ("best bit was…") | |
| Confusing or annoying moments, in their own words | |
| Shop: bought or equipped anything? Any trouble with Buy → Confirm? | |
| Phone only: buttons easy to hit? any words cut off? smooth at night? | |

## 3. The S3 gate (final 7 days of the public test)
| Measure | GO when | Where it comes from |
|---|---|---|
| Night-1 survival, unassisted new accounts | ≥ 50% | Creator Hub → Analytics → Funnels → onboarding funnel: step 6 *Night1Survived* ÷ step 3 *Landed* (new players) |
| Sail again / rematch | ≥ 60% of finished voyages | Funnel step 9 *SailAgain* ÷ step 8 *VoyageEnded* |
| Both beam modes used on purpose | ≥ 70% | Observer sheets (§2). Supporting number: custom event *BeamModes* with value `both` ÷ all *BeamModes* events |
| First-play bounce | lower in week 2 than in week 1 | Creator Hub session length for new players, and custom event *Left* (phase, night) |
| Oil or cannon moment named as a highlight | at least one tester | Observer sheets |
| S3.5 role check: a non-Keeper made the moment of the storm | ≥ 30% of voyages | Custom event *MomentKind*: `oil` + `weapon` + `cannon` ÷ all (`beam` is the Keeper's; `crew` is no single player) |
| S3.1b mode test | the winner becomes the default | Custom events *ModeArm* and *VoyageMode* (nights reached per arm), and Sail again per arm |

**NO-GO (back to S2):** Night-1 survival < 30% after two improvement passes, or rematch < 40%. **Shelve review:** most testers still don't understand the beam after two passes.

## 4. Real-phone checklist (also V8)
- Phone model and graphics quality (Automatic unless changed).
- Night 1 and a big-monster night: smooth, a little choppy, or bad? Did the phone get hot?
- Shop and workbench: every button easy to hit; no cut-off words.
- HUD: nothing covered by the thumb controls or the notch.

## 5. What to send Claude
The observer sheets (photos are fine), the Creator Hub numbers from §3 for the week, and anything a tester said that surprised you. Claude turns them into the weekly change (S3.3) and the written review (S3.4).
