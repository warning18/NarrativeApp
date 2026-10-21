// The camp's roll powers on a choice sheet (roll_power_row.dart), restyled:
// each power is a small card with its icon, its name and its charges as pips,
// dim when it cannot act (no charge, or no card picked for Banish and Raise);
// a tap acts. Three across fit 320 px, in English and French.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/camp_rolls.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/widgets/roll_power_row.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required CampRolls rolls,
    bool canBanish = false,
    bool canRaise = false,
    List<String>? log,
    AppLanguage lang = AppLanguage.en,
    double width = 320,
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = Size(width, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(
        () => container.read(appLanguageProvider.notifier).setLanguage(lang));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: RollPowerRow(
              keyPrefix: 'p',
              rolls: rolls,
              canBanish: canBanish,
              canRaise: canRaise,
              onReroll: () async => log?.add('reroll'),
              onBanish: (draws) async => log?.add('banish $draws'),
              onRaise: () async => log?.add('raise'),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('nothing shows without a house', (tester) async {
    await pump(tester, rolls: const CampRolls());
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('three powers fit 320 px, named, with their charges as pips',
      (tester) async {
    await pump(tester,
        rolls:
            const CampRolls(reroll: 3, banish: 2, raise: 1, raiseProgress: 5),
        canBanish: true,
        canRaise: true);
    expect(tester.takeException(), isNull);
    expect(find.text('Reroll'), findsOneWidget);
    expect(find.text('Banish'), findsOneWidget);
    expect(find.text('Raise'), findsOneWidget);
    // Three pips, two, one: six dots in all.
    final pipRows = tester.widgetList<Row>(find.byKey(const Key('roll_pips')));
    expect(pipRows.map((r) => r.children.whereType<Container>().length),
        [3, 2, 1]);
    // Raise shows how near its next charge is.
    final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('roll_progress')));
    expect(bar.value, closeTo(5 / raiseChargeEvery, 0.001));
  });

  testWidgets('a tap acts; Banish and Raise wait for a card, and for a charge',
      (tester) async {
    final log = <String>[];
    // No card picked: Reroll acts, the others do not.
    await pump(tester,
        rolls: const CampRolls(reroll: 1, banish: 1, raise: 1), log: log);
    await tester.tap(find.byKey(const Key('p_roll_reroll')));
    await tester.tap(find.byKey(const Key('p_roll_banish')),
        warnIfMissed: false);
    await tester.tap(find.byKey(const Key('p_roll_raise')),
        warnIfMissed: false);
    await tester.pump();
    expect(log, ['reroll']);

    log.clear();
    // A card picked: Raise acts, and Banish asks how long.
    await pump(tester,
        rolls: const CampRolls(reroll: 0, banish: 3, raise: 1),
        canBanish: true,
        canRaise: true,
        log: log);
    await tester.tap(find.byKey(const Key('p_roll_reroll')),
        warnIfMissed: false);
    await tester.tap(find.byKey(const Key('p_roll_raise')));
    await tester.tap(find.byKey(const Key('p_roll_banish')));
    await tester.pumpAndSettle();
    expect(log, ['raise'], reason: 'no charge, no reroll');
    await tester.tap(find.byKey(Key('p_roll_banish_${banishLengths.first}')));
    await tester.pumpAndSettle();
    expect(log, ['raise', 'banish ${banishLengths.first}']);
  });

  testWidgets('French names fit as well', (tester) async {
    await pump(tester,
        rolls: const CampRolls(reroll: 7, banish: 2, raise: 4),
        canBanish: true,
        canRaise: true,
        lang: AppLanguage.fr,
        width: 320);
    expect(tester.takeException(), isNull);
    expect(find.text('Relancer'), findsOneWidget);
    expect(find.text('Écarter'), findsOneWidget);
    expect(find.text('Hausser'), findsOneWidget);
    // More than six charges read as a count.
    expect(find.text('×7'), findsOneWidget);
  });
}
