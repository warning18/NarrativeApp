# Tower clan offers in the story's banner-and-card look (picture first, no PR)

The user's call: "for the propositions from clan keep the banner card style choice from story". Built on a branch (`claude/ux-2-clan-offer-cards`, from main v2.8.1) so the pictures are the real screen; no version, no PR until the user approves (the build would be v2.8.2+1071).

`compare-<width>-<lang>.png` (412 and 360, English and French): the floor-16 table (the oath and three gifts) before (the dark rows) | after | after with a gift in hand. `before-*`, `after-*` are the same screens alone; `after-pity-fr-320-1.3x.png` is the tightest case (320 wide, French, text 1.3x): no overflow.

## What changed (only the look; Core's rules, texts, standings, "Not now (+1 mark)" and "Swear" are the same)
- The gifts are the story's fanned hand (`ClanHandFan` / `ClanCardView`): the clan's banner at the left, its colour on the name band, the gift's picture on the tier's plate, the kind and rarity tags, "Standing n/6", and the clan's motto as the quote. A tap lifts a card.
- The oath is the story's wide row (`ClanRaiseRow`) above the hand: the clan's banner, the oath's name, its line and the standing, the clan's motto.
- The card in hand is repeated in full under the table (as it was), with Core's ripple line ("Penitents +2 · Dominion -1 · Vigil +1 ...") and the Take or Swear button; Not now stays under it.
- Everything else on the screen keeps its ink look.

## Things to know
1. The ripple line (who gains, who loses) was on every card; it is now in the detail of the card in hand only: the cards have no room for it. One tap away.
2. The fan overlaps its cards as in the story (a third of the middle card shows at rest), so the middle gift's name is cut until it is lifted; the first tap lifts it. On 320 the hand is narrow (the ladder rail takes the left 56 dp until the cards show).
3. The tier frame follows the skill's own rarity (Common to Legendary), as the story's does.
4. The Tower's other cards (boons, rank-ups) are untouched: tarot cards.

## The late oath's line (Narrative, `tower_oath_late_<clan>`)
`late-oath-360-en.png` and `late-oath-360-fr.png`: a floor-16 offer of the Mire's oath at standing 4/6. The envoy's line sits in the oath row as the clan's quote (in place of its motto) and leads the card in hand's words under the table. It shows only when the clan is below 6/6 (`_late`, read from the run's standing: no flag from Core was needed); an oath earned at 6/6 (`after-oath-*`) carries the clan's motto and no extra line. The six per-clan lines are in `app_strings.dart` (the shared fallback is not used).

## Round 2: the cards redrawn in the Tower's ink (the user's addition)
`ink-cards.png` (start here), `ink-<state>-<lang>-<width>.png`: the fanned gift cards and the oath row keep the story's layout (the clan's banner, the name band in the clan's colour, tags, standing, the clan's quote) but are drawn as the Tower draws: a black body, a hard paper line (the clan's colour when lit, with a hard offset shadow), the painted backdrop in greys under the clan's tint, an ink plate for the gift's picture, paper-line tags, and the rarity as the tarot cards' wax seal instead of the story's bronze-to-gold tier frames. New file `lib/screens/tower/tower_clan_cards.dart` (`TowerClanCard`, `TowerClanOathRow`); the story's hand (`ClanHandFan`) still fans them, and the story's own cards are untouched.
