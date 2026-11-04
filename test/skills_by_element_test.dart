// The Character radar's skills view: known skills counted by element.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/element_points.dart';
import 'package:narrative_data_app/widgets/skills_radar_card.dart';

void main() {
  test('skills are counted by element; None and unknown have no axis', () {
    final counts = skillsByElement([
      {'element': 'Fire'},
      {'element': 'Fire'},
      {'element': 'Ice'},
      {'element': 'None'},
      {'element': 'Plasma'},
      {},
    ]);
    expect(counts.keys.toList(), elementChartOrder);
    expect(counts['Fire'], 2);
    expect(counts['Ice'], 1);
    expect(counts.values.fold(0, (a, b) => a + b), 3);
  });
}
