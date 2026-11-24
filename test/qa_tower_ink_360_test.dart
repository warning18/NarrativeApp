// QA guard (the Tower in ink, v1.1004 to v2.0): a run of the real app through
// the Tower, on a small phone, draws no overflow and never gets stuck: the
// door, the creation, the floors with their events and real fights, the
// lighter plates (no health numbers, one tap on the hero shows them), spoils,
// Level Up, leaving and the end. 360 x 740 English at normal text (the 320 French one is in
// qa_tower_ink_screens_test); one phone to a file, since the Tower's saves
// outlive a run inside one test. Pictures and traces: `QA_PLAY=<folder> flutter test
// test/qa_tower_playthrough_test.dart` (QA_PLAY_CFG=320x568:fr:1.3).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';

import 'support/tower_playthrough.dart';

void main() {
  testWidgets('the Tower in ink on a small phone', (tester) async {
    final play = await playTower(
      tester,
      size: const Size(360, 740),
      lang: AppLanguage.en,
      textScale: 1.0,
      maxFloors: 1,
      seed: 5,
      fightSeed: 7,
    );
    expect(play.overflows, isEmpty);
    expect(play.stuck, isEmpty);
    expect([
      for (final l in play.trace)
        if (l.contains('FINDING plates')) l
    ], isEmpty);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
