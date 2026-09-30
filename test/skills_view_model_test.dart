// The Skills screen's rules (v1.179), worked out away from the widgets:
// where each skill stands, what it costs in points and essence, what a
// tier buys; then the screen itself -- raising a tier from My skills (a companion's
// list is in skills_companion_test.dart).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/skills/skills_screen.dart';
import 'package:narrative_data_app/screens/skills/skills_view_model.dart';

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
  final trees = _data('skill_trees');

  PlayerSession warrior(Map<String, dynamic> extra) => PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        ...extra,
      });

  group('the model', () {
    test('known, ready and locked follow the branch; costs deepen', () {
      final model = SkillsModel.forPlayer(
        session: warrior({
          'skillPoints': 1,
          'unlockedSkillIds': ['warrior_shield_bash', 'bulwark_stance'],
        }),
        skills: skills,
        trees: trees,
      );
      expect(model['warrior_shield_bash']!.status, SkillStatus.known);
      final iron = model['warrior_iron_stance']!;
      expect(iron.status, SkillStatus.ready);
      expect(iron.cost, 2);
      // One point is not enough for a two-point skill.
      expect(iron.affordable, isFalse);
      expect(iron.readyNow, isFalse);
      final stone = model['stone_resolve']!;
      expect(stone.status, SkillStatus.locked);
      expect(stone.after, 'warrior_iron_stance');
      expect(stone.cost, 3);
      // Every branch's first skill is ready at one point.
      expect(model['power_strike']!.readyNow, isTrue);
    });

    test('everyone\'s basic strike is known and has no tiers', () {
      final model = SkillsModel.forPlayer(
          session: warrior({}), skills: skills, trees: trees);
      final basic = model['heavy_attack']!;
      expect(basic.known, isTrue);
      expect(basic.tierable, isFalse);
      expect(basic.upgradeCost, isNull);
      expect(model.knownIds, contains('heavy_attack'));
    });

    test('tiers: what the next costs, the cheapest for the purse, the max', () {
      final model = SkillsModel.forPlayer(
        session: warrior({
          'unlockedSkillIds': ['warrior_shield_bash', 'power_strike'],
          'skillTiers': {'warrior_shield_bash': 1, 'power_strike': 3},
          'skillEssence': 500,
        }),
        skills: skills,
        trees: trees,
      );
      expect(model['warrior_shield_bash']!.upgradeCost, 2000);
      expect(model['power_strike']!.maxed, isTrue);
      expect(model['power_strike']!.upgradeCost, isNull);
      expect(model.nextUpgradeCost, 2000);
      expect(model.essence, 500);
    });

    test('a mastered branch fights a tier higher', () {
      final model = SkillsModel.forPlayer(
        session: warrior({
          'unlockedSkillIds': ['warrior_shield_bash'],
          'masteredBranchId': 'warrior_bulwark',
        }),
        skills: skills,
        trees: trees,
      );
      final bash = model['warrior_shield_bash']!;
      expect(bash.tier, 0);
      expect(bash.fightTier, 1);
    });

    test('reputation skills wait on the standing they need', () {
      final saint = SkillsModel.forPlayer(
          session: warrior({'alignmentScore': 5}),
          skills: skills,
          trees: trees);
      expect(saint.reputationIds, contains('zealous_conviction'));
      expect(saint['zealous_conviction']!.status, SkillStatus.ready);
      expect(saint['ruthless_edge']!.status, SkillStatus.locked);
      expect(saint['ruthless_edge']!.after, isNull);
    });

    test('a companion: their class, one point each, nothing locked', () {
      final model = SkillsModel.forAlly(
        skillPoints: 1,
        unlockedSkillIds: const ['rogue_backstab'],
        professionId: 'rogue',
        skills: skills,
      );
      expect(model.isPlayer, isFalse);
      expect(model['rogue_backstab']!.known, isTrue);
      expect(model['rogue_poison_blade']!.readyNow, isTrue);
      expect(model['rogue_poison_blade']!.cost, 1);
      expect(model['power_strike'], isNull);
      expect(model.entries.values.where((e) => e.status == SkillStatus.locked),
          isEmpty);
    });

    test('the tier table and the summary read the tier numbers', () {
      final bash = skills['warrior_shield_bash'] as Map<String, dynamic>;
      final table = tierTable(bash);
      expect(table.first.key, 'damage_mod_label');
      expect(table.first.values, ['+5', '+6', '+8', '+9']);
      String t(String key) => switch (key) {
            'summary_damage' => '+{n} damage',
            'summary_heal' => 'heals {n}',
            _ => key,
          };
      expect(skillSummary(bash, 1, t), '+6 damage · ×1.1');
      final stance = skills['bulwark_stance'] as Map<String, dynamic>;
      expect(skillSummary(stance, 0, t), 'heals 15 · Earth');
    });
  });

  group('the screen', () {
    Future<ProviderContainer> open(WidgetTester tester, PlayerSession session,
        {String? allyId}) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(420, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: SkillsScreen(allyId: allyId)),
      ));
      await _settle(tester);
      await tester.runAsync(() =>
          container.read(playerSessionProvider.notifier).loadSession(session));
      await _settle(tester);
      return container;
    }

    testWidgets('My skills raises a tier from the sheet, and says why not',
        (tester) async {
      final container = await open(
          tester,
          warrior({
            'unlockedSkillIds': ['warrior_shield_bash', 'power_strike'],
            'skillEssence': 1500,
          }));
      // The purse says what the essence is for.
      expect(find.byKey(const Key('purse_essence')), findsOneWidget);
      expect(find.textContaining('/ 1000'), findsOneWidget);

      await tester.tap(find.byKey(const Key('skills_tab_mine')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('skill_row_warrior_shield_bash')));
      await _settle(tester);
      // By tier, and the dice it is (not yet) on.
      expect(find.text('+5'), findsOneWidget);
      expect(find.byKey(const Key('skill_dice_link')), findsOneWidget);
      await tester.tap(find.byKey(const Key('skill_raise')));
      await _settle(tester);
      final s = container.read(playerSessionProvider);
      expect(s.skillTiers['warrior_shield_bash'], 1);
      expect(s.skillEssence, 500);
      // The next tier costs 2,000: greyed, and it says how far.
      final raise = tester
          .widget<ButtonStyleButton>(find.byKey(const Key('skill_raise')));
      expect(raise.onPressed, isNull);
      expect(find.textContaining('1500'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
