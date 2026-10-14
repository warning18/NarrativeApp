# Core handoff note

For the next Core session. Written at the end of the previous one (v1.267.0 on
`main`). Read `CLAUDE.md` first: it says who owns what, how versions are
reserved, and that you never merge your own PR. This note is the rest: where
things are, what bites, and what was left open.

## 1. Your area, as a map

Core owns rules, numbers and state. Files, by theme:

**Combat engine (`lib/combat/`, except `skill_vfx.dart`, which is UX's).**
Pure Dart, no widgets. `combat_engine.dart` is the base: enemy move choice
(`resolveEnemyMove`), crit and dodge chances, telegraph tiers
(`telegraphTierFor`, Perception against the enemy's Guile), `soloOnlyEnemyIds`.
Around it, one file per mechanic: `status_effect`, `enemy_affix`,
`battlefield_condition`, `field_anomaly`, `enemy_intent`, `enemy_response`,
`dice_tamper` (Hex, Silence, Curse, Mirror), `face_keywords`, `face_smithing`,
`party_combos`, `duo_techniques`, `party_bonus`, `squad`, `doctrine`,
`fight_goal`, `element_reaction`, `parry`, `loot_box`, `spells`, `loadout`,
`turn_order`, `quick_resolve`, `sea_beasts`, `ship_battle`, `ship_combat`.

**The fight screen's logic files (`lib/screens/fight/`).** Part files of one
`FightScreen` state: `fight_rounds.dart`, `fight_dice_rules.dart`,
`fight_queries.dart`, `fight_models.dart`, `fight_rewards.dart`,
`fight_ground.dart`, `fight_goals.dart`. All the screen's randomness goes
through one `_random` (see section 3). `fight_view`, `fight_cards`,
`fight_effects` and the rest are layout and effects: UX's, or shared (check
for open PRs before touching them, as `CLAUDE.md` says).

**Data and rules (`lib/data/`).** Pure helpers over the game files. The ones
you will touch most:
- Story flow: `story_repository`, `story_state`, `story_graph_integrity`,
  `sub_node_engine` (excursions and random draws, including packs),
  `chapter_loop` and `chapter_spine` (the open-loop chapters from chapter 3),
  `chapter_conditions`, `scene_flow`, `turn_in_choices`, `echoes`, `journal`.
- Journey and roads: `journey_map`, `journey_rules` (provisions, days, threat,
  sellswords), `journey_relief`, `world_roads` (the fixed roads, v1.246),
  `world_map`, `map_charts`, `road_events`, `road_hazards`, `road_chart`,
  `party_trail`, `settlements`, `place_plan`.
- Geography: `geography` (continent, country, zone, location, district;
  reads `geography.json` and `biomes.json`), `climate`, `zone_gating`.
- Economy and progress: `shop_pricing`, `shop_stock`, `contracts`, `offers`,
  `perks`, `signs`, `skill_tree`, `skill_access`, `element_points`,
  `approval`, `camp_state`, `camp_fate`, `factions`, `politics_events`.
- Simulation: `sim_combat`, `sim_growth`, `sim_quests`, `autoplay_engine`.

**Models and state.** `lib/models/` (`ally_state`, `story_node`,
`story_politics`, `item_origin`) and `lib/providers/`. The big one is
`player_session_provider.dart`: the whole save, with `copyWith`, `toJson` and
`fromJson`. Any new field goes through all four, with a default in
`fromJson` so old saves still load (QA checks this at L2).

**Game data (`assets/gamedata/`).** Yours: skills, skill trees and merges,
spells, dice, items and sets, enemies, ships and parts, shops, races,
professions, titles, zones, geography, biomes, gates, signs, `game_config`,
factions, subclans, houses, relations, ports, adventure nodes. Narrative's:
quests, chapters, npcs, companions, remarks, intrigues, politics events,
achievements (you set the numbers inside them: rewards, standing
thresholds). The schemas live in `lib/gamedata/db_schema.dart`; a new field
needs a `FieldSchema` there or the in-app editor and the validators ignore
it. Cross-checks: `lib/gamedata/balance_validation.dart` and
`quest_validation.dart`.

**Tutorial.** `lib/tutorial/` (`tutorial_topics`, `guide_tour`,
`tutorial_launcher`). Add a topic when you add a mechanic a player must learn.

## 2. Data conventions

- JSON in `assets/gamedata/` is read through `game_db_repository.dart`.
  English is the base field; French sits beside it as `<field>_fr` (the story
  graph uses bare `fr` keys and `text_fr`). Every new name, description or
  lore line needs both.
- French style, enforced by `french_data_lint_test`, `french_address_test` and
  `qa_story_fr_test`: « vous » for the player, a gender-neutral narrator, a
  non-breaking space (U+00A0) before `; : ! ?`, no straight apostrophes in
  story text (use ’).
- Story choices carry `goldMod`, `alignmentMod`, `flagsToAdd`, `showIfFlags`,
  `politics` (`standing`, `intrigue`) and so on (`StoryChoice` in
  `story_node.dart`). A negative `goldMod` on a choice with `pays` shuts the
  choice when the purse cannot cover it (`affordableWith`). A positive
  `goldMod` triggers the "approves profit" reaction of companions.
- Packs of enemies: `triggerEnemyIds` (plural) beside the old
  `triggerEnemyId`; read both through `allTriggerEnemyIds`. Enemies in
  `soloOnlyEnemyIds` (bosses and uniques) never join a pack and are never Elite.
- Banner pieces come only from a quest's `grantsBannerPieceId` and live in
  `bannerPiecesCollected`. No scene or flag removes one.
- Reference scale for story numbers (from the 198 hub scenes): gold −150…+80
  (chapter 7 goes up to +300), alignment −3…+5, standing −20…+15. A −3
  alignment counts as a "big deed" (double weight) for companion approval.

## 3. Tests: what is deterministic, what was flaky, and why

- **Fight dice.** `FightScreen` takes an optional `random:`; the default comes
  from `fightRandomProvider` (`lib/providers/fight_random_provider.dart`, the
  twin of `roadRandomProvider`). Every fight widget test that asserts an
  outcome overrides it with `Random(7)`:
  `ProviderScope(overrides: [fightRandomProvider.overrideWithValue(() => Random(7))], …)`.
  Do the same in any new fight test. Without it, a dodge (5% floor), an
  anomaly or an affix turns up in one run and not the next.
- The two flakes of v1.259.0: the parry test now accepts a dodge, and the
  anomaly chip no longer overflows (`Flexible` inside its `Wrap`).
  `fight_mirror_spell_test` matched the Venomous affix's poison line before the
  Mirror's: its regex now skips "from poison".
- **Do not put `Flexible` in `_telegraphChip`.** It is a non-flex child of a
  `Row` in `_buildTopStrip` with unbounded width: `Flexible` throws there. Its
  possible overflow on a narrow screen is still open (section 5).
- `autoplay_engine_test` used to be flaky for a different reason (an arbitrary
  path with a fresh level-1 character); read its header comment before editing.
- `boss_balance_test` and `combat_engine_test` are self-contained simulations
  of the engine. They fail when you change enemy numbers or the move
  conditions, not only when you break code: re-tune the data, never loosen the
  band.
- QA owns `test/qa_*_test.dart`. A wrong or failing QA test goes back to QA as
  an issue or a review; you do not edit it.
- Run tests one file per command, and run `flutter analyze` and
  `dart format --output=none --set-exit-if-changed .` before every PR. The full
  suite takes about 15 minutes and CI runs it.

## 4. The simulator and its reports

- Harness: `simulatePlaythroughs` (in
  `lib/screens/playthrough_simulator_screen.dart`) run headless by
  `test/sim_playthroughs_test.dart`. Variables: `SIM_RUNS` (default 40),
  `SIM_SEED` (7), `SIM_GOALS` (comma list of `SimStrategy` names: `random`, `favorGood`,
  `favorEvil`, `maximizeGold`, `explore`, `completionist`, …), `SIM_STRATEGY` (one goal), `SIM_OUT`
  (JSON file). `test/sim_coverage_test.dart` (exploring runs) takes `SIM_RUNS`,
  `SIM_SEED`, `SIM_OUT`.
- **Pitfall:** `SIM_STRATEGY` and `SIM_GOALS` are not the same. `SIM_GOALS`
  plays the listed goals in turn and advances the profession after each round
  of them; to play one goal alone (the reports' "thorough" batch is
  `SIM_GOALS=completionist`, the "random" one `SIM_GOALS=random`) use it with
  one name. `SIM_STRATEGY` fixes the goal but rotates professions over all
  goals' count, so the profession mix differs and the numbers do not match the
  published tables.
- Regenerate `docs/simulation/` with `docs/simulation/make_report.py`
  (usage in its docstring: `tables`, `csv`, `explore-csv`, `branches`,
  `quests`). It only formats the harness's JSON; it changes no game data. The
  two CSVs use CRLF line endings, and the script writes them that way.
  The exact command lines are at the top of `report-100-runs.md`.
- A reports-only PR bumps no version (see `CLAUDE.md`). The last regeneration
  was on 1.256.0 (#176); QA's L3 of 1.264.0 compared against it and found no
  regression (`docs/qa/l3-1.264.0.md`).
- The simulator measures its own policy as much as the game: gold is left
  unspent (median 3,100 at the end), melee classes trail casters by about 16
  points, chapter 5 is the hardest stretch, and the same bosses are lost 80% to
  96% of the time. Read "How to read it" in `report-100-runs.md` before
  comparing two columns.
- `autoplay_engine` (Edit Mode "jump ahead") resolves only the first id of a
  pack choice. `playthrough_simulator_screen` is not pack-aware either.

## 5. Unfinished work and open questions

1. **Hub quests the thorough player never takes** (`report-quests.md`, "open"):
   Grosh's Price, The Reckoning Wall and Glass from the Terraces are offered by
   beats of the Ashen Quarter hub (3005) and are at 0% for the thorough goal,
   18%, 14% and 18% for random. The cause was not traced: check the goal's
   quest-picking policy in `sim_quests.dart` and the beats' gating before
   touching the quests.
2. **`_telegraphChip` overflow** at 360 px: not fixed (see section 3). QA
   planned a guard that forces each anomaly in a 360×640 fight
   (`qa_anomaly_chip_test`, `qa_real_font_layout_test` exist now); the
   telegraph chip needs a layout fix that does not use `Flexible`.
3. **Pack awareness** in `autoplay_engine` and the in-app simulator (section 4).
4. The Fourth Piece (`relic_road`) stays in the pack, broken: a decision by
   the manager and Narrative, not a mechanic to wire.
5. Ideas not started: a sink for the unspent gold of the late game (the camp
   works cost thousands but the simulated player does not buy them, so check
   the policy before adding more sinks); a simulator policy that spends.

## 6. What I would tell a newcomer

- Version numbers are reserved by the manager. Bump `pubspec.yaml`,
  `lib/app_info.dart` and `CHANGELOG.md` last, after merging `origin/main`, and
  keep both sides of the changelog when it conflicts. A docs-only or test-only
  PR does not bump.
- Branches are restarted from `main` after every merge. PRs are squash-merged,
  so your old branch diverges from the remote one: merge the remote tip (a
  no-content `git merge -s ours origin/<branch>`) and push normally. A force
  push is refused here.
- Android only. Never touch `ios/` or `macos/`.
- Never edit someone else's numbers or strings wholesale. Narrative may fix
  text fields in your files but never your numbers; you set the numbers in
  theirs.
- Check `git diff --stat origin/main...origin/<other-branch>` before editing a
  shared screen. Add new strings next to the feature's own block in
  `lib/l10n/app_strings.dart`, and never reorder others'.
- A change to enemy numbers moves the boss win-rate bands: rerun
  `boss_balance_test` and a simulator batch before the PR, and say what moved.
- Do not reformat a file you did not change; `dart format` is enforced in CI.
- If a CI job fails with no test named, run the full suite locally before
  re-running the job; a failure that is not reproducible still needs a cause.
