// The desert road crossing's painted layers (Art's, assets/visuals/crossing/
// desert/): a sky, far mesas, mid dunes and near sand, drawn in place of the
// desert kit's code hills at the same speeds. Only the road crossing asks for
// them (desertLayers(painted: true)); until they are decoded the code kit is
// what paints, so nothing waits on the art.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One painted layer: its file, its top row on the scene's 72-row grid, and
/// whether it tiles (the sky is static).
class DesertPicture {
  const DesertPicture(this.name, this.top, {this.tiles = true});

  final String name;
  final int top;
  final bool tiles;
}

abstract final class DesertPictures {
  static const sky = DesertPicture('sky', 0, tiles: false);
  static const far = DesertPicture('far', 28);
  static const mid = DesertPicture('mid', 38);
  static const near = DesertPicture('near', 48);

  /// Below the layers' feet (rows 52 to 71) the sand the sheet was mocked on.
  static const sandRow = 52;

  static final Map<String, ui.Image> _images = {};
  static Future<void>? _loading;

  /// Rises once the four images are in; the scene repaints on it.
  static final ValueNotifier<bool> ready = ValueNotifier(false);

  static bool get loaded => _images.length == 4;

  static ui.Image? imageOf(DesertPicture p) => _images[p.name];

  /// Starts loading (once).
  static Future<void> preload([AssetBundle? bundle]) => _loading ??= () async {
        final b = bundle ?? rootBundle;
        try {
          for (final p in [sky, far, mid, near]) {
            final data =
                await b.load('assets/visuals/crossing/desert/${p.name}.png');
            final codec =
                await ui.instantiateImageCodec(data.buffer.asUint8List());
            _images[p.name] = (await codec.getNextFrame()).image;
          }
          ready.value = true;
        } catch (_) {
          // No pictures: the code kit stays.
          _images.clear();
          _loading = null;
        }
      }();

  /// For tests: forget the loaded images.
  @visibleForTesting
  static void reset() {
    _images.clear();
    _loading = null;
    ready.value = false;
  }
}

final ui.Paint _pixelPaint = ui.Paint()
  ..filterQuality = ui.FilterQuality.none
  ..isAntiAlias = false;

/// The sky, static from row 0: past its 160 columns the last column repeats.
void paintDesertSky(ui.Canvas canvas, ui.Size size, double u) {
  final image = DesertPictures.imageOf(DesertPictures.sky)!;
  final w = image.width.toDouble(), h = image.height.toDouble();
  canvas.drawImageRect(image, ui.Rect.fromLTWH(0, 0, w, h),
      ui.Rect.fromLTWH(0, 0, w * u, h * u), _pixelPaint);
  final cols = size.width / u;
  if (cols > w) {
    canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(w - 1, 0, 1, h),
        ui.Rect.fromLTWH((w - 1) * u, 0, (cols - w + 1) * u + 1, h * u),
        _pixelPaint);
  }
}

/// A tiling layer from its [DesertPicture.top] row, [scroll] logical pixels
/// along: whole scene pixels, wrapped round the image's own width.
void paintDesertTile(
    ui.Canvas canvas, ui.Size size, DesertPicture p, double scroll, double u) {
  final image = DesertPictures.imageOf(p)!;
  final w = image.width.toDouble(), h = image.height.toDouble();
  final offset = (scroll / u).floorToDouble() % w;
  final cols = size.width / u;
  for (var x = -offset; x < cols; x += w) {
    canvas.drawImageRect(image, ui.Rect.fromLTWH(0, 0, w, h),
        ui.Rect.fromLTWH(x * u, p.top * u, w * u, h * u), _pixelPaint);
  }
}
