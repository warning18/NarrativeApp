// The painted backgrounds of three screens (screen_pictures.dart): each id set
// is the folder's files, a screen without a picture keeps its look, and a
// memory with a band draws it instead of the code scene.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/origin_scene_backdrop.dart';
import 'package:narrative_data_app/widgets/screen_pictures.dart';
import 'package:narrative_data_app/widgets/street_view/street_view.dart';

Set<String> _stems(String dir) => {
      for (final f in Directory(dir).listSync())
        if (f.path.endsWith('.png'))
          f.uri.pathSegments.last.replaceAll('.png', ''),
    };

void main() {
  test('each id set is the files of its folder', () {
    expect(lifeBandIds, _stems('assets/visuals/life'));
    expect(characterPlateIds, _stems('assets/visuals/character'));
    expect(expeditionBandIds, _stems('assets/visuals/expeditions'));
  });

  test('a picture has a path only when its id has a file', () {
    expect(lifeBandAsset('sparrow'), 'assets/visuals/life/sparrow.png');
    expect(lifeBandAsset('lamp'), 'assets/visuals/life/lamp.png');
    expect(lifeBandAsset('mark_orc'), 'assets/visuals/life/mark.png');
    expect(lifeBandAsset('calling_ranger'), 'assets/visuals/life/calling.png');
    // The race's mark (age 8) and the calling's memory (age 12) share the
    // age's band.
    expect(lifeBandStemOf('mark_dwarf'), 'mark');
    expect(lifeBandStemOf('mark_voidkin'), 'mark');
    expect(lifeBandStemOf('calling_mage'), 'calling');
    expect(lifeBandStemOf('sparrow'), 'sparrow');
    expect(characterPlateAsset(0), 'assets/visuals/character/race.png');
    expect(characterPlateAsset(1), 'assets/visuals/character/calling.png');
    expect(expeditionBandAsset('z_lantern_docks'),
        'assets/visuals/expeditions/z_lantern_docks.png');
    expect(expeditionBandAsset('z_salt_road'),
        'assets/visuals/expeditions/z_salt_road.png');
    expect(expeditionBandAsset('z_unknown'), isNull);
    for (final id in lifeBandIds) {
      expect(File(lifeBandAsset(id)!).existsSync(), isTrue, reason: id);
    }
  });

  test('every zone has a band', () {
    final zones =
        jsonDecode(File('assets/gamedata/zones.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(expeditionBandIds, zones.keys.toSet());
  });

  testWidgets('every drawn memory has a band; a new one keeps the code scene',
      (tester) async {
    Future<void> show(String memoryId) => tester.pumpWidget(MaterialApp(
        home: Scaffold(body: OriginSceneBackdrop(memoryId: memoryId))));
    await show('sparrow');
    expect(find.byType(LifeBand), findsOneWidget);
    expect(find.byType(StreetViewScene), findsNothing);
    await show('not_a_memory');
    expect(find.byType(LifeBand), findsNothing);
    expect(find.byType(StreetViewScene), findsOneWidget);
  });
}
