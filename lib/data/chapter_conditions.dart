import 'dart:math';

import 'road_events.dart' show stableHash;

/// Chapter conditions (v1.181): what the region is going through while the
/// party is there, one per chapter from 2 to 6, drawn once per run from
/// the run's seed (see PlayerSession.runSeed). The same run always meets
/// the same conditions; two runs seldom do. Each one shifts a few of the
/// road's numbers: shop and ration prices, what waits on the roads, the
/// weather at sea, what expeditions pay.
enum ChapterConditionId {
  quarantine,
  tideFair,
  contestedRoads,
  stormSeason,
  rivalCompany,
  leanSeason,
  fairWinds,
  bountySeason,
}

class ChapterCondition {
  const ChapterCondition({
    required this.id,
    required this.nameEn,
    required this.nameFr,
    required this.effectEn,
    required this.effectFr,
    required this.arrivalEn,
    required this.arrivalFr,
    this.chapters = const {2, 3, 4, 5, 6},
    this.shopPrice = 1,
    this.rationPrice = 1,
    this.roadEventOdds = 1,
    this.championShare = 0.4,
    this.shrineShare = 0.3,
    this.stormShift = 0,
    this.expeditionPay = 1,
  });

  final ChapterConditionId id;
  final String nameEn;
  final String nameFr;

  /// What it changes, in one line (the Journey tab's road panel).
  final String effectEn;
  final String effectFr;

  /// What the party sees on arriving (the chapter's pop-up).
  final String arrivalEn;
  final String arrivalFr;

  /// The chapters it can be drawn in: weather at sea only once the boat
  /// sails (chapter 3), a fair only where life goes on (not while Alster
  /// falls, nor at the Reliquary Quarter or on the Hollow Shore).
  final Set<int> chapters;

  /// Multiplies shop prices, after the Charisma discount.
  final double shopPrice;

  /// Multiplies what a ration costs.
  final double rationPrice;

  /// Multiplies the odds a road holds an event.
  final double roadEventOdds;

  /// The share of road events that are champions, and shrines; the rest
  /// are the Wayfarer's Caravan.
  final double championShare;
  final double shrineShare;

  /// Widens (or narrows) a sea day's storm band, at the expense of calm
  /// water (see buildVoyage): the calm band is 0.15 wide, so a shift of
  /// that much leaves no calm days at all.
  final double stormShift;

  /// Multiplies an expedition's pay.
  final double expeditionPay;

  String nameFor(bool french) => french ? nameFr : nameEn;
  String effectFor(bool french) => french ? effectFr : effectEn;
  String arrivalFor(bool french) => french ? arrivalFr : arrivalEn;
}

const List<ChapterCondition> chapterConditions = [
  ChapterCondition(
    id: ChapterConditionId.quarantine,
    nameEn: 'Quarantine',
    nameFr: 'Quarantaine',
    effectEn: 'Shops charge a quarter more; rations cost half again.',
    effectFr:
        'Les boutiques vendent un quart plus cher ; les rations coûtent moitié plus.',
    arrivalEn: 'Chalk crosses on the doors, and a guard with a cloth over '
        'his mouth waves you through after a long look. A fever is going '
        'round. Whatever the traders still sell, they sell dear.',
    arrivalFr: 'Des croix à la craie sur les portes, et un garde, un linge '
        'sur la bouche, vous laisse passer après un long regard. Une fièvre '
        'circule. Ce que les marchands vendent encore, ils le vendent cher.',
    shopPrice: 1.25,
    rationPrice: 1.5,
  ),
  ChapterCondition(
    id: ChapterConditionId.tideFair,
    nameEn: 'Tide Fair',
    nameFr: 'Foire des marées',
    effectEn: 'Shops charge a fifth less; the roads are busier, and the '
        'Wayfarer\'s Caravan is out more often.',
    effectFr: 'Les boutiques vendent un cinquième moins cher ; les routes '
        'sont plus animées, et la Caravane du Voyageur sort plus souvent.',
    arrivalEn: 'Bunting between the roofs, drums in the square: the fair '
        'has come. Every trader on the coast is here, and each one '
        'undercuts the next.',
    arrivalFr: 'Des fanions entre les toits, des tambours sur la place : la '
        'foire est arrivée. Tous les marchands de la côte sont là, et chacun '
        'casse les prix du voisin.',
    chapters: {3, 4},
    shopPrice: 0.8,
    roadEventOdds: 1.2,
    championShare: 0.2,
    shrineShare: 0.3,
  ),
  ChapterCondition(
    id: ChapterConditionId.contestedRoads,
    nameEn: 'Contested roads',
    nameFr: 'Routes disputées',
    effectEn: 'Half again as many road events, and most of them are '
        'champions barring the way.',
    effectFr: 'Moitié plus d\'événements sur les routes, et ce sont surtout '
        'des champions qui barrent le passage.',
    arrivalEn: 'Burnt carts at the crossroads, and a notice nailed to a '
        'post: travel in groups. Whatever hunts in this region has taken '
        'to the roads.',
    arrivalFr: 'Des charrettes brûlées aux carrefours, et un avis cloué à un '
        'poteau : voyagez en groupe. Ce qui chasse dans la région a pris '
        'les routes.',
    roadEventOdds: 1.5,
    championShare: 0.65,
    shrineShare: 0.2,
  ),
  ChapterCondition(
    id: ChapterConditionId.stormSeason,
    nameEn: 'Storm season',
    nameFr: 'Saison des tempêtes',
    effectEn: 'Storms come often at sea, and calm days are rare.',
    effectFr: 'Les tempêtes sont fréquentes en mer, et les jours calmes '
        'sont rares.',
    arrivalEn: 'The sky over the water has turned the colour of slate, and '
        'the fishermen have pulled their boats up the shingle. Every '
        'crossing will be rough.',
    arrivalFr: 'Le ciel au-dessus de l\'eau a pris la couleur de l\'ardoise, '
        'et les pêcheurs ont tiré leurs barques sur les galets. Chaque '
        'traversée sera rude.',
    chapters: {3, 4, 5, 6},
    // Most of the calm band, not all of it: calm days stay, rarely.
    stormShift: 0.1,
  ),
  ChapterCondition(
    id: ChapterConditionId.rivalCompany,
    nameEn: 'A rival company',
    nameFr: 'Une compagnie rivale',
    effectEn: 'Another company takes the best contracts: expeditions pay a '
        'quarter less.',
    effectFr: 'Une autre compagnie prend les meilleurs contrats : les '
        'expéditions rapportent un quart de moins.',
    arrivalEn: 'A company in red sashes got here first. Their captain '
        'drinks at the best table and takes the best contracts; what is '
        'left for you pays less.',
    arrivalFr: 'Une compagnie aux écharpes rouges est arrivée la première. '
        'Son capitaine boit à la meilleure table et prend les meilleurs '
        'contrats ; ce qui reste pour vous paie moins.',
    expeditionPay: 0.75,
  ),
  ChapterCondition(
    id: ChapterConditionId.leanSeason,
    nameEn: 'Lean season',
    nameFr: 'Disette',
    effectEn: 'The harvest failed: rations cost twice as much.',
    effectFr: 'La récolte a manqué : les rations coûtent le double.',
    arrivalEn: 'Empty granaries, thin soup, and children watching every '
        'loaf. The harvest failed here, and bread is worth its weight in '
        'coin.',
    arrivalFr: 'Des greniers vides, une soupe claire, et des enfants qui '
        'suivent chaque miche des yeux. La récolte a manqué, et le pain vaut '
        'son poids en pièces.',
    rationPrice: 2,
  ),
  ChapterCondition(
    id: ChapterConditionId.fairWinds,
    nameEn: 'Fair winds',
    nameFr: 'Vents favorables',
    effectEn: 'Steady winds and a flat sea: storms are rare.',
    effectFr: 'Un vent régulier et une mer d\'huile : les tempêtes sont '
        'rares.',
    arrivalEn: 'A steady wind off the land, and a sea like hammered tin. '
        'The sailors say it will not last; for now, every crossing is an '
        'easy one.',
    arrivalFr: 'Un vent régulier venu de la terre, et une mer comme de '
        'l\'étain martelé. Les marins disent que ça ne durera pas ; pour '
        'l\'instant, chaque traversée est facile.',
    chapters: {3, 4, 5, 6},
    stormShift: -0.15,
  ),
  ChapterCondition(
    id: ChapterConditionId.bountySeason,
    nameEn: 'Bounty season',
    nameFr: 'Saison des primes',
    effectEn: 'Someone wants the wilds cleared: expeditions pay a quarter '
        'more.',
    effectFr: 'Quelqu\'un veut qu\'on nettoie les terres sauvages : les '
        'expéditions rapportent un quart de plus.',
    arrivalEn: 'Fresh notices on every door, with a seal and a sum at the '
        'bottom. Someone with money wants the wilds cleared, and pays '
        'over the usual rate.',
    arrivalFr: 'De nouvelles affiches sur chaque porte, avec un sceau et une '
        'somme en bas. Quelqu\'un qui a de l\'argent veut qu\'on nettoie '
        'les terres sauvages, et paie plus que d\'habitude.',
    expeditionPay: 1.25,
  ),
];

/// The chapters that have a condition.
const int firstConditionChapter = 2;
const int lastConditionChapter = 6;

/// The seed a run's conditions are drawn from: its own, or, for a save
/// made before runs had one, one made from the character.
int conditionSeedFor({
  required int runSeed,
  required String characterName,
  required String raceId,
  required String professionId,
  required int cycle,
}) =>
    runSeed != 0
        ? runSeed
        : stableHash('$characterName|$raceId|$professionId|$cycle');

/// The condition of [chapter] in the run of [seed]: none outside chapters
/// 2 to 6. The chapters draw in order, without repeats, so a run meets
/// five different conditions.
ChapterCondition? chapterConditionFor(
    {required int seed, required int chapter}) {
  if (chapter < firstConditionChapter || chapter > lastConditionChapter) {
    return null;
  }
  final random = Random(seed);
  final used = <ChapterConditionId>{};
  ChapterCondition? pick;
  for (var c = firstConditionChapter; c <= chapter; c++) {
    final pool = [
      for (final condition in chapterConditions)
        if (!used.contains(condition.id) && condition.chapters.contains(c))
          condition,
    ];
    pick = pool[random.nextInt(pool.length)];
    used.add(pick.id);
  }
  return pick;
}

/// [price] under [condition]'s [factor]; never below 1 for anything that
/// had a price.
int conditionedPrice(int price, double factor) {
  if (price <= 0 || factor == 1) return price;
  return max(1, (price * factor).round());
}

/// [factor] as a signed percentage: 1.25 → '+25', 0.8 → '−20'.
String percentChange(double factor) {
  final p = ((factor - 1) * 100).round();
  return p > 0 ? '+$p' : '−${p.abs()}';
}

/// The session flag set once the chapter's condition has been shown.
String conditionSeenFlag(int chapter) => 'condition_seen_$chapter';
