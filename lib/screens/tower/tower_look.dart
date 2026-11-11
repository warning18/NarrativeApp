// The Tower's look (v1.900, UX-2's option B): the whole climb in the night
// theme (the dark scheme of the app's palette, on the Tower's own screens
// only), its panels in the double-ink-line and bevel style, the foe standing
// in its panel when it has art.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/palette_provider.dart';
import '../../theme/stitched_ink.dart';
import '../../widgets/fight_sprites.dart';

/// Whether the panels under it wear the Tower's double ink line and bevel.
class TowerPanelStyle extends InheritedWidget {
  const TowerPanelStyle({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TowerPanelStyle>() != null;

  @override
  bool updateShouldNotify(TowerPanelStyle old) => false;
}

/// The Tower's screens wear this: the dark scheme of the current palette, and
/// the bevel panels. Each Tower screen is a thin wrapper that puts its body
/// under it, so the body's own theme reads, and the dialogs it opens, are dark.
class TowerNight extends ConsumerWidget {
  const TowerNight({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(appPaletteProvider);
    return Theme(
      data: buildAppTheme(palette.schemeFor(Brightness.dark)),
      child: TowerPanelStyle(child: child),
    );
  }
}

/// A double ink line (an outer dark line, a gap, an inner seam) with a bevel
/// (a light top-left edge and a shaded bottom-right edge just inside).
class BevelPanelPainter extends CustomPainter {
  BevelPanelPainter({
    required this.outer,
    required this.inner,
    required this.light,
    required this.shade,
    required this.radius,
  });

  final Color outer, inner, light, shade;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    Paint stroke(double w, Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = c;
    canvas.drawRRect(r.deflate(0.75), stroke(1.5, outer));
    final inset = r.deflate(3.5);
    canvas.drawRRect(inset, stroke(1, inner));
    final b = inset.deflate(1.5);
    final top = Path()
      ..moveTo(b.left, b.bottom - radius)
      ..lineTo(b.left, b.top + radius)
      ..quadraticBezierTo(b.left, b.top, b.left + radius, b.top)
      ..lineTo(b.right - radius, b.top);
    final bottom = Path()
      ..moveTo(b.right, b.top + radius)
      ..lineTo(b.right, b.bottom - radius)
      ..quadraticBezierTo(b.right, b.bottom, b.right - radius, b.bottom)
      ..lineTo(b.left + radius, b.bottom);
    canvas.drawPath(top, stroke(1.5, light));
    canvas.drawPath(bottom, stroke(1.5, shade));
  }

  @override
  bool shouldRepaint(BevelPanelPainter old) =>
      old.outer != outer ||
      old.inner != inner ||
      old.light != light ||
      old.shade != shade ||
      old.radius != radius;
}

/// A foe standing: its sprite, as drawn (facing west, toward the hero).
class TowerFoeFigure extends StatelessWidget {
  const TowerFoeFigure(this.enemyId, {super.key, this.size = 56});

  final String enemyId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final set = enemyFightSprite(enemyId);
    if (set == null) return const SizedBox.shrink();
    return ValueListenableBuilder<int>(
      valueListenable: FightSpriteImages.loaded,
      builder: (context, _, __) {
        final image = FightSpriteImages.idleOf(set);
        return SizedBox(
          key: Key('tower_foe_$enemyId'),
          width: size,
          height: size,
          child: image == null
              ? null
              : CustomPaint(
                  painter: _FoePainter(image, set.frameWidth, set.frameHeight)),
        );
      },
    );
  }
}

class _FoePainter extends CustomPainter {
  _FoePainter(this.image, this.w, this.h);

  final ui.Image image;
  final int w, h;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Offset.zero & size,
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false);

  @override
  bool shouldRepaint(_FoePainter old) => old.image != image;
}
