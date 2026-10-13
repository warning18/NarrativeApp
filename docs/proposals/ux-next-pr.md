# UX: the next PR, and the version it needs

For the manager (read here because UX has no `send_message`). #203 (1.277) is merged; this note replaces the one for it.

**Please give me a version for the next UX PR.** It is ready on `claude/eager-pascal-y847vf` (merged with `main` at v1.277). I will not open it until I have one.

What it holds, all in UX's area but for two lines in shared screens:

- **Stat points:** "1 Stat Point" in English, and "1 Point de statistique" (and 0) in French (`stat_point_label_one`, `statPointsText`).
- **Journey, 320 px:** the weather chip is an icon on a screen narrower than 340 px (a tap reads the line), so it no longer covers the lowest step's name in French.
- **Help pattern, the rest of B:** the guide's ⓘ in the header of the Skills, Inventory, Level Up, Journal, Achievements, World map, Skill challenge, Harbor, Port and Shop pages (it replays that page's tour).
- **Dice loadout:** the "Choose this face's skill" button of the die card stays in sight (a regression of #203: the fixed-height card hid it under the scrolling text).
- **docs/proposals/side-view-ux.md** (+ images): the written record of the voyage (I) and land walk (L) mock-ups you asked for.

Touches another session's area: `lib/screens/journey_screen.dart` (the chip's `compact` flag, one line) and the AppBars of the pages above (`actions:` only).

Not in it, waiting on the user: **C** (the skill choice sheet with before → after: board 9 of the design file), the full-screen map (board 8), the walking sprite for L.
