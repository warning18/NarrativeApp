// A shop as layers (v2.10.6, the user's call): the place's plate behind, the
// shopkeeper standing in the middle, Art's stall in front. The stall is a
// 96 x 64 picture with a transparent opening above its counter; the NPC's 64 px
// frame is placed so its feet (frame y 56) stand at stall y 52, under the
// counter top (y 40), centred at stall x 48; the stall's bottom edge sits just
// above the strip's bottom. Anchors are Art's (docs/art/handoff-ux-dark-foes-
// chests-stalls.md). The plate gets a dark wash until Art's darker shop-only
// plates (*_shop_dark) arrive; the six shops without a keeper figure use a
// Tower chibi until Art draws theirs: one lookup each, so a swap is one line.
import 'package:flutter/material.dart';

/// The plate behind each shop: its place, in Art's darker shop-only version
/// of the scene (assets/visuals/shop_scenes/ID.png; the story's own bands
/// stay in assets/visuals/scenes/).
const Map<String, String> shopScenes = {
  'blind_beggar_stall': 'blind_beggar',
  'weaponsmith_forge': 'saltmouth_yard',
  'shieldwrights_hall': 'saltmouth_landward_warehouse',
  'apothecary_row': 'saltmouth_tern_row',
  'black_market_docks': 'saltmouth_tide_cellar',
  'smugglers_vault': 'white_anchorage_vault',
  'sharpweave_den': 'saltmouth_green_door',
  'arcane_bazaar': 'ashen_quarter_ash_market',
  'arcane_academy': 'spire_hall_of_records',
  'hammersmith_forge': 'emberwick_cold_forge',
  'ossuary_relics': 'drowned_cloister_ossuary',
  'last_lantern': 'reliquary_quarter',
  'anchorage_chandlery': 'white_anchorage_chandlery',
  'wayfarer_caravan': 'the_crossing',
};

/// The NPC's 64 px frame for each shop: Art's keeper where one was drawn
/// (assets/visuals/keepers/).
const Map<String, String> shopKeeperFrames = {
  'weaponsmith_forge': 'assets/visuals/keepers/weaponsmith_forge.png',
  'arcane_bazaar': 'assets/visuals/keepers/arcane_bazaar.png',
  'apothecary_row': 'assets/visuals/keepers/apothecary_row.png',
  'arcane_academy': 'assets/visuals/keepers/arcane_academy.png',
  'ossuary_relics': 'assets/visuals/keepers/ossuary_relics.png',
  'last_lantern': 'assets/visuals/keepers/last_lantern.png',
  'anchorage_chandlery': 'assets/visuals/keepers/anchorage_chandlery.png',
  'black_market_docks': 'assets/visuals/keepers/black_market_docks.png',
  // The six keepers drawn for the stalls (a 64 px figure, see below).
  'blind_beggar_stall': 'assets/visuals/keepers/beggars_cellar_boy.png',
  'shieldwrights_hall': 'assets/visuals/keepers/shieldwright.png',
  'hammersmith_forge': 'assets/visuals/keepers/hammersmith.png',
  'smugglers_vault': 'assets/visuals/keepers/vault_keeper.png',
  'sharpweave_den': 'assets/visuals/keepers/needle_house_keeper.png',
  'wayfarer_caravan': 'assets/visuals/keepers/caravan_master.png',
};

/// The keepers drawn big (64 px, bottom-aligned): centred at stall x 48, their
/// top at stall y 2, clipped to the stall's box at y 60. The others are the
/// smaller 48 px figures, feet at stall y 52.
const Set<String> _bigKeepers = {
  'blind_beggar_stall',
  'shieldwrights_hall',
  'hammersmith_forge',
  'smugglers_vault',
  'sharpweave_den',
  'wayfarer_caravan',
};

/// Whether [shopId] has a stall to build the layers with.
bool shopHasLayers(String shopId) =>
    shopScenes.containsKey(shopId) && shopKeeperFrames.containsKey(shopId);

/// The shop's stall picture (96 x 64, transparent opening).
String shopStallAsset(String shopId) => 'assets/visuals/shops/$shopId.png';

class ShopLayers extends StatelessWidget {
  const ShopLayers(this.shopId,
      {super.key, this.stallScale = 1.25, this.keeperScale = 0.85});

  final String shopId;

  /// The stall's size against the strip's base scale (the user chose 1.25).
  final double stallScale;

  /// The keeper's size against the strip's base scale (the user asked for a bit smaller).
  final double keeperScale;

  @override
  Widget build(BuildContext context) {
    if (!shopHasLayers(shopId)) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, box) {
      final width = box.maxWidth;
      final height = width * 0.55;
      final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
      // Snap to whole device pixels so the pixel art scales evenly.
      double snap(double v) => (v * dpr).round() / dpr;
      // The strip is 150 px wide at k = 1; the stall is 96 px of it.
      final k = width / 150;
      final sk = snap(k * stallScale);
      final kk = snap(k * keeperScale);
      final big = _bigKeepers.contains(shopId);
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          key: Key('shop_layers_$shopId'),
          width: width,
          height: height,
          child: Stack(children: [
            Positioned.fill(
              child: Image.asset(
                'assets/visuals/shop_scenes/${shopScenes[shopId]}.png',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            Positioned(
              left: snap((width - 96 * sk) / 2),
              bottom: snap(height * 0.03),
              width: 96 * sk,
              height: 64 * sk,
              child: Stack(clipBehavior: Clip.none, children: [
                // The keeper: a 64 px figure (top at stall y 2, clipped to the
                // stall's box at y 60) or a 48 px NPC (feet at stall y 52).
                Positioned.fill(
                  child: ClipRect(
                    clipper: _KeeperClip(
                        big ? Rect.fromLTWH(0, 0, 96 * sk, 60 * sk) : null),
                    child: Stack(clipBehavior: Clip.none, children: [
                      Positioned(
                        // Feet stay at the same spot of the stall (y 66
                        // for the big keepers, 52 for the NPCs).
                        left: 48 * sk - 32 * kk,
                        top: (big ? 66 : 52) * sk - (big ? 64 : 56) * kk,
                        width: 64 * kk,
                        height: 64 * kk,
                        child: Image.asset(shopKeeperFrames[shopId]!,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.none,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink()),
                      ),
                    ]),
                  ),
                ),
                Positioned.fill(
                  child: Image.asset(shopStallAsset(shopId),
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                ),
              ]),
            ),
          ]),
        ),
      );
    });
  }
}

/// Clips the keeper layer to [box] (null: no clip, a very large box).
class _KeeperClip extends CustomClipper<Rect> {
  _KeeperClip(this.box);

  final Rect? box;

  @override
  Rect getClip(Size size) =>
      box ?? const Rect.fromLTWH(-1000, -1000, 3000, 3000);

  @override
  bool shouldReclip(_KeeperClip old) => old.box != box;
}
