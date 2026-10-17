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

const smokeSizes = [Size(360, 740), Size(320, 568)];

/// The bundled fonts, and the SDK's Material icons when they can be found (a
/// test font draws them as boxes), loaded once.
Future<void> loadSmokeFonts() async {
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
  final root = Platform.environment['FLUTTER_ROOT'] ??
      '${Platform.environment['HOME']}/flutter';
  final icons = File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await loader.load();
  }
}

/// One thing to show.
class SmokeCase {
  const SmokeCase(this.name, this.widget,
      {this.session, this.prepare, this.bare = false});

  /// A short name, for the failure message and the picture's file.
  final String name;
  final Widget widget;

  /// The save to play with (a plain human warrior by default).
  final PlayerSession? session;

  /// More setup, with the container (a table to load, a flag).
  final Future<void> Function(ProviderContainer container)? prepare;

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
        () => Future<void>.delayed(Duration(milliseconds: first ? 200 : 100)));
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
        final label =
            '${c.name} at ${size.width.toInt()} px ${french ? 'French' : 'English'}';
        await tester.runAsync(() => container
            .read(appLanguageProvider.notifier)
            .setLanguage(french ? AppLanguage.fr : AppLanguage.en));
        overflows.clear();
        holder.value = Scaffold(
          body: c.bare
              ? c.widget
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: c.widget,
                  ),
                ),
        );
        await tester.pump();
        await _settle(tester);
        expect(overflows, isEmpty, reason: '$label: ${overflows.join('; ')}');
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
      }
    }
    holder.value = const SizedBox.shrink();
    await tester.pump();
  }
}
