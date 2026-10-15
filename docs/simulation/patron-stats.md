# The patron's passive stats (v5.2 step 5)

Each level reached, your **patron** adds to your stats, on top of the level's +20 health and the 5 training points (`lib/data/patron_stats.dart`). Your patron is the sworn clan, or else the main clan you stand best with at Friendly or better.

| Standing with your patron | Each level |
|---|---|
| Friendly, Friend | +1 to its first stat |
| Trusted | +1 to its first stat and its second in turn (the second on even levels) |
| Sworn | as Trusted, and +2 max health |

| Clan | First stat | Second stat |
|---|---|---|
| Dominion | Strength | Charisma |
| Vigil | Constitution | Perception |
| Compact | Constitution | Strength |
| Mire | Dexterity | Luck |
| Crows | Strength | Dexterity |
| Penitents | Wisdom | Intelligence |

- **One patron at a time:** gains don't stack across clans. Points already given stay.
- **The Open Hand**, once its banner is raised, adds +1 to your strongest stat.
- **Where it shows:** each level-up adds a line to the clan log, for example "Patron's favour · The Lantern Dominion: +1 Charisma".

## Measured

- **Setup:** `PATRON_RUNS=200 flutter test test/patron_stats_test.dart`. 200 runs across the four strategies and all professions, with the passives off and on.
- **Grouping:** each row is the patron the run ended with; the run count is in brackets.

| Patron | Off | On |
|---|---|---|
| All | 61.4% | 64.0% |
| Compact | 68.5% (55) | 71.4% (46) |
| Crows | 66.0% (24) | 70.4% (28) |
| Dominion | 52.6% (35) | 55.8% (29) |
| Mire | 62.0% (11) | 75.4% (17) |
| Penitents | 62.7% (28) | 59.3% (35) |
| Vigil | 55.1% (47) | 56.5% (45) |

- **Overall:** +2.6 points of fights won.
- **The Mire's +13** rests on few runs, so treat it as noisy.
- **The Penitents' Wisdom and Intelligence** pay out only in a caster's spells. The manager kept them as they are.
- **The spread between patrons** comes from which runs end with which patron. It is there with the passives off too.

**Why one point a level.** As first designed (+1 to both stats from Trusted, +5 max health at Sworn), the late bosses were won 13 to 16 points above their curve: the White Admiral 61% against 45%, and the three claimants 53 to 56% against 40%. Most of that came from the Sworn health. One point a level with +2 health keeps every boss on its curve (boss_balance_test).
