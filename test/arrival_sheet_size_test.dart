// The place sheet is large enough to read (v1.550): it opens at up to 90% of
// the screen, the words scroll above the choices, every choice is whole above
// Continue (at 320 px and with large text too), and its handle drags it
// smaller.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/arrival_sheet.dart';

/// The Journey's own composition of the sheet's child: the words take what
/// the choices leave and scroll; the choices are whole, up to 70% of the
/// room the sheet gives them.
Widget _sheet({int lines = 60, int choices = 2, double scale = 1}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 568),
          textScaler: TextScaler.linear(scale),
        ),
        child: Builder(
          builder: (context) => Scaffold(
            body: ArrivalSheet(
              title: 'The White Wells',
              continueLabel: 'Continue',
              closeTip: 'Continue',
              onContinue: () {},
              child: LayoutBuilder(
                builder: (context, room) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ListView(
                        key: const Key('words'),
                        shrinkWrap: true,
                        children: [
                          for (var i = 0; i < lines; i++)
                            Text('The lights were an oasis, line $i.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints:
                          BoxConstraints(maxHeight: room.maxHeight * 0.7),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (var i = 0; i < choices; i++)
                            Card(
                              key: Key('choice_$i'),
                              child: const Padding(
                                padding: EdgeInsets.all(16),
                                child:
                                    Text('Go south with Lysa and the caravan'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

Rect _panel(WidgetTester tester) =>
    tester.getRect(find.byKey(const Key('journey_arrival_panel')));

void main() {
  testWidgets('a long scene opens at 90% of the screen, choices whole',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_sheet());
    await tester.pump(const Duration(milliseconds: 400));
    final panel = _panel(tester);
    expect(panel.height, closeTo(568 * arrivalSheetShare, 1));
    expect(panel.bottom, closeTo(568, 0.5));
    // Both choices are whole, inside the sheet and above Continue.
    final continueTop =
        tester.getRect(find.byKey(const ValueKey('journey_continue'))).top;
    for (var i = 0; i < 2; i++) {
      final r = tester.getRect(find.byKey(Key('choice_$i')));
      expect(r.top, greaterThanOrEqualTo(panel.top), reason: 'choice $i');
      expect(r.bottom, lessThanOrEqualTo(continueTop), reason: 'choice $i');
    }
    // The words are above the choices, and scroll.
    final words = tester.getRect(find.byKey(const Key('words')));
    expect(
        words.bottom,
        lessThanOrEqualTo(
            tester.getRect(find.byKey(const Key('choice_0'))).top));
    final scroll = tester.state<ScrollableState>(find.descendant(
        of: find.byKey(const Key('words')), matching: find.byType(Scrollable)));
    expect(scroll.position.maxScrollExtent, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('with large text the choices are still whole above Continue',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_sheet(scale: 1.6, choices: 3));
    await tester.pump(const Duration(milliseconds: 400));
    final continueTop =
        tester.getRect(find.byKey(const ValueKey('journey_continue'))).top;
    final list = find.descendant(
        of: find.byKey(const Key('journey_arrival_panel')),
        matching: find.byType(Scrollable));
    expect(list, findsWidgets);
    // Whatever shows of the choices is above Continue (the list scrolls
    // when three do not fit in 40% of the screen).
    final first = tester.getRect(find.byKey(const Key('choice_0')));
    expect(first.bottom, lessThanOrEqualTo(continueTop));
    expect(
        tester.getRect(find.byKey(const ValueKey('journey_continue'))).bottom,
        lessThanOrEqualTo(568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a short scene keeps its own height', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_sheet(lines: 2, choices: 1));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_panel(tester).height, lessThan(568 * 0.6));
  });

  testWidgets('the handle drags the sheet smaller, and back up',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_sheet());
    await tester.pump(const Duration(milliseconds: 400));
    final before = _panel(tester).height;
    await tester.drag(
        find.byKey(const Key('journey_arrival_handle')), const Offset(0, 200));
    await tester.pump();
    final smaller = _panel(tester).height;
    expect(smaller, lessThan(before - 100));
    expect(smaller, greaterThanOrEqualTo(568 * arrivalSheetMinShare - 1));
    await tester.drag(
        find.byKey(const Key('journey_arrival_handle')), const Offset(0, -400));
    await tester.pump();
    expect(_panel(tester).height, closeTo(568, 1));
    expect(tester.takeException(), isNull);
  });
}
