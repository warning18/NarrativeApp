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
///
/// Eleven steps (v1.233): five up from Unknown (Known, Friendly, Friend,
/// Trusted, Sworn) and, as their bad equivalents, five down (Wary,
/// Unfriendly, Resented, Hostile, Hunted).
enum StandingTier {
  hunted,
  hostile,
  resented,
  unfriendly,
  wary,
  unknown,
  known,
  friendly,
  friend,
  trusted,
  sworn,
}

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
  StandingTier.resented: StandingTierInfo(
      min: -25, max: -19, priceFactor: 1.30, color: 0xFFDB5F44),
  StandingTier.unfriendly: StandingTierInfo(
      min: -18, max: -12, priceFactor: 1.22, color: 0xFFDC6A3C),
  StandingTier.wary:
      StandingTierInfo(min: -11, max: -6, priceFactor: 1.15, color: 0xFFE0762B),
  StandingTier.unknown:
      StandingTierInfo(min: -5, max: 5, priceFactor: 1.0, color: 0xFFA8A194),
  StandingTier.known:
      StandingTierInfo(min: 6, max: 11, priceFactor: 0.95, color: 0xFF4FB0B0),
  StandingTier.friendly:
      StandingTierInfo(min: 12, max: 18, priceFactor: 0.92, color: 0xFF5FB7A0),
  StandingTier.friend:
      StandingTierInfo(min: 19, max: 25, priceFactor: 0.89, color: 0xFF6BB985),
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
const double _allyRippleShare = 0.25;

/// Its rivals lose this much of a gain with it (a loss leaves them be).
const double _rivalRippleShare = 0.5;

/// Relation steps from which two factions count as allies, and up to
/// which they count as rivals (see [alliesOf], [rivalsOf]).
const int _allyMinStep = 6;
const int _rivalMaxStep = 3;

/// Standing at which a faction becomes the sworn one (the Sworn tier's
/// floor); only one faction is sworn at a time.
const int swornThreshold = 61;

/// What swearing to a faction costs with each of its rivals, once.
const int _swornRivalCost = 20;

/// While a faction is sworn, its rivals stop here (the top of Known), and
/// every other faction at the top of Trusted: there is one banner.
const int swornRivalCap = 25;
const int swornOthersCap = 60;

/// The steps a relation can take, Blood feud to Allies.
const int minRelationStep = 1;
const int maxRelationStep = 7;

/// Log entries kept (the oldest go first): enough for a whole game.
const int maxStandingLogEntries = 500;
const int _maxRelationsLogEntries = 200;

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

// --- The rules ------------------------------------------------------------

/// [factionId]'s allies now: every faction it stands with on step
/// [_allyMinStep] or above (Trade, Allies), in the data's order.
List<String> alliesOf(String factionId, PoliticsState state, ClanData data) =>
    _related(factionId, state, data, (step) => step >= _allyMinStep);

/// [factionId]'s rivals now: every faction it stands with on step
/// [_rivalMaxStep] or below (Blood feud, War, Hostile).
List<String> rivalsOf(String factionId, PoliticsState state, ClanData data) =>
    _related(factionId, state, data, (step) => step <= _rivalMaxStep);

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
///   [_swornRivalCost] ([chargeRivals]);
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
  // Of a fallen clan (clan_crisis.dart), no new oath until a banner of
  // one's own.
  if (current.isEmpty && state.fallenOf.isEmpty) {
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
          values[rival] = _clampStanding(values[rival]! - _swornRivalCost);
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

/// [state] with [entry] logged (a line that moves no standing: the
/// patron's gifts, see patron_stats.dart).
PoliticsState withStandingLogEntry(
        PoliticsState state, StandingLogEntry entry) =>
    state.copyWith(
        standingLog:
            _appendCapped(state.standingLog, entry, maxStandingLogEntries));

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
///   [_swornRivalCost]; while it is sworn its rivals stop at
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
  if (delta == 0 ||
      !data.factions.containsKey(factionId) ||
      data.factions[factionId]!.isLost) {
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
    move(ally, change * _allyRippleShare);
  }
  if (change > 0) {
    for (final rival in rivalsOf(factionId, state, data)) {
      move(rival, -change * _rivalRippleShare);
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

// --- Loyalty's price (v5.2 step 3) ------------------------------------------

/// The relation step of two factions that are tense: neither rivals nor
/// allies, but not at peace either (Tense).
const int _tenseStep = 4;

/// What each new chapter costs a patron's neighbours (see
/// [applyLoyaltyDrift]): its rivals while you are Trusted with it; its
/// rivals, its tense neighbours and (a gain) its allies while you are
/// sworn to it.
const int trustedRivalDrift = -2;
const int swornRivalDrift = -4;
const int swornTenseDrift = -2;
const int swornAllyDrift = 1;

/// [factionId]'s tense neighbours now: every faction it stands with on
/// [_tenseStep].
List<String> tenseWith(String factionId, PoliticsState state, ClanData data) =>
    _related(factionId, state, data, (step) => step == _tenseStep);

/// The clan the character is loyal to, whose favour cools its rivals: the
/// sworn one, else the clan stood highest with at Trusted or above (the
/// first in the data on a tie); '' for none.
String loyaltyPatron(PoliticsState state, ClanData data) {
  if (state.swornFactionId.isNotEmpty) return state.swornFactionId;
  var best = '';
  var bestValue = double.negativeInfinity;
  for (final id in data.factions.keys) {
    if (!canBeSworn(id, data)) continue;
    final value = state.standingOf(id, data);
    if (!standingTierFor(value).isAtLeast(StandingTier.trusted)) continue;
    if (value > bestValue) {
      best = id;
      bestValue = value;
    }
  }
  return best;
}

/// What a new chapter's drift ([applyLoyaltyDrift]) moves, by faction:
/// - the patron ([loyaltyPatron]) at Trusted: its rivals
///   [trustedRivalDrift];
/// - sworn to it: its rivals [swornRivalDrift], its tense neighbours
///   [swornTenseDrift], its allies [swornAllyDrift];
/// - none, or Friend and below: nothing.
Map<String, int> loyaltyDrift(PoliticsState state, ClanData data) {
  final patron = loyaltyPatron(state, data);
  if (patron.isEmpty) return const {};
  final sworn = state.isSworn(patron);
  bool counts(String id) =>
      id != patron &&
      data.factions.containsKey(id) &&
      !data.factions[id]!.isLost;
  return {
    for (final id in rivalsOf(patron, state, data))
      if (counts(id)) id: sworn ? swornRivalDrift : trustedRivalDrift,
    if (sworn) ...{
      for (final id in tenseWith(patron, state, data))
        if (counts(id)) id: swornTenseDrift,
      for (final id in alliesOf(patron, state, data))
        if (counts(id)) id: swornAllyDrift,
    },
  };
}

/// A new chapter's price of loyalty: [loyaltyDrift] applied, with no
/// ripple, logged as `loyalty:<patron>` on [chapter]'s [day]. The banner's
/// caps still hold. Nothing moves (and nothing is logged) without a
/// patron at Trusted or above.
StandingResult applyLoyaltyDrift(
  PoliticsState state, {
  required ClanData data,
  int chapter = 0,
  int day = 0,
}) {
  final drift = loyaltyDrift(state, data);
  if (drift.isEmpty) return StandingResult(state: state);
  final patron = loyaltyPatron(state, data);
  final before = _allStandings(state, data);
  final values = {...before};
  for (final MapEntry(:key, :value) in drift.entries) {
    if (!values.containsKey(key)) continue;
    values[key] = _clampStanding(values[key]! + value);
  }
  final banner = _applyBanner(values,
      sworn: state.swornFactionId,
      preferred: patron,
      state: state,
      data: data,
      chargeRivals: false);
  return _commit(state, before, values,
      sworn: banner.sworn,
      swore: banner.swore,
      released: banner.released,
      factionId: patron,
      cause: 'loyalty:$patron',
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
  if (!data.factions.containsKey(factionId) ||
      data.factions[factionId]!.isLost) {
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

/// A claim taken (v1.196, see throne.dart): standing with [factionId]
/// raised to at least [swornThreshold], with no ripple, and the banner
/// theirs -- the clan the character heads is the one they are sworn to,
/// so any other faction sworn is released and the caps hold for the
/// rest (no rival pays the swearing's cost: the caps already take it).
/// A faction that can never be sworn (a tribe, the Choir, the Pit, the
/// Open Hand) moves nothing here.
StandingResult raiseToClaim(
  PoliticsState state,
  String factionId,
  String cause, {
  required ClanData data,
  int chapter = 0,
  int day = 0,
}) {
  if (!canBeSworn(factionId, data)) return StandingResult(state: state);
  final before = _allStandings(state, data);
  final values = {...before};
  values[factionId] = max(values[factionId]!, swornThreshold.toDouble());
  final banner = _applyBanner(values,
      sworn: '',
      preferred: factionId,
      state: state,
      data: data,
      chargeRivals: false);
  final previous = state.swornFactionId;
  return _commit(state, before, values,
      sworn: banner.sworn,
      swore: banner.sworn != previous ? banner.sworn : '',
      released: previous.isNotEmpty && previous != banner.sworn ? previous : '',
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
        _appendCapped(state.relationsLog, entry, _maxRelationsLogEntries),
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
