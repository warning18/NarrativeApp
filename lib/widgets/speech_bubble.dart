import 'package:flutter/material.dart';

import '../theme/stitched_ink.dart';

/// The words in a speech bubble: the story's prose face, a size up.
TextStyle? speechBubbleTextStyle(ThemeData theme) => theme.textTheme.bodyLarge
    ?.copyWith(fontFamily: InkFonts.prose, fontSize: 16, height: 1.45);

/// Someone's words in a speech bubble whose tail points at them: their
/// name, the words as far as they have been typed out ([shown] of
/// [fullText]), and a button to go on. The guide's tour and the party's
/// remarks both speak in it.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.speaker,
    required this.fullText,
    required this.shown,
    required this.nextLabel,
    required this.onNext,
    required this.tailX,
    required this.tailDown,
    this.counter,
    this.voice = false,
    this.voiceLabel,
    this.onVoice,
    this.nextKey,
  });

  final String speaker;
  final String fullText;
  final String shown;
  final String nextLabel;
  final VoidCallback onNext;

  /// Where the tail sits along the bubble's edge, from its left.
  final double tailX;

  /// Whether the tail hangs from the bottom (the speaker is below).
  final bool tailDown;

  /// Which of how many ("1 / 3"); none when there is only the one.
  final String? counter;

  /// A button to have the words read aloud, lit while [voice] is on; none
  /// without [onVoice].
  final bool voice;
  final String? voiceLabel;
  final VoidCallback? onVoice;
  final Key? nextKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final fill = theme.colorScheme.surfaceContainerHigh;
    final textStyle = speechBubbleTextStyle(theme);
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
          ConstrainedBox(
            // The speaker line keeps its height with or without the voice
            // button beside it.
            constraints: const BoxConstraints(minHeight: 40),
            child: Row(
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
                if (counter != null)
                  Padding(
                    padding: EdgeInsets.only(right: onVoice == null ? 8 : 0),
                    child: Text(counter!,
                        style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: InkFonts.system, color: ink.ash)),
                  ),
                if (onVoice != null)
                  IconButton(
                    tooltip: voiceLabel,
                    visualDensity: VisualDensity.compact,
                    onPressed: onVoice,
                    icon: Icon(
                        voice ? Icons.volume_up : Icons.volume_off_outlined,
                        size: 20,
                        color: voice ? ink.gold : ink.ash),
                  ),
              ],
            ),
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
              key: nextKey,
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
