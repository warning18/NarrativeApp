# The die on the Character tab's portrait (UX mock, nothing built)

## Round 2 (the user's answer): on the portrait square, where its face is

Picture: `docs/ux-shots/character-dice-badge-mock.png`. Mock test:
`test/ux_character_dice_badge_mock_test.dart`. Real capture of the Character tab header at 412
and 320 px; the same header with the die drawn in two ways. This **replaces the card under the
tabs** (round 1, below, kept for the record).

The user: the dice "seen next to or on the character square, where its face is". The die in hand
is shown in its own look (stone, edge, glow; the Bulwark die in the 320 row is the dark one), with
the **+N** of the dice in the bag; **one tap opens the dice screen on that die**
(`DiceLoadoutScreen(initialDieId: ...)`, already built in v1.595).

| Placement | What it is | What it costs |
|---|---|---|
| **On the corner** | A 34 px round badge on the portrait's lower right corner, ringed in the page colour so it lies on the square; the +N pill on its lower left, over the empty part of the square. | Nothing moves: the header keeps its height. The badge is small (28 px die) and touches the name column's left edge at 320 px. |
| **Beside it** | A 56 px square in the portrait's own frame, to its right, holding the die at 36 px with the +N on its corner. | The name column loses 64 px; at 320 px the name, "Human Warrior" and the level bar still fit but are tighter, and the header is about 12 px shorter than today (the vitals move up). |

**My lean: on the corner at 412 and the square beside at 320?** No: one placement everywhere is
simpler. The corner reads as part of the character ("the die this face rolls") and moves nothing;
the square beside is a bigger tap target (56 px against 34). If a tap target of 34 px is too
small, take the square beside. Hidden while the dice feature is closed (the Pages tile's
`GameFeature.inventory` gate) and for a character with no die.

Build (after the user picks, as v1.596): a small widget in `lib/widgets/` (the badge or the
square) and the few lines in `_CharacterHeader` (`character_screen.dart`, Core's file for
behaviour, layout only); one string for the tooltip ("Your dice", EN/FR). No new data.

---

# Round 1 (replaced): a quick way to the dice from the Character tab


Picture: `docs/ux-shots/character-dice-mock.png` (left: the real Character tab today; right: the
same capture with the card drawn in). Mock test: `test/ux_character_dice_mock_test.dart`.
The user, on the Dice tab of the inventory: "also a specific button to reach the dice quickly from
the main Character tab."

## Today
The dice are a tile on the **Pages** tab (Inventory / Dice / Level up / Race and profession), so from
the main Character tab (Overview) they are two taps away, and the tile says nothing about the die.

## The proposal
- **A dice card on the Overview**, directly under the Overview / Gifts / Pages tabs and above the
  abilities radar, the width of the page.
- It shows **the die in hand in its own look** (stone, mark, edge, glow), the small caps line
  "YOUR DICE", **its name** ("Lucky Die") and "d6 · 6 faces · Bone", a **+N tag** when more dice are
  in the bag (the Dice tab of the inventory's list), and a chevron.
- **One tap** opens the dice screen (the ring of face slots) on the die in hand.
- It is hidden while the dice feature is closed (the Pages tile's `GameFeature.inventory` gate) and
  for a character with no die.
- It is a new widget in `lib/widgets/` plus one line in `_OverviewTab` (`character_screen.dart`,
  Core's file for behaviour); no new data, one new string ("Your dice", EN/FR).

## Other placements considered
- Under the radar, above Skills: the radar stays the first thing seen, but the card is below the
  fold on a small phone.
- In the header, next to Gold: too small for the die's name and look.

## Question for the user
Is under the tabs right, or would you rather it sit with the Skills row (the die and the skills it
carries on its faces belong together)?
