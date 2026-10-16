// The chapter signpost (v1.432): when the party is still under the level the
// next chapter recommends (Core's nextChapterLevelAdviceProvider, Narrative's
// line in chapters.json), the camp's chapter card and the Journey map say so
// before the party sets out, in the voice of the hints they already have: a
// row with an icon on the card, a small chip on the map. Nothing once the
// party has the level, or when the chapter recommends none.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapter_loop.dart' show ChapterLevelAdvice;
import '../data/map_charts.dart';
import '../l10n/app_strings.dart';
import '../providers/chapter_loop_provider.dart';
import '../theme/stitched_ink.dart';

/// The advice to show: the next chapter's, when the party is under it.
final levelSignpostProvider = Provider<ChapterLevelAdvice?>((ref) {
  final advice = ref.watch(nextChapterLevelAdviceProvider);
  return advice != null && advice.below ? advice : null;
});

String _sentence(WidgetRef ref, ChapterLevelAdvice advice) =>
    tr(ref, 'level_signpost')
        .replaceAll('{n}', '${advice.chapter}')
        .replaceAll('{level}', '${advice.recommendedLevel}')
        .replaceAll('{you}', '${advice.playerLevel}');

/// The hint row on the camp's chapter card: the sentence, and Narrative's
/// line under it when there is one.
class LevelSignpostRow extends ConsumerWidget {
  const LevelSignpostRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advice = ref.watch(levelSignpostProvider);
    if (advice == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Padding(
      key: const Key('level_signpost'),
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.signpost_outlined, size: 18, color: ink.ember),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_sentence(ref, advice), style: theme.textTheme.bodySmall),
                if (advice.note.isNotEmpty)
                  Text(advice.note,
                      style:
                          theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The chip on the Journey map, above the sky's: "Ch. 4 · lvl 9", or just
/// the level on a narrow screen; the whole sentence on a tap (and to a
/// screen reader).
class LevelSignpostChip extends ConsumerWidget {
  const LevelSignpostChip(
      {super.key, required this.palette, this.compact = false});

  final ChartPalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advice = ref.watch(levelSignpostProvider);
    if (advice == null) return const SizedBox.shrink();
    final ink = InkColors.of(context);
    final sentence = [
      _sentence(ref, advice),
      if (advice.note.isNotEmpty) advice.note,
    ].join(' ');
    final label =
        tr(ref, compact ? 'level_signpost_lv' : 'level_signpost_short')
            .replaceAll('{n}', '${advice.chapter}')
            .replaceAll('{level}', '${advice.recommendedLevel}');
    return Semantics(
      container: true,
      label: sentence,
      child: Tooltip(
        message: sentence,
        triggerMode: TooltipTriggerMode.tap,
        showDuration: const Duration(seconds: 6),
        child: DecoratedBox(
          key: const Key('journey_level_signpost'),
          decoration: BoxDecoration(
            color: palette.fog.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: ink.ember.withValues(alpha: 0.7)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.signpost_outlined, size: 13, color: ink.ember),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(
                        fontFamily: InkFonts.system,
                        fontSize: 11,
                        color: palette.place)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
