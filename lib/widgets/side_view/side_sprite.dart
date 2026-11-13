// The hero in side view: a walk cycle facing east or west and a standing
// frame, painted on the scene's grid in place of the placeholder walker. The
// walker is the user's ronin (assets/visuals/walker, eight frames) or, for a
// hero whose people or calling has one, that figure's own walk
// (assets/visuals/heroes, tool/gen_hero_walks.py). The images load on first
// use, and again when the hero changes; until they are in, the placeholder
// stands in.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One facing of the hero: the walk strip and the standing frame.
class _Facing {
  _Facing(this.walk, this.idle, this.frameWidth, this.frameHeight)
      : frames = walk.width ~/ frameWidth;
  final ui.Image walk;
  final ui.Image idle;
  final int frameWidth;
  final int frameHeight;
  final int frames;
}

abstract final class SideSprites {
  /// One frame of the ronin's strips, in sprite pixels (a hero figure's are
  /// 48 x 48, its strip as many frames as Art drew).
  static const int frameWidth = 42;
  static const int frameHeight = 47;
  static const int frames = 8;

  /// How many scene pixels one sprite pixel covers: the figure stands about
  /// a third of the scene high.
  static const double scale = 0.5;

  static _Facing? _east;
  static _Facing? _west;
  static Future<void>? _loading;

  /// Whose walk is painted: 'ronin', or a hero figure's name
  /// (heroWalkName in fight_sprites.dart).
  static String _wanted = 'ronin';

  /// Asks for [name]'s walk. A different one drops the images, loads the new
  /// ones, and the placeholder stands in until they are in.
  static void setHero(String name) {
    if (name == _wanted) return;
    _wanted = name;
    _east = null;
    _west = null;
    _loading = null;
    preload();
  }

  /// Notifies when the images come in, so a still scene paints them.
  static final ValueNotifier<bool> ready = ValueNotifier(false);

  static bool get loaded => _east != null && _west != null;

  static Future<ui.Image> _decode(AssetBundle bundle, String path) async {
    final data = await bundle.load('assets/visuals/$path.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  /// Starts loading (once); the scene paints the placeholder until it is
  /// done.
  static Future<void> preload([AssetBundle? bundle]) => _loading ??= () async {
        final b = bundle ?? rootBundle;
        final name = _wanted;
        try {
          Future<_Facing> facing(String side) async {
            final ronin = name == 'ronin';
            return _Facing(
                await _decode(
                    b,
                    ronin
                        ? 'walker/ronin_walk_$side'
                        : 'heroes/${name}_walk_$side'),
                await _decode(
                    b,
                    ronin
                        ? 'walker/ronin_idle_$side'
                        : 'heroes/${name}_stand_$side'),
                ronin ? frameWidth : 48,
                ronin ? frameHeight : 48);
          }

          final east = await facing('east');
          final west = await facing('west');
          if (name != _wanted) return; // the hero changed while loading
          _east = east;
          _west = west;
          // Twice, so a listener hears it even when it was already true.
          ready.value = false;
          ready.value = true;
        } catch (_) {
          _loading = null;
          if (name != 'ronin') {
            // No walk for this hero: the ronin walks.
            _wanted = 'ronin';
            return preload(bundle);
          }
          // No sprite: the placeholder stays.
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
    final fw = facing.frameWidth, fh = facing.frameHeight;
    final w = fw * scale;
    final h = fh * scale;
    // Standing, she breathes: one sprite pixel up and down, slowly.
    final bob = moving ? 0.0 : (((t * 1.2) % 1.0) < 0.5 ? 0.0 : -scale);
    final dst =
        ui.Rect.fromLTWH((x - w / 2) * u, (baseY - h + bob) * u, w * u, h * u);
    final paint = ui.Paint()
      ..filterQuality = ui.FilterQuality.none
      ..isAntiAlias = false;
    if (moving) {
      // Ten steps a second for the ronin's eight frames; the same stride
      // for a hero with another count.
      final i = (t * facing.frames * 1.25).floor() % facing.frames;
      canvas.drawImageRect(
          facing.walk,
          ui.Rect.fromLTWH(
              (i * fw).toDouble(), 0, fw.toDouble(), fh.toDouble()),
          dst,
          paint);
    } else {
      canvas.drawImageRect(facing.idle,
          ui.Rect.fromLTWH(0, 0, fw.toDouble(), fh.toDouble()), dst, paint);
    }
    return true;
  }

  /// For tests: forget the loaded images.
  @visibleForTesting
  static void reset() {
    _east = null;
    _west = null;
    _loading = null;
    _wanted = 'ronin';
    ready.value = false;
  }
}
