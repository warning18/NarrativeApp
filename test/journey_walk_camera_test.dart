// The party's walk in a place (v1.219): slow and steady, whatever the
// street's length, with the city's map zooming in on it as it goes.
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';

void main() {
  test('a walk in a place is slow and steady, long streets longer', () {
    final short = journeyWalkDuration(80, place: true);
    final long = journeyWalkDuration(400, place: true);
    expect(short, const Duration(milliseconds: 1500));
    expect(long, greaterThan(short));
    expect(journeyWalkDuration(5000, place: true),
        const Duration(milliseconds: 4200));
    // Not in a place: the short walk it was.
    expect(journeyWalkDuration(400, place: false),
        const Duration(milliseconds: 950));
  });

  test('the city zooms in on the walk, holds, and is back at the end', () {
    expect(journeyWalkZoomAt(0), 1.0);
    expect(journeyWalkZoomAt(1), 1.0);
    expect(journeyWalkZoomAt(0.5), journeyWalkZoom);
    expect(journeyWalkZoomAt(0.1), inExclusiveRange(1.0, journeyWalkZoom));
    expect(journeyWalkZoomAt(0.9), inExclusiveRange(1.0, journeyWalkZoom));
  });
}
