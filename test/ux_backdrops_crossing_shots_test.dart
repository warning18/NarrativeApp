// UX picture tool (not a guard): the real land crossing screen on each terrain,
// showing a chosen version of the scene (the first day of a crossing whose
// seed gives that version), with the app's fonts, for the backdrops review.
//   UX_SHOTS=<folder> flutter test test/ux_backdrops_crossing_shots_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/land_crossing.dart';
import 'package:narrative_data_app/screens/land_crossing_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/side_view/scene_versions.dart';

import 'support/fonts.dart';
import 'support/pump.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final dir = Platform.environment['UX_SHOTS'];
  testWidgets('the crossing scene, version by version', (tester) async {
    if (dir == null) return;
    Directory(dir).createSync(recursive: true);
    await loadAppFonts();
    SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
    usePhone(tester, const Size(412, 890));
    final base = landRouteFor(
        _json('assets/gamedata/land_routes.json'), 'crash_to_sleeper')!;
    final events = landEventsFrom(_json('assets/gamedata/land_events.json'));
    final key = GlobalKey();
    // (terrain, version to show, file name)
    for (final (terrain, version) in const [
      ('desert', 0),
      ('desert', 1),
      ('desert', 2),
      ('desert', 3),
      ('frost', 3),
      ('fen', 1),
      ('ruins', 2),
      ('sea_cliffs', 3),
    ]) {
      // A seed whose first day is [version].
      var seed = 0;
      while (sceneVersionAt('r$seed', 0) != version) {
        seed++;
      }
      final route = LandRoute(
        id: 'r$seed',
        name: base.name,
        nameFr: base.nameFr,
        from: base.from,
        to: base.to,
        roads: base.roads,
        days: base.days,
        biome: terrain,
        terrain: terrain,
        chapter: base.chapter,
        events: base.events,
      );
      await tester.pumpWidget(ProviderScope(
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            theme: buildAppTheme(const ColorScheme.dark()),
            home: LandCrossingScreen(
                route: route, events: events, random: Random(3)),
          ),
        ),
      ));
      await settleApp(tester);
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$dir/crossing-$terrain-v${version + 1}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }
  });
}
