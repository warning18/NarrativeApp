import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/map_charts.dart';
import '../data/region_strip.dart';
import 'geography_provider.dart';
import 'story_providers.dart';

/// The world's strips (region_strip.dart): where every place and road stop
/// stands for the side-view camera. Built once the geography and the story
/// have loaded.
final regionStripsProvider = FutureProvider<RegionStrips>((ref) async {
  final geo = ref.watch(geographyProvider);
  final story = await ref.watch(storyDataProvider.future);
  return RegionStrips.build(
      geo: geo, chart: chartOf(MapShape.story), story: story);
});
