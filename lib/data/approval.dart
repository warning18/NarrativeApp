import 'dart:math';

/// Companion approval (v1.163): how a recruited companion feels about the
/// choices the player makes in front of them.
///
/// Each companion's record in companions.json says what they think of a
/// kind deed (`approvesGood`), a cruel one (`approvesEvil`) and one that
/// fills the purse (`approvesProfit`): a weight from -3 to 3. A story
/// choice's alignment and gold move the approval of every companion in the
/// party by those weights; a choice (or a quest outcome) can also name
/// companions directly (`approvalMods`). Benched companions don't see it.
///
/// Approval runs from [minApproval] to [maxApproval] and sets a tier:
/// devoted companions fight harder, wary ones hold back, and one pushed to
/// [leavingApproval] walks away for good.
enum ApprovalTier { estranged, wary, neutral, friendly, devoted }

const int minApproval = -20;
const int maxApproval = 20;

/// Where a newly recruited companion starts: they chose to follow.
const int startingApproval = 3;

const int friendlyApproval = 5;
const int devotedApproval = 12;
const int waryApproval = -5;

/// At or below this, the companion leaves the party for good.
const int leavingApproval = -12;

ApprovalTier approvalTierFor(int approval) {
  if (approval >= devotedApproval) return ApprovalTier.devoted;
  if (approval >= friendlyApproval) return ApprovalTier.friendly;
  if (approval <= leavingApproval) return ApprovalTier.estranged;
  if (approval <= waryApproval) return ApprovalTier.wary;
  return ApprovalTier.neutral;
}

/// The l10n key naming [tier] ('approval_devoted'...).
String approvalTierKey(ApprovalTier tier) => 'approval_${tier.name}';

/// Damage a companion deals at [tier], in percent of their normal damage.
int approvalDamagePercent(ApprovalTier tier) => switch (tier) {
      ApprovalTier.devoted => 110,
      ApprovalTier.friendly => 105,
      ApprovalTier.neutral => 100,
      ApprovalTier.wary => 90,
      ApprovalTier.estranged => 90,
    };

/// Max health a companion has at [tier], in percent of the normal.
int approvalHealthPercent(ApprovalTier tier) =>
    tier == ApprovalTier.devoted ? 110 : 100;

int _weight(Map<String, dynamic>? companion, String field) =>
    ((companion?[field] as num?)?.toInt() ?? 0).clamp(-3, 3);

/// How much [companion] (a companions.json record) approves of a deed that
/// moved alignment by [alignmentMod] and gold by [goldMod]. A big deed
/// (alignment moved by 3 or more) counts double. [explicit] is a scene's
/// own reaction for this companion, added on top.
int approvalDeltaFor(
  Map<String, dynamic>? companion, {
  int alignmentMod = 0,
  int goldMod = 0,
  int explicit = 0,
}) {
  var delta = explicit;
  if (alignmentMod != 0) {
    final scale = alignmentMod.abs() >= 3 ? 2 : 1;
    delta += scale *
        _weight(companion, alignmentMod > 0 ? 'approvesGood' : 'approvesEvil');
  }
  if (goldMod > 0) delta += _weight(companion, 'approvesProfit');
  return delta;
}

/// [approval] after [delta], kept within [minApproval]..[maxApproval].
int approvalAfter(int approval, int delta) =>
    max(minApproval, min(maxApproval, approval + delta));

/// The explicit reaction a scene's [approvalMods] gives [companionId]: its
/// own entry, else the `*` entry meant for everyone, else 0.
int explicitApprovalFor(Map<String, int> approvalMods, String companionId) =>
    approvalMods[companionId] ?? approvalMods['*'] ?? 0;

/// One companion's reaction to a deed.
class ApprovalChange {
  const ApprovalChange({
    required this.companionId,
    required this.before,
    required this.after,
  });

  final String companionId;
  final int before;
  final int after;

  int get delta => after - before;
  ApprovalTier get tierBefore => approvalTierFor(before);
  ApprovalTier get tierAfter => approvalTierFor(after);
  bool get tierChanged => tierBefore != tierAfter;

  /// They have had enough: this change took them to [leavingApproval].
  bool get leaves => tierAfter == ApprovalTier.estranged;
}

/// Gold it costs to share a drink with a companion at the camp in
/// [chapter]: once a chapter per companion, for [giftApproval].
int giftCostFor(int chapter) => 40 * max(1, chapter);
const int giftApproval = 2;
