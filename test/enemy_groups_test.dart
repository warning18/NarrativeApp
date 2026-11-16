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

  test('every person of no faction has a group, and only they do', () {
    final grouped = <String, List<String>>{};
    for (final MapEntry(:key, :value) in enemies.entries) {
      final enemy = value as Map<String, dynamic>;
      final faction = enemy['faction']?.toString() ?? '';
      final group = enemy['group']?.toString() ?? '';
      if (faction.isEmpty && enemy['kind'] == 'person') {
        expect(group, isNotEmpty, reason: '$key has no faction and no group');
      }
      if (group.isNotEmpty) {
        expect(faction, isEmpty, reason: '$key has a faction and a group');
        expect(enemyGroupIds, contains(group), reason: key);
        (grouped[group] ??= []).add(key);
      }
    }
    expect(grouped.keys.toSet(), enemyGroupIds.toSet(),
        reason: 'every group has a member');
    expect(grouped.values.fold<int>(0, (n, ids) => n + ids.length), 21);
    expect(grouped['turned'], hasLength(8));
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
    expect(enemyGroupOf(const {}), '');
  });
}
