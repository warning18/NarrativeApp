import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../combat/skill_vfx.dart';

/// What a floating number says, which sets its color.
enum VfxTextKind { damage, hurt, heal, block, mana, crit, info }

/// One effect in flight: a [VfxStyle] played on [target] (and, for the
/// travelling styles, from [source]), with an optional floating [text].
/// Anchors are the widgets' [GlobalKey]s, resolved at every frame so an
/// effect follows its card; the rects captured when it was played stand
/// in if a card is gone.
class VfxBurst {
  VfxBurst({
    required this.style,
    required this.palette,
    required this.target,
    this.source,
    this.targetFallback,
    this.sourceFallback,
    this.delay = Duration.zero,
    this.text,
    this.textKind = VfxTextKind.info,
    this.big = false,
    required this.seed,
  })  : durationMs = vfxDurationMs(style),
        particles = _makeParticles(seed);

  final VfxStyle style;
  final VfxPalette palette;
  final GlobalKey target;
  final GlobalKey? source;
  final Rect? targetFallback;
  final Rect? sourceFallback;
  final Duration delay;
  final String? text;
  final VfxTextKind textKind;
  final bool big;
  final int seed;
  final int durationMs;
  final List<VfxParticle> particles;

  /// Set when the layer takes the burst: the layer clock's time it starts.
  Duration? startAt;

  /// How long the burst stays on screen: its style, then its number.
  int get lifeMs => durationMs + (text == null ? 0 : _textExtraMs);

  static const int _textExtraMs = 350;
}

/// One particle's fixed traits, drawn when a burst is made.
class VfxParticle {
  const VfxParticle(
      this.angle, this.speed, this.size, this.delay, this.spin, this.dx);
  final double angle;
  final double speed;
  final double size;
  final double delay;
  final double spin;
  final double dx;
}

List<VfxParticle> _makeParticles(int seed) {
  final random = Random(seed);
  return [
    for (var i = 0; i < 24; i++)
      VfxParticle(
        random.nextDouble() * pi * 2,
        0.45 + random.nextDouble() * 0.55,
        0.5 + random.nextDouble() * 0.5,
        random.nextDouble() * 0.2,
        random.nextDouble() * 2 - 1,
        random.nextDouble() * 2 - 1,
      ),
  ];
}

/// Queues effects for a [CombatVfxLayer] to play.
class CombatVfxController extends ChangeNotifier {
  final List<VfxBurst> _queue = [];
  int _seed = 1;

  /// Plays [style] on [target] after [delayMs], in [element]'s colors.
  void play({
    required VfxStyle style,
    required GlobalKey target,
    GlobalKey? source,
    String element = 'None',
    int delayMs = 0,
    String? text,
    VfxTextKind textKind = VfxTextKind.info,
    bool big = false,
  }) {
    _queue.add(VfxBurst(
      style: style,
      palette: paletteFor(style, element),
      target: target,
      source: source,
      targetFallback: globalRectOf(target),
      sourceFallback: source == null ? null : globalRectOf(source),
      delay: Duration(milliseconds: max(0, delayMs)),
      text: text,
      textKind: textKind,
      big: big,
      seed: _seed++ * 7919,
    ));
    notifyListeners();
  }

  /// Hands the queued bursts to the layer.
  List<VfxBurst> takeQueued() {
    final queued = List<VfxBurst>.of(_queue);
    _queue.clear();
    return queued;
  }
}

/// [key]'s widget rect in global coordinates, or null when it is not laid
/// out.
Rect? globalRectOf(GlobalKey key) {
  final box = key.currentContext?.findRenderObject();
  if (box is RenderBox && box.attached && box.hasSize) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  return null;
}

/// The overlay that draws the bursts: sits over the battle, ignores
/// touches, and ticks only while something is playing. With
/// [reducedMotion] it draws the numbers alone, where they land, without
/// particles or motion.
class CombatVfxLayer extends StatefulWidget {
  const CombatVfxLayer({
    super.key,
    required this.controller,
    this.reducedMotion = false,
  });

  final CombatVfxController controller;
  final bool reducedMotion;

  @override
  State<CombatVfxLayer> createState() => _CombatVfxLayerState();
}

class _CombatVfxLayerState extends State<CombatVfxLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<Duration> _clock = ValueNotifier(Duration.zero);
  final List<VfxBurst> _active = [];
  final GlobalKey _boxKey = GlobalKey();
  Duration _base = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    widget.controller.addListener(_onQueued);
  }

  @override
  void didUpdateWidget(CombatVfxLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onQueued);
      widget.controller.addListener(_onQueued);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onQueued);
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _onQueued() {
    final queued = widget.controller.takeQueued();
    if (queued.isEmpty) return;
    for (final burst in queued) {
      burst.startAt = _clock.value + burst.delay;
      _active.add(burst);
    }
    if (!_ticker.isActive) {
      _base = _clock.value;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final now = _base + elapsed;
    _active.removeWhere(
        (b) => now > b.startAt! + Duration(milliseconds: b.lifeMs));
    _clock.value = now;
    if (_active.isEmpty) _ticker.stop();
  }

  Rect? _localRect(GlobalKey key, Rect? fallbackGlobal) {
    final layer = _boxKey.currentContext?.findRenderObject();
    if (layer is! RenderBox || !layer.attached || !layer.hasSize) return null;
    final global = globalRectOf(key) ?? fallbackGlobal;
    if (global == null) return null;
    final topLeft = layer.globalToLocal(global.topLeft);
    return topLeft & global.size;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      key: _boxKey,
      child: CustomPaint(
        painter: _VfxPainter(
          bursts: _active,
          clock: _clock,
          resolve: _localRect,
          reducedMotion: widget.reducedMotion,
        ),
      ),
    );
  }
}

typedef _Resolve = Rect? Function(GlobalKey key, Rect? fallbackGlobal);

class _VfxPainter extends CustomPainter {
  _VfxPainter({
    required this.bursts,
    required this.clock,
    required this.resolve,
    required this.reducedMotion,
  }) : super(repaint: clock);

  final List<VfxBurst> bursts;
  final ValueNotifier<Duration> clock;
  final _Resolve resolve;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final now = clock.value;
    for (final burst in bursts) {
      final start = burst.startAt;
      if (start == null || now < start) continue;
      final elapsedMs = (now - start).inMicroseconds / 1000.0;
      final target = resolve(burst.target, burst.targetFallback);
      if (target == null) continue;
      final source = burst.source == null
          ? null
          : resolve(burst.source!, burst.sourceFallback);
      final t = elapsedMs / burst.durationMs;
      if (!reducedMotion && t <= 1) {
        _Fx(canvas, burst, target, source, t.clamp(0.0, 1.0)).paint();
      }
      if (burst.text != null) {
        _paintText(
            canvas, burst, target, (elapsedMs / burst.lifeMs).clamp(0.0, 1.0));
      }
    }
  }

  void _paintText(Canvas canvas, VfxBurst burst, Rect target, double t) {
    final color = Color(_textColor(burst.textKind));
    final opacity = t < 0.7 ? 1.0 : max(0.0, 1 - (t - 0.7) / 0.3);
    final painter = TextPainter(
      text: TextSpan(
        text: burst.text,
        style: TextStyle(
          fontSize: burst.big || burst.textKind == VfxTextKind.crit ? 22 : 17,
          fontWeight: FontWeight.w900,
          color: color.withValues(alpha: opacity),
          shadows: [
            Shadow(
              blurRadius: 4,
              color: Colors.black.withValues(alpha: 0.8 * opacity),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final jitter = burst.particles.first.dx * 14;
    final rise = reducedMotion ? 0.0 : 34 * _easeOut(t);
    final offset = Offset(
      target.center.dx - painter.width / 2 + jitter,
      target.top + target.height * 0.3 - painter.height / 2 - rise,
    );
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _VfxPainter oldDelegate) => true;
}

int _textColor(VfxTextKind kind) {
  switch (kind) {
    case VfxTextKind.damage:
      return 0xFFFFF3E0;
    case VfxTextKind.hurt:
      return 0xFFFF5252;
    case VfxTextKind.heal:
      return 0xFF69F0AE;
    case VfxTextKind.block:
      return 0xFF82B1FF;
    case VfxTextKind.mana:
      return 0xFFB388FF;
    case VfxTextKind.crit:
      return 0xFFFFD740;
    case VfxTextKind.info:
      return 0xFFE0E0E0;
  }
}

double _easeOut(double t) => 1 - pow(1 - t.clamp(0.0, 1.0), 3).toDouble();
double _easeInOut(double t) {
  final x = t.clamp(0.0, 1.0);
  return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2;
}

/// Opacity that fades in over [fadeIn] and out from [fadeOutStart].
double _fade(double t, [double fadeIn = 0.1, double fadeOutStart = 0.55]) {
  if (t <= 0 || t >= 1) return 0;
  if (t < fadeIn) return t / fadeIn;
  if (t > fadeOutStart) {
    return max(0, 1 - (t - fadeOutStart) / (1 - fadeOutStart));
  }
  return 1;
}

/// Progress of the window [t0, t0 + span] at [t], or null outside it.
double? _window(double t, double t0, double span) {
  if (t < t0 || t > t0 + span) return null;
  return (t - t0) / span;
}

/// One burst's drawing at progress [t].
class _Fx {
  _Fx(this.canvas, this.burst, this.rect, this.sourceRect, this.t)
      : c = rect.center,
        s = min(rect.width, rect.height).clamp(40.0, 110.0).toDouble(),
        primary = Color(burst.palette.primary),
        secondary = Color(burst.palette.secondary);

  final Canvas canvas;
  final VfxBurst burst;
  final Rect rect;
  final Rect? sourceRect;
  final double t;
  final Offset c;
  final double s;
  final Color primary;
  final Color secondary;

  List<VfxParticle> get p => burst.particles;
  double get scale => burst.big ? 1.35 : 1.0;

  Paint _fill(Color color, double opacity) => Paint()
    ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0))
    ..style = PaintingStyle.fill;

  Paint _stroke(Color color, double opacity, double width) => Paint()
    ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0))
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(0.5, width)
    ..strokeCap = StrokeCap.round;

  /// Where a travelling style starts: its source's center, or off to the
  /// upper left of the target when it has none.
  Offset get _from =>
      sourceRect?.center ?? Offset(rect.left - s * 1.2, c.dy - s * 0.8);

  void paint() {
    switch (burst.style) {
      case VfxStyle.slash:
        _slash(0, 1);
        _sparks(0.15, 0.5, count: 8, reach: 0.6);
      case VfxStyle.heavySlash:
        _slash(0, 1, width: 0.11);
        _slash(0.12, -1, width: 0.11);
        _ring(0.2, 0.5, s * 0.1, s * 0.9, width: 5);
        _sparks(0.2, 0.6, count: 14, reach: 0.9);
      case VfxStyle.pierce:
        _pierce();
      case VfxStyle.whirl:
        _whirl();
      case VfxStyle.claw:
        _claw();
      case VfxStyle.impact:
        _impact();
      case VfxStyle.arrow:
        _arrow(_from, c, 0, 0.45);
        _sparks(0.45, 0.45, count: 8, reach: 0.5);
      case VfxStyle.volley:
        _volley();
      case VfxStyle.bolt:
        _orb(0, 0.45, radius: 0.1, trail: true);
        _jitterBolts(0.45, 0.4);
        _sparks(0.45, 0.5, count: 14, reach: 0.9);
        _ring(0.45, 0.45, s * 0.1, s * 0.8, width: 3);
      case VfxStyle.lightning:
        _lightning();
      case VfxStyle.flame:
        _glow(c, s * 0.6, 0, 0.5, secondary);
        _rise(0, 1, count: 20, height: 1.0, width: 0.45, sizeK: 0.12);
      case VfxStyle.fireball:
        _orb(0, 0.45, radius: 0.16, trail: true);
        _explosion(0.45, 0.55, reach: 1.0);
      case VfxStyle.meteor:
        _meteor();
      case VfxStyle.holyFire:
        _beam(0, 0.5, width: 0.3);
        _rise(0.35, 0.65, count: 16, height: 0.9, width: 0.4, sizeK: 0.1);
      case VfxStyle.frost:
        _shards();
        _ring(0, 0.6, s * 0.1, s * 0.95, width: 3, color: secondary);
        _glow(c, s * 0.5, 0, 0.4, primary);
      case VfxStyle.splash:
        _droplets();
        _ellipseRing(0.05, 0.6);
      case VfxStyle.poison:
        _cloud();
        _bubbles();
      case VfxStyle.smoke:
        _smoke();
      case VfxStyle.wind:
        _gusts();
      case VfxStyle.quake:
        _quake();
      case VfxStyle.voidRift:
        _voidRift();
      case VfxStyle.drain:
        _drain();
      case VfxStyle.shadow:
        _shadow();
      case VfxStyle.radiance:
        _beam(0, 0.7, width: 0.5);
        _twinkles(0.2, 0.8);
        _ring(0.3, 0.6, s * 0.2, s * 0.9, width: 3, color: secondary);
      case VfxStyle.heal:
        _glow(c, s * 0.7, 0, 0.8, primary);
        _pluses();
        _twinkles(0.1, 0.8, color: secondary);
      case VfxStyle.shield:
        _shieldOutline(stone: false);
      case VfxStyle.stoneShield:
        _shieldOutline(stone: true);
      case VfxStyle.mana:
        _spiralIn(0, 0.8, count: 18);
        _glow(c, s * 0.5, 0.55, 0.45, primary);
      case VfxStyle.shout:
        _shout();
      case VfxStyle.stun:
        _stars();
      case VfxStyle.weaken:
        _chevrons();
      case VfxStyle.crit:
        _crit();
      case VfxStyle.miss:
        _smoke(count: 4, reach: 0.35);
      case VfxStyle.phase:
        _glow(c, s * 1.1, 0, 0.5, primary);
        _ring(0, 0.6, s * 0.2, s * 1.6, width: 7);
        _ring(0.25, 0.6, s * 0.2, s * 1.6, width: 5, color: secondary);
    }
  }

  // --- Building blocks ------------------------------------------------------

  void _glow(Offset at, double radius, double t0, double span, Color color) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    final opacity = _fade(lt, 0.2, 0.3) * 0.55;
    final r = radius * scale * (0.6 + 0.4 * _easeOut(lt));
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..shader = ui.Gradient.radial(at, r, [
          color.withValues(alpha: opacity),
          color.withValues(alpha: 0),
        ]),
    );
  }

  void _ring(double t0, double span, double r0, double r1,
      {double width = 3, Color? color}) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    final r = (r0 + (r1 - r0) * _easeOut(lt)) * scale;
    canvas.drawCircle(
        c, r, _stroke(color ?? primary, 1 - lt, width * (1 - lt) + 0.5));
  }

  void _sparks(double t0, double span,
      {int count = 12, double reach = 0.8, Offset? at, Color? color}) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    final origin = at ?? c;
    for (var i = 0; i < count; i++) {
      final q = p[i % p.length];
      final local = ((lt - q.delay) / (1 - q.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final dist = s * reach * scale * q.speed * _easeOut(local);
      final dir = Offset(cos(q.angle), sin(q.angle));
      final head = origin + dir * dist;
      final tail = origin + dir * max(0.0, dist - s * 0.12);
      canvas.drawLine(
        tail,
        head,
        _stroke(i.isEven ? (color ?? primary) : secondary, 1 - local,
            s * 0.035 * q.size),
      );
    }
  }

  /// A curved blade stroke across the target, drawn on then fading.
  /// [dir] 1 runs top-left to bottom-right, -1 the mirror.
  void _slash(double t0, int dir, {double width = 0.07}) {
    final lt = _window(t, t0, 0.75);
    if (lt == null) return;
    final reveal = (lt / 0.35).clamp(0.0, 1.0);
    final opacity = lt < 0.35 ? 1.0 : max(0.0, 1 - (lt - 0.35) / 0.65);
    final a = Offset(c.dx - dir * s * 0.65, c.dy - s * 0.5);
    final b = Offset(c.dx + dir * s * 0.65, c.dy + s * 0.5);
    final ctrl = Offset(c.dx + dir * s * 0.4, c.dy - s * 0.35);
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
    final partial = _partial(path, reveal);
    canvas.drawPath(partial, _stroke(primary, opacity, s * width * scale));
    canvas.drawPath(
        partial, _stroke(Colors.white, opacity, s * width * 0.35 * scale));
  }

  Path _partial(Path path, double fraction) {
    final out = Path();
    for (final metric in path.computeMetrics()) {
      out.addPath(metric.extractPath(0, metric.length * fraction), Offset.zero);
    }
    return out;
  }

  void _pierce() {
    final lt = _window(t, 0, 0.35);
    const dir = Offset(0.95, -0.3);
    if (lt != null) {
      final head = c + dir * (s * 0.15) - dir * (s * 0.9) * (1 - _easeOut(lt));
      final tail = head - dir * (s * 0.7);
      canvas.drawLine(tail, head, _stroke(primary, 1, s * 0.05 * scale));
      canvas.drawLine(tail, head, _stroke(Colors.white, 1, s * 0.02 * scale));
    }
    _sparks(0.25, 0.6, count: 10, reach: 0.6);
    _ring(0.25, 0.5, s * 0.05, s * 0.5, width: 3);
  }

  void _whirl() {
    final lt = _window(t, 0, 1);
    if (lt == null) return;
    final opacity = _fade(lt, 0.1, 0.6);
    final r = s * 0.55 * scale;
    for (var i = 0; i < 3; i++) {
      final start = lt * pi * 3 + i * (2 * pi / 3);
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, pi * 0.45,
          false, _stroke(primary, opacity, s * 0.06));
      canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.8), start + 0.4,
          pi * 0.3, false, _stroke(secondary, opacity, s * 0.03));
    }
    _sparks(0.3, 0.6, count: 10, reach: 0.9);
  }

  void _claw() {
    for (var i = 0; i < 3; i++) {
      final lt = _window(t, i * 0.06, 0.7);
      if (lt == null) continue;
      final reveal = (lt / 0.3).clamp(0.0, 1.0);
      final opacity = lt < 0.3 ? 1.0 : max(0.0, 1 - (lt - 0.3) / 0.7);
      final off = Offset((i - 1) * s * 0.2, (i - 1) * -s * 0.05);
      final a = c + off + Offset(s * 0.45, -s * 0.5);
      final b = c + off + Offset(-s * 0.35, s * 0.5);
      final head = Offset.lerp(a, b, reveal)!;
      canvas.drawLine(a, head, _stroke(primary, opacity, s * 0.06 * scale));
      canvas.drawLine(
          a, head, _stroke(Colors.white, opacity, s * 0.02 * scale));
    }
  }

  void _impact() {
    _glow(c, s * 0.7, 0, 0.35, Colors.white);
    _ring(0, 0.6, s * 0.1, s * 1.0, width: 6);
    final lt = _window(t, 0, 0.5);
    if (lt == null) return;
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4 + p[0].angle;
      final dir = Offset(cos(angle), sin(angle));
      final inner = c + dir * (s * (0.25 + 0.5 * _easeOut(lt)));
      final outer = inner + dir * (s * 0.2 * (1 - lt));
      canvas.drawLine(inner, outer, _stroke(secondary, 1 - lt, s * 0.04));
    }
  }

  void _arrow(Offset from, Offset to, double t0, double span) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    final pos = Offset.lerp(from, to, _easeInOut(lt))!;
    final delta = to - from;
    final dir =
        delta.distance == 0 ? const Offset(1, 0) : delta / delta.distance;
    final tail = pos - dir * (s * 0.4);
    canvas.drawLine(tail, pos, _stroke(secondary, 1, s * 0.03));
    final normal = Offset(-dir.dy, dir.dx);
    final head = Path()
      ..moveTo(pos.dx + dir.dx * s * 0.1, pos.dy + dir.dy * s * 0.1)
      ..lineTo(pos.dx + normal.dx * s * 0.05, pos.dy + normal.dy * s * 0.05)
      ..lineTo(pos.dx - normal.dx * s * 0.05, pos.dy - normal.dy * s * 0.05)
      ..close();
    canvas.drawPath(head, _fill(primary, 1));
    canvas.drawLine(tail, tail - dir * (s * 0.08) + normal * (s * 0.05),
        _stroke(primary, 1, s * 0.025));
  }

  void _volley() {
    for (var i = 0; i < 5; i++) {
      final from = Offset(c.dx - s * 1.4 + i * s * 0.22, rect.top - s * 1.3);
      final to =
          Offset(c.dx + (i - 2) * s * 0.2, c.dy + (i.isEven ? 0 : s * 0.12));
      final t0 = i * 0.07;
      _arrow(from, to, t0, 0.4);
      _sparks(t0 + 0.4, 0.35, count: 5, reach: 0.35, at: to);
    }
  }

  void _orb(double t0, double span,
      {double radius = 0.12, bool trail = false}) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    final from = _from;
    final pos = Offset.lerp(from, c, _easeInOut(lt))!;
    if (trail) {
      for (var i = 0; i < 8; i++) {
        final back = (lt - i * 0.05).clamp(0.0, 1.0);
        final at = Offset.lerp(from, c, _easeInOut(back))!;
        canvas.drawCircle(at, s * radius * (1 - i / 9) * scale,
            _fill(i.isEven ? primary : secondary, 0.35 * (1 - i / 8)));
      }
    }
    _glowAt(pos, s * radius * 2.4 * scale, primary, 0.6);
    canvas.drawCircle(pos, s * radius * scale, _fill(primary, 1));
    canvas.drawCircle(pos, s * radius * 0.5 * scale, _fill(secondary, 1));
  }

  void _glowAt(Offset at, double r, Color color, double opacity) {
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..shader = ui.Gradient.radial(at, r, [
          color.withValues(alpha: opacity),
          color.withValues(alpha: 0),
        ]),
    );
  }

  void _explosion(double t0, double span, {double reach = 1.0}) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    _glowAt(c, s * reach * scale * (0.5 + 0.6 * _easeOut(lt)), secondary,
        0.7 * (1 - lt));
    _sparks(t0, span, count: 18, reach: reach);
    _ring(t0, span, s * 0.1, s * reach, width: 5);
    _rise(t0 + span * 0.2, span * 0.8,
        count: 12, height: 0.8, width: 0.5, sizeK: 0.08);
  }

  void _meteor() {
    final lt = _window(t, 0, 0.4);
    if (lt != null) {
      final from = Offset(c.dx + s * 1.3, rect.top - s * 2.2);
      final pos = Offset.lerp(from, c, lt * lt)!;
      for (var i = 0; i < 10; i++) {
        final back = (lt - i * 0.035).clamp(0.0, 1.0);
        final at = Offset.lerp(from, c, back * back)!;
        canvas.drawCircle(at, s * 0.14 * (1 - i / 11) * scale,
            _fill(i < 3 ? secondary : primary, 0.6 * (1 - i / 10)));
      }
      canvas.drawCircle(
          pos, s * 0.15 * scale, _fill(const Color(0xFF4E342E), 1));
      canvas.drawCircle(pos, s * 0.15 * scale, _stroke(primary, 1, s * 0.03));
    }
    _explosion(0.4, 0.6, reach: 1.4);
    _quakeRocks(0.4, 0.6);
  }

  void _jitterBolts(double t0, double span) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    for (var i = 0; i < 4; i++) {
      final q = p[i];
      final dir = Offset(cos(q.angle), sin(q.angle));
      final path = Path()..moveTo(c.dx, c.dy);
      var at = c;
      for (var k = 0; k < 4; k++) {
        at = at +
            dir * (s * 0.12) +
            Offset(-dir.dy, dir.dx) * (s * 0.06 * (k.isEven ? 1 : -1));
        path.lineTo(at.dx, at.dy);
      }
      canvas.drawPath(path, _stroke(secondary, 1 - lt, s * 0.025));
    }
  }

  void _lightning() {
    final lt = _window(t, 0, 0.5);
    if (lt != null && ((lt * 12).floor().isEven || lt < 0.15)) {
      final top = Offset(c.dx + s * 0.25, rect.top - s * 1.1);
      final path = Path()..moveTo(top.dx, top.dy);
      const segments = 7;
      for (var i = 1; i <= segments; i++) {
        final f = i / segments;
        final base = Offset.lerp(top, c, f)!;
        final wobble = i == segments ? 0.0 : p[i].dx * s * 0.22;
        path.lineTo(base.dx + wobble, base.dy);
      }
      canvas.drawPath(path, _stroke(primary, 1 - lt * 0.5, s * 0.08 * scale));
      canvas.drawPath(path, _stroke(Colors.white, 1, s * 0.03 * scale));
    }
    _glow(c, s * 0.9, 0.05, 0.5, secondary);
    _sparks(0.2, 0.6, count: 14, reach: 0.9, color: secondary);
  }

  void _beam(double t0, double span, {double width = 0.35}) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    final opacity = _fade(lt, 0.2, 0.5);
    final w = s * width * scale * (0.6 + 0.4 * sin(pi * lt));
    // From a little above the target, not the top of the screen: the
    // beam falls on the card without slicing through the dice tray.
    final top = max(0.0, rect.top - s * 2.2);
    final beam = Rect.fromLTRB(c.dx - w / 2, top, c.dx + w / 2, c.dy + s * 0.2);
    canvas.drawRect(
      beam,
      Paint()
        ..shader = ui.Gradient.linear(beam.topCenter, beam.bottomCenter, [
          secondary.withValues(alpha: 0),
          secondary.withValues(alpha: 0.6 * opacity),
          primary.withValues(alpha: 0.9 * opacity),
        ], const [
          0,
          0.6,
          1,
        ]),
    );
    _glowAt(c, s * 0.8 * scale, primary, 0.5 * opacity);
  }

  void _rise(double t0, double span,
      {int count = 16,
      double height = 1.0,
      double width = 0.4,
      double sizeK = 0.1}) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    for (var i = 0; i < count; i++) {
      final q = p[i % p.length];
      final local = ((lt - q.delay) / (1 - q.delay)).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final x = c.dx + q.dx * s * width + sin(local * 6 + q.angle) * s * 0.05;
      final y = c.dy + s * 0.35 - local * s * height * q.speed * scale;
      final color = Color.lerp(primary, secondary, local)!;
      canvas.drawCircle(Offset(x, y), s * sizeK * q.size * (1 - local) * scale,
          _fill(color, 0.9 * (1 - local)));
    }
  }

  void _shards() {
    final lt = _window(t, 0, 0.75);
    if (lt == null) return;
    for (var i = 0; i < 12; i++) {
      final q = p[i];
      final dist = s * 0.95 * q.speed * _easeOut(lt) * scale;
      final pos = c + Offset(cos(q.angle), sin(q.angle)) * dist;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(q.angle + lt * q.spin * 4);
      final k = s * 0.09 * q.size;
      final shard = Path()
        ..moveTo(k * 1.4, 0)
        ..lineTo(-k * 0.5, k * 0.45)
        ..lineTo(-k * 0.5, -k * 0.45)
        ..close();
      canvas.drawPath(shard, _fill(i.isEven ? primary : secondary, 1 - lt));
      canvas.restore();
    }
  }

  void _droplets() {
    final lt = _window(t, 0, 0.9);
    if (lt == null) return;
    for (var i = 0; i < 14; i++) {
      final q = p[i];
      final local =
          ((lt - q.delay * 0.5) / (1 - q.delay * 0.5)).clamp(0.0, 1.0);
      final x = c.dx + q.dx * s * 0.8 * local;
      final y = c.dy - s * 1.3 * q.speed * local + s * 1.8 * local * local;
      canvas.drawCircle(Offset(x, y), s * 0.045 * q.size * scale,
          _fill(i.isEven ? primary : secondary, 1 - local));
    }
  }

  void _ellipseRing(double t0, double span) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    final w = s * 1.4 * _easeOut(lt) * scale;
    canvas.drawOval(
        Rect.fromCenter(
            center: c + Offset(0, s * 0.25), width: w, height: w * 0.3),
        _stroke(primary, 1 - lt, 3));
  }

  void _cloud() {
    final lt = _window(t, 0, 1);
    if (lt == null) return;
    for (var i = 0; i < 4; i++) {
      final q = p[i];
      final at = c + Offset(q.dx * s * 0.35, q.spin * s * 0.2);
      canvas.drawCircle(at, s * (0.25 + 0.3 * _easeOut(lt)) * scale,
          _fill(primary, 0.22 * _fade(lt, 0.15, 0.5)));
    }
  }

  void _bubbles() {
    final lt = _window(t, 0, 1);
    if (lt == null) return;
    for (var i = 0; i < 12; i++) {
      final q = p[i];
      final local = ((lt - q.delay) / (1 - q.delay)).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final x = c.dx + q.dx * s * 0.45 + sin(local * 8 + q.angle) * s * 0.04;
      final y = c.dy + s * 0.3 - local * s * 0.9 * q.speed;
      final r = s * 0.06 * q.size * (0.6 + local) * scale;
      canvas.drawCircle(Offset(x, y), r, _stroke(secondary, 1 - local, 1.5));
      canvas.drawCircle(
          Offset(x, y), r * 0.7, _fill(primary, 0.5 * (1 - local)));
    }
  }

  void _smoke({int count = 7, double reach = 0.55}) {
    final lt = _window(t, 0, 1);
    if (lt == null) return;
    for (var i = 0; i < count; i++) {
      final q = p[i];
      final at =
          c + Offset(q.dx * s * reach, q.spin * s * reach * 0.6) * _easeOut(lt);
      canvas.drawCircle(at, s * (0.15 + 0.3 * _easeOut(lt)) * q.size * scale,
          _fill(i.isEven ? primary : secondary, 0.45 * (1 - lt)));
    }
  }

  void _gusts() {
    for (var i = 0; i < 3; i++) {
      final lt = _window(t, i * 0.08, 0.75);
      if (lt == null) continue;
      final y = c.dy + (i - 1) * s * 0.28;
      final path = Path()
        ..moveTo(rect.left - s * 0.3, y + s * 0.15)
        ..cubicTo(c.dx - s * 0.3, y - s * 0.25, c.dx + s * 0.3, y + s * 0.25,
            rect.right + s * 0.3, y - s * 0.1);
      final metric = path.computeMetrics().first;
      final head = metric.length * _easeOut(lt);
      final tail = max(0.0, head - metric.length * 0.45);
      canvas.drawPath(metric.extractPath(tail, head),
          _stroke(i == 1 ? secondary : primary, 1 - lt * 0.6, s * 0.035));
    }
    _sparks(0.2, 0.7, count: 6, reach: 0.9, color: secondary);
  }

  void _quake() {
    final lt = _window(t, 0, 0.7);
    if (lt != null) {
      final y = rect.bottom - s * 0.1;
      final path = Path()..moveTo(rect.left + 4, y);
      const steps = 10;
      for (var i = 1; i <= steps; i++) {
        final x = rect.left +
            4 +
            (rect.width - 8) * i / steps * _easeOut(lt * 1.6).clamp(0.0, 1.0);
        path.lineTo(x, y + (i.isEven ? -1 : 1) * s * 0.05 * p[i].size);
      }
      canvas.drawPath(path, _stroke(primary, 1 - lt, s * 0.04));
    }
    _quakeRocks(0, 0.9);
    _smoke(count: 4, reach: 0.4);
  }

  void _quakeRocks(double t0, double span) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    for (var i = 0; i < 10; i++) {
      final q = p[i + 4];
      final x = c.dx + q.dx * s * 0.6;
      final y =
          rect.bottom - s * 0.1 - s * 1.1 * q.speed * lt + s * 1.6 * lt * lt;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(q.spin * lt * 6);
      final k = s * 0.07 * q.size * scale;
      canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: k, height: k * 0.8),
          _fill(i.isEven ? primary : secondary, 1 - lt));
      canvas.restore();
    }
  }

  void _voidRift() {
    final lt = _window(t, 0, 1);
    if (lt == null) return;
    final open = sin(pi * lt);
    final h = s * 1.1 * scale;
    final w = s * 0.28 * open * scale;
    final tear = Path()
      ..moveTo(c.dx, c.dy - h / 2)
      ..quadraticBezierTo(c.dx + w, c.dy, c.dx, c.dy + h / 2)
      ..quadraticBezierTo(c.dx - w, c.dy, c.dx, c.dy - h / 2)
      ..close();
    _glowAt(c, s * 0.9 * scale, primary, 0.5 * open);
    canvas.drawPath(tear, _fill(const Color(0xFF12001F), 0.9 * open));
    canvas.drawPath(tear, _stroke(secondary, open, 2.5));
    _spiralIn(0, 0.9, count: 16);
  }

  void _spiralIn(double t0, double span, {int count = 16}) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    for (var i = 0; i < count; i++) {
      final q = p[i % p.length];
      final local = ((lt - q.delay) / (1 - q.delay)).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final radius = s * 0.95 * (1 - _easeInOut(local)) * scale;
      final angle = q.angle + local * pi * 1.6;
      final at = c + Offset(cos(angle), sin(angle)) * radius;
      canvas.drawCircle(at, s * 0.04 * q.size * scale,
          _fill(i.isEven ? primary : secondary, _fade(local, 0.15, 0.8)));
    }
  }

  void _drain() {
    final lt = _window(t, 0, 0.8);
    final to = sourceRect?.center ?? Offset(c.dx, rect.top - s);
    if (lt != null) {
      final ctrl = Offset((c.dx + to.dx) / 2, min(c.dy, to.dy) - s * 0.8);
      for (var i = 0; i < 14; i++) {
        final q = p[i];
        final local =
            ((lt - q.delay * 1.5) / (1 - q.delay * 1.5)).clamp(0.0, 1.0);
        if (local <= 0 || local >= 1) continue;
        final u = _easeInOut(local);
        final a = Offset.lerp(c, ctrl, u)!;
        final b = Offset.lerp(ctrl, to, u)!;
        final at = Offset.lerp(a, b, u)! + Offset(q.dx, q.spin) * (s * 0.08);
        canvas.drawCircle(at, s * 0.045 * q.size * scale,
            _fill(i.isEven ? primary : secondary, _fade(local, 0.1, 0.75)));
      }
    }
    _glow(to, s * 0.6, 0.6, 0.4, secondary);
  }

  void _shadow() {
    for (var i = 0; i < 3; i++) {
      final lt = _window(t, i * 0.1, 0.55);
      if (lt == null) continue;
      final at = c + Offset((i - 1) * s * 0.4, 0);
      canvas.drawOval(
          Rect.fromCenter(
              center: at, width: s * 0.35 * scale, height: s * 0.8 * scale),
          _fill(const Color(0xFF1A1A2E), 0.55 * (1 - lt)));
      canvas.drawOval(
          Rect.fromCenter(
              center: at, width: s * 0.35 * scale, height: s * 0.8 * scale),
          _stroke(primary, 0.8 * (1 - lt), 1.5));
    }
    _slash(0.3, 1, width: 0.05);
  }

  void _twinkles(double t0, double span, {Color? color}) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    for (var i = 0; i < 9; i++) {
      final q = p[i + 8];
      final at = c + Offset(q.dx * s * 0.6, q.spin * s * 0.5);
      final phase = sin(pi * ((lt * 2 + q.delay * 3) % 1));
      final k = s * 0.07 * q.size * phase * scale;
      if (k <= 0) continue;
      final star = Path()
        ..moveTo(at.dx, at.dy - k)
        ..lineTo(at.dx + k * 0.25, at.dy - k * 0.25)
        ..lineTo(at.dx + k, at.dy)
        ..lineTo(at.dx + k * 0.25, at.dy + k * 0.25)
        ..lineTo(at.dx, at.dy + k)
        ..lineTo(at.dx - k * 0.25, at.dy + k * 0.25)
        ..lineTo(at.dx - k, at.dy)
        ..lineTo(at.dx - k * 0.25, at.dy - k * 0.25)
        ..close();
      canvas.drawPath(star, _fill(color ?? secondary, _fade(lt, 0.1, 0.7)));
    }
  }

  void _pluses() {
    final lt = _window(t, 0, 1);
    if (lt == null) return;
    for (var i = 0; i < 8; i++) {
      final q = p[i];
      final local = ((lt - q.delay) / (1 - q.delay)).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final at = Offset(
          c.dx + q.dx * s * 0.5, c.dy + s * 0.25 - local * s * 0.8 * q.speed);
      final k = s * 0.1 * q.size * scale;
      final paint = _stroke(primary, 1 - local, k * 0.45);
      canvas.drawLine(at - Offset(k, 0), at + Offset(k, 0), paint);
      canvas.drawLine(at - Offset(0, k), at + Offset(0, k), paint);
    }
  }

  void _shieldOutline({required bool stone}) {
    final lt = _window(t, 0, 1);
    if (lt == null) return;
    final opacity = _fade(lt, 0.12, 0.55);
    final grow = 2 + 6 * _easeOut(lt);
    final shape =
        RRect.fromRectAndRadius(rect.inflate(grow), const Radius.circular(12));
    canvas.drawRRect(shape, _fill(primary, 0.14 * opacity));
    canvas.drawRRect(shape, _stroke(primary, opacity, stone ? 5 : 4));
    canvas.drawRRect(shape.deflate(3), _stroke(secondary, opacity, 1.5));
    // A glint running round the edge.
    final path = Path()..addRRect(shape);
    final metric = path.computeMetrics().first;
    final at = metric.length * ((lt * 1.2) % 1);
    canvas.drawPath(
        metric.extractPath(at, min(metric.length, at + metric.length * 0.12)),
        _stroke(Colors.white, opacity, 3));
    if (stone) {
      for (var i = 0; i < 8; i++) {
        final q = p[i];
        final angle = q.angle + lt * pi * 1.2;
        final at2 = c +
            Offset(cos(angle) * (rect.width / 2 + 10),
                sin(angle) * (rect.height / 2 + 8));
        canvas.save();
        canvas.translate(at2.dx, at2.dy);
        canvas.rotate(angle * 2);
        final k = s * 0.07 * q.size;
        canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: k, height: k),
            _fill(secondary, opacity));
        canvas.restore();
      }
    }
  }

  void _shout() {
    final origin = sourceRect?.center ?? c;
    for (var i = 0; i < 3; i++) {
      final lt = _window(t, i * 0.15, 0.6);
      if (lt == null) continue;
      canvas.drawCircle(origin, s * (0.2 + 1.2 * _easeOut(lt)) * scale,
          _stroke(i == 1 ? secondary : primary, 1 - lt, 4 * (1 - lt) + 1));
    }
  }

  void _stars() {
    final lt = _window(t, 0, 1);
    if (lt == null) return;
    final opacity = _fade(lt, 0.1, 0.65);
    final centre = Offset(c.dx, rect.top + min(18.0, rect.height * 0.2));
    for (var i = 0; i < 4; i++) {
      final angle = lt * pi * 3 + i * pi / 2;
      final at = centre + Offset(cos(angle) * s * 0.35, sin(angle) * s * 0.1);
      _star(at, s * 0.07 * scale, primary, opacity);
    }
  }

  void _star(Offset at, double r, Color color, double opacity) {
    final path = Path();
    for (var k = 0; k < 10; k++) {
      final radius = k.isEven ? r : r * 0.45;
      final angle = -pi / 2 + k * pi / 5;
      final point = at + Offset(cos(angle), sin(angle)) * radius;
      if (k == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, _fill(color, opacity));
  }

  void _chevrons() {
    for (var i = 0; i < 3; i++) {
      final lt = _window(t, i * 0.12, 0.65);
      if (lt == null) continue;
      final y = rect.top + s * 0.1 + lt * s * 0.6;
      final x = c.dx + (i - 1) * s * 0.3;
      final k = s * 0.1 * scale;
      final path = Path()
        ..moveTo(x - k, y - k * 0.6)
        ..lineTo(x, y)
        ..lineTo(x + k, y - k * 0.6);
      canvas.drawPath(path,
          _stroke(i == 1 ? secondary : primary, _fade(lt, 0.15, 0.5), k * 0.4));
    }
  }

  void _crit() {
    _glow(c, s * 0.9, 0, 0.3, Colors.white);
    final lt = _window(t, 0, 0.7);
    if (lt == null) return;
    for (var i = 0; i < 12; i++) {
      final angle = i * pi / 6 + p[1].angle;
      final dir = Offset(cos(angle), sin(angle));
      final inner = c + dir * (s * 0.2);
      final outer = c + dir * (s * (0.3 + 0.9 * _easeOut(lt)) * scale);
      canvas.drawLine(inner, outer,
          _stroke(primary, 1 - lt, (i.isEven ? 5 : 3) * (1 - lt) + 1));
    }
  }
}
