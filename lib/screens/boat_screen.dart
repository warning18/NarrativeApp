import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/ship_combat.dart';
import '../data/chapter_grid_layout.dart';
import '../data/port_helpers.dart';
import '../data/sail_powers.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/combat_active_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../widgets/immersive_notice.dart';
import 'port_screen.dart';
import 'voyage_screen.dart';
import '../widgets/player_stats_bar.dart';

/// The Rusty Eel: her hull and bulwark, the shipwright's parts to fit into
/// her slots, and the chart of ports she can sail to. The camp stays where
/// it is; the boat is how the party reaches every other port's
/// expeditions (and, later, chapters). A voyage is a short chain of sea
/// events (see VoyageScreen), and landfall opens that port's PortScreen.
class BoatScreen extends ConsumerWidget {
  const BoatScreen({super.key});

  static const String shipId = 'rusty_eel';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final session = ref.watch(playerSessionProvider);
    final ships = ref.watch(localizedDbProvider(shipsSchema)).value;
    final parts = ref.watch(localizedDbProvider(shipPartsSchema)).value;
    final ports = ref.watch(localizedDbProvider(portsSchema)).value;
    final chapter = chapterOfNode(ref.watch(storyPlayProvider).currentNodeId);
    final busy =
        ref.watch(combatActiveProvider) || ref.watch(expeditionActiveProvider);

    if (ships == null || parts == null || ports == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(tr(ref, 'boat_title')),
          actions: const [GoldBadge()],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final resolvedShipId = ships.containsKey(shipId)
        ? shipId
        : (ships.keys.isEmpty ? null : ships.keys.first);
    final ship = resolvedShipId == null
        ? null
        : ships[resolvedShipId] as Map<String, dynamic>?;
    if (ship == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(tr(ref, 'boat_title')),
          actions: const [GoldBadge()],
        ),
        body: Center(child: Text(tr(ref, 'no_zones_available'))),
      );
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
    final portIds = ports.keys
        .where((id) => ports[id] is Map<String, dynamic>)
        .where((id) => portUnlocked(ports[id] as Map<String, dynamic>,
            chapter: chapter, flags: session.flags))
        .toList()
      ..sort((a, b) {
        final ca = portChapter(ports[a] as Map<String, dynamic>);
        final cb = portChapter(ports[b] as Map<String, dynamic>);
        return ca != cb ? ca.compareTo(cb) : a.compareTo(b);
      });

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'boat_title')),
        actions: const [GoldBadge()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
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
                            Text(ship['shipName']?.toString() ?? shipId,
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
                      '${_slotLabel(ref, slot)} '
                      '${slotsUsed(parts, installed, slot)} / ${slotCapacity(ship, slot)}: '
                      '${_installedNames(parts, installed, slot, fr)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed:
                        (repairCost == 0 || session.gold < repairCost || busy)
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
          ),
          const Divider(height: 32),
          Text(tr(ref, 'shipwright_section'),
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final partId in partIds)
            _buildPartCard(
              context,
              ref,
              partId: partId,
              part: parts[partId] as Map<String, dynamic>,
              ship: ship,
              parts: parts,
              installed: installed,
              gold: session.gold,
              fr: fr,
            ),
          const Divider(height: 32),
          Text(tr(ref, 'ports_section'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final portId in portIds)
            _buildPortCard(
              context,
              ref,
              portId: portId,
              port: ports[portId] as Map<String, dynamic>,
              zones: ref.watch(localizedDbProvider(zonesSchema)).value ??
                  const <String, dynamic>{},
              isCurrent: portId == currentPortId,
              fromPortId: currentPortId ?? portId,
              busy: busy,
              fr: fr,
            ),
        ],
      ),
    );
  }

  String _slotLabel(WidgetRef ref, String slot) {
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

  String _partName(Map<String, dynamic> part, bool fr) {
    final name = part['partName']?.toString() ?? '';
    final nameFr = part['partName_fr']?.toString() ?? '';
    return fr && nameFr.isNotEmpty ? nameFr : name;
  }

  String _installedNames(
    Map<String, dynamic> parts,
    List<String> installed,
    String slot,
    bool fr,
  ) {
    final names = [
      for (final id in installed)
        if ((parts[id] as Map<String, dynamic>?)?['slotType']?.toString() ==
            slot)
          _partName(parts[id] as Map<String, dynamic>, fr),
    ];
    return names.isEmpty ? '—' : names.join(', ');
  }

  String _partSummary(WidgetRef ref, Map<String, dynamic> part) {
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

  Widget _buildPartCard(
    BuildContext context,
    WidgetRef ref, {
    required String partId,
    required Map<String, dynamic> part,
    required Map<String, dynamic> ship,
    required Map<String, dynamic> parts,
    required List<String> installed,
    required int gold,
    required bool fr,
  }) {
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
      '${_slotLabel(ref, slot)} · ${_partSummary(ref, part)}',
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
        title: Text(_partName(part, fr)),
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
                                  '${tr(ref, 'installed_label')}: ${_partName(part, fr)}',
                            );
                          },
                    child: Text(
                        '${tr(ref, 'install_button')} ($cost ${tr(ref, 'gold_label')})'),
                  ),
      ),
    );
  }

  Widget _buildPortCard(
    BuildContext context,
    WidgetRef ref, {
    required String portId,
    required Map<String, dynamic> port,
    required Map<String, dynamic> zones,
    required bool isCurrent,
    required String fromPortId,
    required bool busy,
    required bool fr,
  }) {
    final zoneCount =
        portZoneIds(port).where((id) => zones.containsKey(id)).length;
    final details = [
      '${tr(ref, 'chapter_short_prefix')} ${portChapter(port)}',
      if (!isCurrent)
        '${portVoyageLength(port)} ${tr(ref, 'days_at_sea_label')}',
      '$zoneCount ${tr(ref, 'zones_section').toLowerCase()}',
      if (portIsHome(port)) tr(ref, 'home_port_label'),
    ].join(' · ');
    return Card(
      child: ListTile(
        leading: Icon(portIsHome(port) ? Icons.home_outlined : Icons.anchor),
        title: Text(portNameFor(port, fr)),
        subtitle: Text(details),
        trailing: isCurrent
            ? TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PortScreen(portId: portId)),
                ),
                child: Text(tr(ref, 'moored_here_label')),
              )
            : ElevatedButton(
                onPressed: busy
                    ? null
                    : () async {
                        ref.read(expeditionActiveProvider.notifier).state =
                            true;
                        final arrived = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => VoyageScreen(
                              fromPortId: fromPortId,
                              toPortId: portId,
                              toPort: port,
                            ),
                          ),
                        );
                        ref.read(expeditionActiveProvider.notifier).state =
                            false;
                        if (arrived != true || !context.mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => PortScreen(portId: portId)),
                        );
                      },
                child: Text(tr(ref, 'sail_button')),
              ),
      ),
    );
  }
}
