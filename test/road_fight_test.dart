// The road in a fight (v1.176): a chapter the party lingers in gathers
// its enemies' strength and says so, and a hired sellsword strikes the
// weakest enemy each round, one fight off the contract.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/data/journey_rules.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/chapter_loop_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Map<String, dynamic> _enemy(String id) =>
    (jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
        as Map<String, dynamic>)[id] as Map<String, dynamic>;

void main() {
  testWidgets('a lingering chapter’s foes are stronger; a sellsword strikes',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    // Chapter 3, twenty days in: well past the grace.
    container.read(storyPlayProvider.notifier).jumpTo('3002');
    await _settle(tester);
    final chapter = container.read(reachedChapterProvider);
    expect(chapter, 3);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
          'maxHealth': 400,
          'currentHealth': 400,
          'day': 21,
          'clockChapter': 3,
          'chapterStartDay': 1,
          'sellswordFights': 2,
        })));
    expect(container.read(playerSessionProvider).threatIn(3), threatMax);

    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);
    // An ambush: the enemy strikes first, then the party's round opens
    // with the sellsword's blow.
    navigator.push(MaterialPageRoute<bool>(
        builder: (_) => FightScreen(
              enemyId: 'harbor_rat',
              enemy: _enemy('harbor_rat'),
              modifiers: const EncounterModifiers(
                  forcedCondition: BattlefieldCondition.ambush,
                  forcedGoal: FightGoal.slay),
            )));
    await _settle(tester);
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);

    // The whole log, a tap on its ticker away.
    await tester.tap(find.byIcon(Icons.unfold_more));
    await _settle(tester);
    expect(find.textContaining('gathered strength while you lingered (+30%)'),
        findsWidgets);
    expect(find.textContaining('Your sellsword strikes'), findsWidgets);
    expect(container.read(playerSessionProvider).sellswordFights, 1);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
