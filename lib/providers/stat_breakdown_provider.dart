import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/gear_effects.dart' show parseItemSets;
import '../data/stat_breakdown.dart';
import '../gamedata/db_schema.dart';
import 'clans_provider.dart';
import 'game_config_provider.dart';
import 'game_db_providers.dart';
import 'player_session_provider.dart';
import 'signs_provider.dart';

export '../data/stat_breakdown.dart'
    show StatSource, StatBreakdownTotals, breakdownStats;

/// Where the hero's [stat] (one of [breakdownStats]: an ability, or
/// 'maxHealth', 'baseDamage', 'baseArmor') comes from now (see
/// statBreakdown): its kept rows add up to the number the session stores,
/// all of them to the number the next fight starts with. Raw tables, not
/// French-overlaid (only numbers and ids are read); a table still loading
/// reads as empty, so its rows show up as `earlier` until it has loaded.
final statBreakdownProvider =
    Provider.family<List<StatSource>, String>((ref, stat) {
  Map<String, dynamic> table(DbSchema schema) =>
      ref.watch(gameDbProvider(schema)).value ?? const {};
  return statBreakdown(
    ref.watch(playerSessionProvider),
    stat,
    races: table(racesSchema),
    professions: table(professionsSchema),
    gameConfig: ref.watch(gameConfigProvider).value ?? const {},
    items: table(itemsSchema),
    itemSets: parseItemSets(table(itemSetsSchema)),
    signs: ref.watch(signDefsProvider),
    clans: ref.watch(clanDataProvider),
  );
});
