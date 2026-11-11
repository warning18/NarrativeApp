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
import 'package:flutter/widgets.dart' show BuildContext, Color, InheritedWidget;
import 'package:flutter/services.dart';

import '../combat/field_anomaly.dart' show FightStage;

const String _dir = 'assets/visuals/fight_plates';

/// The picture of [stage] at the settlement [settlementId] (the `location`
/// level of the geography: 'saltmouth', 'candlehold'...) or the place
/// [placeId] itself. Every stage has one; a place whose region has a picture
/// of its own (a stage's version) wears that, every other place the stage's
/// shared picture.
String fightPlateAsset(
  FightStage stage,
  String? settlementId, {
  String? placeId,
}) {
  bool at(Set<String> ids) =>
      ids.contains(settlementId) || ids.contains(placeId);
  final version = switch (stage) {
    FightStage.cityRoad when settlementId == 'saltmouth' =>
      'cityroad_saltmouth',
    // The Reliquary and the Ashen Quarter: the grey frost towns.
    FightStage.cityRoad when at(const {'black_reliquary', 'ashen_quarter'}) =>
      'cityroad_frost',
    FightStage.cityRoad when settlementId == 'candlehold' =>
      'cityroad_candlehold',
    FightStage.cityRoad when settlementId == 'white_anchorage' =>
      'cityroad_whiteanchorage',
    FightStage.glass
        when at(const {
          'greyhithe',
          'hollow_shore',
          'beyond_the_tear',
          'white_fleet_grave',
        }) =>
      'glass_greyhithe',
    FightStage.ash when settlementId == 'emberwick' => 'ash_emberwick',
    FightStage.terraces when settlementId == 'akagiri' => 'terraces_akagiri',
    FightStage.waves when settlementId == 'the_crossing' => 'waves_crossing',
    FightStage.hall when at(const {'drowned_cloister', 'alster_undercroft'}) =>
      'hall_wet',
    _ => null,
  };
  if (version != null) return '$_dir/$version.png';
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

/// How a fight is dressed whatever its stage (the Tower's): the picture it
/// wears ([asset]), the stage whose ground skin the dice board takes
/// ([boardStage]) and the floor named in the ground line. Put above the
/// FightScreen. A look only: the stage the rules read is not changed.
class FightPlateOverride extends InheritedWidget {
  const FightPlateOverride({
    super.key,
    required this.asset,
    required this.boardStage,
    required this.floor,
    required super.child,
  });

  final String asset;
  final FightStage boardStage;
  final int floor;

  static FightPlateOverride? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FightPlateOverride>();

  @override
  bool updateShouldNotify(FightPlateOverride old) =>
      old.asset != asset || old.boardStage != boardStage || old.floor != floor;
}

/// The pictures, decoded once. [loaded] changes when one arrives.
abstract final class FightPlateImages {
  static final Map<String, ui.Image> _images = {};
  static final Map<String, Color> _tints = {};
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
      final image = (await codec.getNextFrame()).image;
      final tint = await _groundTintOf(image);
      if (tint != null) _tints[asset] = tint;
      _images[asset] = image;
      loaded.value++;
    } catch (_) {
      // A missing file leaves the stage to its code painter.
    }
  }

  /// The colour of [asset]'s ground (the mean of its lowest third), for the
  /// dice board to lean towards; null until it is loaded.
  static Color? tintOf(String asset) => _tints[asset];

  static Future<Color?> _groundTintOf(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    final from = image.height * 2 ~/ 3;
    var r = 0, g = 0, b = 0, n = 0;
    for (var y = from; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final i = (y * image.width + x) * 4;
        r += data.getUint8(i);
        g += data.getUint8(i + 1);
        b += data.getUint8(i + 2);
        n++;
      }
    }
    if (n == 0) return null;
    return Color.fromARGB(255, r ~/ n, g ~/ n, b ~/ n);
  }

  static void reset() {
    _images.clear();
    _tints.clear();
    _loading.clear();
  }
}
