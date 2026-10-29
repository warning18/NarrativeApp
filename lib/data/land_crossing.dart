/// Land expeditions (v1.285.0, docs/proposals/land-expeditions.md): a long
/// land route played like a voyage. A short chain of events is drawn at
/// departure (land_routes.json), each asks what the party does
/// (land_events.json), and the party's health plays the hull: when it runs
/// out, the crossing fails and the party is carried back to where it set
/// out, alive but wounded. No water, no food, no save field: a crossing is
/// played in one sitting, like a voyage.
library;

import 'dart:math';

import 'ability_check.dart' show checkPasses;
import 'clan_power.dart' show holderOf;
import 'factions.dart'
    show ClanData, PoliticsState, StandingTier, StandingTierOrder;
import 'geography.dart';
import 'town_rulers.dart' show TownRuler, townRulers;

/// What one outcome of a crossing's choice does: health as a percent of
/// the party's maximum (signed), gold (signed), and extra days lost. [note]
/// is the line that tells it.
class LandOutcome {
  const LandOutcome({
    this.healthPct = 0,
    this.gold = 0,
    this.days = 0,
    this.note = '',
    this.noteFr = '',
  });

  factory LandOutcome.fromJson(Object? json) {
    final map = json is Map ? json : const {};
    return LandOutcome(
      healthPct: (map['healthPct'] as num?)?.toInt() ?? 0,
      gold: (map['gold'] as num?)?.toInt() ?? 0,
      days: (map['days'] as num?)?.toInt() ?? 0,
      note: map['note']?.toString() ?? '',
      noteFr: map['note_fr']?.toString() ?? '',
    );
  }

  final int healthPct;
  final int gold;
  final int days;
  final String note;
  final String noteFr;

  String noteFor(bool fr) => fr && noteFr.isNotEmpty ? noteFr : note;

  /// The health this outcome moves for a party of [maxHealth].
  int healthChange(int maxHealth) => (maxHealth * healthPct / 100).round();
}

/// One way through a crossing's event: a sure [outcome], an ability
/// [check] against [dc] (see [landCheckDc]) with a [success] and a [fail],
/// or a [fightEnemyId] fought on the battle screen: won, its [success];
/// broken off, its [fail]; lost, the crossing is lost.
class LandChoice {
  const LandChoice({
    required this.id,
    required this.text,
    this.textFr = '',
    this.check,
    this.dc = 0,
    this.outcome = const LandOutcome(),
    this.success = const LandOutcome(),
    this.fail = const LandOutcome(),
    this.fightEnemyId,
  });

  factory LandChoice.fromJson(Map json) => LandChoice(
        id: json['id']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        textFr: json['text_fr']?.toString() ?? '',
        check: (json['check']?.toString() ?? '').isEmpty
            ? null
            : json['check'].toString(),
        dc: (json['dc'] as num?)?.toInt() ?? 0,
        outcome: LandOutcome.fromJson(json['outcome']),
        success: LandOutcome.fromJson(json['success']),
        fail: LandOutcome.fromJson(json['fail']),
        fightEnemyId: (json['fight']?.toString() ?? '').isEmpty
            ? null
            : json['fight'].toString(),
      );

  final String id;
  final String text;
  final String textFr;

  /// The ability the choice rolls (ability_check.dart's keys), or null for
  /// a sure [outcome].
  final String? check;
  final int dc;
  final LandOutcome outcome;
  final LandOutcome success;
  final LandOutcome fail;

  /// The enemy (enemies.json) the choice is a fight with, or null.
  final String? fightEnemyId;

  bool get hasCheck => check != null;

  bool get isFight => fightEnemyId != null;

  String textFor(bool fr) => fr && textFr.isNotEmpty ? textFr : text;

  /// The gold the choice asks for up front (a purse thrown to raiders):
  /// not made on credit.
  int get goldCost =>
      !hasCheck && !isFight && outcome.gold < 0 ? -outcome.gold : 0;
}

/// One event on a crossing (land_events.json).
class LandEvent {
  const LandEvent({
    required this.id,
    required this.name,
    this.nameFr = '',
    this.text = '',
    this.textFr = '',
    this.choices = const [],
    this.ruler = '',
    this.band,
  });

  factory LandEvent.fromJson(String id, Map json) => LandEvent(
        id: id,
        name: json['name']?.toString() ?? id,
        nameFr: json['name_fr']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        textFr: json['text_fr']?.toString() ?? '',
        choices: [
          for (final c in (json['choices'] as List? ?? const []))
            if (c is Map) LandChoice.fromJson(c),
        ],
        ruler: json['ruler']?.toString() ?? '',
        band: RulerBand.values
            .where((b) => b.name == json['band']?.toString())
            .firstOrNull,
      );

  final String id;
  final String name;
  final String nameFr;
  final String text;
  final String textFr;
  final List<LandChoice> choices;

  /// A ruler's event (wave 16): the clan (factions.json) whose land it is
  /// met on, '' for a biome event; and the [band] of standing with that
  /// clan it is met at.
  final String ruler;
  final RulerBand? band;

  bool get isRulers => ruler.isNotEmpty;

  String nameFor(bool fr) => fr && nameFr.isNotEmpty ? nameFr : name;
  String textFor(bool fr) => fr && textFr.isNotEmpty ? textFr : text;
}

/// How a road's ruler meets the party (wave 16, docs/proposals/
/// wave16-core.md §3), by its standing with them: Friend and up, let
/// through or helped; Hostile and down, the hard version; between, the
/// toll.
enum RulerBand { friend, neutral, hostile }

/// The band of a party at [tier] with a road's ruler.
RulerBand rulerBandFor(StandingTier tier) => tier.isAtLeast(StandingTier.friend)
    ? RulerBand.friend
    : tier.isAtLeast(StandingTier.resented)
        ? RulerBand.neutral
        : RulerBand.hostile;

/// A long land route (land_routes.json): from one landmark to another
/// (world_roads.dart's place ids), over [days] days, an event a day drawn
/// by the [events] weights.
class LandRoute {
  const LandRoute({
    required this.id,
    required this.name,
    this.nameFr = '',
    required this.from,
    required this.to,
    this.roads = const [],
    required this.days,
    this.biome = '',
    this.terrain = '',
    this.chapter = 1,
    this.events = const {},
    this.rulerOneIn = 0,
  });

  factory LandRoute.fromJson(String id, Map json) => LandRoute(
        id: id,
        name: json['name']?.toString() ?? id,
        nameFr: json['name_fr']?.toString() ?? '',
        from: json['from']?.toString() ?? '',
        to: json['to']?.toString() ?? '',
        roads: [...?(json['roads'] as List?)?.map((e) => e.toString())],
        days: (json['days'] as num?)?.toInt() ?? 1,
        biome: json['biome']?.toString() ?? '',
        terrain: json['terrain']?.toString() ?? '',
        chapter: (json['chapter'] as num?)?.toInt() ?? 1,
        events: {
          for (final MapEntry(:key, :value)
              in ((json['events'] as Map?) ?? const {}).entries)
            key.toString(): (value as num?)?.toInt() ?? 0,
        },
        rulerOneIn: (json['rulerOneIn'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String name;
  final String nameFr;
  final String from;
  final String to;
  final List<String> roads;
  final int days;
  final String biome;

  /// The scene kit the side view draws it with (one of [landTerrains]).
  final String terrain;
  final int chapter;
  final Map<String, int> events;

  /// One day in [rulerOneIn] meets the road's ruler (see [drawCrossing]);
  /// 0, never (the crash's and the ashlands' routes).
  final int rulerOneIn;

  String nameFor(bool fr) => fr && nameFr.isNotEmpty ? nameFr : name;

  /// This route meeting its ruler one day in [oneIn] (see [crossingRuler]).
  LandRoute withRulerOneIn(int oneIn) => LandRoute(
        id: id,
        name: name,
        nameFr: nameFr,
        from: from,
        to: to,
        roads: roads,
        days: days,
        biome: biome,
        terrain: terrain,
        chapter: chapter,
        events: events,
        rulerOneIn: oneIn,
      );
}

/// The side view's scene kits: what a route's `terrain` may be.
const List<String> landTerrains = [
  'desert',
  'mountain',
  'forest',
  'marsh',
  'snow',
  'ruins',
  'frost',
  'fen',
  'sea_cliffs',
];

/// [routes]' record [id] (land_routes.json), or null.
LandRoute? landRouteFor(Map<String, dynamic> routes, String id) {
  final record = routes[id];
  return record is Map ? LandRoute.fromJson(id, record) : null;
}

/// Every event of land_events.json's [records], by id.
Map<String, LandEvent> landEventsFrom(Map<String, dynamic> records) => {
      for (final MapEntry(:key, :value) in records.entries)
        if (value is Map) key: LandEvent.fromJson(key, value),
    };

/// The clan that holds the land [route] crosses, now (wave 16): the ruler
/// of the place it leads to, else of the place it leaves (a town's ruler
/// as townRulers reads it, its districts counted; any other place's
/// holder, clan_power.dart's holderOf), else the ruler of the country it
/// leads into, else of the one it leaves; '' for no one. It follows the
/// politics, so a road changes hands with the land around it.
String landRouteRuler(
    LandRoute route, Geography geography, PoliticsState politics) {
  final towns = townRulers(geography, politics, const {});
  final ends = [
    geography.placeOfLandmark(route.to)?.id,
    geography.placeOfLandmark(route.from)?.id,
  ];
  for (final id in ends) {
    final held = _endRuler(id, towns, geography, politics);
    if (held.isNotEmpty) return held;
  }
  for (final id in ends) {
    final ruler = geography.countryOf(id)?.ruler ?? '';
    if (ruler.isNotEmpty) return ruler;
  }
  return '';
}

/// Who holds one end of a route: its town's ruler, else its holder.
String _endRuler(String? id, Map<String, TownRuler> towns, Geography geography,
    PoliticsState politics) {
  if (id == null) return '';
  final town = towns[id]?.clanId ?? '';
  return town.isNotEmpty ? town : holderOf(id, geography, politics);
}

/// How often a clan road meets its clan (wave 18 step 2): one day in this
/// many, in place of its route's [LandRoute.rulerOneIn].
const int clanRoadOneIn = 2;

/// The clan whose road [route] is (wave 18 step 2): the one holding both
/// its ends (see [landRouteRuler]'s ends), '' for none.
String clanRoadOf(
    LandRoute route, Geography geography, PoliticsState politics) {
  final towns = townRulers(geography, politics, const {});
  final to = _endRuler(
      geography.placeOfLandmark(route.to)?.id, towns, geography, politics);
  final from = _endRuler(
      geography.placeOfLandmark(route.from)?.id, towns, geography, politics);
  return to.isNotEmpty && to == from ? to : '';
}

/// The band of a party at [tier] on a clan's own road: friendlier from
/// Friend, harder from Unfriendly down (wider than [rulerBandFor]).
RulerBand clanRoadBandFor(StandingTier tier) =>
    tier.isAtLeast(StandingTier.friend)
        ? RulerBand.friend
        : tier.isAtLeast(StandingTier.wary)
            ? RulerBand.neutral
            : RulerBand.hostile;

/// Who meets the party on [route] now, and how: its ruler
/// ([landRouteRuler]) at the band its standing puts it in, and the route
/// as crossed. On a clan's road ([clanRoadOf]) the ruler comes one day in
/// [clanRoadOneIn] and its bands are [clanRoadBandFor]'s; a route that
/// never meets its ruler ([LandRoute.rulerOneIn] 0) still never does.
({LandRoute route, String clanId, RulerBand band, bool clanRoad}) crossingRuler(
    LandRoute route,
    Geography geography,
    PoliticsState politics,
    ClanData data) {
  final clanId = landRouteRuler(route, geography, politics);
  final tier = politics.tierOf(clanId, data);
  final own = route.rulerOneIn > 0 &&
      clanId.isNotEmpty &&
      clanRoadOf(route, geography, politics) == clanId;
  return (
    route: own ? route.withRulerOneIn(clanRoadOneIn) : route,
    clanId: clanId,
    band: own ? clanRoadBandFor(tier) : rulerBandFor(tier),
    clanRoad: own,
  );
}

/// The events of [events] a road's [ruler] meets the party with at
/// [band], in file order: none for '' or a clan with no events on file.
List<String> rulerPool(
        Map<String, LandEvent> events, String ruler, RulerBand band) =>
    [
      if (ruler.isNotEmpty)
        for (final e in events.values)
          if (e.ruler == ruler && e.band == band) e.id,
    ];

/// A crossing's events, one a day: drawn by [route]'s weights among the
/// [known] events, never the same one two days running (when the route
/// has another). With a [rulers] pool (see [rulerPool]) and a route that
/// meets its ruler ([LandRoute.rulerOneIn]), a day is the ruler's one
/// time in [LandRoute.rulerOneIn], each of its events once at most. An
/// event the route names that is not [known] is never drawn: a route
/// whose events are all missing meets only its ruler, or nothing.
List<String> drawCrossing(LandRoute route, Iterable<String> known,
    {required Random random, List<String> rulers = const []}) {
  final pool = {
    for (final MapEntry(:key, :value) in route.events.entries)
      if (value > 0 && known.contains(key)) key: value,
  };
  final rulersLeft = [
    if (route.rulerOneIn > 0)
      for (final id in rulers)
        if (known.contains(id) && !pool.containsKey(id)) id,
  ];
  if (pool.isEmpty && rulersLeft.isEmpty) return const [];
  final drawn = <String>[];
  for (var day = 0; day < route.days; day++) {
    if (rulersLeft.isNotEmpty &&
        (pool.isEmpty || random.nextInt(route.rulerOneIn) == 0)) {
      drawn.add(rulersLeft.removeAt(random.nextInt(rulersLeft.length)));
      continue;
    }
    if (pool.isEmpty) break;
    final options = {
      for (final MapEntry(:key, :value) in pool.entries)
        if (pool.length == 1 || drawn.isEmpty || drawn.last != key) key: value,
    };
    final total = options.values.fold<int>(0, (a, b) => a + b);
    var roll = random.nextInt(total);
    for (final MapEntry(:key, :value) in options.entries) {
      roll -= value;
      if (roll < 0) {
        drawn.add(key);
        break;
      }
    }
  }
  return drawn;
}

/// A crossing's check in [chapter]: the event's [dc], one harder a
/// chapter after the first.
int landCheckDc(int dc, int chapter) => dc + max(0, chapter - 1);

/// The most of the party's health it is carried back with when a
/// crossing fails: wounded, never better off than when it set out.
const double _turnBackHealthShare = 0.5;

/// The least it is carried back with, whatever it set out with: enough to
/// set out again and, as the simulator measures it (nearly every party
/// crosses from a fifth of its health), not to be stuck at the start.
const double _turnBackHealthFloor = 0.25;

/// The health a party of [maxHealth] that set out with [departureHealth]
/// is carried back with: what it set out with, at most half, at least a
/// quarter (v1.287.0: a failed crossing was a free rest for a party that
/// set out below half).
int turnBackHealth(int maxHealth, {required int departureHealth}) {
  final most = (maxHealth * _turnBackHealthShare).round();
  final least = max(1, (maxHealth * _turnBackHealthFloor).round());
  return max(least, min(departureHealth, most));
}

/// Where a crossing's step leaves the party: its [health] after [change],
/// or [failed] when that runs it out (the crossing is lost).
({int health, bool failed}) afterLandStep(
    {required int health, required int maxHealth, required int change}) {
  final next = health + change;
  if (next <= 0) return (health: 0, failed: true);
  return (health: min(maxHealth, next), failed: false);
}

/// The choice a headless walk takes ("Play to chapter", the playthrough
/// simulator): the most health expected, a check counted at its chance
/// (see ability_check.dart's checkChance), gold breaking ties; a choice
/// that costs gold the purse lacks is never taken, nor a fight (a walk
/// with no player does not stop for the battle screen) while there is
/// another way. [modifierFor] gives the party's bonus for an ability.
LandChoice pickLandChoice(
  LandEvent event, {
  required int Function(String ability) modifierFor,
  required int gold,
  required int chapter,
}) {
  double chanceOf(LandChoice c) {
    final dc = landCheckDc(c.dc, chapter);
    return ((21 - (dc - modifierFor(c.check!))).clamp(0, 20)) / 20;
  }

  (double, double) valueOf(LandChoice c) {
    // Only ever weighed when nothing else is open: counted as broken off.
    if (c.isFight) return (c.fail.healthPct.toDouble(), c.fail.gold.toDouble());
    if (!c.hasCheck) {
      return (c.outcome.healthPct.toDouble(), c.outcome.gold.toDouble());
    }
    final p = chanceOf(c);
    return (
      p * c.success.healthPct + (1 - p) * c.fail.healthPct,
      p * c.success.gold + (1 - p) * c.fail.gold,
    );
  }

  final open = [
    for (final c in event.choices)
      if (c.goldCost <= gold && !c.isFight) c
  ];
  final options = open.isEmpty ? event.choices : open;
  var best = options.first;
  for (final c in options.skip(1)) {
    final (health, coin) = valueOf(c);
    final (bestHealth, bestCoin) = valueOf(best);
    if (health > bestHealth || (health == bestHealth && coin > bestCoin)) {
      best = c;
    }
  }
  return best;
}

/// How a headless crossing went (see [resolveCrossing]).
class CrossingResult {
  const CrossingResult({
    required this.arrived,
    required this.health,
    required this.gold,
    required this.days,
    required this.events,
  });

  /// Whether the party reached the far side; else it is carried back.
  final bool arrived;

  /// The party's health at the end: what is left on arrival, or
  /// [turnBackHealth] when carried back.
  final int health;

  /// The gold won (or paid) on the way, signed.
  final int gold;

  /// The days the crossing took, extra ones included.
  final int days;

  /// The events met, in order.
  final List<String> events;
}

/// Plays [route] through without a player: each day's event by
/// [pickLandChoice], each check rolled with [random] (a d20 plus
/// [modifierFor]'s bonus against [landCheckDc]); [rulers], the road's
/// ruler's events (see [drawCrossing]).
CrossingResult resolveCrossing(
  LandRoute route,
  Map<String, LandEvent> events, {
  required int health,
  required int maxHealth,
  required int gold,
  required int Function(String ability) modifierFor,
  required Random random,
  int? chapter,
  List<String> rulers = const [],
}) {
  final inChapter = chapter ?? route.chapter;
  final drawn =
      drawCrossing(route, events.keys, random: random, rulers: rulers);
  var hp = health;
  var coin = 0;
  var days = 0;
  final met = <String>[];
  for (final id in drawn) {
    final event = events[id]!;
    met.add(id);
    days++;
    if (event.choices.isEmpty) continue;
    final choice = pickLandChoice(event,
        modifierFor: modifierFor, gold: gold + coin, chapter: inChapter);
    final outcome = choice.isFight
        ? choice.fail
        : !choice.hasCheck
            ? choice.outcome
            : checkPasses(random.nextInt(20) + 1, modifierFor(choice.check!),
                    landCheckDc(choice.dc, inChapter))
                ? choice.success
                : choice.fail;
    coin += outcome.gold;
    days += outcome.days;
    final step = afterLandStep(
        health: hp,
        maxHealth: maxHealth,
        change: outcome.healthChange(maxHealth));
    if (step.failed) {
      return CrossingResult(
          arrived: false,
          health: turnBackHealth(maxHealth, departureHealth: health),
          gold: coin,
          days: days,
          events: met);
    }
    hp = step.health;
  }
  return CrossingResult(
      arrived: true, health: hp, gold: coin, days: days, events: met);
}
