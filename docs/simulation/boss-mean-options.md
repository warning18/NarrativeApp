# The boss mean after v1.500: two options

Since v1.500 the simulator keeps its risky gifts to the patron clan ([clan-power-50-v1.500.md](clan-power-50-v1.500.md)). On v1.501 the mean boss win rate is now 49.4 / 48.5 / 48.5 at seeds 7 / 11 / 23. It was about 52.9 before, and the design target is 50–52. `boss_balance_test`'s band (42–58) still passes. The Void Sovereign wins 29 / 25 / 26 against a floor of 23 (35 ± 12).

**How it was measured.** The method is the one in [difficulty-review.md](difficulty-review.md):

- **Bosses and professions:** `boss_balance_test`'s harness: 400 runs, goals random / favorGood / favorEvil / maximizeGold, professions in rotation, seeds 7, 11 and 23.
- **Champions:** `nemesis_quests_test`'s harness: 200 runs, seed 7, with champion fights.
- **Clash gaps:** `clash_balance_test`'s harness: 150 runs, seed 11.

Every candidate was run in full. Band = target ± 12. A cell marked * is outside its band.

## Option A: keep the numbers, move the target to about 48%

Nothing changes in the game. The note and the comment in `boss_balance_test` would say the mean sits near 48. The test bounds already allow that.

- **Hardest bosses:** Void Sovereign 25–29 (target 35), Claimant Morrow 31–36 and Tear-Herald 31–34 (targets 40 and 35), White Admiral 39–44 (45). All four are late bosses, so the end of the game gets steeper and the start does not change.
- **Void Sovereign margin:** 2 to 6 points above its floor (25 at seed 11). Any small data change that reshuffles the seeded stream could push it under 23 and turn CI red. Its band would then need widening or its own trim anyway.
- **Everything else holds:** profession spread 3.8–5.1, largest clash gap (chapters 2–8) 0.072, champions 46.7%.

## Option B: candidates that bring the mean back to 50–52

| Candidate | Change | Boss mean (7 / 11 / 23) | Every boss in band? | Void Sovereign | Prof. range | Largest clash gap | Champions |
|---|---|---|---|---|---|---|---|
| v1.501 (as is) | — | 49.4 / 48.5 / 48.5 | yes | 29 / 25 / 26 | 5.1 / 4.2 / 3.8 | 0.072 | 46.7 |
| B1 | `bossHealthBaseMultiplier` 1.21 → 1.17 | 54.5 / 51.6 / 50.3 | **no** (Inquisitor 68*, Tallis 52.2*) | 33 / 29 / 28 | 3.9 / 3.3 / 2.5 | 0.097 | 48.6 |
| B2 | `bossHealthBaseMultiplier` 1.21 → 1.15 | 53.3 / 52.8 / 52.2 | **no** (Inquisitor 68*) | 32 / 29 / 35 | 2.9 / 3.4 / 2.4 | **0.101** | 51.3 |
| B3 | Sovereign 77 → 70, Tear-Herald 58 → 53, Morrow 121 → 110 | 50.4 / 50.4 / 49.5 | yes | 33 / 35 / 31 | 4.9 / 4.1 / 4.2 | 0.088 | 46.7 |
| **B4** | **Sovereign 77 → 66, Tear-Herald 58 → 52, Morrow 121 → 108** | **51.1 / 50.9 / 50.3** | **yes** | **40 / 39 / 38** | **5.0 / 4.0 / 4.2** | **0.084** | **46.7** |
| B5 | B3 + White Admiral 72 → 66 | 51.4 / 51.4 / 50.8 | yes | 31 / 33 / 34 | 4.9 / 4.3 / 3.8 | 0.056 | 46.7 |
| B6 | B4 + White Admiral 72 → 67 | 52.1 / 51.9 / 51.0 | yes | 39 / 38 / 36 | 4.8 / 4.3 / 4.1 | 0.058 | 46.7 |

The B3–B6 changes are base `maxHealth` values in `assets/gamedata/enemies.json`. Bounds: profession range ≤ 8, clash gap ≤ 0.10 for chapters 2–8, champions ≥ 38.

**The global multiplier fails.** Every boss gets easier, including the early ones that were already over target. The Hollow Court Inquisitor goes past 67 at seed 11, and the reshuffled stream sends a claimant (Tallis) past 52 at seed 7. With 1.15 the clash gap for chapter 7 also goes over 0.10. Seed 7's mean overshoots too (53–54.5).

**The per-boss trims leave chapters 1–6 untouched.** Those bosses keep exactly the same numbers, because the stream only diverges where the trimmed bosses are met (chapters 7–8). Champions don't change either.

### Per-boss win %, recommended B4 (v1.501 → B4)

| Boss | Target (band) | Seed 7 | Seed 11 | Seed 23 |
|---|---|---|---|---|
| Aurel Vane | 75 (63–87) | 79 → 79 | 83 → 83 | 83 → 83 |
| Void Stalker | 65 (53–77) | 69 → 69 | 68 → 68 | 64 → 64 |
| Hollow Court Inquisitor | 55 (43–67) | 62 → 62 | 62 → 62 | 63 → 63 |
| Bone Warden | 55 (43–67) | 56 → 56 | 55 → 55 | 54 → 54 |
| Void Archon | 50 (38–62) | 54 → 54 | 55 → 55 | 56 → 56 |
| White Admiral | 45 (33–57) | 39 → 39 | 39 → 39 | 44 → 44 |
| Claimant Vane | 40 (28–52) | 44 → 44 | 39 → 39 | 40 → 40 |
| Claimant Tallis | 40 (28–52) | 41 → 41 | 41 → 41 | 42 → 42 |
| Claimant Morrow | 40 (28–52) | 36 → 41 | 34 → 42 | 31 → 34 |
| Tear-Herald | 35 (23–47) | 34 → 38 | 32 → 37 | 31 → 36 |
| Void Sovereign | 35 (23–47) | 29 → 40 | 25 → 39 | 26 → 38 |
| **Mean** | 50–52 | 49.4 → 51.1 | 48.5 → 50.9 | 48.5 → 50.3 |

Encounters won within 3 tries, by profession, with B4:

| Seed | Warrior | Mage | Rogue | Cleric | Ranger |
|---|---|---|---|---|---|
| 7 | 64.5 | 68.0 | 69.0 | 69.6 | 66.9 |
| 11 | 68.0 | 69.7 | 66.4 | 65.6 | 68.6 |
| 23 | 65.2 | 66.5 | 68.4 | 67.4 | 64.2 |

## Recommendation

**B4.** It is one knob: a health trim on the three lowest late bosses. It puts the mean at 50.3–51.1 at every seed, inside 50–52, and moves no boss before chapter 7. The Void Sovereign goes to 38–40, 15 or more points off its floor and a little over its 35 target. Tear-Herald (36–38) and Morrow (34–42) end near their targets. The profession spread, clash gaps and champions all stay well inside their bounds.

B6 adds a White Admiral trim (39 → 43–51, nearer its 45). Seed 7's mean goes to 52.1, just over the target band, so it is only worth it if the Admiral's 39 bothers the user. B5 does the same with the milder B3 trims, but leaves the Sovereign at 31–34.

If B4 ships, the change is three `maxHealth` values in `enemies.json` (Core's file). No test bound needs to change.
