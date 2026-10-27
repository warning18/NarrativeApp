// The Journey's list of ways grouped by pin (v1.561): a pin that holds several
// ways is one closed row with a count; one with a single way stays a plain
// row; opening a pin shows its ways, and only one pin is open at a time.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/way_pin_groups.dart';

void main() {
  group('grouping', () {
    test('ways at the same pin are one group, in the order of the steps', () {
      final groups = groupWaysByPin(const [
        WayPinEntry(0, 'b:rope', leads: true),
        WayPinEntry(1, 'b:rope'),
        WayPinEntry(2, 'b:gangway', leads: true),
        WayPinEntry(3, 'b:rope'),
      ]);
      expect(groups.map((g) => g.members), [
        [0, 1, 3],
        [2],
      ]);
      expect(groups.first.isPin, isTrue);
      expect(groups.last.isPin, isFalse);
      expect(pinsWithManyWays(groups), 1);
    });

    test('the way that leads names the pin, else the first', () {
      final led = groupWaysByPin(const [
        WayPinEntry(4, 'p'),
        WayPinEntry(5, 'p', leads: true),
      ]);
      expect(led.single.lead, 5);
      final plain = groupWaysByPin(const [
        WayPinEntry(4, 'p'),
        WayPinEntry(5, 'p'),
      ]);
      expect(plain.single.lead, 4);
    });

    test('no ways, no groups', () {
      expect(groupWaysByPin(const []), isEmpty);
    });
  });

  group('the list', () {
    final groups = groupWaysByPin(const [
      WayPinEntry(0, 'rope', leads: true),
      WayPinEntry(1, 'rope'),
      WayPinEntry(2, 'rope'),
      WayPinEntry(3, 'gangway', leads: true),
      WayPinEntry(4, 'tavern', leads: true),
      WayPinEntry(5, 'tavern'),
    ]);

    Widget list() => MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WayPinList(
                groups: groups,
                rowOf: (i, {double indent = 0}) => Padding(
                  key: ValueKey('journey_city_row_$i'),
                  padding: EdgeInsets.only(left: indent),
                  child: Text('way $i'),
                ),
                leadOf: (i) => Text('lead $i'),
                titleOf: (i) => 'pin $i',
              ),
            ),
          ),
        );

    testWidgets('pins are closed with a count; a single way is a plain row',
        (tester) async {
      await tester.pumpWidget(list());
      expect(find.byKey(const ValueKey('journey_city_pin_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('journey_city_pin_4')), findsOneWidget);
      expect(
          tester
              .widget<Text>(find.descendant(
                  of: find.byKey(const ValueKey('journey_city_pin_count_0')),
                  matching: find.byType(Text)))
              .data,
          '3');
      // The single way is its row; the pins' ways are not shown.
      expect(find.byKey(const ValueKey('journey_city_row_3')), findsOneWidget);
      expect(find.byKey(const ValueKey('journey_city_row_0')), findsNothing);
      expect(find.byKey(const ValueKey('journey_city_row_1')), findsNothing);
      expect(find.byKey(const ValueKey('journey_city_pin_3')), findsNothing,
          reason: 'a pin with one way has no group row');
    });

    testWidgets('a tap opens a pin to its ways, indented; a second closes it',
        (tester) async {
      await tester.pumpWidget(list());
      await tester.tap(find.byKey(const ValueKey('journey_city_pin_0')));
      await tester.pump(const Duration(milliseconds: 300));
      for (final i in [0, 1, 2]) {
        expect(find.byKey(ValueKey('journey_city_row_$i')), findsOneWidget);
      }
      expect(
          tester
              .getTopLeft(find.byKey(const ValueKey('journey_city_row_1')))
              .dx,
          greaterThan(tester
              .getTopLeft(find.byKey(const ValueKey('journey_city_row_3')))
              .dx),
          reason: 'its ways are indented');
      await tester.tap(find.byKey(const ValueKey('journey_city_pin_0')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('journey_city_row_1')), findsNothing);
    });

    testWidgets('only one pin is open at a time', (tester) async {
      await tester.pumpWidget(list());
      await tester.tap(find.byKey(const ValueKey('journey_city_pin_0')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('journey_city_pin_4')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('journey_city_row_5')), findsOneWidget);
      expect(find.byKey(const ValueKey('journey_city_row_1')), findsNothing,
          reason: 'opening another pin closes the first');
    });
  });
}
