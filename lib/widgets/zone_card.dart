import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/zone_gating.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';

/// One zone's row in the town, camp and port expedition lists: its name,
/// tier and main-zone chips, its boss or the zone that must be cleared
/// first, and a Begin button or a "Cleared" mark. A long press (or a tap)
/// opens the zone's description.
class ZoneCard extends ConsumerWidget {
  const ZoneCard({
    super.key,
    required this.zoneId,
    required this.zone,
    required this.zones,
    required this.enemies,
    required this.enabled,
    required this.onBegin,
  });

  final String zoneId;
  final Map<String, dynamic> zone;
  final Map<String, dynamic> zones;
  final Map<String, dynamic> enemies;

  /// False while a fight or another expedition is in progress.
  final bool enabled;
  final Future<void> Function() onBegin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final completed = session.completedZoneIds.contains(zoneId);
    final unlocked = meetsRequiredFlags(zone, session.flags);
    final bossId = zone['bossEnemyId']?.toString() ?? '';
    final bossName = bossId.isEmpty
        ? null
        : (enemies[bossId] as Map<String, dynamic>?)?['enemyName']
                ?.toString() ??
            bossId;
    final lockName =
        unlocked ? null : lockRequirementName(zone, session.flags, zones);
    final name = zone['zoneName']?.toString() ?? zoneId;
    final flavor = zone['flavorText']?.toString() ?? '';
    final canBegin = enabled && unlocked && !completed;
    final theme = Theme.of(context);
    final chips = Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _ZoneChip('${tr(ref, 'zone_tier_label')} ${zoneTier(zone)}'),
        _ZoneChip(
          '${tr(ref, 'zone_level_chip')} ${zoneRecommendedLevel(zone)}+',
          emphasized: session.level < zoneRecommendedLevel(zone),
        ),
        if (zoneIsMain(zone))
          _ZoneChip(tr(ref, 'zone_main_label'), emphasized: true),
      ],
    );
    final facts = [
      if (bossName != null) '${tr(ref, 'zone_boss_prefix')}: $bossName',
      if (lockName != null) '${tr(ref, 'requires_zone_prefix')}: $lockName',
    ];

    // The card stays short: name, chips, boss and the action. The zone's
    // description opens on a long press (or a tap), so a list of zones
    // reads at a glance on a phone.
    void showDetails() => showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            title: Text(name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                chips,
                if (flavor.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    flavor,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'serif', fontStyle: FontStyle.italic),
                  ),
                ],
                for (final fact in facts) ...[
                  const SizedBox(height: 8),
                  Text(fact, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(tr(ref, 'close_button')),
              ),
              if (canBegin)
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onBegin();
                  },
                  child: Text(tr(ref, 'begin_expedition_button')),
                ),
            ],
          ),
        );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: showDetails,
        onLongPress: showDetails,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    completed
                        ? Icons.check_circle
                        : unlocked
                            ? Icons.explore_outlined
                            : Icons.lock_outline,
                    color: completed ? Colors.green : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        chips,
                        for (final fact in facts)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(fact,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // The hint and the action share a line when they fit; on a
              // narrow screen (or in French) the action drops below.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    tr(ref, 'hold_for_details_hint'),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  completed
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(tr(ref, 'zone_cleared_label')),
                        )
                      : ElevatedButton(
                          onPressed: canBegin ? onBegin : null,
                          child: Text(tr(ref, 'begin_expedition_button')),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoneChip extends StatelessWidget {
  const _ZoneChip(this.label, {this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: emphasized
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: emphasized
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
