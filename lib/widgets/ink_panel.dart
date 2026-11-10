// The panel and the small-caps label of the app's own look (promoted from the
// Tower's screens, v1.871): the surface colour, a seam border and round
// corners, with a gold edge when lit; a label over a group of panels.
import 'package:flutter/material.dart';

import '../screens/tower/tower_look.dart';
import '../theme/stitched_ink.dart';

/// A panel: the surface colour, a seam border and
/// round corners, with a gold edge when [lit].
class InkPanel extends StatelessWidget {
  const InkPanel({
    super.key,
    required this.child,
    this.lit = false,
    this.dim = false,
    this.onTap,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final bool lit;
  final bool dim;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    if (TowerPanelStyle.of(context)) {
      // The Tower's panel (v1.900): a double ink line and a bevel.
      final panel = CustomPaint(
        foregroundPainter: BevelPanelPainter(
          outer: lit ? ink.gold : ink.seam,
          inner: lit ? ink.gold.withValues(alpha: .6) : ink.seam,
          light: Colors.white.withValues(alpha: .10),
          shade: Colors.black.withValues(alpha: .35),
          radius: 8,
        ),
        child: Container(
          padding: padding.add(const EdgeInsets.all(5)),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Opacity(opacity: dim ? .5 : 1, child: child),
        ),
      );
      return onTap == null
          ? panel
          : InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: panel);
    }
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: lit ? ink.gold : ink.seam, width: lit ? 1.6 : 1),
      ),
      child: Opacity(opacity: dim ? .5 : 1, child: child),
    );
    if (onTap == null) return body;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: body,
    );
  }
}

/// A small caps label over a group of panels.
class InkLabel extends StatelessWidget {
  const InkLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 6),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
}
