# The nemesis and the alignment hunters (v5.2 step 6, PR 2)

The rules are in `lib/data/nemesis.dart`, `lib/data/rival_hunters.dart` and `lib/data/alignment_events.dart`. The plan is `docs/proposals/territory-power-nemesis.md` (its addendum, B); the hunters and their lines are Narrative's, from `docs/proposals/territory-texts.md` 5a–5c.

## The rules as built

- **The nemesis.** At most one: the strongest main clan with power 25 or more that you stand Hostile or Hunted with.
  - It rises at a chapter's turn, with a news line, and stays until you climb back to Wary or it falls.
  - **It hunts you, sworn or not,** at the Hunted odds (8% a road at rest), through the rival hunters' roll: the same 15% cap, cooldown, mercy and betrayal.
  - **At war it goes first,** and fights your patron from Hostile (step 3), not only at War.
  - **It offers nothing:** Hostile already does that.
  - **Breaking it** (`breakNemesis`, for its quest in PR 5): it loses a tier of power, the hunt ends, and it can't be your nemesis again for 2 chapters.
- **The alignment hunters for everyone.**
  - **Under ±20:** 2% a road at rest plus 0.2% a point, meeting today's 6% at the border. The side is drawn by the lean, so a character at 0 meets either. Temptations stay.
  - **At ±20 and past:** unchanged (6%, +0.15% a point, up to 15%).
- **Who hunts.**
  - The good orders hunt an Evil character: the Vigil's candle-bearer Ysel, the spearman Halvard (in place of the Inquisition soldier) and the masked penitent, with their battle cries.
  - The evil forces hunt a Good character: the cultist acolyte, the Hollow Court zealot and the void hound (from chapter 5; the void stalker is the Scaffold Yards' boss, so it stays one), at alignment −25 to −35 so a high Perception reads them Evil.
  - The angels and the demons keep their own lines; the six take Narrative's.
  - The six are still met as ordinary foes on the roads (`hunterOnly: false`).
  - Hunters now wait for their own `minChapter`.
- **The order on a road** is as before: a betrayal that is due, the alignment hunters, then the clan hunters (rivals and the nemesis).

## Measured

200 runs (seed 17), `HUNT_RUNS=200 flutter test test/nemesis_test.dart`. The counts are hunters per run, grouped by the run's final alignment. "Nemesis hunters" are hunters of the clan that was the nemesis when they came.

| Final alignment | Runs | Alignment hunters | Clan hunters | Nemesis hunters | Betrayals | All | Runs with a nemesis | Roads at rest |
|---|---|---|---|---|---|---|---|---|
| Neutral (under ±20) | 22 | **1.00** (0 before) | 0.82 | 1.05 | 0.18 | 3.05 | 19 | 60.5 |
| Leaning (±20 to ±49) | 38 | 1.79 (0.68) | 0.66 | 1.11 | 0.32 | 3.87 | 37 | 58.9 |
| Strong (±50 and past) | 140 | 2.43 (2.21) | 0.49 | 0.96 | 0.06 | 3.95 | 127 | 58.3 |

- **Every alignment is hunted:** 3 to 4 hunters a run, out of about 60 roads at rest.
- **Neutral characters,** never hunted before, meet about one alignment hunter a run.
- **The nemesis is nearly always the Dominion:** it is a nemesis in 183 of 200 runs (Dominion 178, Compact 4, Vigil 3, Crows 3, Penitents 2, Mire 1). The story itself drives standing with the Dominion to Hostile or Hunted for nearly everyone not sworn to it.
  - Requiring Hunted instead of Hostile barely changes that: 147 runs with the Dominion as nemesis.
  - This is left for the user to decide (see the PR).

## PR 5: the nemesis quests and their champions (v1.401)

- **The quest:** when a clan becomes the character's nemesis, its quest `q_nemesis_<clan>` opens (it is unlocked, never drawn on a detour).
  - Its one objective is to beat the clan's champion, `champion_<clan>`.
  - Its turn-in breaks the nemesis (`breakNemesis`): the clan loses a tier of power, the hunt ends, and it can't become the nemesis again for 2 chapters. The news reads "… have lost their champion, and their hunt with it."
- **The champion:** a boss, with the Hollow Court Inquisitor's skills and phases, 175 health and 24 damage. It is never an ordinary hunter: it carries `championClan`, not `hunterClan`.
  - From chapter 4, while the quest is under way, it comes on a road at rest 35% of the time, after a crisis or a fall and before any hunter.
  - Its scene is its `arrival` line and battle cry, with "Face {name}".
- **Texts are Narrative's** (`docs/proposals/nemesis-texts.json`, #324): the six champions, from Orsolya Keld (the Dominion) to the Heron Queen's Hand (the Mire), their quests, their alignments and the void hound's new cry.
- **Not yet built from Narrative's five beats** (`nemesis-quests.md`):
  - the trail step;
  - the three ways in (Force, Guile, Mercy) and the edge each could give in the fight;
  - the `defeat` line in the fight log;
  - each clan's own "broken" news line. The shared one is used for now.

**Measured:** 200 runs (seed 7), with `championFights` on in the simulator (the walk takes no quest a road opens). `test/nemesis_quests_test.dart` holds the curve at 50% ±12.

- First tried at the Inquisitor's own 203 health and 27 damage: 32.2% won. At 160 and 22: 58.6%.
- At 175 and 24: **50.3% of 501 fights**. Lost fights come again later on the road.

| Champion | Won / fought |
|---|---|
| Dominion | 169/380 |
| Crows | 44/75 |
| Compact | 31/35 |
| Vigil | 4/7 |
| Penitents | 4/4 |

The Dominion's champion is met far most often, as the Dominion is the nemesis in most runs.
- **The boss curve is unchanged:** champions are off in ordinary runs, and `boss_balance_test` passes as before.

## The follow-up: the trail, the way in, the defeat and the news (v1.404)

Narrative's beats (`docs/proposals/nemesis-quests.md`) are now played.

- **The trail:**
  - the quest's first objective is a flag, `nemq_<clan>_trail`;
  - the first road at rest that would bring the champion brings the trail instead: one choice, "Follow the trail".
- **The way in:** the champion's road then offers three choices, in Narrative's words. Each sets its flag `nemq_<clan>_<way>` and gives a small edge (`EncounterModifiers.nemesisWayEdges`):

  | Way | Edge |
  |---|---|
  | Force | 85% health |
  | Guile | 90% health and difficulty (health and half the damage) |
  | Mercy | 90% health, and +5 standing with the clan if won |

- **The defeat:** a foe's `defeat` line goes to the fight log when it falls.
- **The news:** a broken nemesis tells the clan's own line (factions.json `brokenNews`).

**Measured:** 200 runs (seed 7), as above. The simulator walks the trail first, then draws a way at random and folds its edge into the champion's record.

- At 175 and 24 the edges and the later meeting (one road spent on the trail) gave 64.5% won, out of the band.
- At **200 health and 27 damage: 48.2% of 473 fights.**

| Champion | Won / fought |
|---|---|
| Dominion | 164/369 |
| Crows | 31/56 |
| Compact | 28/36 |
| Vigil | 4/11 |
| Penitents | 1/1 |

The Dominion is still the nemesis in most runs; that question is with the user and is unchanged here.

## The Dominion as the story's nemesis (v1.409)

The user's call: your family kept a piece of the Shroud, and the Dominion wants it. Every new game opens with the Dominion as your nemesis (`PoliticsState.storyStart`, `nemesisReason: 'story'`). Narrative's check of the story is in `docs/proposals/dominion-nemesis.md`.

- **Gentle early:**
  - its hunters come at the Hostile odds (4% a road), not the Hunted ones;
  - its people don't join fights against you in its places;
  - it doesn't war on your patron's places first.
  The champion still waits for chapter 4, when its quest opens with Narrative's lamp-boy.
- **It lets go:**
  - when your standing with it reaches Friendly (+12; it starts at −10);
  - when its quest breaks it;
  - for good, with the legate's pact (`inquisition_pact`) or Vane backed for the throne (`throne_backed_vane`).
- **Another clan takes its place** only when you have crossed that clan harder: Hostile or worse, and lower standing than with the Dominion.
- **Turned Hostile,** it becomes an earned nemesis like any other: Hunted odds, and it lets go at Wary.
- **Old saves** take it on load unless they are Friendly with the Dominion, it has fallen, or its nemesis was broken.

**Measured:** 200 runs (seed 7), branch against main (v1.407).

| | main | v1.409 |
|---|---|---|
| Fights won | 64.5% | 64.5% |
| Fights won, champions on | 62.9% | 62.5% |
| Rival hunters met per run | 1.67 | 2.17 |
| Runs where some clan falls | 155 | 155 |
| Places changed per run | 4.64 | 4.64 |
| Runs where the Dominion is ever the nemesis | 178 | 200 |
| Champions beaten | 48.2% of 473 | 42.9% of 541 |

- **Win rates don't move:** the walk doesn't fight the road's hunters, and the story nemesis adds no reinforcements and no war.
- **The extra half hunter a run** is the Dominion's, at the Hostile odds.
- **Champions are met more often, and lost a little more:** the Dominion's quest now opens at chapter 4 in every run, and only 42.9% were beaten. Orsolya Keld is eased to 190 health and 26 damage (the others stay at 200 and 27): **50.0% of 500 champion fights won** (the Dominion's 181 of 393).
- **A first try,** with the ordinary war rule kept for the story nemesis, made 177 runs of 200 see a fall. That rule is why it now wars as any clan.

## Lysa's arc: Brother Clement and the hunt (v1.413)

Core's part of `docs/proposals/lysa-arc.md`. Narrative's nodes set the flags (PR 1.414).

- **Brother Clement** (`brother_clement`): the Black Hold's torturer, a boss fought in the Quarter's chapel when you take Lysa by force.
  - Built on the Hollow Court Inquisitor: 260 health, 28 damage.
  - Chapter 5, `hunterOnly` (never a random draw), alignment −40.
  - **Measured:** in `void_archon`'s chapter-5 place (400 runs, seed 7) he is won 53.4% of 380 fights, against 57.6% for the Archon. The chapter-5 target is 50% ±12.
- **The hunt, as her fate turns it:**
  - `lysa_rescued_force` or `lysa_sacrificed`: the story's nemesis turns into an earned one at the next chapter's turn (Hunted odds, its people in your fights, its wars). Keld's road comes at 60% instead of 35%.
  - `lysa_sworn_for`: joins the pact and the throne in `dominionSidedFlags`, so the Dominion's hunt is over for good. Its +12 standing alone would leave the Dominion at +2, short of Friendly.
- **Still to come (1.415):** the sacrifice's boon on the Shroud and the Void's mark.
