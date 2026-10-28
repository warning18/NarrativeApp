# Difficulty pass: make gear and dice matter (proposal, v1.597)

The user asked to "decrease HP and strength numbers and adapt the overall
difficulty. It doesn't seem for now that the user struggles or really needs
to equip or change their dice."

**Built as v1.597.0+633, without E.** The user's answers: 1 OK (A, B, C),
2 not OK (E dropped: companions stay as they are), 3 OK (D), 4 OK (F),
5 OK (target, G). §6 says what was built and what the simulator measured.

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
2. ~~**Companions help but don't carry.**~~ **Dropped by the user:**
   companions stay as they are.
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
| E (dropped) | Companion HP per level | +12% | +8% | `scaledMaxHealth` for allies |
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

## 6. What was built (v1.597), and what it measured

E was dropped. The rest of the proposal was built, with two numbers moved
from §2, as the measures below show.

**Built:**

| # | Change | Built |
|---|---|---|
| A | Hero HP per level / per CON point | 4 → 3 / 5 → 3 |
| B | Regular foe HP floors, ch2–8 | ×0.9 each (1.62 / 2.72 / 2.72 / 2.85 / 2.12 / 2.05 / 2.00), not ×0.6 |
| B | Foe HP per level | kept at +16%, not 12% |
| B | Boss HP floor | 1.21 → 1.13 |
| C | Foe damage | unchanged |
| D | Weakness | ×1.5 → ×2 (and the fight card says ×2) |
| F | Potion | heals 6 → 8 |
| G | Chapter 1 | floors untouched; Aurel Vane 22 → 29 HP to keep its 75% |

**Re-sized for the bands:**

- Bosses: Void Stalker 34 → 38 HP and White Admiral 72 → 62 HP; the clans'
  champions 43–45 → 36–38 HP (their curve, about half won, holds).
- Professions:
  - warrior health +5 → +9;
  - rogue +3 → +6;
  - ranger 0 → +3;
  - cleric damage +5 → +4.
- The profession changes keep the five professions within 8 points of each
  other: they now sit within about 4.

**Why not ×0.6.** With ×0.6 floors and +12% a level, every fight got much
easier:

- the naive player rose from 0.62 to 0.82 won in chapters 3–8;
- the stubborn player rose from 0.80 to 0.97 at the first try.

The hero's smaller health did not make up for foes with 40% less. ×0.9 with
+16% keeps the naive player where it was, with smaller numbers on both
sides.

**The simulator** (10 runs per profile, seed 7, as v1.564: the five
professions twice, 5 random and 5 favour-good walks, with `skill_merges` and
`companions`). Chapters 3–8 encounters:

| Profile | Before: won / 1st try | v1.597: won / 1st try |
|---|---|---|
| Naive (no companions, starter die, wears little) | 0.62 / 0.40 | 0.59 / 0.42 |
| Stubborn (companions, starter die, starting gear) | 0.93 / 0.80 | 0.92 / 0.81 |
| Competent (companions, best die and gear) | 0.99 / 0.96 | 1.00 / 0.99 |

**The target is not met, because the companions carry the fights.** The
stubborn player still wins about 81% at the first try, against 45–55% asked.

- The gap between it and the competent player is 18 points, up from 16.
- The ×2 weakness widens it, but two or three companions win the fight
  whatever die the hero rolls.

**A solo check** (one hero alone at the chapter's level, no gear, 60 fights
each):

- **Chapters 3–6:** the hero loses almost every fight with any die. Without
  gear and companions these fights are beyond a hero alone.
- **Where it is close, the right die decides.** Against the Void Wisp (weak
  to Light, chapter 3):

| Hero | Starter die | Pilgrim die (Light) | Pilgrim die, elements stripped |
|---|---|---|---|
| Warrior | 0.10 | 0.30 | 0.02 |
| Cleric | 0.40 | 0.83 | 0.57 |

So the drafted guard (`adapt_gap_test`) is not added yet. A solo hero
without gear loses whatever the die, so it has nothing to pin. It waits for
the user's choice below.

**The two options for the user (§7).**

## 7. Options for the companions (the user's choice)

1. **Stronger foes, the same companions.** Foes in a party fight grow with
   the party's size: each seated companion adds about +35% health and +20%
   damage to the foes. The fight a hero meets alone stays as it is. The
   companions keep their numbers, but they no longer win the fight for you,
   so the right die and gear decide it again.
2. **A milder companion change.** Companions keep their health and damage,
   but the foe aims at the hero half the time (today it picks a party member
   at random, and the companions draw most blows). The hero's own health,
   die and gear then matter in every party fight. This is one rule, not the
   three changes of E.

Either is measured the same way (the stubborn profile toward 45–55% at the
first try) before the `adapt_gap_test` guard is added.

## 8. Re-measured: hero + Vica (the companion every hero now gets)

The user made Vica the companion every hero gets (see
`guide-dog-companion.md` §6). So the baseline is now "hero + Vica", and the
§7 question is re-asked on it.

**How it was measured:**

- One human hero per profession, alone or with Vica.
- No gear, at each chapter's usual level (5, 9, 12, 16).
- Six foes of chapters 3–6, each weak to an element: Void Wisp, Inquisition
  Auxiliary, Deaf Tove, Catacomb Ghoul, Drowned Pilgrim, Kraken Arm.
- 60 fights per cell, 1,800 per column, about a minute in all.
- "Matching die": a die carrying the foe's weak element (Pilgrim, Tempest,
  Tide, Flame), with the hero's skills placed on it the way the competent
  simulator places them.

| Won, chapters 3–6 | Alone, own die | + Vica, own die | + Vica, matching die |
|---|---|---|---|
| All professions | 0.06 | **0.34** | **0.22** |
| Warrior | 0.03 | 0.31 | 0.18 |
| Mage | 0.16 | 0.48 | 0.23 |
| Rogue | 0.05 | 0.40 | 0.18 |
| Cleric | 0.06 | 0.28 | **0.44** |
| Ranger | 0.01 | 0.20 | 0.08 |

**What it says:**

1. **Vica alone makes chapters 3–6 playable without gear:** 6% → 34%. Gear
   then decides the rest. Two foes (Deaf Tove at chapter 3, the Drowned
   Pilgrim at chapter 5) stay near 0 with no gear at all. That is the
   "you must equip" the user asked for.
2. **Swapping to the foe's weak element does not pay today. It costs.** The
   dice that carry an element carry it on only 1–2 of their 6–12 faces, and
   they lose the hero's own die, whose Skill faces hold the profession's
   skills. Only the cleric gains, because its own apprentice die is weak.
   The ×2 weakness (v1.597) is not enough on its own: too few hits carry the
   element.

**So the §7 question changes.** With Vica guaranteed and other companions
optional, the companions no longer carry every fight, so §7's two options
matter less. "Change your die for the foe" needs the dice themselves to
change. A third option, for the user:

3. **Make the element dice worth swapping in.** On each elemental die, the
   die's element goes on all its Attack faces, and on its Skill faces when
   their skill has none. Then most of its hits take the ×2 against a weak
   foe, and the ×0.5 against one that resists, so the wrong die costs too.
   - This is a data change in `dice.json` and touches no code.
   - It is measured the same way: a matching die should win clearly more
     than the hero's own die against a weak foe, and clearly less against a
     resisting one.

I recommend 3, with Vica as the baseline, before §7's options 1 and 2. I will
measure 3 here when the user picks it.
