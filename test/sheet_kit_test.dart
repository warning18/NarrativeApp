// The parts the small sheets share (sheet_kit.dart): a header with its
// italic line, a row with the price leading its lines, the main button
// carrying the price.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/sheet_kit.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(const ColorScheme.dark()),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ));
  }

  testWidgets('the header says its line under the title', (tester) async {
    await pump(
        tester,
        const SheetHeader(
            icon: Icons.home,
            title: 'The Anvil Chapel',
            caption: 'Strike it once.',
            captionKey: Key('caption')));
    expect(find.text('The Anvil Chapel'), findsOneWidget);
    expect(
        tester.widget<Text>(find.byKey(const Key('caption'))).style?.fontStyle,
        FontStyle.italic);
  });

  testWidgets('a row puts the price before its lines and the label above',
      (tester) async {
    await pump(
        tester,
        SheetRow(
          title: 'The Ledger’s cover',
          label: 'Blessing',
          price: 135,
          lines: const ['Three fights.', ''],
          onTap: () {},
        ));
    expect(find.text('Blessing'), findsOneWidget);
    expect(find.text('135'), findsOneWidget);
    // An empty line is dropped; the price sits above the text.
    expect(find.text('Three fights.'), findsOneWidget);
    expect(tester.getTopLeft(find.text('135')).dy,
        lessThan(tester.getTopLeft(find.text('Three fights.')).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the main button carries its price; null greys it out',
      (tester) async {
    var closed = 0;
    await pump(
        tester,
        SheetButtons(
          primaryKey: const Key('main'),
          primaryLabel: 'Build',
          price: 280,
          closeLabel: 'Close',
          onClose: () => closed++,
        ));
    expect(find.text('Build · 280 G'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('main'))).onPressed,
        isNull);
    await tester.tap(find.text('Close'));
    expect(closed, 1);
  });
}
