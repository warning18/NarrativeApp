// The groups of the enemies of no faction (lib/data/enemy_groups.dart): every
// person of no faction names one, every group named exists and has its
// English and French names.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/enemy_groups.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';

void main() {
  final enemies =
      jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
          as Map<String, dynamic>;

  test(
      'every person of no faction has a group; a group is its own or a clan\'s',
      () {
    final factions =
        (jsonDecode(File('assets/gamedata/factions.json').readAsStringSync())
                as Map<String, dynamic>)
            .keys
            .toSet();
    final grouped = <String, List<String>>{};
    for (final MapEntry(:key, :value) in enemies.entries) {
      final enemy = value as Map<String, dynamic>;
      final faction = enemy['faction']?.toString() ?? '';
      final group = enemy['group']?.toString() ?? '';
      if (faction.isEmpty && enemy['kind'] == 'person') {
        expect(group, isNotEmpty, reason: '$key has no faction and no group');
      }
      if (group.isNotEmpty) {
        expect(
            enemyGroupIds.contains(group) || factions.contains(group), isTrue,
            reason: '$key: $group is neither a group nor a faction');
        (grouped[group] ??= []).add(key);
      }
    }
    expect(grouped.keys.toSet(), containsAll(enemyGroupIds),
        reason: 'every group has a member');
    expect(grouped.values.fold<int>(0, (n, ids) => n + ids.length), 22);
    expect(grouped['turned'], hasLength(8));
    expect(grouped['champions'], hasLength(6));
    expect(
        grouped['claimants'],
        unorderedEquals(
            ['claimant_morrow', 'claimant_tallis', 'claimant_vane']));
    // The Horn-Taker wears the Dominion's look and fights under no faction.
    expect(grouped['dominion'], ['horn_taker']);
    expect((enemies['horn_taker'] as Map)['faction'], '');
    // Cassian Oriel stays the Dominion's in the rules.
    expect((enemies['claimant_vane'] as Map)['faction'], 'dominion');
  });

  test('every group has its English and French name', () {
    for (final id in enemyGroupIds) {
      final key = enemyGroupNameKey(id);
      final en = trFor(AppLanguage.en, key), fr = trFor(AppLanguage.fr, key);
      expect(en, isNot(key), reason: key);
      expect(fr, isNot(key), reason: key);
      expect(fr, isNot(en), reason: '$key has no French of its own');
    }
  });

  test('the look is grouped by group, else faction, else kind', () {
    expect(enemyGroupOf(enemies['kelda_turned'] as Map<String, dynamic>),
        'turned');
    expect(enemyGroupOf(enemies['slum_thug'] as Map<String, dynamic>), 'crows');
    expect(
        enemyGroupOf(enemies['harbor_rat'] as Map<String, dynamic>), 'beast');
    expect(enemyGroupOf(enemies['claimant_vane'] as Map<String, dynamic>),
        'claimants');
    expect(enemyGroupOf(enemies['horn_taker'] as Map<String, dynamic>),
        'dominion');
    expect(enemyGroupOf(const {}), '');
  });
}
