# What the simulator plays differently from the app (v1.463, v1.500, v1.513, v1.524)

QA's clan-power study (`docs/qa/clan-power-50.md`, "What the simulator does
not play") listed where the simulator's runs part from the app's. This page
keeps track of those gaps: the ones closed, and the ones left on purpose.

## Closed: a quest turn-in's politics (v1.463)

A quest settled with a turn-in choice now moves the clans in the simulator
as it does in the app (`quest_turn_in.dart`). `SimQuestLog.complete`
returns the choice's `politics` with the payout, and the walk applies them
through the same `applyStoryPolitics` (politics_events.dart) the app uses:
once, under `questTurnInPoliticsKey`, logged `quest:<questId>`. So a main
clan the choice raises by `questPowerStanding` (5) or more gains
`questPower` (+5) and is spared that chapter's neglect, and a nemesis quest's
`breakNemesis` breaks the nemesis.

Which choice the simulated player takes is unchanged: the most good
(favorGood), the most evil (favorEvil), the most gold (maximizeGold), else
one at random.

In 50 runs (QA's plan: seeds 7000 to 7049, strategies, professions and races
cycling), about 1.4 turn-ins a run now apply politics, most of them chapter
7's Dominion errands and chapter 5's Penitents' confession. Mean power at
the start of each chapter (and at the run's end), v1.461 before and after:

| Clan | | c2 | c3 | c4 | c5 | c6 | c7 | c8 | end |
|---|---|---|---|---|---|---|---|---|---|
| Dominion | before | 62.2 | 65.6 | 67.6 | 68.5 | 69.7 | 71.5 | 73.0 | 73.6 |
| | after | 62.2 | 65.7 | 67.5 | 68.4 | 70.1 | 71.8 | 74.9 | 75.4 |
| Compact | before | 39.1 | 40.2 | 44.0 | 48.4 | 56.5 | 58.9 | 59.8 | 61.5 |
| | after | 39.1 | 40.2 | 44.1 | 48.3 | 56.4 | 58.7 | 59.8 | 60.9 |
| Crows | before | 46.0 | 49.0 | 53.6 | 56.7 | 62.2 | 64.3 | 64.9 | 65.4 |
| | after | 46.0 | 49.0 | 53.5 | 56.7 | 62.2 | 64.1 | 64.8 | 65.4 |
| Vigil | before | 27.8 | 28.2 | 30.2 | 32.1 | 35.6 | 34.9 | 32.7 | 33.9 |
| | after | 27.8 | 28.2 | 30.2 | 32.0 | 35.8 | 35.3 | 29.6 | 30.6 |
| Penitents | before | 23.3 | 23.3 | 20.1 | 16.6 | 17.0 | 14.3 | 12.7 | 13.2 |
| | after | 23.3 | 23.3 | 20.0 | 16.5 | 17.7 | 14.4 | 12.6 | 13.1 |
| Mire | before | 23.5 | 18.6 | 16.4 | 15.4 | 15.5 | 14.7 | 4.1 | 4.2 |
| | after | 23.5 | 18.6 | 16.3 | 14.8 | 15.1 | 14.6 | 5.3 | 5.5 |

Small, as QA expected: the Dominion gains about 2 by chapter 8 (its
chapter 7 errands), the Penitents a point in chapter 6, and the rest moves
by where the stronger Dominion takes its places (the Vigil about 3 lower at
the end). The fights do not move (400 runs, seed 7).

## Closed: the seat crisis (v1.500)

A chapter's turn that would take your main clan's seat or its last place
now waits as a crisis in the simulator too: `SimGrowth.chapterReached`
runs `territoryTurn` with `protect: mainClanOf(...)`, as the app's
`grantChapterOffer` does. The walk plays it at once, at the chapter's hub
(`SimGrowth.playCrisis`), with the app's own scene (`buildCrisisNode`) and
its choices' politics, applied through the same `applyStoryPolitics`:

- **Defend** when the character is healthy (above half health, the
  estimate `preferredSuitor` reads) and the fight with the attacker's
  hunter is won, fought once with the simulator's fight model, as the
  scene's fight is. Won: the seat holds, +5 power and standing to the
  clan, −10 power to the attacker.
- Else, or when that fight is lost, **pay** when the purse holds the
  price (40 gold a chapter): the attacker takes a lesser place, if any.
- Else **refuse**: −10 standing, and the seat falls.

The crisis fight is not counted among the run's encounters (the roads'
hunters are not either), and the scene draws its hunter on its own dice.
`SimRunSummary.crises` counts what came of each (`held`, `lost`, `paid`,
`refused`). The fall's scene (bend the knee or stay) is still not played.

In QA's 50 runs only 2 crises came (both defended, lost, then paid): the
patron's seat is rarely the one a war reaches. See
[clan-power-50-v1.500.md](clan-power-50-v1.500.md).

## Closed: gifts kept to the patron (v1.500)

Once the character has a main clan (sworn, else its patron:
`mainClanOf`), the simulator's pick (`preferredSuitor`, `keepTo`) keeps to
that clan and its allies (`alliesOf`). Another clan's card is taken only
when it fills an empty die face. The wayfarer's and your own hand's cards
stay in, as they move no clan. If nothing is left, it picks from the
whole offer. Before a patron, any clan's card is taken as before.

In the 50 runs, 2,443 cards were taken: 206 before a patron, 1,165 from
the patron, 886 from its allies, 128 neutral and 58 from another clan
(nothing else left). The Crows and the Dominion get fewer gifts and the
Vigil more, since the Vigil is the most common patron.

## Closed: the politics events (v1.513)

The simulator fired no politics event: neither the chapter ones
(`lantern_bearer_dies`, `returned_taken`, `coal_stops`...) nor the two
upheavals that move power (`wrack_vote_result`, `conclave_counts`). With
`politics_events` in its tables it now fires them as the app does
(`runDueEvents`), at each scene the walk enters, after a new chapter's turn;
a choice's `event` fires too, and a choice's `control` gives the place
through `givePlace`. Narrative's 19 choices with `power` (v1.509) were
already applied. The events put the Dominion at War with the Mire and the
Compact by chapter 3 (before v1.513's softening, see the study), so their
seats fell far more often than the old simulator said: see [clan-power-50-v1.513.md](clan-power-50-v1.513.md). The
simulator tests load the table (`qa_sim_tables_test` requires it); only
`clash_balance_test`'s fights-by-chapter walk runs without it.

## Closed: the enemies' Hex, Silence and Curse

`sim_combat` skipped an enemy's `tamper` move: the enemy spent its turn and
nothing happened, so `hex_of_ill_luck`, `edict_of_silence` and
`rotting_mark` were free turns for the hero. Sixteen enemies use them,
among them Cassian Oriel (both hex and silence, 23% of his turns), the
six clan champions, Brother Clement and the Hollow Court Inquisitor
(silence). The simulator now lays them as the fight screen does
(`fight_dice_rules.dart`), with the shared helpers of `dice_tamper.dart`:

- **Silence:** laid in the enemies' turn, it hangs over the next round:
  a Skill face lands blank (`silencedFace`), and a skill set on a basic
  face falls back to that face. A blank is rerolled like any blank.
- **Hex:** the next roll's first die is rolled again at once (a plain
  roll, even on the ranger's Trail), unless it landed Steady
  (`hexVictim`). It waits through a stunned round, as in the app.
- **Curse:** a random face not yet cursed (`curseTargetFace`) becomes a
  Pain strike for the rest of the fight (`cursedFace`); the Ember face's
  charges lift Curses as they come. The tampering lands after the strike
  signs, as on the fight screen.

The Writ's own silence (doctrines) is unchanged: it was already played.
`test/sim_tamper_test.dart` checks each rule. In 400 runs (seeds 7, 11,
23) the boss and profession numbers moved inside the seeds' noise and
`boss_balance` and `nemesis_quests` pass. On the old 18-table
`clash_balance` the chapter-2 gap went from 0.03 to 0.13 at its seed; on
the real walk (v1.524) the tampering moved the mean gap from 0.140 to
0.116 and chapter 2 from 0.213 to 0.232, and the clash rules' pack change brought it to 0.027
(see [clash-balance-real-walk.md](clash-balance-real-walk.md)). Landed in
v1.524 with the claimants' rules
([claimants-by-profession.md](claimants-by-profession.md)).

## v1.524: the claimants' rules and the pack rules

`sim_combat` plays them as the fight screen does, from the same helpers:
the claimants' Tide cap (`fightTideCap`, enemies.json `tideCap`) and one
heal (`healsOnce`, `withoutHealMoves`); the pack rules
(`executesInFight`, `cornered`, `moraleFleeChanceFor`, `routFleeChance`,
`fightGoalChanceFor`, `holdRoundsFor`, `parryAmount(foes:)`) and the pack
stats (0.7 / 0.6). Nothing new is left unplayed.
