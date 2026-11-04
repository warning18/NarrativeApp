// The game and the simulator start a character by one rule (v1.784, R5 of
// docs/proposals/core-improvements.md): newCharacterTotals and the
// starting die, skills, spells and face slots of character_start.dart.
// Every race and profession starts the same in both.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/combat/stat_rules.dart';
import 'package:narrative_data_app/data/sim_combat.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

Map<String, dynamic> _asset(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every race and profession starts the same in the game and the sim',
      () async {
    final races = _asset('races');
    final professions = _asset('professions');
    final gameConfig = _asset('game_config');
    final dice = _asset('dice');
    final spells = parseSpells(_asset('spells'));
    var pairs = 0;
    for (final r in races.entries) {
      for (final p in professions.entries) {
        final race = r.value as Map<String, dynamic>;
        final profession = p.value as Map<String, dynamic>;
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        final notifier = container.read(playerSessionProvider.notifier);
        while (!notifier.isLoaded) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        await notifier.startNewGame(
            raceId: r.key,
            race: race,
            professionId: p.key,
            profession: profession);
        final game = container.read(playerSessionProvider);
        container.dispose();
        final sim = SimCharacter.create(
          raceId: r.key,
          race: race,
          professionId: p.key,
          profession: profession,
          gameConfig: gameConfig,
          dice: dice,
          spells: spells,
        );
        final why = '${r.key} ${p.key}';
        expect(sim.maxHealth, game.maxHealth, reason: why);
        expect(sim.baseDamage, game.baseDamage, reason: why);
        expect(sim.baseArmor, game.baseArmor, reason: why);
        expect([
          sim.strength,
          sim.dexterity,
          sim.constitution,
          sim.intelligence,
          sim.wisdom,
          sim.luck,
          sim.charisma,
          sim.perception,
        ], [
          game.strength,
          game.dexterity,
          game.constitution,
          game.intelligence,
          game.wisdom,
          game.luck,
          game.charisma,
          game.perception,
        ], reason: why);
        expect(sim.startingGold, game.gold, reason: why);
        expect(sim.potions, game.potionCount, reason: why);
        expect(sim.diceId, game.equippedDiceId, reason: why);
        expect(sim.diceSkillAssignments,
            game.diceSkillAssignments[game.equippedDiceId] ?? const {},
            reason: why);
        expect(sim.unlockedSkillIds, game.unlockedSkillIds.toSet(),
            reason: why);
        expect([for (final s in sim.knownSpells) s.id], game.knownSpellIds,
            reason: why);
        pairs++;
      }
    }
    expect(pairs, races.length * professions.length);
  });

  test('one XP rule: 100 a level', () {
    expect([for (var l = 1; l <= 4; l++) xpForLevel(l)], [100, 200, 300, 400]);
  });
}
