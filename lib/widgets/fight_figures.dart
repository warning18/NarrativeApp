// The fighters standing on the fight board (v1.911): the hero and the allies
// on the left facing east, the foes on the right facing west, along the top
// edge of the dice stage, drawn from the same sprites the Journey scenes use
// (fight_sprites.dart). They are a picture: no touch, no animation, and the
// dice are drawn over them. A fighter with no sprite is left out (its card is
// still there). Sized by [height] (the tallest standing figure), scaled down
// together when the row would be wider than the board.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'fight_sprites.dart';

/// The height of the figure row for a board [width] in logical pixels: 62 on a
/// phone of 412, 54 at 360, 46 at 320 and below.
double fightFigureHeight(double width) => width < 340
    ? 46
    : width < 380
        ? 54
        : 62;

/// The sprite of a fighter: `hero` is the ronin; [ally] fighters are
/// companions (drawn mirrored, their art faces west), the rest enemies.
FightSpriteSet? fightFigureSet(String id, {required bool ally}) => id == 'hero'
    ? roninSprite
    : ally
        ? companionFightSprite(id)
        : enemyFightSprite(id);

class FightFigures extends StatefulWidget {
  const FightFigures({
    super.key,
    required this.allies,
    required this.foes,
    required this.height,
  });

  /// `hero` or a companion's id, in party order.
  final List<String> allies;

  /// The enemies' ids, in pack order.
  final List<String> foes;
  final double height;

  @override
  State<FightFigures> createState() => _FightFiguresState();
}

class _FightFiguresState extends State<FightFigures> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(FightFigures old) {
    super.didUpdateWidget(old);
    _load();
  }

  void _load() {
    for (final id in widget.allies) {
      final s = fightFigureSet(id, ally: true);
      if (s != null) FightSpriteImages.load(s);
    }
    for (final id in widget.foes) {
      final s = fightFigureSet(id, ally: false);
      if (s != null) FightSpriteImages.load(s);
    }
  }

  Widget _figure(String id, {required bool ally}) {
    final set = fightFigureSet(id, ally: ally);
    if (set == null) return const SizedBox.shrink();
    return ValueListenableBuilder<int>(
      valueListenable: FightSpriteImages.loaded,
      builder: (context, _, __) {
        final image = FightSpriteImages.idleOf(set);
        final use = FightSpriteImages.effective(set);
        final k = widget.height / 48 * use.drawScale;
        final w = use.frameWidth * k;
        final h = use.frameHeight * k;
        return SizedBox(
          key: Key('fight_figure_$id'),
          width: w,
          height: widget.height,
          child: image == null
              ? null
              : OverflowBox(
                  alignment: Alignment.bottomCenter,
                  minWidth: w,
                  maxWidth: w,
                  minHeight: h,
                  maxHeight: h,
                  child: Transform.translate(
                    offset: Offset(0, use.footInset * k),
                    child: Transform.scale(
                      scaleX: (ally && !use.facesEast) ? -1 : 1,
                      child: CustomPaint(
                        size: Size(w, h),
                        painter: _FigurePainter(image, use),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _side(List<String> ids, {required bool ally}) => Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final id in ids)
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomCenter,
                  child: _figure(id, ally: ally),
                ),
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => SizedBox(
        key: const Key('fight_figures'),
        height: widget.height,
        child: Row(
          children: [
            _side(widget.allies, ally: true),
            const SizedBox(width: 8),
            _side(widget.foes, ally: false),
          ],
        ),
      );
}

class _FigurePainter extends CustomPainter {
  _FigurePainter(this.image, this.set);

  final ui.Image image;
  final FightSpriteSet set;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawImageRect(
        image,
        Rect.fromLTWH(
            0, 0, set.frameWidth.toDouble(), set.frameHeight.toDouble()),
        Offset.zero & size,
        Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false,
      );

  @override
  bool shouldRepaint(_FigurePainter old) =>
      old.image != image || old.set != set;
}
