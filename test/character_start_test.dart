// The picker's preview (v1.198) adds up what startNewGame will write.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/character_start.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

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

  test('no race and profession start below 0 armour (an Orc Mage: 0, not -4)',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final MapEntry(key: raceId, value: race) in races.entries) {
      if (race is! Map<String, dynamic>) continue;
      for (final MapEntry(key: professionId, value: profession)
          in professions.entries) {
        if (profession is! Map<String, dynamic>) continue;
        final t = startingTotals(
            defaults: defaults, race: race, profession: profession);
        expect(t.baseArmor, greaterThanOrEqualTo(0),
            reason: '$raceId $professionId');
      }
    }
    // And the game itself starts them there.
    SharedPreferences.setMockInitialValues(
        {'gamedb_game_config': jsonEncode(defaults)});
    final notifier = PlayerSessionNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await notifier.startNewGame(
        raceId: 'orc',
        race: races['orc'] as Map<String, dynamic>,
        professionId: 'mage',
        profession: professions['mage'] as Map<String, dynamic>);
    expect(notifier.state.baseArmor, 0);
    expect(startingArmor(-4), 0);
    expect(startingArmor(6), 6);
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
