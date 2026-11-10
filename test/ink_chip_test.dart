// The app's one chip (v1.882): its label wears the colour it is given (the
// Tower's foe marks were white on cream before), and a choice tag, a locked
// one included, is the same chip.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/choice_card.dart';
import 'package:narrative_data_app/widgets/ink_chip.dart';

Color _labelColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.color!;

void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('the label is in the colour given, fully opaque', (tester) async {
    await tester
        .pumpWidget(host(const InkChip('Frenzied', color: Color(0xFFA5302A))));
    expect(_labelColor(tester, 'Frenzied'), const Color(0xFFA5302A));
  });

  testWidgets('a choice tag is an InkChip, and a locked one is ash',
      (tester) async {
    await tester.pumpWidget(host(const Column(children: [
      ChoiceTagChip(tag: ChoiceTag('30 gold', Color(0xFF8A5A00))),
      ChoiceTagChip(tag: ChoiceTag('Fight', Color(0xFFA5302A)), locked: true),
    ])));
    expect(find.byType(InkChip), findsNWidgets(2));
    expect(_labelColor(tester, '30 gold'), const Color(0xFF8A5A00));
    expect(_labelColor(tester, 'Fight'), isNot(const Color(0xFFA5302A)));
  });

  testWidgets('a row of chips wraps rather than overflowing a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(const Wrap(spacing: 6, children: [
      InkChip('Travail à venir', color: Color(0xFF8A5A00)),
      InkChip('Sanguinaire', color: Color(0xFFA5302A), dense: true),
      InkChip('Main droite',
          color: Color(0xFF6B6356), icon: Icons.lock_outline),
    ])));
    expect(tester.takeException(), isNull);
  });
}
