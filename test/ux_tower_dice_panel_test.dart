// The Tower floor's "Your dice" panel (tower_dice_panel.dart): the die in
// play and the resonating die tagged, a "new" dot that goes when the die is
// opened, its faces shown, and "Roll this die" choosing it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_dice.dart';
import 'package:narrative_data_app/screens/tower/tower_dice_panel.dart';
import 'package:narrative_data_app/screens/tower/tower_look.dart';

List<Map<String, dynamic>> _faces() => [
      for (var i = 1; i <= 6; i++)
        {'type': i.isEven ? 'Defend' : 'Attack', 'value': i},
    ];

TowerDieView _die(String id,
        {bool inPlay = false, bool resonates = false, bool isNew = false}) =>
    TowerDieView(
        id: id,
        faces: _faces(),
        inPlay: inPlay,
        resonates: resonates,
        isNew: isNew);

void main() {
  Future<void> pump(WidgetTester tester, List<TowerDieView> dice,
      {void Function(String)? onChoose, void Function(String)? onSeen}) async {
    await tester.binding.setSurfaceSize(const Size(412, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: TowerNight(
          child: Scaffold(
            body: SingleChildScrollView(
              child: TowerDicePanel(
                dice: dice,
                onChoose: onChoose ?? (_) {},
                onSeen: onSeen ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('every die is a tile, the one in play and the resonant tagged',
      (tester) async {
    await pump(tester, [
      _die('apprentice_die', inPlay: true),
      _die('flame_die', resonates: true, isNew: true),
      _die('ward_die'),
    ]);
    expect(find.byKey(const Key('tower_die_apprentice_die')), findsOneWidget);
    expect(find.byKey(const Key('tower_die_flame_die')), findsOneWidget);
    expect(find.byKey(const Key('tower_die_ward_die')), findsOneWidget);
    expect(find.text('In play'), findsOneWidget);
    expect(find.text('Resonates'), findsOneWidget);
    expect(find.byKey(const Key('tower_die_new_flame_die')), findsOneWidget);
    expect(find.byKey(const Key('tower_die_new_ward_die')), findsNothing);
    expect(find.byKey(const Key('tower_die_roll')), findsNothing);
  });

  testWidgets('opening a new die marks it seen and offers to roll it',
      (tester) async {
    final seen = <String>[];
    final chosen = <String>[];
    await pump(tester,
        [_die('apprentice_die', inPlay: true), _die('flame_die', isNew: true)],
        onSeen: seen.add, onChoose: chosen.add);
    await tester.tap(find.byKey(const Key('tower_die_flame_die')));
    await tester.pump();
    expect(seen, ['flame_die']);
    expect(find.byIcon(Icons.bolt), findsNWidgets(3));
    expect(find.byIcon(Icons.shield), findsNWidgets(3));
    await tester.tap(find.byKey(const Key('tower_die_roll')));
    expect(chosen, ['flame_die']);
  });

  testWidgets('the die in play cannot be chosen again', (tester) async {
    await pump(
        tester, [_die('apprentice_die', inPlay: true), _die('flame_die')]);
    await tester.tap(find.byKey(const Key('tower_die_apprentice_die')));
    await tester.pump();
    final button =
        tester.widget<FilledButton>(find.byKey(const Key('tower_die_roll')));
    expect(button.onPressed, isNull);
  });
}
