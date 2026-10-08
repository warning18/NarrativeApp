import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/stitched_ink.dart';
import 'journey_fx.dart';

/// The small moments that make an action land, across the game: bursts,
/// a healing wave, an achievement's toast, a chapter's title card, the
/// edges throbbing at low health, weather behind a scene, a storm at sea,
/// the Shroud drifting behind the menu, a card flipping in and a face
/// snapping into place. None of them plays with the system's reduced
/// motion.

bool _still(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Runs [paint] on an overlay above everything for [duration], then goes.
void _overlayFor(
  BuildContext context, {
  required Duration duration,
  required void Function(Canvas canvas, Size size, double t) paint,
}) {
  if (_still(context)) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => IgnorePointer(
      child: _TimedPaint(
        duration: duration,
        paint: paint,
        onDone: () => entry.remove(),
      ),
    ),
  );
  overlay.insert(entry);
}

class _TimedPaint extends StatefulWidget {
  const _TimedPaint(
      {required this.duration, required this.paint, required this.onDone});

  final Duration duration;
  final void Function(Canvas canvas, Size size, double t) paint;
  final VoidCallback onDone;

  @override
  State<_TimedPaint> createState() => _TimedPaintState();
}

class _TimedPaintState extends State<_TimedPaint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t =
      AnimationController(vsync: this, duration: widget.duration)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        })
        ..forward();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.expand(
        child: CustomPaint(painter: _FnPainter(_t, widget.paint)),
      );
}

class _FnPainter extends CustomPainter {
  _FnPainter(this.t, this.fn) : super(repaint: t);
  final ValueListenable<double> t;
  final void Function(Canvas canvas, Size size, double t) fn;

  @override
  void paint(Canvas canvas, Size size) => fn(canvas, size, t.value);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Where [context]'s widget sits on screen (its centre).
Offset centreOf(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return Offset.zero;
  return box.localToGlobal(box.size.center(Offset.zero));
}

/// A burst of sparks at [at] in [colour]: a skill learned, a coin paid, a
/// face snapped onto a die.
void showBurst(BuildContext context,
    {required Offset at, required Color colour, int count = 14}) {
  final rng = math.Random(at.dx.toInt() * 31 + at.dy.toInt());
  final sparks = [
    for (var i = 0; i < count; i++)
      (
        angle: i / count * math.pi * 2 + rng.nextDouble() * 0.4,
        speed: 40 + rng.nextDouble() * 70,
        size: 2 + rng.nextDouble() * 2.5,
      ),
  ];
  _overlayFor(
    context,
    duration: const Duration(milliseconds: 750),
    paint: (canvas, size, t) {
      final e = Curves.easeOutCubic.transform(t);
      final alpha = 1 - t;
      canvas.drawCircle(
        at,
        10 + e * 40,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = colour.withValues(alpha: alpha * 0.8),
      );
      for (final s in sparks) {
        final p = at +
            Offset(math.cos(s.angle), math.sin(s.angle)) * (s.speed * e) +
            Offset(0, 30 * t * t);
        canvas.drawCircle(
            p, s.size, Paint()..color = colour.withValues(alpha: alpha));
      }
    },
  );
}

/// Coins flying from [from] to [to] (a purchase, gold earned).
void showCoinFlight(BuildContext context,
    {required Offset from, required Offset to, int count = 6}) {
  const gold = Color(0xFFF2C14E);
  _overlayFor(
    context,
    duration: const Duration(milliseconds: 900),
    paint: (canvas, size, t) {
      for (var i = 0; i < count; i++) {
        final local = ((t - i * 0.06) / 0.75).clamp(0.0, 1.0);
        if (local <= 0 || local >= 1) continue;
        final e = Curves.easeInOutCubic.transform(local);
        final mid = Offset((from.dx + to.dx) / 2 + (i - count / 2) * 8,
            math.min(from.dy, to.dy) - 80 - i * 6);
        final p = Offset.lerp(
            Offset.lerp(from, mid, e)!, Offset.lerp(mid, to, e)!, e)!;
        canvas.drawCircle(p, 5, Paint()..color = gold);
        canvas.drawCircle(
            p,
            5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = const Color(0xFF8A5A00));
      }
    },
  );
}

/// A soft green wave through the whole screen: the party rested.
void showHealWave(BuildContext context) {
  const heal = Color(0xFF7DBE6A);
  _overlayFor(
    context,
    duration: const Duration(milliseconds: 1400),
    paint: (canvas, size, t) {
      final centre = size.center(Offset.zero);
      final far = size.longestSide;
      for (var k = 0; k < 3; k++) {
        final local = ((t - k * 0.18) / 0.8).clamp(0.0, 1.0);
        if (local <= 0 || local >= 1) continue;
        canvas.drawCircle(
          centre,
          local * far,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10 * (1 - local) + 2
            ..color = heal.withValues(alpha: (1 - local) * 0.5),
        );
      }
    },
  );
}

/// An achievement earned: a toast slides down from the top with a shine
/// across it, then goes back up.
Future<void> showAchievementToast(BuildContext context, String name,
    {String label = 'ACHIEVEMENT'}) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final still = _still(context);
  final done = Completer<void>();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AchievementToast(
      name: name,
      label: label,
      still: still,
      onDone: () {
        entry.remove();
        done.complete();
      },
    ),
  );
  overlay.insert(entry);
  return done.future;
}

class _AchievementToast extends StatefulWidget {
  const _AchievementToast({
    required this.name,
    required this.label,
    required this.still,
    required this.onDone,
  });

  final String name;
  final String label;
  final bool still;
  final VoidCallback onDone;

  @override
  State<_AchievementToast> createState() => _AchievementToastState();
}

class _AchievementToastState extends State<_AchievementToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final theme = Theme.of(context);
    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.paddingOf(context).top + 12,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, child) {
            final t = _t.value;
            final inT = widget.still ? 1.0 : (t / 0.15).clamp(0.0, 1.0);
            final outT =
                widget.still ? 0.0 : ((t - 0.82) / 0.18).clamp(0.0, 1.0);
            final slide = Curves.easeOutBack.transform(inT) -
                Curves.easeIn.transform(outT);
            final shine = ((t - 0.2) / 0.35).clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(0, (slide - 1) * 110),
              child: Material(
                key: const ValueKey('achievement_toast'),
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                elevation: 6,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ink.gold),
                  ),
                  child: Stack(
                    children: [
                      if (!widget.still && shine > 0 && shine < 1)
                        Positioned.fill(
                          child: FractionalTranslation(
                            translation: Offset(-1 + shine * 2.2, 0),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  ink.gold.withValues(alpha: 0),
                                  ink.gold.withValues(alpha: 0.28),
                                  ink.gold.withValues(alpha: 0),
                                ]),
                              ),
                            ),
                          ),
                        ),
                      child!,
                    ],
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: ink.gold.withValues(alpha: 0.18),
                  child: Icon(Icons.emoji_events, color: ink.gold, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.label.toUpperCase(),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: ink.gold, letterSpacing: 1.4)),
                      Text(widget.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontFamily: InkFonts.display)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A new chapter opens like a page: its number and name over the
/// chapter's colour, inked in across the screen, for a moment, with a
/// [note] under them when there is one (the clans' offer it brings), and
/// the [news] from the coast the chapter brings (v1.195) under
/// [newsTitle] -- the card stays longer for each. It lets taps through:
/// the story goes on under it.
Future<void> showChapterCard(BuildContext context,
    {required String number,
    required String title,
    required Color colour,
    String? note,
    String newsTitle = '',
    List<String> news = const []}) {
  if (_still(context)) return Future.value();
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return Future.value();
  final done = Completer<void>();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => ChapterCard(
      number: number,
      title: title,
      colour: colour,
      note: note,
      newsTitle: newsTitle,
      news: news,
      onDone: () {
        entry.remove();
        done.complete();
      },
    ),
  );
  overlay.insert(entry);
  return done.future;
}

/// How long the chapter card stays: a moment, and longer for each piece
/// of news it tells (at most [_chapterCardLongest]).
Duration chapterCardDuration(int newsCount) {
  final ms = 2400 + 2600 * newsCount;
  return Duration(
      milliseconds: ms.clamp(2400, _chapterCardLongest.inMilliseconds));
}

const Duration _chapterCardLongest = Duration(milliseconds: 10400);

/// The chapter's title card (see [showChapterCard]).
class ChapterCard extends StatefulWidget {
  const ChapterCard({
    super.key,
    required this.number,
    required this.title,
    required this.colour,
    required this.onDone,
    this.note,
    this.newsTitle = '',
    this.news = const [],
  });

  final String number;
  final String title;
  final Color colour;
  final VoidCallback onDone;
  final String? note;
  final String newsTitle;
  final List<String> news;

  @override
  State<ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends State<ChapterCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: chapterCardDuration(widget.news.length),
  )
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, child) {
          final t = _t.value;
          final open = Curves.easeOut.transform((t / 0.2).clamp(0.0, 1.0));
          final fade = t > 0.8 ? 1 - (t - 0.8) / 0.2 : 1.0;
          final ink = ((t - 0.15) / 0.3).clamp(0.0, 1.0);
          return Opacity(
            opacity: fade,
            child: Center(
              child: ClipRect(
                child: Align(
                  heightFactor: open.clamp(0.01, 1.0),
                  child: Container(
                    key: const ValueKey('chapter_card'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 36, horizontal: 24),
                    color: Color.alphaBlend(
                        widget.colour.withValues(alpha: 0.22),
                        theme.colorScheme.surface.withValues(alpha: 0.95)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.number.toUpperCase(),
                            style: theme.textTheme.labelLarge?.copyWith(
                                color: widget.colour, letterSpacing: 3)),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: ink,
                          child: Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium
                                ?.copyWith(fontFamily: InkFonts.display),
                          ),
                        ),
                        if (widget.note != null) ...[
                          const SizedBox(height: 10),
                          Opacity(
                            opacity: ink,
                            child: Text(
                              widget.note!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: widget.colour,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                        if (widget.news.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Opacity(
                            opacity: ink,
                            child: Column(
                              key: const ValueKey('chapter_card_news'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.newsTitle.isNotEmpty)
                                  Text(
                                    widget.newsTitle.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        color: widget.colour, letterSpacing: 2),
                                  ),
                                for (final line in widget.news)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    // Three lines at most: the journal
                                    // keeps the whole of it.
                                    child: Text(
                                      line,
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              fontFamily: InkFonts.prose,
                                              fontStyle: FontStyle.italic),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Loops a painter from time while on screen (not with reduced motion).
class _Looping extends StatefulWidget {
  const _Looping({required this.paint});
  final void Function(Canvas canvas, Size size, double t) paint;

  @override
  State<_Looping> createState() => _LoopingState();
}

class _LoopingState extends State<_Looping>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _time = ValueNotifier(0);
  Ticker? _ticker;
  double _base = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = !_still(context) &&
        Visibility.of(context) &&
        TickerMode.valuesOf(context).enabled;
    if (on) {
      _ticker ??= createTicker((elapsed) {
        _time.value = _base + elapsed.inMicroseconds / 1e6;
      });
      if (!_ticker!.isActive) _ticker!.start();
    } else if (_ticker?.isActive ?? false) {
      _base = _time.value;
      _ticker!.stop();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_still(context)) return const SizedBox.expand();
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(painter: _FnPainter(_time, widget.paint)),
      ),
    );
  }
}

/// A chapter's weather, faint, behind a scene's words.
class WeatherLayer extends StatelessWidget {
  const WeatherLayer({super.key, required this.weather, this.strength = 0.5});

  final JourneyWeather weather;
  final double strength;

  @override
  Widget build(BuildContext context) {
    if (weather == JourneyWeather.none) return const SizedBox.shrink();
    final ink = InkColors.of(context);
    final colour = switch (weather) {
      JourneyWeather.rain => const Color(0xFF8FC3CF),
      JourneyWeather.snow => const Color(0xFFEFF3F6),
      JourneyWeather.dust => const Color(0xFFC9A46A),
      _ => ink.ash,
    }
        .withValues(alpha: strength);
    return _Looping(
      paint: (canvas, size, t) =>
          paintJourneyWeather(canvas, size, t, weather, colour, count: 18),
    );
  }
}

/// A storm over the crossing: slanting rain and lightning now and then.
class StormLayer extends StatelessWidget {
  const StormLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return _Looping(paint: (canvas, size, t) {
      paintJourneyWeather(
          canvas, size, t, JourneyWeather.rain, const Color(0xFFC8E6F0),
          count: 40);
      // A flash every few seconds.
      final phase = t % 4.2;
      final flash = phase > 3.7 && phase < 3.95
          ? (phase < 3.8
              ? 0.55
              : phase > 3.85
                  ? 0.35
                  : 0.1)
          : 0.0;
      if (flash > 0) {
        canvas.drawRect(Offset.zero & size,
            Paint()..color = const Color(0xFFEAF4FF).withValues(alpha: flash));
      }
    });
  }
}

/// The Shroud drifting behind the main menu: grey veils and violet motes.
class ShroudDrift extends StatelessWidget {
  const ShroudDrift({super.key});

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    return _Looping(paint: (canvas, size, t) {
      for (var j = 0; j < 4; j++) {
        final period = 14.0 + j * 4;
        final p = ((t + j * 5) % period) / period;
        final cx = -0.4 * size.width + p * 1.8 * size.width;
        final cy = size.height * (0.2 + j * 0.2);
        final rect = Rect.fromCenter(
            center: Offset(cx, cy), width: size.width * 0.9, height: 120);
        canvas.drawOval(
          rect,
          Paint()
            ..shader = RadialGradient(colors: [
              ink.ash.withValues(alpha: 0.14 * math.sin(math.pi * p)),
              ink.ash.withValues(alpha: 0),
            ]).createShader(rect),
        );
      }
      for (var k = 0; k < 10; k++) {
        final p = ((t / 7) + k / 10) % 1.0;
        final x = size.width * ((k * 0.37) % 1.0) + math.sin(t + k) * 12;
        final y = size.height * (1 - p);
        canvas.drawCircle(
          Offset(x, y),
          2,
          Paint()
            ..color =
                ink.voidColor.withValues(alpha: math.sin(math.pi * p) * 0.6),
        );
      }
    });
  }
}

/// The edges of the screen throbbing faintly red: HP is low.
class LowHealthEdge extends StatelessWidget {
  const LowHealthEdge({super.key});

  @override
  Widget build(BuildContext context) {
    final blood = InkColors.of(context).blood;
    if (_still(context)) {
      return IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.0,
              colors: [
                blood.withValues(alpha: 0),
                blood.withValues(alpha: 0.18)
              ],
              stops: const [0.7, 1],
            ),
          ),
          child: const SizedBox.expand(),
        ),
      );
    }
    return _Looping(paint: (canvas, size, t) {
      final beat = (t % 1.8) / 1.8;
      double pulse(double at) => math.exp(-math.pow((beat - at) * 12, 2));
      final a = 0.08 + 0.22 * pulse(0.1) + 0.16 * pulse(0.3);
      final rect = Offset.zero & size;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            radius: 0.95,
            colors: [blood.withValues(alpha: 0), blood.withValues(alpha: a)],
            stops: const [0.72, 1],
          ).createShader(rect),
      );
    });
  }
}

/// [child] turning over like a card each time [flipKey] changes (an
/// expedition's next event).
class FlipIn extends StatelessWidget {
  const FlipIn({super.key, required this.flipKey, required this.child});

  final Object flipKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (_still(context)) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(flipKey),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          // Short of edge-on, so the card takes taps from the first frame.
          ..rotateY((1 - t) * math.pi * 0.42),
        child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      ),
    );
  }
}

/// [child] snapping in with a small bounce each time [snapKey] changes (a
/// skill set on a die's face).
class SnapIn extends StatelessWidget {
  const SnapIn({super.key, required this.snapKey, required this.child});

  final Object snapKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (_still(context)) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(snapKey),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      child: child,
      builder: (context, t, child) => Transform.scale(
        scale: 0.8 + 0.2 * Curves.elasticOut.transform(t),
        child: child,
      ),
    );
  }
}

/// The time of day over a scene ([watch]: 0 dawn, 1 daytime, 2 dusk,
/// 3 night): a tint, and at night stars that twinkle. Daytime is clear.
class WatchSky extends StatelessWidget {
  const WatchSky({super.key, required this.watch});

  final int watch;

  @override
  Widget build(BuildContext context) {
    if (watch == 1) return const SizedBox.shrink();
    final tint = switch (watch) {
      0 => const Color(0x33F2B279),
      2 => const Color(0x44B4553A),
      _ => const Color(0x88101A33),
    };
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(key: Key('watch_sky_$watch'), color: tint),
          if (watch == 3)
            _Looping(paint: (canvas, size, t) {
              for (var i = 0; i < 28; i++) {
                final x = size.width * ((i * 0.618) % 1.0);
                final y = size.height * 0.45 * ((i * 0.377) % 1.0);
                final a = 0.35 + 0.55 * (0.5 + 0.5 * math.sin(t * 1.7 + i));
                canvas.drawRect(
                  Rect.fromCenter(center: Offset(x, y), width: 2, height: 2),
                  Paint()..color = const Color(0xFFF4EBD0).withValues(alpha: a),
                );
              }
            }),
        ],
      ),
    );
  }
}

/// A heart that beats slowly: a devoted companion.
class ApprovalHeart extends StatelessWidget {
  const ApprovalHeart({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    final heart = Icon(Icons.favorite,
        key: const Key('approval_heart'),
        size: size,
        color: Colors.amber.shade600);
    if (_still(context)) return heart;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: heart,
    );
  }
}

/// Slow golden rays turning behind a medal (a level gained).
class RayBurst extends StatelessWidget {
  const RayBurst({super.key, this.colour = const Color(0xFFD4A017)});

  final Color colour;

  @override
  Widget build(BuildContext context) {
    return _Looping(paint: (canvas, size, t) {
      final c = size.center(Offset.zero);
      final r = size.shortestSide / 2;
      final paint = Paint()..color = colour.withValues(alpha: 0.22);
      for (var i = 0; i < 12; i++) {
        final a = t * 0.4 + i * math.pi / 6;
        final path = Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + math.cos(a - 0.1) * r, c.dy + math.sin(a - 0.1) * r)
          ..lineTo(c.dx + math.cos(a + 0.1) * r, c.dy + math.sin(a + 0.1) * r)
          ..close();
        canvas.drawPath(path, paint);
      }
    });
  }
}

/// [child] rising into place once, after [delay] (a banner, a card dealt).
class RiseIn extends StatelessWidget {
  const RiseIn({super.key, this.delay = Duration.zero, required this.child});

  final Duration delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (_still(context)) return child;
    const run = Duration(milliseconds: 380);
    final total = delay + run;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(delay.inMilliseconds / total.inMilliseconds, 1,
          curve: Curves.easeOutBack),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child:
            Transform.translate(offset: Offset(0, (1 - t) * 18), child: child),
      ),
    );
  }
}

/// A wax seal stamped over the screen's middle (a quest settled): it drops,
/// presses flat with a ring, then fades.
void showQuestSeal(BuildContext context,
    {Color colour = const Color(0xFFA8322A)}) {
  _overlayFor(
    context,
    duration: const Duration(milliseconds: 1100),
    paint: (canvas, size, t) {
      final c = size.center(Offset.zero);
      final drop = Curves.easeInCubic.transform((t / 0.3).clamp(0.0, 1.0));
      final scale = t < 0.3 ? 2.2 - 1.2 * drop : 1.0;
      final fade = t > 0.7 ? 1 - (t - 0.7) / 0.3 : 1.0;
      if (t > 0.3) {
        final ring = (t - 0.3) / 0.7;
        canvas.drawCircle(
          c,
          46 + ring * 60,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = colour.withValues(alpha: (1 - ring) * 0.6),
        );
      }
      final r = 42 * scale;
      final wax = Paint()..color = colour.withValues(alpha: fade * 0.95);
      final blob = Path();
      for (var i = 0; i <= 24; i++) {
        final a = i / 24 * math.pi * 2;
        final rr = r * (1 + 0.06 * math.sin(i * 2.7));
        final p = c + Offset(math.cos(a), math.sin(a)) * rr;
        i == 0 ? blob.moveTo(p.dx, p.dy) : blob.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(blob..close(), wax);
      canvas.drawCircle(
        c,
        r * 0.72,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFF4D9A8).withValues(alpha: fade * 0.7),
      );
      // A tick pressed into the wax.
      final tick = Path()
        ..moveTo(c.dx - r * 0.32, c.dy)
        ..lineTo(c.dx - r * 0.08, c.dy + r * 0.26)
        ..lineTo(c.dx + r * 0.36, c.dy - r * 0.24);
      canvas.drawPath(
        tick,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * scale
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFF4D9A8).withValues(alpha: fade * 0.85),
      );
    },
  );
}

/// Each of [names] announced in turn with [showAchievementToast]; not
/// awaited by callers (the toasts run over whatever comes next).
Future<void> announceAchievements(
    BuildContext context, List<String> names, String label) async {
  for (final name in names) {
    if (!context.mounted) return;
    await showAchievementToast(context, name, label: label);
  }
}

/// A badge earned: a ring of light turning slowly around [child].
class BadgeRing extends StatelessWidget {
  const BadgeRing({super.key, required this.colour, required this.child});

  final Color colour;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: _Looping(paint: (canvas, size, t) {
              final rect = (Offset.zero & size).deflate(2);
              canvas.drawArc(
                rect,
                t * 1.4,
                math.pi * 1.2,
                false,
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2
                  ..strokeCap = StrokeCap.round
                  ..shader = SweepGradient(
                    colors: [colour.withValues(alpha: 0), colour],
                    transform: GradientRotation(t * 1.4),
                  ).createShader(rect),
              );
            }),
          ),
          child,
        ],
      ),
    );
  }
}
