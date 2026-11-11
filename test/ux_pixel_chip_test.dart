// The chip shape (v1.908, lib/theme/pixel_chip.dart): stepped corners, a
// border of the chip's own colour, and nothing breaks on a tiny box.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/theme/pixel_chip.dart';

void main() {
  test('the outer path stays inside the rect and cuts the corners', () {
    const rect = Rect.fromLTWH(0, 0, 80, 32);
    final path = const PixelChipBorder().getOuterPath(rect);
    final b = path.getBounds();
    expect(b.left, greaterThanOrEqualTo(0));
    expect(b.right, lessThanOrEqualTo(80));
    expect(path.contains(const Offset(40, 16)), isTrue);
    // The corner pixel is cut, the middle of each edge is not.
    expect(path.contains(const Offset(0.5, 0.5)), isFalse);
    expect(path.contains(const Offset(79.5, 31.5)), isFalse);
    expect(path.contains(const Offset(40, 0.5)), isTrue);
  });

  test('a very short box does not break the path', () {
    for (final h in [1.0, 4.0, 12.0]) {
      final path =
          const PixelChipBorder().getOuterPath(Rect.fromLTWH(0, 0, 40, h));
      expect(path.getBounds().height, lessThanOrEqualTo(h + 0.001));
    }
  });

  testWidgets('a chip wearing it paints with its border', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Chip(
            label: Text('Gear 2'),
            shape:
                PixelChipBorder(side: BorderSide(color: Colors.red, width: 2)),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('Gear 2'), findsOneWidget);
  });
}
