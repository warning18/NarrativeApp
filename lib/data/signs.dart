import 'dart:math';

import '../combat/face_keywords.dart';
import '../combat/gear_effects.dart';
import '../combat/status_effect.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';

/// Signs (v1.192): the Hades-like half of levelling. Factions -- patrons --
/// draw a power on the character, three to choose from at a time: a banner
/// knot, a painted sigil, a mark cut in stone, a tattoo, an incantation, an
/// angel's vow or a demon's pact. Levels, stat and skill points and the
/// level-up perks (perks.dart) stay as they are; signs are on top of them,
/// and a different kit each life: a permadeath takes them all (favour with
/// the patrons stays, like a New Game+ legacy).
///
/// Everything here is pure and takes a [Random], like perks.dart: the
/// patrons are the factions of assets/gamedata/factions.json (v1.193, see
/// factions.dart) and the signs come from signs.json (see [parsePatrons],
/// [parseSigns]); the session keeps what is held (see [HeldSign]) and the
/// offer waiting (see [SignOffer]); a fight reads the sum of it all as one
/// [SignEffects].

/// A patron's place in the world: one of the clans (the Lantern Dominion
/// and the five clans of the coast), a tribe met on the way, the Choir or
/// the Pit, who shut each other out, or a lost clan (v1.195: the Open
/// Hand), dead and remembered, who never comes the ordinary ways.
enum PatronKind { clan, tribe, otherworld, lost }

/// Where a sign sits: one sign at most on each of the four face slots, as
/// many passives as come.
enum SignSlot { strike, guard, mend, spell, passive }

/// How strong a sign was drawn (see [signRarityMultipliers]).
enum SignRarity { common, rare, epic, heroic }

const Map<SignRarity, double> signRarityMultipliers = {
  SignRarity.common: 1.0,
  SignRarity.rare: 1.5,
  SignRarity.epic: 2.0,
  SignRarity.heroic: 2.5,
};

/// The odds (out of 100) of each rarity on one card, before Luck and
/// favour move some of Common's share up (see [signRarityOdds]).
const Map<SignRarity, int> signRarityBaseOdds = {
  SignRarity.common: 62,
  SignRarity.rare: 27,
  SignRarity.epic: 9,
  SignRarity.heroic: 2,
};

/// Each point of Luck moves 1% of a card's odds from Common to Rare, up to
/// this many.
const int luckRarityCap = 15;

/// Each favour level with the patron moves 1% from Common to Epic, up to
/// this many.
const int favourRarityCap = 5;

/// Titan's Blood raises a held sign one level, up to this one.
const int maxSignLevel = 5;

/// Each level past the first adds this share of the sign's value again.
const double signLevelStep = 0.5;

/// However rare and raised, a chance on a sign never passes this.
const int signChanceCap = 60;

/// The cards an offer shows, when the patron has that many to give.
const int signOfferSize = 3;

/// Odds an eligible duo sign takes one of an offer's places.
const double duoOfferChance = 0.35;

/// Odds an offer comes from a patron that already gave a sign this life
/// (when one can still offer), rather than from a new one.
const double returningPatronChance = 0.6;

/// A tribe's weight among the new patrons, a clan's or the Choir's or the
/// Pit's being 1: tribes are met on the way, and offer less often.
const double tribeOfferWeight = 0.5;

/// Signs taken from a patron for each favour level with them.
const int favourPerLevel = 3;
const int maxFavourLevel = 5;

/// The Choir (angels) and the Pit (demons): their signs are vows and pacts.
const String choirPatronId = 'choir';
const String pitPatronId = 'pit';

/// Alignment moved by taking a Choir sign (up) or a Pit sign (down).
const int otherworldAlignmentShift = 3;

/// A Choir vow falls silent below this alignment score.
const int vowAlignmentFloor = 0;

/// A pact's curse lasts this many fights when its record names none.
const int defaultPactFights = 3;

/// A low-health sign's bonus holds while health is under this share of
/// the maximum.
const double signLowHealthShare = 0.35;

/// Odds a won Elite fight leaves a drop of Titan's Blood (a hunt always
/// does).
const double eliteTitanBloodChance = 0.25;

/// The Material icons a faction may name in factions.json `icon` (see
/// patronIconFor in sign_widgets.dart): no image is drawn for a patron.
const List<String> patronIconNames = [
  'flag',
  'brush',
  'palette',
  'landscape',
  'terrain',
  'hexagon',
  'local_fire_department',
  'whatshot',
  'water_drop',
  'menu_book',
  'history_edu',
  'auto_stories',
  'edit',
  'fitness_center',
  'hardware',
  'waves',
  'sailing',
  'anchor',
  'eco',
  'spa',
  'park',
  'local_florist',
  'wb_sunny',
  'light_mode',
  'brightness_7',
  'dark_mode',
  'nightlight',
  'bedtime',
  'dangerous',
  'shield',
  'bolt',
  'star',
  'auto_awesome',
  'pets',
  'visibility',
  'diamond',
  'church',
  'castle',
  'music_note',
  'notifications',
  'flare',
  'key',
  'vpn_key',
  'lock',
  'gavel',
  'balance',
  'lightbulb',
  'emoji_objects',
  'forest',
  'grass',
  'water',
  'construction',
  'handyman',
  'healing',
  'favorite',
  'handshake',
  'paid',
  'remove_red_eye',
  'psychology',
  'flag_circle',
  'local_police',
  'security',
  'nights_stay',
  'cloud',
  'ac_unit',
  // v1.195: the Open Hand's raised, open hands.
  'back_hand',
  'front_hand',
  'pan_tool',
];

/// Keywords a strike sign may lend the Attack faces: those that make sense
/// on a blow. Echo would turn the Attack into a copy of another face.
const Set<FaceKeyword> signStrikeKeywords = {
  FaceKeyword.cleave,
  FaceKeyword.pierce,
  FaceKeyword.growth,
  FaceKeyword.pain,
  FaceKeyword.steady,
};

// --- Effects --------------------------------------------------------------

/// Everything a sign can do. The slot kinds act only on faces of their own
/// type rolled by the player (strike: Attack, guard: Defend, mend: Heal,
/// spell: Mana faces and spells); the others are passives, the sea's
/// three included.
enum SignEffectKind {
  strikeDamagePercent,
  strikeFlat,
  strikeElement,
  strikeStatus,
  strikeKeyword,
  guardBlockPercent,
  guardFlat,
  guardHeal,
  guardRetaliate,
  guardStatus,
  mendPercent,
  mendParty,
  mendShield,
  mendCleanse,
  manaFlat,
  spellDamagePercent,
  spellCostLess,
  spellStatus,
  maxHealth,
  armor,
  critChance,
  dodgeChance,
  lifestealPercent,
  thorns,
  manaOnHit,
  maxMana,
  secondWind,
  potionBonus,
  goldPercent,
  xpPercent,
  allyDamagePercent,
  stat,
  partyStartBlock,
  startMomentum,
  lowHealthDamagePercent,
  killHeal,
  afterFightHealPercent,
  firstRoundDamagePercent,
  partyMaxHealthPercent,
  shipHullPercent,
  shipGunPercent,
  voyageCalm,

  // v1.194: the clans' Sworn boons (factions.json `_newKinds`).
  /// The first [SignEffect.value] enemy blows aimed at the player in a
  /// fight are cancelled before they resolve (the Lantern's Writ).
  writFace,

  /// Each enemy's intent shows this many rounds further (Open Eyes).
  intentLookahead,

  /// The first [SignEffect.value] times a player strike meets an enemy's
  /// raised guard in a fight, the whole guard breaks (the Compact edge).
  compactEdge,

  /// Gold stolen per hit the player lands, at most [crowsPriceMaxHits]
  /// hits a fight (the Crow's Price).
  crowsPrice,

  /// The first [SignEffect.value] Curses laid on the player's die in a
  /// fight are lifted at once (the Ember face).
  emberFace,

  /// Every Poison the player inflicts lasts this many more turns.
  poisonExtraTurns,
}

/// The most hits a fight's Crow's Price steals on (see
/// [SignEffectKind.crowsPrice]).
const int crowsPriceMaxHits = 10;

SignEffectKind? signEffectKindNamed(String? name) {
  for (final kind in SignEffectKind.values) {
    if (kind.name == name) return kind;
  }
  return null;
}

/// Kinds whose number is a count or a switch, not a strength: rarity and
/// level leave it as written (a cleanse lifts that many afflictions).
const Set<SignEffectKind> _unscaledKinds = {
  SignEffectKind.mendCleanse,
  SignEffectKind.secondWind,
  SignEffectKind.strikeKeyword,
  SignEffectKind.writFace,
  SignEffectKind.intentLookahead,
  SignEffectKind.compactEdge,
  SignEffectKind.emberFace,
  SignEffectKind.poisonExtraTurns,
};

/// Kinds whose value is itself a chance, capped at [signChanceCap] like a
/// status's.
const Set<SignEffectKind> _chanceValueKinds = {
  SignEffectKind.critChance,
  SignEffectKind.dodgeChance,
  SignEffectKind.voyageCalm,
};

/// The ability scores a `stat` sign may raise (the session's own names).
const List<String> signStatNames = [
  'strength',
  'dexterity',
  'constitution',
  'intelligence',
  'wisdom',
  'charisma',
  'luck',
  'perception',
];

StatusEffectType? _statusNamed(String? name) {
  final lower = name?.trim().toLowerCase() ?? '';
  for (final type in StatusEffectType.values) {
    if (type.name == lower) return type;
  }
  return null;
}

/// One thing a sign does, as written in signs.json (see [scaled] for the
/// numbers a held sign actually uses). [value] is the effect's number;
/// a status effect's [chance], [duration] and [magnitude] are its own.
class SignEffect {
  const SignEffect({
    required this.kind,
    this.value = 0,
    this.element = '',
    this.status,
    this.chance = 0,
    this.duration = 0,
    this.magnitude = 0,
    this.keyword,
    this.stat = '',
  });

  final SignEffectKind kind;
  final int value;

  /// strikeElement's element ('Fire', as on dice faces and gear).
  final String element;

  /// strikeStatus / guardStatus / spellStatus: what is inflicted, at what
  /// odds, for how many turns and how hard (Poison's damage, Weaken's %).
  final StatusEffectType? status;
  final int chance;
  final int duration;
  final int magnitude;

  /// strikeKeyword's keyword (see [signStrikeKeywords]).
  final FaceKeyword? keyword;

  /// stat's ability score (see [signStatNames]).
  final String stat;

  /// [json] read, or null when its kind isn't one the game knows.
  static SignEffect? tryParse(Map<String, dynamic> json) {
    final kind = signEffectKindNamed(json['kind']?.toString());
    if (kind == null) return null;
    int number(String key) => (json[key] as num?)?.round() ?? 0;
    final status = _statusNamed(json['status']?.toString()) ??
        (kind == SignEffectKind.guardStatus ? StatusEffectType.weaken : null);
    return SignEffect(
      kind: kind,
      // A chance-valued kind may carry its number as `chance`; a cleanse
      // with none lifts one affliction.
      value: kind == SignEffectKind.mendCleanse
          ? max(1, number('value'))
          : number('value') != 0 || !_chanceValueKinds.contains(kind)
              ? number('value')
              : number('chance'),
      element: json['element']?.toString() ?? '',
      status: status,
      chance: number('chance'),
      duration: max(1, number('duration')),
      magnitude: number('magnitude'),
      keyword: faceKeywordNamed(json['keyword']?.toString() ?? ''),
      stat: json['stat']?.toString().trim().toLowerCase() ?? '',
    );
  }

  /// The status this effect inflicts when its chance comes up.
  StatusEffect? get inflicted => status == null
      ? null
      : StatusEffect(
          type: status!,
          remainingTurns: max(1, duration),
          magnitude: magnitude);

  /// This effect at [rarity] and [level]: its value and chance scaled (see
  /// [signPower]), a chance capped at [signChanceCap]; durations and a
  /// status's strength stay as written.
  SignEffect scaled(SignRarity rarity, int level) {
    if (_unscaledKinds.contains(kind)) return this;
    final power = signPower(rarity, level);
    int scale(int base) => base <= 0 ? base : max(1, (base * power).round());
    final scaledValue = scale(value);
    return SignEffect(
      kind: kind,
      value: _chanceValueKinds.contains(kind)
          ? min(signChanceCap, scaledValue)
          : scaledValue,
      element: element,
      status: status,
      chance: min(signChanceCap, scale(chance)),
      duration: duration,
      magnitude: magnitude,
      keyword: keyword,
      stat: stat,
    );
  }
}

/// A sign's worth at [rarity] and [level]: the rarity's multiplier, then
/// half the value again for each level past the first.
double signPower(SignRarity rarity, int level) =>
    signRarityMultipliers[rarity]! *
    (1 + signLevelStep * (level.clamp(1, maxSignLevel) - 1));

/// [base] at [rarity] and [level] (see [SignEffect.scaled]).
int scaleSignValue(int base, SignRarity rarity, int level) =>
    base <= 0 ? base : max(1, (base * signPower(rarity, level)).round());

// --- Pacts ----------------------------------------------------------------

/// What a Pit sign costs first: for [SignPact.fights] fights after it is
/// taken the curse holds and the gift doesn't, then the gift holds for
/// good.
enum PactCurse { enemyDamagePercent, startHealthPercentLoss, goldPercentLoss }

PactCurse? pactCurseNamed(String? name) {
  for (final curse in PactCurse.values) {
    if (curse.name == name) return curse;
  }
  return null;
}

class SignPact {
  const SignPact({
    required this.curse,
    required this.value,
    this.fights = defaultPactFights,
  });

  final PactCurse curse;
  final int value;
  final int fights;

  /// [raw] read, or null when it is no pact (null, an empty list the data
  /// editor leaves, an unknown curse).
  static SignPact? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final curse = pactCurseNamed(raw['curse']?.toString());
    if (curse == null) return null;
    return SignPact(
      curse: curse,
      value: (raw['value'] as num?)?.round() ?? 0,
      fights: max(1, (raw['fights'] as num?)?.round() ?? defaultPactFights),
    );
  }
}

// --- Patrons and signs ----------------------------------------------------

String _pick(AppLanguage language, String en, String fr) =>
    language == AppLanguage.fr && fr.trim().isNotEmpty ? fr : en;

List<String> _strings(Object? raw) => [
      if (raw is List)
        for (final e in raw)
          if (e.toString().trim().isNotEmpty) e.toString(),
    ];

int? _optionalInt(Object? raw) {
  if (raw is num) return raw.round();
  if (raw is String && raw.trim().isNotEmpty) return int.tryParse(raw.trim());
  return null;
}

/// '#8B1E3F', '8B1E3F' or '0xFF8B1E3F' as an ARGB int; a dim gold when it
/// can't be read.
int parsePatronColor(Object? raw) {
  var text = raw?.toString().trim() ?? '';
  if (text.startsWith('#')) text = text.substring(1);
  if (text.toLowerCase().startsWith('0x')) text = text.substring(2);
  final value = int.tryParse(text, radix: 16);
  if (value == null) return 0xFFB08D3C;
  return text.length <= 6 ? 0xFF000000 | value : value;
}

/// A faction as Signs sees it (factions.json, see factions.dart): who
/// offers, in what colour and words, and when they may. Everything shown
/// comes from the data.
class Patron {
  const Patron({
    required this.id,
    required this.name,
    this.nameFr = '',
    required this.kind,
    this.color = 0xFFB08D3C,
    this.icon = '',
    this.intro = '',
    this.introFr = '',
    this.greetings = const [],
    this.greetingsFr = const [],
    this.unlockFlag = '',
    this.minAlignment,
    this.maxAlignment,
  });

  final String id;
  final String name;
  final String nameFr;
  final PatronKind kind;

  /// ARGB.
  final int color;

  /// A Material icon's name (see patronIconFor in sign_widgets.dart).
  final String icon;

  /// The line shown the first time they offer, then one of [greetings].
  final String intro;
  final String introFr;
  final List<String> greetings;
  final List<String> greetingsFr;

  /// A story flag that must be set before they offer ('' for none).
  final String unlockFlag;

  /// The alignment score they offer within, when set.
  final int? minAlignment;
  final int? maxAlignment;

  String nameFor(AppLanguage language) => _pick(language, name, nameFr);
  String introFor(AppLanguage language) => _pick(language, intro, introFr);

  List<String> greetingsFor(AppLanguage language) =>
      language == AppLanguage.fr && greetingsFr.isNotEmpty
          ? greetingsFr
          : greetings;

  /// Greeting [index] in [language] (wrapping round), '' when there is
  /// none.
  String greetingFor(AppLanguage language, int index) {
    final lines = greetingsFor(language);
    return lines.isEmpty ? '' : lines[index.abs() % lines.length];
  }

  /// Whether the story lets them offer: their flag set, the alignment in
  /// their range.
  bool reachable({required Iterable<String> flags, required int alignment}) {
    if (unlockFlag.isNotEmpty && !flags.contains(unlockFlag)) return false;
    if (minAlignment != null && alignment < minAlignment!) return false;
    if (maxAlignment != null && alignment > maxAlignment!) return false;
    return true;
  }

  factory Patron.fromJson(String id, Map<String, dynamic> json) => Patron(
        id: id,
        name: json['name']?.toString() ?? id,
        nameFr: json['name_fr']?.toString() ?? '',
        kind: PatronKind.values
                .where((k) => k.name == json['kind']?.toString())
                .firstOrNull ??
            PatronKind.clan,
        color: parsePatronColor(json['color']),
        icon: json['icon']?.toString() ?? '',
        intro: json['intro']?.toString() ?? '',
        introFr: json['intro_fr']?.toString() ?? '',
        greetings: _strings(json['greetings']),
        greetingsFr: _strings(json['greetings_fr']),
        unlockFlag: json['unlockFlag']?.toString().trim() ?? '',
        minAlignment: _optionalInt(json['minAlignment']),
        maxAlignment: _optionalInt(json['maxAlignment']),
      );
}

/// One sign as written in signs.json.
class SignDef {
  const SignDef({
    required this.id,
    required this.patronId,
    required this.slot,
    required this.name,
    this.nameFr = '',
    this.flavour = '',
    this.flavourFr = '',
    this.effects = const [],
    this.requiresPatrons = const [],
    this.pact,
    this.unknownEffectKinds = const [],
  });

  final String id;
  final String patronId;
  final SignSlot slot;
  final String name;
  final String nameFr;
  final String flavour;
  final String flavourFr;
  final List<SignEffect> effects;

  /// A duo sign's two patrons: offered only once a sign of each is held.
  final List<String> requiresPatrons;

  /// A Pit sign's price.
  final SignPact? pact;

  /// Effect kinds in the record the game doesn't know (skipped; the
  /// content test keeps this empty).
  final List<String> unknownEffectKinds;

  bool get isDuo => requiresPatrons.isNotEmpty;

  String nameFor(AppLanguage language) => _pick(language, name, nameFr);
  String flavourFor(AppLanguage language) =>
      _pick(language, flavour, flavourFr);

  /// Whether [patronId] may offer this sign: its own patron, or one of a
  /// duo's two.
  bool offeredBy(String patronId) =>
      this.patronId == patronId || requiresPatrons.contains(patronId);

  factory SignDef.fromJson(String id, Map<String, dynamic> json) {
    final effects = <SignEffect>[];
    final unknown = <String>[];
    for (final raw in (json['effects'] as List?) ?? const []) {
      if (raw is! Map) continue;
      final effect = SignEffect.tryParse(raw.cast<String, dynamic>());
      if (effect == null) {
        unknown.add(raw['kind']?.toString() ?? '?');
      } else {
        effects.add(effect);
      }
    }
    return SignDef(
      id: id,
      patronId: json['patron']?.toString() ?? '',
      slot: SignSlot.values
              .where((s) => s.name == json['slot']?.toString())
              .firstOrNull ??
          SignSlot.passive,
      name: json['name']?.toString() ?? id,
      nameFr: json['name_fr']?.toString() ?? '',
      flavour: json['flavour']?.toString() ?? '',
      flavourFr: json['flavour_fr']?.toString() ?? '',
      effects: effects,
      requiresPatrons: _strings(json['requiresPatrons']),
      pact: SignPact.tryParse(json['pact']),
      unknownEffectKinds: unknown,
    );
  }
}

/// factions.json parsed as patrons, by id: every record (a key starting
/// with `_` is a note, not a faction).
Map<String, Patron> parsePatrons(Map<String, dynamic> db) => {
      for (final entry in db.entries)
        if (entry.value is Map && !entry.key.startsWith('_'))
          entry.key: Patron.fromJson(
              entry.key, (entry.value as Map).cast<String, dynamic>()),
    };

/// signs.json parsed, by id.
Map<String, SignDef> parseSigns(Map<String, dynamic> db) => {
      for (final entry in db.entries)
        if (entry.value is Map)
          entry.key: SignDef.fromJson(
              entry.key, (entry.value as Map).cast<String, dynamic>()),
    };

// --- What the session keeps -----------------------------------------------

/// A sign the character carries: how rare it was drawn, how far Titan's
/// Blood has raised it, and the fights its pact still has to run.
class HeldSign {
  const HeldSign({
    required this.signId,
    this.rarity = SignRarity.common,
    this.level = 1,
    this.pactFightsLeft = 0,
  });

  final String signId;
  final SignRarity rarity;
  final int level;
  final int pactFightsLeft;

  bool get pactPending => pactFightsLeft > 0;

  HeldSign copyWith({SignRarity? rarity, int? level, int? pactFightsLeft}) =>
      HeldSign(
        signId: signId,
        rarity: rarity ?? this.rarity,
        level: level ?? this.level,
        pactFightsLeft: pactFightsLeft ?? this.pactFightsLeft,
      );

  Map<String, dynamic> toJson() => {
        'signId': signId,
        'rarity': rarity.name,
        'level': level,
        if (pactFightsLeft > 0) 'pactFightsLeft': pactFightsLeft,
      };

  factory HeldSign.fromJson(Map<String, dynamic> json) => HeldSign(
        signId: json['signId']?.toString() ?? '',
        rarity: _rarityNamed(json['rarity']?.toString()),
        level: ((json['level'] as num?)?.toInt() ?? 1).clamp(1, maxSignLevel),
        pactFightsLeft: max(0, (json['pactFightsLeft'] as num?)?.toInt() ?? 0),
      );

  @override
  bool operator ==(Object other) =>
      other is HeldSign &&
      other.signId == signId &&
      other.rarity == rarity &&
      other.level == level &&
      other.pactFightsLeft == pactFightsLeft;

  @override
  int get hashCode => Object.hash(signId, rarity, level, pactFightsLeft);
}

SignRarity _rarityNamed(String? name) =>
    SignRarity.values.where((r) => r.name == name).firstOrNull ??
    SignRarity.common;

/// One card of an offer: the sign and the rarity it was drawn at.
class SignCard {
  const SignCard({required this.signId, required this.rarity});

  final String signId;
  final SignRarity rarity;

  Map<String, dynamic> toJson() => {'signId': signId, 'rarity': rarity.name};

  factory SignCard.fromJson(Map<String, dynamic> json) => SignCard(
        signId: json['signId']?.toString() ?? '',
        rarity: _rarityNamed(json['rarity']?.toString()),
      );

  @override
  bool operator ==(Object other) =>
      other is SignCard && other.signId == signId && other.rarity == rarity;

  @override
  int get hashCode => Object.hash(signId, rarity);
}

/// The offer waiting: one patron's cards, drawn once and kept until one is
/// taken, so closing the app never loses or redraws it. [firstMeeting]:
/// the patron's first offer, which opens with their intro; otherwise
/// [greetingIndex] picks the greeting.
class SignOffer {
  const SignOffer({
    required this.patronId,
    required this.cards,
    this.firstMeeting = false,
    this.greetingIndex = 0,
  });

  final String patronId;
  final List<SignCard> cards;
  final bool firstMeeting;
  final int greetingIndex;

  SignCard? cardFor(String signId) =>
      cards.where((c) => c.signId == signId).firstOrNull;

  Map<String, dynamic> toJson() => {
        'patronId': patronId,
        'cards': [for (final c in cards) c.toJson()],
        'firstMeeting': firstMeeting,
        'greetingIndex': greetingIndex,
      };

  /// [raw] read, or null for no offer.
  static SignOffer? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final cards = [
      for (final c in (raw['cards'] as List?) ?? const [])
        if (c is Map) SignCard.fromJson(c.cast<String, dynamic>()),
    ];
    final patronId = raw['patronId']?.toString() ?? '';
    if (patronId.isEmpty || cards.isEmpty) return null;
    return SignOffer(
      patronId: patronId,
      cards: cards,
      firstMeeting: raw['firstMeeting'] == true,
      greetingIndex: (raw['greetingIndex'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SignOffer &&
      other.patronId == patronId &&
      other.firstMeeting == firstMeeting &&
      other.greetingIndex == greetingIndex &&
      other.cards.length == cards.length &&
      [for (var i = 0; i < cards.length; i++) other.cards[i] == cards[i]]
          .every((same) => same);

  @override
  int get hashCode =>
      Object.hash(patronId, firstMeeting, greetingIndex, Object.hashAll(cards));
}

// --- The rules --------------------------------------------------------------

/// Sign offers a level-up from [levelBefore] to [levelAfter] brings: one
/// for every odd level reached (3, 5, 7...). Even levels bring a perk (see
/// perkPicksFor), so every level brings one or the other.
int signPicksFor(int levelBefore, int levelAfter) {
  var picks = 0;
  for (var level = max(1, levelBefore) + 1; level <= levelAfter; level++) {
    if (level.isOdd) picks++;
  }
  return picks;
}

/// The favour level [favour] signs taken from a patron add up to.
int favourLevelFor(int favour) =>
    min(maxFavourLevel, max(0, favour) ~/ favourPerLevel);

/// One card's odds of each rarity (out of 100): each point of [luck] moves
/// 1% from Common to Rare (up to [luckRarityCap]), each [favourLevel] 1%
/// from Common to Epic (up to [favourRarityCap]).
Map<SignRarity, int> signRarityOdds({int luck = 0, int favourLevel = 0}) {
  final toRare = luck.clamp(0, luckRarityCap);
  final toEpic = favourLevel.clamp(0, favourRarityCap);
  return {
    SignRarity.common: signRarityBaseOdds[SignRarity.common]! - toRare - toEpic,
    SignRarity.rare: signRarityBaseOdds[SignRarity.rare]! + toRare,
    SignRarity.epic: signRarityBaseOdds[SignRarity.epic]! + toEpic,
    SignRarity.heroic: signRarityBaseOdds[SignRarity.heroic]!,
  };
}

/// One card's rarity (see [signRarityOdds]); a duo sign is never Common.
SignRarity rollSignRarity({
  required Random random,
  int luck = 0,
  int favourLevel = 0,
  bool duo = false,
}) {
  final odds = signRarityOdds(luck: luck, favourLevel: favourLevel);
  var roll = random.nextInt(100);
  var drawn = SignRarity.heroic;
  for (final rarity in SignRarity.values) {
    roll -= odds[rarity]!;
    if (roll < 0) {
      drawn = rarity;
      break;
    }
  }
  return duo && drawn == SignRarity.common ? SignRarity.rare : drawn;
}

/// The Choir or the Pit, whichever gave a sign this life first: the other
/// no longer offers until the life ends. Null while neither has.
String? otherworldClaimOf(
        List<String> patronsThisLife, Map<String, Patron> patrons) =>
    patronsThisLife
        .where((id) => patrons[id]?.kind == PatronKind.otherworld)
        .firstOrNull;

/// Whether [patron] may offer at all this life: the story lets them (see
/// [Patron.reachable]), and they aren't closed off -- the Choir once the
/// Pit has given a sign (and the other way round).
bool patronOpen(
  Patron patron, {
  required Iterable<String> flags,
  required int alignment,
  required List<String> patronsThisLife,
  required Map<String, Patron> patrons,
}) =>
    patron.reachable(flags: flags, alignment: alignment) &&
    !closedThisLife(patron, patronsThisLife: patronsThisLife, patrons: patrons);

/// Whether this life has shut [patron] out: the other of the Choir and
/// the Pit has given a sign. A clan or a tribe never is (v1.193: the clans
/// are no longer three a life; standing decides who comes). A lost clan
/// always is: it comes only by its own rule ("Your own hand", see
/// offers.dart).
bool closedThisLife(
  Patron patron, {
  required List<String> patronsThisLife,
  required Map<String, Patron> patrons,
}) {
  switch (patron.kind) {
    case PatronKind.otherworld:
      final claim = otherworldClaimOf(patronsThisLife, patrons);
      return claim != null && claim != patron.id;
    case PatronKind.clan:
    case PatronKind.tribe:
      return false;
    case PatronKind.lost:
      return true;
  }
}

/// What [patronId] can still offer against [held]: its own signs not held
/// yet, and apart from them the duo signs it shares whose two patrons both
/// have a sign held.
({List<SignDef> regular, List<SignDef> duos}) offerableSigns(
  String patronId, {
  required Map<String, SignDef> signs,
  required List<HeldSign> held,
}) {
  final heldIds = {for (final h in held) h.signId};
  final heldPatrons = {
    for (final h in held)
      if (signs[h.signId] != null) signs[h.signId]!.patronId,
  };
  final regular = <SignDef>[];
  final duos = <SignDef>[];
  final ids = signs.keys.toList()..sort();
  for (final id in ids) {
    final sign = signs[id]!;
    if (heldIds.contains(id) || !sign.offeredBy(patronId)) continue;
    if (sign.isDuo) {
      if (sign.requiresPatrons.every(heldPatrons.contains)) duos.add(sign);
    } else if (sign.patronId == patronId) {
      regular.add(sign);
    }
  }
  return (regular: regular, duos: duos);
}

/// Draws the next offer, or null when no patron can offer. The patron:
/// with [returningPatronChance] one that already gave a sign this life (and
/// can offer), else one of the others, evenly (a tribe at
/// [tribeOfferWeight]). The cards: up to [signOfferSize] different signs of
/// theirs not held yet, an eligible duo taking one place at
/// [duoOfferChance] (or filling places when too few are left), each at a
/// rarity rolled with [luck] and the patron's favour.
SignOffer? rollSignOffer({
  required Map<String, Patron> patrons,
  required Map<String, SignDef> signs,
  required List<HeldSign> held,
  required Iterable<String> flags,
  required int alignment,
  required Random random,
  List<String> patronsThisLife = const [],
  Map<String, int> favour = const {},
  List<String> patronsMet = const [],
  int luck = 0,
}) {
  final ids = patrons.keys.toList()..sort();
  final open = [
    for (final id in ids)
      if (patronOpen(patrons[id]!,
              flags: flags,
              alignment: alignment,
              patronsThisLife: patronsThisLife,
              patrons: patrons) &&
          _hasAnything(offerableSigns(id, signs: signs, held: held)))
        patrons[id]!,
  ];
  if (open.isEmpty) return null;
  final returning = [
    for (final p in open)
      if (patronsThisLife.contains(p.id)) p,
  ];
  final fresh = [
    for (final p in open)
      if (!patronsThisLife.contains(p.id)) p,
  ];
  final pool = returning.isEmpty
      ? fresh
      : fresh.isEmpty || random.nextDouble() < returningPatronChance
          ? returning
          : fresh;
  final patron = _weightedPatron(pool, random);

  final offerable = offerableSigns(patron.id, signs: signs, held: held);
  final regular = [...offerable.regular]..shuffle(random);
  final duos = [...offerable.duos]..shuffle(random);
  final picked = <SignDef>[];
  if (duos.isNotEmpty && random.nextDouble() < duoOfferChance) {
    picked.add(duos.removeAt(0));
  }
  while (picked.length < signOfferSize && regular.isNotEmpty) {
    picked.add(regular.removeAt(0));
  }
  while (picked.length < signOfferSize && duos.isNotEmpty) {
    picked.add(duos.removeAt(0));
  }
  final favourLevel = favourLevelFor(favour[patron.id] ?? 0);
  final greetings = max(1, patron.greetings.length);
  return SignOffer(
    patronId: patron.id,
    cards: [
      for (final sign in picked)
        SignCard(
          signId: sign.id,
          rarity: rollSignRarity(
              random: random,
              luck: luck,
              favourLevel: favourLevel,
              duo: sign.isDuo),
        ),
    ],
    firstMeeting: !patronsMet.contains(patron.id),
    greetingIndex: random.nextInt(greetings),
  );
}

/// Whether any patron could draw an offer now (see [rollSignOffer]): a
/// pick waiting with nobody to offer stays waiting, unannounced.
bool anyPatronCanOffer({
  required Map<String, Patron> patrons,
  required Map<String, SignDef> signs,
  required List<HeldSign> held,
  required Iterable<String> flags,
  required int alignment,
  List<String> patronsThisLife = const [],
}) =>
    patrons.values.any((patron) =>
        patronOpen(patron,
            flags: flags,
            alignment: alignment,
            patronsThisLife: patronsThisLife,
            patrons: patrons) &&
        _hasAnything(offerableSigns(patron.id, signs: signs, held: held)));

bool _hasAnything(({List<SignDef> regular, List<SignDef> duos}) offerable) =>
    offerable.regular.isNotEmpty || offerable.duos.isNotEmpty;

Patron _weightedPatron(List<Patron> pool, Random random) {
  double weight(Patron p) => p.kind == PatronKind.tribe ? tribeOfferWeight : 1;
  final total = pool.fold<double>(0, (sum, p) => sum + weight(p));
  var roll = random.nextDouble() * total;
  for (final patron in pool) {
    roll -= weight(patron);
    if (roll < 0) return patron;
  }
  return pool.last;
}

/// The held sign in [slot] (never a passive: those are many), if any.
HeldSign? heldInSlot(
    SignSlot slot, List<HeldSign> held, Map<String, SignDef> signs) {
  if (slot == SignSlot.passive) return null;
  return held.where((h) => signs[h.signId]?.slot == slot).firstOrNull;
}

/// [held] once [sign] is taken at [rarity]: a sign for a filled slot
/// replaces the one there, keeping its level and the better of the two
/// rarities; a Pit sign's pact starts counting. [replaced] names the sign
/// it took the place of.
({List<HeldSign> held, String? replaced}) takeSign(
  List<HeldSign> held,
  SignDef sign,
  SignRarity rarity,
  Map<String, SignDef> signs,
) {
  final old = heldInSlot(sign.slot, held, signs);
  final taken = HeldSign(
    signId: sign.id,
    rarity:
        old == null || rarity.index >= old.rarity.index ? rarity : old.rarity,
    level: old?.level ?? 1,
    pactFightsLeft: sign.pact?.fights ?? 0,
  );
  return (
    held: [
      for (final h in held)
        if (h.signId != old?.signId && h.signId != sign.id) h,
      taken,
    ],
    replaced: old?.signId,
  );
}

/// The alignment a character moves by taking [sign]: up for a Choir vow,
/// down for a Pit pact.
int alignmentShiftFor(SignDef sign) => switch (sign.patronId) {
      choirPatronId => otherworldAlignmentShift,
      pitPatronId => -otherworldAlignmentShift,
      _ => 0,
    };

/// A Choir vow keeps only while the alignment score is at or above
/// [vowAlignmentFloor]; below it, the sign falls silent.
bool vowSilent(SignDef sign, int alignment) =>
    sign.patronId == choirPatronId && alignment < vowAlignmentFloor;

/// Whether [held]'s gift works now: not a silent vow, no pact still
/// running.
bool signGiftActive(HeldSign held, SignDef sign, int alignment) =>
    !vowSilent(sign, alignment) && !held.pactPending;

/// [held] one fight on: every running pact one fight shorter.
List<HeldSign> countDownPacts(List<HeldSign> held) => [
      for (final h in held)
        h.pactPending ? h.copyWith(pactFightsLeft: h.pactFightsLeft - 1) : h,
    ];

/// [held] with [signId] raised one level by Titan's Blood, or null when it
/// can't be (not held, already at [maxSignLevel]).
List<HeldSign>? raiseSign(List<HeldSign> held, String signId) {
  final sign = held.where((h) => h.signId == signId).firstOrNull;
  if (sign == null || sign.level >= maxSignLevel) return null;
  return [
    for (final h in held)
      h.signId == signId ? h.copyWith(level: h.level + 1) : h,
  ];
}

/// The simulator's pick (and a fair default): a sign that fills an empty
/// slot or a passive before one that replaces, then the rarest.
SignCard? preferredSignCard(
  SignOffer offer,
  List<HeldSign> held,
  Map<String, SignDef> signs,
) {
  SignCard? best;
  var bestScore = -1;
  for (final card in offer.cards) {
    final sign = signs[card.signId];
    if (sign == null) continue;
    final fillsEmpty = heldInSlot(sign.slot, held, signs) == null;
    final score = (fillsEmpty ? 10 : 0) + card.rarity.index;
    if (score > bestScore) {
      best = card;
      bestScore = score;
    }
  }
  return best;
}

// --- What held signs add up to ------------------------------------------------

/// A status a sign may inflict, at its odds; [signId] names the sign in
/// the fight log.
class SignStatusChance {
  const SignStatusChance({
    required this.status,
    required this.chance,
    this.signId = '',
  });

  final StatusEffect status;
  final int chance;
  final String signId;

  /// Whether the chance comes up this time.
  bool rolls(Random random) => random.nextInt(100) < chance;
}

/// Everything the held signs add up to for a fight (and a voyage), from
/// the gifts that work now and the pacts still running. Built by
/// [signEffectsFor]; [none] with no sign held changes nothing anywhere.
class SignEffects {
  const SignEffects({
    this.strikeDamagePercent = 0,
    this.strikeFlat = 0,
    this.strikeElement = '',
    this.strikeStatuses = const [],
    this.strikeKeywords = const {},
    this.guardBlockPercent = 0,
    this.guardFlat = 0,
    this.guardHeal = 0,
    this.guardRetaliate = 0,
    this.guardStatuses = const [],
    this.mendPercent = 0,
    this.mendPartyPercent = 0,
    this.mendShield = 0,
    this.mendCleanse = 0,
    this.manaFlat = 0,
    this.spellDamagePercent = 0,
    this.spellCostLess = 0,
    this.spellStatuses = const [],
    this.maxHealth = 0,
    this.armor = 0,
    this.critChance = 0,
    this.dodgeChance = 0,
    this.lifestealPercent = 0,
    this.thorns = 0,
    this.manaOnHit = 0,
    this.maxMana = 0,
    this.secondWind = false,
    this.potionBonus = 0,
    this.goldPercent = 0,
    this.xpPercent = 0,
    this.allyDamagePercent = 0,
    this.stats = const {},
    this.partyStartBlock = 0,
    this.startMomentum = 0,
    this.lowHealthDamagePercent = 0,
    this.killHeal = 0,
    this.afterFightHealPercent = 0,
    this.firstRoundDamagePercent = 0,
    this.partyMaxHealthPercent = 0,
    this.shipHullPercent = 0,
    this.shipGunPercent = 0,
    this.voyageCalm = 0,
    this.writFace = 0,
    this.intentLookahead = 0,
    this.compactEdge = 0,
    this.crowsPrice = 0,
    this.emberFace = 0,
    this.poisonExtraTurns = 0,
    this.enemyDamagePercent = 0,
    this.startHealthPercentLoss = 0,
    this.goldPercentLoss = 0,
    this.silentVows = 0,
    this.pactsRunning = 0,
  });

  static const SignEffects none = SignEffects();

  // Strike: the player's Attack faces.
  final int strikeDamagePercent;
  final int strikeFlat;

  /// The element the Attack faces strike with ('' for their own), and
  /// [strikeFlat] carries its extra damage too.
  final String strikeElement;
  final List<SignStatusChance> strikeStatuses;
  final Set<FaceKeyword> strikeKeywords;

  // Guard: the player's Defend faces.
  final int guardBlockPercent;
  final int guardFlat;
  final int guardHeal;
  final int guardRetaliate;
  final List<SignStatusChance> guardStatuses;

  // Mend: the player's Heal faces.
  final int mendPercent;
  final int mendPartyPercent;
  final int mendShield;
  final int mendCleanse;

  // Spell: the player's Mana faces and every spell cast.
  final int manaFlat;
  final int spellDamagePercent;
  final int spellCostLess;
  final List<SignStatusChance> spellStatuses;

  // Passives, like perks and gear.
  final int maxHealth;
  final int armor;
  final int critChance;
  final int dodgeChance;
  final int lifestealPercent;
  final int thorns;
  final int manaOnHit;
  final int maxMana;
  final bool secondWind;
  final int potionBonus;
  final int goldPercent;
  final int xpPercent;
  final int allyDamagePercent;

  /// Ability score (see [signStatNames]) -> points added in fights.
  final Map<String, int> stats;

  // The fight as a whole.
  final int partyStartBlock;
  final int startMomentum;
  final int lowHealthDamagePercent;
  final int killHeal;
  final int afterFightHealPercent;
  final int firstRoundDamagePercent;
  final int partyMaxHealthPercent;

  // At sea.
  final int shipHullPercent;
  final int shipGunPercent;
  final int voyageCalm;

  // The clans' Sworn boons (v1.194).
  /// Enemy blows on the player cancelled per fight.
  final int writFace;

  /// Rounds of enemy intent shown past the next.
  final int intentLookahead;

  /// Enemy guards broken outright per fight.
  final int compactEdge;

  /// Gold stolen per hit the player lands (at most [crowsPriceMaxHits]).
  final int crowsPrice;

  /// Curses on the player's die lifted per fight.
  final int emberFace;

  /// Turns added to every Poison the player inflicts.
  final int poisonExtraTurns;

  // Pacts still running.
  final int enemyDamagePercent;
  final int startHealthPercentLoss;
  final int goldPercentLoss;

  /// Choir vows held but silent, and pacts still running: the fight log
  /// says so at the start.
  final int silentVows;
  final int pactsRunning;

  bool get isEmpty =>
      strikeDamagePercent == 0 &&
      strikeFlat == 0 &&
      strikeElement.isEmpty &&
      strikeStatuses.isEmpty &&
      strikeKeywords.isEmpty &&
      guardBlockPercent == 0 &&
      guardFlat == 0 &&
      guardHeal == 0 &&
      guardRetaliate == 0 &&
      guardStatuses.isEmpty &&
      mendPercent == 0 &&
      mendPartyPercent == 0 &&
      mendShield == 0 &&
      mendCleanse == 0 &&
      manaFlat == 0 &&
      spellDamagePercent == 0 &&
      spellCostLess == 0 &&
      spellStatuses.isEmpty &&
      maxHealth == 0 &&
      armor == 0 &&
      critChance == 0 &&
      dodgeChance == 0 &&
      lifestealPercent == 0 &&
      thorns == 0 &&
      manaOnHit == 0 &&
      maxMana == 0 &&
      !secondWind &&
      potionBonus == 0 &&
      goldPercent == 0 &&
      xpPercent == 0 &&
      allyDamagePercent == 0 &&
      stats.isEmpty &&
      partyStartBlock == 0 &&
      startMomentum == 0 &&
      lowHealthDamagePercent == 0 &&
      killHeal == 0 &&
      afterFightHealPercent == 0 &&
      firstRoundDamagePercent == 0 &&
      partyMaxHealthPercent == 0 &&
      shipHullPercent == 0 &&
      shipGunPercent == 0 &&
      voyageCalm == 0 &&
      writFace == 0 &&
      intentLookahead == 0 &&
      compactEdge == 0 &&
      crowsPrice == 0 &&
      emberFace == 0 &&
      poisonExtraTurns == 0 &&
      enemyDamagePercent == 0 &&
      startHealthPercentLoss == 0 &&
      goldPercentLoss == 0;

  int stat(String name) => stats[name] ?? 0;

  static int _percent(int value, int percent) =>
      percent == 0 ? value : (value * (100 + percent) / 100).round();

  /// The damage bonus (%) on the player's strikes this moment: the
  /// Attack-face bonus when [attackFace], a low-health sign under
  /// [signLowHealthShare] of [maxHealth], a first-round sign in round 1.
  int strikePercentFor({
    required bool attackFace,
    required int currentHealth,
    required int maxHealth,
    required bool firstRound,
  }) =>
      (attackFace ? strikeDamagePercent : 0) +
      (currentHealth < maxHealth * signLowHealthShare
          ? lowHealthDamagePercent
          : 0) +
      (firstRound ? firstRoundDamagePercent : 0);

  /// The base damage behind a player's strike once the signs are in: an
  /// Attack face of [faceValue] ([attackFace]) adds [strikeFlat] and hits
  /// [percent] harder all told (see [strikePercentFor]); a Skill face's
  /// base is raised by [percent]. Returns the new base for
  /// resolvePlayerFace, which adds the face's own value to an Attack.
  int strikeBase(int baseDamage, int faceValue,
      {required bool attackFace, int percent = 0}) {
    if (!attackFace) return _percent(baseDamage, percent);
    final total = _percent(baseDamage + faceValue + strikeFlat, percent);
    return total - faceValue;
  }

  /// A Defend face's block with the guard signs in.
  int guardValue(int faceValue) => faceValue <= 0
      ? faceValue
      : _percent(faceValue + guardFlat, guardBlockPercent);

  /// A Heal face's number with the mend signs in, for a healer whose
  /// Wisdom adds [wisdomBonus] (which the engine adds again on top).
  int mendValue(int faceValue, int wisdomBonus) => mendPercent == 0
      ? faceValue
      : _percent(faceValue + wisdomBonus, mendPercent) - wisdomBonus;

  /// A Mana face's number with the spell signs in.
  int manaValue(int faceValue) => faceValue + manaFlat;

  /// A spell's damage or healing with the spell signs in.
  int spellAmount(int amount) => _percent(amount, spellDamagePercent);

  /// A spell's mana cost with the spell signs in: never under 1 (a free
  /// spell stays free).
  int spellCost(int cost) => cost <= 0 ? cost : max(1, cost - spellCostLess);

  /// An enemy's blow with a pact's curse on it.
  int enemyDamage(int damage) => _percent(damage, enemyDamagePercent);

  /// A max health of [base] in a fight: the passive health and the party's
  /// share ([partyWide] false for an ally, who gets only the share).
  int maxHealthFor(int base, {bool partyWide = false}) =>
      _percent(base, partyMaxHealthPercent) + (partyWide ? 0 : maxHealth);

  /// The health a member enters a fight with, [current] of [base] going up
  /// to [fightMax]: full stays full; wounds stay as they are.
  static int healthEntering(
          {required int current, required int base, required int fightMax}) =>
      current >= base ? fightMax : min(current, fightMax);

  /// What a pact's starting-health curse takes off [health] of [maxHealth]
  /// (never the last point).
  int afterStartCurse(int health, int maxHealth) => startHealthPercentLoss <= 0
      ? health
      : max(1, health - (maxHealth * startHealthPercentLoss / 100).round());

  int scaleGold(int gold) =>
      max(0, gold * (100 + goldPercent - goldPercentLoss) ~/ 100);
  int scaleXp(int xp) => xp * (100 + xpPercent) ~/ 100;
  int scaleAllyDamage(int damage) => damage * (100 + allyDamagePercent) ~/ 100;

  /// [gear] with the signs that act like gear laid over it.
  GearEffects over(GearEffects gear) => GearEffects(
        attackDamage: gear.attackDamage,
        armor: gear.armor + armor,
        critChance: gear.critChance + critChance,
        dodgeChance: gear.dodgeChance + dodgeChance,
        lifestealPercent: gear.lifestealPercent + lifestealPercent,
        thorns: gear.thorns + thorns,
        manaOnHit: gear.manaOnHit + manaOnHit,
        secondWind: gear.secondWind || secondWind,
      );

  /// The healing a party member gets from the player's Heal face that
  /// healed [healing] (see [mendPartyPercent]).
  int mendShare(int healing) =>
      mendPartyPercent <= 0 ? 0 : (healing * mendPartyPercent / 100).round();

  /// Block from healing past full: what spilled over, up to [mendShield].
  int shieldFromOverheal(
          {required int healing,
          required int currentHealth,
          required int maxHealth}) =>
      mendShield <= 0
          ? 0
          : min(mendShield, max(0, currentHealth + healing - maxHealth));

  /// Health the party gets back after a won fight, of [maxHealth].
  int afterFightHeal(int maxHealth) => afterFightHealPercent <= 0
      ? 0
      : (maxHealth * afterFightHealPercent / 100).round();

  /// A ship battle's max hull and a gun's damage.
  int shipHull(int maxHull) => _percent(maxHull, shipHullPercent);
  int shipGun(int damage) => _percent(damage, shipGunPercent);

  /// [status] as the player inflicts it: a Poison runs
  /// [poisonExtraTurns] longer.
  StatusEffect playerInflicted(StatusEffect status) =>
      poisonExtraTurns <= 0 || status.type != StatusEffectType.poison
          ? status
          : StatusEffect(
              type: status.type,
              remainingTurns: status.remainingTurns + poisonExtraTurns,
              magnitude: status.magnitude);

  /// The gold a fight's Crow's Price stole on [hits] hits landed.
  int crowsGold(int hits) => crowsPrice * min(hits, crowsPriceMaxHits);
}

/// What [held] adds up to at [alignment] (see [SignEffects]): every gift
/// that works now, scaled by its rarity and level, and every pact's curse
/// still running. [extra] are effects from elsewhere that use the same
/// machinery, taken as written (v1.194: the titles worn and the clans'
/// Sworn boons, see offers.dart's clanEffectsFor).
SignEffects signEffectsFor(
  List<HeldSign> held,
  Map<String, SignDef> signs, {
  required int alignment,
  List<SignEffect> extra = const [],
}) {
  if (held.isEmpty && extra.isEmpty) return SignEffects.none;
  var strikeDamagePercent = 0;
  var strikeFlat = 0;
  var strikeElement = '';
  final strikeStatuses = <SignStatusChance>[];
  final strikeKeywords = <FaceKeyword>{};
  var guardBlockPercent = 0;
  var guardFlat = 0;
  var guardHeal = 0;
  var guardRetaliate = 0;
  final guardStatuses = <SignStatusChance>[];
  var mendPercent = 0;
  var mendParty = 0;
  var mendShield = 0;
  var mendCleanse = 0;
  var manaFlat = 0;
  var spellDamagePercent = 0;
  var spellCostLess = 0;
  final spellStatuses = <SignStatusChance>[];
  var maxHealth = 0;
  var armor = 0;
  var critChance = 0;
  var dodgeChance = 0;
  var lifesteal = 0;
  var thorns = 0;
  var manaOnHit = 0;
  var maxMana = 0;
  var secondWind = false;
  var potionBonus = 0;
  var goldPercent = 0;
  var xpPercent = 0;
  var allyDamagePercent = 0;
  final stats = <String, int>{};
  var partyStartBlock = 0;
  var startMomentum = 0;
  var lowHealth = 0;
  var killHeal = 0;
  var afterFightHeal = 0;
  var firstRound = 0;
  var partyMaxHealth = 0;
  var shipHull = 0;
  var shipGun = 0;
  var voyageCalm = 0;
  var writFace = 0;
  var intentLookahead = 0;
  var compactEdge = 0;
  var crowsPrice = 0;
  var emberFace = 0;
  var poisonExtraTurns = 0;
  var enemyDamage = 0;
  var startHealthLoss = 0;
  var goldLoss = 0;
  var silentVows = 0;
  var pactsRunning = 0;

  void addStatus(
      List<SignStatusChance> into, SignEffect effect, String signId) {
    final status = effect.inflicted;
    if (status == null || effect.chance <= 0) return;
    into.add(SignStatusChance(
        status: status, chance: effect.chance, signId: signId));
  }

  void add(SignEffect e, String sourceId) {
    final v = e.value;
    switch (e.kind) {
      case SignEffectKind.strikeDamagePercent:
        strikeDamagePercent += v;
      case SignEffectKind.strikeFlat:
        strikeFlat += v;
      case SignEffectKind.strikeElement:
        if (e.element.isNotEmpty && e.element != 'None') {
          strikeElement = e.element;
        }
        strikeFlat += v;
      case SignEffectKind.strikeStatus:
        addStatus(strikeStatuses, e, sourceId);
      case SignEffectKind.strikeKeyword:
        final keyword = e.keyword;
        if (keyword != null && signStrikeKeywords.contains(keyword)) {
          strikeKeywords.add(keyword);
        }
      case SignEffectKind.guardBlockPercent:
        guardBlockPercent += v;
      case SignEffectKind.guardFlat:
        guardFlat += v;
      case SignEffectKind.guardHeal:
        guardHeal += v;
      case SignEffectKind.guardRetaliate:
        guardRetaliate += v;
      case SignEffectKind.guardStatus:
        addStatus(guardStatuses, e, sourceId);
      case SignEffectKind.mendPercent:
        mendPercent += v;
      case SignEffectKind.mendParty:
        mendParty += v;
      case SignEffectKind.mendShield:
        mendShield += v;
      case SignEffectKind.mendCleanse:
        mendCleanse += v;
      case SignEffectKind.manaFlat:
        manaFlat += v;
      case SignEffectKind.spellDamagePercent:
        spellDamagePercent += v;
      case SignEffectKind.spellCostLess:
        spellCostLess += v;
      case SignEffectKind.spellStatus:
        addStatus(spellStatuses, e, sourceId);
      case SignEffectKind.maxHealth:
        maxHealth += v;
      case SignEffectKind.armor:
        armor += v;
      case SignEffectKind.critChance:
        critChance += v;
      case SignEffectKind.dodgeChance:
        dodgeChance += v;
      case SignEffectKind.lifestealPercent:
        lifesteal += v;
      case SignEffectKind.thorns:
        thorns += v;
      case SignEffectKind.manaOnHit:
        manaOnHit += v;
      case SignEffectKind.maxMana:
        maxMana += v;
      case SignEffectKind.secondWind:
        secondWind = true;
      case SignEffectKind.potionBonus:
        potionBonus += v;
      case SignEffectKind.goldPercent:
        goldPercent += v;
      case SignEffectKind.xpPercent:
        xpPercent += v;
      case SignEffectKind.allyDamagePercent:
        allyDamagePercent += v;
      case SignEffectKind.stat:
        if (signStatNames.contains(e.stat)) {
          stats[e.stat] = (stats[e.stat] ?? 0) + v;
        }
      case SignEffectKind.partyStartBlock:
        partyStartBlock += v;
      case SignEffectKind.startMomentum:
        startMomentum += v;
      case SignEffectKind.lowHealthDamagePercent:
        lowHealth += v;
      case SignEffectKind.killHeal:
        killHeal += v;
      case SignEffectKind.afterFightHealPercent:
        afterFightHeal += v;
      case SignEffectKind.firstRoundDamagePercent:
        firstRound += v;
      case SignEffectKind.partyMaxHealthPercent:
        partyMaxHealth += v;
      case SignEffectKind.shipHullPercent:
        shipHull += v;
      case SignEffectKind.shipGunPercent:
        shipGun += v;
      case SignEffectKind.voyageCalm:
        voyageCalm += v;
      case SignEffectKind.writFace:
        writFace += v;
      case SignEffectKind.intentLookahead:
        intentLookahead += v;
      case SignEffectKind.compactEdge:
        compactEdge += v;
      case SignEffectKind.crowsPrice:
        crowsPrice += v;
      case SignEffectKind.emberFace:
        emberFace += v;
      case SignEffectKind.poisonExtraTurns:
        poisonExtraTurns += v;
    }
  }

  for (final h in held) {
    final sign = signs[h.signId];
    if (sign == null) continue;
    final pact = sign.pact;
    if (h.pactPending && pact != null) {
      pactsRunning++;
      switch (pact.curse) {
        case PactCurse.enemyDamagePercent:
          enemyDamage += pact.value;
        case PactCurse.startHealthPercentLoss:
          startHealthLoss += pact.value;
        case PactCurse.goldPercentLoss:
          goldLoss += pact.value;
      }
    }
    if (vowSilent(sign, alignment)) silentVows++;
    if (!signGiftActive(h, sign, alignment)) continue;
    for (final raw in sign.effects) {
      add(raw.scaled(h.rarity, h.level), sign.id);
    }
  }
  for (final effect in extra) {
    add(effect, '');
  }
  return SignEffects(
    strikeDamagePercent: strikeDamagePercent,
    strikeFlat: strikeFlat,
    strikeElement: strikeElement,
    strikeStatuses: strikeStatuses,
    strikeKeywords: strikeKeywords,
    guardBlockPercent: guardBlockPercent,
    guardFlat: guardFlat,
    guardHeal: guardHeal,
    guardRetaliate: guardRetaliate,
    guardStatuses: guardStatuses,
    mendPercent: mendPercent,
    mendPartyPercent: mendParty,
    mendShield: mendShield,
    mendCleanse: mendCleanse,
    manaFlat: manaFlat,
    spellDamagePercent: spellDamagePercent,
    spellCostLess: spellCostLess,
    spellStatuses: spellStatuses,
    maxHealth: maxHealth,
    armor: armor,
    critChance: critChance,
    dodgeChance: dodgeChance,
    lifestealPercent: lifesteal,
    thorns: thorns,
    manaOnHit: manaOnHit,
    maxMana: maxMana,
    secondWind: secondWind,
    potionBonus: potionBonus,
    goldPercent: goldPercent,
    xpPercent: xpPercent,
    allyDamagePercent: allyDamagePercent,
    stats: stats,
    partyStartBlock: partyStartBlock,
    startMomentum: startMomentum,
    lowHealthDamagePercent: lowHealth,
    killHeal: killHeal,
    afterFightHealPercent: afterFightHeal,
    firstRoundDamagePercent: firstRound,
    partyMaxHealthPercent: partyMaxHealth,
    shipHullPercent: shipHull,
    shipGunPercent: shipGun,
    voyageCalm: min(signChanceCap, voyageCalm),
    writFace: writFace,
    intentLookahead: intentLookahead,
    compactEdge: compactEdge,
    crowsPrice: crowsPrice,
    emberFace: emberFace,
    poisonExtraTurns: poisonExtraTurns,
    enemyDamagePercent: enemyDamage,
    startHealthPercentLoss: startHealthLoss,
    goldPercentLoss: goldLoss,
    silentVows: silentVows,
    pactsRunning: pactsRunning,
  );
}

// --- The words -----------------------------------------------------------

/// The l10n key of [kind]'s line (`sign_fx_<kind>`, with `{v}` for the
/// number and the placeholders [signEffectText] fills).
String signEffectKey(SignEffectKind kind) => 'sign_fx_${kind.name}';
String pactCurseKey(PactCurse curse) => 'sign_curse_${curse.name}';
String signRarityKey(SignRarity rarity) => 'sign_rarity_${rarity.name}';
String signSlotKey(SignSlot slot) => 'sign_slot_${slot.name}';

String _statusText(StatusEffect status, AppLanguage language) =>
    trFor(language, 'sign_status_${status.type.name}')
        .replaceAll('{m}', '${status.magnitude}')
        .replaceAll('{d}', '${status.remainingTurns}');

String _elementName(String element, AppLanguage language) {
  final key = 'element_name_${element.toLowerCase()}';
  final label = trFor(language, key);
  return label == key ? element : label;
}

String _statName(String stat, AppLanguage language) {
  final key = '${stat}_label';
  final label = trFor(language, key);
  return label == key ? stat : label;
}

/// One effect as the player reads it, with its (already scaled) numbers.
String signEffectText(SignEffect effect, AppLanguage language) {
  final status = effect.inflicted;
  final keyword = effect.keyword;
  return trFor(language, signEffectKey(effect.kind))
      .replaceAll('{v}', '${effect.value}')
      .replaceAll('{c}', '${effect.chance}')
      .replaceAll('{e}', _elementName(effect.element, language))
      .replaceAll('{s}', status == null ? '' : _statusText(status, language))
      .replaceAll('{k}',
          keyword == null ? '' : trFor(language, keywordLabelKey(keyword)))
      .replaceAll('{stat}', _statName(effect.stat, language));
}

/// [sign]'s effects at [rarity] and [level], one line each.
List<String> signEffectLines(
  SignDef sign,
  SignRarity rarity,
  int level,
  AppLanguage language,
) =>
    [
      for (final effect in sign.effects)
        signEffectText(effect.scaled(rarity, level), language),
    ];

/// A pact's curse as the player reads it, for [fights] more fights.
String pactCurseText(SignPact pact, AppLanguage language, {int? fights}) =>
    trFor(language, pactCurseKey(pact.curse))
        .replaceAll('{v}', '${pact.value}')
        .replaceAll('{n}', '${fights ?? pact.fights}');
