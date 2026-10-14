// The side-view engine (docs/proposals/side-view-ux.md, I and L): a scene is
// a stack of layers painted back to front, each scrolling at its own share
// of the walk's (or the sail's) speed, with the weather's particles over the
// scene and nothing over the words around it. A kit (desert_kit.dart, and
// the sea's, later) is a list of layers; the engine only moves them.
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The scene's height in "pixels": every kit paints on this grid, scaled up
/// to the box, so the art stays chunky at any size.
const int sideViewRows = 72;

/// One layer of a scene. [speed] is its share of the scene's scroll (far
/// 0.15, mid 0.4, near 0.8, foreground 1.2); [paint] gets the canvas, the
/// box, the layer's own [scroll] in logical pixels, the time in seconds, and
/// the size of one scene pixel in logical pixels.
class SideLayer {
  const SideLayer(this.speed, this.paint);

  final double speed;
  final void Function(
      Canvas canvas, Size size, double scroll, double t, double unit) paint;
}

/// The weather's particles over a scene (the game's `WeatherKind`, plus the
/// place's own in clear weather).
enum SideParticles {
  none,

  /// A sandstorm: streaks of sand blown across, the scene tinted.
  dust,

  /// Heat shimmer: wavering light lines over the far ground.
  shimmer,
  rain,
  snow,
  ash,
  fog,

  /// Motes of light: leaves, fireflies, violet motes.
  motes,
}

/// A scene: [layers] back to front, the party's or ship's own [actors]
/// (painted still on the box, they bob rather than scroll), and the
/// [particles] over it all. [pace] is the scroll in logical pixels a second
/// at layer speed 1. With reduced motion the scene stands still.
class SideViewScene extends StatefulWidget {
  const SideViewScene({
    super.key,
    required this.layers,
    this.actors,
    this.particles = SideParticles.none,
    this.intensity = 1,
    this.pace = 40,
    this.moving = true,
    this.height = 190,
  });

  final List<SideLayer> layers;

  /// Painted over the layers, under the particles: speed 0.
  final SideLayer? actors;
  final SideParticles particles;

  /// 0 to 1: how much of the weather there is.
  final double intensity;
  final double pace;

  /// False when the party is still (a choice is being made).
  final bool moving;
  final double height;

  @override
  State<SideViewScene> createState() => _SideViewSceneState();
}

class _SideViewSceneState extends State<SideViewScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock =
      AnimationController(vsync: this, duration: const Duration(seconds: 3600));
  double _scroll = 0;
  double _lastT = 0;
  bool _started = false;

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    if (!still && !_started) {
      _started = true;
      _clock.forward();
    }
    if (still && _started) {
      _started = false;
      _clock.stop();
    }
    return SizedBox(
      height: widget.height,
      child: ClipRect(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _clock,
            builder: (context, _) {
              final t = still ? 1.3 : _clock.value * 3600;
              final dt = math.max(0.0, t - _lastT);
              _lastT = t;
              if (widget.moving && !still) _scroll += dt * widget.pace;
              return CustomPaint(
                painter: _ScenePainter(
                  layers: widget.layers,
                  actors: widget.actors,
                  particles: widget.particles,
                  intensity: widget.intensity,
                  scroll: still ? 0 : _scroll,
                  t: t,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.layers,
    required this.actors,
    required this.particles,
    required this.intensity,
    required this.scroll,
    required this.t,
  });

  final List<SideLayer> layers;
  final SideLayer? actors;
  final SideParticles particles;
  final double intensity;
  final double scroll;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.height / sideViewRows;
    for (final layer in layers) {
      layer.paint(canvas, size, scroll * layer.speed, t, unit);
    }
    actors?.paint(canvas, size, 0, t, unit);
    paintSideParticles(canvas, size, particles, intensity, t, unit);
  }

  @override
  bool shouldRepaint(_ScenePainter old) => true;
}

/// A rectangle on the scene's pixel grid: [x] and [y] in scene pixels from
/// the box's left and top, snapped to whole pixels.
void sidePixels(Canvas canvas, double unit, Paint paint, double x, double y,
    double w, double h) {
  canvas.drawRect(
      Rect.fromLTWH(
          (x).floorToDouble() * unit,
          (y).floorToDouble() * unit,
          math.max(1, w.roundToDouble()) * unit,
          math.max(1, h.roundToDouble()) * unit),
      paint);
}

/// Hills of the far ground as columns, one scene pixel wide: the top at
/// [base] scene pixels from the top, moved by [amp] along two slow waves of
/// the world position. A one-pixel [rim] colour lines the top.
void sideHills(
  Canvas canvas,
  Size size,
  double unit,
  double scroll, {
  required double base,
  required double amp,
  required double wave,
  required double phase,
  required Color fill,
  Color? rim,
}) {
  final cols = (size.width / unit).ceil() + 1;
  final fillPaint = Paint()..color = fill;
  final rimPaint = Paint()..color = rim ?? fill;
  final offset = scroll / unit;
  for (var i = 0; i < cols; i++) {
    final wx = (i + offset) * wave;
    final h = base +
        amp * math.sin(wx + phase) +
        amp * 0.45 * math.sin(wx * 2.3 + phase * 1.7);
    final top = h.roundToDouble();
    canvas.drawRect(
        Rect.fromLTWH(i * unit, top * unit, unit + 0.5, size.height),
        fillPaint);
    if (rim != null) {
      canvas.drawRect(
          Rect.fromLTWH(i * unit, top * unit, unit + 0.5, unit), rimPaint);
    }
  }
}

double _rand(int seed) {
  final x = math.sin(seed * 12.9898) * 43758.5453;
  return x - x.floorToDouble();
}

/// The weather over the scene: [intensity] 0 to 1.
void paintSideParticles(Canvas canvas, Size size, SideParticles kind,
    double intensity, double t, double unit) {
  if (kind == SideParticles.none || intensity <= 0) return;
  final w = size.width, h = size.height;
  switch (kind) {
    case SideParticles.dust:
      canvas.drawRect(
          Rect.fromLTWH(0, 0, w, h),
          Paint()
            ..color =
                const Color(0xFFD9A25E).withValues(alpha: 0.22 * intensity));
      final paint = Paint();
      final n = (70 * intensity).round();
      for (var i = 0; i < n; i++) {
        final speed = 120 + _rand(i + 1) * 220;
        final x = ((_rand(i + 7) * w - t * speed) % (w + 40)) - 20;
        final y = _rand(i + 31) * h;
        final len = (5 + _rand(i + 13) * 14).roundToDouble();
        paint.color = const Color(0xFFF0CE94)
            .withValues(alpha: 0.35 + 0.4 * _rand(i + 3));
        canvas.drawRect(
            Rect.fromLTWH((x / unit).floorToDouble() * unit,
                (y / unit).floorToDouble() * unit, len * unit * 0.6, unit),
            paint);
      }
    case SideParticles.shimmer:
      final paint = Paint()
        ..color = const Color(0xFFFFF2CC).withValues(alpha: 0.18 * intensity);
      final band = h * 0.50;
      for (var i = 0; i < 9; i++) {
        final y = band + i * unit * 2.4;
        final wob = math.sin(t * 1.6 + i * 1.3) * unit * 3;
        final x0 = ((_rand(i + 5) * w) + wob) % w;
        canvas.drawRect(
            Rect.fromLTWH(x0, (y / unit).floorToDouble() * unit,
                w * (0.18 + 0.2 * _rand(i + 9)), unit * 0.8),
            paint);
      }
    case SideParticles.rain:
      final paint = Paint()
        ..color = const Color(0xFFB7C7D8).withValues(alpha: 0.55);
      final n = (90 * intensity).round();
      for (var i = 0; i < n; i++) {
        final speed = 260 + _rand(i + 2) * 120;
        final x = (_rand(i + 5) * w - t * 40) % w;
        final y = ((_rand(i + 17) * h) + t * speed) % h;
        canvas.drawRect(
            Rect.fromLTWH((x / unit).floorToDouble() * unit,
                (y / unit).floorToDouble() * unit, unit, unit * 3),
            paint);
      }
    case SideParticles.snow:
      final paint = Paint()
        ..color = const Color(0xFFF4F8FF).withValues(alpha: 0.85);
      final n = (80 * intensity).round();
      for (var i = 0; i < n; i++) {
        final x = ((_rand(i + 5) * w) + math.sin(t + i) * 6 - t * 14) % w;
        final y = ((_rand(i + 17) * h) + t * (30 + _rand(i) * 30)) % h;
        canvas.drawRect(
            Rect.fromLTWH((x / unit).floorToDouble() * unit,
                (y / unit).floorToDouble() * unit, unit, unit),
            paint);
      }
    case SideParticles.ash:
      final paint = Paint()
        ..color = const Color(0xFF9A948C).withValues(alpha: 0.7);
      final n = (60 * intensity).round();
      for (var i = 0; i < n; i++) {
        final x =
            ((_rand(i + 5) * w) + math.sin(t * 0.7 + i) * 10 - t * 20) % w;
        final y = ((_rand(i + 17) * h) + t * (14 + _rand(i) * 20)) % h;
        canvas.drawRect(
            Rect.fromLTWH((x / unit).floorToDouble() * unit,
                (y / unit).floorToDouble() * unit, unit, unit),
            paint);
      }
    case SideParticles.fog:
      for (var i = 0; i < 4; i++) {
        final y = h * (0.35 + i * 0.16);
        final x = ((t * (6 + i * 3)) % (w * 1.4)) - w * 0.2;
        canvas.drawRect(
            Rect.fromLTWH(x - w * 0.4, y, w * 1.2, h * 0.14),
            Paint()
              ..color =
                  const Color(0xFFDDE3E1).withValues(alpha: 0.18 * intensity));
      }
    case SideParticles.motes:
      final paint = Paint();
      final n = (24 * intensity).round();
      for (var i = 0; i < n; i++) {
        final x = ((_rand(i + 5) * w) + math.sin(t * 0.5 + i) * 12) % w;
        final y = (_rand(i + 17) * h * 0.8) + math.cos(t * 0.6 + i * 2) * 6;
        final twinkle = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(t * 2 + i * 1.7));
        paint.color = const Color(0xFFFFF3B8).withValues(alpha: twinkle * 0.8);
        canvas.drawRect(
            Rect.fromLTWH((x / unit).floorToDouble() * unit,
                (y / unit).floorToDouble() * unit, unit, unit),
            paint);
      }
    case SideParticles.none:
      break;
  }
}
