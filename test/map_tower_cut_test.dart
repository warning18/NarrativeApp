// The Tower's maps (Maps, held prototype): the cross-section reads off a
// run only what the run keeps; its page opens with the run's floor in view;
// the end screen carries the climb's trace and the start page the Tower on
// the world's ball.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/screens/tower/tower_end_screen.dart';
import 'package:narrative_data_app/screens/tower_cut_screen.dart';
import 'package:narrative_data_app/widgets/tower_cut.dart';

TowerRun _run(
        {required int floor,
        int crest = 0,
        Iterable<int> won = const [],
        TowerEventResult? last,
        TowerStatus status = TowerStatus.climbing}) =>
    TowerRun(
        seed: 3,
        raceId: 'human',
        professionId: 'warrior',
        floor: floor,
        crest: crest,
        health: 30,
        status: status,
        spoils: {for (final f in won) f: const <String>[]},
        lastEvent: last);

void main() {
  test('the cut reads off the run: won, passed, highest, the last jump', () {
    final climbing = TowerCutView.of(_run(
        floor: 18,
        crest: 18,
        won: [1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 14, 15, 16],
        last: const TowerEventResult(
            kind: TowerEventKind.shortcut, passed: true, from: 16, to: 18)));
    expect(climbing.floor, 18);
    expect(climbing.highest, 18);
    expect(climbing.won, containsAll([1, 6, 16]));
    // Under the highest floor and not won: passed without a fight.
    expect([
      for (var n = 1; n <= 30; n++)
        if (climbing.passed(n)) n
    ], [
      7,
      13,
      17
    ]);
    expect(climbing.jump, (16, 18));
    expect(climbing.over, isFalse);

    // A fall: the run stands under its highest floor, the jump points down.
    final fallen = TowerCutView.of(_run(
        floor: 14,
        crest: 17,
        won: [for (var f = 1; f <= 16; f++) f],
        last: const TowerEventResult(
            kind: TowerEventKind.test, passed: false, from: 17, to: 14)));
    expect(fallen.highest, 17);
    expect(fallen.jump, (17, 14));
    expect(fallen.passed(14), isFalse, reason: 'the run stands there');

    // One step up is no jump.
    expect(
        TowerCutView.of(_run(
                floor: 5,
                won: [1, 2, 3, 4],
                last: const TowerEventResult(
                    kind: TowerEventKind.rival, passed: false, from: 4, to: 5)))
            .jump,
        isNull);
  });

  testWidgets('the page opens on the run\'s floor, the legend under it',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final run =
        _run(floor: 18, crest: 18, won: [for (var f = 1; f < 17; f++) f]);
    await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: TowerCutScreen(run: run))));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('tower_cut')), findsOneWidget);
    expect(find.byKey(const Key('tower_cut_legend')), findsOneWidget);
    // Scrolled so floor 18 is on screen: 12 storeys of 38 px lie above it.
    final scroll = tester
        .widget<SingleChildScrollView>(
            find.byKey(const Key('tower_cut_scroll')))
        .controller!;
    const top = (30 - 18) * 38.0 + 38 * 1.1 + 10;
    expect(top - scroll.offset, inInclusiveRange(0.0, 640.0 - 56 - 38 - 60));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the end screen carries the climb\'s trace', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
            home: TowerEndScreen(
                run: _run(
                    floor: 22,
                    crest: 22,
                    status: TowerStatus.dead,
                    won: [for (var f = 1; f <= 21; f++) f]),
                progress: const TowerProgress(marks: 134, bestFloor: 22)))));
    await tester.pump(const Duration(milliseconds: 300));
    final trace = find.byKey(const Key('tower_end_trace'));
    expect(trace, findsOneWidget);
    expect(tester.widget<TowerCut>(trace).view.floor, 22);
    expect(tester.widget<TowerCut>(trace).compact, isTrue);
    expect(tester.takeException(), isNull);
  });
}
