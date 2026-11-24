// QA: a player's run through the Tower in the real app, shared by the picture
// driver (qa_tower_playthrough_test, QA_PLAY) and the guard of the ink screens
// (qa_tower_ink_screens_test). Door, creation, floors with REAL fights,
// spoils, oaths and boons, Level Up, leaving, the end, the marks. The fights
// are played the naive way (Roll Dice, Confirm, a potion when hurt). It never
// edits lib/.
import 'dart:convert';
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
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/theme_mode_provider.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';

import 'fonts.dart';

/// What a run saw: the lines of its trace (STUCK and FINDING among them) and
/// the distinct "overflowed" errors.
class TowerPlay {
  TowerPlay(this.trace, this.overflows);
  final List<String> trace;
  final List<String> overflows;
  List<String> get stuck => [
        for (final l in trace)
          if (l.startsWith('STUCK')) l
      ];
}

Future<TowerPlay> playTower(
  WidgetTester tester, {
  String? out,
  Size size = const Size(412, 860),
  AppLanguage lang = AppLanguage.en,
  double textScale = 1.0,
  String race = 'human',
  String calling = 'warrior',
  int maxFloors = 8,
  int? seed,
  int? fightSeed,
}) async {
  String t(String key) => trFor(lang, key);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  await tester.runAsync(loadAppFonts);
  final initial = <String, Object>{
    'tutorial_enabled': false,
    'combat_dice_speed': 'quad',
    // A run begun in advance (seed 5): the same floors, foes and events on
    // every pass; the creation is skipped.
    if (seed != null)
      towerRunPrefsKey: jsonEncode(towerStart(
        seed: seed,
        raceId: race,
        professionId: calling,
        data: towerDataFromAssets(),
      ).toJson()),
  };
  SharedPreferences.setMockInitialValues(initial);
  // A second run in the same test finds the first one's saves: wipe them and
  // put the initial values back.
  await tester.runAsync(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    for (final e in initial.entries) {
      final v = e.value;
      if (v is bool) await prefs.setBool(e.key, v);
      if (v is String) await prefs.setString(e.key, v);
    }
  });
  addTearDown(tester.view.reset);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  if (out != null) Directory(out).createSync(recursive: true);
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
  await tester.pumpWidget(ProviderScope(overrides: [
    if (fightSeed != null)
      fightRandomProvider.overrideWithValue(() => Random(fightSeed)),
  ], child: RepaintBoundary(key: boundary, child: const MyApp())));
  Future<void> settle([int n = 6]) async {
    for (var i = 0; i < n; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  var shots = 0;
  Future<void> shot(String name) async {
    if (out == null) return;
    await tester.pump(const Duration(milliseconds: 300));
    final bytes = await tester.runAsync(() async {
      final object =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await object.toImage();
      return image.toByteData(format: ui.ImageByteFormat.png);
    });
    shots++;
    File('$out/${shots.toString().padLeft(2, '0')}-$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  List<String> texts([int n = 30]) => [
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

  Future<void> tapKey(String k) async {
    final f = find.byKey(Key(k));
    for (var i = 0; i < 30 && f.evaluate().isEmpty; i++) {
      final vertical = find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
      if (vertical.evaluate().isEmpty) break;
      await tester.drag(vertical.first, const Offset(0, -200));
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (f.evaluate().isEmpty) {
      note('STUCK: no "$k" on the screen. ${seen()}');
      throw StateError('no $k');
    }
    await tester.ensureVisible(f.first);
    final y = tester.getCenter(f.first).dy;
    if (y < size.height * 0.25 || y > size.height * 0.8) {
      final vertical = find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
      if (vertical.evaluate().isNotEmpty) {
        final dy = size.height * 0.35 - y;
        await tester.drag(vertical.first, Offset(0, dy));
        await tester.pump(const Duration(milliseconds: 200));
        if (f.evaluate().isEmpty) {
          // A small phone built the list around the new place: go back.
          await tester.drag(vertical.first, Offset(0, -dy));
          await tester.pump(const Duration(milliseconds: 200));
          await tester.ensureVisible(f.first);
        }
      }
    }
    await tester.tap(f.first);
    await settle();
  }

  bool has(String key) => find.byKey(Key(key)).evaluate().isNotEmpty;

  await settle(10);
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(
      () => container.read(appLanguageProvider.notifier).setLanguage(lang));
  await tester.runAsync(() =>
      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark));
  await settle(10);

  // --- the door and the creation ---
  await tester.ensureVisible(find.byKey(const Key('menu_tower')));
  await shot('main-menu');
  note('MENU ${seen()}');
  await tapKey('menu_tower');
  await shot('start-screen');
  note('START ${seen()}');
  if (seed != null) {
    await tapKey('tower_continue');
  } else {
    await tapKey('tower_climb');
    await shot('creation-race');
    note('CREATION race ${seen()}');
    await tapKey('choice_card_$race');
    await tapKey('rp_next');
    await shot('creation-calling');
    note('CREATION calling ${seen()}');
    await tapKey('choice_card_$calling');
    await shot('creation-ready');
    await tapKey('rp_start');
  }
  await settle(10);

  // --- the floors ---
  var floorsPlayed = 0;
  var swappedDie = false;
  var platesChecked = false;
  for (var step = 0; step < 400; step++) {
    if (has('tower_end_floor')) break;
    if (has('tower_fight')) {
      // The floors asked for are played: stop at the next floor's stand, so
      // the Level Up, the spoils and the offer of the last one are done first.
      if (floorsPlayed >= maxFloors) break;
      floorsPlayed++;
      final label = texts(8).join(' | ');
      note('FLOOR $floorsPlayed stand: $label');
      await shot('floor-$floorsPlayed-stand');
      // The "Your dice" panel: a die not looked at yet is opened and put in
      // play (once a run), and any dead end of the panel is a finding.
      final newDots = find.byWidgetPredicate((w) =>
          w.key is Key && (w.key as Key).toString().contains('tower_die_new_'));
      if (newDots.evaluate().isNotEmpty && !swappedDie) {
        final dotKey = '${newDots.evaluate().first.widget.key}';
        final id =
            RegExp('tower_die_new_([a-z_]+)').firstMatch(dotKey)?.group(1);
        note('PANEL new die "$id" on floor $floorsPlayed');
        if (id != null) {
          await tapKey('tower_die_$id');
          await shot('floor-$floorsPlayed-die-open');
          final roll = find.byKey(const Key('tower_die_roll'));
          if (roll.evaluate().isEmpty) {
            note('FINDING dice panel: no "Roll this die" after opening $id');
          } else if ((tester.widget(roll) as FilledButton).onPressed == null) {
            note('PANEL $id is already in play');
          } else {
            await tapKey('tower_die_roll');
            await shot('floor-$floorsPlayed-die-in-play');
            note('PANEL put $id in play');
            swappedDie = true;
          }
        }
      }
      // The Fight button waits while the last floor is still being put
      // away: give it real time, and say how long it took.
      var waited = 0;
      while (waited < 40 &&
          !(tester.widget(find.byKey(const Key('tower_fight')).first)
                  as ButtonStyleButton)
              .enabled) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 250)));
        await tester.pump(const Duration(milliseconds: 250));
        waited++;
      }
      if (waited > 0) {
        note(waited >= 40
            ? 'FINDING Fight button stayed disabled for 10 s on floor $floorsPlayed'
            : 'Fight button waited ${waited * 250} ms on floor $floorsPlayed');
      }
      await tapKey('tower_fight');
      await settle(10);
      if (floorsPlayed >= 6 && floorsPlayed <= 8) {
        note(
            'AFTER FIGHT TAP (floor $floorsPlayed): ${seen()} barriers=${find.byType(ModalBarrier).evaluate().length}');
      }
      // the fight
      final enter = find.text(t('enter_battle_button'));
      if (enter.evaluate().isNotEmpty) {
        await shot('floor-$floorsPlayed-prebattle');
        await tester.ensureVisible(enter);
        await tester.pump();
        await tester.tap(enter);
        await settle(10);
      }
      var shotRolled = false;
      var rounds = 0;
      for (var i = 0; i < 800; i++) {
        final back = find.text(t('victory_return_button'));
        if (back.evaluate().isNotEmpty) {
          // The Return button can wait (the chest, a clan's offer after a
          // boss): count how long the player must wait before it works.
          bool ready() {
            final b = find.ancestor(
                of: find.text(t('victory_return_button')),
                matching:
                    find.byWidgetPredicate((w) => w is ButtonStyleButton));
            return b.evaluate().isNotEmpty &&
                (b.evaluate().first.widget as ButtonStyleButton).enabled;
          }

          var waited = 0;
          for (; waited < 120 && !ready(); waited++) {
            await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 250)));
            await tester.pump(const Duration(milliseconds: 250));
          }
          await shot('floor-$floorsPlayed-won');
          note('FIGHT $floorsPlayed won in $rounds rounds; Return ready after '
              '${waited * 0.5} s (${ready() ? 'enabled' : 'NEVER ENABLED'}). ${seen()}');
          if (find.text(t('offer_take_button')).evaluate().isNotEmpty) {
            note(
                'FINDING a clans\' story offer shows after a Tower boss: ${seen()}');
            await shot('floor-$floorsPlayed-clan-offer');
          }
          if (ready()) {
            await tester.tap(back.first);
            var left = 0;
            for (;
                left < 160 &&
                    find.text(t('victory_return_button')).evaluate().isNotEmpty;
                left++) {
              await tester.runAsync(() =>
                  Future<void>.delayed(const Duration(milliseconds: 250)));
              await tester.pump(const Duration(milliseconds: 250));
              if (left == 8) await shot('floor-$floorsPlayed-after-return');
            }
            note('FIGHT $floorsPlayed: the screen left after ${left * 0.5} s '
                '(${find.text(t('victory_return_button')).evaluate().isEmpty ? 'left' : 'STILL ON THE FIGHT'}). ${seen()}');
            await settle(6);
          }
          break;
        }
        final faced = find.text(t('defeat_continue_button'));
        if (faced.evaluate().isNotEmpty) {
          await shot('floor-$floorsPlayed-lost');
          note('FIGHT $floorsPlayed lost in $rounds rounds. ${seen()}');
          await tester.tap(faced.first);
          await settle(10);
          break;
        }
        final confirm = find.text(t('confirm_roll_button'));
        final roll = find.textContaining(t('roll_dice_button'));
        if (confirm.evaluate().isNotEmpty) {
          if (!shotRolled) {
            await shot('floor-$floorsPlayed-rolled');
            shotRolled = true;
            if (!platesChecked) {
              platesChecked = true;
              // The lighter plates (v1.1009): no health numbers on them,
              // one tap on the hero's shows them.
              final numbers =
                  find.textContaining(RegExp(r'^\d+ / \d+$')).evaluate().length;
              if (numbers > 0) {
                note('FINDING plates: $numbers health numbers on the plates');
              }
              final plate = find.byWidgetPredicate((w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith('party_slot_'));
              if (plate.evaluate().length != 1) {
                note('FINDING plates: ${plate.evaluate().length} hero plates');
              } else {
                await tester.tap(plate);
                await settle(6);
                if (!has('tower_hero_sheet_hp')) {
                  note('FINDING plates: one tap on the hero shows no health');
                } else {
                  await shot('floor-$floorsPlayed-hero-sheet');
                  await tester.tapAt(const Offset(4, 4));
                  await settle(6);
                  if (has('tower_hero_sheet_hp')) {
                    note('FINDING plates: the hero sheet does not close');
                  }
                }
              }
            }
          }
          await tester.tap(confirm.first);
          rounds++;
        } else if (roll.evaluate().isNotEmpty) {
          // a potion when the health shows under half
          final hp = RegExp(r'^(\d+) ?/ ?(\d{2,})$');
          for (final e in find.byType(Text).evaluate()) {
            final m = hp.firstMatch((e.widget as Text).data ?? '');
            if (m != null &&
                int.parse(m.group(1)!) * 2 < int.parse(m.group(2)!)) {
              final potion = find.byIcon(Icons.local_drink);
              if (potion.evaluate().isNotEmpty) {
                await tester.tap(potion.first);
                await tester.pump(const Duration(milliseconds: 200));
              }
              break;
            }
          }
          final again = find.textContaining(t('roll_dice_button'));
          if (again.evaluate().isNotEmpty) await tester.tap(again.first);
        }
        await tester.pump(const Duration(milliseconds: 400));
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
      }
      continue;
    }
    if (find.byType(LevelUpScreen).evaluate().isNotEmpty) {
      await shot('level-up');
      note('LEVELUP ${seen()}');
      final take = find.text(t('stat_pick_take'));
      if (take.evaluate().isNotEmpty) {
        final card = find.byKey(const Key('stat_pick_offer_0'));
        if (card.evaluate().isNotEmpty) {
          await tester.tap(card.first);
          await settle();
        }
        await tester.ensureVisible(take);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(take);
        await settle(10);
        await shot('level-up-picked');
        note('LEVELUP picked: ${seen()}');
      }
      if (find.byType(LevelUpScreen).evaluate().isNotEmpty) {
        final cont = find.textContaining(RegExp('Continue|Continuer'));
        if (cont.evaluate().isEmpty) {
          note('FINDING level-up has no Continue button: only the back arrow');
        }
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await settle(10);
      }
      continue;
    }
    if (find.text(t('loot_sheet_changes')).evaluate().isNotEmpty) {
      await shot('spoils');
      note('SPOILS ${seen()}');
      await tester.tap(find.text(t('chest_take_button')));
      await settle(10);
      continue;
    }
    if (has('tower_take') || has('tower_refuse')) {
      await shot('offer');
      note('OFFER ${seen()}');
      await tapKey(has('tower_take') ? 'tower_take' : 'tower_refuse');
      await settle(10);
      continue;
    }
    // The events of a floor: talk to the warden, say no to a bargain, a
    // shortcut or a merchant, so each card is drawn once and the run goes on.
    var eventKey = '';
    for (final k in const [
      'tower_event_test',
      'tower_parley_talk',
      'tower_bargain_refuse',
      'tower_shortcut_decline',
      'tower_merchant_leave',
      'tower_continue',
    ]) {
      if (has(k)) {
        eventKey = k;
        break;
      }
    }
    if (eventKey.isNotEmpty) {
      await shot('event-${eventKey.replaceFirst('tower_', '')}');
      note('EVENT $eventKey ${seen()}');
      await tapKey(eventKey);
      await settle(10);
      continue;
    }
    note('STUCK at step $step: no known screen. ${seen()}');
    await shot('stuck');
    break;
  }

  // --- leaving, the end, the marks ---
  if (has('tower_leave')) {
    await tapKey('tower_leave');
    await tester.pump(const Duration(milliseconds: 400));
    await shot('leave-dialog');
    await tapKey('tower_leave_yes');
    await settle(10);
  }
  if (has('tower_end_floor')) {
    await shot('end-screen');
    note('END ${seen()}');
    await tapKey('tower_end_marks');
    await settle(10);
    await shot('marks');
    note('MARKS ${seen()}');
  } else {
    note('STUCK: no end screen. ${seen()}');
  }
  if (out != null) {
    File('$out/_trace.txt').writeAsStringSync('${trace.join('\n')}\n');
    File('$out/_overflow.txt').writeAsStringSync(
        overflows.isEmpty ? 'none\n' : '${overflows.toSet().join('\n')}\n');
  }
  return TowerPlay(trace, overflows.toSet().toList());
}
