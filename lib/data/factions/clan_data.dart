part of '../factions.dart';

// The Open Hand's flags and stages, the table parsers, and ClanData:
// all the clan data in one place.

// --- The Open Hand (v1.195) -------------------------------------------------

/// The dead clan's id in factions.json (kind `lost`): the drawers whose
/// banner the character carries.
const String _openHandId = 'open_hand';

/// The remembrance stages, one a chapter: the cloth, the name, the blood
/// answers, the ledger, the truth, the banner.
const int openHandStages = 6;

/// The flag the story sets at remembrance stage [n] (`open_hand_<n>`).
String _openHandFlag(int n) => 'open_hand_$n';

/// The flag set when the banner is raised on the Hollow Shore.
const String bannerRaisedFlag = 'banner_raised';

/// The stage from which "Your own hand" may take a fourth place in an
/// offer, at [ownHandChance]; from [openHandStages] with the banner
/// raised it always does (see offers.dart).
const int ownHandFromStage = 3;
const double ownHandChance = 0.25;

/// What taking the Open Hand's gift costs with the Dominion once the
/// banner is raised: they hunt the drawers.
const int ownHandBannerCost = -2;

/// The stage the Open Hand's remembrance has reached: the highest
/// `open_hand_<n>` held (1..[openHandStages]), 0 for none.
int openHandStageFrom(Iterable<String> flags) {
  var stage = 0;
  for (final flag in flags) {
    if (!flag.startsWith('open_hand_')) continue;
    final n = int.tryParse(flag.substring('open_hand_'.length));
    if (n != null && n >= 1 && n <= openHandStages && n > stage) stage = n;
  }
  return stage;
}

/// The flags of remembrance [stage]: every stage up to it, so a scene
/// asking for an earlier one still finds it.
List<String> openHandFlagsUpTo(int stage) => [
      for (var n = 1; n <= stage.clamp(0, openHandStages); n++)
        _openHandFlag(n),
    ];

/// Whether the banner has been raised (see [bannerRaisedFlag]).
bool bannerRaisedIn(Iterable<String> flags) => flags.contains(bannerRaisedFlag);

/// The remembrance stage [title] comes with: its source `remembrance:<n>`,
/// else 3 for "Drawer" and 6 for "Last of the Open Hand" (by id or
/// English name); null for any other title.
int? _remembranceStageOfTitle(TitleDef title) {
  final source = title.source.trim().toLowerCase();
  if (source.startsWith('remembrance:')) {
    return int.tryParse(source.substring('remembrance:'.length));
  }
  final id = title.id.trim().toLowerCase();
  final name = title.name.trim().toLowerCase();
  if (id == 'drawer' || name == 'drawer') return 3;
  if (id == 'last_of_the_open_hand' || name == 'last of the open hand') {
    return openHandStages;
  }
  return null;
}

/// The remembrance titles [flags] have earned: each whose stage the
/// remembrance has reached, the last stage's only once the banner is
/// raised ("Last of the Open Hand").
List<String> remembranceTitlesFor(Iterable<String> flags, ClanData data) {
  final stage = openHandStageFrom(flags);
  if (stage == 0) return const [];
  final raised = bannerRaisedIn(flags);
  return [
    for (final title in data.titles.values)
      if (_remembranceStageOfTitle(title) case final at?)
        if (at >= 1 && stage >= at && (at < openHandStages || raised)) title.id,
  ];
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

  /// The lost clans (the Open Hand), in the file's order.
  List<Faction> get lost => ofKind(PatronKind.lost);

  /// The Open Hand's record: [_openHandId], else the first lost clan; null
  /// before the data has one.
  Faction? get openHand =>
      factions[_openHandId] ?? (lost.isEmpty ? null : lost.first);

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
