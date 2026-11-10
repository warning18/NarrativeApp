// The panel and the small-caps label of the app's own look (promoted from the
// Tower's screens, v1.871; v1.901: the A panel, a double ink line): the surface
// colour, an outer ink line, an inner seam line and a stitch in each corner
// (lib/theme/ink_frames.dart), with a gold inner line when lit; a label over
// a group of panels.
import 'package:flutter/material.dart';

import '../theme/ink_frames.dart';
import '../theme/stitched_ink.dart';

/// A panel: the surface colour in a double ink line, with a gold inner line
/// when [lit].
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
    final body = Container(
      padding: padding,
      decoration: ShapeDecoration(
        color: scheme.surfaceContainer,
        shape: InkPanelBorder(
          radius: 10,
          outer: inkOutlineFor(scheme.brightness),
          inner: lit ? ink.gold : ink.seam,
        ),
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
