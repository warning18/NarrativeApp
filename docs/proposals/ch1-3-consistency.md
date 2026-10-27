# Chapters 1–3: consistency review

Scope: the 182 story nodes of chapters 1–3 (DAG ids below 4000), their
`flag_callbacks`, and the quests, npcs and companions that appear in them.
Read in full in EN and FR. Checked by hand and by script: names, numbers,
negations, quotes, paragraph structure.

No choice, outcome, reward or number was changed. Every fix below is wording
only. Status: **fixed** (done on this branch) or **decision** (a story
question for the user; nothing changed).

## Table

| Scene id | What is inconsistent | Proposed fix | Status |
|---|---|---|---|
| 105 `casino_fled` | "a man I had taken eleven silver off an hour before", but scene 100 says I had been losing all evening | "a man I had won eleven silver off between two losses" (FR: « gagné … entre deux pertes ») | fixed |
| 895 | "forty times that evening"; the scene is the morning line (890_trainer) | "that morning" / « ce matin-là » | fixed |
| 1120 `tear_refused` | "the tear's ring" — no ring exists anywhere in the scene | "whatever lay under the tear" / « ce qui gisait sous la déchirure » | fixed |
| 2015_crow_offer | "A Crow tally-boy"; the hub callbacks in 2015 say tally-girl and FR says *gamine* | "tally-girl" | fixed |
| 2015_dominion_blades | "a charter older than the Dominion"; `relations.json` dates the Charter of Anvils (212 BT) after the Dominion (600 BT) | "older than anyone now living" / « toute mémoire vivante » | fixed |
| 2015_ternrow | Renn is a "customs officer" (EN) and *douanier* / *inspecteur* (FR) here, but "overseer" in the quest, `npcs.json` and the scene's own prompt (*contremaître*) | one title everywhere: "customs overseer" / « contremaître des douanes » | fixed |
| 2015_ternrow | ’landing toll’ and ’deportation’ use closing marks as opening marks | ‘…’ | fixed |
| 2015_cards_won, 2015_sable_lifted, _caught, _bought, _talk_failed | FR "capitaine du port" for the person the hub calls *maître du port* | « maître du port » | fixed |
| 2015_cardrow_tally, _count; the card-row quest texts in `quests.json`; wave 18 draft texts | FR "Corbeaux" for the Crows; canon is « Corneilles de Sel » | « Corneilles » | fixed |
| 2015, 2900 | FR "Enfants-de-Marée"; canon is « Gens de la Marée » | « Gens de la Marée » | fixed |
| quests (Salt Ledger scaffold quest) | FR "clerc du Registre"; the scenes say *greffier* | « greffier du Registre » | fixed |
| `npcs.json`, `quests.json`, the 5010 nodes | FR "Porte-Clés"; canon is « Porte-Clefs » (singular « Porte-Clef ») | canon spelling | fixed |
| 33 nodes, among them 250, 800, 890_trainer, 1002, 2005, 2010, 2011, 2050, many 2015_* scenes and the 3005 / 3200 clan scenes | EN and FR break paragraphs in different places (same sentences, different breaks); the story editor shows them side by side | breaks aligned (33 nodes; text identical apart from whitespace) | fixed |
| 470, 2015 hub (`sable_marker_won`) | already guarded on main (keeper callback, Sable callback) — checked, nothing to do | — | ok |
| 2015 hub | Lantern Alleys is locked after a clan flips it (wave 18) but the hub still offers the Bazaar and the Apothecary there | keep the two story ways open (they are quests), or lock them with the district? | **decision** |
| `q_ch2_tern_row_wrong_name` / 2015_ternrow | the Tern's Toll objective is a kill of `dock_overseer`; the "talk Renn down" path completes nothing for it, so the quest cannot be turned in that way | Core: complete the objective on the talk path, or the quest text stops promising it | **decision** (Core + user) |
| 2030 | Vane greets the player by name though 2010 says he "had never heard of me" | leave: he has read the Wharf's slate by then; or add one line saying so | **decision** (minor) |
| 2005 | "the Crows' tally-boys" (plural, a crowd) next to the single tally-girl later | leave: a crowd of boys, one girl who speaks | ok |

## Checked and clean

- Names and places across the 182 nodes: place spellings and the clan names in EN and FR (drift listed above).
- Numbers and negations are the same in EN and FR (`parity` check).
- No scene assumes a choice that was not made: the flag-gated callbacks all carry their `andFlags` / `unlessFlags`.
- Not settled: 2015_lysa_line says the girl came through the landward gate "in the spring"; I could not tie that to a date in 2000 or the quest log. Left as is.

## Tests run

`story_rules`, `french_data_lint`, `qa_story_fr`, `qa_markup`,
`story_graph_integrity`, `narration`, `quest_rewards`, `turn_in_choices`, and
the DAG-reading batch (554 tests) — all green. `dart format` clean.
