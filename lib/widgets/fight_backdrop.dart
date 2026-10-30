// The place a fight happens in (v1.241), painted in code behind the battle:
// a sky and a horizon of the stage's own (dunes, cliffs, a burnt plain, the
// inside of a hall…), the day's weather drifting over it, and the anomaly of
// the moment -- a sandstorm, the earth breaking, a spring welling up --
// swelling in as the omen turns into the thing itself. No image files: a
// stage is a few shapes, so it costs nothing to ship and looks the same each
// time.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../combat/field_anomaly.dart';
import '../data/climate.dart';
import 'journey_fx.dart';

/// The colours of one stage, sky to ground.
class FightScenery {
  const FightScenery({
    required this.skyTop,
    required this.skyLow,
    required this.far,
    required this.mid,
    required this.ground,
    required this.dark,
    required this.light,
  });

  final Color skyTop;
  final Color skyLow;
  final Color far;
  final Color mid;
  final Color ground;
  final Color dark;
  final Color light;

  static FightScenery of(FightStage stage) => switch (stage) {
        FightStage.fields => const FightScenery(
            skyTop: Color(0xFF6E8CA0),
            skyLow: Color(0xFFC9D6B8),
            far: Color(0xFF7C927A),
            mid: Color(0xFF63794F),
            ground: Color(0xFF566B42),
            dark: Color(0xFF3F5030),
            light: Color(0xFFE5E9C6)),
        FightStage.dunes => const FightScenery(
            skyTop: Color(0xFFD9A15E),
            skyLow: Color(0xFFF2D9A4),
            far: Color(0xFFC99A5A),
            mid: Color(0xFFB8864A),
            ground: Color(0xFFA9783F),
            dark: Color(0xFF7F5A2E),
            light: Color(0xFFFFF1CC)),
        FightStage.saltFlats => const FightScenery(
            skyTop: Color(0xFF9FC1CF),
            skyLow: Color(0xFFF1EBDD),
            far: Color(0xFFC9BEA0),
            mid: Color(0xFFDAD0B6),
            ground: Color(0xFFD8CAA6),
            dark: Color(0xFFA3865A),
            light: Color(0xFFFFFFFF)),
        FightStage.waves => const FightScenery(
            skyTop: Color(0xFF38607E),
            skyLow: Color(0xFF9CC3D6),
            far: Color(0xFF2F5D7C),
            mid: Color(0xFF28506C),
            ground: Color(0xFF1E3F57),
            dark: Color(0xFF14293A),
            light: Color(0xFFCFE3EE)),
        FightStage.ash => const FightScenery(
            skyTop: Color(0xFF6D6963),
            skyLow: Color(0xFFA79F94),
            far: Color(0xFF4D4A45),
            mid: Color(0xFF5F5B55),
            ground: Color(0xFF4A4743),
            dark: Color(0xFF2E2C29),
            light: Color(0xFFE9A35B)),
        FightStage.terraces => const FightScenery(
            skyTop: Color(0xFF8E4B3A),
            skyLow: Color(0xFFE0A27A),
            far: Color(0xFF6E3527),
            mid: Color(0xFF8A4632),
            ground: Color(0xFF723A2B),
            dark: Color(0xFF4A241B),
            light: Color(0xFFE9B48A)),
        FightStage.cliffs => const FightScenery(
            skyTop: Color(0xFF7FA3B5),
            skyLow: Color(0xFFD7E1DC),
            far: Color(0xFF6E7F76),
            mid: Color(0xFF52625A),
            ground: Color(0xFF45544D),
            dark: Color(0xFF2F3A35),
            light: Color(0xFFD9DDD2)),
        FightStage.reeds => const FightScenery(
            skyTop: Color(0xFF7A8C80),
            skyLow: Color(0xFFB9C4A8),
            far: Color(0xFF56644F),
            mid: Color(0xFF3E4A3A),
            ground: Color(0xFF2E3A36),
            dark: Color(0xFF1E2724),
            light: Color(0xFFA9B59A)),
        FightStage.snow => const FightScenery(
            skyTop: Color(0xFFA9BCCC),
            skyLow: Color(0xFFF0F4F8),
            far: Color(0xFF9AA7B4),
            mid: Color(0xFFC9D3DD),
            ground: Color(0xFFE3EAF0),
            dark: Color(0xFFA7B6C4),
            light: Color(0xFFFFFFFF)),
        FightStage.glass => const FightScenery(
            skyTop: Color(0xFF8D86A0),
            skyLow: Color(0xFFD9D4DC),
            far: Color(0xFF6E6A73),
            mid: Color(0xFF857F8E),
            ground: Color(0xFFA7A39C),
            dark: Color(0xFF5A5470),
            light: Color(0xFFE9E6DF)),
        FightStage.hall => const FightScenery(
            skyTop: Color(0xFF2C2A33),
            skyLow: Color(0xFF4A4552),
            far: Color(0xFF1F1D25),
            mid: Color(0xFF34313D),
            ground: Color(0xFF3A3642),
            dark: Color(0xFF211F27),
            light: Color(0xFFE9B96B)),
        // Placeholders until UX's board skins (v1.661): grey stone for
        // the streets, a wet deck under a sea sky.
        FightStage.streets => const FightScenery(
            skyTop: Color(0xFF7D8794),
            skyLow: Color(0xFFC8C3B8),
            far: Color(0xFF6B6660),
            mid: Color(0xFF5A554F),
            ground: Color(0xFF77716A),
            dark: Color(0xFF3E3A36),
            light: Color(0xFFE6DCC4)),
        FightStage.deck => const FightScenery(
            skyTop: Color(0xFF5E86A3),
            skyLow: Color(0xFFB9D0DC),
            far: Color(0xFF3F6A86),
            mid: Color(0xFF6E5236),
            ground: Color(0xFF8A6A47),
            dark: Color(0xFF4A3622),
            light: Color(0xFFF0E2C2)),
      };
}

/// How an anomaly is on the screen: not yet, announced, or upon the party.
double anomalyLevelOf(AnomalyPhase phase) => switch (phase) {
      AnomalyPhase.omen => 0.3,
      AnomalyPhase.active => 1.0,
      _ => 0.0,
    };

/// The fight's backdrop: [stage]'s scenery, [sky]'s weather over it, and
/// [anomaly] drawn at the level its [phase] asks. Draws nothing that takes
/// a touch, and holds still with reduced motion.
class FightBackdrop extends StatefulWidget {
  const FightBackdrop({
    super.key,
    required this.stage,
    this.sky,
    this.anomaly,
    this.phase = AnomalyPhase.quiet,
    this.light = 1,
  });

  /// How much of the day's light there is (see lightLevel in
  /// place_traits.dart): 1 by day, down to pitch dark.
  final double light;

  final FightStage stage;
  final WeatherKind? sky;
  final FieldAnomaly? anomaly;
  final AnomalyPhase phase;

  @override
  State<FightBackdrop> createState() => _FightBackdropState();
}

class _Frame extends ChangeNotifier {
  double t = 0;
  double level = 0;

  void tick(double t, double level) {
    this.t = t;
    this.level = level;
    notifyListeners();
  }
}

class _FightBackdropState extends State<FightBackdrop>
    with SingleTickerProviderStateMixin {
  final _Frame _frame = _Frame();
  Ticker? _ticker;
  Duration _last = Duration.zero;
  double _t = 0;
  double _level = 0;

  double get _target =>
      widget.anomaly == null ? 0 : anomalyLevelOf(widget.phase);

  bool _still(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _level = _target;
    _frame.tick(0, _level);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = !_still(context) && TickerMode.valuesOf(context).enabled;
    if (on) {
      _ticker ??= createTicker(_onTick);
      if (!_ticker!.isActive) _ticker!.start();
    } else {
      _ticker?.stop();
      _last = Duration.zero;
      _level = _target;
      _frame.tick(_t, _level);
    }
  }

  @override
  void didUpdateWidget(FightBackdrop old) {
    super.didUpdateWidget(old);
    if (_ticker?.isActive != true) {
      _level = _target;
      _frame.tick(_t, _level);
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _t += dt;
    final step = dt * 0.7;
    final target = _target;
    if ((_level - target).abs() <= step) {
      _level = target;
    } else {
      _level += _level < target ? step : -step;
    }
    _frame.tick(_t, _level);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _FightBackdropPainter(
          frame: _frame,
          stage: widget.stage,
          sky: widget.sky,
          anomalyId: widget.anomaly?.id,
          light: widget.light,
        ),
      ),
    );
  }
}

class _FightBackdropPainter extends CustomPainter {
  _FightBackdropPainter({
    required _Frame frame,
    required this.stage,
    required this.sky,
    required this.anomalyId,
    required this.light,
  })  : _frame = frame,
        super(repaint: frame);

  final _Frame _frame;
  final FightStage stage;
  final WeatherKind? sky;
  final String? anomalyId;
  final double light;

  @override
  void paint(Canvas canvas, Size size) {
    paintFightBackdrop(
      canvas,
      size,
      stage: stage,
      sky: sky,
      anomalyId: anomalyId,
      t: _frame.t,
      level: _frame.level,
      light: light,
    );
  }

  @override
  bool shouldRepaint(_FightBackdropPainter old) =>
      old.stage != stage ||
      old.sky != sky ||
      old.anomalyId != anomalyId ||
      old.light != light;
}

/// One frame of the backdrop, from time and level alone (so a test can draw
/// any moment of it).
void paintFightBackdrop(
  Canvas canvas,
  Size size, {
  required FightStage stage,
  required WeatherKind? sky,
  required String? anomalyId,
  required double t,
  required double level,
  double light = 1,
}) {
  if (size.isEmpty) return;
  final scenery = FightScenery.of(stage);
  canvas.save();
  canvas.clipRect(Offset.zero & size);
  _paintStage(canvas, size, stage, scenery, t);
  // The day's weather, over the stage.
  final weather = journeyWeatherOf(sky, 0);
  if (weather != JourneyWeather.none && stage != FightStage.hall) {
    paintJourneyWeather(canvas, size, t, weather, _weatherColour(weather),
        count: 22);
  }
  if (anomalyId != null && level > 0) {
    _paintAnomaly(canvas, size, anomalyId, scenery, t, level);
  }
  // Night and dark: the missing light as a cold veil over everything.
  if (light < 1) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = const Color(0xFF070A18).withValues(alpha: (1 - light) * 0.7),
    );
  }
  canvas.restore();
}

Color _weatherColour(JourneyWeather weather) => switch (weather) {
      JourneyWeather.rain => const Color(0xFFBFDCE6),
      JourneyWeather.snow => const Color(0xFFF4F8FB),
      JourneyWeather.dust => const Color(0xFFD9B77A),
      JourneyWeather.ash => const Color(0xFFB9B2A8),
      _ => const Color(0xFFDCE3E6),
    };

double _h(num n) {
  final x = math.sin(n * 12.9898) * 43758.5453;
  return x - x.floorToDouble();
}

// --- The stages -------------------------------------------------------------

void _paintStage(
    Canvas canvas, Size size, FightStage stage, FightScenery s, double t) {
  final w = size.width, h = size.height;
  final horizon = stage == FightStage.hall ? h * 0.58 : h * 0.5;
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [s.skyTop, s.skyLow],
        stops: const [0.0, 0.55],
      ).createShader(Offset.zero & size),
  );
  switch (stage) {
    case FightStage.fields:
      _hills(canvas, size, horizon, s.far, 0.05, 1.3, 0);
      _hills(canvas, size, horizon + h * 0.04, s.mid, 0.07, 0.9, 3);
      _trees(canvas, size, horizon + h * 0.03, s.dark);
      _ground(canvas, size, horizon + h * 0.1, s);
      _furrows(canvas, size, horizon + h * 0.1, s.dark);
    case FightStage.dunes:
      _sun(canvas, size, Offset(w * 0.75, horizon - h * 0.16), s.light, 26);
      _hills(canvas, size, horizon, s.far, 0.06, 0.8, 1);
      _hills(canvas, size, horizon + h * 0.05, s.mid, 0.08, 0.6, 5);
      _ground(canvas, size, horizon + h * 0.12, s);
      _ripples(canvas, size, horizon + h * 0.12, s.dark);
    case FightStage.saltFlats:
      _sun(canvas, size, Offset(w * 0.3, horizon - h * 0.2), s.light, 30);
      _mesas(canvas, size, horizon, s.far);
      _ground(canvas, size, horizon + h * 0.02, s);
      _cracks(canvas, size, horizon + h * 0.02, s.dark);
    case FightStage.waves:
      _sun(canvas, size, Offset(w * 0.2, horizon - h * 0.14), s.light, 22);
      _sea(canvas, size, horizon - h * 0.04, s, t);
      _sail(canvas, size, Offset(w * 0.68, horizon - h * 0.04), s.dark);
    case FightStage.ash:
      _volcano(canvas, size, horizon, s, t);
      _hills(canvas, size, horizon + h * 0.04, s.mid, 0.04, 1.1, 2);
      _ground(canvas, size, horizon + h * 0.1, s);
      _embers(canvas, size, horizon + h * 0.1, s.light, t, 6);
    case FightStage.terraces:
      _steps(canvas, size, horizon, s.far, 0.7, 4);
      _steps(canvas, size, horizon + h * 0.05, s.mid, 1.0, 5);
      _ground(canvas, size, horizon + h * 0.05 + 4, s);
      _vents(canvas, size, horizon + h * 0.12, s.light, t);
    case FightStage.cliffs:
      _sea(canvas, size, horizon + h * 0.02, s, t, shallow: true);
      _cliff(canvas, size, left: true, color: s.mid, dark: s.dark);
      _cliff(canvas, size, left: false, color: s.far, dark: s.dark);
      _ground(canvas, size, horizon + h * 0.13, s);
    case FightStage.reeds:
      _hills(canvas, size, horizon, s.far, 0.03, 1.5, 4);
      _ground(canvas, size, horizon + h * 0.05, s);
      _pools(canvas, size, horizon + h * 0.05, s.light, t);
      _reeds(canvas, size, s.mid, s.dark, t);
    case FightStage.snow:
      _peaks(canvas, size, horizon, s);
      _hills(canvas, size, horizon + h * 0.04, s.mid, 0.05, 1.0, 6);
      _ground(canvas, size, horizon + h * 0.1, s);
    case FightStage.glass:
      _ground(canvas, size, horizon + h * 0.02, s);
      _shards(canvas, size, horizon + h * 0.02, s, t);
    case FightStage.hall:
      _hall(canvas, size, horizon, s, t);
    // Placeholders until UX's board skins (v1.661).
    case FightStage.streets:
      _hills(canvas, size, horizon, s.far, 0.05, 1.3, 0);
      _ground(canvas, size, horizon + h * 0.1, s);
    case FightStage.deck:
      _sea(canvas, size, horizon - h * 0.04, s, t);
      _sail(canvas, size, Offset(w * 0.68, horizon - h * 0.04), s.dark);
  }
}

void _ground(Canvas canvas, Size size, double y, FightScenery s) {
  final rect = Rect.fromLTRB(0, y, size.width, size.height);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [s.ground, s.dark],
      ).createShader(rect),
  );
}

void _hills(Canvas canvas, Size size, double base, Color colour, double amp,
    double freq, int seed) {
  final path = Path()..moveTo(0, size.height);
  for (var x = 0.0; x <= size.width + 6; x += 6) {
    final u = x / size.width;
    final y = base -
        size.height *
            amp *
            (0.5 +
                0.5 *
                    math.sin(u * math.pi * 2 * freq + seed) *
                    math.cos(u * math.pi * 1.3 + seed * 0.7));
    path.lineTo(x, y);
  }
  path
    ..lineTo(size.width, size.height)
    ..close();
  canvas.drawPath(path, Paint()..color = colour);
}

void _trees(Canvas canvas, Size size, double y, Color colour) {
  final paint = Paint()..color = colour.withValues(alpha: 0.85);
  for (var i = 0; i < 7; i++) {
    final x = size.width * (0.05 + _h(i * 3 + 1) * 0.9);
    final r = 5 + _h(i + 40) * 6;
    canvas.drawRect(Rect.fromLTWH(x - 1, y - r, 2, r), paint);
    canvas.drawCircle(Offset(x, y - r * 1.5), r, paint);
  }
}

void _furrows(Canvas canvas, Size size, double y, Color colour) {
  final paint = Paint()
    ..color = colour.withValues(alpha: 0.35)
    ..strokeWidth = 1.2;
  final vanish = Offset(size.width * 0.5, y - size.height * 0.1);
  for (var i = -6; i <= 6; i++) {
    canvas.drawLine(
        vanish, Offset(size.width * (0.5 + i * 0.22), size.height), paint);
  }
}

void _sun(Canvas canvas, Size size, Offset at, Color colour, double radius) {
  canvas.drawCircle(
    at,
    radius * 2.6,
    Paint()
      ..shader = RadialGradient(colors: [
        colour.withValues(alpha: 0.55),
        colour.withValues(alpha: 0),
      ]).createShader(Rect.fromCircle(center: at, radius: radius * 2.6)),
  );
  canvas.drawCircle(at, radius, Paint()..color = colour.withValues(alpha: 0.9));
}

void _ripples(Canvas canvas, Size size, double y, Color colour) {
  final paint = Paint()
    ..color = colour.withValues(alpha: 0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1;
  for (var row = 0; row < 7; row++) {
    final yy = y + (size.height - y) * (row + 1) / 8;
    final path = Path()..moveTo(0, yy);
    for (var x = 0.0; x <= size.width; x += 8) {
      path.lineTo(x, yy + math.sin(x * 0.05 + row * 1.7) * (2 + row * 0.7));
    }
    canvas.drawPath(path, paint);
  }
}

void _mesas(Canvas canvas, Size size, double y, Color colour) {
  final paint = Paint()..color = colour;
  for (var i = 0; i < 4; i++) {
    final x = size.width * (0.08 + i * 0.26 + _h(i + 3) * 0.08);
    final w = size.width * (0.1 + _h(i + 9) * 0.08);
    final hh = size.height * (0.03 + _h(i + 17) * 0.05);
    canvas.drawRect(Rect.fromLTWH(x, y - hh, w, hh + 2), paint);
  }
}

void _cracks(Canvas canvas, Size size, double y, Color colour) {
  final paint = Paint()
    ..color = colour.withValues(alpha: 0.4)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  for (var i = 0; i < 16; i++) {
    final a = Offset(size.width * _h(i + 70),
        y + (size.height - y) * (0.05 + _h(i + 80) * 0.95));
    final b = a + Offset((_h(i + 90) - 0.5) * 70, (_h(i + 99) - 0.3) * 30);
    final c = b + Offset((_h(i + 110) - 0.5) * 50, (_h(i + 120) - 0.2) * 24);
    canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(c.dx, c.dy),
        paint);
  }
}

void _sea(Canvas canvas, Size size, double y, FightScenery s, double t,
    {bool shallow = false}) {
  final rect = Rect.fromLTRB(0, y, size.width, size.height);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [s.far, s.dark],
      ).createShader(rect),
  );
  final paint = Paint()
    ..color = s.light.withValues(alpha: shallow ? 0.25 : 0.32)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  for (var row = 0; row < 9; row++) {
    final yy = y + (size.height - y) * (row + 0.5) / 9;
    final path = Path()..moveTo(0, yy);
    for (var x = 0.0; x <= size.width; x += 6) {
      path.lineTo(
          x,
          yy +
              math.sin(x * 0.04 + row * 2.1 + t * (0.6 + row * 0.08)) *
                  (1 + row * 0.5));
    }
    canvas.drawPath(path, paint);
  }
}

void _sail(Canvas canvas, Size size, Offset at, Color colour) {
  final paint = Paint()..color = colour.withValues(alpha: 0.8);
  canvas.drawPath(
      Path()
        ..moveTo(at.dx, at.dy)
        ..lineTo(at.dx, at.dy - 26)
        ..lineTo(at.dx + 15, at.dy - 5)
        ..close(),
      paint);
  canvas.drawRect(Rect.fromLTWH(at.dx - 10, at.dy, 26, 3), paint);
}

void _volcano(Canvas canvas, Size size, double y, FightScenery s, double t) {
  final cx = size.width * 0.34;
  final top = y - size.height * 0.2;
  final cone = Path()
    ..moveTo(cx - size.width * 0.34, y + 4)
    ..lineTo(cx - 18, top)
    ..lineTo(cx + 18, top)
    ..lineTo(cx + size.width * 0.38, y + 4)
    ..close();
  canvas.drawPath(cone, Paint()..color = s.far);
  canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, top), width: 40, height: 9),
      Paint()..color = s.light.withValues(alpha: 0.75));
  for (var i = 0; i < 5; i++) {
    final p = ((t * 0.05) + i / 5) % 1.0;
    canvas.drawCircle(
      Offset(
          cx + math.sin(p * 6 + i) * 10 + p * 24, top - p * size.height * 0.3),
      9 + p * 20,
      Paint()
        ..color = s.skyLow.withValues(alpha: (1 - p) * 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }
}

void _embers(
    Canvas canvas, Size size, double y, Color colour, double t, int count) {
  for (var i = 0; i < count; i++) {
    final p = ((t * 0.12) + _h(i + 5)) % 1.0;
    final x = size.width * _h(i + 25) + math.sin(t + i) * 6;
    final yy = size.height - (size.height - y) * p * 1.1;
    canvas.drawCircle(Offset(x, yy), 1.6,
        Paint()..color = colour.withValues(alpha: math.sin(math.pi * p) * 0.9));
  }
}

void _steps(
    Canvas canvas, Size size, double y, Color colour, double scale, int count) {
  final paint = Paint()..color = colour;
  final step = size.width / count;
  for (var i = 0; i < count; i++) {
    final hh = size.height * (0.04 + _h(i * 5 + 2) * 0.1) * scale;
    final top = y - hh;
    final x = i * step - 4;
    canvas.drawRect(Rect.fromLTWH(x, top, step + 8, hh + 4), paint);
    canvas.drawRect(
        Rect.fromLTWH(x + step * 0.1, top - hh * 0.35, step * 0.7, hh * 0.38),
        paint);
  }
}

void _vents(Canvas canvas, Size size, double y, Color colour, double t) {
  for (var i = 0; i < 3; i++) {
    final x = size.width * (0.2 + i * 0.3);
    for (var k = 0; k < 4; k++) {
      final p = ((t * 0.18) + k / 4 + i * 0.3) % 1.0;
      canvas.drawCircle(
        Offset(x + math.sin(p * 5 + i) * 6, y + 8 - p * size.height * 0.18),
        5 + p * 12,
        Paint()
          ..color = colour.withValues(alpha: (1 - p) * 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }
}

void _cliff(Canvas canvas, Size size,
    {required bool left, required Color color, required Color dark}) {
  final w = size.width * (left ? 0.3 : 0.22);
  final path = Path()..moveTo(left ? 0 : size.width, 0);
  const steps = 9;
  for (var i = 0; i <= steps; i++) {
    final u = i / steps;
    final edge =
        w * (0.55 + 0.45 * _h(i * 7 + (left ? 1 : 50))) * (1 - u * 0.2);
    path.lineTo(left ? edge : size.width - edge, size.height * 0.62 * u);
  }
  path.lineTo(left ? 0 : size.width, size.height * 0.62);
  path.close();
  canvas.drawPath(path, Paint()..color = color);
  canvas.drawPath(
      path,
      Paint()
        ..color = dark.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
}

void _pools(Canvas canvas, Size size, double y, Color colour, double t) {
  for (var i = 0; i < 6; i++) {
    final x = size.width * (0.1 + _h(i + 3) * 0.8);
    final yy = y + (size.height - y) * (0.1 + _h(i + 13) * 0.8);
    final w = 40 + _h(i + 23) * 70;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, yy), width: w, height: w * 0.18),
      Paint()..color = colour.withValues(alpha: 0.18 + math.sin(t + i) * 0.04),
    );
  }
}

void _reeds(Canvas canvas, Size size, Color a, Color b, double t) {
  for (var i = 0; i < 46; i++) {
    final x =
        size.width * (i % 2 == 0 ? _h(i + 4) * 0.22 : 1 - _h(i + 8) * 0.22);
    final hh = size.height * (0.12 + _h(i + 60) * 0.26);
    final sway = math.sin(t * 0.9 + i) * 3;
    final paint = Paint()
      ..color = (i % 3 == 0 ? b : a).withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        Path()
          ..moveTo(x, size.height)
          ..quadraticBezierTo(x + sway * 0.5, size.height - hh * 0.5, x + sway,
              size.height - hh),
        paint);
  }
}

void _peaks(Canvas canvas, Size size, double y, FightScenery s) {
  for (var i = 0; i < 4; i++) {
    final cx = size.width * (0.1 + i * 0.27 + _h(i + 1) * 0.06);
    final hh = size.height * (0.14 + _h(i + 11) * 0.12);
    final half = size.width * 0.17;
    final path = Path()
      ..moveTo(cx - half, y + 2)
      ..lineTo(cx, y - hh)
      ..lineTo(cx + half, y + 2)
      ..close();
    canvas.drawPath(path, Paint()..color = s.far);
    canvas.drawPath(
        Path()
          ..moveTo(cx - half * 0.3, y - hh * 0.7)
          ..lineTo(cx, y - hh)
          ..lineTo(cx + half * 0.3, y - hh * 0.7)
          ..lineTo(cx + half * 0.1, y - hh * 0.62)
          ..lineTo(cx - half * 0.05, y - hh * 0.72)
          ..close(),
        Paint()..color = s.light.withValues(alpha: 0.9));
  }
}

void _shards(Canvas canvas, Size size, double y, FightScenery s, double t) {
  for (var i = 0; i < 11; i++) {
    final x = size.width * (0.03 + _h(i + 2) * 0.94);
    final hh = size.height * (0.08 + _h(i + 12) * 0.2);
    final lean = (_h(i + 22) - 0.5) * 30;
    final w = 8 + _h(i + 32) * 14;
    final path = Path()
      ..moveTo(x - w / 2, y + 6)
      ..lineTo(x + lean, y - hh)
      ..lineTo(x + w / 2, y + 6)
      ..close();
    canvas.drawPath(path, Paint()..color = s.mid.withValues(alpha: 0.75));
    canvas.drawPath(
        path,
        Paint()
          ..color = s.light.withValues(alpha: 0.35 + math.sin(t + i) * 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }
}

void _hall(Canvas canvas, Size size, double floor, FightScenery s, double t) {
  final w = size.width;
  // The back wall's arches, receding.
  for (var i = 0; i < 5; i++) {
    final x = w * (0.1 + i * 0.2);
    final pillar = Paint()..color = s.mid.withValues(alpha: 0.9);
    canvas.drawRect(Rect.fromLTWH(x - 7, size.height * 0.1, 14, floor), pillar);
    if (i < 4) {
      canvas.drawArc(
          Rect.fromLTWH(x, size.height * 0.1 - w * 0.07, w * 0.2, w * 0.14),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = s.mid
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7);
    }
  }
  _ground(canvas, size, floor, s);
  final lines = Paint()
    ..color = s.dark.withValues(alpha: 0.7)
    ..strokeWidth = 1.2;
  for (var i = -8; i <= 8; i++) {
    canvas.drawLine(Offset(w * 0.5, floor),
        Offset(w * (0.5 + i * 0.2), size.height), lines);
  }
  for (var row = 1; row < 6; row++) {
    final yy = floor + (size.height - floor) * math.pow(row / 6, 1.7);
    canvas.drawLine(Offset(0, yy.toDouble()), Offset(w, yy.toDouble()), lines);
  }
  // Torches on the pillars, flickering.
  for (var i = 0; i < 5; i += 2) {
    final at = Offset(w * (0.1 + i * 0.2), size.height * 0.1 + floor * 0.45);
    final flicker = 0.75 + math.sin(t * 9 + i * 2) * 0.12;
    canvas.drawCircle(
      at,
      30,
      Paint()
        ..shader = RadialGradient(colors: [
          s.light.withValues(alpha: 0.45 * flicker),
          s.light.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: at, radius: 30)),
    );
    canvas.drawCircle(at, 3, Paint()..color = s.light);
  }
}

// --- The anomalies ------------------------------------------------------------

void _veil(Canvas canvas, Size size, Color colour, double alpha) {
  canvas.drawRect(Offset.zero & size,
      Paint()..color = colour.withValues(alpha: alpha.clamp(0.0, 1.0)));
}

void _streaks(Canvas canvas, Size size, double t, Color colour, double level,
    {int count = 36,
    double speed = 0.5,
    double length = 22,
    double slope = 0.1}) {
  final paint = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.4;
  final n = (count * level).round();
  for (var i = 0; i < n; i++) {
    final p = ((t * speed * (0.6 + _h(i) * 0.8)) + _h(i + 50)) % 1.0;
    final x = p * (size.width + length * 2) - length;
    final y = size.height * (0.1 + _h(i + 10) * 0.85);
    paint.color =
        colour.withValues(alpha: math.sin(math.pi * p) * 0.55 * level);
    canvas.drawLine(
        Offset(x, y), Offset(x - length, y + length * slope), paint);
  }
}

void _rain(Canvas canvas, Size size, double t, Color colour, double level,
    {int count = 70, double slant = 0.25}) {
  final paint = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.3;
  final n = (count * level).round();
  for (var i = 0; i < n; i++) {
    final p = ((t * (1.4 + _h(i) * 0.8)) + _h(i + 70)) % 1.0;
    final x = ((_h(i + 20) - slant * p) % 1.0) * size.width;
    final y = p * (size.height + 30) - 15;
    paint.color = colour.withValues(alpha: 0.5 * level);
    canvas.drawLine(Offset(x, y), Offset(x - 5 * slant * 4, y + 14), paint);
  }
}

void _flash(Canvas canvas, Size size, double t, double level) {
  final phase = t % 3.6;
  final f = phase > 3.2 && phase < 3.5
      ? (phase < 3.3 ? 0.5 : (phase < 3.4 ? 0.12 : 0.3))
      : 0.0;
  if (f > 0) _veil(canvas, size, const Color(0xFFEAF4FF), f * level);
}

void _motes(Canvas canvas, Size size, double t, Color colour, double level,
    {int count = 22, bool up = true, double radius = 2.2}) {
  final n = (count * level).round();
  for (var i = 0; i < n; i++) {
    final p = ((t * (0.08 + _h(i) * 0.1)) + _h(i + 30)) % 1.0;
    final x = size.width * _h(i + 5) + math.sin(t * 1.2 + i) * 8;
    final y = up ? size.height * (1 - p) : size.height * p;
    canvas.drawCircle(
        Offset(x, y),
        radius * (0.6 + _h(i + 60)),
        Paint()
          ..color =
              colour.withValues(alpha: math.sin(math.pi * p) * 0.75 * level));
  }
}

void _fogBanks(Canvas canvas, Size size, double t, Color colour, double level) {
  final paint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
  for (var k = 0; k < 6; k++) {
    final x =
        ((_h(k + 3) + t * 0.01 * (1 + _h(k + 9))) % 1.3 - 0.15) * size.width;
    final y = (0.2 + _h(k + 15) * 0.7) * size.height;
    paint.color = colour.withValues(alpha: 0.28 * level);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(x, y), width: size.width * 0.7, height: 46),
        paint);
  }
}

void _cracksGlow(
    Canvas canvas, Size size, double t, Color colour, double level) {
  final glow = Paint()
    ..color = colour.withValues(alpha: 0.5 * level)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  final line = Paint()
    ..color = const Color(0xFF1A120E).withValues(alpha: 0.85 * level)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 4; i++) {
    final x0 = size.width * (0.18 + i * 0.22 + _h(i + 1) * 0.06);
    final path = Path()..moveTo(x0, size.height);
    var x = x0, y = size.height;
    final reach = size.height * (0.28 + _h(i + 7) * 0.2) * level;
    for (var s = 0; s < 7 && size.height - y < reach; s++) {
      x += (_h(i * 11 + s) - 0.5) * 34;
      y -= reach / 7;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);
  }
  // The ground jolts: a low dust at the foot of the screen.
  final shake = math.sin(t * 24) * 2 * level;
  canvas.drawRect(
      Rect.fromLTWH(shake, size.height * 0.94, size.width, size.height * 0.06),
      Paint()..color = colour.withValues(alpha: 0.12 * level));
}

void _falling(Canvas canvas, Size size, double t, Color colour, double level) {
  final n = (14 * level).round();
  for (var i = 0; i < n; i++) {
    final p = ((t * (0.7 + _h(i) * 0.6)) + _h(i + 40)) % 1.0;
    final x = size.width * _h(i + 3);
    final y = p * size.height;
    final r = 2.5 + _h(i + 80) * 4;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(t * 3 + i);
    canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 1.4),
        Paint()..color = colour.withValues(alpha: 0.85 * level));
    canvas.restore();
  }
}

void _rays(Canvas canvas, Size size, double t, Color colour, double level) {
  final origin = Offset(size.width * 0.78, -10);
  for (var i = 0; i < 6; i++) {
    final a = 1.9 + i * 0.16 + math.sin(t * 0.3 + i) * 0.02;
    final end = origin + Offset(math.cos(a), math.sin(a)) * size.height * 1.3;
    canvas.drawLine(
        origin,
        end,
        Paint()
          ..color = colour.withValues(alpha: 0.16 * level)
          ..strokeWidth = 18 + i * 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  }
}

void _eclipse(Canvas canvas, Size size, double t, double level) {
  _veil(canvas, size, const Color(0xFF05060F), 0.4 * level);
  final at = Offset(size.width * 0.5, size.height * 0.2);
  canvas.drawCircle(
    at,
    52,
    Paint()
      ..shader = RadialGradient(colors: [
        const Color(0x00000000),
        const Color(0xFFBFB6FF).withValues(alpha: 0.55 * level),
        const Color(0x00000000),
      ], stops: const [
        0.55,
        0.62,
        1.0
      ]).createShader(Rect.fromCircle(center: at, radius: 52)),
  );
  canvas.drawCircle(at, 30, Paint()..color = const Color(0xFF05060F));
}

void _tide(Canvas canvas, Size size, double t, Color colour, double level) {
  final rise = size.height * (0.12 + math.sin(t * 0.7) * 0.03) * level;
  final path = Path()..moveTo(0, size.height);
  for (var x = 0.0; x <= size.width; x += 8) {
    path.lineTo(x, size.height - rise + math.sin(x * 0.05 + t * 2) * 5);
  }
  path
    ..lineTo(size.width, size.height)
    ..close();
  canvas.drawPath(path, Paint()..color = colour.withValues(alpha: 0.5 * level));
}

void _sheen(Canvas canvas, Size size, double t, double level) {
  for (var i = 0; i < 5; i++) {
    final y = size.height * (0.62 + i * 0.07);
    final x = ((t * 0.1 + _h(i)) % 1.0) * size.width;
    canvas.drawLine(
        Offset(x - 60, y),
        Offset(x + 60, y),
        Paint()
          ..color = const Color(0xFFEAF6FF).withValues(alpha: 0.45 * level)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round);
  }
}

void _heat(Canvas canvas, Size size, double t, double level) {
  _veil(canvas, size, const Color(0xFFFFB45A), 0.12 * level);
  final paint = Paint()
    ..color = const Color(0xFFFFE2A8).withValues(alpha: 0.28 * level)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  for (var row = 0; row < 6; row++) {
    final y = size.height * (0.5 + row * 0.08);
    final path = Path()..moveTo(0, y);
    for (var x = 0.0; x <= size.width; x += 6) {
      path.lineTo(x, y + math.sin(x * 0.06 + t * 3 + row) * 3);
    }
    canvas.drawPath(path, paint);
  }
}

void _anomalyGlint(
    Canvas canvas, Size size, double t, Color colour, double level) {
  final n = (14 * level).round();
  for (var i = 0; i < n; i++) {
    final x = size.width * _h(i + 2);
    final y = size.height * (0.15 + _h(i + 12) * 0.8);
    final a = math.max(0.0, math.sin(t * 2 + i * 1.7));
    final r = 3 + a * 5;
    final paint = Paint()
      ..color = colour.withValues(alpha: a * 0.8 * level)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(x - r, y), Offset(x + r, y), paint);
    canvas.drawLine(Offset(x, y - r), Offset(x, y + r), paint);
  }
}

void _paintAnomaly(Canvas canvas, Size size, String id, FightScenery s,
    double t, double level) {
  switch (id) {
    case 'sandstorm':
      _veil(canvas, size, const Color(0xFFC79A55), 0.3 * level);
      _streaks(canvas, size, t, const Color(0xFFE6C690), level,
          count: 60, speed: 0.9, length: 30, slope: 0.05);
    case 'ash_storm':
      _veil(canvas, size, const Color(0xFF4B4743), 0.32 * level);
      _streaks(canvas, size, t, const Color(0xFFC9C2B6), level,
          count: 50, speed: 0.7, length: 20, slope: 0.18);
      _motes(canvas, size, t, const Color(0xFFE9A35B), level, count: 16);
    case 'heatstroke':
      _heat(canvas, size, t, level);
    case 'salt_glare':
      _veil(canvas, size, const Color(0xFFFFFFFF), 0.32 * level);
      _anomalyGlint(canvas, size, t, const Color(0xFFFFFFFF), level);
    case 'brine_crust':
      _sheen(canvas, size, t, level);
    case 'sea_storm':
      _veil(canvas, size, const Color(0xFF16273A), 0.34 * level);
      _rain(canvas, size, t, const Color(0xFFBFDCE6), level, count: 80);
      _flash(canvas, size, t, level);
      _tide(canvas, size, t, const Color(0xFF3A7CA5), level * 0.7);
    case 'thunderstorm':
      _veil(canvas, size, const Color(0xFF1B2433), 0.36 * level);
      _rain(canvas, size, t, const Color(0xFFBFDCE6), level, count: 70);
      _flash(canvas, size, t, level);
    case 'downpour':
      _veil(canvas, size, const Color(0xFF2B3B4A), 0.3 * level);
      _rain(canvas, size, t, const Color(0xFFD2E6EE), level,
          count: 130, slant: 0.12);
    case 'flash_flood':
      _rain(canvas, size, t, const Color(0xFFD2E6EE), level, count: 60);
      _tide(canvas, size, t, const Color(0xFF6B8C72), level);
    case 'hailstorm':
      _veil(canvas, size, const Color(0xFF3B4650), 0.22 * level);
      _motes(canvas, size, t * 6, const Color(0xFFF4F8FB), level,
          count: 40, up: false, radius: 2.6);
    case 'fog_bank':
      _fogBanks(canvas, size, t, const Color(0xFFE3E9E8), level);
    case 'whiteout':
      _veil(canvas, size, const Color(0xFFF4F8FB), 0.4 * level);
      _streaks(canvas, size, t, const Color(0xFFFFFFFF), level,
          count: 54, speed: 0.8, length: 26, slope: 0.22);
    case 'black_ice':
      _sheen(canvas, size, t, level);
      _anomalyGlint(canvas, size, t, const Color(0xFFDDF1FF), level);
    case 'earth_break':
      _cracksGlow(canvas, size, t, const Color(0xFFE08A3C), level);
    case 'rockslide':
    case 'cliff_fall':
    case 'collapse':
      _falling(canvas, size, t, s.dark, level);
      _veil(canvas, size, const Color(0xFF3A332C), 0.16 * level);
    case 'sinking_ground':
      _veil(canvas, size, const Color(0xFF26301E), 0.2 * level);
      _motes(canvas, size, t, const Color(0xFF9DAA7C), level, count: 14);
    case 'marsh_lights':
      _motes(canvas, size, t, const Color(0xFFBFF2C6), level,
          count: 14, radius: 3.4);
    case 'racing_tide':
      _tide(canvas, size, t, const Color(0xFF4A8CB5), level);
    case 'ember_pits':
    case 'scalding_vent':
      _heat(canvas, size, t, level * 0.7);
      _motes(canvas, size, t, const Color(0xFFFF9B3D), level, count: 26);
    case 'blaze':
      _veil(canvas, size, const Color(0xFFD9602A), 0.2 * level);
      _motes(canvas, size, t, const Color(0xFFFFC46B), level,
          count: 32, radius: 2.6);
    case 'glass_field':
      _anomalyGlint(canvas, size, t, const Color(0xFFFFFFFF), level);
      _veil(canvas, size, const Color(0xFFCFC6F2), 0.12 * level);
    case 'eclipse':
      _eclipse(canvas, size, t, level);
    case 'sunburst':
      _rays(canvas, size, t, const Color(0xFFFFE9A8), level);
    case 'wellspring':
      _motes(canvas, size, t, const Color(0xFF9CF0D2), level, count: 30);
    case 'tailwind':
      _streaks(canvas, size, t, const Color(0xFFEFF6F2), level,
          count: 30, speed: 0.9, length: 40, slope: 0.02);
    default:
      _veil(canvas, size, s.dark, 0.1 * level);
  }
}
