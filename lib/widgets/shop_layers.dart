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

import '../theme/palette.dart';

/// The plate (assets/visuals/scenes/) behind each shop: its place.
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

/// The NPC's 64 px frame for each shop: its own keeper where Art drew one
/// (assets/visuals/keepers/), else a stand-in from the Tower's chibis
/// (assets/visuals/tower/npc/).
const Map<String, String> shopKeeperFrames = {
  'weaponsmith_forge': 'assets/visuals/keepers/weaponsmith_forge.png',
  'arcane_bazaar': 'assets/visuals/keepers/arcane_bazaar.png',
  'apothecary_row': 'assets/visuals/keepers/apothecary_row.png',
  'arcane_academy': 'assets/visuals/keepers/arcane_academy.png',
  'ossuary_relics': 'assets/visuals/keepers/ossuary_relics.png',
  'last_lantern': 'assets/visuals/keepers/last_lantern.png',
  'anchorage_chandlery': 'assets/visuals/keepers/anchorage_chandlery.png',
  'black_market_docks': 'assets/visuals/keepers/black_market_docks.png',
  // Stand-ins until Art draws these six keepers.
  'blind_beggar_stall': 'assets/visuals/tower/npc/chandler.png',
  'shieldwrights_hall': 'assets/visuals/tower/npc/guardian.png',
  'hammersmith_forge': 'assets/visuals/tower/npc/guardian.png',
  'smugglers_vault': 'assets/visuals/tower/npc/clerk.png',
  'sharpweave_den': 'assets/visuals/tower/npc/clerk.png',
  'wayfarer_caravan': 'assets/visuals/tower/npc/chandler.png',
};

/// Whether [shopId] has a stall to build the layers with.
bool shopHasLayers(String shopId) =>
    shopScenes.containsKey(shopId) && shopKeeperFrames.containsKey(shopId);

/// The shop's stall picture (96 x 64, transparent opening).
String shopStallAsset(String shopId) => 'assets/visuals/shops/$shopId.png';

class ShopLayers extends StatelessWidget {
  const ShopLayers(this.shopId, {super.key});

  final String shopId;

  @override
  Widget build(BuildContext context) {
    if (!shopHasLayers(shopId)) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, box) {
      final width = box.maxWidth;
      final height = width * 0.52;
      // The stall is 96 px of the strip's 150: about two thirds of its width.
      final k = width / 150;
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          key: Key('shop_layers_$shopId'),
          width: width,
          height: height,
          child: Stack(children: [
            Positioned.fill(
              child: Image.asset(
                'assets/visuals/scenes/${shopScenes[shopId]}.png',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            // Until the darker shop plates: a wash so the dark stall reads.
            Positioned.fill(
                child: ColoredBox(
                    color: Palette.apolloOutline.withValues(alpha: 0.28))),
            Positioned(
              left: (width - 96 * k) / 2,
              bottom: height * 0.06,
              width: 96 * k,
              height: 64 * k,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned(
                  left: (48 - 32) * k,
                  top: (52 - 56) * k,
                  width: 64 * k,
                  height: 64 * k,
                  child: Image.asset(shopKeeperFrames[shopId]!,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
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
