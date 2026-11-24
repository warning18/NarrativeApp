// The ink kit's pictures: Art's brush frame and wide frame, decoded once and
// kept (v1.1004). Until they are there the panels draw a plain hairline, so
// nothing is bare.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The asset paths of the ink pieces.
const String inkFrameAsset = 'assets/visuals/ink/ink_frame.png';
const String inkWideFrameAsset = 'assets/visuals/ink/ink_wideframe.png';

class InkImages {
  InkImages._();

  static final Map<String, ui.Image> _images = {};
  static final Set<String> _loading = {};

  /// Bumps when a piece arrives, so painters can redraw.
  static final ValueNotifier<int> loaded = ValueNotifier(0);

  /// How many pieces were decoded (the cache's proof in tests).
  @visibleForTesting
  static int decodes = 0;

  static ui.Image? of(String asset) => _images[asset];

  static bool get ready =>
      _images.containsKey(inkFrameAsset) &&
      _images.containsKey(inkWideFrameAsset);

  /// Decodes the pieces that are not yet there; safe to call again.
  static Future<void> preload() async {
    await Future.wait([
      for (final asset in const [inkFrameAsset, inkWideFrameAsset])
        _load(asset),
    ]);
  }

  static Future<void> _load(String asset) async {
    if (_images.containsKey(asset) || !_loading.add(asset)) return;
    try {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      _images[asset] = (await codec.getNextFrame()).image;
      decodes++;
      loaded.value++;
    } finally {
      _loading.remove(asset);
    }
  }

  @visibleForTesting
  static void reset() {
    _images.clear();
    _loading.clear();
    decodes = 0;
  }
}
