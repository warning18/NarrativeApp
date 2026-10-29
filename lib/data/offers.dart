import 'dart:math';

import '../combat/dice_faces.dart' show SkillRarity, skillRarity;
import '../combat/spells.dart'
    show SpellSpec, canLearnSpell, spellbookSpellIdFor;
import '../combat/spec_variants.dart' show SpecVariantInfo, SpecVariantKind;
import '../combat/specialisations.dart'
    show
        SpecInfo,
        specId,
        specNamed,
        specsOfferedBy,
        tempestSkillId,
        weakLinkSpecs;
import 'clan_power.dart';
import 'factions.dart';
import 'perks.dart';
import 'risky_gifts.dart';
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
const double _wayfarerChance = 0.20;

/// Odds the Wayfarer brings a perk rank (when one is left) rather than a
/// common object.
const double _wayfarerPerkChance = 0.75;

/// Standing gained with the faction whose gift is taken; a quest's,
/// an intrigue's or a chapter's end is worth more.
const int _offerStandingGain = 6;
const int _majorOfferStandingGain = 10;

/// How much likelier the clan of the character's own people is to take the
/// home seat while their heritage branch still has a skill to offer.
const double homeHeritageWeight = 3.0;

/// The weight of a clan that has only a fusion or an ascension left to
/// bring, once its branches are grown.
const double _homeAccordWeight = 1.5;

/// Odds a clan with a fusion or an ascension to offer brings one rather
/// than a skill of its branches.
const double _accordPickChance = 0.5;

/// Standing a fusion needs with *both* clans (Trusted), and an ascension
/// with its one (Friend, a step easier since one clan alone is asked); v1.233.
const StandingTier _fusionMinTier = StandingTier.trusted;
const StandingTier _ascensionMinTier = StandingTier.friend;

/// Standing a sub-clan's skill and a secret need with the clan that offers
/// them (v1.234).
const StandingTier _subclanMinTier = StandingTier.known;

/// Standing a main clan's specialisation needs (v5.2: Friend, 19+), its
/// sub-clans' variants and upgrades (Trusted) and its rank II (Sworn).
const StandingTier _specMinTier = StandingTier.friend;
const StandingTier _specVariantMinTier = StandingTier.trusted;
const StandingTier _specRankMinTier = StandingTier.sworn;
const StandingTier _secretMinTier = StandingTier.known;

/// The weight of each kind of gift a clan may bring, among those it has.
const Map<GiftKind, int> _giftKindWeights = {
  GiftKind.spec: 60,
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
double _standingWeightFor(double standing) =>
    (standing + 30).clamp(5, 130).toDouble();

// --- What the session keeps -------------------------------------------------

/// Why an offer is due.
enum OfferSource {
  /// A level reached (replacing the skill point, the perk and the sign).
  level,

  /// A boss beaten.
  boss,

  /// A new chapter reached: the Choir or the Pit come if the alignment
  /// leans (see [_otherworldLeaningFor]).
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

OfferSource _offerSourceNamed(String? name) =>
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
  /// [_majorOfferStandingGain].
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
        source: _offerSourceNamed(json['source']?.toString()),
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

  /// A specialisation of the character's core (specialisations.dart): its
  /// main clan's, from Friend, once.
  spec,
}

GiftKind? _giftKindNamed(String? name) =>
    GiftKind.values.where((k) => k.name == name).firstOrNull;

/// A gift: its [kind], the [id] of what is given (a skill, sign, item or
/// title id, the faction's id for a Sworn boon, a perk's name), and its
/// [rarity] -- a sign's own, the others' read on the same scale (see
/// [_rarityOfSkill], [rarityOfItem]).
class OfferGift {
  const OfferGift({
    required this.kind,
    required this.id,
    this.rarity = SignRarity.common,
    this.partnerId = '',
  });

  final GiftKind kind;
  final String id;
  final SignRarity rarity;

  /// A fusion skill's second clan (v1.232): the gift is offered by two
  /// clans together, and taking it raises both. Empty for any other gift.
  final String partnerId;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'id': id,
        'rarity': rarity.name,
        if (partnerId.isNotEmpty) 'partner': partnerId,
      };

  static OfferGift? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final kind = _giftKindNamed(raw['kind']?.toString());
    final id = raw['id']?.toString() ?? '';
    if (kind == null || id.isEmpty) return null;
    return OfferGift(
      kind: kind,
      id: id,
      rarity: SignRarity.values
              .where((r) => r.name == raw['rarity']?.toString())
              .firstOrNull ??
          SignRarity.common,
      partnerId: raw['partner']?.toString() ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OfferGift &&
      other.kind == kind &&
      other.id == id &&
      other.rarity == rarity &&
      other.partnerId == partnerId;

  @override
  int get hashCode => Object.hash(kind, id, rarity, partnerId);
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
    this.risky = false,
    this.riskRoll = 0,
    this.raised = false,
  });

  final String factionId;
  final String subclanId;
  final OfferGift gift;
  final bool firstMeeting;
  final int greetingIndex;

  /// A risky gift (risky_gifts.dart): [gift] one rarity better than it
  /// would be, at a price [riskRoll] (a d20, rolled with the draw) names
  /// when it is taken.
  final bool risky;
  final int riskRoll;

  /// Raised at the Star Well (camp_rolls.dart): a card is raised once.
  final bool raised;

  bool get isWayfarer => factionId == wayfarerId;

  /// This suitor's card made risky, with the die's [roll].
  Suitor asRisky(int roll) => Suitor(
        factionId: factionId,
        subclanId: subclanId,
        gift: gift,
        firstMeeting: firstMeeting,
        greetingIndex: greetingIndex,
        risky: true,
        riskRoll: roll,
        raised: raised,
      );

  /// This suitor's card raised at the Star Well (camp_rolls.dart) to
  /// [gift], voiced by [subclanId] (its own when null).
  Suitor asRaised(OfferGift gift, {String? subclanId}) => Suitor(
        factionId: factionId,
        subclanId: subclanId ?? this.subclanId,
        gift: gift,
        firstMeeting: firstMeeting,
        greetingIndex: greetingIndex,
        risky: risky,
        riskRoll: riskRoll,
        raised: true,
      );

  Map<String, dynamic> toJson() => {
        'faction': factionId,
        if (subclanId.isNotEmpty) 'subclan': subclanId,
        'gift': gift.toJson(),
        if (firstMeeting) 'first': true,
        'greeting': greetingIndex,
        if (risky) 'risky': true,
        if (risky) 'riskRoll': riskRoll,
        if (raised) 'raised': true,
      };

  static Suitor? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final gift = OfferGift.tryParse(raw['gift']);
    final faction = raw['faction']?.toString() ?? '';
    if (gift == null || faction.isEmpty) return null;
    // An old save has neither: the card is a normal one.
    final roll = (raw['riskRoll'] as num?)?.toInt() ?? 0;
    final risky = raw['risky'] == true && roll >= 1 && roll <= 20;
    return Suitor(
      factionId: faction,
      subclanId: raw['subclan']?.toString() ?? '',
      gift: gift,
      firstMeeting: raw['first'] == true,
      greetingIndex: (raw['greeting'] as num?)?.toInt() ?? 0,
      risky: risky,
      riskRoll: risky ? roll : 0,
      raised: raw['raised'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Suitor &&
      other.factionId == factionId &&
      other.subclanId == subclanId &&
      other.gift == gift &&
      other.firstMeeting == firstMeeting &&
      other.greetingIndex == greetingIndex &&
      other.risky == risky &&
      other.riskRoll == riskRoll &&
      other.raised == raised;

  @override
  int get hashCode => Object.hash(
        factionId,
        subclanId,
        gift,
        firstMeeting,
        greetingIndex,
        risky,
        riskRoll,
        raised,
      );
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
    this.specs = const {},
    this.specVariants = const {},
  });

  /// spec_variants.json parsed (spec_variants.dart).
  final Map<String, SpecVariantInfo> specVariants;

  final ClanData data;
  final Map<String, SignDef> signs;
  final Map<String, dynamic> skills;
  final Map<String, dynamic> skillTrees;
  final Map<String, dynamic> items;
  final Map<String, SpellSpec> spells;

  /// specialisations.json parsed (specialisations.dart).
  final Map<String, SpecInfo> specs;
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
    this.specs = const {},
    this.heldSpecIds = const [],
    this.specVariants = const {},
    this.placeHolder = '',
    this.riskyGifts = false,
    this.bannedGifts = const {},
  });

  /// The gifts warded off at the Warding Cairn (camp_rolls.dart), as
  /// `kind:id` ([giftBanId]): no clan offers them while another gift is
  /// left to it (see [availableGiftKinds]).
  final Set<String> bannedGifts;

  /// Whether gift [id] of [kind] is warded off.
  bool isBanned(GiftKind kind, String id) =>
      bannedGifts.isNotEmpty && bannedGifts.contains('${kind.name}:$id');

  /// This context with [bans] as its warded gifts.
  OfferContext withBans(Set<String> bans) => OfferContext(
        data: data,
        politics: politics,
        signs: signs,
        heldSigns: heldSigns,
        skills: skills,
        skillTrees: skillTrees,
        items: items,
        raceId: raceId,
        professionId: professionId,
        knownSkillIds: knownSkillIds,
        ownedItemIds: ownedItemIds,
        knownSpellIds: knownSpellIds,
        spells: spells,
        flags: flags,
        alignment: alignment,
        patronsThisLife: patronsThisLife,
        favour: favour,
        patronsMet: patronsMet,
        heldTitleIds: heldTitleIds,
        swornBoonIds: swornBoonIds,
        perkRanks: perkRanks,
        luck: luck,
        specs: specs,
        heldSpecIds: heldSpecIds,
        specVariants: specVariants,
        placeHolder: placeHolder,
        riskyGifts: riskyGifts,
        bannedGifts: bans,
      );

  /// Whether risky gifts are open (the Parley Tent built, see
  /// risky_gifts.dart).
  final bool riskyGifts;

  /// The clan that holds the place the offer is made in (clan_power.dart's
  /// holderOf): its suitor comes [heldPlaceSuitorWeight] times as often;
  /// '' for none.
  final String placeHolder;

  /// spec_variants.json parsed: the sub-clans' variants and the ranks II.
  final Map<String, SpecVariantInfo> specVariants;

  /// specialisations.json parsed, and the specialisations held.
  final Map<String, SpecInfo> specs;
  final List<String> heldSpecIds;

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
List<SkillBranch> _sponsoredBranchesFor(String factionId, OfferContext c) {
  final faction = c.data.faction(factionId);
  if (faction == null) return const [];
  final mine = skillBranchesFor(
    c.skillTrees,
    raceId: c.raceId,
    professionId: c.professionId,
  );
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
List<String> offerableSkillsFor(
  String factionId,
  OfferContext c, {
  int tierBonus = 0,
  int deepest = 3,
}) {
  final cap = min(deepest, skillIndexCapFor(c.tierOf(factionId)) + tierBonus);
  final out = <String>[];
  final faction = c.data.faction(factionId);
  for (final branch in _sponsoredBranchesFor(factionId, c)) {
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
  // The Tempest Toll: the Crows offer Teleport Strike (specialisations.dart).
  if (c.specs['tempest_toll']?.factionId == factionId &&
      c.heldSpecIds.contains('tempest_toll') &&
      c.skills[tempestSkillId] is Map<String, dynamic> &&
      !c.knownSkillIds.contains(tempestSkillId) &&
      !out.contains(tempestSkillId)) {
    out.add(tempestSkillId);
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
          !skillFitsCharacter(
            skill,
            raceId: c.raceId,
            professionId: c.professionId,
          )) {
        continue;
      }
      out.add(id);
    }
  }
  if (c.bannedGifts.isNotEmpty) {
    out.removeWhere((id) => c.isBanned(GiftKind.skill, id));
  }
  return out;
}

/// A fusion or an ascension one clan can put on the table (v1.232):
/// [skillId] is the new skill; [partnerId] the second clan of a fusion,
/// empty for an ascension.
class AccordOffer {
  const AccordOffer(this.skillId, [this.partnerId = '']);

  final String skillId;
  final String partnerId;
}

/// The fusions and ascensions [factionId] can offer now.
/// - **Fusion** (`fusionOf`: two skills): both parents known, [factionId]
///   behind one of them and another open clan behind the other, the
///   character at [_fusionMinTier] with both (the partner is the one they
///   stand best with). Offered by either clan, the card shows both.
/// - **Ascension** (`ascendsSkillID`): the skill it raises is known, the
///   character at [_ascensionMinTier] with [factionId], which sponsors it.
/// In the skills' file order, no repeats.
/// A warded skill (camp_rolls.dart) is left out.
List<AccordOffer> accordsFor(String factionId, OfferContext c) {
  final all = (_accordCache[c] ??= {}).putIfAbsent(
    factionId,
    () => _accordsFor(factionId, c),
  );
  if (c.bannedGifts.isEmpty) return all;
  return [
    for (final a in all)
      if (!c.isBanned(GiftKind.skill, a.skillId)) a,
  ];
}

/// The cards of each context drawn so far (a context is built per draw and
/// never changes, so each clan's cards are worked out once).
final Expando<Map<String, List<AccordOffer>>> _accordCache = Expando();

List<AccordOffer> _accordsFor(String factionId, OfferContext c) {
  final out = <AccordOffer>[];
  final tier = c.tierOf(factionId);
  List<String> sponsors(String skillId) => sponsorsOfSkill(
        skillId,
        data: c.data,
        skillTrees: c.skillTrees,
        raceId: c.raceId,
        professionId: c.professionId,
        skills: c.skills,
      );
  for (final entry in c.skills.entries) {
    final skill = entry.value;
    if (skill is! Map<String, dynamic> ||
        c.knownSkillIds.contains(entry.key) ||
        skill['enemyOnly'] == true ||
        !skillFitsCharacter(
          skill,
          raceId: c.raceId,
          professionId: c.professionId,
        )) {
      continue;
    }
    final parents = [
      for (final p in (skill['fusionOf'] as List?) ?? const []) p.toString(),
    ];
    if (parents.length == 2) {
      if (!parents.every(c.knownSkillIds.contains) ||
          !tier.isAtLeast(_fusionMinTier)) {
        continue;
      }
      // The clan may stand behind either parent (or both): the partner is
      // whoever stands behind the other one.
      final partners = <String>{
        for (var i = 0; i < 2; i++)
          if (sponsors(parents[i]).contains(factionId))
            for (final id in sponsors(parents[1 - i]))
              if (id != factionId &&
                  c.data.faction(id) != null &&
                  c.data.faction(id)!.isClan &&
                  suitorOpen(c.data.faction(id)!, c) &&
                  c.tierOf(id).isAtLeast(_fusionMinTier))
                id,
      }.toList()
        ..sort(
          (a, b) => c.politics
              .standingOf(b, c.data)
              .compareTo(c.politics.standingOf(a, c.data)),
        );
      if (partners.isNotEmpty) out.add(AccordOffer(entry.key, partners.first));
      continue;
    }
    // A sub-clan's skill (v1.234): its clan offers it, in its voice, once
    // the sub-clan is the character's friend.
    final subclan = c.data.subclan(skill['subclanId']?.toString() ?? '');
    if (subclan != null) {
      if (subclan.clanId == factionId &&
          c.politics.markOf(subclan.id) == SubclanMark.friend &&
          tier.isAtLeast(_subclanMinTier) &&
          _prerequisiteKnown(skill, c)) {
        out.add(AccordOffer(entry.key));
      }
      continue;
    }
    // A secret (v1.234): hidden until the story flags are held, then taught
    // by its clan.
    final secretFlags = [
      for (final f in (skill['hiddenFlags'] as List?) ?? const []) f.toString(),
    ];
    if (secretFlags.isNotEmpty) {
      final held = c.flags.toSet();
      if (skill['hiddenClan']?.toString() == factionId &&
          secretFlags.every(held.contains) &&
          tier.isAtLeast(_secretMinTier) &&
          _prerequisiteKnown(skill, c)) {
        out.add(AccordOffer(entry.key));
      }
      continue;
    }
    final base = skill['ascendsSkillID']?.toString() ?? '';
    if (base.isNotEmpty &&
        c.knownSkillIds.contains(base) &&
        tier.isAtLeast(_ascensionMinTier) &&
        sponsors(base).contains(factionId)) {
      out.add(AccordOffer(entry.key));
    }
  }
  return out;
}

bool _prerequisiteKnown(Map<String, dynamic> skill, OfferContext c) {
  final required = skill['requiredSkillID']?.toString() ?? '';
  return required.isEmpty || c.knownSkillIds.contains(required);
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
  final skill = skills[skillId];
  // A sub-clan's skill is its clan's (v1.234); a secret has no sponsor to
  // show until it is found.
  if (skill is Map<String, dynamic>) {
    final sub = data.subclan(skill['subclanId']?.toString() ?? '');
    if (sub != null) return [sub.clanId];
    if (skill['hiddenFlags'] is List) return const [];
  }
  // A fusion is offered by the clans behind its two parents, an ascension
  // by the clans behind the skill it raises (v1.232).
  if (skill is Map<String, dynamic>) {
    final parents = <String>[
      ...?(skill['fusionOf'] as List?)?.map((e) => e.toString()),
      if ((skill['ascendsSkillID']?.toString() ?? '').isNotEmpty)
        skill['ascendsSkillID'].toString(),
    ];
    if (parents.isNotEmpty) {
      return {
        for (final parent in parents)
          ...sponsorsOfSkill(
            parent,
            data: data,
            skillTrees: skillTrees,
            raceId: raceId,
            professionId: professionId,
            skills: skills,
          ),
      }.toList();
    }
  }
  final branches = skillBranchesFor(
    skillTrees,
    raceId: raceId,
    professionId: professionId,
  );
  final onBranches = {
    for (final b in branches)
      if (b.skillIds.contains(skillId)) b.id,
  };
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
        !canLearnSpell(
          spell,
          professionId: c.professionId,
          knownSpellIds: c.knownSpellIds,
        )) {
      return false;
    }
  }
  return true;
}

/// The objects [factionId] can offer now: its `objects` whose tier
/// (`minTier`, lowered one step for a quest's suitor) standing has
/// reached.
List<String> offerableObjectsFor(
  String factionId,
  OfferContext c, {
  int tierBonus = 0,
}) {
  final faction = c.data.faction(factionId);
  if (faction == null) return const [];
  final tier = c.tierOf(factionId);
  final reach = StandingTier
      .values[min(StandingTier.values.length - 1, tier.index + tierBonus)];
  return [
    for (final o in faction.objects)
      if (reach.isAtLeast(o.minTier) &&
          _itemOfferable(o.itemId, c) &&
          !c.isBanned(GiftKind.object, o.itemId))
        o.itemId,
  ];
}

/// The titles [factionId] can offer: theirs from an `offer`, not held.
List<String> offerableTitlesFor(String factionId, OfferContext c) => [
      for (final t in c.data.titlesFor(factionId: factionId, source: 'offer'))
        if (!c.heldTitleIds.contains(t.id) && !c.isBanned(GiftKind.title, t.id))
          t.id,
    ];

/// The specialisations [factionId] can offer now: its own for the
/// character's profession (specialisations.json), not held, once standing
/// has reached [_specMinTier].
/// From Trusted, the variants and upgrades of the specialisations of
/// theirs the character holds, and from Sworn their rank II
/// (spec_variants.json); none held twice.
List<String> offerableSpecsFor(String factionId, OfferContext c) {
  final tier = c.tierOf(factionId);
  if (!tier.isAtLeast(_specMinTier)) return const [];
  final mine = specsOfferedBy(
    c.specs,
    factionId: factionId,
    professionId: c.professionId,
  );
  final ids = [
    for (final info in mine)
      if (!c.heldSpecIds.contains(info.id)) info.id,
  ];
  final held = {
    for (final info in mine)
      if (c.heldSpecIds.contains(info.id)) specId(info.spec),
  };
  final variants = c.specVariants.values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  for (final v in variants) {
    if (!held.contains(specId(v.spec)) || c.heldSpecIds.contains(v.id)) {
      continue;
    }
    final need =
        v.kind == SpecVariantKind.rank ? _specRankMinTier : _specVariantMinTier;
    if (tier.isAtLeast(need)) ids.add(v.id);
  }
  if (c.bannedGifts.isNotEmpty) {
    ids.removeWhere((id) => c.isBanned(GiftKind.spec, id));
  }
  return ids;
}

/// Whether gift [id] is a weak link's (step 3c, [weakLinkSpecs]).
bool _isWeakLinkGift(String id) => weakLinkSpecs.contains(specNamed(id));

/// Whether [factionId] brings its Sworn boon: it is the faction sworn to,
/// it has one, and it was never taken.
bool swornBoonDue(String factionId, OfferContext c) =>
    c.politics.isSworn(factionId) &&
    c.data.faction(factionId)?.sworn != null &&
    !c.swornBoonIds.contains(factionId);

/// The signs [factionId] could offer ([offerableSigns]), the warded ones
/// left out.
({List<SignDef> regular, List<SignDef> duos}) _signsOf(
  String factionId,
  OfferContext c,
) {
  final all = offerableSigns(factionId, signs: c.signs, held: c.heldSigns);
  if (c.bannedGifts.isEmpty) return all;
  bool open(SignDef d) => !c.isBanned(GiftKind.sign, d.id);
  return (
    regular: all.regular.where(open).toList(),
    duos: all.duos.where(open).toList(),
  );
}

/// What [factionId] could put on the table now, kind by kind. A clan whose
/// every gift is warded (camp_rolls.dart) keeps them: the ban is ignored
/// for it (see [giftsLeftAfterBans]).
Map<GiftKind, int> availableGiftKinds(
  String factionId,
  OfferContext c, {
  bool better = false,
}) {
  final kinds = _giftKinds(factionId, c, better: better);
  if (kinds.isNotEmpty || c.bannedGifts.isEmpty) return kinds;
  return _giftKinds(factionId, c.withBans(const {}), better: better);
}

/// Whether [factionId] has a gift left that is not warded.
bool giftsLeftAfterBans(
  String factionId,
  OfferContext c, {
  bool better = false,
}) =>
    _giftKinds(factionId, c, better: better).isNotEmpty;

Map<GiftKind, int> _giftKinds(
  String factionId,
  OfferContext c, {
  bool better = false,
}) {
  final faction = c.data.faction(factionId);
  if (faction == null) return const {};
  final signs = _signsOf(factionId, c);
  final hasSign = signs.regular.isNotEmpty || signs.duos.isNotEmpty;
  if (faction.kind == PatronKind.otherworld || faction.isLost) {
    return {if (hasSign) GiftKind.sign: 1};
  }
  final bonus = better ? 1 : 0;
  final skillOptions = offerableSkillsFor(factionId, c, tierBonus: bonus);
  final accords = accordsFor(factionId, c);
  return {
    if (swornBoonDue(factionId, c)) GiftKind.sworn: 1,
    if (offerableSpecsFor(factionId, c).isNotEmpty) GiftKind.spec: 1,
    if (skillOptions.isNotEmpty || accords.isNotEmpty)
      GiftKind.skill: skillOptions.length + accords.length,
    if (hasSign) GiftKind.sign: 1,
    if (offerableObjectsFor(factionId, c, tierBonus: bonus).isNotEmpty)
      GiftKind.object: 1,
    if (offerableTitlesFor(factionId, c).isNotEmpty) GiftKind.title: 1,
  };
}

/// How much more often the clan holding the place an offer is made in
/// sends its suitor (clan_power.dart).
const double heldPlaceSuitorWeight = 1.5;

/// The strongest sign a clan of power [tier] gives (clan_power.dart): a
/// Minor one up to epic, a Rising or stronger one heroic. (Rare for a
/// Minor one and epic for a Rising one, as first planned, threw Claimant
/// Tallis off its curve in boss_balance_test.)
SignRarity maxSignRarityFor(PowerTier tier) => switch (tier) {
      PowerTier.minor => SignRarity.epic,
      _ => SignRarity.heroic,
    };

/// Whether [faction] may come as a suitor at all: the story lets them
/// (a tribe's flag, the Choir's or the Pit's alignment), this life hasn't
/// shut them out (the Choir and the Pit shut each other out), they are
/// neither Hostile nor Hunted, and (clan_power.dart) they have not fallen,
/// unless the character stayed of them.
bool suitorOpen(Faction faction, OfferContext c) =>
    patronOpen(
      faction.patron,
      flags: c.flags,
      alignment: c.alignment,
      patronsThisLife: c.patronsThisLife,
      patrons: c.patrons,
    ) &&
    c.tierOf(faction.id).isAtLeast(StandingTier.resented) &&
    // A fallen clan sends no one -- but to the character who stayed of it
    // (clan_crisis.dart): its survivors still come.
    (!c.politics.fallen.contains(faction.id) ||
        c.politics.fallenOf == faction.id);

/// Every faction that could come now and has something to give, in the
/// file's order.
List<String> eligibleSuitors(OfferContext c) => [
      for (final f in c.data.factions.values)
        if (suitorOpen(f, c) && availableGiftKinds(f.id, c).isNotEmpty) f.id,
    ];

/// The Choir or the Pit, when a chapter's end brings them: the one the
/// alignment leans to (at or past their own threshold), if open and with
/// a sign left. Null when the alignment leans neither way.
String? _otherworldLeaningFor(OfferContext c) {
  for (final f in c.data.otherworld) {
    if (suitorOpen(f, c) && availableGiftKinds(f.id, c).isNotEmpty) {
      return f.id;
    }
  }
  return null;
}

/// The Wayfarer's common objects: the Common potions and scrolls of
/// items.json.
List<String> _wayfarerObjectsFor(OfferContext c) => [
      for (final e in c.items.entries)
        if (e.value is Map<String, dynamic> &&
            (e.value as Map<String, dynamic>)['rarity'] == 'Common' &&
            const {
              'Potion',
              'Scroll',
            }.contains((e.value as Map<String, dynamic>)['itemType']))
          e.key,
    ]..sort();

/// [skill]'s rarity on the signs' scale: common stays common, uncommon
/// and rare read Rare, epic Epic, legendary Heroic.
SignRarity _rarityOfSkill(Map<String, dynamic>? skill) =>
    switch (skillRarity(skill)) {
      SkillRarity.common => SignRarity.common,
      SkillRarity.uncommon || SkillRarity.rare => SignRarity.rare,
      SkillRarity.epic => SignRarity.epic,
      SkillRarity.legendary => SignRarity.heroic,
    };

/// [item]'s rarity on the signs' scale: Common, Uncommon reads Rare, Rare
/// reads Epic, a Relic (v1.204) heroic.
SignRarity rarityOfItem(Map<String, dynamic>? item) =>
    switch (item?['rarity']?.toString()) {
      'Uncommon' => SignRarity.rare,
      'Rare' => SignRarity.epic,
      'Relic' || 'Epic' || 'Legendary' => SignRarity.heroic,
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

OfferGift _accordGift(AccordOffer accord, OfferContext c, bool better) {
  final rarity = _rarityOfSkill(
    c.skills[accord.skillId] as Map<String, dynamic>?,
  );
  return OfferGift(
    kind: GiftKind.skill,
    id: accord.skillId,
    rarity: better ? _better(rarity) : rarity,
    partnerId: accord.partnerId,
  );
}

/// The gift [factionId] brings (see [GiftKind]), or null when it has
/// none. The Choir and the Pit bring signs only, at least Rare; a clan
/// that is sworn to and owes its Sworn boon brings that; otherwise a kind
/// drawn at [_giftKindWeights] among those it has. [better]: a quest's
/// suitor, one rarity better (and one tier deeper for skills and
/// objects).
OfferGift? drawGift(
  String factionId,
  OfferContext c,
  Random random, {
  bool better = false,
}) {
  final faction = c.data.faction(factionId);
  if (faction == null) return null;
  // Every gift of the clan warded: the ban is ignored for it.
  if (c.bannedGifts.isNotEmpty &&
      !giftsLeftAfterBans(factionId, c, better: better)) {
    c = c.withBans(const {});
  }
  final kinds = availableGiftKinds(factionId, c, better: better);
  if (kinds.isEmpty) return null;
  final bonus = better ? 1 : 0;
  final GiftKind kind;
  if (kinds.containsKey(GiftKind.sworn)) {
    kind = GiftKind.sworn;
  } else {
    // A weak link's gift comes half as often as a main clan's
    // specialisation (step 3c).
    final weakOnly = kinds.containsKey(GiftKind.spec) &&
        offerableSpecsFor(factionId, c).every(_isWeakLinkGift);
    kind = _weighted({
      for (final k in kinds.keys)
        k: k == GiftKind.spec && weakOnly
            ? max(1, _giftKindWeights[k]! ~/ 2)
            : _giftKindWeights[k] ?? 1,
    }, random);
  }
  switch (kind) {
    case GiftKind.sworn:
      return OfferGift(
        kind: GiftKind.sworn,
        id: factionId,
        rarity: SignRarity.heroic,
      );
    case GiftKind.skill:
      final options = offerableSkillsFor(factionId, c, tierBonus: bonus);
      final accords = accordsFor(factionId, c);
      if (accords.isNotEmpty &&
          (options.isEmpty || random.nextDouble() < _accordPickChance)) {
        return _accordGift(accords[random.nextInt(accords.length)], c, better);
      }
      final id = options[random.nextInt(options.length)];
      final rarity = _rarityOfSkill(c.skills[id] as Map<String, dynamic>?);
      return OfferGift(
        kind: GiftKind.skill,
        id: id,
        rarity: better ? _better(rarity) : rarity,
      );
    case GiftKind.object:
      final options = offerableObjectsFor(factionId, c, tierBonus: bonus);
      final id = options[random.nextInt(options.length)];
      final rarity = rarityOfItem(c.items[id] as Map<String, dynamic>?);
      return OfferGift(
        kind: GiftKind.object,
        id: id,
        rarity: better ? _better(rarity) : rarity,
      );
    case GiftKind.title:
      final options = offerableTitlesFor(factionId, c);
      return OfferGift(
        kind: GiftKind.title,
        id: options[random.nextInt(options.length)],
        rarity: better ? SignRarity.epic : SignRarity.rare,
      );
    case GiftKind.sign:
      final offerable = _signsOf(factionId, c);
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
    case GiftKind.spec:
      final options = offerableSpecsFor(factionId, c);
      final id = options[random.nextInt(options.length)];
      // A main specialisation is epic, a weak link's gift and a
      // sub-clan's variant rare, a rank II heroic.
      final rarity = switch (c.specVariants[id]?.kind) {
        null when _isWeakLinkGift(id) => SignRarity.rare,
        null => SignRarity.epic,
        SpecVariantKind.rank => SignRarity.heroic,
        _ => SignRarity.rare,
      };
      return OfferGift(
        kind: GiftKind.spec,
        id: id,
        rarity: better ? _better(rarity) : rarity,
      );
    case GiftKind.perk:
      return null;
  }
}

/// The Wayfarer's gift: a perk rank (at [_wayfarerPerkChance], while one is
/// left) or one of [_wayfarerObjectsFor]; null when there is neither.
OfferGift? drawWayfarerGift(OfferContext c, Random random) {
  var perks = perksAvailable(c.perkRanks);
  var objects = _wayfarerObjectsFor(c);
  if (perks.isEmpty && objects.isEmpty) return null;
  // The warded ones left out (camp_rolls.dart), unless nothing else is.
  if (c.bannedGifts.isNotEmpty) {
    final p = [
      for (final k in perks)
        if (!c.isBanned(GiftKind.perk, k.name)) k,
    ];
    final o = [
      for (final id in objects)
        if (!c.isBanned(GiftKind.object, id)) id,
    ];
    if (p.isNotEmpty || o.isNotEmpty) {
      perks = p;
      objects = o;
    }
  }
  if (perks.isNotEmpty &&
      (objects.isEmpty || random.nextDouble() < _wayfarerPerkChance)) {
    return OfferGift(
      kind: GiftKind.perk,
      id: perks[random.nextInt(perks.length)].name,
    );
  }
  return OfferGift(
    kind: GiftKind.object,
    id: objects[random.nextInt(objects.length)],
  );
}

/// The skills [factionId] can offer from the branches it sponsors for the
/// character (not the reputation skills a clan's lean adds), and whether
/// one of those branches is the character's heritage. The home seat reaches
/// one tier deeper than standing allows, the fourth skill of a branch
/// still waiting for Sworn.
({List<String> skills, bool heritage}) _homeSkillsOf(
  String factionId,
  OfferContext c,
) {
  final deepest = c.tierOf(factionId).isAtLeast(StandingTier.sworn) ? 3 : 2;
  final offerable = offerableSkillsFor(
    factionId,
    c,
    tierBonus: 1,
    deepest: deepest,
  );
  if (offerable.isEmpty) return (skills: const [], heritage: false);
  final skills = <String>[];
  var heritage = false;
  for (final branch in _sponsoredBranchesFor(factionId, c)) {
    for (final id in branch.skillIds) {
      if (offerable.contains(id) && !skills.contains(id)) {
        skills.add(id);
        if (branch.heritage) heritage = true;
      }
    }
  }
  return (skills: skills, heritage: heritage);
}

/// The clans that can be the character's home seat now (v1.231): a clan,
/// open as a suitor, that sponsors a branch the character grows on and has
/// a skill on it to offer, or (v1.232) a fusion or an ascension. Mapped to
/// the weight each has in the draw: [homeHeritageWeight] for the clan of
/// their own people while the heritage branch has a skill left, 1 for the
/// class's clans, [_homeAccordWeight] for one with only a fusion or an
/// ascension left.
Map<String, double> homeClansFor(OfferContext c) {
  final out = <String, double>{};
  for (final f in c.data.factions.values) {
    if (!f.isClan || !suitorOpen(f, c)) continue;
    final home = _homeSkillsOf(f.id, c);
    if (home.skills.isNotEmpty) {
      out[f.id] = home.heritage ? homeHeritageWeight : 1.0;
    } else if (accordsFor(f.id, c).isNotEmpty) {
      out[f.id] = _homeAccordWeight;
    }
  }
  return out;
}

/// The suitor [factionId] sends: a sub-clan of theirs at random voices a
/// clan's gift (none for the others), with the gift drawn by [drawGift].
Suitor? drawSuitor(
  String factionId,
  OfferContext c,
  Random random, {
  bool better = false,
  OfferGift? gift,
}) {
  final faction = c.data.faction(factionId);
  if (faction == null) return null;
  gift ??= drawGift(factionId, c, random, better: better);
  if (gift == null) return null;
  // Its power caps the strength of the signs it gives (clan_power.dart).
  if (gift.kind == GiftKind.sign && hasPower(factionId, c.data)) {
    final cap = maxSignRarityFor(
      powerTierFor(powerOf(c.politics, factionId, c.data)),
    );
    if (gift.rarity.index > cap.index) {
      gift = OfferGift(
        kind: gift.kind,
        id: gift.id,
        rarity: cap,
        partnerId: gift.partnerId,
      );
    }
  }
  final voices = faction.isClan ? c.data.subclansOf(factionId) : const [];
  final greetings = max(1, faction.patron.greetings.length);
  // A sub-clan's skill, or its variant of a specialisation, is voiced by
  // that sub-clan.
  final giftSkill = c.skills[gift.id];
  final owner = gift.kind == GiftKind.skill && giftSkill is Map<String, dynamic>
      ? giftSkill['subclanId']?.toString() ?? ''
      : gift.kind == GiftKind.spec
          ? c.specVariants[gift.id]?.subclanId ?? ''
          : '';
  return Suitor(
    factionId: factionId,
    subclanId: owner.isNotEmpty && voices.any((v) => v.id == owner)
        ? owner
        : voices.isEmpty
            ? ''
            : voices[random.nextInt(voices.length)].id,
    gift: gift,
    firstMeeting: !c.patronsMet.contains(factionId),
    greetingIndex: random.nextInt(greetings),
  );
}

/// The home seat (v1.231): a clan that sponsors a branch the character
/// grows on, drawn at [homeClansFor]'s weights, bringing a skill from that
/// branch, so every offer has a skill to take while their tree has one
/// left. Null when no clan has one. A sworn boon due still takes the seat
/// (it comes once).
Suitor? drawHomeSuitor(
  OfferContext c,
  Random random, {
  Set<String> exclude = const {},
}) {
  final clans = homeClansFor(c)..removeWhere((id, _) => exclude.contains(id));
  if (clans.isEmpty) return null;
  final id = _weighted(clans, random);
  if (swornBoonDue(id, c)) return drawSuitor(id, c, random);
  final skills = _homeSkillsOf(id, c).skills;
  final accords = accordsFor(id, c);
  if (accords.isNotEmpty &&
      (skills.isEmpty || random.nextDouble() < _accordPickChance)) {
    return drawSuitor(
      id,
      c,
      random,
      gift: _accordGift(accords[random.nextInt(accords.length)], c, false),
    );
  }
  final skill = skills[random.nextInt(skills.length)];
  return drawSuitor(
    id,
    c,
    random,
    gift: OfferGift(
      kind: GiftKind.skill,
      id: skill,
      rarity: _rarityOfSkill(c.skills[skill] as Map<String, dynamic>?),
    ),
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
/// - **The home seat:** a clan sponsoring a branch of the character's tree
///   brings a skill from it ([drawHomeSuitor]), unless a guaranteed place
///   already does, so growth never depends on luck of the draw.
/// - **The other places:** one leans to the factions the character stands
///   well with ([_standingWeightFor]); the rest are drawn evenly (a tribe
///   at [tribeOfferWeight]).
/// - **The Wayfarer** takes a place at [_wayfarerChance], and whenever
///   fewer than three factions can come.
/// Null when nobody at all can come.
///
/// [riskyRandom] draws the risky card (risky_gifts.dart) instead of
/// [random] when given: the simulator keeps it apart so the rest of the
/// draw is the one it would be without the Parley Tent.
ClanOffer? drawOffer(
  OfferTicket ticket,
  OfferContext c,
  Random random, {
  Random? riskyRandom,
}) {
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
  var homeSeat = '';
  // A chapter's end: the Choir or the Pit, if the alignment leans.
  if (ticket.source == OfferSource.chapter && !otherworldTaken) {
    final leaning = _otherworldLeaningFor(c);
    if (leaning != null && !taken.contains(leaning)) {
      take(drawSuitor(leaning, c, random));
    }
  }

  // The home seat: a skill of the character's own tree.
  final hasHomeSkill = suitors.any(
    (s) =>
        s.gift.kind == GiftKind.skill &&
        (s.gift.partnerId.isNotEmpty ||
            _homeSkillsOf(s.factionId, c).skills.contains(s.gift.id) ||
            accordsFor(s.factionId, c).any((a) => a.skillId == s.gift.id)),
  );
  if (!hasHomeSkill && suitors.length < offerSuitorCount) {
    final home = drawHomeSuitor(c, random, exclude: taken);
    take(home);
    homeSeat = home?.factionId ?? '';
  }

  List<String> pool() => [
        for (final id in eligible)
          if (!taken.contains(id) && !(otherworldTaken && isOtherworld(id))) id,
      ];

  final wayfarerGift = drawWayfarerGift(c, random);
  final wayfarerComes = wayfarerGift != null &&
      (pool().length + suitors.length < offerSuitorCount ||
          random.nextDouble() < _wayfarerChance);
  final factionPlaces = offerSuitorCount - (wayfarerComes ? 1 : 0);

  double tribeWeight(String id) =>
      (c.data.faction(id)?.kind == PatronKind.tribe ? tribeOfferWeight : 1.0) *
      // The clan that holds the place comes more often (clan_power.dart).
      (id == c.placeHolder ? heldPlaceSuitorWeight : 1.0);

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
          o: _standingWeightFor(c.politics.standingOf(o, c.data)) *
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
    suitors.add(
      Suitor(
        factionId: wayfarerId,
        gift: wayfarerGift,
        firstMeeting: !c.patronsMet.contains(wayfarerId),
        greetingIndex: random.nextInt(4),
      ),
    );
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
  if (c.riskyGifts) {
    _makeOneRisky(suitors, c, riskyRandom ?? random, skip: {forced, homeSeat});
  }
  return ClanOffer(ticket: ticket, suitors: suitors);
}

/// Whether [suitor] may be made risky in [c] (risky_gifts.dart's
/// [riskyEligible]): never the Wayfarer.
bool _riskySuitorEligible(Suitor suitor, OfferContext c) {
  if (suitor.isWayfarer) return false;
  final faction = c.data.faction(suitor.factionId);
  return faction != null &&
      riskyEligible(
        faction,
        tier: c.tierOf(faction.id),
        alignment: c.alignment,
        nemesis: c.politics.nemesis,
      );
}

/// Risky gifts (risky_gifts.dart): when a suitor of [suitors] qualifies
/// (not one of [skip]: the ticket's own faction, the home seat), at
/// [riskyGiftChance] one of them at random brings its gift one rarity
/// better ([drawSuitor] with `better`), with the die rolled now. When the
/// better draw comes out no rarer, the card stays as it was. [random] is
/// not drawn on when no suitor qualifies.
void _makeOneRisky(
  List<Suitor> suitors,
  OfferContext c,
  Random random, {
  Set<String> skip = const {},
}) {
  final options = [
    for (var i = 0; i < suitors.length; i++)
      if (!skip.contains(suitors[i].factionId) &&
          _riskySuitorEligible(suitors[i], c))
        i,
  ];
  if (options.isEmpty || random.nextDouble() >= riskyGiftChance) return;
  final at = options[random.nextInt(options.length)];
  final normal = suitors[at];
  final better = drawSuitor(normal.factionId, c, random, better: true);
  final roll = random.nextInt(20) + 1;
  if (better == null || better.gift.rarity.index <= normal.gift.rarity.index) {
    return;
  }
  suitors[at] = Suitor(
    factionId: better.factionId,
    subclanId: better.subclanId,
    gift: better.gift,
    firstMeeting: normal.firstMeeting,
    greetingIndex: normal.greetingIndex,
  ).asRisky(roll);
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

// --- Taking a suitor --------------------------------------------------------

/// The standing a suitor taken for [ticket] brings: [_offerStandingGain],
/// or [_majorOfferStandingGain] for a quest, an intrigue or a chapter's end.
int _standingGainFor(OfferTicket ticket) =>
    ticket.major ? _majorOfferStandingGain : _offerStandingGain;

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
  final lead = standingPreview(
    politics,
    suitor.factionId,
    _standingGainFor(ticket),
    data: data,
  );
  final partner = suitor.gift.partnerId;
  if (partner.isEmpty || data.faction(partner) == null) return lead;
  // A fusion raises its second clan too, by half.
  final second = standingPreview(
    politics,
    partner,
    _standingGainFor(ticket) / 2,
    data: data,
  );
  return {
    for (final id in {...lead.keys, ...second.keys})
      id: (lead[id] ?? 0) + (second[id] ?? 0),
  };
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
      alignment: 0,
    );
  }
  final cause = offerCause(ticket, suitor.gift);
  if (data.faction(suitor.factionId)?.isLost ?? false) {
    final standing = bannerRaisedIn(flags)
        ? applyStandingChange(
            politics,
            'dominion',
            ownHandBannerCost,
            cause,
            data: data,
            chapter: chapter,
            day: day,
          )
        : StandingResult(state: politics);
    return (politics: standing.state, standing: standing, alignment: 0);
  }
  final standing = applyStandingChange(
    politics,
    suitor.factionId,
    _standingGainFor(ticket),
    cause,
    data: data,
    chapter: chapter,
    day: day,
  );
  var next = standing.state;
  final partner = suitor.gift.partnerId;
  if (partner.isNotEmpty && data.faction(partner) != null) {
    next = applyStandingChange(
      next,
      partner,
      _standingGainFor(ticket) / 2,
      cause,
      data: data,
      chapter: chapter,
      day: day,
    ).state;
  }
  if (suitor.subclanId.isNotEmpty) {
    next = setSubclanMark(
      next,
      suitor.subclanId,
      SubclanMark.friend,
      cause,
      data: data,
      chapter: chapter,
      day: day,
    ).state;
  }
  // Its power grows with the gifts taken (clan_power.dart).
  next = addPower(
    next,
    suitor.factionId,
    giftPowerFor(suitor.gift.rarity.name),
    data,
    helped: true,
  );
  return (politics: next, standing: standing, alignment: leanOf(suitor, data));
}

// --- Titles -----------------------------------------------------------------

/// What [politics] says of [held] titles: every tier title whose tier the
/// character has reached with its faction (kept once earned), and the
/// mark titles (`mark:<mark>:<sub-clan>`, "the Marked") held only while
/// the mark stands, and the `while:<tier>` titles (v1.235) held only while
/// the standing is at that tier or beyond it; with [flags], the Open Hand's remembrance titles
/// (v1.195, see remembranceTitlesFor), kept once earned; and the
/// coronation's (`throne:<faction>`, v1.196) once that faction is on the
/// Throne, kept. Returns the titles held after, and those [gained] and
/// [lost].
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
    } else if (source.startsWith('while:')) {
      // Held only while the standing lasts (v1.235): a good title while the
      // tier is reached or better, a bad one while it is reached or worse;
      // lost again, gained again, with the standing.
      final tier = standingTierNamed(source.substring('while:'.length));
      if (tier == null ||
          title.factionId.isEmpty ||
          data.faction(title.factionId) == null) {
        continue;
      }
      final now = politics.tierOf(title.factionId, data);
      final has = tier.index > StandingTier.unknown.index
          ? now.isAtLeast(tier)
          : now.index <= tier.index;
      if (has && !next.contains(title.id)) {
        next.add(title.id);
        gained.add(title.id);
      } else if (!has && next.remove(title.id)) {
        lost.add(title.id);
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
    } else if (source.startsWith('throne:')) {
      // The coronation's (v1.196, see throne.dart), kept once earned.
      final winner = source.substring('throne:'.length).trim();
      if (winner.isNotEmpty &&
          politics.throneWinner == winner &&
          !next.contains(title.id)) {
        next.add(title.id);
        gained.add(title.id);
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
///
/// A risky card (risky_gifts.dart) is taken only when its gift would win at
/// its normal rarity (one lower); otherwise it scores as usual minus 5, so
/// the simulator never chases risk. Never while the character is not
/// [healthy] (above half health). [favourBest] skips it too.
///
/// With [keepTo] (the patron and its allies, v1.500), a card of any other
/// clan is taken only when it fills an empty die face; the wayfarer's and
/// your own hand's cards, which move no clan, stay in. When nothing is
/// left, the whole offer is picked from.
Suitor? preferredSuitor(
  ClanOffer offer, {
  required bool Function(String skillId) fillsEmptyFace,
  required List<HeldSign> heldSigns,
  required Map<String, SignDef> signs,
  bool favourBest = false,
  PoliticsState politics = PoliticsState.empty,
  ClanData data = ClanData.empty,
  bool healthy = true,
  Set<String>? keepTo,
}) {
  if (offer.suitors.isEmpty) return null;
  var suitors = offer.suitors;
  if (keepTo != null && keepTo.isNotEmpty) {
    final kept = [
      for (final s in suitors)
        if (s.isWayfarer ||
            keepTo.contains(s.factionId) ||
            (data.faction(s.factionId)?.isLost ?? false) ||
            (s.gift.kind == GiftKind.skill && fillsEmptyFace(s.gift.id)))
          s,
    ];
    if (kept.isNotEmpty) suitors = kept;
  }
  if (favourBest) {
    final factions = [
      for (final s in suitors)
        if (!s.isWayfarer && !s.risky) s,
    ];
    if (factions.isNotEmpty) {
      return factions.reduce(
        (a, b) => politics.standingOf(b.factionId, data) >
                politics.standingOf(a.factionId, data)
            ? b
            : a,
      );
    }
  }
  int giftScore(OfferGift gift) {
    if (gift.kind == GiftKind.skill && fillsEmptyFace(gift.id)) return 100;
    // A specialisation changes how the character fights: taken first.
    if (gift.kind == GiftKind.spec) return 90;
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

  final safeBest = suitors
      .where((s) => !s.risky)
      .map((s) => giftScore(s.gift))
      .fold<int?>(null, (best, v) => best == null || v > best ? v : best);
  int score(Suitor s) {
    final usual = giftScore(s.gift);
    if (!s.risky) return usual;
    final g = s.gift;
    final normal = giftScore(
      OfferGift(
        kind: g.kind,
        id: g.id,
        rarity: SignRarity.values[max(0, g.rarity.index - 1)],
        partnerId: g.partnerId,
      ),
    );
    // At half health or less, never (unless it is the only card).
    if (!healthy) return -1000;
    if (safeBest == null || normal > safeBest) return usual;
    return usual - 5;
  }

  return suitors.reduce((a, b) => score(b) > score(a) ? b : a);
}
