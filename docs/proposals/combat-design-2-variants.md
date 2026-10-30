# Combat design 2 (Cartes compactes), two variants (UX-2, pictures only)

The user chose design 2 with changes: (a) no big sprite figures on the cards; (b) the icons (the
"V" disc, portrait discs, ring crops, enemy and ally icons) become the sprite HEAD, a crop of the
real sprite (Vica's dog head, the hero's head, the enemy's head; an ally with no sprite keeps its
disc); (c) the dice board takes most of the fight screen; (d) dice are thrown and tumble each roll
before settling; (e) a locked die leaves the board and sits small in a "kept" row below it.
Pictures in `docs/ux-shots/combat2/`: `variant-A.png`, `variant-B.png` (each: pre-fight, a roll in
flight, two dice locked below, then the four frames of one throw), `sprite-heads.png` (the three
head crops, cut from the existing sprite files; no new art).

- **A, kept strip.** HP and mana in two twin cards on top; the board is the middle half of the
  screen at full width (392 px); locked dice go into one strip directly under the board.
- **B, kept tray + side rail.** HP and mana in a left column of heads, the enemy as a banner, the
  board on the right over the full height (292 px wide); locked dice go into a small tray under
  the board with their effect readable (who, what) and a count (2/3).

The throw (both): launch from the bottom with a trail (0.15 s), tumble in the air with the shadow
on the ground (0.35 s), land and bounce on the final face (0.3 s), settle and label (0.3 s), about
1.1 s. A tap during the flight lands them at once; reduced motion places them with no flight.

Core: nothing to change. This is look and motion only (positions come from the view; the set of
locked dice stays the same state), `fight_dice_rules.dart` is not touched. Core confirmed the board holds at most 4 dice (player + 2 seated companions, 4 with the Barracks
Annex): A fits 4 dice of 64 px in a row; B (292 px) fits 4 dice of 58 px as 2 x 2.

Recommendation: A (the wider board is worth more than the side rail on a phone).

## Round 3: variant A with the user's changes (A')
The user likes A and the throw; asks for bigger cards, one per player / companion, so bonuses
and maluses show, as small icons with a pop-in explaining them on tap.
`docs/ux-shots/combat2/variant-A2-cards-icons.png` (a roll in flight, two dice kept, the pop-in
open on Vica's poison, the icon legend); the 8 icons (9 x 9 pixel, one colour each) are in
`docs/ux-shots/combat2/icons/`: poison, stun, weaken, block, parry, shelter, fury, target.
- Three cards of 70 px on the left (head, name, HP, icons with a corner number = turns or value,
  damage and armour), the enemy in a column on the right with its own icons; the board goes from
  420 to 346 px tall (4 dice of 64 px still fit).
- Tap an icon: a pop-in under the card (effect, who, turns left, what it does); tap elsewhere closes.
- Core: nothing to change (same data: statusEffects, block, parry, Fury / Watchfire, the telegraph).
  To write before building: the pop-in texts (EN + FR) with the exact numbers; Fury, Parry and
  Watchfire already have texts in the game (fury_tip, parry_tip, watchfire_tip), Poison, Stun,
  Weaken, Block and Shelter do not.

## Round 4: variant A'' (fixed slots, target line, two-tap lock)
User feedback: no dynamic spaces; max 3 per side, equal blocks; tap a die: a line to its target (an
enemy, or an ally for a heal); tap again to lock it (it drops small below the board); a locked die
returns to the board with a double tap until a new roll is triggered, then the lock is final.
Picture: `docs/ux-shots/combat2/variant-A3-fixed-slots-targeting.png` (3+3 slots, all six the same size, 192 x 70 px, the enemy blocks identical to the party blocks; 2 allies vs 1
enemy with empty slots; a strike die with its line; a heal die with its line to an ally; the second
tap; the double-tap return; the sealed locks after a new roll).

How it works today (fight_view.dart / fight_cards.dart / fight_rounds.dart / fight_dice_rules.dart):
- **Lock.** Tapping a die toggles `_lockedActorIds` at once (a long press opens the face sheet);
  locked dice are not re-rolled; a Steady face is locked for good. A die can be released again
  at any time before the last roll (cap `_rollCap`).
- **Strike target.** `_selectedTargets[actorId]` (enemy key); in a solo fight it is automatic. In a
  pack fight the player selects a party card (`_selectedActorId`) and taps an enemy card
  (`canRetarget`). Companions follow the player's pick while `_companionsAutoAim` is on (a
  setting); `_autoAssignTargets` overwrites their picks.
- **Heal.** There is no target: a heal goes to the one who plays it (`actor.currentHealth += healing`,
  fight_rounds.dart ~291), Shelter shares a part with the others (`_shelterFrom`). Block is the same.

Look and interaction only (UX): the fixed 3+3 slots; selecting a die (reusing `_selectedActorId`)
and drawing the line to `_selectedTargets`; two-tap lock; the kept row; the double-tap release.
Needs Core (rules / state): (1) a heal aimed at a chosen ally (new target state and its use in
`_confirmRoll`; companions would aim at the most wounded); (2) a lock that becomes final once a
new roll is triggered (a frozen set, today it can be released until the last roll); (3) the party
size: the Barracks Annex gives 4 seats, the user asks for 3 slots (a decision: 3 slots and the
Annex +1 stays unseen, or 4 fixed slots when it is built). Enemy packs are at most 3 (chapter 3+).
Companion lines are read-only while auto-aim is on (companions follow the player), editable when off.

## Round 5: the board's look by place, weather on the whole screen, events on the board only
Picture: `docs/ux-shots/combat2/board-skins-weather-events.png` (four full frames: dunes + dust,
city streets + rain, ship deck + sea storm, cliff + earth break; the earth break in four phases;
four other events; the 13 board skins).
- **Place -> board skin.** The game has 11 fight stages already (`FightStage`, field_anomaly.dart:
  fields, dunes, saltFlats, waves, ash, terraces, cliffs, reeds, snow, glass, hall), chosen from the
  biome by `fightStageOf`; the 11 board skins follow with no Core change. City streets and a ship's
  deck are not stages: two new values and the choice of place (a town, a ship) are a small Core
  change (enum + `fightStageOf`); without it a town falls back to fields and a ship to waves.
- **Weather** (`WeatherKind`: clear, cloud, fog, rain, snow, dust, ash): one overlay above the whole
  screen (header, cards, board, buttons), never blocking touches; today the rain is part of the
  painted backdrop behind the cards.
- **Events** (`FieldAnomalyPlan`: sandstorm, earth_break, flash_flood, rockslide, blaze, sea_storm...,
  each with an omen / active / over phase): a layer clipped to the board's rounded corners that
  follows the phases (earth break: fine cracks and a banner, then wide cracks with dust and a
  shake, then dull cracks and settling dust). Nothing outside the board moves.
- Reduced motion: still weather (very light), no shake, cracks and waves drawn still.
- Everything is drawn in code (patterns and strokes); no image to add. The painted stage behind
  the cards is UX map's and is not touched.
