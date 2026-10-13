/// Land expeditions (v1.285.0, docs/proposals/land-expeditions.md): a long
/// land route played like a voyage. A short chain of events is drawn at
/// departure (land_routes.json), each asks what the party does
/// (land_events.json), and the party's health plays the hull: when it runs
/// out, the crossing fails and the party is carried back to where it set
/// out, alive but wounded. No water, no food, no save field: a crossing is
/// played in one sitting, like a voyage.
library;

import 'dart:math';

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

/// One way through a crossing's event: a sure [outcome], or an ability
/// [check] against [dc] (see [landCheckDc]) with a [success] and a [fail].
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

  bool get hasCheck => check != null;

  String textFor(bool fr) => fr && textFr.isNotEmpty ? textFr : text;

  /// The gold the choice asks for up front (a purse thrown to raiders):
  /// not made on credit.
  int get goldCost => !hasCheck && outcome.gold < 0 ? -outcome.gold : 0;
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
      );

  final String id;
  final String name;
  final String nameFr;
  final String text;
  final String textFr;
  final List<LandChoice> choices;

  String nameFor(bool fr) => fr && nameFr.isNotEmpty ? nameFr : name;
  String textFor(bool fr) => fr && textFr.isNotEmpty ? textFr : text;
}

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

  String nameFor(bool fr) => fr && nameFr.isNotEmpty ? nameFr : name;
}

/// The side view's scene kits: what a route's `terrain` may be.
const List<String> landTerrains = [
  'desert',
  'mountain',
  'forest',
  'marsh',
  'snow',
  'ruins',
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

/// A crossing's events, one a day: drawn by [route]'s weights among the
/// [known] events, never the same one two days running (when the route
/// has another).
List<String> drawCrossing(LandRoute route, Iterable<String> known,
    {required Random random}) {
  final pool = {
    for (final MapEntry(:key, :value) in route.events.entries)
      if (value > 0 && known.contains(key)) key: value,
  };
  if (pool.isEmpty) return const [];
  final drawn = <String>[];
  for (var day = 0; day < route.days; day++) {
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

/// The share of the party's health it is carried back with when a
/// crossing fails: wounded, but able to set out again.
const double turnBackHealthShare = 0.5;

/// The health a party of [maxHealth] is carried back with.
int turnBackHealth(int maxHealth) =>
    max(1, (maxHealth * turnBackHealthShare).round());

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
/// that costs gold the purse lacks is never taken. [modifierFor] gives the
/// party's bonus for an ability.
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
      if (c.goldCost <= gold) c
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
/// [modifierFor]'s bonus against [landCheckDc]).
CrossingResult resolveCrossing(
  LandRoute route,
  Map<String, LandEvent> events, {
  required int health,
  required int maxHealth,
  required int gold,
  required int Function(String ability) modifierFor,
  required Random random,
  int? chapter,
}) {
  final inChapter = chapter ?? route.chapter;
  final drawn = drawCrossing(route, events.keys, random: random);
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
    final outcome = !choice.hasCheck
        ? choice.outcome
        : random.nextInt(20) + 1 + modifierFor(choice.check!) >=
                landCheckDc(choice.dc, inChapter)
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
          health: turnBackHealth(maxHealth),
          gold: coin,
          days: days,
          events: met);
    }
    hp = step.health;
  }
  return CrossingResult(
      arrived: true, health: hp, gold: coin, days: days, events: met);
}
