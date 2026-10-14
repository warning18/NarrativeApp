# Location names: the audit (Wave 6)

Every named place in the data, with its English and French name, or **MISSING**. From `assets/gamedata/geography.json` (with the city PR #244's two districts), the story world's chart (`lib/data/chart_story.dart`, the whole sphere of PR #245: its lands, zones, seas, archipelagos and islands). Charts A, B and C (the map looks) carry their own labels and are not listed. Narrative names the missing ones.

**Named since** (v1.312.0): Narrative named everything below marked MISSING (`docs/proposals/location-names-narrative.md` on claude/narrative). The names are in `lib/data/chart_story.dart`, generated from `tool/fmg_chart/story_world.py`: `storyLandNames`, `storyArchipelagoNames`, `storyIslandNames`, and the four oceans as sea labels. The 13 chart regions keep their names. The tables below are the audit as it stood.

**To name** (all from the whole sphere):
- **seven lands:** the west, equator, south-west, north-east and east lands, and the two polar lands;
- **twelve archipelagos and their 29 islands**;
- **the oceans:** none is named;
- **thirteen placeholder region names** on the chart ("chart only" below), which Narrative may keep or rename.

Everything in `geography.json` has both its names.

## Continents (4)

| Id | English | French | In |
|---|---|---|---|
| `old_continent` | The Old Continent | L’Ancien Continent |  |
| `the_seas` | The Seas | Les Mers |  |
| `ashen_continent` | The Ashen Continent | Le Continent cendré |  |
| `lantern_isles` | The Lantern Isles | Les Îles de la Lanterne |  |

## Lands on the whole sphere (the chart's ten lands) (10)

| Id | English | French | Kind |
|---|---|---|---|
| `ashen` | The Ashen Continent (`ashen_continent`) | as the continent | story land |
| `old` | The Old Continent (`old_continent`) | as the continent | story land |
| `lantern` | The Lantern Isles (`lantern_isles`) | as the continent | story land |
| `west` | MISSING | MISSING | empty land |
| `equator` | MISSING | MISSING | empty land |
| `south_west` | MISSING | MISSING | empty land |
| `north_east` | MISSING | MISSING | empty land |
| `east` | MISSING | MISSING | empty land |
| `polar_north` | MISSING | MISSING | polar land |
| `polar_south` | MISSING | MISSING | polar land |

## Countries and lands (9)

| Id | English | French | In |
|---|---|---|---|
| `alster_marches` | The Alster Marches | Les Marches d’Alster | The Old Continent |
| `the_waste` | The Waste | La Désolation | The Old Continent |
| `salt_coast` | The Salt Coast | La Côte de Sel | The Old Continent |
| `narrow_sea` | The Narrow Sea | La Mer Étroite | The Seas |
| `ashen_coast` | The Ashen Coast | La Côte de Cendre | The Ashen Continent |
| `grey_fen` | The Grey Fen | Le Marais gris | The Ashen Continent |
| `frost_reach` | The Frost Reach | Les Confins du Givre | The Ashen Continent |
| `hollow_cape` | The Hollow Cape | Le Cap Creux | The Ashen Continent |
| `throne_demesne` | The Throne’s Demesne | Le Domaine du Trône | The Lantern Isles |

## Regions (geography zones) (12)

| Id | English | French | In |
|---|---|---|---|
| `alster_vale` | The Vale of Alster | Le Val d’Alster | The Alster Marches |
| `dune_sea` | The Dune Sea | La Mer de dunes | The Waste |
| `saltmouth_headland` | The Saltmouth Headland | Le Promontoire de Bouche-de-Sel | The Salt Coast |
| `open_water` | The Open Water | La Haute Mer | The Narrow Sea |
| `the_cove` | The Cove | La Crique | The Ashen Coast |
| `ashlands` | The Ash Flats | Les Plaines de cendre | The Ashen Coast |
| `spring_terraces` | The Red Hills | Les Collines rouges | The Ashen Coast |
| `wrack_cliffs` | The Wrack Cliffs | Les Falaises du Varech | The Grey Fen |
| `the_fen` | The Reed-Beds | Les Roselières | The Grey Fen |
| `frost_road` | The Pilgrims’ Road | La Route des pèlerins | The Frost Reach |
| `glass_shore` | The Grey Sands | Les Sables gris | The Hollow Cape |
| `lantern_cliffs` | The Lantern Cliffs | Les Falaises de la Lanterne | The Throne’s Demesne |

## Regions on the chart (biome zones of the story world) (24)

| Biome | English | French | Note |
|---|---|---|---|
| temperate | The Alster Marches | Les Marches d’Alster | in geography.json |
| desert | The Waste | La Désolation | in geography.json |
| arid_coast | The Salt Coast | La Côte de Sel | in geography.json |
| temperate | The Tallow Downs | Les Landes de suif | chart only (placeholder name) |
| sea_cliffs | The Lantern Isles | Les Îles de la Lanterne | in geography.json |
| sea_cliffs | The Cove | La Crique | in geography.json |
| ashlands | The Ash Flats | Les Plaines de cendre | in geography.json |
| volcanic | The Red Hills | Les Collines rouges | in geography.json |
| frost | The Frost Reach | Les Confins du Givre | in geography.json |
| tear | The Hollow Cape | Le Cap Creux | in geography.json |
| fen | The Grey Fen | Le Marais gris | in geography.json |
| sea_cliffs | The Wrack Cliffs | Les Falaises du Varech | in geography.json |
| desert | The Pale Dunes | Les Dunes pâles | chart only (placeholder name) |
| jungle | The Tidewood | Le Bois des marées | chart only (placeholder name) |
| temperate | The Orchard Coast | La Côte des vergers | chart only (placeholder name) |
| desert | The Ember Dunes | Les Dunes de braise | chart only (placeholder name) |
| temperate | The Wick Meadows | Les Prés de la mèche | chart only (placeholder name) |
| jungle | The Green Deep | Les Profondeurs vertes | chart only (placeholder name) |
| desert | The Bone Flats | Les Plaines d’os | chart only (placeholder name) |
| temperate | The Grey Downs | Les Collines grises | chart only (placeholder name) |
| temperate | The Long Pines | Les Longs Pins | chart only (placeholder name) |
| frost | The Rime Coast | La Côte du Givre | chart only (placeholder name) |
| frost | The White Crown | La Couronne blanche | chart only (placeholder name) |
| frost | The Mute Ice | Les Glaces muettes | chart only (placeholder name) |

## Cities, towns, villages, sites and the camp (21)

| Id | English | French | In |
|---|---|---|---|
| `alster` | Alster | Alster | city · The Vale of Alster |
| `lark_wreck` | The Wreck of the Lark | L’Épave de l’Alouette | site · The Dune Sea |
| `sleepers_face` | The Sleeper’s Face | Le Visage du dormeur | site · The Dune Sea |
| `white_wells` | The White Wells | Les Puits blancs | village · The Dune Sea |
| `saltmouth` | Saltmouth | Bouche-de-Sel | city · The Saltmouth Headland |
| `cove_camp` | The Cove Camp | Le camp de la crique | camp · The Cove |
| `ashen_quarter` | The Ashen Quarter | Le Quartier des Cendres | town · The Ash Flats |
| `emberwick` | Emberwick | Braiseval | village · The Ash Flats |
| `spire_of_judgment` | The Spire of Judgment | La Flèche du Jugement | site · The Ash Flats |
| `akagiri` | Akagiri | Akagiri | village · The Red Hills |
| `wracks_end` | Wrack’s End | Bout-du-Varech | village · The Wrack Cliffs |
| `kindly_hill` | The Kindly Hill | La Colline des Bienveillants | village · The Reed-Beds |
| `drowned_cloister` | The Drowned Cloister | Le Cloître noyé | town · The Reed-Beds |
| `hollow_court` | The Hollow Court | La Cour Creuse | site · The Reed-Beds |
| `black_reliquary` | The Black Reliquary | Le Reliquaire Noir | city · The Pilgrims’ Road |
| `rimewell` | Rimewell | Puits-de-Givre | village · The Pilgrims’ Road |
| `highhearth` | Highhearth | Haut-Âtre | village · The Pilgrims’ Road |
| `white_anchorage` | The White Anchorage | Le Mouillage Blanc | town · The Grey Sands |
| `greyhithe` | Greyhithe | Grisegrève | village · The Grey Sands |
| `hollow_shore` | The Hollow Shore | La Rive Creuse | site · The Grey Sands |
| `candlehold` | Candlehold | Candlehold | city · The Lantern Cliffs |

## Districts and buildings (18)

| Id | English | French | In |
|---|---|---|---|
| `alster_lower_town` | The Lower Town | La Ville basse | Alster |
| `blind_beggar` | The Blind Beggar | Le Mendiant Aveugle | The Lower Town |
| `alster_stone_bridge` | The Stone Bridge | Le Pont de Pierre | Alster |
| `alster_black_hold` | The Black Hold | La Geôle Noire | Alster |
| `alster_undercroft` | The Undercroft | Les Souterrains | Alster |
| `alster_high_quay` | The High Quay | Le Haut Quai | Alster |
| `saltmouth_landward_gate` | The Landward Gate | La Porte de la terre | Saltmouth |
| `saltmouth_tern_row` | Tern Row | Tern Row | Saltmouth |
| `saltmouth_wharf` | Smugglers’ Wharf | Le Quai des Contrebandiers | Saltmouth |
| `saltmouth_yard` | The Ship-breaker’s Yard | Le Chantier des démolisseurs | Saltmouth |
| `saltmouth_lantern_alleys` | The Lantern Alleys | Les Ruelles aux lanternes | Saltmouth |
| `saltmouth_card_row` | Card Row | La Rangée des cartes | Saltmouth |
| `reliquary_quarter` | The Reliquary Quarter | Le Quartier des Reliquaires | The Black Reliquary |
| `dead_heart` | The Dead Heart | Le Cœur mort | The Black Reliquary |
| `hollow_shore_battlefield` | The Battlefield | Le Champ de bataille | The Hollow Shore |
| `beyond_the_tear` | Beyond the Tear | Au-delà de la déchirure | The Hollow Shore |
| `candlehold_gates` | The Gates | Les Portes | Candlehold |
| `candlehold_lantern_hall` | The Lantern Hall | La Salle de la Lanterne | Candlehold |

## Seas and oceans (9)

| Id | English | French | In |
|---|---|---|---|
| `the_seas` | The Seas | Les Mers | continent ·  |
| `narrow_sea` | The Narrow Sea | La Mer Étroite | country · The Seas |
| `open_water` | The Open Water | La Haute Mer | zone · The Narrow Sea |
| `the_crossing` | The Crossing | La Traversée | location · The Open Water |
| `white_fleet_grave` | The White Fleet’s Grave | Le Tombeau de la Flotte Blanche | location · The Grey Sands |
| chart label | the Narrow Sea | la Mer Étroite | the story world's seas |
| chart label | the Open Water | la Haute Mer | the story world's seas |
| chart label | the Grey Water | l’Eau Grise | the story world's seas |
| oceans | MISSING | MISSING | the whole sphere has no ocean named |

## Archipelagos (12)

| Id | English | French | Islands |
|---|---|---|---|
| `far_north_west` | MISSING | MISSING | 3 islands |
| `north_west` | MISSING | MISSING | 3 islands |
| `west_isles` | MISSING | MISSING | 2 islands |
| `frost_isle` | MISSING | MISSING | 1 islands |
| `ashen_east` | MISSING | MISSING | 1 islands |
| `lantern_east` | MISSING | MISSING | 3 islands |
| `mid_sea` | MISSING | MISSING | 5 islands |
| `old_north` | MISSING | MISSING | 2 islands |
| `north_east` | MISSING | MISSING | 2 islands |
| `far_east` | MISSING | MISSING | 1 islands |
| `south_mid` | MISSING | MISSING | 3 islands |
| `south_east` | MISSING | MISSING | 3 islands |

## Islands (29)

None of the archipelagos' 29 islands is named (MISSING). Each is `lands[i]` in `chart_story.dart`, listed by archipelago in `storyArchipelagoLands`; a name per island would need a field on the chart (Core adds it when Narrative has names).

