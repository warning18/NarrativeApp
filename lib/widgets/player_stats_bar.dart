import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';

class PlayerStatsBar extends ConsumerWidget {
  const PlayerStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);

    Widget chip(IconData icon, String label) => Chip(
          avatar: Icon(icon, size: 16),
          label: Text(label),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          chip(Icons.shield, '${tr(ref, 'level_abbrev')} ${session.level}'),
          const SizedBox(width: 6),
          chip(
            Icons.favorite,
            '${session.currentHealth}/${session.maxHealth} ${tr(ref, 'hp_label')}',
          ),
          const SizedBox(width: 6),
          chip(Icons.paid, '${session.gold}g'),
          const SizedBox(width: 6),
          chip(Icons.balance, trAlignmentLabel(ref, session.alignmentLabel)),
          if (session.flags.isNotEmpty) ...[
            const SizedBox(width: 6),
            chip(Icons.flag, '${session.flags.length} ${tr(ref, 'flags_count_label')}'),
          ],
        ],
      ),
    );
  }
}
