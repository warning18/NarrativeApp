import 'dart:math';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import 'signs.dart';

/// Clans, standing and politics (v1.193): the Grey Shroud's Lantern
/// Dominion and the five clans of the coast, their 29 sub-clans, the
/// Choir and the Pit, and the tribes met on the way -- all of them
/// *factions* (assets/gamedata/factions.json). The character stands
/// somewhere with each one, from -100 (Hunted) to +100 (Sworn); each
/// sub-clan keeps a mark (friend, none or foe); and every pair of clans
/// sits on one step of a seven-step scale, from Blood feud to Allies,
/// which moves with the story.
///
/// Everything here is pure, like signs.dart: the data files parse into a
/// [ClanData]; the session keeps a [PoliticsState]; and the rules --
/// [applyStandingChange] (with its ripple and the Sworn banner),
/// [setSubclanMark], [shiftRelation], [setStandingValue] -- take a state
/// and return the next one, with what they log.
///
/// For the code that calls this (offers, quests, intrigues):
/// - **faction lookup:** [ClanData.faction], [ClanData.clans],
///   [ClanData.subclansOf], [ClanData.subclan], [ClanData.titlesFor];
/// - **standing:** [PoliticsState.standingOf], [PoliticsState.tierOf],
///   [applyStandingChange] (and [standingPreview] for its numbers alone);
/// - **tiers:** [standingTierFor], [StandingTier.isAtLeast],
///   [tierPriceFactor];
/// - **marks:** [PoliticsState.markOf], [setSubclanMark];
/// - **relations:** [alliesOf], [rivalsOf], [PoliticsState.relationStep],
///   [shiftRelation], [relationsAtChapter];
/// - **the log:** [PoliticsState.standingLog] and
///   [PoliticsState.relationsLog], each entry dated by chapter and day,
///   its cause read with [standingCauseLabel].

/// A faction's place in the world: one of the clans (the Dominion
/// included), a tribe met on the way, or the Choir or the Pit. The same
/// kinds Signs knows its patrons by: every faction is a patron.
typedef FactionKind = PatronKind;

// --- Tiers ------------------------------------------------------------------

/// Where the character stands with a faction, from worst to best (see
/// [standingTierFor]). The order matters: compare with [isAtLeast].
enum StandingTier { hunted, hostile, wary, unknown, known, trusted, sworn }

extension StandingTierOrder on StandingTier {
  /// Whether this tier is [other] or better.
  bool isAtLeast(StandingTier other) => index >= other.index;
}

/// The lowest and highest standing there is.
const int minStanding = -100;
const int maxStanding = 100;

/// A tier's range and what it means in a shop: the price factor, null
/// for no trade at all; and its colour (ARGB), the brief's, used on
/// every screen.
class StandingTierInfo {
  const StandingTierInfo({
    required this.min,
    required this.max,
    required this.priceFactor,
    required this.color,
  });

  final int min;
  final int max;
  final double? priceFactor;
  final int color;
}

const Map<StandingTier, StandingTierInfo> standingTiers = {
  StandingTier.hunted: StandingTierInfo(
      min: -100, max: -61, priceFactor: null, color: 0xFF8A1A1A),
  StandingTier.hostile: StandingTierInfo(
      min: -60, max: -26, priceFactor: 1.40, color: 0xFFD9544D),
  StandingTier.wary:
      StandingTierInfo(min: -25, max: -6, priceFactor: 1.15, color: 0xFFE0762B),
  StandingTier.unknown:
      StandingTierInfo(min: -5, max: 5, priceFactor: 1.0, color: 0xFFA8A194),
  StandingTier.known:
      StandingTierInfo(min: 6, max: 25, priceFactor: 0.95, color: 0xFF4FB0B0),
  StandingTier.trusted:
      StandingTierInfo(min: 26, max: 60, priceFactor: 0.85, color: 0xFF7DBE6A),
  StandingTier.sworn:
      StandingTierInfo(min: 61, max: 100, priceFactor: 0.75, color: 0xFFF2C14E),
};

/// The tier [standing] falls in. Standing may be fractional (a quarter
/// of a gain reaches the allies); it is read rounded, the way it is
/// shown.
StandingTier standingTierFor(num standing) {
  final value = standing.round();
  for (final tier in StandingTier.values) {
    if (value <= standingTiers[tier]!.max) return tier;
  }
  return StandingTier.sworn;
}

/// What a shop of a faction at [tier] charges, as a factor of its price:
/// 1.40 when Hostile down to 0.75 when Sworn. Null: a Hunted faction's
/// shop does not trade at all.
double? tierPriceFactor(StandingTier tier) => standingTiers[tier]!.priceFactor;

/// [tier]'s colour, ARGB.
int tierColor(StandingTier tier) => standingTiers[tier]!.color;

/// The l10n key of [tier]'s word (`standing_tier_hunted`...).
String standingTierKey(StandingTier tier) => 'standing_tier_${tier.name}';

StandingTier? standingTierNamed(String? name) =>
    StandingTier.values.where((t) => t.name == name?.trim()).firstOrNull;

// --- The ripple and the banner -------------------------------------------

/// A faction's allies share this much of any change with it, gain or
/// loss.
const double allyRippleShare = 0.25;

/// Its rivals lose this much of a gain with it (a loss leaves them be).
const double rivalRippleShare = 0.5;

/// Relation steps from which two factions count as allies, and up to
/// which they count as rivals (see [alliesOf], [rivalsOf]).
const int allyMinStep = 6;
const int rivalMaxStep = 3;

/// Standing at which a faction becomes the sworn one (the Sworn tier's
/// floor); only one faction is sworn at a time.
const int swornThreshold = 61;

/// What swearing to a faction costs with each of its rivals, once.
const int swornRivalCost = 20;

/// While a faction is sworn, its rivals stop here (the top of Known), and
/// every other faction at the top of Trusted: there is one banner.
const int swornRivalCap = 25;
const int swornOthersCap = 60;

/// The steps a relation can take, Blood feud to Allies.
const int minRelationStep = 1;
const int maxRelationStep = 7;

/// Log entries kept (the oldest go first): enough for a whole game.
const int maxStandingLogEntries = 500;
const int maxRelationsLogEntries = 200;

// --- Reading the data -----------------------------------------------------

String _pick(AppLanguage language, String en, String fr) =>
    language == AppLanguage.fr && fr.trim().isNotEmpty ? fr : en;

String _text(Object? raw) => raw?.toString() ?? '';

List<String> _strings(Object? raw) => [
      if (raw is List)
        for (final e in raw)
          if (e.toString().trim().isNotEmpty) e.toString().trim(),
    ];

int _int(Object? raw, [int fallback = 0]) {
  if (raw is num) return raw.round();
  if (raw is String) return int.tryParse(raw.trim()) ?? fallback;
  return fallback;
}

/// Effects written the Signs way ({kind, value, ...}): those the game
/// knows parsed, the others' kinds kept, and every record as written --
/// a later version may know a kind this one doesn't.
({
  List<SignEffect> effects,
  List<String> unknownKinds,
  List<Map<String, dynamic>> raw,
}) _signEffects(Object? list) {
  final effects = <SignEffect>[];
  final unknown = <String>[];
  final raw = <Map<String, dynamic>>[];
  for (final e in (list is List ? list : const [])) {
    if (e is! Map) continue;
    final map = e.cast<String, dynamic>();
    raw.add(map);
    final effect = SignEffect.tryParse(map);
    if (effect == null) {
      unknown.add(map['kind']?.toString() ?? '?');
    } else {
      effects.add(effect);
    }
  }
  return (effects: effects, unknownKinds: unknown, raw: raw);
}

/// An object a faction may give (factions.json `objects`): an item, once
/// the character stands at [minTier] or better with them.
class FactionObject {
  const FactionObject({
    required this.itemId,
    this.minTier = StandingTier.unknown,
  });

  final String itemId;
  final StandingTier minTier;

  factory FactionObject.fromJson(Map<String, dynamic> json) => FactionObject(
        itemId: _text(json['itemId']).trim(),
        minTier: standingTierNamed(json['minTier']?.toString()) ??
            StandingTier.unknown,
      );
}

/// A faction's Sworn boon ("the banner in your Loft"), given once to the
/// sworn faction's champion. Its [effects] are Signs' kinds; kinds this
/// version does not know are kept in [rawEffects] and named in
/// [unknownEffectKinds].
class SwornBoon {
  const SwornBoon({
    required this.name,
    this.nameFr = '',
    this.line = '',
    this.lineFr = '',
    this.effects = const [],
    this.rawEffects = const [],
    this.unknownEffectKinds = const [],
  });

  final String name;
  final String nameFr;
  final String line;
  final String lineFr;
  final List<SignEffect> effects;
  final List<Map<String, dynamic>> rawEffects;
  final List<String> unknownEffectKinds;

  String nameFor(AppLanguage language) => _pick(language, name, nameFr);
  String lineFor(AppLanguage language) => _pick(language, line, lineFr);

  /// [raw] read, or null when there is no boon.
  static SwornBoon? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.cast<String, dynamic>();
    final name = _text(json['name']).trim();
    if (name.isEmpty) return null;
    final effects = _signEffects(json['effects']);
    return SwornBoon(
      name: name,
      nameFr: _text(json['name_fr']),
      line: _text(json['line'] ?? json['text']),
      lineFr: _text(json['line_fr'] ?? json['text_fr']),
      effects: effects.effects,
      rawEffects: effects.raw,
      unknownEffectKinds: effects.unknownKinds,
    );
  }
}

/// One faction of factions.json. What Signs needs of it -- its name,
/// colour, icon, words and when it may offer -- is its [patron]; the rest
/// is the clan's: motto, alignment lean, where standing starts, its
/// sub-clans, the skill-tree branches it sponsors, its objects and its
/// Sworn boon.
class Faction {
  const Faction({
    required this.patron,
    this.nameOf = '',
    this.nameOfFr = '',
    this.short = '',
    this.shortFr = '',
    this.motto = '',
    this.mottoFr = '',
    this.lean = 0,
    this.startStanding = 0,
    this.subclans = const [],
    this.sponsors = const [],
    this.objects = const [],
    this.sworn,
  });

  final Patron patron;

  /// The name after a sub-clan's: "of the Grey Vigil", « de la Veille
  /// Grise » (see [nameOfFor]).
  final String nameOf;
  final String nameOfFr;

  /// The name in a word, for the offers' standing preview ("+6 Compact ·
  /// −3 Penitents"); see [shortFor].
  final String short;
  final String shortFr;
  final String motto;
  final String mottoFr;

  /// The alignment nudge when the character accepts their gift: -1, 0 or
  /// 1.
  final int lean;

  /// Where standing with them starts (the Dominion: -10).
  final int startStanding;

  /// Sub-clan ids, in the order they are shown.
  final List<String> subclans;

  /// skill_trees.json branch ids whose skills they offer.
  final List<String> sponsors;
  final List<FactionObject> objects;
  final SwornBoon? sworn;

  String get id => patron.id;
  FactionKind get kind => patron.kind;
  bool get isClan => kind == PatronKind.clan;

  /// ARGB.
  int get color => patron.color;
  String get icon => patron.icon;
  String get unlockFlag => patron.unlockFlag;

  String nameFor(AppLanguage language) => patron.nameFor(language);

  /// "of the Grey Vigil" in [language], for "The Candlebearers of the Grey
  /// Vigil"; the bare name when the data has none.
  String nameOfFor(AppLanguage language) {
    final own = _pick(language, nameOf, nameOfFr);
    return own.isNotEmpty ? own : nameFor(language);
  }

  /// The name in a word in [language]; the full name when the data has
  /// none.
  String shortFor(AppLanguage language) {
    final own = _pick(language, short, shortFr);
    return own.isNotEmpty ? own : nameFor(language);
  }

  String mottoFor(AppLanguage language) => _pick(language, motto, mottoFr);
  String introFor(AppLanguage language) => patron.introFor(language);
  List<String> greetingsFor(AppLanguage language) =>
      patron.greetingsFor(language);

  factory Faction.fromJson(String id, Map<String, dynamic> json) => Faction(
        patron: Patron.fromJson(id, json),
        nameOf: _text(json['nameOf']),
        nameOfFr: _text(json['nameOf_fr']),
        short: _text(json['short']),
        shortFr: _text(json['short_fr']),
        motto: _text(json['motto']),
        mottoFr: _text(json['motto_fr']),
        lean: _int(json['lean']).clamp(-1, 1),
        startStanding:
            _int(json['startStanding']).clamp(minStanding, maxStanding),
        subclans: _strings(json['subclans']),
        sponsors: _strings(json['sponsors']),
        objects: [
          for (final o in (json['objects'] as List?) ?? const [])
            if (o is Map && _text(o['itemId']).trim().isNotEmpty)
              FactionObject.fromJson(o.cast<String, dynamic>()),
        ],
        sworn: SwornBoon.tryParse(json['sworn']),
      );
}

/// One of a clan's sub-clans (subclans.json): the Houses of the Dominion,
/// the Vigil's Candlebearers... Each keeps the character's mark.
class SubClan {
  const SubClan({
    required this.id,
    required this.clanId,
    required this.name,
    this.nameFr = '',
    this.line = '',
    this.lineFr = '',
    this.color = 0xFFB08D3C,
    this.lean = 0,
    this.favour = '',
    this.favourFr = '',
  });

  final String id;
  final String clanId;
  final String name;
  final String nameFr;

  /// One sentence on who they are.
  final String line;
  final String lineFr;

  /// ARGB.
  final int color;

  /// The alignment nudge of a gift they voice (the Inquisition -1, the
  /// Wickwardens 1).
  final int lean;

  /// Their favour's name.
  final String favour;
  final String favourFr;

  String nameFor(AppLanguage language) => _pick(language, name, nameFr);
  String lineFor(AppLanguage language) => _pick(language, line, lineFr);
  String favourFor(AppLanguage language) => _pick(language, favour, favourFr);

  factory SubClan.fromJson(String id, Map<String, dynamic> json) => SubClan(
        id: id,
        clanId: _text(json['clan']).trim(),
        name: _text(json['name']).isEmpty ? id : _text(json['name']),
        nameFr: _text(json['name_fr']),
        line: _text(json['line']),
        lineFr: _text(json['line_fr']),
        color: parsePatronColor(json['color']),
        lean: _int(json['lean']).clamp(-1, 1),
        favour: _text(json['favour']),
        favourFr: _text(json['favour_fr']),
      );
}

/// One step of the relations scale (relations.json `steps`): 1 Blood
/// feud ... 7 Allies.
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
class TitleDef {
  const TitleDef({
    required this.id,
    required this.name,
    this.nameFr = '',
    this.line = '',
    this.lineFr = '',
    this.factionId = '',
    this.source = '',
    this.negative = false,
    this.effects = const [],
    this.rawEffects = const [],
    this.unknownEffectKinds = const [],
  });

  final String id;
  final String name;
  final String nameFr;
  final String line;
  final String lineFr;
  final String factionId;

  /// `offer`, `tier:known`, `tier:trusted`, `tier:sworn`,
  /// `mark:foe:<subclan>`, `quest` or `intrigue`.
  final String source;
  final bool negative;
  final List<SignEffect> effects;
  final List<Map<String, dynamic>> rawEffects;
  final List<String> unknownEffectKinds;

  String nameFor(AppLanguage language) => _pick(language, name, nameFr);
  String lineFor(AppLanguage language) => _pick(language, line, lineFr);

  factory TitleDef.fromJson(String id, Map<String, dynamic> json) {
    final effects = _signEffects(json['effects']);
    return TitleDef(
      id: id,
      name: _text(json['name']).isEmpty ? id : _text(json['name']),
      nameFr: _text(json['name_fr']),
      line: _text(json['line']),
      lineFr: _text(json['line_fr']),
      factionId: _text(json['faction']).trim(),
      source: _text(json['source']).trim(),
      negative: json['negative'] == true,
      effects: effects.effects,
      rawEffects: effects.raw,
      unknownEffectKinds: effects.unknownKinds,
    );
  }
}

/// The six stages every intrigue runs through, one a chapter column.
const List<String> intrigueStageNames = [
  'Clue',
  'Hook',
  'Turn',
  'Reveal',
  'Crisis',
  'Choice',
];

/// One stage of an intrigue: its name ([intrigueStageNames]), the
/// chapter it falls in ("1–2", "3"...) and what happens.
class IntrigueStage {
  const IntrigueStage({
    required this.stage,
    this.chapter = '',
    this.text = '',
    this.textFr = '',
  });

  final String stage;
  final String chapter;
  final String text;
  final String textFr;

  String textFor(AppLanguage language) => _pick(language, text, textFr);

  /// The l10n key of the stage's name (`intrigue_stage_clue`...).
  String get key => 'intrigue_stage_${stage.trim().toLowerCase()}';

  factory IntrigueStage.fromJson(Map<String, dynamic> json) => IntrigueStage(
        stage: _text(json['stage']).trim(),
        chapter: _text(json['chapter']).trim(),
        text: _text(json['text']),
        textFr: _text(json['text_fr']),
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

/// One way an intrigue can end.
class IntrigueOutcome {
  const IntrigueOutcome({
    required this.name,
    this.nameFr = '',
    this.text = '',
    this.textFr = '',
    this.effects = const [],
  });

  final String name;
  final String nameFr;
  final String text;
  final String textFr;
  final List<IntrigueEffect> effects;

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

/// Records of a gamedata table: every entry that is a record, leaving out
/// notes (a key starting with `_`, like factions.json's `_newKinds`).
Iterable<MapEntry<String, Map<String, dynamic>>> _records(
        Map<String, dynamic> db) =>
    [
      for (final entry in db.entries)
        if (!entry.key.startsWith('_') && entry.value is Map)
          MapEntry(entry.key, (entry.value as Map).cast<String, dynamic>()),
    ];

/// factions.json parsed, by id, in the file's order.
Map<String, Faction> parseFactions(Map<String, dynamic> db) => {
      for (final e in _records(db)) e.key: Faction.fromJson(e.key, e.value),
    };

/// subclans.json parsed, by id.
Map<String, SubClan> parseSubclans(Map<String, dynamic> db) => {
      for (final e in _records(db)) e.key: SubClan.fromJson(e.key, e.value),
    };

/// relations.json parsed.
Relations parseRelations(Map<String, dynamic> db) => Relations.fromJson(db);

/// titles.json parsed, by id.
Map<String, TitleDef> parseTitles(Map<String, dynamic> db) => {
      for (final e in _records(db)) e.key: TitleDef.fromJson(e.key, e.value),
    };

/// intrigues.json parsed, by id.
Map<String, Intrigue> parseIntrigues(Map<String, dynamic> db) => {
      for (final e in _records(db)) e.key: Intrigue.fromJson(e.key, e.value),
    };

/// Every faction as Signs' patron (see signs.dart): the Choir and the Pit
/// keep their alignment rules and the tribes their unlock flags, all
/// from factions.json.
Map<String, Patron> patronsFromFactions(Map<String, Faction> factions) => {
      for (final faction in factions.values) faction.id: faction.patron,
    };

/// All the clan data in one place: what the rules read.
class ClanData {
  const ClanData({
    this.factions = const {},
    this.subclans = const {},
    this.relations = Relations.empty,
    this.titles = const {},
    this.intrigues = const {},
  });

  static const ClanData empty = ClanData();

  final Map<String, Faction> factions;
  final Map<String, SubClan> subclans;
  final Relations relations;
  final Map<String, TitleDef> titles;
  final Map<String, Intrigue> intrigues;

  /// The data files' records, parsed.
  factory ClanData.fromTables({
    Map<String, dynamic> factions = const {},
    Map<String, dynamic> subclans = const {},
    Map<String, dynamic> relations = const {},
    Map<String, dynamic> titles = const {},
    Map<String, dynamic> intrigues = const {},
  }) =>
      ClanData(
        factions: parseFactions(factions),
        subclans: parseSubclans(subclans),
        relations: parseRelations(relations),
        titles: parseTitles(titles),
        intrigues: parseIntrigues(intrigues),
      );

  Faction? faction(String id) => factions[id];
  SubClan? subclan(String id) => subclans[id];

  /// Factions of [kind], in the file's order.
  List<Faction> ofKind(FactionKind kind) => [
        for (final f in factions.values)
          if (f.kind == kind) f,
      ];

  /// The Dominion and the five clans, in the file's order.
  List<Faction> get clans => ofKind(PatronKind.clan);
  List<Faction> get tribes => ofKind(PatronKind.tribe);
  List<Faction> get otherworld => ofKind(PatronKind.otherworld);

  /// [factionId]'s sub-clans, in its record's order (any sub-clan naming
  /// it as its clan but missing from the list comes after).
  List<SubClan> subclansOf(String factionId) {
    final listed = factions[factionId]?.subclans ?? const <String>[];
    return [
      for (final id in listed)
        if (subclans[id] != null) subclans[id]!,
      for (final s in subclans.values)
        if (s.clanId == factionId && !listed.contains(s.id)) s,
    ];
  }

  /// Where standing with [factionId] starts (0 for an unknown id).
  int startStandingOf(String factionId) =>
      factions[factionId]?.startStanding ?? 0;

  /// The titles of [factionId] (any faction when null) from [source]
  /// (any when null).
  List<TitleDef> titlesFor({String? factionId, String? source}) => [
        for (final t in titles.values)
          if ((factionId == null || t.factionId == factionId) &&
              (source == null || t.source == source))
            t,
      ];
}

// --- What the session keeps -----------------------------------------------

/// A sub-clan's mark on the character. "You can be Trusted by the
/// Dominion and still be the Inquisition's foe."
enum SubclanMark { none, friend, foe }

SubclanMark? subclanMarkNamed(String? name) =>
    SubclanMark.values.where((m) => m.name == name?.trim()).firstOrNull;

/// The mark after [mark] when Edit Mode taps a sub-clan: none, friend,
/// foe, none...
SubclanMark nextSubclanMark(SubclanMark mark) =>
    SubclanMark.values[(mark.index + 1) % SubclanMark.values.length];

/// The l10n key of [mark]'s word.
String subclanMarkKey(SubclanMark mark) => 'subclan_mark_${mark.name}';

Map<String, double> _doubles(Object? raw) => {
      if (raw is Map)
        for (final e in raw.entries)
          if (e.value is num) e.key.toString(): (e.value as num).toDouble(),
    };

Map<String, int> _ints(Object? raw) => {
      if (raw is Map)
        for (final e in raw.entries)
          if (e.value is num) e.key.toString(): (e.value as num).round(),
    };

/// Standing kept to the hundredth, so the save stays readable.
double _tidy(double value) => (value * 100).round() / 100;

bool _same(double a, double b) => (a - b).abs() < 0.005;

/// One line of the standing log: when (the chapter and the story's day),
/// why ([cause], see [standingCauseLabel]) and what moved -- each
/// faction's change in [deltas] and where it ended in [after]. The faction
/// the change was made with is [factionId]; the others are its ripple.
/// A sub-clan marked is logged here too ([subclanId], [mark]), and the
/// banner changing hands ([swore], [released]).
class StandingLogEntry {
  const StandingLogEntry({
    required this.chapter,
    required this.day,
    required this.cause,
    this.factionId = '',
    this.deltas = const {},
    this.after = const {},
    this.subclanId = '',
    this.mark,
    this.swore = '',
    this.released = '',
  });

  final int chapter;
  final int day;
  final String cause;
  final String factionId;
  final Map<String, double> deltas;
  final Map<String, double> after;
  final String subclanId;
  final SubclanMark? mark;
  final String swore;
  final String released;

  /// [factionId]'s own change (0 for a mark alone).
  double get mainDelta => deltas[factionId] ?? 0;

  /// The other factions' changes: the ripple, and swearing's cost.
  Map<String, double> get rippleDeltas => {
        for (final e in deltas.entries)
          if (e.key != factionId) e.key: e.value,
      };

  Map<String, dynamic> toJson() => {
        'chapter': chapter,
        'day': day,
        'cause': cause,
        if (factionId.isNotEmpty) 'faction': factionId,
        if (deltas.isNotEmpty) 'deltas': deltas,
        if (after.isNotEmpty) 'after': after,
        if (subclanId.isNotEmpty) 'subclan': subclanId,
        if (mark != null) 'mark': mark!.name,
        if (swore.isNotEmpty) 'swore': swore,
        if (released.isNotEmpty) 'released': released,
      };

  factory StandingLogEntry.fromJson(Map<String, dynamic> json) =>
      StandingLogEntry(
        chapter: _int(json['chapter']),
        day: _int(json['day']),
        cause: _text(json['cause']),
        factionId: _text(json['faction']),
        deltas: _doubles(json['deltas']),
        after: _doubles(json['after']),
        subclanId: _text(json['subclan']),
        mark: subclanMarkNamed(json['mark']?.toString()),
        swore: _text(json['swore']),
        released: _text(json['released']),
      );
}

/// One line of the relations log: [a] and [b] moved from step [from] to
/// [to], when and why.
class RelationLogEntry {
  const RelationLogEntry({
    required this.chapter,
    required this.day,
    required this.a,
    required this.b,
    required this.from,
    required this.to,
    required this.cause,
  });

  final int chapter;
  final int day;
  final String a;
  final String b;
  final int from;
  final int to;
  final String cause;

  String get key => relationKey(a, b);

  Map<String, dynamic> toJson() => {
        'chapter': chapter,
        'day': day,
        'a': a,
        'b': b,
        'from': from,
        'to': to,
        'cause': cause,
      };

  factory RelationLogEntry.fromJson(Map<String, dynamic> json) =>
      RelationLogEntry(
        chapter: _int(json['chapter']),
        day: _int(json['day']),
        a: _text(json['a']),
        b: _text(json['b']),
        from: _int(json['from']),
        to: _int(json['to']),
        cause: _text(json['cause']),
      );
}

/// Where the character stands with the coast, as the session keeps it:
/// - [standings]: standing with each faction it has moved with (any
///   other is still at its `startStanding`, see [standingOf]);
/// - [marks]: each sub-clan's mark, when it is one (see [markOf]);
/// - [swornFactionId]: the one faction the character is sworn to, '' for
///   none;
/// - [relationSteps]: each pair of clans that has moved off its opening
///   step (see [relationStep]), and [relationSnapshots], how those stood
///   after each chapter in which one moved (see [relationsAtChapter]);
/// - [standingLog] and [relationsLog], oldest first.
///
/// A new game, a permadeath and a New Game+ start from [empty]: the world
/// starts over.
class PoliticsState {
  const PoliticsState({
    this.standings = const {},
    this.marks = const {},
    this.swornFactionId = '',
    this.relationSteps = const {},
    this.relationSnapshots = const {},
    this.standingLog = const [],
    this.relationsLog = const [],
  });

  static const PoliticsState empty = PoliticsState();

  final Map<String, double> standings;
  final Map<String, SubclanMark> marks;
  final String swornFactionId;
  final Map<String, int> relationSteps;
  final Map<int, Map<String, int>> relationSnapshots;
  final List<StandingLogEntry> standingLog;
  final List<RelationLogEntry> relationsLog;

  bool get isEmpty =>
      standings.isEmpty &&
      marks.isEmpty &&
      swornFactionId.isEmpty &&
      relationSteps.isEmpty &&
      relationSnapshots.isEmpty &&
      standingLog.isEmpty &&
      relationsLog.isEmpty;

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
  }) =>
      PoliticsState(
        standings: standings ?? this.standings,
        marks: marks ?? this.marks,
        swornFactionId: swornFactionId ?? this.swornFactionId,
        relationSteps: relationSteps ?? this.relationSteps,
        relationSnapshots: relationSnapshots ?? this.relationSnapshots,
        standingLog: standingLog ?? this.standingLog,
        relationsLog: relationsLog ?? this.relationsLog,
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
      };

  /// [raw] read; [empty] for a save from before clans (or anything
  /// unreadable).
  factory PoliticsState.fromJson(Object? raw) {
    if (raw is! Map) return empty;
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
    return PoliticsState(
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
    );
  }
}

// --- The rules ------------------------------------------------------------

/// [factionId]'s allies now: every faction it stands with on step
/// [allyMinStep] or above (Trade, Allies), in the data's order.
List<String> alliesOf(String factionId, PoliticsState state, ClanData data) =>
    _related(factionId, state, data, (step) => step >= allyMinStep);

/// [factionId]'s rivals now: every faction it stands with on step
/// [rivalMaxStep] or below (Blood feud, War, Hostile).
List<String> rivalsOf(String factionId, PoliticsState state, ClanData data) =>
    _related(factionId, state, data, (step) => step <= rivalMaxStep);

List<String> _related(String factionId, PoliticsState state, ClanData data,
    bool Function(int step) matches) {
  final others = <String>{
    for (final p in data.relations.pairs)
      if (p.a == factionId) p.b else if (p.b == factionId) p.a,
    for (final key in state.relationSteps.keys)
      if (key.split('|').contains(factionId))
        key.split('|').firstWhere((id) => id != factionId, orElse: () => ''),
  }..remove('');
  final ordered = [
    for (final id in data.factions.keys)
      if (others.contains(id)) id,
    for (final id in others)
      if (!data.factions.containsKey(id)) id,
  ];
  return [
    for (final other in ordered)
      if (other != factionId &&
          matches(state.relationStep(factionId, other, data) ?? 4))
        other,
  ];
}

/// What [applyStandingChange] (or another rule) did: the [state] after,
/// every faction's change in [deltas], and the [entry] it logged (null
/// when nothing moved).
class StandingResult {
  const StandingResult({
    required this.state,
    this.deltas = const {},
    this.entry,
  });

  final PoliticsState state;
  final Map<String, double> deltas;
  final StandingLogEntry? entry;

  bool get changed => entry != null;

  /// The faction the character became sworn to by it, '' for none.
  String get swore => entry?.swore ?? '';

  /// The faction it stopped being sworn to, '' for none.
  String get released => entry?.released ?? '';
}

double _clampStanding(double value) =>
    value.clamp(minStanding.toDouble(), maxStanding.toDouble());

bool _swornLevel(double value) => standingTierFor(value) == StandingTier.sworn;

/// Whether [factionId] may ever be the sworn faction: only a clan (the
/// Dominion and the five clans) can. The Choir, the Pit and the tribes
/// never are, and never stand past [swornOthersCap] (see [_applyBanner]).
bool canBeSworn(String factionId, ClanData data) =>
    data.faction(factionId)?.isClan ?? false;

/// The banner's rules over [values] (standing by faction, every faction of
/// [data] in it), with [sworn] the faction sworn before the change (''
/// for none) and [preferred] the one the change was made with:
/// - only a clan can be sworn (see [canBeSworn]): any other faction stops
///   at [swornOthersCap], so it never reaches the Sworn tier;
/// - the sworn faction falling under [swornThreshold] is released;
/// - with none sworn, one reaching it is sworn (the [preferred] one
///   first, then the highest), and costs each of its rivals
///   [swornRivalCost] ([chargeRivals]);
/// - while one is sworn, its rivals stop at [swornRivalCap] and every
///   other faction at [swornOthersCap].
/// Returns the faction sworn after, and those sworn and released.
({String sworn, String swore, String released}) _applyBanner(
  Map<String, double> values, {
  required String sworn,
  required String preferred,
  required PoliticsState state,
  required ClanData data,
  bool chargeRivals = true,
}) {
  var current = sworn;
  var swore = '';
  var released = '';
  for (final id in values.keys.toList()) {
    if (!canBeSworn(id, data) && values[id]! > swornOthersCap) {
      values[id] = swornOthersCap.toDouble();
    }
  }
  if (current.isNotEmpty &&
      (!values.containsKey(current) ||
          !canBeSworn(current, data) ||
          !_swornLevel(values[current]!))) {
    released = current;
    current = '';
  }
  if (current.isEmpty) {
    final candidates = [
      for (final e in values.entries)
        if (canBeSworn(e.key, data) && _swornLevel(e.value)) e.key,
    ];
    if (candidates.isNotEmpty) {
      current = candidates.contains(preferred)
          ? preferred
          : (candidates
                ..sort((x, y) {
                  final byValue = values[y]!.compareTo(values[x]!);
                  return byValue != 0 ? byValue : x.compareTo(y);
                }))
              .first;
      swore = current;
      if (chargeRivals) {
        for (final rival in rivalsOf(current, state, data)) {
          if (!values.containsKey(rival)) continue;
          values[rival] = _clampStanding(values[rival]! - swornRivalCost);
        }
      }
    }
  }
  if (current.isNotEmpty) {
    final rivals = rivalsOf(current, state, data).toSet();
    for (final id in values.keys.toList()) {
      if (id == current) continue;
      final cap = rivals.contains(id) ? swornRivalCap : swornOthersCap;
      if (values[id]! > cap) values[id] = cap.toDouble();
    }
  }
  return (sworn: current, swore: swore, released: released);
}

/// [state] with [values] (every faction's standing) kept where they
/// differ from [before], logged as one entry when anything moved.
StandingResult _commit(
  PoliticsState state,
  Map<String, double> before,
  Map<String, double> values, {
  required String sworn,
  required String swore,
  required String released,
  required String factionId,
  required String cause,
  required int chapter,
  required int day,
}) {
  final deltas = <String, double>{};
  final after = <String, double>{};
  final standings = {...state.standings};
  for (final id in values.keys) {
    final old = before[id]!;
    final now = _tidy(values[id]!);
    if (_same(old, now)) continue;
    deltas[id] = _tidy(now - old);
    after[id] = now;
    standings[id] = now;
  }
  if (deltas.isEmpty && swore.isEmpty && released.isEmpty) {
    return StandingResult(state: state);
  }
  final entry = StandingLogEntry(
    chapter: chapter,
    day: day,
    cause: cause,
    factionId: factionId,
    deltas: deltas,
    after: after,
    swore: swore,
    released: released,
  );
  return StandingResult(
    state: state.copyWith(
      standings: standings,
      swornFactionId: sworn,
      standingLog:
          _appendCapped(state.standingLog, entry, maxStandingLogEntries),
    ),
    deltas: deltas,
    entry: entry,
  );
}

List<T> _appendCapped<T>(List<T> list, T entry, int cap) {
  final next = [...list, entry];
  return next.length <= cap ? next : next.sublist(next.length - cap);
}

Map<String, double> _allStandings(PoliticsState state, ClanData data) => {
      for (final id in data.factions.keys) id: state.standingOf(id, data),
    };

/// Moves standing with [factionId] by [delta], for [cause] (see
/// [standingCauseLabel]), on [chapter]'s [day]:
/// - **the ripple:** each of its allies ([alliesOf]) moves by a quarter
///   of [delta], gain or loss; on a gain, each of its rivals ([rivalsOf])
///   loses half of it; on a loss, the rivals don't move;
/// - **the banner:** reaching [swornThreshold] with no faction sworn
///   swears the character to it, which costs each of its rivals
///   [swornRivalCost]; while it is sworn its rivals stop at
///   [swornRivalCap] and every other faction at [swornOthersCap]; falling
///   under the threshold releases them;
/// - every standing stays within [minStanding]..[maxStanding].
///
/// Relations are read as they stand now, so the same gift can cost more
/// in a later chapter. Returns the state after, each faction's change and
/// the log entry (none, and the state unchanged, when nothing moved or
/// [factionId] is no faction of [data]).
StandingResult applyStandingChange(
  PoliticsState state,
  String factionId,
  num delta,
  String cause, {
  required ClanData data,
  int chapter = 0,
  int day = 0,
}) {
  if (delta == 0 || !data.factions.containsKey(factionId)) {
    return StandingResult(state: state);
  }
  final before = _allStandings(state, data);
  final values = {...before};
  final change = delta.toDouble();
  void move(String id, double by) {
    if (!values.containsKey(id)) return;
    values[id] = _clampStanding(values[id]! + by);
  }

  move(factionId, change);
  for (final ally in alliesOf(factionId, state, data)) {
    move(ally, change * allyRippleShare);
  }
  if (change > 0) {
    for (final rival in rivalsOf(factionId, state, data)) {
      move(rival, -change * rivalRippleShare);
    }
  }
  final banner = _applyBanner(values,
      sworn: state.swornFactionId,
      preferred: factionId,
      state: state,
      data: data);
  return _commit(state, before, values,
      sworn: banner.sworn,
      swore: banner.swore,
      released: banner.released,
      factionId: factionId,
      cause: cause,
      chapter: chapter,
      day: day);
}

/// What [applyStandingChange] would move, faction by faction, without
/// doing it: an offer card's "+6 Compact · +1.5 Mire · −3 Penitents".
Map<String, double> standingPreview(
  PoliticsState state,
  String factionId,
  num delta, {
  required ClanData data,
}) =>
    applyStandingChange(state, factionId, delta, '', data: data).deltas;

/// Edit Mode's slider: standing with [factionId] set to [value] (within
/// [minStanding]..[maxStanding]), with no ripple. The banner still holds:
/// a sworn faction set under the threshold is released, one set to it
/// with none sworn is sworn (without the rivals' cost), and while one is
/// sworn the caps hold -- the value set included.
StandingResult setStandingValue(
  PoliticsState state,
  String factionId,
  num value,
  String cause, {
  required ClanData data,
  int chapter = 0,
  int day = 0,
}) {
  if (!data.factions.containsKey(factionId)) {
    return StandingResult(state: state);
  }
  final before = _allStandings(state, data);
  final values = {...before};
  values[factionId] = _clampStanding(value.toDouble());
  final banner = _applyBanner(values,
      sworn: state.swornFactionId,
      preferred: factionId,
      state: state,
      data: data,
      chargeRivals: false);
  return _commit(state, before, values,
      sworn: banner.sworn,
      swore: banner.swore,
      released: banner.released,
      factionId: factionId,
      cause: cause,
      chapter: chapter,
      day: day);
}

/// What [setSubclanMark] did: the [state] after and its log [entry]
/// (null when the mark was already that).
class MarkResult {
  const MarkResult({required this.state, this.entry});

  final PoliticsState state;
  final StandingLogEntry? entry;

  bool get changed => entry != null;
}

/// [subclanId] marks the character [mark] (friend, none or foe), for
/// [cause], logged in the standing log under its clan.
MarkResult setSubclanMark(
  PoliticsState state,
  String subclanId,
  SubclanMark mark,
  String cause, {
  required ClanData data,
  int chapter = 0,
  int day = 0,
}) {
  if (subclanId.isEmpty || state.markOf(subclanId) == mark) {
    return MarkResult(state: state);
  }
  final marks = {...state.marks};
  if (mark == SubclanMark.none) {
    marks.remove(subclanId);
  } else {
    marks[subclanId] = mark;
  }
  final entry = StandingLogEntry(
    chapter: chapter,
    day: day,
    cause: cause,
    factionId: data.subclan(subclanId)?.clanId ?? '',
    subclanId: subclanId,
    mark: mark,
  );
  return MarkResult(
    state: state.copyWith(
      marks: marks,
      standingLog:
          _appendCapped(state.standingLog, entry, maxStandingLogEntries),
    ),
    entry: entry,
  );
}

/// What [shiftRelation] did: the [state] after, its log [entry] (null
/// when the pair didn't move) and, when the banner's caps took standing
/// off a new rival of the sworn faction, that [standing] change.
class RelationResult {
  const RelationResult({required this.state, this.entry, this.standing});

  final PoliticsState state;
  final RelationLogEntry? entry;
  final StandingLogEntry? standing;

  bool get changed => entry != null;
}

/// [a] and [b] move [steps] along the scale (negative: towards Blood
/// feud), within [minRelationStep]..[maxRelationStep], for [cause] on
/// [chapter]'s [day]. Logged, and the relations as they now stand kept
/// as [chapter]'s snapshot (see [relationsAtChapter]). A pair the data
/// doesn't relate starts from the middle step. While a faction is sworn,
/// a pair turned rival to it is capped at once.
RelationResult shiftRelation(
  PoliticsState state,
  String a,
  String b,
  int steps,
  String cause, {
  required ClanData data,
  int chapter = 0,
  int day = 0,
}) {
  if (a.isEmpty || b.isEmpty || a == b || steps == 0) {
    return RelationResult(state: state);
  }
  final from = state.relationStep(a, b, data) ?? 4;
  final to = (from + steps).clamp(minRelationStep, maxRelationStep);
  if (to == from) return RelationResult(state: state);
  final key = relationKey(a, b);
  final base = data.relations.baseSteps[key];
  final relationSteps = {...state.relationSteps};
  if (base == to) {
    relationSteps.remove(key);
  } else {
    relationSteps[key] = to;
  }
  final entry = RelationLogEntry(
      chapter: chapter, day: day, a: a, b: b, from: from, to: to, cause: cause);
  var next = state.copyWith(
    relationSteps: relationSteps,
    relationSnapshots: {...state.relationSnapshots, chapter: relationSteps},
    relationsLog:
        _appendCapped(state.relationsLog, entry, maxRelationsLogEntries),
  );
  StandingLogEntry? standing;
  if (next.swornFactionId.isNotEmpty) {
    final before = _allStandings(next, data);
    final values = {...before};
    final banner = _applyBanner(values,
        sworn: next.swornFactionId,
        preferred: next.swornFactionId,
        state: next,
        data: data,
        chargeRivals: false);
    final capped = _commit(next, before, values,
        sworn: banner.sworn,
        swore: banner.swore,
        released: banner.released,
        factionId: next.swornFactionId,
        cause: 'sworn_cap',
        chapter: chapter,
        day: day);
    next = capped.state;
    standing = capped.entry;
  }
  return RelationResult(state: next, entry: entry, standing: standing);
}

/// Every related pair's step as it stood at [chapter], by [relationKey]:
/// the snapshot of the latest chapter up to it in which a pair moved,
/// over the steps the story opens on. A chapter past every snapshot reads
/// the relations as they stand now.
Map<String, int> relationsAtChapter(
    PoliticsState state, int chapter, ClanData data) {
  final base = data.relations.baseSteps;
  final earlier = [
    for (final c in state.relationSnapshots.keys)
      if (c <= chapter) c,
  ]..sort();
  final moved = earlier.isEmpty
      ? const <String, int>{}
      : state.relationSnapshots[earlier.last]!;
  return {...base, ...moved};
}

/// Every faction's standing after each entry of the standing log that
/// moved any, for the Evolution chart: index 0 is where they stood before
/// the first, then one map per such entry. Factions in [ids] only.
List<Map<String, double>> standingHistory(
    PoliticsState state, ClanData data, List<String> ids) {
  final moving = [
    for (final e in state.standingLog)
      if (e.deltas.isNotEmpty) e,
  ];
  // Where each stood before its first logged change: its value then, less
  // that change; one never logged stands where it stands now.
  final start = <String, double>{};
  for (final id in ids) {
    final first = moving.where((e) => e.after.containsKey(id)).firstOrNull;
    start[id] = first == null
        ? state.standingOf(id, data)
        : first.after[id]! - (first.deltas[id] ?? 0);
  }
  final history = <Map<String, double>>[start];
  var current = start;
  for (final e in moving) {
    current = {
      for (final id in ids) id: e.after[id] ?? current[id]!,
    };
    history.add(current);
  }
  return history;
}

// --- The words ------------------------------------------------------------

/// A standing as shown: rounded, signed, with a true minus: "+31", "−14",
/// "0".
String formatStanding(num value) {
  final n = value.round();
  if (n > 0) return '+$n';
  if (n < 0) return '\u2212${-n}';
  return '0';
}

/// A change as shown, to the half where it has one: "+6", "+1.5", "−3".
String formatStandingDelta(num delta, {AppLanguage? language}) {
  final rounded = (delta * 10).round() / 10;
  final whole = rounded == rounded.roundToDouble();
  var digits = whole
      ? rounded.abs().round().toString()
      : rounded.abs().toStringAsFixed(1);
  if (language == AppLanguage.fr) digits = digits.replaceAll('.', ',');
  if (rounded > 0) return '+$digits';
  if (rounded < 0) return '\u2212$digits';
  return '0';
}

/// A cause as the log shows it. A cause is `kind` or `kind:detail`; a
/// kind with words (`standing_cause_<kind>`: offer, quest, favour,
/// intrigue, sea, edit, chapter, story, sworn_cap...) is said in
/// [language], the detail after it as written -- or as [describe] names
/// it (an offer's gift id read as the gift's name, see offers.dart), when
/// it gives a name; an unknown kind is shown as it is.
String standingCauseLabel(String cause, AppLanguage language,
    {String? Function(String kind, String detail)? describe}) {
  final split = cause.indexOf(':');
  final kind = split < 0 ? cause : cause.substring(0, split);
  final detail = split < 0 ? '' : cause.substring(split + 1).trim();
  final key = 'standing_cause_$kind';
  final label = trFor(language, key);
  final head = label == key ? kind : label;
  if (detail.isEmpty) return head;
  if (label == key) return cause;
  return '$head · ${describe?.call(kind, detail) ?? detail}';
}
