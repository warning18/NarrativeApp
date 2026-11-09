// The hub view of a place: its sections, the enter button, the settlement
// arrival and the detour card, cut out of story_player_screen.dart
// with no change.
part of '../story_player_screen.dart';

/// Presents a hub node as a place: a Rest option, then what can be done
/// here -- its boutiques (the story's shops and, in a town, the port's own),
/// its expeditions (a town's or camp's zones), its people and its
/// challenges -- and only after all of that, the way onward. Choices whose
/// scene leads back to the hub are the place's own; any other choice moves
/// the story on and sits under "Onward" (folded away in a town, under a
/// "Leave" header, so the town reads as a town first). Reuses
/// [_selectChoice] for the actual effect/routing logic, so a card behaves
/// exactly like a [_ChoiceButton] would have.
class _HubSections extends ConsumerWidget {
  const _HubSections({
    required this.node,
    required this.choices,
    this.done = const [],
    required this.story,
    required this.session,
    required this.currentNodeId,
    required this.isExcursion,
    required this.french,
    required this.maxHeight,
    this.onReread,
  });

  /// Opens the place's scene again (its card's Reread); null when the
  /// place has no scene to fold.
  final VoidCallback? onReread;

  /// The most height the whole hub block may take (see the story view's
  /// choice budget); its services and its way onward scroll within it.
  final double maxHeight;

  final StoryNode node;
  final List<StoryChoice> choices;

  /// The hub's finished activities (their `hideIfFlags` marker is set):
  /// listed greyed under their section, and counted in the header.
  final List<StoryChoice> done;
  final StoryData story;
  final PlayerSession session;
  final String currentNodeId;
  final bool isExcursion;
  final bool french;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local =
        choices.where((c) => isLocalChoice(c, node.id, story)).toList();
    final onward =
        choices.where((c) => !isLocalChoice(c, node.id, story)).toList();
    final doneLocal =
        done.where((c) => isLocalChoice(c, node.id, story)).toList();
    List<StoryChoice> of(_HubCategory? category) =>
        local.where((c) => _hubCategoryFor(c) == category).toList();
    List<StoryChoice> doneOf(Set<_HubCategory?> categories) => doneLocal
        .where((c) => categories.contains(_hubCategoryFor(c)))
        .toList();
    final shopChoices = of(_HubCategory.shop);
    final challenges = of(_HubCategory.challenge);
    final people = [...of(_HubCategory.people), ...of(null)];

    // A town's port: its own shops (those the story isn't offering as a
    // scene right now) and its expeditions.
    final settlement = node.settlement;
    // Once the camp stands, it is where the party sleeps: resting in a town
    // means walking back to it.
    final restsAtCamp = settlement != null &&
        !settlement.isCamp &&
        session.flags.contains(campFoundedFlag);
    final travelsFromHere = !isExcursion &&
        canReturnToCampFrom(node,
            inExcursion: isExcursion, flags: session.flags);
    final travelsOn = travelsFromHere &&
        ref.watch(knownPlacesProvider).any((p) => p.id != node.id);
    final ports = ref.watch(localizedDbProvider(portsSchema)).value;
    final shopsDb = ref.watch(localizedDbProvider(shopsSchema)).value;
    final zones = ref.watch(localizedDbProvider(zonesSchema)).value;
    final enemies = ref.watch(localizedDbProvider(enemiesSchema)).value ??
        const <String, dynamic>{};
    final port = settlement?.portId == null
        ? null
        : ports?[settlement!.portId] as Map<String, dynamic>?;
    final storyShopIds = {for (final c in shopChoices) c.unlockShopId};
    final portShops = port == null || shopsDb == null
        ? const <String>[]
        : portShopIds(port)
            .where((id) =>
                shopsDb[id] is Map<String, dynamic> &&
                !storyShopIds.contains(id))
            .toList();
    final portZones = port == null || zones == null
        ? const <String>[]
        : portZoneIds(port)
            .where((id) => zones[id] is Map<String, dynamic>)
            .toList();
    final expeditionBlocked =
        ref.watch(combatActiveProvider) || ref.watch(expeditionActiveProvider);

    Widget doneRow(StoryChoice choice) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(Icons.check_circle,
                  size: 16, color: Theme.of(context).colorScheme.outline),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  choice.textFor(french),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        decoration: TextDecoration.lineThrough,
                      ),
                ),
              ),
            ],
          ),
        );

    Widget card(StoryChoice choice) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _HubChoiceCard(
            choice: choice,
            story: story,
            session: session,
            currentNodeId: currentNodeId,
            isExcursion: isExcursion,
            french: french,
          ),
        );

    Widget portShopTile(String shopId) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            child: ListTile(
              leading: ShopPixelIcon(shopId),
              title: Text((shopsDb![shopId] as Map<String, dynamic>)['shopName']
                      ?.toString() ??
                  shopId),
              subtitle: Text(
                (shopsDb[shopId] as Map<String, dynamic>)['shopDescription']
                        ?.toString() ??
                    '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ShopDetailScreen(
                    shopId: shopId,
                    shop: shopsDb[shopId] as Map<String, dynamic>,
                  ),
                ),
              ),
            ),
          ),
        );

    Widget zoneTile(String zoneId) => ZoneCard(
          zoneId: zoneId,
          zone: zones![zoneId] as Map<String, dynamic>,
          zones: zones,
          enemies: enemies,
          enabled: !expeditionBlocked,
          onBegin: () async {
            ref.read(expeditionActiveProvider.notifier).state = true;
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExpeditionScreen(
                    zoneId: zoneId,
                    zone: zones[zoneId] as Map<String, dynamic>),
              ),
            );
            ref.read(expeditionActiveProvider.notifier).state = false;
          },
        );

    // The place's activities, a group per kind: each is a tab of its own
    // (see _HubTab), and All lists them one under the other.
    final groups = <_HubGroup>[
      _HubGroup(
        id: 'shops',
        title: tr(ref, 'hub_shops_section'),
        icon: Icons.storefront_outlined,
        open: shopChoices.length + portShops.length,
        items: [
          for (final choice in shopChoices) card(choice),
          for (final shopId in portShops) portShopTile(shopId),
          for (final choice in doneOf({_HubCategory.shop})) doneRow(choice),
        ],
      ),
      _HubGroup(
        id: 'expeditions',
        title: tr(ref, 'hub_expeditions_section'),
        icon: Icons.explore_outlined,
        open: portZones.length,
        items: [for (final zoneId in portZones) zoneTile(zoneId)],
      ),
      _HubGroup(
        id: 'people',
        title: tr(ref, 'hub_people_section'),
        icon: Icons.chat_bubble_outline,
        open: people.length,
        items: [
          for (final choice in people) card(choice),
          for (final choice in doneOf({_HubCategory.people, null}))
            doneRow(choice),
        ],
      ),
      _HubGroup(
        id: 'challenges',
        title: tr(ref, 'hub_challenges_section'),
        icon: Icons.gpp_maybe_outlined,
        open: challenges.length,
        items: [
          for (final choice in challenges) card(choice),
          for (final choice in doneOf({_HubCategory.challenge}))
            doneRow(choice),
        ],
      ),
    ].where((g) => g.items.isNotEmpty).toList();
    final storedTab = ref.watch(_hubTabProvider);
    final tab =
        storedTab?.$1 == node.id && groups.any((g) => g.id == storedTab!.$2)
            ? storedTab!.$2
            : 'all';
    final tabbed = groups.length > 1;

    Widget header(_HubGroup group) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Row(
            children: [
              Icon(group.icon, size: 18),
              const SizedBox(width: 6),
              Text(group.title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        );
    final services = <Widget>[
      for (final group in groups)
        if (!tabbed || tab == 'all' || tab == group.id) ...[
          if (!tabbed || tab == 'all')
            header(group)
          else
            const SizedBox(height: 8),
          ...group.items,
        ],
    ];

    Widget tabChip(String id, String label, int count) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            key: Key('hub_tab_$id'),
            label: Text(count > 0 ? '$label $count' : label),
            selected: tab == id,
            showCheckmark: false,
            onSelected: (_) =>
                ref.read(_hubTabProvider.notifier).state = (node.id, id),
          ),
        );

    final onwardButtons = [
      for (final choice in onward)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ChoiceButton(
            choice: choice,
            story: story,
            session: session,
            currentNodeId: currentNodeId,
            isExcursion: isExcursion,
            french: french,
          ),
        ),
    ];
    final onwardSection = <Widget>[
      if (settlement != null)
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.logout),
            title: Text(tr(ref, 'leave_settlement_title')
                .replaceAll('{place}', settlement.nameFor(french))),
            children: onwardButtons,
          ),
        )
      else ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.arrow_forward, size: 18),
              const SizedBox(width: 6),
              Text(tr(ref, 'hub_onward_section'),
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        ...onwardButtons,
      ],
    ];

    final theme = Theme.of(context);
    final total = doneLocal.length + local.length;
    // The place's card: its name, how much of it is done, Rest and Reread.
    final placeCard = Container(
      key: const Key('hub_place_card'),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          if (settlement != null) ...[
            Icon(
              settlement.isCamp
                  ? Icons.local_fire_department_outlined
                  : Icons.location_city_outlined,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (settlement != null)
                  Text(
                    settlement.nameFor(french),
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (total > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: doneLocal.length / total,
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr(ref, 'hub_done_count')
                            .replaceAll('{done}', '${doneLocal.length}')
                            .replaceAll('{total}', '$total'),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onReread != null)
            IconButton(
              key: const Key('hub_reread'),
              tooltip: tr(ref, 'hub_story_unfold'),
              icon: const Icon(Icons.auto_stories_outlined),
              onPressed: onReread,
            ),
          IconButton(
            key: const Key('hub_rest'),
            tooltip:
                tr(ref, restsAtCamp ? 'rest_at_camp_button' : 'rest_button'),
            icon: const Icon(Icons.local_fire_department_outlined),
            onPressed: () => restTheNight(context, ref,
                message: tr(
                    ref,
                    restsAtCamp
                        ? 'party_rested_at_camp_message'
                        : 'party_rested_message'),
                atCamp: restsAtCamp),
          ),
        ],
      ),
    );

    // The whole block stays within [maxHeight]: the place's card, its tabs,
    // then its activities and its way onward, each scrolling within its
    // share, so the way onward is always on screen.
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            placeCard,
            // Once the camp stands, a place is somewhere the party travels
            // to from it: the way back, and on to the other places it knows.
            if (travelsFromHere)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Expanded(child: CampReturnButton()),
                    if (travelsOn) const SizedBox(width: 8),
                    if (travelsOn)
                      OutlinedButton.icon(
                        key: const Key('place_travel_on'),
                        style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact),
                        onPressed: () => showInkSheet<void>(
                          context: context,
                          builder: (_) => SafeArea(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(tr(ref, 'travel_on_title'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                  const SizedBox(height: 8),
                                  TravelOnList(fromNodeId: node.id),
                                ],
                              ),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.signpost_outlined, size: 18),
                        label: Text(tr(ref, 'travel_on_button')),
                      ),
                  ],
                ),
              ),
            if (tabbed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      tabChip('all', tr(ref, 'hub_tab_all'), 0),
                      for (final group in groups)
                        tabChip(group.id, group.title, group.open),
                    ],
                  ),
                ),
              ),
            if (services.isNotEmpty)
              Flexible(
                child: SingleChildScrollView(
                  key: PageStorageKey('hub_services_${node.id}_$tab'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: services,
                  ),
                ),
              ),
            // The way onward takes what it needs (one line while folded),
            // up to two fifths of the block, and the lists the rest.
            if (onward.isNotEmpty) ...[
              const Divider(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight * 0.4),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: onwardSection,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One kind of activity in a place (its shops, expeditions, people or
/// challenges): a tab of the place's list.
class _HubGroup {
  const _HubGroup({
    required this.id,
    required this.title,
    required this.icon,
    required this.open,
    required this.items,
  });

  final String id;
  final String title;
  final IconData icon;

  /// How many are still to do (the tab's count).
  final int open;
  final List<Widget> items;
}

/// The tab picked in a place's list, by the place's node id: another place
/// opens on All.
final _hubTabProvider = StateProvider<(String, String)?>((ref) => null);

/// Under a town or camp's scene, while it is being read: the one way on,
/// into the place (see the story view's readingScene).
class _EnterPlaceButton extends ConsumerWidget {
  const _EnterPlaceButton({
    super.key,
    required this.place,
    required this.again,
    required this.french,
    required this.onEnter,
  });

  final Settlement place;

  /// The scene was read before (reopened with Reread, or changed since).
  final bool again;
  final bool french;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = place.nameFor(french);
    // Scrolls inside the room the choices are given (a long quest strip
    // above leaves a short phone little): the button comes first, so the
    // hint is what slides out of sight, never an overflow (320 px).
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              key: const Key('hub_enter'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
              onPressed: onEnter,
              icon: Icon(place.isCamp
                  ? Icons.local_fire_department_outlined
                  : Icons.location_city_outlined),
              label: Text(
                tr(ref, again ? 'hub_back_button' : 'hub_enter_button')
                    .replaceAll('{place}', name),
                textAlign: TextAlign.center,
              ),
            ),
            if (!again) ...[
              const SizedBox(height: 6),
              Text(
                tr(ref, 'hub_enter_hint'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The pop-up on reaching a town from elsewhere in the story: where the
/// player is, and that the place's shops, expeditions and people are
/// listed under the story, with the way onward at the bottom. (The camp
/// says its own welcome: see CampScreen.)
void _showSettlementArrival(
  BuildContext context,
  WidgetRef ref,
  Settlement settlement,
  bool french,
) {
  final ports = ref.read(localizedDbProvider(portsSchema)).value;
  final port = settlement.portId == null
      ? null
      : ports?[settlement.portId] as Map<String, dynamic>?;
  final portText = port == null ? '' : portDescriptionFor(port, french);
  final name = settlement.nameFor(french);
  // After the founding, the camp is home: arriving there is coming back,
  // and a town is somewhere away from it.
  final campFounded =
      ref.read(playerSessionProvider).flags.contains(campFoundedFlag);
  final bodyKey = campFounded ? 'arrival_town_away_body' : 'arrival_town_body';
  // The first place reached in a chapter also says what the region is going
  // through (see chapter_conditions.dart), once.
  final chapter = ref.read(reachedChapterProvider);
  final condition = ref.read(chapterConditionProvider);
  final showCondition = condition != null &&
      !ref
          .read(playerSessionProvider)
          .flags
          .contains(conditionSeenFlag(chapter));
  if (showCondition) {
    ref
        .read(playerSessionProvider.notifier)
        .applyChoiceEffects(flagsToAdd: [conditionSeenFlag(chapter)]);
  }
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        // A short screen scrolls the port's description and the guide
        // rather than overflowing.
        scrollable: true,
        icon: const Icon(Icons.location_city, size: 36),
        title: Text(
          tr(ref, 'arrival_town_title').replaceAll('{place}', name),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (portText.isNotEmpty) ...[
              Text(portText,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic, height: 1.4)),
              const SizedBox(height: 12),
            ],
            Text(
              tr(ref, bodyKey).replaceAll('{place}', name),
              style: theme.textTheme.bodyMedium,
            ),
            if (showCondition) ...[
              const Divider(height: 24),
              Row(
                key: const ValueKey('arrival_condition'),
                children: [
                  Icon(Icons.flag_outlined,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr(ref, 'condition_line')
                          .replaceAll('{name}', condition.nameFor(french)),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(condition.arrivalFor(french),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic, height: 1.4)),
              const SizedBox(height: 8),
              Text(condition.effectFor(french),
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(tr(ref, 'condition_where'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(tr(ref,
                campFounded ? 'arrival_away_button' : 'arrival_town_button')),
          ),
        ],
      );
    },
  );
}

/// A single card within a [_HubSections] section — the categorized,
/// icon-led counterpart to [_ChoiceButton], reached only for choices a
/// hub node sorted out of its main list.
class _HubChoiceCard extends ConsumerWidget {
  const _HubChoiceCard({
    required this.choice,
    required this.story,
    required this.session,
    required this.currentNodeId,
    required this.isExcursion,
    required this.french,
  });

  final StoryChoice choice;
  final StoryData story;
  final PlayerSession session;
  final String currentNodeId;
  final bool isExcursion;
  final bool french;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainQuestShut = _mainQuestShut(ref, choice, isExcursion);
    final locked = mainQuestShut ||
        _isChoiceLocked(choice, story, session, isExcursion,
            world: ref.watch(coastGateWorldProvider),
            shutWays: ref.watch(lockedStoryWaysProvider));
    final lockedLabel = locked
        ? storyChoiceLockedText(ref, choice, session,
            isExcursion: isExcursion,
            french: french,
            mainQuestShut: mainQuestShut)
        : null;
    final label = (lockedLabel?.isNotEmpty ?? false)
        ? lockedLabel!
        : choice.textFor(french);

    if (choice.triggersCombat) {
      // Keep the enemies database warm so it's ready by the time this
      // card is tapped.
      ref.watch(localizedDbProvider(enemiesSchema));
    }

    final roster = isExcursion
        ? null
        : _fightRosterFor(
            choice, ref.watch(localizedDbProvider(enemiesSchema)).value);
    final subtitle = choice.hasAbilityCheck
        ? '${tr(ref, '${choice.checkAbility}_label')} DC ${choice.checkDC ?? 10}'
        : roster == null
            ? null
            : tr(ref, 'choice_fight_roster').replaceAll('{roster}', roster);
    final hint = isExcursion ? '' : choicePoliticsHint(ref, choice);

    return Card(
      child: ListTile(
        leading: Icon(_hubIconFor(choice)),
        title: Text(label),
        subtitle: subtitle == null && hint.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (subtitle != null) Text(subtitle),
                  if (hint.isNotEmpty) _PoliticsHintLine(hint: hint),
                ],
              ),
        trailing: Icon(locked ? Icons.lock_outline : Icons.chevron_right),
        onTap: locked
            ? null
            : () => _selectChoice(
                  context: context,
                  ref: ref,
                  choice: choice,
                  story: story,
                  session: session,
                  currentNodeId: currentNodeId,
                  isExcursion: isExcursion,
                  french: french,
                ),
      ),
    );
  }
}

/// Who a story fight choice sends the party against ("Street Bandit ×3"),
/// or null for a choice with no fight, a fight whose enemies are not
/// loaded yet, or the pact's turned companion (`@first_ally`), which the
/// scene deliberately does not name before it happens.
String? _fightRosterFor(StoryChoice choice, Map<String, dynamic>? enemies) {
  if (!choice.triggersCombat || enemies == null) return null;
  final ids = choice.allTriggerEnemyIds;
  if (ids.any((id) => id.startsWith('@'))) return null;
  return enemyRoster(ids, enemies);
}

/// The strip above a detour's text: that this scene is met on the way to
/// the choice the player just made, why it is happening when the builder
/// knows (a hunter's reason, the job on offer), and that the story picks
/// up where the player was going once it is dealt with.
class _DetourContextCard extends ConsumerWidget {
  const _DetourContextCard({required this.origin, required this.note});

  final String? origin;
  final String? note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onColor = scheme.onSecondaryContainer;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.secondaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.alt_route, size: 18, color: onColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    origin == null
                        ? tr(ref, 'detour')
                        : '${tr(ref, 'detour_on_the_way')} “$origin”',
                    style: theme.textTheme.labelLarge?.copyWith(color: onColor),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: onColor, fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    tr(ref, 'detour_resumes'),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: onColor.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
