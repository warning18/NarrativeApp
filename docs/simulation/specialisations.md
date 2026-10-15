# The main clans' specialisations (v5.2, step 2a)

The design is in `docs/proposals/profession-clan-mechanics.md`; the words are Narrative's (`docs/proposals/specialisation-texts.md`).
- Each profession's core (`lib/combat/profession_cores.dart`) is bent by its three main clans.
- A clan offers its specialisation as a gift once you are its **Friend** (19+). It comes once, stays for the run, and several stack.
- The rules and numbers are in `lib/combat/specialisations.dart`; the words, profession and clan in `assets/gamedata/specialisations.json`.
- The live fight and the simulator play the same rules.

## The fifteen

| Profession (core) | Clan | Specialisation | What it does |
|---|---|---|---|
| Warrior (Fury) | Crows | **Berserker** | Attack faces are Pain strikes (double, 8% of max health). The life paid adds 1 Fury. |
| | Compact | **Briar Guard** | A blow the block and armour stop adds 1 Fury, and a quarter of what they stopped goes back. You can't dodge. |
| | Dominion | **Lantern Vanguard** | The heavy blow is ×2.85 (Fury's own is ×2.5), Fire, and Pierces. Against an Evil foe (one weak to Light: the void, the dead, demons) it heals a fifth of its damage. |
| Cleric (the Watchfire) | Vigil | **Long Vigil** | Above half health, 5% of max health mended each round. |
| | Penitents | **Ashen Hand** | Whenever the fire burns (a heal's burn or the round's): 1 mana, the burn's amount mended, one affliction lifted. |
| | Dominion | **Beacon** | The fire holds up to your whole max health. Every burn strikes every enemy, in Light, ×1.5. |
| Mage (the Ash Well) | Dominion | **Censer Mage** | Mana past full burns the enemy for 3× your strike per point. |
| | Penitents | **Burden-Bearer** | A spell cast from a full Well hits ×2. |
| | Crows | **Tempest Toll** | Spells heal 6% of their damage, and the Crows offer Teleport Strike. |
| Rogue (Flurry) | Mire | **Fever Blade** | Each critical hit adds the Rot: a poison of 40% of the hit that stacks and lasts the fight. |
| | Crows | **Ledger Knife** | Each hit that isn't critical adds 8 points to the next one's chance. A critical resets it and hits ×1.75 instead of ×1.5. |
| | Penitents | **Relicbreaker** | Each critical hit gives 1 mana. At 3 mana, the next strike is a sure critical and spends it. |
| Ranger (the Trail) | Crows | **Corsair's Eye** | The Verdict (the last face of a run) counts ×1.6 and Pierces. |
| | Compact | **Trapwright** | The Verdict also stuns its target for a turn. |
| | Mire | **Fen Guide** | The first face of each run poisons its target: half the blow, for 3 turns. |

## Measured

- **Setup:** 200 seeded runs per line (seed 11), random strategy, one profession. The specialisation is held from the start and set against the core alone, with the fight-length rules and the Tide on.
- **Command:** `SPECS_RUNS=200 flutter test test/specialisations_test.dart`. `SPECS_ONLY=id,id` limits it to some.
- **Target:** +3 to +6 points of fights won over the core.

| Profession | Specialisation | Won: core → with it | Over the core | Rounds |
|---|---|---|---|---|
| Warrior | Berserker | 60.3% → 65.3% | **+5.0** | 6.9 |
| | Briar Guard | 60.3% → 65.3% | **+5.0** | 8.2 |
| | Lantern Vanguard | 60.3% → 65.3% | **+5.0** | 9.2 |
| Cleric | Long Vigil | 51.9% → 56.3% | **+4.3** | 14.5 |
| | Ashen Hand | 51.9% → 54.0% | +2.0 | 14.3 |
| | Beacon | 51.9% → 55.4% | **+3.5** | 13.6 |
| Mage | Censer Mage | 71.7% → 73.6% | +1.9 | 6.9 |
| | Burden-Bearer | 71.7% → 73.3% | +1.6 | 7.0 |
| | Tempest Toll | 71.7% → 76.9% | **+5.2** | 7.1 |
| Rogue | Fever Blade | 63.2% → 69.7% | +6.5 | 8.9 |
| | Ledger Knife | 63.2% → 67.2% | **+4.0** | 9.1 |
| | Relicbreaker | 63.2% → 66.1% | +2.9 | 9.3 |
| Ranger | Corsair's Eye | 68.5% → 74.3% | **+5.8** | 9.4 |
| | Trapwright | 68.5% → 75.1% | +6.6 | 10.0 |
| | Fen Guide | 68.5% → 73.8% | **+5.3** | 9.3 |

**How sure:** runs of 40 and 100 put the same line up to 2.5 points apart, so a figure here is ±2.

**In range (+3 to +6):** nine specialisations. Fever Blade and Trapwright sit just above, Relicbreaker just below.

**Below range, and why:**
- **Censer Mage and Burden-Bearer** reward a mage who fills the Well before spending it. The autoplay casts as soon as it can afford a spell, so it rarely overflows or casts from a full Well. The proposal said the same of the Inquisitor. A player who builds two Mana faces and holds a spell gets more.
- **Ashen Hand** gives the cleric mana, whose pool is mostly full already in the simulator. The mend from the burn is what it measures.

**Taken in a run** (100 runs of the four strategies, offers on):
- 95 of 100 runs took at least one specialisation.
- On average a run took 1.4 (warrior) to 2.6 (ranger).
- The boss curve (boss_balance_test) holds.

## Changes to Narrative's texts

`specialisations.json` was generated from Narrative's doc. Five gifts changed where the rule moved. Narrative may reword them; the figures are Core's.

| Specialisation | Change |
|---|---|
| Corsair's Eye | "the last face of a run": the Trail deals five faces a run, not six |
| Relicbreaker | adds "At 3, your next strike is sure to be critical": a rogue has no spell to spend mana on |
| Ashen Hand | adds "mends you a little" |
| Lantern Vanguard | adds "strikes harder" |
| Beacon | adds "harder" |

## Not in this step (2b)

- The thirty sub-clan variants and upgrades, from Trusted, on a specialisation held.
- Rank II at Sworn.
- The weak links' twists.
