# Tower: the cleric's wardens and bosses (Core)

The user's ask: with every unlock the cleric won the top less often than any other calling (13.3% against 24.0 to 28.9%), so buying it for 15 marks made a run weaker. The goal is to bring the cleric into the other callings' range without moving them or the overall bands.

All numbers come from the bot batch on main v2.8.1 (`test/qa_tower_sim_test.dart --plain-name batch`, live floor events), on seeds 1 to 2000 and 10001 to 12000. With no unlocks the cleric is not drawn, so the "none" case is identical before and after.

## 1. Why

The cleric's foes are scaled ×1.28 (`towerProfessionScale`, set in v1.848 when the cleric healed itself through every fight and won half the runs with every unlock). Since then the heal between floors fell to 15% of max health, the heal cards went, and the climb got harder. The ×1.28 still fits the ordinary floors: the cleric loses them as rarely as the others. It does not fit the long fights. The share of fights lost, with all unlocks, over 4,000 seeds:

| Calling | Ordinary 1–9 | Ordinary 11–19 | Ordinary 21–29 | f15 warden | f20 boss | f25 warden | f30 boss |
|---|---|---|---|---|---|---|---|
| cleric (before) | 0.4 | 4.2 | 5.5 | 14.3 | 30.6 | 20.5 | 40.1 |
| mage | 0.8 | 6.2 | 6.1 | 4.6 | 5.7 | 8.5 | 12.7 |
| ranger | 0.5 | 4.3 | 4.5 | 6.3 | 14.9 | 5.5 | 16.3 |
| rogue | 0.5 | 3.5 | 5.3 | 8.3 | 11.4 | 12.4 | 24.1 |
| warrior | 0.1 | 4.2 | 6.5 | 6.4 | 7.7 | 8.3 | 10.2 |

(Other callings' columns are from seeds 1 to 2000.) A warden or boss has several times an ordinary foe's health, and phases that cleanse and heal. The cleric deals the least damage, so those fights last longest. At ×1.28 the boss's damage over that many rounds outlasts the cleric's heals and potion. The cause is the number, not the bot: the same bot heals the cleric well enough to win the ordinary floors as often as anyone.

## 2. The change

A new Tower-only table, `towerProfessionPeakScale` (`lib/data/tower/tower_tables.dart`): the cleric's foes are scaled **×1.08 on the warden and boss floors** (5, 10, 15, 20, 25, 30). On ordinary floors they stay at ×1.28. `TowerFloor.extraFor` (`tower_floors.dart`) reads it on any floor that is not an ordinary fight. The app's fight (`modifiersFor`) and the bot read the same value. No other calling has an entry, the story's cleric and `assets/gamedata/` are not touched, and no story run reads the table.

Scales tried (cleric's top with all unlocks, over 4,000 seeds): ×1.00 30%, ×1.05 29.4%, ×1.06 28.2%, ×1.07 27.5%, ×1.075 27.7%, **×1.08 22.8%**, ×1.10 22.4%, and ×1.10 on every floor 33.2% (seeds 1 to 2000; it makes the ordinary floors too easy). Between ×1.075 and ×1.08 the floor-20 boss (claimant_morrow) crosses a rounding step: the cleric loses there 9% of the time below it, 18% above it. So the cleric's top lands either at about 23% or at about 27.5%, with nothing in between. The lower step was picked because:
- it matches the mage, the other caster (23.1%), whose bot numbers QA's real-fight sample confirms;
- the bot is optimistic for the non-casters (next section), so the warrior's and ranger's 27 to 29% are probably above what players reach.

## 3. Before and after (all unlocks)

| | Seeds 1–2000 before | after | Seeds 10001–12000 before | after |
|---|---|---|---|---|
| **cleric top** | 13.3% | **23.8%** | 11.1% | **22.0%** |
| mage | 24.0% | 24.0% | 22.3% | 22.3% |
| ranger | 28.6% | 28.6% | 25.1% | 25.1% |
| rogue | 24.8% | 24.8% | 20.3% | 20.3% |
| warrior | 28.9% | 28.9% | 28.5% | 28.5% |
| cleric's floor-30 loss | 43% (n 89) | 20% (n 114) | 37% (n 78) | 19% (n 120) |
| overall top | 24.05% | 26.05% | 21.20% | 23.60% |
| floor-30 loss, all callings | 20.0% | 16.8% | 22.1% | 19.5% |
| median floor / floor 20 | 21 / 60.6% | 22 / 61.8% | 21 / 58.4% | 21 / 60.0% |
| worst ordinary floor | f26 6.6% | f26 6.8% | f27 7.5% | f27 6.7% |

No unlocks: unchanged on both seed sets (top 11.15% and 10.80%, median 17, worst ordinary floor f26 12.5% / 13.0%). The other callings do not move by a single run. The overall top with every unlock rises by about 2 points because a fifth of the runs are clerics. It stays inside QA's band (`_topAll` 0.18 to 0.32). The cleric still loses the floor-20 boss more often than the others (18% against 6 to 15%).

## 4. The bot against real play

QA's real-fight sample (`docs/qa/tower-real-fight-2.8.1.md`, PR #1165) found that when spells are cast, the bot reads the mage within about 3 points of real play (86.8% against 83.3%). It reads the warrior and the rogue about 19 points high (96.8% against 77.5%), because they cannot add a spell and the bot plays their dice better than the sample's player. The cleric is a caster and a healer. A player who times Mending Light and Purge should do at least as well as the bot, so the bot is unlikely to over-rate the cleric. If anything, the real cleric sits above the real warrior and rogue, which is why the lower of the two steps was chosen. The cleric was not in QA's sample, and an 8-fight cleric row on floors 20 and 30 would confirm this. No bot bug was found for the cleric.

## 5. Tests

- `test/tower_events_test.dart`: the cleric's peak scale on the wardens' and bosses' floors only, and no other calling's.
- `test/qa_tower_live_pin_test.dart` (QA's file): every unlock's pin re-set, 128 / 305 / 10799 to 144 / 314 / 10984; no unlocks unchanged.
