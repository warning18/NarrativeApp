import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/expedition_steps.dart';
import '../data/place_pools.dart';
import '../gamedata/db_schema.dart';
import 'game_db_providers.dart';

/// detours.json (place_pools.dart): empty while it loads, and for good
/// when the file is missing.
final placePoolsProvider = Provider<PlacePools>((ref) {
  final raw = ref.watch(gameDbProvider(detoursSchema)).value;
  return raw == null ? PlacePools.empty : PlacePools.fromJson(raw);
});

/// detours.json once it has loaded (or failed to): for a detour rolled
/// right after a cold start.
Future<PlacePools> loadPlacePools(WidgetRef ref) async => PlacePools.fromJson(
    await ref.read(gameDbProvider(detoursSchema).notifier).whenLoaded());

/// expedition_steps.json (expedition_steps.dart), by zone id: empty while
/// it loads, and for good when the file is missing.
final writtenStepsProvider = Provider<Map<String, List<WrittenStep>>>((ref) {
  final raw = ref.watch(gameDbProvider(expeditionStepsSchema)).value;
  return raw == null ? const {} : writtenStepsFrom(raw);
});

/// zones.json as the simulator reads it: each zone with a written road
/// (expedition_steps.json) as long as its steps.
Future<Map<String, dynamic>> loadZonesWithWrittenCounts(WidgetRef ref) async {
  final zones =
      await ref.read(gameDbRepositoryProvider(zonesSchema)).loadRecords();
  Map<String, dynamic> raw;
  try {
    raw = await ref
        .read(gameDbRepositoryProvider(expeditionStepsSchema))
        .loadRecords();
  } catch (_) {
    // No expedition_steps.json: every zone keeps its count.
    raw = const {};
  }
  return zonesWithWrittenCounts(zones, writtenStepsFrom(raw));
}
