# Redraws after the user's answers (UX, pictures only, nothing built)

Branch `claude/ux-redraw-2` (on top of `claude/ux-mocks`). Three pictures.

## C. Standing sign: dropped
The user said it repeated what the banners and the ring already show. It is not built;
the mock stays in `claude/ux-mocks` for the record.

## D. The power sign, new design: `docs/ux-shots/power-ways-mock.png`
No bars, nothing about relationship (no green, no red, no heart). The clan card's four
tiers only (Minor below 25, Rising 25–49, Dominant 50–74, Ascendant 75 and up). Each way
is shown at the offer's banners (128 px), the Throne room's standards (64 px), the ring's
crests (34 px) and on the ring itself:

- **A. A rank numeral**: I, II, III or IV on a small plate at the foot; the plate goes
  gold at IV. Exact and quiet, but it has to be read.
- **B. The cloth fills**: the banner is a dark silhouette that fills with its own colours
  from the foot, a quarter for each tier, with a gold hairline at the level. The banner
  itself is the gauge. It costs a weak clan's banner its colours.
- **C. Size and aura**: on the ring the crest grows with its tier (78 / 95 / 112 / 130 %);
  on a banner a gold glow grows round it. The loudest at a glance, but on a banner the four
  glows are close at 34 px.

My read: **B** reads fastest at every size and needs no extra mark, if giving up a weak
clan's colours is acceptable; **A** is the safe, exact one; **C** is best only on the ring.
(`test/ux_power_ways_mock_test.dart`)

## E. The Forge sheet, with tabs: `docs/ux-shots/forge-tabs-mock.png`
Tabs by kind of piece, from the equipment slot of the pieces `craftedAt` the forge:
**Head, Body, Legs, Feet** (items.json `equipSlot` Head / Top / Bottom / Foot; the real
four pieces of the Hammersmith's forge are drawn with their real numbers). A dot on a tab
says something there can be forged now; the row scrolls when weapons or more slots come.
Less on each card: the d20 is **one short line** ("Roll d20 + 3", odds behind a tap: the
modifiers with their sources, the tier bar, what each tier does); the ore hint is behind an
(i); Dagny's line is one line; each piece is **a compact card**: name, its number, what it
needs with a tick or a cross ("Iron ore have 5 · need 3", "Gold have 112 · need 60"), one
button (it says what it lacks when it cannot be pressed). The forging moment is the approved
one (`forge-moment-mock.png`). Core's rule is built (v1.562); this sheet waits for the
user's approval. (`test/ux_forge_tabs_mock_test.dart`)

## F. Tutorials, two different ideas: `docs/ux-shots/tutorial-ideas-mock.png`
The user did not like the pointer animation; I do not know what they disliked, so two
other ideas, both tap-to-skip, no hook asked of Core:
- **A. The guide dog acts it out** (about 3 s): it trots in, sits by the control, taps it
  with a paw, the control dips and rings gold, one line in its bubble, then today's card.
  It reuses the dog the tour already draws and the tour's lit-target measuring.
- **B. A short looping demo inside the card**: the card the player already gets (its own
  title, line and buttons) gets a small picture at its top that plays the feature in
  miniature in a ~3 s loop (a route drawn across a map for the Journey, the radar growing
  for the Character). No overlay, no pointer. Each topic needs its own small demo drawn.
(`test/ux_tutorial_ideas_mock_test.dart`)
