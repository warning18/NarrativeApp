// The d20 of a check (lib/widgets/d20_roll.dart, ability_roll_dialog.dart):
// it tumbles, flickering through numbers, and lands on the roll; a single
// check is rolled on screen and then tells its sum.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/ability_check.dart';
import 'package:narrative_data_app/widgets/ability_roll_dialog.dart';
import 'package:narrative_data_app/widgets/d20_roll.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('the die rests on a 20, tumbles to a new roll and lands on it',
      (tester) async {
    var landed = 0;
    Widget die(int? roll, bool? ok, int id) => host(D20Roll(
          roll: roll,
          success: ok,
          rollId: id,
          onLanded: () => landed++,
        ));
    await tester.pumpWidget(die(null, null, 0));
    expect(find.text('20'), findsOneWidget);

    await tester.pumpWidget(die(7, true, 1));
    await tester.pump(const Duration(milliseconds: 300));
    // Mid-tumble: not landed yet.
    expect(landed, 0);
    await tester.pump(const Duration(milliseconds: 400));
    expect(landed, 0);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 50));
    expect(landed, 1);
    expect(find.text('7'), findsOneWidget);

    // The same number again rolls again when the roll id moves.
    await tester.pumpWidget(die(7, true, 2));
    await tester.pump(const Duration(milliseconds: 200));
    expect(landed, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(landed, 2);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a check rolled without a tumble sets the die straight down',
      (tester) async {
    await tester.pumpWidget(
        host(const D20Roll(roll: 13, success: false, rolling: false)));
    expect(find.text('13'), findsOneWidget);
  });

  testWidgets('a single check is rolled on screen, then tells its sum',
      (tester) async {
    const result =
        AbilityCheckResult(ability: 'strength', roll: 12, modifier: 2, dc: 12);
    await tester.pumpWidget(host(Builder(
      builder: (context) => TextButton(
        onPressed: () => showAbilityRoll(context,
            result: result, message: 'Strength check: 12 + 2 = 14 — success'),
        child: const Text('roll'),
      ),
    )));
    await tester.tap(find.text('roll'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const Key('ability_roll_die')), findsOneWidget);
    // The line is in the tree but hidden until the die lands.
    final line = find.text('Strength check: 12 + 2 = 14 — success');
    expect(
        tester
            .widget<AnimatedOpacity>(
                find.ancestor(of: line, matching: find.byType(AnimatedOpacity)))
            .opacity,
        0);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(
        tester
            .widget<AnimatedOpacity>(
                find.ancestor(of: line, matching: find.byType(AnimatedOpacity)))
            .opacity,
        1);
    // It goes by itself.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ability_roll_die')), findsNothing);
  });
}
