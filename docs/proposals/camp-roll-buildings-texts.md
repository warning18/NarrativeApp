# Camp roll buildings: the texts (Narrative, for docs/proposals/camp-roll-buildings.md)

`camp-roll-buildings-texts.json`, EN and FR, for Core to take into the code PR:

- `houses`: `houseName`, `houseName_fr`, `description`, `description_fr` for `bone_casters_hut` (Reroll), `warding_cairn` (Banish) and `star_well` (Raise), for `houses.json`. The names follow the draft's; the French reads "La hutte du jeteur d’os", "Le cairn de garde", "Le puits aux étoiles" (lower case after the article, as the other houses do).
- `strings`: the three button labels with `{left}` (`roll_reroll`, `roll_banish`, `roll_raise`), the Banish 5/10/15 choice label (`roll_banish_length`: `{draws}`, `{cost}`), the result lines (`roll_reroll_done`; `roll_banish_done` with `{name}`, `{draws}`; `roll_raise_done` with `{name}`, `{rarity}`), the Reroll warning, the list line `roll_warded` (`{n}`), and the no-charge line `roll_no_charge`. The key names are my suggestions; Core can keep the placeholders and rename the keys.
- `camp lines`: `house_bone_casters_hut` and `house_warding_cairn` are `flag_callbacks` of `4999_camp`, `house_star_well` of `6002_camp` (the Well comes at chapter 5), already in the DAG on this branch, so `camp_base_test` passes once the three houses exist in `houses.json`.
  - French verbs: Relancer, Écarter, Hausser. "Écarter" for Banish keeps the card out of play without the religious weight of "bannir".
  - The `{cost}` plural: both languages write "charges" even for 1; the note's costs are 1, 2 and 3. If you want "1 charge", Core can pick the key by count, or I give a `_one` variant.

No data file is changed in this branch.
