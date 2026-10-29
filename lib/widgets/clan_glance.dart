// A clan at a glance (v1.576): the standing disc (standing_sign.dart) at the
// corner of a clan's banner says how the clan stands with the player, one
// disc for each of the eleven steps. It reads the tier the clan card already
// shows (PoliticsState.tierOf), so no new numbers. How strong the clan is is
// not on the banner: that is the rank plate (clan_rank.dart).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/factions.dart';
import '../providers/clans_provider.dart';
import 'standing_sign.dart';

/// What a clan's banner says of it at a glance: how it stands with the
/// player.
class ClanGlance {
  const ClanGlance(this.standing);

  final StandingTier standing;

  @override
  bool operator ==(Object other) =>
      other is ClanGlance && other.standing == standing;

  @override
  int get hashCode => standing.hashCode;
}

/// [clanId]'s glance now, or null for a faction not on file.
final clanGlanceProvider = Provider.family<ClanGlance?, String>((ref, clanId) {
  final data = ref.watch(clanDataProvider);
  if (data.faction(clanId) == null) return null;
  return ClanGlance(ref.watch(politicsProvider).tierOf(clanId, data));
});

/// [child], a clan's banner, with its standing disc of [discSize] pixels at
/// the top-right corner (drawn over the corner, so the layout does not
/// move). The banner alone for a faction not on file. The clan's power is
/// not on the banner: it is the rank plate (clan_rank.dart).
class ClanMarks extends ConsumerWidget {
  const ClanMarks({
    super.key,
    required this.factionId,
    required this.child,
    this.discSize = 24,
    this.atLeft = false,
  });

  final String factionId;
  final Widget child;
  final double discSize;

  /// Whether the disc stands at the top-left corner instead (a crest that
  /// already wears a number at its right).
  final bool atLeft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glance = ref.watch(clanGlanceProvider(factionId));
    if (glance == null) return child;
    return Stack(
      key: Key('clan_marks_$factionId'),
      clipBehavior: Clip.none,
      children: [
        child,
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
