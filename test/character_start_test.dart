// The picker's preview (v1.198) adds up what startNewGame will write.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/dice_faces.dart';
import 'package:narrative_data_app/data/character_start.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final defaults = _json('game_config');
  final races = _json('races');
  final professions = _json('professions');

  Future<PlayerSessionNotifier> startGame(
      String raceId, String professionId) async {
    SharedPreferences.setMockInitialValues(
        {'gamedb_game_config': jsonEncode(defaults)});
    final notifier = PlayerSessionNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await notifier.startNewGame(
        raceId: raceId,
        race: races[raceId] as Map<String, dynamic>,
        professionId: professionId,
        profession: professions[professionId] as Map<String, dynamic>);
    return notifier;
  }

  test('a dwarf warrior starts at 33 HP, 2 damage, 1 armour', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final state = (await startGame('dwarf', 'warrior')).state;
    expect(state.maxHealth, 33);
    expect(state.baseDamage, 2);
    expect(state.baseArmor, 1);
    expect(state.gold, 100);
    expect([
      state.strength,
      state.dexterity,
      state.constitution,
      state.intelligence,
      state.wisdom,
      state.perception
    ], [
      6,
      0,
      6,
      0,
      0,
      1
    ]);
  });

  test('no race and profession start below 0 armour (an Orc Mage: 0, not -4)',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final raceId in races.keys) {
      for (final professionId in professions.keys) {
        if (races[raceId] is! Map<String, dynamic> ||
            professions[professionId] is! Map<String, dynamic>) {
          continue;
        }
        final notifier = await startGame(raceId, professionId);
        expect(notifier.state.baseArmor, greaterThanOrEqualTo(0),
            reason: '$raceId $professionId');
      }
    }
    // And the game itself starts them there.
    expect((await startGame('orc', 'mage')).state.baseArmor, 0);
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
    // The mage starts 5 health short since v1.601 (Vica guards her best).
    expect(mage.first.key, 'hp_label');
    expect(mage.first.value, -5);
    final rogue = presetBonuses(professions['rogue'] as Map<String, dynamic>);
    expect(rogue.first.key, 'hp_label');
    expect(rogue.first.value, 6);
  });

  test('every starting skill has a French name, not its id in English', () {
    for (final db in [races, professions]) {
      for (final e in db.entries) {
        final id = (e.value as Map)['standardSkillID']?.toString() ?? '';
        if (id.isEmpty) continue;
        expect(skillDisplayName(id, language: AppLanguage.fr),
            isNot(skillDisplayName(id)),
            reason: '${e.key} grants $id');
      }
    }
    expect(skillDisplayName('human_resolve', language: AppLanguage.fr),
        'Détermination');
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
