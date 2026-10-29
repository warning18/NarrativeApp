# The opening scene as an animation: three storyboards, round 2 (UX-2, pictures only)

The user wants the wall of text of the first scene (`docs/feedback/prologue-text-screen.jpg`)
replaced by an animation where the text arrives directly and flows into the character choice.
Round 2 applies the user's feedback: "transition with only the sigil of the Shroud with low
opacity like a whisper behind." Pictures: `docs/ux-shots/prologue-animation/storyboard-A.png`,
`-B.png`, `-C.png` (four frames each, phone width, French). Narrative's words and the bold
phrases are unchanged; no shorter lines are needed.

**The only transition effect: the Grey Shroud's sigil.** I used the title's own standard
(`assets/visuals/banners/void_standard.png`, `titleBannerId`: an eye above a spiral), the
existing mark of the game's title; no new art. If the user means another mark, only the image
changes. It sits BEHIND the text and the cards, still, desaturated, 8-15 % opacity (10-12 % at
its peak): it fades in as the last sentence finishes (frame 3) and fades out as the choice
settles (frame 4). No die, candle or other effect carries the transition.

Common to all: about 29 s if not skipped. A tap finishes the sentence being shown; a second tap
jumps to the end. The Peuple / Vocation choice is usable at the end, no extra tap. Reduced
motion: all the text at once, the sigil still at 10 %, the choice with a simple fade.
"Revenir à la carte" stays as a quiet link.

**A, "La voix".** One large sentence at a time, word by word; earlier sentences rise and dim;
bold phrases turn gold. At the end the text folds into a strip (tap to reread) and the choice
rises beneath, over the fading sigil.

**B, "Mot à mot".** The text arrives word by word at the foot of the screen, bold phrases in
gold. The die is only a word now (no animated object). The sigil rises behind the last
sentence; the text goes up to a strip and the two cards unfold over the fading sigil.

**C, "Lecture".** The whole text is already there, as today; a soft clarity (a plain fade, no
shape) descends line by line, read lines dimming. The sigil rises behind the finished text, then
fades behind the cards. Keeps free reading; the least animated.

**Recommendation: A.** The user asked for the text to arrive directly, and A is the one where
the text truly arrives (one sentence at a time) while the sigil stays the only other thing on
screen, so the whisper reads clearly against a nearly empty screen.
