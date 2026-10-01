import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/factions.dart';
import '../gamedata/db_schema.dart';
import 'game_db_providers.dart';
import 'player_session_provider.dart';

/// factions.json, subclans.json, relations.json, titles.json and
/// intrigues.json (see factions.dart), loaded the way every gamedata table
/// is: the asset, or the Data tab's edited copy. Read raw, not
/// French-overlaid: a faction, a sub-clan or a title picks its language
/// itself (nameFor...), and the rules need the same records whatever the
/// language. Empty tables until they have loaded.
final factionsProvider = Provider<Map<String, Faction>>((ref) =>
    parseFactions(ref.watch(gameDbProvider(factionsSchema)).value ?? const {}));

final clanDataProvider = Provider<ClanData>((ref) {
  Map<String, dynamic> table(DbSchema schema) =>
      ref.watch(gameDbProvider(schema)).value ?? const {};
  return ClanData(
    factions: ref.watch(factionsProvider),
    subclans: parseSubclans(table(subclansSchema)),
    relations: parseRelations(table(relationsSchema)),
    titles: parseTitles(table(titlesSchema)),
    intrigues: parseIntrigues(table(intriguesSchema)),
  );
});

/// The clan data once every table has loaded: for code that acts on it
/// and may be the first to ask (an offer after a cold start), where
/// [clanDataProvider] could still be empty.
Future<ClanData> loadClanData(WidgetRef ref) async {
  Future<Map<String, dynamic>> table(DbSchema schema) =>
      ref.read(gameDbProvider(schema).notifier).whenLoaded();
  return ClanData.fromTables(
    factions: await table(factionsSchema),
    subclans: await table(subclansSchema),
    relations: await table(relationsSchema),
    titles: await table(titlesSchema),
    intrigues: await table(intriguesSchema),
  );
}

/// The character's standing, marks and relations (see PoliticsState).
final politicsProvider = Provider<PoliticsState>(
    (ref) => ref.watch(playerSessionProvider.select((s) => s.politics)));
