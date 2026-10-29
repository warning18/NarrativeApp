// QA: an image the game loads must be in the build (issue #598). pubspec.yaml
// lists asset folders one by one and a folder entry is not recursive, so a
// folder missing from the list loads fine from disk in a tool and fails in the
// app: the tutorial guide's walk frames west and south, and the chapter art
// strips, were once missing.
//  1. every folder of images under assets/ is declared in pubspec.yaml, or is
//     named below as source art that does not ship;
//  2. the tutorial guide's frames, in every direction it walks, load.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/companion_sprites.dart';

/// Source art the build does not need: the animation's own exports.
const _sourceOnly = {
  'assets/visuals/companion/dog_companion_animations/Fight_-_Attack/rotations',
  'assets/visuals/companion/dog_companion_animations/Fight_-_Attack/animations/Bark/east',
  'assets/visuals/companion/dog_companion_animations/Fight_-_Attack/animations/Bark/north',
  'assets/visuals/companion/dog_companion_animations/Fight_-_Attack/animations/Bark/west',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every folder of images under assets/ is declared in pubspec.yaml', () {
    final declared = {
      for (final m in RegExp(r'^\s+- (assets/\S+)', multiLine: true)
          .allMatches(File('pubspec.yaml').readAsStringSync()))
        m.group(1)!,
    };
    final missing = <String>{};
    for (final f in Directory('assets').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.png')) continue;
      final path = f.path.replaceAll('\\', '/');
      final folder = path.substring(0, path.lastIndexOf('/'));
      if (declared.contains('$folder/') || declared.contains(path)) continue;
      if (_sourceOnly.contains(folder)) continue;
      missing.add(folder);
    }
    expect(missing, isEmpty,
        reason: 'These folders hold images pubspec.yaml does not list, so the '
            'build leaves them out (a folder entry is not recursive). List '
            'them, or, if they are source art, add them to _sourceOnly in '
            'this test:\n${missing.join('\n')}');
    for (final s in _sourceOnly) {
      expect(Directory(s).existsSync(), isTrue,
          reason:
              '$s is named as source art but is gone: drop it from the list');
    }
  });

  test('the tutorial guide\'s walk frames load in every direction', () async {
    final frames = [
      for (final dir in const [
        'Walking/east',
        'Walking/west',
        'Walking/north',
        'Walking/south',
        'walking_angel/east',
        'walking_evil/east',
      ])
        ...companionFrames(dir, 8),
      '$companionAssetsRoot/Sitting_down/rotations/south.png',
      '$companionAssetsRoot/Make_it_with_angel_w/rotations/south.png',
      '$companionAssetsRoot/Make_it_with_demon_w/rotations/south.png',
    ];
    final failed = <String>[];
    for (final path in frames) {
      try {
        expect((await rootBundle.load(path)).lengthInBytes, greaterThan(0));
      } catch (_) {
        failed.add(path);
      }
    }
    expect(failed, isEmpty, reason: 'not in the build: ${failed.join(', ')}');
  });
}
