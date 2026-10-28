// Pictures of the built Forge sheet and forging moment (v1.593), drawn only
// with UX_SHOTS (a folder):
//   UX_SHOTS=docs/ux-shots flutter test test/ux_forge_build_shots_test.dart
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/forge_sheet.dart';

class _Face implements Random {
  _Face(this.face);
  final int face;
  @override
  int nextInt(int max) => face - 1;
  @override
  double nextDouble() => 0.5;
  @override
  bool nextBool() => true;
}

Future<void> _loadFonts() async {
  for (final (family, files) in const [
    ('PixelifySans', ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']),
    (
      'Spectral',
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      final file = File('assets/fonts/$f');
      if (!file.existsSync()) continue;
      loader
          .addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    }
    await loader.load();
  }
  final icons = File(
      '/tmp/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await loader.load();
  }
}

Future<void> _settle(WidgetTester tester, {int n = 4}) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  if (shots == null) {
    test('the forge pictures are drawn only with UX_SHOTS', () {});
    return;
  }

  testWidgets('the forge sheet and the forging moment', (tester) async {
    await tester.runAsync(_loadFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    forgeRandomForTest = () => _Face(13);
    addTearDown(() => forgeRandomForTest = null);
    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme:
              buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.light)),
          home: const Scaffold(body: ForgeSheet(shopId: 'hammersmith_forge')),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    container.read(playerSessionProvider);
    await _settle(tester);
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'dwarf',
          'professionId': 'warrior',
          'gold': 112,
          'inventoryItemIds': const [
            'material_iron_ore',
            'material_iron_ore',
            'material_iron_ore'
          ],
        })));
    await _settle(tester);

    Future<void> shot(String name) async {
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/forge-build-$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    await tester.tap(find.byKey(const ValueKey('forge_tab_Foot')));
    await tester.pump();
    await shot('1-feet');
    await tester.tap(find.byKey(const Key('forge_odds_toggle')));
    await tester.tap(find.byKey(const Key('forge_hint_button')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('forge_tab_Bottom')));
    await tester.pump();
    await shot('2-legs-odds');
    await tester.tap(find.byKey(const ValueKey('forge_tab_Foot')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('forge_odds_toggle')));
    await tester.tap(find.byKey(const Key('forge_hint_button')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('forge_go_boots_iron_shod')));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    for (final (name, ms) in const [
      ('3-strike', 300),
      ('4-lands', 1500),
      ('5-tier', 1000),
      ('6-piece', 1700),
    ]) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(Duration(milliseconds: ms));
      // The switch between beats fades over 200 ms: let it run.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await shot(name);
    }
    await tester.tap(find.byKey(const Key('forge_take_it')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  });
}
