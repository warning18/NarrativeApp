// QA guard (the Tower's tarot cards, v2.3.0): the offer after a won floor, on
// a phone wide enough for the tall tarot cards (412 x 860, French, normal
// text), draws no overflow and is the tall layout: a card taller than wide,
// the words under the row, Take and Leave working. The rows (a narrow phone,
// big text) are guarded by qa_tower_ink_screens_test (320, 1.3x), and the 360
// English one by qa_tower_ink_360_test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';

import 'support/tower_playthrough.dart';

void main() {
  testWidgets('the Tower\'s tarot cards at 412, French', (tester) async {
    final play = await playTower(
      tester,
      size: const Size(412, 860),
      lang: AppLanguage.fr,
      maxFloors: 2,
      seed: 5,
      fightSeed: 7,
    );
    expect(play.overflows, isEmpty);
    expect(play.stuck, isEmpty);
    final cards = [
      for (final l in play.trace)
        if (l.startsWith('OFFER card')) l
    ];
    expect(cards, isNotEmpty, reason: 'no offer was shown');
    for (final c in cards) {
      final m = RegExp(r'(\d+)x(\d+)').firstMatch(c)!;
      expect(int.parse(m.group(2)!), greaterThan(int.parse(m.group(1)!)),
          reason: 'a tarot card is taller than wide at 412: $c');
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
