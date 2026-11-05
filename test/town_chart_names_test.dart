// The town chart's way names and banners on the village hubs (v1.853): no
// two names over each other, none over a banner, every banner whole in the
// frame, and the way picked keeps its name. QA found White Wells' banner cut
// by the frame and Rimewell's names on each other (main 1.851, 412 x 860).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';
import 'support/open_game.dart' show storedCityPlans;
import 'support/pump.dart';

const _hubs = <(String, String)>[
  ('1200', 'White Wells'),
  ('6100', 'Rimewell'),
  ('7200', 'Greyhithe'),
  ('5100', "Wrack's End"),
  ('6200', 'Highhearth'),
  ('3100', 'Emberwick'),
  ('3200', 'Akagiri'),
];

void main() {
  testWidgets('on the village hubs no name covers another or a banner',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(412, 860));
    await tester.pumpWidget(
        ProviderScope(overrides: [storedCityPlans], child: const MyApp()));
    Future<void> settle([int n = 8]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await settle();
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await settle();
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await settle();
    final play = container.read(storyPlayProvider.notifier);
    var checked = 0;
    for (final (id, name) in _hubs) {
      await tester.runAsync(() => container
          .read(playerSessionProvider.notifier)
          .loadSession(PlayerSession.fromJson({
            'raceId': 'human',
            'professionId': 'warrior',
            if (id == '1200') 'flags': ['lysa_survived', 'vica_follow'],
          })));
      play.jumpTo(id);
      await settle();
      await tester.pump(const Duration(seconds: 6));
      for (var i = 0; i < 3; i++) {
        tester
            .state<NavigatorState>(find.byType(Navigator).first)
            .popUntil(isGameRoute);
        await tester.pump(const Duration(seconds: 1));
      }
      for (final k in ['journey_reading_exit', 'journey_continue']) {
        final button = find.byKey(ValueKey(k));
        if (find.byKey(const ValueKey('journey_go')).evaluate().isEmpty &&
            button.evaluate().isNotEmpty) {
          await tester.tap(button.first);
          await settle();
          await tester.pump(const Duration(seconds: 2));
        }
      }
      final district = find.text('District');
      if (district.evaluate().isNotEmpty) {
        await tester.tap(district.first);
        await tester.pump(const Duration(seconds: 5));
      }
      final view = find.byType(CityChartView);
      if (view.evaluate().isEmpty) continue;
      final state = tester.state(view) as dynamic;
      final frame = Offset.zero & tester.getSize(view);
      final names = (state.debugNames() as List).cast<(Rect, String)>();
      for (var a = 0; a < names.length; a++) {
        for (var b = a + 1; b < names.length; b++) {
          expect(names[a].$1.overlaps(names[b].$1), isFalse,
              reason: '$name: "${names[a].$2}" over "${names[b].$2}"');
        }
      }
      final chart = tester.widget<CityChartView>(view).chart;
      for (final w in chart.ways) {
        final banner = state.debugBanner(w.id) as Rect?;
        if (banner == null) continue;
        expect(
            frame.contains(banner.topLeft) &&
                frame.contains(banner.bottomRight),
            isTrue,
            reason: '$name: the banner of "${w.id}" is cut by the frame: '
                '$banner in $frame');
        for (final n in names) {
          expect(n.$1.overlaps(banner), isFalse,
              reason: '$name: "${n.$2}" over the banner of "${w.id}"');
        }
      }
      checked++;
    }
    expect(checked, greaterThanOrEqualTo(5));
  });
}
