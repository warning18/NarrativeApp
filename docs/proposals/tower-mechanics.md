# The Tower: mechanics (phase 0a, Core, docs only)

This note gives the rules and numbers of the Tower, following the
manager's wave plan (`the-tower-wave.md`, PR #803). Nothing in `lib/` or
`assets/` changes with it. Every number below is a **first value** for the
simulator (phase 2) to confirm. Phase 1 builds nothing until the user has
seen this note and UX-2's pictures.

The note is written against main at v1.826.0.

## 1. The run in one paragraph

The player picks a race, a profession and a clan (only unlocked ones). The
hero starts at level 1 with the profession's starter kit. Seed `S` fixes
every floor. On each floor the hero fights once. After a win they pick 1
of 3 rewards. Health carries from floor to floor; a heal is one of the
rewards. Floors 10, 20 and 30 are bosses, and winning floor 30 is the top.
A loss ends the run. Win or lose, the hero earns Tower marks, which buy
starter unlocks for later runs. Nothing is read from or written to the
story save.

## 2. The run state

A new record, `TowerRun`, in a new file (`lib/data/tower/tower_run.dart`).
It serialises to JSON.

| Field | Type | What |
|---|---|---|
| `seed` | int | the run's seed; the same seed gives the same floors and the same offers |
| `floor` | int | the floor to fight next (1..30) |
| `hero` | `PlayerSession` | the Tower's own hero: race, profession, level, stats, health, dice, faces, skills, spells, items, signs, clan. It is the same class the story uses, so the fight reads it unchanged (see §9) |
| `clanId` | String | the clan picked at the start (one of the six main clans) |
| `offer` | `List<TowerReward>`? | the 3 rewards on the table, if the hero hasn't picked yet; saved so a reload can't reroll them |
| `taken` | `List<String>` | the reward ids taken so far (for the end screen and to avoid repeats) |
| `status` | enum | `climbing`, `dead`, `won` |
| `marksEarned` | int | marks this run, worked out at the end (§7) |
| `startedAt`, `version` | | for the save and the end screen |

The run moves through three states:

1. `fight(floor)`
2. `offer(floor)`, after a win
3. `fight(floor + 1)`

A loss goes to `dead`, and a win on floor 30 goes to `won`. There is no
other state: no map, no rest floor and no shop.

**Randomness.** Each floor draws from its own `Random(hash(seed, floor, purpose))`:

| Purpose | Draws |
|---|---|
| `foes` | which enemies the floor has |
| `affix` | the floor's affixes |
| `offer` | the 3 rewards |
| `fight` | the fight's own dice |

So a floor's foes and its offer don't depend on how the floors before it
were played. A shared seed gives everyone the same tower.

## 3. The floor generator and its budget

A floor runs on the main game's difficulty curve (`difficultyCurveFor` in
`combat_engine.dart`), through `EncounterModifiers`:

- **`chapter`** is the floor's band (the column *Chapter* below). It picks
  the enemy pool, the health and damage floors and the chapter curve.
- **`difficultyMultiplier`** is the Tower's own extra on top (the column
  *Extra*).

The main game's numbers are not changed. The Tower has its own table: the
one below.

| Floors | Chapter | Extra | Foes | Pack chance | Forced affixes | Elite chance (solo) | Hero level after the floor |
|---|---|---|---|---|---|---|---|
| 1–3 | 1 | ×1.00 | 1 | 0% | 0 | 0% | 1, 2, 2 |
| 4 | 2 | ×1.00 | 1–2 | 30% | 0 | 12% | 3 |
| 5 | 2 | ×1.00 | warden (§4) | | 0 | | 3 |
| 6–9 | 2, 2, 3, 3 | ×1.00 | 1–2 | 30% | 0–1 (50%) | 12% | 4, 4, 5, 5 |
| **10** | 3 | ×1.00 | **boss** | | 0 | | 6 |
| 11–14 | 4 | ×1.00 | 1–2 | 50% | 1 | 12% | 6, 7, 7, 8 |
| 15 | 4 | ×1.05 | warden | | 1 | | 8 |
| 16–19 | 4, 5, 5, 5 | ×1.05 | 1–3 | 50% | 1 | 15% | 9, 9, 10, 10 |
| **20** | 5 | ×1.05 | **boss** | | 0 | | 11 |
| 21–24 | 6 | ×1.10 | 2–3 | 70% | 1–2 | 20% | 11, 12, 12, 13 |
| 25 | 7 | ×1.10 | warden | | 1 | | 13 |
| 26–29 | 7, 7, 8, 8 | ×1.15 | 2–3 | 70% | 2 | 25% | 14, 14, 15, 15 |
| **30** | 8 | ×1.15 | **the top's boss** | | 0 | | (the run is won) |

How to read the columns:

- **Foes.** A floor with "1–2" rolls a pack at the pack chance. The pack's
  size is drawn in that range from the band's pack-eligible enemies
  (`packEligible`), and pack fights keep their own stat multipliers
  (`packStatMultipliers`).
- **Forced affixes.** These come from the 5 affixes in `enemy_affix.dart`
  (venomous, armored, skittish, frenzied, pack leader) and go on top of the
  normal affix roll (20% solo, 15% per pack member).
  - Today `forcedAffixes` only reaches the *first* enemy. Phase 1 keeps it
    that way: forced affixes go on the floor's strongest foe.
  - A second forced affix on floors 26–29 means two different ones. Pack
    leader only goes on a pack.
- **Hero level.** The hero levels by floor, not by XP. Gold and XP from the
  fight are not granted (the engine's `xpReward`/`goldReward` are ignored).
  - The enemies' own player-level scaling (+10% health a level) still runs,
    so the bands above are tuned with it on.
  - Each new level gives what a level gives in the story: health and the
    level's stat pick, taken at once (the bot takes the profession's
    first stat).
- **Threat, weather, light.** These are all off: threat 0, no sky, the
  default light. They are story systems.

### The enemy pool

Regular foes come from `enemies.json`. An enemy is in the pool when all of
these hold:

- `minChapter` ≤ the band;
- it is not a boss (`isBossEnemy` is false);
- it is not `hunterOnly`;
- it is not story-bound. These are excluded:
  - every `*_turned` companion and `inquisition_legate`;
  - the claimants and `tear_herald` (they are bosses, below);
  - `aurel_vane`, `masked_penitent`;
  - `den_*`, `sore_loser`;
  - `kraken_arm` (a ship fight).

The pool has this many enemies per band:

| Band | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Regular foes | 7 | 9 | 12 | 14 | 16 | 18 | 18 | 18 |
| Pack-eligible | 2 | 3 | 6 | 8 | 10 | 12 | 12 | 12 |

**No repeats.** A foe met on one of the last 3 floors is drawn again only
if the pool has nothing else.

### As built (phase 1, v1.845): the bot's numbers

The table above was the starting point. Played by the bot (`tower_bot.dart`,
the headless fight), it was far too hard: the median run died on floor 2.
The Tower's hero climbs alone, with no companion, no shop and no rest.
Phase 1 changes four of the Tower's own numbers. The main game's are
untouched.

| Number | Planned | As built |
|---|---|---|
| Extra on ordinary floors | ×1.00 to ×1.15 | ×0.30 (1–9), ×0.35–0.37 (11–19), ×0.39–0.40 (21–29) |
| Extra on wardens and bosses | ×1.00 to ×1.15 | ×0.18 (5, 10), ×0.22 (15, 20), ×0.23 (25), ×0.24 (30) |
| Hero level after the floor | 1 to 15 | 2 to 18, the story's pace by chapter |
| Between floors | its level's health only | +30% of max health, and 1 potion carried into each fight |

The bot over 500 seeds:

| | Median floor | Floor 20 reached | Top reached |
|---|---|---|---|
| No unlocks | 16 | 30% | 9.6% |
| Every unlock | 17 | 37% | 18.8% |

These are inside the targets of §11. QA's phase 2 confirms them.

### As tuned (v1.848): QA's #834, the user's calls

QA's batch showed the splits were off. The user chose three changes. The
overall difficulty stays as it was.

| Change | Numbers |
|---|---|
| Foes per profession (Tower only) | mage ×0.65, cleric ×1.35, the others ×1 (on the floor's extra) |
| Wardens (5, 15, 25) | ×1.9: extra 0.34, 0.42, 0.44 |
| Bosses | 10 ×1.7 (0.31), 20 ×1.25 (0.28), 30 ×1.1 (0.26) |
| Unlock power | +2% max health for each unlock owned at the start, and +1 potion carried into each fight for every 5 |

Start levels were tried first as the unlocks' power, and they made the
Tower harder. The foes grow with the hero's level: with every unlock, the
top won fell from 10% to 3.6%.

The bot over 1,500 seeds:

| | Median floor | Floor 20 reached | Top won |
|---|---|---|---|
| No unlocks | 17 | 33% | 10.1% |
| Every unlock | 19 | 47% | 19.6% |

- **Professions:** with no unlocks, mage 8.8%, rogue 10.0%, warrior 11.3%
  top won; with every unlock, 16–23%.
- **Bosses won:** 93/89/87% (10/20/30) with no unlocks, so they are now
  gates.
- **Clans and Voidkin:** not tuned. The bot can't see them; the user's
  hand test decides.

## 4. Bosses on 10, 20 and 30

The bosses are the existing boss records, each with its phases. They run on
the boss floor (`bossHealthBaseMultiplier` 1.45 and damage 1.24), and the
Tower's extra goes on top.

| Floor | Chapter | Boss | Phases |
|---|---|---|---|
| 10 | 3 | `inquisition_legate` (the Legate's Champion) | 1 |
| 20 | 5 | `claimant_morrow` (Hesk Morrow) | 2 |
| 30 | 8 | `void_sovereign` (the Sovereign) | 2 |

- The bosses are Narrative's picks (`the-tower-names.md`, each with its
  banner line). The same three every run, so phase 2's win rates mean one
  thing. They are a table in `tower_tables.dart`, so another foe is a
  one-line change.
- A boss is always alone: no pack, no forced affix, no Elite.
- After a boss the offer is a **boss offer**: 3 rewards one rarity step up
  (§5), and a heal of 50% if the hero is below half.

**Wardens on 5, 15 and 25.** A warden is a lighter boss: one enemy with
phases from the band's boss list, minus the floor bosses above.

| Floor | Warden pool |
|---|---|
| 5 | `rat_matriarch`, `dock_overseer`, `smuggler_captain`, `plague_hound`, `kroll_the_branded`, `brine_jack` |
| 15 | `hollow_court_zealot`, `hollow_court_inquisitor`, `knell_keeper`, `horn_taker`, `purifier_vell` |
| 25 | `strand_colossus`, `glass_shepherd`, `white_admiral`, `tear_spawn`, `void_manifestation`, `inquisition_penitent` |

They break the climb into steps of five, and each one guards a better offer
too (one rarity step up, as after a boss).

Clan champions, the other claimants and `tear_herald` are left out of the
first version. They are story duels with lines written for the story.

## 5. Rewards: 1 of 3

After every win the hero is shown 3 rewards, each of a different kind
where possible. **A reward is never gold.**

| Kind | Weight | What it gives | Pool |
|---|---|---|---|
| Item | 30 | one weapon, armour, charm or artifact, equipped or kept | `items.json`, `isEquippable`, by rarity (below); no quest items or materials |
| Die | 10 | a new die for the loadout | `dice.json` minus the companion dice (`liora_die`, `vess_die`, `grosh_die`, `tobin_die`, `malrik_die`) and other clans' dice |
| Skill | 18 | one skill learnt | `skills.json` the hero may learn (race and profession limits), by rarity |
| Spell | 8 | one spell | `spells.json` for the profession (3–4 each); none once all are known |
| Heal | 16 | 35% of max health (50% after a boss or warden) | always offered when the hero is below 40% health (it replaces the lowest-weight card) |
| Clan gift | 14 | from the run's clan: **its die** once a run, then a point in the profession's damage stat | the clan's die (`dice.json` `clan`) |

Weights are per card. The 3 cards are drawn without repeating a kind,
unless a kind's pool is empty.

**Rarity by floor.** One step up after a boss or a warden.

| Floors | Common | Uncommon | Rare | Relic / epic+ |
|---|---|---|---|---|
| 1–9 | 60% | 35% | 5% | 0% |
| 11–19 | 25% | 45% | 27% | 3% |
| 21–29 | 5% | 35% | 50% | 10% |

Items use Common, Uncommon, Rare and Relic (53, 36, 37 and 8 in
`items.json`). Skills use common to legendary (29, 36, 45, 43, 9). For
skills, "Relic / epic+" means epic or legendary.

**Skip.** The hero may refuse all three for **+1 mark**. It's an easy
choice for a full build, and it costs the hero the power.

**Later (not in phase 1).** A die-face card (the forge's face smithing), a
sellsword card, and clan skills, signs and objects as clan gifts: each needs
its own screen, and none is in the headless engine yet. Companions are left
out (§10).

## 6. Clans and dice in a run

**The clan.** It is picked at the start, from the six main clans
(`dominion`, `vigil`, `compact`, `mire`, `crows`, `penitents`) that are
unlocked. It works like this in the run:

- **Standing.** The run sets the hero sworn to the clan at **Friend**, the
  standing its die resonates from (`clan_dice.dart`). The standing is fixed
  for the run: no standing moves and no clan power (that's politics, §10).
- **The clan's rule and specialisation.** The clan's solo signature rule
  and its specialisation cards play in the fight as in the story, because
  the fight reads them from the hero's session.
- **Clan gift cards** (§5) come from this clan only.
- The **clan die** is the best clan-gift card. With resonance on, faces 1–3
  count +1.

**Dice.**

- The run starts with the profession's starter die
  (`startingDiceIdFor`), its starter faces (`starterFaceAssignments`) and
  its starter skills (`starterSkillsFor`), exactly as a new story hero.
- The loadout limit is the story's.
- Die and face cards (§5) are the only way to change dice in a run. There
  is no shop.

## 7. Tower marks and the first unlock tree

**Marks earned in a run** are added at the run's end, win or loss:

| For | Marks |
|---|---|
| each floor cleared | 1 |
| each warden beaten (5, 15, 25) | +2 |
| each boss beaten (10, 20) | +5 |
| the top (floor 30) | +15 |
| a refused offer | +1 |

A death on floor 1 earns nothing. A death on floor 12 earns 11 + 2 + 5 =
**18**. A won run earns 30 + 6 + 10 + 15 = **61** (plus any refused
offers).

**The first unlock tree** has 10 entries. Marks are spent, not lost on
death.

Narrative's ten (`the-tower-names.md`), in their order, cheapest first:

| # | Unlock | Kind | Cost | Needs |
|---|---|---|---|---|
| 1 | Flame Die (`flame_die`) | start die | 10 | — |
| 2 | The Salt Crows (`crows`) | clan | 10 | — |
| 3 | Knight's Bulwark (`shield_t5`) | start item | 15 | — |
| 4 | Cleric (`cleric`) | profession | 15 | — |
| 5 | Tide Die (`tide_die`) | start die | 20 | 1 |
| 6 | The Grey Vigil (`vigil`) | clan | 20 | 2 |
| 7 | Silvered Longsword (`sword_t4`) | start item | 25 | 3 |
| 8 | Ranger (`ranger`) | profession | 25 | 4 |
| 9 | The Cinder Compact (`compact`) | clan | 30 | 6 |
| 10 | Tearglass Die (`tearglass_die`) | start die | 40 | 5 |

The ten cost 210 marks in all, about three and a half won runs. At first
the player has every race, three professions (warrior, mage, rogue) and
three clans (Dominion, Mire, Penitents). A start die is owned from the
first floor and played when it beats the profession's own; a start item is
worn.
Each unlock adds options and never raises a number on its own, so the
balance batch can test "no unlocks" and "all unlocks" as two cases.

## 8. The save slot

The Tower saves under its own keys, apart from the story save
(`saved_game_slot_N`):

| Key | Holds | Written |
|---|---|---|
| `tower_run_v1` | the `TowerRun` in progress (JSON), or nothing | after each fight's result and after each pick |
| `tower_marks_v1` | marks banked, unlocks bought, best floor, runs played, runs won | at a run's end and on each purchase |

The save follows these rules:

- **Quitting mid-fight.** The run reopens at the start of that floor's
  fight with the health the hero had before it. There's no save inside a
  fight, as in the story.
- **Ending a run.** A run ended by death or victory clears `tower_run_v1`
  after its marks are banked.
- **Deleting saves.** Deleting the story saves (`SavedGamesNotifier.deleteAll`,
  the death screen) never touches the `tower_*` keys, and deleting a Tower
  run never touches the story's. A test checks both.

## 9. The fight: what it reuses and the story context it needs

**Reused as is:** the fight itself.

- `FightScreen(enemyId, enemy, additionalEnemyIds, additionalEnemies,
  modifiers, random, landLayers)`;
- the whole engine: dice, faces, skills, spells, signs, clans and their
  dice, affixes, Elites, boss phases, allies;
- the headless fight `simulateSimFight` (`lib/data/sim_combat.dart`) for
  the bot and the phase 2 simulator.

**What the fight reads today**, and what the Tower gives it:

| The fight reads | Where | The Tower gives |
|---|---|---|
| the hero (`playerSessionProvider`) | setup, actions, rewards | **a Tower session notifier** in a `ProviderScope` around the Tower screens. `_SessionNotifierBase` already leaves `_persist()` abstract, so a `TowerSessionNotifier` writes to `tower_run_v1` and never to the story save |
| the chapter (`storyPlayProvider` and `storyDataProvider` via `storyChapterOf`) | `_chapter` | `EncounterModifiers.chapter` = the floor's band; the scene is never read |
| the threat (`reachedChapterProvider`) and the sellsword's damage | setup | an override with the band; the threat is off (see below) |
| the sky (`skyHereProvider`) | setup | an override with null: no weather |
| the ground and light (`geographyProvider` + the current scene's place) | `fight_ground.dart` | `forcedStage` and `landLayers`: a Tower stage (UX-2's art, phase 3) |
| the chest, gold and XP, `lastFightOutcomeProvider` | `fight_rewards.dart` | **one new modifier**, `EncounterModifiers.tower` (below) |
| permadeath and the story restart (`storyPlayProvider.notifier.restart`) | `_leaveFight` | `lossContinues: true`: a loss is handed back to the Tower, never the death screen |

**The `tower` modifier.** Phase 1 adds one field to `EncounterModifiers`,
`tower` (bool). When it is set:

- no chest is rolled;
- no gold or XP is granted;
- no `lastFightOutcomeProvider` is written for a scene;
- the threat is 0.

The fight ends by popping its result (won or lost, and the health left) to
the Tower screen. It touches about 6 lines in `fight_setup.dart` and
`fight_rewards.dart` (Core's files). `fight_screen.dart` is shared, but
only the constructor already takes `modifiers`.

So a fight needs exactly these from the Tower, and no scene:

- **a zone:** none (the stage replaces it);
- **a stage:** `forcedStage`;
- **an enemy record:** `enemies.json` as is;
- **a chapter:** the band.

## 10. Left out of the first version

| Left out | Why |
|---|---|
| Ships, sea fights, `kraken_arm` | their own engine and their own screen |
| Camps, errands, buildings, the forge as a place | the reward cards stand in for the forge |
| Politics: clan power, territory, standings moving, intrigues | the clan is fixed at Friend for the run |
| Quests, scenes, the map, the Journey, narration | no story (the user's rule) |
| Companions as allies, their dice, their remarks | story-bound; a sellsword card instead (§5) |
| Gold, shops, prices | a reward is never gold; there's no shop floor |
| Clan champions, claimants, `tear_herald`, turned companions | story duels |
| Threat, weather, the feature ladder | story systems; every fight feature is open from floor 1 |
| New Game+ on the Tower | later, maybe as "Tower +1": every number ×1.10, as the story's NG+ |

## 11. What phase 1 builds (for the estimate)

Phase 1 is headless and has no UI. All of its files are new and under
`lib/data/tower/`:

- `tower_run.dart`: the run state and its JSON;
- `tower_floors.dart`: the generator and the table in §3;
- `tower_rewards.dart`: the offers and the weights in §5;
- `tower_marks.dart`: the marks, the unlocks and their save.

It also has these parts:

- **The modifier:** `EncounterModifiers.tower` (§9), and the
  `TowerSessionNotifier`.
- **The tests:**
  - the same seed gives the same 30 floors and offers;
  - every floor's foes are in its pool;
  - a bot (`simulateSimFight`, picking the first reward that adds the most
    health or damage) plays 20 seeds to the end, win or loss, with no
    error;
  - the Tower and story saves stay apart.

QA's phase 2 then reports the bot's win rate per floor.

**What I'd aim the balance at** (first targets for phase 2, to be changed
with the user):

| Measure | Target |
|---|---|
| A naive bot's median floor reached | 12–16 |
| The bot reaching floor 20 | 25–35% |
| The bot winning floor 30 | 5–10% with no unlocks, 15–25% with all |

## The clans offer their oaths (v1.855)

The user's call, after playing it: "in the Tower you don't choose clans,
they propose you rewards like in the story mode". Their answers: several
clans per climb, an oath on any floor while a clan is left, the rule and
the die at once.

- **The start** is people and calling only: a run begins sworn to none
  (`towerStart`'s `clanId` is gone from the screen; kept, optional, for an
  old save sworn at the start, which keeps its clan as its first).
- **The oath card** (`TowerRewardKind.clanOath`, `id` the clan): always on
  the first floor won; later on `towerOathChance` (35%) of the offers while
  a clan of the run's pool is left; one oath an offer at most, in one of
  its three slots, drawn from its own stream (the other cards draw as
  before). Refused, it is the usual mark.
- **The pool** (`TowerRun.clanPool`) is the clans open when the run began
  (`TowerProgress.clans`: the three of the start, and Salt Crows, Grey
  Vigil, Cinder Compact once unlocked: an unlock now means "this clan can
  be offered").
- **Sworn** (`TowerRun.clanIds`, in the order sworn): the clan's die is
  owned at once; in the fight each sworn clan stands at Friend, the first
  one point above, so the story's own rules decide: one main clan
  (`mainClanOf`: the patron, the first sworn), its die the one that
  resonates; the other clans' dice roll plain. Nothing stacks.
- **The clan's gift** (stat points) is offered only once a clan is sworn,
  one point as before: it does not grow with the clans sworn.
- **Balance** (1,500 seeds, the bot taking the first oath it sees): no
  unlocks, median 17, floor 20 34.7% (33.2% before), top 10.5% (10.1%);
  every unlock, median 19, top 16.5% (19.6%). The spread between clans is
  gone: as the main clan, each wins the top 10–11% with no unlocks,
  14–18% with every unlock (it was Dominion 15% to Mire 4.7%).

## The level-up, the main game's way (v1.857)

The user's call: the Tower takes the main game's "earning offers", in
three steps; this is the first: **the level-up's stat picks are the
player's**, as in the story (stat-picks.md), not a point given to the
damage stat.

- **The picks are held by the run.** A level gained earns
  `levelStatPicks` (1) pick; `towerPendingPicks(run)` is the picks the
  run's level earned less those taken (`TowerRun.statPicks`, the offer
  taken for each, saved as `picks`). An old save (no `picks`) keeps the
  points its levels gave then.
- **The pick is the main game's**: `towerStatPickOffer(run, data)` draws it
  with `drawStatPick` (three offers, one rarity, the calling, the habit and
  a turn), from the run's own stream (`TowerStream.pick`), as the hero
  stands; `towerTakeStatPick(run, data, index)` takes one; the hero
  replays every pick (`towerHeroOf`).
- **The picks come before the floor's cards**: the screen opens the main
  game's Level Up on `TowerLevelUpSession(run, data).wrap(LevelUpScreen())`
  (the Tower hero's own session, the story save untouched) after a floor
  that gains a level; a pick still waiting when the cards are taken goes to
  the calling (`towerPick`), so the climb never stalls.
- **The bot** takes its picks as the story's bot does (`simBuildShares`,
  `statPickForShares`).
- **Balance**: the story's builds spread their points (about 60% to the
  damage stat), so the climb came out harder (no unlocks, median 15, top
  7.0%); every foe of the Tower is now at `towerFoeScale` (0.95) of its
  floor's extra: no unlocks, median 17, floor 20 34.9%, top 10.7%; every
  unlock, median 19, top 16.3% (1,500 seeds), as at v1.855.

## The spoils chest and the boons (v1.860)

Step 2 of the main game's earning offers (the user's call): the cards of §5
go, and a floor won pays the main game's way.

- **The spoils chest, every floor won** (`towerSpoilsFor`): the story's own
  chest (`rollLootBox`: the fortune roll with the hero's Luck, a boss floor
  never below Gold, a warden or an Elite raised as an Elite is), from the
  floor's own stream (`TowerStream.spoils`). The Tower keeps its gear and
  its potions; never its gold (nor charms, tomes or materials). The run
  holds each floor's chest (`TowerRun.spoils`, saved as `spoils`); the hero
  wears its gear when it beats what it wears.
- **The bag** (`TowerRun.potions`, `antidotes`): the chest's potions (a
  major one is two, as in the story) and antidotes, carried from floor to
  floor on top of the flask that fills every floor (`towerFlask`). A fight
  drinks the flask first: what it leaves (`towerAfterFight`'s
  `potionsLeft`, from `TowerFightSession`) is what the bag still holds.
- **A boon on floors 5, 10, 15, 20 and 25** (`towerBoonFloors`; 30 ends the
  run): a choose-one of a skill, a die and a spell (`towerBoonKinds`), the
  rarity of §5's draw. Refusing it is still a mark.
- **The clans' oaths after the spoils**: always on the first floor won,
  then on 35% of the floors that are not a boon's, while a clan is left
  (v1.855). Many floors offer nothing: the screen shows the spoils and goes
  on, and nothing refused is no mark.
- **No heal cards, item cards or clan gifts** any more (an old save's offer
  still takes them).
- **The bot** takes a boon's skill first (a die first left the ranger at 1
  top in 70).
- **Balance** (1,500 seeds): see the table below. Fewer skills and dice than
  the cards gave hit the unlocked runs (every unlock, top 7%): an unlock is
  now `towerHealthPerUnlock` .04 more health (was .02); the ranger's foes at
  .88, the rogue's at 1.04 (`towerProfessionScale`). QA's floor-20 bound
  goes to 20% (more climbs end between 10 and 20; the median and the top
  hold).

| 1,500 seeds | median | floor 20 | top | top by profession |
|---|---|---|---|---|
| v1.857, no unlocks | 17 | 34.9% | 10.7% | |
| v1.860, no unlocks | 17 | 23.9% | 10.2% | mage 9.2, warrior 10.0, rogue 11.4 |
| v1.857, every unlock | 19 | | 16.3% | |
| v1.860, every unlock | 18 | 31.4% | 15.7% | mage 21.8, warrior 15.9, cleric 15.9, rogue 12.5, ranger 12.2 |

By main clan (every unlock): dominion 20.1%, mire 17.5%, crows 16.5%,
compact 15.3%, vigil 14.9%, penitents 10.3%. The bag ends a climb with about
7 potions (no unlocks) to 11 (every unlock): the bot drinks only below 40%
health.
