// An enemy's portrait that moves in pixel art (v1.221): it flashes and
// shakes when a blow lands on its card, lunges at the party member it
// strikes, and, when it is beaten, dissolves from the feet up into rising
// pixels (a boss's fall adds a ring of light). The 32x32 sprite is read
// from the portrait's own file and drawn pixel by pixel, so every enemy has
// all three moves with no extra art. With animations off, the portrait is
// the still sprite as before.
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../utils/pixel_icons/enemy_icons.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import 'combat_vfx.dart';

/// What a portrait can be cued to do.
enum PortraitCue { hit, lunge, death }

/// How long each lasts, in milliseconds.
int portraitCueMs(PortraitCue cue, {bool boss = false}) => switch (cue) {
      PortraitCue.hit => 520,
      PortraitCue.lunge => 760,
      PortraitCue.death => boss ? 1500 : 1100,
    };

/// An enemy sprite's 32x32 pixels (RGBA), read once from its portrait.
class PortraitPixels {
  PortraitPixels._();

  static const int side = 32;
  static final Map<String, Uint8List> _cache = {};
  static final Set<String> _asked = {};

  /// Counts the sprites in, for a widget to rebuild on.
  static final ValueNotifier<int> loaded = ValueNotifier(0);

  /// [enemyId]'s pixels, or null while they load (or for an enemy with no
  /// portrait file).
  static Uint8List? of(String enemyId) {
    final got = _cache[enemyId];
    if (got == null &&
        EnemyIcons.allIds.contains(enemyId) &&
        _asked.add(enemyId)) {
      _load(enemyId);
    }
    return got;
  }

  static Future<void> _load(String enemyId) async {
    try {
      final data = await rootBundle.load(EnemyIcons.pathFor(enemyId));
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (raw == null) return;
      final out = Uint8List(side * side * 4);
      for (var y = 0; y < side; y++) {
        for (var x = 0; x < side; x++) {
          final sx = ((x + 0.5) * image.width / side)
              .floor()
              .clamp(0, image.width - 1);
          final sy = ((y + 0.5) * image.height / side)
              .floor()
              .clamp(0, image.height - 1);
          final from = (sy * image.width + sx) * 4;
          final to = (y * side + x) * 4;
          for (var k = 0; k < 4; k++) {
            out[to + k] = raw.getUint8(from + k);
          }
        }
      }
      _cache[enemyId] = out;
      loaded.value++;
    } catch (_) {
      _asked.remove(enemyId);
    }
  }
}

const List<List<int>> _bayer = [
  [0, 8, 2, 10],
  [12, 4, 14, 6],
  [3, 11, 1, 9],
  [15, 7, 13, 5],
];

double _hash(num i, int salt) {
  final x = sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}

/// The portrait of [enemyId] on its card [anchor], cued by [controller].
class PixelEnemyPortrait extends StatefulWidget {
  const PixelEnemyPortrait({
    super.key,
    required this.enemyId,
    required this.alive,
    required this.controller,
    required this.anchor,
    this.boss = false,
    this.animate = true,
    this.size = 32,
  });

  final String enemyId;
  final bool alive;
  final CombatVfxController controller;
  final GlobalKey anchor;
  final bool boss;

  /// False with reduced motion, quick fights or the effects switched off.
  final bool animate;
  final double size;

  @override
  State<PixelEnemyPortrait> createState() => _PixelEnemyPortraitState();
}

class _PixelEnemyPortraitState extends State<PixelEnemyPortrait>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          if (_cue == PortraitCue.death) _gone = true;
          _playing = false;
        });
      }
    });
  PortraitCue _cue = PortraitCue.hit;
  Offset _dir = const Offset(-1, 0);
  bool _playing = false;
  bool _gone = false;
  Timer? _deathTimer;
  final Set<Timer> _timers = {};

  @override
  void initState() {
    super.initState();
    widget.controller.addCueListener(_onCue);
    PortraitPixels.of(widget.enemyId);
    _gone = !widget.alive && widget.animate;
  }

  @override
  void didUpdateWidget(PixelEnemyPortrait old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeCueListener(_onCue);
      widget.controller.addCueListener(_onCue);
    }
    if (old.alive && !widget.alive && widget.animate) {
      // The blow that ended it is still on its way: fall when it lands,
      // or soon after in any case.
      _deathTimer?.cancel();
      _deathTimer = Timer(const Duration(milliseconds: 900), _startDeath);
    } else if (!old.alive && widget.alive) {
      _deathTimer?.cancel();
      _gone = false;
    }
  }

  @override
  void dispose() {
    widget.controller.removeCueListener(_onCue);
    _deathTimer?.cancel();
    for (final t in _timers) {
      t.cancel();
    }
    _anim.dispose();
    super.dispose();
  }

  void _onCue(VfxCue cue) {
    if (!mounted || !widget.animate || cue.target != widget.anchor) return;
    if (_gone || (_playing && _cue == PortraitCue.death)) return;
    if (cue.cue == PortraitCue.death) return;
    void go() {
      if (!mounted || _gone || (_playing && _cue == PortraitCue.death)) return;
      if (cue.cue == PortraitCue.hit && !widget.alive && _deathTimer != null) {
        // The killing blow has landed: the fall follows it.
        _deathTimer?.cancel();
        _deathTimer = Timer(const Duration(milliseconds: 160), _startDeath);
      }
      _play(cue.cue, cue.dir);
    }

    if (cue.delay == Duration.zero) {
      go();
    } else {
      late final Timer timer;
      timer = Timer(cue.delay, () {
        _timers.remove(timer);
        go();
      });
      _timers.add(timer);
    }
  }

  void _startDeath() {
    _deathTimer = null;
    if (!mounted || widget.alive || _gone) return;
    _play(PortraitCue.death, _dir);
  }

  void _play(PortraitCue cue, Offset dir) {
    setState(() {
      _cue = cue;
      _dir = dir;
      _playing = true;
    });
    _anim.duration =
        Duration(milliseconds: portraitCueMs(cue, boss: widget.boss));
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final pixels = PortraitPixels.of(widget.enemyId);
    final size = widget.size;
    if (_gone) {
      return SizedBox(
          key: const ValueKey('portrait_gone'), width: size, height: size);
    }
    if (pixels == null) {
      // Until the sprite is read (or with no file): the plain icon.
      return ValueListenableBuilder<int>(
        valueListenable: PortraitPixels.loaded,
        builder: (context, _, __) => PortraitPixels.of(widget.enemyId) == null
            ? EnemyPixelIcon(widget.enemyId, size: size)
            : _paint(PortraitPixels.of(widget.enemyId)!),
      );
    }
    return _paint(pixels);
  }

  Widget _paint(Uint8List pixels) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          key: ValueKey(_playing ? 'portrait_${_cue.name}' : 'portrait_still'),
          painter: _PortraitPainter(
            pixels: pixels,
            cue: _playing ? _cue : null,
            t: _anim.value,
            dir: _dir,
            boss: widget.boss,
            enemyId: widget.enemyId,
          ),
        ),
      ),
    );
  }
}

class _PortraitPainter extends CustomPainter {
  _PortraitPainter({
    required this.pixels,
    required this.cue,
    required this.t,
    required this.dir,
    required this.boss,
    required this.enemyId,
  });

  final Uint8List pixels;
  final PortraitCue? cue;
  final double t;
  final Offset dir;
  final bool boss;
  final String enemyId;

  static const int n = PortraitPixels.side;

  Color _at(int x, int y) {
    final i = (y * n + x) * 4;
    return Color.fromARGB(
        pixels[i + 3], pixels[i], pixels[i + 1], pixels[i + 2]);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / n;
    final paint = Paint()..isAntiAlias = false;

    void dot(double x, double y, Color c, {double w = 1}) {
      paint.color = c;
      canvas.drawRect(
          Rect.fromLTWH((x * u).roundToDouble(), (y * u).roundToDouble(),
              max(1, (w * u).roundToDouble()), max(1, (w * u).roundToDouble())),
          paint);
    }

    /// The sprite shifted by ([dx], [dy]) pixels, scaled ([sx], [sy]) about
    /// its feet, each pixel lerped to [tint] by [amount] and kept at
    /// [opacity].
    void sprite(
        {double dx = 0,
        double dy = 0,
        double sx = 1,
        double sy = 1,
        Color? tint,
        double amount = 0,
        double opacity = 1,
        bool Function(int x, int y)? keep,
        double lighten = 0}) {
      for (var y = 0; y < n; y++) {
        for (var x = 0; x < n; x++) {
          var c = _at(x, y);
          if (c.a == 0) continue;
          if (keep != null && !keep(x, y)) continue;
          if (tint != null && amount > 0) c = Color.lerp(c, tint, amount)!;
          if (lighten > 0) c = Color.lerp(c, Colors.white, lighten)!;
          if (opacity < 1) c = c.withValues(alpha: opacity);
          final px = (n / 2) + (x - n / 2) * sx + dx;
          final py = (n - 1) + (y - (n - 1)) * sy + dy;
          paint.color = c;
          canvas.drawRect(
              Rect.fromLTWH(
                  (px * u).roundToDouble(),
                  (py * u).roundToDouble(),
                  max(1.0, (sx * u).ceilToDouble()),
                  max(1.0, (sy * u).ceilToDouble())),
              paint);
        }
      }
    }

    switch (cue) {
      case null:
        sprite();
      case PortraitCue.hit:
        final i = (t * 6).floor().clamp(0, 5);
        const amount = [1.0, 0.7, 0.5, 0.3, 0.12, 0.0];
        const shake = [0.0, 2.0, -2.0, 1.0, -1.0, 0.0];
        sprite(
            dx: shake[i],
            tint: i == 0 ? Colors.white : const Color(0xFFFF6A5C),
            amount: amount[i]);
        if (i < 4) {
          for (var k = 0; k < 7; k++) {
            final a = -0.9 + k * 0.55 + _hash(k, 2) * 0.4 - 1.5;
            final r = 8 + i * 4 + _hash(k, 3) * 5;
            dot(16 + cos(a) * r, 14 + sin(a) * r * 0.9,
                k.isEven ? Colors.white : const Color(0xFFC9D1DC),
                w: i < 2 && k % 3 == 0 ? 2 : 1);
          }
        }
      case PortraitCue.lunge:
        final i = (t * 8).floor().clamp(0, 7);
        const dy = [0.0, -2.0, -4.0, 6.0, 14.0, 14.0, 7.0, 0.0];
        const sx = [1.0, 1.05, 1.08, 0.94, 0.92, 1.0, 1.0, 1.0];
        const sy = [1.0, 0.95, 0.92, 1.1, 1.14, 1.0, 1.0, 1.0];
        const ghosts = [0, 0, 0, 2, 3, 1, 0, 0];
        final d = dir.distance == 0 ? const Offset(-1, 0) : dir / dir.distance;
        for (var g = ghosts[i]; g > 0; g--) {
          sprite(
              dx: d.dx * (dy[i] - g * 6),
              dy: d.dy * (dy[i] - g * 6),
              sx: sx[i],
              sy: sy[i],
              opacity: 0.45 - g * 0.1);
        }
        sprite(dx: d.dx * dy[i], dy: d.dy * dy[i], sx: sx[i], sy: sy[i]);
        if (i >= 4 && i <= 6) {
          final e = (i - 4) / 2;
          for (var k = 0; k < 10; k++) {
            final side = k.isEven ? -1 : 1;
            dot(
                16 + d.dx * dy[i] + side * (4 + e * 12 * _hash(k, 3)),
                (n - 2) + d.dy * dy[i] - e * 5 * _hash(k, 4) - _hash(k, 5) * 3,
                k % 3 == 0 ? const Color(0xFFF0E2D2) : const Color(0xFFB08C70),
                w: e < 0.6 ? 2 : 1);
          }
        }
      case PortraitCue.death:
        const steps = 10;
        final i = (t * steps).floor().clamp(0, steps - 1);
        if (i < 2) {
          sprite(
              dx: i == 0 ? 2 : -2,
              tint: Colors.white,
              amount: i == 0 ? 1 : 0.55);
        } else {
          final p = (i - 1) / (steps - 1);
          double vanish(int x, int y) =>
              (1 - y / 31) * 0.5 +
              _bayer[y % 4][x % 4] / 16 * 0.4 +
              _hash(x * 31 + y, 4) * 0.05;
          final fadeOut =
              i >= 6 ? ((i - 5.5) / 5.5).clamp(0.0, 1.0) * 0.9 : 0.0;
          bool shown(int x, int y) =>
              p <= vanish(x, y) && _bayer[y % 4][x % 4] / 16 >= fadeOut;
          sprite(keep: shown, lighten: i < 5 ? 0.18 * (1 - p) : 0);
          // The pixels that came away rise as embers.
          for (var y = 0; y < n; y++) {
            for (var x = 0; x < n; x++) {
              final c = _at(x, y);
              if (c.a == 0) continue;
              final v = vanish(x, y);
              if (p <= v) continue;
              if (_hash(x * 17 + y * 5, 9) >= (boss ? 0.55 : 0.32)) continue;
              var born = 2;
              while (born < steps && (born - 1) / (steps - 1) <= v) {
                born++;
              }
              final age = i - born;
              if (age < 0) continue;
              if (_bayer[y % 4][x % 4] / 16 < fadeOut) continue;
              final ex = x + sin(age * 1.3 + x) * 2;
              final ey = y - age * (2.0 + _hash(x, 6) * 1.5);
              dot(
                  ex,
                  ey,
                  age > 2
                      ? (age.isOdd ? const Color(0xFFFFE08A) : Colors.white)
                      : c,
                  w: boss && age < 3 ? 2 : 1);
            }
          }
          if (boss && i >= 1 && i <= 6) {
            final e = (i - 1) / 5;
            final r = 6 + (1 - pow(1 - e, 3)) * 17;
            final steps2 = (r * 7).round();
            for (var s = 0; s < steps2; s++) {
              final a = s * 2 * pi / steps2;
              dot(16 + cos(a) * r, 14 + sin(a) * r, const Color(0xFFFFF08A),
                  w: e < 0.35
                      ? 3
                      : e < 0.6
                          ? 2
                          : 1);
            }
            for (var k = 0; k < 12; k++) {
              final a = k * 2 * pi / 12 + _hash(k, 1) * 0.3;
              final rr = 10 + (1 - pow(1 - e, 3)) * (9 + _hash(k, 2) * 5);
              dot(16 + cos(a) * rr, 14 + sin(a) * rr,
                  k.isEven ? Colors.white : const Color(0xFFFFF08A),
                  w: 2);
            }
          }
        }
    }
  }

  @override
  bool shouldRepaint(_PortraitPainter old) =>
      old.cue != cue || old.t != t || old.pixels != pixels || old.dir != dir;
}
