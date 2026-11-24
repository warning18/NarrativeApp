// The story scene's picture (v1.953): a band of 240x100 pixels for each of
// the story's places (assets/visuals/scenes/<location>.png, Art's, one per
// DAG `location`), shown at the top of a story node over its words. A place
// with no band (hollow_shore, left without one by choice) shows nothing, as
// before. The place looks the same in its fight stage and in its scenes
// (docs/art/pairing-stage-scenes.md).
import 'package:flutter/material.dart';

import '../theme/palette.dart';

/// The places that have a band: the file stems under assets/visuals/scenes/
/// (a test keeps this and the folder the same).
const Set<String> storySceneBandIds = {
  'akagiri',
  'akagiri_tetsu_forge',
  'alster_family_house',
  'alster_high_quay',
  'alster_lower_town',
  'alster_stone_bridge',
  'alster_undercroft',
  'ashen_quarter_archive',
  'ashen_quarter_ash_market',
  'ashen_quarter_cinder_row',
  'ashen_quarter_gate',
  'ashen_quarter_spire_stair',
  'ashen_quarter_wall_of_names',
  'beyond_the_tear',
  'black_hold_cells',
  'blind_beggar',
  'candlehold_gates',
  'candlehold_lantern_hall',
  'candlehold_throne_room',
  'cove_camp',
  'cove_sail_loft',
  'dead_heart',
  'drowned_cloister_cache',
  'drowned_cloister_nave_hall',
  'drowned_cloister_ossuary',
  'drowned_cloister_stair',
  'emberwick',
  'emberwick_cold_forge',
  'emberwick_widows_house',
  'greyhithe',
  'highhearth',
  'highhearth_great_hearth',
  'hollow_court',
  'hollow_court_chamber',
  'hollow_shore_battlefield',
  'kindly_hill',
  'kindly_hill_long_room',
  'lark_wreck',
  'reliquary_chair_chapel',
  'reliquary_chartkeeper_chapel',
  'reliquary_hammer_chapel',
  'reliquary_muniment_room',
  'reliquary_parish_chapel',
  'reliquary_quarter',
  'reliquary_tribunal_chapel',
  'rimewell',
  'rimewell_chapel',
  'rimewell_road_keepers_house',
  'saltmouth_card_row',
  'saltmouth_green_door',
  'saltmouth_landward_gate',
  'saltmouth_landward_warehouse',
  'saltmouth_lantern_alleys',
  'saltmouth_tern_row',
  'saltmouth_tide_cellar',
  'saltmouth_wharf',
  'saltmouth_yard',
  'sleepers_face',
  'spire_cathedral',
  'spire_hall_of_records',
  'spire_of_judgment',
  'the_crossing',
  'white_anchorage_chandlery',
  'white_anchorage_chapel',
  'white_anchorage_hulls',
  'white_anchorage_impound',
  'white_anchorage_quay',
  'white_anchorage_stern',
  'white_anchorage_vault',
  'white_fleet_grave',
  'white_wells',
  'wracks_end',
  'wracks_end_lamp_room',
};

/// The band's file for a story node's [location], or null when it has none.
String? storySceneBandAsset(String? location) =>
    location != null && storySceneBandIds.contains(location)
        ? 'assets/visuals/scenes/$location.png'
        : null;

/// The 240x100 band at the full width of the story, its pixels kept square
/// (no smoothing), the page's colour fading in over its foot so the words
/// under it read as one with it.
class StorySceneBand extends StatelessWidget {
  const StorySceneBand({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final asset = storySceneBandAsset(location);
    if (asset == null) return const SizedBox.shrink();
    final ground = Theme.of(context).colorScheme.surface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 240 / 100,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(
              asset,
              key: Key('story_scene_$location'),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
              gaplessPlayback: true,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.62, 1],
                  colors: [Palette.alpha33Night0.withValues(alpha: 0), ground],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
