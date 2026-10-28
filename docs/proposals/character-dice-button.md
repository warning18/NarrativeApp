# A quick way to the dice from the Character tab (UX mock, nothing built)

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
