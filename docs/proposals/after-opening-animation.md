# After the opening animation: three options (UX-2, pictures only)

The user asked to see "1. 2. 3." of what could follow the opening animation. Pictures in
`docs/ux-shots/after-opening/option-1.png`, `option-2.png`, `option-3.png` (four frames each, phone
width, French; frames marked "vraie capture" are real screenshots of the app, the others are
montages over real captures). All three use the same Grey Shroud sigil whisper (8-15 %) as the only
link. Tap skips, reduced motion shows the result at once without the sigil, nothing blocks a choice.

1. **The "Choisissez qui vous êtes… Go" card (live since the fix of v1.654).** After the last
   sentence the sigil rises, the text folds, the card fades in, the sigil fades out. About 3 s
   after the last word. Nothing more to build.
2. **The Peuple / Vocation screen opens.** After Go the screen (race_profession_screen.dart) enters
   by its header and the two tabs, then the peoples arrive one by one (80 ms apart, a few pixels
   up and fading in), the sigil behind fading out. About 1 s; a tap finishes it; layout only.
3. **From the finished character into the Blind Beggar (node 100_dice).** A cross-fade from the
   character's screen to the Beggar's page, the sigil at its highest (15 %) in the middle, then the
   scene's text told as today. About 1.5 s of fade; a tap skips to the whole text.

Recommendation: do 1 (already live) and 3 next. It is the one moment where the player is thrown
from a menu into the story with a hard cut, and the sigil whisper already ties it to the opening;
2 is a nicety on a screen the player stays on for a long time.
