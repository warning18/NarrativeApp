import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/geography.dart';
import '../gamedata/db_schema.dart';
import 'game_db_providers.dart';

/// The world's places and biomes (v1.197, see geography.dart), from
/// geography.json and biomes.json, loaded the way every gamedata table is:
/// the asset, or the Data tab's edited copy. Read raw, not French-overlaid:
/// a place picks its language itself (nameFor). Empty until both have
/// loaded, and empty for a file that is missing.
final geographyProvider = Provider<Geography>((ref) {
  final places = ref.watch(gameDbProvider(geographySchema)).value;
  final biomes = ref.watch(gameDbProvider(biomesSchema)).value;
  if ((places == null || places.isEmpty) &&
      (biomes == null || biomes.isEmpty)) {
    return Geography.empty;
  }
  return Geography.parse(
      geography: places ?? const {}, biomes: biomes ?? const {});
});

/// The geography once both files have loaded (or failed to): for code that
/// acts on it and may be the first to ask (a road event after a cold
/// start), where [geographyProvider] could still be empty.
Future<Geography> loadGeography(WidgetRef ref) async {
  final ready = ref.read(geographyProvider);
  if (!ready.isEmpty) return ready;
  final places =
      await ref.read(gameDbProvider(geographySchema).notifier).whenLoaded();
  final biomes =
      await ref.read(gameDbProvider(biomesSchema).notifier).whenLoaded();
  return Geography.parse(geography: places, biomes: biomes);
}
