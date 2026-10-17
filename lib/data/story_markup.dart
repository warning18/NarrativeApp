// The story text's markup and its names (docs/proposals/story-markup.md).
//
// Narrative writes `**key facts**` and blank lines between paragraphs; the
// names of people, places and clans are found by the game from its own
// tables. Pure: [parseStoryText] turns a scene's text into paragraphs of
// runs (bold, italic, the kind of name), the widget (story_text.dart) draws
// them, and [stripStoryMarkup] gives the plain words (for the voice, the
// journal, a folded line).

/// What a coloured name is.
enum StoryNameKind { person, place, clan }

/// One run of a paragraph: [text] with the same look all through.
class StoryRun {
  const StoryRun(this.text,
      {this.bold = false, this.italic = false, this.kind});

  final String text;
  final bool bold;
  final bool italic;

  /// Set when the run is a name.
  final StoryNameKind? kind;

  @override
  bool operator ==(Object other) =>
      other is StoryRun &&
      other.text == text &&
      other.bold == bold &&
      other.italic == italic &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(text, bold, italic, kind);

  @override
  String toString() =>
      'StoryRun("$text"${bold ? ', bold' : ''}${italic ? ', italic' : ''}'
      '${kind == null ? '' : ', ${kind!.name}'})';
}

/// Finds the names in a text: whole words, the longest first, case as
/// written. The names are the display names of the language of the text.
class StoryNameMatcher {
  StoryNameMatcher(Map<String, StoryNameKind> names)
      : _kinds = {for (final e in names.entries) _fold(e.key): e.value},
        _pattern = _compile(names.keys);

  /// No names.
  static final StoryNameMatcher empty = StoryNameMatcher(const {});

  final Map<String, StoryNameKind> _kinds;
  final RegExp? _pattern;

  bool get isEmpty => _pattern == null;

  /// The apostrophes written either way match the same.
  static String _fold(String s) => s.replaceAll("'", '’');

  static RegExp? _compile(Iterable<String> names) {
    final sorted = [
      for (final n in names)
        if (n.trim().length >= 3) n.trim()
    ]..sort((a, b) => b.length.compareTo(a.length));
    if (sorted.isEmpty) return null;
    final alternatives = sorted.map((n) {
      final escaped = RegExp.escape(n).replaceAll(RegExp("['’]"), "['’]");
      return escaped;
    }).join('|');
    return RegExp('(?<![\\p{L}\\p{N}_])(?:$alternatives)(?![\\p{L}\\p{N}_])',
        unicode: true);
  }

  /// The names found in [text], in order and not overlapping.
  List<({int start, int end, StoryNameKind kind})> find(String text) {
    final pattern = _pattern;
    if (pattern == null) return const [];
    return [
      for (final m in pattern.allMatches(text))
        if (_kinds[_fold(m.group(0)!)] case final kind?)
          (start: m.start, end: m.end, kind: kind),
    ];
  }
}

/// [text] without the markup: the `**` signs gone, the words as written.
String stripStoryMarkup(String text) => text.replaceAllMapped(
    RegExp(r'\*\*(?=\S)(.+?)(?<=\S)\*\*', dotAll: false), (m) => m.group(1)!);

final RegExp _paragraphBreak = RegExp(r'\n[ \t]*\n\s*');

/// [text] as paragraphs of runs.
///
/// * A blank line starts a paragraph; a single line break stays one.
/// * `**words**` are bold, inside a paragraph (an unclosed `**` stays as
///   typed).
/// * [names] colours the names; [italicQuotes] sets what is said in
///   quotation marks in italics; [firstSentenceBold] (the look of a text
///   with no markup at all, before it is marked) bolds the first sentence.
List<List<StoryRun>> parseStoryText(
  String text, {
  StoryNameMatcher? names,
  bool italicQuotes = true,
  bool firstSentenceBold = false,
}) {
  final paragraphs = [
    for (final p in text.replaceAll('\r\n', '\n').split(_paragraphBreak))
      if (p.trim().isNotEmpty) p.trim(),
  ];
  return [
    for (final (i, p) in paragraphs.indexed)
      _runsOf(p,
          names: names,
          italicQuotes: italicQuotes,
          firstSentenceBold: firstSentenceBold && i == 0),
  ];
}

List<StoryRun> _runsOf(String paragraph,
    {required StoryNameMatcher? names,
    required bool italicQuotes,
    required bool firstSentenceBold}) {
  // The bold ranges, over the text without its `**`.
  final plain = StringBuffer();
  final bold = <(int, int)>[];
  var i = 0;
  while (i < paragraph.length) {
    final open = paragraph.indexOf('**', i);
    if (open < 0) {
      plain.write(paragraph.substring(i));
      break;
    }
    final close = paragraph.indexOf('**', open + 2);
    final inner = close < 0 ? '' : paragraph.substring(open + 2, close);
    final good = close > open + 2 &&
        inner.trim().isNotEmpty &&
        !inner.startsWith(RegExp(r'\s')) &&
        !RegExp(r'\s$').hasMatch(inner) &&
        !inner.contains('\n\n');
    if (!good) {
      // Not a pair: the signs stay as typed.
      plain.write(paragraph.substring(i, open + 2));
      i = open + 2;
      continue;
    }
    plain.write(paragraph.substring(i, open));
    final start = plain.length;
    plain.write(inner);
    bold.add((start, plain.length));
    i = close + 2;
  }
  final text = plain.toString();
  final hasMarkup = bold.isNotEmpty;

  final italics = <(int, int)>[];
  if (italicQuotes) {
    for (final m in RegExp('["“«][^"”»]{3,}["”»]').allMatches(text)) {
      italics.add((m.start, m.end));
    }
  }
  if (firstSentenceBold && !hasMarkup) {
    final first = RegExp(r'[.!?]+(\s|$)').firstMatch(text);
    if (first != null) bold.add((0, first.end));
  }
  final found = names?.find(text) ?? const [];

  final cuts = <int>{0, text.length};
  for (final (a, b) in [...bold, ...italics]) {
    cuts.addAll([a, b]);
  }
  for (final n in found) {
    cuts.addAll([n.start, n.end]);
  }
  final sorted = cuts.toList()..sort();
  final runs = <StoryRun>[];
  for (var k = 0; k < sorted.length - 1; k++) {
    final a = sorted[k], b = sorted[k + 1];
    if (a >= b) continue;
    final kind = found
        .where((n) => a >= n.start && b <= n.end)
        .map((n) => n.kind)
        .firstOrNull;
    runs.add(StoryRun(
      text.substring(a, b),
      bold: bold.any((r) => a >= r.$1 && b <= r.$2),
      italic: italics.any((r) => a >= r.$1 && b <= r.$2),
      kind: kind,
    ));
  }
  return runs;
}

/// The characters a text shows once marked up (what a typewriter counts).
int storyTextLength(List<List<StoryRun>> paragraphs) => paragraphs.fold(
    0, (sum, p) => sum + p.fold(0, (s, r) => s + r.text.length));
