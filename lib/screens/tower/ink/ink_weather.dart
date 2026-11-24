// Weather on the ink pieces (v2.1, UX-2): snow, sand, ash and rain build up on
// a piece while a screen is open, a tap knocks them off, fog is a veil.
//
// - ONE clock per screen: a [WeatherScope] holds the seconds on screen and
//   tells the pieces below it twice a second (a periodic timer, not a ticker:
//   no frame is asked for between two steps). Pieces repaint from it without
//   rebuilding, and a cap re-lays its path only when its quantised level moves.
// - The level of a cap is `seconds / (30 / fall)`, 0 to 1: 30 s to heavy in the
//   hardest fall, longer in a light one. It stops at [inkCapMaxHeight], above
//   the label's room (a cap sits on the top edge, outside the box).
// - A tap on a piece (the tap goes on to the button) knocks its cap off in a
//   puff over 450 ms, then it builds again from nothing. The controller lives
//   only while it knocks.
// - The level is kept in memory per scope id: a rebuild keeps it, leaving and
//   coming back returns it less the time away (a loss of 1 per 120 s of cap).
// - Reduce motion: a fixed medium cap (level 0.5), no timer, no falling.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/climate_provider.dart' show skyHereProvider;

import '../../../data/climate.dart' show WeatherKind;
import 'ink_palette.dart';
import 'ink_seed.dart';

/// The tallest a cap grows, in logical pixels above the piece's top edge.
const double inkCapMaxHeight = 12;

/// How long a cap takes to reach its heavy height at [fall] (0 to 1).
double inkSecondsToHeavy(double fall) => 30 / fall.clamp(0.3, 1.0);

/// The level (0 to 1) of a cap [seconds] after it started at [fall].
double inkLevelAfter(double seconds, double fall) =>
    (seconds / inkSecondsToHeavy(fall)).clamp(0.0, 1.0);

/// The level a reduced-motion screen shows.
const double inkMediumLevel = 0.5;

/// The sky where the party stands, for screens that wear its weather on their
/// ink pieces (the story's screens, when they take it up). The Tower does not
/// read it: its snow is its own, by band. Nothing reads this one today.
final uiSkyProvider = Provider<({WeatherKind kind, double fall})?>((ref) {
  final w = ref.watch(skyHereProvider)?.today();
  return w == null ? null : (kind: w.kind, fall: w.fall);
});

/// The levels kept between visits, in memory: scope id to (seconds, saved at).
class InkWeatherStore {
  InkWeatherStore._();
  static final Map<String, (double, DateTime)> _kept = {};

  static void save(String id, double seconds) =>
      _kept[id] = (seconds, DateTime.now());

  /// The seconds a scope starts with: those it had, less the time away
  /// (1 of level per 120 s away, in seconds of build-up).
  static double restore(String id, double fall, [DateTime? now]) {
    final k = _kept[id];
    if (k == null) return 0;
    final away = (now ?? DateTime.now()).difference(k.$2).inSeconds;
    final loss = away * inkSecondsToHeavy(fall) / 120;
    return math.max(0, k.$1 - loss);
  }

  static void reset() => _kept.clear();
}

/// The one clock of a screen. The pieces below read it.
class InkWeatherClock {
  InkWeatherClock(this.kind, this.fall,
      {required double start, required this.reduceMotion})
      : seconds = ValueNotifier<double>(start);

  final WeatherKind kind;
  final double fall;
  final bool reduceMotion;

  /// Seconds on screen, steps of half a second (a fixed one under reduce
  /// motion). Pieces repaint when it moves.
  final ValueNotifier<double> seconds;

  /// How many clocks are running (the test of "one per screen").
  static int live = 0;

  bool get active => kind != WeatherKind.clear && kind != WeatherKind.cloud;
}

class _InkWeather extends InheritedWidget {
  const _InkWeather({required this.clock, required super.child});
  final InkWeatherClock clock;

  static InkWeatherClock? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_InkWeather>()?.clock;

  @override
  bool updateShouldNotify(_InkWeather old) =>
      old.clock.kind != clock.kind ||
      old.clock.fall != clock.fall ||
      old.clock.reduceMotion != clock.reduceMotion;
}

/// The weather of a screen: put it above the pieces. Without one (the home
/// menu, the story) the pieces draw no weather.
class WeatherScope extends StatefulWidget {
  const WeatherScope({
    super.key,
    required this.id,
    required this.kind,
    required this.fall,
    required this.child,
  });

  /// What keeps the level between visits (the Tower's screens share one).
  final String id;
  final WeatherKind kind;

  /// How hard it falls, 0 to 1.
  final double fall;
  final Widget child;

  @override
  State<WeatherScope> createState() => _WeatherScopeState();
}

class _WeatherScopeState extends State<WeatherScope> {
  InkWeatherClock? _clock;
  Timer? _timer;
  bool? _reduce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_clock == null || reduce != _reduce) _start(reduce);
  }

  @override
  void didUpdateWidget(WeatherScope old) {
    super.didUpdateWidget(old);
    if (old.kind != widget.kind || old.fall != widget.fall) {
      _start(_reduce ?? false, keepSeconds: true);
    }
  }

  void _start(bool reduce, {bool keepSeconds = false}) {
    final had = keepSeconds ? _clock?.seconds.value : null;
    _stop();
    _reduce = reduce;
    final start = reduce
        ? inkMediumLevel * inkSecondsToHeavy(widget.fall)
        : (had ?? InkWeatherStore.restore(widget.id, widget.fall));
    final clock = InkWeatherClock(widget.kind, widget.fall,
        start: start, reduceMotion: reduce);
    _clock = clock;
    InkWeatherClock.live++;
    if (clock.active && !reduce) {
      // Half a second a tick: time on screen, not wall time (a paused app
      // builds nothing up), and a cap re-lays at most twice a second.
      _timer = Timer.periodic(
          const Duration(milliseconds: 500), (_) => clock.seconds.value += 0.5);
    }
  }

  void _stop() {
    final clock = _clock;
    _timer?.cancel();
    _timer = null;
    if (clock == null) return;
    if (!clock.reduceMotion) {
      InkWeatherStore.save(widget.id, clock.seconds.value);
    }
    InkWeatherClock.live--;
    _clock = null;
  }

  @override
  void dispose() {
    final clock = _clock;
    _stop();
    clock?.seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _InkWeather(clock: _clock!, child: widget.child);
}

/// A piece under the weather: it draws the cap, the wet or the veil over its
/// child, and a tap on it (which still goes on to the child) knocks the cap
/// off. Without a [WeatherScope] above, or in clear weather, it is the child.
class InkWeatherPiece extends StatefulWidget {
  const InkWeatherPiece({super.key, required this.seed, required this.child});

  final InkSeed seed;
  final Widget child;

  @override
  State<InkWeatherPiece> createState() => InkWeatherPieceState();
}

class InkWeatherPieceState extends State<InkWeatherPiece>
    with TickerProviderStateMixin {
  AnimationController? _knock;
  double _baseline = 0;
  InkWeatherClock? _clock;

  /// The level of this piece now (0 to 1): what the tests read.
  double get level {
    final c = _clock;
    if (c == null || !c.active) return 0;
    if (c.reduceMotion) return inkMediumLevel;
    return inkLevelAfter(c.seconds.value - _baseline, c.fall);
  }

  /// Whether a knock is under way.
  bool get knocking => _knock != null;

  void _knocked() {
    final c = _clock;
    if (c == null || !c.active || c.reduceMotion || _knock != null) return;
    if (level < 0.05) return;
    final puff = level;
    _knockLevel = puff;
    final ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _knock = ctrl;
    ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        // It builds again from nothing, at the clock's time of the knock.
        _baseline = c.seconds.value;
        ctrl.dispose();
        if (mounted) setState(() => _knock = null);
        _knock = null;
      }
    });
    setState(() {});
    ctrl.forward();
  }

  double _knockLevel = 0.8;

  @override
  void dispose() {
    _knock?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clock = _InkWeather.maybeOf(context);
    _clock = clock;
    if (clock == null || !clock.active) return widget.child;
    final kind = clock.kind;
    Widget body = widget.child;
    if (kind == WeatherKind.fog) {
      body = Opacity(opacity: 1 - 0.28 * clock.fall, child: body);
    } else if (kind == WeatherKind.rain) {
      body = ValueListenableBuilder<double>(
        valueListenable: clock.seconds,
        builder: (context, _, child) => ColorFiltered(
            colorFilter: ColorFilter.mode(
                inkBlack.withValues(alpha: 0.3 * _wet), BlendMode.srcATop),
            child: child),
        child: body,
      );
    }
    final painter = InkSkyPainter(
      kind: kind,
      fall: clock.fall,
      seed: widget.seed,
      level: () => level,
      wet: () => _wet,
      knock: () => _knock?.value ?? 0,
      knockLevel: () => _knockLevel,
      repaint: Listenable.merge([clock.seconds, if (_knock != null) _knock!]),
    );
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _knocked(),
      child: Stack(clipBehavior: Clip.none, children: [
        body,
        Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: painter))),
      ]),
    );
  }

  /// How wet it is (rain): 0 to 1 over about 8 s at full fall.
  double get _wet {
    final c = _clock;
    if (c == null) return 0;
    if (c.reduceMotion) return 0.8;
    return ((c.seconds.value - _baseline) / (8 / c.fall.clamp(0.3, 1.0)))
        .clamp(0.0, 1.0);
  }
}

// ---- the drawing ------------------------------------------------------------

/// The profile of a drift along its length (0 to 1): thin at the ends, thickest
/// toward the windward side, lumpy but smooth, never a repeating scallop.
double inkDriftProfile(double x, int seed, double wind) {
  final peak = 0.5 + wind * 0.18;
  final base = math
      .pow(math.sin(math.pi * math.pow(x, math.log(0.5) / math.log(peak))), 0.8)
      .toDouble();
  final lump = 0.78 +
      0.22 * math.sin(x * 5.3 + seed * 1.7) * math.cos(x * 2.1 + seed) +
      0.12 * math.sin(x * 11.0 + seed * 0.6);
  return (base * lump).clamp(0.0, 1.2);
}

class InkSkyPainter extends CustomPainter {
  InkSkyPainter({
    required this.kind,
    required this.fall,
    required this.seed,
    required this.level,
    required this.wet,
    required this.knock,
    required this.knockLevel,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final WeatherKind kind;
  final double fall;
  final InkSeed seed;
  final double Function() level;
  final double Function() wet;
  final double Function() knock;
  final double Function() knockLevel;

  /// Where a cap of [level] lies on a piece [size] big: above the top edge
  /// (flakes a little higher). A label inside the box never meets it.
  static Rect capBounds(Size size, double level) {
    final h = inkCapMaxHeight * level;
    return Rect.fromLTRB(0, -h - 6, size.width, 2);
  }

  @override
  void paint(Canvas canvas, Size s) {
    final r = math.Random(seed.n * 97 + 3);
    final wind = (seed.n % 3 - 1) * 0.8;
    switch (kind) {
      case WeatherKind.snow:
        _drift(canvas, s, r, wind, inkPaper, const Color(0xFFC9D2D6));
      case WeatherKind.dust:
        _drift(canvas, s, r, wind, inkSand, const Color(0xFF9C8660),
            ripples: true);
      case WeatherKind.ash:
        _drift(canvas, s, r, wind, const Color(0xFF4A4A4E),
            const Color(0xFF2A2A2E),
            height: 0.55);
        final l = level();
        if (l > 0.2 && knock() == 0) {
          for (var i = 0; i < 2 + (l * 6).round(); i++) {
            canvas.drawCircle(
                Offset(r.nextDouble() * s.width, -2 - r.nextDouble() * 5 * l),
                0.9,
                Paint()..color = const Color(0xFFD06A1E));
          }
        }
      case WeatherKind.rain:
        _rain(canvas, s, r);
      case WeatherKind.fog:
        canvas.drawRect(
            Offset.zero & s,
            Paint()
              ..shader = ui.Gradient.linear(Offset.zero, Offset(0, s.height), [
                inkGrey.withValues(alpha: 0.05),
                inkGrey.withValues(alpha: 0.2 + 0.2 * fall),
              ]));
      default:
        break;
    }
  }

  void _drift(
      Canvas canvas, Size s, math.Random r, double wind, Color top, Color shade,
      {bool ripples = false, double height = 1}) {
    final k = knock();
    final lift = k * 20;
    final fade = (1 - k).clamp(0.0, 1.0);
    final lv = level();
    final h = inkCapMaxHeight * lv * height;
    if (h > 0.4 && fade > 0) {
      final pts = <Offset>[];
      for (var x = 0.0; x <= 1.0001; x += 1 / math.max(8, s.width / 2.5)) {
        pts.add(Offset(
            x * s.width, 1 + lift - inkDriftProfile(x, seed.n, wind) * h));
      }
      final path = Path()
        ..moveTo(-1, 2 + lift)
        ..lineTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length - 1; i++) {
        final mid = Offset(
            (pts[i].dx + pts[i + 1].dx) / 2, (pts[i].dy + pts[i + 1].dy) / 2);
        path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
      }
      path
        ..lineTo(s.width + 1, 2 + lift)
        ..close();
      canvas.drawPath(path, Paint()..color = shade.withValues(alpha: fade));
      canvas.save();
      canvas.translate(0, -1.2);
      canvas.drawPath(path, Paint()..color = top.withValues(alpha: fade));
      canvas.restore();
      if (ripples) {
        for (var i = 0; i < 3; i++) {
          canvas.drawLine(
              Offset(s.width * (0.2 + 0.15 * i), -h * 0.35 + lift),
              Offset(s.width * (0.35 + 0.15 * i), -h * 0.45 + lift),
              Paint()
                ..color = shade.withValues(alpha: 0.6 * fade)
                ..strokeWidth = 0.8);
        }
      }
      for (var i = 0; i < (lv * 7).round(); i++) {
        final x = r.nextDouble() * s.width;
        canvas.drawCircle(
            Offset(
                x,
                1 +
                    lift -
                    inkDriftProfile(x / s.width, seed.n, wind) * h -
                    1.5 -
                    r.nextDouble() * 4),
            0.7 + r.nextDouble() * 1.1,
            Paint()..color = top.withValues(alpha: 0.9 * fade));
      }
    }
    // The knock: a puff of flakes thrown off, the size of the cap it was.
    if (k > 0 && k < 1) {
      final n = (knockLevel() * 14).round();
      for (var i = 0; i < n; i++) {
        final a = r.nextDouble() * math.pi * 2;
        final d = k * (8 + r.nextDouble() * 26);
        canvas.drawCircle(
            Offset(r.nextDouble() * s.width + math.cos(a) * d * 0.6,
                -2 + math.sin(a).abs() * d),
            1.0 + r.nextDouble() * 1.8,
            Paint()..color = top.withValues(alpha: (1 - k) * 0.95));
      }
    }
  }

  void _rain(Canvas canvas, Size s, math.Random r) {
    final w = wet();
    if (w > 0.35) {
      canvas.drawLine(
          Offset(s.width * 0.28, s.height * 0.1),
          Offset(s.width * 0.5, s.height * 0.9),
          Paint()
            ..color = inkPaper.withValues(alpha: 0.10 * w)
            ..strokeWidth = 2.5);
    }
    // The drips start once the piece is wet through.
    final drip = ((w - 0.6) / 0.4).clamp(0.0, 1.0);
    for (var i = 0; i < 4; i++) {
      final x = 8 + r.nextDouble() * (s.width - 16);
      final len = (3 + r.nextDouble() * 11) * drip;
      if (len < 1) continue;
      canvas.drawLine(
          Offset(x, s.height),
          Offset(x, s.height + len),
          Paint()
            ..color = inkSlate
            ..strokeWidth = 1.6);
      canvas.drawCircle(
          Offset(x, s.height + len), 1.8, Paint()..color = inkGrey);
    }
  }

  @override
  bool shouldRepaint(InkSkyPainter old) =>
      old.kind != kind || old.fall != fall || old.seed != seed;
}
