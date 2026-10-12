// QA: dangling references between the gamedata files that different
// sessions edit (skills, trees, merges, enemies, items, effects).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/skill_vfx.dart';

Map<String, dynamic> _load(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final skills = _load('skills');
  final spells = _load('spells');
  final items = _load('items');
  final enemies = _load('enemies');
  bool known(Object? id) => skills.containsKey(id) || spells.containsKey(id);

  test('every skill and spell names an effect that exists', () {
    final ids = vfxStyleIds.values.toSet();
    final bad = [
      for (final m in [skills, spells])
        for (final e in m.entries)
          if ((e.value['vfx'] ?? '') != '' && !ids.contains(e.value['vfx']))
            '${e.key}: ${e.value['vfx']}',
    ];
    expect(bad, isEmpty);
  });

  test('every active skill names an effect', () {
    final bare = [
      for (final e in skills.entries)
        if (e.value['isActiveSkill'] == true && (e.value['vfx'] ?? '') == '')
          e.key,
    ];
    expect(bare, isEmpty);
  });

  test('skill trees, merges and prerequisites point at real skills', () {
    final bad = <String>[];
    for (final t in _load('skill_trees').values) {
      for (final s in (t['skillIds'] as List)) {
        if (!known(s)) bad.add('tree ${t['branchID']}: $s');
      }
    }
    for (final m in _load('skill_merges').values) {
      for (final s in [...(m['inputSkillIDs'] as List), m['resultSkillID']]) {
        if (!known(s)) bad.add('merge ${m['id']}: $s');
      }
    }
    for (final e in skills.entries) {
      for (final f in ['requiredSkillID', 'ascendsSkillID']) {
        final v = e.value[f];
        if (v is String && v.isNotEmpty && !known(v)) {
          bad.add('${e.key}.$f: $v');
        }
      }
      for (final s in (e.value['fusionOf'] as List? ?? const [])) {
        if (!known(s)) bad.add('${e.key}.fusionOf: $s');
      }
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('enemy moves and loot point at real skills and items', () {
    final bad = <String>[];
    for (final e in enemies.entries) {
      for (final m in (e.value['skillMoves'] as List? ?? const [])) {
        if (!known(m['skillID'])) bad.add('${e.key} move ${m['skillID']}');
      }
      for (final l in (e.value['lootTable'] as List? ?? const [])) {
        if (!items.containsKey(l['itemID'])) {
          bad.add('${e.key} loot ${l['itemID']}');
        }
      }
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('every skill has a French name, description and battle line', () {
    final bad = [
      for (final e in skills.entries)
        if ('${e.value['name_fr'] ?? ''}'.isEmpty ||
            '${e.value['description_fr'] ?? ''}'.isEmpty ||
            (('${e.value['battleMessage'] ?? ''}'.isNotEmpty) &&
                '${e.value['battleMessage_fr'] ?? ''}'.isEmpty))
          e.key,
    ];
    expect(bad, isEmpty);
  });
}
