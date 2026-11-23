# Engagement review: why a player keeps playing, and where they stop

The user's request (via the manager): a review of the game's mechanics and
what makes them compelling. Why does a player keep playing, and where would
they stop? This is a report for Core. **It changes no rule, number or data.**
Every proposal waits for the user.

## Sources

| Tag | What | Version | Runs |
|---|---|---|---|
| **EG992** | My batch: `simulatePlaythroughs`, typical (T) and competent (C), seeds 1..100, one run per seed, the 25 race x profession pairs x 4 goals (the plan of `difficulty-review-1.914/`). The `onFight` hook read the save before every encounter: level, skills, dice, die in play, gear, signs, specs, titles, spells, companions, gold. Per-chapter table: `engagement-review.csv`. Throwaway harness `test/zz_engage_test.dart`, deleted. | v1.992 (main) | 100 T + 100 C |
| **TP933** | `typical-player.md` | v1.933 | 100 x 3 policies |
| **B976** | `combinations-review.md` | v1.976 | 100 T + 100 C |
| **DS977** | `die-swap.md` | v1.977 | 4 x 100 |
| **GS989** | `gear-sets.md` | v1.989 | 2 x 100 |
| **CD989** | `clan-dice.md` (branch `claude/core-clandice`) | v1.989 | 8 x 100 |
| **TW961** | `docs/qa/tower-1.961.md` (QA, Tower bot) | v1.961 | 2,000 seeds |
| **TB855** | `docs/qa/tower-balance.md` (QA) | v1.855 | 2,000 seeds |

An **encounter** is one fight node of the story (up to 3 tries). A **big
change** is one that changes how the next fight plays: a new skill, a die
owned or rolled, worn gear, a specialisation, a spell or a companion. Levels,
signs and titles are counted apart. The simulator plays no party combos and
no duos (B976), and it does not feel anything: what follows is how often
things happen, not how they feel.

## 1. The loops

### Core loop: one fight

| | |
|---|---|
| What the player wants next | Win, then the chest. The chest tier rises with play: flawless +8 fortune, swift (2 rounds or fewer) +8, a critical finish +8, a pack +6 per extra foe (`lib/combat/loot_box.dart:25-31`). |
| How soon | About 6.8 rounds a fight (EG992: T 6.78, C 6.74). Wall time: **guess** 1 to 2 minutes. |
| Winning | T wins 92.8% of fight tries (EG992: 7,282 won, 563 lost); 98.7% of encounters within 3 tries (TP933). |
| On a loss | Retreat and retry. A retreat costs 20% of gold, at least 10 (`lib/providers/player_session_model.dart:106-114`). Nothing else is lost. With Ironman (permadeath, off by default) the story restarts: level, gold, stats and dice kept; items, skills, signs, clan standing and titles lost (`lib/providers/session_skills_combat.dart:448-462`, called from `lib/screens/fight/fight_rewards.dart:797`). |

### Core loop: one story run

| | |
|---|---|
| What the player wants next | The next chapter, the next level card, the next companion. |
| How soon | 74 encounters, 7 chapters, 17 quests, 22.5 level-ups a run (EG992, T). A level-up every 3.2 encounters, steady to the end. |
| On finishing | An ending (100/100 runs in TP933 and EG992), one of 7 throne titles. Replay: 25 race x profession pairs, 4 alignments, 6 clans. Nothing carries into the next story run. |

### Meta loops

| Loop | Wants next | How soon (EG992, T unless said) | Kept on failure / finish |
|---|---|---|---|
| Chapters and story | the next beat | a chapter every 9.7 encounters; very uneven: ch3 16.2 encounters, ch7 **2.6** | all, except Ironman |
| Clans (3 suitors a card) | a better card, a rank | 66 offers a run: 23.5 at levels, 35.4 at bosses, 7 at chapters | standing kept |
| Camp (15 houses, from ch3, `lib/data/camp_state.dart:7`) | the next house | 10 houses built in 100/100 runs; Banner Loft 56, Shroud Shrine 31 | kept |
| Camp rolls (reroll, banish, raise) | a better card | T 13.6 rerolls, 11.5 banishes, 1.8 raises a run | charges refill on level-up, not on a clock |
| Skills and merges | a skill for an open face | 8.9 new skills a run T, 3.8 C. Merges **0/100 T**, 10/100 C | kept |
| Dice | a better die | 2.8 dice gained a run; 1.0 die change a run; **24 T runs never change die** | kept |
| Gear sets | the third piece | a whole set owned in 18 T / 26 C runs; **worn in 0** (GS989) | kept |
| Titles (70) and achievements (19) | collection | 16.5 titles a run; one active at a time | kept |
| The Tower (main menu, `lib/screens/main_menu_screen.dart:316`) | a higher floor, marks | median floor 18; the top in 13.2% with no unlocks, 24.9% with all (TW961) | run lost: back to floor 1; marks and unlocks kept. All 10 unlocks cost 210 marks (`lib/data/tower/tower_tables.dart:636-649`); about 26 marks a run (TB855): **about 8 climbs** |

The Tower is the only true roguelite loop: a run can end, and what you earn
shortens the next. The story loop never fails a run (outside Ironman).

## 2. Reward rhythm

Mean encounters between two events of a kind, over the whole run (EG992):

| Event | T per run | T mean gap | T 90th pct gap | C per run | C mean gap |
|---|---|---|---|---|---|
| level-up | 22.5 | 3.2 | 5 | 22.2 | 3.2 |
| anything (level, skill, die, gear, sign, spec, title, spell, companion) | 39.5 | 1.8 | 3 | 43.2 | 1.6 |
| a big change | 19.7 | 3.0 | 6 | 17.4 | 3.7 |
| new skill | 8.9 | 4.6 | 10 | 3.8 | 11.9 |
| new sign | 10.0 | 6.3 | 14 | 12.6 | 4.9 |
| new title | 16.5 | 4.1 | 9 | 18.3 | 3.7 |
| gear worn changes | 6.5 | 8.5 | 21 | 8.0 | 7.1 |
| new specialisation | 4.8 | 8.1 | 19 | 3.4 | 13.3 |
| new companion | 3.8 | 4.4 | 8 | 3.6 | 4.0 |
| new chapter | 7.0 | 9.7 | 20 | 7.0 | 9.5 |
| die owned | 2.8 | 12.9 | 26 | 2.1 | 18.3 |
| spell | 1.6 | 17.5 | 34 | 1.5 | 17.4 |
| die rolled changes | 1.0 | 17.5 | 34 | 1.2 | 19.8 |

**Something** is gained every 1.8 encounters, and no run goes more than 5
encounters without something (EG992, max 5). The drip never stops: levels
carry it. **Big changes** stop. Per chapter (T, EG992; C in the CSV):

| Ch | Encounters | Level-ups | New skills | Gear changes | Die changes | Big changes | Big per encounter |
|---|---|---|---|---|---|---|---|
| 1 | 3.9 | 0.6 | 0.5 | 0.6 | 0.0 | 0.8 | 0.22 |
| 2 | 7.3 | 2.8 | 2.6 | 1.8 | 0.3 | 4.6 | **0.63** |
| 3 | 16.2 | 3.9 | 3.5 | 2.0 | 0.6 | 7.5 | 0.46 |
| 4 | 11.9 | 3.7 | 1.3 | 0.7 | 0.0 | 3.2 | 0.27 |
| 5 | 15.6 | 4.6 | 0.6 | 0.3 | 0.0 | 1.8 | **0.12** |
| 6 | 10.2 | 2.7 | 0.1 | 0.9 | 0.1 | 1.2 | **0.12** |
| 7 | 2.6 | 1.1 | 0.1 | 0.1 | 0.0 | 0.2 | **0.08** |
| 8 | 6.3 | 3.0 | 0.2 | 0.1 | 0.0 | 0.3 | **0.05** |

- The build is settled by chapter 4. From chapter 5 to the end (35
  encounters, nearly half the run) a typical player makes about 3.5 big
  changes in all.
- The longest stretch with no big change: mean **17.8** encounters a run,
  max **54** (T); C 13.8, max 41 (EG992).
- **Gold piles up.** Median gold at the first encounter of chapter 5: 2,417;
  chapter 8: **6,203**; at the end 6,236 (T, EG992). C: 5,814 at chapter 8.
  From chapter 6 nothing a typical player wants costs that much.

## 3. Dead zones

### Stretches with no new decision

| Where | Evidence | Why |
|---|---|---|
| Chapters 5 to 8 | 0.05 to 0.12 big changes per encounter (EG992) | open faces are full, the die is settled, gear stops beating the worn piece |
| Mid-game fights are not in doubt | first-try win T: ch2 98.9%, ch3 99.5%, ch4 97.9%, ch5 93.7%, ch6 92.7% (TP933) | the typical player has companions and plainly better gear; the tension is in chapter 8 (81.4%) and the bosses |
| Gold after chapter 5 | 6,203 median at ch8 (EG992) | nothing late to spend on |

### Choices always or never taken (share of offered cards taken, EG992)

| Card | T offered / run | T taken | C offered / run | C taken |
|---|---|---|---|---|
| sworn (a clan's oath) | 1.3 | **94%** | 1.3 | **100%** |
| specialisation | 6.1 | **82%** | 3.6 | **97%** |
| die | 3.2 | 70% | 7.8 | 19% |
| object | 38.9 | 51% | 22.4 | 14% |
| title | 15.1 | 29% | 10.8 | 59% |
| skill | 38.4 | 28% | 74.5 | **5%** |
| sign | 101.4 | 22% | 85.7 | 50% |
| perk | 10.4 | **5%** | 7.1 | 43% |

- A specialisation or an oath beats the other two cards almost every time:
  that card is not a choice.
- The competent player takes 4 skills of 75 offered: once the open faces
  are full a skill card is dead (also B976: T 1053 / 3858).
- The typical player's 5% perks is the policy (it reads only attack and
  armour), not the game. Treat as unmeasured.
- Final die: starter 27, shadow 20, headsman 16 of 100 T runs (EG992); 24 T
  runs never change die. Same picture as B976 (A1, A2, A3 dominant).

### Systems a player may never meet

| System | Evidence |
|---|---|
| Merges | 0/100 T, 10/100 C (EG992); 0/100 T in B976 |
| 7 of 10 fusions | never offered in 200 runs (B976) |
| `mage_stormcaller`, `rogue_gale_cut` | never offered in 200 runs (B976) |
| Duo techniques | the two commonest pairs have none (B976) |
| A whole gear set worn | 0 in 200 runs (GS989): the Void Banner holds the Top slot all run |
| Element reactions | need a Wind, Ice or Light hero die with the usual parties (B976) |
| Shroud Shrine, Banner Loft | built in 31 and 56 T runs (EG992) |
| Chapter 7 | 2.6 encounters (EG992): a short chapter between two long ones |

### Seams with other sessions (pass 3)

- **Skills that play the same (Core data, Narrative text).** 15 groups of
  skills in `assets/gamedata/skills.json` have identical numbers; some differ
  only in who may learn them. `warcry` (line 1199) and `inner_fire` (1259)
  have no difference at all but text. `human_diplomacy` (126, "a sharp word
  can turn the tide") is `power_strike` (919) for humans. Others:
  `second_wind`/`mage_mana_shield`, `quick_heal`/`mending_touch`, four Earth
  stances (`warrior_iron_stance`, `ranger_beast_bond`, `bulwark_stance`,
  `stone_resolve`). No code keys on these ids except icons
  (`lib/utils/pixel_icons/skill_icons.dart`). A player who reads the text
  expects a different effect; the fight shows the same one. This undercuts
  "combos you discover".
- **UX:** a skill card offered when no face is open is still shown as a full
  card. Whether it says what it would replace is UX's to check.
- **Maps:** no finding; the dead zones are not about travel.

## 4. Hooks: what exists, how strong

| Hook | Exists? | Strength (evidence) |
|---|---|---|
| Steady drip | yes: level every 3.2 encounters, something every 1.8 | **strong** all run (EG992) |
| "One more fight" | the next level card is always 1 to 5 encounters away | strong early; weak late, because the late cards change little |
| Near-miss | chest fortune for flawless, swift, critical finish, reading telegraphs (`loot_box.dart:25-31`); bosses at 79 to 90% first try late (TP933) | medium: rewards are shown, but most fights are not in doubt |
| Build-defining find | the die (shadow, headsman, clan dice), specs, ascensions | strong in ch2 to 3, then gone (0.0 die changes ch4 to ch8, EG992) |
| Set and collection completion | 2 sets, 36 dice, 70 titles, 19 achievements | weak: no set worn (GS989); titles come 16 a run with no target shown |
| Rare drops | Hollow Court seal 12 to 30%, set pieces 25 to 40% (GS989) | weak: the pieces lose to what is worn |
| Combos discovered, not read | reactions, party combos, duos, merges | hidden (B976); clone skills work against it |
| Run-end goals | endings, throne titles | medium: no score, no "next time try" |
| Roguelite meta | the Tower | **strong and fair**: about 8 climbs to all unlocks, the top 13% to 25% (TW961, TB855) |
| Daily goals | none | none (no clock in game rules) |

## 5. Fair limits

No pay wall, no wait wall, no energy, no timer in the rules: the only
`DateTime.now` calls in `lib/` stamp saves, run an animation or name a branch
(`save_game_provider.dart:144`, `land_crossing_screen.dart:333`,
`settings_screen.dart:631`). No streak reward.

| Mechanic | Leans the wrong way? | Verdict |
|---|---|---|
| Ironman: a loss restarts the story; items, skills, signs, standing and titles lost | a loss that wipes progress | **fair as is**: off by default, chosen in settings; level, gold and dice kept. Keep it opt-in. |
| Retreat costs 20% of gold | a loss penalty | mild; with 6,000 gold late it is felt early only |
| Chest pity: +15 fortune per Wooden chest in a row, reset at Silver (`loot_box.dart:31`, `551`) | a pity system | **benign**: upward only, shown as a fortune line (`fortune_pity`), no money |
| Risky gifts (a better gift at a price the die names) | a gamble | fair: odds are shown, "nothing" is never a result, standing rises anyway (`lib/data/risky_gifts.dart`) |
| Tower run loss | run ends | fair: marks and unlocks kept, a refusal pays a mark (`tower_run.dart:438`) |
| Camp roll charges | could become a timer | fair today: they refill on level-up, not on time |

Rule for every proposal below: no clock, no streak, nothing bought.

## 6. Ranked proposals

Ranked by impact x cost, after a self-review (each re-checked against the
numbers above). None is built.

**1. Late cards that change the build. M. Needs the user's choice.**
When every open face is full, a skill card offered on a face's skill
becomes "**rank up** X" (+1 tier, the mastery rule that exists) or "swap
into face N", instead of a dead card.
- Where: `lib/data/offers.dart`, `skill_tree.dart`; the simulator in
  `sim_growth.dart`.
- Expected: big changes in ch5 to ch8 from about 3.5 to about 10 a run
  (**estimate**); skill take rate for C from 5% up.
- Risk to balance: medium. Late power rises; re-check the boss bands
  (`boss_balance_test`).
- Touches: UX (card label), Narrative (one line per card kind).

**2. A late gold sink with a decision. S to M. Needs the user's choice.**
Give the median 6,000 gold a use from chapter 5: the Hammersmith's
inscriptions and recasts at rising prices, or a fourth camp tier.
- Where: `lib/data/town_services.dart`, `shop_pricing.dart`,
  `assets/gamedata/houses.json`.
- Expected: gold at ch8 well under 6,203; one more decision per town.
- Risk: low. Measure win rates before and after.
- Touches: UX if a new screen row, Narrative for names.

**3. Settle the always-taken cards. S. Quick win.**
A specialisation (82 to 97% taken) and an oath (94 to 100%) are dealt
beside two cards they always beat. Deal them alone, as a gift with a yes or
no, or pair them only with each other.
- Where: `lib/data/offers.dart`.
- Expected: the other two card slots are no longer wasted; no power change.
- Risk: low. Touches: UX (a one-card offer).

**4. A ready merge says so (B976 proposal 7, still open). M. Quick win.**
When both inputs are known, the Skillwright shows on the travel list, or a
suitor brings the recipe.
- Where: `offers.dart`, `skill_craft.dart`.
- Expected: merges from 0/100 T to an estimated 30 to 50 (B976).
- Risk: low to medium: merges are the strongest skills (median 23.4).
- Touches: UX (hint), Narrative (suitor line).

**5. Give the clone skills one difference each. M. Needs the user's choice.**
15 groups play the same. Give each member a small keyword that exists
(a status, a second strike, a splash, a heal on hit), matching its text.
- Where: `assets/gamedata/skills.json` only.
- Expected: "discovered" combos; the text matches the fight.
- Risk: medium; re-run B976's skill-power table.
- Touches: Narrative (text checked against the new effect), Art (only if an
  icon must change).

**6. Chapter goals with a chest, no clock. M. Needs the user's choice.**
Three optional goals a chapter, drawn from what exists: beat the boss
flawless, win a fight on a weakness, finish one side quest. Each met goal
raises the chapter's last chest by a tier. Nothing lost if missed.
- Where: new `lib/data/chapter_goals.dart`, `chapter_loop.dart`,
  `loot_box.dart` (a tier floor that exists).
- Expected: a reason to play a known fight well; near-misses become visible.
- Risk: low.
- Touches: UX (a goal card), Narrative (goal lines).

**7. A set the player can actually wear. S. Needs the user's choice.**
The Void Banner holds the Top slot all run (GS989). Either move it to its
own banner slot, or give each set a piece in another slot.
- Where: `assets/gamedata/items.json` (slot), `item_sets.json`.
- Expected: whole sets worn in some runs (0 today).
- Risk: low (GS989: owning sets does not move the win rate).
- Touches: UX (the slot on the character sheet).

**8. Pace chapter 7. S to M. Needs the user's choice.**
2.6 encounters between chapters 6 (10.2) and 8 (6.3). Add one road
champion or a side fight, or fold it into chapter 8.
- Where: `assets/Cleaned_Narrative_DAG.json` (Narrative's), road events
  (Core).
- Expected: a steadier climb into the finale.
- Risk: low. Touches: Narrative (owner of the story graph).

**9. A visible collection. M. Needs pictures first.**
A codex of the 36 dice, the 70 titles and the sets, found and not yet found,
with where each comes from.
- Where: data exists (`dice.json`, `titles.json`); a new screen.
- Expected: a target for replays; collection completion as a goal.
- Risk: none to balance.
- Touches: UX (screen), Art (silhouettes), Narrative (hints).

| # | Proposal | Size | Mark | Other sessions |
|---|---|---|---|---|
| 1 | Late cards that change the build | M | needs the user's choice | UX, Narrative |
| 2 | Late gold sink with a decision | S to M | needs the user's choice | UX, Narrative |
| 3 | Deal specs and oaths alone | S | quick win | UX |
| 4 | A ready merge says so | M | quick win | UX, Narrative |
| 5 | One difference per clone skill | M | needs the user's choice | Narrative, Art (maybe) |
| 6 | Chapter goals with a chest | M | needs the user's choice | UX, Narrative |
| 7 | A set the player can wear | S | needs the user's choice | UX |
| 8 | Pace chapter 7 | S to M | needs the user's choice | Narrative |
| 9 | A visible collection | M | needs pictures first | UX, Art, Narrative |

Left out on review: a daily Tower seed (a clock by another name; ask the
user), harder mid-game fights (a difficulty call already made in
`difficulty-review.md`; ask the user).

## 7. Simulator performance

| Batch (EG992, 100 runs, `onFight` save read each encounter) | Wall time |
|---|---|
| typical | **22 s** |
| competent | **29 s** |

- Both ran at once on a 4-core box, compile included.
- The extra 30% for C is most likely `prepareForFight`'s loadout search
  (`simBestLoadout`) before every encounter (**not profiled**).
- Easy speedup: the 100 seeds run one after another in one test. Splitting
  the seeds over 4 processes (`SIM_SEEDS=1-25` and so on) would cut a batch
  to about a quarter of the wall time. That is a harness change, no `lib/`
  change.

## 8. Duplicated or dead in Core's area

**Duplicated data:** the 15 groups of clone skills (§3).

**Public functions used only by tests** (no caller in `lib/`; a token count
over `lib/` and `test/`):

| File:line | Name | Note |
|---|---|---|
| `lib/data/politics_events.dart:990` | `eventVariantFor` | test probe |
| `lib/data/politics_events.dart:999` | `eventDue` | test probe |
| `lib/data/stat_pick_text.dart:114` | `statPickEffect` | the screen uses `statPickEffects` |
| `lib/data/enemy_groups.dart:23` | `enemyGroupNameKey` | not read by any screen |
| `lib/data/forge_roll.dart:359` | `forgeSheetFor` | test only |
| `lib/data/expedition_kinds.dart:590` | `kindSceneKeys` | test only |
| `lib/combat/specialisations.dart:103` | `isMainSpec` | test only |
| `lib/data/tower/tower_events.dart:460`, `:676` | `towerStoreClanOf`, `towerParleyClanOf` | test only |
| `lib/data/description_text.dart:83` | `unresolvedPlaceholdersIn` | **intended**: the content test's check |
| `lib/data/tower/tower_bot.dart:35`, `:395` | `towerDataFromAssets`, `playTowerBatch` | **intended**: the bot's entry points |
| `lib/data/world_leg_path.dart:206`, `lib/providers/travel_history_provider.dart:41` | `worldLegPathForScenes`, `worldLegPathProvider` | test only; on the seam with Maps |

These are candidates for the Cleanup session (wave 2), not deletions here:
each needs a check that no screen is about to use it.

**A comment that says the wrong thing:** `lib/providers/permadeath_provider.dart:23-24` says a loss keeps "level/stats/skills, losing items"; the code wipes the skills, signs, standing and titles too (`session_skills_combat.dart:448-462`). One-line fix for Core.

Checked and **not** duplicated: the weakness multiplier. The simulator's die
value reads `elementMultiplierFor` (`lib/data/sim_policy.dart:297`), the
fight's own rule (`lib/combat/enemy_intent.dart:93`).

## 9. Core's tests, three runs

The families asked for: `test/sim_*`, `test/qa_*sim*`, `*dice*`, `tower_*`,
`clan_*`, `fight_*`; 102 files, 518 test entries, run three times in a row
with `flutter test --reporter json` on v1.992 (4 cores).

| Run | Wall time | Passed | Not passed |
|---|---|---|---|
| 1 | 306 s | 516 | 2 |
| 2 | 281 s | 516 | 2 |
| 3 | 282 s | 516 | 2 |

- **No real failure, no flaky test**: every entry gave the same result all
  three times.
- The 2 not passed are **loading errors, not tests**:
  `test/fight_markers_harness.dart` and `test/fight_qa694_harness.dart`
  match the `fight_*` glob but are helper harnesses with no `main`. CI runs
  only `*_test.dart`, so it never loads them. Nothing to fix.

## 10. Questions only the user can answer

1. Should the late game (chapters 5 to 8) bring new build choices, or is a
   settled build the reward for the early game?
2. Should mid-game fights be in more doubt for a typical player (93 to 99%
   first try today), or is the story the draw there?
3. Is a daily or seeded Tower climb wanted, with no streak and no reward for
   coming back? Or no clock of any kind?
4. Should the clone skills stay alike (a race's or profession's version of
   the same move), or should each play differently?
5. Should something carry from one story run to the next (a codex, a title,
   a starting card), as the Tower's marks do?
6. Gold: should it run short late, or stay plenty?
7. Chapter 7: is it meant to be short?
