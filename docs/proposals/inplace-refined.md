# Choices that keep you in place: the scene panel and stage mode, refined (UX, pictures only)

The user keeps two of the four designs of `docs/proposals/inplace-choices.md`: **the scene panel**
(design 2) and **stage mode** (design 4). Designs 1 and 3 are dropped. Nothing is built or pushed
yet; this is the refinement the user asked for. Mock test: `test/ux_inplace_refined_mock_test.dart`
(parts: `ux_inplace_refined_parts.dart`). Pictures, at 412 and 320 px, in
`docs/ux-shots/inplace-refined/`: `panel-1.png`, `panel-2.png`, `stage-1.png`, `stage-2.png`,
`coexist.png`.

The four scenes are real nodes of the story, with their real choices, `facing` and `prompt`:
**The Stone Bridge** (260: pay or fight), **the family house** (400: fight, kneel, run),
**Vane's gate** (`2015_vane`: four choices, two checks and a move) and **the price of the crossing**
(`7002_price`: four decisions with the story's longest choice texts, drawn in French, with no one
faced: the Sovereign is a voice). The map is drawn like the District zoom; the figures are the real
ronin and fighter sprites (Aurel Vane has his own; the toll keeper and Vane the quartermaster stand
in with a white soldier and an Inquisition soldier); the cards are the real `ChoiceCard`.

## The scene panel (`panel-1.png`, `panel-2.png`)

What I would change from the first drawing:
1. **The map is no longer a dim strip.** It stays in view above the panel (118 px at 320, 190 px at
   412), only lightly dimmed, with the place's name on it.
2. **A choice you have picked shows where it goes.** One that moves you ("Run", "Push past him")
   draws its road on the map strip, dashed, to a pin with the destination's name; the card says it
   too ("→ The Black Hold"). A first tap picks (the card shows Go), a second does it, as today.
3. **The vignette adapts.** With two or three short choices it is the scene (you, the one you face on
   one ground line, the line just said). With four choices, or a choice over about 46 characters, it
   folds to one line (their head, their name, what they said) so the cards keep the room. A scene
   with no one faced (the Sovereign) shows the voice's icon instead of a head.
4. **Nothing is cut.** Long choices wrap to three lines with their tag; a list that is still too long
   scrolls inside the panel under a fade (the panel's own scroll; the map does not move).
5. **The question is the node's `prompt`**, in italics under the vignette, in the choice's language.

Kept: the handle (a drag down could fold the panel to a bar and give the whole map back; not drawn),
the bottom bar and the header.

## Stage mode (`stage-1.png`, `stage-2.png`)

What I would change from the first drawing:
1. **The bubbles no longer cover the map and the sprites.** The stage keeps the two figures on one
   ground line, the other's line in a small box over them, and nothing else. The choices are a
   **tray of bubbles under the stage**, hung on a thread that runs down from the hero, each tail turned
   toward the thread, so they read as the hero's answers.
2. **The tap plays the answer.** The picked bubble rises into a balloon over the hero (drawn on the
   Stone Bridge and the house), the others fade, and the other answers in their box; then the next
   scene's options come.
3. **A choice that moves you is a door.** Its destination's name sits at the stage's right edge as a
   tab with an arrow, dim until a bubble that moves you is picked, then lit; the hero turns and leaves
   by it (the transition's "road"). A plain `go` choice (no scene of its own) is the same tab.
4. **The stage has a fixed height** (330 px at 412, 236 px at 320; the sprites are 3x and 2.2x) so the
   tray never moves under the player's thumb. The map behind it is zoomed to the District, dimmed.
5. Long French text wraps to two or three lines in the bubble; four bubbles fit at both widths, a
   fifth or longer text scrolls the tray (the stage could shrink while it does).

Weak case: a scene with no one to face (`price`) leaves the stage nearly empty, and one with many
long choices is cramped. Those read better as a panel.

## How the two live together (`coexist.png`)

One set of cards (the `ChoiceCard` data: icon, text, tag, destination) and one transition (the beat,
the road); the scene's kind picks how they are shown:
- **A hub** (more than four choices acted out here, a town) stays on the map with the rings built in
  v1.4xx; neither of the two kept designs is for it.
- **A scene with a fight against someone who has a sprite** is the **stage**: the family house, the
  Stone Bridge's thug when he has art, a boss. It is the one place where "facing" is the point.
- **Every other scene** is the **panel**: talk, decide, pay, checks, a voice with no body. It is the
  quiet, text-heavy screen, with the map in view for choices that move you.
- The panel's vignette is the stage in small, so a scene could open as a panel and grow into the stage
  when a fight choice is picked (the vignette expands to the stage and the cards become bubbles); that
  is a refinement, not needed for a first build.

## What it needs
- **Art:** a standing west-facing sprite for each person you face (today six exist; the toll keeper,
  the slum thug and Vane the quartermaster stand in). The panel falls back to the voice's icon, the
  stage to the hero alone.
- **Data, all there:** `facing`, `prompt`, `about`, the choices' tags and destinations (Core's
  `choiceShape`). The rule for stage against panel is a derived one (a fight choice and a faced person
  with a sprite).
- **Built from:** `ChoiceCard`, `FightFigure`/`FightSpriteImages` for the figures, the District map.
  The panel is a bottom sheet over the Journey; the stage is a Journey layer over the map.
