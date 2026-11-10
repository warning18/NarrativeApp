// QA guard for #891 (found by the 1.888.0 L3): on the smallest phone (320 x
// 568), in French, the fight's Roll, Reroll and Confirm buttons keep each
// label on one line; before v1.893 "Relancer (2)" and "Confirmer" broke in
// the middle of a word ("Relance / r (2)", "Confirm / er"). Real fonts (the
// test font is far wider): the bundled ones, as the player sees them.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart' show trFor;
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

import 'support/fonts.dart';
import 'support/pump.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The number of lines the text containing [words] is laid out on.
int _lines(WidgetTester tester, String words) {
  final finder = find.textContaining(words);
  expect(finder, findsOneWidget, reason: '"$words" is not on the screen');
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final length = paragraph.text.toPlainText().length;
  return paragraph
      .getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: length))
      .map((box) => box.top.round())
      .toSet()
      .length;
}

void main() {
  testWidgets('320 x 568, French: Roll, Reroll and Confirm are on one line',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await tester.runAsync(loadAppFonts);
    SharedPreferences.setMockInitialValues({'combat_dice_speed': 'quad'});
    usePhone(tester, const Size(320, 568));
    await tester.pumpWidget(ProviderScope(
        overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
        child: const MyApp()));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
          'maxHealth': 4000,
          'currentHealth': 4000,
        })));
    final thug = {
      ...(jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
          as Map<String, dynamic>)['slum_thug'] as Map<String, dynamic>,
      'maxHealth': 90000,
      'skillMoves': <dynamic>[],
    };
    tester.state<NavigatorState>(find.byType(Navigator).first).push(
        MaterialPageRoute<bool>(
            builder: (_) => FightScreen(enemyId: 'slum_thug', enemy: thug)));
    await _settle(tester);
    final enter = find.text(trFor(AppLanguage.fr, 'enter_battle_button'));
    await tester.ensureVisible(enter);
    await tester.pump();
    await tester.tap(enter);
    await _settle(tester);

    final roll = trFor(AppLanguage.fr, 'roll_dice_button');
    final reroll = trFor(AppLanguage.fr, 'reroll_button');
    final confirm = trFor(AppLanguage.fr, 'confirm_roll_button');
    expect(_lines(tester, roll), 1, reason: '"$roll" breaks over two lines');

    await tester.tap(find.textContaining(roll));
    for (var i = 0; i < 40 && find.text(confirm).evaluate().isEmpty; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _settle(tester);
    expect(_lines(tester, reroll), 1, reason: '"$reroll (n)" breaks');
    expect(_lines(tester, confirm), 1, reason: '"$confirm" breaks');
  });
}
