# Clans in the Tower, in the tarot style (proposal, pictures only)

360 and 320 wide, English and French (`<a|b|c>-<name>-<width>-<lang>.png`; `_compare-<width>-<lang>.png` put the three side by side; start with `_compare-360-en.png`). Clan names, mottoes, colours and oath names are the game's (`factions.json`); the gifts and the numbers are samples until Core gives the data shape.

- **a. A clan offer.** The same three-card pick as the Tower's other cards: each card is a clan (its painted backdrop from `assets/visuals/cards/clans/`, its banner in the corner), named for the gift it brings, with the gift's rarity seal and, under the words, the standing it would move ("+6 Crows"). The card in hand shows the clan's motto and what the gift moves, clan by clan, as the story's offer does, and the buttons are Accept / Not now. At 320 and 1.3x text the rows take over (`a-offer-rows-320-fr-1.3x`).
- **b. Standing rising.** Three places, and a fourth I left out. My pick is 1 and 3: a toast after the fight that moved it ("The Compact thinks more of you · 3 → 4"), and the hero sheet as the home of all the clans (a bar of six steps each, the step where the oath is offered boxed, the clan that just rose tagged "+1"). 2 is the same bar on the card when that clan offers. The rail (shown dimmed, not chosen) is too small for it: 40 px wide.
- **c. The oath unlocks.** A banner in the clan's colour opens the cleared floor ("A door opens: The Crows think you worthy of their oath. Standing 6/6"), then the oath is one of the cards (the oath's own name, the clan's backdrop, a five-pip seal; Swear / Not now), with the clan, its die and "one oath a run" in the detail line.

## What I need from Core
- A clan offer in the Tower: which clans, which gift (a skill, a perk or a sign, as in the story), and whether a card can be refused for a mark.
- Standing in a run: a whole number per clan or a range (the pictures use 0 to 6), what moves it (a fight, a floor, an event, a gift), and the step where the oath is offered.
- Whether an oath card replaces one of the three cards or comes as a fourth.

## Updated to Core's provisional plan (v2.6.0)
Standing runs 0 to 6, the oath is at 6, and only gifts taken move it (so the toast in b comes after a gift is taken, not after a fight). A card can be refused for a mark ("Refuse (+1 mark)" in a; "Leave them all (+1 mark)" in c). The oath comes as a fourth card, not replacing one of the three: in c it is a wide card on top, in hand, over the floor's three. The cards use Art's tarot set.
