# Tower clan offers in the story's banner-and-card look (picture first, no PR)

Design A, rounder (radius 12) with all the information on the card (the user, 25 Nov): paper, the gift on a black plate, name in small caps, the clan hue once (a short line), the wax seal, tags, standing, what it moves, the quote; the oath row in the same spirit. Sheet: `ink-cards.png` (EN 412, FR 360, a gift in hand).


The user's call: "for the propositions from clan keep the banner card style choice from story". Built on a branch (`claude/ux-2-clan-offer-cards`, from main v2.8.1) so the pictures are the real screen; no version, no PR until the user approves (the build would be v2.8.2+1071).

`compare-<width>-<lang>.png` (412 and 360, English and French): the floor-16 table (the oath and three gifts) before (the dark rows) | after | after with a gift in hand. `before-*`, `after-*` are the same screens alone; `after-pity-fr-320-1.3x.png` is the tightest case (320 wide, French, text 1.3x): no overflow.

## What changed (only the look; Core's rules, texts, standings, "Not now (+1 mark)" and "Swear" are the same)
- The cards are the story's banner layout drawn in the Tower's ink (new `lib/screens/tower/tower_clan_cards.dart`): the clan's banner at the left, the name on a band in the clan's colour, kind and rarity tags, "Standing n/6", the clan's motto as the quote; a black body, a hard paper line (the clan's colour and a hard offset shadow when lit), the painted backdrop in greys, an ink plate for the gift's picture, the rarity as the tarot cards' wax seal. The story's hand (`ClanHandFan`) fans them; a tap lifts one.
- The oath is a wide ink row above the hand with the banner, the oath's line, the standing and the quote (the late-oath line when it came early).
- The card in hand is repeated in full under the table, with Core's ripple line and Take or Swear; Not now stays under it.
- The Tower's other cards are untouched; the story's own offer cards are untouched.

## Things to know
1. The ripple line (who gains, who loses) was on every card; it is now in the detail of the card in hand: the cards have no room. One tap away.
2. The fan overlaps its cards as the story's does; the rail gives its room to the cards once the head has walked to its notch (it already did), so at 412 each card shows about two thirds.
3. The tier frames of the story (bronze to gold) are not used here: the rarity is the seal and the tag.

## The late oath's line (Narrative, `tower_oath_late_<clan>`)
`late-oath-360-en.png` and `late-oath-360-fr.png`: a floor-16 offer of the Mire's oath at standing 4/6. The envoy's line sits in the oath row as the clan's quote (in place of its motto) and leads the card in hand's words under the table. It shows only when the clan is below 6/6 (`_late`, read from the run's standing: no flag from Core was needed); an oath earned at 6/6 (`after-oath-*`) carries the clan's motto and no extra line. The six per-clan lines are in `app_strings.dart` (the shared fallback is not used).
