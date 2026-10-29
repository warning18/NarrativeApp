// A class with five branches (a mage) on a 320 px sky (v1.619): the fifth
// constellation has the last row to itself, across both cells, and every name
// stays inside the sky. One test per file: the game data is read from the
// bundle on the first pass and a read begun in one test never finishes for the
// next.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/skills/skills_screen.dart';
import 'package:narrative_data_app/screens/skills/star_chart.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a mage\'s five constellations fit 320 px, the fifth across',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SkillsScreen()),
    ));
    await _settle(tester);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(
            PlayerSession.fromJson({'raceId': 'elf', 'professionId': 'mage'})));
    await _settle(tester);

    final names = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key as ValueKey<String>).value.startsWith('branch_'));
    expect(names, findsNWidgets(5));
    final sky = tester.getSize(find.byKey(const Key('star_sky')));
    expect(sky.height, StarSky.of(5, sky.width).height);
    // Every constellation's name is inside the sky, none cut by its edge.
    final skyRect = tester.getRect(find.byKey(const Key('star_sky')));
    for (final e in names.evaluate()) {
      final rect = tester.getRect(find.byWidget(e.widget));
      expect(skyRect.contains(rect.topLeft), isTrue);
      expect(rect.right, lessThanOrEqualTo(skyRect.right + 0.5));
    }
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });
}
