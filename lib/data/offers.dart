import 'dart:math';

import '../combat/dice_faces.dart' show SkillRarity, skillRarity;
import '../combat/spells.dart'
    show SpellSpec, canLearnSpell, spellbookSpellIdFor;
import 'factions.dart';
import 'perks.dart';
import 'signs.dart';
import 'skill_access.dart' show skillFitsCharacter;
import 'skill_tree.dart';

/// Offers (v1.194): the clans come to the character. Skill points, the
/// level-up perk pick and the sign pick are gone; in their place, each
/// level-up, boss beaten, chapter reached or Tome of Mastery read brings
/// **three suitors from different factions**, each with one gift on the
/// table -- a skill, a sign, an object, a title, a clan's Sworn boon, or,
/// from the Wayfarer (no faction), a perk rank. The character takes one.
/// The faction taken rises in their favour, its allies a little, its
/// rivals hold it against them (the ripple, see factions.dart); the
/// sub-clan that voiced the gift becomes a friend; and the faction's lean
/// nudges the alignment.
///
/// Everything here is pure and takes a [Random], like signs.dart: the
/// session keeps the offers due ([OfferTicket]) and the one on the table
/// ([ClanOffer]); [drawOffer] draws it from an [OfferContext], and
/// [acceptPolitics] works out what taking a suitor does to the politics.
/// The gift itself is applied by the session (it knows the pack, the
/// purse and the dice).
///
/// For later scenes: a quest step or an intrigue grants an offer with
/// `PlayerSessionNotifier.grantOffer(source, factionId: ...)`; the named
/// faction then always takes a place, with a gift one rarity better.

// --- Constants --------------------------------------------------------------

/// The Wayfarer: no faction, a perk or a common object.
const String wayfarerId = 'wayfarer';

/// Suitors an offer brings, when that many can come.
const int offerSuitorCount = 3;

/// Odds the Wayfarer takes a place when three factions could fill them.
const double wayfarerChance = 0.20;

/// Odds the Wayfarer brings a perk rank (when one is left) rather than a
/// common object.
const double wayfarerPerkChance = 0.75;

/// Standing gained with the faction whose gift is taken; a quest's,
/// an intrigue's or a chapter's end is worth more.
const int offerStandingGain = 6;
const int majorOfferStandingGain = 10;

/// The weight of each kind of gift a clan may bring, among those it has.
const Map<GiftKind, int> giftKindWeights = {
  GiftKind.skill: 35,
  GiftKind.sign: 30,
  GiftKind.object: 20,
  GiftKind.title: 15,
};

/// The deepest skill (its index on a branch) a faction offers at each
/// tier: the first at Unknown (or Wary), the second at Known, the third
/// at Trusted, the fourth at Sworn.
int skillIndexCapFor(StandingTier tier) {
  if (tier.isAtLeast(StandingTier.sworn)) return 3;
  if (tier.isAtLeast(StandingTier.trusted)) return 2;
  if (tier.isAtLeast(StandingTier.known)) return 1;
  return 0;
}

/// A faction's place in the standing-leaning draw: the better the
/// standing, the likelier (a Wary one barely, a Sworn one most).
double standingWeightFor(double standing) =>
    (standing + 30).clamp(5, 130).toDouble();

// --- What the session keeps -------------------------------------------------

/// Why an offer is due.
enum OfferSource {
  /// A level reached (replacing the skill point, the perk and the sign).
  level,

  /// A boss beaten.
  boss,

  /// A new chapter reached: the Choir or the Pit come if the alignment
  /// leans (see [otherworldLeaningFor]).
  chapter,

  /// A Tome of Mastery read.
  tome,

  /// A clan quest step: its clan always comes, one rarity better.
  quest,

  /// An intrigue coming to a head.
  intrigue,

  /// A new character's starting skill points.
  start,

  /// An old save's unspent skill points, perk and sign picks.
  migrated,

  /// Edit Mode.
  edit,

  /// A story choice's or a politics event's `offerFrom` (v1.195): its
  /// faction always comes; [OfferTicket.detail] is the cause to log
  /// (`story:<node>`, `event:<id>`).
  story,
}

OfferSource offerSourceNamed(String? name) =>
    OfferSource.values.where((s) => s.name == name).firstOrNull ??
    OfferSource.level;

/// One offer due, and what shapes it: [detail] (the quest's id, the
/// chapter's number...) goes in the log's cause; [factionId], when set,
/// always takes a place.
class OfferTicket {
  const OfferTicket({
    required this.source,
    this.detail = '',
    this.factionId = '',
  });

  final OfferSource source;
  final String detail;
  final String factionId;

  /// A quest's, an intrigue's or a chapter's end: worth
  /// [majorOfferStandingGain].
  bool get major =>
      source == OfferSource.quest ||
      source == OfferSource.intrigue ||
      source == OfferSource.chapter;

  /// Its faction's gift is one rarity better.
  bool get better =>
      factionId.isNotEmpty &&
      (source == OfferSource.quest || source == OfferSource.intrigue);

  Map<String, dynamic> toJson() => {
        'source': source.name,
        if (detail.isNotEmpty) 'detail': detail,
        if (factionId.isNotEmpty) 'faction': factionId,
      };

  factory OfferTicket.fromJson(Map<String, dynamic> json) => OfferTicket(
        source: offerSourceNamed(json['source']?.toString()),
        detail: json['detail']?.toString() ?? '',
        factionId: json['faction']?.toString() ?? '',
      );

  @override
  bool operator ==(Object other) =>
      other is OfferTicket &&
      other.source == source &&
      other.detail == detail &&
      other.factionId == factionId;

  @override
  int get hashCode => Object.hash(source, detail, factionId);
}

/// What a suitor puts on the table.
enum GiftKind {
  /// A skill from a branch the faction sponsors.
  skill,

  /// A sign (signs.json) of theirs.
  sign,

  /// One of the faction's objects (items.json), or the Wayfarer's.
  object,

  /// A title (titles.json, source `offer`).
  title,

  /// The sworn faction's Sworn boon, once.
  sworn,

  /// A perk rank (perks.dart), from the Wayfarer.
  perk,
}

GiftKind? giftKindNamed(String? name) =>
    GiftKind.values.where((k) => k.name == name).firstOrNull;

/// A gift: its [kind], the [id] of what is given (a skill, sign, item or
/// title id, the faction's id for a Sworn boon, a perk's name), and its
/// [rarity] -- a sign's own, the others' read on the same scale (see
/// [rarityOfSkill], [rarityOfItem]).
class OfferGift {
  const OfferGift({
    required this.kind,
    required this.id,
    this.rarity = SignRarity.common,
  });

  final GiftKind kind;
  final String id;
  final SignRarity rarity;

  Map<String, dynamic> toJson() =>
      {'kind': kind.name, 'id': id, 'rarity': rarity.name};

  static OfferGift? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final kind = giftKindNamed(raw['kind']?.toString());
    final id = raw['id']?.toString() ?? '';
    if (kind == null || id.isEmpty) return null;
    return OfferGift(
      kind: kind,
      id: id,
      rarity: SignRarity.values
              .where((r) => r.name == raw['rarity']?.toString())
              .firstOrNull ??
          SignRarity.common,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OfferGift &&
      other.kind == kind &&
      other.id == id &&
      other.rarity == rarity;

  @override
  int get hashCode => Object.hash(kind, id, rarity);
}

/// One suitor: the faction ([wayfarerId] for the Wayfarer), the sub-clan
/// that voices it ('' for none), the gift, and how they greet -- their
/// intro the first time ([firstMeeting]), else greeting
/// [greetingIndex].
class Suitor {
  const Suitor({
    required this.factionId,
    required this.gift,
    this.subclanId = '',
    this.firstMeeting = false,
    this.greetingIndex = 0,
  });

  final String factionId;
  final String subclanId;
  final OfferGift gift;
  final bool firstMeeting;
  final int greetingIndex;

  bool get isWayfarer => factionId == wayfarerId;

  Map<String, dynamic> toJson() => {
        'faction': factionId,
        if (subclanId.isNotEmpty) 'subclan': subclanId,
        'gift': gift.toJson(),
        if (firstMeeting) 'first': true,
        'greeting': greetingIndex,
      };

  static Suitor? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final gift = OfferGift.tryParse(raw['gift']);
    final faction = raw['faction']?.toString() ?? '';
    if (gift == null || faction.isEmpty) return null;
    return Suitor(
      factionId: faction,
      subclanId: raw['subclan']?.toString() ?? '',
      gift: gift,
      firstMeeting: raw['first'] == true,
      greetingIndex: (raw['greeting'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Suitor &&
      other.factionId == factionId &&
      other.subclanId == subclanId &&
      other.gift == gift &&
      other.firstMeeting == firstMeeting &&
      other.greetingIndex == greetingIndex;

  @override
  int get hashCode =>
      Object.hash(factionId, subclanId, gift, firstMeeting, greetingIndex);
}

/// The offer on the table: drawn once for its [ticket] and kept until a
/// suitor is taken, so closing the app never loses or redraws it.
class ClanOffer {
  const ClanOffer({required this.ticket, required this.suitors});

  final OfferTicket ticket;
  final List<Suitor> suitors;

  Suitor? suitorOf(String factionId) =>
      suitors.where((s) => s.factionId == factionId).firstOrNull;

  Map<String, dynamic> toJson() => {
        'ticket': ticket.toJson(),
        'suitors': [for (final s in suitors) s.toJson()],
      };

  static ClanOffer? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final suitors = [
      for (final s in (raw['suitors'] as List?) ?? const [])
        if (Suitor.tryParse(s) case final suitor?) suitor,
    ];
    if (suitors.isEmpty) return null;
    final ticket = raw['ticket'];
    return ClanOffer(
      ticket: ticket is Map
          ? OfferTicket.fromJson(ticket.cast<String, dynamic>())
          : const OfferTicket(source: OfferSource.level),
      suitors: suitors,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ClanOffer &&
      other.ticket == ticket &&
      other.suitors.length == suitors.length &&
      [for (var i = 0; i < suitors.length; i++) other.suitors[i] == suitors[i]]
          .every((same) => same);

  @override
  int get hashCode => Object.hash(ticket, Object.hashAll(suitors));
}

/// Offers an old save is owed: its unspent skill points, its perk picks
/// and its sign picks, one offer each (learned skills, perk ranks and held
/// signs stay as they are).
List<OfferTicket> migratedOffers({
  int skillPoints = 0,
  int perkPicks = 0,
  int signPicks = 0,
}) =>
    [
      for (var i = 0; i < max(0, skillPoints + perkPicks + signPicks); i++)
        const OfferTicket(source: OfferSource.migrated),
    ];

// --- Drawing an offer -------------------------------------------------------

/// The gamedata an offer is drawn from and applied with: the clans, the
/// signs, and skills.json, skill_trees.json, items.json and spells.json.
class OfferTables {
  const OfferTables({
    required this.data,
    this.signs = const {},
    this.skills = const {},
    this.skillTrees = const {},
    this.items = const {},
    this.spells = const {},
  });

  final ClanData data;
  final Map<String, SignDef> signs;
  final Map<String, dynamic> skills;
  final Map<String, dynamic> skillTrees;
  final Map<String, dynamic> items;
  final Map<String, SpellSpec> spells;
}

/// Everything a draw reads about the character and the world. The tables
/// are the gamedata files as maps (skills.json, skill_trees.json,
/// items.json); the rest is the session's.
class OfferContext {
  const OfferContext({
    required this.data,
    required this.politics,
    this.signs = const {},
    this.heldSigns = const [],
    this.skills = const {},
    this.skillTrees = const {},
    this.items = const {},
    this.raceId = '',
    this.professionId = '',
    this.knownSkillIds = const {},
    this.ownedItemIds = const [],
    this.knownSpellIds = const [],
    this.spells = const {},
    this.flags = const [],
    this.alignment = 0,
    this.patronsThisLife = const [],
    this.favour = const {},
    this.patronsMet = const [],
    this.heldTitleIds = const [],
    this.swornBoonIds = const [],
    this.perkRanks = const {},
    this.luck = 0,
  });

  final ClanData data;
  final PoliticsState politics;
  final Map<String, SignDef> signs;
  final List<HeldSign> heldSigns;
  final Map<String, dynamic> skills;
  final Map<String, dynamic> skillTrees;
  final Map<String, dynamic> items;
  final String raceId;
  final String professionId;

  /// Every skill the character knows (learned, or everyone's).
  final Set<String> knownSkillIds;
  final List<String> ownedItemIds;
  final List<String> knownSpellIds;

  /// spells.json parsed: a spellbook is offered only to a character who
  /// can learn its spell.
  final Map<String, SpellSpec> spells;
  final Iterable<String> flags;
  final int alignment;

  /// The patrons that gave a sign this life: the Choir or the Pit among
  /// them shuts the other out (see otherworldClaimOf).
  final List<String> patronsThisLife;
  final Map<String, int> favour;
  final List<String> patronsMet;
  final List<String> heldTitleIds;

  /// The factions whose Sworn boon was taken.
  final List<String> swornBoonIds;
  final Map<String, int> perkRanks;
  final int luck;

  Map<String, Patron> get patrons => patronsFromFactions(data.factions);

  StandingTier tierOf(String factionId) => politics.tierOf(factionId, data);
}

/// The skill-tree branches [factionId] sponsors that the character can
/// grow on: their profession's, or their race's heritage.
List<SkillBranch> sponsoredBranchesFor(String factionId, OfferContext c) {
  final faction = c.data.faction(factionId);
  if (faction == null) return const [];
  final mine = skillBranchesFor(c.skillTrees,
      raceId: c.raceId, professionId: c.professionId);
  return [
    for (final branch in mine)
      if (faction.sponsors.contains(branch.id)) branch,
  ];
}

/// Whether a faction leaning [lean] offers reputation skill [skill]: one
/// leaning good (the Vigil, the Penitents) the skills a good name earns
/// (`requiredAlignmentMin`), one leaning evil (the Crows) those of a bad
/// name (`requiredAlignmentMax`). Skill points used to buy them; no
/// branch holds them.
bool _leanOffersReputation(int lean, Map<String, dynamic> skill) =>
    isReputationSkill(skill) &&
    (lean > 0 && skill['requiredAlignmentMin'] != null ||
        lean < 0 && skill['requiredAlignmentMax'] != null);

/// The skills [factionId] can offer now: on each branch it sponsors for
/// the character, every skill not known whose turn has come (the one
/// before it on the branch known, its `requiredSkillID` known) and that
/// lies no deeper than standing allows ([skillIndexCapFor], plus
/// [tierBonus] for a quest's suitor); then, from a clan that leans one
/// way, the reputation skills of that side the character's alignment
/// allows. In the branches' order, no repeats.
List<String> offerableSkillsFor(String factionId, OfferContext c,
    {int tierBonus = 0}) {
  final cap = min(3, skillIndexCapFor(c.tierOf(factionId)) + tierBonus);
  final out = <String>[];
  final faction = c.data.faction(factionId);
  for (final branch in sponsoredBranchesFor(factionId, c)) {
    for (var i = 0; i < branch.skillIds.length && i <= cap; i++) {
      final id = branch.skillIds[i];
      if (c.knownSkillIds.contains(id) || out.contains(id)) continue;
      if (i > 0 && !c.knownSkillIds.contains(branch.skillIds[i - 1])) break;
      final skill = c.skills[id];
      if (skill is! Map<String, dynamic>) continue;
      final required = skill['requiredSkillID']?.toString() ?? '';
      if (required.isNotEmpty && !c.knownSkillIds.contains(required)) {
        continue;
      }
      out.add(id);
    }
  }
  if (faction != null && faction.isClan && faction.lean != 0) {
    final ids = c.skills.keys.toList()..sort();
    for (final id in ids) {
      final skill = c.skills[id];
      if (skill is! Map<String, dynamic> ||
          c.knownSkillIds.contains(id) ||
          out.contains(id) ||
          skill['enemyOnly'] == true ||
          !_leanOffersReputation(faction.lean, skill) ||
          !reputationAllows(skill, c.alignment) ||
          !skillFitsCharacter(skill,
              raceId: c.raceId, professionId: c.professionId)) {
        continue;
      }
      out.add(id);
    }
  }
  return out;
}

/// The factions sponsoring [skillId] for this character: what the skill
/// screen names under a skill not yet learned ("Offered by..."). A
/// reputation skill ([skills]' record says so) is the leaning clans'.
List<String> sponsorsOfSkill(
  String skillId, {
  required ClanData data,
  required Map<String, dynamic> skillTrees,
  required String raceId,
  required String professionId,
  Map<String, dynamic> skills = const {},
}) {
  final branches =
      skillBranchesFor(skillTrees, raceId: raceId, professionId: professionId);
  final onBranches = {
    for (final b in branches)
      if (b.skillIds.contains(skillId)) b.id,
  };
  final skill = skills[skillId];
  return [
    for (final f in data.factions.values)
      if (f.sponsors.any(onBranches.contains) ||
          (f.isClan &&
              skill is Map<String, dynamic> &&
              _leanOffersReputation(f.lean, skill)))
        f.id,
  ];
}

/// Whether [itemId] is worth offering to this character: an item that
/// exists, not already in the pack (a potion's charges always are), and a
/// spellbook only for a spell they can learn and don't know.
bool _itemOfferable(String itemId, OfferContext c) {
  final item = c.items[itemId];
  if (item is! Map<String, dynamic>) return false;
  final type = item['itemType']?.toString() ?? '';
  if (type == 'Potion') return true;
  if (c.ownedItemIds.contains(itemId)) return false;
  final spellId = spellbookSpellIdFor(item);
  if (spellId != null) {
    final spell = c.spells[spellId];
    if (c.knownSpellIds.contains(spellId)) return false;
    if (spell != null &&
        !canLearnSpell(spell,
            professionId: c.professionId, knownSpellIds: c.knownSpellIds)) {
      return false;
    }
  }
  return true;
}

/// The objects [factionId] can offer now: its `objects` whose tier
/// (`minTier`, lowered one step for a quest's suitor) standing has
/// reached.
List<String> offerableObjectsFor(String factionId, OfferContext c,
    {int tierBonus = 0}) {
  final faction = c.data.faction(factionId);
  if (faction == null) return const [];
  final tier = c.tierOf(factionId);
  final reach = StandingTier
      .values[min(StandingTier.values.length - 1, tier.index + tierBonus)];
  return [
    for (final o in faction.objects)
      if (reach.isAtLeast(o.minTier) && _itemOfferable(o.itemId, c)) o.itemId,
  ];
}

/// The titles [factionId] can offer: theirs from an `offer`, not held.
List<String> offerableTitlesFor(String factionId, OfferContext c) => [
      for (final t in c.data.titlesFor(factionId: factionId, source: 'offer'))
        if (!c.heldTitleIds.contains(t.id)) t.id,
    ];

/// Whether [factionId] brings its Sworn boon: it is the faction sworn to,
/// it has one, and it was never taken.
bool swornBoonDue(String factionId, OfferContext c) =>
    c.politics.isSworn(factionId) &&
    c.data.faction(factionId)?.sworn != null &&
    !c.swornBoonIds.contains(factionId);

/// What [factionId] could put on the table now, kind by kind.
Map<GiftKind, int> availableGiftKinds(String factionId, OfferContext c,
    {bool better = false}) {
  final faction = c.data.faction(factionId);
  if (faction == null) return const {};
  final signs = offerableSigns(factionId, signs: c.signs, held: c.heldSigns);
  final hasSign = signs.regular.isNotEmpty || signs.duos.isNotEmpty;
  if (faction.kind == PatronKind.otherworld || faction.isLost) {
    return {if (hasSign) GiftKind.sign: 1};
  }
  final bonus = better ? 1 : 0;
  return {
    if (swornBoonDue(factionId, c)) GiftKind.sworn: 1,
    if (offerableSkillsFor(factionId, c, tierBonus: bonus).isNotEmpty)
      GiftKind.skill: offerableSkillsFor(factionId, c, tierBonus: bonus).length,
    if (hasSign) GiftKind.sign: 1,
    if (offerableObjectsFor(factionId, c, tierBonus: bonus).isNotEmpty)
      GiftKind.object: 1,
    if (offerableTitlesFor(factionId, c).isNotEmpty) GiftKind.title: 1,
  };
}

/// Whether [faction] may come as a suitor at all: the story lets them
/// (a tribe's flag, the Choir's or the Pit's alignment), this life hasn't
/// shut them out (the Choir and the Pit shut each other out), and they
/// are neither Hostile nor Hunted.
bool suitorOpen(Faction faction, OfferContext c) =>
    patronOpen(faction.patron,
        flags: c.flags,
        alignment: c.alignment,
        patronsThisLife: c.patronsThisLife,
        patrons: c.patrons) &&
    c.tierOf(faction.id).isAtLeast(StandingTier.wary);

/// Every faction that could come now and has something to give, in the
/// file's order.
List<String> eligibleSuitors(OfferContext c) => [
      for (final f in c.data.factions.values)
        if (suitorOpen(f, c) && availableGiftKinds(f.id, c).isNotEmpty) f.id,
    ];

/// The Choir or the Pit, when a chapter's end brings them: the one the
/// alignment leans to (at or past their own threshold), if open and with
/// a sign left. Null when the alignment leans neither way.
String? otherworldLeaningFor(OfferContext c) {
  for (final f in c.data.otherworld) {
    if (suitorOpen(f, c) && availableGiftKinds(f.id, c).isNotEmpty) {
      return f.id;
    }
  }
  return null;
}

/// The Wayfarer's common objects: the Common potions and scrolls of
/// items.json.
List<String> wayfarerObjectsFor(OfferContext c) => [
      for (final e in c.items.entries)
        if (e.value is Map<String, dynamic> &&
            (e.value as Map<String, dynamic>)['rarity'] == 'Common' &&
            const {'Potion', 'Scroll'}
                .contains((e.value as Map<String, dynamic>)['itemType']))
          e.key,
    ]..sort();

/// [skill]'s rarity on the signs' scale: common stays common, uncommon
/// and rare read Rare, epic Epic, legendary Heroic.
SignRarity rarityOfSkill(Map<String, dynamic>? skill) =>
    switch (skillRarity(skill)) {
      SkillRarity.common => SignRarity.common,
      SkillRarity.uncommon || SkillRarity.rare => SignRarity.rare,
      SkillRarity.epic => SignRarity.epic,
      SkillRarity.legendary => SignRarity.heroic,
    };

/// [item]'s rarity on the signs' scale: Common, Uncommon reads Rare, Rare
/// reads Epic.
SignRarity rarityOfItem(Map<String, dynamic>? item) =>
    switch (item?['rarity']?.toString()) {
      'Uncommon' => SignRarity.rare,
      'Rare' => SignRarity.epic,
      'Epic' || 'Legendary' => SignRarity.heroic,
      _ => SignRarity.common,
    };

SignRarity _better(SignRarity rarity, [int steps = 1]) =>
    SignRarity.values[min(SignRarity.values.length - 1, rarity.index + steps)];

T _weighted<T>(Map<T, num> weights, Random random) {
  final total = weights.values.fold<num>(0, (sum, w) => sum + w);
  var roll = random.nextDouble() * total;
  for (final e in weights.entries) {
    roll -= e.value;
    if (roll < 0) return e.key;
  }
  return weights.keys.last;
}

/// The gift [factionId] brings (see [GiftKind]), or null when it has
/// none. The Choir and the Pit bring signs only, at least Rare; a clan
/// that is sworn to and owes its Sworn boon brings that; otherwise a kind
/// drawn at [giftKindWeights] among those it has. [better]: a quest's
/// suitor, one rarity better (and one tier deeper for skills and
/// objects).
OfferGift? drawGift(String factionId, OfferContext c, Random random,
    {bool better = false}) {
  final faction = c.data.faction(factionId);
  if (faction == null) return null;
  final kinds = availableGiftKinds(factionId, c, better: better);
  if (kinds.isEmpty) return null;
  final bonus = better ? 1 : 0;
  final GiftKind kind;
  if (kinds.containsKey(GiftKind.sworn)) {
    kind = GiftKind.sworn;
  } else {
    kind = _weighted(
        {for (final k in kinds.keys) k: giftKindWeights[k] ?? 1}, random);
  }
  switch (kind) {
    case GiftKind.sworn:
      return OfferGift(
          kind: GiftKind.sworn, id: factionId, rarity: SignRarity.heroic);
    case GiftKind.skill:
      final options = offerableSkillsFor(factionId, c, tierBonus: bonus);
      final id = options[random.nextInt(options.length)];
      final rarity = rarityOfSkill(c.skills[id] as Map<String, dynamic>?);
      return OfferGift(
          kind: GiftKind.skill,
          id: id,
          rarity: better ? _better(rarity) : rarity);
    case GiftKind.object:
      final options = offerableObjectsFor(factionId, c, tierBonus: bonus);
      final id = options[random.nextInt(options.length)];
      final rarity = rarityOfItem(c.items[id] as Map<String, dynamic>?);
      return OfferGift(
          kind: GiftKind.object,
          id: id,
          rarity: better ? _better(rarity) : rarity);
    case GiftKind.title:
      final options = offerableTitlesFor(factionId, c);
      return OfferGift(
          kind: GiftKind.title,
          id: options[random.nextInt(options.length)],
          rarity: better ? SignRarity.epic : SignRarity.rare);
    case GiftKind.sign:
      final offerable =
          offerableSigns(factionId, signs: c.signs, held: c.heldSigns);
      final regular = offerable.regular;
      final duos = offerable.duos;
      final SignDef sign;
      if (duos.isNotEmpty &&
          (regular.isEmpty || random.nextDouble() < duoOfferChance)) {
        sign = duos[random.nextInt(duos.length)];
      } else {
        sign = regular[random.nextInt(regular.length)];
      }
      var rarity = rollSignRarity(
        random: random,
        luck: c.luck,
        favourLevel: favourLevelFor(c.favour[factionId] ?? 0),
        duo: sign.isDuo,
      );
      if (faction.kind == PatronKind.otherworld &&
          rarity.index < SignRarity.rare.index) {
        rarity = SignRarity.rare;
      }
      if (better) rarity = _better(rarity);
      return OfferGift(kind: GiftKind.sign, id: sign.id, rarity: rarity);
    case GiftKind.perk:
      return null;
  }
}

/// The Wayfarer's gift: a perk rank (at [wayfarerPerkChance], while one is
/// left) or one of [wayfarerObjectsFor]; null when there is neither.
OfferGift? drawWayfarerGift(OfferContext c, Random random) {
  final perks = perksAvailable(c.perkRanks);
  final objects = wayfarerObjectsFor(c);
  if (perks.isEmpty && objects.isEmpty) return null;
  if (perks.isNotEmpty &&
      (objects.isEmpty || random.nextDouble() < wayfarerPerkChance)) {
    return OfferGift(
        kind: GiftKind.perk, id: perks[random.nextInt(perks.length)].name);
  }
  return OfferGift(
      kind: GiftKind.object, id: objects[random.nextInt(objects.length)]);
}

/// The suitor [factionId] sends: a sub-clan of theirs at random voices a
/// clan's gift (none for the others), with the gift drawn by [drawGift].
Suitor? drawSuitor(String factionId, OfferContext c, Random random,
    {bool better = false}) {
  final faction = c.data.faction(factionId);
  if (faction == null) return null;
  final gift = drawGift(factionId, c, random, better: better);
  if (gift == null) return null;
  final voices = faction.isClan ? c.data.subclansOf(factionId) : const [];
  final greetings = max(1, faction.patron.greetings.length);
  return Suitor(
    factionId: factionId,
    subclanId: voices.isEmpty ? '' : voices[random.nextInt(voices.length)].id,
    gift: gift,
    firstMeeting: !c.patronsMet.contains(factionId),
    greetingIndex: random.nextInt(greetings),
  );
}

/// Draws the offer for [ticket]: up to [offerSuitorCount] suitors from
/// different factions.
/// - **Who may come:** [eligibleSuitors] (clans not Hostile or Hunted,
///   tribes once found, the Choir or the Pit by the alignment, the one
///   shutting the other out); at most one of the Choir and the Pit.
/// - **Guaranteed places:** the ticket's faction (a quest's clan, one
///   rarity better), and at a chapter's end the Choir or the Pit when the
///   alignment leans to them.
/// - **The other places:** one leans to the factions the character stands
///   well with ([standingWeightFor]); the rest are drawn evenly (a tribe
///   at [tribeOfferWeight]).
/// - **The Wayfarer** takes a place at [wayfarerChance], and whenever
///   fewer than three factions can come.
/// Null when nobody at all can come.
ClanOffer? drawOffer(OfferTicket ticket, OfferContext c, Random random) {
  final eligible = eligibleSuitors(c);
  final suitors = <Suitor>[];
  final taken = <String>{};
  var otherworldTaken = false;

  bool isOtherworld(String id) =>
      c.data.faction(id)?.kind == PatronKind.otherworld;

  void take(Suitor? s) {
    if (s == null) return;
    suitors.add(s);
    taken.add(s.factionId);
    if (isOtherworld(s.factionId)) otherworldTaken = true;
  }

  // The ticket's own faction: a quest's clan comes whatever the draw.
  final forced = ticket.factionId;
  if (forced.isNotEmpty && c.data.faction(forced) != null) {
    take(drawSuitor(forced, c, random, better: ticket.better));
  }
  // A chapter's end: the Choir or the Pit, if the alignment leans.
  if (ticket.source == OfferSource.chapter && !otherworldTaken) {
    final leaning = otherworldLeaningFor(c);
    if (leaning != null && !taken.contains(leaning)) {
      take(drawSuitor(leaning, c, random));
    }
  }

  List<String> pool() => [
        for (final id in eligible)
          if (!taken.contains(id) && !(otherworldTaken && isOtherworld(id))) id,
      ];

  final wayfarerGift = drawWayfarerGift(c, random);
  final wayfarerComes = wayfarerGift != null &&
      (pool().length + suitors.length < offerSuitorCount ||
          random.nextDouble() < wayfarerChance);
  final factionPlaces = offerSuitorCount - (wayfarerComes ? 1 : 0);

  double tribeWeight(String id) =>
      c.data.faction(id)?.kind == PatronKind.tribe ? tribeOfferWeight : 1.0;

  // One place leans to standing.
  var leaned = false;
  while (suitors.length < factionPlaces) {
    final options = pool();
    if (options.isEmpty) break;
    final String id;
    if (!leaned) {
      leaned = true;
      id = _weighted({
        for (final o in options)
          o: standingWeightFor(c.politics.standingOf(o, c.data)) *
              tribeWeight(o),
      }, random);
    } else {
      id = _weighted({for (final o in options) o: tribeWeight(o)}, random);
    }
    final before = suitors.length;
    take(drawSuitor(id, c, random));
    // A faction with nothing to give after all is left out.
    if (suitors.length == before) taken.add(id);
  }
  if (wayfarerComes) {
    suitors.add(Suitor(
      factionId: wayfarerId,
      gift: wayfarerGift,
      firstMeeting: !c.patronsMet.contains(wayfarerId),
      greetingIndex: random.nextInt(4),
    ));
  }
  // The dead clan: "Your own hand", a fourth card (see ownHandComes).
  final hand = c.data.openHand;
  if (hand != null &&
      !taken.contains(hand.id) &&
      suitors.isNotEmpty &&
      ownHandComes(c.flags, random)) {
    final own = drawSuitor(hand.id, c, random);
    if (own != null) suitors.add(own);
  }
  if (suitors.isEmpty) return null;
  return ClanOffer(ticket: ticket, suitors: suitors);
}

/// Whether "Your own hand" (the Open Hand, v1.195) takes a fourth place in
/// an offer, with [flags] held: always from the last remembrance stage
/// with the banner raised; at [ownHandChance] from [ownHandFromStage];
/// never before. [random] is only drawn on when it is a chance.
bool ownHandComes(Iterable<String> flags, Random random) {
  final stage = openHandStageFrom(flags);
  if (stage >= openHandStages && bannerRaisedIn(flags)) return true;
  if (stage < ownHandFromStage) return false;
  return random.nextDouble() < ownHandChance;
}

/// Whether anyone at all could come now (an offer waiting with nobody to
/// bring it stays waiting, unannounced).
bool anySuitorCanCome(OfferContext c) =>
    eligibleSuitors(c).isNotEmpty ||
    perksAvailable(c.perkRanks).isNotEmpty ||
    wayfarerObjectsFor(c).isNotEmpty;

// --- Taking a suitor --------------------------------------------------------

/// The standing a suitor taken for [ticket] brings: [offerStandingGain],
/// or [majorOfferStandingGain] for a quest, an intrigue or a chapter's end.
int standingGainFor(OfferTicket ticket) =>
    ticket.major ? majorOfferStandingGain : offerStandingGain;

/// The log's cause for taking [gift] for [ticket]: `chapter:<n>`,
/// `quest:<id>` and `intrigue:<id>` for those, `offer:<gift id>` for the
/// rest.
String offerCause(OfferTicket ticket, OfferGift gift) =>
    switch (ticket.source) {
      OfferSource.chapter => 'chapter:${ticket.detail}',
      OfferSource.quest => 'quest:${ticket.detail}',
      OfferSource.intrigue => 'intrigue:${ticket.detail}',
      OfferSource.story when ticket.detail.isNotEmpty => ticket.detail,
      _ => 'offer:${gift.id}',
    };

/// The alignment [suitor]'s gift nudges, besides a sign's own (the
/// Choir's and the Pit's ±3, see alignmentShiftFor): the voicing
/// sub-clan's lean when it has one, else the faction's; nothing from the
/// Choir, the Pit or the Wayfarer.
int leanOf(Suitor suitor, ClanData data) {
  if (suitor.isWayfarer) return 0;
  final faction = data.faction(suitor.factionId);
  if (faction == null ||
      faction.kind == PatronKind.otherworld ||
      faction.isLost) {
    return 0;
  }
  final voice = data.subclan(suitor.subclanId);
  if (voice != null && voice.lean != 0) return voice.lean;
  return faction.lean;
}

/// What taking [suitor] for [ticket] would move, faction by faction: the
/// card's "+6 Compact · +1.5 Mire · −3 Penitents". Empty for the
/// Wayfarer; for "Your own hand" (a lost clan), nothing, or once the
/// banner is raised in [flags] the Dominion's [ownHandBannerCost].
Map<String, double> suitorPreview(
  Suitor suitor,
  OfferTicket ticket, {
  required PoliticsState politics,
  required ClanData data,
  Iterable<String> flags = const [],
}) {
  if (suitor.isWayfarer) return const {};
  if (data.faction(suitor.factionId)?.isLost ?? false) {
    return bannerRaisedIn(flags)
        ? standingPreview(politics, 'dominion', ownHandBannerCost, data: data)
        : const {};
  }
  return standingPreview(politics, suitor.factionId, standingGainFor(ticket),
      data: data);
}

/// What taking [suitor] does to the politics: the standing gain with its
/// ripple, the voicing sub-clan marked a friend, both logged under
/// [offerCause]; and the alignment nudge ([leanOf]). "Your own hand" (a
/// lost clan) moves no standing -- choosing yourself over the clans --
/// except, once the banner is raised in [flags], the Dominion's
/// [ownHandBannerCost]: they hunt the drawers.
({PoliticsState politics, StandingResult standing, int alignment})
    acceptPolitics(
  Suitor suitor,
  OfferTicket ticket, {
  required PoliticsState politics,
  required ClanData data,
  int chapter = 0,
  int day = 0,
  Iterable<String> flags = const [],
}) {
  if (suitor.isWayfarer) {
    return (
      politics: politics,
      standing: StandingResult(state: politics),
      alignment: 0
    );
  }
  final cause = offerCause(ticket, suitor.gift);
  if (data.faction(suitor.factionId)?.isLost ?? false) {
    final standing = bannerRaisedIn(flags)
        ? applyStandingChange(politics, 'dominion', ownHandBannerCost, cause,
            data: data, chapter: chapter, day: day)
        : StandingResult(state: politics);
    return (politics: standing.state, standing: standing, alignment: 0);
  }
  final standing = applyStandingChange(
      politics, suitor.factionId, standingGainFor(ticket), cause,
      data: data, chapter: chapter, day: day);
  var next = standing.state;
  if (suitor.subclanId.isNotEmpty) {
    next = setSubclanMark(next, suitor.subclanId, SubclanMark.friend, cause,
            data: data, chapter: chapter, day: day)
        .state;
  }
  return (politics: next, standing: standing, alignment: leanOf(suitor, data));
}

// --- Titles -----------------------------------------------------------------

/// What [politics] says of [held] titles: every tier title whose tier the
/// character has reached with its faction (kept once earned), and the
/// mark titles (`mark:<mark>:<sub-clan>`, "the Marked") held only while
/// the mark stands; with [flags], the Open Hand's remembrance titles
/// (v1.195, see remembranceTitlesFor), kept once earned. Returns the
/// titles held after, and those [gained] and [lost].
({List<String> held, List<String> gained, List<String> lost}) titlesEarned(
  List<String> held,
  PoliticsState politics,
  ClanData data, {
  Iterable<String> flags = const [],
}) {
  final next = [...held];
  final gained = <String>[];
  final lost = <String>[];
  for (final id in remembranceTitlesFor(flags, data)) {
    if (!next.contains(id)) {
      next.add(id);
      gained.add(id);
    }
  }
  for (final title in data.titles.values) {
    final source = title.source;
    if (source.startsWith('tier:')) {
      final tier = standingTierNamed(source.substring(5));
      if (tier == null || title.factionId.isEmpty) continue;
      if (!next.contains(title.id) &&
          data.faction(title.factionId) != null &&
          politics.tierOf(title.factionId, data).isAtLeast(tier)) {
        next.add(title.id);
        gained.add(title.id);
      }
    } else if (source.startsWith('mark:')) {
      final parts = source.split(':');
      if (parts.length != 3) continue;
      final mark = subclanMarkNamed(parts[1]);
      if (mark == null) continue;
      final has = politics.markOf(parts[2]) == mark;
      if (has && !next.contains(title.id)) {
        next.add(title.id);
        gained.add(title.id);
      } else if (!has && next.remove(title.id)) {
        lost.add(title.id);
      }
    }
  }
  return (held: next, gained: gained, lost: lost);
}

/// The title worn after [held] changed: [active] while still held, else
/// the first good title gained, else none ('').
String activeTitleAfter(
  String active,
  List<String> held,
  List<String> gained,
  ClanData data,
) {
  if (active.isNotEmpty && held.contains(active)) return active;
  for (final id in [...gained, ...held]) {
    final title = data.titles[id];
    if (title != null && !title.negative) return id;
  }
  return '';
}

/// The effects the clans add to a fight, through the signs' machinery
/// (see signEffectsFor's `extra`): the worn title's; every bad title held
/// (a brand is worn whether chosen or not); and the Sworn boon of the
/// faction still sworn to.
List<SignEffect> clanEffectsFor({
  required String activeTitleId,
  required List<String> heldTitleIds,
  required List<String> swornBoonIds,
  required String swornFactionId,
  required ClanData data,
}) =>
    [
      for (final id in heldTitleIds)
        if (data.titles[id] case final title?)
          if (id == activeTitleId || title.negative) ...title.effects,
      if (swornFactionId.isNotEmpty && swornBoonIds.contains(swornFactionId))
        ...?data.faction(swornFactionId)?.sworn?.effects,
    ];

// --- The simulator's pick ---------------------------------------------------

/// The simulator's pick (and a fair default): a skill that fills an empty
/// die face ([fillsEmptyFace]) first, else the rarest gift (a sign for an
/// empty slot before one that replaces). With [favourBest] the suitor of
/// the faction the character stands best with is taken instead.
Suitor? preferredSuitor(
  ClanOffer offer, {
  required bool Function(String skillId) fillsEmptyFace,
  required List<HeldSign> heldSigns,
  required Map<String, SignDef> signs,
  bool favourBest = false,
  PoliticsState politics = PoliticsState.empty,
  ClanData data = ClanData.empty,
}) {
  if (offer.suitors.isEmpty) return null;
  if (favourBest) {
    final factions = [
      for (final s in offer.suitors)
        if (!s.isWayfarer) s,
    ];
    if (factions.isNotEmpty) {
      return factions.reduce((a, b) => politics.standingOf(b.factionId, data) >
              politics.standingOf(a.factionId, data)
          ? b
          : a);
    }
  }
  int score(Suitor s) {
    final gift = s.gift;
    if (gift.kind == GiftKind.skill && fillsEmptyFace(gift.id)) return 100;
    var score = gift.rarity.index * 10;
    if (gift.kind == GiftKind.sworn) score += 50;
    if (gift.kind == GiftKind.sign) {
      final sign = signs[gift.id];
      if (sign != null && heldInSlot(sign.slot, heldSigns, signs) == null) {
        score += 5;
      }
    }
    return score;
  }

  return offer.suitors.reduce((a, b) => score(b) > score(a) ? b : a);
}
