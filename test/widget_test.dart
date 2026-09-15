// Smoke test for the actual app. The previous version of this file was
// still Flutter's default counter-app template, testing a widget that
// hasn't existed in this project for a long time — it passed on every run
// regardless of whether the app itself still built or rendered.
//
// This pumps the real widget tree (ProviderScope > MyApp > HomeShell, which
// eagerly builds every tab via an IndexedStack) with SharedPreferences
// mocked to an empty store, and checks it renders its main chrome without
// throwing. It deliberately uses bounded pump()s rather than
// pumpAndSettle(), since the tree contains an unbounded Future.delayed
// animation trigger that pumpAndSettle would wait on forever.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app launches and renders its main navigation chrome',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // A handful of bounded pumps lets async providers (story data load,
    // player session load, etc.) settle one frame at a time without
    // waiting indefinitely on anything still pending.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
