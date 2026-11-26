// The Tower's event cards (v2.10.24): each button carries its own outcome,
// a setback owed a Level Up pick says so, and a check plays the d20.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/screens/tower/tower_event_card.dart';
import 'package:narrative_data_app/widgets/d20_roll.dart';

Widget _wrap(Widget child) => ProviderScope(
    child:
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shortcut: the stair and the door each say what follows',
      (tester) async {
    await tester.pumpWidget(_wrap(TowerEventCard(
        const TowerEventView(
            kind: TowerEventKind.shortcut,
            floor: 4,
            revisit: false,
            setbacksLeft: 2,
            skip: 2,
            landsOn: 7),
        onShortcut: (_) {})));
    await tester.pump();
    final stair = find.ancestor(
        of: find.byKey(const Key('tower_shortcut_take')),
        matching: find.byType(TowerChoiceBlock));
    final door = find.ancestor(
        of: find.byKey(const Key('tower_shortcut_decline')),
        matching: find.byType(TowerChoiceBlock));
    expect(
        find.descendant(
            of: stair,
            matching:
                find.textContaining('land on floor 7', findRichText: true)),
        findsOneWidget);
    expect(
        find.descendant(
            of: stair,
            matching:
                find.textContaining('The climb ends here', findRichText: true)),
        findsOneWidget);
    expect(
        find.descendant(
            of: door,
            matching: find.textContaining('no risk', findRichText: true)),
        findsOneWidget);
  });

  testWidgets('a setback owed a pick says its modifier may change',
      (tester) async {
    const view = TowerEventView(
        kind: TowerEventKind.test,
        floor: 4,
        revisit: false,
        setbacksLeft: 2,
        ability: 'strength',
        dc: 12,
        modifier: 3,
        chance: 0.6,
        fallTo: 3,
        gain: 1,
        picksBeforeCheck: 1);
    await tester.pumpWidget(_wrap(const TowerEventCard(view)));
    await tester.pump();
    expect(find.byKey(const Key('tower_event_picks_note')), findsOneWidget);
  });

  testWidgets('a check result plays the d20 and shows roll, bonus and DC',
      (tester) async {
    await tester.pumpWidget(_wrap(const TowerEventResultLine(TowerEventResult(
        kind: TowerEventKind.parley,
        roll: 14,
        total: 17,
        ability: 'charisma',
        modifier: 3,
        dc: 12,
        passed: true,
        from: 4,
        to: 6))));
    await tester.pump();
    expect(find.byType(D20Roll), findsOneWidget);
    expect(find.text('14 + 3 = 17  ·  DC 12'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
}
