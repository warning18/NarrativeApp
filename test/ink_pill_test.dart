// InkPill, the one rounded tag the harbour's parts, the origin book's lessons,
// the offers and the choice cards share (wave 3b): its words, its icon, its
// neutral-text form, and a long label that wraps in a narrow row instead of
// overflowing. UX_SHOTS (a folder) saves the picture of the four forms.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/theme/stitched_ink.dart';

Widget _host(Widget child, {double width = 320}) => MaterialApp(
      theme: buildAppTheme(const ColorScheme.dark()),
      home: Scaffold(
        body: Center(child: SizedBox(width: width, child: child)),
      ),
    );

void main() {
  testWidgets('a pill shows its words in its colour, with its icon when large',
      (tester) async {
    await tester.pumpWidget(_host(const Wrap(spacing: 6, children: [
      InkPill(label: 'Rare', color: Colors.teal),
      InkPill(
          label: 'Teaches patience',
          color: Colors.amber,
          icon: Icons.auto_awesome,
          large: true),
      InkPill(label: 'Risky', color: Colors.red, neutralText: true),
    ])));
    expect(tester.widget<Text>(find.text('Rare')).style?.color, Colors.teal);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    // Neutral text: the words keep the page's own colour, only the frame is red.
    expect(tester.widget<Text>(find.text('Risky')).style?.color,
        isNot(Colors.red));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long label does not overflow a narrow row', (tester) async {
    await tester.pumpWidget(_host(
        const Row(children: [
          Flexible(
              child: InkPill(
                  label: 'A very long condition that goes on and on',
                  color: Colors.teal)),
        ]),
        width: 160));
    expect(tester.takeException(), isNull);
  });
}
