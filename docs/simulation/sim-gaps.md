# What the simulator plays differently from the app (v1.463)

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

## Left: no seat crisis

The simulator plays no seat crisis (`clan_crisis.dart`): with no one to ask
to defend, pay or refuse, a chapter's turn that would take the patron's seat
or its last place goes through at once (`SimGrowth.chapterReached`). In the
app the scene comes first, so patron falls run higher in the simulator than
a player would see (QA: 9 of 50 runs saw the patron fall). The falls of
clans the player does not back are the same in both.

## Left: gifts from every clan

The simulator's picking rule takes clan gifts from every clan's offers, not
only the patron's, so unbacked clans rise more here than with a player who
keeps to a patron (QA's finding 4).

## Not the simulator's: story power

No story node, choice or politics event carries `power` in the data, so the
"story power" source never fires, in the app or here. That is Narrative's
data to add, if wanted.
