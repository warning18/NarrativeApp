// The first-launch intro (v1.582, docs/proposals/intro-animation-d.md): the
// Great Shroud burning over Alster in ashes, the camera pushing down to the
// Blind Beggar, the old bone die falling, bouncing and rolling to the middle,
// slowing and stopping on a six, the title over it, and a slow fade into the
// game. 15 seconds, over eight beats; Narrative's four lines (set A) write
// themselves over it. It plays once, at the first New Game; a tap anywhere
// skips to the last beat; with reduced motion it shows the title over the
// die, then the last line, and goes on. It can be played again from Settings.
//
// The Shroud is the player's own banner, cut into six pieces long ago: the
// burning is a vision of before and it leaves six embers, one falling toward
// Alster. The first shell lands outside only as the die stops.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/climate.dart' show WeatherKind;
import '../data/journey_rules.dart' show DayPhase;
import '../l10n/app_strings.dart';
import '../theme/stitched_ink.dart';
import '../widgets/intro_art.dart';
import '../widgets/pixel_banner.dart';
import '../widgets/story_text.dart' show storyTextShownAtOnce;
import '../widgets/street_view/street_view.dart';

/// Whether the intro plays at the first New Game. The tests turn it off (see
/// test/flutter_test_config.dart); the ones about the intro turn it back on.
bool introOnNewGame = true;

/// The preference that remembers the intro was played.
const String introSeenKey = 'intro_seen';

Future<bool> introSeen() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(introSeenKey) ?? false;
  } catch (_) {
    return true;
  }
}

Future<void> markIntroSeen() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(introSeenKey, true);
  } catch (_) {}
}

/// Where each beat starts, in seconds, and when the intro ends.
const List<double> introBeatStarts = [0, 2.5, 4.5, 6.5, 8.5, 10.5, 12, 13.5];
const double introSeconds = 15;

/// With reduced motion: the title over the die for this long, then the last
/// beat (its line at once, the fade).
const double _stillHold = 2.5;
const double _stillFade = 1.5;

/// The lines, when each starts writing itself and when the next replaces it.
const List<(String, double, double)> _lines = [
  ('intro_line_1', 0.3, 4.6),
  ('intro_line_2', 4.8, 6.9),
  ('intro_line_3', 6.8, 13.7),
  ('intro_line_4', 13.8, 99),
];

const Color _cream = Color(0xFFEDE3C8);
const double _stageW = 210;
const double _stageH = 372;

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 15000));
  bool _still = false;
  bool _started = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _clock.addListener(() => setState(() {}));
    _clock.addStatusListener((s) {
      // A skip also ends in `completed`, at the last beat; only 1.0 is the end.
      if (s == AnimationStatus.completed && _clock.value >= 1) _finish();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _still = MediaQuery.of(context).disableAnimations;
    if (_still) {
      _clock.duration =
          Duration(milliseconds: ((_stillHold + _stillFade) * 1000).round());
    }
    _clock.forward();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_done) return;
    _done = true;
    await markIntroSeen();
    if (mounted) Navigator.of(context).pop(true);
  }

  /// A tap goes to the last beat; a tap in the last beat ends the intro.
  void _skip() {
    if (_done) return;
    final lastBeat = _still
        ? _stillHold / (_stillHold + _stillFade)
        : introBeatStarts.last / introSeconds;
    if (_clock.value < lastBeat - 0.001) {
      _clock
          .animateTo(lastBeat,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut)
          .then((_) {
        if (mounted && !_done) _clock.forward();
      });
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seconds = _still ? _stillSeconds : _clock.value * introSeconds;
    final beat = _still ? (seconds < 13.5 ? 6 : 7) : _beatAt(seconds);
    final local = _still
        ? (beat == 6 ? 1.5 : seconds - 13.5)
        : seconds - introBeatStarts[beat];
    final len = _beatLength(beat);
    final p = (local / len).clamp(0.0, 1.0);
    final fade = beat == 0 || _still ? 1.0 : (local / 0.4).clamp(0.0, 1.0);
    final endFade = beat == 7 ? p : 0.0;
    return Scaffold(
      key: const Key('intro'),
      backgroundColor: Colors.black,
      body: GestureDetector(
        key: const Key('intro_tap'),
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: Stack(fit: StackFit.expand, children: [
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _stageW,
                height: _stageH,
                child: Stack(fit: StackFit.expand, children: [
                  if (beat > 0 && fade < 1) _beat(beat - 1, 1, seconds),
                  Opacity(opacity: fade, child: _beat(beat, p, seconds)),
                  _ash(seconds),
                ]),
              ),
            ),
          ),
          // The last beat: the room fades into the game's own page.
          if (endFade > 0)
            ColoredBox(
                color: theme.scaffoldBackgroundColor
                    .withValues(alpha: endFade.clamp(0.0, 1.0))),
          _lineOver(context, seconds, endFade),
          Positioned(
            right: 16,
            bottom: 14,
            child: SafeArea(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: seconds < 3.5 ? 0.7 : 0,
                child: Text(tr(ref, 'intro_skip'),
                    style: const TextStyle(
                        fontFamily: InkFonts.system,
                        fontSize: 11,
                        color: Color(0xFF9A93A6))),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  double get _stillSeconds {
    final t = _clock.value * (_stillHold + _stillFade);
    return t < _stillHold ? 12.5 : 13.5 + (t - _stillHold);
  }

  int _beatAt(double seconds) {
    var i = 0;
    for (var k = 0; k < introBeatStarts.length; k++) {
      if (seconds >= introBeatStarts[k]) i = k;
    }
    return i;
  }

  double _beatLength(int beat) =>
      (beat == introBeatStarts.length - 1
          ? introSeconds
          : introBeatStarts[beat + 1]) -
      introBeatStarts[beat];

  /// Ash coming down over the whole stage: two tiles, sliding.
  Widget _ash(double seconds) {
    final dy = (seconds * 22) % _stageH;
    return IgnorePointer(
      child: ClipRect(
        child: Stack(children: [
          Positioned(
              left: 0,
              top: dy - _stageH,
              width: _stageW,
              height: _stageH,
              child: const CustomPaint(painter: IntroAsh(11))),
          Positioned(
              left: 0,
              top: dy,
              width: _stageW,
              height: _stageH,
              child: const CustomPaint(painter: IntroAsh(11))),
        ]),
      ),
    );
  }

  Widget _beat(int i, double p, double seconds) {
    switch (i) {
      case 0:
        return _shroud(p, seconds, burning: true);
      case 1:
        return _embers(p, seconds);
      case 2:
        return _city(p);
      case 3:
        return _tavernFront(p);
      case 4:
        return _dieFalls(p);
      case 5:
        return _dieStops(p);
      default:
        return _title(i == 6 ? p : 1);
    }
  }

  // 1: the Great Shroud, burning.
  Widget _shroud(double p, double seconds, {required bool burning}) {
    final flame = (seconds * 12).floor();
    return Stack(fit: StackFit.expand, children: [
      const CustomPaint(painter: IntroCity('smoke')),
      ColoredBox(color: Colors.black.withValues(alpha: 0.72 - 0.4 * p)),
      Align(
        alignment: const Alignment(0, -0.1),
        child: SizedBox(
          height: 300,
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.7, 0.05, 0.02, 0, 0, //
              0.05, 0.55, 0.02, 0, 0,
              0.04, 0.04, 0.5, 0, 0,
              0, 0, 0, 1, 0,
            ]),
            child: FittedBox(child: PixelBanner(id: titleBannerId, scale: 1)),
          ),
        ),
      ),
      CustomPaint(painter: IntroFire(0.1 + 0.5 * p, flicker: flame)),
    ]);
  }

  // 2: it burns away into six embers, one falling toward Alster.
  Widget _embers(double p, double seconds) {
    final flame = (seconds * 12).floor();
    final banner = (1 - p * 2.2).clamp(0.0, 1.0);
    return Stack(fit: StackFit.expand, children: [
      const CustomPaint(painter: IntroCity('smoke')),
      if (banner > 0)
        Opacity(
          opacity: banner,
          child: Stack(fit: StackFit.expand, children: [
            Align(
              alignment: const Alignment(0, -0.1),
              child: SizedBox(
                height: 300,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.5, 0.05, 0.02, 0, 0, //
                    0.05, 0.35, 0.02, 0, 0,
                    0.04, 0.04, 0.3, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
                  child: FittedBox(
                      child: PixelBanner(id: titleBannerId, scale: 1)),
                ),
              ),
            ),
            CustomPaint(painter: IntroFire(0.6 + 0.35 * p, flicker: flame)),
          ]),
        ),
      for (final (i, from, drift) in const [
        (0, Offset(80, 150), Offset(-46, -110)),
        (1, Offset(100, 140), Offset(0, -118)),
        (2, Offset(120, 150), Offset(44, -96)),
        (3, Offset(90, 170), Offset(-30, -70)),
        (4, Offset(112, 168), Offset(36, -64)),
      ])
        Positioned(
          left: from.dx + drift.dx * p,
          top: from.dy + drift.dy * p,
          child: Opacity(
              opacity: (p * 3).clamp(0.0, 1.0),
              child: IntroEmber(
                  id: shroudPieceIds[i], height: 30, tilt: (i - 2) * 0.35 + p)),
        ),
      // The sixth, falling toward the roofs, with its trail.
      for (var k = 0; k < 7; k++)
        Positioned(
          left: 88 + k * 3.0,
          top: 120 + 160 * p - k * 11.0,
          child: Opacity(
            opacity: (p * 2).clamp(0.0, 1.0) * (0.9 - k * 0.12).clamp(0.0, 1.0),
            child:
                Container(width: 3, height: 3, color: const Color(0xFFE0702A)),
          ),
        ),
      Positioned(
        left: 96 + 12 * p,
        top: 130 + 150 * p,
        child: IntroEmber(id: shroudPieceIds[5], height: 34, tilt: 0.5),
      ),
    ]);
  }

  // 3: the city on alert: calm streets, the white ships far off. No shell.
  Widget _city(double p) => Stack(fit: StackFit.expand, children: [
        const CustomPaint(painter: IntroCity('street')),
        Positioned(
          left: 6.0 + 8 * p,
          top: 0,
          width: _stageW,
          height: _stageH,
          child: const CustomPaint(
              painter: IntroSkyShips(ships: [(4, 18, 0.55), (44, 10, 0.4)])),
        ),
      ]);

  // 4: down through the smoke to the Blind Beggar.
  Widget _tavernFront(double p) => Stack(fit: StackFit.expand, children: [
        ClipRect(
          child: Transform.scale(
            scale: 1.35 + 0.45 * Curves.easeInOut.transform(p),
            alignment: const Alignment(-0.1, 0.35),
            child: const StreetViewScene(
                kind: 'tavern',
                name: 'The Blind Beggar',
                phase: DayPhase.dusk,
                sky: WeatherKind.ash,
                party: false),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            height: 140 * (1 - p * 0.6),
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xEE2B2830), Color(0x002B2830)])),
          ),
        ),
      ]);

  // 5: the die falls from the top, bounces on the floor, rolls to the middle.
  Widget _dieFalls(double p) {
    // Keyframes: (progress, x, y) as shares of the stage, y down.
    const keys = [
      (0.0, -0.25, -0.12),
      (0.34, -0.12, 0.52),
      (0.52, -0.04, 0.30),
      (0.66, 0.03, 0.54),
      (0.77, 0.06, 0.45),
      (0.88, 0.09, 0.55),
      (1.0, 0.12, 0.55),
    ];
    var (x, y) = (keys.last.$2, keys.last.$3);
    for (var i = 0; i < keys.length - 1; i++) {
      final a = keys[i], b = keys[i + 1];
      if (p >= a.$1 && p <= b.$1) {
        final t = (p - a.$1) / (b.$1 - a.$1);
        // Going down speeds up, going up slows: gravity.
        final goingDown = b.$3 > a.$3;
        final e = goingDown ? t * t : 1 - (1 - t) * (1 - t);
        x = a.$2 + (b.$2 - a.$2) * t;
        y = a.$3 + (b.$3 - a.$3) * e;
        break;
      }
    }
    return Stack(fit: StackFit.expand, children: [
      const CustomPaint(painter: IntroFloor()),
      Align(
        alignment: Alignment(x * 2, y * 2 - 1),
        child: introDie(70, roll: 0.72 * p),
      ),
    ]);
  }

  // 6: it turns slower and slower and stops on a six; the first shell lands.
  Widget _dieStops(double p) {
    final e = Curves.easeOut.transform(p);
    final stopped = p >= 0.97;
    return Stack(fit: StackFit.expand, children: [
      CustomPaint(painter: IntroFloor(flash: p > 0.8 && p < 0.97)),
      Align(
        alignment: Alignment(0.24 * (1 - e), 0.1 + 0.0 * e),
        child: introDie(86, roll: stopped ? null : 0.72 + 0.28 * e),
      ),
    ]);
  }

  // 7: the title over the resting die (and the 8th beat keeps it).
  Widget _title(double p) {
    final e = Curves.easeOut.transform(p);
    return Stack(fit: StackFit.expand, children: [
      const CustomPaint(painter: IntroFloor()),
      Align(alignment: const Alignment(0, 0.35), child: introDie(86)),
      Align(
        alignment: const Alignment(0, -0.62),
        child: Opacity(
          opacity: e,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - e)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(tr(ref, 'menu_title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: InkFonts.system,
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                      color: _cream)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Text(tr(ref, 'menu_subtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: InkFonts.prose,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF9A93A6))),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }

  /// The line being written now, over the foot of the screen.
  Widget _lineOver(BuildContext context, double seconds, double endFade) {
    (String, double, double)? current;
    for (final l in _lines) {
      if (seconds >= l.$2 && seconds < l.$3) current = l;
    }
    if (current == null) return const SizedBox.shrink();
    final (key, start, end) = current;
    final text = tr(ref, key);
    final write = storyTextShownAtOnce(context) || _still
        ? text.length
        : (((seconds - start) / _typeSeconds(text)).clamp(0.0, 1.0) *
                text.length)
            .round();
    final fadeIn = ((seconds - start) / 0.3).clamp(0.0, 1.0);
    final fadeOut = ((end - seconds) / 0.3).clamp(0.0, 1.0);
    final scaffold = Theme.of(context).colorScheme.onSurface;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Opacity(
        opacity: fadeIn * fadeOut,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
              24, 40, 24, MediaQuery.of(context).padding.bottom + 44),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                const Color(0x00000000),
                Colors.black.withValues(alpha: 0.85 * (1 - endFade))
              ])),
          child: Text(
            // The unwritten rest is kept invisible so the text does not jump.
            text.substring(0, write),
            key: Key(key),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: InkFonts.prose,
                fontSize: 17,
                height: 1.35,
                fontStyle: FontStyle.italic,
                color: Color.lerp(_cream, scaffold, endFade)),
          ),
        ),
      ),
    );
  }

  /// How long a line takes to write itself out (a little slower than the
  /// story's own typewriter, the words are few).
  double _typeSeconds(String text) => (text.length / 22.0).clamp(1.0, 3.2);
}
