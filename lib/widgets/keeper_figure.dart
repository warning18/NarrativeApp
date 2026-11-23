// A shopkeeper standing in the keeper strip of their shop (the user's
// PixelLab characters, a three-quarter frame turned toward the words at the
// right). Eight of the fourteen keepers have a figure that fits; the others
// keep the shop's sign. The pictures are Art's 64x64 frames; each is cropped
// to the figure's own width and drawn at twice its size (about 100 px tall),
// feet at the bottom.
import 'package:flutter/material.dart';

/// Per shop: the left edge and width (in the frame's pixels) of the figure.
const Map<String, (int, int)> _keeperBox = {
  'weaponsmith_forge': (19, 24),
  'arcane_bazaar': (20, 23),
  'apothecary_row': (20, 23),
  'arcane_academy': (19, 24),
  'ossuary_relics': (19, 45),
  'last_lantern': (20, 23),
  'anchorage_chandlery': (20, 23),
  'black_market_docks': (19, 24),
};

/// Whether [shopId]'s keeper has a figure.
bool keeperHasFigure(String shopId) => _keeperBox.containsKey(shopId);

/// The scale the figures are drawn at.
const int keeperFigureScale = 2;

class KeeperFigure extends StatelessWidget {
  const KeeperFigure(this.shopId, {super.key});

  final String shopId;

  static const _y0 = 5, _h = 52;

  @override
  Widget build(BuildContext context) {
    final box = _keeperBox[shopId];
    if (box == null) return const SizedBox.shrink();
    final (x0, w) = box;
    const k = keeperFigureScale;
    return SizedBox(
      key: Key('keeper_figure_$shopId'),
      width: w * k.toDouble(),
      height: _h * k.toDouble(),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          minHeight: 0,
          maxWidth: 64.0 * k,
          maxHeight: 64.0 * k,
          child: Transform.translate(
            offset: Offset(-x0 * k.toDouble(), -_y0 * k.toDouble()),
            child: Image.asset(
              'assets/visuals/keepers/$shopId.png',
              width: 64.0 * k,
              height: 64.0 * k,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
              isAntiAlias: false,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
