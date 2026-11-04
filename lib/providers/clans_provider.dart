import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clan_power.dart' show ClanPowerRank, clanPowerRanking;
import '../data/factions.dart';
import '../data/region_holders.dart';
import '../data/road_wards.dart';
import '../gamedata/db_schema.dart';
import 'game_db_providers.dart';
import 'geography_provider.dart';
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
  // Every table asked for before the first wait: [ref] is not read again
  // once this awaits, so the widget that asked may go (a fight left while
  // the offer after its level-up loads).
  Future<Map<String, dynamic>> table(DbSchema schema) =>
      ref.read(gameDbProvider(schema).notifier).whenLoaded();
  final factions = table(factionsSchema);
  final subclans = table(subclansSchema);
  final relations = table(relationsSchema);
  final titles = table(titlesSchema);
  final intrigues = table(intriguesSchema);
  final tables = [
    await factions,
    await subclans,
    await relations,
    await titles,
    await intrigues,
  ];
  // Parsed once while the tables stay the same (about 2 ms a parse, and
  // 13 callers); an edit in the Data tab gives a new table, so a new parse.
  final last = _lastClanData;
  if (last != null && sameTables(last.tables, tables)) return last.data;
  final data = ClanData.fromTables(
    factions: tables[0],
    subclans: tables[1],
    relations: tables[2],
    titles: tables[3],
    intrigues: tables[4],
  );
  _lastClanData = (tables: tables, data: data);
  return data;
}

({List<Map<String, dynamic>> tables, ClanData data})? _lastClanData;

/// Whether [a] and [b] hold the very same table objects, in order: the
/// game-data tables are replaced, never changed in place, when edited.
bool sameTables(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!identical(a[i], b[i])) return false;
  }
  return true;
}

/// The character's standing, marks and relations (see PoliticsState).
final politicsProvider = Provider<PoliticsState>(
    (ref) => ref.watch(playerSessionProvider.select((s) => s.politics)));

/// The clans with power ranked, now and at the last chapter's turn
/// (clanPowerRanking, clan_power.dart): the clan power sign's rank and
/// arrow.
final clanPowerRankingProvider = Provider<List<ClanPowerRank>>((ref) =>
    clanPowerRanking(ref.watch(politicsProvider), ref.watch(clanDataProvider)));

/// Each region (a geography.json country) and the clans holding its places
/// (regionHolders, region_holders.dart): the world map's Clans layer.
final regionHoldersProvider = Provider<Map<String, RegionHolders>>((ref) =>
    regionHolders(ref.watch(geographyProvider), ref.watch(politicsProvider)));

/// The clans the Warding Cairn may ward the road against now: those
/// hunting the character (road_wards.dart's [wardTargets]). Empty: the
/// `ward_no_target` line.
final wardTargetsProvider = Provider<List<String>>((ref) => wardTargets(
    ref.watch(playerSessionProvider.select((s) => s.politics)),
    ref.watch(clanDataProvider)));
