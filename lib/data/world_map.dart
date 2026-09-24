import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Color;

import '../l10n/app_locale.dart';

/// The story's world as one pixel map, 256 × 176 map pixels: the 23
/// landmarks every scene of the story happens at, the road between them in
/// story order, and the terrain under them (generated, always the same).
/// Play mode shows it from the header; a landmark appears once one of its
/// scenes has been read.

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
  MapChapter(
      6,
      'Chapter 6: Beyond the Tear',
      'Chapitre 6 : Au-delà de la Déchirure',
      Color(0xFFE9E6DF),
      Color(0xFF3B3743)),
];

MapChapter mapChapter(int number) =>
    mapChapters.firstWhere((c) => c.number == number);

/// One place on the map and the scenes that happen there.
class Landmark {
  const Landmark({
    required this.id,
    required this.chapter,
    required this.x,
    required this.y,
    required this.sprite,
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
  final int x;
  final int y;
  final String sprite;
  final String nameEn;
  final String nameFr;
  final String blurbEn;
  final String blurbFr;

  /// The story nodes that happen here.
  final List<String> scenes;

  /// The enemies fought here, one entry per enemy (`@first_ally` is the
  /// companion who turns on you at the end).
  final List<String> fights;

  /// Out on the water: no land is raised under it.
  final bool atSea;

  /// Drawn at twice the size.
  final bool big;

  String name(AppLanguage language) =>
      language == AppLanguage.fr ? nameFr : nameEn;
  String blurb(AppLanguage language) =>
      language == AppLanguage.fr ? blurbFr : blurbEn;
}

/// Where the river crosses row [y].
double riverX(num y) => 48 + math.sin(y * 0.08) * 6;

/// Every landmark, in the order the story reaches them.
final List<Landmark> worldMapLandmarks = [
  const Landmark(
    id: 'beggar',
    chapter: 1,
    x: 26,
    y: 126,
    sprite: 'tavern',
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
    x: 30,
    y: 100,
    sprite: 'lamp',
    nameEn: 'Weaver’s Alley',
    nameFr: 'La Ruelle du Tisserand',
    blurbEn:
        'The slow, dark road. A starving warhound is caught in razor wire beside its murdered handler. Cut it free, strip the handler, or leave them both.',
    blurbFr:
        'La route lente et obscure. Un chien de guerre affamé est pris dans des barbelés, à côté de son maître assassiné. Le libérer, dépouiller le maître, ou les laisser tous les deux.',
    scenes: ['270'],
  ),
  Landmark(
    id: 'bridge',
    chapter: 1,
    x: riverX(112).round(),
    y: 112,
    sprite: 'bridge',
    nameEn: 'The Stone Bridge',
    nameFr: 'Le Pont de Pierre',
    blurbEn:
        'The fast, exposed road. Invasion soldiers have built a toll booth out of a market stall. Pay 50 gold or fight your way across.',
    blurbFr:
        'La route rapide et exposée. Des soldats de l’invasion ont fait d’un étal de marché un poste de péage. Payer 50 pièces d’or ou passer en force.',
    scenes: const ['260', '261'],
    fights: const ['slum_thug'],
  ),
  const Landmark(
    id: 'square',
    chapter: 1,
    x: 58,
    y: 86,
    sprite: 'tear',
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
    x: 80,
    y: 100,
    sprite: 'stall',
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
    x: 18,
    y: 72,
    sprite: 'hovel',
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
    x: 40,
    y: 48,
    sprite: 'hold',
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
    x: 62,
    y: 62,
    sprite: 'grate',
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
    x: 102,
    y: 80,
    sprite: 'ship',
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
    x: 102,
    y: 56,
    sprite: 'boat',
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
    x: 84,
    y: 36,
    sprite: 'crates',
    nameEn: 'Smuggler’s Wharf',
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
    x: 54,
    y: 20,
    sprite: 'gate',
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
    x: 86,
    y: 15,
    sprite: 'ship',
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
    x: 138,
    y: 64,
    sprite: 'storm',
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
    x: 166,
    y: 150,
    sprite: 'tent',
    nameEn: 'The coast camp',
    nameFr: 'Le camp de la côte',
    blurbEn:
        'Landfall after twenty days. In a cove hidden from the Spire the survivors start building without anyone deciding to: the base you keep coming back to.',
    blurbFr:
        'La terre, après vingt jours. Dans une crique cachée de la Flèche, les survivants se mettent à bâtir sans que personne l’ait décidé : la base où vous reviendrez sans cesse.',
    scenes: ['3001', '3001_camp'],
  ),
  const Landmark(
    id: 'quarter',
    chapter: 3,
    x: 212,
    y: 100,
    sprite: 'ruins',
    nameEn: 'The Ashen Quarter',
    nameFr: 'Le Quartier de Cendre',
    blurbEn:
        'Chapter 3’s hub, a town the Inquisition burned itself. The Ashen Oath, the Void Relic contract, the relocated Smugglers’ Vault, Maren’s confession, Grosh the mercenary, Reya’s wall of names, and a message to Lysa.',
    blurbFr:
        'Le carrefour du chapitre 3, une ville que l’Inquisition a brûlée elle-même. Le Serment de Cendre, le contrat de la Relique du Vide, le Coffre des Contrebandiers déménagé, la confession de Maren, Grosh le mercenaire, le mur des noms de Reya, et un message pour Lysa.',
    scenes: [
      '3005', '3005_oath', '3005_acolyte', '3005_vault', '3005_relic', //
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
    id: 'spire',
    chapter: 3,
    x: 230,
    y: 70,
    sprite: 'spire',
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
    id: 'grate',
    chapter: 4,
    x: 190,
    y: 114,
    sprite: 'skull',
    nameEn: 'The drain grate',
    nameFr: 'La grille d’égout',
    blurbEn:
        'Survivors whisper about the Hollow Court. A grate no wider than a coffin leads down into the catacombs.',
    blurbFr:
        'Les survivants parlent à voix basse de la Cour Creuse. Une grille pas plus large qu’un cercueil descend vers les catacombes.',
    scenes: ['5001', '5002'],
  ),
  const Landmark(
    id: 'cloister',
    chapter: 4,
    x: 176,
    y: 132,
    sprite: 'candles',
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
    x: 202,
    y: 136,
    sprite: 'altar',
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
    x: 236,
    y: 120,
    sprite: 'chapel',
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
    id: 'heart',
    chapter: 5,
    x: 222,
    y: 152,
    sprite: 'tear',
    big: true,
    nameEn: 'The dead heart',
    nameFr: 'Le cœur mort',
    blurbEn:
        'The tear the ledger names. Something wearing the faces of everyone you killed stands in front of it. Beyond, the Void thanks you for bringing the Shroud whole.',
    blurbFr:
        'La déchirure que nomme le registre. Devant elle se dresse une chose qui porte les visages de tous ceux que vous avez tués. Au-delà, le Vide vous remercie d’avoir apporté le Linceul entier.',
    scenes: ['6003', '6003b', '6004'],
    fights: ['void_manifestation'],
  ),
  const Landmark(
    id: 'shore',
    chapter: 6,
    x: 222,
    y: 24,
    sprite: 'crown',
    nameEn: 'The Hollow Shore',
    nameFr: 'La Rive Creuse',
    blurbEn:
        'Grey sand drawn out of the dead heart, and the tear now a door. Reflections on the sand, the legate’s pact, the Sovereign’s price, and four endings: the city, the seeker, the dawn, or the crown.',
    blurbFr:
        'Un sable gris tiré du cœur mort, et la déchirure devenue porte. Des reflets sur le sable, le pacte du légat, le prix du Souverain, et quatre fins : la ville, le chercheur, l’aube ou la couronne.',
    scenes: [
      '7001', '7002', '7002_reflections', '7002_rest', '7002_pact', //
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

// ---- Sprites and palette ------------------------------------------------

Color _hex(String hex) =>
    Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);

/// The sprites' colours, one letter each.
final Map<String, Color> spritePalette = {
  for (final entry in const {
    'k': '#14110f', 'n': '#3a3632', 'w': '#b9ad95', 'd': '#2a211b', //
    'r': '#8c3b2e', 'y': '#f2c14e', 'g': '#7a7468', 'G': '#a39d90',
    'p': '#8a4fd1', 'P': '#d7b8ff', 'v': '#22103a', 'b': '#6b4a2b',
    'B': '#9c7446', 's': '#d9d2c1', 'o': '#e0762b', 'e': '#eeeae2',
    'm': '#6d3fa0', 'c': '#b58b5a', 'x': '#9b2a2a', 't': '#3f8c8c',
  }.entries)
    entry.key: _hex(entry.value),
};

/// Each landmark's picture, a row of letters per pixel row ('.' is empty).
const Map<String, List<String>> mapSprites = {
  'tavern': ['..rrr..', '.rrrrr.', 'rrrrrrr', '.wwwww.', '.wywdw.', '.wwwdw.'],
  'hovel': ['...r...', '..rrr..', '.rrr.r.', '.wwkww.', '.wwkdw.', '.wwwdw.'],
  'bridge': ['GGGGGGGGG', 'gGgGgGgGg', 'g..g.g..g', 'g..g.g..g'],
  'lamp': ['.yyy.', '.yoy.', '..b..', '..b..', '..b..', '.bbb.'],
  'tear': [
    '..P..', '..p..', '.pPp.', '.pvp.', '.pvp.', '.pvp.', '.pPp.', //
    '..p..', '..P..',
  ],
  'stall': ['xexexex', 'xexexex', '.b...b.', '.bcccb.', '.bcccb.', '.b...b.'],
  'hold': [
    'n.n.n.n.n', 'nnnnnnnnn', 'nxnnnnnxn', 'nnnnnnnnn', 'nnnkkknnn', //
    'nnnkkknnn',
  ],
  'grate': ['ggggggg', 'gkgkgkg', 'gkgkgkg', 'gkgkgkg', 'ggggggg'],
  'ship': [
    '....bs...', '....bss..', '....bsss.', '....bssss', '....b....', //
    'bbbbbbbbb', '.bBBBBBb.', '..bbbbb..',
  ],
  'gate': [
    'G.G.G.G.G', 'GGGGGGGGG', 'GgGGGGGgG', 'GGGkkkGGG', 'GGkkkkkGG', //
    'GGkkkkkGG',
  ],
  'crates': ['bbb.bbb', 'bBb.bBb', 'bbb.bbb', 'bbbbbbb', 'bBbbbBb', 'bbbbbbb'],
  'boat': ['...y...', '...e...', '..ee...', '.eeee..', 'eeeeee.', '.eeee..'],
  'storm': [
    '..ggg....', '.ggggggg.', 'ggggggggg', '.ggggggg.', '....y....', //
    '...y.....', '....y....',
  ],
  'tent': ['....b....', '...ccc...', '..ccccc..', '.ccckccc.', 'ccckkkccc'],
  'ruins': [
    'g........', 'g...g....', 'gg..g..g.', 'gg.gg..gg', 'ggggg.ggg', //
    'nnnnnnnnn',
  ],
  'spire': [
    '...p...', '...G...', '...G...', '..GGG..', '..GmG..', '..GGG..', //
    '.GGmGG.', '.GGGGG.', '.GGmGG.', 'GGGGGGG', 'GmGGGmG', 'GGGkGGG',
    'GGGkGGG',
  ],
  'skull': ['.eeeee.', 'eeeeeee', 'ekeeeke', 'eeekeee', '.eeeee.', '.e.e.e.'],
  'candles': [
    '..y...y', '..o...o', '..e...e', '..e.y.e', '..e.o.e', 'ttttttt', //
    'ttttttt',
  ],
  'altar': [
    '....p....', '...pvp...', '....p....', 'kkkkkkkkk', '.kkkkkkk.', //
    '.kk...kk.',
  ],
  'chapel': [
    '...y...', '..yyy..', '...y...', '..www..', '.wwwww.', 'wwwwwww', //
    'wwmwmww', 'wwwwwww', 'wwwdwww',
  ],
  'crown': ['y...y...y', 'yy.yyy.yy', 'yyyyyyyyy', 'yxyyxyyxy', 'yyyyyyyyy'],
  // The "you are here" marker.
  'pin': ['kkkkk', 'kyyyk', 'kyyyk', '.kyk.', '..k..'],
};

// ---- Terrain -------------------------------------------------------------

/// 32-bit integer multiply, as the map's noise was first written with.
int _imul(int a, int b) {
  a &= 0xFFFFFFFF;
  b &= 0xFFFFFFFF;
  final ah = (a >> 16) & 0xFFFF, al = a & 0xFFFF;
  final bh = (b >> 16) & 0xFFFF, bl = b & 0xFFFF;
  return (al * bl + (((ah * bl + al * bh) << 16) & 0xFFFFFFFF)).toSigned(32);
}

/// A repeatable value in [0, 1) for a grid point.
double mapHash(int x, int y) {
  var h = (_imul(x, 374761393) + _imul(y, 668265263)).toSigned(32);
  h = _imul(h ^ ((h & 0xFFFFFFFF) >> 13), 1274126177);
  return ((h ^ ((h & 0xFFFFFFFF) >> 16)) & 0xFFFFFFFF) / 4294967296;
}

double _valueNoise(double x, double y) {
  final xi = x.floor(), yi = y.floor();
  final xf = x - xi, yf = y - yi;
  final u = xf * xf * (3 - 2 * xf), v = yf * yf * (3 - 2 * yf);
  final a = mapHash(xi, yi), b = mapHash(xi + 1, yi);
  final c = mapHash(xi, yi + 1), d = mapHash(xi + 1, yi + 1);
  return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v;
}

double _ellipse(int x, int y, double cx, double cy, double rx, double ry) {
  final dx = (x - cx) / rx, dy = (y - cy) / ry;
  return 1 - (dx * dx + dy * dy);
}

/// A glint on open water, lit two frames in six from [phase].
class MapGlint {
  const MapGlint(this.x, this.y, this.phase);
  final int x;
  final int y;
  final int phase;
}

/// The ground under the landmarks: one colour per map pixel (ARGB),
/// the water's glints and the city's embers.
class WorldMapTerrain {
  WorldMapTerrain._(this.pixels, this.glints, this.fires);

  final Uint32List pixels;
  final List<MapGlint> glints;
  final List<(int, int)> fires;

  int colorAt(int x, int y) => pixels[y * worldMapWidth + x];

  factory WorldMapTerrain.generate() {
    const w = worldMapWidth, h = worldMapHeight;
    final land = Uint8List(w * h), region = Uint8List(w * h);
    final onLand = [
      for (final l in worldMapLandmarks)
        if (!l.atSea) l,
    ];
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final alster = _ellipse(x, y, 56, 92, 56, 80);
        final coast = _ellipse(x, y, 205, 112, 52, 62);
        final shore = _ellipse(x, y, 226, 22, 26, 12);
        var raised = -1.0;
        for (final l in onLand) {
          final d = math
              .sqrt(((x - l.x) * (x - l.x) + (y - l.y) * (y - l.y)).toDouble());
          raised = math.max(raised, 1 - d / 8);
        }
        final n = (_valueNoise(x * .07, y * .07) - .5) * .5 +
            (_valueNoise(x * .2 + 50, y * .2) - .5) * .25;
        final v =
            math.max(math.max(alster, coast), math.max(shore, raised)) + n;
        final i = y * w + x;
        if (v > 0) {
          land[i] = 1;
          region[i] = x < 130 ? 1 : (y < 40 && x > 190 ? 3 : 2);
        }
      }
    }

    final pixels = Uint32List(w * h);
    final glints = <MapGlint>[];
    final fires = <(int, int)>[];
    void put(int x, int y, int rgb) => pixels[y * w + x] = 0xFF000000 | rgb;

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        final nz = _valueNoise(x * .15, y * .15);
        final dith = ((x + y) & 1) == 1;
        if (land[i] == 0) {
          final near = (x > 0 && land[i - 1] == 1) ||
              (x < w - 1 && land[i + 1] == 1) ||
              (y > 0 && land[i - w] == 1) ||
              (y < h - 1 && land[i + w] == 1);
          if (near) {
            put(x, y, 0x2F6B73);
          } else {
            put(
                x,
                y,
                nz > .55 && dith
                    ? 0x163A44
                    : (nz < .3 && dith ? 0x0E2730 : 0x122F38));
          }
          if (!near && mapHash(x * 3, y * 7) < .012) {
            glints.add(MapGlint(x, y, (mapHash(x, y) * 6).floor()));
          }
          continue;
        }
        final r = region[i];
        if (r == 1) {
          final du =
              math.sqrt(((x - 54) * (x - 54) + (y - 20) * (y - 20)).toDouble());
          if ((x - riverX(y)).abs() < 1.3 && y > 6) {
            put(x, y, 0x1D4C57);
            continue;
          }
          if (du >= 12 && du < 13.3) {
            put(x, y, 0xA39D90);
            continue;
          }
          if (du < 12) {
            put(x, y, dith && nz > .5 ? 0x7A7468 : 0x6A6459);
            if (mapHash(x, y + 9) < .05) fires.add((x, y));
            continue;
          }
          put(
              x,
              y,
              nz > .6 && dith
                  ? 0x4A4032
                  : (nz < .35 && dith ? 0x2F291F : 0x3B3326));
          if (y > 55 && mapHash(x + 5, y) < .025) fires.add((x, y));
        } else if (r == 2) {
          final fr = math
              .sqrt(((x - 230) * (x - 230) + (y - 138) * (y - 138)).toDouble());
          if (fr < 24 && nz + (24 - fr) / 40 > .65) {
            put(x, y, dith ? 0x9FB3BF : 0x7F939F);
          } else {
            put(
                x,
                y,
                nz > .62 && dith
                    ? 0x7B7A75
                    : (nz < .3 && dith ? 0x4A4946 : 0x5E5C58));
          }
        } else {
          put(x, y, nz > .5 && dith ? 0xB3AFA4 : 0x9A968C);
        }
      }
    }
    // Piers.
    void pier(int x0, int y0, int dx, int dy, int length) {
      for (var k = 0; k < length; k++) {
        final x = x0 + dx * k, y = y0 + dy * k;
        if (x >= 0 && x < w && y >= 0 && y < h) put(x, y, 0x6B4A2B);
      }
    }

    pier(96, 24, 1, -1, 6);
    pier(92, 40, 1, 0, 10);
    pier(106, 82, 1, 0, 8);
    pier(170, 156, -1, 1, 5);
    return WorldMapTerrain._(pixels, glints, fires);
  }
}

/// Generated once, on first use.
final WorldMapTerrain worldMapTerrain = WorldMapTerrain.generate();

// ---- Fog -----------------------------------------------------------------

/// How far around a reached landmark the map is clear, in map pixels; the
/// fog's edge is dithered over a few more.
const double fogClearRadius = 26;
const double fogEdge = 6;

/// Per map pixel: 1 under fog, 0 clear. Around what has been reached the
/// map is clear, with a checkerboard edge.
Uint8List fogMask(Set<String> discovered) {
  const w = worldMapWidth, h = worldMapHeight;
  final mask = Uint8List(w * h)..fillRange(0, w * h, 1);
  final reached = [
    for (final l in worldMapLandmarks)
      if (discovered.contains(l.id)) l,
  ];
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      var nearest = double.infinity;
      for (final l in reached) {
        final d = math
            .sqrt(((x - l.x) * (x - l.x) + (y - l.y) * (y - l.y)).toDouble());
        if (d < nearest) nearest = d;
      }
      final i = y * w + x;
      if (nearest <= fogClearRadius) {
        mask[i] = 0;
      } else if (nearest <= fogClearRadius + fogEdge) {
        mask[i] = ((x + y) & 1) == 0 ? 1 : 0;
      }
    }
  }
  return mask;
}

/// [argb] under the fog: most of the way to the fog's own colour.
int foggedColor(int argb) {
  const fog = 0x0B0A0D;
  int mix(int shift) {
    final c = (argb >> shift) & 0xFF, f = (fog >> shift) & 0xFF;
    return (c * 0.22 + f * 0.78).round();
  }

  return 0xFF000000 | (mix(16) << 16) | (mix(8) << 8) | mix(0);
}
