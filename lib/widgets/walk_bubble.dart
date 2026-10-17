// A companion's word on the road (wave 13, speakUpOnWalk): a small speech
// bubble over their figure in the land walk's scene, their name over the
// words, its tail pointing down at them. It stands a few seconds and goes by
// itself; nothing to tap.
import 'package:flutter/material.dart';

import '../theme/stitched_ink.dart';
import 'speech_bubble.dart';

class WalkBubble extends StatelessWidget {
  const WalkBubble({
    super.key,
    required this.speaker,
    required this.line,
    this.width = 220,
    this.tailX = 24,
  });

  final String speaker;
  final String line;
  final double width;

  /// Where the tail sits along the bottom edge, from the bubble's left.
  final double tailX;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final fill = theme.colorScheme.surfaceContainerHigh;
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ink.gold, width: 1.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(speaker,
                    key: const Key('walk_bubble_speaker'),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: ink.gold, letterSpacing: 0.6)),
                const SizedBox(height: 2),
                Text(line,
                    key: const Key('walk_bubble_line'),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: speechBubbleTextStyle(theme)
                        ?.copyWith(fontSize: 13, height: 1.3)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: tailX),
            child: CustomPaint(
              size: const Size(14, 8),
              painter: _Tail(fill: fill, stroke: ink.gold),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tail extends CustomPainter {
  _Tail({required this.fill, required this.stroke});
  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);
    canvas.drawPath(
        path.shift(const Offset(0, 0)),
        Paint()
          ..color = fill
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        path,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(_Tail old) => old.fill != fill || old.stroke != stroke;
}
