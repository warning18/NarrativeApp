# Level Up, made like the rest of the art (picture only, no build)

Art's PixelLab files (`src/`) in the Tower's ink style, one picture per plate at 412 and 360 wide. The plates rotate by `level % 3` (shrine, anvil, yard). A mock in the Ink palette, from `test/ux_level_up_art_shots_test.dart` with `UX_SHOTS=<dir>`. The numbers are a warrior's in the Tower.

- Top: the plate, Art's red ribbon with "Level N" in code, the hero's south frame (48 px at 2x, centred at x 90).
- Paper panel: three offer cards with Art's symbols. Each shows the before → after rows of `statPickPreview`, or "No effect in the Tower" in plain words. Unpicked cards are not greyed. The digits are Spectral.
- A bar per stat with its symbol; the pick adds a red step and shows "10 → 11".
- The red "Take this pick" button.

Files: `level-up-{shrine,anvil,yard}-{412,360}.png`.
