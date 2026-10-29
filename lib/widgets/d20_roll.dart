// The d20 of a skill check (v1.309): drawn as bare lines, no panel behind
// it, it tumbles in perspective while its number flickers through other
// values, then lands on the roll -- the edge turning gold for a success or
// the error colour for a failure, a ring flashing out of it, a failure
// shuddering sideways. One reusable widget for every check: the Skill
// Challenge, a single ability check (see ability_roll_dialog.dart) and the
// land crossings' rolls.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/stitched_ink.dart';

/// How long the tumble lasts before the die lands: a d20 shown large takes
/// longer than a small die (see dieRollDuration in poly_die.dart).
const Duration d20RollDuration = Duration(milliseconds: 1500);

class D20Roll extends StatefulWidget {
  const D20Roll({
    super.key,
    this.roll,
    this.success,
    this.rollId = 0,
    this.size = 150,
    this.rolling = true,
    this.onLanded,
  });

  /// The number it lands on; null shows the resting die, a 20.
  final int? roll;

  /// How the roll went: shown on the edge once the die has landed.
  final bool? success;

  /// Bump to roll again to the same number (a new [roll] also rolls).
  final int rollId;
  final double size;

  /// False sets the die down on [roll] with no tumble.
  final bool rolling;

  /// Called when the die has landed.
  final VoidCallback? onLanded;

  @override
  State<D20Roll> createState() => _D20RollState();
}

class _D20RollState extends State<D20Roll> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: d20RollDuration)
        ..addStatusListener((s) {
          // Only a tumble lands: setting the die down at rest does not.
          if (s == AnimationStatus.completed && _tumbling) {
            _tumbling = false;
            widget.onLanded?.call();
          }
        });
  bool _tumbling = false;
  final math.Random _rng = math.Random();
  int _shown = 20;
  int _lastFlick = -1;

  @override
  void initState() {
    super.initState();
    _shown = widget.roll ?? 20;
    _c.value = 1;
    if (widget.rolling && widget.roll != null && !_reduced) _roll();
  }

  bool get _reduced => WidgetsBinding
      .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

  @override
  void didUpdateWidget(D20Roll old) {
    super.didUpdateWidget(old);
    if (widget.roll == null) {
      _tumbling = false;
      _c.value = 1;
      _shown = 20;
      return;
    }
    if (widget.roll != old.roll || widget.rollId != old.rollId) {
      if (widget.rolling && !_reduced) {
        _roll();
      } else {
        _c.value = 1;
        _shown = widget.roll!;
        widget.onLanded?.call();
      }
    }
  }

  void _roll() {
    _lastFlick = -1;
    _tumbling = true;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final size = widget.size;
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final landed = t >= 1;
            // The tumble: fast, slowing to rest.
            final e = Curves.easeOutCubic.transform(t);
            final left = 1 - e;
            final spin = left * math.pi * 5;
            final tipX = math.sin(t * 17) * 0.9 * left;
            final tipY = math.cos(t * 13) * 0.9 * left;
            // Up and down once, landing with a small bounce.
            final hop = math.sin(math.pi * math.min(1.0, t * 1.15)) * -0.18;
            final bounce =
                t > 0.8 ? math.sin((t - 0.8) / 0.2 * math.pi) * 0.07 : 0.0;
            final scale = 1 + bounce + (t < 1 ? 0.04 : 0);
            // A failure shudders sideways as it lands.
            final shake = widget.success == false && t > 0.82 && t < 1
                ? math.sin((t - 0.82) * 90) * size * 0.025 * (1 - t) * 6
                : 0.0;
            // The number flickers while it tumbles (every ~70 ms), then is the roll.
            final flick = (t * d20RollDuration.inMilliseconds / 70).floor();
            if (!landed && flick != _lastFlick) {
              _lastFlick = flick;
              _shown = 1 + _rng.nextInt(20);
            }
            final shownNow = landed
                ? (widget.roll ?? 20)
                : (t > 0.86 ? widget.roll ?? 20 : _shown);
            final result = landed ? widget.success : null;
            final edge = result == null
                ? ink.seam
                : result
                    ? ink.gold
                    : theme.colorScheme.error;
            final matrix = Matrix4.identity()
              ..setEntry(3, 2, 0.0014)
              ..translateByDouble(shake, hop * size, 0, 1)
              ..rotateX(tipX)
              ..rotateY(tipY)
              ..rotateZ(spin)
              ..scaleByDouble(scale, scale, 1, 1);
            return Stack(
              alignment: Alignment.center,
              children: [
                if (landed && result != null)
                  // The flash that leaves the die as it lands.
                  _Ring(color: edge, size: size),
                Transform(
                  alignment: Alignment.center,
                  transform: matrix,
                  child: CustomPaint(
                    size: Size.square(size),
                    painter: D20Painter(edge: edge, facet: ink.seam),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: size * 0.09),
                        child: Text(
                          widget.roll == null && !landed ? '20' : '$shownNow',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontSize: size * 0.24,
                            fontFamily: InkFonts.system,
                            fontWeight: FontWeight.w600,
                            color: widget.roll == null
                                ? ink.ash
                                : (result == null ? ink.ash : edge),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The ring that leaves a landed die: it widens and fades once.
class _Ring extends StatefulWidget {
  const _Ring({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<_Ring> createState() => _RingState();
}

class _RingState extends State<_Ring> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            size: Size.square(widget.size),
            painter: _RingPainter(widget.color, _c.value),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.color, this.t);
  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    canvas.drawCircle(
      size.center(Offset.zero),
      size.width * (0.42 + 0.3 * t),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - t) + 0.5
        ..color = color.withValues(alpha: 0.7 * (1 - t)),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t || old.color != color;
}

/// The d20's outline: a hexagon with its facets, lines only.
class D20Painter extends CustomPainter {
  const D20Painter({required this.edge, required this.facet});

  final Color edge;
  final Color facet;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    Offset p(double x, double y) => Offset(x * w / 170, y * h / 170);
    final hex = Path()
      ..moveTo(p(85, 6).dx, p(85, 6).dy)
      ..lineTo(p(158, 48).dx, p(158, 48).dy)
      ..lineTo(p(158, 122).dx, p(158, 122).dy)
      ..lineTo(p(85, 164).dx, p(85, 164).dy)
      ..lineTo(p(12, 122).dx, p(12, 122).dy)
      ..lineTo(p(12, 48).dx, p(12, 48).dy)
      ..close();
    final facetPaint = Paint()
      ..color = facet
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final tri = Path()
      ..moveTo(p(85, 34).dx, p(85, 34).dy)
      ..lineTo(p(134, 112).dx, p(134, 112).dy)
      ..lineTo(p(36, 112).dx, p(36, 112).dy)
      ..close();
    canvas.drawPath(tri, facetPaint);
    for (final (a, b) in [
      ((85.0, 6.0), (85.0, 34.0)),
      ((158.0, 48.0), (134.0, 112.0)),
      ((12.0, 48.0), (36.0, 112.0)),
      ((85.0, 164.0), (36.0, 112.0)),
      ((85.0, 164.0), (134.0, 112.0)),
      ((158.0, 122.0), (134.0, 112.0)),
      ((12.0, 122.0), (36.0, 112.0)),
      ((12.0, 48.0), (85.0, 34.0)),
      ((158.0, 48.0), (85.0, 34.0)),
    ]) {
      canvas.drawLine(p(a.$1, a.$2), p(b.$1, b.$2), facetPaint);
    }
    canvas.drawPath(
        hex,
        Paint()
          ..color = edge
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(D20Painter old) => old.edge != edge || old.facet != facet;
}
