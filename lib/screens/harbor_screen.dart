import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/ship_combat.dart';
import '../data/sail_powers.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../widgets/immersive_notice.dart';
import '../widgets/player_stats_bar.dart';
import '../widgets/ship_widgets.dart';

/// The camp's Harbor, once built: the Rusty Eel hauled up on its slipway,
/// her hull made sound and the shipwright's parts fitted into her slots.
/// It is the only place she is refitted.
class HarborScreen extends ConsumerWidget {
  const HarborScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final session = ref.watch(playerSessionProvider);
    final ships = ref.watch(localizedDbProvider(shipsSchema)).value;
    final parts = ref.watch(localizedDbProvider(shipPartsSchema)).value;
    final ship = ships == null ? null : playerShipRecord(ships);

    Widget body;
    if (ships == null || parts == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (ship == null) {
      body = Center(child: Text(tr(ref, 'no_zones_available')));
    } else {
      final partIds = parts.keys.toList()
        ..sort((a, b) {
          final pa = parts[a] as Map<String, dynamic>;
          final pb = parts[b] as Map<String, dynamic>;
          final sa = slotTypeOptions.indexOf(pa['slotType']?.toString() ?? '');
          final sb = slotTypeOptions.indexOf(pb['slotType']?.toString() ?? '');
          if (sa != sb) return sa.compareTo(sb);
          return ((pa['cost'] as num?)?.toInt() ?? 0)
              .compareTo((pb['cost'] as num?)?.toInt() ?? 0);
        });
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ShipStatusCard(),
          const Divider(height: 32),
          Text(tr(ref, 'shipwright_section'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final partId in partIds)
            _PartCard(
              partId: partId,
              part: parts[partId] as Map<String, dynamic>,
              ship: ship,
              parts: parts,
              installed: session.shipPartIds,
              gold: session.gold,
              fr: fr,
            ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'harbor_title')),
        actions: const [GoldBadge()],
      ),
      body: body,
    );
  }
}

class _PartCard extends ConsumerWidget {
  const _PartCard({
    required this.partId,
    required this.part,
    required this.ship,
    required this.parts,
    required this.installed,
    required this.gold,
    required this.fr,
  });

  final String partId;
  final Map<String, dynamic> part;
  final Map<String, dynamic> ship;
  final Map<String, dynamic> parts;
  final List<String> installed;
  final int gold;
  final bool fr;

  String _summary(WidgetRef ref) {
    final damage = (part['damageAmount'] as num?)?.toInt() ?? 0;
    final charge = (part['chargeTurns'] as num?)?.toInt() ?? 1;
    final roomDamage = (part['roomDamage'] as num?)?.toInt() ?? 1;
    final bonus = part['roomBonus'];
    final power = sailPowerOf(part);
    return [
      if (power != null) tr(ref, 'sail_power_${power.name}'),
      if (damage > 0) '${tr(ref, 'damage_label')} $damage',
      if (damage > 0) '${tr(ref, 'charge_turns_label')} $charge',
      if (damage > 0 && roomDamage > 1)
        '${tr(ref, 'room_damage_label')} $roomDamage',
      if (damage > 0 && part['piercesShield'] == true)
        tr(ref, 'pierces_shield_label'),
      if (damage > 0 && part['setsFire'] == true) tr(ref, 'sets_fire_label'),
      if (bonus is Map)
        for (final entry in bonus.entries)
          '${tr(ref, 'ship_room_${entry.key}_title')} +${entry.value}',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cost = (part['cost'] as num?)?.toInt() ?? 0;
    final isInstalled = installed.contains(partId);
    final slot = part['slotType']?.toString() ?? '';
    // A painted sail is repainted rather than added: the sigil already on
    // the canvas comes off when a new one goes on.
    final currentSail = slot == 'Sail' ? installedSail(parts, installed) : null;
    final replacing = currentSail != null && currentSail.partId != partId
        ? [currentSail.partId]
        : const <String>[];
    final fits = canInstallPart(
            ship: ship,
            parts: parts,
            installedPartIds: installed,
            partId: partId) ||
        replacing.isNotEmpty;
    final matchesMedium = slot == 'Sail' &&
        sailMediumOf(part) == ref.read(playerSessionProvider).raceId;
    final subtitle = [
      '${shipSlotLabel(ref, slot)} · ${_summary(ref)}',
      if (slot == 'Sail')
        fr
            ? (part['description_fr']?.toString() ?? '')
            : (part['description']?.toString() ?? ''),
      if (matchesMedium) tr(ref, 'sail_medium_match_label'),
      if (replacing.isNotEmpty) tr(ref, 'sail_repaint_note'),
    ].where((line) => line.isNotEmpty).join('\n');
    return Card(
      child: ListTile(
        leading: Icon(
            isInstalled
                ? Icons.check_circle
                : (slot == 'Sail'
                    ? Icons.brush_outlined
                    : Icons.handyman_outlined),
            color: isInstalled ? Colors.green : null),
        title: Text(shipPartName(part, fr)),
        subtitle: Text(subtitle),
        isThreeLine: true,
        trailing: isInstalled
            ? Text(tr(ref, 'installed_label'))
            : !fits
                ? Text(tr(ref, 'slot_full_label'))
                : ElevatedButton(
                    onPressed: gold < cost
                        ? null
                        : () async {
                            final ok = await ref
                                .read(playerSessionProvider.notifier)
                                .installShipPart(partId, cost,
                                    replacing: replacing);
                            if (!ok || !context.mounted) return;
                            showImmersiveNotice(
                              context,
                              icon: Icons.handyman_outlined,
                              message:
                                  '${tr(ref, 'installed_label')}: ${shipPartName(part, fr)}',
                            );
                          },
                    child: Text(
                        '${tr(ref, 'install_button')} ($cost ${tr(ref, 'gold_label')})'),
                  ),
      ),
    );
  }
}
