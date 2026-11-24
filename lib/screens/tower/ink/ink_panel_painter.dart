// The Tower's plain panel in ink (v1.1005, UX-2): a black ground, a thin grey
// line round it and a thick paper bar on its left edge (red when lit); no
// round corners, no bevel. Quiet, so the pictures and the red lead.
import 'package:flutter/material.dart';

import 'ink_palette.dart';

class InkPanelPainter extends CustomPainter {
  const InkPanelPainter({this.lit = false});

  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = lit ? inkRed : inkSlate;
    canvas.drawRect(Offset.zero & size, line);
    canvas.drawRect(Rect.fromLTWH(0, 0, 3, size.height),
        Paint()..color = lit ? inkRed : inkPaper);
  }

  @override
  bool shouldRepaint(InkPanelPainter old) => old.lit != lit;
}
