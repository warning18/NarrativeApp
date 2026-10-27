// QA: layouts at phone widths, measured with the app's own fonts. The test
// font (Ahem) is far wider than PixelifySans and Spectral, so a 360 px
// overflow under Ahem says nothing (the level-up pop-up shows 53 px of it),
// and a layout can only be trusted when the bundled fonts are loaded. This
// loads them and checks the level-up pop-up (English and French) at 360 and
// 320 px, and the home shell's bar and tablet rail at a landscape phone and
// a tablet, for any overflow.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/level_up_dialog.dart';

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

/// Collects the overflow reports instead of failing on the first.
List<String> _collectOverflows(WidgetTester tester) {
  final seen = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) {
      seen.add(details.exceptionAsString().split('\n').first);
    } else {
      previous?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = previous);
  return seen;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  for (final size in const [Size(360, 640), Size(320, 568)]) {
    for (final french in [false, true]) {
      testWidgets(
          'the level-up pop-up fits ${size.width.toInt()} px '
          '${french ? 'in French' : 'in English'}', (tester) async {
        final overflows = _collectOverflows(tester);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues(
            {if (french) 'app_language': 'fr'});
        await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
            theme: buildAppTheme(ColorScheme.fromSeed(
                seedColor: Colors.amber, brightness: Brightness.dark)),
            home: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    key: const Key('open'),
                    onPressed: () =>
                        showLevelUpDialog(context, ref, newLevel: 14),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ));
        final container = ProviderScope.containerOf(
            tester.element(find.byKey(const Key('open'))));
        container.read(appLanguageProvider);
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 200)));
        // The widest value a row shows: "120 / 120".
        await tester.runAsync(() => container
            .read(playerSessionProvider.notifier)
            .loadSession(PlayerSession.fromJson({
              'statPoints': 3,
              'currentHealth': 120,
              'maxHealth': 120,
              'baseDamage': 12,
            })));
        await tester.pump();
        await tester.tap(find.byKey(const Key('open')));
        // The medal's rays turn for ever: step by hand rather than settle.
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        // The pop-up is up (its points box is gone: v1.565 shows only a quiet
        // count when more than one pick waits).
        expect(find.byKey(const Key('level_up_close')), findsOneWidget);
        expect(overflows, isEmpty, reason: overflows.toSet().join('\n'));
      });
    }
  }

  // The home shell: a bar on a phone (also one held sideways), a rail only
  // where there is room for it.
  for (final c in const [
    (Size(844, 390), false, 'a landscape phone keeps the bar'),
    (Size(844, 480), true, 'a tablet gets the rail'),
    (Size(360, 640), false, 'a phone keeps the bar'),
  ]) {
    testWidgets('home at ${c.$1.width.toInt()}x${c.$1.height.toInt()}: ${c.$3}',
        (tester) async {
      final overflows = _collectOverflows(tester);
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = c.$1;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      final edit = find.byKey(const Key('menu_edit_mode'));
      await tester.ensureVisible(edit);
      await tester.pump();
      await tester.tap(edit);
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
          find.byKey(const Key('home_nav_rail')).evaluate().isNotEmpty, c.$2);
      expect(find.byType(NavigationBar).evaluate().isNotEmpty, !c.$2);
      expect(overflows, isEmpty, reason: overflows.toSet().join('\n'));
    });
  }
}
