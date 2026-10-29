// The Journey map's steps take taps on their marks alone: a tap on a
// step's mark picks that step, whatever name lies near it, never a
// neighbour's (v1.186 had a step's whole label take its taps, so the
// step later in the list won). Checked on a 360-wide phone, at the alley
// with three ways out to the square (scene 270) and at the busy wharf
// (hub 2015), with nothing picked and with each step picked in turn.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'support/pump.dart';
import 'support/open_game.dart';

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

/// A walk over the steps 0..n-1 that takes every ordered pair (a, b), a != b,
/// as consecutive entries exactly once (an Eulerian circuit of the complete
/// directed graph, by Hierholzer's algorithm).
List<int> _everyPair(int n) {
  final next = List<int>.generate(n, (_) => 0);
  int target(int a) {
    var b = next[a]++;
    if (b >= a) b++;
    return b;
  }

  final stack = <int>[0];
  final circuit = <int>[];
  while (stack.isNotEmpty) {
    final a = stack.last;
    if (next[a] < n - 1) {
      stack.add(target(a));
    } else {
      circuit.add(stack.removeLast());
    }
  }
  return circuit.reversed.toList();
}

void main() {
  testWidgets('a tap on a step\'s mark picks that step, never a neighbour',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(360, 640));

    final container = await openGame(tester, overrides: [noCityPlans]);
    final play = container.read(storyPlayProvider.notifier);
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await settleApp(tester);

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
      for (final id in ['1101', '2015']) {
        play.jumpTo(id);
        await settleApp(tester);
        // Past the map inking in (and a new chapter's burning open), and
        // the new place's card, and the road walked to it.
        await tester.pump(const Duration(seconds: 6));
        await clearCards();
        // The marks the map draws: a way acted out here is a card, so the
        // marks' own numbers have gaps.
        final marks = [
          for (var i = 0; i < 40; i++)
            if (_step(i).evaluate().isNotEmpty) i,
        ].take(8).toList();
        final n = marks.length;
        expect(n, greaterThanOrEqualTo(3), reason: id);
        // Each mark picks its own step: from nothing picked, and from every
        // other step picked (and named, its name near the others). One tap
        // chain walks every ordered pair (a, then b) exactly once.
        final chain = [for (final k in _everyPair(n)) marks[k]];
        await tapMark(chain.first);
        expect(_picked(tester, chain.first), isTrue,
            reason: '$id at $size: ${chain.first}');
        for (var k = 1; k < chain.length; k++) {
          final from = chain[k - 1], to = chain[k];
          await tapMark(to);
          expect(_picked(tester, to), isTrue,
              reason: '$id at $size: $to after $from');
          expect(_picked(tester, from), isFalse,
              reason: '$id at $size: $to after $from');
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
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 6));
    await clearCards();
    final gold = container.read(playerSessionProvider).gold;
    // A choice acted out here is a card in the scene view, not a mark on the
    // map.
    expect(_step(0), findsNothing);
    await tester.tap(find.byKey(const ValueKey('journey_open_choices')));
    await tester.pump(const Duration(milliseconds: 400));
    final card = find.byKey(const ValueKey('journey_choice_card_0'));
    await tester.tap(card);
    await tester.pump();
    await tester.tap(card);
    await tester.pump();
    // The story goes on, with no road to walk.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await settleApp(tester);
    expect(container.read(storyPlayProvider).currentNodeId, '300');
    expect(container.read(playerSessionProvider).gold, gold);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
