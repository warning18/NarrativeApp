// A floor's check is rolled once (the user's feedback: menu, then Continue
// climb, showed the "catch yourself" test again, every time). The roll is
// rolled when the event resolves and saved in TowerRun.lastEvent; a resume
// (the save read again) never rolls it again nor applies it again, and once
// its d20 has been shown (towerMarkEventShown, saved) a resume sets the die
// down instead of tumbling it.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/screens/tower/tower_event_card.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';
import 'package:narrative_data_app/widgets/d20_roll.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final data = towerDataFromAssets();

  TowerRun at(int seed, int floor, int rules) => towerStart(
          seed: seed,
          raceId: 'human',
          professionId: 'warrior',
          events: 1,
          rules: rules,
          data: data)
      .copyWith(floor: floor);

  /// The run after [run]'s floor won and every table refused: its event
  /// resolved, as the floor screen leaves it.
  TowerRun resolve(TowerRun run) {
    var next = towerAfterFight(run, data, won: true, healthLeft: run.health);
    for (var i = 0; i < 12 && next.status == TowerStatus.choosing; i++) {
      next = towerPick(next, data, null);
    }
    return next;
  }

  /// Runs on both rules whose floor's setback test has been rolled.
  List<TowerRun> rolled() {
    final found = <TowerRun>[];
    for (final rules in [1, 2]) {
      for (var seed = 1; seed < 400 && found.length < rules * 6; seed++) {
        for (var floor = 2; floor < 28; floor++) {
          final run = at(seed, floor, rules);
          if (towerEventKindOf(run) != TowerEventKind.test) continue;
          final next = resolve(run);
          if (next.lastEvent?.kind == TowerEventKind.test) {
            found.add(next);
            break;
          }
        }
      }
    }
    return found;
  }

  final runs = rolled();

  Future<TowerController> opened() async {
    final controller = TowerController();
    for (var i = 0; i < 50 && controller.state.value == null; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return controller;
  }

  test('save, reload and resume: the check is not rolled again', () async {
    expect(runs.where((r) => r.rules == 1), isNotEmpty);
    expect(runs.where((r) => r.rules == 2), isNotEmpty);
    for (final run in runs) {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await TowerSave(prefs).saveRun(run);
      final saved = prefs.getString(towerRunPrefsKey);
      final before = towerEventOf(run, data)?.result;
      expect(before, run.lastEvent);
      // Menu, Continue climb, three times over.
      for (var resume = 0; resume < 3; resume++) {
        final loaded = (await opened()).state.value!.run!;
        expect(jsonEncode(loaded.toJson()), jsonEncode(run.toJson()));
        expect(loaded.lastEvent, run.lastEvent);
        expect(loaded.lastEvent!.roll, run.lastEvent!.roll);
        expect(loaded.health, run.health);
        expect(loaded.potions, run.potions);
        expect(loaded.floor, run.floor);
        expect(loaded.setbacks, run.setbacks);
        expect(towerEventOf(loaded, data)?.result, before);
        // Nothing rewrote the save.
        expect(prefs.getString(towerRunPrefsKey), saved);
      }
    }
  });

  test('the roll shown is saved, once, and leaves the result as it was',
      () async {
    final run = runs.first;
    final shown = towerMarkEventShown(run);
    expect(shown.lastEvent!.shown, isTrue);
    expect(shown.lastEvent, run.lastEvent); // Display only.
    expect(identical(towerMarkEventShown(shown), shown), isTrue);
    final back = TowerRun.fromJson(
        jsonDecode(jsonEncode(shown.toJson())) as Map<String, dynamic>);
    expect(back.lastEvent!.shown, isTrue);
    expect(back.lastEvent, run.lastEvent);
    // A save from before reads as not shown yet.
    expect(TowerEventResult.fromJson(run.lastEvent!.toJson()).shown, isFalse);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await TowerSave(prefs).saveRun(run);
    final controller = await opened();
    await controller.markEventShown();
    final again = (await opened()).state.value!.run!;
    expect(again.lastEvent!.shown, isTrue);
    expect(again.health, run.health);
    expect(again.potions, run.potions);
    expect(again.floor, run.floor);
  });

  Widget host(Widget child) => ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );

  testWidgets('a result not yet shown rolls once and reports it',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final result = runs.first.lastEvent!;
    var calls = 0;
    await tester
        .pumpWidget(host(TowerEventResultLine(result, onShown: () => calls++)));
    expect(tester.widget<D20Roll>(find.byType(D20Roll)).rolling, isTrue);
    await tester.pump(d20RollDuration + const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('a result already shown is set down, not rolled again',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final result = runs.first.lastEvent!.asShown();
    var calls = 0;
    await tester
        .pumpWidget(host(TowerEventResultLine(result, onShown: () => calls++)));
    expect(tester.widget<D20Roll>(find.byType(D20Roll)).rolling, isFalse);
    await tester.pump();
    // The roll line shows at once.
    final line = tester.widget<AnimatedOpacity>(find
        .ancestor(
            of: find.byKey(const Key('tower_event_roll_line')),
            matching: find.byType(AnimatedOpacity))
        .first);
    expect(line.opacity, 1);
    await tester.pumpAndSettle();
    expect(calls, 0);
  });
}
