// Pages inside one scene (v1.750). A long scene may be read in pages: the
// first pages end on Continue, and the scene's choices wait on its last
// page. The writer marks a page break with `[PAGE]`; an ending's
// `[EPILOGUE]` (`[ÉPILOGUE]`) also starts a new page, and stays as the
// heading of the page it opens. The node keeps one id, one set of choices
// and one narration recording: only its reading is cut.

/// The neutral page-break marker. It is removed from the text shown.
const String pageBreakMarker = '[PAGE]';

/// Markers that open a page of their own and stay as its first words.
const List<String> pageOpeningMarkers = ['[EPILOGUE]', '[ÉPILOGUE]'];

/// [text] cut into its pages, in order. A text with no marker is one page;
/// empty pages (two markers in a row, a marker at either end) are dropped,
/// so there is always at least one page.
List<String> splitNarrationPages(String text) {
  final pages = <String>[];
  for (final chunk in text.split(pageBreakMarker)) {
    var rest = chunk;
    while (true) {
      final at = _firstOpening(rest);
      if (at <= 0) break;
      pages.add(rest.substring(0, at));
      rest = rest.substring(at);
    }
    pages.add(rest);
  }
  final kept = [
    for (final page in pages)
      if (page.trim().isNotEmpty) page.trim(),
  ];
  return kept.isEmpty ? [text.replaceAll(pageBreakMarker, '').trim()] : kept;
}

/// [text] whole, as one page: the page-break markers are removed and the
/// opening markers kept (for a reader that shows the scene in one go, such
/// as a prelude or the narration's script).
String joinedNarration(String text) => splitNarrationPages(text).join('\n\n');

/// Where the first opening marker after the start of [text] is, or -1.
int _firstOpening(String text) {
  var best = -1;
  if (text.length < 2) return best;
  for (final marker in pageOpeningMarkers) {
    // From the second character: a page that already opens on a marker is
    // not cut again there.
    final at = text.indexOf(marker, 1);
    if (at > 0 && (best < 0 || at < best)) best = at;
  }
  return best;
}
