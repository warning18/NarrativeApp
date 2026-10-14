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
  // The casino and its first fight, the streets, the cannonball and the
  // Inquisitor-General, the cloth under the trapdoor, the quay and the
  // flying vessel, the crash in the Waste and the White Wells (v1.196).
  ChapterSpine(1, [
    {'100'},
    {'105'},
    {'250'},
    {'400'},
    {'470'},
    {'891'},
    {'960'},
    {'1100'},
    {'1200'},
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
  // From chapter 4 each chapter opens at the camp: its places and
  // expeditions first (see chapter_loop.dart), then its main quest.
  ChapterSpine(4, [
    {'4999_camp'},
    {'5003'},
    {'5004', '5004b'},
    {'5004_altar'},
    {'5005'},
  ]),
  ChapterSpine(5, [
    {'6001'},
    {'6002'},
    {'6002_camp'},
    {'6003'},
    {'6004'},
  ]),
  ChapterSpine(6, [
    {'7001'},
    {'7300'},
  ]),
  // The war for the Lantern Throne (v1.196): the claim at Candlehold's
  // gate, the way in under that claim's banner, the last stand of whoever
  // holds the Lantern Hall, and the coronation.
  ChapterSpine(7, [
    {'7400'},
    {'7500'},
    {
      '7510_dominion', '7510_vigil', '7510_compact', '7510_mire', //
      '7510_crows', '7510_penitents', '7510_open_hand',
    },
    {'7520_vane', '7520_morrow', '7520_tallis'},
    {
      '7590_dominion', '7590_vigil', '7590_compact', '7590_mire', //
      '7590_crows', '7590_penitents', '7590_open_hand',
    },
  ]),
  // Crowned: the Host mustered at the cove, the Battle of the Hollow
  // Shore, then the tear, the Sovereign and the endings.
  ChapterSpine(8, [
    {'7800'},
    {'7810'},
    {'7002_confront'},
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
