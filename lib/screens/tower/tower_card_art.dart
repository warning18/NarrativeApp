// The picture on a Tower card (v2.3, UX-2): one lookup, so Art's own
// vignettes replace the stand-ins without touching a card. The key is
// "kind:school" first ("skill:warrior"), then "kind" ("skill"); a card that
// finds neither keeps its kind's stand-in, a plate of the Tower's own ink.
//
// To add Art's pictures: put the files in assets/visuals/tower_cards/, declare
// the folder in pubspec.yaml, and add an entry to [towerCardArt].
import '../../utils/pixel_icons/skill_icons.dart';

/// Art's vignettes: "kind:school" or "kind" to an asset path. Empty until Art
/// has drawn them.
const Map<String, String> towerCardArt = {};

/// What a card shows until Art's picture is there, by kind.
const Map<String, String> towerCardStandIn = {
  'skill': 'assets/visuals/tower/tower_ward5.png',
  'die': 'assets/visuals/tower/tower_shop.png',
  'spell': 'assets/visuals/tower/tower_parley.png',
  'oath': 'assets/visuals/tower/tower_bargain.png',
};

/// The vignette of a card of [kind] ('skill', 'die', 'spell' or 'oath') and,
/// when it has one, its [school] (the profession a skill belongs to).
String towerCardVignette(String kind, {String? school}) {
  if (school != null && school.isNotEmpty) {
    final own = towerCardArt['$kind:$school'];
    if (own != null) return own;
  }
  return towerCardArt[kind] ??
      towerCardStandIn[kind] ??
      towerCardStandIn['skill']!;
}

/// The small picture of a skill or a spell: its icon when it has one.
String? towerCardIcon(String kind, String id, {int? faces}) {
  switch (kind) {
    case 'die':
      return faces == null
          ? null
          : 'assets/visuals/dice/die_d${faces}_bone_44.png';
    default:
      return SkillIcons.allIds.contains(id) ? SkillIcons.pathFor(id) : null;
  }
}

/// A skill's rarity as a number: 0 common to 4 legendary; null for anything
/// that has none (dice and spells).
int? towerRarityIndex(String? rarity) {
  const order = ['common', 'uncommon', 'rare', 'epic', 'legendary'];
  final i = order.indexOf((rarity ?? '').toLowerCase());
  return i < 0 ? null : i;
}
