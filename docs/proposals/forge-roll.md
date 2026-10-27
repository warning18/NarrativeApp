# Forging rolls for its result (Core, proposal)

Design only. Written on v1.551. The user wants forging to roll a die that decides how good the piece is, with an animation.

## Today

`craftItem` (`lib/providers/player_session_provider.dart`) checks `canCraft`, takes the recipe's `craftGold` and `craftMaterials` from the pack, and adds the piece. There is no chance in it. Four items have a recipe today, all Uncommon and all forged at `hammersmith_forge`. The Iron-Shod Boots are one: 60 gold and 3 iron ore.

## The die: the forge's own d20, not one of the party's

The party's dice are what it fights with. Spending one, or picking one from the cup, would make the forge compete with the next fight. That mixes two systems the player already reads separately.

The forge instead rolls one **d20**, the same roll and the same widget as the crossing checks (`D20Roll`, wave 6). The player sees the face land, then the modifiers added, then the tier.

## Tiers

The total is the d20 plus the modifiers below.

| Total | Tier | The piece |
|---|---|---|
| 1–4 | **Flawed** | −1 to its main number (armour, or damage for a weapon), never below 0 |
| 5–14 | **Sound** | as listed |
| 15–19 | **Fine** | +1 to its main number |
| 20 or more | **Masterwork** | +2 to its main number |

With no modifier the odds are: flawed 20%, sound 50%, fine 25%, masterwork 5%. On average a forged piece is worth +0.15 of its main number, so forging stays about as strong as today, with a spread.

**A flawed roll loses nothing.** The gold and the materials are spent as today and the piece is made, flawed. It can be sold. Iron ore is scarce and there are only four recipes, so losing the materials would feel like a punishment, not a gamble.

## What moves the odds

- **A dwarf hero: +2.** This is the race's forge lore. With it, flawed drops to 10% and masterwork rises to 15%.
- **Standing with the forge's holder.** At Friendly or better, +1; at Hostile or worse, −1. The holder is the clan that holds the forge's district (`holderOf`). Whether this should follow the forge's prices too is checked at build time.
- **The camp's roll houses** (v1.482: reroll, raise). If the camp has built one, it works on this roll as it does on an offer: one reroll, or one +1 a day.
- **Nothing else for now.** No stat adds to the roll, so the odds stay easy to read on the sheet.

## How a tier is kept

The pack holds item ids, so two boots of the same id can't differ. A forged piece above or below Sound takes a variant id: `boots_iron_shod@fine`. The item loader resolves it to the base item with the tier's change, and a prefix name ("Fine Iron-Shod Boots" / « Bottes ferrées fines »). Saves, the shop's resale price (Fine and Masterwork +25% / +50%, Flawed −25%) and the simulator all read the same id.

## For the simulator, later

The rule is pure: `forgeRoll(d20, modifiers) → tier` plus `forgedItem(baseId, tier)`. The playthrough walk can forge on the same seed and record the tier in the run. What we would measure:
- how often each tier lands, by race;
- the main-number gain a run gets from forging;
- whether the dwarf +2 moves a dwarf's win rate. If it moves it by more than one point, lower the bonus to +1.

## For UX

UX draws the sheet and the forging moment. Core gives them:
- the d20 face;
- each modifier with its source ("Dwarf +2", "Friends of the Pact +1");
- the total;
- the tier;
- the piece's before and after.

A reroll from a camp house replays the same roll on screen.

## Questions for the user

1. Should a flawed roll lose the materials (harsher) or only make a weaker piece (as proposed)?
2. Should Masterwork add a sign, on top of the +2? That needs a sign per item type.
3. Should the dwarf bonus apply only at the Hammersmith's forge, or at any forge?
