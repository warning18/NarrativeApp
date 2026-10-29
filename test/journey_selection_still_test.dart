// Picking a way on the Journey map moves nothing (v1.210): the panel under
// the map keeps one height whether or not a way is picked, so the map is
// the same size and every mark stays where it was.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/story_providers.dart';
import 'support/pump.dart';
import 'support/open_game.dart';

void main() {
  testWidgets('picking a way moves no mark on the map', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(400, 860));

    final container = await openGame(tester);
    container.read(storyPlayProvider.notifier).jumpTo('100');
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);

    List<Offset> marks() => [
          for (var i = 0; i < 3; i++)
            tester.getCenter(find.byKey(ValueKey('journey_step_$i')))
        ];
    final before = marks();
    final mapBefore =
        tester.getSize(find.byKey(const ValueKey('journey_room')));
    await tester.tap(find.byKey(const ValueKey('journey_step_0')));
    await settleApp(tester);
    expect(marks(), before);
    expect(
        tester.getSize(find.byKey(const ValueKey('journey_room'))), mapBefore);
    await tester.tap(find.byKey(const ValueKey('journey_step_1')));
    await settleApp(tester);
    expect(marks(), before);
  });
}
