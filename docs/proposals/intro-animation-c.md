# The first-launch intro, version C: the city in ashes, told in text (proposal, nothing built)

Picture: `docs/ux-shots/intro-storyboard-c.png` (eight frames, timing under each).
Drawn by `test/ux_intro_c_mock_test.dart`; frame 8 is the real Race & Profession screen.

The user asked for a more textual intro, with the city in ashes and more detail.
So the lines lead and the picture is one slow pan across Alster burnt to ash, shown
in far more detail than A and B (postcards) or B (one drop): each line sits over
the part of the city it speaks of.

## Beats (about 25 s)
| # | Time | What | Line |
|---|---|---|---|
| 1 | 0.0 to 4.0 s | Black; line 1 writes itself; the burning sky fades up and the camera starts to slide over the skyline (smoke columns, roofs with no rafters, embers in the windows) | 1 (set A) |
| 2 | 4.0 to 7.5 s | The broken tower, the bell still hanging in its arch, the roof beside it burnt to its rafters | 2 (set A) |
| 3 | 7.5 to 11.0 s | Tallow Street: every door chalked white above the latch, razor wire in an alley, the proclamation on the well-head, Inquisitors going in with lanterns in pairs | **A (new)** |
| 4 | 11.0 to 14.5 s | The edict close up; the Inquisition's banners scorched on their poles over the square | **B (new)** |
| 5 | 14.5 to 18.0 s | The harbor: the stone giant kneeling in black water that takes the fires' red; the white ships coming in | **C (new)** |
| 6 | 18.0 to 21.0 s | The thirteen clans' flags on the roofs, scorched; the last slot dark: the player's own | 3 (set A) |
| 7 | 21.0 to 23.0 s | The title, the Shroud's six torn pieces small above it, one faintly lit. The still frame with reduced motion | |
| 8 | 23.0 to 25.0 s | Melts into the Race & Profession screen; line 4 holds | 4 (set A) |

**The 15 s cut** is frames 1, 2, 6, 7, 8 (the four set-A lines and the title, a longer
pause on each), so this version still fits the original brief if the three new lines
are not written. Plays once, a tap skips, reduced motion shows frame 7 then frame 8,
replayable from Settings.

## What Narrative is asked for: lines A, B, C (about 20 words each)
Each is one line that types itself out over its frame, in the same grim voice as set
A; the hero is a local of Tallow Street (never a stranger); the bell is just a bell;
the Shroud is the player's own and the clans are the rivals. What the picture shows
under each, all taken from the story's own scenes (250, 270, 300, 100):
- **A, Tallow Street:** "Alster had been made to kneel in a single evening"; every
  door chalked with a white sign above the latch and the house behind it emptied;
  razor wire strung across an alley; Inquisitors in pairs going in and out of the
  houses with sacks and lanterns.
- **B, the edict and the banners:** the proclamation nailed to the well-head, the ink
  still wet, "against unlicensed drawers of every clan and of none"; the
  Inquisition's banners over the square.
- **C, the harbor:** the stone giant of the harbor (scene 250) and the white ships
  that come in that night.

## Reused as it is
`ClanFlag` / `PixelBanner` (the clans' banners, scorched with a colour filter, and the
Shroud's six pieces, found or dark), the title's words, the `StoryText` typewriter for
every line, the real `RaceProfessionScreen`, the reduced-motion check.

## New
- the city in ashes: four small pixel painters (the burning skyline with its smoke; the
  broken tower and bell; Tallow Street with its chalked doors, wire, edict and
  Inquisitors; the harbor with the giant and the ships), a slow pan across them, the ash
  falling over all
- `IntroScreen` with a clock over the eight beats and tap to skip; an `intro_seen` flag;
  a "Replay the intro" row in Settings; the lines

## Size
About two days: one PR of about 700 lines plus a test (the beats in order, a tap skips,
reduced motion shows the title, the flag is set once). The painters are the cost; no new
art files. The decisions: lines A, B, C, and whether the 15 s cut or the 25 s version is
the one.

## A, B or C
A (postcards, a day) is the cheapest; B (one drop to the player's table and the die, a
day and a half) ties the opening to the die; C (text and the ruined city, two days) gives
the most to read and see, and the most to look at before choosing a character. Any of the
three can end on the same frames 7 and 8.
