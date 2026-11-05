# Real pictures of the build for the hand test of 1.809 to 1.846

Drawn from `main` at **v1.846.0** by `test/qa_hand_test_shots_test.dart` (only with `QA_SHOTS=<folder>`: `QA_SHOTS=docs/qa/hand-test-1.846 flutter test test/qa_hand_test_shots_test.dart`). It runs the real app (the real screens, the app's own fonts and icons) on a 412 x 860 phone in English, a human warrior, with the stored city plans. Each scene is opened as the Journey opens it (`jumpTo`), after the map has inked in and the place's card and the chapter's notice are closed. The red ribbon in the top right corner is Flutter's debug banner (a test build), not the game. `movement-data.json` holds the raw numbers of the table below. Nothing in `lib/` was touched and nothing here is judged: the pictures say what the screen shows.

## Pictures, by item

| Release, item | Pictures | What to look at |
|---|---|---|
| **1.825 rooms show their spots** | `1825-blind-beggar-100`, `-105`, `-106`, `-110`, `-120` | the Blind Beggar's room: each way is a banner at its spot on the plan |
| 1.825 towns keep banners | `1825-lower-town-chart-250` | the Lower Town's chart (scene 250) and its list of districts under it |
| 1.825 one plain way continues | `1825-one-plain-way-100_dice-map`, `-page`, `-after-continue` | scene 100_dice: the room with Go ready, the page, and after Continue |
| 1.825 White Wells roads south | `1825-white-wells-1200` | scene 1200 with Lysa and Vica alive: the chart shows the district "The Pool, 2 ways"; the two ways are behind the hand badge |
| 1.825 district walk 250 to 260 | `1825-district-walk-250-before`, `-card`, `-mid`, `-arrival` | a tap on "Walk to the Stone Bridge": the camera pans to the toll booth. The walk was already over at the first picture after the tap (0.9 s), so "mid" and "arrival" are the same frame |
| **1.827 Back to the map** | `1827-1101_scarred-map`, `-page`, `-after-back-to-the-map`, `-after-one-tap-on-the-mark` | the wreck of the Lark: Go ready on the map; the page; the map after "Back to the map"; after one tap on the mark the map is as before and the party has not set out (checked by `qa_journey_back_to_map_test`) |
| **1.810 taken line, still-here line** | `1810-2005-1-before`, `-2-cards`, `-3-after` (and the same for 2010, 2015, 2020) | the Landward Gate and the wharf: before, the cards, and after a card is taken (the line "Hide in a salt wagon / Still at The Landward Gate" on top of the page). 2015 is a hub: `1810-2015-2b-chip-list` is the list a chip opens. 2020 has no card on its page: `1810-2020-2-page` |
| **1.815 land crossing** | `1815-land-crossing-0-before`, `-01s` to `-11s`, `-arrival` | "Walk on" from the wreck, Go: the map flight at 1, 2, 4, 7 and 11 seconds, and the arrival |
| 1.815 crossing, days | `1815-sleeper-to-wells-day1-start`, `-step1` to `-step3` | the crossing's own screen (Sleeper's Face to the White Wells), a day and its answers |
| **1.821 / 1.822 camp to the quarter** | `1822-camp-to-quarter-day1-start`, `-step1-answer` to `-step5-answer` | the crossing from the cove camp to the Ashen Quarter, played on its screen: day 1 starts in the cliffs' dithered seam with the ruins; day 2 ends in the ruins ("You reach the far side"). The camp's own button that starts it is greyed in a new game ("Once the coast is known, climb the Spire"), so it is started the way the Journey does it, with the real road and camera |
| 1.822 the camp's tabs | `1822-camp-road`, `-place-card`, `-town-tab` (and `-scroll1` to `-3`), `-party-tab`, `-sea-tab` | the camp screen; `1822-camp-sea-voyage-*` is the sea voyage to The Hollow Shore that the camp's "Go" starts (a voyage, not a land crossing) |
| **1.812 / 1.826 a fight met on a crossing, land behind the cards** | `1826-fight-on-a-crossing-0-prebattle` to `-3-die-picked-aim-line` | the fight drawn with the desert's land behind the cards. It is the fight screen given the crossing's land layers, not the random meeting of a real crossing |
| **1.824 aim line** | `1824-fight-allies-0-prebattle` to `-3-die-picked-aim-line` | a fight with Vica beside the hero: the pink line from Vica's picked heal to its target, over the empty slots |
| **1.831 spoils sheet** | `1831-spoils-4-after-confirm-0` to `-5` | a won fight and its chest: the last pictures are the "Spoils" sheet (gold 0 to 88, potions, antidote, the toggle) with Take |
| **1.829 to 1.844 skill glyphs** | `skills-character-overview`, `skills-screen-tab1` (Tree), `-tab2` (My skills, 62 skills with their glyphs), `-tab3` (Spells) | a level 12 hero who knows every skill that has a glyph |
| **1.819 callbacks** | `1819-callbacks-7800-map`/`-page`, `7004`, `7001`, `7400`, `7500` | each scene with every flag it calls back set (the scene's own list), the map and the page |
| 1.819 second visit, English and French | `1819-revisit-4999-en`/`-fr`, `7800`, `2900`, `7515_rest` | the scene visited twice (away to scene 100 and back); scene "7515" is `7515_rest` in the story |
| **1.820 Edit Mode errand** | `1820-errand-loyal_kelda-journey-edit-mode`, `-editor-top`, `-editor-scroll1` to `-3` | the companion's errand scene in Edit Mode and the scene editor on it |
| **1.814 dice, element and keyword effects** | `1814-effects-gallery-1` to `-4`, `-play-fireball`, `-play-lightning`, `-play-frost` | the Effects gallery (Other tab, Edit Mode tools) and three effects caught as they play; the dice themselves are in the fight pictures |
| 1.814 the campfire | `1814-campfire-camp`, `1814-campfire-rest-0`, `-1` | the camp, then Rest and the fate die dialog |
| 1.814 the chest | `1831-spoils-4-after-confirm-0` to `-5` | the chest opening and its spoils |

## Where a move is on the map, and where it is only a card

What the Journey shows for each scene where a choice takes the hero to another place (or, in a camp, is a button). "Choices" are the ones the player sees with the flags given. "Cards" are the choices listed behind the hand badge at the top of the Journey, read from the screen (the list is in `movement-*-cards.png`). Pictures: `movement-<scene>.png`.

| Scene | What the screen shows | The move | On the map? |
|---|---|---|---|
| 106 Blind Beggar (after the fight) | the room, 2 spots | "Out the back, into the streets" | **yes**: a banner at its spot |
| 110 Blind Beggar (back room) | the room, 2 spots | "Out before the roof goes" | **yes**: a banner at its spot |
| 250 Lower Town | the district chart; under it the districts you may walk to | "Take the Stone Bridge" | **yes**: a row "Walk to the Stone Bridge" under the map (and one banner on the chart's data, outside the frame) |
| 260 Stone Bridge | the town chart, 2 cards | none (both ways stay: "Thirty gold. I did not have it.", "Refuse and fight") | n/a |
| 1101_scarred wreck of the Lark | the land, 1 mark with its label | "Walk on" (to the Sleeper's Face) | **yes**: a mark, Go ready |
| 1140 Sleeper's Face | the land, 1 mark and 2 cards | "Go the long way round" | **yes**: the mark; the other two ways are cards |
| **1200 White Wells** (with Lysa alive) | the district chart "The Pool, 2 ways" and the hand badge 2 | "Go south with Lysa and the caravan" | **no: a card only** (cards: "Sleep by the water", "Go south with Lysa and the caravan"); the map draws no road south |
| 2005 Landward Gate | the district chart: one banner "The salt wagon", hand badge 1 | "Go in with the caravan" | **yes** (the one banner); the card is "Hide in a salt wagon" |
| 2010 Smugglers' Wharf | the district chart, 2 cards | none | n/a |
| 2015 Smugglers' Wharf (the hub) | the district chart with 18 pins and a list "Places here" | the 18 "Visit..." and "Hear..." ways | **yes**: pins and rows; 7 other ways are cards (errands) |
| 2020 Landward Gate | the town chart, district rows; hand badge 1 | "Slip out through the storm drain" (to Smugglers' Wharf) | **yes**: a district row and flag on the town chart; the card is "Ambush the inspector" |
| 3001_camp (the camp, chapter 3) | the Camp tab | "Once the coast is known, climb the Spire" | **no map**: a greyed button on the Camp tab's main-quest card |
| 7400 (the camp, chapter 7) | the Camp tab | "Sail for Candlehold and take the Throne" | **no map**: a greyed button on the Camp tab's main-quest card |
| 7500 Candlehold gates | the scene's page (no map) | none (one way, a card) | n/a |
| 6100_clan_vigil_2 | the town chart, 2 cards | none | n/a |

**Rows where a move is only a card (for the brief to Core): scene 1200, "Go south with Lysa and the caravan".** The two camp scenes (3001_camp, 7400) have their move as a button on the Camp tab, not on any map. In every other row with a move, the move has a mark, banner, pin or district row. Not looked at: "going to your house" (a camp house or a place in the Town tab): the camp's Town tab is in `1822-camp-town-tab*.png` (houses are built, not walked to).

## What I could not render, and why

- **A fight met on a real crossing** (the scavengers of 1.826): the meeting is random. `1826-fight-on-a-crossing-*` is the fight screen with the crossing's land given to it, as the crossing does.
- **A fight's skill list showing the glyphs**: I found no skill list in the fight screen (its board shows dice and faces); the glyphs are on the skills screen (`skills-screen-tab2`).
- **The party mark mid-walk of the district walk 250 to 260**: the walk is instant on the district chart (see the table above); the picture shows the camera pan and the arrival.
- **The camp's own "climb the Spire" button starting the crossing**: greyed in a new game (it needs the coast known); the crossing is started with the Journey's own function instead.
- **Second visits (1.819)**: the pictures show the scene's text on a second visit; whether that text is the scene's "revisit" text is not told by the picture. Scene 7515 is `7515_rest`.
- **A layout finding from the Edit Mode editor** (`1820-errand-loyal_kelda-editor-*`): at 412 px the scene editor's "Destination node" dropdown (`story_node_editor_screen.dart:733`) overflows by 22 px on the right (the yellow and black stripes in `editor-scroll1`). It is an Edit Mode tool.
- Chapter notices: a chapter's first scene opens under its "burning" notice; the pictures wait ten seconds, but a camp scene may still show it faintly (`movement-3001_camp`, `movement-7400`).
