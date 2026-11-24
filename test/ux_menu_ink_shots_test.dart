// The home menu in ink (v1.1009): the real app's menu, 360 and 320 wide
// (UX_SHOTS=<folder>). Pictures only.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/main.dart';

import 'support/fonts.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(rootBundle.clear);

  Future<void> shoot(WidgetTester tester, GlobalKey key, String name) async {
    await tester.runAsync(() async {
      final render =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> show(WidgetTester tester, String name, double width, Widget app,
      {Map<String, Object> prefs = const {}, double height = 780}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final key = GlobalKey();
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
        RepaintBoundary(key: key, child: ProviderScope(child: app)));
    await settle(tester);
    expect(tester.takeException(), isNull, reason: name);
    await shoot(tester, key, name);
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('the home menu in ink', skip: shots == null, (tester) async {
    await tester.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await show(tester, 'menu-360', 360, const MyApp(), height: 800);
    await show(tester, 'menu-320', 320, const MyApp(), height: 800);
    await show(tester, 'menu-short-360', 360, const MyApp(), height: 640);
  });
}
