# The first-launch intro, version B: one long drop (proposal, nothing built)

Picture: `docs/ux-shots/intro-storyboard-b.png` (eight frames, timing under each).
Drawn by `test/ux_intro_b_mock_test.dart` from the game's own widgets; frame 8
is the real Race & Profession screen. A different idea from version A
(`docs/proposals/intro-animation.md`, a run of postcards): one camera that
falls from the ash sky over Alster to the player's own table on Tallow Street,
each frame pushing into the next, ending on the old bone die being thrown. The
die is the through-line: the story's first scene is the player rolling it.

Same brief and rules as A: 15 s, plays once, a tap anywhere skips to frame 8,
reduced motion shows frame 7 still (then frame 8 with line 4 at once), no sound
needed (a low bell on frame 2 and the die's clatter on frame 7 are optional),
replayable from Settings. Same four lines (Narrative's set A), none reworded.

## Beats
| # | Time | What | Line |
|---|---|---|---|
| 1 | 0.0 to 3.0 s | Fade up on the ash sky over Alster, the chapel's cross | 1 |
| 2 | 3.0 to 6.0 s | The camera drops to the bell; it swings, rings spread. Just a bell | 2 |
| 3 | 6.0 to 8.0 s | Over the roofs the thirteen clans' flags rise in turn; slide right | 3 |
| 4 | 8.0 to 9.0 s | The drop ends at one house on Tallow Street, lamp lit | |
| 5 | 9.0 to 10.5 s | The lit window; the hero's silhouette at the table inside | |
| 6 | 10.5 to 12.0 s | The table by candle: the bone die, the six torn pieces of the Shroud (the heirloom faintly lit) | |
| 7 | 12.0 to 13.5 s | The die is thrown and tumbles; the title comes up under it | |
| 8 | 13.5 to 15.0 s | The die lands on the real Race & Profession screen; line 4 holds | 4 |

Line 2 ("Nobody on Tallow Street looked up") hands the camera to Tallow Street.
The Shroud is the player's own (six pieces), the clans are the rivals, the hero
is a local: all as the manager's lore note says.

## Reused as it is
- `StreetViewScene` at dusk with ash, pushed in with a scale: frames 1 to 4
- `ClanFlag`: 3; `SideSprites` (the hero) as a silhouette: 5
- the six Shroud pieces (`shroudPieceIds`, `PixelBanner`): 6
- `Die3D` with `boneSkin`, still (6, 8) or tumbling (7)
- the title's words (`menu_title`, `menu_subtitle`), the `StoryText`
  typewriter for the lines, the real `RaceProfessionScreen`, the
  reduced-motion check

## New
- the bell and its rings (about 30 lines), the lit window, the candlelit table:
  three small painters
- `IntroScreen`: a clock over the eight beats and a camera that pushes each
  frame into the next (a scale and a dissolve); tap to skip
- an `intro_seen` flag, a "Replay the intro" row in Settings, the four lines

## Size and where it plugs in
About a day and a half: one PR of about 450 lines plus a test (the beats in
order, a tap skips, reduced motion shows frame 7, the flag is set once). No new
art files. `MainMenuScreen._newGame` pushes it before `enterGame` the first
time; Settings has the replay row. Touches `main_menu_screen.dart` (a few
lines), `settings_screen.dart` (one row), `app_strings.dart`.

## A or B
A is cheaper (a day) and reads as a trailer of the city. B costs half a day
more and ties the opening to the die and to the player's house; it also
needs the most care on frames 4 to 7, which are the least like anything the
game has drawn so far.
