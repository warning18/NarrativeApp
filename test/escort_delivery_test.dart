// Escorts and deliveries (v1.179) in play: the wagons' load and the days on
// the road show under the progress bar, and each choice says what it cost.
// A payment the purse can't make is shut, and an expedition left early
// still takes its half day.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/alignment_events.dart';
import 'package:narrative_data_app/data/expedition_kinds.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/expedition_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Map<String, dynamic> _zone(String id) =>
    (jsonDecode(File('assets/gamedata/zones.json').readAsStringSync())
        as Map<String, dynamic>)[id] as Map<String, dynamic>;

/// A seed whose expedition opens on one of [keys]: the screen first rolls
/// the alignment event (nothing, for a Neutral party, over
/// [temptationChance]), then draws the stage.
int _seedOpeningOn(ExpeditionKind kind, Set<String> keys) {
  for (var seed = 0;; seed++) {
    final random = Random(seed);
    if (random.nextDouble() < temptationChance) continue;
    final step = buildKindStep(kind,
        chapter: 3,
        random: random,
        used: const {},
        enemyPool: const ['harbor_rat']);
    if (keys.contains(step.key)) return seed;
  }
}

void main() {
  testWidgets('a delivery counts its days; an escort, its load',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
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
          'currentHealth': 300,
          'gold': 500,
        })));
    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);

    // A delivery: a stage takes a day, the safe road another.
    final deliverySeed = _seedOpeningOn(ExpeditionKind.delivery,
        {'crossroads', 'checkpoint', 'bridge', 'storm', 'letter'});
    navigator.push(MaterialPageRoute<bool>(
        builder: (_) => ExpeditionScreen(
              zoneId: 'z_fever_bark',
              zone: _zone('z_fever_bark'),
              random: Random(deliverySeed),
            )));
    await _settle(tester);
    expect(find.byKey(const ValueKey('expedition_deadline_gauge')),
        findsOneWidget);
    expect(find.text('Days on the road: 0 of 6'), findsOneWidget);
    expect(
        find.textContaining('Destination: the Reckoning Wall'), findsOneWidget);
    await tester.tap(find.textContaining('(a day)').first);
    await _settle(tester);
    expect(find.text('Days on the road: 2 of 6'), findsOneWidget);
    expect(find.textContaining('That cost a day: 2 of 6 days gone.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    navigator.pop();
    await _settle(tester);

    // An escort: the wagons' load, and what a choice cost it.
    final escortSeed =
        _seedOpeningOn(ExpeditionKind.escort, {'stragglers', 'thieves'});
    navigator.push(MaterialPageRoute<bool>(
        builder: (_) => ExpeditionScreen(
              zoneId: 'z_salt_road',
              zone: _zone('z_salt_road'),
              random: Random(escortSeed),
            )));
    await _settle(tester);
    expect(
        find.byKey(const ValueKey('expedition_cargo_gauge')), findsOneWidget);
    expect(find.text('Wagons’ load 100%'), findsOneWidget);
    final costly =
        find.text('Make room for them (a crate left)').evaluate().isNotEmpty
            ? find.text('Make room for them (a crate left)')
            : find.text('Raise the alarm');
    await tester.tap(costly);
    await _settle(tester);
    expect(find.text('Wagons’ load 95%'), findsOneWidget);
    expect(find.text('The wagons lost 5% of their load (95% left).'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    navigator.pop();
    await _settle(tester);

    // An empty purse at the checkpoint or the shepherd's: the payment is
    // shut and says why; the other ways stay open.
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(container.read(playerSessionProvider).copyWith(gold: 0)));
    final paidSeed =
        _seedOpeningOn(ExpeditionKind.delivery, {'checkpoint', 'guide'});
    navigator.push(MaterialPageRoute<bool>(
        builder: (_) => ExpeditionScreen(
              zoneId: 'z_fever_bark',
              zone: _zone('z_fever_bark'),
              random: Random(paidSeed),
            )));
    await _settle(tester);
    final shut = find.textContaining('not enough gold (0 in the purse)');
    expect(shut, findsOneWidget);
    ElevatedButton button(Finder label) => tester.widget<ElevatedButton>(
        find.ancestor(of: label, matching: find.byType(ElevatedButton)));
    expect(button(shut).onPressed, isNull);
    final open = find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.byWidgetPredicate(
            (w) => w is Text && !(w.data ?? '').contains('gold')));
    expect(button(open.first).onPressed, isNotNull);

    // Backing out is a retreat, and the half day passes all the same.
    int clock() {
      final session = container.read(playerSessionProvider);
      return session.day * 4 + session.watch;
    }

    final before = clock();
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.text(trFor(AppLanguage.en, 'expedition_retreat_message')),
        findsOneWidget);
    expect(clock(), before + 2);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
