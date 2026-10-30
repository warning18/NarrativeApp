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
import 'fight_pixel_stage.dart';
import 'side_view/side_view.dart' show SideParticles, paintSideParticles;

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
        FightStage.ruins => const FightScenery(
            skyTop: Color(0xFF6B6560),
            skyLow: Color(0xFFB8AB9B),
            far: Color(0xFF55504B),
            mid: Color(0xFF433F3B),
            ground: Color(0xFF4C453E),
            dark: Color(0xFF2A2724),
            light: Color(0xFFE2C79A)),
        FightStage.woods => const FightScenery(
            skyTop: Color(0xFF7E967F),
            skyLow: Color(0xFFC3D0B2),
            far: Color(0xFF58744F),
            mid: Color(0xFF3F5A3B),
            ground: Color(0xFF3A4A30),
            dark: Color(0xFF22301F),
            light: Color(0xFFF1EBB8)),
        FightStage.ford => const FightScenery(
            skyTop: Color(0xFF7799AE),
            skyLow: Color(0xFFD4DEC9),
            far: Color(0xFF7C927A),
            mid: Color(0xFF63794F),
            ground: Color(0xFF566B42),
            dark: Color(0xFF3F5030),
            light: Color(0xFFCFE6EE)),
        FightStage.burntFields => const FightScenery(
            skyTop: Color(0xFF7A5A4A),
            skyLow: Color(0xFFD99A68),
            far: Color(0xFF4A3B33),
            mid: Color(0xFF3A2F2A),
            ground: Color(0xFF2F2723),
            dark: Color(0xFF1B1613),
            light: Color(0xFFFFB45C)),
        FightStage.oasis => const FightScenery(
            skyTop: Color(0xFFDDA862),
            skyLow: Color(0xFFF2D9A4),
            far: Color(0xFFC99A5A),
            mid: Color(0xFFB8864A),
            ground: Color(0xFFC79A58),
            dark: Color(0xFF7F5A2E),
            light: Color(0xFFFFF1CC)),
        FightStage.caravanRoad => const FightScenery(
            skyTop: Color(0xFFD28E5A),
            skyLow: Color(0xFFF0CFA0),
            far: Color(0xFFB98650),
            mid: Color(0xFFA9783F),
            ground: Color(0xFFB98B4C),
            dark: Color(0xFF7F5A2E),
            light: Color(0xFFFFF1CC)),
        FightStage.quay => const FightScenery(
            skyTop: Color(0xFF2F4A66),
            skyLow: Color(0xFFC59A78),
            far: Color(0xFF27425C),
            mid: Color(0xFF1F364B),
            ground: Color(0xFF5A4636),
            dark: Color(0xFF2C2118),
            light: Color(0xFFFFC66B)),
        FightStage.pass => const FightScenery(
            skyTop: Color(0xFF8AA0AE),
            skyLow: Color(0xFFDCD3BC),
            far: Color(0xFF8B8576),
            mid: Color(0xFF6E685B),
            ground: Color(0xFF8A8068),
            dark: Color(0xFF4F4A3E),
            light: Color(0xFFF1E7C9)),
        // Placeholders until UX's board skins (v1.662): grey stone for
        // the streets, a wet deck under a sea sky.
        FightStage.cityRoad => const FightScenery(
            skyTop: Color(0xFF7D8794),
            skyLow: Color(0xFFC8C3B8),
            far: Color(0xFF6B6660),
            mid: Color(0xFF5A554F),
            ground: Color(0xFF77716A),
            dark: Color(0xFF3E3A36),
            light: Color(0xFFE6DCC4)),
        FightStage.shipDeck => const FightScenery(
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
  paintPixelStage(canvas, size, stage,
      stars: light <= 0.5 ? 34 : (light < 1 ? 8 : 0));
  // The day's weather over the stage, as the scenes draw it: pixel streaks.
  final particles = switch (sky) {
    WeatherKind.rain => SideParticles.rain,
    WeatherKind.snow => SideParticles.snow,
    WeatherKind.dust => SideParticles.dust,
    WeatherKind.ash => SideParticles.ash,
    WeatherKind.fog => SideParticles.fog,
    _ => SideParticles.none,
  };
  if (particles != SideParticles.none && stage != FightStage.hall) {
    paintSideParticles(
        canvas, size, particles, 0.6, t, size.width / pixelStageColumns);
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
  // The lamps and torches shine through the dark.
  paintPixelLights(canvas, size, stage, lit: light < 1);
  canvas.restore();
}

double _h(num n) {
  final x = math.sin(n * 12.9898) * 43758.5453;
  return x - x.floorToDouble();
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
