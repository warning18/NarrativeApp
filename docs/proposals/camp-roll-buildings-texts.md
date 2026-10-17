# Camp roll buildings: the texts (Narrative, for docs/proposals/camp-roll-buildings.md)

`camp-roll-buildings-texts.json`, EN and FR, for Core to take into the code PR:

- `houses`: `houseName`, `houseName_fr`, `description`, `description_fr` for `bone_casters_hut` (Reroll), `warding_cairn` (Banish) and `star_well` (Raise), for `houses.json`. The names follow the draft's; the French reads "La hutte du jeteur d’os", "Le cairn de garde", "Le puits aux étoiles" (lower case after the article, as the other houses do).
- `strings`: the six keys the note names (`roll_reroll`, `roll_banish`, `roll_raise`, `roll_banish_length`, `roll_reroll_warning`, `roll_warded`), plus two I suggest for the charge lines (`roll_charges_left`, `roll_no_charge`).
  - Placeholders: `{n}` (charges, or draws for `roll_warded`), `{draws}` and `{cost}` in `roll_banish_length`. Tell me if the code names them otherwise and I rewrite.
  - French verbs: Relancer, Écarter, Hausser. "Écarter" for Banish keeps the card out of play without the religious weight of "bannir".
  - The `{cost}` plural: both languages write "charges" even for 1; the note's costs are 1, 2 and 3. If you want "1 charge", Core can pick the key by count, or I give a `_one` variant.

No data file is changed in this branch.
