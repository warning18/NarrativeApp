# Tower: trimming the dwarf and the elf with every unlock (Core)

The user's call: with every unlock the dwarf and the elf win the top far
more often than the human, the orc and the voidkin. Close the gap by
**trimming the two ahead**, without lifting the others, keeping the overall
top with every unlock at or a little below today's. With no unlocks the five
peoples are level and must stay so. The story's races are not touched.

Measured with the bot batch (`test/qa_tower_sim_test.dart --plain-name
batch`, live floor events, Heat 0) on seeds 1 to 2000 and 10001 to 12000,
on v2.9.0 (Heat merged, the cleric's retune in). The lifting alternative,
which was not taken, is `docs/simulation/tower-race-gap.md` on
`claude/core-races`.

## 1. Why the two lead

The only Tower start that differs by people is `towerPeoplePoints` (human
2, voidkin 3 points in the calling's damage stat), sized on the climb with
no unlocks. Flat damage points help most on the early floors. The dwarf's
health, constitution and armour, and the elf's dexterity, perception and
luck, help most in the long fights of floors 21 to 30. With every unlock
about 60% of runs reach floor 20, so those floors decide the top.

The share of runs that clear each stretch, every unlock, 4,000 seeds:

| | 1–10 | 11–20 | 21–29 (of those reaching 21) | floor 30 (of those reaching it) |
|---|---|---|---|---|
| dwarf | 93.4 | **63.3** | 57.9 | 80.2 |
| elf | 94.3 | 58.5 | **60.0** | **87.2** |
| human | 95.2 | 56.1 | 56.0 | 81.1 |
| orc | 92.1 | 55.0 | 54.3 | 80.8 |
| voidkin | 95.8 | 56.2 | 48.4 | 77.5 |

No single card favours them. Each group was removed in turn, with the
calling fixed (warriors and rangers, seeds 1 to 400 each, every people;
rangers alike). Taking out the start gear, the dice or the clans cost every
people points, and the dwarf and elf stayed ahead every time:

| Warriors, every unlock but … | dwarf | elf | human | orc | voidkin |
|---|---|---|---|---|---|
| nothing (all) | 34.0 | 40.0 | 24.5 | 20.8 | 28.5 |
| the shield | 27.3 | 31.3 | 20.0 | 21.5 | 24.0 |
| the sword and the shield | 24.3 | 31.0 | 21.5 | 18.8 | 21.3 |
| the three dice | 26.5 | 33.5 | 18.8 | 18.0 | 22.5 |
| the three clans | 24.3 | 32.8 | 19.3 | 16.0 | 21.3 |

The shield row is the telling one. The shield and the sword share the
weapon slot, and `_wear` keeps the later of equal scores, so the shield is
never worn: removing it only removes what owning one more unlock gives,
3% max health (`towerHealthPerUnlock`) and, from 10 to 9 unlocks, one
potion a fight (`towerUnlocksPerPotion`). That alone costs the dwarf 6.7
and the elf 8.7 points, the human and the voidkin 4.5, the orc nothing
(each cell ±3.3 points). With all ten, `towerHealthPerUnlock` is ×1.30 max
health: the share that keeps a sturdy or a dodging hero standing through
the long fights, so it is the lever taken.

## 2. The change

`towerPeopleHealthPerUnlock` (`lib/data/tower/tower_tables.dart`): the
dwarf takes **.015** of max health per unlock (×1.15 with every unlock) and
the elf **.01** (×1.10), in place of `towerHealthPerUnlock` .03 (×1.30).
`towerHealthPerUnlockOf(raceId)` reads it, and `towerFreshHero`
(`tower_hero.dart`) uses it, so every rebuild of the hero (the app's and
the bot's) gets it. It scales with the unlocks owned, so a run with few
unlocks is barely touched, and with no unlocks nothing changes.

Tried and set aside:
- dwarf and elf both .015: dwarf 23.6, elf 25.9 (spread 5.7 over 4,000
  seeds).
- dwarf .015, elf 0: elf 21.4 (−7.5), too much.
- dwarf and elf −1 point in the damage stat with every unlock: dwarf 21.7,
  elf 22.7, overall top 22.2%. A step at ten unlocks, and it costs the dwarf
  more than needed.
- dwarf .015, elf .0075: elf 22.8, overall 22.6%.

## 3. Before and after (top %, every unlock)

| People | 1–2000 before | after | 10001–12000 before | after | 4,000 seeds before | after |
|---|---|---|---|---|---|---|
| dwarf | 29.4 | 25.5 | 25.6 | 21.9 | 27.5 | **23.6** |
| elf | 31.6 | 24.9 | 26.3 | 22.2 | 28.9 | **23.5** |
| human | 24.4 | 24.4 | 24.1 | 24.1 | 24.3 | 24.3 |
| orc | 24.2 | 24.2 | 19.8 | 19.8 | 22.2 | 22.2 |
| voidkin | 19.9 | 19.9 | 20.5 | 20.5 | 20.2 | 20.2 |
| spread | 11.7 | 5.6 | 6.5 | 4.3 | 8.7 | **4.1** |

A people's runs number about 400 per seed set, so each figure carries about
±2 points. The human, orc and voidkin rows are identical: a people's runs
read only its own numbers. The voidkin is now the low end (20.2%). Lifting
it is the other branch's lever and was not part of this ask.

| Every unlock | 1–2000 before | after | 10001–12000 before | after | 4,000 seeds before | after |
|---|---|---|---|---|---|---|
| overall top | 25.85% | **23.80%** | 23.35% | **21.75%** | 24.60% | **22.77%** |
| median floor / floor 20 | 22 / 61.8% | 21 / 58.8% | 21 / 61.1% | 21 / 58.9% | 22 / 61.4% | 21 / 58.8% |
| floor-30 loss | 17.1% | 17.2% | 19.8% | 21.1% | 18.4% | 19.1% |
| worst ordinary floor | f26 7.2% | f26 7.3% | f27 7.6% | f27 7.8% | f26 7.1% | f26 7.4% |

The overall top with every unlock falls 1.8 to 2.0 points, which is what
trimming two of the five peoples costs. On the 500 guard seeds it is 21.2%
(106 runs), inside QA's `_topAll` band (0.18 to 0.32).

No unlocks: identical on both seed sets (top 11.10% and 10.75%; over 4,000
seeds dwarf 12.8, elf 11.5, human 10.9, orc 7.9, voidkin 11.6; median floor
17; floor-30 loss 27.9%; worst ordinary floor f26 12.3%).

## 4. The bot against real play

QA's real-fight sample (`docs/qa/tower-real-fight-2.8.1.md`, #1165) found
the bot about right for a casting mage and about 19 points optimistic for
warriors and rogues, which have no spell to add. The same split (4,000
seeds, every unlock):

| | dwarf | elf | human | orc | voidkin |
|---|---|---|---|---|---|
| casters (cleric, mage), before | 27.8 | 21.9 | 21.6 | 20.4 | 18.4 |
| casters, after | 23.8 | 18.9 | 21.6 | 20.4 | 18.4 |
| non-casters (warrior, rogue, ranger), before | 27.2 | 33.9 | 26.1 | 23.4 | 21.4 |
| non-casters, after | 23.5 | 26.9 | 26.1 | 23.4 | 21.4 |

- **The dwarf** led on both sides, so its trim falls where the bot is
  trustworthy too. It is now level with the human.
- **The elf's** lead was all in the non-caster cells, where the bot is
  optimistic (the elf warrior was the single highest cell, 47.5%). Among the
  casters it was already level with the human. The trim is per people, so
  the elf's casters pay too (21.9 → 18.9%, level with the voidkin). If hand
  tests find the elf mage or cleric weak, the elf's share can go back to
  .015 (elf 25.9% overall, spread 5.7).

## 5. Tests

- `test/tower_engine_test.dart`: `towerPeopleHealthPerUnlock`,
  `towerHealthPerUnlockOf`, and a fresh hero's max health with 0, 1, 5 and
  every unlock for each people (the dwarf ×1.15, the orc ×1.30 with all).
- `test/qa_tower_live_pin_test.dart` (QA's file): every unlock's pin re-set,
  124 / 308 / 10862 to 106 / 294 / 10548; no unlocks unchanged.
