// On a 320 px screen the Journey's weather chip is an icon (a tap reads the
// whole line), so it never lies over the lowest step's name (v1.278). In its
// own file: the Journey tests leave app-wide state that changes the chip.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/story_providers.dart';
import 'support/pump.dart';
import 'support/open_game.dart';

void main() {
  testWidgets('on a 320 px screen the weather chip is an icon, a tap reads it',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(320, 640));

    final container = await openGame(tester);
    final play = container.read(storyPlayProvider.notifier);
    play.jumpTo('2001');
    await settleApp(tester);
    play.jumpTo('2005');
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);

    final compact = find.byKey(const ValueKey('journey_weather_chip_compact'),
        skipOffstage: false);
    expect(compact, findsOneWidget);
    expect(
        find.byKey(const ValueKey('journey_weather_chip'), skipOffstage: false),
        findsNothing);
    await tester.tap(compact, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('°', skipOffstage: false), findsWidgets);
  });
}
