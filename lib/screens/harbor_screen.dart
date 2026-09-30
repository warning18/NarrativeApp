import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/sea_beasts.dart';
import '../combat/ship_combat.dart';
import '../data/port_helpers.dart';
import '../data/sail_powers.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../widgets/immersive_notice.dart';
import '../widgets/player_stats_bar.dart';
import '../widgets/ship_widgets.dart';
import 'voyage_screen.dart';

/// The camp's Harbor, once built: the Rusty Eel hauled up on its slipway,
/// her hull made sound and the shipwright's parts fitted into her slots.
/// It is the only place she is refitted: a part can go on in place of one
/// already aboard, which then waits here to go back on for nothing.
///
/// From v1.185 it is also where the sea beasts are tracked (see
/// sea_beasts.dart): the crew's signs of each beast met, and, with enough
/// of them, a hunt. The hunter's harpoon is sold once a beast has been
/// seen, and a slain beast's trophy is fitted here for free.
class HarborScreen extends ConsumerWidget {
  const HarborScreen({super.key});

  /// Whether [part] is on offer: beast gear once a beast has been seen, a
  /// beast's trophy once it is slain (or already won), the rest always.
  static bool partOffered(
      String partId, Map<String, dynamic> part, PlayerSession session) {
    final trophyOf = part['trophyOf']?.toString() ?? '';
    if (trophyOf.isNotEmpty) {
      return (session.seaBeasts[trophyOf]?.slain ?? false) ||
          session.shipPartIds.contains(partId) ||
          session.storedShipPartIds.contains(partId);
    }
    if (part['beastGear'] == true) {
      return session.seaBeasts.values.any((b) => b.seen);
    }
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final session = ref.watch(playerSessionProvider);
    final ships = ref.watch(localizedDbProvider(shipsSchema)).value;
    final parts = ref.watch(localizedDbProvider(shipPartsSchema)).value;
    final enemyShips = ref.watch(localizedDbProvider(enemyShipsSchema)).value;
    final ports = ref.watch(localizedDbProvider(portsSchema)).value;
    final ship = ships == null ? null : playerShipRecord(ships);

    Widget body;
    if (ships == null || parts == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (ship == null) {
      body = Center(child: Text(tr(ref, 'no_zones_available')));
    } else {
      final partIds = parts.keys
          .where((id) =>
              partOffered(id, parts[id] as Map<String, dynamic>, session))
          .toList()
        ..sort((a, b) {
          final pa = parts[a] as Map<String, dynamic>;
          final pb = parts[b] as Map<String, dynamic>;
          final sa = slotTypeOptions.indexOf(pa['slotType']?.toString() ?? '');
          final sb = slotTypeOptions.indexOf(pb['slotType']?.toString() ?? '');
          if (sa != sb) return sa.compareTo(sb);
          return ((pa['cost'] as num?)?.toInt() ?? 0)
              .compareTo((pb['cost'] as num?)?.toInt() ?? 0);
        });
      final beastIds = enemyShips == null
          ? const <String>[]
          : [
              for (final id in beastIdsIn(enemyShips))
                if (session.seaBeasts[id]?.seen ?? false) id,
            ];
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ShipStatusCard(),
          const SizedBox(height: 16),
          Text(tr(ref, 'shipwright_section'),
              style: Theme.of(context).textTheme.titleMedium),
          // The shipwright's parts by the slot they fit, each slot saying
          // how many of hers are filled.
          for (final slot in slotTypeOptions)
            if (partIds.any((id) =>
                (parts[id] as Map<String, dynamic>)['slotType'] == slot)) ...[
              Padding(
                key: Key('harbour_slot_$slot'),
                padding: const EdgeInsets.only(top: 14, bottom: 4),
                child: Text(
                  '${shipSlotLabel(ref, slot)} · '
                          '${tr(ref, 'slots_filled').replaceAll('{used}', '${slotsUsed(parts, session.shipPartIds, slot)}').replaceAll('{cap}', '${slotCapacity(ship, slot)}')}'
                      .toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1, color: InkColors.of(context).ash),
                ),
              ),
              for (final partId in partIds)
                if ((parts[partId] as Map<String, dynamic>)['slotType'] == slot)
                  _PartCard(
                    partId: partId,
                    part: parts[partId] as Map<String, dynamic>,
                    ship: ship,
                    parts: parts,
                    installed: session.shipPartIds,
                    stored: session.storedShipPartIds,
                    gold: session.gold,
                    fr: fr,
                  ),
            ],
          if (enemyShips != null) ...[
            const Divider(height: 32),
            Text(tr(ref, 'beasts_section'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              tr(ref, beastIds.isEmpty ? 'beasts_none_hint' : 'beasts_hint')
                  .replaceAll('{of}', '$cluesNeeded'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final id in beastIds)
              _BeastCard(
                beastId: id,
                record: enemyShips[id] as Map<String, dynamic>,
                state: session.seaBeasts[id]!,
                atHome: ports != null &&
                    currentPortIdFor(ports, session.currentPortId) ==
                        homePortId(ports),
                fr: fr,
              ),
          ],
        ],
      );
    }
    return TutorialTrigger(
      topic: TutorialTopic.boat,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr(ref, 'harbor_title')),
          actions: const [GoldBadge()],
        ),
        body: body,
      ),
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
    required this.stored,
    required this.gold,
    required this.fr,
  });

  final String partId;
  final Map<String, dynamic> part;
  final Map<String, dynamic> ship;
  final Map<String, dynamic> parts;
  final List<String> installed;
  final List<String> stored;
  final int gold;
  final bool fr;

  String _summary(WidgetRef ref) {
    final damage = (part['damageAmount'] as num?)?.toInt() ?? 0;
    final charge = (part['chargeTurns'] as num?)?.toInt() ?? 1;
    final roomDamage = (part['roomDamage'] as num?)?.toInt() ?? 1;
    final tether = (part['tetherRounds'] as num?)?.toInt() ?? 0;
    final bonus = part['roomBonus'];
    final power = sailPowerOf(part);
    final ranges = [
      for (final r in ShipRange.values)
        if (weaponRangesFrom(part['ranges']).contains(r)) r.name,
    ];
    return [
      if (power != null) tr(ref, 'sail_power_${power.name}'),
      if (damage > 0) '${tr(ref, 'damage_label')} $damage',
      if (damage > 0) '${tr(ref, 'charge_turns_label')} $charge',
      if (damage > 0 && roomDamage > 1)
        '${tr(ref, 'room_damage_label')} $roomDamage',
      if (damage > 0 && part['piercesShield'] == true)
        tr(ref, 'pierces_shield_label'),
      if (damage > 0 && part['setsFire'] == true) tr(ref, 'sets_fire_label'),
      if (tether > 0) tr(ref, 'tether_label').replaceAll('{n}', '$tether'),
      if (damage > 0 && ranges.isNotEmpty && ranges.length < 3)
        '${tr(ref, 'weapon_reach_label')} '
            '${ranges.map((r) => tr(ref, 'ship_range_$r')).join(', ')}',
      if (bonus is Map)
        for (final entry in bonus.entries)
          '${tr(ref, 'ship_room_${entry.key}_title')} +${entry.value}',
      if (((part['turnSecondsBonus'] as num?)?.toInt() ?? 0) > 0)
        tr(ref, 'turn_seconds_bonus_label')
            .replaceAll('{n}', '${part['turnSecondsBonus']}'),
    ].join(' · ');
  }

  /// Fits the part, [replacing] what comes off for it, and says so.
  Future<void> _fit(BuildContext context, WidgetRef ref, int cost,
      List<String> replacing) async {
    final ok = await ref
        .read(playerSessionProvider.notifier)
        .installShipPart(partId, cost, replacing: replacing);
    if (!ok || !context.mounted) return;
    showImmersiveNotice(
      context,
      icon: Icons.handyman_outlined,
      message: '${tr(ref, 'installed_label')}: ${shipPartName(part, fr)}',
    );
  }

  /// Asks which part of the slot comes off for this one; null to keep
  /// things as they are.
  Future<String?> _pickSwap(
      BuildContext context, WidgetRef ref, List<String> candidates) {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(
            tr(ref, 'swap_title').replaceAll('{part}', shipPartName(part, fr))),
        children: [
          for (final id in candidates)
            SimpleDialogOption(
              key: Key('swap_out_$id'),
              onPressed: () => Navigator.of(context).pop(id),
              child: Text(shipPartName(parts[id] as Map<String, dynamic>, fr)),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr(ref, 'cancel')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStored = stored.contains(partId);
    // A stored part goes back on for nothing; a trophy costs nothing.
    final cost = isStored ? 0 : (part['cost'] as num?)?.toInt() ?? 0;
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
    // A full slot takes the part in place of one aboard.
    final swapCandidates = fits || isInstalled
        ? const <String>[]
        : [
            for (final id in installed)
              if ((parts[id] as Map<String, dynamic>?)?['slotType']
                      ?.toString() ==
                  slot)
                id,
          ];
    final matchesMedium = slot == 'Sail' &&
        sailMediumOf(part) == ref.read(playerSessionProvider).raceId;
    final trophy = (part['trophyOf']?.toString() ?? '').isNotEmpty;
    final subtitle = [
      '${shipSlotLabel(ref, slot)} · ${_summary(ref)}',
      if (slot == 'Sail' || trophy || part['beastGear'] == true)
        fr
            ? (part['description_fr']?.toString() ?? '')
            : (part['description']?.toString() ?? ''),
      if (matchesMedium) tr(ref, 'sail_medium_match_label'),
      if (replacing.isNotEmpty) tr(ref, 'sail_repaint_note'),
      if (isStored) tr(ref, 'part_stored_note'),
    ].where((line) => line.isNotEmpty).join('\n');
    final price =
        cost == 0 ? tr(ref, 'free_label') : '$cost ${tr(ref, 'gold_label')}';
    // The button sits under the text, so a long description keeps the
    // card's width on a phone.
    Widget? action;
    if (isInstalled) {
      action = null;
    } else if (fits) {
      action = ElevatedButton(
        key: Key('install_$partId'),
        onPressed:
            gold < cost ? null : () => _fit(context, ref, cost, replacing),
        child: Text('${tr(ref, 'install_button')} ($price)'),
      );
    } else if (swapCandidates.isNotEmpty) {
      action = OutlinedButton(
        key: Key('swap_$partId'),
        onPressed: gold < cost
            ? null
            : () async {
                final out = await _pickSwap(context, ref, swapCandidates);
                if (out == null || !context.mounted) return;
                await _fit(context, ref, cost, [out]);
              },
        child: Text('${tr(ref, 'swap_button')} ($price)'),
      );
    }
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                    isInstalled
                        ? Icons.check_circle
                        : trophy
                            ? Icons.emoji_events_outlined
                            : (slot == 'Sail'
                                ? Icons.brush_outlined
                                : Icons.handyman_outlined),
                    size: 20,
                    color: isInstalled ? ink.heal : ink.ash),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(shipPartName(part, fr),
                      style: theme.textTheme.titleMedium),
                ),
                if (isInstalled)
                  Text(tr(ref, 'installed_label'),
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: ink.heal))
                else if (action == null)
                  Text(tr(ref, 'slot_full_label'),
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: ink.ash)),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
            if (action != null) ...[
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: action),
            ],
          ],
        ),
      ),
    );
  }
}

/// One beast the crew has seen: slain, or the signs of it gathered and
/// the wounds it carries, and the hunt once the signs are enough.
class _BeastCard extends ConsumerWidget {
  const _BeastCard({
    required this.beastId,
    required this.record,
    required this.state,
    required this.atHome,
    required this.fr,
  });

  final String beastId;
  final Map<String, dynamic> record;
  final BeastState state;

  /// The Eel is moored at the camp: a hunt sets out from here.
  final bool atHome;
  final bool fr;

  String get _name {
    final name = record['displayName']?.toString() ?? beastId;
    final nameFr = record['displayName_fr']?.toString() ?? '';
    return fr && nameFr.isNotEmpty ? nameFr : name;
  }

  Future<void> _hunt(BuildContext context, WidgetRef ref) async {
    final ports = ref.read(localizedDbProvider(portsSchema)).value ?? const {};
    final home = homePortId(ports);
    final port = home == null ? null : ports[home] as Map<String, dynamic>?;
    if (home == null || port == null) return;
    // The signs are spent: the hunt goes where they led.
    await ref
        .read(playerSessionProvider.notifier)
        .updateSeaBeast(beastId, (b) => b.copyWith(clues: 0));
    if (!context.mounted) return;
    final expedition = ref.read(expeditionActiveProvider.notifier);
    expedition.state = true;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VoyageScreen(
          fromPortId: home,
          toPortId: home,
          toPort: port,
          huntBeastId: beastId,
        ),
      ),
    );
    expedition.state = false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxHull = (record['maxHull'] as num?)?.toInt() ?? 1;
    final wounds = maxHull - beastStartHull(maxHull, state);
    final lines = state.slain
        ? [tr(ref, 'beast_slain_label')]
        : [
            tr(ref, 'beast_signs_label')
                .replaceAll('{n}', '${state.clues}')
                .replaceAll('{of}', '$cluesNeeded'),
            if (wounds > 0)
              tr(ref, 'beast_wounds_label').replaceAll('{n}', '$wounds'),
            if (state.huntReady && !atHome) tr(ref, 'beast_hunt_away_hint'),
          ];
    return Card(
      child: ListTile(
        key: Key('beast_card_$beastId'),
        leading: Icon(state.slain ? Icons.emoji_events : Icons.waves),
        title: Text(_name),
        subtitle: Text(lines.join('\n')),
        isThreeLine: lines.length > 1,
        trailing: state.slain
            ? null
            : ElevatedButton(
                key: Key('beast_hunt_$beastId'),
                onPressed: state.huntReady && atHome
                    ? () => _hunt(context, ref)
                    : null,
                child: Text(tr(ref, 'beast_hunt_button')),
              ),
      ),
    );
  }
}
