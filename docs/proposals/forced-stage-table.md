# forcedStage table for Narrative (from UX)

The fight scenes of the story whose **text names a terrain** that is not the one the fight is drawn on today. Written from `assets/Cleaned_Narrative_DAG.json` and the geography; UX does not edit the DAG: Narrative decides each row.

## How to read it
- `forcedStage` is a field of a **choice** that starts a fight (`story_node.dart`, `choice.forcedStage`): the fight is drawn on that stage, whatever the place says. It is written 0 times today.
- **Today** is what the fight shows now: the place's own `stage`, else its biome's stage, a town or city's road, else open country (which has four faces by place since v1.665: open country, woods, ford, burnt fields).
- **Suggested** is the stage the text points to. **strong** = the word appears more than once or is the only terrain word; **check** = one mention, possibly incidental (a name, a figure of speech, another place): read the line before writing it.
- Valid stage names: `fields`, `dunes`, `saltFlats`, `waves`, `ash`, `terraces`, `cliffs`, `reeds`, `snow`, `glass`, `hall`, `cityRoad`, `shipDeck`, `ruins`, `woods`, `ford`, `burntFields`, `oasis`, `caravanRoad`, `quay`, `pass`.
- Where several terrains are named the most specific wins (quay over shore, ruins over street); the others are listed under "also".
- The same list as data: `docs/proposals/forced-stage-table.json`.

**39 scenes, 66 fight choices** (of 95 fight scenes).


## `quay` (The quay): 14 choices

| Node | Place | Today | Confidence | Choice | The text says |
|---|---|---|---|---|---|
| `2015` | saltmouth_wharf | cityRoad | check | Deal with a lurking smuggler captain | …merchants still plied their trade along the wharf. They had concluded that empires rise and fa… (also: cityRoad) |
| `2015` | saltmouth_wharf | cityRoad | check | Fend off a plague hound | …merchants still plied their trade along the wharf. They had concluded that empires rise and fa… (also: cityRoad) |
| `2015` | saltmouth_wharf | cityRoad | check | Break up two harbor rats over spoiled cargo | …merchants still plied their trade along the wharf. They had concluded that empires rise and fa… (also: cityRoad) |
| `2015` | saltmouth_wharf | cityRoad | check | Answer the harbor master’s bounty on the wharf b | …merchants still plied their trade along the wharf. They had concluded that empires rise and fa… (also: cityRoad) |
| `2015_house_drowned_debt` | saltmouth_tern_row | cityRoad | check | Break the chain and see off his friends | …of his hand said why. The Drowned Debt, the wharf calls people like him: Crows who borrowed fr… (also: shipDeck) |
| `7002` | hollow_shore | glass | check | Put down the reflections walking the sand | …n** on a bridge, in a locked chamber, on the docks, **each of them wearing a face I remembered*… (also: dunes, waves, hall) |
| `7510_dominion` | candlehold_gates | cityRoad | check | Take the Hall stair with the Houses behind you | …I came up Candlehold’s harbour steps under the Dominion’s own gonfalon, tid… (also: cliffs) |
| `2011` | saltmouth_wharf | cityRoad | strong | Continue through the Docks | …apped wet boards as I pushed deeper into the docks, without the courtesy of an explanation.  So… |
| `2015_dockside` | saltmouth_wharf | cityRoad | strong | Back through the fish-stink and the shouting | …The harbor master was a weathered woman with the exhaus… (also: cliffs, cityRoad) |
| `2015_informant_exposed` | saltmouth_landward_gate | cityRoad | strong | Go after the warden he named | …n still sharp on every coin. I asked where a wharf rat came by so much of it, and he told me, b… |
| `2015_informant_trap` | saltmouth_landward_warehouse | cityRoad | strong | Drift back along the wharf | …sharp on every coin: the going rate on this wharf, a dockhand told me afterward, for anything… |
| `2015_kelda` | saltmouth_landward_gate | cityRoad | strong | Hold the gate beside her | …A dwarf in a dented cuirass held the wharf gate alone. A barrel for a barricade, no one… (also: shipDeck) |
| `7100` | white_anchorage_quay | cityRoad | strong | Face the last company still at war | …ls, a chapel made from a flagship’s stern, a harbor wall of anchors. **The crusaders who had sai… |
| `7510_crows` | candlehold_gates | cityRoad | strong | Ram the harbour chain with the Eel | …come to everything, and anchored across the harbour mouth under black pennants, three rings on e… |

## `caravanRoad` (Caravan road): 2 choices

| Node | Place | Today | Confidence | Choice | The text says |
|---|---|---|---|---|---|
| `2000` | saltmouth_landward_gate | cityRoad | check | Attack | …the salt flats in the night and claimed the caravan’s grain wagon. Their eyes glowed a sick gree… (also: saltFlats) |
| `2020` | saltmouth_landward_gate | cityRoad | strong | Ambush the inspector | …knees.  Heavy boots walked the length of the caravan. **A spear went into the next wagon’s sacks… |

## `dunes` (Dunes): 1 choice

| Node | Place | Today | Confidence | Choice | The text says |
|---|---|---|---|---|---|
| `7100_house_order` | white_anchorage_chapel | cityRoad | strong | Give her the rest the glass refused her | …her.  I found her where the strand turns to dunes. The tear had been at her. She was still sta… |

## `reeds` (The fen): 2 choices

| Node | Place | Today | Confidence | Choice | The text says |
|---|---|---|---|---|---|
| `6100_clan_mire_2` | rimewell | snow | strong | Meet the hunters on the road instead | …The child had come out of the fen two winters ago and walked to Rimewell. Nobo… (also: snow) |
| `7510_mire` | candlehold_gates | cityRoad | strong | Take the Reed Gate with fever-bark and blades | …The Mire Courts came to Candlehold as the fen comes t… |

## `snow` (Frost / snow): 6 choices

| Node | Place | Today | Confidence | Choice | The text says |
|---|---|---|---|---|---|
| `6010` | reliquary_quarter | cityRoad | check | Drive off the void hounds circling the reliquary | …ad been given up to the tear’s slow weather: frost on the cobbles in summer.  What was left of… (also: cityRoad) |
| `6010` | reliquary_quarter | cityRoad | check | Answer the penitent’s challenge | …ad been given up to the tear’s slow weather: frost on the cobbles in summer.  What was left of… (also: cityRoad) |
| `6010` | reliquary_quarter | cityRoad | check | Hunt the unstitched thing in the chapel | …ad been given up to the tear’s slow weather: frost on the cobbles in summer.  What was left of… (also: cityRoad) |
| `6010_candle_walk_fight` | reliquary_quarter | cityRoad | strong | Unmake it and take the count | …Past the frost line the Quarter stopped being a quarter: co… (also: cityRoad) |
| `6010_masked` | reliquary_quarter | cityRoad | strong | Break the chair-chapel, and take her out | …She had stood at the edge of the frost every time I crossed the quarter, a girl in… |
| `6010_masked` | reliquary_quarter | cityRoad | strong | Fight her | …She had stood at the edge of the frost every time I crossed the quarter, a girl in… |

## `cliffs` (Sea cliffs): 14 choices

| Node | Place | Today | Confidence | Choice | The text says |
|---|---|---|---|---|---|
| `7520_tallis` | candlehold_throne_room | hall | strong | Put out her lamps, and leave her the First | …and it to someone I do not know**.” Down the cliff, lamp after lamp was being lit, and every on… |
| `7520_tallis` | candlehold_throne_room | hall | strong | Put out the First Lantern in her hands | …and it to someone I do not know**.” Down the cliff, lamp after lamp was being lit, and every on… |
| `7520_tallis` | candlehold_throne_room | hall | strong | Put out her lamps, and leave her the First | …and it to someone I do not know**.” Down the cliff, lamp after lamp was being lit, and every on… |
| `7520_tallis` | candlehold_throne_room | hall | strong | Put out the First Lantern in her hands | …and it to someone I do not know**.” Down the cliff, lamp after lamp was being lit, and every on… |
| `7520_tallis` | candlehold_throne_room | hall | strong | Put out her lamps, and leave her the First | …and it to someone I do not know**.” Down the cliff, lamp after lamp was being lit, and every on… |
| `7520_tallis` | candlehold_throne_room | hall | strong | Put out the First Lantern in her hands | …and it to someone I do not know**.” Down the cliff, lamp after lamp was being lit, and every on… |
| `7520_tallis` | candlehold_throne_room | hall | strong | Put out her lamps, and leave her the First | …and it to someone I do not know**.” Down the cliff, lamp after lamp was being lit, and every on… |
| `7520_tallis` | candlehold_throne_room | hall | strong | Put out the First Lantern in her hands | …and it to someone I do not know**.” Down the cliff, lamp after lamp was being lit, and every on… |
| `7520_tallis` | candlehold_throne_room | hall | strong | Put out her lamps, and leave her the First | …and it to someone I do not know**.” Down the cliff, lamp after lamp was being lit, and every on… |
| `7520_tallis` | candlehold_throne_room | hall | strong | Put out the First Lantern in her hands | …and it to someone I do not know**.” Down the cliff, lamp after lamp was being lit, and every on… |
| `7520_tallis` | candlehold_throne_room | hall | strong | Put out her lamps, and leave her the First | …and it to someone I do not know**.” Down the cliff, lamp after lamp was being lit, and every on… |
| `7520_tallis` | candlehold_throne_room | hall | strong | Put out the First Lantern in her hands | …and it to someone I do not know**.” Down the cliff, lamp after lamp was being lit, and every on… |
| `7520_tallis` | candlehold_throne_room | hall | strong | Put out her lamps, and leave her the First | …and it to someone I do not know**.” Down the cliff, lamp after lamp was being lit, and every on… |
| `7520_tallis` | candlehold_throne_room | hall | strong | Put out the First Lantern in her hands | …and it to someone I do not know**.” Down the cliff, lamp after lamp was being lit, and every on… |

## `waves` (The shore): 10 choices

| Node | Place | Today | Confidence | Choice | The text says |
|---|---|---|---|---|---|
| `7002_pact` | hollow_shore | glass | check | Take the pact, and its crown | …watching.  **The Inquisition would hold this shore**, and my camp on the Ashen Coast, and every… (also: ash) |
| `7200_clan_vigil_3` | greyhithe | glass | check | Hold its eye until it goes | …would I. The tear stood open off the Hollow Shore like a door, and Greyhithe had been through… (also: ruins) |
| `6002_siege_breach` | cove_camp | cliffs | strong | Stand in the breach | …long moment the camp was not a camp, only a beach with people on it and things that wanted the… |
| `7002_approach` | hollow_shore_battlefield | glass | strong | Cut a road straight through them | …to be called in.  **The Host could hold the beach. It could not go into the water**: the tear… |
| `7100_impound_fight` | white_anchorage_impound | cityRoad | strong | Clear the hull and take the haul | …ll, when I got it free, said so to the whole shore**.  The two soldiers came down the ladder wi… |
| `7200` | greyhithe | glass | strong | Put down the reflection wearing a child’s face | …ughed up its houses and people on the Hollow Shore, nets in hand, the grey in their faces.  The… |
| `7510_open_hand` | candlehold_gates | cityRoad | strong | Hold the grey hand up at the gate until it break | …oever had stood under the spar on the Hollow Shore, and a cloth with a figure on it, arms raise… |
| `7810` | hollow_shore_battlefield | glass | strong | Lead the Host at the Herald yourself | …The Host came ashore on the Hollow Shore at dawn under every banner I had, and the re… |
| `7810` | hollow_shore_battlefield | glass | strong | Hold the line and let the Herald break on it | …The Host came ashore on the Hollow Shore at dawn under every banner I had, and the re… |
| `7810` | hollow_shore_battlefield | glass | strong | Answer its crowned copy with the true hand | …The Host came ashore on the Hollow Shore at dawn under every banner I had, and the re… |

## `ash` (Ashlands): 8 choices

| Node | Place | Today | Confidence | Choice | The text says |
|---|---|---|---|---|---|
| `3005` | ashen_quarter_gate | cityRoad | check | Cut down the chanting acolyte | …The Ashen Quarter lay at the Spire’s foot, **a day’s w… (also: cityRoad) |
| `3005` | ashen_quarter_gate | cityRoad | check | Snuff the grey candle over the ashes | …The Ashen Quarter lay at the Spire’s foot, **a day’s w… (also: cityRoad) |
| `3005` | ashen_quarter_gate | cityRoad | check | Hunt the void stalker in the ruins | …The Ashen Quarter lay at the Spire’s foot, **a day’s w… (also: cityRoad) |
| `3005` | ashen_quarter_gate | cityRoad | check | Break the iron golem guarding the vault | …The Ashen Quarter lay at the Spire’s foot, **a day’s w… (also: cityRoad) |
| `3005` | ashen_quarter_gate | cityRoad | check | Drive off two auxiliaries sifting the ash | …The Ashen Quarter lay at the Spire’s foot, **a day’s w… (also: cityRoad) |
| `3005_clan_compact_1` | ashen_quarter_cinder_row | cityRoad | check | Hold the left side of the cart | …go cold to starve the Tribunal’s forges, and Cinder Row had been dark ever since. Now they meant… (also: woods) |
| `6010_clan_compact_3` | reliquary_hammer_chapel | cityRoad | check | Take it off the velvet | …When Cinder Row broke its hammers after the Spire, **it… (also: hall) |
| `3200` | akagiri | terraces | strong | Break the exorcists’ salt circle | …of its own steam, the only warm place on the Ashen Coast. **The oni had come over the mountains… |

## `ruins` (Ruins): 9 choices

| Node | Place | Today | Confidence | Choice | The text says |
|---|---|---|---|---|---|
| `400` | alster_family_house | cityRoad | check | Charge him | …n in any city: Lysa. A man walked out of the ruin holding my sister off the ground by one wris… (also: cityRoad) |
| `105` | blind_beggar | cityRoad | strong | Put the bouncer down | …like a sleeper. People climbed out over the rubble, or did not.  Three steps in, someone steppe… |
| `105` | blind_beggar | cityRoad | strong | Get the looter off her | …like a sleeper. People climbed out over the rubble, or did not.  Three steps in, someone steppe… |
| `105` | blind_beggar | cityRoad | strong | Clear the door | …like a sleeper. People climbed out over the rubble, or did not.  Three steps in, someone steppe… |
| `3005_clan_vigil_1` | ashen_quarter_wall_of_names | cityRoad | strong | Hold your stretch of rubble | …six spears in the Quarter, and a stretch of rubble wall on its northern edge, where the ash gav… |
| `3005_clan_vigil_1_breach` | ashen_quarter_wall_of_names | cityRoad | strong | Hunt it down through the ash | …st of them, the smallest: **it came over the rubble where I had said nothing would**, past the s… |
| `3005_oath` | ashen_quarter_ash_market | cityRoad | strong | Return to the district’s streets | …I signed on anyway. An oath sworn to ash and ruin was at least honest about what it expected o… |
| `3200_house_road_exorcists` | akagiri | terraces | strong | Hold him, and take what comes out | …the village, below the last terrace, with a burnt-out lantern on a staff and a patient.  He was a… |
| `7510_penitents` | candlehold_gates | cityRoad | strong | Break the shield-wall at the Exorcists’ Gate | …everywhere, barefoot, in no hurry, lanterns burnt out, the cloth of names carried in front where a… |
