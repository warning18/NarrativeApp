part of '../combat_vfx.dart';

/// What a strong or mighty burst adds on top of its style: the flash, the
/// rings, the rays, the embers and the cracks. Cut out of combat_vfx.dart
/// with no change.
extension _FxTiers on _Fx {
  // --- Tier details ---------------------------------------------------------

  /// What a strong or mighty burst adds on top of its style. A blow gets,
  /// at the moment it lands, a white flash, then a second shockwave and
  /// embers, then (mighty) a flash of the whole screen, a ring across the
  /// ground and rays. Anything else (a heal, a shield) rises: motes and a
  /// ring, then a pillar of light. A light burst adds nothing, and the
  /// system styles (a crit's burst, a miss, a phase) keep their own look.
  void _tierDetails() {
    if (tier == VfxTier.light || systemVfxStyles.contains(burst.style)) {
      return;
    }
    final at = vfxImpactAt(burst.style);
    // In a crowd, the lingering and far-reaching details go first.
    final full = !frame.crowded;
    if (burst.hit) {
      _flashCore(at, 0.18);
      if (strong) {
        _ring(at, 0.45, s * 0.2, s * 0.95, width: 2.5, color: secondary);
        if (full) _embers(at + 0.1, 1 - at - 0.1);
      }
      if (mighty) {
        _screenFlash(at, 0.25);
        _groundRing(at, 0.55);
        if (full) _rays(at, 0.45);
        _ring(at + 0.08, 0.45, s * 0.3, s * 1.2, width: 4);
      }
    } else {
      if (strong) {
        if (full) _motes(0.05, 0.9);
        _ring(0.1, 0.6, s * 0.3, s * 0.9, width: 2, color: secondary);
      }
      if (mighty) {
        _pillar(0, 0.85);
        _screenFlash(0.05, 0.25, opacity: 0.1);
      }
    }
  }

  /// A white-hot core where the blow lands.
  void _flashCore(double t0, double span) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    final k = sin(pi * lt);
    _glowAt(c, s * 0.4 * scale, Colors.white, 0.55 * k);
    _glowAt(c, s * 0.7 * scale, primary, 0.3 * k);
  }

  /// The whole layer washed in the burst's color for a heartbeat.
  void _screenFlash(double t0, double span, {double opacity = 0.16}) {
    final lt = _window(t, t0, span);
    if (lt == null || frame.flashed) return;
    frame.flashed = true;
    canvas.drawRect(
        Offset.zero & layer, _fill(primary, opacity * (1 - _easeOut(lt))));
  }

  /// A flat ring running out along the ground under the target.
  void _groundRing(double t0, double span) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    final e = _easeOut(lt);
    final ground = Offset(c.dx, rect.bottom - s * 0.08);
    final w = s * (0.4 + 1.5 * e) * scale;
    canvas.drawOval(Rect.fromCenter(center: ground, width: w, height: w * 0.22),
        _stroke(secondary, 1 - lt, 5 * (1 - lt) + 1));
    canvas.drawOval(
        Rect.fromCenter(center: ground, width: w * 0.7, height: w * 0.14),
        _fill(primary, 0.25 * (1 - lt)));
  }

  /// Long thin rays thrown out from the target.
  void _rays(double t0, double span) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    const count = 10;
    for (var i = 0; i < count; i++) {
      final q = p[30 + i];
      final angle = i * 2 * pi / count + q.spin * 0.25;
      final dir = Offset(cos(angle), sin(angle));
      final reach = s * (0.45 + 0.75 * q.speed * _easeOut(lt));
      final inner = c + dir * (reach * 0.55);
      final outer = c + dir * reach;
      canvas.drawLine(inner, outer,
          _stroke(i.isEven ? Colors.white : secondary, 0.6 * (1 - lt), 1.5));
    }
  }

  /// Soft dots rising around the target, for a strong heal or shield.
  void _motes(double t0, double span) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    for (var i = 0; i < _n(12); i++) {
      final q = p[40 + i % 24];
      final local = ((lt - q.delay * 2) / (1 - q.delay * 2)).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final x = c.dx + q.dx * s * 0.75 + sin(local * 5 + q.angle) * s * 0.06;
      final y = rect.bottom - local * s * 1.5 * q.speed;
      final r = s * 0.035 * q.size * scale;
      _glowAt(Offset(x, y), r * 3, secondary, 0.4 * _fade(local, 0.2, 0.6));
      canvas.drawCircle(
          Offset(x, y), r, _fill(Colors.white, 0.8 * _fade(local, 0.2, 0.6)));
    }
  }

  /// A column of light standing on the target.
  void _pillar(double t0, double span) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    final opacity = _fade(lt, 0.2, 0.5) * 0.45;
    final w = s * 0.7 * scale * (0.6 + 0.4 * sin(pi * lt));
    final column = Rect.fromLTRB(
        c.dx - w / 2, rect.top - s * 1.2, c.dx + w / 2, rect.bottom);
    canvas.drawRect(
      column,
      Paint()
        ..shader = ui.Gradient.linear(column.topCenter, column.bottomCenter, [
          secondary.withValues(alpha: 0),
          primary.withValues(alpha: opacity),
          Colors.white.withValues(alpha: opacity),
        ], const [
          0,
          0.7,
          1
        ]),
    );
  }

  /// Glowing specks that linger and drift up after a blow or a flame.
  void _embers(double t0, double span) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    for (var i = 0; i < _n(10); i++) {
      final q = p[20 + i % 40];
      final local = ((lt - q.delay) / (1 - q.delay)).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final at = c +
          Offset(q.dx * s * 0.6 * scale + sin(local * 7 + q.angle) * s * 0.05,
              q.spin * s * 0.25 - local * s * 0.8 * q.speed);
      final flicker = 0.6 + 0.4 * sin(local * 30 + q.angle * 5);
      final r = s * 0.025 * q.size;
      _glowAt(at, r * 4, primary, 0.35 * (1 - local));
      canvas.drawCircle(
          at, r, _fill(i.isEven ? secondary : primary, flicker * (1 - local)));
    }
  }

  /// Streaks behind a thrust, along its line.
  void _speedLines(double t0, double span) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    const dir = Offset(0.95, -0.3);
    const across = Offset(0.3, 0.95);
    final lines = _n(4);
    for (var i = 0; i < lines; i++) {
      final q = p[i + 10];
      final lane = (i - (lines - 1) / 2) * s * 0.12;
      final head =
          c - dir * (s * (0.4 + 0.6 * (1 - _easeOut(lt)))) + across * lane;
      final tail = head - dir * (s * (0.4 + 0.3 * q.speed));
      canvas.drawLine(tail, head, _stroke(secondary, 0.7 * (1 - lt), 1.5));
    }
  }

  /// Jagged cracks running out from where the blow lands.
  void _cracks(double t0, double span, {int count = 5}) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    final grow = _easeOut((lt / 0.3).clamp(0.0, 1.0));
    final opacity = lt < 0.5 ? 1.0 : 1 - (lt - 0.5) / 0.5;
    final cracks = strong ? count + 2 : count;
    for (var i = 0; i < cracks; i++) {
      final q = p[i + 44];
      final angle = i * 2 * pi / cracks + q.spin * 0.4;
      final length = s * (0.35 + 0.35 * q.speed) * scale * grow;
      final path = Path()..moveTo(c.dx, c.dy);
      var at = c;
      const steps = 4;
      for (var j = 1; j <= steps; j++) {
        final bend = angle + (j.isEven ? 0.35 : -0.35) * q.dx;
        at = at + Offset(cos(bend), sin(bend)) * (length / steps);
        path.lineTo(at.dx, at.dy);
      }
      canvas.drawPath(path, _stroke(primary, 0.6 * opacity, s * 0.04));
      canvas.drawPath(
          path, _stroke(const Color(0xFF2B1D14), 0.85 * opacity, s * 0.018));
    }
  }

  /// Heat haze: wavy threads rising over a flame.
  void _shimmer(double t0, double span) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    final opacity = _fade(lt, 0.2, 0.6) * 0.35;
    for (var i = 0; i < 3; i++) {
      final x0 = c.dx + (i - 1) * s * 0.3;
      final path = Path()..moveTo(x0, rect.bottom);
      const steps = 8;
      for (var j = 1; j <= steps; j++) {
        final y = rect.bottom - (s * 1.4 * scale) * j / steps;
        final x = x0 + sin(j * 1.3 + lt * 12 + i) * s * 0.06;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, _stroke(secondary, opacity, 2));
    }
  }

  /// A cold mist settling over the target.
  void _mist(double t0, double span) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    final opacity = _fade(lt, 0.25, 0.5) * 0.25 * _glowK;
    for (var i = 0; i < 5; i++) {
      final q = p[i + 50];
      final at = c +
          Offset(q.dx * s * 0.55 + lt * q.spin * s * 0.2, q.spin * s * 0.25);
      _glowAt(at, s * (0.3 + 0.2 * q.size) * scale, secondary, opacity);
    }
  }

  /// Six-armed flakes drifting down and turning.
  void _snowflakes(double t0, double span) {
    final lt = _window(t, t0, span);
    if (lt == null) return;
    for (var i = 0; i < _n(6); i++) {
      final q = p[i + 56 < p.length ? i + 56 : i];
      final local = ((lt - q.delay) / (1 - q.delay)).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final at = Offset(c.dx + q.dx * s * 0.8,
          rect.top - s * 0.2 + local * (rect.height + s * 0.2));
      final r = s * 0.06 * q.size * scale;
      final spin = q.spin * local * 4;
      final paint = _stroke(Colors.white, _fade(local, 0.15, 0.7), 1.3);
      for (var arm = 0; arm < 6; arm++) {
        final a = spin + arm * pi / 3;
        canvas.drawLine(at, at + Offset(cos(a), sin(a)) * r, paint);
      }
    }
  }
}
