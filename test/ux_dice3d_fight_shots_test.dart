// A real Tower fight and the loadout ring (UX_SHOTS=<folder>, UX_TAG=
// before|after): the Tower's dice (flame d8, tide d8, tearglass d12, a d4, a
// d10 and the starter d6) each as the equipped die of a fight, mid-roll and at
// rest, 412 px dark; and the loadout's ring die. Drawn only with UX_SHOTS.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'package:narrative_data_app/screens/dice_loadout_screen.dart';
import 'skill_fight_harness.dart' show gamedata, settle, tapWhenEnabled;
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final tag = Platform.environment['UX_TAG'] ?? 'after';
  const dice = [
    'starter_die',
    'flame_die',
    'tide_die',
    'tearglass_die',
    'void_die',
    'storm_die'
  ];

  testWidgets('a Tower fight and the ring', skip: shots == null,
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await tester.runAsync(loadAppFonts);
    //SLOWFLAG
    Future<void> shot(String name) async {
      final b = tester.firstRenderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary));
      late List<int> bytes;
      await tester.runAsync(() async {
        final image = await b.toImage(pixelRatio: 2);
        bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
      });
      File('$shots/$name-$tag.png').writeAsBytesSync(bytes);
    }

    for (final die in dice) {
      SharedPreferences.setMockInitialValues({
        'app_theme_mode': 'dark',
      });
      usePhone(tester, const Size(412, 860));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(ProviderScope(
          overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
          child: const MyApp()));
      await settle(tester);
      final container =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      await tester.runAsync(() => container
          .read(playerSessionProvider.notifier)
          .loadSession(PlayerSession.fromJson({
            'raceId': 'human',
            'professionId': 'warrior',
            'ownedDiceIds': [die],
            'equippedDiceId': die,
            'maxHealth': 400,
            'currentHealth': 400,
          })));
      final thug = {
        ...gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
        'maxHealth': 900,
        'skillMoves': <dynamic>[],
      };
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(MaterialPageRoute<bool>(
              builder: (_) => FightScreen(
                    enemyId: 'slum_thug',
                    enemy: thug,
                    modifiers: const EncounterModifiers(
                        forcedCondition: BattlefieldCondition.highGround,
                        forcedGoal: FightGoal.slay),
                  )));
      await settle(tester);
      await tester.tap(find.text('Enter Battle'));
      await settle(tester);
      await tapWhenEnabled(tester, 'Roll Dice');
      // Mid-roll, then at rest.
      for (var i = 0; i < 9; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await shot('fight-$die-roll');
      for (var i = 0; i < 60; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await shot('fight-$die-rest');
    }

    // The loadout's ring (the big die in the middle) with the dice owned in
    // the rail under it.
    for (final die in ['flame_die', 'tearglass_die']) {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
      usePhone(tester, const Size(412, 860));
      await tester.pumpWidget(const SizedBox());
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            theme: buildAppTheme(const ColorScheme.dark()),
            home: DiceLoadoutScreen(initialDieId: die)),
      ));
      await settle(tester);
      await tester.runAsync(() => container
          .read(playerSessionProvider.notifier)
          .loadSession(PlayerSession.fromJson({
            'raceId': 'human',
            'professionId': 'warrior',
            'ownedDiceIds': [
              'starter_die',
              'flame_die',
              'tide_die',
              'tearglass_die',
              'void_die',
              'storm_die',
            ],
            'equippedDiceId': die,
          })));
      await settle(tester);
      await shot('ring-$die');
    }
  });
}
