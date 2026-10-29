// Pictures of the built inventory (v1.594), drawn only with UX_SHOTS (a
// folder):
//   UX_SHOTS=docs/ux-shots flutter test test/ux_inventory_build_shots_test.dart
import 'dart:io';
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
import 'package:narrative_data_app/screens/inventory_screen.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

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
    test('the inventory pictures are drawn only with UX_SHOTS', () {});
    return;
  }

  Future<void> run(WidgetTester tester, double width, Brightness brightness,
      String suffix) async {
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({
      'inventory_seen': ['sword_001', 'helm_iron_cap', 'charm_fourth_roll'],
    });
    usePhone(tester, Size(width, 900));
    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(AppPalette.stitchedInk.schemeFor(brightness)),
          home: const InventoryScreen(),
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
          'raceId': 'human',
          'professionId': 'warrior',
          'inventoryItemIds': const [
            'sword_001',
            'helm_iron_cap',
            'charm_fourth_roll',
            'material_iron_ore',
            'material_iron_ore',
            'potion_minor',
            'tome_of_insight',
            'warden_signet',
            'armor_leather',
          ],
          'equippedItemIds': const ['sword_001', 'helm_iron_cap'],
          'ownedDiceIds': const [
            'starter_die',
            'iron_die',
            'bulwark_die',
            'arcane_die'
          ],
          'equippedDiceId': 'starter_die',
        })));
    await _settle(tester, n: 6);

    Future<void> shot(String name) async {
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/inventory-build-$name-$suffix.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    await shot('1-all');
    await tester.tap(find.byKey(const Key('inv_tab_gear')));
    await tester.pump();
    await shot('2-gear');
    await tester.ensureVisible(find.byKey(const Key('inv_tab_dice')));
    await tester.tap(find.byKey(const Key('inv_tab_dice')));
    await tester.pump();
    await shot('3-dice');
    await tester.ensureVisible(find.byKey(const Key('inv_tab_gear')));
    await tester.tap(find.byKey(const Key('inv_tab_gear')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('inv_row_warden_signet')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await shot('4-detail');
  }

  setUp(rootBundle.clear);

  testWidgets('the inventory at 412', (tester) async {
    await run(tester, 412, Brightness.light, '412');
  });
  testWidgets('the inventory at 320, dark', (tester) async {
    await run(tester, 320, Brightness.dark, '320-dark');
  });
}
