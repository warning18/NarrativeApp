// Confirms every pixel icon id list stays in sync with its real game-data
// file. A record added to items/skills/enemies/shops.json without a
// matching entry here silently falls back to a generic Material glyph in
// the real game (see ItemPixelIcon etc. in game_pixel_icons.dart) --
// harmless, but this test catches the gap immediately instead of it going
// unnoticed indefinitely.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/utils/pixel_icons/enemy_icons.dart';
import 'package:narrative_data_app/utils/pixel_icons/item_icons.dart';
import 'package:narrative_data_app/utils/pixel_icons/shop_icons.dart';
import 'package:narrative_data_app/utils/pixel_icons/skill_icons.dart';

Future<Set<String>> _idsIn(String path) async {
  final raw = await rootBundle.loadString(path);
  return (json.decode(raw) as Map<String, dynamic>).keys.toSet();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ItemIcons covers every id in items.json', () async {
    final ids = await _idsIn('assets/gamedata/items.json');
    expect(ItemIcons.allIds.toSet(), ids);
  });

  test('SkillIcons covers every id in skills.json', () async {
    final ids = await _idsIn('assets/gamedata/skills.json');
    expect(SkillIcons.allIds.toSet(), ids);
  });

  test('EnemyIcons covers every id in enemies.json', () async {
    final ids = await _idsIn('assets/gamedata/enemies.json');
    expect(EnemyIcons.allIds.toSet(), ids);
  });

  test('ShopIcons covers every id in shops.json', () async {
    final ids = await _idsIn('assets/gamedata/shops.json');
    expect(ShopIcons.allIds.toSet(), ids);
  });
}
