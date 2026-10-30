# Three new combat designs, and Vica's sprite (UX-2, pictures only)

Pictures in `docs/ux-shots/combat/`: `combat-1.png`, `combat-2.png`, `combat-3.png` (each: today's
setup and fight, real captures of the app in French, then the new setup and fight; phone width),
and `vica-sprite.png`. Real sprites are used (the hero, Vica, the thug); the painted backdrop is not
touched (a plain gradient stands in for it in the mock-ups). Nothing is built.

1. **Face-à-face (cinematic versus).** The two camps stand large on the stage with their HP above
   them; text folds into chips and two collapsed bands (doctrine, lesson); one big button.
   Cost: fight_setup.dart and fight_view.dart layout. Allies other than Vica have no sprite yet.
2. **Cartes compactes.** Four cards of one size (adversary with a 76 px sprite, group with sprites,
   die and mana, doctrine / lesson as tabs); in the fight, two twin cards on top, a small stage,
   big dice. Cost: layout only (fight_setup.dart, party cards). The least risky.
3. **La table de jeu (dice first).** Standees on a table, HP as pips, huge dice in the middle,
   doctrine and lesson as two cards laid askew. Cost: the biggest (a new stage instead of the
   painted one, which UX map is reworking).

Recommendation: 2 first (small, safe, gives allies a face), then bring 1's stage into it when UX
map's backdrop is done; 3 is the boldest and fits the dice theme best, but replaces the stage.

## Vica (`vica-sprite.png`)
Where she is still an icon: the stage badge (fight_stage_parts.dart: a disc with "V"), the fight
party card (fight_cards.dart: a 24 px disc with "V"), the story remark bubble badge
(companion_remark_bubble.dart: a round initial). Already her sprite, but cropped in a ring: the
Party tab and the companion page (companion_parts.dart CompanionPortrait). Walking strip, tutorial
and empty state already use her frames. Her art: Sitting_down, Walking, Fight_-_Attack (incl.
Bark), 64 x 64. A small PR: stage + card + bubble (+ the portrait tile, optional); other allies
keep their disc until they have sprites.
