import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/approval.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import 'immersive_notice.dart';

/// The lines that tell the player how the party took a choice (see
/// approval.dart): "Maren approves." for each reaction, and a companion's
/// own words when they come to trust the player completely, start losing
/// patience, or walk out (with who took their seat). [companions] is the
/// localized companions table.
List<String> approvalReactionLines(
  List<ApprovalChange> reactions,
  Map<String, dynamic> companions,
  String Function(String key) t,
) {
  final lines = <String>[];
  for (final reaction in reactions) {
    final companion =
        companions[reaction.companionId] as Map<String, dynamic>? ?? const {};
    final name = companion['companionName']?.toString() ?? reaction.companionId;
    String quote(String field) {
      final line = companion[field]?.toString() ?? '';
      return line.isEmpty ? '' : '$name: “$line”';
    }

    lines.add(
        t(reaction.delta > 0 ? 'approval_approves' : 'approval_disapproves')
            .replaceAll('{name}', name));
    if (!reaction.tierChanged) continue;
    final after = reaction.tierAfter;
    if (reaction.leaves) {
      lines
        ..add(quote('leaveLine'))
        ..add(t('approval_leaves_notice').replaceAll('{name}', name));
      final seat = reaction.replacedBy;
      if (seat != null) {
        final stepsIn =
            (companions[seat] as Map<String, dynamic>?)?['companionName']
                ?.toString();
        lines.add(t('approval_replaced_notice')
            .replaceAll('{name}', stepsIn ?? seat)
            .replaceAll('{left}', name));
      }
    } else if (after == ApprovalTier.devoted && reaction.delta > 0) {
      lines
        ..add(quote('devotedLine'))
        ..add(t('approval_devoted_notice').replaceAll('{name}', name));
    } else if (after == ApprovalTier.wary && reaction.delta < 0) {
      lines
        ..add(quote('warnLine'))
        ..add(t('approval_wary_notice').replaceAll('{name}', name));
    }
  }
  return [
    for (final line in lines)
      if (line.isNotEmpty) line,
  ];
}

/// Shows [reactions] in one notice, if there are any.
Future<void> showApprovalReactions(
  BuildContext context,
  WidgetRef ref,
  List<ApprovalChange> reactions,
) async {
  if (reactions.isEmpty || !context.mounted) return;
  final companions =
      ref.read(localizedDbProvider(companionsSchema)).value ?? const {};
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
}
