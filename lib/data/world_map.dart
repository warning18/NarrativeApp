import 'dart:math' as math;
import 'dart:ui' show Color;

import '../l10n/app_locale.dart';

/// The story's world, on a chart 256 × 176 units across: the 23
/// landmarks every scene of the story happens at and the road between them
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
  MapChapter(
      2,
      'Chapter 2: The Ashes of Alster',
      'Chapitre 2 : Les Cendres d’Alster',
      Color(0xFF3F9C9C),
      Color(0xFF1F6F6F)),
  MapChapter(
      3,
      'Chapter 3: The Spire of Judgment',
      'Chapitre 3 : La Flèche du Jugement',
      Color(0xFF9A968C),
      Color(0xFF5F5B55)),
  MapChapter(4, 'Chapter 4: The Hollow Court', 'Chapitre 4 : La Cour Creuse',
      Color(0xFFD9CFB8), Color(0xFF7A6A48)),
  MapChapter(
      5,
      'Chapter 5: The Shroud’s Truth',
      'Chapitre 5 : La Vérité du Linceul',
      Color(0xFF9B6FE0),
      Color(0xFF6D3FA0)),
  MapChapter(6, 'Chapter 6: The Hollow Shore', 'Chapitre 6 : La Rive Creuse',
      Color(0xFFE9E6DF), Color(0xFF3B3743)),
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
        'Where it starts. The prologue asks who you were; then the slum tavern you ran to is already gutted, the barkeep dead, and Lysa hiding in the cellar. Two roads out: the exposed bridge or the dark alley.',
    blurbFr:
        'Là où tout commence. Le prologue demande qui vous étiez ; puis la taverne des bas-quartiers vers laquelle vous avez fui est déjà éventrée, le tavernier mort, et Lysa cachée dans la cave. Deux routes pour sortir : le pont à découvert ou la ruelle obscure.',
    scenes: ['0', '100', '250'],
  ),
  const Landmark(
    id: 'alley',
    chapter: 1,
    nameEn: 'Weaver’s Alley',
    nameFr: 'La Ruelle du Tisserand',
    blurbEn:
        'The slow, dark road. A starving warhound is caught in razor wire beside its murdered handler. Cut it free, strip the handler, or leave them both.',
    blurbFr:
        'La route lente et obscure. Un chien de guerre affamé est pris dans des barbelés, à côté de son maître assassiné. Le libérer, dépouiller le maître, ou les laisser tous les deux.',
    scenes: ['270'],
  ),
  const Landmark(
    id: 'bridge',
    chapter: 1,
    nameEn: 'The Stone Bridge',
    nameFr: 'Le Pont de Pierre',
    blurbEn:
        'The fast, exposed road. Invasion soldiers have built a toll booth out of a market stall. Pay 50 gold or fight your way across.',
    blurbFr:
        'La route rapide et exposée. Des soldats de l’invasion ont fait d’un étal de marché un poste de péage. Payer 50 pièces d’or ou passer en force.',
    scenes: ['260', '261'],
    fights: ['slum_thug'],
  ),
  const Landmark(
    id: 'square',
    chapter: 1,
    nameEn: 'The Scorched Square',
    nameFr: 'La Place calcinée',
    blurbEn:
        'A tear no wider than a coin slot hangs a hand above the cobbles. Touch it and something vast looks back; the looters’ dropped goods lie in a ring around it.',
    blurbFr:
        'Une déchirure pas plus large qu’une fente de tirelire flotte à une main au-dessus des pavés. Touchez-la et quelque chose d’immense vous regarde en retour ; le butin abandonné des pillards gît en cercle autour d’elle.',
    scenes: ['280', '281', '281_scarred'],
  ),
  const Landmark(
    id: 'market',
    chapter: 1,
    nameEn: 'The last stalls',
    nameFr: 'Les derniers étals',
    blurbEn:
        'A blacksmith, a shieldwright and a bandit working the panic. The forge’s back room hides a cache, and Vess, marked by the tear like you, waits at the edge of the stalls.',
    blurbFr:
        'Un forgeron, un fabricant de boucliers et un bandit qui profite de la panique. L’arrière-boutique de la forge cache une réserve, et Vess, marquée par la déchirure comme vous, attend au bout des étals.',
    scenes: ['151', '151_forge', '151_vess'],
    fights: ['street_bandit'],
  ),
  const Landmark(
    id: 'hovel',
    chapter: 1,
    nameEn: 'Your parents’ hovel',
    nameFr: 'La masure de vos parents',
    blurbEn:
        'The Grey Bundle waits under the floorboard, warm as a living thing. Three White Soldiers break the door. Unfurl it and win, or lose or surrender and wake in the Black Hold.',
    blurbFr:
        'Le Balluchon Gris attend sous le plancher, tiède comme une chose vivante. Trois Soldats Blancs enfoncent la porte. Déployez-le et gagnez ; perdez ou rendez-vous, et vous vous réveillerez dans la Geôle Noire.',
    scenes: ['300', '400', '400_lost', '450'],
    fights: ['white_soldier', 'white_soldier', 'white_soldier'],
  ),
  const Landmark(
    id: 'hold',
    chapter: 1,
    nameEn: 'The Black Hold',
    nameFr: 'La Geôle Noire',
    blurbEn:
        'Three days under a porcelain mask, then the resistance blows the wall in. Recover the Bundle from the torturer’s table, get past the Wardens, and choose the battlements or the Corpse Chute.',
    blurbFr:
        'Trois jours sous un masque de porcelaine, puis la résistance fait sauter le mur. Reprenez le Balluchon sur la table du bourreau, passez les Gardiens, et choisissez les remparts ou la Goulotte aux Cadavres.',
    scenes: ['800', '816', '820', '822', '823'],
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
    scenes: ['840', '850', '855'],
    fights: ['rat_matriarch'],
  ),
  const Landmark(
    id: 'docks',
    chapter: 1,
    nameEn: 'Alster docks',
    nameFr: 'Les docks d’Alster',
    blurbEn:
        'The Rusty Eel weighs anchor. Plead, bargain or threaten your way past the smuggler, then face Kroll the Branded on the pier. How you finish him, and what you climb toward, sets your origin: Guardian, Rat or Broken.',
    blurbFr:
        'Le Rusty Eel lève l’ancre. Suppliez, marchandez ou menacez pour passer le contrebandier, puis affrontez Kroll sur la jetée. La façon dont vous l’achevez, et ce vers quoi vous grimpez, fixe votre origine : Gardien, Rat ou Brisé.',
    scenes: [
      '891', '895', '896', '897', '898', '960', '965', '965_mercy', //
      '965_vengeance', '1000', '1001', '1002',
    ],
    fights: ['kroll_the_branded'],
  ),
  const Landmark(
    id: 'tern',
    chapter: 2,
    nameEn: 'Tern Row',
    nameFr: 'Tern Row',
    blurbEn:
        'The Tide-Kin quarter of paper boats. Nadira asks for help against Renn, a customs officer charging a toll that exists in no ledger. Talk him down or fight.',
    blurbFr:
        'Le quartier des Gens de la Marée et de leurs bateaux de papier. Nadira demande de l’aide contre Renn, un douanier qui perçoit un péage inscrit dans aucun registre. Le raisonner ou se battre.',
    scenes: ['2015_ternrow', '2015_ternrow_talked', '2015_ternrow_fight'],
    fights: ['dock_overseer'],
  ),
  const Landmark(
    id: 'wharf',
    chapter: 2,
    nameEn: 'Smugglers’ Wharf',
    nameFr: 'Le Quai des Contrebandiers',
    blurbEn:
        'Chapter 2’s hub. Vane holds the gangplank to the Lower City; the market around him is full of work: the Bazaar, Apothecary Row, bounties, card games, a false informant, Kelda at the gate, Sable’s marker, and Liora on the rooftop.',
    blurbFr:
        'Le carrefour du chapitre 2. Vane garde la passerelle vers la Ville Basse ; autour de lui, le marché regorge de travail : le Bazar, la rue des Apothicaires, des primes, des parties de cartes, un faux informateur, Kelda à la porte, la reconnaissance de dette de Sable, et Liora sur le toit.',
    scenes: [
      '2001', '2000', '2005', '2010', '2010_crane', '2010_liora', '2011', //
      '2015', '2015_apothecary', '2015_bandits', '2015_bazaar', '2015_cards',
      '2015_cards_won', '2015_cards_lost', '2015_dockside', '2015_hound',
      '2015_informant', '2015_informant_trap', '2015_informant_exposed',
      '2015_informant_caught', '2015_kelda', '2015_rats', '2015_sable',
      '2015_smuggler', '2020', '2021', '2030', '2040', '2050', '2070',
    ],
    fights: [
      'harbor_rat', 'smuggler_captain', 'plague_hound', 'street_bandit', //
      'inquisition_soldier',
    ],
  ),
  const Landmark(
    id: 'upper',
    chapter: 2,
    nameEn: 'The Upper Tier',
    nameFr: 'Le Palier Supérieur',
    blurbEn:
        'The last sanctuary behind iron gates. By the chapter’s end the Crusade holds them and the Tier burns behind its own walls.',
    blurbFr:
        'Le dernier sanctuaire derrière des grilles de fer. À la fin du chapitre, la Croisade les tient et le Palier brûle derrière ses propres murs.',
    scenes: ['2001', '2900'],
  ),
  const Landmark(
    id: 'berths',
    chapter: 2,
    atSea: true,
    nameEn: 'The old berths',
    nameFr: 'Les anciens mouillages',
    blurbEn:
        'The Eel is the last hull that floats, holed below the waterline. Patch the hull and mend the sail, then decide who sails: everyone, the twenty who can fight, or no one.',
    blurbFr:
        'L’Eel est la dernière coque qui flotte, percée sous la ligne de flottaison. Colmatez la coque, réparez la voile, puis décidez qui embarque : tout le monde, les vingt qui savent se battre, ou personne.',
    scenes: ['2900', '2900_boat_fixed'],
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
        'Trois semaines de haute mer vers la Côte de Cendre. La douzième nuit, la tempête frappe : sacrifier les vivres, couper l’amarre des réfugiés, ou vous attacher à la barre.',
    scenes: ['2999'],
  ),
  const Landmark(
    id: 'camp',
    chapter: 3,
    nameEn: 'The Cove Camp',
    nameFr: 'Le camp de la crique',
    blurbEn:
        'Landfall after twenty days. In a cove hidden from the Spire the survivors start building without anyone deciding to: your base, where every chapter opens, between every trip, until the last night before the tear.',
    blurbFr:
        'La terre, après vingt jours. Dans une crique cachée de la Flèche, les survivants se mettent à bâtir sans que personne l’ait décidé : votre base, où chaque chapitre commence, entre chaque voyage, jusqu’à la dernière nuit avant la déchirure.',
    scenes: ['3001', '3001_camp', '4999_camp', '6002_camp', '7001', '7400'],
  ),
  const Landmark(
    id: 'quarter',
    chapter: 3,
    nameEn: 'The Ashen Quarter',
    nameFr: 'Le Quartier des Cendres',
    blurbEn:
        'Chapter 3’s hub, a day’s walk from the camp: a town the Inquisition burned itself. The Ashen Oath, the Void Relic contract, Maren’s confession, Grosh the mercenary, Reya’s wall of names, and a message to Lysa.',
    blurbFr:
        'Le carrefour du chapitre 3, à une journée de marche du camp : une ville que l’Inquisition a brûlée elle-même. Le Serment de Cendres, le contrat de la Relique du Néant, la confession de Maren, Grosh le mercenaire, le mur des noms de Reya, et un message pour Lysa.',
    scenes: [
      '3005', '3005_oath', '3005_acolyte', '3005_relic', //
      '3005_wisp', '3005_stalker', '3005_golem', '3005_auxiliaries',
      '3005_maren', '3005_archive', '3005_archive_failed', '3005_ledger',
      '3005_ledger_failed', '3005_grosh', '3005_wall', '3005_wall_argued',
      '3005_wall_fight', '3005_lysa',
    ],
    fights: [
      'cultist_acolyte', 'void_wisp', 'void_stalker', 'iron_golem', //
      'inquisition_auxiliary',
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
        'Un creux des vieux terrils où les familles des forgerons se sont repliées quand les golems ont survécu à leurs maîtres : des fours, un puits, des collecteurs de dîme de la Flèche, et une veuve de forgeron qui entend encore son cantique.',
    scenes: [
      '3100', '3100_tithe', '3100_kiln', '3100_kiln_failed', //
      '3100_widow', '3100_widow_later', '3100_bread',
    ],
    fights: ['inquisition_auxiliary'],
  ),
  const Landmark(
    id: 'spire',
    chapter: 3,
    nameEn: 'The Spire of Judgment',
    nameFr: 'La Flèche du Jugement',
    blurbEn:
        'The Inquisition’s mother-house. Go over the cloister roofs and through the stained glass, or through the Hall of Records by bribe or violence. The High Warden’s white standard is grey underneath: a piece of the Shroud.',
    blurbFr:
        'La maison mère de l’Inquisition. Passez par les toits du cloître et à travers les vitraux, ou par la Salle des Archives, en soudoyant ou par la force. L’étendard blanc du Haut Gardien est gris en dessous : un morceau du Linceul.',
    scenes: [
      '3002', '3010', '3020', '3030', '3040', '3050', '4999', //
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
      '5100_headman', '5100_headman_later', '5100_nets',
    ],
    fights: ['drowned_pilgrim'],
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
      '5010_sapper_thanks', '5010_warden', '5010_trade', '5010_span',
      '5010_span_failed', '5010_wisps', '5010_deserter',
      '5010_deserter_later', '5010_deserter_failed', '5010_tobin',
      '5010_tobin_hymn',
    ],
    fights: ['catacomb_ghoul', 'bone_warden', 'void_wisp'],
  ),
  const Landmark(
    id: 'court',
    chapter: 4,
    nameEn: 'The Hollow Court',
    nameFr: 'La Cour Creuse',
    blurbEn:
        'Inked inquisitors around a black altar and the Shroud’s twin. Their ledger of the taken has your parents on page two, and a dozen sleepers lie wrapped in the grey you need.',
    blurbFr:
        'Des inquisiteurs tatoués autour d’un autel noir et du jumeau du Linceul. Leur registre des disparus porte vos parents en page deux, et une douzaine de dormeurs gisent enveloppés du gris qu’il vous faut.',
    scenes: ['5003', '5004', '5004b', '5004_altar', '5005'],
    fights: ['hollow_court_zealot'],
  ),
  const Landmark(
    id: 'reliquary',
    chapter: 5,
    nameEn: 'The Reliquary Quarter',
    nameFr: 'Le Quartier des Reliquaires',
    blurbEn:
        'Frost in summer and penitents at the gate. The ledger’s truth, the chart-keeper, the Last Lantern, Malrik’s stall, a confession to answer, Lysa’s fate, and the fourth piece of the Shroud in a girl’s reliquary.',
    blurbFr:
        'Du givre en plein été et des pénitents à la porte. La vérité du registre, la gardienne des cartes, la Dernière Lanterne, l’étal de Malrik, une confession à laquelle répondre, le sort de Lysa, et le quatrième morceau du Linceul dans le reliquaire d’une fillette.',
    scenes: [
      '6001', '6002', '6010_gate', '6010', '6010_chartkeeper', //
      '6010_chartkeeper_words', '6010_lysa', '6010_lysa_later',
      '6010_lysa_dead', '6010_masked', '6010_masked_after', '6010_hounds',
      '6010_confession', '6010_confession_later', '6010_penitent',
      '6010_lantern', '6010_lantern_keeper', '6010_spawn', '6010_frost',
      '6010_frost_failed', '6010_malrik', '6010_thread',
    ],
    fights: [
      'void_hound', 'inquisition_penitent', 'tear_spawn', 'masked_penitent', //
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
        'Une halte de pèlerins sur la route du Reliquaire Noir, où le givre de la déchirure est arrivé en premier : une cloche qui compte les disparus, la lanterne d’une gardienne de la route, et un pain rassis partagé avec ceux qui marchent encore.',
    scenes: [
      '6100', '6100_bell', '6100_bell_failed', '6100_road', //
      '6100_keeper', '6100_keeper_later', '6100_bread',
    ],
    fights: ['void_hound', 'drowned_pilgrim'],
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
        'Une ville bâtie avec les épaves de la Flotte Blanche par les croisés qui s’y sont échoués : un aumônier qui sait où gît le vaisseau amiral, une chandlerie, le mal gris, et une dernière compagnie encore en guerre.',
    scenes: [
      '7100', '7100_chaplain', '7100_chandlery', '7100_company', //
      '7100_sick', '7100_sick_failed', '7100_helmsman',
      '7100_helmsman_later',
    ],
    fights: ['inquisition_soldier', 'white_soldier'],
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
        'Grey sand drawn out of the dead heart, and the tear now a door. Reflections on the sand, the legate’s pact, the Sovereign’s price and its sixth piece, four endings (the city, the seeker, the dawn, or the crown), and the night the whole Banner turns back.',
    blurbFr:
        'Un sable gris tiré du cœur mort, et la déchirure devenue porte. Des reflets sur le sable, le pacte du légat, le prix du Souverain et sa sixième pièce, quatre fins (la ville, le chercheur, l’aube ou la couronne), et la nuit où la Bannière entière revient en arrière.',
    scenes: [
      '7002', '7002_reflections', '7002_rest', '7002_pact', //
      '7002_betrayal', '7002_crew', '7002_confront', '7002_price', '7003',
      '7004', '7005', '7005_seeker', '7005_dawn', '7005_crown',
    ],
    fights: ['hollow_reflection', '@first_ally'],
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

/// The landmark a scene happens at. A scene shared by two places (the
/// arrival under the Upper Tier, the burning harbour at the berths) belongs
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
