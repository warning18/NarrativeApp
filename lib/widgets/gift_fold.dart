// A gift's row on the Character tab (v1.266): its title, how many there are,
// a one-line summary, and a chevron; a tap opens what it holds in place.
// Folded by default, and the choice is kept for the session (the same
// provider as InkFold).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/stitched_ink.dart';
import 'ink_fold.dart';

class GiftFold extends ConsumerWidget {
  const GiftFold({
    super.key,
    required this.id,
    required this.title,
    required this.summary,
    required this.child,
    this.count,
  });

  /// Keys the state; also the widget keys: `gift_fold_<id>` on the header
  /// row, `gift_fold_body_<id>` on what it shows.
  final String id;
  final String title;

  /// How many it holds; shown as a small box by the title.
  final int? count;

  /// One line of what is inside (the names), or of why it is empty.
  final String summary;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final open =
        ref.watch(foldedSectionsProvider.select((s) => s.contains('open:$id')));
    void toggle() {
      final set = {...ref.read(foldedSectionsProvider)};
      open ? set.remove('open:$id') : set.add('open:$id');
      ref.read(foldedSectionsProvider.notifier).state = set;
    }

    return Material(
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: ink.seam),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: InkWell(
              key: Key('gift_fold_$id'),
              onTap: toggle,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                child: Row(
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    if (count != null && count! > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: ink.seam),
                        ),
                        child: Text('$count',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: ink.ash)),
                      ),
                    ],
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style:
                            theme.textTheme.bodySmall?.copyWith(color: ink.ash),
                      ),
                    ),
                    Icon(open ? Icons.expand_less : Icons.expand_more,
                        size: 20, color: ink.ash),
                  ],
                ),
              ),
            ),
          ),
          if (open)
            Padding(
              key: Key('gift_fold_body_$id'),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: child,
            ),
        ],
      ),
    );
  }
}
