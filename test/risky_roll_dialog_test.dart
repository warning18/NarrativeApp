// The die of a risky gift (wave 15): it tumbles when the card is taken and
// lands on the number saved with the card, the Luck bonus added; Next waits
// for the landing; the odds bar shows the gift's share and the price's.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/risky_gifts.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/widgets/d20_roll.dart' show d20RollDuration;
import 'package:narrative_data_app/widgets/risky_roll_dialog.dart';

void main() {
  Future<void> open(WidgetTester tester,
      {required int roll,
      required int luck,
      required bool won,
      AppLanguage lang = AppLanguage.en}) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: const Key('open'),
            onPressed: () => showRiskyRoll(context,
                roll: roll, luck: luck, won: won, lang: lang),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('open')));
    await tester.pump();
  }

  testWidgets('the die lands, the sum and the verdict show, Next goes on',
      (tester) async {
    await open(tester, roll: 13, luck: 5, won: true);
    expect(find.byKey(const Key('risky_roll_die')), findsOneWidget);
    expect(find.text('The die decides'), findsOneWidget);
    // Tumbling: nothing to go on with yet.
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('risky_roll_continue')))
            .onPressed,
        isNull);
    await tester.pump(d20RollDurationPlus);
    expect(find.text('13 + 1 Luck = 14'), findsOneWidget);
    expect(find.text('The gift is yours.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('risky_roll_continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('risky_roll_dialog')), findsNothing);
  });

  testWidgets('a price is told in French, with no bonus at Luck 0',
      (tester) async {
    await open(tester, roll: 1, luck: 0, won: false, lang: AppLanguage.fr);
    await tester.pump(d20RollDurationPlus);
    expect(find.text('Le dé décide'), findsOneWidget);
    expect(find.byKey(const Key('risky_roll_sum')), findsOneWidget);
    expect(
        tester.widget<Text>(find.byKey(const Key('risky_roll_sum'))).data, '1');
    expect(find.text('Un prix à payer.'), findsOneWidget);
  });

  testWidgets('the odds bar splits the gift and the price by the odds',
      (tester) async {
    for (final luck in [0, 5, 10]) {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(width: 200, child: RiskyOddsBar(luck: luck)))));
      final odds = riskyOddsFor(luck);
      final bar = find.byKey(const Key('risky_odds_bar'));
      final flexes = tester
          .widgetList<Expanded>(
              find.descendant(of: bar, matching: find.byType(Expanded)))
          .map((e) => e.flex)
          .toList();
      expect(flexes, [odds.gift, odds.price], reason: 'Luck $luck');
    }
  });
}

/// Past the die's tumble and the fade of its words.
final Duration d20RollDurationPlus =
    d20RollDuration + const Duration(milliseconds: 500);
