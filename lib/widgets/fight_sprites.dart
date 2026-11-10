// The sprites that stand in a fight (the hero today, the enemies that have
// art after it): which art a character gets, and how it is loaded. Adding
// one is a data change here, never a change to the fight's layout: a
// FightSpriteSet says where its images are and how big a frame is, and the
// fight sizes and places the figure from that.
//
// Every hero is the ronin (assets/visuals/walker) today; the user's later art
// plugs in here, by profession, race or both. A set whose image is missing
// falls back to the ronin rather than failing.
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
    this.drawScale = 1,
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

  /// How big the figure stands next to the others: 1 for the usual 48 pixel
  /// figure, less for a creature drawn on a bigger canvas than its size in the
  /// world (a rat is not taller than the ronin).
  final double drawScale;

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

const String _fighters = 'assets/visuals/fighters';

/// The frame size and the empty rows under the feet of the sprites that are
/// not the usual 48 x 48 low top-down figure: the sewer's vermin are 60 x 60
/// side views (art/pixellab/sewer).
const Map<String, ({int size, int foot, double scale})> _enemyFrames = {
  'rat': (size: 60, foot: 1, scale: 0.7),
  'rat_matriarch': (size: 60, foot: 4, scale: 0.85),
  'plague_hound': (size: 60, foot: 2, scale: 0.85),
};

FightSpriteSet _enemySet(String name) {
  final frame = _enemyFrames[name];
  return FightSpriteSet(
    id: name,
    idleAsset: '$_fighters/${name}_idle_west.png',
    frameWidth: frame?.size ?? 48,
    frameHeight: frame?.size ?? 48,
    facesEast: false,
    footInset: frame?.foot ?? 2,
    drawScale: frame?.scale ?? 1,
  );
}

/// Which sprite an enemy wears: enemy id to sprite name (the files of
/// assets/visuals/fighters). Adding an enemy's art is a line here and a file
/// there; an enemy with no line keeps its portrait card alone.
const Map<String, String> _enemySprites = {
  'aurel_vane': 'aurel_vane',
  'inquisition_warden': 'inquisition_warden',
  'white_soldier': 'white_soldier',
  'inquisition_soldier': 'inquisition_soldier_02',
  'inquisition_auxiliary': 'inquisition_soldier_03',
  'harbor_rat': 'rat',
  'rat_matriarch': 'rat_matriarch',
  'plague_hound': 'plague_hound',
  'wreck_scavenger': 'wreck_scavenger',
  'den_bouncer': 'den_bouncer',
  'den_looter': 'den_looter',
  'mire_returned_sedge': 'sedge_returned',
  'demon_imp': 'low_demon',
  'angel_sentinel': 'low_angel',
  'street_bandit': 'street_bandit',
};

/// The art an enemy stands in the fight with (facing west, toward the
/// hero), or null: it has none yet, and the fight shows only its card.
FightSpriteSet? enemyFightSprite(String enemyId) {
  final name = _enemySprites[enemyId];
  return name == null ? null : _enemySet(name);
}

/// Which enemy a road event puts on the road when the event's own data does
/// not say (land_events.json names an enemy only in a fight choice): event id
/// to enemy id. UX's table, so the event data stays Core's and Narrative's.
const Map<String, String> _roadEventEnemies = {
  'inquisition_patrol': 'inquisition_soldier',
};

/// What stands on the road in front of the party at a land-crossing event:
/// the art of the enemy it is (the fight choice's [fightEnemyId], else the
/// table above), with [sprite] null for a placeholder figure when that enemy
/// has no art yet. Null when the event has no figure at all (a storm, a dry
/// well, the water seller: nothing in the data says who they are).
({FightSpriteSet? sprite})? roadEncounterFigure(String eventId,
    {String? fightEnemyId}) {
  final enemy = fightEnemyId ?? _roadEventEnemies[eventId];
  if (enemy == null) return null;
  return (sprite: enemyFightSprite(enemy));
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
