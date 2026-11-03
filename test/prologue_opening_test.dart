// The opening scene as an animation (version A, "La voix"): the text is
// told a sentence at a time with its bold phrases kept, a tap finishes the
// sentence and a second tap jumps to the end, reduced motion shows it all at
// once, and the Grey Shroud's sigil rises behind the text's end and fades
// out as the choice settles.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/prologue_opening.dart';

const _text = 'Toute histoire ment. **Celle-ci demande d’abord.** Avant le '
    'vacarme, une question ?\n\nJe roule **un vieux dé d’os**. Il se porte.';

Widget _app({bool reduced = false, VoidCallback? onGo}) => ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: PrologueOpening(
                text: _text,
                choices: ElevatedButton(
                    key: const Key('go'),
                    onPressed: onGo ?? () {},
                    child: const Text('Choisissez qui vous êtes…')),
              ),
            ),
          ),
        ),
      ),
    );

double _opacity(WidgetTester tester, String key) =>
    tester.widget<Opacity>(find.byKey(Key(key))).opacity;

void main() {
  group('the text cut into sentences', () {
    test('each sentence knows its bold characters and its paragraph', () {
      final s = prologueSentences(_text);
      expect(s.map((e) => e.text), [
        'Toute histoire ment.',
        'Celle-ci demande d’abord.',
        'Avant le vacarme, une question ?',
        'Je roule un vieux dé d’os.',
        'Il se porte.',
      ]);
      expect(s.map((e) => e.opensParagraph), [true, false, false, true, false]);
      expect(s[1].runs().every((r) => r.bold), isTrue);
      final bold = s[3].runs().where((r) => r.bold).map((r) => r.text);
      expect(bold, ['un vieux dé d’os']);
    });

    test('the real opening keeps its three bold phrases, in French and English',
        () {
      final node = (jsonDecode(
              File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>)['0'] as Map<String, dynamic>;
      final fr = prologueSentences(node['description_fr'] as String);
      final bold = {
        for (final s in fr)
          for (final r in s.runs())
            if (r.bold) r.text,
      };
      expect(bold, containsAll(['un vieux dé d’os']));
      expect(bold.any((b) => b.contains('le pouvoir ne se tient pas')), isTrue);
      expect(prologueSentences(node['description'] as String), isNotEmpty);
    });

    test('a sentence is told word by word', () {
      final s = prologueSentences('Un vieux dé d’os roule.').single;
      expect(prologueWordsShown(s, 0), 0);
      expect(s.text.substring(0, prologueWordsShown(s, 0.3)).endsWith(' '),
          isTrue);
      expect(prologueWordsShown(s, 1), s.length);
    });
  });

  testWidgets('the text arrives a sentence at a time; the choice waits',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('prologue_sentence_0')), findsOneWidget);
    expect(find.byKey(const Key('prologue_sentence_4')), findsNothing);
    expect(_opacity(tester, 'prologue_choices'), 0);
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const Key('prologue_sentence_1')), findsOneWidget);
    expect(find.byKey(const Key('prologue_sentence_4')), findsNothing);
    // The choice is not reachable before the end.
    await tester.tap(find.byKey(const Key('go')), warnIfMissed: false);
    expect(find.byKey(const Key('prologue_sentence_4')), findsNothing);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('a tap finishes the sentence, a second tap jumps to the end',
      (tester) async {
    var went = 0;
    await tester.pumpWidget(_app(onGo: () => went++));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('prologue_sentence_1')), findsNothing);
    await tester.tap(find.byKey(const Key('prologue_text')));
    await tester.pump(const Duration(milliseconds: 100));
    // The first sentence is whole (no unseen tail) and nothing is skipped.
    final first =
        tester.widget<Text>(find.byKey(const Key('prologue_sentence_0')));
    expect(first.textSpan!.toPlainText(), 'Toute histoire ment.');
    expect(find.byKey(const Key('prologue_sentence_4')), findsNothing);
    expect(_opacity(tester, 'prologue_choices'), 0);
    // A second tap soon after: the end, and the choice settles in.
    await tester.tap(find.byKey(const Key('prologue_text')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('prologue_sentence_4')), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(_opacity(tester, 'prologue_choices'), 1);
    await tester.tap(find.byKey(const Key('go')));
    expect(went, 1);
  });

  testWidgets('reduced motion: all the text at once, the sigil still',
      (tester) async {
    var went = 0;
    await tester.pumpWidget(_app(reduced: true, onGo: () => went++));
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      final sentence =
          tester.widget<Text>(find.byKey(Key('prologue_sentence_$i')));
      // Nothing is held back as an unseen tail.
      expect(sentence.textSpan!.toPlainText(), isNot(isEmpty));
      expect(_opacity(tester, 'prologue_choices'), 1);
    }
    expect(_opacity(tester, 'prologue_sigil'), prologueSigilStill);
    await tester.tap(find.byKey(const Key('go')));
    expect(went, 1);
  });

  testWidgets(
      'the sigil rises as the text ends and fades as the choice settles',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 100));
    expect(_opacity(tester, 'prologue_sigil'), closeTo(0, 1e-9));
    // Jump to the end of the text (two taps), then watch the settle.
    await tester.tap(find.byKey(const Key('prologue_text')));
    await tester.tap(find.byKey(const Key('prologue_text')));
    await tester.pump(const Duration(milliseconds: 100));
    final atEnd = _opacity(tester, 'prologue_sigil');
    expect(atEnd, inInclusiveRange(prologueSigilPeak * 0.9, prologueSigilPeak));
    expect(atEnd, lessThanOrEqualTo(0.15));
    expect(atEnd, greaterThanOrEqualTo(0.08));
    await tester.pump(const Duration(seconds: 3));
    expect(_opacity(tester, 'prologue_sigil'), closeTo(0, 1e-9));
  });
}
