// v2.2.2 (UX-2): in the Tower's fight the die's tag (name, dN, element) sits
// clear of the hint under the dice at 320 wide, French, text x1.3 (QA's
// picture on #1125), and at the usual size.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';

import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });

  for (final cfg in [
    (const Size(320, 568), AppLanguage.fr, 1.3),
    (const Size(360, 740), AppLanguage.en, 1.0),
  ]) {
    testWidgets('the die tag clears the hint: ${cfg.$1.width} ${cfg.$2.name}',
        (tester) async {
      await tester.runAsync(loadAppFonts);
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
      usePhone(tester, cfg.$1);
      tester.platformDispatcher.textScaleFactorTestValue = cfg.$3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      Future<void> settle([int n = 8]) async {
        for (var i = 0; i < n; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 40)));
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await settle(10);
      final c =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      await tester.runAsync(
          () => c.read(appLanguageProvider.notifier).setLanguage(cfg.$2));
      await settle(6);
      Future<void> tapKey(String k) async {
        final f = find.byKey(Key(k));
        await tester.ensureVisible(f.first);
        await tester.pump();
        await tester.tap(f.first);
        await settle(10);
      }

      await tapKey('menu_tower');
      await tapKey('tower_continue');
      await tapKey('tower_fight');
      await settle(12);
      if (find
          .text(trFor(cfg.$2, 'enter_battle_button'))
          .evaluate()
          .isNotEmpty) {
        await tester
            .ensureVisible(find.text(trFor(cfg.$2, 'enter_battle_button')));
        await tester.pump();
        await tester.tap(find.text(trFor(cfg.$2, 'enter_battle_button')));
        await settle(14);
      }
      final tag = find.byWidgetPredicate((w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('tower_die_tag_'));
      final hint = find.text(trFor(cfg.$2, 'roll_hint'));
      expect(tag, findsWidgets, reason: 'the tag shows before the roll');
      expect(hint, findsOneWidget);
      final t = tester.getRect(tag.first);
      final h = tester.getRect(hint);
      expect(t.bottom, lessThanOrEqualTo(h.top),
          reason: 'tag $t is above the hint $h');
      // Nor does any text of the die's own tile (its name, its face).
      for (final label in tester.widgetList<Text>(find.descendant(
          of: find.byWidgetPredicate((w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('die_tile_')),
          matching: find.byType(Text)))) {
        if ((label.data ?? '').isEmpty) continue;
        final r = tester.getRect(find.text(label.data!).first);
        expect(r.overlaps(h), isFalse,
            reason: '"${label.data}" $r overlaps the hint $h');
      }
      expect(tester.takeException(), isNull);
    });
  }
}
