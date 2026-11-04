// The world camera (docs/proposals/scene-transitions.md, 3c): one x on the
// land strip (RegionStrips, lib/data/region_strip.dart) says which land the
// side view shows. Inside a region it is that region's kit in the window of
// the x (scene_windows.dart); near the border of two regions with different
// kits it is the seam between them (kit_blend.dart), so a walk from one end
// of the strip to the other never cuts. Pure: the same x gives the same
// picture on every launch. A scene that stands still (a town, a crossing's
// day) is the camera parked at its x; a walk moves the x.
import '../../data/region_strip.dart';
import 'cliffs_kit.dart';
import 'desert_kit.dart';
import 'fen_kit.dart';
import 'frost_kit.dart';
import 'kit_blend.dart';
import 'ruins_kit.dart';
import 'scene_windows.dart';
import 'side_view.dart';

/// How far on each side of the border of two regions the seam runs (chart
/// units): a road of the story is about 40 long, a seam 12.
const double worldSeamHalf = 6;

/// The seam between two kits: [from] to [to] across [start] to [end] on the
/// strip.
class KitSeam {
  const KitSeam(this.from, this.to, this.start, this.end);

  final String from;
  final String to;
  final double start;
  final double end;

  /// 0 before the seam, 1 after it.
  double progressAt(double x) => ((x - start) / (end - start)).clamp(0.0, 1.0);
}

/// The layers of the land kit [kit] ('desert', 'ruins', 'fen', 'frost',
/// 'cliffs'); null for a kit the camera does not paint (the sea has its own
/// scene).
List<SideLayer>? kitLayersOf(String kit, {double progress = 0.5}) =>
    switch (kit) {
      'desert' => desertLayers(progress: progress),
      'ruins' => ruinsLayers(progress: progress),
      'fen' => fenLayers(progress: progress),
      'frost' => frostLayers(progress: progress),
      'cliffs' => cliffsLayers(progress: progress),
      _ => null,
    };

/// The camera on the land strip.
class WorldCamera {
  /// [zones] are the land stretches of the strip in order (the sea strip's
  /// are left out); a seam is put on the border of every two neighbours
  /// whose kits differ.
  WorldCamera(Iterable<RegionStrip> zones, {this.seamHalf = worldSeamHalf})
      : _zones = [
          for (final z in zones)
            if (z.strip == StripKind.land) z,
        ] {
    for (var i = 1; i < _zones.length; i++) {
      final a = _zones[i - 1], b = _zones[i];
      if (a.kit == b.kit) continue;
      final border = b.start;
      _seams.add(KitSeam(a.kit, b.kit, border - seamHalf, border + seamHalf));
    }
  }

  final double seamHalf;
  final List<RegionStrip> _zones;
  final List<KitSeam> _seams = [];

  List<KitSeam> get seams => List.unmodifiable(_seams);

  /// The kit of the region [x] is in (the first and last region hold for
  /// anything before or after the strip); null for no land at all.
  String? kitAt(double x) {
    if (_zones.isEmpty) return null;
    for (final z in _zones) {
      if (x < z.end) return z.kit;
    }
    return _zones.last.kit;
  }

  /// The seam [x] is inside of, or null.
  KitSeam? seamAt(double x) {
    for (final s in _seams) {
      if (x > s.start && x < s.end) return s;
    }
    return null;
  }

  /// The window of the kit's world at [x].
  int windowAt(double x) => sceneWindowAt(x);

  /// The scene's layers with the camera at [x]: the kit of the region in
  /// its window, or the seam between two kits. Null when the strip has no
  /// land there to paint.
  List<SideLayer>? layersAt(double x, {double progress = 0.5}) {
    final seam = seamAt(x);
    final window = windowAt(x);
    List<SideLayer>? windowed(String kit) {
      final layers = kitLayersOf(kit, progress: progress);
      return layers == null ? null : withSceneWindow(layers, kit, window);
    }

    if (seam != null) {
      final from = windowed(seam.from), to = windowed(seam.to);
      if (from != null && to != null) {
        final k = seam.progressAt(x);
        return [kitBlend(from, to, (_) => k)];
      }
    }
    final kit = kitAt(x);
    return kit == null ? null : windowed(kit);
  }
}
