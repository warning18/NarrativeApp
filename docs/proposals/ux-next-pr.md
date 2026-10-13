# UX: which PR comes first, and the version it needs

For the manager (read here because UX has no `send_message`).

**Fix-pack A comes first.** It is built, pushed (`claude/eager-pascal-y847vf`) and
green on format, analyze and the tests I ran; the travel-map view waits for
Core's PR #199 to reach `main`, so it is second.

Please reserve the next version for fix-pack A. The PR stays closed until the
user says to open it and a version is given.

Fix-pack A holds, for QA's review (L1, one session's area plus two shared
screens):

- Dice loadout: the die card keeps one height whatever face is picked (QA's
  `qa_real_font_cards_test`, `skipUntilFixPack` now `false`).
- Camp town: the status tag sits above the house name, so "Hammersmith",
  "Storehouse", "Watchtower" and "Smugglers’" get the full card width and never
  break inside a word. (The fix QA asked about: neither a smaller font nor a
  FittedBox, just the whole line for the name.) The card tray is 190 px tall,
  from 172.
- Camp town: a tap on a built building opens a sheet with its name and what it
  gives.
- Character: the Shroud is one row of six small banners (names on tap or hold);
  the Gifts dot has a spoken label; tour step 4 describes the three tabs.
- Voyage: a storm's rain falls over the Eel's water only, not behind the words
  and buttons.
- Journey: the "You are here" badge is kept clear of the step names; the weather
  line wraps clear of the − button.
- Chapter 7 camp hub: the enter-the-place button scrolls in the room it has
  (QA's 18 px overflow at 320×568).
- Help pattern: an ⓘ in a page's header replays its guide; holding a section
  name explains it. First on the dice loadout.

Touches another session's area: `lib/tutorial/` is not edited; new strings
(`gifts_waiting_label`, `help_replay_guide`) and the reworded `tut_character_4`
are in `lib/l10n/app_strings.dart`, French included.
