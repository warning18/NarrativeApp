# Wave 18 draft texts (Narrative)

Draft of the texts for `wave18-narrative.md`, EN and FR, in `wave18-texts.json`. Nothing is wired; they wait for Core's hooks (`held_<district>_<clan>`, `lock` with `lockedText`, quests with `district` and `faction`, `district_flipped`, `attack_<district>` flags, the `attack` camp errand, and the two remark kinds).

- **district_quests (6):** one quest per held district (Card Row, Tern Row, Cinder Row, the Spire Stair, the Chapels, the Anchor Quay), two choices each, with a result line.
- **district_keepers (6):** the named face of each district and three barks: held by the original holder, flipped, contested.
- **notices (7):** flip news and town line, attack alert and its three answers (defended, joined, ignored), and the locked-district reason. `{district}`, `{clan}` (the new holder, or the attacker) and `{from}` (the old holder) fill in, as Core named them; in French the clan names come in the "de" form ("la bannière du Pacte des Cendres"), so each French line puts them after "bannière".
- **companion_remarks (8):** `district_flipped` and `district_attacked` for each companion.
- **epilogue_lines (6):** one line per district for the epilogue map.

## Step 1 (Saltmouth) additions
- **saltmouth_tags (10):** each Saltmouth side quest with the district and clan it should carry (`district`, `faction`), and why. Ready to apply to `quests.json` once Core's field names are final.
- **locked_texts (2):** the one-line `lockedText` (EN/FR) for the Lantern Alleys (opens when *The Informant's Tip* is done) and Tern Row (*Tern's Toll*).
- **door_scenes (2):** the door scenes for the two locked districts, EN and FR, with two choices each.
