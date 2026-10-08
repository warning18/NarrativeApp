import 'dart:math' as math;
import 'dart:ui' show Color;

import '../l10n/app_locale.dart';

/// The story's world, on a chart 256 × 176 units across: the landmarks
/// every scene of the story happens at and the road between them
/// in story order. Play mode shows it from the header as a chart (see
/// map_charts.dart, which places the landmarks on each geography); a
/// landmark appears once one of its scenes has been read.

const int worldMapWidth = 256;
const int worldMapHeight = 176;

/// The story's own chapters, as its chapter headings name them.
class MapChapter {
  const MapChapter(
      this.number, this.titleEn, this.titleFr, this.dark, this.light);

  final int number;
  final String titleEn;
  final String titleFr;

  /// The chapter's colour on a dark and on a light background.
  final Color dark;
  final Color light;

  String title(AppLanguage language) =>
      language == AppLanguage.fr ? titleFr : titleEn;
}

const List<MapChapter> mapChapters = [
  MapChapter(
      1, 'Chapter 1', 'Chapitre 1', Color(0xFFE0762B), Color(0xFFB5531A)),
  MapChapter(2, 'Chapter 2: Saltmouth', 'Chapitre 2\u00a0: Bouche-de-Sel',
      Color(0xFF3F9C9C), Color(0xFF1F6F6F)),
  MapChapter(
      3,
      'Chapter 3: The Spire of Judgment',
      'Chapitre 3\u00a0: La Flèche du Jugement',
      Color(0xFF9A968C),
      Color(0xFF5F5B55)),
  MapChapter(4, 'Chapter 4: The Hollow Court',
      'Chapitre 4\u00a0: La Cour Creuse', Color(0xFFD9CFB8), Color(0xFF7A6A48)),
  MapChapter(
      5,
      'Chapter 5: The Shroud’s Truth',
      'Chapitre 5\u00a0: La Vérité du Linceul',
      Color(0xFF9B6FE0),
      Color(0xFF6D3FA0)),
  MapChapter(6, 'Chapter 6: The Hollow Shore',
      'Chapitre 6\u00a0: La Rive Creuse', Color(0xFFE9E6DF), Color(0xFF3B3743)),
  MapChapter(
      7,
      'Chapter 7: The Lantern Throne',
      'Chapitre 7\u00a0: Le Trône de la Lanterne',
      Color(0xFFF2C14E),
      Color(0xFF8F6B10)),
  MapChapter(
      8,
      'Chapter 8: Beyond the Tear',
      'Chapitre 8\u00a0: Au-delà de la déchirure',
      Color(0xFFD9544D),
      Color(0xFF8A1A1A)),
];

MapChapter mapChapter(int number) =>
    mapChapters.firstWhere((c) => c.number == number);

/// One place on the map and the scenes that happen there.
class Landmark {
  const Landmark({
    required this.id,
    required this.chapter,
    required this.nameEn,
    required this.nameFr,
    required this.blurbEn,
    required this.blurbFr,
    required this.scenes,
    this.fights = const [],
    this.atSea = false,
    this.big = false,
  });

  final String id;
  final int chapter;
  final String nameEn;
  final String nameFr;
  final String blurbEn;
  final String blurbFr;

  /// The story nodes that happen here.
  final List<String> scenes;

  /// The enemies fought here, one entry per enemy (`@first_ally` is the
  /// companion who turns on you at the end).
  final List<String> fights;

  /// Out on the water: the chart puts it at sea and draws no house for it.
  final bool atSea;

  /// Drawn at twice the size.
  final bool big;

  String name(AppLanguage language) =>
      language == AppLanguage.fr ? nameFr : nameEn;
  String blurb(AppLanguage language) =>
      language == AppLanguage.fr ? blurbFr : blurbEn;
}

/// Every landmark, in the order the story reaches them.
final List<Landmark> worldMapLandmarks = [
  const Landmark(
    id: 'beggar',
    chapter: 1,
    nameEn: 'The Blind Beggar',
    nameFr: 'Le Mendiant Aveugle',
    blurbEn:
        'Where it starts. The prologue asks who you were; then a card game in the Blind Beggar’s back room ends when the wall comes in. Take back what the tables took, dig out the people under the fallen gallery, or take your stake and run: every way out begins with a fight, and with the old bone die you carry for luck.',
    blurbFr:
        'Là où tout commence. Le prologue demande qui vous étiez\u00a0; puis une partie de cartes dans l’arrière-salle du Mendiant Aveugle s’achève quand le mur cède. Reprendre aux tables ce qu’elles ont pris, dégager les gens pris sous la galerie, ou reprendre votre mise et fuir\u00a0: chaque sortie commence par un combat, et par le vieux dé d’os que vous portez pour la chance.',
    scenes: ['0', '100', '105', '106', '110', '115', '120', '125', '250'],
    fights: [
      'den_bouncer', 'den_looter', 'sore_loser', 'street_bandit', //
      'slum_thug', 'white_soldier',
    ],
  ),
  const Landmark(
    id: 'alley',
    chapter: 1,
    nameEn: 'Weaver’s Alley',
    nameFr: 'La Ruelle du Tisserand',
    blurbEn:
        'The slow, dark road home. A starving warhound is caught in razor wire beside its murdered handler, an Inquisition dog-handler. Cut it free, strip the handler, or leave them both.',
    blurbFr:
        'La route lente et obscure vers la maison. Un chien de guerre affamé est pris dans des barbelés, à côté de son maître assassiné, un maître-chien de l’Inquisition. Le libérer, dépouiller le maître, ou les laisser tous les deux.',
    scenes: ['270'],
  ),
  const Landmark(
    id: 'bridge',
    chapter: 1,
    nameEn: 'The Stone Bridge',
    nameFr: 'Le Pont de Pierre',
    blurbEn:
        'The quick, watched road home. Slum toughs with Inquisition armbands have built a toll booth out of a market stall. Pay 30 gold or fight your way across.',
    blurbFr:
        'La route rapide et surveillée vers la maison. Des durs des bas-quartiers à brassard de l’Inquisition ont fait d’un étal de marché un poste de péage. Payer 30 pièces d’or ou passer en force.',
    scenes: ['260', '261'],
    fights: ['slum_thug'],
  ),
  const Landmark(
    id: 'hovel',
    chapter: 1,
    nameEn: 'Your family’s house',
    nameFr: 'La maison de famille',
    blurbEn:
        'Inquisitors are tearing the house apart, looking for something. A ball from the white ships folds the wall, and the Inquisitor-General Aurel Vane walks out of the dust holding Lysa by one wrist: charge him, run, or kneel. When the searchers have gone, the ball has found what they could not: a trapdoor, and a cloth as big as a cape.',
    blurbFr:
        'Des inquisiteurs mettent la maison sens dessus dessous\u00a0: ils cherchent quelque chose. Un boulet des navires blancs plie le mur, et l’Inquisiteur général Aurel Vane sort de la poussière en tenant Lysa par un poignet\u00a0: le charger, fuir, ou s’agenouiller. Quand les fouilleurs sont partis, le boulet a trouvé ce qu’ils cherchaient en vain\u00a0: une trappe, et une étoffe grande comme une cape.',
    scenes: ['300', '400', '400_lost', '450', '470'],
    fights: ['aurel_vane'],
  ),
  const Landmark(
    id: 'hold',
    chapter: 1,
    nameEn: 'The Black Hold',
    nameFr: 'La Geôle Noire',
    blurbEn:
        'Three days of Brother Clement’s questions about a cloth you have never seen, then the resistance blows the wall in. On his table, a drawing of the cloth and your family’s name. Get past the Wardens, and choose the battlements or the Corpse Chute.',
    blurbFr:
        'Trois jours de questions de frère Clément sur une étoffe que vous n’avez jamais vue, puis la résistance fait sauter le mur. Sur sa table, un dessin de l’étoffe et le nom de votre famille. Passez les Gardiens, et choisissez les remparts ou la Goulotte aux Cadavres.',
    scenes: ['800', '816', '820', '822', '822_lie_failed', '823'],
    fights: ['inquisition_warden'],
  ),
  const Landmark(
    id: 'sewers',
    chapter: 1,
    nameEn: 'The sewers',
    nameFr: 'Les égouts',
    blurbEn:
        'Waist-deep rot below the Corpse Chute, and a Rat Matriarch squatting in the main drainage pipe.',
    blurbFr:
        'De la pourriture jusqu’à la taille sous la Goulotte aux Cadavres, et une Matriarche des Rats tapie dans le collecteur principal.',
    scenes: ['840', '850', '850_fed_failed', '855'],
    fights: ['rat_matriarch'],
  ),
  const Landmark(
    id: 'docks',
    chapter: 1,
    nameEn: 'Alster’s high quay',
    nameFr: 'Le haut quai d’Alster',
    blurbEn:
        'Vessels that should not float, their painted sails shining as the crews wet them. Talk your way aboard the Lark, pass as crew, or climb her line as she lifts; then the sign on her sail carries you up through the guns.',
    blurbFr:
        'Des vaisseaux qui ne devraient pas flotter, leurs voiles peintes brillant à mesure que les équipages les mouillent. Négociez votre place à bord de l’Alouette, faites-vous passer pour un membre d’équipage, ou grimpez à son amarre au décollage\u00a0; puis le signe de sa voile vous emporte à travers les canons.',
    scenes: [
      '891', '895', '896_failed', '897_failed', '898_failed', '960', //
    ],
  ),
  const Landmark(
    id: 'crash',
    chapter: 1,
    nameEn: 'The wreck of the Lark',
    nameFr: 'L’épave de l’Alouette',
    blurbEn:
        'The first storm snuffed the sign on the sail, and the Lark fell into the Waste. Her crew are dead, her cargo looted, and a tear in the world hangs over the sand.',
    blurbFr:
        'La première tempête a éteint le signe de la voile, et l’Alouette est tombée dans la Désolation. Son équipage est mort, sa cargaison pillée, et une déchirure du monde pend au-dessus du sable.',
    scenes: ['965', '1100', '1101', '1101_scarred'],
  ),
  const Landmark(
    id: 'sleeper',
    chapter: 1,
    nameEn: 'The sleeper’s face',
    nameFr: 'Le visage du dormeur',
    blurbEn:
        'A stone face as big as a house, half buried in the dunes, with a sign on its brow like the one on your die. Water seeps from under its jaw, and the wreck’s looters camp in its shadow.',
    blurbFr:
        'Un visage de pierre grand comme une maison, à demi enfoui dans les dunes, un signe au front pareil à celui de votre dé. De l’eau suinte sous sa mâchoire, et les pilleurs de l’épave campent dans son ombre.',
    scenes: ['1120', '1125', '1130', '1140', '1140_spotted'],
    fights: ['wreck_scavenger', 'wreck_scavenger'],
  ),
  const Landmark(
    id: 'wells',
    chapter: 1,
    nameEn: 'The White Wells',
    nameFr: 'Les Puits blancs',
    blurbEn:
        'An oasis of white clay huts round a green pool, a salt caravan and a few merchants. Rest, and hear of a city to the south where the Waste meets the sea. Who walks south with you sets your origin: Guardian, Rat or Broken.',
    blurbFr:
        'Une oasis de cases d’argile blanche autour d’une mare verte, une caravane de sel et quelques marchands. Reposez-vous, et entendez parler d’une ville au sud, là où la Désolation rejoint la mer. Qui marche vers le sud avec vous fixe votre origine\u00a0: Gardien, Rat ou Brisé.',
    scenes: ['1200', '1210', '1000', '1001', '1002'],
  ),
  const Landmark(
    id: 'upper',
    chapter: 2,
    nameEn: 'Saltmouth’s landward gate',
    nameFr: 'La porte de la terre de Bouche-de-Sel',
    blurbEn:
        'Where the Waste comes down to the sea: white walls on a headland, a stone giant to its knees in the harbor mouth, and the Inquisition searching every caravan at the gate. Go in with the caravan, or hidden in a salt wagon.',
    blurbFr:
        'Là où la Désolation descend jusqu’à la mer\u00a0: des murs blancs sur un promontoire, un géant de pierre dans l’eau jusqu’aux genoux à l’entrée du port, et l’Inquisition qui fouille chaque caravane à la porte. Entrer avec la caravane, ou sous les sacs d’un chariot de sel.',
    scenes: ['2001', '2000', '2005', '2020', '2021'],
    fights: ['harbor_rat', 'inquisition_soldier'],
  ),
  const Landmark(
    id: 'tern',
    chapter: 2,
    nameEn: 'Tern Row',
    nameFr: 'Tern Row',
    blurbEn:
        'The Tide-Kin quarter of paper boats. Nadira asks for help against Renn, a customs officer charging a toll that exists in no ledger. Talk him down or fight.',
    blurbFr:
        'Le quartier des Gens de la Marée et de leurs bateaux de papier. Nadira demande de l’aide contre Renn, un douanier qui perçoit un péage qui ne figure dans aucun registre. Le raisonner ou se battre.',
    scenes: ['2015_ternrow', '2015_ternrow_talked', '2015_ternrow_fight'],
    fights: ['dock_overseer'],
  ),
  const Landmark(
    id: 'wharf',
    chapter: 2,
    nameEn: 'Smugglers’ Wharf',
    nameFr: 'Le Quai des Contrebandiers',
    blurbEn:
        'Chapter 2’s hub, Saltmouth’s harbor quarter. A quartermaster called Vane, no kin to the Inquisitor-General, holds the gate to the shipyards; the market around him is full of work: the Bazaar, Apothecary Row, bounties, card games, a false informant, Kelda at the gate, Sable’s marker, Liora on the rooftop, and Vess, who follows the Bundle.',
    blurbFr:
        'Le carrefour du chapitre 2, le quartier du port de Bouche-de-Sel. Un intendant nommé Vane, sans lien avec l’Inquisiteur général, garde la porte des chantiers navals\u00a0; autour de lui, le marché regorge de travail\u00a0: le Bazar, la rue des Apothicaires, des primes, des parties de cartes, un faux informateur, Kelda à la porte, la reconnaissance de dette de Sable, Liora sur le toit, et Vess, qui suit le Balluchon.',
    scenes: [
      '2010', '2010_crane', '2010_liora', '2011', //
      '2015', '2015_apothecary', '2015_bandits', '2015_bazaar', '2015_cards',
      '2015_cards_won', '2015_cards_lost', '2015_dockside', '2015_hound',
      '2015_informant', '2015_informant_trap', '2015_informant_exposed',
      '2015_informant_caught', '2015_kelda', '2015_rats', '2015_sable',
      '2015_sable_lifted', '2015_sable_caught', '2015_sable_bought',
      '2015_sable_talk_failed', '2015_liora', '2015_liora_won',
      '2015_liora_refused', '2015_vess', '2015_drawer', '2015_smuggler',
      '2011_roof_fall', '2030', '2040', '2040_paid', '2050', '2070',
      '2070_cut_failed',
      '2015_house_drowned_debt', '2015_house_keyholders',
      '2015_house_keyholders_turned', '2015_house_salt_ledger',
    ],
    fights: [
      'harbor_rat', 'smuggler_captain', 'plague_hound', 'street_bandit', //
      'inquisition_soldier',
    ],
  ),
  const Landmark(
    id: 'berths',
    chapter: 2,
    nameEn: 'The ship-breaker’s yard',
    nameFr: 'Le chantier des démolisseurs',
    blurbEn:
        'The one hull the yard will sell a stranger: the Rusty Eel, holed and torn. Buy her or work off her price, patch the hull and mend the sail, then decide who sails: everyone, the twenty who can fight, or no one.',
    blurbFr:
        'La seule coque que le chantier accepte de vendre à un inconnu\u00a0: le Rusty Eel, troué et déchiré. Achetez-le ou payez-le de votre travail, colmatez la coque et réparez la voile, puis décidez qui embarque\u00a0: tout le monde, les vingt qui savent se battre, ou personne.',
    scenes: [
      '2900',
      '2900_boat_fixed',
      '2015_dorran',
      '2015_scaffold_clerk',
      '2015_scaffold_clerk_fight',
    ],
  ),
  const Landmark(
    id: 'storm',
    chapter: 2,
    atSea: true,
    nameEn: 'The crossing',
    nameFr: 'La traversée',
    blurbEn:
        'Three weeks of open sea toward the Ashen Coast. On the twelfth night the storm hits: cut the stores, cut the refugees’ tow-line, or lash yourself to the tiller.',
    blurbFr:
        'Trois semaines de haute mer vers la Côte de Cendre. La douzième nuit, la tempête frappe\u00a0: sacrifier les vivres, couper l’amarre des réfugiés, ou vous attacher à la barre.',
    scenes: ['2999'],
  ),
  const Landmark(
    id: 'camp',
    chapter: 3,
    nameEn: 'The Cove Camp',
    nameFr: 'Le camp de la crique',
    blurbEn:
        'Landfall after twenty days. In a cove hidden from the Spire the survivors start building without anyone deciding to: your base, where every chapter opens, between every trip, until the night the Host of the Lantern Throne musters on its shingle for the tear.',
    blurbFr:
        'La terre, après vingt jours. Dans une crique cachée de la Flèche, les survivants se mettent à bâtir sans que personne l’ait décidé\u00a0: votre base, où chaque chapitre commence, entre chaque voyage, jusqu’à la nuit où l’Ost du Trône de la Lanterne se rassemble sur ses galets avant la déchirure.',
    scenes: [
      '3001', '3001_camp', '4999_camp', '6002_siege', '6002_siege_2', //
      '6002_siege_breach', '6002_siege_end', '6002_camp', '7001', '7400',
      '7800', '7800_council', '7800_lines',
    ],
  ),
  const Landmark(
    id: 'quarter',
    chapter: 3,
    nameEn: 'The Ashen Quarter',
    nameFr: 'Le Quartier des Cendres',
    blurbEn:
        'Chapter 3’s hub, a day’s walk from the camp: a town the Inquisition burned itself. The Ashen Oath, the Void Relic contract, Maren’s confession, Grosh the mercenary, Reya’s wall of names, and a message to Lysa.',
    blurbFr:
        'Le carrefour du chapitre 3, à une journée de marche du camp\u00a0: une ville que l’Inquisition a brûlée elle-même. Le Serment de Cendres, le contrat de la Relique du Néant, la confession de Maren, Grosh le mercenaire, le mur des noms de Reya, et un message pour Lysa.',
    scenes: [
      '3005', '3005_oath', '3005_acolyte', '3005_relic', //
      '3005_wisp', '3005_stalker', '3005_golem', '3005_auxiliaries',
      '3005_maren', '3005_archive', '3005_archive_failed', '3005_ledger',
      '3005_ledger_failed', '3005_grosh', '3005_wall', '3005_wall_argued',
      '3005_wall_fight', '3005_lysa', '3005_envoys',
      '3005_house_tribunal',
      '3005_clan_vigil_1',
      '3005_clan_vigil_1_breach',
      '3005_clan_vigil_1_dawn',
      '3005_clan_compact_1',
      '3005_clan_compact_1_lit', '3005_imeh', '3005_glass_fire',
      '3005_glass_fire_fight',
    ],
    fights: [
      'cultist_acolyte', 'void_wisp', 'void_stalker', 'iron_golem', //
      'inquisition_auxiliary',
      'inquisition_soldier',
    ],
  ),
  const Landmark(
    id: 'emberwick',
    chapter: 3,
    nameEn: 'Emberwick',
    nameFr: 'Braiseval',
    blurbEn:
        'A hollow of the old slag heaps where the ironworkers’ families went when the golems outlasted their masters: kilns, a well, tithe-takers from the Spire, and a smith’s widow who still hears his hymn.',
    blurbFr:
        'Un creux des vieux terrils où les familles des forgerons se sont repliées quand les golems ont survécu à leurs maîtres\u00a0: des fours, un puits, des collecteurs de dîme de la Flèche, et une veuve de forgeron qui entend encore son cantique.',
    scenes: [
      '3100', '3100_tithe', '3100_kiln', '3100_kiln_failed', //
      '3100_widow', '3100_widow_later', '3100_bread',
      '3100_house_cantors', '3100_house_emberwives', '3100_house_anvil_deaf',
      '3100_house_anvil_deaf_failed',
    ],
    fights: [
      'inquisition_auxiliary',
      'void_wisp',
      'street_bandit',
    ],
  ),
  const Landmark(
    id: 'akagiri',
    chapter: 3,
    nameEn: 'Akagiri',
    nameFr: 'Akagiri',
    blurbEn:
        'The oni village on the terraces above the hot springs, at the top of the Exorcists’ Road: bells on every eave, a smith with a sawn-off horn, brewers who bet on their guests, and the Horn-Taker’s chest of proofs.',
    blurbFr:
        'Le village des oni sur les terrasses au-dessus des sources chaudes, en haut de la Route des Exorcistes\u00a0: des cloches à chaque avant-toit, un forgeron à la corne sciée, des brasseurs qui parient sur leurs invités, et le coffre de preuves du Preneur de Cornes.',
    scenes: [
      '3200', '3200_circle', '3200_brew', '3200_brew_failed', //
      '3200_smith', '3200_smith_later', '3200_blade', '3200_springs',
      '3200_house_road_exorcists', '3200_clan_penitents_1',
    ],
    fights: [
      'inquisition_soldier',
      'inquisition_auxiliary',
      'void_wisp',
    ],
  ),
  const Landmark(
    id: 'spire',
    chapter: 3,
    nameEn: 'The Spire of Judgment',
    nameFr: 'La Flèche du Jugement',
    blurbEn:
        'The Inquisition’s mother-house. Go over the cloister roofs and through the stained glass, or through the Hall of Records by bribe or violence. The High Warden’s white standard is grey underneath: a piece of the Shroud.',
    blurbFr:
        'La maison mère de l’Inquisition. Passez par les toits du cloître et à travers les vitraux, ou par la Salle des Archives, en soudoyant ou par la force. L’étendard blanc du Haut Gardien est gris en dessous\u00a0: un morceau du Linceul.',
    scenes: [
      '3002', '3010', '3010_rope_fail', '3020', '3030', '3040', '3050',
      '4999_drawn', '4999', //
      '4999_standard',
    ],
    fights: ['inquisition_high_warden'],
  ),
  const Landmark(
    id: 'wrack',
    chapter: 4,
    nameEn: 'Wrack’s End',
    nameFr: 'Bout-du-Varech',
    blurbEn:
        'Wreckers and weed-cutters on the cliff above the Drowned Stair, in houses built from hulls, with false lamps on the point and the drowned climbing toward them.',
    blurbFr:
        'Des pilleurs d’épaves et des coupeurs de varech sur la falaise au-dessus de l’Escalier Noyé, dans des maisons bâties avec des coques, de fausses lampes sur la pointe et les noyés qui grimpent vers elles.',
    scenes: [
      '5100', '5100_drowned', '5100_salvage', '5100_salvage_failed', //
      '5100_headman', '5100_headman_later', '5100_nets', '5100_vote',
      '5100_house_tar_hands',
      '5100_house_fishbasket_line',
      '5100_house_fishbasket_line_drawn',
      '5100_clan_dominion_1',
      '5100_clan_dominion_1_lit',
      '5100_clan_dominion_1_out',
      '5100_clan_crows_1',
      '5100_clan_crows_1_seen',
      '5100_clan_crows_1_lost',
    ],
    fights: ['drowned_pilgrim'],
  ),
  const Landmark(
    id: 'kindly',
    chapter: 4,
    nameEn: 'The Kindly Hill',
    nameFr: 'La Colline des Bienveillants',
    blurbEn:
        'A green hill in the grey fen where it is always a summer evening: the Good Folk’s riddle-table, a clock that shows what a visit costs, and Nell, this year’s teind to the Hollow Court, knitting a grey shawl.',
    blurbFr:
        'Une colline verte dans le marais gris, où c’est toujours un soir d’été\u00a0: la table aux énigmes des Bienveillants, une horloge qui montre ce que coûte une visite, et Nell, la dîme de cette année pour la Cour Creuse, qui tricote un châle gris.',
    scenes: [
      '5200', '5200_barrows', '5200_riddles', '5200_riddles_failed', //
      '5200_nell', '5200_nell_later', '5200_sleep',
      '5200_house_barkbleeders',
      '5200_house_barkbleeders_bled',
      '5200_house_returned',
      '5200_clan_mire_1',
      '5200_clan_mire_1_edge',
      '5200_clan_mire_1_answered',
    ],
    fights: ['bone_sexton', 'catacomb_ghoul'],
  ),
  const Landmark(
    id: 'cloister',
    chapter: 4,
    nameEn: 'The Drowned Cloister',
    nameFr: 'Le Cloître noyé',
    blurbEn:
        'Chapter 4’s hub, knee-deep in black water. The Court’s former archivist, a deserter, a ghoul-bitten sapper and Tobin the choir dwarf, before the Drowned Stair.',
    blurbFr:
        'Le carrefour du chapitre 4, dans une eau noire jusqu’aux genoux. L’ancienne archiviste de la Cour, un déserteur, un sapeur mordu par une goule et Tobin, le nain du chœur, avant l’Escalier Noyé.',
    scenes: [
      '5010', '5010_archivist', '5010_archivist_words', '5010_ghouls', //
      '5010_deserter_dive_fail',
      '5010_sapper_thanks', '5010_warden', '5010_trade', '5010_span',
      '5010_span_failed', '5010_wisps', '5010_deserter',
      '5010_deserter_later', '5010_deserter_failed', '5010_tobin',
      '5010_tobin_hymn', '5010_letter',
      '5010_house_candlebearers',
      '5010_house_herons_wake',
      '5010_house_herons_wake_broken',
      '5010_clan_crows_2',
      '5010_clan_crows_2_found',
      '5010_clan_crows_2_failed', '5010_brannoc', '5010_bark_cache',
      '5010_bark_cache_fight',
    ],
    fights: ['catacomb_ghoul', 'bone_warden', 'void_wisp'],
  ),
  const Landmark(
    id: 'court',
    chapter: 4,
    nameEn: 'The Hollow Court',
    nameFr: 'La Cour Creuse',
    blurbEn:
        'Inked inquisitors around a black altar and the Shroud’s twin. Their ledger of the taken has your parents on page two, and a dozen sleepers lie wrapped in the grey you need. Its truth is read on the steps outside, in daylight.',
    blurbFr:
        'Des inquisiteurs tatoués autour d’un autel noir et du jumeau du Linceul. Leur registre des disparus porte vos parents en page deux, et une douzaine de dormeurs gisent enveloppés du gris qu’il vous faut. Sa vérité se lit sur les marches, dehors, au grand jour.',
    scenes: [
      '5003', '5004', '5004b', '5004_altar', '5005', '5006_chase', //
      '5006_cornered', '6001', '6002',
    ],
    fights: ['hollow_court_zealot'],
  ),
  const Landmark(
    id: 'reliquary',
    chapter: 5,
    nameEn: 'The Reliquary Quarter',
    nameFr: 'Le Quartier des Reliquaires',
    blurbEn:
        'Frost in summer and penitents at the gate. The chart-keeper, the Last Lantern, Malrik’s stall, a confession to answer, Lysa’s fate, and the fourth piece of the Shroud in a girl’s reliquary.',
    blurbFr:
        'Du givre en plein été et des pénitents à la porte. La gardienne des cartes, la Dernière Lanterne, l’étal de Malrik, une confession à laquelle répondre, le sort de Lysa, et le quatrième morceau du Linceul dans le reliquaire d’une fillette.',
    scenes: [
      '6010_gate', '6010', '6010_chartkeeper', '6010_chart_bought', //
      '6010_chartkeeper_words', '6010_lysa', '6010_lysa_later',
      '6010_lysa_dead', '6010_masked', '6010_masked_after', '6010_hounds',
      '6010_confession', '6010_confession_later', '6010_penitent',
      '6010_lantern', '6010_lantern_keeper', '6010_spawn', '6010_frost',
      '6010_frost_failed', '6010_malrik', '6010_thread', '6010_record',
      '6010_wickwarden',
      '6010_house_reliquary',
      '6010_house_reliquary_thieves',
      '6010_house_reliquary_thieves_searched',
      '6010_clan_dominion_2',
      '6010_clan_compact_3',
      '6010_clan_compact_3_seen',
      '6010_clan_compact_3_hammer', '6010_orsabet', '6010_candle_walk',
      '6010_candle_walk_fight',
    ],
    fights: [
      'void_hound', 'inquisition_penitent', 'tear_spawn', 'masked_penitent', //
      'inquisition_soldier',
    ],
  ),
  const Landmark(
    id: 'rimewell',
    chapter: 5,
    nameEn: 'Rimewell',
    nameFr: 'Puits-de-Givre',
    blurbEn:
        'A pilgrims’ halt on the road into the Black Reliquary, where the tear’s frost came first: a bell that counts the taken, a road-keeper’s lantern, and stale bread shared with whoever is still walking.',
    blurbFr:
        'Une halte de pèlerins sur la route du Reliquaire Noir, où le givre de la déchirure est arrivé en premier\u00a0: une cloche qui compte les disparus, la lanterne d’une gardienne de la route, et un pain rassis partagé avec ceux qui marchent encore.',
    scenes: [
      '6100', '6100_bell', '6100_bell_failed', '6100_road', //
      '6100_keeper', '6100_keeper_later', '6100_bread', '6100_knife',
      '6100_house_scorched_choir',
      '6100_house_scorched_choir_failed',
      '6100_clan_vigil_2',
      '6100_clan_vigil_2_after',
      '6100_clan_mire_2',
      '6100_clan_mire_2_found',
      '6100_clan_mire_2_fourth',
      '6100_clan_penitents_2',
      '6100_clan_penitents_2_heard',
      '6100_clan_penitents_2_broken',
    ],
    fights: [
      'void_hound',
      'drowned_pilgrim',
      'void_stalker',
      'inquisition_penitent',
      'inquisition_soldier',
    ],
  ),
  const Landmark(
    id: 'highhearth',
    chapter: 5,
    nameEn: 'Highhearth',
    nameFr: 'Haut-Âtre',
    blurbEn:
        'The last forty giants, below the Frost Quarry: they cut the stone for the Reliquary and were paid by being written out of scripture. A fire six hundred years old, a first child in eleven years, and a tally-stone of names.',
    blurbFr:
        'Les quarante derniers géants, sous la Carrière de Givre\u00a0: ils ont taillé la pierre du Reliquaire et ont été payés en étant rayés des Écritures. Un feu vieux de six cents ans, un premier enfant en onze ans, et une pierre de compte couverte de noms.',
    scenes: [
      '6200', '6200_gate', '6200_birth', '6200_birth_failed', //
      '6200_eldest', '6200_eldest_later', '6200_hearth',
      '6200_house_quarrymen', '6200_clan_compact_2',
      '6200_clan_compact_2_refused', '6200_ghrem', '6200_quarry_face',
      '6200_quarry_face_fight',
    ],
    fights: ['void_hound', 'void_hound'],
  ),
  const Landmark(
    id: 'heart',
    chapter: 5,
    big: true,
    nameEn: 'The dead heart',
    nameFr: 'Le cœur mort',
    blurbEn:
        'The tear the ledger names. Something wearing the faces of everyone you killed stands in front of it. Beyond, the Void thanks you for bringing the Shroud whole.',
    blurbFr:
        'La déchirure que nomme le registre. Devant elle se dresse une chose qui porte les visages de tous ceux que vous avez tués. Au-delà, le Néant vous remercie d’avoir apporté le Linceul entier.',
    scenes: ['6003', '6003b', '6004'],
    fights: ['void_manifestation'],
  ),
  const Landmark(
    id: 'anchorage',
    chapter: 6,
    nameEn: 'The White Anchorage',
    nameFr: 'Le Mouillage Blanc',
    blurbEn:
        'A town built from the White Fleet’s wrecks by the crusaders who washed up in them: a chaplain who knows where the flagship lies, a chandlery, the grey sickness, and a last company still at war.',
    blurbFr:
        'Une ville bâtie avec les épaves de la Flotte Blanche par les croisés qui s’y sont échoués\u00a0: un aumônier qui sait où gît le vaisseau amiral, une chandlerie, le mal gris, et une dernière compagnie encore en guerre.',
    scenes: [
      '7100', '7100_chaplain', '7100_chandlery', '7100_company', //
      '7100_sick', '7100_sick_failed', '7100_helmsman', '7100_helmsman_refused',
      '7100_helmsman_later', '7100_cutter', '7100_cutter_lost', '7100_log',
      '7100_house_order',
      '7100_clan_dominion_3',
      '7100_clan_crows_3',
      '7100_clan_penitents_3',
      '7100_clan_penitents_3_bolt',
      '7100_clan_penitents_3_through', '7100_nkem', '7100_impound',
      '7100_impound_fight',
    ],
    fights: [
      'inquisition_soldier',
      'white_soldier',
      'unmade_knight',
    ],
  ),
  const Landmark(
    id: 'greyhithe',
    chapter: 6,
    nameEn: 'Greyhithe',
    nameFr: 'Grisegrève',
    blurbEn:
        'A fishing village the tear ate somewhere else and coughed up on the Hollow Shore, grey faces and all, where the eldest cannot remember her daughter’s name.',
    blurbFr:
        'Un village de pêcheurs que la déchirure a dévoré ailleurs et recraché sur la Rive Creuse, visages gris compris, où l’aînée ne se rappelle pas le nom de sa fille.',
    scenes: [
      '7200', '7200_nets', '7200_reflection', '7200_elder', //
      '7200_elder_later', '7200_tide', '7200_tide_failed',
      '7200_house_spire_fallen',
      '7200_clan_vigil_3',
      '7200_clan_vigil_3_changed',
      '7200_clan_vigil_3_sworn',
      '7200_clan_mire_3',
    ],
    fights: ['hollow_reflection'],
  ),
  const Landmark(
    id: 'wreck',
    chapter: 6,
    atSea: true,
    nameEn: 'The White Fleet’s grave',
    nameFr: 'Le tombeau de la Flotte Blanche',
    blurbEn:
        'Forty hulls on a floor of glass off the point, and the flagship among them, its Admiral on the quarterdeck and the fifth piece of the Shroud as its mainsail.',
    blurbFr:
        'Quarante coques sur un fond de verre au large de la pointe, et le vaisseau amiral parmi elles, son Amiral sur la dunette et la cinquième pièce du Linceul en guise de grand-voile.',
    scenes: ['7300'],
    fights: ['white_admiral'],
  ),
  const Landmark(
    id: 'shore',
    chapter: 6,
    nameEn: 'The Hollow Shore',
    nameFr: 'La Rive Creuse',
    blurbEn:
        'Grey sand drawn out of the dead heart, and the tear now a door. Reflections on the sand, the legate’s pact, the Admiralty’s vote and the grey hand; then, past the Host’s battle, the Sovereign’s price and its sixth piece, four endings (the city, the seeker, the dawn, or the crown), and the night the whole Banner turns back.',
    blurbFr:
        'Un sable gris tiré du cœur mort, et la déchirure devenue porte. Des reflets sur le sable, le pacte du légat, la voix de l’Amirauté et la main grise\u00a0; puis, après la bataille de l’Ost, le prix du Souverain et sa sixième pièce, quatre fins (la ville, le chercheur, l’aube ou la couronne), et la nuit où la Bannière entière revient en arrière.',
    scenes: [
      '7002', '7002_reflections', '7002_rest', '7002_pact', //
      '7002_betrayal', '7002_crew', //
      '7002_orders', '7002_throne', '7002_banner', //
      '7002_confront', '7002_price', '7003',
      '7004', '7005', '7005_seeker', '7005_dawn', '7005_crown',
    ],
    fights: ['hollow_reflection', '@first_ally'],
  ),
  const Landmark(
    id: 'candlehold',
    chapter: 7,
    big: true,
    nameEn: 'Candlehold',
    nameFr: 'Candlehold',
    blurbEn:
        'The Dominion’s capital across the sea, a city grown around one lamp on the First Lantern’s cliff. Raise a banner at its gate, find a way in under it, face whoever holds the Lantern Hall, and be crowned on the Lantern Throne.',
    blurbFr:
        'La capitale du Dominion de l’autre côté de la mer, une ville poussée autour d’une seule lampe sur la falaise de la Première Lanterne. Levez une bannière à sa porte, trouvez un chemin sous elle, affrontez qui tient la Salle de la Lanterne, et recevez la couronne sur le Trône de la Lanterne.',
    scenes: [
      '7500', '7510_dominion', '7510_vigil', '7510_compact', '7510_mire', //
      '7510_crows', '7510_penitents', '7510_open_hand', '7510_seen',
      '7520_vane', '7520_morrow', '7520_tallis', '7590_dominion', //
      '7590_vigil', '7590_compact', '7590_mire', '7590_crows',
      '7590_penitents', '7590_open_hand',
    ],
    fights: [
      'inquisition_soldier', 'inquisition_auxiliary', 'white_soldier', //
      'claimant_vane', 'claimant_morrow', 'claimant_tallis',
    ],
  ),
  const Landmark(
    id: 'battle',
    chapter: 8,
    nameEn: 'The Battle of the Hollow Shore',
    nameFr: 'La bataille de la Rive Creuse',
    blurbEn:
        'Where the Host of the Lantern Throne came ashore to meet the tear’s answer to the crowning: the Tear-Herald, wearing every face the tear has taken, and a mile of reflections drawn up behind it, with only the last mile left to cross alone.',
    blurbFr:
        'Là où l’Ost du Trône de la Lanterne débarqua pour affronter la réponse de la déchirure au couronnement\u00a0: le Héraut de la Déchirure, qui porte tous les visages qu’elle a pris, et une lieue de reflets rangés derrière lui, avec la dernière lieue à traverser sans personne.',
    scenes: ['7810', '7002_approach', '7002_alarm'],
    fights: ['tear_herald', 'hollow_reflection', 'unmade_knight'],
  ),
];

Landmark? landmarkById(String id) {
  for (final landmark in worldMapLandmarks) {
    if (landmark.id == id) return landmark;
  }
  return null;
}

/// The landmarks reached so far: every one with a scene in [visited].
Set<String> discoveredLandmarkIds(Iterable<String> visited) {
  final seen = visited.toSet();
  return {
    for (final landmark in worldMapLandmarks)
      if (landmark.scenes.any(seen.contains)) landmark.id,
  };
}

/// The landmark a scene happens at. A scene shared by two places belongs
/// to the later one on the road.
Landmark? landmarkOfScene(String nodeId) {
  Landmark? found;
  for (final landmark in worldMapLandmarks) {
    if (landmark.scenes.contains(nodeId)) found = landmark;
  }
  return found;
}

/// Where the story stands: the landmark of [currentNodeId], or, for a
/// scene that is on no landmark (an excursion's generated steps), of the
/// latest scene in [history] that is.
Landmark? currentLandmark(String currentNodeId, List<String> history) {
  final here = landmarkOfScene(currentNodeId);
  if (here != null) return here;
  for (final nodeId in history.reversed) {
    final there = landmarkOfScene(nodeId);
    if (there != null) return there;
  }
  return null;
}

// ---- The player's journey --------------------------------------------------

/// The places the story has passed through, in order: the landmark of
/// each scene in [history], then of [currentNodeId]; a place is counted
/// once for as long as the story stays there. Scenes on no landmark (an
/// excursion's generated steps) are skipped.
List<Landmark> journeyOf(List<String> history, String currentNodeId) {
  final journey = <Landmark>[];
  for (final nodeId in [...history, currentNodeId]) {
    final landmark = landmarkOfScene(nodeId);
    if (landmark == null) continue;
    if (journey.isEmpty || journey.last.id != landmark.id) {
      journey.add(landmark);
    }
  }
  return journey;
}

/// The stretches of road to draw: each leg of the [journey] once, or,
/// with no journey to go by (a story moved by jumps), the road through
/// the [discovered] places in story order.
List<(Landmark, Landmark)> roadLegs(
    List<Landmark> journey, Set<String> discovered) {
  final legs = <(Landmark, Landmark)>[];
  final seen = <String>{};
  void add(Landmark a, Landmark b) {
    final key =
        a.id.compareTo(b.id) < 0 ? '${a.id}|${b.id}' : '${b.id}|${a.id}';
    if (seen.add(key)) legs.add((a, b));
  }

  if (journey.length >= 2) {
    for (var i = 0; i < journey.length - 1; i++) {
      add(journey[i], journey[i + 1]);
    }
    return legs;
  }
  Landmark? previous;
  for (final landmark in worldMapLandmarks) {
    if (!discovered.contains(landmark.id)) continue;
    if (previous != null) add(previous, landmark);
    previous = landmark;
  }
  return legs;
}

/// The most legs the traveller walks when the map opens.
const int maxWalkLegs = 8;

/// Where the traveller starts walking when the map opens: the place the
/// map last showed ([seenSteps] places into the journey, the last being
/// [seenLast]), so the walk covers what the story has done since. A first
/// look, or a journey the record doesn't match (another game), walks the
/// last leg. Returns the journey index to start from; the last index
/// means there is nothing to walk.
int journeyWalkStart(List<Landmark> journey,
    {int? seenSteps, String? seenLast}) {
  if (journey.length < 2) return journey.length - 1;
  var start = journey.length - 2;
  if (seenSteps != null &&
      seenLast != null &&
      seenSteps >= 1 &&
      seenSteps <= journey.length &&
      journey[seenSteps - 1].id == seenLast) {
    start = seenSteps - 1;
  }
  final earliest = journey.length - 1 - maxWalkLegs;
  return start < earliest ? earliest : start;
}

/// A point [t] (0 to 1) of the way along the path through [points],
/// by distance.
(double, double) pointAlong(List<(double, double)> points, double t) {
  if (points.length == 1) return points.first;
  final lengths = <double>[];
  var total = 0.0;
  for (var i = 0; i < points.length - 1; i++) {
    final (ax, ay) = points[i];
    final (bx, by) = points[i + 1];
    final d = math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay));
    lengths.add(d);
    total += d;
  }
  if (total == 0) return points.last;
  var remaining = t.clamp(0.0, 1.0) * total;
  for (var i = 0; i < lengths.length; i++) {
    if (remaining <= lengths[i] || i == lengths.length - 1) {
      final f =
          lengths[i] == 0 ? 1.0 : (remaining / lengths[i]).clamp(0.0, 1.0);
      final (ax, ay) = points[i];
      final (bx, by) = points[i + 1];
      return (ax + (bx - ax) * f, ay + (by - ay) * f);
    }
    remaining -= lengths[i];
  }
  return points.last;
}

// ---- Looks -----------------------------------------------------------------

/// The map's three looks: the night it was drawn in, an old parchment
/// chart, and the grey of the Shroud, where only the Void keeps its
/// colour.
enum MapLook { night, parchment, shroud }
