// One burst's drawing: the class that holds a burst, its canvas and its
// progress, and how a style starts. Cut out of combat_vfx.dart with no
// change.
part of '../combat_vfx.dart';

/// One burst's drawing at progress [t]: its style, then the details its
/// tier adds (see [_tierDetails]).
class _Fx {
  _Fx(this.canvas, this.layer, this.burst, this.rect, this.sourceRect, this.t,
      this.frame)
      : c = rect.center,
        s = min(rect.width, rect.height).clamp(40.0, 110.0),
        primary = Color(burst.palette.primary),
        secondary = Color(burst.palette.secondary);

  final Canvas canvas;

  /// The whole layer, for a mighty blow's flash of the screen.
  final Size layer;
  final VfxBurst burst;
  final Rect rect;
  final Rect? sourceRect;
  final double t;
  final _Frame frame;
  final Offset c;
  final double s;
  final Color primary;
  final Color secondary;

  List<VfxParticle> get p => burst.particles;

  /// The burst's size: its power (see [vfxPowerFor]), capped so a mighty
  /// blow grows by its details rather than swallowing the screen.
  double get scale => min(burst.power, maxVfxScale);
  VfxTier get tier => burst.tier;
  bool get strong => tier.index >= VfxTier.strong.index;
  bool get mighty => tier == VfxTier.mighty;

  /// [count] particles as many as the tier throws, within the burst's
  /// supply.
  int _n(int count) => max(
      1,
      min(p.length,
          (count * vfxCountFactor(tier) * (frame.crowded ? 0.6 : 1)).round()));

  /// A light touch glows less.
  double get _glowK => tier == VfxTier.light ? 0.65 : 1.0;

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
    // In pixel art (see pixel_vfx.dart) once the strips are in; the vector
    // effect below plays until then.
    if (paintPixelBurst(
      canvas,
      style: burst.style,
      palette: burst.palette,
      tier: tier,
      hit: burst.hit,
      rect: rect,
      sourceRect: sourceRect,
      t: t,
      s: s,
      extent: vfxExtentFor(burst.style, burst.power),
    )) {
      // The flash across the screen stays: it is light, not a shape.
      if (mighty && !systemVfxStyles.contains(burst.style)) {
        if (burst.hit) {
          _screenFlash(vfxImpactAt(burst.style), 0.25);
        } else {
          _screenFlash(0.05, 0.25, opacity: 0.1);
        }
      }
      _accent();
      return;
    }
    _style();
    _tierDetails();
    _accent();
  }

  /// The clan card's particles over the style (see [VfxAccent]).
  void _accent() {
    switch (burst.accent) {
      case VfxAccent.none:
        return;
      case VfxAccent.fusion:
        // Two colors circle each other, close in and flare as one.
        final lt = _window(t, 0, 0.55);
        if (lt != null) {
          final r = s * 0.5 * (1 - _easeInOut(lt)) * scale;
          for (var k = 0; k < 2; k++) {
            final angle = lt * pi * 3 + k * pi;
            final at = c + Offset(cos(angle), sin(angle)) * r;
            final color = k == 0 ? primary : secondary;
            final a = _fade(lt, 0.1, 0.8);
            canvas.drawCircle(at, s * 0.16 * scale, _fill(color, 0.25 * a));
            canvas.drawCircle(at, s * 0.08 * scale, _fill(color, a));
          }
        }
        _glow(c, s * 0.6, 0.5, 0.4, Colors.white);
        _ring(0.5, 0.45, s * 0.1, s * 0.9, width: 3, color: Colors.white);
        _sparks(0.5, 0.45, count: 10, reach: 0.7);
      case VfxAccent.ascension:
        // A pillar rises with the sparks, and chevrons climb it.
        _beam(0, 0.7, width: 0.35);
        _rise(0.05, 0.95, count: 18, height: 1.4, width: 0.35, sizeK: 0.07);
        final lt = _window(t, 0.1, 0.8);
        if (lt != null) {
          for (var k = 0; k < 3; k++) {
            final local = ((lt - k * 0.18) / (1 - k * 0.18)).clamp(0.0, 1.0);
            if (local <= 0 || local >= 1) continue;
            final y = c.dy + s * 0.3 - local * s * 1.1;
            final w = s * 0.22 * scale;
            final chevron = Path()
              ..moveTo(c.dx - w, y + w * 0.5)
              ..lineTo(c.dx, y - w * 0.2)
              ..lineTo(c.dx + w, y + w * 0.5);
            canvas.drawPath(
                chevron, _stroke(secondary, (1 - local) * 0.9, 3 * scale));
          }
        }
      case VfxAccent.subclan:
        // A sigil of two rings, six motes orbiting it and flying off.
        final lt = _window(t, 0, 0.8);
        if (lt == null) return;
        final r = s * 0.62 * scale * (0.7 + 0.3 * _easeOut(lt));
        canvas.drawCircle(
            c, r, _stroke(primary, 0.55 * _fade(lt, 0.15, 0.6), 2.5));
        canvas.drawCircle(
            c, r * 0.72, _stroke(secondary, 0.4 * _fade(lt, 0.2, 0.6), 1.5));
        final spread = lt > 0.6 ? (lt - 0.6) * 2.5 : 0.0;
        for (var i = 0; i < 6; i++) {
          final angle = lt * pi * 2 + i * pi / 3;
          final at = c + Offset(cos(angle), sin(angle)) * (r * (1 + spread));
          final k = s * 0.06 * scale;
          final mote = Path()
            ..moveTo(at.dx, at.dy - k)
            ..lineTo(at.dx + k, at.dy)
            ..lineTo(at.dx, at.dy + k)
            ..lineTo(at.dx - k, at.dy)
            ..close();
          canvas.drawPath(mote, _fill(secondary, _fade(lt, 0.1, 0.7)));
        }
      case VfxAccent.secret:
        // A violet veil, rune fragments drifting up, a late pale ring.
        _glow(c, s * 0.8, 0, 0.7, const Color(0xFF4A2A7A));
        _twinkles(0.05, 0.9, color: Colors.white);
        final lt = _window(t, 0.1, 0.85);
        if (lt != null) {
          for (var i = 0; i < _n(10); i++) {
            final q = p[i];
            final x = c.dx + q.dx * s * 0.55;
            final y = c.dy + s * 0.3 - lt * s * 0.9 * q.speed;
            final len = s * 0.08 * q.size * scale;
            final dir = Offset(cos(q.angle), sin(q.angle)) * len;
            canvas.drawLine(Offset(x, y) - dir, Offset(x, y) + dir,
                _stroke(secondary, (1 - lt) * 0.9, 2));
          }
        }
        _ring(0.55, 0.4, s * 0.15, s * 0.8, width: 2, color: primary);
    }
  }

  void _style() {
    switch (burst.style) {
      case VfxStyle.slash:
        // An afterimage trails the blade; a strong cut crosses back.
        if (tier != VfxTier.light) {
          _slash(0.06, 1,
              width: 0.045, shift: const Offset(0.09, 0.07), fade: 0.35);
        }
        _slash(0, 1);
        if (strong) _slash(0.14, -1, width: 0.055);
        _sparks(0.15, 0.5, count: 8, reach: 0.6);
      case VfxStyle.heavySlash:
        _slash(0.06, 1, width: 0.07, shift: const Offset(0.1, 0.08), fade: 0.3);
        _slash(0, 1, width: 0.11);
        _slash(0.12, -1, width: 0.11);
        _ring(0.2, 0.5, s * 0.1, s * 0.9, width: 5);
        _sparks(0.2, 0.6, count: 14, reach: 0.9);
        _cracks(0.18, 0.7, count: 3);
      case VfxStyle.pierce:
        _speedLines(0, 0.35);
        _pierce();
      case VfxStyle.whirl:
        _whirl();
      case VfxStyle.claw:
        _claw();
      case VfxStyle.impact:
        _impact();
        _cracks(0.05, 0.85);
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
        _shimmer(0, 0.9);
        _glow(c, s * 0.6, 0, 0.5, secondary);
        _rise(0, 1, count: 20, height: 1.0, width: 0.45, sizeK: 0.12);
        _embers(0.25, 0.75);
      case VfxStyle.fireball:
        _orb(0, 0.45, radius: 0.16, trail: true);
        _explosion(0.45, 0.55, reach: 1.0);
        _smoke(count: 5, reach: 0.5, t0: 0.6, span: 0.4);
        _embers(0.5, 0.5);
      case VfxStyle.meteor:
        _meteor();
      case VfxStyle.holyFire:
        _beam(0, 0.5, width: 0.3);
        _rise(0.35, 0.65, count: 16, height: 0.9, width: 0.4, sizeK: 0.1);
      case VfxStyle.frost:
        _mist(0, 1);
        _shards();
        _ring(0, 0.6, s * 0.1, s * 0.95, width: 3, color: secondary);
        _glow(c, s * 0.5, 0, 0.4, primary);
        _snowflakes(0.1, 0.9);
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
        _cracks(0, 0.9, count: 6);
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
}
