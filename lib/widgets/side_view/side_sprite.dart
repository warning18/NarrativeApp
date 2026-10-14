// The hero in side view (assets/visuals/walker): the user's ronin, a walk
// cycle of eight frames facing east or west and a standing frame, painted
// on the scene's grid in place of the placeholder walker. The images load
// once, on first use; until they are in, the placeholder stands in.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One facing of the hero: the walk strip and the standing frame.
class _Facing {
  _Facing(this.walk, this.idle);
  final ui.Image walk;
  final ui.Image idle;
}

abstract final class SideSprites {
  /// One frame of the strips, in sprite pixels.
  static const int frameWidth = 42;
  static const int frameHeight = 47;
  static const int frames = 8;

  /// How many scene pixels one sprite pixel covers: the figure stands about
  /// a third of the scene high.
  static const double scale = 0.5;

  static _Facing? _east;
  static _Facing? _west;
  static Future<void>? _loading;

  /// Notifies when the images come in, so a still scene paints them.
  static final ValueNotifier<bool> ready = ValueNotifier(false);

  static bool get loaded => _east != null && _west != null;

  static Future<ui.Image> _decode(AssetBundle bundle, String name) async {
    final data = await bundle.load('assets/visuals/walker/$name.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  /// Starts loading (once); the scene paints the placeholder until it is
  /// done.
  static Future<void> preload([AssetBundle? bundle]) => _loading ??= () async {
        final b = bundle ?? rootBundle;
        try {
          _east = _Facing(await _decode(b, 'ronin_walk_east'),
              await _decode(b, 'ronin_idle_east'));
          _west = _Facing(await _decode(b, 'ronin_walk_west'),
              await _decode(b, 'ronin_idle_west'));
          ready.value = true;
        } catch (_) {
          // No sprite: the placeholder stays.
          _loading = null;
        }
      }();

  /// Paints the hero with her feet at scene pixel ([x], [baseY]); false when
  /// the images are not in yet (the caller paints the placeholder).
  static bool paint(
    ui.Canvas canvas,
    double u,
    double x,
    double baseY,
    double t, {
    bool moving = true,
    bool east = true,
  }) {
    final facing = east ? _east : _west;
    if (facing == null) return false;
    const w = frameWidth * scale;
    const h = frameHeight * scale;
    // Standing, she breathes: one sprite pixel up and down, slowly.
    final bob = moving ? 0.0 : (((t * 1.2) % 1.0) < 0.5 ? 0.0 : -scale);
    final dst =
        ui.Rect.fromLTWH((x - w / 2) * u, (baseY - h + bob) * u, w * u, h * u);
    final paint = ui.Paint()
      ..filterQuality = ui.FilterQuality.none
      ..isAntiAlias = false;
    if (moving) {
      final i = (t * 10).floor() % frames;
      canvas.drawImageRect(
          facing.walk,
          ui.Rect.fromLTWH((i * frameWidth).toDouble(), 0,
              frameWidth.toDouble(), frameHeight.toDouble()),
          dst,
          paint);
    } else {
      canvas.drawImageRect(
          facing.idle,
          ui.Rect.fromLTWH(0, 0, frameWidth.toDouble(), frameHeight.toDouble()),
          dst,
          paint);
    }
    return true;
  }

  /// For tests: forget the loaded images.
  @visibleForTesting
  static void reset() {
    _east = null;
    _west = null;
    _loading = null;
    ready.value = false;
  }
}
