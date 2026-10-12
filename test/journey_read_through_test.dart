// The Journey walks the party to where the story really lands (v1.226): the
// wharf's way "pay for the insult" leads to a scene on the wharf that the
// story reads straight through to the Yard (2040 -> 2040_paid -> 2900), so
// the way sits at the Yard on the city's plan and the party walks there,
// not to a spot by itself on the wharf.
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
import 'package:narrative_data_app/widgets/city_plan_painter.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a way read through to another district sits there and walks',
      (tester) async {
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
    // Gold enough to pay, so the way is open.
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(
            {'raceId': 'human', 'professionId': 'warrior', 'gold': 100})));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);

    container.read(storyPlayProvider.notifier).jumpTo('2040');
    await _settle(tester);
    await tester.tap(find.text('Journey'));
    await _settle(tester);
    // The jump set the party down here along no choice: the map walks it
    // by the road first (a tap would skip it).
    await tester.pump(const Duration(seconds: 3));

    // The city's plan, with the fight and the way to pay on it.
    expect(find.byKey(const ValueKey('journey_streets')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_step_1')), findsOneWidget);
    final painter = tester
        .widget<CustomPaint>(find.byKey(const ValueKey('journey_streets')))
        .painter as CityPlanPainter;
    final streets =
        tester.getRect(find.byKey(const ValueKey('journey_streets')));
    Offset onMap(String district) =>
        streets.topLeft +
        painter.origin +
        painter.plan.anchorOf(district) * painter.scale;

    // The way to pay is at the Yard, where the story reads through to, and
    // nearer it than the wharf where the party stands.
    final pay = tester.getCenter(find.byKey(const ValueKey('journey_step_1')));
    expect((pay - onMap('saltmouth_yard')).distance,
        lessThan((pay - onMap('saltmouth_wharf')).distance),
        reason: 'pay at $pay');

    // Taking it walks the party there.
    await tester.tap(find.byKey(const ValueKey('journey_step_1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('journey_go')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('journey_traveller')), findsOneWidget);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await _settle(tester);
    expect(container.read(storyPlayProvider).currentNodeId, '2900');
    final error = tester.takeException();
    expect(error, isNull,
        reason: error is FlutterError ? error.toStringDeep() : '$error');
  });
}
