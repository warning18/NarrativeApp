// The Journey's ways grouped by the pin they hang at (v1.561): the list names
// one row for each pin (v1.607), however many ways hang at it.
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
}
