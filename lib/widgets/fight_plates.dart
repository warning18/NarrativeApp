// The fight's background pictures (Art's PixelLab plates, 180 x 320, palette
// PNG8, no figures): a stage that has a picture wears it, and a place's
// region can have a picture of its own (the city road of Saltmouth is not the
// city road of Alster), so a place looks the same in its fight and in its
// story scenes. A stage with no picture here keeps its code painter
// (fight_pixel_stage.dart); the day's weather, the anomalies and the hour's
// veil stay code over the picture.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../combat/field_anomaly.dart' show FightStage;

const String _dir = 'assets/visuals/fight_plates';

/// The picture of [stage] at the settlement [settlementId] (the `location`
/// level of the geography: 'saltmouth', 'candlehold'...), or null when the
/// stage has none. A settlement with no picture of its own takes the stage's
/// default.
String? fightPlateAsset(FightStage stage, String? settlementId) {
  switch (stage) {
    case FightStage.cityRoad:
      final region = switch (settlementId) {
        'saltmouth' => 'saltmouth',
        // The Reliquary and the Ashen Quarter: the grey frost towns.
        'black_reliquary' || 'ashen_quarter' => 'frost',
        'candlehold' => 'candlehold',
        _ => null,
      };
      return '$_dir/cityroad${region == null ? '' : '_$region'}.png';
    default:
      return null;
  }
}

/// The pictures, decoded once. [loaded] changes when one arrives.
abstract final class FightPlateImages {
  static final Map<String, ui.Image> _images = {};
  static final Set<String> _loading = {};
  static final ValueNotifier<int> loaded = ValueNotifier(0);

  /// [asset]'s image, or null while it loads (a call starts the load).
  static ui.Image? of(String asset) {
    final got = _images[asset];
    if (got == null && _loading.add(asset)) unawaited(_load(asset));
    return got;
  }

  static Future<void> _load(String asset) async {
    try {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      _images[asset] = (await codec.getNextFrame()).image;
      loaded.value++;
    } catch (_) {
      // A missing file leaves the stage to its code painter.
    }
  }

  static void reset() {
    _images.clear();
    _loading.clear();
  }
}
