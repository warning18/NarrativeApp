// The list under the Journey's map names places, not choices (v1.607): one row
// for each pin, no count and nothing to open in place; the ways show after a
// tap, in the pin's sheet, as after a tap on the pin itself. At the High Quay
// of Alster: the Lark's gangway (one way) and the looted armory (three).

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
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => rootBundle.clear());

  testWidgets('the High Quay lists its places, and a place opens its ways',
      (tester) async {
    tester.view.physicalSize = const Size(412, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
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
    container.read(storyPlayProvider.notifier).jumpTo('891');
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.tap(find.text('Journey').last);
    for (var i = 0;
        i < 60 &&
            (i < 8 ||
                find
                    .byKey(const ValueKey('journey_city_list'))
                    .evaluate()
                    .isEmpty);
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 500));
    }
    final district = find.text('District');
    if (district.evaluate().isNotEmpty) {
      await tester.tap(district.first, warnIfMissed: false);
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 500));
      }
    }

    final list = find.byKey(const ValueKey('journey_city_list'));
    Finder inList(Finder f) => find.descendant(of: list, matching: f);
    // No text laid over the map.
    expect(find.byKey(const Key('scene_band')), findsNothing);
    // The places, one row each.
    expect(inList(find.textContaining('Lark')), findsOneWidget);
    expect(inList(find.text('The looted armory')), findsOneWidget);
    // Never a choice's text, a count or a chevron.
    expect(inList(find.text('Bind your wounds with sailcloth')), findsNothing);
    expect(inList(find.text('Talk to the mate at the gangway')), findsNothing);
    expect(inList(find.byIcon(Icons.expand_more)), findsNothing);
    expect(
        find.byWidgetPredicate((w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>)
                .value
                .startsWith('journey_city_pin_count_')),
        findsNothing);
    // A place with several ways opens a sheet that names them.
    await tester.tap(inList(find.text('The looted armory')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
        find.byKey(const ValueKey('journey_pin_sheet_title')), findsOneWidget);
    final ways = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('journey_pin_way_'));
    expect(ways, findsAtLeastNWidgets(2));
    expect(find.text('Bind your wounds with sailcloth'), findsOneWidget);
    // A tap on a way opens it with its Go.
    await tester.tap(find.text('Bind your wounds with sailcloth'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('journey_go')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
