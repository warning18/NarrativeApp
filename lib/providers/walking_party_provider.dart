import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/companion_remarks.dart';
import 'player_session_provider.dart';
import 'remark_provider.dart';

/// The most companions who walk beside the hero on a land walk (wave 13):
/// the side view has room for three figures.
const int _maxWalkingCompanions = 2;

/// One figure of the walking party on a land walk's side view.
class WalkingPartyMember {
  const WalkingPartyMember({required this.id, required this.spriteKey});

  /// `hero` for the player's character, else a companions.json id.
  final String id;

  /// Which walking sprite draws this figure: `hero`, or
  /// `companion_<id>`. Until the user's art arrives, UX draws a
  /// placeholder figure for any key it has no frames for.
  final String spriteKey;

  bool get isHero => id == heroWalkerId;

  @override
  bool operator ==(Object other) =>
      other is WalkingPartyMember &&
      other.id == id &&
      other.spriteKey == spriteKey;

  @override
  int get hashCode => Object.hash(id, spriteKey);

  @override
  String toString() => 'WalkingPartyMember($id, $spriteKey)';
}

const String heroWalkerId = 'hero';

/// Who walks on a land walk, front to back: the hero first, then the
/// companions the player picked for the party (`activeAllyIds`, in the
/// order picked), at most [_maxWalkingCompanions]. With no companion in the
/// party the hero walks alone. A companion the story took or who left
/// does not walk, whatever the party list still says.
List<WalkingPartyMember> walkingPartyOf(PlayerSession session) {
  final gone = {...session.lostAllyIds, ...session.departedAllyIds};
  final recruited = {
    for (final ally in session.recruitedAllies) ally.companionId,
  };
  final companions = <String>[];
  for (final id in session.activeAllyIds) {
    if (companions.length >= _maxWalkingCompanions) break;
    if (id.isEmpty || gone.contains(id) || !recruited.contains(id)) continue;
    if (companions.contains(id)) continue;
    companions.add(id);
  }
  return [
    const WalkingPartyMember(id: heroWalkerId, spriteKey: heroWalkerId),
    for (final id in companions)
      WalkingPartyMember(id: id, spriteKey: 'companion_$id'),
  ];
}

/// The walking party of the current save, for the land walk's side view
/// (UX reads it; see [walkingPartyOf]).
final walkingPartyProvider = Provider<List<WalkingPartyMember>>(
  (ref) => walkingPartyOf(ref.watch(playerSessionProvider)),
);

/// The word a walking companion says as a land walk starts, or null (see
/// [walkRemark]): UX calls it once when a walk begins and shows the line
/// as a bubble over that companion's figure ([CompanionRemark.companionId]
/// is the walker's id; [CompanionRemark.lineFor] gives the words).
CompanionRemark? speakUpOnWalk(WidgetRef ref) {
  final walkers = [
    for (final member in ref.read(walkingPartyProvider))
      if (!member.isHero) member.id,
  ];
  final said = walkRemark(
      ref.read(remarkBookProvider), ref.read(remarkMemoryProvider), walkers);
  ref.read(remarkMemoryProvider.notifier).state = said.memory;
  return said.remark;
}
