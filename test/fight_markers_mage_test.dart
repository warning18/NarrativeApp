// The mage's Ash Well starts empty and says so on the mana meter.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fight_markers_harness.dart';

void main() {
  testWidgets('a mage sees the Ash Well start empty', (tester) async {
    await enterFight(tester, 'mage');
    expect(find.byKey(const Key('ash_well_label')), findsOneWidget);
    expect(find.byKey(const Key('fury_notch_0')), findsNothing);
  });
}
