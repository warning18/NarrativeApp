# Level Up screen (built, v2.10.19 to come), two versions of the stats area

Real screen, real numbers (the Tower hero's session and `statPickPreviewOf`), from `test/ux_level_up_art_shots_test.dart` with `UX_SHOTS=<dir>`.

- `level-up-{warrior,mage}-list-{412,360}.png`: the list version, a bar per stat.
- `level-up-{warrior,mage}-radar-{412,360}.png`: the radar version, Art's symbols at the corners, rings at -2, 0, 4, 8, 12 and the pick ghosted in red dashes.
- `level-up-plate-level-{3,4,5}.png`: the plate turning with the level (shrine, anvil, yard).

The switch is one line: `levelUpStatsView` in `lib/widgets/level_up_art.dart` (list or radar).
