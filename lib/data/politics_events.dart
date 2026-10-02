import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import 'factions.dart';
import 'throne.dart';

/// Politics in motion (v1.195): the story's choices carry politics (see
/// story_politics.dart), and the coast moves on its own -- the politics
/// events of assets/gamedata/politics_events.json, which happen whether or
/// not the character is there, and are told as "News from the coast".
///
/// Everything here is pure, like factions.dart: [applyStoryPolitics] works
/// out what a choice's or a scene's politics do, [runDueEvents] fires the
/// events whose time has come (on a chapter change and a day's tick), and
/// [fireEvent] fires one now (a story choice's `event`, Edit Mode's "Fire
/// now"). Each takes the session's [PoliticsState] and flags and returns
/// a [CoastChange]: the state after, the flags, and what only the session
/// can do (offers due, companions leaving, titles given).
///
/// The file, keyed by event id like every gamedata table:
/// ```json
/// "lantern_bearer_failing": {
///   "id": "lantern_bearer_failing",
///   "name": "The Lantern-Bearer fails", "name_fr": "…",
///   "trigger": {"chapter": 1, "day": 3},
///   "once": true,
///   "variants": [
///     {"conditions": {"flags": ["warned_crows"]},
///      "effects": {"flags": ["x"]},
///      "news": "…", "news_fr": "…"},
///     {"effects": {"relations": [{"a": "crows", "b": "dominion",
///                                 "steps": -1}]},
///      "news": "…", "news_fr": "…"}
///   ]
/// }
/// ```
/// - **trigger:** every key given must hold: `chapter` (the chapter
///   reached is at least it), `day` (the story's day is at least it),
///   `chapterDay` (days into the chapter), `flag`/`flags` (held),
///   `notFlags` (none held). A list of triggers fires on any of them. An
///   event with no trigger fires only when the story or Edit Mode fires
///   it.
/// - **variants:** the first whose `conditions` hold fires; the last is the
///   default. Conditions: `flags`, `notFlags`, `anyFlags`,
///   `chapterAtLeast`, `chapterAtMost`, `standingAtLeast`/`standingAtMost`
///   ({faction: n}), `relationAtLeast`/`relationAtMost` ({"a|b": step}),
///   `marks` ({sub-clan: friend|foe|none}); and (v1.196, see throne.dart)
///   `claim` (a faction id, `any` or `none`, or a list: any of them),
///   `rungAtLeast` ({faction: 1 House, 2 claim, 3 Throne}) and
///   `throneWinner` (an id, `any` or `none`, or a list). A story choice's
///   `politicsIf` is written the same way (see [choicePoliticsGate]).
/// - **effects:** the shape of a choice's `politics`, plus `flags` to set.
///   `claim` and `throneWinner` are effects too: write a variant's
///   `conditions` and `effects` apart when it uses them.
/// - **once:** true unless written false; an event that is not once may
///   fire again in a later chapter.

// --- The events file --------------------------------------------------------

String _text(Object? raw) => raw?.toString().trim() ?? '';

List<String> _strings(Object? raw) {
  if (raw is String) return raw.trim().isEmpty ? const [] : [raw.trim()];
  if (raw is! List) return const [];
  return [
    for (final e in raw)
      if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
  ];
}

int? _optionalInt(Object? raw) {
  if (raw is num) return raw.round();
  if (raw is String) return int.tryParse(raw.trim());
  return null;
}

Map<String, num> _numbers(Object? raw) => {
      if (raw is Map)
        for (final e in raw.entries)
          if (e.value is num) e.key.toString(): e.value as num,
    };

String _pick(AppLanguage language, String en, String fr) =>
    language == AppLanguage.fr && fr.trim().isNotEmpty ? fr : en;

/// When an event fires by itself (see the file's notes above): every part
/// given must hold.
class EventTrigger {
  const EventTrigger({
    this.chapter,
    this.day,
    this.chapterDay,
    this.flags = const [],
    this.notFlags = const [],
  });

  final int? chapter;
  final int? day;
  final int? chapterDay;
  final List<String> flags;
  final List<String> notFlags;

  bool get isEmpty =>
      chapter == null && day == null && chapterDay == null && flags.isEmpty;

  /// Whether it holds in [world] with [flags] held.
  bool holds(CoastWorld world, Iterable<String> held) {
    if (isEmpty) return false;
    final set = held.toSet();
    if (chapter != null && world.chapter < chapter!) return false;
    if (day != null && world.day < day!) return false;
    if (chapterDay != null && world.chapterDay < chapterDay!) return false;
    if (!flags.every(set.contains)) return false;
    if (notFlags.any(set.contains)) return false;
    return true;
  }

  /// [raw] read: a map, `"chapter:3"`, `"day:3"`, `"flag:x"`, or a bare
  /// number (a chapter). Null when it says nothing.
  static EventTrigger? tryParse(Object? raw) {
    if (raw is num) return EventTrigger(chapter: raw.round());
    if (raw is String) {
      final split = raw.indexOf(':');
      if (split < 0) return null;
      final kind = raw.substring(0, split).trim();
      final value = raw.substring(split + 1).trim();
      return tryParse({'type': kind, 'value': value});
    }
    if (raw is! Map) return null;
    final type = _text(raw['type']).toLowerCase();
    final value = raw['value'];
    final trigger = EventTrigger(
      chapter: _optionalInt(raw['chapter'] ??
          raw['chapterAtLeast'] ??
          (type == 'chapter' ? value : null)),
      day: _optionalInt(
          raw['day'] ?? raw['dayAtLeast'] ?? (type == 'day' ? value : null)),
      chapterDay: _optionalInt(raw['chapterDay'] ??
          raw['dayInChapter'] ??
          (type == 'chapterday' ? value : null)),
      flags: [
        ..._strings(raw['flags']),
        ..._strings(raw['flag']),
        if (type == 'flag') ..._strings(value),
      ],
      notFlags: _strings(raw['notFlags']),
    );
    return trigger.isEmpty ? null : trigger;
  }
}

/// What must hold for a variant to fire (see the file's notes above).
class EventConditions {
  const EventConditions({
    this.flags = const [],
    this.notFlags = const [],
    this.anyFlags = const [],
    this.chapterAtLeast,
    this.chapterAtMost,
    this.standingAtLeast = const {},
    this.standingAtMost = const {},
    this.relationAtLeast = const {},
    this.relationAtMost = const {},
    this.marks = const {},
    this.claim = const [],
    this.rungAtLeast = const {},
    this.throneWinner = const [],
  });

  static const EventConditions none = EventConditions();

  final List<String> flags;
  final List<String> notFlags;
  final List<String> anyFlags;
  final int? chapterAtLeast;
  final int? chapterAtMost;
  final Map<String, num> standingAtLeast;
  final Map<String, num> standingAtMost;

  /// By "a|b", the pair written either way round.
  final Map<String, num> relationAtLeast;
  final Map<String, num> relationAtMost;
  final Map<String, String> marks;

  /// The claims any of which will do: faction ids, `any` (some claim) or
  /// `none` (no claim yet). Empty: any.
  final List<String> claim;

  /// The rung each faction must have reached (see rungFor).
  final Map<String, num> rungAtLeast;

  /// The factions on the Throne any of which will do (ids, `any` or
  /// `none`). Empty: any.
  final List<String> throneWinner;

  /// The keys conditions are written with.
  static const Set<String> keys = {
    'flags',
    'notFlags',
    'anyFlags',
    'chapterAtLeast',
    'chapterAtMost',
    'standingAtLeast',
    'standingAtMost',
    'relationAtLeast',
    'relationAtMost',
    'marks',
    'claim',
    'rungAtLeast',
    'throneWinner',
  };

  /// Whether [held] (a claim or the Throne's faction, '' for none) is one
  /// of [wanted] (ids, `any`, `none`).
  static bool _oneOf(List<String> wanted, String held) => wanted.any((w) =>
      w == 'any' ? held.isNotEmpty : (w == 'none' ? held.isEmpty : w == held));

  factory EventConditions.fromJson(Map<String, dynamic> json) =>
      EventConditions(
        flags: _strings(json['flags']),
        notFlags: _strings(json['notFlags']),
        anyFlags: _strings(json['anyFlags']),
        chapterAtLeast: _optionalInt(json['chapterAtLeast']),
        chapterAtMost: _optionalInt(json['chapterAtMost']),
        standingAtLeast: _numbers(json['standingAtLeast']),
        standingAtMost: _numbers(json['standingAtMost']),
        relationAtLeast: _numbers(json['relationAtLeast']),
        relationAtMost: _numbers(json['relationAtMost']),
        marks: {
          if (json['marks'] is Map)
            for (final e in (json['marks'] as Map).entries)
              e.key.toString(): _text(e.value),
        },
        claim: _strings(json['claim']),
        rungAtLeast: _numbers(json['rungAtLeast']),
        throneWinner: _strings(json['throneWinner']),
      );

  /// Whether they hold with [held] flags and [politics], in [world].
  bool holds(CoastWorld world, Iterable<String> held, PoliticsState politics) {
    if (claim.isNotEmpty && !_oneOf(claim, politics.claim)) return false;
    if (throneWinner.isNotEmpty &&
        !_oneOf(throneWinner, politics.throneWinner)) {
      return false;
    }
    for (final e in rungAtLeast.entries) {
      if (rungFor(e.key, politics, world.data) < e.value) return false;
    }
    final set = held.toSet();
    if (!flags.every(set.contains)) return false;
    if (notFlags.any(set.contains)) return false;
    if (anyFlags.isNotEmpty && !anyFlags.any(set.contains)) return false;
    if (chapterAtLeast != null && world.chapter < chapterAtLeast!) {
      return false;
    }
    if (chapterAtMost != null && world.chapter > chapterAtMost!) return false;
    for (final e in standingAtLeast.entries) {
      if (politics.standingOf(e.key, world.data) < e.value) return false;
    }
    for (final e in standingAtMost.entries) {
      if (politics.standingOf(e.key, world.data) > e.value) return false;
    }
    int step(String pair) {
      final ids = pair.split('|');
      if (ids.length != 2) return 4;
      return politics.relationStep(ids[0].trim(), ids[1].trim(), world.data) ??
          4;
    }

    for (final e in relationAtLeast.entries) {
      if (step(e.key) < e.value) return false;
    }
    for (final e in relationAtMost.entries) {
      if (step(e.key) > e.value) return false;
    }
    for (final e in marks.entries) {
      final want = subclanMarkNamed(e.value) ?? SubclanMark.none;
      if (politics.markOf(e.key) != want) return false;
    }
    return true;
  }
}

/// One way an event can go: its [conditions], its [effects] (a choice's
/// politics, flags included) and its news.
class EventVariant {
  const EventVariant({
    this.conditions = EventConditions.none,
    this.effects = const StoryPolitics(),
    this.news = '',
    this.newsFr = '',
  });

  final EventConditions conditions;
  final StoryPolitics effects;
  final String news;
  final String newsFr;

  String newsFor(AppLanguage language) => _pick(language, news, newsFr);

  static const Set<String> _newsKeys = {
    'news',
    'news_fr',
    'text',
    'text_fr',
    'conditions',
    'when',
    'if',
    'effects',
    'politics',
  };

  factory EventVariant.fromJson(Map<String, dynamic> json) {
    final rawConditions = json['conditions'] ?? json['when'] ?? json['if'];
    final conditions = rawConditions is Map
        ? EventConditions.fromJson(rawConditions.cast<String, dynamic>())
        // Written on the variant itself.
        : EventConditions.fromJson(json);
    final rawEffects = json['effects'] ?? json['politics'];
    final StoryPolitics? effects;
    if (rawEffects is Map) {
      effects = StoryPolitics.tryParse(rawEffects);
    } else {
      // Written on the variant itself: everything that is no condition
      // (when the conditions are there too) and no news.
      effects = StoryPolitics.tryParse({
        for (final e in json.entries)
          if (!_newsKeys.contains(e.key) &&
              !(rawConditions == null && EventConditions.keys.contains(e.key)))
            e.key: e.value,
      });
    }
    return EventVariant(
      conditions: conditions,
      effects: effects ?? const StoryPolitics(),
      news: _text(json['news'] ?? json['text']),
      newsFr: _text(json['news_fr'] ?? json['text_fr']),
    );
  }
}

/// One politics event of politics_events.json (see the file's notes
/// above).
class PoliticsEvent {
  const PoliticsEvent({
    required this.id,
    this.name = '',
    this.nameFr = '',
    this.triggers = const [],
    this.variants = const [],
    this.once = true,
  });

  final String id;
  final String name;
  final String nameFr;

  /// Any of them fires it; none: only the story or Edit Mode do.
  final List<EventTrigger> triggers;
  final List<EventVariant> variants;
  final bool once;

  /// Its name in [language], its id when it has none.
  String nameFor(AppLanguage language) {
    final own = _pick(language, name, nameFr);
    return own.isEmpty ? id : own;
  }

  factory PoliticsEvent.fromJson(String id, Map<String, dynamic> json) {
    final rawTrigger = json['trigger'] ??
        json['triggers'] ??
        // Written on the event itself.
        (json['chapter'] != null || json['day'] != null || json['flag'] != null
            ? {
                'chapter': json['chapter'],
                'day': json['day'],
                'flag': json['flag'],
              }
            : null);
    final triggers = [
      for (final t in rawTrigger is List ? rawTrigger : [rawTrigger])
        if (EventTrigger.tryParse(t) case final trigger?) trigger,
    ];
    final rawVariants = json['variants'];
    final variants = [
      if (rawVariants is List)
        for (final v in rawVariants)
          if (v is Map) EventVariant.fromJson(v.cast<String, dynamic>()),
      // An event with one way to go may write it on itself.
      if (rawVariants is! List &&
          (json['effects'] != null || json['news'] != null))
        EventVariant.fromJson({
          'effects': json['effects'] ?? const {},
          'news': json['news'],
          'news_fr': json['news_fr'],
        }),
    ];
    return PoliticsEvent(
      id: id,
      name: _text(json['name']),
      nameFr: _text(json['name_fr']),
      triggers: triggers,
      variants: variants,
      once: json['once'] != false,
    );
  }
}

/// politics_events.json parsed, by id, in the file's order: its records
/// (notes starting with `_` left out), or, written as a list under
/// `events`, each with its `id`.
Map<String, PoliticsEvent> parsePoliticsEvents(Map<String, dynamic> db) {
  final out = <String, PoliticsEvent>{};
  for (final entry in db.entries) {
    if (entry.key.startsWith('_')) continue;
    final value = entry.value;
    if (value is Map) {
      final json = value.cast<String, dynamic>();
      final id = _text(json['id']).isEmpty ? entry.key : _text(json['id']);
      out[id] = PoliticsEvent.fromJson(id, json);
    } else if (value is List && entry.key == 'events') {
      for (final e in value) {
        if (e is! Map) continue;
        final json = e.cast<String, dynamic>();
        final id = _text(json['id']);
        if (id.isNotEmpty) out[id] = PoliticsEvent.fromJson(id, json);
      }
    }
  }
  return out;
}

// --- The world the rules read ----------------------------------------------

/// What the politics rules read besides the session's politics and flags:
/// the clan [data], the [events], the chapter reached, the story's [day]
/// and the days into the chapter; and (v1.196) the patrons that gave a
/// sign this life ([signPatrons]), for the Choir or the Pit in the Host.
class CoastWorld {
  const CoastWorld({
    required this.data,
    this.events = const {},
    this.chapter = 1,
    this.day = 1,
    this.chapterDay = 1,
    this.signPatrons = const [],
  });

  final ClanData data;
  final Map<String, PoliticsEvent> events;
  final int chapter;
  final int day;
  final int chapterDay;
  final List<String> signPatrons;
}

/// An offer the politics brought: [factionId] guaranteed a place, logged
/// under [cause].
class CoastOffer {
  const CoastOffer({required this.factionId, required this.cause});

  final String factionId;
  final String cause;
}

/// A companion an intrigue's outcome moves: `leaves`, `disapproves`,
/// `approves` (see intrigues.json).
class CompanionTurn {
  const CompanionTurn({required this.companionId, required this.change});

  final String companionId;
  final String change;
}

/// What the politics did: the [politics] and [flags] after, and what only
/// the session can do -- the [offers] due, the [companions] moved, the
/// [titles] given; the [news] told and the events [fired]; whether the
/// Host [mustered] (v1.196: the session shows it). [applied] false:
/// nothing happened at all (politics applied before, or no event due).
class CoastChange {
  const CoastChange({
    required this.politics,
    required this.flags,
    this.offers = const [],
    this.companions = const [],
    this.titles = const [],
    this.news = const [],
    this.fired = const [],
    this.mustered = false,
    this.applied = true,
  });

  final PoliticsState politics;
  final List<String> flags;
  final List<CoastOffer> offers;
  final List<CompanionTurn> companions;
  final List<String> titles;
  final List<CoastNews> news;
  final List<String> fired;
  final bool mustered;
  final bool applied;
}

// --- The rules --------------------------------------------------------------

/// The key a choice's politics are remembered under (see
/// [PoliticsState.appliedKeys]): the node's id and the choice's place.
String choicePoliticsKey(String nodeId, int choiceIndex) =>
    'story:$nodeId:choice$choiceIndex';

/// The key a scene's politics on entry are remembered under.
String enterPoliticsKey(String nodeId) => 'story:$nodeId:enter';

/// The flag of intrigue [id] reaching [stage] (see intrigueStageFrom).
String intrigueStageFlag(String id, int stage) => 'intrigue_${id}_stage_$stage';

/// The flag of intrigue [id] settling on [outcome] (see
/// intrigueOutcomeFrom).
String intrigueOutcomeFlag(String id, int outcome) =>
    'intrigue_${id}_outcome_$outcome';

/// How far an event fired from the story may set off others before the
/// chain stops.
const int _maxEventDepth = 8;

class _Coast {
  _Coast(this.world, this.politics, List<String> flags) : flags = [...flags];

  final CoastWorld world;
  PoliticsState politics;
  final List<String> flags;
  final offers = <CoastOffer>[];
  final companions = <CompanionTurn>[];
  final titles = <String>[];
  final news = <CoastNews>[];
  final fired = <String>[];
  var mustered = false;

  ClanData get data => world.data;

  void addFlag(String flag) {
    if (flag.isNotEmpty && !flags.contains(flag)) flags.add(flag);
  }

  void standing(String factionId, num delta, String cause) {
    politics = applyStandingChange(politics, factionId, delta, cause,
            data: data, chapter: world.chapter, day: world.day)
        .state;
  }

  void mark(String subclanId, SubclanMark mark, String cause) {
    politics = setSubclanMark(politics, subclanId, mark, cause,
            data: data, chapter: world.chapter, day: world.day)
        .state;
  }

  void apply(StoryPolitics p, String cause, int depth) {
    for (final e in p.standing.entries) {
      standing(e.key, e.value, cause);
    }
    for (final e in p.marks.entries) {
      final m = subclanMarkNamed(e.value);
      if (m != null) mark(e.key, m, cause);
    }
    for (final r in p.relations) {
      politics = shiftRelation(politics, r.a, r.b, r.steps, cause,
              data: data, chapter: world.chapter, day: world.day)
          .state;
    }
    p.flags.forEach(addFlag);
    openHandFlagsUpTo(p.remembrance).forEach(addFlag);
    for (final step in p.intrigues) {
      intrigue(step, cause);
    }
    // The climb (v1.196, see throne.dart): the claim before the crown, the
    // crown before the muster, so the Host flies the Throne's banner.
    if (p.claim.isNotEmpty) claim(p.claim);
    p.pledges.forEach(pledge);
    if (p.throneWinner.isNotEmpty) crown(p.throneWinner);
    if (p.muster) muster();
    if (p.offerFrom.isNotEmpty) {
      offers.add(CoastOffer(factionId: p.offerFrom, cause: cause));
    }
    for (final id in p.events) {
      fireById(id, depth + 1);
    }
  }

  /// A line in the standing log that moved nothing: a pledge, the crown,
  /// the muster (or a claim with nothing left to raise).
  void log(String cause, String factionId) {
    politics = politics.copyWith(
      standingLog: _capped(
        politics.standingLog,
        StandingLogEntry(
          chapter: world.chapter,
          day: world.day,
          cause: cause,
          factionId: factionId,
        ),
        maxStandingLogEntries,
      ),
    );
  }

  /// [id] taken as the claim: the last one renounced (its standing
  /// [renounceCost] down, logged `renounce:<id>`), the flag `claim_<id>`
  /// the only faction's claim flag held (the story's own `claim_` flags
  /// stay), and its standing raised to the Sworn tier with the banner (see
  /// raiseToClaim, logged `claim`).
  void claim(String id) {
    final previous = politics.claim;
    if (previous != id) {
      if (previous.isNotEmpty) {
        final renounce = 'renounce:$previous';
        final renounced = setStandingValue(politics, previous,
            politics.standingOf(previous, data) - renounceCost, renounce,
            data: data, chapter: world.chapter, day: world.day);
        politics = renounced.state;
        if (!renounced.changed) log(renounce, previous);
      }
      politics = politics.copyWith(claim: id);
    }
    // The other factions' claim flags go; the story's own claim_ flags
    // (7500's claim_kept) stay.
    final others = {
      for (final other in [...data.factions.keys, previous])
        if (other.isNotEmpty && other != id) claimFlag(other),
    };
    flags.removeWhere(others.contains);
    addFlag(claimFlag(id));
    final raised = raiseToClaim(politics, id, 'claim',
        data: data, chapter: world.chapter, day: world.day);
    politics = raised.state;
    if (!raised.changed && previous != id) log('claim', id);
  }

  /// [id] pledged to the cause: it joins the Host whatever its standing.
  void pledge(String id) {
    if (id.isEmpty) return;
    if (!politics.hasPledged(id)) {
      politics = politics.copyWith(pledged: [...politics.pledged, id]);
      log('pledge', id);
    }
    addFlag(pledgedFlag(id));
  }

  /// [id] crowned: on the Throne, its flags set (any other winner's
  /// dropped) and its throne titles given.
  void crown(String id) {
    final previous = politics.throneWinner;
    if (previous != id) {
      politics = politics.copyWith(throneWinner: id);
      log('throne', id);
    }
    final others = {
      for (final other in [...data.factions.keys, previous])
        if (other.isNotEmpty && other != id) throneWinnerFlag(other),
    };
    flags.removeWhere(others.contains);
    addFlag(throneWinnerFlag(id));
    addFlag(onThroneFlag);
    for (final title in throneTitlesOf(id, data)) {
      if (!titles.contains(title.id)) titles.add(title.id);
    }
  }

  /// The Host mustered now (see hostFor): kept, and its flags set in
  /// place of an earlier muster's.
  void muster() {
    final host =
        hostFor(politics: politics, data: data, signPatrons: world.signPatrons)
            .musteredOn(world.chapter, world.day);
    politics = politics.copyWith(host: host);
    flags.removeWhere((f) => isMusterFlag(f, data.factions.keys));
    hostFlagsFor(host).forEach(addFlag);
    log('muster', host.banner);
    mustered = true;
  }

  void intrigue(IntrigueStep step, String cause) {
    final stage = step.stage;
    if (stage != null && stage >= 1 && stage <= intrigueStageNames.length) {
      addFlag(intrigueStageFlag(step.id, stage));
    }
    final outcome = step.outcome;
    // An intrigue ends once: a second outcome changes nothing.
    if (outcome == null ||
        outcome < 0 ||
        intrigueOutcomeFrom(flags, step.id) != null) {
      return;
    }
    addFlag(intrigueOutcomeFlag(step.id, outcome));
    addFlag(intrigueStageFlag(step.id, intrigueStageNames.length));
    final record = data.intrigues[step.id];
    if (record == null || outcome >= record.outcomes.length) return;
    for (final effect in record.outcomes[outcome].effects) {
      outcomeEffect(effect, cause);
    }
  }

  /// One of an outcome's effects, in its five shapes: standing with a
  /// faction (only while a flag named by its `condition` is held, when it
  /// has one), a sub-clan's mark, a companion moved, a title given; a note
  /// is only told (the Intrigues tab shows it).
  void outcomeEffect(IntrigueEffect e, String cause) {
    final condition = e.condition.trim();
    if (condition.isNotEmpty && !flags.contains(condition)) return;
    if (e.factionId.isNotEmpty && e.delta != 0) {
      standing(e.factionId, e.delta, cause);
    }
    if (e.subclanId.isNotEmpty && e.mark != null) {
      mark(e.subclanId, e.mark!, cause);
    }
    if (e.companionId.isNotEmpty && e.change.isNotEmpty) {
      companions
          .add(CompanionTurn(companionId: e.companionId, change: e.change));
    }
    if (e.titleId.isNotEmpty &&
        data.titles.containsKey(e.titleId) &&
        !titles.contains(e.titleId)) {
      titles.add(e.titleId);
    }
  }

  void fireById(String id, int depth) {
    final event = world.events[id];
    if (event == null || depth > _maxEventDepth) return;
    if (event.once && politics.hasFired(id)) return;
    fire(event, depth);
  }

  /// The variant [event] takes now: the first whose conditions hold, the
  /// last by default.
  int variantOf(PoliticsEvent event) {
    final variants = event.variants;
    for (var i = 0; i < variants.length - 1; i++) {
      if (variants[i].conditions.holds(world, flags, politics)) return i;
    }
    return variants.isEmpty ? 0 : variants.length - 1;
  }

  void fire(PoliticsEvent event, int depth) {
    final index = variantOf(event);
    final variant =
        index < event.variants.length ? event.variants[index] : null;
    final cause = 'event:${event.id}';
    final previous = politics.firedEvents[event.id];
    // Recorded first: an event whose effects fire it again stops there.
    politics = politics.copyWith(
      firedEvents: {
        ...politics.firedEvents,
        event.id: FiredEvent(
          variant: index,
          chapter: world.chapter,
          day: world.day,
          count: (previous?.count ?? 0) + 1,
        ),
      },
      standingLog: _capped(
        politics.standingLog,
        StandingLogEntry(
          chapter: world.chapter,
          day: world.day,
          cause: cause,
          note: variant?.news ?? '',
          noteFr: variant?.newsFr ?? '',
        ),
        maxStandingLogEntries,
      ),
    );
    fired.add(event.id);
    if (variant != null &&
        (variant.news.isNotEmpty || variant.newsFr.isNotEmpty)) {
      final told = CoastNews(
        eventId: event.id,
        variant: index,
        chapter: world.chapter,
        day: world.day,
        text: variant.news,
        textFr: variant.newsFr,
      );
      news.add(told);
      politics =
          politics.copyWith(news: _capped(politics.news, told, maxCoastNews));
    }
    if (variant != null) apply(variant.effects, cause, depth);
  }

  /// Whether [event] may fire by itself now: never fired (or, not once,
  /// last fired in an earlier chapter) and one of its triggers holds.
  bool due(PoliticsEvent event) {
    if (event.triggers.isEmpty) return false;
    final last = politics.firedEvents[event.id];
    if (last != null && (event.once || last.chapter >= world.chapter)) {
      return false;
    }
    return event.triggers.any((t) => t.holds(world, flags));
  }

  CoastChange result({required bool applied}) => CoastChange(
        politics: politics,
        flags: flags,
        offers: offers,
        companions: companions,
        titles: titles,
        news: news,
        fired: fired,
        mustered: mustered,
        applied: applied,
      );
}

List<T> _capped<T>(List<T> list, T entry, int cap) {
  final next = [...list, entry];
  return next.length <= cap ? next : next.sublist(next.length - cap);
}

/// What story politics [p] do, for [cause] (`story:<nodeId>`), with
/// [politics] and [flags] as they stand in [world]:
/// - **standing** with each faction, through the ripple (see
///   applyStandingChange); **marks**; **relations** shifted;
/// - **flags** set; **remembrance** n sets `open_hand_1` .. `open_hand_<n>`;
/// - **intrigue** stage n sets `intrigue_<id>_stage_<n>`; an outcome sets
///   `intrigue_<id>_outcome_<i>` (and the Choice stage) and applies the
///   outcome's effects from intrigues.json (once an intrigue has ended,
///   another outcome does nothing);
/// - **offerFrom** an offer due with that faction guaranteed a place;
/// - **event** fired now (see [fireEvent]).
/// Everything logged under [cause]. With [key] (see [choicePoliticsKey],
/// [enterPoliticsKey]) the politics are applied once: under a key already
/// applied nothing happens, and [CoastChange.applied] is false.
CoastChange applyStoryPolitics(
  StoryPolitics p, {
  required String cause,
  required PoliticsState politics,
  required List<String> flags,
  required CoastWorld world,
  String key = '',
}) {
  final coast = _Coast(world, politics, flags);
  if (key.isNotEmpty && politics.applied(key)) {
    return coast.result(applied: false);
  }
  if (key.isNotEmpty) {
    coast.politics = coast.politics
        .copyWith(appliedKeys: [...coast.politics.appliedKeys, key]);
  }
  coast.apply(p, cause, 0);
  return coast.result(applied: true);
}

/// Fires every event whose time has come in [world] (see the file's notes
/// above), in the file's order, again and again while one sets off
/// another: each takes its variant, applies its effects (logged under
/// `event:<id>`, after a line with its news), is recorded as fired, and
/// tells its news. [CoastChange.applied] is false when none was due.
CoastChange runDueEvents({
  required PoliticsState politics,
  required List<String> flags,
  required CoastWorld world,
}) {
  final coast = _Coast(world, politics, flags);
  for (var pass = 0; pass < _maxEventDepth; pass++) {
    var any = false;
    for (final event in world.events.values) {
      if (!coast.due(event)) continue;
      coast.fire(event, 0);
      any = true;
    }
    if (!any) break;
  }
  return coast.result(applied: coast.fired.isNotEmpty);
}

/// Fires event [eventId] now: the story's `event`, or Edit Mode's "Fire
/// now" ([force]: even one that has fired). A `once` event that has fired
/// does nothing otherwise, nor an unknown id.
CoastChange fireEvent(
  String eventId, {
  required PoliticsState politics,
  required List<String> flags,
  required CoastWorld world,
  bool force = false,
}) {
  final coast = _Coast(world, politics, flags);
  final event = world.events[eventId];
  if (event == null || (!force && event.once && politics.hasFired(eventId))) {
    return coast.result(applied: false);
  }
  coast.fire(event, 0);
  return coast.result(applied: true);
}

/// The variant [event] would take now (see [runDueEvents]).
int eventVariantFor(
  PoliticsEvent event, {
  required PoliticsState politics,
  required List<String> flags,
  required CoastWorld world,
}) =>
    _Coast(world, politics, flags).variantOf(event);

/// Whether [event] would fire by itself now.
bool eventDue(
  PoliticsEvent event, {
  required PoliticsState politics,
  required List<String> flags,
  required CoastWorld world,
}) =>
    _Coast(world, politics, flags).due(event);

// --- The words --------------------------------------------------------------

/// The muted line under a choice: what it moves, "Vigil +5 · Dominion −5",
/// then its marks ("Inquisition: foe"), each faction by its short name
/// in [language] (the French `short_fr`); then (v1.196) the climb's
/// moves by full name: "Claim: The Cinder Compact (gives up the Grey
/// Vigil)" -- the claim given up read off [politics] -- "Joins your
/// cause: …", "The Throne: …". Empty when [p] is hidden or moves none of
/// it.
String politicsHint(StoryPolitics? p, ClanData data, AppLanguage language,
    {PoliticsState politics = PoliticsState.empty}) {
  if (p == null || !p.hasHint) return '';
  String name(String id) => throneFactionName(id, data, language);
  final previous = politics.claim;
  final parts = <String>[
    for (final e in p.standing.entries)
      // A no-break space: "Vigil +5" never splits across lines.
      '${data.faction(e.key)?.shortFor(language) ?? e.key} '
          '${formatStandingDelta(e.value, language: language)}',
    for (final e in p.marks.entries)
      if (subclanMarkNamed(e.value) case final mark?)
        trFor(language, 'politics_hint_mark_${mark.name}').replaceAll(
            '{name}', data.subclan(e.key)?.nameFor(language) ?? e.key),
    if (p.claim.isNotEmpty)
      previous.isNotEmpty && previous != p.claim
          ? trFor(language, 'throne_hint_claim_renounce')
              .replaceAll('{name}', name(p.claim))
              .replaceAll('{old}', midSentenceName(name(previous)))
          : trFor(language, 'throne_hint_claim')
              .replaceAll('{name}', name(p.claim)),
    for (final id in p.pledges)
      trFor(language, 'throne_hint_pledge').replaceAll('{name}', name(id)),
    if (p.throneWinner.isNotEmpty)
      trFor(language, 'throne_hint_throne')
          .replaceAll('{name}', name(p.throneWinner)),
  ];
  return parts.join(' · ');
}

// --- A choice's politics gate (v1.196) ---------------------------------------

/// How a story choice stands behind its politics gate
/// ([StoryChoice.politicsIf]): [open] (no gate, or it holds), [locked]
/// (it fails and the choice has a `lockedText`: shown shut with it) or
/// [hidden] (it fails: not shown at all).
enum ChoiceGate { open, locked, hidden }

/// Whether the conditions written in [politicsIf] (the shape of an event
/// variant's `conditions`, see [EventConditions]) hold with [politics]
/// and [flags] in [world]. An empty gate always holds.
bool politicsIfHolds(
  Map<String, dynamic> politicsIf, {
  required PoliticsState politics,
  required Iterable<String> flags,
  required CoastWorld world,
}) =>
    politicsIf.isEmpty ||
    EventConditions.fromJson(politicsIf).holds(world, flags, politics);

/// How [choice] stands behind its politics gate (see [ChoiceGate]).
ChoiceGate choicePoliticsGate(
  StoryChoice choice, {
  required PoliticsState politics,
  required Iterable<String> flags,
  required CoastWorld world,
}) {
  if (politicsIfHolds(choice.politicsIf,
      politics: politics, flags: flags, world: world)) {
    return ChoiceGate.open;
  }
  return (choice.lockedText ?? '').trim().isNotEmpty ||
          (choice.lockedTextFr ?? '').trim().isNotEmpty
      ? ChoiceGate.locked
      : ChoiceGate.hidden;
}

/// An event cause's name for the log (`event:<id>`, see
/// standingCauseLabel's `describe`): the event's name, null for one
/// [events] doesn't know.
String? eventCauseName(
        String id, Map<String, PoliticsEvent> events, AppLanguage language) =>
    events[id]?.nameFor(language);
