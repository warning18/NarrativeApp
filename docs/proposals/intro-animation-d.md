# The first-launch intro, version D: the burning Shroud, the die, the title (proposal, nothing built)

The user's own idea for the intro (the manager called it "version C"; C is already the
text-led storyboard of #537, so this one is D). Picture: `docs/ux-shots/intro-storyboard-d.png`
(eight frames, 15 s, timing under each). Drawn by `test/ux_intro_d_mock_test.dart`; frame 8
is the real Race & Profession screen.

## The idea, in the user's words
"A plan shows the Great Shroud banner burning and disappearing, showing from behind the
ashen city on alert and under bombing. A zoom on the casino/tavern: a dice roll from the
top, rebounds on the floor and comes to the middle, continues to turn slower, and once it
stops the title appears over it, and after a bit of time slowly fades to show your choices
of Profession and Race."

## Beats
| # | Time | What | Line |
|---|---|---|---|
| 1 | 0.0 to 2.5 s | The Great Shroud fills the frame over the ash-sky city; fire climbs it from the foot | 1 |
| 2 | 2.5 to 4.5 s | It burns away into six embers; one falls toward Alster; the city comes up behind it | |
| 3 | 4.5 to 6.5 s | The city on alert: calm streets, chalked doors, Inquisitors with lanterns, the bell, the white ships far off. **No shell yet** | 2 |
| 4 | 6.5 to 8.5 s | The camera pushes down through the smoke to the Blind Beggar on Tallow Street | 3 |
| 5 | 8.5 to 10.5 s | Inside: the bone die drops from the top, bounces on the floor, rolls to the middle | 3 |
| 6 | 10.5 to 12.0 s | The tumble eases out; it stops on a **six**; the first shell lands outside, its light crosses the room | 3 |
| 7 | 12.0 to 13.5 s | The title rises over the resting die; a beat. The still frame with reduced motion | |
| 8 | 13.5 to 15.0 s | The room fades slowly into the real Race & Profession screen | 4 |

Rules as for A, B and C: plays once, a tap anywhere skips to frame 8, reduced motion shows
frame 7, replayable from Settings, no sound needed (a low bell on frame 3, the die's clatter
on frame 5 and a distant boom on frame 6 are optional).

## The four set A lines
Unchanged and in the same order: **1** over the banner and the city, **2** over the calm
streets, **3** over the zoom and the die, **4** after the title as it fades. No reordering.

## Lore (Narrative's note, `intro-lore-c.md` on `claude/narrative-intro`)
- The Shroud was cut into six pieces long ago, so a whole banner burning on the night would
  contradict the story. It is drawn as a vision of before: the whole banner burns and
  vanishes as an image, and it leaves **six embers** (the six pieces), **one falling toward
  Alster** (the piece under the player's family house). The six survive, so "restore the
  Shroud" still reads.
- The tavern is **The Blind Beggar**, Tallow Street (building `alster_b000`, geography
  `blind_beggar`); the first playable scene (100) happens there, and the player rolls the old
  bone die once for luck and it comes up six, so the die stops on a six.
- The bombing is the Inquisition's low white ships with painted sails burning like lamps,
  firing iron balls; the harbor's stone giant stands in the smoke; doors are chalked white.
- **One tension, for the user:** they want the city "under bombing" through line 2, but in the
  story the first shell comes after the six, and line 2 says nobody looked up. This storyboard
  holds the shell for the moment the die stops (frame 6). If the user wants bombing earlier,
  line 2 is the one that would need rewording, and Narrative will not change it without their
  word.

## Reused as it is
The grey banner and the six pieces (`PixelBanner`, `shroudPieceIds`), the street-view kit at
dusk with ash for the tavern's front (`StreetViewScene`, kind `tavern`), the bone die (`Die3D`
with `boneSkin`, tumbling by its roll and at rest), the title's words, the `StoryText`
typewriter for the lines, the real `RaceProfessionScreen`, the reduced-motion check.

## New
- the fire (a painter), the six embers and the one falling, the white ships and the shell's
  flash (a painter), the city in ashes (the four small pixel painters of C), the tavern's floor
  (a painter)
- the die's path: a bounce and an ease-out on the existing tumble
- `IntroScreen` with the clock over the beats, the zooms between frames, tap to skip; an
  `intro_seen` flag; a "Replay the intro" row in Settings

## Cost, against A and B
About **two days**, one PR of about 750 lines plus a test: dearer than A (a day, postcards) and
B (a day and a half, the drop to the table). The fire, the ships and the die's path are the
cost. The die and the title are the strong, cheap part; a **short version, frames 5 to 8 only**
(the die, the title, the fade, with lines 3 and 4) is about half a day.
