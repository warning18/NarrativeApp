# The loot dialog: three designs and a pick-1-of-3 (pictures only, UX-2)

The user's screenshot (`docs/feedback/loot-dialog-butin.jpg`): "Butin", the
chest, three small tiles (+18 or, Osselet du joueur, Antidote) and, below them,
the same items again in a "use now" list with their text, a gold "Prendre".
What is wrong: the items are shown twice (tiles, then list), the text sits
apart from the thing it describes, the dialog is a plain dark box over the
fight, and the chest is only a picture.

Each sheet shows the same real content (the Gambler's Knucklebone / Osselet du
joueur, the Antidote, +18 gold, the silver chest and the dice art we already
have), left to right: **French 360 px, English 360 px, French 412 px, English
412 px**. Smallest text is 12 px (the 11 px minimum holds). The sheets were
drawn with the app's real theme and fonts by `docs/ux-shots/loot/
loot_designs_mock.dart.txt` (a throwaway test, not built into the game).

## A. The chest opens, the rewards come out as cards with their text inside

`docs/ux-shots/loot/design-A.png`. The chest opens with its light behind it;
below it, one card per reward: icon, name, what it does, and on the cards that
can be used (a charm, a potion) a line "Use right away" that is the toggle the
list holds today. No second list. One gold "Take" button.
- For: nothing is said twice; all the text is read without a tap; the cards
  are the component the Tower needs (below).
- Against: three cards with long text make the dialog taller; at 360 px French
  it scrolls on a short phone.

## B. A compact strip of rewards, a detail line for the selected one

`docs/ux-shots/loot/design-B.png`. A small chest in the header; the rewards
as three tiles in a row; the selected tile (ringed) fills a detail panel under
it with its name, text and the "Use right away" switch.
- For: the shortest dialog, the same height with 3 or 6 rewards (a strip that
  scrolls sideways past 4).
- Against: the text of two of the three rewards is hidden until it is tapped;
  that is a step back for a quick read.

## C. A full-height sheet with what the loot changes

`docs/ux-shots/loot/design-C.png`. A bottom sheet over the fight: the chest,
then "What the spoils change": gold 126 → 144, dice 1 reroll / round → 2, bag
Antidote ×1 → ×2; the item texts underneath; a full-width "Take".
- For: it shows the consequence, not just the object; the best read of why a
  reward matters.
- Against: it needs the engine to say what each reward changes (a number for
  each kind of reward, and "dice" lines for charms and dice); heavy for a
  fight's end; empty space on a short loot.

## The Tower's "pick 1 of 3": the same cards as A

`docs/ux-shots/loot/design-A-pick.png`. The same card with a "Choose" button
in place of the "Use right away" line; one card is raised (the one in hand,
ringed in gold), the others dim; the chest becomes the floor's emblem and the
header says "Floor 7". The loot dialog and the Tower's reward screen are then
one component with two modes: *take all* (a list of toggles and one button) and
*choose one* (a button per card).

## Recommendation

**A for the loot, and A's card in "choose one" mode for the Tower.** It fixes
what the user's screenshot shows (everything twice, text apart) at the lowest
cost, needs nothing from the engine, and gives the Tower its reward screen for
free. C's "what changes" line can later become a small line under a card
("Gold 126 → 144") without becoming a different dialog. B is the fallback if
the dialog is too tall on the smallest phones.

## "The interface"

I read the request as the loot dialog (the screenshot). If it meant the whole
fight screen, say so and I draw that as a second set (the top strip, the slots,
the dice board, the bottom bar), with the same cards and fonts.
