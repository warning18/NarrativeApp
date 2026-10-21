# Wave 16 on the look side: five things UX could do (UX, for the user to pick)

Wave 13 to 15 are done and merged (the land walk's party, clan flags on the skill tree, the level-up radar, the move on the world chart with a camera the player can take, service pins, town tints, the risky gift's d20, the roll powers as cards). These five are what the screens still owe. Sizes: **S** is a day's work and one PR, **M** two to three days, **L** a week or a design board first. None needs Core, except where it says so.

## 1. One sheet pattern (S to M): recommended first
The camp's build sheet, the temple sheet, the town service sheet, the skill choice sheet and the offer's confirm dialog were each built on their own: each has its own title, price line and button. Fold them into one pattern in `lib/widgets/`: a title with the keeper's or the builder's one italic line, rows with an icon, a name and a price chip, one button that carries the price ("Build · 280 G"), and the same greyed-out reason line. Three of the five already follow it after v1.498 (the temple's keeper line, the build sheet's cost row). Why now: QA's smoke pictures keep finding one-off wrap bugs on 320 px phones (the Star Well "G", "The Wayfarer"), and a shared sheet fixes each once. Risk: low; it touches our own widgets and a few lines of shared screens.

## 2. The town at the hour (M)
The city plan and the district view show a town that is always at noon. The day, the hour and the weather already exist for the world chart (`ChartWeather`) and the party's day count. Give the city plan an hour: a dusk wash, lit windows at night (the pixel buildings already have window marks), rain streaks over the roofs in rain, and the service pins glowing at night when a service is open (the tavern) and dim when it is shut. Pairs with town tints: a town's ruler colour reads best at dusk. Risk: performance on the city painter (it repaints on pan); drawn once into a cached layer.

## 3. The fight's entrance and finish (M)
The fight has good hits and falls (v1.25x to v1.3xx) but no entrance and a plain end. An entrance card for named foes and bosses (the foe's pixel portrait sliding in with its name and one line of the story, 1.2 s, skippable), and a finish that tallies the reward as it lands (gold counting up, items dropping into the strip, the level-up moment already there). Reads `fight_rewards.dart` and the foe's data, no new data. Needs Core to say which foes get a card (a flag on the foe, or every boss).

## 4. The towns change hands (S to M, needs Core's events)
Town tints now show who rules a town, but a change of ruler is silent. When a town's ruler changes (a quest outcome, Core's `townRulersProvider` differing from the last one seen), cross-fade the tint over a second on the next visit to the world chart, with the new clan's banner in a toast ("The Compact now holds Candlehold"). Size S for the fade, M with a small "what changed" list on the world chart's layers sheet. Needs Core to say when a change counts as an event (or I diff the provider's state against the last seen, which is enough for a first version).

## 5. The sea as the land is now (M)
The land walk got its party, its speech bubbles and its encounters (waves 13 to 14); the sea voyage still draws the ship alone, with the crew as an icon row. Put the crew on deck as small figures in the side view (the pixel faces the companion strip uses), let the companions speak up at sea (Core's `speakUpOnWalk` has a sea sibling to add), and an encounter at sea should arrive from the side the way the land's does. Needs a small Core hook for sea remarks. Risk: the side-view sea kit is the busiest painter; the figures are small.

## What I would pick
1 first (it makes the later screens cheaper), then 2 (the most visible gain on the phone), then 4 if Core can name the event. 3 and 5 are the larger, more optional ones.

Smaller leftovers, not in the five: the camp build sheet's cost chips (done on a branch, joins 1), the Star Well's two-line gold label, and a real-font picture of the offer hall's new "drawing" state.
