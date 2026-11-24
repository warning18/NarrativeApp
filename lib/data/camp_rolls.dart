/// Camp buildings that bend the rolls (docs/proposals/camp-roll-buildings.md):
/// three houses of houses.json, each with a `rollPower`, act on the two
/// "banner choice" draws -- the stat pick of a level and the clans' offer:
/// - **Reroll** (the Bone-Caster's Hut): redraw the whole set, up to
///   [rerollMaxCharges] charges, full when built, +1 per level gained;
/// - **Banish** (the Warding Cairn): ward a card's training path or gift
///   off for 5, 10 or 15 fresh draws ([banishLengths], 1 to 3 charges), up
///   to [banishMaxCharges], full when built, +1 per level gained; or ward
///   the road against a hunting clan (road_wards.dart);
/// - **Raise** (the Star Well): one card one rarity up, once per card, 1
///   charge when built then +1 every [raiseChargeEvery] fresh draws, up to
///   [raiseMaxCharges].
///
/// Everything here is pure; the session keeps the charges and the bans
/// (PlayerSession `rerollCharges`, `banishCharges`, `raiseCharges`,
/// `raiseProgress`, `rollBans`, `rollNonce`) and calls these where it
/// draws. The draws themselves read the bans: training.dart's drawStatPick
/// (`bannedPaths`) and offers.dart's OfferContext (`bannedGifts`).
library;

import 'dart:math';

import 'clan_power.dart';
import 'offers.dart';
import 'signs.dart';

/// The three powers a house may give (houses.json `rollPower`).
enum RollPower { reroll, banish, raise }

RollPower? rollPowerNamed(String? name) =>
    RollPower.values.where((p) => p.name == name).firstOrNull;

/// [house]'s power, or null for a house without one.
RollPower? rollPowerOf(Map<String, dynamic>? house) =>
    rollPowerNamed(house?['rollPower']?.toString());

/// The roll houses of houses.json and their power (their `rollPower`;
/// camp_roll_buildings_test keeps the two in step). The session reads it
/// where it has no houses table at hand: the level-up's refill, the fresh
/// draws' count.
const Map<String, RollPower> rollPowerHouses = {
  'bone_casters_hut': RollPower.reroll,
  'warding_cairn': RollPower.banish,
  'star_well': RollPower.raise,
};

/// The powers of the roll houses among [builtHouseIds] ([rollPowerHouses]).
Set<RollPower> rollPowersOf(Iterable<String> builtHouseIds) => {
      for (final id in builtHouseIds)
        if (rollPowerHouses[id] case final power?) power,
    };

/// The powers of the houses in [builtHouseIds] (houses.json [houses]).
Set<RollPower> rollPowersBuilt(
    Iterable<String> builtHouseIds, Map<String, dynamic> houses) {
  final out = <RollPower>{};
  for (final id in builtHouseIds) {
    final house = houses[id];
    if (house is Map<String, dynamic>) {
      final power = rollPowerOf(house);
      if (power != null) out.add(power);
    }
  }
  return out;
}

/// Charges: the most each power holds.
const int rerollMaxCharges = 4;
const int banishMaxCharges = 3;
const int raiseMaxCharges = 5;

/// Fresh draws (stat picks and offers together) for one more Raise charge.
const int raiseChargeEvery = 15;

/// How long a ban lasts, in fresh draws of its kind; the i-th costs i+1
/// charges.
const List<int> banishLengths = [5, 10, 15];

/// The charges a ban of [draws] costs (1, 2 or 3), 0 for no such length.
int banishCostOf(int draws) => banishLengths.indexOf(draws) + 1;

/// The charges [power] holds the day its house goes up: Reroll and Banish
/// full, Raise one.
int chargesWhenBuilt(RollPower power) => switch (power) {
      RollPower.reroll => rerollMaxCharges,
      RollPower.banish => banishMaxCharges,
      RollPower.raise => 1,
    };

/// Which draw a ban counts down on: the stat picks (a training path), the
/// offers (a gift), or the roads at rest (a hunting clan's ward,
/// road_wards.dart).
enum RollBanOn { pick, offer, road }

/// One ban: [id] (a path id, a gift's `kind:id`, see [giftBanId], or a
/// warded clan's id) kept off [on]'s draws for [left] more fresh draws (or
/// roads at rest).
class RollBan {
  const RollBan({required this.on, required this.id, required this.left});

  final RollBanOn on;
  final String id;
  final int left;

  Map<String, dynamic> toJson() => {'on': on.name, 'id': id, 'left': left};

  static RollBan? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final on = RollBanOn.values
        .where((o) => o.name == raw['on']?.toString())
        .firstOrNull;
    final id = raw['id']?.toString() ?? '';
    final left = (raw['left'] as num?)?.toInt() ?? 0;
    if (on == null || id.isEmpty || left <= 0) return null;
    return RollBan(on: on, id: id, left: left);
  }

  @override
  bool operator ==(Object other) =>
      other is RollBan &&
      other.on == on &&
      other.id == id &&
      other.left == left;

  @override
  int get hashCode => Object.hash(on, id, left);
}

/// The bans saved as [raw] (a list), the unreadable ones dropped.
List<RollBan> rollBansFromJson(Object? raw) => [
      for (final b in (raw is List ? raw : const []))
        if (RollBan.tryParse(b) case final ban?) ban,
    ];

/// A gift's ban id: `kind:id` (`skill:...`, `sign:...`, `perk:...`).
String giftBanId(OfferGift gift) => '${gift.kind.name}:${gift.id}';

/// The ids [bans] keep off [on]'s draws now.
Set<String> bannedIdsOf(List<RollBan> bans, RollBanOn on) => {
      for (final b in bans)
        if (b.on == on && b.left > 0) b.id,
    };

/// [bans] with [ban] added (a ban on the same thing keeps the longer).
List<RollBan> withRollBan(List<RollBan> bans, RollBan ban) {
  final old = bans.where((b) => b.on == ban.on && b.id == ban.id).firstOrNull;
  return [
    for (final b in bans)
      if (b != old) b,
    if (old == null || old.left < ban.left) ban else old,
  ];
}

/// What a fresh draw of [on] does to the rolls: its bans count down by
/// one (the spent ones go), and, with the Star Well up ([raiseBuilt]), the
/// Raise count moves on, a charge coming every [raiseChargeEvery] draws
/// (never above [raiseMaxCharges]).
({List<RollBan> bans, int raise, int raiseProgress}) afterFreshDraw({
  required RollBanOn on,
  required List<RollBan> bans,
  required bool raiseBuilt,
  required int raise,
  required int raiseProgress,
}) {
  final next = [
    for (final b in bans)
      if (b.on != on)
        b
      else if (b.left > 1)
        RollBan(on: b.on, id: b.id, left: b.left - 1),
  ];
  if (!raiseBuilt) return (bans: next, raise: raise, raiseProgress: 0);
  var progress = raiseProgress + 1;
  var charges = raise;
  if (progress >= raiseChargeEvery) {
    progress = 0;
    charges = min(raiseMaxCharges, charges + 1);
  }
  return (bans: next, raise: charges, raiseProgress: progress);
}

/// What the camp's roll houses give now, for the choice sheet: each
/// power's charges, null when its house isn't up, and the bans running.
class CampRolls {
  const CampRolls({
    this.reroll,
    this.banish,
    this.raise,
    this.raiseProgress = 0,
    this.bans = const [],
  });

  final int? reroll;
  final int? banish;
  final int? raise;

  /// Fresh draws toward the next Raise charge (0 to [raiseChargeEvery]-1).
  final int raiseProgress;
  final List<RollBan> bans;

  /// Whether any of the three houses is up.
  bool get any => reroll != null || banish != null || raise != null;
}

/// A seed for [text] that is the same on every run and platform.
int stableSeedOf(String text) =>
    text.codeUnits.fold<int>(17, (a, b) => (a * 31 + b) & 0x3fffffff);

// --- The offer's cards --------------------------------------------------------

/// Whether [suitor]'s card of [offer] may be warded off: never the Sworn
/// boon (it comes once) nor the ticket's own faction's card (a quest's clan
/// always comes).
bool suitorBanishable(Suitor suitor, ClanOffer offer) =>
    suitor.gift.kind != GiftKind.sworn &&
    (offer.ticket.factionId.isEmpty ||
        suitor.factionId != offer.ticket.factionId);

/// The card that takes [factionId]'s place in [offer] once its gift is
/// warded ([c] holds the bans, that one among them): the same clan with
/// another gift, else (nothing else to give) another faction from the
/// pool, drawn as the offer's other places are. The new card keeps the old
/// one's greeting. Null when nobody can take the place.
Suitor? replacementSuitor(
    ClanOffer offer, String factionId, OfferContext c, Random random) {
  final old = offer.suitorOf(factionId);
  if (old == null) return null;
  Suitor keepGreeting(Suitor s) => Suitor(
        factionId: s.factionId,
        subclanId: s.subclanId,
        gift: s.gift,
        firstMeeting:
            s.factionId == old.factionId ? old.firstMeeting : s.firstMeeting,
        greetingIndex:
            s.factionId == old.factionId ? old.greetingIndex : s.greetingIndex,
      );
  if (old.isWayfarer) {
    final gift = drawWayfarerGift(c, random);
    if (gift != null && !c.isBanned(gift.kind, gift.id)) {
      return keepGreeting(Suitor(factionId: wayfarerId, gift: gift));
    }
  } else if (giftsLeftAfterBans(factionId, c)) {
    final s = drawSuitor(factionId, c, random);
    if (s != null && !c.isBanned(s.gift.kind, s.gift.id)) {
      return keepGreeting(s);
    }
  }
  // Another faction, from the pool the offer's other places come from.
  final shown = {for (final s in offer.suitors) s.factionId};
  bool otherworld(String id) =>
      c.data.faction(id)?.kind == PatronKind.otherworld;
  final otherworldShown = offer.suitors
      .any((s) => s.factionId != factionId && otherworld(s.factionId));
  final pool = {
    for (final id in eligibleSuitors(c))
      if (!shown.contains(id) &&
          !(otherworldShown && otherworld(id)) &&
          giftsLeftAfterBans(id, c))
        id: (c.data.faction(id)?.kind == PatronKind.tribe
                ? tribeOfferWeight
                : 1.0) *
            (id == c.placeHolder ? heldPlaceSuitorWeight : 1.0),
  };
  while (pool.isNotEmpty) {
    final total = pool.values.fold<double>(0, (a, b) => a + b);
    var roll = random.nextDouble() * total;
    var id = pool.keys.last;
    for (final e in pool.entries) {
      roll -= e.value;
      if (roll < 0) {
        id = e.key;
        break;
      }
    }
    final s = drawSuitor(id, c, random);
    if (s != null) return s;
    pool.remove(id);
  }
  return null;
}

/// [offer] with the card of [factionId] replaced by [next].
ClanOffer offerWith(ClanOffer offer, String factionId, Suitor next) =>
    ClanOffer(ticket: offer.ticket, suitors: [
      for (final s in offer.suitors) s.factionId == factionId ? next : s,
    ]);

/// Whether [suitor]'s card is of a kind Raise may act on: not raised yet,
/// not risky (its better rarity is the risk's prize), not the Sworn boon,
/// not the Wayfarer's (a perk has no rarity), not Heroic.
bool suitorRaisable(Suitor suitor) =>
    !suitor.raised &&
    !suitor.risky &&
    !suitor.isWayfarer &&
    suitor.gift.kind != GiftKind.sworn &&
    suitor.gift.kind != GiftKind.perk &&
    suitor.gift.rarity != SignRarity.heroic;

/// [suitor]'s card raised at the Star Well, or null when it shows no real
/// step up: a sign one rarity up (capped by its clan's power,
/// [maxSignRarityFor]); any other gift the clan's better draw (as a quest's
/// suitor: one rarity up, one skill deeper), which may be another skill or
/// object. [random] draws the better gift: pass the same seed to preview
/// it and to take it.
Suitor? raisedSuitor(Suitor suitor, OfferContext c, Random random) {
  if (!suitorRaisable(suitor)) return null;
  final gift = suitor.gift;
  if (gift.kind == GiftKind.sign) {
    var rarity = SignRarity.values[gift.rarity.index + 1];
    if (hasPower(suitor.factionId, c.data)) {
      final cap = maxSignRarityFor(
          powerTierFor(powerOf(c.politics, suitor.factionId, c.data)));
      if (rarity.index > cap.index) rarity = cap;
    }
    if (rarity.index <= gift.rarity.index) return null;
    return suitor.asRaised(OfferGift(
        kind: gift.kind,
        id: gift.id,
        rarity: rarity,
        partnerId: gift.partnerId));
  }
  final better = drawSuitor(suitor.factionId, c, random, better: true);
  if (better == null ||
      better.gift.kind == GiftKind.sworn ||
      better.gift.rarity.index <= gift.rarity.index) {
    return null;
  }
  return suitor.asRaised(better.gift, subclanId: better.subclanId);
}
