import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/approval.dart';
import '../data/companion_remarks.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/remark_provider.dart';
import 'companion_remark_bubble.dart';
import 'immersive_notice.dart';

/// The lines that tell the player how the party took a choice (see
/// approval.dart): "Maren approves." for each reaction, and when a
/// companion comes to trust the player completely, starts losing
/// patience, or walks out (with who took their seat). [companions] is the
/// localized companions table. What they say about it is in
/// [approvalReactionWords].
List<String> approvalReactionLines(
  List<ApprovalChange> reactions,
  Map<String, dynamic> companions,
  String Function(String key) t,
) {
  final lines = <String>[];
  for (final reaction in reactions) {
    final name = _nameOf(companions, reaction.companionId);
    lines.add(
        t(reaction.delta > 0 ? 'approval_approves' : 'approval_disapproves')
            .replaceAll('{name}', name));
    if (!reaction.tierChanged) continue;
    final after = reaction.tierAfter;
    if (reaction.leaves) {
      lines.add(t('approval_leaves_notice').replaceAll('{name}', name));
      final seat = reaction.replacedBy;
      if (seat != null) {
        lines.add(t('approval_replaced_notice')
            .replaceAll('{name}', _nameOf(companions, seat))
            .replaceAll('{left}', name));
      }
    } else if (after == ApprovalTier.devoted && reaction.delta > 0) {
      lines.add(t('approval_devoted_notice').replaceAll('{name}', name));
    } else if (after == ApprovalTier.wary && reaction.delta < 0) {
      lines.add(t('approval_wary_notice').replaceAll('{name}', name));
    }
  }
  return lines;
}

/// What the companions [reactions] moved say in their own words when they
/// come to trust the player completely, start losing patience, or walk
/// out (their devotedLine, warnLine or leaveLine), for speech bubbles.
List<SpokenLine> approvalReactionWords(
  List<ApprovalChange> reactions,
  Map<String, dynamic> companions,
) {
  final words = <SpokenLine>[];
  for (final reaction in reactions) {
    if (!reaction.tierChanged) continue;
    final after = reaction.tierAfter;
    final field = reaction.leaves
        ? 'leaveLine'
        : after == ApprovalTier.devoted && reaction.delta > 0
            ? 'devotedLine'
            : after == ApprovalTier.wary && reaction.delta < 0
                ? 'warnLine'
                : null;
    if (field == null) continue;
    final companion =
        companions[reaction.companionId] as Map<String, dynamic>? ?? const {};
    final line = companion[field]?.toString() ?? '';
    if (line.isEmpty) continue;
    words.add(SpokenLine(
      speaker: _nameOf(companions, reaction.companionId),
      line: line,
      companionId: reaction.companionId,
    ));
  }
  return words;
}

String _nameOf(Map<String, dynamic> companions, String id) =>
    (companions[id] as Map<String, dynamic>?)?['companionName']?.toString() ??
    id;

/// What the party says about [deed], which [reactions] answer (see
/// companion_remarks.dart): picked, remembered, and returned for a notice
/// to show. [deedKeys] name the choice for its written lines; [action] is
/// what the choice showed of the player besides (a check, a sneak).
List<CompanionRemark> speakUpAbout(
  WidgetRef ref, {
  List<ApprovalChange> reactions = const [],
  RemarkDeed deed = const RemarkDeed(),
  List<String> deedKeys = const [],
  RemarkKind? action,
}) {
  final picked = pickRemark(
    book: ref.read(remarkBookProvider),
    memory: ref.read(remarkMemoryProvider),
    activeAllyIds: ref.read(playerSessionProvider).activeAllyIds,
    reactions: reactions,
    deed: deed,
    companions: ref.read(gameDbProvider(companionsSchema)).value ?? const {},
    deedKeys: deedKeys,
    action: action,
  );
  ref.read(remarkMemoryProvider.notifier).state = picked.memory;
  return picked.remarks;
}

/// Shows [reactions] in one notice, if there are any, then what the
/// party says in speech bubbles: a companion's own words when their trust
/// turns (see [approvalReactionWords]) and, with [deed] (what they react
/// to), what one of them makes of it. The story leaves [deed] out and
/// shows its remark over the next scene instead.
Future<void> showApprovalReactions(
  BuildContext context,
  WidgetRef ref,
  List<ApprovalChange> reactions, {
  RemarkDeed? deed,
}) async {
  if (reactions.isEmpty || !context.mounted) return;
  final companions =
      ref.read(localizedDbProvider(companionsSchema)).value ?? const {};
  final remarks = deed == null
      ? const <CompanionRemark>[]
      : speakUpAbout(ref, reactions: reactions, deed: deed);
  final lines =
      approvalReactionLines(reactions, companions, (key) => tr(ref, key));
  final warm = reactions.fold<int>(0, (sum, r) => sum + r.delta) >= 0;
  final someoneLeft = reactions.any((r) => r.leaves);
  await showImmersiveNotice(
    context,
    message: lines.join('\n'),
    icon: someoneLeft
        ? Icons.heart_broken
        : (warm ? Icons.favorite : Icons.sentiment_dissatisfied),
    duration: Duration(milliseconds: 1800 + 900 * lines.length),
  );
  if (!context.mounted) return;
  await showSpokenLines(context, ref, [
    ...approvalReactionWords(reactions, companions),
    ...spokenRemarks(ref, remarks),
  ]);
}
