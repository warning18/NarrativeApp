import 'dart:math';

import 'package:flutter/material.dart';

/// The uploaded walk-cycle frames — see assets/visuals/companion/README.md.
/// Listed explicitly (rather than discovered at runtime via
/// AssetManifest.json) since that manifest's format/availability isn't
/// guaranteed across Flutter versions, and this app only ever ships with
/// this one fixed frame set anyway. The "east" set (rather than "west")
/// faces the direction of travel below: left to right.
final List<String> _spriteFrames = List<String>.generate(
  8,
  (i) => 'assets/visuals/companion/dog_companion_animations/Walking/east/'
      'frame_${i.toString().padLeft(3, '0')}.png',
);

/// A thin strip that plays a small walking-companion animation moving from
/// the left edge to the right edge (west to east) whenever [trigger]
/// changes — used between the story text and the choice list so each node
/// transition gets a playful "someone crossed the page" beat.
class WalkingCompanionStrip extends StatefulWidget {
  const WalkingCompanionStrip({super.key, required this.trigger, this.height = 36});

  final Object trigger;
  final double height;

  @override
  State<WalkingCompanionStrip> createState() => _WalkingCompanionStripState();
}

class _WalkingCompanionStripState extends State<WalkingCompanionStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  }

  @override
  void didUpdateWidget(covariant WalkingCompanionStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isDismissed) return const SizedBox.shrink();
          return LayoutBuilder(
            builder: (context, constraints) {
              const spriteWidth = 60.0;
              const spriteHeight = 60.0;
              final t = Curves.linear.transform(_controller.value);
              final x = -spriteWidth + (constraints.maxWidth + spriteWidth) * t;
              final legPhase = t * 16 * pi;
              // A handful of walk cycles across the crossing.
              final frameIndex = (t * _spriteFrames.length * 4).floor() % _spriteFrames.length;
              final sprite = SizedBox(
                width: spriteWidth,
                height: spriteHeight,
                child: Image.asset(
                  _spriteFrames[frameIndex],
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (context, error, stackTrace) => CustomPaint(
                    size: const Size(spriteWidth, spriteHeight),
                    painter: _WalkingDogPainter(
                      legPhase: legPhase,
                      bodyColor: Theme.of(context).colorScheme.onSurface,
                      patchColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
              );
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(left: x, bottom: 0, child: sprite),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Draws a small terrier-like silhouette (pointy ears, stocky body, a white
/// chest/muzzle patch) mid-stride, with legs swinging from [legPhase].
class _WalkingDogPainter extends CustomPainter {
  _WalkingDogPainter({required this.legPhase, required this.bodyColor, required this.patchColor});

  final double legPhase;
  final Color bodyColor;
  final Color patchColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()..color = bodyColor;
    final lightPaint = Paint()..color = patchColor;
    final legPaint = Paint()
      ..color = bodyColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final bob = 1.0 * (1 - cos(legPhase)).abs() / 2;
    final baseY = size.height - 2 - bob;

    void drawLeg(double hipX, double phaseOffset) {
      final swing = 3.0 * sin(legPhase + phaseOffset);
      canvas.drawLine(Offset(hipX, baseY - 3), Offset(hipX + swing, baseY + 5), legPaint);
    }

    drawLeg(size.width * 0.70, 0);
    drawLeg(size.width * 0.70, pi);
    drawLeg(size.width * 0.28, pi);
    drawLeg(size.width * 0.28, 0);

    // Tail stub, wagging slightly.
    final tailX = size.width * 0.16;
    canvas.drawLine(
      Offset(tailX, baseY - 12),
      Offset(tailX - 4, baseY - 15 + sin(legPhase) * 1.5),
      legPaint,
    );

    // Body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.20, baseY - 12, size.width * 0.62, 10),
        const Radius.circular(6),
      ),
      bodyPaint,
    );

    // Belly patch.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.40, baseY - 6, size.width * 0.28, 5),
        const Radius.circular(3),
      ),
      lightPaint,
    );

    // Head (leading, on the right since the walk moves left-to-right).
    final headCenter = Offset(size.width * 0.86, baseY - 14);
    canvas.drawCircle(headCenter, 6.5, bodyPaint);
    canvas.drawCircle(Offset(headCenter.dx + 3, headCenter.dy + 2), 3.0, lightPaint);

    // Pointy ears.
    canvas.drawPath(
      Path()
        ..moveTo(headCenter.dx + 4, headCenter.dy - 5)
        ..lineTo(headCenter.dx + 6, headCenter.dy - 11)
        ..lineTo(headCenter.dx + 1, headCenter.dy - 6)
        ..close(),
      bodyPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(headCenter.dx - 3, headCenter.dy - 5)
        ..lineTo(headCenter.dx - 5, headCenter.dy - 11)
        ..lineTo(headCenter.dx - 6, headCenter.dy - 4)
        ..close(),
      bodyPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WalkingDogPainter oldDelegate) =>
      oldDelegate.legPhase != legPhase ||
      oldDelegate.bodyColor != bodyColor ||
      oldDelegate.patchColor != patchColor;
}
