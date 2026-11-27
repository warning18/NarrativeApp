// The Tower's lighter nameplates (v1.1009): in a Tower fight a fighter's plate
// holds its name and a thin health bar (no numbers on it); the hero's numbers,
// armour, damage and status marks are one tap away, in its sheet. A guard: the
// information must stay reachable.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';

void main() {
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });

  testWidgets(
      'the plate bars carry the health numbers; the hero sheet does too',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    final run = towerStart(
        seed: 5,
        raceId: 'human',
        professionId: 'warrior',
        data: towerDataFromAssets());
    SharedPreferences.setMockInitialValues({
      towerRunPrefsKey: jsonEncode(run.toJson()),
      'tutorial_enabled': false,
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 860);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    Future<void> settle([int n = 8]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> tapKey(String k) async {
      final f = find.byKey(Key(k));
      await tester.ensureVisible(f.first);
      await tester.pump();
      await tester.tap(f.first);
      await settle(10);
    }

    await settle(10);
    await tapKey('menu_tower');
    await tapKey('tower_continue');
    await tapKey('tower_fight');
    final enter = find.text('Enter Battle');
    await tester.ensureVisible(enter);
    await tester.pump();
    await tester.tap(enter);
    await settle(14);

    // The plates: names and bars with "29 / 29" inside them (v2.10.43).
    expect(find.textContaining(RegExp(r'^\d+ / \d+$')), findsWidgets);
    final plate = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('party_slot_'));
    expect(plate, findsOneWidget);

    // One tap: the hero's sheet, with the numbers.
    await tester.tap(plate);
    await settle(6);
    expect(find.byKey(const Key('tower_hero_sheet_hp')), findsOneWidget);
    expect(
        tester.widget<Text>(find.byKey(const Key('tower_hero_sheet_hp'))).data,
        matches(RegExp(r'^\d+ / \d+$')));
  });
}
