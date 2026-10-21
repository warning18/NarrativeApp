# Warding the road: the texts (Narrative, for docs/proposals/wave16-core.md §2)

Ready if the user picks item 2. `ward-lines.json`, EN and FR:

- the two lines Core asked for: `ward_set` ("The cairn hides your trail from {clan}.") and `ward_ended` (the ward running out), plus `ward_set_nemesis` for the nemesis's champion;
- the camp-tray lines for the Warding Cairn's new target: `ward_choice` (the button), `ward_choice_hint`, `ward_length` ("{roads} roads · {cost} charges"), `ward_no_target` (when no clan hunts you);
- the Journey's small mark: `ward_mark` ("Warded from {clan}: {n} roads").

**Placeholders.** `{clan}` is the clan's short name in English. In French a clan needs "de" with its article ("du Dominion de la Lanterne", "des Corneilles de Sel"), so the French lines use `{clanOf}` (the clan's `nameOf_fr` from `factions.json`); Core can fill `{clanOf}` from that field with no new data. The texts name no number, so they hold if the 3 / 6 / 9 roads change.
