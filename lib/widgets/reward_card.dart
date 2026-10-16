// The reward card (Wave 8, docs/proposals/reward-popups.md, card A): one
// card for every kind of reward, so it is learnt once. A header in the
// source's own colour (a small kind label over the title in the display
// font), one row per reward (an icon tile, a name, a sub-line, the value at
// the right), notes of their own in a dashed box, and one button that says
// what happens next. Rows come in one after another; with reduced motion
// they are simply there.
import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/stitched_ink.dart';

/// One reward: its [icon] on a tile in [accent], its [title] and [sub]-line,
/// the [value] at the right, a [tag] beside the title (a rarity), a [bar]
/// (0 to 1) under it for what fills (experience) and a [glow] for a rare
/// find.
class RewardLine {
  const RewardLine({
    required this.icon,
    required this.accent,
    required this.title,
    this.sub = '',
    this.value = '',
    this.tag = '',
    this.tagColor,
    this.bar,
    this.glow = false,
    this.key,
  });

  final Widget icon;
  final Color accent;
  final String title;
  final String sub;
  final String value;
  final String tag;
  final Color? tagColor;
  final double? bar;
  final bool glow;
  final Key? key;
}

/// A note set apart under the rows: what changed the outcome, with the gold
/// it paid as a [chip] when there is one.
class RewardNote {
  const RewardNote(this.text, {this.chip = ''});

  final String text;
  final String chip;
}

/// A big figure with its label (card B: gold and XP as two counters), and a
/// small [sub] under the label when there is something to say (a level
/// reached).
class RewardCounter {
  const RewardCounter({
    required this.value,
    required this.label,
    required this.accent,
    this.sub = '',
    this.key,
  });

  final String value;
  final String label;
  final Color accent;
  final String sub;
  final Key? key;
}

/// Everything the card shows. With a [hero] (the path of an art strip) the
/// card is the banner-led one (B): the strip carries the kind and the
/// title, and the [counters] stand under it.
class RewardCardData {
  const RewardCardData({
    required this.kind,
    required this.title,
    required this.accent,
    required this.button,
    this.lines = const [],
    this.notes = const [],
    this.hero,
    this.counters = const [],
  });

  final String? hero;
  final List<RewardCounter> counters;

  /// The small label over the title ("QUEST COMPLETE · CHAPTER 1").
  final String kind;
  final String title;
  final Color accent;
  final String button;
  final List<RewardLine> lines;
  final List<RewardNote> notes;
}

/// Shows [data] as a dialog until its button is tapped.
Future<void> showRewardCard(BuildContext context, RewardCardData data) =>
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: data.title,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, __) => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: RewardCard(
                data: data,
                onDone: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );

class RewardCard extends StatefulWidget {
  const RewardCard({super.key, required this.data, required this.onDone});

  final RewardCardData data;
  final VoidCallback onDone;

  @override
  State<RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends State<RewardCard>
    with SingleTickerProviderStateMixin {
  static const _stagger = Duration(milliseconds: 60);
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration:
        const Duration(milliseconds: 280) + _stagger * widget.data.lines.length,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _in.value = 1;
    } else {
      unawaited(_in.forward());
    }
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  /// Row [i]'s own slice of the animation.
  Animation<double> _slice(int i) {
    final total = _in.duration!.inMilliseconds;
    final begin = (_stagger.inMilliseconds * i) / total;
    final end = (begin + 280 / total).clamp(0.0, 1.0);
    return CurvedAnimation(
        parent: _in, curve: Interval(begin, end, curve: Curves.easeOut));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Material(
      key: const Key('reward_card'),
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: data.accent.withValues(alpha: 0.9)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          data.hero == null
              ? _plainHeader(theme, data)
              : _heroHeader(theme, data),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (data.counters.isNotEmpty) _counters(context, data),
                  for (var i = 0; i < data.lines.length; i++) ...[
                    if (i > 0 || data.counters.isNotEmpty)
                      Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.6)),
                    _row(context, data.lines[i], _slice(i)),
                  ],
                  for (final note in data.notes) _note(context, note, ink),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: FilledButton(
              key: const Key('reward_button'),
              style: FilledButton.styleFrom(
                  backgroundColor: data.accent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(44)),
              onPressed: widget.onDone,
              child: Text(data.button),
            ),
          ),
        ],
      ),
    );
  }

  Widget _plainHeader(ThemeData theme, RewardCardData data) => Container(
        key: const Key('reward_header'),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              data.accent.withValues(alpha: 0.30),
              data.accent.withValues(alpha: 0.06),
            ],
          ),
          border: Border(
              bottom: BorderSide(color: data.accent.withValues(alpha: 0.8))),
        ),
        child: _headerText(theme, data),
      );

  /// Card B's strip: the art, darkened from the left where the words sit.
  Widget _heroHeader(ThemeData theme, RewardCardData data) => SizedBox(
        key: const Key('reward_header'),
        height: 116,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              data.hero!,
              key: const Key('reward_hero'),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, __, ___) =>
                  ColoredBox(color: data.accent.withValues(alpha: 0.3)),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.78),
                    Colors.black.withValues(alpha: 0.35),
                  ],
                ),
                border: Border(bottom: BorderSide(color: data.accent)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: _headerText(theme, data),
              ),
            ),
          ],
        ),
      );

  Widget _headerText(ThemeData theme, RewardCardData data) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.kind.toUpperCase(),
            key: const Key('reward_kind'),
            style: theme.textTheme.labelSmall?.copyWith(
                color: data.accent,
                fontFamily: InkFonts.system,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          Text(
            data.title,
            key: const Key('reward_title'),
            style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: InkFonts.display,
                color: data.hero == null
                    ? theme.colorScheme.onSurface
                    : Colors.white),
          ),
        ],
      );

  /// Card B's counters: gold and XP as two big figures side by side.
  Widget _counters(BuildContext context, RewardCardData data) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        children: [
          for (var i = 0; i < data.counters.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: FadeTransition(
                opacity: _slice(i),
                child: Container(
                  key: data.counters[i].key,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: theme.colorScheme.outlineVariant, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(data.counters[i].value,
                          style: theme.textTheme.headlineSmall?.copyWith(
                              fontFamily: InkFonts.system,
                              color: data.counters[i].accent,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(data.counters[i].label.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFamily: InkFonts.system)),
                      if (data.counters[i].sub.isNotEmpty)
                        Text(data.counters[i].sub,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: data.counters[i].accent,
                                fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, RewardLine line, Animation<double> anim) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
            .animate(anim),
        child: Padding(
          key: line.key,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: line.accent.withValues(alpha: 0.14),
                  border: Border.all(color: line.accent, width: 2),
                  boxShadow: line.glow
                      ? [
                          BoxShadow(
                              color: line.accent.withValues(alpha: 0.5),
                              blurRadius: 10)
                        ]
                      : null,
                ),
                child: line.icon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(line.title,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        if (line.tag.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: (line.tagColor ?? line.accent)
                                  .withValues(alpha: 0.16),
                            ),
                            child: Text(line.tag,
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: line.tagColor ?? line.accent,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                    if (line.bar != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            key: const Key('reward_bar'),
                            value: line.bar!.clamp(0.0, 1.0),
                            minHeight: 6,
                            color: line.accent,
                            backgroundColor:
                                line.accent.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                    if (line.sub.isNotEmpty)
                      Text(line.sub,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (line.value.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(line.value,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: InkFonts.system,
                        color: line.accent,
                        fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _note(BuildContext context, RewardNote note, InkColors ink) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: CustomPaint(
        painter: _DashedBox(theme.colorScheme.outline),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: note.text),
                  if (note.chip.isNotEmpty)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          key: const Key('reward_note_chip'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: ink.gold.withValues(alpha: 0.16),
                          ),
                          child: Text(note.chip,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: ink.gold,
                                  fontFamily: InkFonts.system,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                ])),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A rounded box drawn with a dashed line.
class _DashedBox extends CustomPainter {
  _DashedBox(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(0.5), const Radius.circular(8));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBox old) => old.color != color;
}
