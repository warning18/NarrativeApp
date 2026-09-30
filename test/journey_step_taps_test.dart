// The Journey map's steps take taps on their marks alone: a tap on a
// step's mark picks that step, whatever name lies near it, never a
// neighbour's (v1.186 had a step's whole label take its taps, so the
// step later in the list won). Checked on a 360-wide phone, at the alley
// with three ways out to the square (scene 270) and at the busy wharf
// (hub 2015), with nothing picked and with each step picked in turn.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _step(int i) => find.byKey(ValueKey('journey_step_$i'));

/// Whether step [i] is the one picked, as its mark tells it.
bool _picked(WidgetTester tester, int i) =>
    tester
        .widget<Semantics>(find
            .ancestor(
                of: _step(i),
                matching: find.byWidgetPredicate(
                    (w) => w is Semantics && (w.properties.button ?? false)))
            .first)
        .properties
        .selected ??
    false;

void main() {
  testWidgets('a tap on a step\'s mark picks that step, never a neighbour',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(
            {'raceId': 'human', 'professionId': 'warrior'})));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await _settle(tester);
    final play = container.read(storyPlayProvider.notifier);
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await _settle(tester);

    // Taps step [i]'s mark at its centre, the map scrolled to it first.
    Future<void> tapMark(int i) async {
      await tester.ensureVisible(_step(i));
      await tester.pump();
      final mark = tester.getRect(_step(i));
      // The tap is the mark's own, no wider.
      expect(mark.width, closeTo(44, 0.01), reason: 'step $i');
      expect(mark.height, closeTo(44, 0.01), reason: 'step $i');
      await tester.tapAt(mark.center);
      await tester.pump();
    }

    // What arriving somewhere opens over the game (a new place's card, a
    // chapter's notice) is closed.
    Future<void> clearCards() async {
      for (var i = 0; i < 3; i++) {
        Navigator.of(tester.element(find.byType(JourneyScreen)))
            .popUntil(isGameRoute);
        await tester.pump(const Duration(seconds: 1));
      }
    }

    for (final size in const [Size(360, 640), Size(360, 800)]) {
      tester.view.physicalSize = size;
      for (final id in ['270', '2015']) {
        play.jumpTo(id);
        await _settle(tester);
        // Past the map inking in (and a new chapter's burning open), and
        // the new place's card.
        await tester.pump(const Duration(seconds: 2));
        await clearCards();
        final count =
            List.generate(30, _step).takeWhile((f) => f.evaluate().isNotEmpty);
        final n = count.length;
        expect(n, greaterThanOrEqualTo(3), reason: id);
        // Each mark picks its own step: from nothing picked, and with every
        // other step picked (and named, its name near the others).
        for (var i = 0; i < n; i++) {
          await tapMark(i);
          expect(_picked(tester, i), isTrue, reason: '$id at $size: $i');
          for (var j = 0; j < n; j++) {
            if (j == i) continue;
            await tapMark(j);
            expect(_picked(tester, j), isTrue,
                reason: '$id at $size: $j after $i');
            expect(_picked(tester, i), isFalse,
                reason: '$id at $size: $j after $i');
            await tapMark(i);
            expect(_picked(tester, i), isTrue,
                reason: '$id at $size: $i after $j');
          }
        }
        // Picking never takes a step.
        expect(container.read(storyPlayProvider).currentNodeId, id);
        expect(tester.takeException(), isNull);
      }
    }

    // At the alley, a second tap on "Cut it free" frees the hound, with no
    // gold taken from its handler.
    tester.view.physicalSize = const Size(360, 640);
    play.jumpTo('270');
    await _settle(tester);
    await tester.pump(const Duration(seconds: 2));
    await clearCards();
    final gold = container.read(playerSessionProvider).gold;
    await tapMark(0);
    await tapMark(0);
    // The walk out of the alley, then the road to the square.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await _settle(tester);
    expect(container.read(storyPlayProvider).currentNodeId, '280');
    expect(container.read(playerSessionProvider).flags,
        contains('companion_hound'));
    expect(container.read(playerSessionProvider).gold, gold);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
