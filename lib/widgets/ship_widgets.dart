import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/ship_combat.dart';
import '../data/chapter_grid_layout.dart';
import '../data/port_helpers.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/combat_active_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../screens/voyage_screen.dart';
import 'immersive_notice.dart';

/// The Rusty Eel's own record in ships.json.
const String playerShipId = 'rusty_eel';

/// The Rusty Eel's record, or the first ship on file.
Map<String, dynamic>? playerShipRecord(Map<String, dynamic> ships) {
  final id = ships.containsKey(playerShipId)
      ? playerShipId
      : (ships.keys.isEmpty ? null : ships.keys.first);
  return id == null ? null : ships[id] as Map<String, dynamic>?;
}

String shipSlotLabel(WidgetRef ref, String slot) {
  switch (slot) {
    case 'Weapon':
      return tr(ref, 'slot_weapon_label');
    case 'Shield':
      return tr(ref, 'slot_shield_label');
    case 'Sail':
      return tr(ref, 'slot_sail_label');
    default:
      return tr(ref, 'slot_utility_label');
  }
}

String shipPartName(Map<String, dynamic> part, bool fr) {
  final name = part['partName']?.toString() ?? '';
  final nameFr = part['partName_fr']?.toString() ?? '';
  return fr && nameFr.isNotEmpty ? nameFr : name;
}

/// The Rusty Eel as she stands: where she is moored, her hull, her rooms,
/// what is fitted in each slot, and a repair when her hull is down.
class ShipStatusCard extends ConsumerWidget {
  const ShipStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final session = ref.watch(playerSessionProvider);
    final ships = ref.watch(localizedDbProvider(shipsSchema)).value;
    final parts = ref.watch(localizedDbProvider(shipPartsSchema)).value;
    final ports = ref.watch(localizedDbProvider(portsSchema)).value;
    final busy =
        ref.watch(combatActiveProvider) || ref.watch(expeditionActiveProvider);
    final ship = ships == null ? null : playerShipRecord(ships);
    if (ship == null || parts == null || ports == null) {
      return const SizedBox.shrink();
    }
    final installed = session.shipPartIds;
    final playerShip = buildPlayerShip(
      ship: ship,
      parts: parts,
      installedPartIds: installed,
      currentHull: session.shipHull,
    );
    final repairCost =
        repairCostFor(hull: playerShip.hull, maxHull: playerShip.maxHull);
    final currentPortId = currentPortIdFor(ports, session.currentPortId);
    final currentPort = currentPortId == null
        ? null
        : ports[currentPortId] as Map<String, dynamic>?;
    final theme = Theme.of(context);

    String installedNames(String slot) {
      final names = [
        for (final id in installed)
          if ((parts[id] as Map<String, dynamic>?)?['slotType']?.toString() ==
              slot)
            shipPartName(parts[id] as Map<String, dynamic>, fr),
      ];
      return names.isEmpty ? '—' : names.join(', ');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.sailing, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ship['shipName']?.toString() ?? playerShipId,
                          style: theme.textTheme.titleMedium),
                      if (currentPort != null)
                        Text(
                          '${tr(ref, 'boat_at_port_prefix')}: ${portNameFor(currentPort, fr)}',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: playerShip.maxHull == 0
                  ? 0
                  : playerShip.hull / playerShip.maxHull,
              minHeight: 8,
            ),
            const SizedBox(height: 4),
            Text(
              '${tr(ref, 'hull_label')} ${playerShip.hull} / ${playerShip.maxHull} · '
              '${[
                for (final room in ShipRoom.values)
                  '${tr(ref, 'ship_room_${room.name}_title')} ${playerShip.room(room).level}',
              ].join(' · ')}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final slot in slotTypeOptions)
              Text(
                '${shipSlotLabel(ref, slot)} '
                '${slotsUsed(parts, installed, slot)} / ${slotCapacity(ship, slot)}: '
                '${installedNames(slot)}',
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              key: const Key('ship_repair'),
              onPressed: (repairCost == 0 || session.gold < repairCost || busy)
                  ? null
                  : () async {
                      final ok = await ref
                          .read(playerSessionProvider.notifier)
                          .repairShip(repairCost);
                      if (!ok || !context.mounted) return;
                      showImmersiveNotice(
                        context,
                        icon: Icons.build_outlined,
                        message: tr(ref, 'ship_sound_label'),
                      );
                    },
              icon: const Icon(Icons.build_outlined),
              label: Text(repairCost == 0
                  ? tr(ref, 'ship_sound_label')
                  : '${tr(ref, 'repair_ship_button')} ($repairCost ${tr(ref, 'gold_label')})'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sails the Rusty Eel from where she is moored to [toPortId]: the voyage's
/// sea events play out (see VoyageScreen), and true comes back once she
/// makes landfall there.
Future<bool> sailTo(
  BuildContext context,
  WidgetRef ref, {
  required String toPortId,
  required Map<String, dynamic> toPort,
}) async {
  final ports = ref.read(localizedDbProvider(portsSchema)).value ?? const {};
  final fromPortId =
      currentPortIdFor(ports, ref.read(playerSessionProvider).currentPortId) ??
          toPortId;
  // Landfall can swap the tab this was called from (the camp gives way to
  // the ship), so nothing here touches [ref] once the voyage is under way.
  final expedition = ref.read(expeditionActiveProvider.notifier);
  expedition.state = true;
  final arrived = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => VoyageScreen(
        fromPortId: fromPortId,
        toPortId: toPortId,
        toPort: toPort,
      ),
    ),
  );
  expedition.state = false;
  return arrived == true;
}

/// The chart: every port the story has opened, where the boat is moored
/// and how far the others are. The camp's own cove is on it only when
/// [homeOnChart] (the story is at the camp): otherwise the way home is the
/// story's.
class PortChart extends ConsumerWidget {
  const PortChart({super.key, required this.homeOnChart});

  final bool homeOnChart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final session = ref.watch(playerSessionProvider);
    final ports = ref.watch(localizedDbProvider(portsSchema)).value;
    final zones = ref.watch(localizedDbProvider(zonesSchema)).value ??
        const <String, dynamic>{};
    final chapter = chapterOfNode(ref.watch(storyPlayProvider).currentNodeId);
    final busy =
        ref.watch(combatActiveProvider) || ref.watch(expeditionActiveProvider);
    if (ports == null) return const SizedBox.shrink();
    final currentPortId = currentPortIdFor(ports, session.currentPortId);
    final portIds = ports.keys
        .where((id) => ports[id] is Map<String, dynamic>)
        .where((id) => id != currentPortId)
        .where((id) =>
            homeOnChart || !portIsHome(ports[id] as Map<String, dynamic>))
        .where((id) => portUnlocked(ports[id] as Map<String, dynamic>,
            chapter: chapter, flags: session.flags))
        .toList()
      ..sort((a, b) {
        final pa = ports[a] as Map<String, dynamic>;
        final pb = ports[b] as Map<String, dynamic>;
        // The way home first, then by chapter.
        if (portIsHome(pa) != portIsHome(pb)) return portIsHome(pa) ? -1 : 1;
        final ca = portChapter(pa);
        final cb = portChapter(pb);
        return ca != cb ? ca.compareTo(cb) : a.compareTo(b);
      });
    if (portIds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(tr(ref, 'chart_empty')),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final portId in portIds)
          _PortCard(
            portId: portId,
            port: ports[portId] as Map<String, dynamic>,
            zones: zones,
            busy: busy,
            fr: fr,
          ),
      ],
    );
  }
}

class _PortCard extends ConsumerWidget {
  const _PortCard({
    required this.portId,
    required this.port,
    required this.zones,
    required this.busy,
    required this.fr,
  });

  final String portId;
  final Map<String, dynamic> port;
  final Map<String, dynamic> zones;
  final bool busy;
  final bool fr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = portIsHome(port);
    final zoneCount =
        portZoneIds(port).where((id) => zones.containsKey(id)).length;
    final details = [
      if (home) tr(ref, 'home_port_label'),
      '${portVoyageLength(port)} ${tr(ref, 'days_at_sea_label')}',
      if (!home) '$zoneCount ${tr(ref, 'zones_section').toLowerCase()}',
    ].join(' · ');
    return Card(
      child: ListTile(
        key: Key('chart_$portId'),
        leading:
            Icon(home ? Icons.local_fire_department_outlined : Icons.anchor),
        title: Text(home ? tr(ref, 'sail_home_title') : portNameFor(port, fr)),
        subtitle: Text(details),
        trailing: ElevatedButton(
          onPressed: busy
              ? null
              : () => sailTo(context, ref, toPortId: portId, toPort: port),
          child: Text(tr(ref, 'sail_button')),
        ),
      ),
    );
  }
}
