import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// The ship battle's particles (see ShipBattlePanel): each shot, what it
/// does where it lands, the weather over the sea, rooms burning and holds
/// leaking. Effects are placed on the widgets they belong to through
/// [GlobalKey]s, looked up at every frame, so they follow the battle as it
/// scrolls. They are the same for both ships: whichever fires, whichever
/// is hit.
enum ShipFxKind {
  /// A gun going off: a flash, sparks and smoke rolling off the rail.
  muzzle,

  /// Wood splinters and dust off a room a shot hit.
  splinters,

  /// A shield layer stopping a shot: a hexagon flare and glancing sparks.
  shield,

  /// A shot the ship slipped, plunging into the sea beside her.
  splash,

  /// A room losing its last pip: sparks and a puff of grey smoke.
  knockedOut,

  /// A critical: a gold starburst and ring.
  critical,

  /// Rope fibres off a helm a chain shot tore.
  fibres,

  /// A red-hot ball setting a room alight: a burst of embers.
  ignite,

  /// A wave rolling under both ships, spray breaking over the rails.
  wave,

  /// Gold sparkles rising off a room mended by all hands.
  sparkles,

  /// Motes of light rising over a crew blessed and healed.
  motes,

  /// A ring flaring around a ship or a room (an order taking hold).
  ring,

  /// Bubbles and spray off a hull going down, or bitten from below.
  bubbles,

  /// Planks and debris bobbing on the sea (a drifting wreck).
  debris,
}

/// What a shot in flight is: a plain ball, two on a chain, a spread of
/// small shot, or a red-hot ball.
enum ShipShotKind { round, chain, grape, heated }

/// The colours the effects are drawn in, from the app's palette.
class ShipFxPalette {
  const ShipFxPalette({
    required this.gold,
    required this.ember,
    required this.blood,
    required this.tide,
    required this.wood,
    required this.steel,
    required this.smoke,
    required this.light,
    required this.voidColor,
  });

  final Color gold;
  final Color ember;
  final Color blood;
  final Color tide;
  final Color wood;
  final Color steel;
  final Color smoke;
  final Color light;
  final Color voidColor;
}

/// The weather over the sea, drawn all battle long.
enum ShipFxWeather { none, fog, rain, wind }

/// What lasts rather than bursts, asked of the panel at every frame: the
/// weather, the rooms burning and the holds letting in water.
class ShipFxAmbient {
  const ShipFxAmbient({
    this.weather = ShipFxWeather.none,
    this.burning = const [],
    this.leaking = const [],
  });

  final ShipFxWeather weather;
  final List<GlobalKey> burning;

  /// The hold's key and how many leaks it has.
  final List<(GlobalKey, int)> leaking;
}

enum _Shape { dot, sliver, smoke, streak, ring, hex, flash, glow, plus }

class _Particle {
  _Particle({
    required this.shape,
    required this.color,
    required this.origin,
    required this.velocity,
    required this.life,
    this.delay = 0,
    this.gravity = 0,
    this.size = 3,
    this.grow = 1,
    this.spin = 0,
    this.angle = 0,
  });

  final _Shape shape;
  final Color color;

  /// Where it starts, from the anchor's centre.
  final Offset origin;
  final Offset velocity;
  final double life;
  final double delay;
  final double gravity;
  final double size;

  /// How much bigger it ends than it starts.
  final double grow;
  final double spin;
  final double angle;
}

/// One effect: its particles around [anchor], started at [start] seconds.
class _Burst {
  _Burst({
    required this.anchor,
    required this.fallback,
    required this.start,
    required this.particles,
    this.align = Alignment.center,
  }) : end = start +
            particles.fold<double>(0, (m, p) => math.max(m, p.delay + p.life));

  final GlobalKey? anchor;
  final Rect fallback;
  final Alignment align;
  final double start;
  final double end;
  final List<_Particle> particles;
}

/// A ball crossing from one ship to the other.
class _Shot {
  _Shot({
    required this.from,
    required this.to,
    required this.fromRect,
    required this.toRect,
    required this.start,
    required this.kind,
    required this.seeds,
  });

  final GlobalKey from;
  final GlobalKey to;
  final Rect fromRect;
  final Rect toRect;
  final double start;
  final ShipShotKind kind;

  /// Each grape pellet's own spread.
  final List<Offset> seeds;
}

/// How long a ball takes to cross, in seconds; the panel waits as long
/// before saying what it did.
const double shipShotSeconds = 0.42;

/// Queues effects for a [ShipFxLayer].
class ShipFxController extends ChangeNotifier {
  ShipFxController({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;
  final List<_Burst> _bursts = [];
  final List<_Shot> _shots = [];
  double _now = 0;
  ShipFxPalette? _palette;

  bool get _busy => _bursts.isNotEmpty || _shots.isNotEmpty;

  double _r(double a, double b) => a + _random.nextDouble() * (b - a);

  /// Plays [kind] on [anchor]'s widget, after [delay] seconds.
  void play(ShipFxKind kind, GlobalKey anchor,
      {double delay = 0, Alignment align = Alignment.center}) {
    final palette = _palette;
    final rect = _rectOf(anchor);
    if (palette == null || rect == null) return;
    _bursts.add(_Burst(
      anchor: anchor,
      fallback: rect,
      start: _now + delay,
      align: align,
      particles: _particlesFor(kind, palette, rect.size),
    ));
    notifyListeners();
  }

  /// Fires a [kind] of shot from [from]'s widget to [to]'s: a muzzle flash
  /// at once, the ball across, and whatever [arrival] plays where it
  /// lands.
  void shot(GlobalKey from, GlobalKey to, ShipShotKind kind,
      {List<ShipFxKind> arrival = const [], double delay = 0}) {
    final fromRect = _rectOf(from);
    final toRect = _rectOf(to);
    if (_palette == null || fromRect == null || toRect == null) return;
    play(ShipFxKind.muzzle, from, delay: delay, align: Alignment.topCenter);
    _shots.add(_Shot(
      from: from,
      to: to,
      fromRect: fromRect,
      toRect: toRect,
      start: _now + delay,
      kind: kind,
      seeds: [
        if (kind == ShipShotKind.grape)
          for (var i = 0; i < 9; i++) Offset(_r(-26, 26), _r(-12, 12)),
      ],
    ));
    for (final effect in arrival) {
      play(effect, to, delay: delay + shipShotSeconds);
    }
    notifyListeners();
  }

  Rect? Function(GlobalKey key) _rectOf = (_) => null;

  List<_Particle> _particlesFor(ShipFxKind kind, ShipFxPalette c, Size size) {
    final w = size.width;
    final h = size.height;
    switch (kind) {
      case ShipFxKind.muzzle:
        return [
          _Particle(
              shape: _Shape.flash,
              color: c.gold,
              origin: Offset.zero,
              velocity: Offset.zero,
              life: 0.18,
              size: 14,
              grow: 1.6),
          for (var i = 0; i < 7; i++)
            _Particle(
                shape: _Shape.dot,
                color: c.gold,
                origin: Offset.zero,
                velocity: Offset(_r(-90, 90), _r(-110, -20)),
                life: _r(0.25, 0.45),
                size: 1.6),
          for (var i = 0; i < 6; i++)
            _Particle(
                shape: _Shape.smoke,
                color: c.smoke,
                origin: Offset(_r(-6, 6), 0),
                velocity: Offset(_r(-20, 20), _r(-45, -15)),
                life: _r(0.8, 1.3),
                delay: i * 0.03,
                size: 6,
                grow: 3),
        ];
      case ShipFxKind.splinters:
        return [
          for (var i = 0; i < 14; i++)
            _Particle(
                shape: _Shape.sliver,
                color: c.wood,
                origin: Offset(_r(-w / 4, w / 4), 0),
                velocity: Offset(_r(-120, 120), _r(-160, -50)),
                gravity: 420,
                life: _r(0.6, 0.9),
                size: _r(4, 7),
                spin: _r(-12, 12),
                angle: _r(0, math.pi)),
          for (var i = 0; i < 4; i++)
            _Particle(
                shape: _Shape.smoke,
                color: c.smoke,
                origin: Offset(_r(-10, 10), 0),
                velocity: Offset(_r(-15, 15), _r(-30, -10)),
                life: _r(0.6, 0.9),
                size: 5,
                grow: 2.6),
        ];
      case ShipFxKind.shield:
        return [
          _Particle(
              shape: _Shape.hex,
              color: c.steel,
              origin: Offset.zero,
              velocity: Offset.zero,
              life: 0.55,
              size: math.min(w, h) * 0.6,
              grow: 1.8),
          for (var i = 0; i < 9; i++)
            _Particle(
                shape: _Shape.dot,
                color: c.light,
                origin: Offset.zero,
                velocity: Offset(_r(-130, 130), _r(-120, -30)),
                gravity: 300,
                life: _r(0.3, 0.5),
                size: 1.5),
        ];
      case ShipFxKind.splash:
        // Beside the ship, in the sea off its stern.
        final side = Offset(-w * 0.55, h * 0.1);
        return [
          _Particle(
              shape: _Shape.ring,
              color: c.tide,
              origin: side,
              velocity: Offset.zero,
              life: 0.6,
              size: 8,
              grow: 3),
          for (var i = 0; i < 14; i++)
            _Particle(
                shape: _Shape.dot,
                color: Color.lerp(c.tide, c.light, 0.4)!,
                origin: side,
                velocity: Offset(_r(-50, 50), _r(-200, -90)),
                gravity: 480,
                life: _r(0.5, 0.8),
                size: _r(1.5, 3)),
        ];
      case ShipFxKind.knockedOut:
        return [
          for (var i = 0; i < 12; i++)
            _Particle(
                shape: _Shape.streak,
                color: c.gold,
                origin: Offset.zero,
                velocity: Offset(_r(-140, 140), _r(-140, 80)),
                life: _r(0.2, 0.4),
                size: 1.4),
          for (var i = 0; i < 3; i++)
            _Particle(
                shape: _Shape.smoke,
                color: c.smoke,
                origin: Offset(_r(-8, 8), 0),
                velocity: Offset(0, _r(-30, -15)),
                delay: 0.15 + i * 0.1,
                life: 1.0,
                size: 8,
                grow: 2.4),
        ];
      case ShipFxKind.critical:
        return [
          _Particle(
              shape: _Shape.ring,
              color: c.gold,
              origin: Offset.zero,
              velocity: Offset.zero,
              life: 0.5,
              size: 10,
              grow: 5),
          for (var i = 0; i < 12; i++)
            () {
              final a = i / 12 * 2 * math.pi;
              return _Particle(
                  shape: _Shape.streak,
                  color: c.gold,
                  origin: Offset(math.cos(a) * 6, math.sin(a) * 6),
                  velocity: Offset(math.cos(a) * 170, math.sin(a) * 170),
                  life: 0.32,
                  size: 2.4);
            }(),
        ];
      case ShipFxKind.fibres:
        return [
          for (var i = 0; i < 10; i++)
            _Particle(
                shape: _Shape.sliver,
                color: Color.lerp(c.wood, c.light, 0.35)!,
                origin: Offset.zero,
                velocity: Offset(_r(-90, 90), _r(-130, -30)),
                gravity: 260,
                life: _r(0.6, 1.0),
                size: _r(5, 9),
                spin: _r(-8, 8),
                angle: _r(0, math.pi)),
        ];
      case ShipFxKind.ignite:
        return [
          _Particle(
              shape: _Shape.glow,
              color: c.ember,
              origin: Offset.zero,
              velocity: Offset.zero,
              life: 0.5,
              size: math.min(w, h) * 0.5,
              grow: 1.4),
          for (var i = 0; i < 12; i++)
            _Particle(
                shape: _Shape.dot,
                color: i.isEven ? c.ember : c.gold,
                origin: Offset(_r(-w / 3, w / 3), 0),
                velocity: Offset(_r(-30, 30), _r(-110, -50)),
                life: _r(0.5, 0.9),
                size: _r(1.5, 2.5)),
        ];
      case ShipFxKind.wave:
        return [
          for (var i = 0; i < 26; i++)
            _Particle(
                shape: _Shape.dot,
                color: Color.lerp(c.tide, c.light, 0.5)!,
                origin: Offset(_r(-w / 2, w / 2), _r(-4, 4)),
                velocity: Offset(_r(20, 80), _r(-170, -70)),
                gravity: 380,
                delay: _r(0, 0.5),
                life: _r(0.6, 0.9),
                size: _r(1.5, 3)),
          _Particle(
              shape: _Shape.streak,
              color: c.tide,
              origin: Offset(-w / 2, 0),
              velocity: Offset(w * 1.1, 0),
              life: 0.9,
              size: 3),
        ];
      case ShipFxKind.sparkles:
        return [
          for (var i = 0; i < 6; i++)
            _Particle(
                shape: _Shape.plus,
                color: c.gold,
                origin: Offset(_r(-w / 3, w / 3), _r(-4, 6)),
                velocity: Offset(_r(-8, 8), _r(-50, -30)),
                delay: _r(0, 0.4),
                life: _r(0.7, 1.0),
                size: _r(3, 5)),
        ];
      case ShipFxKind.motes:
        return [
          for (var i = 0; i < 18; i++)
            _Particle(
                shape: _Shape.glow,
                color: c.light,
                origin: Offset(_r(-w / 2.4, w / 2.4), _r(-h / 4, h / 4)),
                velocity: Offset(_r(-8, 8), _r(-60, -30)),
                delay: _r(0, 0.6),
                life: _r(0.9, 1.3),
                size: _r(2, 3.5)),
        ];
      case ShipFxKind.ring:
        return [
          _Particle(
              shape: _Shape.ring,
              color: c.steel,
              origin: Offset.zero,
              velocity: Offset.zero,
              life: 0.6,
              size: math.min(w, h) * 0.35,
              grow: 2.2),
        ];
      case ShipFxKind.bubbles:
        return [
          for (var i = 0; i < 18; i++)
            _Particle(
                shape: _Shape.ring,
                color: c.tide,
                origin: Offset(_r(-w / 2.5, w / 2.5), h * 0.4),
                velocity: Offset(_r(-6, 6), _r(-50, -25)),
                delay: _r(0, 0.9),
                life: _r(0.6, 1.0),
                size: _r(1.5, 3),
                grow: 1.3),
          for (var i = 0; i < 10; i++)
            _Particle(
                shape: _Shape.dot,
                color: Color.lerp(c.tide, c.light, 0.5)!,
                origin: Offset(_r(-w / 2.5, w / 2.5), h * 0.4),
                velocity: Offset(_r(-40, 40), _r(-150, -60)),
                gravity: 400,
                life: _r(0.5, 0.8),
                size: _r(1.5, 2.5)),
        ];
      case ShipFxKind.debris:
        return [
          for (var i = 0; i < 7; i++)
            _Particle(
                shape: _Shape.sliver,
                color: c.wood,
                origin: Offset(_r(-w / 2.2, w / 2.2), _r(-4, 6)),
                velocity: Offset(_r(8, 22), _r(-2, 2)),
                life: _r(2.4, 3.2),
                size: _r(6, 12),
                spin: _r(-0.6, 0.6),
                angle: _r(-0.4, 0.4)),
        ];
    }
  }
}

/// Draws a [ShipFxController]'s effects and the battle's [ambient] ones
/// over the battle. Ignores touches, ticks only while something shows,
/// and draws nothing when the device asks for less motion.
class ShipFxLayer extends StatefulWidget {
  const ShipFxLayer({
    super.key,
    required this.controller,
    required this.palette,
    required this.ambient,
  });

  final ShipFxController controller;
  final ShipFxPalette palette;
  final ShipFxAmbient Function() ambient;

  @override
  State<ShipFxLayer> createState() => _ShipFxLayerState();
}

class _ShipFxLayerState extends State<ShipFxLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _random = math.Random();
  final List<_Burst> _ambient = [];
  Duration _last = Duration.zero;
  double _flashAt = -10;
  double _nextFlash = 3;
  bool _still = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    widget.controller
      .._palette = widget.palette
      .._rectOf = _rectOf
      ..addListener(_wake);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.of(context).disableAnimations;
    _wake();
  }

  @override
  void didUpdateWidget(covariant ShipFxLayer old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_wake);
      widget.controller.addListener(_wake);
    }
    widget.controller
      .._palette = widget.palette
      .._rectOf = _rectOf;
    _wake();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_wake);
    widget.controller._rectOf = (_) => null;
    _ticker.dispose();
    super.dispose();
  }

  /// [key]'s widget, in this layer's coordinates.
  Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    final own = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    if (own is! RenderBox || !own.attached || !own.hasSize) return null;
    final topLeft = own.globalToLocal(box.localToGlobal(Offset.zero));
    return topLeft & box.size;
  }

  bool get _ambientShows {
    final a = widget.ambient();
    return a.weather != ShipFxWeather.none ||
        a.burning.isNotEmpty ||
        a.leaking.isNotEmpty;
  }

  void _wake() {
    if (!mounted) return;
    final wanted = !_still &&
        (widget.controller._busy || _ambientShows || _ambient.isNotEmpty);
    if (wanted && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!wanted && _ticker.isActive) {
      _ticker.stop();
    }
    if (_still) {
      widget.controller
        .._bursts.clear()
        .._shots.clear();
    }
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    final c = widget.controller;
    c._now += dt;
    final now = c._now;
    c._bursts.removeWhere((b) => now > b.end);
    c._shots.removeWhere((s) => now > s.start + shipShotSeconds);
    _ambient.removeWhere((b) => now > b.end);
    _spawnAmbient(dt, now);
    setState(() {});
    if (!c._busy && !_ambientShows && _ambient.isEmpty) _ticker.stop();
  }

  double _r(double a, double b) => a + _random.nextDouble() * (b - a);

  /// Embers off burning rooms and drips from leaking holds, a few a frame.
  void _spawnAmbient(double dt, double now) {
    final a = widget.ambient();
    final p = widget.palette;
    for (final key in a.burning) {
      final rect = _rectOf(key);
      if (rect == null || _random.nextDouble() > dt * 14) continue;
      _ambient.add(_Burst(
        anchor: key,
        fallback: rect,
        start: now,
        particles: [
          _Particle(
              shape: _Shape.dot,
              color: _random.nextBool() ? p.ember : p.gold,
              origin: Offset(_r(-rect.width / 2.4, rect.width / 2.4),
                  _r(0, rect.height / 3)),
              velocity: Offset(_r(-10, 10), _r(-70, -40)),
              life: _r(0.7, 1.2),
              size: _r(1.2, 2.2)),
          if (_random.nextDouble() < 0.2)
            _Particle(
                shape: _Shape.smoke,
                color: p.smoke,
                origin: Offset(_r(-10, 10), -rect.height / 3),
                velocity: Offset(_r(-6, 6), -28),
                life: 1.4,
                size: 5,
                grow: 2.6),
        ],
      ));
    }
    for (final (key, leaks) in a.leaking) {
      final rect = _rectOf(key);
      if (rect == null || _random.nextDouble() > dt * 2.2 * leaks) continue;
      _ambient.add(_Burst(
        anchor: key,
        fallback: rect,
        start: now,
        particles: [
          _Particle(
              shape: _Shape.dot,
              color: p.tide,
              origin: Offset(
                  _r(-rect.width / 2.6, rect.width / 2.6), rect.height / 2),
              velocity: const Offset(0, 8),
              gravity: 120,
              life: 0.6,
              size: 1.8),
        ],
      ));
    }
    if (a.weather == ShipFxWeather.rain && now > _nextFlash) {
      _flashAt = now;
      _nextFlash = now + _r(4, 9);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_still) return const SizedBox.expand();
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ShipFxPainter(
          controller: widget.controller,
          ambient: _ambient,
          weather: widget.ambient().weather,
          palette: widget.palette,
          rectOf: _rectOf,
          flash: widget.controller._now - _flashAt,
        ),
      ),
    );
  }
}

class _ShipFxPainter extends CustomPainter {
  _ShipFxPainter({
    required this.controller,
    required this.ambient,
    required this.weather,
    required this.palette,
    required this.rectOf,
    required this.flash,
  });

  final ShipFxController controller;
  final List<_Burst> ambient;
  final ShipFxWeather weather;
  final ShipFxPalette palette;
  final Rect? Function(GlobalKey) rectOf;

  /// Seconds since the last lightning, for a squall.
  final double flash;

  @override
  void paint(Canvas canvas, Size size) {
    final now = controller._now;
    _paintWeather(canvas, size, now);
    for (final burst in [...ambient, ...controller._bursts]) {
      _paintBurst(canvas, burst, now);
    }
    for (final shot in controller._shots) {
      _paintShot(canvas, shot, now);
    }
  }

  void _paintWeather(Canvas canvas, Size size, double now) {
    switch (weather) {
      case ShipFxWeather.none:
        return;
      case ShipFxWeather.fog:
        final paint = Paint()
          ..color = palette.light.withValues(alpha: 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
        for (var i = 0; i < 4; i++) {
          final speed = 14.0 + i * 5;
          final span = size.width + 320;
          final x = (now * speed + i * 173) % span - 160;
          final y = size.height * (0.18 + i * 0.21);
          canvas.drawOval(
              Rect.fromCenter(center: Offset(x, y), width: 260, height: 54),
              paint);
        }
      case ShipFxWeather.rain:
        final paint = Paint()
          ..color = palette.steel.withValues(alpha: 0.30)
          ..strokeWidth = 1.2;
        for (var i = 0; i < 46; i++) {
          final seedX = (i * 97.0) % size.width;
          final fall = size.height + 40;
          final y = (now * 520 + i * 61) % fall - 20;
          final x = (seedX - y * 0.18) % size.width;
          canvas.drawLine(Offset(x, y), Offset(x - 3, y + 14), paint);
        }
        if (flash >= 0 && flash < 0.18) {
          final a = flash < 0.06 ? 0.22 : (0.18 - flash) / 0.12 * 0.12;
          canvas.drawRect(Offset.zero & size,
              Paint()..color = palette.light.withValues(alpha: a));
        }
      case ShipFxWeather.wind:
        final paint = Paint()
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 10; i++) {
          final span = size.width + 200;
          final x = (now * (240 + i * 14) + i * 131) % span - 100;
          final y = size.height * ((i * 0.37) % 1.0);
          paint.color = palette.tide.withValues(alpha: 0.28);
          canvas.drawLine(Offset(x, y), Offset(x + 46, y), paint);
        }
    }
  }

  Offset _centre(_Burst burst) {
    final rect =
        (burst.anchor == null ? null : rectOf(burst.anchor!)) ?? burst.fallback;
    return burst.align.withinRect(rect);
  }

  void _paintBurst(Canvas canvas, _Burst burst, double now) {
    final centre = _centre(burst);
    for (final p in burst.particles) {
      final t = now - burst.start - p.delay;
      if (t < 0 || t > p.life) continue;
      final k = t / p.life;
      final pos = centre +
          p.origin +
          p.velocity * t +
          Offset(0, 0.5 * p.gravity * t * t);
      final fade = (1 - k).clamp(0.0, 1.0);
      final s = p.size * (1 + (p.grow - 1) * k);
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      switch (p.shape) {
        case _Shape.dot:
          canvas.drawCircle(pos, s, paint);
        case _Shape.plus:
          paint.strokeWidth = 1.6;
          canvas.drawLine(pos - Offset(s, 0), pos + Offset(s, 0), paint);
          canvas.drawLine(pos - Offset(0, s), pos + Offset(0, s), paint);
        case _Shape.glow:
          paint.maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.9);
          canvas.drawCircle(pos, s, paint);
        case _Shape.smoke:
          paint.color = p.color.withValues(alpha: 0.45 * fade);
          canvas.drawCircle(pos, s, paint);
        case _Shape.sliver:
          canvas.save();
          canvas.translate(pos.dx, pos.dy);
          canvas.rotate(p.angle + p.spin * t);
          canvas.drawRect(
              Rect.fromCenter(center: Offset.zero, width: s * 0.35, height: s),
              paint);
          canvas.restore();
        case _Shape.streak:
          final dir = p.velocity.distance == 0
              ? Offset.zero
              : p.velocity / p.velocity.distance;
          paint
            ..strokeWidth = p.size
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(pos, pos - dir * 10, paint);
        case _Shape.ring:
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          canvas.drawCircle(pos, s, paint);
        case _Shape.hex:
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5;
          final path = Path();
          for (var i = 0; i < 6; i++) {
            final a = math.pi / 6 + i * math.pi / 3;
            final v = pos + Offset(math.cos(a) * s, math.sin(a) * s);
            i == 0 ? path.moveTo(v.dx, v.dy) : path.lineTo(v.dx, v.dy);
          }
          path.close();
          canvas.drawPath(path, paint);
        case _Shape.flash:
          paint.shader = ui.Gradient.radial(pos, s, [
            Color.lerp(p.color, Colors.white, 0.7)!.withValues(alpha: fade),
            p.color.withValues(alpha: 0.8 * fade),
            p.color.withValues(alpha: 0),
          ], const [
            0,
            0.45,
            1
          ]);
          canvas.drawCircle(pos, s, paint);
      }
    }
  }

  void _paintShot(Canvas canvas, _Shot shot, double now) {
    final t = (now - shot.start) / shipShotSeconds;
    if (t < 0 || t > 1) return;
    final from = (rectOf(shot.from) ?? shot.fromRect).topCenter;
    final to = (rectOf(shot.to) ?? shot.toRect).center;
    // An arc over the sea: the higher the further apart.
    final lift = (to - from).distance * 0.35;
    Offset at(double k) {
      final mid = Offset.lerp(from, to, 0.5)! - Offset(0, lift);
      final a = Offset.lerp(from, mid, k)!;
      final b = Offset.lerp(mid, to, k)!;
      return Offset.lerp(a, b, k)!;
    }

    final pos = at(t);
    switch (shot.kind) {
      case ShipShotKind.round:
      case ShipShotKind.heated:
        final heated = shot.kind == ShipShotKind.heated;
        for (var i = 1; i <= 5; i++) {
          final k = t - i * 0.04;
          if (k < 0) continue;
          canvas.drawCircle(
              at(k),
              3.5 - i * 0.4,
              Paint()
                ..color = (heated ? palette.ember : palette.gold)
                    .withValues(alpha: 0.5 - i * 0.08));
        }
        if (heated) {
          canvas.drawCircle(
              pos,
              9,
              Paint()
                ..color = palette.ember.withValues(alpha: 0.45)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        }
        canvas.drawCircle(
            pos, 4.5, Paint()..color = heated ? palette.ember : palette.smoke);
        canvas.drawCircle(
            pos,
            4.5,
            Paint()
              ..color = heated ? palette.gold : palette.gold
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      case ShipShotKind.chain:
        final spin = t * math.pi * 9;
        final d = Offset(math.cos(spin), math.sin(spin)) * 8;
        final link = Paint()
          ..color = palette.light.withValues(alpha: 0.8)
          ..strokeWidth = 1.5;
        canvas.drawLine(pos - d, pos + d, link);
        final ball = Paint()..color = palette.smoke;
        canvas.drawCircle(pos - d, 3.5, ball);
        canvas.drawCircle(pos + d, 3.5, ball);
      case ShipShotKind.grape:
        final paint = Paint()..color = palette.light.withValues(alpha: 0.9);
        for (final seed in shot.seeds) {
          canvas.drawCircle(pos + seed * t, 1.8, paint);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _ShipFxPainter old) => true;
}
