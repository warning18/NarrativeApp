// A chibi standing in ink (v1.1005, UX-2): the figure's own sprite, recoloured
// once by InkSprites (ink_sprites.dart), its first frame drawn crisp. The foe
// faces west and the hero east, as drawn; nothing is redrawn.
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../../widgets/fight_sprites.dart';
import 'ink_sprites.dart';

class InkFigure extends StatefulWidget {
  const InkFigure(this.set, {super.key, this.size = 56});

  final FightSpriteSet set;
  final double size;

  @override
  State<InkFigure> createState() => _InkFigureState();
}

class _InkFigureState extends State<InkFigure> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(InkFigure old) {
    super.didUpdateWidget(old);
    if (old.set.idleAsset != widget.set.idleAsset) {
      _image = null;
      _load();
    }
  }

  Future<void> _load() async {
    final asset = widget.set.idleAsset;
    try {
      final image = await InkSprites.of(asset);
      if (mounted && widget.set.idleAsset == asset) {
        setState(() => _image = image);
      }
    } catch (_) {
      // No art: nothing stands there (the panel still reads).
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: _image == null
            ? null
            : CustomPaint(
                painter: _InkFigurePainter(
                  _image!,
                  widget.set.frameWidth,
                  widget.set.frameHeight,
                ),
              ),
      );
}

class _InkFigurePainter extends CustomPainter {
  _InkFigurePainter(this.image, this.w, this.h);

  final ui.Image image;
  final int w, h;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawImageRect(
        image,
        // The recolour adds one pixel of ink on every side.
        Rect.fromLTWH(0, 0, w + 2.0, h + 2.0),
        Offset.zero & size,
        Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false,
      );

  @override
  bool shouldRepaint(_InkFigurePainter old) => old.image != image;
}
