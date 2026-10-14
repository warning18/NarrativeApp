// Picking a way on the Journey map moves nothing (v1.210): the panel under
// the map keeps one height whether or not a way is picked, so the map is
// the same size and every mark stays where it was.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('picking a way moves no mark on the map', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(
            {'raceId': 'human', 'professionId': 'warrior'})));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);
    container.read(storyPlayProvider.notifier).jumpTo('100');
    await _settle(tester);
    await tester.tap(find.text('Journey'));
    await _settle(tester);

    List<Offset> marks() => [
          for (var i = 0; i < 3; i++)
            tester.getCenter(find.byKey(ValueKey('journey_step_$i')))
        ];
    final before = marks();
    final mapBefore =
        tester.getSize(find.byKey(const ValueKey('journey_room')));
    await tester.tap(find.byKey(const ValueKey('journey_step_0')));
    await _settle(tester);
    expect(marks(), before);
    expect(
        tester.getSize(find.byKey(const ValueKey('journey_room'))), mapBefore);
    await tester.tap(find.byKey(const ValueKey('journey_step_1')));
    await _settle(tester);
    expect(marks(), before);
  });
}
