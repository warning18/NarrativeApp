part of '../factions.dart';

// What the session keeps besides PoliticsState itself: sub-clan marks,
// the standing and relations logs, the coast news, fired events, the host
// and the story nemesis.

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

Map<String, String> _texts(Object? raw) => {
      if (raw is Map)
        for (final e in raw.entries)
          if (_text(e.value).trim().isNotEmpty)
            e.key.toString(): _text(e.value).trim(),
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
    this.note = '',
    this.noteFr = '',
    this.placeId = '',
    this.how = '',
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

  /// What happened, in words (v1.195): a politics event's news, logged
  /// under `event:<id>` before what it moved.
  final String note;
  final String noteFr;

  String noteFor(AppLanguage language) => _pick(language, note, noteFr);

  /// A place changing hands (cause 'territory', wave 18 step 2): the place
  /// and how ([givePlace]'s cause: 'war', 'influence', 'town', 'claim'…).
  final String placeId;
  final String how;

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
        if (note.isNotEmpty) 'note': note,
        if (noteFr.isNotEmpty) 'note_fr': noteFr,
        if (placeId.isNotEmpty) 'place': placeId,
        if (how.isNotEmpty) 'how': how,
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
        note: _text(json['note']),
        noteFr: _text(json['note_fr']),
        placeId: _text(json['place']),
        how: _text(json['how']),
      );
}

/// One piece of "News from the coast" (v1.195): what a politics event
/// ([eventId], its [variant]) told when it fired, on [chapter]'s [day],
/// in both languages; [read] once the camp has shown it.
class CoastNews {
  const CoastNews({
    required this.eventId,
    this.variant = 0,
    this.chapter = 0,
    this.day = 0,
    this.text = '',
    this.textFr = '',
    this.read = false,
  });

  final String eventId;
  final int variant;
  final int chapter;
  final int day;
  final String text;
  final String textFr;
  final bool read;

  String textFor(AppLanguage language) => _pick(language, text, textFr);

  CoastNews markedRead() => CoastNews(
        eventId: eventId,
        variant: variant,
        chapter: chapter,
        day: day,
        text: text,
        textFr: textFr,
        read: true,
      );

  Map<String, dynamic> toJson() => {
        'event': eventId,
        'variant': variant,
        'chapter': chapter,
        'day': day,
        if (text.isNotEmpty) 'text': text,
        if (textFr.isNotEmpty) 'text_fr': textFr,
        if (read) 'read': true,
      };

  factory CoastNews.fromJson(Map<String, dynamic> json) => CoastNews(
        eventId: _text(json['event']),
        variant: _int(json['variant']),
        chapter: _int(json['chapter']),
        day: _int(json['day']),
        text: _text(json['text']),
        textFr: _text(json['text_fr']),
        read: json['read'] == true,
      );
}

/// A politics event that has fired: the [variant] it took, when, and how
/// many times ([count]: more than one only for an event not `once`, or
/// fired again from Edit Mode).
class FiredEvent {
  const FiredEvent({
    this.variant = 0,
    this.chapter = 0,
    this.day = 0,
    this.count = 1,
  });

  final int variant;
  final int chapter;
  final int day;
  final int count;

  Map<String, dynamic> toJson() => {
        'variant': variant,
        'chapter': chapter,
        'day': day,
        if (count != 1) 'count': count,
      };

  factory FiredEvent.fromJson(Map<String, dynamic> json) => FiredEvent(
        variant: _int(json['variant']),
        chapter: _int(json['chapter']),
        day: _int(json['day']),
        count: _int(json['count'], 1),
      );
}

/// News kept (the oldest go first).
const int maxCoastNews = 200;

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

/// The Host (v1.196, see throne.dart): the force the character raised
/// over the game, which fights beside the party in the last battles --
/// the [banner] (the faction on the Throne, or the claim; '' for none),
/// the [allies] (faction ids, in the data's order) and the [houses]
/// (friend sub-clans, one champion each). Kept in [PoliticsState.host]
/// once mustered, on [chapter]'s [day]; a [chapter] of 0 is a Host worked
/// out but not mustered.
class Host {
  const Host({
    this.banner = '',
    this.allies = const [],
    this.houses = const [],
    this.chapter = 0,
    this.day = 0,
  });

  static const Host none = Host();

  final String banner;
  final List<String> allies;
  final List<String> houses;
  final int chapter;
  final int day;

  /// Whether it was mustered (see [PoliticsState.host]).
  bool get mustered => chapter > 0;

  /// The factions that came: the banner first, then the allies.
  List<String> get contingents => [
        if (banner.isNotEmpty) banner,
        ...allies,
      ];

  /// Everyone who came: the contingents and the Houses.
  int get size => contingents.length + houses.length;

  bool get isEmpty => banner.isEmpty && allies.isEmpty && houses.isEmpty;

  /// The same Host, mustered on [chapter]'s [day].
  Host musteredOn(int chapter, int day) => Host(
        banner: banner,
        allies: allies,
        houses: houses,
        chapter: max(1, chapter),
        day: day,
      );

  Map<String, dynamic> toJson() => {
        if (banner.isNotEmpty) 'banner': banner,
        if (allies.isNotEmpty) 'allies': allies,
        if (houses.isNotEmpty) 'houses': houses,
        'chapter': chapter,
        'day': day,
      };

  /// [raw] read; [none] for anything unreadable.
  factory Host.fromJson(Object? raw) {
    if (raw is! Map) return none;
    return Host(
      banner: _text(raw['banner']).trim(),
      allies: _strings(raw['allies']),
      houses: _strings(raw['houses']),
      chapter: _int(raw['chapter']),
      day: _int(raw['day']),
    );
  }
}

/// The story's own nemesis: the Dominion, from a new game's first page
/// (it wants the piece of the Shroud the character's family kept;
/// nemesis.dart).
const String storyNemesisClan = 'dominion';

/// [PoliticsState.nemesisReason] of [storyNemesisClan] as the story opens.
const String nemesisReasonStory = 'story';

/// Where the character stands with the coast, as the session keeps it:
/// - [standings]: standing with each faction it has moved with (any
///   other is still at its `startStanding`, see [standingOf]);
/// - [marks]: each sub-clan's mark, when it is one (see [markOf]);
/// - [swornFactionId]: the one faction the character is sworn to, '' for
///   none;
/// - [relationSteps]: each pair of clans that has moved off its opening
///   step (see [relationStep]), and [relationSnapshots], how those stood
///   after each chapter in which one moved (see [relationsAtChapter]);
/// - [standingLog] and [relationsLog], oldest first;
/// - (v1.195) [appliedKeys], the story politics already applied (a choice
///   taken or a scene entered again applies nothing), [firedEvents], the
///   politics events that have fired, and [news], what they told, oldest
///   first;
/// - (v1.196, see throne.dart) the [claim], the faction the character
///   heads ('' for none); the [throneWinner] crowned; the factions
///   [pledged] to the cause; and the [host] once mustered.
///
/// A new game, a permadeath and a New Game+ start from [empty]: the world
/// starts over.
