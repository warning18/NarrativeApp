# Hub rows that do nothing: candidates (Narrative)

For the manager and the user to mark **keep** or **drop**, one by one. **Nothing is removed until each is marked.**

**Correction to `narrative-improvements-2.md` item 3.** The first count (30 rows) used a one-level test and over-counted. Checked again: 16 of the 30 are not "do nothing": they open a sub-scene with an outcome (a fight, a gold or alignment change, a trap, a won game: `2015_informant`, `2015_ternrow`, `2015_cards`, `2015_liora`, `2015_vane`, `2015_doors`, `3005_wall`), or open a shop or a place that tests pin by id (`2015_bazaar`, `2015_apothecary`, `6010_confession`, `6010_lantern`, `5010_archivist_words`, `5010_trade`, `5010_deserter_later`, `7100_chandlery`, `7100_cutter`). That leaves **12 leaf scenes reached straight from a hub row** (two more, `2015_dorran` and `2015_cardrow_tally`, are reached from other scenes, not from the hub): one short scene, one way back, only the hub's own flag. They are listed here.

**What dropping one costs, honestly:** every one of them is also a *place* on the map (`lib/data/world_map.dart` lists each scene id, and `location` anchors it), and its `hub_<hub>_<name>` flag hides the row once read and feeds the hub's progress lines and callbacks. So a drop means: remove the row, the scene, its `world_map.dart` entry, the flag uses, and the scene count tests. It also removes a person or a corner of the town. The gain is a shorter hub menu; the loss is a voice. My recommendation is to keep most and drop only the ones marked *thin* below.

| Hub | Scene | Row text | Chars | Flag used in DAG | What it gives | Recommend |
|---|---|---|---|---|---|---|
| `2015` | `2015_dorran` | Hear the dwarf foreman at the breaker’s yard | 428 | 3 | The ship-breaker’s yard ran on scaffolding, and the scaffolding ran on a dwarf named Dorran Quill, who had rig… | keep |
| `2015` | `2015_cardrow_tally` | Hear the tally-man out at Card Row | 523 | 3 | Voss kept the tally on a slate nailed to the nearest barrel, and the slate and the stack disagreed. He did not… | keep |
| `2015` | `2015_ternrow_buyer` | Hear out the lantern-maker on Tern Row | 634 | 3 | Dunn made lanterns for the paper boats, slowly, the way you make something that has to be right once. She had … | keep |
| `6010` | `6010_chartkeeper_words` | Ask the chart-keeper what the last page cost | 395 | 2 | "You want to know what the last page cost," she said, before I had asked. "**My sister’s name**. She was on it… | keep |
| `6010` | `6010_lysa_later` | Walk the frost with Lysa | 282 | 2 | Lysa walked the frost with me, not talking, which was what we had always been best at. At the edge of the quar… | thin: drop |
| `6010` | `6010_lantern_keeper` | Hear what the Last Lantern’s keeper has seen | 361 | 3 | The Last Lantern’s keeper had seen the tear open, and said so the way people say they have seen the sea. "**It… | keep |
| `6010` | `6010_orsabet` | Sit with the widow who counts the taken | 479 | 4 | Orsabet Vell lit a candle for every person the tear had taken from the Reliquary Quarter: **four hundred and e… | keep |
| `3005` | `3005_imeh` | Hear the oni glass-trader at the ash-market | 505 | 3 | She had set her stall where the ash was thinnest: a plank on two barrels and a hundred pieces of terrace glass… | keep |
| `7200` | `7200_nets` | Haul the nets with the grey fishers | 225 | 2 | The nets came up full of fish from no sea I knew, pale and quick and perfectly edible. The grey fishers sorted… | thin: drop |
| `5010` | `5010_tobin_hymn` | Sit with Tobin while he trims the wicks | 519 | 2 | I sat on the ledge while Tobin trimmed the wicks and did not sing.  “I will tell you what I tell the dying,” h… | keep |
| `5010` | `5010_house_herons_wake` | Follow a Heron’s Wake guide, on her terms | 655 | 5 | Some of the Cloister’s refugees would rather risk the fen than wait for the Court to remember them, and a guid… | keep |
| `5010` | `5010_brannoc` | Hear the elf healer out about his bark | 471 | 3 | The cloister’s healer worked the driest ledge with no medicine at all: an elf with the Barkbleeders’ cut scars… | keep |
| `7100` | `7100_nkem` | Hear the Brig-Born salvager out | 451 | 3 | Nkem Tallow worked the White Fleet’s grave for what the sea gave back, out of a boat the Brig-Born had built f… | keep |
| `5100` | `5100_nets` | Mend nets with the weed-cutters | 210 | 2 | Mending nets leaves the head free, and mine went, for once, nowhere in particular. The weed-cutters sang while… | thin: drop |
