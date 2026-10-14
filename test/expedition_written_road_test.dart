// A zone with a written road (expedition_steps.json) walks it in play: its
// steps in order, its length theirs, and a choice's note opening the next
// step.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/expedition_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Settles until [done] holds (at most 30 s): the session, the zone's
/// steps and the screen all load in their own time, slower on a busy runner.
Future<void> _settleUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 300 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a written road is walked step by step', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    // The road, as the Data tab's saved copy of expedition_steps.json.
    SharedPreferences.setMockInitialValues({
      // No hunter or temptation in the way of the road (the setting loads
      // from here, over anything set before it has).
      'alignment_hunters_enabled': false,
      'gamedb_expedition_steps': jsonEncode({
        // A test zone of its own, so the real file's roads never meet it.
        'z_test_road': {
          'steps': [
            {
              'id': 'gutting',
              'type': 'event',
              'text': 'A gutting-table line that does not look up.',
              'text_fr': 'Une rangée d’étals qui ne lève pas les yeux.',
              'choices': [
                {
                  'id': 'ask',
                  'text': 'Ask after the overseer',
                  'text_fr': 'Demander le contremaître',
                  'outcome': {
                    'note': 'Nobody answers a stranger.',
                    'note_fr': 'Personne ne répond à un étranger.',
                  },
                },
              ],
            },
            {
              'id': 'brazier',
              'type': 'rest',
              'text': 'The smokehouse brazier.',
              'text_fr': 'Le brasero du fumoir.',
              'choices': [
                {'id': 'warm', 'text': 'Warm up', 'text_fr': 'Se réchauffer'},
              ],
            },
          ],
        },
      }),
    });
    tester.view.physicalSize = const Size(420, 900);
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
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(const {
          'raceId': 'human',
          'professionId': 'warrior',
          'maxHealth': 300,
          'currentHealth': 200,
        })));
    final zone =
        (jsonDecode(File('assets/gamedata/zones.json').readAsStringSync())
                as Map<String, dynamic>)['z_fishermans_row']
            as Map<String, dynamic>;
    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.push(MaterialPageRoute<bool>(
        // Seed 2's first draw (0.0008) would bring a temptation, were the
        // hunters setting not honoured: the road's first step must show
        // all the same (the screen waits for the saved setting).
        builder: (_) => ExpeditionScreen(
            zoneId: 'z_test_road', zone: zone, random: Random(2))));
    await _settleUntil(
        tester,
        () =>
            find.textContaining('A gutting-table line').evaluate().isNotEmpty);

    expect(find.textContaining('A gutting-table line'), findsOneWidget);
    expect(find.textContaining('Expedition 1 / 2'), findsOneWidget);
    await tester.tap(find.text('Ask after the overseer'));
    await _settleUntil(
        tester,
        () => find
            .textContaining('The smokehouse brazier.')
            .evaluate()
            .isNotEmpty);

    // The note opens the next step, the rest.
    expect(find.textContaining('Nobody answers a stranger.'), findsOneWidget);
    expect(find.textContaining('The smokehouse brazier.'), findsOneWidget);
    expect(find.textContaining('Expedition 2 / 2'), findsOneWidget);
    final before = container.read(playerSessionProvider).currentHealth;
    await tester.tap(find.text('Warm up'));
    await _settleUntil(tester,
        () => container.read(playerSessionProvider).currentHealth > before);
    expect(container.read(playerSessionProvider).currentHealth,
        greaterThan(before));
    expect(tester.takeException(), isNull);
  });
}
