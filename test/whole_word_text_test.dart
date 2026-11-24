// WholeWordText (v1.999): every French palette name, at 1.3x text on the
// narrow box a palette tile leaves it (the test font is wide), keeps each
// word whole;
// a word that fits is left at the text-size setting.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/widgets/whole_word_text.dart';

const _keys = [
  'palette_stitched_ink',
  'palette_deep_purple',
  'palette_weathered_earth',
  'palette_autumn_meadow',
  'palette_dusk_horizon',
  'palette_aurora_dusk',
  'palette_rose_noir',
  'palette_mist_slate',
];

void main() {
  const style = TextStyle(fontSize: 11);
  Widget host(String text, {double scale = 1.3}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 140,
                child: WholeWordText(text: text, maxLines: 3, style: style),
              ),
            ),
          ),
        ),
      );

  for (final key in _keys) {
    final label = trFor(AppLanguage.fr, key);
    testWidgets('"$label" keeps its words whole at 1.3x', (tester) async {
      await tester.pumpWidget(host(label));
      expect(tester.takeException(), isNull);
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      for (final word in label.split(RegExp(r'\s+'))) {
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

  testWidgets('a text that fits follows the setting up to the cap',
      (tester) async {
    await tester.pumpWidget(host('Aube', scale: 1.3));
    final paragraph = tester.renderObject<RenderParagraph>(find.text('Aube'));
    expect(paragraph.textScaler.scale(10), closeTo(11.5, 0.01),
        reason: '1.3 is capped at 1.15');
  });
}
