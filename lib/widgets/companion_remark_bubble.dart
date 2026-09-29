import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/companion_remarks.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/remark_provider.dart';
import '../theme/stitched_ink.dart';
import '../tutorial/guide_tour.dart' show guideTourShowing;
import 'speech_bubble.dart';

/// Something a companion says: who, and the words.
class SpokenLine {
  const SpokenLine({
    required this.speaker,
    required this.line,
    this.companionId = '',
  });

  /// Their name, as the player knows it.
  final String speaker;
  final String line;

  /// Their id in the companions table: the badge the bubble points at
  /// shows its first letter ("Sister Maren" is M).
  final String companionId;
}

/// What [remarks] say (see companion_remarks.dart), with who says it, in
/// the player's language; a remark with no words (its lines emptied in
/// the Data tab) is left out.
List<SpokenLine> spokenRemarks(WidgetRef ref, List<CompanionRemark> remarks) {
  final french = ref.read(appLanguageProvider) == AppLanguage.fr;
  final book = ref.read(remarkBookProvider);
  final companions =
      ref.read(localizedDbProvider(companionsSchema)).value ?? const {};
  return [
    for (final remark in remarks)
      if (remark.lineFor(book, french: french).isNotEmpty)
        SpokenLine(
          speaker: (companions[remark.companionId]
                      as Map<String, dynamic>?)?['companionName']
                  ?.toString() ??
              remark.companionId,
          line: remark.lineFor(book, french: french),
          companionId: remark.companionId,
        ),
  ];
}

bool _showing = false;

/// Whether companions are speaking over the screen now.
bool get companionRemarksShowing => _showing;

/// Shows what [remarks] say in speech bubbles over the screen, one after
/// the other, the way the guide talks in a tour; done when the player has
/// tapped through them.
Future<void> showCompanionRemarks(
        BuildContext context, WidgetRef ref, List<CompanionRemark> remarks) =>
    showSpokenLines(context, ref, spokenRemarks(ref, remarks));

/// Shows [lines] in speech bubbles over the screen, one after the other:
/// each speaker's badge at the bottom of the screen (the first on the
/// left, who answers on the right) and the words typed out above it. Tap
/// anywhere (or Next) to go on.
Future<void> showSpokenLines(
    BuildContext context, WidgetRef ref, List<SpokenLine> lines) async {
  if (lines.isEmpty || _showing || !context.mounted) return;
  _showing = true;
  try {
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (_, __, ___) => CompanionRemarkOverlay(
          lines: lines,
          nextLabel: tr(ref, 'tut_next'),
          doneLabel: tr(ref, 'remark_done'),
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  } finally {
    _showing = false;
  }
}

const double _badgeSize = 52;
const double _bubbleWidth = 340;

/// The party speaking over the screen (see [showSpokenLines]).
class CompanionRemarkOverlay extends StatefulWidget {
  const CompanionRemarkOverlay({
    super.key,
    required this.lines,
    required this.nextLabel,
    required this.doneLabel,
  });

  final List<SpokenLine> lines;
  final String nextLabel;

  /// On the last line's button.
  final String doneLabel;

  @override
  State<CompanionRemarkOverlay> createState() => _CompanionRemarkOverlayState();
}

class _CompanionRemarkOverlayState extends State<CompanionRemarkOverlay> {
  int _index = 0;
  int _chars = 0;
  Timer? _typer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _type();
    }
  }

  @override
  void dispose() {
    _typer?.cancel();
    super.dispose();
  }

  String get _text => widget.lines[_index].line;

  void _type() {
    _typer?.cancel();
    if (MediaQuery.of(context).disableAnimations) {
      _chars = _text.length;
      return;
    }
    _chars = 0;
    _typer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _chars = math.min(_text.length, _chars + 1));
      if (_chars >= _text.length) timer.cancel();
    });
  }

  /// The words all at once if they are still coming; else the next line,
  /// or the screen back.
  void _next() {
    if (_chars < _text.length) {
      _typer?.cancel();
      setState(() => _chars = _text.length);
      return;
    }
    if (_index + 1 < widget.lines.length) {
      setState(() => _index++);
      _type();
    } else {
      _typer?.cancel();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final media = MediaQuery.of(context);
    final spoken = widget.lines[_index];
    final last = _index == widget.lines.length - 1;
    // Who answers stands across from who spoke first.
    final onLeft = _index.isEven;

    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(builder: (context, constraints) {
        final screen = constraints.biggest;
        final bubbleLeft =
            ((screen.width - _bubbleWidth) / 2).clamp(12.0, screen.width);
        final bubbleWidth = math.min(_bubbleWidth, screen.width - 2 * 12.0);
        const badgeInset = 20.0;
        final badgeLeft =
            onLeft ? badgeInset : screen.width - badgeInset - _badgeSize;
        final badgeBottom = media.padding.bottom + 20;
        final bubbleBottom = badgeBottom + _badgeSize + 2;
        final tailX = (badgeLeft + _badgeSize / 2 - bubbleLeft - 9)
            .clamp(14.0, math.max(14.0, bubbleWidth - 32));

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                key: const Key('remark_bubble_barrier'),
                behavior: HitTestBehavior.opaque,
                onTap: _next,
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
              ),
            ),
            Positioned(
              left: badgeLeft,
              bottom: badgeBottom,
              width: _badgeSize,
              height: _badgeSize,
              child: IgnorePointer(
                child: AnimatedSwitcher(
                  duration: media.disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: CurvedAnimation(
                        parent: animation, curve: Curves.easeOutBack),
                    child: child,
                  ),
                  child: _Badge(
                    key: ValueKey(_index),
                    letter: _initialOf(spoken),
                    fill: theme.colorScheme.surfaceContainerHigh,
                    ring: ink.gold,
                  ),
                ),
              ),
            ),
            Positioned(
              left: bubbleLeft,
              width: bubbleWidth,
              top: media.padding.top + 16,
              bottom: bubbleBottom,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SpeechBubble(
                  key: const Key('remark_bubble'),
                  nextKey: const Key('remark_next'),
                  speaker: spoken.speaker,
                  fullText: spoken.line,
                  shown: spoken.line.substring(0, _chars),
                  counter: widget.lines.length > 1
                      ? '${_index + 1} / ${widget.lines.length}'
                      : null,
                  nextLabel: last ? widget.doneLabel : widget.nextLabel,
                  onNext: _next,
                  tailX: tailX.toDouble(),
                  tailDown: true,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  static String _initialOf(SpokenLine spoken) {
    final name = spoken.companionId.isNotEmpty
        ? spoken.companionId
        : spoken.speaker.trim();
    return name.isEmpty ? '?' : name.characters.first.toUpperCase();
  }
}

/// The speaker, as a round badge with their initial.
class _Badge extends StatelessWidget {
  const _Badge({
    super.key,
    required this.letter,
    required this.fill,
    required this.ring,
  });

  final String letter;
  final Color fill;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontFamily: InkFonts.display,
            fontSize: 26,
            height: 1,
            color: ring,
          ),
        ),
      ),
    );
  }
}

/// Shows [remarks] in speech bubbles once they are set and the screen
/// under [child] is on top and [ready]: after the pop-ups that come with
/// a new scene (an arrival, a discovery) and after a tour. Each set shows
/// once, however often the screen is rebuilt (see [shownRemarksProvider]).
class CompanionRemarksTrigger extends ConsumerStatefulWidget {
  const CompanionRemarksTrigger({
    super.key,
    required this.remarks,
    required this.child,
    this.ready = true,
  });

  final List<CompanionRemark> remarks;
  final Widget child;
  final bool ready;

  @override
  ConsumerState<CompanionRemarksTrigger> createState() =>
      _CompanionRemarksTriggerState();
}

class _CompanionRemarksTriggerState
    extends ConsumerState<CompanionRemarksTrigger> {
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _consider();
  }

  @override
  void didUpdateWidget(covariant CompanionRemarksTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    _consider();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _due =>
      widget.ready &&
      widget.remarks.isNotEmpty &&
      !identical(ref.read(shownRemarksProvider), widget.remarks);

  void _consider() {
    if (_timer != null || !_due) return;
    // A moment for the scene to settle, and for what opens with it (an
    // arrival, a discovery, a tour) to open first.
    _timer = Timer(const Duration(milliseconds: 450), () {
      _timer = null;
      if (!mounted || !_due) return;
      // Something over the screen: tried again once it's gone (the route
      // below becoming current again calls didChangeDependencies).
      if (guideTourShowing ||
          companionRemarksShowing ||
          ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      final remarks = widget.remarks;
      ref.read(shownRemarksProvider.notifier).state = remarks;
      showCompanionRemarks(context, ref, remarks);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilt, and so reconsidered, when a route over this one goes.
    ModalRoute.of(context);
    return widget.child;
  }
}
