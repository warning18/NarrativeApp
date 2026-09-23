/// Each chapter's main story beats: nodes every playthrough passes through
/// on the way from one beat to the next, regardless of which authored
/// choice was taken. A beat is a set of node ids rather than a single id
/// because some beats sit right at a branch point (e.g. two different
/// opening choices that both count as "reaching beat 2").
class ChapterSpine {
  const ChapterSpine(this.chapter, this.beats);

  final int chapter;
  final List<Set<String>> beats;
}

const List<ChapterSpine> chapterSpines = [
  ChapterSpine(1, [
    {'100'},
    {'250'},
    {'400'},
    {'891'},
    {'960'},
  ]),
  ChapterSpine(2, [
    {'2001'},
    {'2005'},
    {'2010', '2020', '2050'},
    {'2030', '2040', '2070'},
    {'2900'},
  ]),
  ChapterSpine(3, [
    {'3001'},
    {'3002'},
    {'3010', '3020'},
    {'3030', '3040', '3050'},
    {'4999'},
  ]),
  ChapterSpine(4, [
    {'5001'},
    {'5002'},
    {'5010'},
    {'5003', '5003_seeker'},
    {'5005'},
  ]),
  ChapterSpine(5, [
    {'6001', '6001_seeker'},
    {'6002'},
    {'6010'},
    {'6003'},
    {'6004'},
  ]),
  ChapterSpine(6, [
    {'7001'},
    {'7002'},
    {'7003'},
    {'7004'},
    {'7005', '7005_seeker', '7005_dawn', '7005_crown'},
  ]),
];

/// The chapter a node belongs to, or null if it isn't part of the spine
/// (side content, excursions, endings, etc).
int? chapterForNode(String nodeId) {
  for (final spine in chapterSpines) {
    for (final beat in spine.beats) {
      if (beat.contains(nodeId)) return spine.chapter;
    }
  }
  return null;
}

/// Whether [nodeId] is one of the fixed main story beats every playthrough
/// passes through. Leaving such a node is where a procedural excursion may
/// be inserted before the player reaches the next beat.
bool isMainBeatNode(String nodeId) => chapterForNode(nodeId) != null;

/// The first main-beat node of [chapter] — chapter 0 is the prologue/start
/// node; a chapter beyond [chapterSpines] has no defined entry point yet.
/// When a beat has more than one node (a bearer/seeker fork), the
/// lexicographically-first one is picked. Used both by the map's "Jump to
/// Chapter" shortcut and the autoplay-to-chapter feature as the concrete
/// node either one actually targets.
String? firstNodeIdForChapter(int chapter, {required String prologueNodeId}) {
  if (chapter == 0) return prologueNodeId;
  for (final spine in chapterSpines) {
    if (spine.chapter != chapter) continue;
    final sortedBeatNodes = spine.beats.first.toList()..sort();
    return sortedBeatNodes.isEmpty ? null : sortedBeatNodes.first;
  }
  return null;
}
