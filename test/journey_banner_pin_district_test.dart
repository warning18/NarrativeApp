// The district view's ways wear the banner too (v1.440): the rows under the
// chart, and the key button that opens the legend. In a file of its own: the
// city chart's plan is read once per run.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/city_provider.dart'
    show currentCityProvider;
import 'package:narrative_data_app/providers/home_tab_provider.dart'
    show isGameRoute;
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/widgets/journey_banner_pin.dart';
import 'support/pump.dart';
import 'support/open_game.dart';

void main() {
  testWidgets('a district: its ways wear the banner in the rows, the key shows',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(400, 860));

    final container = await openGame(tester);
    container.read(storyPlayProvider.notifier).jumpTo('2005');
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 6));
    for (var i = 0; i < 3; i++) {
      Navigator.of(tester.element(find.byType(JourneyScreen)))
          .popUntil(isGameRoute);
      await tester.pump(const Duration(seconds: 1));
    }
    expect(container.read(currentCityProvider), 'saltmouth');

    // The way here is a plain road: a banner in the row, no number.
    final row = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key as ValueKey<String>).value.startsWith('journey_row_banner_'));
    expect(row, findsOneWidget);
    expect(tester.widget<BannerPin>(row).cat, JourneyPinCat.way);
    expect(find.byKey(const Key('journey_legend_key')), findsOneWidget);

    await tester.tap(find.byKey(const Key('journey_legend_key')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('journey_legend')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
