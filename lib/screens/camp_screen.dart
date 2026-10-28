import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/camp_state.dart';
import '../data/harbour.dart' show harbourAwaited;
import '../data/narration_clips.dart' show storyBodyFor;
import '../data/politics_events.dart' show ChoiceGate;
import '../data/materials.dart' show materialCountsOf;
import '../data/port_helpers.dart';
import '../data/zone_gating.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/chapter_loop_provider.dart';
import '../providers/combat_active_provider.dart';
import '../providers/expedition_active_provider.dart';
import '../providers/game_config_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/politics_provider.dart';
import '../providers/story_providers.dart';
import '../theme/stitched_ink.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import '../widgets/level_signpost.dart';
import '../widgets/road_panel.dart';
import '../widgets/player_stats_bar.dart';
import '../widgets/camp_town_section.dart';
import '../widgets/bounty_board.dart';
import '../widgets/ink_fold.dart';
import '../widgets/coast_news.dart';
import '../widgets/camp_travel.dart';
import '../widgets/party_formation.dart';
import '../widgets/pixel_sprite.dart';
import '../widgets/quest_tracker.dart';
import '../widgets/ship_widgets.dart';
import '../widgets/zone_card.dart';
import 'harbor_screen.dart';
import 'port_screen.dart';
import 'shop_detail_screen.dart';
import 'story_player_screen.dart'
    show composeNarration, isStoryChoiceLocked, takeStoryChoice;
import '../data/story_markup.dart' show stripStoryMarkup;

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
    // What the harbour costs, as the card says it: its materials (the
    // story's grant, see harbour.dart), and its gold if any.
    final harbourRecord = houses[harborHouseId] as Map<String, dynamic>?;
    final harbourGold = (harbourRecord?['buildCost'] as num?)?.toInt() ?? 0;
    final itemNames =
        ref.watch(localizedDbProvider(itemsSchema)).value ?? const {};
    final harbourCost = [
      for (final MapEntry(key: id, value: count)
          in materialCountsOf(harbourRecord, 'materialCost').entries)
        '$count ${(itemNames[id] as Map?)?['itemName'] ?? id}',
      if (harbourGold > 0) '$harbourGold ${tr(ref, 'gold_label')}',
    ].join(', ');
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

    final tab = ref.watch(campTabProvider);
    final progress = ref.watch(chapterProgressProvider);
    // The camp's scene: a card until it has been read, then a chip.
    final sceneText = campNode == null
        ? ''
        : storyBodyFor(composeNarration(campNode, session, french: fr));
    final sceneKey =
        campNode == null ? null : sceneReadKey(campNode.id, sceneText);
    final sceneRead =
        sceneKey != null && session.readSceneKeys.contains(sceneKey);
    final subtitle = [
      if (progress != null) '${progress.loop.label} · ${progress.loop.title}',
      '${tr(ref, 'day_label').replaceAll('{n}', '${session.day}')}, '
          '${tr(ref, 'watch_${session.watch}').toLowerCase()}',
    ].join(' · ');

    final List<Widget> tabContent = switch (tab) {
      // Each section folds (v1.201), the fold kept for the session.
      CampTab.road => [
          if (campNode != null)
            InkFold(
              id: 'camp_places',
              title: tr(ref, 'places_section'),
              count: places.length,
              children: [
                if (places.isEmpty)
                  Text(tr(ref, 'places_empty'),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
                else
                  for (final place in places) PlaceCard(place: place),
              ],
            ),
          InkFold(
            id: 'camp_expeditions',
            title: tr(ref, 'camp_expeditions_section'),
            count: shoreZoneIds.length,
            children: [
              if (shoreZoneIds.isEmpty)
                Text(tr(ref, 'no_zones_available'))
              else
                for (final zoneId in shoreZoneIds)
                  ZoneCard(
                    zoneId: zoneId,
                    zone: zones[zoneId] as Map<String, dynamic>,
                    zones: zones,
                    enemies:
                        ref.watch(localizedDbProvider(enemiesSchema)).value ??
                            const <String, dynamic>{},
                    enabled: !busy,
                    onBegin: () => launchExpedition(context, ref, zoneId,
                        zones[zoneId] as Map<String, dynamic>),
                  ),
            ],
          ),
          if (campNode != null)
            // Short goals for ordinary fights, paid at the camp (v1.162).
            InkFold(
              id: 'camp_bounties',
              title: tr(ref, 'bounty_board_section'),
              children: const [BountyBoard()],
            ),
        ],
      // The camp's town on the cliff: what has been built, and the tray
      // to build more. A house tied to a companion waits for them.
      CampTab.town => [
          const SizedBox(height: 12),
          CampTownSection(
            houses: {
              for (final id in discoveredHouseIds) id: houses[id],
            },
            shops: shops,
            zones: zones,
            achievements:
                ref.watch(localizedDbProvider(achievementsSchema)).value ??
                    const <String, dynamic>{},
            harborAction: harborBuilt
                ? TutorialTarget(
                    id: 'camp.boat',
                    child: OutlinedButton.icon(
                      key: const Key('town_harbor'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HarborScreen()),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        backgroundColor: const Color(0xE614262A),
                        foregroundColor: const Color(0xFFECE7DC),
                        side: const BorderSide(color: Color(0xFF4FB0B0)),
                        textStyle: const TextStyle(
                            fontFamily: 'PixelifySans', fontSize: 12),
                      ),
                      icon: const Icon(Icons.anchor, size: 16),
                      label: Text(tr(ref, 'harbor_title')),
                    ),
                  )
                : null,
          ),
          InkFold(
            id: 'camp_boutiques',
            title: tr(ref, 'boutiques_section'),
            count: boutiqueShopIds.length,
            children: [
              if (boutiqueShopIds.isEmpty)
                Text(tr(ref, 'no_boutiques_yet'))
              else
                for (final shopId in boutiqueShopIds)
                  Card(
                    child: ListTile(
                      leading: ShopPixelIcon(shopId),
                      title: Text(
                          (shops[shopId] as Map<String, dynamic>)['shopName']
                                  ?.toString() ??
                              shopId),
                      subtitle: Text((shops[shopId]
                                  as Map<String, dynamic>)['shopDescription']
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
            ],
          ),
        ],
      CampTab.party => [
          section(tr(ref, 'camp_party_section'),
              trailing: '${tr(ref, 'active_party_label')}: '
                  '${session.activeAllyIds.length} / $partyCapacity'),
          PartyFormation(houses: houses),
        ],
      // The Eel, her harbour (or what building it would give), and the
      // chart to sail by.
      CampTab.sea => [
          const SizedBox(height: 12),
          const ShipStatusCard(),
          const SizedBox(height: 8),
          _HarbourCard(built: harborBuilt, cost: harbourCost),
          section(tr(ref, 'camp_sail_section')),
          Text(
            tr(ref, 'camp_sail_hint'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          const PortChart(homeOnChart: false),
        ],
    };

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // One header: the camp, its chapter and the hour, and the purse.
        Row(
          children: [
            // The camp's fire (v1.216): a pixel flame that flickers.
            const SizedBox(
              width: 36,
              height: 36,
              child: PixelSprite(
                name: 'campfire',
                frames: 6,
                frameSize: 18,
                scale: 2,
                fps: 7,
                loop: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campNode?.settlement?.nameFor(fr) ?? tr(ref, 'camp_title'),
                    style: theme.textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    key: const Key('camp_subtitle'),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: InkColors.of(context).ash),
                  ),
                ],
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
            if (campNode != null && sceneRead)
              _SceneChip(title: tr(ref, 'camp_scene_title'), text: sceneText),
            // What the clans did meanwhile (v1.195): the news from the
            // coast not read yet, a tap away.
            if (campNode != null) const CoastNewsChip(),
          ],
        ),
        // The followed quest stays in view.
        if (campNode != null)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: QuestTrackerBar(),
          ),
        if (campNode != null && !sceneRead)
          _CampSceneCard(text: sceneText, sceneKey: sceneKey!),
        if (campNode != null)
          TutorialTarget(
            id: 'camp.next',
            child: _ChapterCard(campNode: campNode, busy: busy),
          ),
        // The camp's first work, until it stands (see harbour.dart): the
        // camp's tour points at it.
        if (harbourAwaited(
            flags: session.flags, builtHouseIds: session.builtHouseIds)) ...[
          const SizedBox(height: 12),
          TutorialTarget(
            id: 'camp.harbour',
            child: _HarbourCard(built: false, cost: harbourCost, first: true),
          ),
        ],
        const SizedBox(height: 12),
        _CampTabs(selected: tab),
        ...tabContent,
        const SizedBox(height: 16),
      ],
    );
    final triggered = TutorialTrigger(topic: TutorialTopic.camp, child: body);
    if (embedded) return triggered;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'camp_title')),
        actions: const [GoldBadge()],
      ),
      body: triggered,
    );
  }
}

/// The next step: the chapter's main quest as a checklist -- each place
/// still to visit (a tap goes to the Road), how much of the chapter is
/// explored, its quests settled -- and the way in once they are done. Any
/// other way on from the camp's scene follows.
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
    final ink = InkColors.of(context);
    // A choice behind a politics gate that fails (v1.196) is hidden, or
    // shut with its locked text.
    final gateWorld = ref.watch(coastGateWorldProvider);
    // The camp errands follow the camp's own ways (see camp_errands.dart).
    final visible = [
      ...campNode.choices,
      ...ref.watch(campErrandChoicesProvider)
    ].where((c) => !choiceHiddenFor(c, session, gateWorld)).toList();
    bool shut(StoryChoice c) =>
        story == null ||
        isStoryChoiceLocked(c, story, session, world: gateWorld);
    String label(StoryChoice c) =>
        choiceGateFor(c, session, gateWorld) == ChoiceGate.locked
            ? c.lockedTextFor(fr) ?? c.textFor(fr)
            : c.textFor(fr);
    final mainChoices = visible.where((c) => c.mainQuest).toList();
    final otherChoices = visible.where((c) => !c.mainQuest).toList();
    final open = progress?.mainQuestOpen ?? true;
    final companionLeads = ref.watch(companionLeadsProvider);
    String placeName(String id) =>
        story?.nodeFor(id)?.settlement?.nameFor(fr) ?? id;

    // One line of the checklist: ticked or not, what, and how far.
    Widget step({
      required Key key,
      required bool done,
      required String text,
      String? sub,
      VoidCallback? onTap,
    }) {
      final line = Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18, color: done ? ink.heal : ink.ash),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    onTap == null ? text : '$text ›',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onTap != null ? ink.tide : null,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (sub != null)
                    Text(sub,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ink.ash)),
                ],
              ),
            ),
          ],
        ),
      );
      return onTap == null
          ? KeyedSubtree(key: key, child: line)
          : InkWell(key: key, onTap: onTap, child: line);
    }

    var stepsLeft = 0;
    final steps = <Widget>[];
    if (progress != null && !open) {
      for (final id in progress.missingPlaceIds) {
        stepsLeft++;
        steps.add(step(
          key: Key('next_place_$id'),
          done: false,
          text:
              tr(ref, 'next_visit_place').replaceAll('{place}', placeName(id)),
          sub: tr(ref, 'next_visit_place_sub'),
          onTap: () => ref.read(campTabProvider.notifier).state = CampTab.road,
        ));
      }
    }
    if (progress != null && progress.goal > 0) {
      final done = progress.done >= progress.goal;
      if (!done) stepsLeft++;
      steps.add(step(
        key: const Key('chapter_progress'),
        done: done,
        text: tr(ref, 'chapter_progress')
            .replaceAll('{done}', '${progress.done.clamp(0, progress.goal)}')
            .replaceAll('{goal}', '${progress.goal}'),
        sub: done ? null : tr(ref, 'next_explore_sub'),
      ));
    }
    if (progress != null && progress.questGoal > 0) {
      final done = progress.questsDone >= progress.questGoal;
      if (!done) stepsLeft++;
      steps.add(step(
        key: const Key('chapter_quests_progress'),
        done: done,
        text: tr(ref, 'chapter_quests_progress')
            .replaceAll(
                '{done}', '${progress.questsDone.clamp(0, progress.questGoal)}')
            .replaceAll('{goal}', '${progress.questGoal}'),
      ));
    }

    return Container(
      key: const Key('chapter_card'),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ink.gold),
        color: ink.gold.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (progress != null) ...[
            Row(children: [
              Icon(open ? Icons.flag : Icons.flag_outlined,
                  size: 16, color: ink.gold),
              const SizedBox(width: 6),
              // Longer in French: cut short rather than overflow.
              Flexible(
                child: Text(
                    (open
                            ? tr(ref, 'main_quest_open_label')
                            : tr(ref, 'next_main_quest_label'))
                        .toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: ink.gold, letterSpacing: 1)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(progress.loop.mainQuestTitle,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontFamily: InkFonts.display)),
            if (!open && progress.loop.mainQuestHint.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(progress.loop.mainQuestHint,
                  style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
            ],
            const SizedBox(height: 6),
            ...steps,
            // The level the next chapter asks, while the party is under it.
            const LevelSignpostRow(),
            // Word of a companion to meet, so a party in a hurry does not
            // walk past them.
            for (final placeId in companionLeads.keys)
              Padding(
                key: Key('companion_hint_$placeId'),
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.person_add_alt_1_outlined,
                        size: 18, color: ink.voidColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr(ref, 'companion_hint')
                            .replaceAll('{place}', placeName(placeId)),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          for (final choice in mainChoices)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    key: Key('main_quest_${choice.nextId}'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onPressed: busy || !open || shut(choice)
                        ? null
                        : () => setOutOnMainQuest(context, ref, choice),
                    child: Text(label(choice), textAlign: TextAlign.center),
                  ),
                  if (!open && stepsLeft > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        stepsLeft == 1
                            ? tr(ref, 'steps_left_one')
                            : tr(ref, 'steps_left_many')
                                .replaceAll('{n}', '$stepsLeft'),
                        key: const Key('main_quest_steps_left'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ink.ash),
                      ),
                    ),
                ],
              ),
            ),
          for (final choice in otherChoices)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton(
                key: Key('camp_choice_${choice.nextId}'),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: busy || shut(choice)
                    ? null
                    : () => takeStoryChoice(context, ref, choice),
                child: Text(label(choice)),
              ),
            ),
        ],
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
              : () => restTheNight(context, ref,
                  message: tr(ref, 'party_rested_message'), atCamp: true),
          icon: const Icon(Icons.local_fire_department_outlined, size: 18),
          label: Text(tr(ref, 'rest_button')),
        ),
      );
}

/// The camp's scene as the story tells it this visit (what was built, who
/// is back): its opening lines, the rest a tap away. Once read (put away)
/// it folds to a chip beside Rest (see [_SceneChip]).
class _CampSceneCard extends ConsumerStatefulWidget {
  const _CampSceneCard({required this.text, required this.sceneKey});

  final String text;
  final String sceneKey;

  @override
  ConsumerState<_CampSceneCard> createState() => _CampSceneCardState();
}

class _CampSceneCardState extends ConsumerState<_CampSceneCard> {
  bool _open = false;

  @override
  void didUpdateWidget(_CampSceneCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sceneKey != widget.sceneKey) _open = false;
  }

  @override
  Widget build(BuildContext context) {
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
                stripStoryMarkup(widget.text),
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
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('camp_scene_done'),
                    onPressed: () => ref
                        .read(playerSessionProvider.notifier)
                        .markSceneRead(widget.sceneKey),
                    child: Text(tr(ref, 'camp_scene_put_away')),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A camp scene already read: a chip that opens it again in a sheet.
class _SceneChip extends StatelessWidget {
  const _SceneChip({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('camp_scene_chip'),
      style: _compact,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(sheetContext).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(stripStoryMarkup(text),
                    style: Theme.of(sheetContext)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.5)),
              ],
            ),
          ),
        ),
      ),
      icon: const Icon(Icons.menu_book_outlined, size: 18),
      label: Text(title),
    );
  }
}

/// The camp's four jobs, one at a time: the road out, the town on the
/// cliff, the party, and the sea.
enum CampTab { road, town, party, sea }

/// The camp tab showing; kept while the player goes and comes back.
final campTabProvider = StateProvider<CampTab>((ref) => CampTab.road);

class _CampTabs extends ConsumerWidget {
  const _CampTabs({required this.selected});

  final CampTab selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = InkColors.of(context);
    final theme = Theme.of(context);
    final placesWaiting = ref.watch(companionLeadsProvider).isNotEmpty;
    Widget tab(CampTab t, IconData icon, String label, String tourId,
        {bool dot = false}) {
      final on = t == selected;
      return Expanded(
        child: TutorialTarget(
          id: tourId,
          child: InkWell(
            key: Key('camp_tab_${t.name}'),
            onTap: () => ref.read(campTabProvider.notifier).state = t,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: on ? ink.gold : ink.seam, width: on ? 2 : 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: on ? ink.gold : ink.ash),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(label,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: on ? null : ink.ash)),
                  ),
                  if (dot) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: ink.gold, shape: BoxShape.circle),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: [
      tab(CampTab.road, Icons.route_outlined, tr(ref, 'camp_tab_road'),
          'camp.road',
          dot: placesWaiting),
      tab(CampTab.town, Icons.holiday_village_outlined,
          tr(ref, 'camp_tab_town'), 'camp.town'),
      tab(CampTab.party, Icons.groups_outlined, tr(ref, 'camp_tab_party'),
          'camp.roster'),
      tab(CampTab.sea, Icons.anchor, tr(ref, 'camp_tab_sea'), 'camp.sail'),
    ]);
  }
}

/// The harbour in the Sea tab: the way to refit the Eel once it stands,
/// and before that what building it gives and costs (a tap goes to Town).
class _HarbourCard extends ConsumerWidget {
  const _HarbourCard(
      {required this.built, required this.cost, this.first = false});

  final bool built;

  /// The card above the camp's tabs, while the harbour is awaited (the Sea
  /// tab keeps its own).
  final bool first;

  /// What building it costs, as the card says it ("4 Timber, 2 Cut Stone").
  final String cost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = InkColors.of(context);
    final theme = Theme.of(context);
    final colour = built ? ink.tide : ink.gold;
    return InkWell(
      key: Key(first
          ? 'camp_harbour_first'
          : built
              ? 'camp_harbor'
              : 'camp_harbor_locked'),
      borderRadius: BorderRadius.circular(10),
      onTap: built
          ? () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const HarborScreen()))
          : () => ref.read(campTabProvider.notifier).state = CampTab.town,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colour),
          color: colour.withValues(alpha: 0.06),
        ),
        child: Row(children: [
          Icon(Icons.anchor, color: colour),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    built
                        ? tr(ref, 'harbor_title')
                        : tr(ref, 'harbour_not_built_title'),
                    style: theme.textTheme.titleSmall?.copyWith(color: colour)),
                Text(
                  built
                      ? tr(ref, 'harbour_built_body')
                      : tr(ref, 'harbour_not_built_body')
                          .replaceAll('{cost}', cost),
                  style: theme.textTheme.bodySmall?.copyWith(color: ink.ash),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colour),
        ]),
      ),
    );
  }
}
