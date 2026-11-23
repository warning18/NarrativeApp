// A slot tile's name keeps its long words whole at a big text setting
// (#1098): at 1.3x text on a narrow tile, "Emberproof" and "Zweihander" are
// scaled to fit instead of breaking inside the word, and nothing overflows.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/inventory_parts.dart';

void main() {
  for (final name in const ['Godslayer Zweihander', 'Emberproof Plate']) {
    testWidgets('$name stays whole on a narrow tile at 1.3x text',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 130,
                height: 98,
                child: InventorySlotTile(
                    slotLabel: 'Body',
                    icon: const SizedBox(height: 32),
                    worn: name),
              ),
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      // No word is wider than the tile's text box, so none is split.
      final paragraph = tester.renderObject<RenderParagraph>(find.text(name));
      final style = tester.widget<Text>(find.text(name)).style!;
      for (final word in name.split(' ')) {
        final p = TextPainter(
          text: TextSpan(text: word, style: style),
          textScaler: paragraph.textScaler,
          textDirection: TextDirection.ltr,
        )..layout();
        expect(p.width, lessThanOrEqualTo(paragraph.size.width),
            reason: '"$word" is wider than its box');
      }
    });
  }
}
