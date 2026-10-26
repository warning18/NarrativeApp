# Wave 18 draft texts (Narrative)

Draft of the texts for `wave18-narrative.md`, EN and FR, in `wave18-texts.json`. Nothing is wired; they wait for Core's hooks (held-by condition, locked districts, district quests, flip and attack events, companion triggers).

- **district_quests (6):** one quest per held district (Card Row, Tern Row, Cinder Row, the Spire Stair, the Chapels, the Anchor Quay), two choices each, with a result line.
- **district_keepers (6):** the named face of each district and three barks: held by the original holder, flipped, contested.
- **notices (7):** flip news and town line, attack alert and its three answers (defended, joined, ignored), and the locked-district reason. `{district}`, `{clan}` and `{rival}` fill in; in French the clan names come in the "de" form ("la bannière du Pacte des Cendres"), so each French line puts them after "bannière".
- **companion_remarks (8):** `districtFlipped` and `districtAttacked` for each companion.
- **epilogue_lines (6):** one line per district for the epilogue map.
