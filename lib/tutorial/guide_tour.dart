import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/companion_sprites.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/app_mode_provider.dart';
import '../providers/companion_name_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/tts_provider.dart';
import '../providers/tutorial_provider.dart';
import '../theme/stitched_ink.dart';
import 'tutorial_topics.dart';

// --- Targets --------------------------------------------------------------

final Map<String, List<_TutorialTargetState>> _targets = {};

/// Marks [child] as the part of the screen a tour step lights up when the
/// step's target is [id] (see [TutorialStep.target]).
class TutorialTarget extends StatefulWidget {
  const TutorialTarget({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  State<TutorialTarget> createState() => _TutorialTargetState();
}

class _TutorialTargetState extends State<TutorialTarget> {
  @override
  void initState() {
    super.initState();
    _targets.putIfAbsent(widget.id, () => []).add(this);
  }

  @override
  void didUpdateWidget(covariant TutorialTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _targets[oldWidget.id]?.remove(this);
      _targets.putIfAbsent(widget.id, () => []).add(this);
    }
  }

  @override
  void dispose() {
    _targets[widget.id]?.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Whether [context] is on screen: not on a tab of an IndexedStack that
/// isn't showing, nor on a page under another (which turns tickers off).
bool _onScreen(BuildContext context) =>
    Visibility.of(context) && TickerMode.valuesOf(context).enabled;

/// The one [id] target on screen now.
BuildContext? _shownTarget(String id) {
  for (final state in (_targets[id] ?? const []).reversed) {
    if (!state.mounted) continue;
    final box = state.context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) continue;
    if (!_onScreen(state.context)) continue;
    return state.context;
  }
  return null;
}

/// Where [context] sits on the screen, cut to [screen]; null when none of
/// it shows.
Rect? _rectOf(BuildContext context, Size screen) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.attached || !box.hasSize) return null;
  final rect = (box.localToGlobal(Offset.zero) & box.size)
      .intersect(Offset.zero & screen);
  if (rect.width < 4 || rect.height < 4) return null;
  return rect;
}

// --- Starting a tour ------------------------------------------------------

bool _tourShowing = false;

/// Plays [topic]'s tour over the app: the guide walks to the middle of the
/// screen and talks the player through it, lighting up each part as it
/// goes. Skippable at any point. Marks the tour seen.
Future<void> showGuideTour(
    BuildContext context, WidgetRef ref, TutorialTopic topic) async {
  if (_tourShowing) return;
  _tourShowing = true;
  unawaited(ref.read(tutorialProvider.notifier).markSeen(topic));
  try {
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => GuideTour(topic: topic),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  } finally {
    _tourShowing = false;
  }
}

/// Plays [topic]'s tour the first time [child] shows (and whenever the
/// Tutorials list asks for it), once [ready] — the Story tab waits for a
/// character, for instance. Put it around the feature's screen.
class TutorialTrigger extends ConsumerStatefulWidget {
  const TutorialTrigger({
    super.key,
    required this.topic,
    required this.child,
    this.ready = true,
  });

  final TutorialTopic topic;
  final Widget child;
  final bool ready;

  @override
  ConsumerState<TutorialTrigger> createState() => _TutorialTriggerState();
}

class _TutorialTriggerState extends ConsumerState<TutorialTrigger> {
  bool _shown = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shown = _onScreen(context);
    _consider();
  }

  @override
  void didUpdateWidget(covariant TutorialTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    _consider();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _asked => ref.read(pendingTourProvider) == widget.topic;

  bool get _due {
    final settings = ref.read(tutorialProvider);
    // Edit Mode is for writing the story, not for being shown around.
    return ref.read(tutorialAutoShowProvider) &&
        ref.read(appModeProvider) != AppMode.edit &&
        settings.loaded &&
        settings.enabled &&
        !settings.hasSeen(widget.topic);
  }

  void _consider() {
    if (_timer != null || !_shown || !widget.ready) return;
    if (!_asked && !_due) return;
    // A moment for the screen to settle (routes to finish sliding in,
    // lists to lay out) before the guide measures it.
    _timer = Timer(const Duration(milliseconds: 600), () {
      _timer = null;
      if (!mounted || !_shown || !widget.ready) return;
      // A dialog or another tour on top: try again once it's gone.
      if (_tourShowing || ModalRoute.of(context)?.isCurrent == false) {
        _consider();
        return;
      }
      final asked = _asked;
      if (!asked && !_due) return;
      if (asked) ref.read(pendingTourProvider.notifier).state = null;
      showGuideTour(context, ref, widget.topic);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pendingTourProvider, (_, next) {
      if (next == widget.topic) _consider();
    });
    ref.listen(tutorialProvider.select((s) => s.loaded), (_, __) {
      _consider();
    });
    ref.listen(appModeProvider, (_, __) => _consider());
    return widget.child;
  }
}

// --- The tour -------------------------------------------------------------

const double _dogSize = 104;
// Every pose's frames sit on their own canvas size; scaling each by the
// same factor keeps the dog one size (see walking_companion_strip.dart).
const double _walkNative = 88;
const double _sitNative = 64;
const double _bubbleWidth = 340;
// The bubble's parts around the words (see [_bubbleHeightFor]): the box's
// padding and border, the gap the words keep on their right, and the tail.
const double _bubbleFrame = 23;
const double _bubbleTextInset = 35;
const double _tailHeight = 10;
// However little room is left, the bubble keeps this much: the speaker
// line and Next, with a line of words scrolling between them.
const double _bubbleMinHeight = 120;

/// The bubble's left edge and width on a screen [screenWidth] wide.
(double, double) _bubbleBox(double screenWidth) {
  final left = ((screenWidth - _bubbleWidth) / 2).clamp(12.0, screenWidth);
  return (left, math.min(_bubbleWidth, screenWidth - 2 * left));
}

TextStyle? _bubbleTextStyle(ThemeData theme) => theme.textTheme.bodyLarge
    ?.copyWith(fontFamily: InkFonts.prose, fontSize: 16, height: 1.45);

/// How tall the bubble grows around [text] at [width]: the words laid out
/// in the player's own text size, the speaker line, Next, the padding and
/// the tail. The guide keeps that much room free beside itself (see
/// [_GuideTourState._placeDog]), so a long line on a small phone with large
/// text never pushes Next off the screen.
double _bubbleHeightFor(BuildContext context, String text, double width) {
  final scaler = MediaQuery.textScalerOf(context);
  final painter = TextPainter(
    text: TextSpan(text: text, style: _bubbleTextStyle(Theme.of(context))),
    textDirection: Directionality.of(context),
    textScaler: scaler,
  )..layout(maxWidth: math.max(1.0, width - _bubbleTextInset));
  final words = painter.height;
  painter.dispose();
  final speaker = math.max(40.0, scaler.scale(20));
  final next = math.max(48.0, scaler.scale(14) + 28);
  return _bubbleFrame + speaker + words + next + _tailHeight;
}

final Map<String, List<String>> _neutralWalk = {
  'east': companionFrames('Walking/east', 8),
  'west': companionFrames('Walking/west', 8),
  'north': companionFrames('Walking/north', 8),
  'south': companionFrames('Walking/south', 8),
};
final List<String> _angelWalk = companionFrames('walking_angel/east', 8);
final List<String> _demonWalk = companionFrames('walking_evil/east', 8);
const String _neutralSit =
    '$companionAssetsRoot/Sitting_down/rotations/south.png';
const String _angelSit =
    '$companionAssetsRoot/Make_it_with_angel_w/rotations/south.png';
const String _demonSit =
    '$companionAssetsRoot/Make_it_with_demon_w/rotations/south.png';

/// The tour itself, full screen over the app: the rest of the screen
/// dimmed around the lit part, the guide dog, and what it says in a
/// speech bubble. Tap anywhere (or Next) to go on; Skip ends it.
class GuideTour extends ConsumerStatefulWidget {
  const GuideTour({super.key, required this.topic});

  final TutorialTopic topic;

  @override
  ConsumerState<GuideTour> createState() => _GuideTourState();
}

class _GuideTourState extends ConsumerState<GuideTour>
    with TickerProviderStateMixin {
  late final AnimationController _move;
  late final AnimationController _gait;
  Timer? _typer;

  int _step = 0;
  bool _arrived = false;
  bool _started = false;
  int _chars = 0;
  // Where the dog is walking from and to (its box's top-left), and the
  // lit rectangle it is moving from and to.
  Offset _dogFrom = Offset.zero;
  Offset _dogTo = Offset.zero;
  Rect? _holeFrom;
  Rect? _holeTo;
  bool _bubbleAbove = true;
  int _moveId = 0;
  // Set once the guide has read a line aloud, to hush it when the tour
  // ends (ref can't be read in dispose).
  TtsNotifier? _voice;

  List<TutorialStep> get _steps => widget.topic.steps;

  @override
  void initState() {
    super.initState();
    _move = AnimationController(vsync: this);
    _gait = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goTo(0));
  }

  @override
  void dispose() {
    _typer?.cancel();
    _move.dispose();
    _gait.dispose();
    _voice?.stop();
    _tourShowing = false;
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  String _textOf(int step) {
    final name = ref.read(companionNameProvider);
    return tr(ref, _steps[step].textKey).replaceAll(
        '{name}', name.isEmpty ? tr(ref, 'tut_guide_default_name') : name);
  }

  Future<void> _goTo(int step) async {
    if (!mounted) return;
    final id = ++_moveId;
    _typer?.cancel();
    setState(() {
      _step = step;
      _arrived = false;
      _chars = 0;
    });
    final media = MediaQuery.of(context);
    final screen = media.size;

    Rect? hole;
    final targetId = _steps[step].target;
    final target = targetId == null ? null : _shownTarget(targetId);
    if (target != null) {
      await Scrollable.ensureVisible(target,
          alignment: 0.25,
          duration: _reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 300));
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || id != _moveId) return;
      if (target.mounted) hole = _rectOf(target, screen);
    }

    final (_, bubbleWidth) = _bubbleBox(screen.width);
    final room = _bubbleHeightFor(context, _textOf(step), bubbleWidth);
    final (dog, above) = _placeDog(hole, screen, media.padding, room);
    final from = _started
        ? Offset.lerp(
            _dogFrom, _dogTo, Curves.easeInOut.transform(_move.value))!
        : Offset(-_dogSize, dog.dy);
    final holeFrom = _started ? _currentHole : null;
    _started = true;
    final distance = (dog - from).distance;
    setState(() {
      _dogFrom = from;
      _dogTo = dog;
      _holeFrom = holeFrom;
      _holeTo = hole;
      _bubbleAbove = above;
    });
    _move.duration = _reduceMotion
        ? Duration.zero
        : Duration(
            milliseconds: (distance / 320 * 1000).clamp(250, 1500).round());
    await _move.forward(from: 0).orCancel.catchError((_) {});
    if (!mounted || id != _moveId) return;
    setState(() => _arrived = true);
    if (ref.read(tutorialProvider).voice) _speak();
    final text = _textOf(step);
    if (_reduceMotion) {
      setState(() => _chars = text.length);
    } else {
      _typer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (!mounted) return timer.cancel();
        setState(() => _chars = math.min(text.length, _chars + 1));
        if (_chars >= text.length) timer.cancel();
      });
    }
  }

  Rect? get _currentHole {
    final t = Curves.easeInOut.transform(_move.value);
    final from = _holeFrom;
    final to = _holeTo;
    if (from == null && to == null) return null;
    return Rect.lerp(
        from ?? Rect.fromCenter(center: to!.center, width: 0, height: 0),
        to ?? Rect.fromCenter(center: from!.center, width: 0, height: 0),
        t);
  }

  /// Where the dog sits for a step lighting [hole]: under it when there is
  /// more room below, else over it, near its middle; in the middle of the
  /// screen when nothing is lit. Also whether the bubble goes above the dog.
  /// [bubble] is the room the bubble needs (see [_bubbleHeightFor]); the
  /// dog leaves it free between itself and the screen's edge, even if that
  /// means sitting over part of the lit area.
  (Offset, bool) _placeDog(
      Rect? hole, Size screen, EdgeInsets padding, double bubble) {
    final top = padding.top + 56;
    final bottom = screen.height - padding.bottom - 12;
    // Never so much that the dog itself is pushed off the screen: past
    // that, the bubble's words scroll.
    final room = math.min(bubble, math.max(0.0, bottom - top - _dogSize));
    // A lit part taking most of the screen leaves no room beside it: the
    // guide sits over it, in the middle.
    if (hole == null || hole.height > screen.height * 0.5) {
      return (
        Offset(
            (screen.width - _dogSize) / 2,
            math.min(
                math.max((top + bottom + room) / 2 - _dogSize / 2, top + room),
                bottom - _dogSize)),
        true,
      );
    }
    final x = (hole.center.dx - _dogSize / 2)
        .clamp(16.0, math.max(16.0, screen.width - _dogSize - 16))
        .toDouble();
    final below = bottom - hole.bottom >= hole.top - top;
    if (below) {
      final y = math.min(hole.bottom + 4, bottom - _dogSize - room);
      return (Offset(x, math.max(top, y)), false);
    }
    final y = math.max(hole.top - 4 - _dogSize, top + room);
    return (Offset(x, math.min(y, bottom - _dogSize)), true);
  }

  void _speak([String? text]) {
    final voice = _voice ?? ref.read<TtsNotifier>(ttsProvider.notifier);
    _voice = voice;
    voice.speak(text ?? _textOf(_step), ref.read(appLanguageProvider));
  }

  void _next() {
    if (!_arrived) return;
    final text = _textOf(_step);
    if (_chars < text.length) {
      _typer?.cancel();
      setState(() => _chars = text.length);
      return;
    }
    if (_step + 1 < _steps.length) {
      _goTo(_step + 1);
    } else {
      _close();
    }
  }

  void _close() {
    _moveId++;
    _typer?.cancel();
    Navigator.of(context).pop();
  }

  List<String> _walkFrames(Offset delta, String alignment) {
    final horizontal = delta.dx.abs() >= delta.dy.abs();
    switch (alignment) {
      case 'Good':
        return _angelWalk;
      case 'Evil':
        return _demonWalk;
    }
    if (horizontal) return _neutralWalk[delta.dx >= 0 ? 'east' : 'west']!;
    return _neutralWalk[delta.dy < 0 ? 'north' : 'south']!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final media = MediaQuery.of(context);
    final screen = media.size;
    final alignment = ref.watch(playerSessionProvider).alignmentLabel;
    final voice = ref.watch(tutorialProvider.select((s) => s.voice));
    final name = ref.watch(companionNameProvider);
    final text = _started ? _textOf(_step) : '';
    final isLast = _step == _steps.length - 1;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _moveId++;
      },
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: Listenable.merge([_move, _gait]),
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_move.value);
            final dog = Offset.lerp(_dogFrom, _dogTo, t)!;
            final delta = _dogTo - _dogFrom;
            final walking = _started && !_arrived && delta.distance > 1;
            final frames = _walkFrames(delta, alignment);
            // The angel and demon only walk east: west is east mirrored.
            final flip = walking &&
                (alignment == 'Good' || alignment == 'Evil') &&
                delta.dx < 0 &&
                delta.dx.abs() >= delta.dy.abs();
            final sprite = walking
                ? frames[(_gait.value * frames.length).floor() % frames.length]
                : switch (alignment) {
                    'Good' => _angelSit,
                    'Evil' => _demonSit,
                    _ => _neutralSit,
                  };
            final spriteSize =
                walking ? _dogSize : _dogSize * _sitNative / _walkNative;
            final (bubbleLeft, bubbleWidth) = _bubbleBox(screen.width);
            // The bubble stays between the Skip button and the bottom of
            // the screen (the navigation bar), whatever its words.
            final safeTop = media.padding.top + 56;
            final safeBottom = screen.height - media.padding.bottom - 8;
            var bubbleTop = safeTop;
            var bubbleBottom = safeBottom;
            if (_bubbleAbove) {
              bubbleBottom = math.min(safeBottom, dog.dy + 6);
              if (bubbleBottom - safeTop < _bubbleMinHeight) {
                bubbleBottom = math.min(safeBottom, safeTop + _bubbleMinHeight);
              }
            } else {
              bubbleTop = math.max(safeTop, dog.dy + _dogSize + 2);
              if (safeBottom - bubbleTop < _bubbleMinHeight) {
                bubbleTop = math.max(safeTop, safeBottom - _bubbleMinHeight);
              }
            }
            final tailX = (dog.dx + _dogSize / 2 - bubbleLeft - 9)
                .clamp(14.0, bubbleWidth - 32);

            final bubble = _Bubble(
              speaker: name.isEmpty ? tr(ref, 'tut_guide_default_name') : name,
              fullText: text,
              shown: text.substring(0, math.min(_chars, text.length)),
              counter: '${_step + 1} / ${_steps.length}',
              nextLabel: tr(ref, isLast ? 'tut_done' : 'tut_next'),
              onNext: _next,
              voice: voice,
              voiceLabel: tr(ref, voice ? 'tut_voice_off' : 'tut_voice_on'),
              onVoice: () {
                final on = !voice;
                ref.read(tutorialProvider.notifier).setVoice(on);
                if (on) {
                  _speak(text);
                } else {
                  _voice?.stop();
                }
              },
              tailX: tailX.toDouble(),
              tailDown: _bubbleAbove,
            );

            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _next,
                    child: CustomPaint(
                      painter: _DimPainter(
                        hole: _started ? _currentHole : null,
                        dim: Colors.black
                            .withValues(alpha: _holeTo == null ? 0.45 : 0.6),
                        ring: ink.gold,
                      ),
                    ),
                  ),
                ),
                if (_started)
                  Positioned(
                    left: dog.dx,
                    top: dog.dy,
                    width: _dogSize,
                    height: _dogSize,
                    child: IgnorePointer(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Transform.flip(
                          flipX: flip,
                          child: Image.asset(
                            sprite,
                            key: const Key('guide_dog'),
                            width: spriteSize,
                            height: spriteSize,
                            filterQuality: FilterQuality.none,
                            gaplessPlayback: true,
                            errorBuilder: (_, __, ___) => Icon(Icons.pets,
                                size: spriteSize * 0.6, color: ink.gold),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_arrived)
                  Positioned(
                    left: bubbleLeft,
                    width: bubbleWidth,
                    top: bubbleTop,
                    bottom: screen.height - bubbleBottom,
                    child: Align(
                      alignment: _bubbleAbove
                          ? Alignment.bottomCenter
                          : Alignment.topCenter,
                      child: bubble,
                    ),
                  ),
                Positioned(
                  top: media.padding.top + 8,
                  right: 12,
                  child: OutlinedButton.icon(
                    key: const Key('tutorial_skip'),
                    onPressed: _close,
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.surface.withValues(alpha: 0.92),
                      minimumSize: const Size(0, 40),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(tr(ref, 'tut_skip')),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// What the guide says, in a speech bubble whose tail points at it.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.speaker,
    required this.fullText,
    required this.shown,
    required this.counter,
    required this.nextLabel,
    required this.onNext,
    required this.voice,
    required this.voiceLabel,
    required this.onVoice,
    required this.tailX,
    required this.tailDown,
  });

  final String speaker;
  final String fullText;
  final String shown;
  final String counter;
  final String nextLabel;
  final VoidCallback onNext;
  final bool voice;
  final String voiceLabel;
  final VoidCallback onVoice;
  final double tailX;
  final bool tailDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final fill = theme.colorScheme.surfaceContainerHigh;
    final textStyle = _bubbleTextStyle(theme);
    final tail = Padding(
      padding: EdgeInsets.only(left: tailX),
      child: CustomPaint(
        size: const Size(18, 10),
        painter: _TailPainter(fill: fill, stroke: ink.gold, down: tailDown),
      ),
    );
    final box = Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ink.gold, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(speaker.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                        fontFamily: InkFonts.system,
                        letterSpacing: 1.5,
                        color: ink.gold)),
              ),
              Text(counter,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(fontFamily: InkFonts.system, color: ink.ash)),
              IconButton(
                tooltip: voiceLabel,
                visualDensity: VisualDensity.compact,
                onPressed: onVoice,
                icon: Icon(voice ? Icons.volume_up : Icons.volume_off_outlined,
                    size: 20, color: voice ? ink.gold : ink.ash),
              ),
            ],
          ),
          // Where the screen is short, the words scroll and Next stays put.
          Flexible(
            child: SingleChildScrollView(
              primary: false,
              padding: const EdgeInsets.only(right: 8),
              child: Semantics(
                liveRegion: true,
                label: fullText,
                child: ExcludeSemantics(
                  // The whole line takes its room from the start, so the
                  // bubble doesn't grow while the words come.
                  child: Stack(
                    children: [
                      Opacity(
                          opacity: 0, child: Text(fullText, style: textStyle)),
                      Text(shown, style: textStyle),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('tutorial_next'),
              onPressed: onNext,
              child: Text(nextLabel),
            ),
          ),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tailDown
          ? [Flexible(child: box), tail]
          : [tail, Flexible(child: box)],
    );
  }
}

class _TailPainter extends CustomPainter {
  _TailPainter({required this.fill, required this.stroke, required this.down});

  final Color fill;
  final Color stroke;
  final bool down;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = down
        ? (Path()
          ..moveTo(0, -1)
          ..lineTo(w / 2, h)
          ..lineTo(w, -1))
        : (Path()
          ..moveTo(0, h + 1)
          ..lineTo(w / 2, 0)
          ..lineTo(w, h + 1));
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
        path,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _TailPainter old) =>
      old.fill != fill || old.stroke != stroke || old.down != down;
}

/// The screen dimmed all over but for [hole], ringed in [ring].
class _DimPainter extends CustomPainter {
  _DimPainter({required this.hole, required this.dim, required this.ring});

  final Rect? hole;
  final Color dim;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Offset.zero & size;
    final hole = this.hole;
    if (hole == null || hole.isEmpty) {
      canvas.drawRect(screen, Paint()..color = dim);
      return;
    }
    final lit =
        RRect.fromRectAndRadius(hole.inflate(6), const Radius.circular(8));
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(screen)
        ..addRRect(lit),
      Paint()..color = dim,
    );
    canvas.drawRRect(
      lit,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _DimPainter old) =>
      old.hole != hole || old.dim != dim || old.ring != ring;
}
