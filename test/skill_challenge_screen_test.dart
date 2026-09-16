// Widget-level coverage for SkillChallengeScreen -- renders with real
// layout, drives the Begin -> round-reveal -> Continue flow through the
// widget tree, and confirms it pops a bool back to its caller, the same
// contract FightScreen already has for a combat result.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/screens/skill_challenge_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Begin reveals every round, then Continue pops a bool result',
      (WidgetTester tester) async {
    bool? popped;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                popped = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const SkillChallengeScreen(
                      promptText: 'Play to win',
                      ability: 'luck',
                      dc: 12,
                      successesNeeded: 3,
                      maxFailures: 2,
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    // Let PlayerSessionNotifier's async SharedPreferences load settle
    // before the screen reads the session in initState.
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Begin'), findsOneWidget);
    // Nothing revealed yet -- confirms the reveal is gated behind Begin,
    // not dumped on screen immediately.
    expect(find.byType(ListTile), findsNothing);

    await tester.tap(find.text('Begin'));
    await tester.pump();

    // Race-to-3-successes-or-2-failures resolves in at most
    // successesNeeded + maxFailures - 1 = 4 rounds; advance the fake clock
    // through more than that so the real (unseeded) outcome always
    // finishes revealing, whichever way it went.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 550));
    }
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // At least one round tile should have been revealed, and the flow
    // should have reached its final Continue button.
    expect(find.byType(ListTile), findsWidgets);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(popped, isNotNull);
  });
}
