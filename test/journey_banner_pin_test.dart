// The Journey's pins as banners (v1.440, docs/proposals/journey-pins-banner.md):
// a way hangs as a banner in the colour and icon of what it is, a key button
// opens the legend, and a fight or a roll keeps its round mark.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/journey_map.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/city_provider.dart'
    show cityPlanRecordsProvider;
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/journey_banner_pin.dart';
import 'package:narrative_data_app/widgets/journey_glyph.dart';
import 'support/pump.dart';

void main() {
  test('a way folds to one of the seven categories, the main quest first', () {
    JourneyPinCat? cat(JourneyStepKind k, [JourneyQuestTie? t]) =>
        journeyPinCatOf(k, t);
    expect(cat(JourneyStepKind.mainQuest), JourneyPinCat.main);
    expect(cat(JourneyStepKind.ending), JourneyPinCat.main);
    // Tied to the main quest, whatever the way is.
    expect(cat(JourneyStepKind.road, JourneyQuestTie.main), JourneyPinCat.main);
    expect(cat(JourneyStepKind.shop, JourneyQuestTie.side), JourneyPinCat.side);
    expect(cat(JourneyStepKind.quest), JourneyPinCat.side);
    expect(cat(JourneyStepKind.expedition), JourneyPinCat.detour);
    expect(cat(JourneyStepKind.shop), JourneyPinCat.shop);
    expect(cat(JourneyStepKind.travel), JourneyPinCat.travel);
    expect(cat(JourneyStepKind.rest), JourneyPinCat.rest);
    expect(cat(JourneyStepKind.road), JourneyPinCat.way);
    // Played where the party stands: no banner.
    expect(cat(JourneyStepKind.fight), isNull);
    expect(cat(JourneyStepKind.check), isNull);
    expect(cat(JourneyStepKind.challenge), isNull);
  });

  test('every category has its own icon and its own colour, dark and light',
      () {
    for (final dark in [true, false]) {
      final ink = dark ? InkColors.dark : InkColors.light;
      final colours = {
        for (final c in JourneyPinCat.values) c.colorOn(ink, dark: dark)
      };
      expect(colours.length, JourneyPinCat.values.length,
          reason: 'colours differ, dark: $dark');
    }
    expect({for (final c in JourneyPinCat.values) c.icon}.length,
        JourneyPinCat.values.length);
  });

  testWidgets('the Journey hangs its ways as banners; the key opens the legend',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(400, 860));

    await tester.pumpWidget(ProviderScope(overrides: [
      cityPlanRecordsProvider.overrideWith((ref) async => const {})
    ], child: const MyApp()));
    await settleApp(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await settleApp(tester);
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
    await settleApp(tester);
    final play = container.read(storyPlayProvider.notifier);
    play.jumpTo('2001');
    await settleApp(tester);
    play.jumpTo('2005');
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);

    // The gate's ways are plain roads: banners with the signpost.
    final pin = find.descendant(
        of: find.byKey(const ValueKey('journey_step_0')),
        matching: find.byType(BannerPin));
    expect(pin, findsOneWidget);
    expect(tester.widget<BannerPin>(pin).cat, JourneyPinCat.way);
    expect(find.byKey(const Key('journey_legend_key')), findsOneWidget);

    // The pin is still the tap's: picking it says what the way is.
    await tester.tap(find.byKey(const ValueKey('journey_step_0')));
    await tester.pump();
    expect(
        tester
            .widget<BannerPin>(find.descendant(
                of: find.byKey(const ValueKey('journey_step_0')),
                matching: find.byType(BannerPin)))
            .lit,
        isTrue);

    await tester.tap(find.byKey(const Key('journey_legend_key')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('journey_legend')), findsOneWidget);
    expect(find.text('What the banners mean'), findsOneWidget);
    for (final c in JourneyPinCat.values) {
      expect(find.byKey(Key('journey_legend_${c.name}')), findsOneWidget,
          reason: c.name);
    }
    expect(find.text('Main quest'), findsOneWidget);
    expect(find.text('Shop and service'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [true, false]) {
    testWidgets('the legend fits 320 px in French, ${dark ? 'dark' : 'light'}',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      usePhone(tester, const Size(320, 640));
      final scheme = ColorScheme.fromSeed(
          seedColor: Colors.brown,
          brightness: dark ? Brightness.dark : Brightness.light);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(scheme),
          home: const Scaffold(body: JourneyLegendSheet()),
        ),
      ));
      final container =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      await tester.runAsync(() => container
          .read(appLanguageProvider.notifier)
          .setLanguage(AppLanguage.fr));
      await tester.pump();
      expect(find.text('Quête principale'), findsOneWidget);
      expect(find.text('Boutique et service'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
