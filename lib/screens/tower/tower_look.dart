// The Tower's look (v1.900, UX-2's option B): the whole climb in the night
// theme (the dark scheme of the app's palette, on the Tower's own screens
// only), the foe standing in its panel when it has art.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/palette_provider.dart';
import '../../theme/stitched_ink.dart';
import '../../widgets/fight_sprites.dart';

/// The Tower's screens wear this: the dark scheme of the current palette. Each Tower screen is a thin wrapper that puts its body
/// under it, so the body's own theme reads, and the dialogs it opens, are dark.
class TowerNight extends ConsumerWidget {
  const TowerNight({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(appPaletteProvider);
    return Theme(
      data: buildAppTheme(palette.schemeFor(Brightness.dark)),
      child: child,
    );
  }
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
