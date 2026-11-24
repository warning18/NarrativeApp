// Pixel banners (v1.229): the Shroud's six pieces, the title's standard and
// the twelve clans' main banners, drawn by tool/gen_banners.py as 64x128
// sprites in assets/visuals/banners/, after bold poster lettering: a black
// woven cloth, cream strokes of one weight, two signs stacked like vertical
// writing and one round disc of colour, a header band and tassels in the
// banner's own colour. Shown at a whole-number scale with hard edges.
import 'package:flutter/material.dart';

/// The pieces of the Shroud, in the order the character screen lays them.
const List<String> shroudPieceIds = [
  'heirloom_shroud',
  'moon_shard_shroud',
  'warden_standard',
  'reliquary_thread',
  'white_fleet_sail',
  'sovereign_mantle',
];

/// The title's own standard.
const String titleBannerId = 'void_standard';

/// The clans' main banners, by faction id (assets/visuals/banners/clan_ID).
const List<String> clanBannerFactionIds = [
  'dominion',
  'vigil',
  'compact',
  'mire',
  'crows',
  'penitents',
  'choir',
  'pit',
  'giants',
  'oni',
  'tidekin',
  'kindly',
  'open_hand',
];

/// The banner id of faction [factionId], or null when it has none.
String? clanBannerId(String factionId) =>
    clanBannerFactionIds.contains(factionId) ? 'clan_$factionId' : null;

/// A banner's sprite size.
const Size pixelBannerSize = Size(64, 128);

/// Dims a banner to a silhouette: the piece not yet recovered.
const ColorFilter _unfound = ColorFilter.matrix(<double>[
  0.12, 0.12, 0.12, 0, 6, //
  0.12, 0.12, 0.12, 0, 6,
  0.12, 0.12, 0.12, 0, 6,
  0, 0, 0, 0.55, 0,
]);

/// The banner [id], [scale] times bigger (a whole number keeps its pixels
/// square); [found] false shows it as a dark silhouette.
class PixelBanner extends StatelessWidget {
  const PixelBanner({
    super.key,
    required this.id,
    this.scale = 2,
    this.found = true,
  });

  final String id;
  final int scale;
  final bool found;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/visuals/banners/$id.png',
      width: pixelBannerSize.width * scale,
      height: pixelBannerSize.height * scale,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => SizedBox(
        width: pixelBannerSize.width * scale,
        height: pixelBannerSize.height * scale,
      ),
    );
    return found ? image : ColorFiltered(colorFilter: _unfound, child: image);
  }
}

/// A clan's main banner as a small flag [height] logical pixels tall (the
/// sprite is 1:2, so half as wide), or nothing when the clan has none. The
/// edges stay hard, so it reads as the same cloth as the full banner.
class ClanFlag extends StatelessWidget {
  const ClanFlag({
    super.key,
    required this.factionId,
    this.height = 28,
    this.found = true,
  });

  final String factionId;
  final double height;
  final bool found;

  @override
  Widget build(BuildContext context) {
    final id = clanBannerId(factionId);
    if (id == null) return const SizedBox.shrink();
    return SizedBox(
      width: height * pixelBannerSize.width / pixelBannerSize.height,
      height: height,
      child: FittedBox(child: PixelBanner(id: id, scale: 1, found: found)),
    );
  }
}
