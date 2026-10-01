import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/ship_combat.dart';
import '../data/port_helpers.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/chapter_loop_provider.dart';
import '../providers/combat_active_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/signs_provider.dart';
import '../screens/voyage_screen.dart';
import '../theme/stitched_ink.dart';
import 'immersive_notice.dart';
import 'ship_cutaway.dart';

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
    // A hull sign (see signs.dart) shows here as at sea.
    final signs = ref.watch(signEffectsProvider);
    final playerShip = buildPlayerShip(
      ship: ship,
      parts: parts,
      installedPartIds: installed,
      currentHull: session.shipHull,
      hullPercent: signs.shipHullPercent,
      gunPercent: signs.shipGunPercent,
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

    final ink = InkColors.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The Eel herself, on the water.
          ShipAtSea(ship: playerShip, borderRadius: 0),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(ship['shipName']?.toString() ?? playerShipId,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontFamily: InkFonts.display)),
                    ),
                    if (currentPort != null)
                      Flexible(
                        child: Text(
                          '${tr(ref, 'boat_at_port_prefix')} ${portNameFor(currentPort, fr)}',
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: ink.ash),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                HullBar(hull: playerShip.hull, maxHull: playerShip.maxHull),
                if (playerShip.maxLayers > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    tr(ref, 'ship_shield_line')
                        .replaceAll('{n}', '${playerShip.maxLayers}'),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: ink.voidColor),
                  ),
                ],
                const SizedBox(height: 8),
                // What is fitted, slot by slot.
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final slot in slotTypeOptions)
                      if (slotCapacity(ship, slot) > 0)
                        Tooltip(
                          message: installedNames(slot),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: slotsUsed(parts, installed, slot) > 0
                                      ? ink.tide
                                      : ink.seam),
                            ),
                            child: Text(
                              '${shipSlotLabel(ref, slot)} '
                              '${slotsUsed(parts, installed, slot)}/${slotCapacity(ship, slot)}',
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  key: const Key('ship_repair'),
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
        ],
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
    final chapter = ref.watch(reachedChapterProvider);
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

/// A hull bar in the sea's colour (days and other bars are gold), with
/// its numbers.
class HullBar extends ConsumerWidget {
  const HullBar({super.key, required this.hull, required this.maxHull});

  final int hull;
  final int maxHull;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = InkColors.of(context);
    final theme = Theme.of(context);
    final low = maxHull > 0 && hull * 3 < maxHull;
    return Row(
      children: [
        Text(tr(ref, 'hull_label'), style: theme.textTheme.labelMedium),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              key: const Key('hull_bar'),
              value: maxHull == 0 ? 0 : (hull / maxHull).clamp(0.0, 1.0),
              minHeight: 8,
              color: low ? ink.blood : ink.tide,
              backgroundColor: ink.seam,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$hull / $maxHull', style: theme.textTheme.labelMedium),
      ],
    );
  }
}

/// The Eel drawn on the water: her pixel cutaway (battered below half her
/// hull, refitted by her rooms) on a band of sea, and [beside] -- what she
/// meets -- to her right.
class ShipAtSea extends StatelessWidget {
  const ShipAtSea({
    super.key,
    required this.ship,
    this.beside,
    this.height = 112,
    this.borderRadius = 10,
  });

  final ShipState ship;
  final Widget? beside;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final cutaway = ShipCutaway.rustyEel;
    final asset = cutaway.asset(
        battered: ship.hull * 2 < ship.maxHull,
        refit: ShipCutaway.refitOf(ship));
    final shipHeight = height * 0.82;
    final shipWidth = shipHeight *
        ShipCutaway.spriteSize.width /
        ShipCutaway.spriteSize.height;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        key: const Key('ship_at_sea'),
        height: height,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1C2A3E), Color(0xFF14212E)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: height * 0.24,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF24596A), Color(0xFF1A3F4C)],
                    ),
                  ),
                ),
              ),
              // Centred alone; to the left when she meets something.
              Positioned(
                left: beside == null ? 0 : 16,
                right: beside == null ? 0 : null,
                bottom: height * 0.06,
                height: shipHeight,
                child: Align(
                  alignment: beside == null
                      ? Alignment.bottomCenter
                      : Alignment.bottomLeft,
                  child: Image.asset(asset,
                      width: shipWidth,
                      height: shipHeight,
                      filterQuality: FilterQuality.none,
                      fit: BoxFit.contain),
                ),
              ),
              if (beside == null)
                const SizedBox.shrink()
              else
                Positioned(
                  right: 20,
                  top: 0,
                  bottom: height * 0.14,
                  child: Center(child: beside),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
