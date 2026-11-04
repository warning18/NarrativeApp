part of '../factions.dart';

// Intrigues (intrigues.json): their stages, effects and outcomes, and
// where a story's flags have taken each one.

const List<String> intrigueStageNames = [
  'Clue',
  'Hook',
  'Turn',
  'Reveal',
  'Crisis',
  'Choice',
];

/// One stage of an intrigue: its name ([intrigueStageNames]), the
/// chapter it falls in ("1–2", "3"...), what happens and (v1.210) the
/// person at that stage, [npcId] in npcs.json ('' when unnamed).
class IntrigueStage {
  const IntrigueStage({
    required this.stage,
    this.chapter = '',
    this.text = '',
    this.textFr = '',
    this.npcId = '',
  });

  final String stage;
  final String chapter;
  final String text;
  final String textFr;
  final String npcId;

  String textFor(AppLanguage language) => _pick(language, text, textFr);

  /// The l10n key of the stage's name (`intrigue_stage_clue`...).
  String get key => 'intrigue_stage_${stage.trim().toLowerCase()}';

  factory IntrigueStage.fromJson(Map<String, dynamic> json) => IntrigueStage(
        stage: _text(json['stage']).trim(),
        chapter: _text(json['chapter']).trim(),
        text: _text(json['text']),
        textFr: _text(json['text_fr']),
        npcId: _text(json['npcId']).trim(),
      );
}

/// One thing an intrigue's outcome does: moves standing with a faction
/// ([factionId], [delta], perhaps only on a [condition]), marks a
/// sub-clan ([subclanId], [mark]), moves a companion ([companionId],
/// [change]: leaves, disapproves...), gives a title ([titleId]), or
/// something only told ([note]). Shown only, for now.
class IntrigueEffect {
  const IntrigueEffect({
    this.factionId = '',
    this.delta = 0,
    this.condition = '',
    this.conditionFr = '',
    this.subclanId = '',
    this.mark,
    this.companionId = '',
    this.change = '',
    this.titleId = '',
    this.note = '',
    this.noteFr = '',
    this.raw = const {},
  });

  final String factionId;
  final int delta;
  final String condition;
  final String conditionFr;
  final String subclanId;
  final SubclanMark? mark;
  final String companionId;
  final String change;
  final String titleId;
  final String note;
  final String noteFr;
  final Map<String, dynamic> raw;

  String noteFor(AppLanguage language) => _pick(language, note, noteFr);
  String conditionFor(AppLanguage language) =>
      _pick(language, condition, conditionFr);

  factory IntrigueEffect.fromJson(Map<String, dynamic> json) => IntrigueEffect(
        factionId: _text(json['faction']).trim(),
        delta: _int(json['delta']),
        condition: _text(json['condition']),
        conditionFr: _text(json['condition_fr']),
        subclanId: _text(json['subclan']).trim(),
        mark: subclanMarkNamed(json['mark']?.toString()),
        companionId: _text(json['companion']).trim(),
        change: _text(json['change']).trim(),
        titleId: _text(json['title']).trim(),
        note: _text(json['note'] ?? json['text']),
        noteFr: _text(json['note_fr'] ?? json['text_fr']),
        raw: json,
      );
}

/// One way an intrigue can end; (v1.210) [npcId] names the person it
/// turns on, in npcs.json ('' when unnamed).
class IntrigueOutcome {
  const IntrigueOutcome({
    required this.name,
    this.nameFr = '',
    this.text = '',
    this.textFr = '',
    this.effects = const [],
    this.npcId = '',
  });

  final String name;
  final String nameFr;
  final String text;
  final String textFr;
  final List<IntrigueEffect> effects;
  final String npcId;

  String nameFor(AppLanguage language) => _pick(language, name, nameFr);
  String textFor(AppLanguage language) => _pick(language, text, textFr);

  factory IntrigueOutcome.fromJson(Map<String, dynamic> json) =>
      IntrigueOutcome(
        name: _text(json['name']),
        nameFr: _text(json['name_fr']),
        text: _text(json['text'] ?? json['line']),
        textFr: _text(json['text_fr'] ?? json['line_fr']),
        effects: [
          for (final e in (json['effects'] as List?) ?? const [])
            if (e is Map) IntrigueEffect.fromJson(e.cast<String, dynamic>()),
        ],
        npcId: _text(json['npcId']).trim(),
      );
}

/// One of the eight plots beside the main story (intrigues.json). Shown
/// only, for now: no scene plays them yet.
class Intrigue {
  const Intrigue({
    required this.id,
    required this.name,
    this.nameFr = '',
    this.premise = '',
    this.premiseFr = '',
    this.factionIds = const [],
    this.subclanIds = const [],
    this.stages = const [],
    this.outcomes = const [],
  });

  final String id;
  final String name;
  final String nameFr;
  final String premise;
  final String premiseFr;
  final List<String> factionIds;
  final List<String> subclanIds;
  final List<IntrigueStage> stages;
  final List<IntrigueOutcome> outcomes;

  String nameFor(AppLanguage language) => _pick(language, name, nameFr);
  String premiseFor(AppLanguage language) =>
      _pick(language, premise, premiseFr);

  factory Intrigue.fromJson(String id, Map<String, dynamic> json) => Intrigue(
        id: id,
        name: _text(json['name']).isEmpty ? id : _text(json['name']),
        nameFr: _text(json['name_fr']),
        premise: _text(json['premise']),
        premiseFr: _text(json['premise_fr']),
        factionIds: _strings(json['factions']),
        subclanIds: _strings(json['subclans']),
        stages: [
          for (final s in (json['stages'] as List?) ?? const [])
            if (s is Map) IntrigueStage.fromJson(s.cast<String, dynamic>()),
        ],
        outcomes: [
          for (final o in (json['outcomes'] as List?) ?? const [])
            if (o is Map) IntrigueOutcome.fromJson(o.cast<String, dynamic>()),
        ],
      );
}

/// The stage [intrigueId] has reached in the story, 1 (Clue) to 6
/// (Choice), from the flags `intrigue_<id>_stage_<n>` (or
/// `intrigue_<id>_stage=<n>`): the highest set. 0 when none is: not
/// started.
int intrigueStageFrom(Iterable<String> flags, String intrigueId) {
  final prefix = 'intrigue_${intrigueId}_stage';
  var stage = 0;
  for (final flag in flags) {
    if (!flag.startsWith(prefix)) continue;
    final rest = flag.substring(prefix.length);
    if (rest.length < 2 || (rest[0] != '_' && rest[0] != '=')) continue;
    final n = int.tryParse(rest.substring(1));
    if (n != null && n >= 1 && n <= intrigueStageNames.length) {
      stage = max(stage, n);
    }
  }
  return stage;
}

/// The outcome [intrigueId] came to (its index in the record), from the
/// flag `intrigue_<id>_outcome_<n>` (counting from 0); null while none
/// is set.
int? intrigueOutcomeFrom(Iterable<String> flags, String intrigueId) {
  final prefix = 'intrigue_${intrigueId}_outcome_';
  for (final flag in flags) {
    if (!flag.startsWith(prefix)) continue;
    final n = int.tryParse(flag.substring(prefix.length));
    if (n != null && n >= 0) return n;
  }
  return null;
}
