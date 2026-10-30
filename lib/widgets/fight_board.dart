// The dice board of a fight (combat redesign A''): a felt-like surface whose
// look follows the place of the fight (the sand of the dunes, the flagstones
// of a hall...), and the line a selected die draws to its target. Everything
// is drawn in code (patterns and strokes); there is no image to ship.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../combat/field_anomaly.dart' show FightStage;

/// The board's base colour for [stage] (also the colour of its edge glow).
Color fightBoardBase(FightStage stage) => switch (stage) {
      FightStage.fields => const Color(0xFF3D5233),
      FightStage.dunes => const Color(0xFFC9A96A),
      FightStage.saltFlats => const Color(0xFFD8D9D2),
      FightStage.waves => const Color(0xFF2D5F78),
      FightStage.ash => const Color(0xFF26242A),
      FightStage.terraces => const Color(0xFF6C6A5E),
      FightStage.cliffs => const Color(0xFF58565C),
      FightStage.reeds => const Color(0xFF3F4A36),
      FightStage.snow => const Color(0xFFDFE8EF),
      FightStage.glass => const Color(0xFF1C2B3A),
      FightStage.hall => const Color(0xFF4A4036),
    };

/// Paints the board's surface for [stage]: the same picture every time (a
/// fixed seed), never animated.
class FightBoardPainter extends CustomPainter {
  const FightBoardPainter(this.stage);

  final FightStage stage;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = math.Random(stage.index * 97 + 13);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h), Paint()..color = fightBoardBase(stage));
    Paint stroke(Color c, double width, [double alpha = 1]) => Paint()
      ..color = c.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    Paint fill(Color c, [double alpha = 1]) =>
        Paint()..color = c.withValues(alpha: alpha);
    double rx(double a, double b) => a + r.nextDouble() * (b - a);

    switch (stage) {
      case FightStage.fields:
        for (var i = 0; i < 8; i++) {
          canvas.drawOval(
              Rect.fromCenter(
                  center: Offset(rx(0, w), rx(0, h)),
                  width: rx(28, 72),
                  height: rx(10, 20)),
              fill(const Color(0xFF4A3D2A), 0.35));
        }
        for (var i = 0; i < 150; i++) {
          final x = rx(5, w - 5);
          final y = rx(10, h);
          final p = Path()
            ..moveTo(x, y)
            ..relativeLineTo(-2, -7)
            ..moveTo(x, y)
            ..relativeLineTo(1, -8)
            ..moveTo(x, y)
            ..relativeLineTo(4, -6);
          canvas.drawPath(p, stroke(const Color(0xFF5C7A45), 1.4));
        }
      case FightStage.dunes:
        for (var y = 30.0; y < h; y += 34) {
          final a = Path()
            ..moveTo(0, y)
            ..quadraticBezierTo(w * 0.25, y - 14, w * 0.5, y)
            ..quadraticBezierTo(w * 0.75, y + 14, w, y);
          canvas.drawPath(a, stroke(const Color(0xFFA98A4E), 2, 0.55));
          final b = Path()
            ..moveTo(0, y + 9)
            ..quadraticBezierTo(w * 0.25, y - 4, w * 0.5, y + 9)
            ..quadraticBezierTo(w * 0.75, y + 22, w, y + 9);
          canvas.drawPath(b, stroke(const Color(0xFFE6CF94), 2, 0.5));
        }
      case FightStage.saltFlats:
        for (var i = 0; i < 60; i++) {
          final p = Path()..moveTo(rx(0, w), rx(0, h));
          p.relativeLineTo(rx(-30, 30), rx(-30, 30));
          p.relativeLineTo(rx(-30, 30), rx(-20, 30));
          canvas.drawPath(p, stroke(const Color(0xFF9FA39A), 1.6));
        }
      case FightStage.waves:
        for (var y = 18.0; y < h; y += 26) {
          final p = Path()..moveTo(0, y);
          for (var k = 0; k < 4; k++) {
            p.relativeQuadraticBezierTo(w / 8, -10, w / 4, 0);
          }
          canvas.drawPath(p, stroke(const Color(0xFF8CC4D8), 2, 0.55));
        }
      case FightStage.ash:
        for (var i = 0; i < 14; i++) {
          final p = Path()
            ..moveTo(rx(0, w), rx(0, h))
            ..relativeLineTo(rx(-40, 40), rx(-10, 10));
          canvas.drawPath(p, stroke(const Color(0xFF12100F), 3));
        }
        for (var i = 0; i < 160; i++) {
          final c = [
            const Color(0xFFE0752B),
            const Color(0xFFF2A24A),
            const Color(0xFF5B5860)
          ][r.nextInt(3)];
          canvas.drawCircle(Offset(rx(0, w), rx(0, h)), rx(1, 2), fill(c, 0.7));
        }
      case FightStage.terraces:
        for (var i = 0; i < 5; i++) {
          final rect = Rect.fromLTWH(0, i * h / 5, w, h / 5);
          canvas.drawRect(
              rect,
              fill([
                const Color(0xFF7A776A),
                const Color(0xFF6C6A5E),
                const Color(0xFF827F70)
              ][i % 3]));
          canvas.drawRect(rect, stroke(const Color(0xFF3C3B34), 2));
        }
      case FightStage.cliffs:
        for (var i = 0; i < 24; i++) {
          final p = Path()
            ..moveTo(rx(0, w), rx(0, h))
            ..relativeLineTo(rx(-60, 60), rx(10, 60))
            ..relativeLineTo(rx(-40, 40), rx(10, 40));
          canvas.drawPath(p, stroke(const Color(0xFF2C2B30), 2.2));
          final q = Path()
            ..moveTo(rx(0, w), rx(0, h))
            ..relativeLineTo(rx(-50, 50), rx(10, 40));
          canvas.drawPath(q, stroke(const Color(0xFF7B7980), 1.5));
        }
      case FightStage.reeds:
        for (var i = 0; i < 7; i++) {
          canvas.drawOval(
              Rect.fromCenter(
                  center: Offset(rx(0, w), rx(0, h)),
                  width: rx(40, 100),
                  height: rx(16, 36)),
              fill(const Color(0xFF2C4A52), 0.7));
        }
        for (var i = 0; i < 60; i++) {
          final x = rx(5, w - 5);
          final y = rx(30, h);
          final p = Path()
            ..moveTo(x, y)
            ..relativeLineTo(-3, -22)
            ..moveTo(x, y)
            ..relativeLineTo(2, -26)
            ..moveTo(x, y)
            ..relativeLineTo(6, -18);
          canvas.drawPath(p, stroke(const Color(0xFF8A9A52), 1.6));
        }
      case FightStage.snow:
        for (var i = 0; i < 14; i++) {
          final c = Offset(rx(0, w), rx(0, h));
          canvas.drawOval(
              Rect.fromCenter(
                  center: c, width: rx(60, 140), height: rx(12, 28)),
              fill(Colors.white, 0.7));
          final p = Path()
            ..moveTo(c.dx, c.dy)
            ..relativeLineTo(rx(20, 50), 6);
          canvas.drawPath(p, stroke(const Color(0xFFB5C6D6), 2));
        }
      case FightStage.glass:
        for (var i = 0; i < 16; i++) {
          final p = Path()
            ..moveTo(rx(0, w), rx(0, h))
            ..lineTo(rx(0, w), rx(0, h))
            ..lineTo(rx(0, w), rx(0, h))
            ..close();
          canvas.drawPath(
              p,
              fill(
                  [
                    const Color(0xFF2B5A6A),
                    const Color(0xFF3A2F5E),
                    const Color(0xFF1F7A78)
                  ][r.nextInt(3)],
                  0.35));
          canvas.drawPath(p, stroke(const Color(0xFF9FE0E8), 1));
        }
      case FightStage.hall:
        final cell = Size(w / 6, h / 5);
        for (var row = 0; row < 5; row++) {
          for (var col = -1; col < 7; col++) {
            final x = col * cell.width + (row.isOdd ? cell.width / 2 : 0);
            final rect =
                Rect.fromLTWH(x, row * cell.height, cell.width, cell.height);
            canvas.drawRect(
                rect,
                fill([
                  const Color(0xFF5A4F42),
                  const Color(0xFF4F453A),
                  const Color(0xFF625648)
                ][r.nextInt(3)]));
            canvas.drawRect(rect, stroke(const Color(0xFF2A241D), 2));
          }
        }
    }
    // The edge falls into shadow, so the dice stand out in the middle.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.1),
          radius: 0.95,
          colors: [Color(0x00000000), Color(0xAA000000)],
          stops: [0.45, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  @override
  bool shouldRepaint(FightBoardPainter old) => old.stage != stage;
}

/// The board surface for [stage], with [child] (the dice) on it. Rounded and
/// clipped, so what plays on the board (a later event layer) never draws
/// outside it.
class FightBoardSurface extends StatelessWidget {
  const FightBoardSurface(
      {super.key, required this.stage, required this.child});

  final FightStage stage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4D5B4A), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                key: const Key('fight_board_skin'),
                painter: FightBoardPainter(stage),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// A curved line from the widget under [from] to the one under [to] (both
/// found by their keys, measured against [space], the Stack it is drawn in),
/// with [label] on it: the target of the selected die.
class FightAimLine extends StatefulWidget {
  const FightAimLine({
    super.key,
    required this.from,
    required this.to,
    required this.space,
    required this.color,
    this.label = '',
  });

  final GlobalKey from;
  final GlobalKey to;
  final GlobalKey space;
  final Color color;
  final String label;

  @override
  State<FightAimLine> createState() => _FightAimLineState();
}

class _FightAimLineState extends State<FightAimLine> {
  Offset? _a;
  Offset? _b;

  void _measure() {
    Offset? local(GlobalKey key, GlobalKey space, {required bool top}) {
      final box = key.currentContext?.findRenderObject();
      final root = space.currentContext?.findRenderObject();
      if (box is! RenderBox ||
          root is! RenderBox ||
          !box.hasSize ||
          !root.hasSize) {
        return null;
      }
      final center = box.localToGlobal(box.size.center(Offset.zero));
      final at = root.globalToLocal(center);
      return at;
    }

    final a = local(widget.from, widget.space, top: true);
    final b = local(widget.to, widget.space, top: false);
    if (a != _a || b != _b) {
      if (!mounted) return;
      setState(() {
        _a = a;
        _b = b;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final a = _a;
    final b = _b;
    if (a == null || b == null) return const SizedBox.shrink();
    final mid = Offset.lerp(a, b, 0.5)!;
    return IgnorePointer(
      child: Stack(
        key: const Key('fight_aim_line'),
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _AimPainter(a, b, widget.color)),
          ),
          if (widget.label.isNotEmpty)
            Positioned(
              left: mid.dx - 50,
              top: mid.dy - 11,
              width: 100,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xF015131A),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: widget.color),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    child: Text(widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AimPainter extends CustomPainter {
  const _AimPainter(this.a, this.b, this.color);

  final Offset a;
  final Offset b;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = Offset.lerp(a, b, 0.5)!;
    final bend = Offset((b.dy - a.dy).sign * 24, 0);
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(mid.dx + bend.dx, mid.dy, b.dx, b.dy);
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(a, 4, Paint()..color = color);
    canvas.drawCircle(b, 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_AimPainter old) =>
      old.a != a || old.b != b || old.color != color;
}
