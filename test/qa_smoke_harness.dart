// QA: the smoke test of a widget on a phone, with the app's own fonts (the test
// font is far wider, so only the bundled fonts tell the truth). Each case is a
// widget (and the save it needs); [runSmoke] shows it at 360 x 740 and
// 320 x 568, in English and in French, and fails on any "overflowed" error.
// SMOKE_SHOTS=<folder> also writes a picture of each to that folder.
//
// One test per file runs every case: the game data is read from the bundle on
// the first pass, and a read begun inside one test never finishes for the next.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'support/fonts.dart';

const smokeSizes = [Size(360, 740), Size(320, 568)];

/// The bundled fonts, and the SDK's Material icons when they can be found.
Future<void> loadSmokeFonts() => loadAppFonts();

/// One thing to show.
class SmokeCase {
  const SmokeCase(this.name, this.widget,
      {this.session, this.prepare, this.act, this.after, this.bare = false});

  /// A short name, for the failure message and the picture's file.
  final String name;
  final Widget widget;

  /// The save to play with (a plain human warrior by default).
  final PlayerSession? session;

  /// More setup, with the container (a table to load, a flag).
  final Future<void> Function(ProviderContainer container)? prepare;

  /// Something to do once the widget is up (a tap, a scroll); the widget
  /// is settled again after it.
  final Future<void> Function(WidgetTester tester)? act;

  /// What to do once the pass is checked and photographed (close what the
  /// case opened the way a player would).
  final Future<void> Function(WidgetTester tester)? after;

  /// Shown as it is, with no scroll view around it (a screen, a sheet's own
  /// body that scrolls itself).
  final bool bare;
}

final _warmed = Expando<bool>();

Future<void> _settle(WidgetTester tester) async {
  // The first one of a test waits for the game data to load.
  final first = _warmed[tester] == null;
  _warmed[tester] = true;
  for (var i = 0; i < (first ? 6 : 3); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: first ? 200 : 30)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

PlayerSession smokeSession() => PlayerSession.fromJson({
      'raceId': 'human',
      'professionId': 'warrior',
      'ownedDiceIds': ['starter_die'],
      'equippedDiceId': 'starter_die',
    });

/// Runs [cases] on every size, in both languages. [overrides] go to the
/// provider scope (a table or a record the widgets read).
Future<void> runSmoke(
  WidgetTester tester,
  List<SmokeCase> cases, {
  List<Override> overrides = const [],
  List<Size> sizes = smokeSizes,
}) async {
  final shots = Platform.environment['SMOKE_SHOTS'];
  final overflows = <String>[];
  // Every pass that overflowed, told at the end: an expect() while the error
  // handler is ours makes the test runner hang instead of failing.
  final failures = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) {
      overflows.add(details.exceptionAsString().split('\n').first);
    } else {
      previous?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = previous);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.view.physicalSize = sizes.first;

  final holder = ValueNotifier<Widget>(const SizedBox.shrink());
  final boundary = GlobalKey();
  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: RepaintBoundary(
      key: boundary,
      child: MaterialApp(
        theme: buildAppTheme(ColorScheme.fromSeed(
            seedColor: Colors.amber, brightness: Brightness.dark)),
        home: ValueListenableBuilder<Widget>(
          valueListenable: holder,
          builder: (_, widget, __) => widget,
        ),
      ),
    ),
  ));
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  container.read(playerSessionProvider);
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));

  for (final c in cases) {
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(c.session ?? smokeSession()));
    if (c.prepare != null) await tester.runAsync(() => c.prepare!(container));
    for (final size in sizes) {
      tester.view.physicalSize = size;
      for (final french in [false, true]) {
        // A case that acts (builds, buys) starts every pass from its save.
        if (c.act != null) {
          await tester.runAsync(() => container
              .read(playerSessionProvider.notifier)
              .loadSession(c.session ?? smokeSession()));
        }
        final label =
            '${c.name} at ${size.width.toInt()} px ${french ? 'French' : 'English'}';
        await tester.runAsync(() => container
            .read(appLanguageProvider.notifier)
            .setLanguage(french ? AppLanguage.fr : AppLanguage.en));
        // A sheet or dialog a case opened is closed before the next one.
        tester
            .state<NavigatorState>(find.byType(Navigator).first)
            .popUntil((route) => route.isFirst);
        await tester.pump(const Duration(milliseconds: 400));
        overflows.clear();
        // A new State each pass (a sheet a widget opens opens again).
        holder.value = KeyedSubtree(
          key: ValueKey(label),
          child: Scaffold(
            body: c.bare
                ? c.widget
                : SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: c.widget,
                    ),
                  ),
          ),
        );
        await tester.pump();
        await _settle(tester);
        if (c.act != null) {
          await c.act!(tester);
          await _settle(tester);
        }
        if (overflows.isNotEmpty) {
          failures.add('$label: ${overflows.toSet().join('; ')}');
        }
        if (shots != null) {
          final image = await tester.runAsync(() async {
            final object = boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            return object.toImage();
          });
          final bytes = await tester.runAsync(
              () => image!.toByteData(format: ui.ImageByteFormat.png));
          Directory(shots).createSync(recursive: true);
          File('$shots/${c.name}_${size.width.toInt()}_${french ? 'fr' : 'en'}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        }
        if (c.after != null) await c.after!(tester);
      }
    }
    // A sheet the case opened goes before its host does.
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .popUntil((route) => route.isFirst);
    await tester.pump(const Duration(milliseconds: 400));
    holder.value = const SizedBox.shrink();
    await tester.pump();
  }
  FlutterError.onError = previous;
  expect(failures, isEmpty, reason: failures.join('\n'));
}
