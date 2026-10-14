// A section that folds (v1.201): its title row stays, a tap on it hides
// or shows what is under it, and the choice is kept for the session.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../theme/stitched_ink.dart';

/// The ids of the sections folded shut, for the session.
final foldedSectionsProvider = StateProvider<Set<String>>((ref) => const {});

class InkFold extends ConsumerWidget {
  const InkFold({
    super.key,
    required this.id,
    required this.title,
    required this.children,
    this.count,
    this.trailing,
    this.initiallyFolded = false,
    this.dense = false,
  });

  /// Keys the fold's state; also the widget's keys: `fold_<id>` on the
  /// header, `fold_body_<id>` on what it shows.
  final String id;
  final String title;
  final List<Widget> children;

  /// A count shown by the title (what the fold holds), when known.
  final int? count;
  final Widget? trailing;
  final bool initiallyFolded;

  /// A card's inner section: smaller title, no top margin.
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final folded = ref.watch(foldedSectionsProvider.select(
        (s) => s.contains(id) || (initiallyFolded && !s.contains('open:$id'))));
    void toggle() {
      final set = {...ref.read(foldedSectionsProvider)};
      if (initiallyFolded) {
        folded ? set.add('open:$id') : set.remove('open:$id');
        folded ? set.remove(id) : set.add(id);
      } else {
        folded ? set.remove(id) : set.add(id);
      }
      ref.read(foldedSectionsProvider.notifier).state = set;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: !folded,
          child: InkWell(
            key: Key('fold_$id'),
            onTap: toggle,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: EdgeInsets.only(top: dense ? 0 : 24, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: dense
                            ? theme.textTheme.titleSmall
                            : theme.textTheme.titleMedium),
                  ),
                  if (count != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text('$count',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: ink.ash)),
                    ),
                  if (trailing != null) trailing!,
                  AnimatedRotation(
                    turns: folded ? 0 : 0.5,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.expand_more, size: 20, color: ink.ash),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: folded
              ? const SizedBox(width: double.infinity)
              : Column(
                  key: Key('fold_body_$id'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
        ),
      ],
    );
  }
}
