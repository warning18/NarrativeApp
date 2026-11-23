// The map-theme dropdown of Settings in French at 1.3x text, 320 wide
// (UX_SHOTS=<folder>), scrolled into view. Picture only.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/settings_screen.dart';

import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  testWidgets('settings dropdown, French 1.3x', skip: shots == null,
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await tester.runAsync(loadAppFonts);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final key = GlobalKey();
    await tester.pumpWidget(
        RepaintBoundary(key: key, child: const ProviderScope(child: MyApp())));
    await settleApp(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await settleApp(tester);
    final c =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(
        () => c.read(appLanguageProvider.notifier).setLanguage(AppLanguage.fr));
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    await settleApp(tester);
    final dropdown = find.byWidgetPredicate(
        (w) => w.runtimeType.toString().startsWith('DropdownButtonFormField'));
    await tester.scrollUntilVisible(dropdown, 300,
        scrollable: find.byType(Scrollable).first);
    await settleApp(tester);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final render =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(shots!).createSync(recursive: true);
      File('$shots/settings-dropdown-320-fr-1.3.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
