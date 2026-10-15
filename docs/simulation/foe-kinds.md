# What a foe is, and the rules by foe

Every enemy now has a `kind` in `enemies.json`, from Narrative's reviewed `docs/proposals/foe-kinds.md`:

| Kind | Enemies |
|---|---|
| person | 41 |
| undead | 9 |
| void | 9 |
| beast | 4 |
| construct | 3 |
| demon | 2 |
| angel | 2 |
| giant | 1 |

The rules are in `lib/combat/foe_kind.dart`; the live fight and the simulator play them alike:

- **An Evil foe** (the Lantern Vanguard's heal) is the void, the undead or a demon. It no longer means anything weak to Light: the Turned, the cultists and the zealots are living people.
- **Beasts tire:** from round 6, a beast strikes 5% softer each round, down to half its blow.
- **The dead crumble:** from round 6, an undead foe loses 3% of its max health each round. It never finishes them; the execute does.
- **Morale:** only people and beasts break and flee. The dead, the void, constructs, demons, angels and giants hold.
- **Bosses:** neither tiring nor crumbling touches a boss, just as the execute and morale don't. Crumbling, the Bone Warden and the White Admiral were won 74% and 70% of the time against their 55% and 45%.

## Measured

- **Setup:** `KINDS_RUNS=100 flutter test test/foe_kind_test.dart`, 100 runs per profession, random strategy.
- **Cells:** fights won % / rounds per fight, with the foe rules off and on.

| | Off | On |
|---|---|---|
| Cleric | 56.7 / 14.2 | 56.8 / 14.4 |
| Mage | 83.0 / 6.9 | 82.3 / 6.9 |
| Ranger | 75.5 / 9.4 | 76.2 / 9.5 |
| Rogue | 74.3 / 8.9 | 75.6 / 9.0 |
| Warrior | 70.5 / 7.9 | 70.0 / 8.0 |

- **Effect:** small, −0.7 to +1.3 points, and fight length doesn't change.
- **Why so small:** few foes are beasts or undead, and the rules start at round 6, when most fights are nearly over.
- **Lantern Vanguard:** over the warrior's core (200 runs), it is +1.6 both before and after the change to "Evil foe".
