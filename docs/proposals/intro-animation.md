# The first-launch intro (proposal, nothing built)

Picture: `docs/ux-shots/intro-storyboard.png` (eight frames, timing under each).
Drawn by `test/ux_intro_mock_test.dart` from the game's own widgets; frame 8
is the real Race & Profession screen.

## Brief
Plays once, before the race and profession choice, 15 s. A tap anywhere skips
to frame 8. Reduced motion shows frame 7 (the title) still, then frame 8 with
line 4 shown at once. No sound needed; one low bell on frame 2 is optional.
Replayable from Settings.

## Beats (the user chose Narrative's set A, Grim)
| # | Time | What | Line |
|---|---|---|---|
| 1 | 0.0 to 3.0 s | Alster at dusk, ash falling; fades up from black | 1 |
| 2 | 3.0 to 6.0 s | Just a bell: it swings, rings spread over the rooftops | 2 |
| 3 | 6.0 to 7.5 s | The Inquisition's banners along the quay | |
| 4 | 7.5 to 10.0 s | The thirteen clans' banners (the rivals who want the city) light up in turn; the last slot stays dark: the player's own | 3 |
| 5 | 10.0 to 11.5 s | The ronin, a local, crosses the quay in silhouette | |
| 6 | 11.5 to 12.5 s | A grey cloth falls and shows the player's own standard torn into its six pieces, hanging in shreds | |
| 7 | 12.5 to 13.5 s | The title in the pixel face; the Shroud small above it, torn: six dark slots, one faintly lit | |
| 8 | 13.5 to 15.0 s | Melts into the Race & Profession screen; line 4 holds | 4 |

Lines (EN; FR in `docs/proposals/intro-lines.md` on `claude/narrative-intro`):
1. Alster at dusk. The ash had already begun to fall.
2. The bell rang for the Inquisition. Nobody on Tallow Street looked up.
3. Every clan wanted the city. None of them wanted you in it.
4. Tonight it burns. First, decide who you are.

Each line sits over the bottom of its frame and types itself out (`StoryText`).
The hero is a local, so nothing shows a stranger arriving, and the bell is just
a bell (not a named tower).

## Reused as it is
- `StreetViewScene` (street-view kit) at dusk with ash: frames 1, 2, 3, 5, 6 backdrops
- `SideSprites` (the ronin): frame 4
- `WindBanner`, `ClanFlag` (`found: false` is the dark silhouette): 3, 4, 7
- the six Shroud pieces (`shroudPieceIds`, `PixelBanner`, found or dark, as the character screen's `_ShroudCard` draws them): 6, 7
- the title screen's words (`menu_title`, `menu_subtitle`): 7
- `StoryText` typewriter and `storyTextShownAtOnce` (reduced motion): the lines
- `RaceProfessionScreen`: frame 8

## New
- a pixel bell with its rings (`CustomPainter`, about 30 lines): frame 2
- the falling grey cloth (one painter, a slide and a fade) with the pieces hanging torn on it, each tilted a little: frame 6
- `IntroScreen`: a clock over the eight beats; tap anywhere or reduced motion
  jump to the end
- a `intro_seen` flag (shared preferences), set when it ends or is skipped, and
  a "Replay the intro" row in Settings
- the four line strings (EN and FR, Narrative's) and the Settings label, next to `menu_title`

## Lore
The Shroud is the player's own clan banner (`void_standard`), restored by its
own six pieces, not by collecting the other clans' banners: those are the
rivals in the city. So frame 4 ends on the dark slot that is the player's, and
frames 6 and 7 show the Shroud torn into its six pieces.

## Where it plugs in
`MainMenuScreen._newGame`: when `intro_seen` is not set, push `IntroScreen`
before `enterGame`; it pops into the story, whose first scene leads to the
Race & Profession screen. Settings: a row that pushes `IntroScreen`
(replay never touches the flag's value).

## Size
About a day: one PR of about 350 lines plus a test (the beats in order, a tap
skips, reduced motion shows frame 7, the flag is set once). No new art files.
Touches `main_menu_screen.dart` (a few lines), `settings_screen.dart` (one row)
and `app_strings.dart` (UX owns the widget, Narrative owns the four lines).

## Open
- The intro plays on the first New Game tap, not at app start (there is
  nothing to skip to before then). Say if it should play at app start instead.
