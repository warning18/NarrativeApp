// QA: shared body of the anomaly chip guard (qa_anomaly_chip_en_test.dart
// and qa_anomaly_chip_fr_test.dart): one language per file so the two halves
// run on different CI shards. The chip's label is the anomaly's name plus
// " · N rounds left" (or " · soon"), and the French ones are long; an
// unwrapped label overflowed on a 420 px window (ship_boarding_retreat_test,
// 1-2% of runs, fixed in 1.259.0). This forces every ground anomaly onto a
// 360 px-wide fight.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/field_anomaly.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 2; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void anomalyChipTest(AppLanguage language) {
  testWidgets('every anomaly chip fits a 360 px fight (${language.name})',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    // Only the chip's own overflow counts here: a 360 px window with the
    // test font has other tight rows that are not this test's business.
    final chipOverflows = <String>[];
    final reporter = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        final where = (details.informationCollector?.call() ?? const [])
            .map((node) => node.toStringDeep())
            .join(' ');
        if (where.contains('fight_anomaly_chip')) {
          chipOverflows.add(details.exceptionAsString().split('\n').first);
        }
        return;
      }
      reporter?.call(details);
    };
    addTearDown(() => FlutterError.onError = reporter);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
        })));
    final thug = {
      ...(jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
          as Map<String, dynamic>)['slum_thug'] as Map<String, dynamic>,
      'maxHealth': 900,
    };

    expect(fieldAnomalies.length, greaterThan(20));
    final overflows = <String>[];
    {
      await tester.runAsync(() =>
          container.read(appLanguageProvider.notifier).setLanguage(language));
      for (final anomaly in fieldAnomalies) {
        final navigator =
            tester.state<NavigatorState>(find.byType(Navigator).first);
        // Active from round 1: the chip carries the longest suffix.
        navigator.push(MaterialPageRoute<bool>(
            builder: (_) => FightScreen(
                  enemyId: 'slum_thug',
                  enemy: thug,
                  modifiers: EncounterModifiers(
                    forcedCondition: BattlefieldCondition.highGround,
                    forcedGoal: FightGoal.slay,
                    forcedAnomaly: FieldAnomalyPlan(
                        anomaly: anomaly,
                        side: AnomalySide.both,
                        onset: 1,
                        rounds: 3),
                  ),
                )));
        await _settle(tester);
        final enter = find.text(trFor(language, 'enter_battle_button'));
        await tester.ensureVisible(enter);
        await tester.tap(enter, warnIfMissed: false);
        await _settle(tester);
        final chip = find.byKey(const Key('fight_anomaly_chip'));
        if (chip.evaluate().isEmpty) {
          overflows.add('${language.name} ${anomaly.id}: no chip shown');
        }
        for (final overflow in chipOverflows) {
          overflows.add('${language.name} ${anomaly.id}: $overflow');
        }
        chipOverflows.clear();
        navigator.pop();
        await _settle(tester);
        chipOverflows.clear();
      }
    }
    expect(overflows, isEmpty, reason: overflows.join('\n'));
  });
}
