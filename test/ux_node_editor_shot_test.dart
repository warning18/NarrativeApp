// The story node editor's destination field at 412 px with the longest node
// id of the story (UX_SHOTS=<folder> UX_SHOT_TAG=before|after). Drawn only
// with UX_SHOTS.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/story_node_editor_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

class _Repository extends StoryRepository {
  _Repository(this.story);

  final StoryData story;

  @override
  Future<StoryData> load() async => story;
}

Future<void> _loadFonts() async {
  for (final (family, files) in [
    (
      InkFonts.system,
      ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']
    ),
    (
      InkFonts.prose,
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    (InkFonts.display, ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(Future.value(
          ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync())));
    }
    await loader.load();
  }
  final icons = File('/tmp/flutter/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final tag = Platform.environment['UX_SHOT_TAG'] ?? 'after';
  testWidgets('the destination field at 412 px', (tester) async {
    await tester.runAsync(_loadFonts);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(412 * 2, 760 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;
    final story = StoryData({
      for (final e in raw.entries)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
    });
    final longest = raw.keys.reduce((a, b) => a.length >= b.length ? a : b);
    final node = StoryNode.fromJson('probe', {
      'description': 'd',
      'choices': [
        {'text': 'Go', 'next_id': longest},
      ],
    });
    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storyRepositoryProvider.overrideWithValue(_Repository(story)),
      ],
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
            theme: buildAppTheme(const ColorScheme.light()),
            home: StoryNodeEditorScreen(node: node)),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(longest), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    tester.takeException();
    final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    late Uint8List bytes;
    await tester.runAsync(() async {
      final image = await b.toImage(pixelRatio: 1);
      bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
    });
    File('$shots/node-editor-$tag.png').writeAsBytesSync(bytes);
  }, skip: shots == null);
}
