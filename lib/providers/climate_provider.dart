import 'dart:ui' show Offset;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/climate.dart';
import '../data/map_charts.dart';
import '../data/world_map.dart';
import 'map_look_provider.dart';
import 'player_session_provider.dart';
import 'story_providers.dart';

/// The sky over the party (v1.204, see climate.dart): the chart's climate
/// at the place the story stands, on the story's day. Null on a detour or
/// where the chart has no place for the scene.
class SkyHere {
  const SkyHere({required this.climate, required this.at, required this.day});

  final ChartClimate climate;

  /// Where on the chart.
  final Offset at;
  final int day;

  /// The day's weather, the same all day: what the map shows and what the
  /// play reads (fights, the road), so a fight or a road is the same
  /// whenever it is looked at that day (v1.208, see weather_effects.dart).
  /// Time stands still between turns (v1.210): there is no 'now' that
  /// moves.
  WeatherSample today() => climate.weather(at, ChartClimate.timeOf(day));

  /// The ground's climate today.
  ClimateSample get ground => climate.sample(at, day: day);
}

final skyHereProvider = Provider<SkyHere?>((ref) {
  final play = ref.watch(storyPlayProvider);
  if (play.isInExcursion) return null;
  final standing = currentLandmark(play.currentNodeId, play.history) ??
      landmarkOfScene(play.currentNodeId);
  if (standing == null) return null;
  final chart = chartOf(ref.watch(mapShapeProvider));
  final day = ref.watch(playerSessionProvider.select((s) => s.day));
  return SkyHere(
      climate: ChartClimate.of(chart), at: chart.of(standing), day: day);
});
