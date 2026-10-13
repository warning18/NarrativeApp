// The simulator's "play to chapter" button sat under an Android phone's
// navigation bar: the full controls were taller than the screen, did not
// scroll and had no SafeArea. At 360 x 640 with a 48 px bottom inset, with
// the app's own fonts (Ahem measures far too wide), the button can be
// reached and tapped.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

Future<void> _loadFonts() async {
  const families = {
    'PixelifySans': [
      'assets/fonts/PixelifySans-Regular.ttf',
      'assets/fonts/PixelifySans-SemiBold.ttf',
    ],
    'Spectral': [
      'assets/fonts/Spectral-Regular.ttf',
      'assets/fonts/Spectral-Medium.ttf',
      'assets/fonts/Spectral-Italic.ttf',
    ],
    'IMFellEnglishSC': ['assets/fonts/IMFellEnglishSC-Regular.ttf'],
  };
  for (final family in families.entries) {
    final loader = FontLoader(family.key);
    for (final path in family.value) {
      loader.addFont(
          Future.value(ByteData.view(File(path).readAsBytesSync().buffer)));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  for (final size in const [Size(360, 640), Size(320, 568)]) {
    for (final french in [false, true]) {
      testWidgets(
          'the play-to-chapter button clears the system bar at '
          '${size.width.toInt()} px ${french ? 'in French' : 'in English'}',
          (tester) async {
        SharedPreferences.setMockInitialValues(
            {if (french) 'app_language': 'fr'});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        const bar = 48.0;
        tester.view.padding = const FakeViewPadding(bottom: bar);
        tester.view.viewPadding = const FakeViewPadding(bottom: bar);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
            theme: buildAppTheme(ColorScheme.fromSeed(
                seedColor: Colors.amber, brightness: Brightness.dark)),
            home: const PlaythroughSimulatorScreen(),
          ),
        ));
        final container = ProviderScope.containerOf(
            tester.element(find.byType(PlaythroughSimulatorScreen)));
        container.read(appLanguageProvider);
        await tester
            .runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
        await tester.pump(const Duration(milliseconds: 300));

        // A chapter chip, so the button is enabled, then the button itself.
        // The controls scroll as one list: fail here if it is not there.
        expect(find.byKey(const Key('sim_scroll_full')), findsOneWidget);
        final button = find.byIcon(Icons.fast_forward);
        await tester.dragUntilVisible(button,
            find.byKey(const Key('sim_scroll_full')), const Offset(0, -120));
        await tester.pump(const Duration(milliseconds: 300));
        final rect = tester.getRect(button);
        expect(rect.bottom, lessThanOrEqualTo(size.height - bar),
            reason: 'the button ends above the 48 px system bar');
        expect(tester.takeException(), isNull);
        // Hit-testable: a tap lands on the button, not on whatever is over it.
        expect(button.hitTestable(), findsOneWidget);
      });
    }
  }
}
