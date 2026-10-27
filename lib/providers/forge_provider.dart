import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/forge_roll.dart';
import 'clans_provider.dart';
import 'player_session_provider.dart';
import 'territory_provider.dart';

/// The modifiers on a forge roll now (forge_roll.dart's forgeModifiersFor):
/// a dwarf hero's +2, and the standing with the clan holding the place the
/// forge is used at. A forge has no place of its own on file (the
/// Hammersmith's opens from the camp's house), so it is the place the
/// story stands at, as for the forge's prices (shop_detail_screen.dart).
final forgeModifiersProvider = Provider<List<ForgeModifier>>((ref) {
  final holder = ref.watch(holderHereProvider);
  return forgeModifiersFor(
    raceId: ref.watch(playerSessionProvider.select((s) => s.raceId)),
    holderId: holder,
    holderTier: holder.isEmpty
        ? null
        : ref
            .watch(politicsProvider)
            .tierOf(holder, ref.watch(clanDataProvider)),
  );
});
