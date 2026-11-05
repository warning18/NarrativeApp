# The Tower on the main game's own screens: a sketch (UX-2)

The user: "For the Tower, take the character choice and earning offers from the main game." Nothing is built; these are the main game's real screens (412 px, EN), with only the Tower's title and Climb button drawn over the first three (a mock).

Picture: `docs/ux-shots/tower/main-screens/tower-on-main-screens-en412.png` (the single captures are beside it: `a1`, `a2`, `a2b`, `a3`, `b1`, `b2`). They come from `test/ux_tower_main_sketch_test.dart` (only with `UX_SHOTS`).

## (a) The character choice: the main game's Race & Profession screen as the Tower's first screen

What the main screen is: two steps, **1 People** (five cards, the stat chips, a card opened with its lore and the clans that will court you, Compare, a dice for a random one) and **2 Calling**, then a **summary** ("You will play as Human Mage", the clans that will come first), then "Start New Game With This Character". Name and look are not on it: the main game asks them after, on the character sheet.

**Keep**: both steps, the cards, Compare, the summary. It is the screen the player already knows, with the art (people portraits, calling icons) the Tower's own lists never had.

**Change (small)**: the title ("The Ashen Tower"), the last button ("Climb"), a line under the summary "Nothing is taken from your story's saves." (panels 1 to 3 draw it). The story's prologue is not part of this screen: it opens after the button, so nothing to drop there.

**Decide**: (1) the screen **locks nothing** today; the Tower locks callings (Cleric and Ranger are bought with marks): a locked card needs a padlock and "bought with marks" line on the main cards (a few lines in `race_profession_cards.dart`, UX's). (2) Name and look: skip for the Tower (a fixed name, "the Climber"?) or ask on the sheet after, as the story does. (3) "These clans will court you" and "the clans that will come first" are the **story's** clan rules; in the Tower the clans offer oaths on the way up (v1.855), so these two blocks should be hidden for the Tower, or they say something the Tower does not do.

## (b) A reward moment with the main game's own screens

Panel 4: the **spoils sheet** (`LootSheet`, the loot dialog's design C) for a won floor, the Tower's ladder beside it, the title "Floor 7 cleared": the chest and its tier, what the spoils change (dice, bag, gold), each reward with its "Use right away" switch, **Take**. Panel 5: the **Level Up screen** a floor that levels the hero would open (the radar, "Pick a gain").

It looks at home, but the two screens answer a different question from the Tower's cards:
- the spoils sheet **gives all** its rewards ("Take" takes the list); the Tower's rule is **choose one of three** (a risk and a build choice). On the sheet, the three would be rewards with one switch each: choose one = a radio, not a list taken whole. A **choose-one mode** of the sheet (design A of `docs/proposals/loot-dialog-designs.md`, already drawn) is the way, and is a small change to `loot_sheet.dart` (UX's).
- the Level Up screen is a story rule (stat picks, `statPoints`); the Tower levels the hero by floor (`towerHeroOf`), with no points to spend. Opening it needs the engine to hold points (Core), or the Tower keeps its floor-to-floor levelling silent and shows the level in the floor screen's header.
- the clan offers of the story are the offer dialog (`offer_dialog.dart`, a suitor who offers its standing); the Tower's oath card could take that dialog's look.

## What of #848 (the oaths, 1.856) would be thrown away

- **Thrown away if (a) is taken**: the Tower's own people/calling lists in `tower_start_screen.dart` (about 100 lines); its two tests.
- **Thrown away if (b) is taken**: `TowerOfferView`'s cards (`tower_offer_view.dart`, about 180 lines, the die-name fix goes with them) become the sheet's choose-one mode, and the oath card moves to the offer dialog's look.
- **Kept either way**: the floor screen with its ladder, the "Oaths" row (unsworn / sworn clans), the marks screen and the end screen, the fight, the save, the strings of the floors and the marks.
- Nothing of #848 blocks (a) or (b); the oath card and "Oaths" row are what the Tower says about clans, whatever the screens around them.

## Open questions for the user

1. Lock callings on the main cards (padlock and "bought with marks"), or keep the three open callings only and show the others from the marks screen?
2. Name and look: none, or after the button as in the story?
3. The three cards: keep "choose one" (on the sheet's choose-one mode), or give the sheet's whole list (a bigger reward, an easier Tower)?
4. Level-ups: silent (the level in the floor header), or the Level Up screen with points?

## Update after the user's decision

The user chose: the main Race & Profession screen as the Tower's first screen, with locks, no name/look step, the story's clan text hidden for the Tower; the spoils chest (`LootSheet`, no gold) with the ladder beside it, and the Level Up screen after a floor that gains a level; the pick-one offer only for boons on wardens and bosses (the sheet's choose-one mode, design A); the clan oath as the clan's own offer after the spoils.

Pictures: `docs/ux-shots/tower/main-screens/tower-locks-and-spoils-en412.png`.
1. **The locked callings** (real cards): Cleric and Ranger are dimmed under a padlock with "Bought with marks: 15" / "25"; a tap does nothing. A prototype is in the branch: `ChoiceCard.lockedNote` and `RaceProfessionScreen(locks: {id: line})` (null by default, so the story's screen is unchanged; a few lines).
2. **The spoils sheet with the ladder** (real widgets): the sheet shows what the spoils change and each reward, with no gold line.
3. **A boon on a boss or warden floor** (a mock: the loot designs' picture A beside the real ladder, its gold row to be dropped): choose one of three, the card in hand ringed, a Choose button on each.
