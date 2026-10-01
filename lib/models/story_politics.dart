/// The politics a story choice carries, or a scene on entry (v1.195):
/// what taking it does to the coast. Pure, like the rest of the story
/// model: the graph-integrity tooling reads it too, so it never imports
/// gameplay code; the rules that apply it live in
/// lib/data/politics_events.dart.
///
/// Written in the story file (and, as an event variant's `effects`, in
/// politics_events.json) as:
/// ```json
/// "politics": {
///   "standing":    {"vigil": 5, "dominion": -5},
///   "marks":       {"inquisition": "foe", "wickwardens": "friend"},
///   "relations":   [{"a": "mire", "b": "penitents", "steps": 1}],
///   "offerFrom":   "penitents",
///   "intrigue":    {"id": "hooded_lantern", "stage": 2},
///   "remembrance": 3,
///   "event":       "lantern_bearer_dies",
///   "flags":       ["dominion_split"],
///   "hidden":      true
/// }
/// ```
/// `intrigue` takes `"outcome": <index>` instead of `stage` to settle the
/// intrigue; it may also be a list of such steps, and `event` a list of
/// ids. Keys this version does not know are kept as they were, so a later
/// version's politics survive the editor.
class StoryPolitics {
  const StoryPolitics({
    this.standing = const {},
    this.marks = const {},
    this.relations = const [],
    this.offerFrom = '',
    this.intrigues = const [],
    this.remembrance = 0,
    this.events = const [],
    this.flags = const [],
    this.hidden = false,
    this.extra = const {},
  });

  /// Standing moved with each faction (through the ripple), in the order
  /// written.
  final Map<String, num> standing;

  /// Each sub-clan's new mark on the character: `friend`, `foe` or
  /// `none`.
  final Map<String, String> marks;

  /// Pairs of clans moved along the relations scale.
  final List<RelationShiftSpec> relations;

  /// A faction that brings an offer now, guaranteed a place in it.
  final String offerFrom;

  /// Intrigue stages reached, or outcomes settled.
  final List<IntrigueStep> intrigues;

  /// The Open Hand's remembrance stage reached (1..6), 0 for none: sets
  /// the flags `open_hand_1` up to `open_hand_<n>`.
  final int remembrance;

  /// Politics events (politics_events.json) fired now.
  final List<String> events;

  /// Story flags set (what an event's effects need most: "the Dominion
  /// splits").
  final List<String> flags;

  /// The consequences are not hinted on the choice.
  final bool hidden;

  /// Keys this version does not read, kept as written.
  final Map<String, dynamic> extra;

  static const Set<String> _known = {
    'standing',
    'marks',
    'relations',
    'offerFrom',
    'intrigue',
    'remembrance',
    'event',
    'flags',
    'flagsToAdd',
    'setFlags',
    'hidden',
  };

  /// The first intrigue step, if any (most politics carry one).
  IntrigueStep? get intrigue => intrigues.isEmpty ? null : intrigues.first;

  /// The first event fired, '' for none.
  String get event => events.isEmpty ? '' : events.first;

  /// Whether it does nothing at all.
  bool get isEmpty =>
      standing.isEmpty &&
      marks.isEmpty &&
      relations.isEmpty &&
      offerFrom.isEmpty &&
      intrigues.isEmpty &&
      remembrance <= 0 &&
      events.isEmpty &&
      flags.isEmpty;

  /// Whether a choice's hint has anything to say (standing or marks).
  bool get hasHint => !hidden && (standing.isNotEmpty || marks.isNotEmpty);

  static String _text(Object? raw) => raw?.toString().trim() ?? '';

  static List<String> _strings(Object? raw) {
    if (raw is String) return raw.trim().isEmpty ? const [] : [raw.trim()];
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
    ];
  }

  static int _int(Object? raw) {
    if (raw is num) return raw.round();
    if (raw is String) return int.tryParse(raw.trim()) ?? 0;
    return 0;
  }

  /// [raw] read; null when it is no map, or says nothing this version can
  /// act on and keeps nothing else.
  static StoryPolitics? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.cast<String, dynamic>();
    final standing = <String, num>{};
    final rawStanding = json['standing'];
    if (rawStanding is Map) {
      for (final e in rawStanding.entries) {
        final value = e.value is num
            ? e.value as num
            : num.tryParse(e.value?.toString() ?? '');
        if (value != null && value != 0) standing[e.key.toString()] = value;
      }
    }
    final marks = <String, String>{};
    final rawMarks = json['marks'];
    if (rawMarks is Map) {
      for (final e in rawMarks.entries) {
        final mark = _text(e.value);
        if (mark.isNotEmpty) marks[e.key.toString()] = mark;
      }
    }
    final relations = [
      for (final r
          in (json['relations'] is List ? json['relations'] : const []))
        if (RelationShiftSpec.tryParse(r) case final shift?) shift,
    ];
    final rawIntrigue = json['intrigue'];
    final intrigues = [
      for (final i in rawIntrigue is List ? rawIntrigue : [rawIntrigue])
        if (IntrigueStep.tryParse(i) case final step?) step,
    ];
    final politics = StoryPolitics(
      standing: standing,
      marks: marks,
      relations: relations,
      offerFrom: _text(json['offerFrom']),
      intrigues: intrigues,
      remembrance: _int(json['remembrance']).clamp(0, 6),
      events: _strings(json['event']),
      flags: [
        ..._strings(json['flags']),
        ..._strings(json['flagsToAdd']),
        ..._strings(json['setFlags']),
      ],
      hidden: json['hidden'] == true,
      extra: {
        for (final e in json.entries)
          if (!_known.contains(e.key)) e.key: e.value,
      },
    );
    return politics.isEmpty && politics.extra.isEmpty && !politics.hidden
        ? null
        : politics;
  }

  Map<String, dynamic> toJson() => {
        if (standing.isNotEmpty) 'standing': Map<String, num>.of(standing),
        if (marks.isNotEmpty) 'marks': Map<String, String>.of(marks),
        if (relations.isNotEmpty)
          'relations': [for (final r in relations) r.toJson()],
        if (offerFrom.isNotEmpty) 'offerFrom': offerFrom,
        if (intrigues.length == 1) 'intrigue': intrigues.single.toJson(),
        if (intrigues.length > 1)
          'intrigue': [for (final i in intrigues) i.toJson()],
        if (remembrance > 0) 'remembrance': remembrance,
        if (events.length == 1) 'event': events.single,
        if (events.length > 1) 'event': List<String>.of(events),
        if (flags.isNotEmpty) 'flags': List<String>.of(flags),
        if (hidden) 'hidden': true,
        ...extra,
      };
}

/// Two clans moved [steps] along the relations scale (negative: towards
/// Blood feud).
class RelationShiftSpec {
  const RelationShiftSpec({
    required this.a,
    required this.b,
    required this.steps,
  });

  final String a;
  final String b;
  final int steps;

  static RelationShiftSpec? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final a = raw['a']?.toString().trim() ?? '';
    final b = raw['b']?.toString().trim() ?? '';
    final steps = StoryPolitics._int(
        raw['steps'] ?? raw['step'] ?? raw['delta'] ?? raw['by']);
    if (a.isEmpty || b.isEmpty || steps == 0) return null;
    return RelationShiftSpec(a: a, b: b, steps: steps);
  }

  Map<String, dynamic> toJson() => {'a': a, 'b': b, 'steps': steps};
}

/// An intrigue ([id], intrigues.json) reaching [stage] (1 Clue .. 6
/// Choice), or settling on [outcome] (its index in the record).
class IntrigueStep {
  const IntrigueStep({required this.id, this.stage, this.outcome});

  final String id;
  final int? stage;
  final int? outcome;

  static IntrigueStep? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id']?.toString().trim() ?? '';
    if (id.isEmpty) return null;
    int? optional(Object? value) => value is num
        ? value.round()
        : value is String
            ? int.tryParse(value.trim())
            : null;
    final stage = optional(raw['stage']);
    final outcome = optional(raw['outcome']);
    if (stage == null && outcome == null) return null;
    return IntrigueStep(id: id, stage: stage, outcome: outcome);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (stage != null) 'stage': stage,
        if (outcome != null) 'outcome': outcome,
      };
}
