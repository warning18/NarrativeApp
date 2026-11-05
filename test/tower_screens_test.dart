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
import 'package:narrative_data_app/screens/race_profession_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_end_screen.dart';
import 'package:narrative_data_app/widgets/race_profession_cards.dart'
    show ClanDisc;
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
  testWidgets(
      'the main game\'s creation screen picks the hero: the unbought calling '
      'lies padlocked, no clan is told', (tester) async {
    await _open(tester, const TowerStartScreen());
    // The start screen opens the main game's Race & Profession screen.
    final climb = find.byKey(const Key('tower_climb'));
    await tester.ensureVisible(climb);
    await tester.tap(climb);
    await _settle(tester);
    expect(find.byType(RaceProfessionScreen), findsOneWidget);
    // Nothing of the story's clans: no count on the cards.
    expect(find.textContaining('clans'), findsNothing);
    final start = find.byKey(const Key('rp_start'));
    expect(tester.widget<FilledButton>(start).onPressed, isNull);

    await tester.tap(find.byKey(const Key('choice_card_human')));
    await tester.pump();
    expect(find.byKey(const Key('rp_next')), findsOneWidget);
    await tester.tap(find.byKey(const Key('rp_next')));
    await _settle(tester);
    // The cleric is bought with marks: padlocked, a tap does nothing.
    expect(find.byKey(const Key('choice_lock_cleric')), findsOneWidget);
    expect(find.text('Bought with marks: 15'), findsOneWidget);
    expect(find.text('Bought with marks: 25'), findsOneWidget);
    await tester.tap(find.byKey(const Key('choice_card_cleric')));
    await tester.pump();
    expect(tester.widget<FilledButton>(start).onPressed, isNull);

    await tester.tap(find.byKey(const Key('choice_card_warrior')));
    await tester.pump();
    // Picked: the open card tells no clan that will court the hero.
    expect(find.byKey(const Key('open_choice_warrior')), findsOneWidget);
    expect(find.byKey(const Key('rp_summary')), findsOneWidget);
    expect(tester.widgetList(find.byType(ClanDisc)), isEmpty);
    expect(tester.widget<FilledButton>(start).onPressed, isNotNull);

    await tester.tap(start);
    await _settle(tester);
    expect(find.byKey(const Key('tower_floor_label')), findsOneWidget);
    expect(find.text('Floor 1 of 30'), findsOneWidget);
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
