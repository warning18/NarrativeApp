// A short text that follows the text-size setting up to a cap, but never past
// what keeps its longest word whole on one line (v1.997 for the inventory's
// slot tiles, #1098; v1.999 for the palette tiles of Settings): a long word
// (Emberproof, crépusculaire) does not break inside itself.
import 'package:flutter/material.dart';

/// The most such a text grows with the text-size setting.
const double wholeWordMaxTextScale = 1.15;

class WholeWordText extends StatelessWidget {
  const WholeWordText({
    super.key,
    required this.text,
    required this.maxLines,
    required this.style,
    this.maxScale = wholeWordMaxTextScale,
  });

  final String text;
  final int maxLines;
  final TextStyle? style;
  final double maxScale;

  @override
  Widget build(BuildContext context) {
    final user =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: maxScale);
    return LayoutBuilder(
      builder: (context, box) {
        var scaler = user;
        if (box.maxWidth.isFinite) {
          var widest = 0.0;
          for (final word in text.split(RegExp(r'\s+'))) {
            final p = TextPainter(
              text: TextSpan(text: word, style: style),
              textScaler: user,
              textDirection: TextDirection.ltr,
              maxLines: 1,
            )..layout();
            if (p.width > widest) widest = p.width;
          }
          // A 3 % margin: scaled text is not exactly proportional.
          final room = box.maxWidth * 0.97;
          if (widest > room) {
            final k = (user.scale(1) * room / widest).clamp(0.8, 1.0);
            scaler = TextScaler.linear(k);
          }
        }
        return Text(
          text,
          textScaler: scaler,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: style,
        );
      },
    );
  }
}
