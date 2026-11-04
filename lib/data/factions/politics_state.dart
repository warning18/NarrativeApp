part of '../factions.dart';

// PoliticsState: where the character stands with the coast, as the
// session keeps it.

class PoliticsState {
  const PoliticsState({
    this.standings = const {},
    this.marks = const {},
    this.swornFactionId = '',
    this.relationSteps = const {},
    this.relationSnapshots = const {},
    this.standingLog = const [],
    this.relationsLog = const [],
    this.appliedKeys = const [],
    this.firedEvents = const {},
    this.news = const [],
    this.claim = '',
    this.throneWinner = '',
    this.pledged = const [],
    this.host = Host.none,
    this.power = const {},
    this.powerAtTurn = const {},
    this.control = const {},
    this.influence = const {},
    this.helped = const [],
    this.fallen = const [],
    this.nemesis = '',
    this.nemesisReason = '',
    this.nemesisCooldown = const {},
    this.crisis = const {},
    this.sieges = const {},
    this.fellTo = const {},
    this.fallenOf = '',
    this.fallenWinner = '',
  });

  static const PoliticsState empty = PoliticsState();

  /// The coast as a new game opens: the Dominion your nemesis, a story
  /// fact (it wants the piece of the Shroud your family kept), not a
  /// standing earned (nemesis.dart).
  static const PoliticsState storyStart = PoliticsState(
      nemesis: storyNemesisClan, nemesisReason: nemesisReasonStory);

  /// Each main clan's power (0..100, clan_power.dart) once it has moved;
  /// a clan not here stands at its `startPower`.
  final Map<String, int> power;

  /// Each clan's power as the last chapter's turn began (territoryTurn,
  /// clan_power.dart): what the clan power sign's arrow compares with
  /// (clanPowerRanking). Empty before the first turn.
  final Map<String, int> powerAtTurn;

  /// The places that changed hands (place id -> clan), over the holders
  /// geography.json writes (see holderOf in clan_power.dart).
  final Map<String, String> control;

  /// Each clan's influence in a district (wave 18, district_influence.dart):
  /// district id -> clan -> 0..100. A district is here only once its
  /// influence moved; before, its holder stands at holderStartInfluence and
  /// every other clan at 0.
  final Map<String, Map<String, int>> influence;

  /// The main clans the character did something for this chapter (a gift
  /// taken, a quest, a fight in their lands): spared the chapter's neglect.
  final List<String> helped;

  /// The clans that lost their last place (clan_power.dart), until one
  /// takes a place again.
  final List<String> fallen;

  /// The clan that has made the character its nemesis (nemesis.dart), ''
  /// for none.
  final String nemesis;

  /// Why [nemesis] hunts the character: [nemesisReasonStory] for the
  /// story's own enemy (the Dominion as a game opens), '' for one earned
  /// by standing.
  final String nemesisReason;

  /// Whether [nemesis] is the story's own enemy ([nemesisReasonStory]).
  bool get isStoryNemesis =>
      nemesis.isNotEmpty && nemesisReason == nemesisReasonStory;

  /// Clans whose nemesis was broken: the chapter from which each may
  /// become one again.
  final Map<String, int> nemesisCooldown;

  /// Your clan's seat threatened (clan_crisis.dart): `clan`, `attacker`,
  /// `place`; empty for none.
  final Map<String, String> crisis;

  /// The districts under siege (district_attacks.dart): district id ->
  /// `attacker`, `holder`, `city`, `until` (the day it runs out) and `met`
  /// (the party stood aside).
  final Map<String, Map<String, String>> sieges;

  /// Each fallen clan's last place taker (clan -> clan).
  final Map<String, String> fellTo;

  /// The fallen clan the character stayed of (clan_crisis.dart): no oath,
  /// no patron, until a banner of their own; '' for none.
  final String fallenOf;

  /// Who took it: the character's nemesis while [fallenOf] lasts.
  final String fallenWinner;

  final Map<String, double> standings;
  final Map<String, SubclanMark> marks;
  final String swornFactionId;
  final Map<String, int> relationSteps;
  final Map<int, Map<String, int>> relationSnapshots;
  final List<StandingLogEntry> standingLog;
  final List<RelationLogEntry> relationsLog;

  /// The keys of the story politics applied (`story:<node>:choice<i>`,
  /// `story:<node>:enter`), in order.
  final List<String> appliedKeys;

  /// Each politics event that has fired, by id.
  final Map<String, FiredEvent> firedEvents;

  /// "News from the coast": what the events told, oldest first.
  final List<CoastNews> news;

  /// The faction the character heads (rung 2 of the climb, see
  /// throne.dart), '' for none: one at a time.
  final String claim;

  /// The faction on the Lantern Throne, '' while it is empty.
  final String throneWinner;

  /// The factions pledged to the character's cause, in the order they
  /// pledged: they join the Host whatever their standing.
  final List<String> pledged;

  /// The Host as it mustered ([Host.none] before).
  final Host host;

  bool get isEmpty =>
      standings.isEmpty &&
      marks.isEmpty &&
      swornFactionId.isEmpty &&
      relationSteps.isEmpty &&
      relationSnapshots.isEmpty &&
      standingLog.isEmpty &&
      relationsLog.isEmpty &&
      appliedKeys.isEmpty &&
      firedEvents.isEmpty &&
      news.isEmpty &&
      claim.isEmpty &&
      throneWinner.isEmpty &&
      pledged.isEmpty &&
      !host.mustered;

  /// Whether [factionId] has pledged to the cause.
  bool hasPledged(String factionId) => pledged.contains(factionId);

  /// Whether the story politics under [key] were applied.
  bool applied(String key) => appliedKeys.contains(key);

  /// Whether politics event [eventId] has fired.
  bool hasFired(String eventId) => firedEvents.containsKey(eventId);

  /// The news the camp has not shown yet, oldest first.
  List<CoastNews> get unreadNews => [
        for (final n in news)
          if (!n.read) n,
      ];

  /// Standing with [factionId]: its own, or where [data] says it starts.
  double standingOf(String factionId, ClanData data) =>
      standings[factionId] ?? data.startStandingOf(factionId).toDouble();

  /// The tier of [standingOf].
  StandingTier tierOf(String factionId, ClanData data) =>
      standingTierFor(standingOf(factionId, data));

  bool isSworn(String factionId) =>
      swornFactionId.isNotEmpty && swornFactionId == factionId;

  /// [subclanId]'s mark on the character.
  SubclanMark markOf(String subclanId) => marks[subclanId] ?? SubclanMark.none;

  /// The step [a] and [b] stand on now: moved, or as the story opens;
  /// null for a pair the data doesn't relate (a tribe, the Choir...).
  int? relationStep(String a, String b, ClanData data) {
    final key = relationKey(a, b);
    return relationSteps[key] ?? data.relations.baseSteps[key];
  }

  PoliticsState copyWith({
    Map<String, double>? standings,
    Map<String, SubclanMark>? marks,
    String? swornFactionId,
    Map<String, int>? relationSteps,
    Map<int, Map<String, int>>? relationSnapshots,
    List<StandingLogEntry>? standingLog,
    List<RelationLogEntry>? relationsLog,
    List<String>? appliedKeys,
    Map<String, FiredEvent>? firedEvents,
    List<CoastNews>? news,
    String? claim,
    String? throneWinner,
    List<String>? pledged,
    Host? host,
    Map<String, int>? power,
    Map<String, int>? powerAtTurn,
    Map<String, String>? control,
    Map<String, Map<String, int>>? influence,
    List<String>? helped,
    List<String>? fallen,
    String? nemesis,
    String? nemesisReason,
    Map<String, int>? nemesisCooldown,
    Map<String, String>? crisis,
    Map<String, Map<String, String>>? sieges,
    Map<String, String>? fellTo,
    String? fallenOf,
    String? fallenWinner,
  }) =>
      PoliticsState(
        standings: standings ?? this.standings,
        marks: marks ?? this.marks,
        swornFactionId: swornFactionId ?? this.swornFactionId,
        relationSteps: relationSteps ?? this.relationSteps,
        relationSnapshots: relationSnapshots ?? this.relationSnapshots,
        standingLog: standingLog ?? this.standingLog,
        relationsLog: relationsLog ?? this.relationsLog,
        appliedKeys: appliedKeys ?? this.appliedKeys,
        firedEvents: firedEvents ?? this.firedEvents,
        news: news ?? this.news,
        claim: claim ?? this.claim,
        throneWinner: throneWinner ?? this.throneWinner,
        pledged: pledged ?? this.pledged,
        host: host ?? this.host,
        power: power ?? this.power,
        powerAtTurn: powerAtTurn ?? this.powerAtTurn,
        control: control ?? this.control,
        influence: influence ?? this.influence,
        helped: helped ?? this.helped,
        fallen: fallen ?? this.fallen,
        nemesis: nemesis ?? this.nemesis,
        // A new nemesis is an earned one unless told otherwise.
        nemesisReason: nemesisReason ??
            (nemesis == null || nemesis == this.nemesis
                ? this.nemesisReason
                : ''),
        nemesisCooldown: nemesisCooldown ?? this.nemesisCooldown,
        crisis: crisis ?? this.crisis,
        sieges: sieges ?? this.sieges,
        fellTo: fellTo ?? this.fellTo,
        fallenOf: fallenOf ?? this.fallenOf,
        fallenWinner: fallenWinner ?? this.fallenWinner,
      );

  Map<String, dynamic> toJson() => {
        'standings': standings,
        'marks': {for (final e in marks.entries) e.key: e.value.name},
        'sworn': swornFactionId,
        'relations': relationSteps,
        'snapshots': {
          for (final e in relationSnapshots.entries) '${e.key}': e.value,
        },
        'log': [for (final e in standingLog) e.toJson()],
        'relationsLog': [for (final e in relationsLog) e.toJson()],
        if (appliedKeys.isNotEmpty) 'applied': appliedKeys,
        if (firedEvents.isNotEmpty)
          'fired': {
            for (final e in firedEvents.entries) e.key: e.value.toJson(),
          },
        if (news.isNotEmpty) 'news': [for (final n in news) n.toJson()],
        if (claim.isNotEmpty) 'claim': claim,
        if (throneWinner.isNotEmpty) 'throne': throneWinner,
        if (pledged.isNotEmpty) 'pledged': pledged,
        if (host.mustered) 'host': host.toJson(),
        if (power.isNotEmpty) 'power': power,
        if (powerAtTurn.isNotEmpty) 'powerAtTurn': powerAtTurn,
        if (control.isNotEmpty) 'control': control,
        if (influence.isNotEmpty) 'influence': influence,
        if (helped.isNotEmpty) 'helped': helped,
        if (fallen.isNotEmpty) 'fallen': fallen,
        if (nemesis.isNotEmpty) 'nemesis': nemesis,
        // Always written: a save without it predates the story's nemesis
        // (see [PoliticsState.fromJson]).
        'nemesisReason': nemesisReason,
        if (nemesisCooldown.isNotEmpty) 'nemesisCooldown': nemesisCooldown,
        if (crisis.isNotEmpty) 'crisis': crisis,
        if (sieges.isNotEmpty) 'sieges': sieges,
        if (fellTo.isNotEmpty) 'fellTo': fellTo,
        if (fallenOf.isNotEmpty) 'fallenOf': fallenOf,
        if (fallenWinner.isNotEmpty) 'fallenWinner': fallenWinner,
      };

  /// [raw] read; [empty] for a save from before clans (or anything
  /// unreadable).
  factory PoliticsState.fromJson(Object? raw) {
    if (raw is! Map) return storyStart;
    final json = raw.cast<String, dynamic>();
    final marks = <String, SubclanMark>{};
    final rawMarks = json['marks'];
    if (rawMarks is Map) {
      for (final e in rawMarks.entries) {
        final mark = subclanMarkNamed(e.value?.toString());
        if (mark != null && mark != SubclanMark.none) {
          marks[e.key.toString()] = mark;
        }
      }
    }
    final snapshots = <int, Map<String, int>>{};
    final rawSnapshots = json['snapshots'];
    if (rawSnapshots is Map) {
      for (final e in rawSnapshots.entries) {
        final chapter = int.tryParse(e.key.toString());
        if (chapter != null) snapshots[chapter] = _ints(e.value);
      }
    }
    final state = PoliticsState(
      standings: _doubles(json['standings']),
      marks: marks,
      swornFactionId: _text(json['sworn']),
      relationSteps: _ints(json['relations']),
      relationSnapshots: snapshots,
      standingLog: [
        for (final e in (json['log'] as List?) ?? const [])
          if (e is Map) StandingLogEntry.fromJson(e.cast<String, dynamic>()),
      ],
      relationsLog: [
        for (final e in (json['relationsLog'] as List?) ?? const [])
          if (e is Map) RelationLogEntry.fromJson(e.cast<String, dynamic>()),
      ],
      appliedKeys: _strings(json['applied']),
      firedEvents: {
        if (json['fired'] is Map)
          for (final e in (json['fired'] as Map).entries)
            if (e.value is Map)
              e.key.toString():
                  FiredEvent.fromJson((e.value as Map).cast<String, dynamic>()),
      },
      news: [
        for (final n in (json['news'] as List?) ?? const [])
          if (n is Map) CoastNews.fromJson(n.cast<String, dynamic>()),
      ],
      claim: _text(json['claim']).trim(),
      throneWinner: _text(json['throne']).trim(),
      pledged: _strings(json['pledged']).toSet().toList(),
      host: Host.fromJson(json['host']),
      power: _ints(json['power']),
      powerAtTurn: _ints(json['powerAtTurn']),
      control: {
        if (json['control'] is Map)
          for (final e in (json['control'] as Map).entries)
            if (_text(e.value).trim().isNotEmpty)
              e.key.toString(): _text(e.value).trim(),
      },
      influence: {
        if (json['influence'] is Map)
          for (final e in (json['influence'] as Map).entries)
            if (e.value is Map) e.key.toString(): _ints(e.value),
      },
      helped: _strings(json['helped']).toSet().toList(),
      fallen: _strings(json['fallen']).toSet().toList(),
      nemesis: _text(json['nemesis']).trim(),
      nemesisReason: _text(json['nemesisReason']).trim(),
      nemesisCooldown: _ints(json['nemesisCooldown']),
      crisis: _texts(json['crisis']),
      sieges: {
        if (json['sieges'] is Map)
          for (final e in (json['sieges'] as Map).entries)
            if (e.value is Map) e.key.toString(): _texts(e.value),
      },
      fellTo: _texts(json['fellTo']),
      fallenOf: _text(json['fallenOf']).trim(),
      fallenWinner: _text(json['fallenWinner']).trim(),
    );
    // A save from before the story's nemesis (no `nemesisReason`): the
    // Dominion takes the place it holds in a new game, unless the
    // character is already Friendly with it, or it is out of the way.
    if (json.containsKey('nemesisReason') ||
        state.nemesis.isNotEmpty ||
        state.fallen.contains(storyNemesisClan) ||
        state.nemesisCooldown.containsKey(storyNemesisClan) ||
        (state.standings[storyNemesisClan] ?? 0) >=
            standingTiers[StandingTier.friendly]!.min) {
      return state;
    }
    return state.copyWith(
        nemesis: storyNemesisClan, nemesisReason: nemesisReasonStory);
  }
}
