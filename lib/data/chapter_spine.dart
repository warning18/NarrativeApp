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
    {'2010', '2020'},
    {'2030', '2040', '2050', '2070'},
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
    {'5003', '5003_seeker'},
    {'5004'},
    {'5005'},
  ]),
  ChapterSpine(5, [
    {'6001', '6001_seeker'},
    {'6002'},
    {'6003'},
    {'6004'},
    {'6005', '6005_seeker'},
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
