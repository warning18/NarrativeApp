// The panel and the small-caps label of the app's own look (promoted from the
// Tower's screens, v1.871): the surface colour, a seam border and round
// corners, with a gold edge when lit; a label over a group of panels.
import 'package:flutter/material.dart';

import '../screens/tower/tower_look.dart';
import '../theme/frame_style.dart';
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
    this.decor = EnvParts.none,
  });

  final Widget child;
  final bool lit;
  final bool dim;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  /// The place's decorations this panel wears (none by default): a screen
  /// gives a few of its panels a share, so the frames stay clean otherwise.
  final EnvParts decor;

  @override
  Widget build(BuildContext context) {
    final ink = InkColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final f = Theme.of(context).extension<FrameStyle>();
    if (TowerPanelStyle.of(context) &&
        f != null &&
        FrameImages.ready(f.material, f.env)) {
      final framed = Container(
        // Top pieces (32 px tall at 2x) hang below the frame's edge: the
        // content starts under them, never under a piece.
        padding: padding
            .add(EdgeInsets.all(2.0 * f.compactScale))
            .add(EdgeInsets.only(top: decor.top > 0 ? 12 : 0)),
        decoration: ShapeDecoration(
          color: scheme.surfaceContainer,
          shape: FrameBorder(
              piece: FramePiece.panelDark,
              material: f.material,
              env: decor == EnvParts.none ? EnvDecor.none : f.env,
              envParts: decor,
              envPixel: f.compactScale,
              pixel: f.compactScale,
              seed: f.seed * 31 + decor.hashCode),
        ),
        child: Opacity(opacity: dim ? .5 : 1, child: child),
      );
      return onTap == null ? framed : InkWell(onTap: onTap, child: framed);
    }
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
