import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Sprite frames are picked up automatically from this folder if present —
/// see assets/visuals/companion/README.md. Falls back to a hand-drawn dog
/// when no frames have been added yet.
const String _spriteFramePrefix =
    'assets/visuals/companion/dog_companion_animations/Walking/west/frame_';

/// A thin strip that plays a small walking-companion animation moving from
/// the right edge to the left edge (east to west) whenever [trigger]
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
  List<String> _frames = const [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    _loadFrames();
  }

  Future<void> _loadFrames() async {
    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final manifest = json.decode(manifestJson) as Map<String, dynamic>;
      final frames = manifest.keys.where((path) => path.startsWith(_spriteFramePrefix)).toList()
        ..sort();
      if (mounted && frames.isNotEmpty) {
        setState(() => _frames = frames);
      }
    } catch (_) {
      // No manifest yet, or nothing under assets/visuals/companion/ —
      // keep using the hand-drawn fallback below.
    }
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
              // The hand-drawn fallback is a wide horizontal silhouette;
              // real sprite frames (square, e.g. 88x88 source art) read
              // better a little larger and evenly sized.
              final spriteWidth = _frames.isEmpty ? 40.0 : 34.0;
              final spriteHeight = _frames.isEmpty ? 24.0 : 34.0;
              final t = Curves.linear.transform(_controller.value);
              final x = constraints.maxWidth - (constraints.maxWidth + spriteWidth) * t;
              final legPhase = t * 16 * pi;
              final sprite = _frames.isEmpty
                  ? CustomPaint(
                      size: Size(spriteWidth, spriteHeight),
                      painter: _WalkingDogPainter(
                        legPhase: legPhase,
                        bodyColor: Theme.of(context).colorScheme.onSurface,
                        patchColor: Theme.of(context).colorScheme.surface,
                      ),
                    )
                  : SizedBox(
                      width: spriteWidth,
                      height: spriteHeight,
                      // A handful of walk cycles across the crossing, cycling
                      // through whatever frames were found.
                      child: Image.asset(
                        _frames[(t * _frames.length * 4).floor() % _frames.length],
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
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

    drawLeg(size.width * 0.30, 0);
    drawLeg(size.width * 0.30, pi);
    drawLeg(size.width * 0.72, pi);
    drawLeg(size.width * 0.72, 0);

    // Tail stub, wagging slightly.
    final tailX = size.width * 0.84;
    canvas.drawLine(
      Offset(tailX, baseY - 12),
      Offset(tailX + 4, baseY - 15 + sin(legPhase) * 1.5),
      legPaint,
    );

    // Body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.18, baseY - 12, size.width * 0.62, 10),
        const Radius.circular(6),
      ),
      bodyPaint,
    );

    // Belly patch.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.32, baseY - 6, size.width * 0.28, 5),
        const Radius.circular(3),
      ),
      lightPaint,
    );

    // Head (leading, on the left since the walk moves right-to-left).
    final headCenter = Offset(size.width * 0.14, baseY - 14);
    canvas.drawCircle(headCenter, 6.5, bodyPaint);
    canvas.drawCircle(Offset(headCenter.dx - 3, headCenter.dy + 2), 3.0, lightPaint);

    // Pointy ears.
    canvas.drawPath(
      Path()
        ..moveTo(headCenter.dx - 4, headCenter.dy - 5)
        ..lineTo(headCenter.dx - 6, headCenter.dy - 11)
        ..lineTo(headCenter.dx - 1, headCenter.dy - 6)
        ..close(),
      bodyPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(headCenter.dx + 3, headCenter.dy - 5)
        ..lineTo(headCenter.dx + 5, headCenter.dy - 11)
        ..lineTo(headCenter.dx + 6, headCenter.dy - 4)
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
