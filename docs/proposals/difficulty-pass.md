# Difficulty pass: make gear and dice matter (proposal, v1.597)

The user asked to "decrease HP and strength numbers and adapt the overall
difficulty. It doesn't seem for now that the user struggles or really needs
to equip or change their dice."

**This is a proposal only; nothing is changed yet.** The build comes after
the user's OK, as v1.597.0+633.

## In plain words (for the user)

- **Today the fights are won by your companions.** With two or three
  companions in the party, the simulator wins 98–100% of fights from chapter
  3 on, whatever die it rolls. Your companions take most of the blows and keep
  growing with your level.
- **A loss costs almost nothing.** A lost fight heals you to full and still
  gives 30% of its experience.
- **The numbers balloon.** By chapter 6 a common foe has about 500 health and
  a boss about 700, while your hits do about 20. The fights stay winnable
  only because enemy damage grows slowly.

The proposal:

1. **Smaller numbers on both sides.** Foes get about 40% less health, and you
   gain less health per level, so a fight is 150–250 health against your
   15–25 damage, not 500.
2. **Companions help but don't carry.** They grow more slowly and take fewer
   blows, and the foe aims at you at least half the time.
3. **The right die wins.** Almost every foe from chapter 2 on (70 of 78) has
   a weakness and most have a resist. A hit on the weakness goes from ×1.5 to
   ×2, and a resisted hit stays at ×0.5. The starter die has no element, so
   it is never the best choice after chapter 2.
4. **Gear counts more.** Weapon damage and armor weigh more, because your own
   base numbers are smaller.
5. **The target.** Take a hero with companions who keeps the starter die and
   wears nothing new. From chapter 3 that hero wins only about half of the
   fights at the first try and dies more often. The same hero who swaps to the
   right die and wears the loot wins about 80–85%. Chapter 1 stays as it is,
   because it is the tutorial.

## 1. Where the numbers are today

### Hero

- Starts with 20 HP, plus the race and profession bonuses (Warrior +5, Cleric
  +7, Dwarf +4).
- Each level gives +4 max HP (`levelHealthGain`, `lib/combat/stat_rules.dart`)
  and one stat pick.
- One point of CON is +5 HP (`healthPerConstitution`). One point of the damage
  stat is +1 base damage.
- A hit does base damage + the face value + flat gear bonuses, then is ×1.5
  on a weakness or ×0.5 on a resist (`lib/combat/enemy_intent.dart`).

| Level (Warrior, Human) | HP, STR picks | HP, CON picks | Damage, STR picks |
|---|---|---|---|
| 5 | 41 | 61 | 6 |
| 10 | 61 | 106 | 11 |
| 20 | 101 | 196 | 21 |

### Enemies

Enemy stats go through `fight_setup.dart` and `combat_engine.dart`:

- HP is multiplied by (1 + 0.16·(L−1)), then by a chapter floor (regular foes
  1.36 → 3.17, bosses 1.21), then by the chapter (+15% each) and by the zone
  tier (+10% each).
- Damage is multiplied by (1 + 0.08·(L−1)), then by its own floor (1.25 →
  2.40).

Median foe at the usual level for each chapter:

| Chapter (level) | Regular HP / dmg | Boss HP / dmg |
|---|---|---|
| 3 (5) | 185 / 12 | 92 / 7 |
| 4 (9) | 301 / 19 | 184 / 13 |
| 5 (12) | 422 / 21 | 277 / 13 |
| 6 (16) | 503 / 22 | 472 / 20 |
| 7 (19) | – | 716 / 19 |

### Companions

- They use the presets of their race and profession.
- HP is multiplied by (1 + 0.12·(L−1)) and damage by (1 + 0.08·(L−1)), times
  the approval tier (devoted 110%).
- A foe picks a target among the members at random, and the one with the
  biggest Defend block draws the blows.

### What the simulator says

From `competent-player-v1.564.md` and `companions-v1.568.md`, encounters won
within 3 tries, chapters 3–8:

| Profile | Won |
|---|---|
| Naive: keeps the starter die, wears almost nothing | about 0.62 |
| Competent: best die and gear, no companions | about 0.88 |
| Competent with companions: what a real player does | **0.98–1.00** |

The gap the user wants, ignoring the gear against adapting, exists only
without companions. With them it vanishes: the starter die and the right die
both win.

### Healing

- A loss heals to full and gives 30% of the XP.
- A level-up heals to full, and so does a camp rest.
- A win heals nothing (HP carries over).
- A potion heals 6.

## 2. What I would change

All of these are numbers in Core's files. There is no new screen and no save
change.

| # | Change | From | To | Where |
|---|---|---|---|---|
| A | Hero HP per level | +4 | +3 | `stat_rules.dart` `levelHealthGain` |
| A | HP per CON point | +5 | +3 | `stat_rules.dart` `healthPerConstitution` |
| B | Regular foe HP floors, ch2–8 | 1.80 / 3.02 / 3.02 / 3.17 / 2.36 / 2.28 / 2.22 | about ×0.6 each (1.10 / 1.80 / 1.80 / 1.90 / 1.45 / 1.40 / 1.35) | `combat_engine.dart` floors |
| B | Foe HP per level | +16% | +12% | `enemyHealthPerLevel` |
| B | Boss HP floor | 1.21 | 1.0 (re-pinned per boss by the band) | `combat_engine.dart` |
| C | Foe damage | unchanged | unchanged (it now hits a smaller HP pool, so each blow weighs more) | – |
| D | Weakness | ×1.5 | **×2.0** | `enemy_intent.dart` |
| D | Resist | ×0.5 | ×0.5 (unchanged) | – |
| E | Companion HP per level | +12% | +8% | `scaledMaxHealth` for allies |
| E | Companion damage | ×1.0 | ×0.8 | `fight_setup.dart` ally setup |
| E | Who the foe hits | random member | the hero at least 50% of blows; the rest at random (Defend still draws) | `fight_rounds.dart` + `sim_combat.dart` |
| F | Potion heal | 6 | 8 (the hero's pool is smaller, but a potion still matters) | `item_stats.dart` |
| G | Chapter 1 | – | untouched (its floors, Aurel Vane, the tutorial fights) | – |

**Left out on purpose:**

- The hero's base damage. Gear and the die carry it, as they should.
- The lost-fight full heal and its 30% XP. Taking that away would change
  permadeath and saves. It can be a second step if the user still finds fights
  free.

## 3. The target, and how it is checked

**A new simulator profile, `stubborn`:** the competent player with its
companions, but it keeps the starter die and its starting gear.

| Chapters 3–8, encounters | Today | Target |
|---|---|---|
| Competent with companions: won at the first try | about 0.95 | **0.80–0.85** |
| Stubborn: won at the first try | about 0.95 (estimated) | **0.45–0.55** |
| Stubborn: won within 3 tries | about 0.99 | ≤ 0.80 |

It is measured like v1.564: 10 runs per profile, seed 7, about 10 seconds per
profile. **No large batch.**

**A new cheap guard, `test/adapt_gap_test.dart`:** it fights 6 set fights
from chapters 3–6, one per main element (a Light-weak void foe, an
Electricity-weak inquisitor, and so on), 60 tries each.

- With the starter die and starting gear, the hero must win at least 25
  points less than with the matching die and the chapter's loot.
- This pins what the user asked for, "you need to change your dice", in a test
  that takes seconds.

## 4. Tests that move

| Test | Today | What happens |
|---|---|---|
| `boss_balance_test` boss curve (naive, 400 runs) | targets 0.75 → 0.35 | Targets kept. Each boss's HP is re-sized (its `maxHealth` in `enemies.json`) until the naive player hits them again, as at #336. Aurel Vane is untouched. |
| `boss_balance_test` single fights (starter die, L3–L7) | 0.15–0.65 | Re-pinned to the new measures; the "L7 beats L4 by 15 points" check stays. |
| `boss_balance_test` professions within 8 points, each ≥ 60% | – | Checked. If the Cleric (most HP) falls behind, its +5 damage is reconsidered. |
| `clash_balance_test` | a gap between two rule sets | Should not move (both sides shift). Run once. |
| `chapter_one_fights_test` | ch1 | Should not move (chapter 1 is untouched). Run once. |
| `sea_beast_balance_test`, `ship_battle_balance_test` | ship fights | Not touched: ships have their own stats. |
| `sim_competent_test`, `sim_companions_test` | compare only | Kept. A `stubborn` case is added. |

Only these files run locally; CI runs the rest.

## 5. Order of the build

1. Changes A–F and the `stubborn` profile.
2. Measure the three profiles, 10 runs each.
3. Nudge B and E until the target holds.
4. Re-size the bosses for the curve.
5. Add `adapt_gap_test`, and write the measures in
   `docs/simulation/difficulty-pass-v1.597.md`.

Narrative's story data is untouched. If a quest's reward needs a number, I set
it as usual.
