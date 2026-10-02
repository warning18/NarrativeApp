// The picker's preview (v1.198) adds up what startNewGame will write.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/character_start.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final defaults = _json('game_config');
  final races = _json('races');
  final professions = _json('professions');

  test('a dwarf warrior starts at 140 HP, 13 damage, 6 armour', () {
    final t = startingTotals(
        defaults: defaults,
        race: races['dwarf'] as Map<String, dynamic>,
        profession: professions['warrior'] as Map<String, dynamic>);
    expect(t.maxHealth, 140);
    expect(t.baseDamage, 13);
    expect(t.baseArmor, 6);
    expect(t.gold, 100);
    expect(t.abilities, {'str_abbrev': 6, 'con_abbrev': 6, 'per_abbrev': 1});
  });

  test('a preset lists only what it changes', () {
    final dwarf = presetBonuses(races['dwarf'] as Map<String, dynamic>);
    expect(dwarf.map((e) => e.key),
        ['hp_label', 'arm_abbrev', 'str_abbrev', 'con_abbrev']);
    final mage = presetBonuses(professions['mage'] as Map<String, dynamic>,
        withOffers: true);
    expect(mage.last.key, 'offer_bonus_label');
    expect(mage.first.key, 'hp_label');
    expect(mage.first.value, -15);
  });

  test('the granted skill drops its preset\'s name', () {
    expect(grantedSkillName('dwarf_stoneskin', presetId: 'dwarf'), 'Stoneskin');
    expect(grantedSkillName('warrior_shield_bash', presetId: 'warrior'),
        'Shield Bash');
    expect(grantedSkillName('human_resolve'), 'Human Resolve');
  });

  test('every race and profession has a mark and a tag', () {
    for (final db in [races, professions]) {
      for (final e in db.entries) {
        final v = e.value as Map<String, dynamic>;
        expect(v['visualAsset'], '${e.key}.png');
        expect(v['tag'], isNotEmpty, reason: e.key);
        expect(v['tag_fr'], isNotEmpty, reason: e.key);
      }
    }
  });
}
