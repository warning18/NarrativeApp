// The story text's markup and names (docs/proposals/story-markup.md):
// **bold**, blank lines, names found by the game, and what the real tables
// give.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/story_markup.dart';
import 'package:narrative_data_app/data/story_names.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

List<StoryRun> _first(String text, {StoryNameMatcher? names}) =>
    parseStoryText(text, names: names).first;

void main() {
  test('bold: a pair is bold, anything else stays as typed', () {
    expect(_first('He owed **forty crowns** by dawn.'), [
      const StoryRun('He owed '),
      const StoryRun('forty crowns', bold: true),
      const StoryRun(' by dawn.'),
    ]);
    // Unclosed, empty, or padded: shown as typed.
    expect(
        _first('A **loose sign.').map((r) => r.text).join(), 'A **loose sign.');
    expect(
        _first('Two **** signs.').map((r) => r.text).join(), 'Two **** signs.');
    expect(_first('A ** padded ** pair.').map((r) => r.text).join(),
        'A ** padded ** pair.');
    // Two in a paragraph, and one cannot span a paragraph.
    final two = _first('**One** and **two**.');
    expect(two.where((r) => r.bold).map((r) => r.text), ['One', 'two']);
    final apart = parseStoryText('A **open\n\nclosed** B');
    expect(apart, hasLength(2));
    expect(apart.expand((p) => p).any((r) => r.bold), isFalse);
  });

  test('paragraphs: a blank line splits, a single break stays', () {
    final text = 'First paragraph.\n\nSecond,\nwith a break.\n \n\n  Third.  ';
    final paragraphs = parseStoryText(text);
    expect(paragraphs.map((p) => p.map((r) => r.text).join()),
        ['First paragraph.', 'Second,\nwith a break.', 'Third.']);
    expect(parseStoryText('  \n\n '), isEmpty);
  });

  test('names: whole words, longest first, either apostrophe, in bold too', () {
    final names = StoryNameMatcher({
      'Aurel Vane': StoryNameKind.person,
      'Vane': StoryNameKind.person,
      'Alster': StoryNameKind.place,
      "Wrack's End": StoryNameKind.place,
      'Lantern Dominion': StoryNameKind.clan,
    });
    final runs = _first(
        'Aurel Vane left Alster; Vane’s men held Wrack’s End for the Lantern Dominion. Alsterfield stays plain. **Alster** burns.',
        names: names);
    Iterable<String> of(StoryNameKind k) =>
        runs.where((r) => r.kind == k).map((r) => r.text);
    expect(of(StoryNameKind.person), ['Aurel Vane', 'Vane']);
    expect(of(StoryNameKind.place), ['Alster', 'Wrack’s End', 'Alster']);
    expect(of(StoryNameKind.clan), ['Lantern Dominion']);
    // "Alsterfield" is not Alster, and a bold name is both.
    expect(runs.any((r) => r.text.contains('Alsterfield') && r.kind != null),
        isFalse);
    final boldName = runs.where((r) => r.bold).single;
    expect(boldName.text, 'Alster');
    expect(boldName.kind, StoryNameKind.place);
    // The words are all there, in order.
    expect(
        runs.map((r) => r.text).join(),
        stripStoryMarkup(
            'Aurel Vane left Alster; Vane’s men held Wrack’s End for the Lantern Dominion. Alsterfield stays plain. **Alster** burns.'));
  });

  test('quotes are italic; an unmarked text bolds its first sentence', () {
    final runs = parseStoryText('Rain fell. He said "stay close to me" twice.',
            firstSentenceBold: true)
        .first;
    expect(runs.first, const StoryRun('Rain fell. ', bold: true));
    expect(runs.where((r) => r.italic).single.text, '"stay close to me"');
    // Once a text is marked, nothing is bold but what is marked.
    final marked =
        parseStoryText('Rain **fell**. Then more.', firstSentenceBold: true)
            .first;
    expect(marked.where((r) => r.bold).map((r) => r.text), ['fell']);
  });

  test('stripping gives the words as written, for the voice and the journal',
      () {
    expect(stripStoryMarkup('He owed **forty crowns** and **a life**.'),
        'He owed forty crowns and a life.');
    expect(stripStoryMarkup('A ** padded ** pair and a **loose one.'),
        'A ** padded ** pair and a **loose one.');
    expect(stripStoryMarkup('No markup.'), 'No markup.');
  });

  test('the names in the real tables, in English and in French', () {
    final geography = Geography.parse(
        geography: _table('geography'), biomes: _table('biomes'));
    StoryNameMatcher build(bool french) => buildStoryNames(
          npcs: _table('npcs'),
          companions: _table('companions'),
          factions: _table('factions'),
          subclans: _table('subclans'),
          geography: geography,
          french: french,
        );
    final en = build(false);
    final runs = _first(
        'Aurel Vane watched Saltmouth for the Lantern Dominion, the Inquisition, the Open Hand and Kelda. The archivist and the Pit were not named.',
        names: en);
    StoryNameKind? kindOf(String s) =>
        runs.where((r) => r.text == s).map((r) => r.kind).firstOrNull;
    expect(kindOf('Aurel Vane'), StoryNameKind.person);
    expect(kindOf('Saltmouth'), StoryNameKind.place);
    expect(kindOf('Lantern Dominion'), StoryNameKind.clan);
    expect(kindOf('Inquisition'), StoryNameKind.clan);
    expect(kindOf('Open Hand'), StoryNameKind.clan);
    expect(kindOf('Kelda'), StoryNameKind.person);
    // A description of someone is not a name, and a plain word is ignored.
    expect(runs.any((r) => r.text.contains('archivist') && r.kind != null),
        isFalse);
    expect(runs.any((r) => r.text.contains('Pit') && r.kind != null), isFalse);
    // French text uses the French names.
    final fr = build(true);
    expect(fr.isEmpty, isFalse);
  });
}
