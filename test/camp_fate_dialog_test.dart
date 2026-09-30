// The camp's fate die on screen (v1.183): rolled, landed on a visitor,
// and the rations shared. Back skips neither the roll nor the night's
// choice, and a quick second tap (on a choice, or on Rest) plays nothing
// twice.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/camp_fate.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/camp_fate_dialog.dart';
import 'package:narrative_data_app/widgets/road_panel.dart';

import 'dart:math';

void main() {
  testWidgets('the die lands on pilgrims, and the rations are shared',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const camp = FateContext(
      chapter: 4,
      gold: 500,
      provisions: 8,
      provisionsMax: 8,
      companionIds: [],
      rumorPlaceIds: [],
    );
    const roll = FateRoll(
        faceIndex: 1, face: FateFace.visitor, visitor: FateVisitor.pilgrims);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => CampFateDialog(
                  fateContext: camp,
                  roll: roll,
                  random: Random(1),
                  restedLine: 'Day 12 begins.',
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() async {
      // The notifier reads its save first; the test's session goes over it.
      final notifier = container.read(playerSessionProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await notifier.loadSession(PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'gold': 500,
        'provisions': 8,
      }));
    });

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('The fate die'), findsOneWidget);
    expect(find.text('Day 12 begins.'), findsOneWidget);
    expect(find.text('Windfall'), findsOneWidget);
    expect(find.byKey(const ValueKey('fate_sleep_button')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('fate_roll_button')));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.textContaining('Three pilgrims'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('fate_choice_shareRations')));
    for (var i = 0;
        i < 20 && find.textContaining('They eat in silence').evaluate().isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    final session = container.read(playerSessionProvider);
    expect(session.provisions, 6);
    expect(session.alignmentScore, pilgrimShareAlignment);
    expect(find.textContaining('They eat in silence'), findsOneWidget);
    expect(find.text('−2 rations'), findsOneWidget);
    expect(find.text('Alignment +3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('fate_sleep_button')));
    await tester.pumpAndSettle();
    expect(find.text('The fate die'), findsNothing);
  });

  testWidgets('back waits for the night; a double tap hands over once',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const camp = FateContext(
      chapter: 4,
      gold: 100,
      provisions: 6,
      provisionsMax: 8,
      companionIds: [],
      rumorPlaceIds: [],
    );
    const roll = FateRoll(
        faceIndex: 1, face: FateFace.visitor, visitor: FateVisitor.deserter);
    List<Object?>? closedWith;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                closedWith = await showDialog<List<Object?>>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => CampFateDialog(
                    fateContext: camp,
                    roll: roll,
                    random: Random(1),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() async {
      // The notifier reads its save first; the test's session goes over it.
      final notifier = container.read(playerSessionProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await notifier.loadSession(PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'gold': 100,
      }));
    });

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Back before the roll: the die stays, the night still to roll.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fate_roll_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('fate_roll_button')));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    // Back with the deserter at the fire: the choice still waits.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final handOver = find.byKey(const ValueKey('fate_choice_handOver'));
    expect(handOver, findsOneWidget);

    // Two quick taps: the bounty is paid, and the alignment lost, once.
    await tester.tap(handOver);
    await tester.tap(handOver, warnIfMissed: false);
    for (var i = 0;
        i < 20 &&
            find.byKey(const ValueKey('fate_sleep_button')).evaluate().isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    final session = container.read(playerSessionProvider);
    expect(session.gold, 100 + deserterBounty(4));
    expect(session.alignmentScore, deserterHandOverAlignment);

    // Played out, back closes it as its button does.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('The fate die'), findsNothing);
    expect(closedWith, isNotNull);
  });

  testWidgets('two quick taps on Rest rest one night', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () =>
                  restTheNight(context, ref, message: 'A night by the fire.'),
              child: const Text('rest'),
            ),
          ),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() async {
      // The notifier reads its save first; the test's session goes over it.
      final notifier = container.read(playerSessionProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await notifier.loadSession(PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'day': 4,
      }));
    });

    await tester.tap(find.text('rest'));
    await tester.tap(find.text('rest'));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(container.read(playerSessionProvider).day, 5);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Once it is over, Rest rests again.
    await tester.tap(find.text('rest'));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(container.read(playerSessionProvider).day, 6);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
