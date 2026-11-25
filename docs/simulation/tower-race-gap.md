# Tower: the peoples' gap with every unlock (Core)

The user's ask: with no unlocks the five peoples win the top about as often as each other (9.7 to 12.7%). With every unlock, human (20.5%) and voidkin (19.4%) fell well behind dwarf (28.9%) and elf (28.5%). The goal is to bring all of them within about 4 points of each other with every unlock, and to leave the no-unlock case level.

This is measured with the bot batch (`test/qa_tower_sim_test.dart --plain-name batch`, live floor events) on seeds 1 to 2000 and 10001 to 12000, on top of the cleric's retune (`claude/core-cleric`, `docs/simulation/tower-cleric-retune.md`). That retune is the "before" below; it lifted every people's cleric, so the orc and the voidkin had already moved.

## 1. Why

The only Tower start that differs by people is `towerPeoplePoints`: 2 points for humans and 3 for voidkin in the calling's damage stat. It was sized in v1.922 on the climb with no unlocks, where the median run ends on floor 17 and few runs see floor 21. Flat damage points pay off early, while the dwarf's health, constitution and armour, and the elf's dexterity, perception and luck, keep paying on the long fights at the top. The share of runs that clear each stretch, over 4,000 seeds:

| | Floors 1–10 | 11–20 | 21–30 (of those reaching 21) |
|---|---|---|---|
| no unlocks: dwarf / elf | 79.8 / 82.2 | 45.3 / 45.2 | 32.2 / 34.2 |
| no unlocks: human / voidkin | 84.3 / 88.2 | 45.5 / 43.8 | 26.2 / 30.6 |
| every unlock: dwarf / elf | 93.0 / 94.3 | 62.4 / 57.2 | 49.6 / 52.0 |
| every unlock: human / voidkin | 95.1 / 95.6 | 55.4 / 55.9 | 45.6 / 38.7 |

Humans and voidkin climb the first floors better, and the upper floors worse, in both cases. With no unlocks the early lead and the late loss cancel out in the top. With every unlock about 60% of the runs reach floor 20, so the upper floors decide the top and the gap shows.

No unlock alone causes it. Each group was removed in turn (the start dice, the start items, the three clans, the two callings, the health per unlock). The gap between dwarf/elf and the others stayed at 5 to 8 points every time, within the noise. The nearest candidate was the extra health (×1.3 with every unlock, which favours the dwarf), but with it removed the gap remained (about 21% for dwarf and elf against 16% for the others).

## 2. The change

`towerPeopleUnlockPoints` (`lib/data/tower/tower_tables.dart`): more points of the same start as the unlocks grow, **human +1, orc +1, voidkin +2** with every unlock owned. With fewer unlocks a share of those points is given, rounded down, so a voidkin gets its first point at 5 unlocks. `towerPeoplePointsOf` adds them to `towerPeoplePoints`. `towerFreshHero` (`tower_hero.dart`) reads it, and so does every rebuild of the hero (the app's and the bot's). With no unlocks nothing changes. The story's races are not touched.

Per-people effects are separable, because a people's runs read only its own points. With every unlock, +1 point gave human +3.0, orc +4.1 and voidkin +2.6 points of top; +2 points gave voidkin +6.5; and human +2 / voidkin +3 / orc +2 overshot (33.3 / 30.3 / 31.0%).

## 3. Before and after (top %, every unlock)

| People | 1–2000 before | after | 10001–12000 before | after | 4,000 seeds before | after |
|---|---|---|---|---|---|---|
| dwarf | 31.3 | 31.3 | 26.4 | 26.4 | 28.7 | 28.7 |
| elf | 30.5 | 30.5 | 25.6 | 25.6 | 28.0 | 28.0 |
| human | 21.7 | 26.8 | 26.4 | 27.1 | 24.0 | **27.0** |
| orc | 24.9 | 29.8 | 20.1 | 23.1 | 22.7 | **26.8** |
| voidkin | 22.2 | 26.6 | 19.3 | 27.7 | 20.7 | **27.2** |
| spread | 9.6 | 4.7 | 7.1 | 4.6 | 8.0 | **1.9** |

The user's numbers before the cleric retune (seeds 1 to 2000) were dwarf 28.9, elf 28.5, human 20.5, orc 23.3 and voidkin 19.4. A people's runs number about 400 a seed set, so each figure carries about ±2 points. On a single seed set the spread is still 4.6 to 4.7 points; pooled, it is 1.9.

| Every unlock | 1–2000 before | after | 10001–12000 before | after |
|---|---|---|---|---|
| overall top | 26.05% | **29.00%** | 23.60% | **26.05%** |
| median floor / floor 20 | 22 / 61.8% | 23 / 65.2% | 21 / 60.0% | 22 / 63.2% |
| floor-30 loss | 16.8% | 17.3% | 19.5% | 18.8% |
| worst ordinary floor | f26 6.8% | f26 6.6% | f27 6.7% | f27 7.0% |

No unlocks: identical (top 11.15% and 10.80%; per people dwarf 11.6, elf 12.7, human 10.0, orc 8.7, voidkin 11.8 over 4,000 seeds; worst ordinary floor f26 12.5% / 13.0%).

**The overall top with every unlock rises.** It was 24.05% before both fixes (seeds 1 to 2000), 26.05% after the cleric's, and 29.0% after this one. On the 500 guard seeds it is now 30.4% (152 runs), inside QA's `_topAll` band (0.18 to 0.32) but close to its top: the next buff to unlocked runs will cross it. The alternative was to take points from the dwarf and the elf, which keeps the overall top where it was. It was not tried, because the ask was to lift the runs that pay 15 marks for less.

## 4. The bot against real play

QA's real-fight sample (`docs/qa/tower-real-fight-2.8.1.md`, PR #1165) found the bot about right for a casting mage and about 19 points optimistic for warriors and rogues, which have no spell to add. Split the same way (4,000 seeds, every unlock):

| | dwarf | elf | human | orc | voidkin |
|---|---|---|---|---|---|
| casters (cleric, mage), before | 25.9 | 25.1 | 24.3 | 21.1 | 18.4 |
| casters, after | 25.9 | 25.1 | 26.9 | 25.9 | 21.5 |
| non-casters (warrior, rogue, ranger), before | 30.7 | 30.1 | 23.9 | 23.8 | 22.3 |
| non-casters, after | 30.7 | 30.1 | 27.0 | 27.3 | 31.2 |

On the casters, the cells where the bot is trustworthy, the human was already level with the dwarf and elf. Its gap was all in the non-caster cells, where the bot is optimistic, so part of the human's gap may come from the bot. It gets the smallest lift (+1). The orc and the voidkin were behind on both sides. The voidkin's lift lands mostly on its non-casters (31.2%, the highest cell after the change), and its mage stays at 17.9% whatever its points. If the hand tests find the voidkin warrior or ranger too strong, the voidkin's +2 can go back to +1 (23.3% overall, still within 5.4 points of the dwarf).

## 5. Tests

- `test/tower_engine_test.dart`: `towerPeoplePointsOf` (shares, rounding, every unlock) and a fresh hero's damage stat with every unlock.
- `test/qa_tower_live_pin_test.dart` (QA's file): every unlock's pin re-set, 144 / 314 / 10984 to 152 / 332 / 11259; no unlocks unchanged.
