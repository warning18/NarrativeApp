# The competent player's companions (v1.567)

The competent simulator profile (`SimPolicy.competent`, see
`competent-player-v1.564.md`) now recruits companions, picks the party and
fights beside them (`lib/data/sim_companions.dart`). The naive profile is
unchanged and stays the CI bands' measure. Companions play only when the
run's tables hold `companions.json`. The simulator screen now loads that
file, with the quests and NPCs that recruit them.

## What the real game does

| Part | The game | Code |
|---|---|---|
| Recruiting | A companion joins when their quest (`rewardAllyId`) is handed in. They never join twice, and never after they leave or the story takes them. The quests have their own gates: Tobin's needs a Good player and Malrik's an Evil one. Companions have no race or profession condition. The `raceId` and `professionId` in `companions.json` are the companion's own. | `recruitAlly`, `quest_turn_in.dart`, `quests.json` |
| Seats | `partyCapacityFor`: two companions, and a third with the Barracks Annex. A new recruit takes a free seat. Kelda sits only once Kelda's Hall stands, and that house can only be built after she joins. | `player_session_provider.dart`, `houses.json` |
| Fight | Each seated companion rolls their signature die at the player's level, with damage and health set by their approval tier (devoted 110%, wary 90%). Enemies hit a party member chosen at random, and the member holding the biggest Defend block draws the blows. A companion at 0 health is knocked out, and the fight goes on until the player falls. After a won fight, a knocked-out companion comes back at 30% health. A rest or a level-up heals everyone. | `fight_setup.dart`, `fight_rounds.dart`, `fight_rewards.dart` |
| Approval | A choice's alignment and gold, and its `approvalMods`, move the approval of the seated companions by their weights. Benched companions don't see it. At -12 a companion leaves, and the benched companion with the highest approval takes the seat. `loseAllyId` takes one companion for good. | `approval.dart`, `_reactToDeed`, `_removeAlly` |
| Dice | The player rolls **one** die. Before a fight they can swap it for another die they own (the v1.213 loadout). The game has no dice cup. The competent player already rolls the best die it owns (`rollBestDie`). | `PlayerSession.equippedDiceId`, `combat/loadout.dart`, `fight_quick.dart` |

## The pick rule

- **Seats** go to the companions worth most in a fight. A companion's worth
  (`simCompanionValue`) is the average roll of their signature die at their
  damage, plus a tenth of their health, plus 0.8 per point of armor.
- **Ties:** two companions within one point of each other are a tie. The tie
  goes to the higher approval, then to the companion whose weights best fit
  the player's alignment (`approvesGood` for a good player, `approvesEvil`
  for an evil one), then to the earlier recruit.
- **Swaps:** when a better companion joins a full party, they take the
  weakest seat. The rule runs again at every recruit, departure and house
  built, and at each chapter's rest, because worth grows with the player's
  level.
- **Seeking recruits:** the competent player takes a way that offers a
  companion's quest when it is allowed to take that quest.

The run report has a "Companions" section next to the clan offers. It logs
every `seek`, `recruit`, `pick`, `bench`, `swap`, `leave` and `lost` event,
and every move into `devoted` or `wary`, each with its reason. The report
ends with the party at the end of the run and its knock-outs.

## Measurement

The runs use the same plan as v1.564: seed 7, 10 runs per profile (the five
professions twice, 5 random walks and 5 favour-good walks), with the v1.564
tables plus `skill_merges` and `companions`. The naive and competent columns
match the v1.564 numbers exactly. "Win" means an encounter won within 3
tries.

| Chapter | Naive enc. | Naive win | Competent enc. | Competent win | Companions enc. | Companions win | Companions 1st |
|---|---|---|---|---|---|---|---|
| 1 | 23 | 0.96 | 23 | 0.96 | 23 | 0.96 | 0.96 |
| 2 | 59 | 0.93 | 59 | 1.00 | 57 | 1.00 | 0.95 |
| 3 | 110 | 0.69 | 151 | 0.90 | 154 | 0.99 | 0.99 |
| 4 | 97 | 0.64 | 102 | 0.89 | 103 | 0.99 | 0.98 |
| 5 | 106 | 0.59 | 118 | 0.86 | 132 | 0.98 | 0.95 |
| 6 | 76 | 0.61 | 85 | 0.88 | 95 | 0.99 | 0.96 |
| 7 | 18 | 0.67 | 15 | 0.87 | 18 | 1.00 | 0.89 |
| 8 | 41 | 0.54 | 48 | 0.90 | 49 | 1.00 | 0.92 |

Average per run:

| | Naive | Competent | With companions |
|---|---|---|---|
| Final level | 20.5 | 22.9 | 23.2 |
| Fights won / lost | 36.0 / 66.2 | 54.2 / 32.9 | 62.9 / 3.6 |

- **Recruits:** 28 over the 10 runs: Kelda 10, Maren 10, Vess 3, Liora 2,
  and Grosh, Sable and Tobin once each. Every run ended with two or three
  companions seated. Sable's quest was taken once and never finished.
- **Picks:** 4 swaps, all in chapter 3 (Maren over Vess twice, Maren over
  Liora, Grosh over Vess). No tie came up. Kelda sat from chapter 3, once
  her hall stood.
- **Approval:** no companion left and none became wary. There were 33 moves
  into devoted: the walk's choices lean good, and so do Kelda's and Maren's
  weights.
- **Knock-outs:** 500 over the 10 runs, about 50 per run. With two or three of
  them standing, companions take most of the enemies' blows.

**Reading:** with the two or three companions the real game seats, almost
every fight is won from chapter 3 on (0.98 to 1.00, against 0.86 to 0.90
solo). For a competent party the game is easy. Even the competent solo
numbers overstate how hard it is.

## How it was run

The runs used a one-off `flutter test` harness, which is not committed. It
called `simulatePlaythroughs(..., seed: 7, policy: ...)` three times:
naive, competent without `companions`, and competent with it. It summed
`byChapter`, and the summaries' `companionLog`, `companions` and
`companionKnockouts`. The three profiles take about 10 seconds.

## Limits

- Not modelled: party combos, duo techniques, momentum's surge, the
  hunt-the-healer retarget, a companion's gear, skill points and the open
  face they unlock, and Hammersmith work on their die. Approval gifts at the
  camp are also not modelled.
- The enemies' Hex, Silence and Curse land only on the player's die. The
  rising ground and the foes' reinforcements strike only the player.
- Battlefield conditions and Quick Resolve are left out, as they are for
  the solo player.
- The house bonuses besides the seats (`partyBonusFor`) are not played, as
  before.
