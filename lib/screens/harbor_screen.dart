import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/sea_beasts.dart';
import '../combat/ship_combat.dart';
import '../data/port_helpers.dart';
import '../data/sail_powers.dart';
import '../data/ship_forms.dart';
import '../data/ship_looks.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/chapter_loop_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../widgets/immersive_notice.dart';
import '../widgets/player_stats_bar.dart';
import '../widgets/ship_cutaway.dart';
import '../widgets/ship_dress.dart';
import '../widgets/ship_widgets.dart';
import '../widgets/ship_yard.dart';
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
///
/// From v1.226 it is the shipwright's yard too: the Eel from above, as she
/// would look with a part or a look tried on her (nothing is bought until
/// it is fitted), the shelf of paint, cloth, figureheads and flags, and
/// every part in versions, from the plain to the rare, each from its
/// chapter on.
class HarborScreen extends ConsumerStatefulWidget {
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

  /// Whether the story has come far enough for the shipwright to sell
  /// [part] (ship_parts.json `unlockChapter`; 0 or none is always); a part
  /// already aboard or stored stays unlocked.
  static bool partUnlocked(String partId, Map<String, dynamic> part,
      PlayerSession session, int chapter) {
    final from = (part['unlockChapter'] as num?)?.toInt() ?? 0;
    return from <= chapter ||
        session.shipPartIds.contains(partId) ||
        session.storedShipPartIds.contains(partId);
  }

  @override
  ConsumerState<HarborScreen> createState() => _HarborScreenState();
}

class _HarborScreenState extends ConsumerState<HarborScreen> {
  /// The part being tried on the ship (not yet fitted), if any.
  String? _tryPartId;

  /// The hull being tried on the ship (not yet built), if any.
  String? _tryHullId;

  /// The looks being tried, by category (not yet worn).
  final Map<String, String> _tryLooks = {};

  /// The shelf's open category.
  String _lookTab = shipLookCategories.first;

  Future<void> _wear(ShipLook look) async {
    final session = ref.read(playerSessionProvider);
    final owned = look.isDefault || session.ownedShipLooks.contains(look.id);
    final price = owned || look.trophyOf.isNotEmpty ? 0 : look.cost;
    final ok = await ref
        .read(playerSessionProvider.notifier)
        .wearShipLook(look.category, look.id, price);
    if (!ok || !mounted) return;
    setState(() => _tryLooks.remove(look.category));
    showImmersiveNotice(
      context,
      icon: Icons.palette_outlined,
      message: '${tr(ref, 'look_worn_notice')}: ${look.name}',
    );
  }

  /// Rebuilds the Eel on the hull [hullId] after saying which parts have no
  /// slot on it and go to the Harbor's store.
  Future<void> _rebuild(
    String hullId,
    Map<String, dynamic> ships,
    Map<String, dynamic> parts,
    bool fr,
  ) async {
    final session = ref.read(playerSessionProvider);
    final next = ships[hullId] as Map<String, dynamic>?;
    final current = playerShipRecord(ships, session.shipHullId);
    if (next == null || current == null) return;
    final toStore = partsBeyondSlots(
        ship: next, parts: parts, installedPartIds: session.shipPartIds);
    final hullName = _hullName(next, fr);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('rebuild_confirm'),
        title:
            Text(tr(ref, 'hull_confirm_title').replaceAll('{hull}', hullName)),
        content: Text(toStore.isEmpty
            ? tr(ref, 'hull_confirm_all_fit')
            : tr(ref, 'hull_confirm_body').replaceAll(
                '{parts}',
                toStore
                    .map((id) =>
                        shipPartName(parts[id] as Map<String, dynamic>, fr))
                    .join(', '))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr(ref, 'cancel')),
          ),
          ElevatedButton(
            key: const Key('rebuild_confirm_yes'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(tr(ref, 'hull_confirm_yes')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    // She keeps the share of her hull she has, on the new one.
    final now = buildPlayerShip(
        ship: current,
        parts: parts,
        installedPartIds: session.shipPartIds,
        currentHull: session.shipHull);
    final share = now.maxHull == 0 ? 1.0 : now.hull / now.maxHull;
    final kept = [
      for (final id in session.shipPartIds)
        if (!toStore.contains(id)) id,
    ];
    final built = buildPlayerShip(
        ship: next, parts: parts, installedPartIds: kept, currentHull: -1);
    final hull = session.shipHull < 0
        ? -1
        : math.max(1, (share * built.maxHull).round());
    final cost = (next['hullCost'] as num?)?.toInt() ?? 0;
    final done = await ref
        .read(playerSessionProvider.notifier)
        .rebuildHull(hullId, cost, toStore: toStore, hull: hull);
    if (!done || !mounted) return;
    setState(() {
      _tryHullId = null;
      _tryPartId = null;
    });
    showImmersiveNotice(
      context,
      icon: Icons.construction,
      message: tr(ref, 'hull_rebuilt_notice').replaceAll('{hull}', hullName),
    );
  }

  String _hullName(Map<String, dynamic> hull, bool fr) {
    final name = hull['hullName']?.toString() ?? '';
    final nameFr = hull['hullName_fr']?.toString() ?? '';
    return fr && nameFr.isNotEmpty ? nameFr : name;
  }

  @override
  Widget build(BuildContext context) {
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final session = ref.watch(playerSessionProvider);
    final chapter = ref.watch(reachedChapterProvider);
    final ships = ref.watch(localizedDbProvider(shipsSchema)).value;
    final parts = ref.watch(localizedDbProvider(shipPartsSchema)).value;
    final lookRecords = ref.watch(localizedDbProvider(shipLooksSchema)).value;
    final enemyShips = ref.watch(localizedDbProvider(enemyShipsSchema)).value;
    final ports = ref.watch(localizedDbProvider(portsSchema)).value;
    final ship =
        ships == null ? null : playerShipRecord(ships, session.shipHullId);

    Widget body;
    if (ships == null || parts == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (ship == null) {
      body = Center(child: Text(tr(ref, 'no_zones_available')));
    } else {
      // Versions of a part sit together, the plainest first.
      final familyFloor = <String, int>{};
      for (final entry in parts.entries) {
        final part = entry.value as Map<String, dynamic>;
        final family = part['family']?.toString() ?? entry.key;
        final cost = (part['cost'] as num?)?.toInt() ?? 0;
        final floor = familyFloor[family];
        if (floor == null || cost < floor) familyFloor[family] = cost;
      }
      final partIds = parts.keys
          .where((id) => HarborScreen.partOffered(
              id, parts[id] as Map<String, dynamic>, session))
          .toList()
        ..sort((a, b) {
          final pa = parts[a] as Map<String, dynamic>;
          final pb = parts[b] as Map<String, dynamic>;
          final sa = slotTypeOptions.indexOf(pa['slotType']?.toString() ?? '');
          final sb = slotTypeOptions.indexOf(pb['slotType']?.toString() ?? '');
          if (sa != sb) return sa.compareTo(sb);
          final fa = familyFloor[pa['family']?.toString() ?? a] ?? 0;
          final fb = familyFloor[pb['family']?.toString() ?? b] ?? 0;
          if (fa != fb) return fa.compareTo(fb);
          final ta = (pa['tier'] as num?)?.toInt() ?? 1;
          final tb = (pb['tier'] as num?)?.toInt() ?? 1;
          if (ta != tb) return ta.compareTo(tb);
          return ((pa['cost'] as num?)?.toInt() ?? 0)
              .compareTo((pb['cost'] as num?)?.toInt() ?? 0);
        });
      final beastIds = enemyShips == null
          ? const <String>[]
          : [
              for (final id in beastIdsIn(enemyShips))
                if (session.seaBeasts[id]?.seen ?? false) id,
            ];

      // The yard: the ship as she would be with what is tried on her.
      final looks = lookRecords == null ? null : shipLooksFrom(lookRecords);
      final owned = {...session.ownedShipLooks};
      final slain = {
        for (final entry in session.seaBeasts.entries)
          if (entry.value.slain) entry.key,
      };
      final currentHullId = ships.containsKey(session.shipHullId)
          ? session.shipHullId
          : defaultHullId;
      final tryHull = _tryHullId == null
          ? null
          : ships[_tryHullId] as Map<String, dynamic>?;
      final yardShip = tryHull ?? ship;
      final yardHullId = tryHull == null ? currentHullId : _tryHullId!;
      final tryingPart = _tryPartId == null
          ? null
          : parts[_tryPartId] as Map<String, dynamic>?;
      final shownParts = tryingPart == null
          ? session.shipPartIds
          : fittedWith(
              ship: yardShip,
              parts: parts,
              installed: session.shipPartIds,
              partId: _tryPartId!);
      final yardDress = lookRecords == null
          ? null
          : buildShipDress(
              ship: yardShip,
              parts: parts,
              installed: shownParts,
              lookRecords: lookRecords,
              chosen: {...session.shipLooks, ..._tryLooks},
              owned: [...owned, ..._tryLooks.values],
            );
      final wornIds = <String, String>{
        if (looks != null)
          for (final cat in shipLookCategories)
            if (wornLook(looks, cat, session.shipLooks, owned) != null)
              cat: wornLook(looks, cat, session.shipLooks, owned)!.id,
      };
      final theme = Theme.of(context);
      final ink = InkColors.of(context);

      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ShipStatusCard(showShip: false),
          const SizedBox(height: 16),
          if (yardDress != null && looks != null)
            Card(
              key: const Key('yard_card'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(tr(ref, 'yard_title'),
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(tr(ref, 'yard_hint'),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: ink.ash)),
                    const SizedBox(height: 10),
                    ShipYardPreview(
                        dress: yardDress,
                        form: ShipForm.fromRecord(yardHullId, yardShip),
                        refit: ShipCutaway.refitOf(buildPlayerShip(
                            ship: ship,
                            parts: parts,
                            installedPartIds: session.shipPartIds,
                            currentHull: -1))),
                    if (tryingPart != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.visibility_outlined,
                              size: 18, color: ink.gold),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              tr(ref, 'part_trying_label').replaceAll(
                                  '{part}', shipPartName(tryingPart, fr)),
                              key: const Key('yard_trying'),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          TextButton(
                            key: const Key('yard_clear_try'),
                            onPressed: () => setState(() => _tryPartId = null),
                            child: Text(tr(ref, 'part_try_clear')),
                          ),
                        ],
                      ),
                    ],
                    if (tryHull != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.visibility_outlined,
                              size: 18, color: ink.gold),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              tr(ref, 'hull_trying_label')
                                  .replaceAll('{hull}', _hullName(tryHull, fr)),
                              key: const Key('yard_trying_hull'),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          TextButton(
                            key: const Key('yard_clear_hull'),
                            onPressed: () => setState(() => _tryHullId = null),
                            child: Text(tr(ref, 'part_try_clear')),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(tr(ref, 'looks_section'),
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    LookShelf(
                      looks: looks,
                      category: _lookTab,
                      onCategory: (c) => setState(() => _lookTab = c),
                      worn: wornIds,
                      previewed: Map.of(_tryLooks),
                      onTry: (look) => setState(() {
                        if (wornIds[look.category] == look.id) {
                          _tryLooks.remove(look.category);
                        } else {
                          _tryLooks[look.category] = look.id;
                        }
                      }),
                      owned: owned,
                      chapter: chapter,
                      slain: slain,
                      beastNames: {
                        if (enemyShips != null)
                          for (final id in beastIdsIn(enemyShips))
                            id: (enemyShips[id]
                                        as Map<String, dynamic>)['displayName']
                                    ?.toString() ??
                                id,
                      },
                      gold: session.gold,
                      onWear: _wear,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(tr(ref, 'hull_section'),
              key: const Key('hull_section'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(tr(ref, 'hull_hint'),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: InkColors.of(context).ash)),
          const SizedBox(height: 6),
          for (final hullId in hullIdsInOrder(ships))
            _HullCard(
              hullId: hullId,
              record: ships[hullId] as Map<String, dynamic>,
              current: hullId == currentHullId,
              owned: session.ownedHullIds.contains(hullId),
              unlocked: hullUnlocked(ships[hullId] as Map<String, dynamic>,
                  chapter, session.ownedHullIds.contains(hullId)),
              gold: session.gold,
              trying: _tryHullId == hullId,
              fr: fr,
              onTry: () => setState(
                  () => _tryHullId = _tryHullId == hullId ? null : hullId),
              onRebuild: () => _rebuild(hullId, ships, parts, fr),
            ),
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
                    unlocked: HarborScreen.partUnlocked(
                        partId,
                        parts[partId] as Map<String, dynamic>,
                        session,
                        chapter),
                    trying: _tryPartId == partId,
                    onTry: () => setState(() =>
                        _tryPartId = _tryPartId == partId ? null : partId),
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

/// One hull the Eel can be rebuilt on: its picture from above, what it
/// carries, and the button that builds it (or says why not).
class _HullCard extends ConsumerWidget {
  const _HullCard({
    required this.hullId,
    required this.record,
    required this.current,
    required this.owned,
    required this.unlocked,
    required this.gold,
    required this.trying,
    required this.fr,
    required this.onTry,
    required this.onRebuild,
  });

  final String hullId;
  final Map<String, dynamic> record;

  /// The hull she is built on now.
  final bool current;

  /// She has been built on it before: back on it for nothing.
  final bool owned;
  final bool unlocked;
  final int gold;
  final bool trying;
  final bool fr;
  final VoidCallback onTry;
  final VoidCallback onRebuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final name = fr && (record['hullName_fr']?.toString() ?? '').isNotEmpty
        ? record['hullName_fr'].toString()
        : record['hullName']?.toString() ?? hullId;
    final description = fr
        ? (record['description_fr']?.toString() ?? '')
        : (record['description']?.toString() ?? '');
    final cost = (record['hullCost'] as num?)?.toInt() ?? 0;
    final chapter = (record['unlockChapter'] as num?)?.toInt() ?? 0;
    final flying = record['flying'] == true;
    int slots(String key) => (record[key] as num?)?.toInt() ?? 0;
    final chips = [
      '${tr(ref, 'hull_label')} ${record['baseMaxHull']}',
      '${shipSlotLabel(ref, 'Weapon')} ${slots('weaponSlots')}',
      '${shipSlotLabel(ref, 'Shield')} ${slots('shieldSlots')}',
      '${shipSlotLabel(ref, 'Utility')} ${slots('utilitySlots')}',
      '${shipSlotLabel(ref, 'Sail')} ${slots('sailSlots')}',
      if (flying) tr(ref, 'hull_flying_label'),
    ];
    final price =
        cost == 0 ? tr(ref, 'free_label') : '$cost ${tr(ref, 'gold_label')}';
    Widget? action;
    if (current) {
      action = null;
    } else if (!unlocked) {
      action = null;
    } else if (owned) {
      action = OutlinedButton(
        key: Key('rebuild_$hullId'),
        onPressed: onRebuild,
        child: Text(tr(ref, 'hull_switch_button')),
      );
    } else {
      action = ElevatedButton(
        key: Key('rebuild_$hullId'),
        onPressed: gold < cost ? null : onRebuild,
        child: Text('${tr(ref, 'hull_build_button')} ($price)'),
      );
    }
    return Opacity(
      opacity: unlocked || current ? 1 : 0.55,
      child: Card(
        key: Key('hull_card_$hullId'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: current
                  ? ink.heal
                  : trying
                      ? ink.gold
                      : InkColors.of(context).seam,
              width: current || trying ? 2 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(name, style: theme.textTheme.titleMedium),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: current
                          ? Text(tr(ref, 'hull_aboard_label'),
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: ink.heal))
                          : !unlocked
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_outline,
                                        size: 14, color: ink.ash),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                          tr(ref, 'look_locked_note')
                                              .replaceAll('{n}', '$chapter'),
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(color: ink.ash)),
                                    ),
                                  ],
                                )
                              : owned
                                  ? Text(tr(ref, 'hull_owned_note'),
                                      textAlign: TextAlign.end,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(color: ink.heal))
                                  : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HullThumb(
                      form: ShipForm.fromRecord(hullId, record), width: 150),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chips.join(' · '),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: ink.gold)),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(description,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: ink.ash)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (!current) ...[
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton.icon(
                      key: Key('try_hull_$hullId'),
                      onPressed: onTry,
                      icon: Icon(
                          trying
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18),
                      label: Text(tr(
                          ref, trying ? 'part_try_clear' : 'part_try_button')),
                    ),
                    if (action != null) action,
                  ],
                ),
              ],
            ],
          ),
        ),
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
    required this.unlocked,
    required this.trying,
    required this.onTry,
  });

  final String partId;
  final Map<String, dynamic> part;
  final Map<String, dynamic> ship;
  final Map<String, dynamic> parts;
  final List<String> installed;
  final List<String> stored;
  final int gold;
  final bool fr;

  /// The story has come far enough for the shipwright to sell it.
  final bool unlocked;

  /// It is the part tried on the ship in the yard.
  final bool trying;
  final VoidCallback onTry;

  String _summary(WidgetRef ref) {
    final damage = (part['damageAmount'] as num?)?.toInt() ?? 0;
    final charge = (part['chargeTurns'] as num?)?.toInt() ?? 1;
    final roomDamage = (part['roomDamage'] as num?)?.toInt() ?? 1;
    final tether = (part['tetherRounds'] as num?)?.toInt() ?? 0;
    final hull = (part['hullBonus'] as num?)?.toInt() ?? 0;
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
      if (hull > 0) tr(ref, 'hull_bonus_label').replaceAll('{n}', '$hull'),
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
    final sails = slot == 'Sail'
        ? installedSails(parts, installed)
        : const <({String partId, SailPower power, String medium})>[];
    final power = sailPowerOf(part);
    // A sail of a power already aboard is painted over by it (one of each
    // power counts); with a single sail slot, any sail is.
    final sameKind = [
      for (final sail in sails)
        if (sail.power == power && sail.partId != partId) sail.partId,
    ];
    final replacing = sameKind.isNotEmpty
        ? [sameKind.first]
        : (slot == 'Sail' &&
                slotCapacity(ship, 'Sail') == 1 &&
                sails.isNotEmpty &&
                sails.first.partId != partId)
            ? [sails.first.partId]
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
    final description = fr
        ? (part['description_fr']?.toString() ?? '')
        : (part['description']?.toString() ?? '');
    final unlockChapter = (part['unlockChapter'] as num?)?.toInt() ?? 0;
    final subtitle = [
      '${shipSlotLabel(ref, slot)} · ${_summary(ref)}',
      description,
      if (matchesMedium) tr(ref, 'sail_medium_match_label'),
      if (replacing.isNotEmpty) tr(ref, 'sail_repaint_note'),
      if (isStored) tr(ref, 'part_stored_note'),
      if (!unlocked)
        tr(ref, 'part_locked_note').replaceAll('{n}', '$unlockChapter'),
    ].where((line) => line.isNotEmpty).join('\n');
    final price =
        cost == 0 ? tr(ref, 'free_label') : '$cost ${tr(ref, 'gold_label')}';
    // The button sits under the text, so a long description keeps the
    // card's width on a phone.
    Widget? action;
    if (isInstalled || !unlocked) {
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
    final trophy = (part['trophyOf']?.toString() ?? '').isNotEmpty;
    final rarity = part['rarity']?.toString() ?? 'common';
    final tier = (part['tier'] as num?)?.toInt() ?? 1;
    final shade = rarityColor(rarity);
    if (!unlocked) {
      // A part for a later chapter takes one line, so the shelf of versions
      // stays short: its name, what it is, and when it comes.
      return Card(
        key: Key('part_card_$partId'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: trying ? ink.gold : shade.withValues(alpha: 0.3),
              width: trying ? 2 : 1),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(Icons.lock_outline, size: 20, color: ink.ash),
          title: Text(shipPartName(part, fr),
              style: theme.textTheme.titleSmall?.copyWith(color: ink.ash)),
          subtitle: Text(
              [
                tr(ref, 'rarity_$rarity'),
                if (slot != 'Sail' && !trophy)
                  tr(ref, 'part_version_label')
                      .replaceAll('{n}', romanVersion(tier)),
                tr(ref, 'look_locked_note').replaceAll('{n}', '$unlockChapter'),
              ].join(' · '),
              style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
          trailing: IconButton(
            key: Key('try_$partId'),
            tooltip: tr(ref, trying ? 'part_try_clear' : 'part_try_button'),
            onPressed: onTry,
            icon: Icon(
                trying
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: trying ? ink.gold : ink.ash),
          ),
        ),
      );
    }
    return Opacity(
      opacity: unlocked ? 1 : 0.55,
      child: Card(
        key: Key('part_card_$partId'),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: trying ? ink.gold : shade.withValues(alpha: 0.45),
              width: trying ? 2 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                      !unlocked
                          ? Icons.lock_outline
                          : isInstalled
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
                  else if (action == null && unlocked)
                    Text(tr(ref, 'slot_full_label'),
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: ink.ash)),
                ],
              ),
              const SizedBox(height: 4),
              // What it is: its rarity, and which version of its family.
              Wrap(
                spacing: 6,
                children: [
                  _Tag(tr(ref, 'rarity_$rarity'), shade),
                  if (slot != 'Sail' && !trophy)
                    _Tag(
                        tr(ref, 'part_version_label')
                            .replaceAll('{n}', romanVersion(tier)),
                        ink.ash),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
              if (action != null || !isInstalled) ...[
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!isInstalled)
                      TextButton.icon(
                        key: Key('try_$partId'),
                        onPressed: onTry,
                        icon: Icon(
                            trying
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18),
                        label: Text(tr(ref,
                            trying ? 'part_try_clear' : 'part_try_button')),
                      ),
                    if (action != null) action,
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontSize: 10)),
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
    // The hunt goes where the signs led; they are spent once the beast is
    // met (see VoyageScreen), so a hunt cut short on its day out keeps them.
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
