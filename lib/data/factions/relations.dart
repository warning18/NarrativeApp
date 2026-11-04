part of '../factions.dart';

// The relations data (relations.json): the seven-step scale, the
// opening pair steps and the history behind them.

class RelationStep {
  const RelationStep({
    required this.step,
    required this.name,
    this.nameFr = '',
    this.color = 0xFFA8A194,
  });

  final int step;
  final String name;
  final String nameFr;

  /// ARGB.
  final int color;

  String nameFor(AppLanguage language) => _pick(language, name, nameFr);

  factory RelationStep.fromJson(Map<String, dynamic> json) => RelationStep(
        step: _int(json['step']).clamp(minRelationStep, maxRelationStep),
        name: _text(json['name']),
        nameFr: _text(json['name_fr']),
        color: parsePatronColor(json['color']),
      );
}

/// Where two factions stand with each other when the story opens, and
/// why (relations.json `pairs`).
class RelationPair {
  const RelationPair({
    required this.a,
    required this.b,
    required this.step,
    this.reason = '',
    this.reasonFr = '',
  });

  final String a;
  final String b;
  final int step;
  final String reason;
  final String reasonFr;

  String get key => relationKey(a, b);
  String reasonFor(AppLanguage language) => _pick(language, reason, reasonFr);

  factory RelationPair.fromJson(Map<String, dynamic> json) => RelationPair(
        a: _text(json['a']).trim(),
        b: _text(json['b']).trim(),
        step: _int(json['step'], 4).clamp(minRelationStep, maxRelationStep),
        reason: _text(json['reason']),
        reasonFr: _text(json['reason_fr']),
      );
}

/// One event of the coast's history (relations.json `history`).
class HistoryEvent {
  const HistoryEvent({
    required this.year,
    this.yearFr = '',
    required this.name,
    this.nameFr = '',
    this.text = '',
    this.textFr = '',
  });

  final String year;
  final String yearFr;
  final String name;
  final String nameFr;
  final String text;
  final String textFr;

  String yearFor(AppLanguage language) => _pick(language, year, yearFr);
  String nameFor(AppLanguage language) => _pick(language, name, nameFr);
  String textFor(AppLanguage language) => _pick(language, text, textFr);

  factory HistoryEvent.fromJson(Map<String, dynamic> json) => HistoryEvent(
        year: _text(json['year']),
        yearFr: _text(json['year_fr']),
        name: _text(json['name']),
        nameFr: _text(json['name_fr']),
        text: _text(json['text']),
        textFr: _text(json['text_fr']),
      );
}

/// The key a pair of factions is kept under, whichever way round:
/// 'compact|dominion'.
String relationKey(String a, String b) =>
    a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';

/// relations.json: the seven steps, the pairs as the story opens, and the
/// history behind them.
class Relations {
  const Relations({
    this.steps = const [],
    this.pairs = const [],
    this.history = const [],
  });

  static const Relations empty = Relations();

  final List<RelationStep> steps;
  final List<RelationPair> pairs;
  final List<HistoryEvent> history;

  /// [step]'s record, if the data has it.
  RelationStep? stepInfo(int step) =>
      steps.where((s) => s.step == step).firstOrNull;

  /// The pair of [a] and [b] as the story opens, if they have one.
  RelationPair? pair(String a, String b) {
    final key = relationKey(a, b);
    return pairs.where((p) => p.key == key).firstOrNull;
  }

  /// The step every pair starts on, by [relationKey].
  Map<String, int> get baseSteps => {for (final p in pairs) p.key: p.step};

  factory Relations.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> maps(Object? raw) => [
          for (final e in (raw is List ? raw : const []))
            if (e is Map) e.cast<String, dynamic>(),
        ];
    return Relations(
      steps: [for (final s in maps(json['steps'])) RelationStep.fromJson(s)]
        ..sort((x, y) => x.step.compareTo(y.step)),
      pairs: [
        for (final p in maps(json['pairs']))
          if (_text(p['a']).isNotEmpty && _text(p['b']).isNotEmpty)
            RelationPair.fromJson(p),
      ],
      history: [
        for (final h in maps(json['history'])) HistoryEvent.fromJson(h)
      ],
    );
  }
}

/// A title (titles.json): a name the character wears, from a faction's
/// offer, a tier reached, a mark, a quest or an intrigue ([source]).
