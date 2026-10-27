// A clan at a glance (v1.576): two marks on the same banner. The standing
// disc (standing_sign.dart) at its corner says how the clan stands with the
// player, one disc for each of the eleven steps; the power cloth says how
// strong the clan is: the banner is a dark silhouette that fills with its own
// colours from the foot, a quarter for each of Minor, Rising, Dominant and
// Ascendant, with a gold hairline at the level. Both read the tiers the clan
// card already shows (PoliticsState.tierOf, powerTierFor), so no new numbers;
// the exact words stay on the clan card.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clan_power.dart';
import '../data/factions.dart';
import '../providers/clans_provider.dart';
import 'standing_sign.dart';

/// What a clan's banner says of it at a glance.
class ClanGlance {
  const ClanGlance(this.standing, this.power);

  /// How it stands with the player.
  final StandingTier standing;

  /// How strong it is, or null for a faction with no power of its own.
  final PowerTier? power;

  @override
  bool operator ==(Object other) =>
      other is ClanGlance && other.standing == standing && other.power == power;

  @override
  int get hashCode => Object.hash(standing, power);
}

/// [clanId]'s glance now, or null for a faction not on file.
final clanGlanceProvider = Provider.family<ClanGlance?, String>((ref, clanId) {
  final data = ref.watch(clanDataProvider);
  if (data.faction(clanId) == null) return null;
  final politics = ref.watch(politicsProvider);
  return ClanGlance(
    politics.tierOf(clanId, data),
    hasPower(clanId, data)
        ? powerTierFor(powerOf(politics, clanId, data))
        : null,
  );
});

/// How much of the cloth a power tier fills, from the foot: a quarter a tier.
double powerClothShare(PowerTier tier) => (tier.index + 1) / 4;

const Color _hairline = Color(0xFFF2C14E);

/// The cloth above the level: the banner's own colours nearly all hidden.
const Color _empty = Color(0xE0151319);

/// [child] (a banner) drawn as the power cloth of [tier]: dark above the
/// level, in its own colours from the foot up to it, a gold hairline at the
/// level. The banner is drawn once (a shader darkens the part above the
/// level), so its key and its animation stay single.
class PowerCloth extends StatelessWidget {
  const PowerCloth({super.key, required this.tier, required this.child});

  final PowerTier tier;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final share = powerClothShare(tier);
    final level = 1 - share;
    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight.isFinite ? box.maxHeight : 0.0;
      return Stack(
        key: Key('power_cloth_${tier.name}'),
        clipBehavior: Clip.none,
        children: [
          share >= 1
              ? child
              : ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (rect) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [
                      _empty,
                      _empty,
                      Color(0x00000000),
                      Color(0x00000000)
                    ],
                    stops: [0, level, level + 0.0001, 1],
                  ).createShader(rect),
                  child: child,
                ),
          if (share < 1 && h > 0)
            Positioned(
              left: 0,
              right: 0,
              top: h * level,
              child: Container(height: h < 60 ? 1 : 1.6, color: _hairline),
            ),
        ],
      );
    });
  }
}

/// [child] as [factionId]'s power cloth only (no disc): for a crest that has
/// room for the cloth but draws its own corner. [child] alone for a faction
/// with no power.
class ClanCloth extends ConsumerWidget {
  const ClanCloth({super.key, required this.factionId, required this.child});

  final String factionId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final power = ref.watch(clanGlanceProvider(factionId))?.power;
    return power == null ? child : PowerCloth(tier: power, child: child);
  }
}

/// [child], a clan's banner, with its two marks: the power cloth and, at the
/// top-right corner, the standing disc of [discSize] pixels (drawn over the
/// corner, so the layout does not move). The banner alone for a faction not
/// on file.
class ClanMarks extends ConsumerWidget {
  const ClanMarks({
    super.key,
    required this.factionId,
    required this.child,
    this.discSize = 24,
    this.cloth = true,
    this.atLeft = false,
  });

  final String factionId;
  final Widget child;
  final double discSize;

  /// Whether the power shows as the cloth: false where the banner is only
  /// part of a crest (the disc alone).
  final bool cloth;

  /// Whether the disc stands at the top-left corner instead (a crest that
  /// already wears a number at its right).
  final bool atLeft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glance = ref.watch(clanGlanceProvider(factionId));
    if (glance == null) return child;
    final power = glance.power;
    return Stack(
      key: Key('clan_marks_$factionId'),
      clipBehavior: Clip.none,
      children: [
        power == null || !cloth ? child : PowerCloth(tier: power, child: child),
        Positioned(
          left: atLeft ? -discSize * 0.2 : null,
          right: atLeft ? null : -discSize * 0.2,
          top: -discSize * 0.2,
          child: StandingSign(glance.standing, size: discSize),
        ),
      ],
    );
  }
}
