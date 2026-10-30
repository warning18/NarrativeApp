// The Skills screen on a phone, in French (#651): the three tab names are
// whole (a word is never broken, nothing is cut) and every branch of the star
// chart keeps its count, at 412, 360 and 320 px, with one known skill and
// with twelve (a two-digit count on the middle tab). SMOKE_SHOTS=<folder>
// saves the pictures (qa_smoke_harness.dart).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/skills/skills_screen.dart';

import 'qa_smoke_harness.dart';

/// What is cut in the text under [finder]: more lines than it may take, or a
/// word wider than the line (the paragraph then breaks it in two). Told at the
/// end, not by an expect() inside the case (qa_smoke_harness.dart).
List<String> _cut(Finder finder, String what) {
  final found = <String>[];
  if (finder.evaluate().isEmpty) return ['$what: not on screen'];
  for (final element in finder.evaluate()) {
    final paragraph = element.findRenderObject()! as RenderParagraph;
    final text = paragraph.text.toPlainText().trim();
    if (paragraph.didExceedMaxLines) found.add('$what "$text": cut');
    // A text that stays on one line (a tab's does not wrap) must fit whole;
    // one that wraps must not break a word.
    final oneLine = !paragraph.softWrap || paragraph.maxLines == 1;
    for (final piece in oneLine ? [text] : text.split(RegExp(r'\s+'))) {
      final painter = TextPainter(
        text: TextSpan(text: piece, style: paragraph.text.style),
        textDirection: TextDirection.ltr,
      )..layout();
      if (painter.width > paragraph.size.width + 0.5) {
        found.add('$what "$text": "$piece" does not fit');
      }
    }
  }
  return found;
}

PlayerSession _warrior(List<String> known) => PlayerSession.fromJson({
      'raceId': 'human',
      'professionId': 'warrior',
      'level': 8,
      'skillEssence': 6,
      'unlockedSkillIds': known,
      'ownedDiceIds': ['starter_die'],
      'equippedDiceId': 'starter_die',
    });

const _twelve = [
  'warrior_shield_bash',
  'warrior_whirlwind',
  'warrior_iron_stance',
  'warrior_execute',
  'warrior_rally_cry',
  'warrior_bastion_charge',
  'warrior_writ_banner',
  'warrior_unbroken_stance',
  'warrior_reaping_whirl',
  'warrior_quarry_break',
  'warrior_last_watch_stand',
  'warrior_matriarch_reckoning',
];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  testWidgets('the tabs and the branch counts are whole, in French',
      (tester) async {
    final problems = <String>[];
    SmokeCase caseOf(String name, PlayerSession session) => SmokeCase(
          name,
          const SkillsScreen(),
          session: session,
          prepare: (container) async {
            for (final schema in [
              factionsSchema,
              subclansSchema,
              skillsSchema,
              skillTreesSchema,
            ]) {
              await container
                  .read(gameDbProvider(schema).notifier)
                  .whenLoaded();
            }
          },
          bare: true,
          act: (tester) async {
            final french = find
                .descendant(
                    of: find.byKey(const Key('skills_tab_mine')),
                    matching: find.byType(Text))
                .evaluate()
                .any((e) => (e.widget as Text).data!.contains('compétences'));
            if (!french) return;
            final width = tester.view.physicalSize.width.toInt();
            for (final key in const [
              'skills_tab_tree',
              'skills_tab_mine',
              'skills_tab_spells',
            ]) {
              problems.addAll(_cut(
                  find.descendant(
                      of: find.byKey(Key(key)), matching: find.byType(Text)),
                  '$name: $key at $width px'));
            }
            // A long name may give way (an ellipsis, its sheet is a tap
            // away); the count is the point of the line and stays whole.
            final counts = find.byWidgetPredicate((w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('star_count_'));
            problems.addAll(_cut(counts, '$name: branch count at $width px'));
            for (final e in counts.evaluate()) {
              final rect = tester.getRect(find.byWidget(e.widget));
              if (rect.right > width) {
                problems.add('$name: branch count at $width px is off screen');
              }
            }
          },
        );

    await runSmoke(
      tester,
      [
        caseOf('skills_fr_layout_1', _warrior(_twelve.take(1).toList())),
        caseOf('skills_fr_layout_12', _warrior(_twelve)),
      ],
      sizes: const [Size(412, 800), Size(360, 740), Size(320, 568)],
    );
    expect(problems, isEmpty);
  });
}
