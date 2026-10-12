// The UX polish of v1.255: one page transition for every screen, the title
// standard in the wind, a pixel flourish for a level gained and a chapter
// opened, patrons shown by their pixel banner, the standing meter that slides
// and glows, empty and error states with the companion, and the tablet
// layout (a rail instead of the bar).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/clan_widgets.dart';
import 'package:narrative_data_app/widgets/empty_state.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';
import 'package:narrative_data_app/widgets/pixel_vfx.dart';
import 'package:narrative_data_app/widgets/sign_widgets.dart';
import 'package:narrative_data_app/widgets/wind_banner.dart';

// One theme object, so a rebuilt app does not animate between two equal themes.
final ThemeData _theme = buildAppTheme(
    ColorScheme.fromSeed(seedColor: Colors.amber, brightness: Brightness.dark));

Widget _app(Widget home) => MaterialApp(theme: _theme, home: home);

void main() {
  group('page transition', () {
    Future<void> push(WidgetTester tester) async {
      await tester.pumpWidget(_app(Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('next page')))),
            child: const Text('go'),
          ),
        ),
      )));
      await tester.tap(find.text('go'));
      await tester.pump();
    }

    testWidgets('the new page fades in and rises 12 px over 180 ms',
        (tester) async {
      await push(tester);
      await tester.pump(const Duration(milliseconds: 90));
      final fade = tester.widget<FadeTransition>(find
          .ancestor(
              of: find.text('next page'), matching: find.byType(FadeTransition))
          .first);
      expect(fade.opacity.value, inExclusiveRange(0.0, 1.0));
      final shift = tester.widget<Transform>(find
          .ancestor(
              of: find.text('next page'), matching: find.byType(Transform))
          .first);
      final dy = shift.transform.getTranslation().y;
      expect(dy, inExclusiveRange(0.0, InkPageTransitions.rise));
      await tester.pump(InkPageTransitions.duration);
      await tester.pumpAndSettle();
      expect(find.text('next page'), findsOneWidget);
    });

    testWidgets('with reduced motion the pages just swap', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await push(tester);
      await tester.pump(const Duration(milliseconds: 30));
      final fades = find.ancestor(
          of: find.text('next page'), matching: find.byType(FadeTransition));
      for (final e in fades.evaluate()) {
        expect((e.widget as FadeTransition).opacity.value, 1.0);
      }
    });
  });

  group('the title standard', () {
    testWidgets('blows in the wind, and holds still with reduced motion',
        (tester) async {
      await tester.pumpWidget(_app(const Scaffold(
          body: Center(child: WindBanner(id: titleBannerId, scale: 2)))));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(WindBanner), findsOneWidget);
      expect(tester.getSize(find.byType(WindBanner)),
          const Size((64 + 24) * 2, 128 * 2));
      expect(tester.hasRunningAnimations, isTrue);
      expect(tester.takeException(), isNull);

      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await tester.pumpWidget(_app(const Scaffold(
          body: Center(child: WindBanner(id: 'clan_vigil', scale: 1)))));
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    test('the cloth leans into the wind more the lower it hangs', () {
      final rod = WindPainter.offsetAt(0.25, 0, 14, 128);
      final hem = WindPainter.offsetAt(0.25, 0, 126, 128);
      expect(hem.abs(), greaterThan(rod.abs()));
    });
  });

  group('a pixel moment', () {
    testWidgets('plays once and is gone', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(
          body: SizedBox(
              width: 144,
              height: 144,
              child: PixelMoment(
                palette: PixelMoment.gold,
                duration: Duration(milliseconds: 800),
                layers: [PixelMomentLayer('vfx_crit', span: 0.6)],
              )))));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
    });
  });

  group('patron emblems', () {
    testWidgets('a clan is shown by the sign off its pixel banner',
        (tester) async {
      const vigil = Patron(
          id: 'vigil', name: 'Vigil', kind: PatronKind.clan, color: 0xFF607D8B);
      await tester.pumpWidget(_app(const Scaffold(
          body: Center(child: PatronEmblem(patron: vigil, size: 36)))));
      expect(find.byKey(const ValueKey('patron_banner_vigil')), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('a patron with no banner keeps the icon on its disc',
        (tester) async {
      const wanderer = Patron(
          id: 'nobody',
          name: 'Nobody',
          kind: PatronKind.clan,
          icon: 'pan_tool');
      await tester.pumpWidget(_app(const Scaffold(
          body: Center(child: PatronEmblem(patron: wanderer, size: 36)))));
      expect(find.byType(Icon), findsOneWidget);
      expect(find.byKey(const ValueKey('patron_banner_nobody')), findsNothing);
    });
  });

  group('the standing meter', () {
    testWidgets('slides to the new standing and the glow fades',
        (tester) async {
      Widget meter(double v) => _app(Scaffold(
          body: Padding(
              padding: const EdgeInsets.all(20),
              child: StandingMeter(value: v))));
      await tester.pumpWidget(meter(10));
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(meter(40));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(StandingMeter.slide);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('with reduced motion it jumps', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      Widget meter(double v) =>
          _app(Scaffold(body: Center(child: StandingMeter(value: v))));
      await tester.pumpWidget(meter(10));
      await tester.pumpWidget(meter(-60));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('empty and error states', () {
    testWidgets('the companion sits by the message', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(
          body: InkEmptyState(message: 'Nothing written yet.'))));
      expect(find.byKey(const ValueKey('empty_state_dog')), findsOneWidget);
      expect(find.text('Nothing written yet.'), findsOneWidget);
    });

    testWidgets('an error shows the message in the error colour',
        (tester) async {
      await tester.pumpWidget(_app(const Scaffold(
          body: InkErrorState(message: 'Could not load', detail: 'boom'))));
      expect(find.text('Could not load'), findsOneWidget);
      expect(find.text('boom'), findsOneWidget);
      final text = tester.widget<Text>(find.text('Could not load'));
      final scheme =
          Theme.of(tester.element(find.text('Could not load'))).colorScheme;
      expect(text.style?.color, scheme.error);
    });
  });

  group('the tablet layout', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> openEditMode(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
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
      // On a short window the menu scrolls: bring the button into view.
      await tester.ensureVisible(find.byKey(const Key('menu_edit_mode')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('menu_edit_mode')));
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('a wide window puts the tabs in a rail', (tester) async {
      await openEditMode(tester, const Size(1000, 700));
      expect(find.byKey(const Key('home_nav_rail')), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Generate'), findsOneWidget);
    });

    testWidgets('a phone on its side keeps the bar and does not overflow',
        (tester) async {
      await openEditMode(tester, const Size(844, 390));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('home_nav_rail')), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('a small tablet takes the rail without overflowing',
        (tester) async {
      await openEditMode(tester, const Size(900, 500));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('home_nav_rail')), findsOneWidget);
    });

    testWidgets('a phone keeps the bar', (tester) async {
      await openEditMode(tester, const Size(390, 844));
      expect(find.byKey(const Key('home_nav_rail')), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });
}
