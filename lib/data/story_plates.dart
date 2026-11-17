// What a story choice's or a quest's plate shows (UX-2's story redesign,
// docs/proposals/story-redesign.md): the clan it touches and how much it
// weighs. Display only: read from the effects the choice already carries,
// nothing in the rules reads these.

import '../models/story_node.dart';

/// How much a choice weighs on the plate: [plain] (a quiet frame),
/// [weighty] (the clan's accent) or [major] (the rich metal).
enum ChoiceWeight { plain, weighty, major }

/// A companion's approval moved by this much or more, either way, makes a
/// choice [ChoiceWeight.major].
const int majorApprovalShift = 5;

/// The clan a choice's effects touch ('' for none): its claim, else the
/// faction that brings an offer, else the first pledge, else the standing
/// moved the most (the first written on a tie), else the clan of the first
/// sub-clan marked (from [subclanClans], sub-clan id -> clan), else its
/// `about` when that is a clan of [clans]. A choice whose consequences are
/// hidden shows none.
String choiceClanOf(
  StoryChoice choice, {
  Map<String, String> subclanClans = const {},
  Set<String> clans = const {},
}) {
  final politics = choice.politics;
  if (politics != null && !politics.isEmpty) {
    if (politics.hidden) return '';
    if (politics.claim.isNotEmpty) return politics.claim;
    if (politics.offerFrom.isNotEmpty) return politics.offerFrom;
    if (politics.pledges.isNotEmpty) return politics.pledges.first;
    String best = '';
    num most = 0;
    for (final MapEntry(:key, :value) in politics.standing.entries) {
      if (value.abs() > most) {
        best = key;
        most = value.abs();
      }
    }
    if (best.isNotEmpty) return best;
    for (final subclan in politics.marks.keys) {
      final clan = subclanClans[subclan] ?? '';
      if (clan.isNotEmpty) return clan;
    }
  }
  return clans.contains(choice.about) ? choice.about : '';
}

/// How much [choice] weighs (see [ChoiceWeight]). Major: a claim, a pledge,
/// the Throne, a banner piece, an ally lost, or a companion's approval
/// moved by [majorApprovalShift] or more. Weighty: alignment moved, any
/// companion's approval, politics shown on the choice, an item given or a
/// quest opened. Plain otherwise (flags alone are the story's bookkeeping).
/// A choice whose consequences are hidden reads plain unless it also does
/// something the player sees.
ChoiceWeight choiceWeightOf(StoryChoice choice) {
  final politics = choice.politics;
  final shown = politics != null && !politics.isEmpty && !politics.hidden;
  if ((shown &&
          (politics.claim.isNotEmpty ||
              politics.pledges.isNotEmpty ||
              politics.throneWinner.isNotEmpty)) ||
      (choice.grantsBannerPieceId ?? '').isNotEmpty ||
      (choice.loseAllyId ?? '').isNotEmpty ||
      choice.approvalMods.values.any((v) => v.abs() >= majorApprovalShift)) {
    return ChoiceWeight.major;
  }
  if (shown ||
      choice.alignmentMod != 0 ||
      choice.approvalMods.values.any((v) => v != 0) ||
      (choice.grantItemId ?? '').isNotEmpty ||
      (choice.unlockQuestId ?? '').isNotEmpty) {
    return ChoiceWeight.weighty;
  }
  return ChoiceWeight.plain;
}

/// The clan a quest's plate wears ('' for the neutral plate): its display
/// `clan` (quests.json), else its `faction`.
String questClanOf(Map<String, dynamic> quest) {
  for (final key in const ['clan', 'faction']) {
    final value = quest[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}
