# The typical player

Finding #8 of the difficulty review ("measure a real player"). The
simulator had two players: **naive** (every CI band uses it) and
**competent** (plays the gear, the dice and the merges well). Neither is the
player most people are. `SimPolicy.typical` (`lib/data/sim_policy.dart`) is
the one in between: it takes what is plainly better and nothing more.

Measured on v1.933.0 (origin/main 179b1abb) plus this change, 2026-11-12.

## What it does

- Recruits and seats the companions the story hands over, as the stubborn
  and the competent players do (same seat rule).
- Wears a piece it finds (fight loot, a scene's or a quest's item, a clan's
  gift) when its flat attack plus armor is higher than the worn piece's, and
  its stats allow it. Slot by slot, one number per piece.
- Shops like the naive player: its spellbook, two charges of each potion,
  the best affordable piece per slot by the same flat score.
- Rolls a die it owns (a clan's gift, or one it bought) when that die's
  average roll is plainly better than the one in play's: `simDieValue` (the
  sim's average worth of a roll, with the die's skills placed the way the
  walk always places them) higher by at least 0.25. At a shop it buys the
  best such die it can afford, after potions and gear. No trial fights.
- Takes the naive banners (the 25% favour-best rule, kept to its clan).

## What it does not do

- No set weighing, no elemental or proc value: a shield with more attack
  plus armor than a staff goes in the weapon slot, as it would for someone
  who reads only the two big numbers.
- No skill merges, no combos, no optimal rerolls.
- No die trials, no pack kept for later (an old piece is dropped).
- No competent banners and no competent potion stocking.

## The 100 story runs, side by side

The set of `difficulty-review-1.914/`: seeds 1..100, the 25 race x
profession pairs x 4 goals, one `simulatePlaythroughs` call per seed. The
harness is `typical-player-runs_test.dart.txt` and the tables come from
`typical_summary.py` (raw: `typical-summary.json`). Terms as in
`story_summary.py`: an encounter is retried up to 3 times; a **death** is an
encounter lost after its 3 tries (the walk goes on; with permadeath the run
would end there).

N = naive, T = typical, C = competent.

| Ch | Encounters | Won 1st try % | Won within 3 tries % | Deaths | Arrival level |
|---|---|---|---|---|---|
| 1 | 385 / 386 / 380 | 90.4 / 93.3 / 95.3 | 92.7 / 94.3 / 95.5 | 8 / 9 / 6 | 1 / 1 / 1 |
| 2 | 677 / 698 / 676 | 90.8 / 98.9 / 99.3 | 97.9 / 100 / 99.7 | 14 / 0 / 2 | 3 / 3 / 3 |
| 3 | 1382 / 1596 / 1604 | 64.8 / 99.5 / 99.8 | 85.4 / 100 / 100 | 202 / 0 / 0 | 5 / 5 / 5 |
| 4 | 1002 / 1148 / 1133 | 45 / 97.9 / 97.5 | 74.1 / 99.8 / 99.8 | 260 / 2 / 2 | 8 / 9 / 9 |
| 5 | 1330 / 1481 / 1481 | 55.1 / 93.7 / 94.5 | 74.5 / 98.7 / 98.6 | 339 / 19 / 21 | 11 / 12 / 12 |
| 6 | 790 / 921 / 922 | 34.9 / 92.7 / 93.8 | 61.8 / 98.5 / 97.8 | 302 / 14 / 20 | 15 / 16.5 / 17 |
| 7 | 174 / 177 / 170 | 36.8 / 91.5 / 94.7 | 56.9 / 96.6 / 98.2 | 75 / 6 / 3 | 18 / 20 / 20.5 |
| 8 | 392 / 506 / 507 | 26.8 / 81.4 / 85 | 49.7 / 94.7 / 94.7 | 197 / 27 / 27 | 19 / 21 / 21.5 |
| all | | | 76.9 / 98.7 / 98.7 | 1397 / 77 / 81 | |

Runs with no death: N 0, T 65, C 73. Median final level: N 21, T 24,
C 25. Every run of every player reaches an ending.

Bosses, share of tries lost (tries in brackets; the target is
`boss_balance_test`'s win share for the naive player):

| Boss | Target win % | N lost % | T lost % | C lost % |
|---|---|---|---|---|
| aurel_vane | 75 | 43.8 (32) | 21.4 (28) | 13.8 (29) |
| void_stalker | 65 | 42.0 (100) | 0.0 (131) | 0.0 (134) |
| hollow_court_inquisitor | 55 | 38.8 (98) | 0.0 (100) | 0.0 (100) |
| bone_warden | 55 | 37.3 (134) | 0.0 (146) | 0.0 (143) |
| void_archon | 50 | 62.7 (83) | 3.0 (100) | 6.0 (100) |
| white_admiral | 45 | 62.7 (67) | 2.0 (98) | 2.0 (98) |
| claimant_vane | 40 | 60.0 (15) | 8.3 (12) | 7.1 (14) |
| claimant_tallis | 40 | 68.6 (70) | 2.8 (72) | 1.5 (68) |
| claimant_morrow | 40 | 73.3 (15) | 18.8 (16) | 5.6 (18) |
| tear_herald | 35 | 73.0 (100) | 10.0 (100) | 9.0 (100) |
| void_sovereign | 35 | 70.7 (58) | 12.5 (96) | 9.4 (96) |

## Where typical sits

Next to the competent player, far from the naive one. Over the 100 runs it
wins as many encounters within 3 tries (98.7%), dies about as often (77
deaths against 81), and its first-try rate trails the competent one by 0 to
4 points, most of it in chapters 7 and 8 (91.5 against 94.7, 81.4 against
85.0). Its boss losses are within a few points of the competent player's,
the widest gaps being Aurel Vane (21% against 14%) and Claimant Morrow (19%
against 6%, on 16 tries).

For scale, the stubborn player (companions, no gear worn, no die changed)
on the same seeds: 94.7% within 3 tries, 346 deaths, 24 runs with no death,
Tear Herald lost on 23% of tries. So:

- the naive-to-stubborn gap (76.9% to 94.7%) is the companions;
- the stubborn-to-typical gap (94.7% to 98.7%) is wearing plainly better
  gear and rolling a plainly better die;
- the typical-to-competent gap is almost nothing: weighing sets, trying
  dice and crafting merges buy a few first-try points late in the story.

So the game as measured by naive (the CI bands) is much harder than the game
a real player who keeps the companions meets: for that player the story is
easy through chapter 6 and the chapter-8 fights (Tear Herald, the Void
Sovereign) are the only ones that bite. The five fights below, the deadliest
for naive, lose this player 0 to 10% of encounters after 3 tries:

| Fight | N lost / encounters | T | C |
|---|---|---|---|
| 3200 (ch3, inquisition) | 32 / 64 | 0 / 72 | 0 / 65 |
| 5100 (ch4, drowned pilgrims) | 25 / 50 | 0 / 48 | 0 / 49 |
| 6200 (ch5, void hounds) | 32 / 62 | 2 / 66 | 6 / 62 |
| 7002 (ch6, hollow reflections) | 46 / 87 | 2 / 80 | 6 / 77 |
| 7810 (ch8, Tear Herald) | 73 / 100 | 10 / 100 | 9 / 100 |

A caveat on all of it: the simulator plays the fight with its own model
(`sim_combat.dart`), and the companions in it may be stronger than in the
real fight screen. QA's replay of the builds below is the check.

## Typical builds at the five deadliest fights

`typical-player-builds.json`, keyed by encounter (scene) id, then by
profession under `byProfession` (`mostCommonProfession` names the one with
the most runs arriving; they are nearly even). For each profession it holds
the typical run whose level on arrival is the median among the runs of that
profession that reached the fight (ties by seed), with:

- `seed`, `race`, `goal`, `chapter`, `enemies`, `runsArriving`,
  `levelRange`, `medianLevel`;
- `save`: the build as the run brings it to the fight's first try (after
  its gear and die choices, with its companions seated), in the keys of
  `PlayerSession.toJson` (`saveVersion` 6, `diceDataVersion` 2): level,
  XP, gold, alignment, `maxHealth`/`currentHealth`, `baseDamage`/
  `baseArmor`, the eight stats, `potionCount`, `flags`, `equippedItemIds`,
  `unlockedSkillIds`, `diceSkillAssignments`, `ownedDiceIds`/
  `equippedDiceId`, `specIds`, `mana`, `knownSpellIds`, `heldSigns`,
  `perkRanks`, titles and boons, `politics` (its histories, `log`, `news`
  and `relationsLog`, left out), `recruitedAllies` (companion id, health,
  approval) and `activeAllyIds`. The keys it lacks take
  `PlayerSession.fromJson`'s defaults.

The saves are built by `simSessionSave` (`lib/data/sim_snapshot.dart`),
which the walk calls through the `onFight` hook of `simulatePlaythroughs`
(read-only: a run with the hook plays exactly as one without). The numbers
are the simulator's own (`SimCharacter`); a field the real game derives
differently (a companion's gear and skills, which the sim does not keep)
is left to `fromJson`.

**QA's driver plays the dice in the most basic way** (no rerolls, no
targeting, no skill timing), so its replay of these builds is a lower bound
on how the fight goes for this player, not the fight itself.

### 3200 (chapter 3: inquisition_soldier, inquisition_auxiliary)

| Profession | Run (seed, race) | Level (range) | HP / dmg | STR DEX CON INT WIS | Gear worn | Die | Companions | Potions |
|---|---|---|---|---|---|---|---|---|
| cleric | 56, dwarf | 6 (4-7, 14 runs) | 55 / 9 | 3 0 7 1 6 | boots_worn_leather, sword_t4, void_banner, warden_signet | apprentice_die | maren, sable | 13 |
| mage (most common) | 27, elf | 6 (5-7, 16 runs) | 31 / 6 | -1 5 1 6 2 | boots_worn_leather, spear_t3, void_banner | court_die | maren, sable | 6 |
| ranger | 40, elf | 6 (5-8, 14 runs) | 39 / 7 | 0 10 1 2 2 | boots_worn_leather, helm_iron_cap, spear_t3, void_banner | starter_die | maren, sable | 11 |
| rogue | 29, elf | 6 (5-7, 14 runs) | 42 / 6 | 0 11 1 2 1 | boots_worn_leather, spear_t3, void_banner | starter_die | maren, sable | 10 |
| warrior | 21, elf | 6 (4-7, 14 runs) | 45 / 3 | 4 6 3 2 0 | boots_worn_leather, shield_t4, void_banner | court_die | maren, kelda | 2 |

### 5100 (chapter 4: drowned_pilgrim, drowned_pilgrim)

| Profession | Run (seed, race) | Level (range) | HP / dmg | STR DEX CON INT WIS | Gear worn | Die | Companions | Potions |
|---|---|---|---|---|---|---|---|---|
| cleric | 16, human | 12 (9-12, 7 runs) | 74 / 13 | 2 0 4 5 10 | boots_worn_leather, hollow_court_seal, plate_emberproof, shield_t6, void_banner | headsman_die | maren, kelda | 1 |
| mage | 28, elf | 11 (8-12, 7 runs) | 54 / 10 | 0 6 3 10 3 | boots_worn_leather, hollow_court_seal, plate_emberproof, staff_t10, void_banner | arcane_die | maren, kelda | 10 |
| ranger | 40, elf | 11 (8-13, 11 runs) | 61 / 11 | 0 14 2 2 2 | boots_worn_leather, dagger_t10, hollow_court_seal, plate_emberproof, void_banner | starter_die | maren, sable | 9 |
| rogue | 12, human | 11 (8-13, 11 runs) | 64 / 10 | 2 12 2 0 3 | boots_worn_leather, dagger_t10, hollow_court_seal, plate_emberproof, void_banner | shadow_die | maren, sable | 6 |
| warrior (most common) | 61, orc | 10 (8-12, 12 runs) | 77 / 11 | 16 0 9 -1 0 | boots_tearwalker, greaves_voidsteel, hollow_court_seal, sword_t10, void_banner | starter_die | maren, tobin | 8 |

### 6200 (chapter 5: void_hound, void_hound)

| Profession | Run (seed, race) | Level (range) | HP / dmg | STR DEX CON INT WIS | Gear worn | Die | Companions | Potions |
|---|---|---|---|---|---|---|---|---|
| cleric | 53, dwarf | 16 (12-17, 11 runs) | 113 / 15 | 5 0 13 7 10 | boots_worn_leather, hollow_court_seal, plate_emberproof, shield_t10, void_banner | court_die | maren, sable | 1 |
| mage | 85, voidkin | 13 (10-18, 13 runs) | 62 / 11 | 1 4 0 12 3 | boots_tearwalker, hollow_court_seal, plate_emberproof, staff_t10, void_banner | headsman_die | maren, kelda | 12 |
| ranger | 57, dwarf | 15 (11-18, 13 runs) | 101 / 10 | 5 10 12 0 2 | boots_tearwalker, greaves_voidsteel, hollow_court_seal, shield_t10, void_banner | starter_die | maren, kelda | 8 |
| rogue (most common) | 49, dwarf | 14 (11-19, 15 runs) | 91 / 10 | 3 12 10 0 0 | boots_tearwalker, hollow_court_seal, plate_emberproof, shield_t10, void_banner | shadow_die | maren, sable | 14 |
| warrior | 62, orc | 12 (11-18, 14 runs) | 83 / 13 | 18 0 9 -1 0 | boots_worn_leather, hollow_court_seal, plate_emberproof, sword_t10, void_banner | starter_die | maren, kelda | 4 |

### 7002 (chapter 6: hollow_reflection, hollow_reflection)

| Profession | Run (seed, race) | Level (range) | HP / dmg | STR DEX CON INT WIS | Gear worn | Die | Companions | Potions |
|---|---|---|---|---|---|---|---|---|
| cleric | 95, voidkin | 16 (12-22, 14 runs) | 103 / 17 | 0 1 6 11 9 | boots_worn_leather, hollow_court_seal, plate_emberproof, shield_t8, void_banner | headsman_die | sable, kelda | 11 |
| mage | 87, voidkin | 15 (13-22, 16 runs) | 80 / 12 | -1 1 4 13 3 | boots_worn_leather, hollow_court_seal, plate_emberproof, shield_t8, void_banner | flame_die | liora, vica | 0 |
| ranger | 57, dwarf | 19 (13-22, 15 runs) | 120 / 13 | 6 13 13 0 2 | boots_tearwalker, greaves_voidsteel, hollow_court_seal, shield_t10, void_banner | starter_die | maren, kelda | 8 |
| rogue | 49, dwarf | 19 (12-23, 17 runs) | 116 / 15 | 4 17 12 0 0 | boots_tearwalker, hollow_court_seal, plate_emberproof, shield_t10, void_banner | shadow_die | maren, sable | 7 |
| warrior (most common) | 1, human | 17 (14-22, 18 runs) | 120 / 16 | 18 0 13 0 2 | boots_tearwalker, greaves_voidsteel, hollow_court_seal, sword_t10, void_banner | starter_die | maren, sable | 6 |

### 7810 (chapter 8: tear_herald)

| Profession | Run (seed, race) | Level (range) | HP / dmg | STR DEX CON INT WIS | Gear worn | Die | Companions | Potions |
|---|---|---|---|---|---|---|---|---|
| cleric | 14, human | 20 (17-28, 20 runs) | 114 / 23 | 0 0 6 15 14 | boots_tearwalker, hollow_court_seal, plate_emberproof, shield_t8, void_banner | headsman_die | maren, kelda | 7 |
| mage | 66, orc | 20 (16-28, 20 runs) | 109 / 20 | 3 0 9 17 8 | boots_worn_leather, hollow_court_seal, plate_emberproof, shield_t8, void_banner | berserker_die | maren, tobin | 5 |
| ranger | 98, voidkin | 19 (17-28, 20 runs) | 101 / 17 | 6 17 3 3 1 | boots_tearwalker, hollow_court_seal, plate_emberproof, tear_glass_blade, void_banner | storm_die | maren, kelda | 0 |
| rogue | 91, voidkin | 21 (16-29, 20 runs) | 112 / 17 | 0 19 3 7 4 | boots_tearwalker, hollow_court_seal, plate_emberproof, tear_glass_blade, void_banner | shadow_die | vica | 0 |
| warrior (most common) | 62, orc | 21 (18-27, 20 runs) | 133 / 21 | 26 0 14 -1 0 | boots_tearwalker, hollow_court_seal, plate_emberproof, sword_t10, void_banner | starter_die | maren, kelda | 3 |

## To rerun

```
cp docs/simulation/typical-player-runs_test.dart.txt test/zz_story_runs_test.dart
for p in naive typical competent; do
  SIM_POLICY=$p SIM_OUT=/tmp/$p.json SIM_BUILDS=/tmp/$p-builds.json \
    flutter test test/zz_story_runs_test.dart
done
python3 docs/simulation/typical_summary.py /tmp/naive.json /tmp/typical.json \
  /tmp/competent.json /tmp/typical-builds.json <out dir>
rm test/zz_story_runs_test.dart
```

About 30 s per player on one core. The naive and the competent runs of this
change are byte-identical to the same harness on unmodified main.
`test/sim_competent_test.dart` ("the typical player") checks the rules and
that four typical runs lose fewer tries than naive and no fewer than
competent.
