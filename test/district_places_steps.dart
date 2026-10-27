// The district as places (v1.583): the steps a test takes to reach a way's
// row on the Journey's District view: raise the list under the map, then
// go to a place.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The places of the district's list, one row each.
final placeRows = find.byWidgetPredicate((w) =>
    w.key is ValueKey<String> &&
    (w.key as ValueKey<String>).value.startsWith('place_row_'));

/// Raises the list of places under the map (the handle zooms the map fully).
Future<void> raisePlaces(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('places_handle')));
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// The party goes to the place [row] of the list (the first by default): its
/// mark walks there, then its ways show.
Future<void> goToPlace(WidgetTester tester, {Finder? row}) async {
  await tester.tap(row ?? placeRows.first);
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Both: from the district's map to its first place's ways.
Future<void> openFirstPlace(WidgetTester tester) async {
  await raisePlaces(tester);
  await goToPlace(tester);
}
