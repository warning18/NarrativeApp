// Small pieces the Tower's screens share (v1.847): a panel in today's look
// (ink panel, gold accent), a section label and a stat chip.
import 'package:flutter/material.dart';

import '../../theme/stitched_ink.dart';

/// A panel of the Tower's screens: the surface colour, a seam border and
/// round corners, with a gold edge when [lit].
class TowerPanel extends StatelessWidget {
  const TowerPanel({
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
class TowerLabel extends StatelessWidget {
  const TowerLabel(this.text, {super.key});

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
