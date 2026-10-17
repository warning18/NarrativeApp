# The temple: the texts (Narrative, for docs/proposals/temple-service.md)

`temple-service-texts.json`, EN and FR, for Core to take into the code PR:

- `clans`: for each of the 13 clans and tribes that have a `host` kit (the six main clans, the Choir, the Pit, the Giants, the Oni, the Tide-Kin, the Kindly Ones and the Open Hand), the four `factions.json` fields the note asks for: `templeName`, `blessingName`, `templeLine` (the keeper's offer) and `templeLineHunted` (the refusal). Each line names no number, so it stays true if the kit or the prices change; each says "three fights" so tell me if `templeBlessingFights` moves. The temple of a town no clan rules uses the neutral set below.
- `strings`: the twelve keys the note names for `app_strings.dart`, plus `temple_neutral_line` (the keeper's offer at a neutral temple). Placeholders: `{clan}` and `{n}` in `temple_blessing_active`. `{clan}` should be the clan's short name in the player's language ("la Veille", "les Corneilles" would need an article, so tell me the form: I wrote "Béni par {clan}" for a short name with no article).
- The neutral temple's refusal is `temple_refused`: "The keeper will not take your coin." (a neutral temple never refuses; Hunted by its town's clan only).

No data file is changed in this branch.

## Added after Core's second request
- `clans.<id>.blessingGrants` (+ `_fr`): one line of what the blessing grants, taken from the clan's `host.effects` (and the starting block of 1). The numbers are written in the text; if a `host` kit changes, this line needs the same change (or Core generates it from the kit).
- `strings`: the service names and descriptions (`temple_mend_name`, `temple_mend_desc`, `temple_blessing_name`, `temple_blessing_desc`), the price (`temple_price`, `{gold}`), "already blessed" (`temple_blessed_already`), "mended today" (`temple_mended_today`), the Hunted refusal (`temple_refused_hunted`), the result lines (`temple_mend_result`, `temple_blessing_result`) and the neutral temple's blessing line (`temple_neutral_blessing_line`). Several overlap the first set (`temple_mend`, `temple_mend_used`, `temple_refused`): use whichever key names the code prefers; the texts say the same.
