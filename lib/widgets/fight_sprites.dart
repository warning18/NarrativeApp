// The sprites that stand in a fight (the hero today, the enemies that have
// art after it): which art a character gets, and how it is loaded. Adding
// one is a data change here, never a change to the fight's layout: a
// FightSpriteSet says where its images are and how big a frame is, and the
// fight sizes and places the figure from that.
//
// The hero's resolver returns the ronin (assets/visuals/walker) for every
// hero today; the user's later art plugs in to [heroFightSprite], by
// profession, race or both. A set whose image is missing falls back to the
// ronin rather than failing.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One figure's art: a standing frame, an optional walk strip, the size of a
/// frame in image pixels, and which way it faces.
@immutable
class FightSpriteSet {
  const FightSpriteSet({
    required this.id,
    required this.idleAsset,
    required this.frameWidth,
    required this.frameHeight,
    this.walkAsset,
    this.frames = 1,
    this.facesEast = true,
    this.footInset = 0,
  });

  /// A name for the set (a cache key, and what tests say).
  final String id;

  /// The standing frame: an image of [frameWidth] x [frameHeight] pixels, or
  /// a strip of them (the first frame is the standing one).
  final String idleAsset;

  /// The walk strip, [frames] frames wide; null for a figure with none.
  final String? walkAsset;
  final int frameWidth;
  final int frameHeight;
  final int frames;

  /// How the art is drawn: true for the hero (east, toward the enemies on
  /// the right); false for an enemy drawn facing west, toward the hero. It
  /// says which way the figure lunges.
  final bool facesEast;

  /// The empty rows under the feet in the image, in image pixels.
  final int footInset;

  @override
  bool operator ==(Object other) => other is FightSpriteSet && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// The ronin of the side view (assets/visuals/walker): the placeholder hero,
/// and what every missing set falls back to.
const FightSpriteSet roninSprite = FightSpriteSet(
  id: 'ronin',
  idleAsset: 'assets/visuals/walker/ronin_idle_east.png',
  walkAsset: 'assets/visuals/walker/ronin_walk_east.png',
  frameWidth: 42,
  frameHeight: 47,
  frames: 8,
);

/// The art of the hero in a fight, from the hero's choices. The ronin for
/// every hero today; later sprites (by [professionId], [raceId], or both) are
/// added here, east-facing, and nothing else changes.
FightSpriteSet heroFightSprite({String raceId = '', String professionId = ''}) {
  return roninSprite;
}

const String _fighters = 'assets/visuals/fighters';

FightSpriteSet _enemySet(String name) => FightSpriteSet(
      id: name,
      idleAsset: '$_fighters/${name}_idle_west.png',
      frameWidth: 48,
      frameHeight: 48,
      facesEast: false,
      footInset: 2,
    );

/// Which sprite an enemy wears: enemy id to sprite name (the files of
/// assets/visuals/fighters). Adding an enemy's art is a line here and a file
/// there; an enemy with no line keeps its portrait card alone.
const Map<String, String> _enemySprites = {
  'aurel_vane': 'aurel_vane',
  'inquisition_warden': 'inquisition_warden',
  'white_soldier': 'white_soldier',
  'inquisition_soldier': 'inquisition_soldier_02',
  'inquisition_auxiliary': 'inquisition_soldier_03',
};

/// The art an enemy stands in the fight with (facing west, toward the
/// hero), or null: it has none yet, and the fight shows only its card.
FightSpriteSet? enemyFightSprite(String enemyId) {
  final name = _enemySprites[enemyId];
  return name == null ? null : _enemySet(name);
}

/// The images of the sets, loaded once on first use.
abstract final class FightSpriteImages {
  static final Map<String, ui.Image> _idle = {};
  static final Map<String, Future<void>> _loading = {};
  static final Set<String> _missing = {};

  /// Counts the images in, for a widget to rebuild on.
  static final ValueNotifier<int> loaded = ValueNotifier(0);

  /// The set that will actually be drawn: [set], or the ronin once [set]'s
  /// image proved missing.
  static FightSpriteSet effective(FightSpriteSet set) =>
      _missing.contains(set.id) ? roninSprite : set;

  /// Whether [set]'s image proved missing: an enemy that is so shows no
  /// figure (only the hero falls back to the ronin).
  static bool failed(FightSpriteSet set) => _missing.contains(set.id);

  /// [set]'s standing image, or null while it loads (a missing image loads
  /// the ronin's instead, see [effective]).
  static ui.Image? idleOf(FightSpriteSet set) {
    final use = effective(set);
    final got = _idle[use.id];
    if (got == null) load(use);
    return got;
  }

  /// Starts loading [set] (once); on a failure, the ronin's.
  static Future<void> load(FightSpriteSet set, {AssetBundle? bundle}) =>
      _loading[set.id] ??= () async {
        try {
          final data = await (bundle ?? rootBundle).load(set.idleAsset);
          final codec =
              await ui.instantiateImageCodec(data.buffer.asUint8List());
          _idle[set.id] = (await codec.getNextFrame()).image;
          loaded.value++;
        } catch (_) {
          if (set.id == roninSprite.id) {
            // Not even the ronin: nothing is drawn.
            return;
          }
          _missing.add(set.id);
          await load(roninSprite, bundle: bundle);
          loaded.value++;
        }
      }();

  /// For tests: forget what was loaded.
  @visibleForTesting
  static void reset() {
    _idle.clear();
    _loading.clear();
    _missing.clear();
    loaded.value = 0;
  }
}
