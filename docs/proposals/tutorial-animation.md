# The main tutorials as a short animation (UX proposal, for the user to approve)

Nothing is built. The mock is `docs/ux-shots/tutorial-animation-mock.png` on this branch (`claude/ux-tutorial-anim-mock`), made by `test/ux_tutorial_anim_mock_test.dart` with `UX_SHOTS=<folder>`. Left: a frame of the animation (2.4 s into 3.2 s, for the Journey tab). Right: the card it ends on, which is today's "New: Journey / Later / Show me", unchanged.

## The plan, in one paragraph

Today a feature's introduction is a pop-in (`lib/widgets/feature_unlock.dart`: "New: Journey", one line, Later and Show me) and, on Show me, the guide dog's tour (`lib/tutorial/guide_tour.dart`). I would put a short guided animation between the unlock and the card, for the main tutorials: 2 to 4 s (set by the topic, 3.2 s by default) over the screen the player is on. The screen dims round the control the tutorial is about (a rounded hole, the way the tour already lights a target); a pointer (a hand with a ring where it touches) moves from the screen's edge to the control on an ease; the control lifts, scales a little and rings in gold with a soft glow; one line of caption (`tut_<topic>_intro`, Narrative may reword it) sits above it; a thin gold line along the top shows how far through it is, with "Tap anywhere to skip" at the corner. A tap anywhere ends it at once; it ends by itself on the same Show me / Later card as today, which keeps its two buttons. Reduced motion: no movement and no lift, the control lit and the caption shown for the same time (a tap still skips). The animation is one widget in `lib/widgets/` that takes the control's `TutorialTarget` id, a caption and a duration; it plays once per topic (the same "seen" setting as the unlock card) and again from the Tutorials list in the Other tab, before the dog's tour. It is built on the tour's existing lit-target measuring, so it works at any screen size.

## Which tutorials count as main (the user's call; my suggestion)

The six tabs' own: story, journey, character, camp, other, plus the ones a player meets once as a feature unlocks (quests, shop, ship). Each already has a `TutorialTopic` and an unlock card.

## What I need from Core (`lib/tutorial/` is Core's)

1. On `TutorialTopic`: an optional `intro` (`TutorialIntro(target, captionKey, seconds)`): the `TutorialTarget` id the animation points at (for a tab, the tab's id on `home.nav`, which today lights the whole bar: it needs one id per tab, or the tab's index) and the caption's string key. Topics without one keep today's pop-in.
2. A way to ask "has this topic's intro been seen" (the same seen set as `hasSeen`, or a second flag so the animation can be replayed without the tour).
3. The unlock card to call the animation first when the topic has an intro and then show itself (a callback, so `feature_unlock.dart` can wait for it): or I add that call myself, in a few lines, if Core prefers.
4. Strings: `tut_<topic>_intro` (EN/FR) from Narrative for each main topic.

## Questions for the user

- Should the animation play every time a main tutorial is opened from the list, or only the first time?
- Is a hand pointer right, or should the guide dog be the pointer (it walks to the control)? The dog's art exists (`companion_sprites.dart`); the hand is simpler and clearer on a small screen.
