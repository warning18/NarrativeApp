# Districts for the places that have none (Narrative, proposal)

The user asked for districts in every town. This gives **2 to 4 districts to each of the 9 places that had none**, and **third and fourth districts to the Black Reliquary and Candlehold**, with the scenes (node ids) that stand in each. Text is Narrative’s; Core owns the numbers in `geography.json` and generates the town plans.

**How it is meant to land.** Core adds each district to `geography.json` (`level: district`, `parent` = the place, `name`, `name_fr`, `blurb`, `blurb_fr`, and the suggested `controller` if any). Then each scene’s `location` in the story file is retagged to its district: Narrative does that retag in the story file (its own file) once Core’s ids are on `main`. A scene keeps its place: its district’s parent is the place it has now. The mood word is a hint for the plan’s look. The same data is in `docs/proposals/town-districts.json`.

**Building names** for the new plans come after Core generates them (the names follow the building ids): send the plans and Narrative names them, as for Saltmouth.


## Rimewell (`rimewell`)

### The Bell Square / La Place de la Cloche  (`rimewell_bell_square`)

- **Blurb:** A square of frozen cobbles round a bell that rings by itself at the hour the tear opened, and the penitents who come to hear what it is counting.
- **Blurb (FR) :** Une place de pavés gelés autour d’une cloche qui sonne toute seule à l’heure où la déchirure s’est ouverte, et les pénitents qui viennent entendre ce qu’elle compte.
- **Controller:** none · **Mood:** eerie · **Scenes (6):** `6100`, `6100_bell`, `6100_bell_failed`, `6100_clan_penitents_2`, `6100_clan_penitents_2_heard`, `6100_clan_penitents_2_broken`

### The Pilgrims’ Road / La Route des Pèlerins  (`rimewell_pilgrims_road`)

- **Blurb:** The last stretch of the road into the Black Reliquary, where the frost walks beside you, and things come down that were not there last year.
- **Blurb (FR) :** Le dernier tronçon de la route vers le Reliquaire Noir, où le givre marche à vos côtés, et d’où descendent des choses qui n’y étaient pas l’an dernier.
- **Controller:** none · **Mood:** bleak · **Scenes (8):** `6100_road`, `6100_knife`, `6100_debt_rising`, `6100_bread`, `6100_charter_signing`, `6100_clan_mire_2`, `6100_clan_mire_2_found`, `6100_clan_mire_2_fourth`

### The Ridge Post / Le Poste de la Crête  (`rimewell_ridge_post`)

- **Blurb:** A stone post on the rise above the halt, where the Vigil’s lamp has not gone out in thirty-eight years, and a needle is always working somewhere in the frost.
- **Blurb (FR) :** Un poste de pierre sur la crête au-dessus de l’étape, où la lampe de la Veille n’est pas éteinte depuis trente-huit ans, et où une aiguille travaille toujours quelque part dans le givre.
- **Controller:** vigil · **Mood:** watchful · **Scenes (5):** `6100_clan_vigil_2`, `6100_clan_vigil_2_after`, `6100_stitcher_door`, `6100_keeper`, `6100_keeper_later`

### The Choir Well / Le Puits du Chœur  (`rimewell_choir_well`)

- **Blurb:** A well at the edge of the halt where the Scorched Choir sings the one name it still remembers, down the shaft, once a night.
- **Blurb (FR) :** Un puits au bord de l’étape où le Chœur Calciné chante, dans le conduit, une fois par nuit, le seul nom dont il se souvienne encore.
- **Controller:** penitents · **Mood:** mournful · **Scenes (2):** `6100_house_scorched_choir`, `6100_house_scorched_choir_failed`


## Greyhithe (`greyhithe`)

### The Shingle / La Grève  (`greyhithe_shingle`)

- **Blurb:** The grey beach where the ebb leaves things it has no business leaving: a chapel bell, a child’s shoe, a purse, and the Crows’ brigs lying off the point.
- **Blurb (FR) :** La grève grise où le reflux laisse ce qu’il n’a pas à laisser : une cloche de chapelle, un soulier d’enfant, une bourse, et les brigs des Corneilles au large de la pointe.
- **Controller:** none · **Mood:** uncanny · **Scenes (6):** `7200`, `7200_nets`, `7200_tide`, `7200_tide_failed`, `7200_relic`, `7200_ledger`

### The Moorings / Les Amarres  (`greyhithe_moorings`)

- **Blurb:** Where the Eel lies at her rope, and where boats come out to her in the small hours with sacking on the oars and a grey lantern in the bow.
- **Blurb (FR) :** Là où l’Anguille tire sur son amarre, et où des barques viennent la rejoindre à la nuit avancée, du sac sur les avirons et une lanterne grise à la proue.
- **Controller:** none · **Mood:** secretive · **Scenes (7):** `7200_thieves_aboard`, `7200_fourth_piece`, `7200_returned`, `7200_followed`, `7200_courts_children`, `7200_stitcher`, `7200_clan_mire_3`

### The Net-Lofts / Les Séchoirs  (`greyhithe_net_lofts`)

- **Blurb:** The village’s lofts and low houses, faces and all: a place the tear ate on some other coast and coughed up here, and the people who remember it.
- **Blurb (FR) :** Les séchoirs et les maisons basses du village, avec leurs visages : un lieu que la déchirure a mangé sur une autre côte et recraché ici, et les gens qui s’en souviennent.
- **Controller:** none · **Mood:** haunted · **Scenes (5):** `7200_elder`, `7200_elder_later`, `7200_reflection`, `7200_stitcher_kin`, `7200_house_spire_fallen`

### The Watch Stones / Les Pierres de Garde  (`greyhithe_watch_stones`)

- **Blurb:** A ring of standing stones above the shingle where the Vigil’s spears stand with their eyes open and the oldest oath on the coast is sworn again.
- **Blurb (FR) :** Un cercle de pierres dressées au-dessus de la grève où les lances de la Veille se tiennent les yeux ouverts, et où l’on jure de nouveau le plus vieux serment de la côte.
- **Controller:** vigil · **Mood:** solemn · **Scenes (3):** `7200_clan_vigil_3`, `7200_clan_vigil_3_changed`, `7200_clan_vigil_3_sworn`


## Wrack’s End (`wracks_end`)

### The Hull-Houses / Les Maisons-Coques  (`wracks_end_hull_houses`)

- **Blurb:** Houses built from hulls, with a fish-oil lamp over every door and, over one, a painted hand; where the Tar-Hands refit boats overnight and forget it by morning.
- **Blurb (FR) :** Des maisons bâties dans des coques, une lampe à huile de poisson au-dessus de chaque porte et, au-dessus d’une seule, une main peinte ; où les Mains-de-Goudron refont des bateaux dans la nuit et l’oublient au matin.
- **Controller:** crows · **Mood:** guarded · **Scenes (9):** `5100`, `5100_headman`, `5100_headman_later`, `5100_nets`, `5100_house_fishbasket_line`, `5100_house_fishbasket_line_drawn`, `5100_house_tar_hands`, `5100_tar_hand_book`, `5100_keyholder_cut`

### The Lamp Path / Le Sentier de la Lampe  (`wracks_end_lamp_path`)

- **Blurb:** The cliff path above the village, ending at a chapel no bigger than a boathouse with a lamp-room where the Wickwardens kept a flame, and the lamps that call the drowned.
- **Blurb (FR) :** Le sentier de la falaise au-dessus du village, qui s’achève devant une chapelle pas plus grande qu’un hangar à bateaux, avec une salle de lampe où les Garde-Mèches entretenaient une flamme, et les lampes qui appellent les noyés.
- **Controller:** dominion · **Mood:** misty · **Scenes (4):** `5100_clan_dominion_1`, `5100_clan_dominion_1_lit`, `5100_clan_dominion_1_out`, `5100_drowned`

### The Quay / Le Quai  (`wracks_end_quay`)

- **Blurb:** A short quay of black timber where crates move at night, the Anvil-Deaf vote in signs, and the Tribunal’s last clerk waits for a boat that will not come.
- **Blurb (FR) :** Un court quai de bois noir où l’on déplace des caisses la nuit, où les Sourds de l’Enclume votent par signes, et où le dernier greffier du Tribunal attend un bateau qui ne viendra pas.
- **Controller:** none · **Mood:** tense · **Scenes (7):** `5100_clan_crows_1`, `5100_clan_crows_1_seen`, `5100_clan_crows_1_lost`, `5100_vote`, `5100_anvil_deaf_vote`, `5100_salvage`, `5100_salvage_failed`


## The Cove Camp (`cove_camp`)

### The Landing / Le Débarcadère  (`cove_camp_landing`)

- **Blurb:** The shingle where the Eel comes in, and where every new chapter begins: a keel on the stones, a fire already lit.
- **Blurb (FR) :** La grève où l’Anguille accoste, et où chaque nouveau chapitre commence : une quille sur les galets, un feu déjà allumé.
- **Controller:** none · **Mood:** hopeful · **Scenes (5):** `3001`, `3001_camp`, `4999_camp`, `7001`, `7800_nkem_later`

### The Fireside / Le Coin du Feu  (`cove_camp_fireside`)

- **Blurb:** The big fire, where the factors, heralds and pilots come to say what they have been sent to say, and the Host reads the letters it was asked not to read.
- **Blurb (FR) :** Le grand feu, où les facteurs, les hérauts et les pilotes viennent dire ce qu’on les a envoyés dire, et où l’Hôte lit les lettres qu’on lui a demandé de ne pas lire.
- **Controller:** none · **Mood:** watchful · **Scenes (7):** `7400`, `7400_reed`, `7400_reed_later`, `7400_herald`, `7400_herald_later`, `7400_chain`, `7400_chain_later`

### The Palisade / La Palissade  (`cove_camp_palisade`)

- **Blurb:** The wall the camp built from salvage and nerve, with the corner nobody ever finished, and the bell hung on it for storms and for worse.
- **Blurb (FR) :** Le mur que le camp a bâti de récupération et de nerf, avec l’angle que nul n’a jamais fini, et la cloche qu’on y a pendue pour les tempêtes et pour pire.
- **Controller:** none · **Mood:** grim · **Scenes (5):** `6002_siege`, `6002_siege_2`, `6002_siege_breach`, `6002_siege_end`, `6002_camp`

### The Sail-Loft / La Voilerie  (`cove_camp_sail_loft`)

- **Blurb:** The only roof in the cove big enough to hold the Host’s council, where plans are made on sailcloth and the muster is counted twice.
- **Blurb (FR) :** Le seul toit de la crique assez grand pour abriter le conseil de l’Hôte, où l’on fait des plans sur de la toile à voile et où l’on compte deux fois les troupes.
- **Controller:** open_hand · **Mood:** resolute · **Scenes (3):** `7800`, `7800_council`, `7800_lines`


## The Kindly Hill (`kindly_hill`)

### The Fen Edge / La Lisière du Marais  (`kindly_hill_fen_edge`)

- **Blurb:** Where the grey fen comes right up to the green and stops as if at a fence: the Barkbleeders’ cut trees, the Returned in their masks, and the reeds that call you by a name you have not heard since you were small.
- **Blurb (FR) :** Là où le marais gris arrive jusqu’au vert et s’arrête comme devant une clôture : les arbres entaillés des Saigne-Écorce, les Revenus en masque, et les roseaux qui vous appellent d’un nom que vous n’avez plus entendu depuis l’enfance.
- **Controller:** mire · **Mood:** eerie · **Scenes (7):** `5200_house_barkbleeders`, `5200_house_barkbleeders_bled`, `5200_house_returned`, `5200_clan_mire_1`, `5200_clan_mire_1_edge`, `5200_clan_mire_1_answered`, `5200_barrows`

### The Hall Under the Hill / La Salle sous la Colline  (`kindly_hill_hall`)

- **Blurb:** Through the door in the hill: a hall where it is always a summer evening, a clock by the door, a riddle-game played for stakes, and a mortal girl called Nell by the hearth.
- **Blurb (FR) :** Par la porte dans la colline : une salle où c’est toujours un soir d’été, une horloge près de l’entrée, un jeu d’énigmes joué pour des enjeux, et près de l’âtre une mortelle nommée Nell.
- **Controller:** kindly · **Mood:** bright · **Scenes (6):** `5200`, `5200_riddles`, `5200_riddles_failed`, `5200_nell`, `5200_nell_later`, `5200_sleep`


## Highhearth (`highhearth`)

### The Moot-Hall / La Salle du Conseil  (`highhearth_moot_hall`)

- **Blurb:** The giants’ great hall, built for people three times your height, with the fire that has not gone out in six hundred years, and the eldest who remembers everything.
- **Blurb (FR) :** La grande salle des géants, bâtie pour des gens trois fois plus hauts que vous, avec le feu qui ne s’est pas éteint depuis six cents ans, et l’aînée qui se souvient de tout.
- **Controller:** giants · **Mood:** solemn · **Scenes (7):** `6200`, `6200_hearth`, `6200_ghrem`, `6200_eldest`, `6200_eldest_later`, `6200_clan_compact_2`, `6200_clan_compact_2_refused`

### The Frost Quarry / La Carrière de Givre  (`highhearth_quarry`)

- **Blurb:** The cut face at the back of the quarry, six centuries of tool-marks on it, where the Compact’s Quarrymen have come to cut stone again at the giants’ invitation.
- **Blurb (FR) :** La paroi taillée au fond de la carrière, six siècles de marques d’outils, où les Carriers du Pacte sont revenus tailler la pierre à l’invitation des géants.
- **Controller:** compact · **Mood:** laborious · **Scenes (3):** `6200_quarry_face`, `6200_quarry_face_fight`, `6200_house_quarrymen`

### The Long Houses / Les Longues Maisons  (`highhearth_long_houses`)

- **Blurb:** The doors like barn ends, and the gate they close at dusk against the things that come down out of the frost; and the house where a child has not been born in eleven years.
- **Blurb (FR) :** Les portes comme des pignons de grange, et la porte qu’on ferme au crépuscule contre ce qui descend du givre ; et la maison où un enfant n’est pas né depuis onze ans.
- **Controller:** giants · **Mood:** watchful · **Scenes (3):** `6200_gate`, `6200_birth`, `6200_birth_failed`


## Emberwick (`emberwick`)

### The Kilns / Les Fours  (`emberwick_kilns`)

- **Blurb:** A dozen kilns in a hollow of the slag heaps, black bread, banked fires on the new moon, and the Emberwives who turn charcoal into something a forge can trust.
- **Blurb (FR) :** Une douzaine de fours dans un creux des crassiers, du pain noir, des feux couverts à la nouvelle lune, et les Charbonnières qui font du charbon de bois quelque chose en quoi une forge peut avoir confiance.
- **Controller:** compact · **Mood:** smoky · **Scenes (6):** `3100`, `3100_kiln`, `3100_kiln_failed`, `3100_house_emberwives`, `3100_bread`, `3100_new_moon`

### Smithy Lane / La Ruelle des Forges  (`emberwick_smithy_lane`)

- **Blurb:** The lane of cold anvils, where the oldest smith has not heard a hammer in thirty years and still cannot keep away, and the widow keeps her husband’s hammer on the lintel.
- **Blurb (FR) :** La ruelle des enclumes froides, où le plus vieux forgeron n’a pas entendu un marteau depuis trente ans et ne peut pourtant s’en passer, et où la veuve garde le marteau de son mari sur le linteau.
- **Controller:** compact · **Mood:** quiet · **Scenes (4):** `3100_house_anvil_deaf`, `3100_house_anvil_deaf_failed`, `3100_widow`, `3100_widow_later`

### The Well Square / La Place du Puits  (`emberwick_well_square`)

- **Blurb:** The village well and the one open space, where the Spire sends for its tenth of the charcoal and a cantor walks down with a bell-lantern and the seven hours of the day.
- **Blurb (FR) :** Le puits du village et le seul espace dégagé, où la Flèche vient chercher sa dîme de charbon et où un chantre descend avec une lanterne-cloche et les sept heures du jour.
- **Controller:** dominion · **Mood:** tense · **Scenes (2):** `3100_tithe`, `3100_house_cantors`


## Akagiri (`akagiri`)

### The Springs / Les Sources  (`akagiri_springs`)

- **Blurb:** Pools that come out of the rock hot enough to hurt, a circle of salt across the path with a bell at each point, and the village’s dislike of exorcists, hung from every eave.
- **Blurb (FR) :** Des bassins qui jaillissent de la roche assez chauds pour faire mal, un cercle de sel en travers du sentier avec une cloche à chaque point, et l’aversion du village pour les exorcistes, pendue à chaque avant-toit.
- **Controller:** oni · **Mood:** steaming · **Scenes (4):** `3200`, `3200_springs`, `3200_circle`, `3200_house_road_exorcists`

### The Brewhouse / La Brasserie  (`akagiri_brewhouse`)

- **Blurb:** Where the oni brew their spirit from red rice and something they will not name, and serve it in cups the size of helmets.
- **Blurb (FR) :** Là où les oni brassent leur alcool de riz rouge et d’autre chose qu’ils refusent de nommer, et le servent dans des coupes de la taille de casques.
- **Controller:** oni · **Mood:** convivial · **Scenes (2):** `3200_brew`, `3200_brew_failed`

### The Forge Terrace / La Terrasse de la Forge  (`akagiri_forge_terrace`)

- **Blurb:** The top terrace, where a one-horned smith makes blades for no one in particular, and a banner is stitched in brown thread with the name of everyone the Spire hanged.
- **Blurb (FR) :** La terrasse du haut, où un forgeron à une corne fait des lames pour personne en particulier, et où l’on brode sur une bannière, en fil brun, le nom de tous ceux que la Flèche a pendus.
- **Controller:** oni · **Mood:** solemn · **Scenes (4):** `3200_smith`, `3200_smith_later`, `3200_blade`, `3200_clan_penitents_1`


## The White Wells (`white_wells`)

### The Pool / Le Bassin  (`white_wells_pool`)

- **Blurb:** A green pool among white clay huts, where the salt caravans kneel their camels, nobody asks where you came from, and a traveller can sleep beside the water.
- **Blurb (FR) :** Un bassin vert parmi des huttes d’argile blanche, où les caravanes de sel font agenouiller leurs chameaux, où personne ne demande d’où vous venez, et où l’on peut dormir au bord de l’eau.
- **Controller:** none · **Mood:** calm · **Scenes (4):** `1200`, `1000`, `1001`, `1002`

### The Caravan Ring / Le Cercle des Caravanes  (`white_wells_caravan_ring`)

- **Blurb:** The ring of kneeling camels and bedrolls round the fires, where strangers are fed and watched in equal measure.
- **Blurb (FR) :** Le cercle des chameaux agenouillés et des couchages autour des feux, où l’on nourrit les étrangers et où on les observe à parts égales.
- **Controller:** none · **Mood:** watchful · **Scenes (1):** `1210`


## The Reliquary Quarter (`reliquary_quarter`)

### The Reliquary Quarter / Le Quartier des Reliquaires  (`reliquary_quarter`)

- **Blurb:** Chapels and reliquaries given up street by street to the tear’s slow weather: frost on the cobbles in summer, and shadows that lie the wrong way.
- **Blurb (FR) :** Des chapelles et des reliquaires abandonnés rue après rue à la lente météo de la déchirure : du givre sur les pavés en plein été, et des ombres qui tombent du mauvais côté.
- **Controller:** none · **Mood:** frozen · **Scenes (9):** `6010_gate`, `6010`, `6010_house_reliquary`, `6010_house_reliquary_thieves`, `6010_house_reliquary_thieves_searched`, `6010_lysa`, `6010_lysa_later`, `6010_brannoc_later`, `6010_record`

### Last Lantern Street / La Rue de la Dernière Lanterne  (`reliquary_last_lantern`)

- **Blurb:** The one street still lit, where a Wickwarden sells lamp-oil and charms one street from the tear, and a widow lights a candle for each person it has taken.
- **Blurb (FR) :** La seule rue encore éclairée, où une Garde-Mèche vend de l’huile de lampe et des talismans à une rue de la déchirure, et où une veuve allume une chandelle pour chacun de ceux qu’elle a pris.
- **Controller:** vigil · **Mood:** warm · **Scenes (7):** `6010_lantern`, `6010_lantern_keeper`, `6010_malrik`, `6010_lantern_manifest`, `6010_wickwarden`, `6010_orsabet`, `6010_count_short`

### The Chapels of the Chair / Les Chapelles à la Chaise  (`reliquary_chapels`)

- **Blurb:** The inner chapels, their saints chipped off the walls by people who no longer wished to be watched: the chart-keeper, the Reliquary Thieves’ meeting, a confession, and the chapel with the chair.
- **Blurb (FR) :** Les chapelles intérieures, leurs saints écaillés des murs par des gens qui ne voulaient plus être regardés : la gardienne des cartes, la réunion des Voleurs de Reliquaire, une confession, et la chapelle à la chaise.
- **Controller:** dominion · **Mood:** grim · **Scenes (16):** `6010_chartkeeper`, `6010_chartkeeper_words`, `6010_chart_bought`, `6010_thread`, `6010_returned_roll`, `6010_heist_night`, `6010_clan_compact_3`, `6010_clan_compact_3_seen`, `6010_clan_compact_3_hammer`, `6010_clan_dominion_2`, `6010_lysa_dead`, `6010_masked`, `6010_masked_after`, `6010_confession`, `6010_confession_later`, `6010_penitent`

### The Frost Line / La Limite du Givre  (`reliquary_frost_line`)

- **Blurb:** Past the line where the Quarter stops being a quarter: cobbles rimed white in summer, a pattern in the frost, and what the tear sends down the streets, with the shape of dogs and the stained glass for a hide.
- **Blurb (FR) :** Au-delà de la ligne où le Quartier cesse d’être un quartier : des pavés givrés en plein été, un dessin dans le givre, et ce que la déchirure envoie dans les rues, qui a la forme de chiens et se vêt de vitraux.
- **Controller:** none · **Mood:** frozen · **Scenes (6):** `6010_frost`, `6010_frost_failed`, `6010_hounds`, `6010_spawn`, `6010_candle_walk`, `6010_candle_walk_fight`


## Candlehold (`candlehold`)

### The Gates / Les Portes  (`candlehold_gates`)

- **Blurb:** The harbour chain, the steps and the city’s gates (the Sun, the Anvil, the Reed and the Exorcists’), shut to anyone who comes without a banner; where each clan arrives in its own way.
- **Blurb (FR) :** La chaîne du port, les marches et les portes de la ville (celles du Soleil, de l’Enclume, du Roseau et des Exorcistes), fermées à qui vient sans bannière ; où chaque clan arrive à sa façon.
- **Controller:** none · **Mood:** ceremonial · **Scenes (9):** `7500`, `7510_dominion`, `7510_vigil`, `7510_compact`, `7510_mire`, `7510_crows`, `7510_penitents`, `7510_open_hand`, `7510_seen`

### The Lantern Hall / La Salle de la Lanterne  (`candlehold_lantern_hall`)

- **Blurb:** The hall at the top of the stair, under the First Lantern, where the Throne waits and whoever holds the doors must be faced.
- **Blurb (FR) :** La salle au sommet de l’escalier, sous la Première Lanterne, où le Trône attend et où il faut affronter celui qui tient les portes.
- **Controller:** dominion · **Mood:** tense · **Scenes (3):** `7520_vane`, `7520_morrow`, `7520_tallis`

### The Lantern Cliff / La Falaise de la Lanterne  (`candlehold_lantern_cliff`)

- **Blurb:** The cliff under the First Lantern, where the Houses gather to see who is crowned, and each clan crowns its own way.
- **Blurb (FR) :** La falaise sous la Première Lanterne, où les Maisons se rassemblent pour voir qui est couronné, et où chaque clan couronne à sa façon.
- **Controller:** dominion · **Mood:** ceremonial · **Scenes (7):** `7590_dominion`, `7590_vigil`, `7590_compact`, `7590_mire`, `7590_crows`, `7590_penitents`, `7590_open_hand`

