// The fight's background pictures (Art's PixelLab plates, 180 x 320, palette
// PNG8, no figures): a stage that has a picture wears it, and a place's
// region can have a picture of its own (the city road of Saltmouth is not the
// city road of Alster), so a place looks the same in its fight and in its
// story scenes. The day's weather, the anomalies and the hour's veil stay
// code over the picture; fight_pixel_stage.dart's painter stays for a picture
// that is not loaded yet.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext, InheritedWidget;
import 'package:flutter/services.dart';

import '../combat/field_anomaly.dart' show FightStage;

const String _dir = 'assets/visuals/fight_plates';

/// The picture of [stage] at the settlement [settlementId] (the `location`
/// level of the geography: 'saltmouth', 'candlehold'...). Every stage has
/// one; a settlement with no picture of its own takes the stage's default.
String fightPlateAsset(FightStage stage, String? settlementId) {
  if (stage == FightStage.cityRoad) {
    final region = switch (settlementId) {
      'saltmouth' => 'saltmouth',
      // The Reliquary and the Ashen Quarter: the grey frost towns.
      'black_reliquary' || 'ashen_quarter' => 'frost',
      'candlehold' => 'candlehold',
      _ => null,
    };
    return '$_dir/cityroad${region == null ? '' : '_$region'}.png';
  }
  final stem = switch (stage) {
    FightStage.fields => 'fields',
    FightStage.dunes => 'dunes',
    FightStage.saltFlats => 'saltflats',
    FightStage.waves => 'waves',
    FightStage.ash => 'ash',
    FightStage.terraces => 'terraces',
    FightStage.cliffs => 'cliffs',
    FightStage.reeds => 'reeds',
    FightStage.snow => 'snow',
    FightStage.glass => 'glass',
    FightStage.hall => 'hall',
    FightStage.cityRoad => 'cityroad',
    FightStage.shipDeck => 'shipdeck',
    FightStage.ruins => 'ruins',
    FightStage.woods => 'woods',
    FightStage.ford => 'ford',
    FightStage.burntFields => 'burnt',
    FightStage.oasis => 'oasis',
    FightStage.caravanRoad => 'caravanroad',
    FightStage.quay => 'quay',
    FightStage.pass => 'pass',
  };
  return '$_dir/$stem.png';
}

/// A picture the fight is told to wear whatever its stage (the Tower's boss
/// and warden floors): put above the FightScreen, it wins over the stage's.
class FightPlateOverride extends InheritedWidget {
  const FightPlateOverride(
      {super.key, required this.asset, required super.child});

  final String asset;

  static String? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FightPlateOverride>()?.asset;

  @override
  bool updateShouldNotify(FightPlateOverride old) => old.asset != asset;
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
