// A skill takes no more faces of a die than its rarity allows: common 3,
// uncommon and rare 2, epic and legendary 1. The loadout's picker holds to
// it, and a fight keeps a save from before the limits to it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/dice_faces.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/dice_loadout_screen.dart';

Map<String, dynamic> _data(String name) =>
    json.decode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final skills = _data('skills');
  final dice = _data('dice');
  // Attack, Attack, Skill (Heavy Blow), Guard, Skill, Skill.
  final starter =
      (dice['starter_die']['faces'] as List).cast<Map<String, dynamic>>();

  test('every skill has a rarity, and the rarer the fewer faces', () {
    for (final entry in skills.entries) {
      final skill = entry.value as Map<String, dynamic>;
      expect(skillRarityOptionsFor(skill), isTrue, reason: entry.key);
    }
    expect(skillRarity(skills['heavy_attack']), SkillRarity.common);
    expect(skillRarity(skills['warrior_shield_bash']), SkillRarity.uncommon);
    expect(skillRarity(skills['fireball']), SkillRarity.rare);
    expect(skillRarity(skills['final_stand']), SkillRarity.epic);
    expect(skillRarity(skills['wrath_of_dawn']), SkillRarity.legendary);
    expect(maxFacesForSkill(skills['heavy_attack']), 3);
    expect(maxFacesForSkill(skills['warrior_shield_bash']), 2);
    expect(maxFacesForSkill(skills['fireball']), 2);
    expect(maxFacesForSkill(skills['final_stand']), 1);
    // Without a rarity, a skill is rated by its cost.
    expect(skillRarity(const {'cost': 4}), SkillRarity.epic);
  });

  test('a save with too many copies keeps the first ones only', () {
    final kept = limitedFaceAssignments(
      starter,
      const {
        '0': 'warrior_shield_bash',
        '4': 'warrior_shield_bash',
        '5': 'warrior_shield_bash',
        '3': 'final_stand',
        '1': 'final_stand',
      },
      skills,
    );
    expect(kept, {
      '0': 'warrior_shield_bash',
      '4': 'warrior_shield_bash',
      '1': 'final_stand',
    });
  });

  test('a die\'s fixed faces count first; its open faces don\'t', () {
    // Kelda's iron die has Shield Bash fixed on face 5: one more fits.
    final iron =
        (dice['iron_die']['faces'] as List).cast<Map<String, dynamic>>();
    expect(
        limitedFaceAssignments(
          iron,
          const {'0': 'warrior_shield_bash', '3': 'warrior_shield_bash'},
          skills,
        ),
        {'0': 'warrior_shield_bash'});
    expect(
        facesCastingSkill('warrior_shield_bash', iron,
            const {'0': 'warrior_shield_bash'}, skills),
        2);
    // The starter's open faces left as Heavy Blow don't use its three.
    final kept = limitedFaceAssignments(
      starter,
      const {
        '0': 'heavy_attack',
        '1': 'heavy_attack',
        '3': 'heavy_attack',
        '4': 'heavy_attack',
      },
      skills,
    );
    expect(
        kept, {'0': 'heavy_attack', '1': 'heavy_attack', '3': 'heavy_attack'});
  });

  test('a skill at its limit takes no other face, but keeps its own', () {
    const two = {'0': 'warrior_shield_bash', '4': 'warrior_shield_bash'};
    expect(canSetSkillOnFace('warrior_shield_bash', 5, starter, two, skills),
        isFalse);
    expect(canSetSkillOnFace('warrior_shield_bash', 4, starter, two, skills),
        isTrue);
    expect(canSetSkillOnFace('final_stand', 5, starter, two, skills), isTrue);
    expect(
        canSetSkillOnFace(
            'final_stand', 5, starter, const {'4': 'final_stand'}, skills),
        isFalse);
  });

  testWidgets('the picker greys out a skill already on its faces',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: DiceLoadoutScreen()),
    ));
    await _settle(tester);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'dwarf',
          'professionId': 'warrior',
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
          'unlockedSkillIds': [
            'warrior_shield_bash',
            'dwarf_stoneskin',
            'final_stand',
          ],
          'diceSkillAssignments': {
            'starter_die': {
              '0': 'warrior_shield_bash',
              '4': 'warrior_shield_bash',
              '5': 'warrior_shield_bash',
            },
          },
        })));
    await _settle(tester);

    // The third Shield Bash (face 5) is past its limit.
    expect(find.textContaining('Over its limit'), findsOneWidget);

    // Face 3 (Guard) can't take a third Shield Bash; Stoneskin it can.
    await tester.tap(find.byKey(const Key('face_slot_3')));
    await _settle(tester);
    final bash = tester.widget<ListTile>(
        find.byKey(const Key('pick_skill_warrior_shield_bash')));
    expect(bash.enabled, isFalse);
    final stoneskin = tester
        .widget<ListTile>(find.byKey(const Key('pick_skill_dwarf_stoneskin')));
    expect(stoneskin.enabled, isTrue);
    await tester.tap(find.byKey(const Key('pick_skill_dwarf_stoneskin')));
    await _settle(tester);
    expect(
        container
            .read(playerSessionProvider)
            .diceSkillAssignments['starter_die']?['3'],
        'dwarf_stoneskin');
    await tester.pump(const Duration(seconds: 3));
  });
}

/// Whether [skill]'s `rarity` is one of the five.
bool skillRarityOptionsFor(Map<String, dynamic> skill) =>
    SkillRarity.values.any((r) => r.name == skill['rarity']);
