import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_engine.dart';
import '../data/camp_state.dart';
import '../data/chapter_grid_layout.dart';
import '../data/port_helpers.dart';
import '../data/zone_gating.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/ally_state.dart';
import '../models/story_node.dart';
import '../providers/combat_active_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/game_config_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import '../widgets/immersive_notice.dart';
import '../widgets/player_stats_bar.dart';
import '../widgets/camp_travel.dart';
import '../widgets/quest_tracker.dart';
import '../widgets/ship_widgets.dart';
import '../widgets/zone_card.dart';
import 'dice_loadout_screen.dart';
import 'harbor_screen.dart';
import 'inventory_screen.dart';
import 'port_screen.dart';
import 'shop_detail_screen.dart';
import 'skills_screen.dart';
import 'story_player_screen.dart'
    show composeNarration, isStoryChoiceLocked, storyBodyFor, takeStoryChoice;

/// The party's camp from chapter 3, open while the party is at it: the
/// story at a camp's scene, or the party gone back to it from a town where
/// the story waits. What happened on coming back, who comes along, the
/// expeditions on its shore and the voyages out, what has been built, its
/// shops, and the way on (see [leaveCamp]). While the party is here the
/// Story tab gives way to this page, and comes back once the party leaves.
class CampScreen extends ConsumerWidget {
  const CampScreen({super.key, this.embedded = false});

  /// True as the in-game Camp tab: the page without its own app bar, with
  /// the camp's scene and its way on. Opened from Edit Mode, it is the
  /// camp's works only.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final session = ref.watch(playerSessionProvider);
    final companions = ref.watch(localizedDbProvider(companionsSchema)).value;
    final houses = ref.watch(localizedDbProvider(housesSchema)).value;
    final races = ref.watch(localizedDbProvider(racesSchema)).value;
    final professions = ref.watch(localizedDbProvider(professionsSchema)).value;
    final gameConfig = ref.watch(gameConfigProvider).value;
    final zones = ref.watch(localizedDbProvider(zonesSchema)).value;
    final shops = ref.watch(localizedDbProvider(shopsSchema)).value;
    final ports = ref.watch(localizedDbProvider(portsSchema)).value ??
        const <String, dynamic>{};
    final play = ref.watch(storyPlayProvider);
    final story = ref.watch(storyDataProvider).value;
    final node = story?.nodeFor(play.currentNodeId);
    final campNode =
        embedded && (node?.settlement?.isCamp ?? false) ? node : null;
    // Gone back to the camp from a town: the story waits there.
    final waitingTown = embedded &&
            campNode == null &&
            node != null &&
            session.campVisitFromNodeId == node.id
        ? node
        : null;

    if (companions == null ||
        houses == null ||
        races == null ||
        professions == null ||
        gameConfig == null ||
        zones == null ||
        shops == null) {
      const loading = Center(child: CircularProgressIndicator());
      if (embedded) return loading;
      return Scaffold(
        appBar: AppBar(
          title: Text(tr(ref, 'camp_title')),
          actions: const [GoldBadge()],
        ),
        body: loading,
      );
    }

    final theme = Theme.of(context);
    final harborBuilt = session.builtHouseIds.contains(harborHouseId);
    final homeId = homePortId(ports);
    final homePort =
        homeId == null ? null : ports[homeId] as Map<String, dynamic>?;
    final shoreZoneIds = homePort == null
        ? const <String>[]
        : portZoneIds(homePort)
            .where((id) => zones[id] is Map<String, dynamic>)
            .toList();
    final blockers = campExitBlockers(
      ports: ports,
      zones: zones,
      chapter: chapterOfNode(play.currentNodeId),
      completedZoneIds: session.completedZoneIds,
    );
    final busy =
        ref.watch(combatActiveProvider) || ref.watch(expeditionActiveProvider);

    Widget section(String title, {String? trailing}) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              if (trailing != null)
                Text(trailing, style: theme.textTheme.bodyMedium),
            ],
          ),
        );

    final recruitedIds =
        session.recruitedAllies.map((a) => a.companionId).toList()..sort();
    final partyCapacity = partyCapacityFor(session.builtHouseIds, houses);
    final discoveredHouseIds = [
      for (final id in houses.keys.toList()..sort())
        if (houses[id] is Map<String, dynamic> &&
            houseDiscovered(houses[id] as Map<String, dynamic>, recruitedIds))
          id,
    ];
    // Which houses' shops are browsable: built, with a shop still on file.
    final boutiqueShopIds = session.builtHouseIds
        .map((houseId) =>
            (houses[houseId] as Map<String, dynamic>?)?['unlocksShopId']
                ?.toString() ??
            '')
        .where((shopId) => shopId.isNotEmpty && shops[shopId] is Map)
        .toList()
      ..sort();

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // The camp's name, the purse, and its two ways off the page: the
        // Harbor once built, and the way on (small, it's not the page's
        // point).
        Row(
          children: [
            const Icon(Icons.local_fire_department_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                campNode?.settlement?.nameFor(fr) ?? tr(ref, 'camp_title'),
                style: theme.textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const GoldBadge(),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          children: [
            _RestButton(blocked: busy),
            if (harborBuilt)
              FilledButton.tonalIcon(
                key: const Key('camp_harbor'),
                style: _compact,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HarborScreen()),
                ),
                icon: const Icon(Icons.anchor, size: 18),
                label: Text(tr(ref, 'harbor_title')),
              ),
            if (campNode != null || waitingTown != null)
              OutlinedButton.icon(
                key: const Key('camp_leave'),
                style: _compact,
                onPressed: busy ? null : () => leaveCamp(context, ref),
                icon: const Icon(Icons.logout, size: 18),
                label: Text(waitingTown == null
                    ? tr(ref, 'camp_leave_button')
                    : tr(ref, 'camp_set_out_button').replaceAll(
                        '{place}', waitingTown.settlement?.nameFor(fr) ?? '')),
              ),
          ],
        ),
        // The followed quest stays in view while the story waits.
        if (campNode != null || waitingTown != null)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: QuestTrackerBar(),
          ),
        if (campNode != null) _CampSceneCard(node: campNode),
        if (waitingTown?.settlement != null)
          Card(
            margin: const EdgeInsets.only(top: 12),
            child: ListTile(
              key: const Key('camp_story_waits'),
              leading: const Icon(Icons.location_city_outlined),
              title: Text(tr(ref, 'camp_story_waits')
                  .replaceAll('{place}', waitingTown!.settlement!.nameFor(fr))),
              subtitle:
                  Text(campRouteLabel(ref, waitingTown.settlement!, ports)),
            ),
          ),

        section(tr(ref, 'camp_party_section'),
            trailing: '${tr(ref, 'active_party_label')}: '
                '${session.activeAllyIds.length} / $partyCapacity'),
        if (recruitedIds.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(tr(ref, 'no_companions_recruited')),
          )
        else
          for (final companionId in recruitedIds)
            _AllyCard(
              companionId: companionId,
              companions: companions,
              houses: houses,
              races: races,
              professions: professions,
              gameConfig: gameConfig,
            ),

        section(tr(ref, 'camp_expeditions_section')),
        if (blockers.isNotEmpty && (campNode != null || waitingTown != null))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              tr(ref, 'camp_exit_needs_note'),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
        if (shoreZoneIds.isEmpty)
          Text(tr(ref, 'no_zones_available'))
        else
          for (final zoneId in shoreZoneIds)
            ZoneCard(
              zoneId: zoneId,
              zone: zones[zoneId] as Map<String, dynamic>,
              zones: zones,
              enemies: ref.watch(localizedDbProvider(enemiesSchema)).value ??
                  const <String, dynamic>{},
              enabled: !busy,
              onBegin: () => launchExpedition(
                  context, ref, zoneId, zones[zoneId] as Map<String, dynamic>),
            ),
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(tr(ref, 'camp_sail_section'),
              style: theme.textTheme.titleSmall),
        ),
        Text(
          tr(ref, 'camp_sail_hint'),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        const PortChart(homeOnChart: false),

        section(tr(ref, 'houses_section')),
        for (final houseId in discoveredHouseIds)
          _HouseCard(
            houseId: houseId,
            house: houses[houseId] as Map<String, dynamic>,
            shops: shops,
            zones: zones,
          ),

        section(tr(ref, 'boutiques_section')),
        if (boutiqueShopIds.isEmpty)
          Text(tr(ref, 'no_boutiques_yet'))
        else
          for (final shopId in boutiqueShopIds)
            Card(
              child: ListTile(
                leading: ShopPixelIcon(shopId),
                title: Text((shops[shopId] as Map<String, dynamic>)['shopName']
                        ?.toString() ??
                    shopId),
                subtitle: Text(
                    (shops[shopId] as Map<String, dynamic>)['shopDescription']
                            ?.toString() ??
                        ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ShopDetailScreen(
                        shopId: shopId,
                        shop: shops[shopId] as Map<String, dynamic>),
                  ),
                ),
              ),
            ),
        const SizedBox(height: 16),
      ],
    );
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'camp_title')),
        actions: const [GoldBadge()],
      ),
      body: body,
    );
  }
}

final ButtonStyle _compact = ButtonStyle(
  visualDensity: VisualDensity.compact,
  padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
);

class _RestButton extends ConsumerWidget {
  const _RestButton({required this.blocked});

  final bool blocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Tooltip(
        message: blocked ? tr(ref, 'rest_blocked_hint') : '',
        child: OutlinedButton.icon(
          style: _compact,
          onPressed: blocked
              ? null
              : () async {
                  await ref
                      .read(playerSessionProvider.notifier)
                      .healPartyToFull();
                  if (!context.mounted) return;
                  showImmersiveNotice(
                    context,
                    icon: Icons.local_fire_department,
                    message: tr(ref, 'party_rested_message'),
                  );
                },
          icon: const Icon(Icons.local_fire_department_outlined, size: 18),
          label: Text(tr(ref, 'rest_button')),
        ),
      );
}

/// The camp's scene as the story tells it this visit (what was built, who
/// is back): its opening lines, and the rest a tap away, so the camp's
/// own business stays on screen.
class _CampSceneCard extends ConsumerStatefulWidget {
  const _CampSceneCard({required this.node});

  final StoryNode node;

  @override
  ConsumerState<_CampSceneCard> createState() => _CampSceneCardState();
}

class _CampSceneCardState extends ConsumerState<_CampSceneCard> {
  bool _open = false;

  @override
  void didUpdateWidget(_CampSceneCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.id != widget.node.id) _open = false;
  }

  @override
  Widget build(BuildContext context) {
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final session = ref.watch(playerSessionProvider);
    final text =
        storyBodyFor(composeNarration(widget.node, session, french: fr));
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('camp_scene'),
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(tr(ref, 'camp_scene_title'),
                        style: theme.textTheme.titleSmall),
                  ),
                  Icon(_open ? Icons.expand_less : Icons.expand_more),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                text,
                maxLines: _open ? null : 4,
                overflow: _open ? TextOverflow.visible : TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              if (!_open)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    tr(ref, 'camp_scene_read_all'),
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Puts [companionId] in the party or on the bench, and says which
/// achievements joining earned.
Future<void> _setAllyInParty(
  BuildContext context,
  WidgetRef ref, {
  required String companionId,
  required bool active,
  required int partyCapacity,
  required String requiredHouseId,
}) async {
  final notifier = ref.read(playerSessionProvider.notifier);
  await notifier.setAllyActive(companionId, active,
      partyCapacity: partyCapacity, requiredHouseId: requiredHouseId);
  if (!active) return;
  final earned = await notifier.checkAchievements();
  if (earned.isEmpty || !context.mounted) return;
  final achievements =
      ref.read(localizedDbProvider(achievementsSchema)).value ?? const {};
  showImmersiveNotice(
    context,
    icon: Icons.emoji_events_outlined,
    message:
        '${tr(ref, 'achievement_unlocked_prefix')}: ${earned.map((id) => (achievements[id] as Map<String, dynamic>?)?['achievementName']?.toString() ?? id).join(', ')}',
  );
}

/// Whether [companionId] can join the party now, and if not, why.
({bool canJoin, String reason}) _joinState(
  WidgetRef ref,
  PlayerSession session, {
  required String companionId,
  required Map<String, dynamic>? companion,
  required Map<String, dynamic> houses,
}) {
  if (session.activeAllyIds.contains(companionId)) {
    return (canJoin: true, reason: '');
  }
  final requiredHouseId = companion?['requiredHouseId']?.toString() ?? '';
  if (requiredHouseId.isNotEmpty &&
      !session.builtHouseIds.contains(requiredHouseId)) {
    final houseName =
        (houses[requiredHouseId] as Map<String, dynamic>?)?['houseName']
                ?.toString() ??
            requiredHouseId;
    return (
      canJoin: false,
      reason: '${tr(ref, 'requires_house_prefix')}: $houseName',
    );
  }
  if (session.activeAllyIds.length >=
      partyCapacityFor(session.builtHouseIds, houses)) {
    return (canJoin: false, reason: tr(ref, 'party_at_capacity'));
  }
  return (canJoin: true, reason: '');
}

/// One companion at the fire: who they are, their health, whether they
/// come along, and their gear, skills and dice.
class _AllyCard extends ConsumerWidget {
  const _AllyCard({
    required this.companionId,
    required this.companions,
    required this.houses,
    required this.races,
    required this.professions,
    required this.gameConfig,
  });

  final String companionId;
  final Map<String, dynamic> companions;
  final Map<String, dynamic> houses;
  final Map<String, dynamic> races;
  final Map<String, dynamic> professions;
  final Map<String, dynamic> gameConfig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final companion = companions[companionId] as Map<String, dynamic>?;
    final ally =
        session.recruitedAllies.firstWhere((a) => a.companionId == companionId);
    final raceId = companion?['raceId']?.toString() ?? '';
    final professionId = companion?['professionId']?.toString() ?? '';
    final race = races[raceId] as Map<String, dynamic>? ?? const {};
    final profession =
        professions[professionId] as Map<String, dynamic>? ?? const {};
    final base = deriveAllyBaseStats(
        gameConfig: gameConfig, race: race, profession: profession);
    final liveMaxHealth = scaledMaxHealth(base.maxHealth, session.level);
    final liveHealth = ally.currentHealth.clamp(0, liveMaxHealth);
    final isActive = session.activeAllyIds.contains(companionId);
    final join = _joinState(ref, session,
        companionId: companionId, companion: companion, houses: houses);

    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return Card(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: Icon(isActive ? Icons.shield : Icons.shield_outlined),
              title:
                  Text(companion?['companionName']?.toString() ?? companionId),
              subtitle: Text(
                '${race['raceName'] ?? raceId} '
                '${profession['professionName'] ?? professionId} · '
                '$liveHealth / $liveMaxHealth ${tr(ref, 'hp_label')}'
                '${join.reason.isNotEmpty ? '\n${join.reason}' : ''}',
              ),
              isThreeLine: join.reason.isNotEmpty,
              trailing: FilterChip(
                key: Key('party_toggle_$companionId'),
                label: Text(isActive
                    ? tr(ref, 'active_label')
                    : tr(ref, 'benched_label')),
                selected: isActive,
                onSelected: !join.canJoin
                    ? null
                    : (_) => _setAllyInParty(
                          context,
                          ref,
                          companionId: companionId,
                          active: !isActive,
                          partyCapacity:
                              partyCapacityFor(session.builtHouseIds, houses),
                          requiredHouseId:
                              companion?['requiredHouseId']?.toString() ?? '',
                        ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  style: _compact,
                  onPressed: () => open(InventoryScreen(allyId: companionId)),
                  icon: const Icon(Icons.backpack_outlined, size: 18),
                  label: Text(tr(ref, 'ally_gear_button')),
                ),
                TextButton.icon(
                  style: _compact,
                  onPressed: () => open(SkillsScreen(allyId: companionId)),
                  icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                  label: Text(tr(ref, 'skills')),
                ),
                TextButton.icon(
                  style: _compact,
                  onPressed: () => open(DiceLoadoutScreen(allyId: companionId)),
                  icon: const Icon(Icons.casino_outlined, size: 18),
                  label: Text(tr(ref, 'ally_dice_button')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A camp work: what it is and gives, and Build (or, for the Harbor once
/// built, the way in).
class _HouseCard extends ConsumerWidget {
  const _HouseCard({
    required this.houseId,
    required this.house,
    required this.shops,
    required this.zones,
  });

  final String houseId;
  final Map<String, dynamic> house;
  final Map<String, dynamic> shops;
  final Map<String, dynamic> zones;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final houseName = house['houseName']?.toString() ?? houseId;
    final description = house['description']?.toString() ?? '';
    final cost = (house['buildCost'] as num?)?.toInt() ?? 0;
    final capacityBonus = (house['partyCapacityBonus'] as num?)?.toInt() ?? 0;
    final healthBonus = (house['partyHealthBonus'] as num?)?.toInt() ?? 0;
    final damageBonus = (house['partyDamageBonus'] as num?)?.toInt() ?? 0;
    final unlocksShopId = house['unlocksShopId']?.toString() ?? '';
    final unlocksShopName = unlocksShopId.isNotEmpty
        ? ((shops[unlocksShopId] as Map<String, dynamic>?)?['shopName']
                ?.toString() ??
            unlocksShopId)
        : null;
    final built = session.builtHouseIds.contains(houseId);
    final affordable = session.gold >= cost;
    final requiredFlags = requiredFlagsOf(house);
    final unlocked = meetsRequiredFlags(house, session.flags);
    final lockName =
        unlocked ? null : lockRequirementName(house, session.flags, zones);
    final statsParts = <String>[
      if (capacityBonus > 0)
        '+$capacityBonus ${tr(ref, 'party_capacity_label')}',
      if (healthBonus > 0)
        '+$healthBonus% ${tr(ref, 'party_health_bonus_label')}',
      if (damageBonus > 0)
        '+$damageBonus% ${tr(ref, 'party_damage_bonus_label')}',
      if (unlocksShopName != null)
        '${tr(ref, 'unlocks_shop_prefix')}: $unlocksShopName',
      if (houseId == harborHouseId) tr(ref, 'harbor_unlocks_note'),
      if (!built && lockName != null)
        '${tr(ref, 'requires_zone_prefix')}: $lockName',
    ];

    // The Build button sits under the description, not beside it: beside
    // it, a phone squeezes the text into a narrow column.
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: Icon(built
                  ? Icons.home
                  : unlocked
                      ? Icons.home_outlined
                      : Icons.lock_outline),
              title: Text(houseName),
              subtitle: Text([
                description,
                if (statsParts.isNotEmpty) statsParts.join(' · '),
              ].where((s) => s.isNotEmpty).join('\n')),
              trailing: built
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
            if (built && houseId == harborHouseId)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HarborScreen()),
                    ),
                    icon: const Icon(Icons.anchor),
                    label: Text(tr(ref, 'harbor_open_button')),
                  ),
                ),
              ),
            if (!built)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    key: Key('build_$houseId'),
                    onPressed: (!affordable || !unlocked)
                        ? null
                        : () async {
                            final notifier =
                                ref.read(playerSessionProvider.notifier);
                            await notifier.buildHouse(houseId, cost,
                                unlocksShopId: unlocksShopId,
                                requiredFlags: requiredFlags);
                            final earned = await notifier.checkAchievements();
                            if (!context.mounted) return;
                            final achievements = ref
                                    .read(
                                        localizedDbProvider(achievementsSchema))
                                    .value ??
                                const {};
                            final suffix = earned.isEmpty
                                ? ''
                                : '\n${tr(ref, 'achievement_unlocked_prefix')}: '
                                    '${earned.map((id) => (achievements[id] as Map<String, dynamic>?)?['achievementName']?.toString() ?? id).join(', ')}';
                            showImmersiveNotice(
                              context,
                              icon: Icons.home,
                              message:
                                  '${tr(ref, 'house_built_prefix')}: $houseName$suffix',
                            );
                          },
                    child: Text(
                        '${tr(ref, 'build_button')} ($cost ${tr(ref, 'gold_label')})'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The way on from the camp: once the expeditions on its shore are
/// cleared, a last look at who comes along, then the story's own ways out
/// of the camp's scene, or (gone back to the camp from a town) the way
/// back to that town. Until then, what is left to clear.
Future<void> leaveCamp(BuildContext context, WidgetRef ref) async {
  final zones = ref.read(localizedDbProvider(zonesSchema)).value ?? const {};
  final ports = ref.read(localizedDbProvider(portsSchema)).value ?? const {};
  final play = ref.read(storyPlayProvider);
  final blockers = campExitBlockers(
    ports: ports,
    zones: zones,
    chapter: chapterOfNode(play.currentNodeId),
    completedZoneIds: ref.read(playerSessionProvider).completedZoneIds,
  );
  if (blockers.isNotEmpty) {
    final fr = ref.read(appLanguageProvider) == AppLanguage.fr;
    String zoneName(String id) {
      final zone = zones[id] as Map<String, dynamic>?;
      final name = zone?['zoneName']?.toString() ?? id;
      final nameFr = zone?['zoneName_fr']?.toString() ?? '';
      return fr && nameFr.isNotEmpty ? nameFr : name;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.flag_outlined),
        title: Text(tr(ref, 'camp_exit_blocked_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(ref, 'camp_exit_blocked_body')),
            const SizedBox(height: 8),
            for (final id in blockers)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.explore_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(zoneName(id))),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(tr(ref, 'close_button')),
          ),
        ],
      ),
    );
    return;
  }
  final picked = await showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _LeaveCampSheet(),
  );
  if (picked == null || !context.mounted) return;
  if (picked is StoryChoice) {
    await takeStoryChoice(context, ref, picked);
  } else if (picked == _setOut) {
    await travelToWaitingTown(context, ref);
  }
}

/// The leave sheet's answer when the party sets out for the town where the
/// story waits.
const Object _setOut = 'set_out';

/// Who comes along (changeable here), then the camp scene's ways out.
class _LeaveCampSheet extends ConsumerWidget {
  const _LeaveCampSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final session = ref.watch(playerSessionProvider);
    final story = ref.watch(storyDataProvider).value;
    final node = story?.nodeFor(ref.watch(storyPlayProvider).currentNodeId);
    final companions =
        ref.watch(localizedDbProvider(companionsSchema)).value ?? const {};
    final houses =
        ref.watch(localizedDbProvider(housesSchema)).value ?? const {};
    final ports = ref.watch(localizedDbProvider(portsSchema)).value ?? const {};
    final theme = Theme.of(context);
    // Gone back to the camp from a town, the way on is back to that town;
    // at the camp's own scene, its ways out.
    final waitingTown = node != null &&
            !(node.settlement?.isCamp ?? false) &&
            session.campVisitFromNodeId == node.id
        ? node.settlement
        : null;
    final choices = node == null || story == null || waitingTown != null
        ? const <StoryChoice>[]
        : node.choices.where((c) => !c.isHiddenFor(session.flags)).toList();
    final recruitedIds =
        session.recruitedAllies.map((a) => a.companionId).toList()..sort();
    final capacity = partyCapacityFor(session.builtHouseIds, houses);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr(ref, 'camp_leave_title'),
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              '${tr(ref, 'camp_party_section')} '
              '(${session.activeAllyIds.length} / $capacity)',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            if (recruitedIds.isEmpty)
              Text(tr(ref, 'camp_leave_alone'),
                  style: theme.textTheme.bodyMedium)
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final id in recruitedIds)
                    Builder(builder: (chipContext) {
                      final companion = companions[id] as Map<String, dynamic>?;
                      final active = session.activeAllyIds.contains(id);
                      final join = _joinState(ref, session,
                          companionId: id,
                          companion: companion,
                          houses: houses);
                      return Tooltip(
                        message: join.reason,
                        child: FilterChip(
                          key: Key('leave_party_$id'),
                          label: Text(
                              companion?['companionName']?.toString() ?? id),
                          selected: active,
                          onSelected: !join.canJoin
                              ? null
                              : (_) => _setAllyInParty(
                                    context,
                                    ref,
                                    companionId: id,
                                    active: !active,
                                    partyCapacity: capacity,
                                    requiredHouseId:
                                        companion?['requiredHouseId']
                                                ?.toString() ??
                                            '',
                                  ),
                        ),
                      );
                    }),
                ],
              ),
            // Why a companion can't come, under the chips.
            for (final id in recruitedIds)
              if (!_joinState(ref, session,
                      companionId: id,
                      companion: companions[id] as Map<String, dynamic>?,
                      houses: houses)
                  .canJoin)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${(companions[id] as Map<String, dynamic>?)?['companionName'] ?? id}: '
                    '${_joinState(ref, session, companionId: id, companion: companions[id] as Map<String, dynamic>?, houses: houses).reason}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
            const SizedBox(height: 16),
            Text(tr(ref, 'camp_leave_way_label'),
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            if (waitingTown != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: FilledButton.tonal(
                  key: const Key('leave_set_out'),
                  style: FilledButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(_setOut),
                  child: Text(
                    '${tr(ref, 'camp_set_out_button').replaceAll('{place}', waitingTown.nameFor(fr))}'
                    ' · ${campRouteLabel(ref, waitingTown, ports)}',
                  ),
                ),
              ),
            for (final choice in choices)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: FilledButton.tonal(
                  key: Key('leave_choice_${choice.nextId}'),
                  style: FilledButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onPressed: isStoryChoiceLocked(choice, story!, session)
                      ? null
                      : () => Navigator.of(context).pop(choice),
                  child: Text(choice.textFor(fr)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
