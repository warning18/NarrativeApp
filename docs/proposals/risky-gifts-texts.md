# Risky gifts: the texts (Narrative, for docs/proposals/risky-gifts.md)

All the text of the risky gift in `risky-gifts-texts.json`, EN and FR, for Core to take into the code PR:

- `strings`: the eight keys named in the note (`offer_risky_badge` … `ledger_curse`), to add next to the offer strings in `app_strings.dart`.
  - `offer_risky_odds` takes `{gift}` and `{price}` (the percentages from the roll table: 75/25, 80/20, 85/15); the FR writes the percent with a no-break space ("75 %").
  - `offer_risky_gift` / `offer_risky_curse` take the clan. A French clan name takes an article and agrees in number ("Les Corneilles", "Le Dominion de la Lanterne"), so the FR gift line puts `{clan}` at the end of a sentence with no verb to agree, and the curse line uses `{clanOf}` (the clan's `nameOf_fr`, "du Dominion de la Lanterne", "des Corneilles"). If the code has only one placeholder, give me the form it fills and I rewrite the FR.
  - `offer_risky_health` says "points de vie" in FR; `{stat}` is the stat's own name in the player's language.
- `clan_offer_lines`: one line per clan that can qualify (11; the Choir and the Pit cannot), in that clan's voice. A new `riskyOffer` / `riskyOffer_fr` field on each clan in `factions.json` is my suggestion; Core can name it otherwise. The card shows it under the gift.
- `parley_tent`: `houseName`, `houseName_fr`, `description`, `description_fr` for the `houses.json` record. Core sets cost, category and footprint.

Numbers in the lines: none. Nothing in them names a result, so they work whatever the die says. No data file is changed in this branch.
