# L3 preparation: the 1.270.0 baseline

Prepared ahead of the next L3 (due at 1.274.0). Head measured: `211d2ce`
(#197), v1.270.0+306, 2026-10-13, **Android only**, the same commands as the
[1.264.0 L3](l3-1.264.0.md). The L3 itself compares 1.274.0 with this file,
so that chapter 5's change (#196) is seen on its own and is not mixed with
what the later PRs do.

## Baseline numbers

| check | result |
|---|---|
| `dart format --output=none --set-exit-if-changed .` | clean (2.7 s) |
| `flutter analyze` | no issues (17 s) |
| full `flutter test` | 2191 tests passed, 10 skipped, 14m49s (1.264.0: 2141 tests, 14m32s) |
| simulator, 100 runs, seed 7, 4 goals, 20 runs per profession | 100/100 reach an ending in chapter 8 |
| simulator, 800-run check (seeds 11 and 23, 400 each) | 800/800 reach an ending |
| story coverage, 300 runs per batch, seed 7 | exploring runs reach 408 of 421 scenes (97%), random 387 (92%); 0 scenes statically unreachable |

The 10 skipped tests are the ones switched off on purpose until UX's layout
fix-pack lands: `qa_real_font_cards_test` (8: dice loadout card height, camp
house titles) and `qa_ch7_hub_layout_test` (2: the cove camp page at 320 px).
When the fix-pack merges, set `skipUntilFixPack` to `false` in both files.

### Simulator, 1.270.0

Commands (as in `docs/simulation/report-100-runs.md`):

```
SIM_GOALS=random,favorGood,favorEvil,maximizeGold SIM_RUNS=100 SIM_SEED=7  SIM_OUT=runs100.json flutter test test/sim_playthroughs_test.dart
SIM_GOALS=random,favorGood,favorEvil,maximizeGold SIM_RUNS=400 SIM_SEED=11 SIM_OUT=runs11.json  flutter test test/sim_playthroughs_test.dart
SIM_GOALS=random,favorGood,favorEvil,maximizeGold SIM_RUNS=400 SIM_SEED=23 SIM_OUT=runs23.json  flutter test test/sim_playthroughs_test.dart
SIM_RUNS=300 SIM_SEED=7 SIM_OUT=cov300.json flutter test test/sim_coverage_test.dart
```

| measure | 1.264.0 | **1.270.0 (baseline)** |
|---|---|---|
| ended in a real ending | 100 / 100 | 100 / 100 (800/800 in the check) |
| attempt win rate, 100 runs | 36% | **38.1%** |
| attempt win rate, 800-run check | 36.7% | **40.0%** |
| level at the end (100 runs, mean) | 10.9 | 11.4 |
| gold at the end (100 runs, mean) | 3698 | 3732 |
| warrior / rogue / ranger attempt win, 800 runs | 28% / 33% / 33% | 31% / 36% / 36% |
| cleric / mage attempt win, 800 runs | 47% / 45% | 52% / 49% |
| chapter 1 / 2 / 3 / 4 attempt win, 800 runs | | 84 / 74 / 40 / 36% |
| chapter 5 / 6 / 7 / 8 attempt win, 800 runs | | **31** / 31 / 17 / 21% |
| chapter 5 attempt win, 100 runs | 21% | 29% |

Reading it. The rise of about 3 points in the 800-run figure (36.7% to
40.0%) is chapter 5 (21% to 31%, #196) and the small rise it brings to
chapters 6 to 8 (the void hound and the inquisition penitent also fight
there). Chapters 1 to 4 did not move (checked in the #196 review, to the
decimal on four runs). All five professions rose by 3 to 5 points. Chapter 5
is no longer the wall; chapter 7 (17%) now is.

### Coverage, 1.270.0

- 421 scenes in the story (415 at 1.264.0; the six of #195's cove visitors).
  The exploring runs visit 408. The 13 left are the **same 13 as at
  1.264.0**: `5010_clan_crows_2*` (3), `6010_clan_compact_3*` (3),
  `7100_clan_crows_3`, `5100_clan_crows_1_lost`, `7100_cutter_lost`, and the
  flag-gated follow-ups `3100_widow_later`, `3200_smith_later`,
  `5200_nell_later`, `6200_eldest_later`.
- Quests seen 39 of 43, shops opened 5 of 14, enemies met 42 (1.264.0: 36
  quests, 5 shops, 42 enemies). The new ones are the three cove quests.

## Screens to read through at the L3 (#186 to #199)

The 1.264.0 L3 covered up to #186. Since then (merged to `211d2ce`, and the
two merged after the baseline):

| PR | version | what changed | files | QA on merge |
|---|---|---|---|---|
| #188 | 1.265.0 | the simulator's controls scroll ("Play to chapter" reachable on a phone) | `playthrough_simulator_screen.dart` | L1 |
| #189 | 1.266.0 | Character tab: skills beside a radar, title chips, folded perks and signs; recap as rows; Mana opens Spells | `character_screen.dart`, `skills_radar_card.dart`, `ability_radar.dart`, `radar_chart.dart`, `perk_list.dart`, `title_widgets.dart`, `skills_screen.dart`, `sign_widgets.dart` | L2 |
| #191 | 1.267.0 | offer banners fixed-size, chest rarity reveal, dice cube turn fix, Throne room first, Character page in tabs, race and profession dossier | `offer_dialog.dart`, `spoils_chest_dialog.dart`, `interactive_die.dart`, `clans_politics_screen.dart`, `character_screen.dart`, `race_profession_screen.dart` | L2 |
| #190 | 1.268.0 | one spelling of two place names | story data, `app_strings.dart` | L1 |
| #195 | 1.269.0 | chapter 7: three cove side quests, quest goal 1, gate lines at Candlehold | story, `quests.json`, `chapters.json`, `world_map.dart` | L2 (`qa_ch7_side_quests_test`) |
| #196 | 1.270.0 | chapter 5 enemies softened; simulator JSON fields | `enemies.json`, `playthrough_simulator_screen.dart`, `docs/simulation/` | L2 (simulator, seeds 7, 11, 23) |
| #198 | 1.271.0 | `broken_charter` played end to end; chapter 7 objectives shortened | story, `intrigues.json`, `world_map.dart` | L1 |
| #199 | 1.272.0 | travel-history data (no screen yet), the story chart | `travel_history.dart`, `map_charts.dart`, `world_map_screen.dart` (one line) | L2 (`qa_travel_history_test`, to be added) |

Still to come before 1.274.0 and to add to the read-through: UX's fix-pack
(dice loadout header card, camp house cards, scrollable cove camp page,
voyage-screen rain layer) and the travel-history view UX builds beside the
Journey. For each: read it on a 360 px and a 320 px screen with the bundled
fonts, in English and French (the `qa_real_font_*` files hold the pattern),
and turn the skipped guards back on.

Screens to read in that pass, by area: Character (three tabs, Overview /
Gifts / Pages), Race and profession dossier, Clans (Throne room first), the
offer dialog and the spoils chest, the dice cube and loadout, the camp (town
tray, cards), the cove camp page, the simulator screen, the world map (look
selector shows three looks) and the new travel map.

## Open at the baseline

- Layout: the cove camp page overflows by 18 px at 320×568 when a quest is
  active (`_EnterPlaceButton`); the dice loadout header card changes height
  as faces are picked; camp house titles (Storehouse, Watchtower,
  Smugglers') break inside a word at 360 px. All three are in UX's
  fix-pack.
- The 13 never-visited scenes (above).
- Not covered, as before: ship battles on voyages, the fight lab, and the
  player's real choices of dice and loadouts.
