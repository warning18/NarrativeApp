part of '../factions.dart';

// The faction records as factions.json, subclans.json and titles.json
// parse them (Faction, SubClan, TitleDef and what they hold), with the
// shared readers of the data.

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

/// A faction's contingent in the Host (v1.196, factions.json `host`): what
/// it brings to the last battles, the Signs way ([effects], kinds this
/// version does not know kept in [rawEffects] and named in
/// [unknownEffectKinds]), and its line on the Host's sheet.
class HostContingent {
  const HostContingent({
    this.line = '',
    this.lineFr = '',
    this.effects = const [],
    this.rawEffects = const [],
    this.unknownEffectKinds = const [],
  });

  final String line;
  final String lineFr;
  final List<SignEffect> effects;
  final List<Map<String, dynamic>> rawEffects;
  final List<String> unknownEffectKinds;

  String lineFor(AppLanguage language) => _pick(language, line, lineFr);

  /// [raw] read, or null when there is no contingent.
  static HostContingent? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.cast<String, dynamic>();
    final effects = _signEffects(json['effects']);
    if (effects.raw.isEmpty && _text(json['line']).trim().isEmpty) {
      return null;
    }
    return HostContingent(
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
/// sub-clans, the skill-tree branches it sponsors, its objects, its
/// Sworn boon and its contingent in the Host (v1.196).
class Faction {
  const Faction({
    required this.patron,
    this.nameOf = '',
    this.nameOfFr = '',
    this.short = '',
    this.shortFr = '',
    this.motto = '',
    this.mottoFr = '',
    this.standsFor = '',
    this.standsForFr = '',
    this.ruling = '',
    this.rulingFr = '',
    this.lean = 0,
    this.startStanding = 0,
    this.subclans = const [],
    this.sponsors = const [],
    this.objects = const [],
    this.sworn,
    this.host,
    this.startPower = 0,
    this.seat = '',
    this.claims = const [],
    this.genderFr = 'm',
    this.nameToFr = '',
    this.brokenNews = '',
    this.brokenNewsFr = '',
    this.riskStat = '',
    this.riskyOffer = '',
    this.riskyOfferFr = '',
    this.templeName = '',
    this.templeNameFr = '',
    this.blessingName = '',
    this.blessingNameFr = '',
    this.templeLine = '',
    this.templeLineFr = '',
    this.templeLineHunted = '',
    this.templeLineHuntedFr = '',
    this.blessingGrants = '',
    this.blessingGrantsFr = '',
  });

  final Patron patron;

  /// The ability its curse lowers when a risky gift goes wrong
  /// (risky_gifts.dart); '' for a faction that never offers one.
  final String riskStat;

  /// What it says over a risky gift (Narrative's); '' for none.
  final String riskyOffer;
  final String riskyOfferFr;

  String riskyOfferFor(AppLanguage language) =>
      _pick(language, riskyOffer, riskyOfferFr);

  // The temple (temple.dart, Narrative's texts): the temples it keeps, its
  // blessing, what the keeper says (and says to a Hunted character), and a
  // line of what the blessing grants; '' for none.
  final String templeName;
  final String templeNameFr;
  final String blessingName;
  final String blessingNameFr;
  final String templeLine;
  final String templeLineFr;
  final String templeLineHunted;
  final String templeLineHuntedFr;
  final String blessingGrants;
  final String blessingGrantsFr;
  String templeNameFor(AppLanguage language) =>
      _pick(language, templeName, templeNameFr);
  String blessingNameFor(AppLanguage language) =>
      _pick(language, blessingName, blessingNameFr);
  String templeLineFor(AppLanguage language) =>
      _pick(language, templeLine, templeLineFr);
  String templeLineHuntedFor(AppLanguage language) =>
      _pick(language, templeLineHunted, templeLineHuntedFr);
  String blessingGrantsFor(AppLanguage language) =>
      _pick(language, blessingGrants, blessingGrantsFr);

  /// Where its power starts (factions.json `power`, clan_power.dart); 0
  /// for a faction with none.
  final int startPower;

  /// Its seat (a place id), the last place it gives up; '' for none.
  final String seat;

  /// The places it reaches for as its power grows, in order.
  final List<String> claims;

  /// The French name's gender and number ('m', 'f', 'mp', 'fp'), for the
  /// words that agree with it ("est tombée", "tiennent").
  final String genderFr;

  /// "au Dominion de la Lanterne": the French name after "à"; '' when the
  /// data has none.
  final String nameToFr;

  /// The news when the character breaks it as their nemesis (nemesis.dart,
  /// Narrative's per clan); '' tells the shared line.
  final String brokenNews;
  final String brokenNewsFr;

  /// Whether the French name is plural (`genderFr` 'mp' or 'fp').
  bool get pluralFr => genderFr.endsWith('p');

  /// Whether the French name is feminine.
  bool get feminineFr => genderFr.startsWith('f');

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

  /// What it wants of the character, in a few words ("Law, order, one
  /// flame over all"): factions.json `stands_for`, Narrative's.
  final String standsFor;
  final String standsForFr;

  /// How the clan is ruled: who holds power, how it passes, what a member
  /// owes (factions.json `ruling`, Narrative's).
  final String ruling;
  final String rulingFr;

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

  /// What it brings to the Host (v1.196, see throne.dart).
  final HostContingent? host;

  String get id => patron.id;
  FactionKind get kind => patron.kind;
  bool get isClan => kind == PatronKind.clan;

  /// A dead clan, remembered (v1.195: the Open Hand): no standing meter,
  /// a remembrance stage instead (see [openHandStageFrom]).
  bool get isLost => kind == PatronKind.lost;

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
  String standsForIn(AppLanguage language) =>
      _pick(language, standsFor, standsForFr);
  String rulingFor(AppLanguage language) => _pick(language, ruling, rulingFr);
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
        standsFor: _text(json['stands_for']),
        standsForFr: _text(json['stands_for_fr']),
        ruling: _text(json['ruling']).trim(),
        rulingFr: _text(json['ruling_fr']).trim(),
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
        host: HostContingent.tryParse(json['host']),
        startPower: _int(json['power']).clamp(0, 100),
        seat: _text(json['seat']).trim(),
        claims: _strings(json['claims']),
        genderFr: switch (_text(json['gender_fr']).trim()) {
          final g when const {'m', 'f', 'mp', 'fp'}.contains(g) => g,
          _ => 'm',
        },
        nameToFr: _text(json['nameTo_fr']).trim(),
        brokenNews: _text(json['brokenNews']).trim(),
        brokenNewsFr: _text(json['brokenNews_fr']).trim(),
        riskStat: _text(json['riskStat']).trim(),
        riskyOffer: _text(json['riskyOffer']).trim(),
        riskyOfferFr: _text(json['riskyOffer_fr']).trim(),
        templeName: _text(json['templeName']).trim(),
        templeNameFr: _text(json['templeName_fr']).trim(),
        blessingName: _text(json['blessingName']).trim(),
        blessingNameFr: _text(json['blessingName_fr']).trim(),
        templeLine: _text(json['templeLine']).trim(),
        templeLineFr: _text(json['templeLine_fr']).trim(),
        templeLineHunted: _text(json['templeLineHunted']).trim(),
        templeLineHuntedFr: _text(json['templeLineHunted_fr']).trim(),
        blessingGrants: _text(json['blessingGrants']).trim(),
        blessingGrantsFr: _text(json['blessingGrants_fr']).trim(),
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
