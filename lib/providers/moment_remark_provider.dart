import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/companion_remarks.dart';
import 'player_session_provider.dart';
import 'remark_provider.dart';

/// The companions who can speak up on a moment (see momentRemark): those
/// the player picked for the party (`activeAllyIds`, in that order),
/// recruited and not taken by the story or gone.
List<String> momentPartyOf(PlayerSession session) {
  final gone = {...session.lostAllyIds, ...session.departedAllyIds};
  final recruited = {
    for (final ally in session.recruitedAllies) ally.companionId,
  };
  final party = <String>[];
  for (final id in session.activeAllyIds) {
    if (id.isEmpty || gone.contains(id) || !recruited.contains(id)) continue;
    if (!party.contains(id)) party.add(id);
  }
  return party;
}

/// A companion's word on a moment the player just chose (a house built, a
/// risky gift taken or its die, a temple service bought), or null (see
/// [momentRemark]); the memory is updated. The caller shows it the way a
/// shared drink's word is shown: `showCompanionRemarks(context, ref,
/// [remark])`, a speech bubble over the screen, tapped away.
CompanionRemark? speakUpOnMoment(WidgetRef ref, RemarkKind kind) {
  final said = momentRemark(
      ref.read(remarkBookProvider),
      ref.read(remarkMemoryProvider),
      momentPartyOf(ref.read(playerSessionProvider)),
      kind);
  ref.read(remarkMemoryProvider.notifier).state = said.memory;
  return said.remark;
}

/// A companion's word at sea as a voyage in [chapter] casts off (wave 16,
/// [RemarkKind.atSea]), or null: once a chapter (see [seaRemarkDue]), from
/// the party as for a moment ([momentRemark]). When someone speaks, the
/// chapter is noted in the save so the chapter's later voyages stay quiet;
/// nothing is noted while nobody has a sea line. The caller shows it as a
/// moment's word is shown.
CompanionRemark? speakUpAtSea(WidgetRef ref, {required int chapter}) {
  final session = ref.read(playerSessionProvider);
  if (!seaRemarkDue(chapter, session.seaRemarkChapter)) return null;
  final remark = speakUpOnMoment(ref, RemarkKind.atSea);
  if (remark != null) {
    ref.read(playerSessionProvider.notifier).noteSeaRemark(chapter);
  }
  return remark;
}

/// Watched in the build of a screen with a moment, so the remark lines
/// are loaded before the moment comes (as the camp's drink panel does).
void watchMomentRemarks(WidgetRef ref) => ref.watch(remarkBookProvider);
