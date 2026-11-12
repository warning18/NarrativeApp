// The pictures behind three screens (Art's, painted in the story scenes'
// style, no figures): a band for each memory of "A Life Before This One"
// (assets/visuals/life/<memory id>.png, 240x100), a full-bleed plate for each
// step of the character choice (assets/visuals/character/<step>.png, 180x320)
// and a band for each expedition zone (assets/visuals/expeditions/<zone
// id>.png, 240x72). A screen whose picture is missing looks as it did before:
// each id set below is the folder's files (a test keeps them the same).
import 'package:flutter/material.dart';

/// The painted bands, by file stem (see [lifeBandStemOf]); a memory without
/// one keeps the code-drawn scene (origin_scene_backdrop.dart).
const Set<String> lifeBandIds = {
  'sparrow',
  'mark',
  'beggar',
  'calling',
  'lamp',
  'board',
};

/// The character choice's plates, by step: the people, then the calling.
const Set<String> characterPlateIds = {'race', 'calling'};

/// The zones that have a band (zones.json ids).
const Set<String> expeditionBandIds = {
  'z_bell_road',
  'z_beyond_the_tear',
  'z_changeling_fen',
  'z_cinder_row',
  'z_dead_heart_approach',
  'z_drowned_stair',
  'z_ember_run',
  'z_exorcists_road',
  'z_fever_bark',
  'z_fishermans_row',
  'z_frost_quarry',
  'z_glass_strand',
  'z_lantern_docks',
  'z_lantern_train',
  'z_ossuary_galleries',
  'z_salt_road',
  'z_scaffold_yards',
  'z_shroud_vigil',
  'z_tanners_court',
  'z_white_fleet_grave',
};

/// The band file a memory uses: the age's own (a race's mark at age 8 and a
/// calling's memory at age 12 share the age's band, 'mark' and 'calling'), or
/// the memory's id.
String lifeBandStemOf(String memoryId) => memoryId.startsWith('mark_')
    ? 'mark'
    : memoryId.startsWith('calling_')
        ? 'calling'
        : memoryId;

String? lifeBandAsset(String memoryId) {
  final stem = lifeBandStemOf(memoryId);
  return lifeBandIds.contains(stem) ? 'assets/visuals/life/$stem.png' : null;
}

/// The plate of the character choice's [step] (0 the people, 1 the calling).
String? characterPlateAsset(int step) {
  final id = step == 0 ? 'race' : 'calling';
  return characterPlateIds.contains(id)
      ? 'assets/visuals/character/$id.png'
      : null;
}

String? expeditionBandAsset(String zoneId) => expeditionBandIds.contains(zoneId)
    ? 'assets/visuals/expeditions/$zoneId.png'
    : null;

Image _pixels(String asset, {required BoxFit fit, Alignment? alignment}) =>
    Image.asset(
      asset,
      fit: fit,
      alignment: alignment ?? Alignment.center,
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
      gaplessPlayback: true,
    );

/// A memory's band, full width, top-aligned (nearest-neighbour pixels): the
/// screen's own fade into the page colour goes over it.
class LifeBand extends StatelessWidget {
  const LifeBand({super.key, required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
        child: _pixels(asset,
            fit: BoxFit.fitWidth, alignment: Alignment.topCenter),
      );
}

/// A plate laid under a screen: it covers the screen (cropped in the middle)
/// and the page colour is laid over it at [veil], so it shows as texture and
/// colour only and no layout changes.
class ScreenPlate extends StatelessWidget {
  const ScreenPlate({super.key, required this.asset, this.veil = 0.7});

  final String asset;
  final double veil;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          _pixels(asset, fit: BoxFit.cover),
          ColoredBox(
            color: Theme.of(context)
                .scaffoldBackgroundColor
                .withValues(alpha: veil),
          ),
        ],
      );
}

/// An expedition zone's band across the top of its screen, fading into the
/// page colour at its foot.
class ExpeditionBand extends StatelessWidget {
  const ExpeditionBand({super.key, required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    final page = Theme.of(context).scaffoldBackgroundColor;
    return AspectRatio(
      aspectRatio: 240 / 72,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _pixels(asset, fit: BoxFit.fitWidth, alignment: Alignment.topCenter),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.55, 1.0],
                colors: [Colors.transparent, page],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
