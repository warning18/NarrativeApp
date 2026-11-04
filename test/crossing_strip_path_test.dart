// A land crossing's road on the world's strip (stripPathOf): every route of
// land_routes.json that stays on the land has an x for each end, and the
// windows along it are the same on every launch.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/land_crossing.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/region_strip.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/land_crossing_screen.dart';
import 'package:narrative_data_app/widgets/side_view/scene_windows.dart';
import 'package:narrative_data_app/widgets/side_view/world_camera.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  final geo =
      Geography.parse(geography: _table('geography'), biomes: _table('biomes'));
  final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
      as Map<String, dynamic>;
  final story = StoryData({
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });
  final strips = RegionStrips.build(
      geo: geo, chart: chartOf(MapShape.story), story: story);
  final routes = {
    for (final e in _table('land_routes').entries)
      e.key: LandRoute.fromJson(e.key, e.value as Map),
  };

  test('every land route has a way along the strip, start to end', () {
    for (final r in routes.values) {
      final path = stripPathOf(strips, geo, r);
      expect(path.length, greaterThanOrEqualTo(2), reason: r.id);
      expect(path.first, isNot(path.last), reason: '${r.id} goes somewhere');
    }
  });

  test('a road shows its windows the same on every launch', () {
    for (final r in routes.values) {
      List<int> days() {
        final path = stripPathOf(strips, geo, r);
        return [
          for (var d = 0; d < r.days; d++)
            sceneWindowAt(pathXAt(path, (d + 0.5) / r.days)!)
        ];
      }

      expect(days(), days(), reason: r.id);
    }
  });

  double reach(LandRoute r) {
    final p = stripPathOf(strips, geo, r);
    return p.reduce((a, b) => a > b ? a : b) -
        p.reduce((a, b) => a < b ? a : b);
  }

  test('only the sea cliffs\' long road is left to its own terrain', () {
    final long = [
      for (final r in routes.values)
        if (reach(r) > crossingCameraReach) r.id,
    ];
    expect(long, ['lantern_cliffs']);
  });

  testWidgets('a crossing along a seam is painted by the camera',
      (tester) async {
    final camera = WorldCamera(strips.zones);
    final route = routes['camp_to_quarter']!;
    final path = stripPathOf(strips, geo, route);
    // The road runs over the border of the cliffs and the ruins.
    expect(camera.seamAt(path[1]) ?? camera.seamAt(path[2]), isNotNull);
    await tester.binding.setSurfaceSize(const Size(400, 800));
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: LandCrossingScreen(
          route: route,
          events: const {},
          stripPath: path,
          camera: camera,
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('crossing_scene')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
