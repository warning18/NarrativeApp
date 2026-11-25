// The small print on the ball reads on a phone (wave 3 of the Maps review):
// no name is drawn under 12 px, whatever the zoom or the box.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/chart_map_painter.dart';

void main() {
  test('no name on the ball is drawn under 12 px', () {
    expect(ChartMapPainter.minRegionPx, greaterThanOrEqualTo(12));
    expect(ChartMapPainter.minSmallPx, greaterThanOrEqualTo(12));
    // A seat reads over the works round it, a place over its land.
    expect(ChartMapPainter.minSeatPx,
        greaterThanOrEqualTo(ChartMapPainter.minSmallPx));
    expect(ChartMapPainter.minPlacePx,
        greaterThanOrEqualTo(ChartMapPainter.minRegionPx));
  });
}
