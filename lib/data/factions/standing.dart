part of '../factions.dart';

// Standing tiers (from Unknown to Sworn, with their price factors and
// colours) and the numbers of the ripple and the Sworn banner.

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
