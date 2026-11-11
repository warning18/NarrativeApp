// QA: a player's first minutes in the main story, in the real app (New Game,
// creation, the intro, the Blind Beggar's casino with its first fight, up to
// the way out to the streets), dark theme, 412 x 860, English. Only with
// QA_PLAY=<folder>: a picture of each stage, `_trace.txt` (the scene reached,
// what the player sees and can press, every place it is stuck) and
// `_overflow.txt`. The fights are played the naive way. It never edits lib/.
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
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/providers/theme_mode_provider.dart';
import 'package:narrative_data_app/widgets/choice_card.dart' show ChoiceCard;

import 'support/fonts.dart';

void main() {
  final out = Platform.environment['QA_PLAY'];
  if (out == null || out.isEmpty) {
    test('the chapter 1 playthrough runs only with QA_PLAY', () {});
    return;
  }

  testWidgets('a player starts the story', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await tester.runAsync(loadAppFonts);
    SharedPreferences.setMockInitialValues({
      'combat_dice_speed': 'quad',
    });
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 860);
    Directory(out).createSync(recursive: true);
    final trace = <String>[];
    void note(String text) {
      trace.add(text);
      debugPrint('PLAY $text');
    }

    final overflows = <String>[];
    final previousHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflows.add(details.exceptionAsString().split('\n').first);
      } else {
        previousHandler?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = previousHandler);

    final boundary = GlobalKey();
    await tester.pumpWidget(ProviderScope(
        child: RepaintBoundary(key: boundary, child: const MyApp())));
    Future<void> settle([int n = 6]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    var shots = 0;
    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 300));
      final bytes = await tester.runAsync(() async {
        final object = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await object.toImage();
        return image.toByteData(format: ui.ImageByteFormat.png);
      });
      shots++;
      File('$out/${shots.toString().padLeft(2, '0')}-$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    }

    List<String> texts([int n = 26]) => [
          for (final e in find.byType(Text).evaluate())
            if ((e.widget as Text).data case final String t when t.isNotEmpty) t
        ].take(n).toList();
    List<String> buttons() => [
          for (final e in find.byType(ButtonStyleButton).evaluate())
            if ((e.widget as ButtonStyleButton).enabled)
              find
                  .descendant(
                      of: find.byWidget(e.widget), matching: find.byType(Text))
                  .evaluate()
                  .map((t) => (t.widget as Text).data)
                  .join('/')
        ];
    String seen() => 'TEXT ${texts().join(' | ')} || BUTTONS ${buttons()}';
    bool has(String key) =>
        find.byKey(ValueKey(key)).evaluate().isNotEmpty ||
        find.byKey(Key(key)).evaluate().isNotEmpty;
    Finder k(String key) =>
        has(key) && find.byKey(ValueKey(key)).evaluate().isNotEmpty
            ? find.byKey(ValueKey(key))
            : find.byKey(Key(key));

    await settle(10);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.runAsync(() => container
        .read(themeModeProvider.notifier)
        .setThemeMode(ThemeMode.dark));
    await settle(10);
    String node() => container.read(storyPlayProvider).currentNodeId;

    await shot('main-menu');
    note('MENU ${seen()}');
    await tester.tap(k('menu_new_game'));
    await settle(10);
    await shot('after-new-game');
    note('AFTER NEW GAME ${seen()}');

    var lastNode = '';
    var stale = 0;
    var fights = 0;
    var seenCasino = false;
    final picks = <String>[];
    for (var step = 0; step < 220; step++) {
      final here = node();
      if (here != lastNode) {
        note('SCENE $here (step $step)');
        lastNode = here;
        stale = 0;
        if (here == '125') seenCasino = true;
      } else {
        stale++;
      }
      if (here == '250') {
        await shot('reached-250');
        note('REACHED 250: the way out to the streets. ${seen()}');
        break;
      }
      // the spoils: open the chest (Take all), then the sheet's Take
      if (find.text('What the spoils change').evaluate().isNotEmpty) {
        await shot('spoils-sheet');
        note('SPOILS SHEET: ${seen()}');
        final t = find.widgetWithText(FilledButton, 'Take');
        if (t.evaluate().isNotEmpty) {
          await tester.tap(t.last);
        } else {
          await tester.tap(find.text('Take').last);
        }
        await settle(10);
        continue;
      }
      if (find.text('Take all').evaluate().isNotEmpty) {
        await shot('spoils-chest');
        await tester.tap(find.text('Take all'));
        await settle(10);
        continue;
      }
      // a first-time tip card ("New: Spoils chest" ... Later / OK)
      if (find.text('OK').evaluate().isNotEmpty &&
          (find.textContaining('New:').evaluate().isNotEmpty ||
              find.text('Later').evaluate().isNotEmpty)) {
        await shot('tip-$here');
        note('TIP at $here: ${seen()}');
        await tester.tap(find.text('OK').first);
        await settle(8);
        continue;
      }
      // a dialog (the creation's "start with this character?", a sheet)
      final dialog = find.byType(AlertDialog);
      if (dialog.evaluate().isNotEmpty) {
        await shot('dialog-$here');
        note('DIALOG at $here: ${seen()}');
        final tf =
            find.descendant(of: dialog, matching: find.byType(TextField));
        if (tf.evaluate().isNotEmpty) {
          await tester.enterText(tf.first, 'Mara');
          await tester.pump();
        }
        final confirmBtn =
            find.descendant(of: dialog, matching: find.byType(FilledButton));
        if (confirmBtn.evaluate().isNotEmpty) {
          await tester.tap(confirmBtn.last);
        } else {
          final any =
              find.descendant(of: dialog, matching: find.byType(TextButton));
          await tester.tap(any.last);
        }
        await settle(12);
        continue;
      }
      // a fight
      if (find.text('Enter Battle').evaluate().isNotEmpty ||
          find.textContaining('Roll Dice').evaluate().isNotEmpty ||
          find.text('Confirm').evaluate().isNotEmpty ||
          find.text('Victory! Return').evaluate().isNotEmpty ||
          find.text('Face what comes').evaluate().isNotEmpty ||
          find.text('Retreat').evaluate().isNotEmpty) {
        final enter = find.text('Enter Battle');
        if (enter.evaluate().isNotEmpty) {
          fights++;
          await shot('fight-$fights-prebattle');
          note('FIGHT $fights: ${seen()}');
          await tester.ensureVisible(enter);
          await tester.pump();
          await tester.tap(enter);
          await settle(10);
          continue;
        }
        final back = find.text('Victory! Return');
        final lost = find.text('Face what comes');
        if (back.evaluate().isNotEmpty) {
          await shot('fight-$fights-won');
          note('FIGHT $fights won. ${seen()}');
          var ok = false;
          for (var i = 0; i < 80; i++) {
            final b = find.ancestor(
                of: back,
                matching:
                    find.byWidgetPredicate((w) => w is ButtonStyleButton));
            if (b.evaluate().isNotEmpty &&
                (b.evaluate().first.widget as ButtonStyleButton).enabled) {
              ok = true;
              break;
            }
            await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 250)));
            await tester.pump(const Duration(milliseconds: 250));
          }
          if (!ok) note('STUCK: Victory! Return never enabled. ${seen()}');
          await tester.tap(back.first);
          await settle(12);
          continue;
        }
        if (lost.evaluate().isNotEmpty) {
          note('FIGHT $fights lost: ${seen()}');
          await tester.tap(lost.first);
          await settle(12);
          continue;
        }
        final confirm = find.text('Confirm');
        final roll = find.textContaining('Roll Dice');
        if (confirm.evaluate().isNotEmpty) {
          await tester.tap(confirm.first);
        } else if (roll.evaluate().isNotEmpty) {
          await tester.tap(roll.first);
        }
        await tester.pump(const Duration(milliseconds: 400));
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        continue;
      }
      // the intro
      if (has('intro_tap')) {
        await shot('intro');
        await tester.tap(k('intro_tap'));
        await settle(8);
        continue;
      }
      // origin memories
      if (has('origin_random_all')) {
        await shot('origin-intro');
        await tester.tap(k('origin_random_all'));
        await settle(10);
        continue;
      }
      if (has('origin_random_again')) {
        await shot('origin-summary');
        note('ORIGIN SUMMARY ${seen()}');
        final fb = find.byWidgetPredicate((w) => w is FilledButton);
        if (fb.evaluate().isEmpty) {
          await tester.drag(
              find.byType(Scrollable).last, const Offset(0, -600));
          await settle(4);
          if (stale++ > 30) {
            note('ORIGIN SUMMARY: no begin button: ${seen()}');
            break;
          }
          continue;
        }
        await tester.ensureVisible(fb.last);
        await tester.pump();
        await tester.tap(fb.last);
        await settle(14);
        continue;
      }
      // the character sheet after creation: Continue (below the fold)
      if (!has('rp_start') &&
          here == '0' &&
          find.text('Human · Warrior').evaluate().isNotEmpty) {
        final c = find.widgetWithText(FilledButton, 'Continue');
        if (c.evaluate().isEmpty) {
          final sc = find.byType(Scrollable).evaluate().isEmpty
              ? null
              : find.byType(Scrollable).last;
          if (sc != null) await tester.drag(sc, const Offset(0, -500));
          await settle(4);
          continue;
        }
        await shot('character-sheet');
        await tester.ensureVisible(c);
        await tester.pump();
        await tester.tap(c);
        await settle(10);
        continue;
      }
      // the creation
      if (has('rp_start') || has('rp_next') || has('choice_card_human')) {
        if (has('rp_start') &&
            (tester.widget(k('rp_start')) as FilledButton).onPressed != null) {
          if (stale == 0) {
            await shot('creation-ready');
            note('CREATION ready: ${seen()}');
          }
          await tester.ensureVisible(k('rp_start'));
          await tester.pump();
          await tester.tap(find.text('Start New Game With This Character'));
          await settle(14);
          note(
              'after start: node ${node()} ${has('rp_start') ? 'STILL ON CREATION' : 'left'} dialogs=${find.byType(AlertDialog).evaluate().length} routes=${find.byType(ModalBarrier).evaluate().length} text=${seen()}');
          if (stale > 4 && find.byType(AlertDialog).evaluate().isEmpty) {
            note('STUCK: the start button does nothing. ${seen()}');
            break;
          }
          stale++;
          continue;
        }
        if (has('rp_next') &&
            (tester.widget(k('rp_next')) as FilledButton).onPressed != null) {
          await shot('creation-race-picked');
          await tester.tap(k('rp_next'));
          await settle(8);
          continue;
        }
        final warrior = find.byKey(const Key('choice_card_warrior'));
        final human = find.byKey(const Key('choice_card_human'));
        if (has('rp_next') && warrior.evaluate().isNotEmpty) {
          await tester.tap(warrior.first);
          await settle(6);
          continue;
        }
        if (human.evaluate().isNotEmpty) {
          await shot('creation-race');
          await tester.ensureVisible(human.first);
          await tester.tap(human.first);
          await settle(6);
          continue;
        }
      }
      // a name to give, a confirm dialog
      final textField = find.byType(TextField);
      if (textField.evaluate().isNotEmpty) {
        await shot('name-prompt');
        note('NAME PROMPT ${seen()}');
        await tester.enterText(textField.first, 'Mara');
        await settle();
        final ok = find.byType(FilledButton);
        if (ok.evaluate().isNotEmpty) {
          await tester.tap(ok.last);
          await settle(8);
          continue;
        }
      }
      // the journey: read, go, continue, choose
      if (find
              .textContaining('Your camp is set up on the shore')
              .evaluate()
              .isNotEmpty &&
          find.text('Journey').evaluate().isNotEmpty) {
        note('NOT ON JOURNEY at $here: switching back. ${seen()}');
        await tester.tap(find.text('Journey').last);
        await settle(8);
        continue;
      }
      if (stale > 8 && stale % 8 == 1) {
        await shot('slow-$here-$stale');
        note('SLOW at $here (stale $stale): ${seen()}');
      }
      if (stale > 30) {
        note(
            'STUCK at $here: Go/Continue taps do not move the story. ${seen()}');
        break;
      }
      if (!has('journey_continue')) {
        // the map: tap a step, then Go. First the fight, then the others
        final stepKeys = find.byWidgetPredicate((w) =>
            w.key is ValueKey &&
            '${(w.key as ValueKey).value}'.startsWith('journey_step_'));
        final goOn = has('journey_go') &&
            (tester.widget(k('journey_go')) as ButtonStyleButton).enabled;
        if (stepKeys.evaluate().isNotEmpty && !goOn) {
          final n = stepKeys.evaluate().length;
          await shot('map-before-pick');
          note(
              'MAP has $n steps; picking #${picks.length % n} at $here: ${seen()}');
          await tester.tap(
              stepKeys.at((here == '106' || here == '110') ? n - 1 : 0),
              warnIfMissed: false);
          await settle(8);
          final now = has('journey_go') &&
              (tester.widget(k('journey_go')) as ButtonStyleButton).enabled;
          await shot('map-selected');
          note('MAP selected go=$now: ${seen()}');
          if (!now) stale++;
          continue;
        }
      }
      if (has('journey_go')) {
        final go = k('journey_go');
        final enabled = (tester.widget(go) as ButtonStyleButton).enabled;
        if (enabled) {
          if (stale == 0) await shot('journey-go');
          await tester.tap(go.first);
          await settle(10);
          continue;
        }
      }
      if (has('journey_continue')) {
        await tester.tap(k('journey_continue').first);
        await settle(8);
        continue;
      }
      final cards = find.byType(ChoiceCard);
      if (cards.evaluate().isNotEmpty) {
        if (stale == 0) await shot('cards-$here');
        note('CHOICES at $here: ${seen()}');
        await tester.tap(cards.first);
        await settle(10);
        continue;
      }
      if (has('journey_open_choices')) {
        await tester.tap(k('journey_open_choices').first);
        await settle(8);
        continue;
      }
      if (has('journey_read')) {
        if (stale == 0) await shot('map-$here');
        await tester.tap(k('journey_read').first);
        await settle(8);
        continue;
      }
      if (stale > 12) {
        note('STUCK at $here (step $step): ${seen()}');
        await shot('stuck-$here');
        break;
      }
      await tester.pump(const Duration(milliseconds: 500));
      await settle(4);
    }
    note('DONE fights=$fights casino125=$seenCasino node=${node()}');
    File('$out/_trace.txt').writeAsStringSync('${trace.join('\n')}\n');
    File('$out/_overflow.txt').writeAsStringSync(
        overflows.isEmpty ? 'none\n' : '${overflows.toSet().join('\n')}\n');
  }, timeout: const Timeout(Duration(minutes: 30)));
}
