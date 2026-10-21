// The temple (wave 15, docs/proposals/temple-service.md): what a town's
// temple pin opens. Two services:
//
// - Mending: the whole party back to full health, mana unchanged, no time
//   passing, for [templeMendPrice] gold, once a day, from chapter 2
//   ([roadRulesFromChapter]).
// - A blessing: for the next [templeBlessingFights] fights, the ruling
//   clan's `host.effects` (factions.json, the kit its contingent brings to
//   the Host) and a starting block of [templeWardBlock] for the whole
//   party; a neutral temple gives +[templeNeutralHealthPercent]% party max
//   health instead of the clan's kit. One at a time: a new one replaces
//   the old. The first blessing of a chapter from a clan gives
//   +[templeStandingGain] standing with it (not with a clan of the
//   opposite alignment).
//
// The temple belongs to whoever rules its district, else its town
// (town_rulers.dart). Prices follow the standing with that clan as a
// clan's shop does (factionPriceFor: x1.40 Hostile ... x0.75 Sworn); a
// Hunted character is refused. Charisma doesn't haggle here.
//
// Pure rules; templeOfferProvider (temple_provider.dart) reads them for the
// sheet, PlayerSessionNotifier.templeMend / templeBless apply them.
import 'dart:math';

import 'factions.dart';
import 'geography.dart' show Geography;
import 'journey_rules.dart';
import 'risky_gifts.dart' show alignmentOpposite;
import 'shop_pricing.dart';
import 'signs.dart';
import 'town_rulers.dart' show TownRuler;

/// Fights a blessing lasts (like sellswordContractFights).
const int templeBlessingFights = 3;

/// The starting block every temple's blessing gives the party.
const int templeWardBlock = 1;

/// A neutral temple's party max health bonus, in percent.
const int templeNeutralHealthPercent = 3;

/// The standing a clan's first blessing of a chapter brings.
const int templeStandingGain = 1;

/// What Mending costs in [chapter], before the standing.
int templeMendPrice(int chapter) => 20 * max(chapter, 1);

/// What a blessing costs in [chapter], before the standing.
int templeBlessingPrice(int chapter) => 30 + 30 * max(chapter, 1);

/// Whether Mending is offered in [chapter] (in chapter 1 the night costs
/// nothing, so the row is hidden).
bool templeMendOffered(int chapter) => roadRulesApply(chapter);

/// What a blessing of [clanId]'s temple ('' neutral) adds to a fight,
/// through the Signs pipeline (signEffectsFor's `extra`): the clan's
/// `host.effects`, read live, and the ward; a neutral temple's health
/// bonus and the ward.
List<SignEffect> templeBlessingEffects(String clanId, ClanData data) => [
      if (clanId.isEmpty)
        const SignEffect(
            kind: SignEffectKind.partyMaxHealthPercent,
            value: templeNeutralHealthPercent)
      else
        ...?data.faction(clanId)?.host?.effects,
      const SignEffect(
          kind: SignEffectKind.partyStartBlock, value: templeWardBlock),
    ];

/// What an active blessing adds to the next fight: none when
/// [blessingFights] is 0.
List<SignEffect> activeBlessingEffects(
        {required int blessingFights,
        required String blessingClan,
        required ClanData data}) =>
    blessingFights > 0
        ? templeBlessingEffects(blessingClan, data)
        : const <SignEffect>[];

/// Whether a blessing from [clanId] in [chapter] brings
/// [templeStandingGain] standing: a clan (not neutral, not lost) not
/// already counted this chapter ([standingChapters]: clan -> the chapter
/// it last gave it), and not of the opposite alignment to [alignment].
bool templeBlessingGivesStanding(
  String clanId, {
  required ClanData data,
  required int chapter,
  required int alignment,
  required Map<String, int> standingChapters,
}) {
  final faction = data.faction(clanId);
  if (faction == null || faction.isLost) return false;
  if (standingChapters[clanId] == chapter) return false;
  return !alignmentOpposite(faction.lean, alignment);
}

/// Why a temple service can't be used now.
enum TempleBlock {
  /// The ruling clan hunts the character: the door is shut.
  hunted,

  /// A fight or an expedition is under way.
  busy,

  /// The purse falls short of the price.
  poor,

  /// Mending was used today already.
  mendedToday,
}

/// What a temple offers now (the sheet's rows): the ruling clan, the
/// prices at the standing with them, and what blocks each service.
class TempleOffer {
  const TempleOffer({
    required this.clanId,
    required this.tier,
    required this.chapter,
    required this.mendOffered,
    required this.mendPrice,
    required this.mendBlock,
    required this.blessingPrice,
    required this.blessingBlock,
    required this.blessingEffects,
    required this.blessingReplaces,
    required this.blessingStanding,
  });

  /// The clan that keeps the temple; '' for a neutral one.
  final String clanId;

  /// The standing tier with [clanId]; null for a neutral temple.
  final StandingTier? tier;
  final int chapter;

  /// Whether the Mending row is shown at all (from chapter 2).
  final bool mendOffered;

  /// The prices at [tier] (0 when [refused]).
  final int mendPrice;
  final int blessingPrice;

  /// What stops each service now; null when it can be bought.
  final TempleBlock? mendBlock;
  final TempleBlock? blessingBlock;

  /// What the blessing would give (see [templeBlessingEffects]).
  final List<SignEffect> blessingEffects;

  /// A blessing is active and a new one would replace it.
  final bool blessingReplaces;

  /// The blessing would bring [templeStandingGain] standing.
  final bool blessingStanding;

  bool get isNeutral => clanId.isEmpty;

  /// The ruling clan hunts the character: no service at all.
  bool get refused => mendBlock == TempleBlock.hunted;

  bool get canMend => mendOffered && mendBlock == null;
  bool get canBless => blessingBlock == null;
}

/// The offer of the temple [clanId] ('' neutral) keeps, to a character
/// standing in [politics], in [chapter] on [day], with [gold] and
/// [alignment], who last mended on [templeMendDay], carries a blessing of
/// [blessingFights] fights and has had the clans' standing of
/// [standingChapters]; [busy] in a fight or an expedition.
TempleOffer templeOfferFor({
  required String clanId,
  required ClanData data,
  required PoliticsState politics,
  required int chapter,
  required int day,
  required int gold,
  required int alignment,
  int templeMendDay = 0,
  int blessingFights = 0,
  Map<String, int> standingChapters = const {},
  bool busy = false,
}) {
  final faction = data.faction(clanId);
  final ruler = faction == null ? '' : clanId;
  final tier = faction == null ? null : politics.tierOf(clanId, data);
  final hunted = shopRefusesTrade(tier);
  final mendPrice =
      hunted ? 0 : factionPriceFor(templeMendPrice(chapter), tier) ?? 0;
  final blessingPrice =
      hunted ? 0 : factionPriceFor(templeBlessingPrice(chapter), tier) ?? 0;
  TempleBlock? blockFor(int price, {bool mendedToday = false}) => hunted
      ? TempleBlock.hunted
      : busy
          ? TempleBlock.busy
          : mendedToday
              ? TempleBlock.mendedToday
              : gold < price
                  ? TempleBlock.poor
                  : null;
  return TempleOffer(
    clanId: ruler,
    tier: tier,
    chapter: chapter,
    mendOffered: templeMendOffered(chapter),
    mendPrice: mendPrice,
    mendBlock: blockFor(mendPrice,
        mendedToday: templeMendDay > 0 && templeMendDay == day),
    blessingPrice: blessingPrice,
    blessingBlock: blockFor(blessingPrice),
    blessingEffects: templeBlessingEffects(ruler, data),
    blessingReplaces: blessingFights > 0,
    blessingStanding: !hunted &&
        templeBlessingGivesStanding(ruler,
            data: data,
            chapter: chapter,
            alignment: alignment,
            standingChapters: standingChapters),
  );
}

/// The clan that keeps the temple of [placeId] (a district, else a town)
/// in [rulers] (town_rulers.dart): the place's ruler, else that of
/// [parent] (the town above it); '' for a neutral temple.
String templeClanAt(String placeId, Map<String, TownRuler> rulers,
        {String parent = ''}) =>
    (rulers[placeId] ?? rulers[parent])?.clanId ?? '';

/// The clan that keeps the temple of the town [placeId] lies in ('' a
/// neutral one), or null when it lies in no town of [rulers] (no temple
/// there): the place, else the nearest place above it that is a town or a
/// district of one. For the simulator's hubs.
String? templeClanOfPlace(
    String? placeId, Map<String, TownRuler> rulers, Geography geography) {
  var id = placeId;
  for (var depth = 0; id != null && id.isNotEmpty && depth < 16; depth++) {
    final ruler = rulers[id];
    if (ruler != null) return ruler.clanId;
    id = geography.places[id]?.parent;
  }
  return null;
}

/// The simulator's rule for a blessing (docs/proposals/temple-service.md
/// section 6): at a chapter's hub, one is bought when the purse holds at
/// least [simBlessingGoldFactor] times its price.
const int simBlessingGoldFactor = 3;
