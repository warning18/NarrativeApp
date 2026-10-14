import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/camp_works.dart';
import '../gamedata/db_schema.dart';
import 'chapter_loop_provider.dart' show reachedChapterProvider;
import 'game_db_providers.dart';
import 'player_session_provider.dart';

/// The camp's works as the building screen lists them (see camp_works.dart
/// and docs/proposals/building-screen.md): by category, each house with
/// its state and what it still needs.
final campWorksProvider = Provider<Map<WorkCategory, List<CampWork>>>((ref) {
  final session = ref.watch(playerSessionProvider);
  return campWorksOf(
    houses: ref.watch(gameDbProvider(housesSchema)).value ?? const {},
    zones: ref.watch(gameDbProvider(zonesSchema)).value ?? const {},
    shops: ref.watch(gameDbProvider(shopsSchema)).value ?? const {},
    chapter: ref.watch(reachedChapterProvider),
    flags: session.flags,
    gold: session.gold,
    inventory: session.inventoryItemIds,
    builtHouseIds: session.builtHouseIds,
    recruitedAllyIds: [
      for (final ally in session.recruitedAllies) ally.companionId,
    ],
  );
});
