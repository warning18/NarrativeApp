# Chapter 1 review: Core's part (v1.606)

Read-only review of main at v1.606.0 (05982973): rules, numbers and state in
chapter 1 (nodes 0 to 1210, Alster to the White Wells), Core's code on the
Journey, fight and camp screens, and the simulator's pins. Nothing here is
fixed yet; the user ranks first. No simulation was run: the numbers come from
the data and what the tests already measure.

**Severity:**
- **blocks play:** the game can't go on;
- **wrong number:** a value or state the player sees is wrong;
- **cosmetic:** wrong but harmless;
- **cleanup:** code only.

**Size:** the lines a fix takes.

## 1. Rules, numbers and state

### Starting heroes

From `game_config.json` (20 HP, 2 damage, 0 armour) plus each race's and
profession's bonus. Each cell is HP / damage / armour.

| race \ profession | warrior | mage | rogue | cleric | ranger |
|---|---|---|---|---|---|
| human | 29/2/0 | 15/2/0 | 26/2/0 | 30/8/1 | 23/2/0 |
| elf | 27/3/0 | 13/3/0 | 24/3/0 | 28/9/1 | 21/3/0 |
| dwarf | 33/2/1 | 19/2/1 | 30/2/1 | 34/8/2 | 27/2/1 |
| orc | 31/3/0 | 17/3/0 | 28/3/0 | 32/9/1 | 25/3/0 |
| voidkin | 26/3/0 | 12/3/0 | 23/3/0 | 27/9/1 | 20/3/0 |

- **Gold:** 100 to start, plus 20 for a human, 30 for a rogue and 10 for a
  ranger.
- **Shops:** none in chapter 1. Every shop has `minChapter` of 2 or more.
- **Where gold goes:** the 30-gold toll, fines, the casino chain, and the two
  10-gold offerings (1130, and Vica's "count coins").
- **Locked choices:** both offerings are `pays` choices, shown locked when the
  hero has less than 10 gold; the other choices there are free.
- **Charges you can't pay:** the other gold charges clamp at 0, so none can
  lock the story.
- **End of chapter 1** (estimated from the story data):
  - XP from fights: about 30 to 460, so level 1–3, or 2–4 with the banner
    quest's +150 XP at Saltmouth;
  - gold: about 150–500.

### Findings

| # | Where | Finding | Severity | Size |
|---|---|---|---|---|
| R1 | `story_recruits_provider.dart:35`, `story_providers.dart:275` | **Vica joins a hero who has not met her yet.** Loading a save merges its history into the current run's visited scenes and never shrinks them. A save from before 1150_vica, loaded after reaching it, gets her at once, and she can never leave. The same happens when a character is made on a save left on node 0. Fix: read `{...history, currentNodeId}`, which a save restores exactly, not `visitedNodeIds`. | wrong number (state) | 3 |
| R2 | DAG 1210 and 2015_vess (Narrative) | **Meeting Vess pays +5 Vigil twice.** A void-marked hero gets `vigil +5` at 1210 and again at Saltmouth's "Hear her out": the hub row there no longer hides on `met_vess` since v1.602, and each choice has its own politics key. | wrong number | 1–3 |
| R3 | DAG 2015 hub row (Narrative) | **Old saves that met Vess in chapter 1 meet her again.** These are saves from before v1.602. The Saltmouth row shows again and re-offers her finished quest. `recruitAlly` refuses a second Vess, so she is never doubled. Fix: hide the row on `q_ch1_vess_in_the_dark_accepted`. | cosmetic | 1 |
| R4 | `story_recruits_provider.dart:33,55` | **Vica can join one step late on a save past her scene.** If the session loads after the first check, nothing checks again until the next story step. Fix: also listen to the session's load. | cosmetic | 3 |
| R5 | `player_session_provider.dart:~3494` | **A latent hole in the "Vica never leaves" rule.** The intrigue path's `'leaves'` and `'lost'` cases call `_removeAlly` without the permanent check, and its approval path skips the −12 floor. No intrigue names Vica today, so nothing triggers it. The `'lost'` case also passes `lost: false`. | cleanup (latent bug) | 4 |
| R6 | `enemies.json:148` | **The rat matriarch is fought in chapter 1 but tagged chapter 2.** It has `minChapter: 2` and is a forced chapter-1 fight at 850 and 855. It is also chapter 1's hardest fight (30 HP, 4 damage), fought alone before Vica, with no lose path. | wrong number | 1 |
| R7 | `player_session_provider.dart:6012` | **Permadeath replays chapter 1 with the run's state.** It keeps companions, flags, gold and level, so Vica walks through Alster, the gold choices pay again, and one-time hub choices stay hidden. Permadeath is opt-in, so this is a design question. | design | — |
| R8 | professions and races | **The spread of starting heroes is wide.** A voidkin mage starts with 12 HP and an elf mage with 13. The cleric leads every other profession on HP, damage and armour (v1.601 on purpose; Vica guards a caster most). | design | — |

**Checked, no problem:**
- **Recruit races:** two recruits of Vica cannot race; `recruitAlly` is
  synchronous until its first await and refuses a second.
- **New Game** from the menu wipes the visited scenes.
- **Vica's mood:** her approval changes at 1150_vica apply, and her floor holds.
- **Benching and losses:** `canBench`, `setAllyActive` and `storyLossOf` agree.
- **Automations:** `script_trigger` ones are never executed, so nothing fires
  twice on a revisit.
- **Double rewards:** no reward is paid by both a quest turn-in and a scene.

## 2. Code (Core's logic on the Journey, fight and camp)

| # | Where | Finding | Severity | Size |
|---|---|---|---|---|
| C1 | `fight_screen.dart:718-749` (shared) | **The fight reparses tables on every rebuild.** Each `build` reparses item sets, factions, subclans, titles and spells, and rebuilds the clan, host and blessing lists. The fight calls `setState` at about 58 sites (every roll and log line). Parse once behind `_partyBuilt`. | cleanup (performance) | 10 |
| C2 | `city_provider.dart:207` | **The Journey's list of places rebuilds too often.** `districtPlacesProvider` watches the whole session, so any gold, potion or clock change recomputes it. It needs only `flags` and `completedQuestIds`, a select like `lockedDistrictsProvider` uses. | cleanup (performance) | 2 |
| C3 | `chapter_loop_provider.dart:170` | **The camp recomputes companion leads on every session change.** `companionLeadsProvider` watches the whole session and runs `placeCompanionLeads` for each place. Use a record select. | cleanup (performance) | 6 |
| C4 | `chapter_loop_provider.dart:24,34,53` | **Three chapter providers watch the whole story state.** They also fire on excursion-queue changes; select the node and history instead. | cleanup | 3 |
| C5 | `choice_flow_provider.dart:15` | **The story's stops are indexed twice at startup.** `storyStopsProvider` builds once with empty city plans, then again when they load. Its index is a fixpoint loop over the reached scenes. Return null until the plans load. | cleanup | 2 |
| C6 | `sim_combat.dart:335-348` | **The simulator's damage is lower than the game's.** The game's `_totalDamageFor` (`fight_queries.dart:113-139`) also adds stat-scaling and alignment gear bonuses; the simulator does not, so it under-rates those builds. Extract one shared sum. | wrong number (sim) | 10 |
| C7 | `sim_combat.dart:814-817`, `sim_companions.dart:44` | **The simulator copies the fight screen's constants.** The potion heal (8), the pack multipliers, the reroll count and the revive share are copies of the fight screen's. The simulator's potion also misses the shrine ×1.5. Move them to one file in lib/combat. | drift risk | 8 |
| C8 | `fight_dice_rules.dart:316` vs `fight_rounds.dart:235-250` | **The heal preview ignores two heal rules.** It leaves out the Briar-Guard no-heal and heal fatigue, so the previewed heal can differ from the heal dealt. The shrine ×1.5 is also written in four places. Use one helper. | wrong number (preview) | 10 |
| C9 | `fight_models.dart:110-130` vs `sim_combat.dart:340-362` | **The elemental bonus and resist are written twice**, once in the fight and once in the simulator. | cleanup | 15 |
| C10 | `spoils_chest_dialog.dart:500` (UX) | **The spoils chest's "health still missing" leaves out the potion bonus** from perks and signs. | wrong number (UI) | 1 |
| C11 | various | **Dead code**, used only by tests or by nothing: `startingTotals` (`character_start.dart:46`, whose fallbacks of 100 HP and 10 damage disagree with the game's 20 and 2), `professionLootAffinityBonus` (`combat_engine.dart:1039`; `loot_box.dart:392` is the one used), `districtArrivalProvider`, `learnSpell`, `questReadinessProvider`, `activeBlessingProvider`, `mode_nudge_provider.dart`, and about ten public names used only in their own file. | cleanup | about 150 in all |
| C12 | `player_session_provider.dart:4268` | **The hut's forge reroll can't be reached.** `canRerollForge` and `rerollForge`, and the `forgeSheetFor` odds, are built (v1.592) but no screen calls them; the forge sheet recomputes the odds itself. UX should wire it, or Core should drop it. | feature unreachable | 10 (UX) |

## 3. Simulator pins and bands

| # | Where | Finding | Severity | Size |
|---|---|---|---|---|
| S1 | `sim_competent_test.dart:345`, `sim_companions_test.dart:292` | **A frozen run that breaks on every new scene.** Both pin the same naive warrior run: an exact tuple plus a hash of every choice taken. Any new scene breaks them: they were re-pinned at v1.577, 1.581, 1.597, 1.601 and 1.602, and v1.602 was a story-only PR. Assert properties instead (the run reaches the ending, offers are all taken, the naive gear stays as given), and keep the run once (the two files repeat it). | cleanup (costs every story PR) | 30 |
| S2 | `road_hazards_test.dart:62-98` | **A sample that grows with the story.** It tallies every story road × 1,000 draws, so its cost and its noise move with the story (200 → 1,000 at v1.602). A fixed list of about 50 roads would hold still. | cleanup | 15 |
| S3 | 12 simulator tests | **Most simulator tests play without Vica.** Since v1.601 every hero has her, but only four tests load `companions` (boss_balance, nemesis_quests, sim_competent, sim_companions). clash_balance, profession_cores, fight_length, sim_playthroughs, sim_coverage, sim_houses, detour_engine, specialisations, sim_quest_politics, clan_power_moves, sign_fight_hooks and QA's clan_power_50 measure a game without her. QA's guard `qa_sim_tables_test.dart:14` doesn't require the table, and it scans only `simulatePlaythroughs(`, not `simulateFightsByChapter(`. Adding her may move profession_cores' and clash_balance's numbers. | wrong number (sims) | 2 per file + guard |
| S4 | all simulator tests | **Each simulator test builds its own table list, and the lists have drifted.** boss_balance has no specialisations, spec variants, skill merges, detour scenes or ports, all of which the simulator screen loads. One helper, `test/support/sim_world.dart`, mirroring the screen's list (`playthrough_simulator_screen.dart:2440`) would end that class of drift. It means one re-baseline of the bands. | wrong number (sims) | 60 + re-baseline |
| S5 | boss_balance + nemesis_quests | **Two big runs share a plan.** 400 runs and 200 runs on the same seed and plan shape. The champions could be measured inside boss_balance's run (`championFights: true`), saving about 200 runs per CI pass. Also for QA: boss_balance (400), clash_balance (240), nemesis (200) and sim_coverage (180) are the slowest simulator tests. | cleanup (CI time) | 20 + re-baseline |

**Sturdy as they are:**
- the boss curve's bands (sample-scaled since #546);
- clash_balance (three seeds, gaps only);
- the champions' pooled band;
- chapter_one_fights, which is direct fights, not a walk.

## Suggested order (for the user's ranking)

1. R1 (Vica joining early), R6 (rat matriarch), and R2 and R3 (Vess,
   Narrative's): small fixes to wrong state in chapter 1.
2. S1 (the frozen run), S3 (Vica in the simulator tests) and C6 (simulator
   damage): every later balance call depends on these.
3. C1 to C3 (Journey and fight rebuilds) and C8 (the heal preview).
4. The rest is cleanup.

Items in another session's area:
- R2 and R3 are Narrative's data.
- C10 and C12 are UX's.
- C1 is in a shared screen.
- S3, S4 and S5 touch QA's guard and QA's test speed.
