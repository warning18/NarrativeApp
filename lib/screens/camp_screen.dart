import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_engine.dart';
import '../data/camp_state.dart';
import '../data/port_helpers.dart';
import '../data/zone_gating.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/ally_state.dart';
import '../models/story_node.dart';
import '../providers/chapter_loop_provider.dart';
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

/// The party's camp from chapter 3, its base: the story stands here
/// between trips. What happened on coming back, the open chapter (how much
/// of it is done, and its main quest once it opens), the places the party
/// knows and can travel to, who comes along, the expeditions on its shore
/// and the voyages out, what has been built, and its shops. While the
/// party is here the Story tab gives way to this page.
class CampScreen extends ConsumerWidget {
  const CampScreen({super.key, this.embedded = false});

  /// True as the in-game Camp tab: the page without its own app bar, with
  /// the camp's scene and its chapter. Opened from Edit Mode, it is the
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
    final reached = ref.watch(reachedChapterProvider);
    // The camp's own shore: its expeditions of the chapters reached so far
    // (a chapter's main zone is its main quest's, never offered here).
    final shoreZoneIds = homePort == null
        ? const <String>[]
        : portZoneIds(homePort)
            .where((id) => zones[id] is Map<String, dynamic>)
            .where((id) => !zoneIsMain(zones[id] as Map<String, dynamic>))
            .where((id) =>
                (((zones[id] as Map<String, dynamic>)['chapter'] as num?)
                        ?.toInt() ??
                    1) <=
                reached)
            .toList();
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
    final places = ref.watch(knownPlacesProvider);

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // The camp's name, the purse, and the Harbor once built.
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
          ],
        ),
        // The followed quest stays in view.
        if (campNode != null)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: QuestTrackerBar(),
          ),
        if (campNode != null) _CampSceneCard(node: campNode),
        if (campNode != null) _ChapterCard(campNode: campNode, busy: busy),

        if (campNode != null) ...[
          section(tr(ref, 'places_section')),
          if (places.isEmpty)
            Text(tr(ref, 'places_empty'),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
          else
            for (final place in places) PlaceCard(place: place),
        ],

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

/// The open chapter at its camp: its name, how much of it is done, and its
/// main quest -- shut, with what it still needs, or open, with the camp's
/// way into it. Any other way on from the camp's scene follows.
class _ChapterCard extends ConsumerWidget {
  const _ChapterCard({required this.campNode, required this.busy});

  final StoryNode campNode;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fr = ref.watch(appLanguageProvider) == AppLanguage.fr;
    final progress = ref.watch(chapterProgressProvider);
    final story = ref.watch(storyDataProvider).value;
    final session = ref.watch(playerSessionProvider);
    final theme = Theme.of(context);
    final visible =
        campNode.choices.where((c) => !c.isHiddenFor(session.flags)).toList();
    final mainChoices = visible.where((c) => c.mainQuest).toList();
    final otherChoices = visible.where((c) => !c.mainQuest).toList();
    final open = progress?.mainQuestOpen ?? true;
    String placeName(String id) =>
        story?.nodeFor(id)?.settlement?.nameFor(fr) ?? id;

    return Card(
      key: const Key('chapter_card'),
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (progress != null) ...[
              Text(progress.loop.label,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.primary)),
              Text(progress.loop.title, style: theme.textTheme.titleMedium),
              if (progress.goal > 0) ...[
                const SizedBox(height: 8),
                Text(
                  tr(ref, 'chapter_progress')
                      .replaceAll(
                          '{done}', '${progress.done.clamp(0, progress.goal)}')
                      .replaceAll('{goal}', '${progress.goal}'),
                  key: const Key('chapter_progress'),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress.goal == 0
                      ? 1
                      : (progress.done / progress.goal).clamp(0.0, 1.0),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(open ? Icons.flag : Icons.flag_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${tr(ref, 'main_quest_label')}: '
                      '${progress.loop.mainQuestTitle}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              if (!open) ...[
                const SizedBox(height: 4),
                if (progress.loop.mainQuestHint.isNotEmpty)
                  Text(progress.loop.mainQuestHint,
                      style: theme.textTheme.bodySmall),
                for (final id in progress.missingPlaceIds)
                  Text(
                    tr(ref, 'main_quest_needs_place')
                        .replaceAll('{place}', placeName(id)),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
              ],
            ],
            for (final choice in mainChoices)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton(
                  key: Key('main_quest_${choice.nextId}'),
                  style: FilledButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onPressed: busy ||
                          !open ||
                          story == null ||
                          isStoryChoiceLocked(choice, story, session)
                      ? null
                      : () => setOutOnMainQuest(context, ref, choice),
                  child: Text(choice.textFor(fr)),
                ),
              ),
            for (final choice in otherChoices)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton(
                  key: Key('camp_choice_${choice.nextId}'),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onPressed: busy ||
                          story == null ||
                          isStoryChoiceLocked(choice, story, session)
                      ? null
                      : () => takeStoryChoice(context, ref, choice),
                  child: Text(choice.textFor(fr)),
                ),
              ),
          ],
        ),
      ),
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
