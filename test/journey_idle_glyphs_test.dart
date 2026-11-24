// The Journey chart's idle glyphs (Maps' perf review, perf-2.md): their
// 12-second clock runs only while a round mark that breathes is drawn and
// the chart is on screen, so a view of banner pins only, or the tab left,
// asks for no frames; each breathing glyph has its own layer, so a breath
// repaints the glyph, not the chart under it.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart'
    show debugJourneyIdleGlyphs;
import 'support/pump.dart';
import 'support/open_game.dart';

/// The breathing glyphs drawn: the builders on the 12-second clock.
final _breathing = find.byWidgetPredicate((w) =>
    w is AnimatedBuilder &&
    w.listenable is AnimationController &&
    (w.listenable as AnimationController).duration ==
        const Duration(seconds: 12));

void main() {
  testWidgets('the glyph clock runs only while a breathing mark is drawn',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(400, 860));
    final container = await openGame(tester, overrides: [storedCityPlans]);
    final play = container.read(storyPlayProvider.notifier);
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    final seen = <bool>{};
    for (final scene in [
      '1101',
      '1100',
      '1140',
      '2000',
      '2011',
      '2020',
      '1102'
    ]) {
      play.jumpTo(scene);
      await settleApp(tester);
      final drawn = _breathing.evaluate().isNotEmpty;
      seen.add(drawn);
      expect(debugJourneyIdleGlyphs.value, drawn ? 1 : 0,
          reason: 'scene $scene: glyphs drawn $drawn');
      if (drawn) {
        // Each breathing glyph sits on its own layer.
        for (final e in _breathing.evaluate()) {
          expect(
              find.ancestor(
                  of: find.byWidget(e.widget),
                  matching: find.byType(RepaintBoundary)),
              findsWidgets);
        }
      }
    }
    // Off the tab, nothing breathes.
    container.read(homeTabIndexProvider.notifier).state = 1;
    await settleApp(tester);
    expect(debugJourneyIdleGlyphs.value, 0);
    // Both cases met: scene 1140 has fights off the quests (round marks
    // that breathe), the prologue's ways are banners.
    expect(seen, {true, false});
    expect(tester.takeException(), isNull);
  });
}
