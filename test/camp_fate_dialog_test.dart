// The camp's fate die on screen (v1.183): rolled, landed on a visitor,
// and the rations shared.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/camp_fate.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/camp_fate_dialog.dart';

import 'dart:math';

void main() {
  testWidgets('the die lands on pilgrims, and the rations are shared',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const camp = FateContext(
      chapter: 4,
      gold: 500,
      provisions: 10,
      provisionsMax: 12,
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
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await container
          .read(playerSessionProvider.notifier)
          .loadSession(PlayerSession.fromJson({
            'raceId': 'human',
            'professionId': 'warrior',
            'gold': 500,
            'provisions': 10,
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
    expect(session.provisions, 8);
    expect(session.alignmentScore, pilgrimShareAlignment);
    expect(find.textContaining('They eat in silence'), findsOneWidget);
    expect(find.text('−2 rations'), findsOneWidget);
    expect(find.text('Alignment +3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('fate_sleep_button')));
    await tester.pumpAndSettle();
    expect(find.text('The fate die'), findsNothing);
  });
}
