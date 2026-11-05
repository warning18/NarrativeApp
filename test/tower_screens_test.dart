// The Tower's screens without the climb (v1.847): the start screen locks what
// is not bought, a run starts and is left from the floor stand-in, the end
// screen banks its marks, and the marks screen buys in order.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/screens/tower/tower_end_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_marks_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_start_screen.dart';
import 'support/pump.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<ProviderContainer> _open(WidgetTester tester, Widget screen,
    {Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  usePhone(tester, const Size(400, 2800));
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: screen),
  ));
  await _settle(tester);
  return container;
}

void main() {
  testWidgets('the start screen locks what is not bought; Climb needs a pick',
      (tester) async {
    await _open(tester, const TowerStartScreen());
    // Open at the start: warrior, the Dominion.
    expect(find.byKey(const Key('tower_profession_warrior')), findsOneWidget);
    // The cleric is bought with marks: locked, a tap does nothing.
    await tester
        .ensureVisible(find.byKey(const Key('tower_profession_cleric')));
    await tester.tap(find.byKey(const Key('tower_profession_cleric')),
        warnIfMissed: false);
    await tester.pump();
    final climb = find.byKey(const Key('tower_climb'));
    await tester.ensureVisible(climb);
    expect(tester.widget<FilledButton>(climb).onPressed, isNull);

    for (final k in [
      'tower_race_human',
      'tower_profession_warrior',
      'tower_clan_dominion',
    ]) {
      await tester.ensureVisible(find.byKey(Key(k)));
      await tester.tap(find.byKey(Key(k)));
      await tester.pump();
    }
    await tester.ensureVisible(climb);
    expect(tester.widget<FilledButton>(climb).onPressed, isNotNull);

    await tester.tap(climb);
    await _settle(tester);
    expect(find.byKey(const Key('tower_stub_floor')), findsOneWidget);
    final saved = await TowerSave.open();
    expect(saved.loadRun()?.floor, 1);
    expect(saved.loadRun()?.professionId, 'warrior');

    // Leaving ends the run and shows the end screen.
    await tester.tap(find.byKey(const Key('tower_leave')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('tower_leave_yes')));
    await _settle(tester);
    expect(find.byKey(const Key('tower_end_floor')), findsOneWidget);
    expect(saved.loadRun(), isNull);
  });

  testWidgets('the end screen reads the run and its marks', (tester) async {
    const run = TowerRun(
      seed: 1,
      raceId: 'human',
      professionId: 'warrior',
      clanId: 'dominion',
      floor: 7,
      health: 0,
      status: TowerStatus.dead,
    );
    await _open(
        tester,
        const TowerEndScreen(
            run: run,
            progress: TowerProgress(marks: 6, bestFloor: 7, runs: 1)));
    expect(find.text('Floor 7 of 30'), findsOneWidget);
    expect(find.textContaining('6'), findsWidgets);
    expect(find.byKey(const Key('tower_end_again')), findsOneWidget);
  });

  testWidgets('the marks screen buys in order, with the marks in hand',
      (tester) async {
    await _open(tester, const TowerMarksScreen(), prefs: {
      towerMarksPrefsKey: '{"marks":20}',
    });
    expect(find.byKey(const Key('tower_marks_balance')), findsOneWidget);
    // Flame Die costs 10: bought; the Tide Die needs it and costs 20.
    final tide = find.byKey(const Key('tower_buy_tide_die'));
    await tester.ensureVisible(tide);
    expect(tester.widget<FilledButton>(tide).onPressed, isNull);
    final flame = find.byKey(const Key('tower_buy_flame_die'));
    await tester.ensureVisible(flame);
    await tester.tap(flame);
    await _settle(tester);
    expect(find.text('10'), findsWidgets);
    expect(find.byKey(const Key('tower_buy_flame_die')), findsNothing);
    final saved = await TowerSave.open();
    expect(saved.loadProgress().unlocked, contains('flame_die'));
    expect(saved.loadProgress().marks, 10);
  });
}
