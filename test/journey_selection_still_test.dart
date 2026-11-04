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
    // The house after the escape (470): both its ways lead out of the Lower
    // Town, so both are marks on the map (the Blind Beggar's 100, used
    // before, has only ways that stay in the room: cards, no marks).
    container.read(storyPlayProvider.notifier).jumpTo('470');
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);

    final shown = [
      for (var i = 0; i < 4; i++)
        if (find.byKey(ValueKey('journey_step_$i')).evaluate().isNotEmpty) i,
    ];
    expect(shown.length, greaterThanOrEqualTo(2), reason: '$shown');
    List<Offset> marks() => [
          for (final i in shown)
            tester.getCenter(find.byKey(ValueKey('journey_step_$i')))
        ];
    // The map the marks stand on: the nearest stack round the first one.
    final map = find
        .ancestor(
            of: find.byKey(ValueKey('journey_step_${shown[0]}')),
            matching: find.byType(Stack))
        .first;
    final before = marks();
    final mapBefore = tester.getSize(map);
    await tester.tap(find.byKey(ValueKey('journey_step_${shown[0]}')));
    await settleApp(tester);
    expect(marks(), before);
    expect(tester.getSize(map), mapBefore);
    await tester.tap(find.byKey(ValueKey('journey_step_${shown[1]}')));
    await settleApp(tester);
    expect(marks(), before);
  });
}
