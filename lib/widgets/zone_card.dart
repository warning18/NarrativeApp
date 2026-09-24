import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/zone_gating.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';

/// One zone's row in Town Hub's and Camp's expedition lists: its tier and
/// main-zone chips, its boss, and either a Begin button, a "Cleared" mark,
/// or the lock line naming the zone that must be cleared first.
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
    final details = <String>[
      zone['flavorText']?.toString() ?? '',
      if (bossName != null) '${tr(ref, 'zone_boss_prefix')}: $bossName',
      if (lockName != null) '${tr(ref, 'requires_zone_prefix')}: $lockName',
    ].where((s) => s.isNotEmpty).join('\n');

    // The action sits under the description, not beside it: a button in a
    // list tile's trailing slot takes the whole row on a phone in French.
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: Icon(
                completed
                    ? Icons.check_circle
                    : unlocked
                        ? Icons.explore_outlined
                        : Icons.lock_outline,
                color: completed ? Colors.green : null,
              ),
              title: Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(zone['zoneName']?.toString() ?? zoneId),
                  _ZoneChip('${tr(ref, 'zone_tier_label')} ${zoneTier(zone)}'),
                  _ZoneChip(
                    '${tr(ref, 'zone_level_chip')} ${zoneRecommendedLevel(zone)}+',
                    emphasized: session.level < zoneRecommendedLevel(zone),
                  ),
                  if (zoneIsMain(zone))
                    _ZoneChip(tr(ref, 'zone_main_label'), emphasized: true),
                ],
              ),
              subtitle: Text(details),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: completed
                    ? Text(tr(ref, 'zone_cleared_label'))
                    : ElevatedButton(
                        onPressed: (!enabled || !unlocked) ? null : onBegin,
                        child: Text(tr(ref, 'begin_expedition_button')),
                      ),
              ),
            ),
          ],
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
