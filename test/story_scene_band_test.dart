// The story scene's picture (v1.953, widgets/story_scene_band.dart): one band
// of 240x100 pixels for each place of the story, a place with none (hollow_shore,
// left without one) shows nothing, and the list of places in code is the
// folder's.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/story_scene_band.dart';

void main() {
  final folder = Directory('assets/visuals/scenes');
  final files = {
    for (final f in folder.listSync().whereType<File>())
      if (f.path.endsWith('.png')) f.uri.pathSegments.last.split('.').first: f,
  };

  test('the places in code are the files in the folder', () {
    expect(storySceneBandIds, files.keys.toSet());
    expect(storySceneBandIds.length, 73);
  });

  test('every band is 240x100, a palette picture', () {
    for (final e in files.entries) {
      final b = ByteData.sublistView(e.value.readAsBytesSync());
      expect((b.getUint32(16), b.getUint32(20)), (240, 100), reason: e.key);
      expect(b.getUint8(25), 3, reason: '${e.key} is an 8-bit palette PNG');
    }
  });

  test('every place of the story but the one left bare has a band', () {
    final dag =
        jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
            as Map<String, dynamic>;
    final places = {
      for (final n in dag.values)
        if (n is Map && n['location'] != null) n['location'] as String
    };
    expect(places.difference(storySceneBandIds), {'hollow_shore'});
    expect(storySceneBandAsset('hollow_shore'), isNull);
    expect(storySceneBandAsset(null), isNull);
    expect(storySceneBandAsset('greyhithe'),
        'assets/visuals/scenes/greyhithe.png');
  });

  testWidgets('a band draws at the width of the story, a bare place nothing',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: Column(children: [
      StorySceneBand(location: 'greyhithe'),
      StorySceneBand(location: 'hollow_shore'),
    ]))));
    expect(find.byKey(const Key('story_scene_greyhithe')), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    final box = tester.getSize(find.byType(AspectRatio).first);
    expect(box.width / box.height, closeTo(2.4, 0.01));
  });
}
