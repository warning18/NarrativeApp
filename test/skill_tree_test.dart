// The skill tree: three branches per class learned in order, a heritage
// branch per race, one mastery per character that lifts its branch a
// tier; companions keep to their own class's skills.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/skill_tree.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/skills_screen.dart';

import 'player_session_provider_test.dart' show baseSession, notifierWith;

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

  final trees = _data('skill_trees');
  final skills = _data('skills');
  final professions = _data('professions');
  final races = _data('races');

  group('the trees', () {
    for (final professionId in professions.keys) {
      test('$professionId: three branches of four, all theirs, once each', () {
        final branches = skillBranchesFor(trees,
            raceId: 'human', professionId: professionId);
        final classBranches = branches.where((b) => !b.heritage).toList();
        expect(classBranches, hasLength(3));
        final onTree = <String>[];
        for (final branch in classBranches) {
          expect(branch.skillIds, hasLength(4), reason: branch.id);
          for (final id in branch.skillIds) {
            final skill = skills[id] as Map<String, dynamic>?;
            expect(skill, isNotNull, reason: id);
            expect(skill!['enemyOnly'], isNot(true), reason: id);
            expect(skill['restrictedProfessionID'], anyOf('', professionId),
                reason: id);
            expect(skill['restrictedRaceID'], '', reason: id);
            expect(skill['unlockedViaMergeOnly'], isNot(true), reason: id);
          }
          onTree.addAll(branch.skillIds);
        }
        expect(onTree.toSet(), hasLength(onTree.length));
        // Every skill of the class grows on its tree.
        for (final entry in skills.entries) {
          if ((entry.value as Map)['restrictedProfessionID'] == professionId) {
            expect(onTree, contains(entry.key));
          }
        }
        // A new character's own skills start a branch, so it opens known.
        final profession = professions[professionId] as Map<String, dynamic>;
        for (final key in ['standardSkillID', 'manaSkillID']) {
          final id = profession[key]?.toString() ?? '';
          if (id.isEmpty) continue;
          expect(classBranches.map((b) => b.skillIds.first), contains(id));
        }
      });
    }

    test('each race has its heritage, starting with its own skill', () {
      for (final entry in races.entries) {
        final heritage =
            skillBranchesFor(trees, raceId: entry.key, professionId: 'warrior')
                .where((b) => b.heritage)
                .toList();
        expect(heritage, hasLength(1), reason: entry.key);
        expect(heritage.single.skillIds.first,
            (entry.value as Map)['standardSkillID']);
        for (final id in heritage.single.skillIds) {
          expect((skills[id] as Map)['restrictedRaceID'], entry.key);
        }
      }
    });
  });

  group('learning', () {
    final branches =
        skillBranchesFor(trees, raceId: 'human', professionId: 'warrior');
    bool can(String id, Set<String> known, [int alignment = 0]) =>
        canLearnWithPoints(id,
            branches: branches,
            known: known,
            skills: skills,
            alignmentScore: alignment);

    test('a branch is learned from the top down', () {
      expect(can('power_strike', {}), isTrue);
      expect(can('guard_break', {}), isFalse);
      expect(can('guard_break', {'power_strike'}), isTrue);
      expect(can('power_strike', {'power_strike'}), isFalse);
    });

    test('off the tree only reputation opens a skill', () {
      // A general skill on no warrior branch, and another class's.
      expect(can('focus_mind', {}), isFalse);
      expect(can('fireball', {}), isFalse);
      final zealous = skills['zealous_conviction'] as Map<String, dynamic>;
      expect(isReputationSkill(zealous), isTrue);
      expect(can('zealous_conviction', {}, 100), isTrue);
      expect(can('zealous_conviction', {}, 0), isFalse);
    });
  });

  group('mastery', () {
    final branches =
        skillBranchesFor(trees, raceId: 'human', professionId: 'warrior');
    final vanguard = branches.firstWhere((b) => b.id == 'warrior_vanguard');
    final heritage = branches.firstWhere((b) => b.heritage);

    test('a whole class branch, the points, and no other mastery', () {
      final all = vanguard.skillIds.toSet();
      bool can(Set<String> known, String mastered, int points) =>
          canMasterBranch(vanguard,
              known: known, masteredBranchId: mastered, skillPoints: points);
      expect(can(all, '', 2), isTrue);
      expect(can(all.skip(1).toSet(), '', 2), isFalse);
      expect(can(all, '', 1), isFalse);
      expect(can(all, 'warrior_bulwark', 5), isFalse);
      expect(
          canMasterBranch(heritage,
              known: heritage.skillIds.toSet(),
              masteredBranchId: '',
              skillPoints: 9),
          isFalse);
    });

    test('a mastered branch fights a tier higher', () {
      final tiers = effectiveSkillTiers(
          const {'power_strike': 2, 'bulwark_stance': 1},
          trees,
          'warrior_vanguard');
      expect(tiers['power_strike'], 3);
      expect(tiers['warrior_execute'], 1);
      expect(tiers['bulwark_stance'], 1);
      expect(effectiveSkillTiers(const {'a': 1}, trees, ''), {'a': 1});
    });

    test('masterBranch spends the points once, and a save keeps it', () async {
      final notifier = await notifierWith(baseSession(skillPoints: 5));
      await notifier.masterBranch('warrior_vanguard', cost: branchMasteryCost);
      expect(notifier.state.masteredBranchId, 'warrior_vanguard');
      expect(notifier.state.skillPoints, 3);
      await notifier.masterBranch('warrior_bulwark', cost: branchMasteryCost);
      expect(notifier.state.masteredBranchId, 'warrior_vanguard');
      expect(notifier.state.skillPoints, 3);
      expect(PlayerSession.fromJson(notifier.state.toJson()).masteredBranchId,
          'warrior_vanguard');
    });
  });

  test('a companion keeps to their class, and their die\'s kit', () {
    final rogue = allySkillIds(skills,
        professionId: 'rogue', known: const ['void_blast']);
    expect(rogue, containsAll(['rogue_backstab', 'rogue_poison_blade']));
    expect(rogue, contains('void_blast'));
    expect(rogue, isNot(contains('warrior_whirlwind')));
    expect(rogue, isNot(contains('power_strike')));
    expect(rogue, isNot(contains('human_resolve')));
  });

  testWidgets('the tree learns a skill, then the next; the list filters',
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
      child: const MaterialApp(home: SkillsScreen()),
    ));
    // The saved session loads first; the test's own comes after it.
    await _settle(tester);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'skillPoints': 2,
          'unlockedSkillIds': ['warrior_shield_bash', 'human_resolve'],
        })));
    await _settle(tester);

    expect(find.byKey(const Key('branch_warrior_vanguard')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tree_node_power_strike')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('tree_learn')));
    await _settle(tester);
    var s = container.read(playerSessionProvider);
    expect(s.unlockedSkillIds, contains('power_strike'));
    expect(s.skillPoints, 1);

    // Execute waits for the two before it.
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.byKey(const Key('tree_node_warrior_execute')));
    await _settle(tester);
    expect(find.byKey(const Key('tree_learn')), findsNothing);
    expect(find.textContaining('After'), findsWidgets);
    Navigator.of(tester.element(find.textContaining('After').first)).pop();
    await _settle(tester);

    // The list, healing only: no strike in it, and Bulwark Stance (next on
    // its branch) ready to learn.
    await tester.tap(find.text('List'));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('skill_filter__KindFilter.heal')));
    await _settle(tester);
    expect(find.text('Power Strike'), findsNothing);
    expect(find.byKey(const Key('learn_bulwark_stance')), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
