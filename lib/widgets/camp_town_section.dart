import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cliff_town.dart';
import '../data/zone_gating.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';
import 'cliff_town_view.dart';
import 'immersive_notice.dart';

/// The camp's town and what can be built on it: the cliff town (see
/// [CliffTownView]) over a tray of houses and town additions. Tapping a
/// card outlines where it would go; Build raises it there.
class CampTownSection extends ConsumerStatefulWidget {
  const CampTownSection({
    super.key,
    required this.houses,
    required this.shops,
    required this.zones,
    required this.achievements,
    this.harborAction,
  });

  final Map<String, dynamic> houses;
  final Map<String, dynamic> shops;
  final Map<String, dynamic> zones;
  final Map<String, dynamic> achievements;

  /// The boat's button, set over the harbour.
  final Widget? harborAction;

  @override
  ConsumerState<CampTownSection> createState() => _CampTownSectionState();
}

class _CampTownSectionState extends ConsumerState<CampTownSection> {
  final _scroll = ScrollController();
  bool _showAdditions = false;
  String? _selected;
  String? _log;
  int? _lastBuilt;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<String> get _houseIds {
    final ids = widget.houses.keys.toList();
    // The town's own order first (the order houses.json lists them in),
    // then any house it does not know.
    final known = houseFootprints.keys.toList();
    ids.sort((a, b) {
      final ia = known.indexOf(a), ib = known.indexOf(b);
      return (ia < 0 ? 999 : ia).compareTo(ib < 0 ? 999 : ib);
    });
    return ids;
  }

  String _nameOf(String id) {
    if (isTownAddition(id)) return tr(ref, '${id}_name');
    return (widget.houses[id] as Map<String, dynamic>?)?['houseName']
            ?.toString() ??
        id;
  }

  /// Scrolls the town so the outline of [footprint] is in view.
  void _reveal(CliffTown town, TownFootprint footprint) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final spot = town.spotFor(footprint);
      if (spot == null) return;
      final position = _scroll.position;
      final scale = (context.size?.width ?? townWidth) / townWidth;
      final fromBottom = (townHarborHeight +
              (spot.$1 + footprint.height / 2) * townRowHeight) *
          scale;
      final target = (fromBottom - position.viewportDimension / 2)
          .clamp(0.0, position.maxScrollExtent);
      _scroll.animateTo(target,
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    });
  }

  Future<void> _buildHouse(String houseId, CliffTown town) async {
    final house = widget.houses[houseId] as Map<String, dynamic>;
    final cost = (house['buildCost'] as num?)?.toInt() ?? 0;
    final notifier = ref.read(playerSessionProvider.notifier);
    await notifier.buildHouse(houseId, cost,
        unlocksShopId: house['unlocksShopId']?.toString() ?? '',
        requiredFlags: requiredFlagsOf(house));
    if (!mounted) return;
    // Nothing to tell if it did not go up (the purse or the flags changed
    // under the button).
    if (!ref.read(playerSessionProvider).builtHouseIds.contains(houseId)) {
      return;
    }
    final newAchievements = await notifier.checkAchievements();
    if (!mounted) return;
    _afterBuild(houseId, town);
    final lang = ref.read(appLanguageProvider);
    final achievementSuffix = newAchievements.isEmpty
        ? ''
        : '\n${trFor(lang, 'achievement_unlocked_prefix')}: '
            '${newAchievements.map((id) => (widget.achievements[id] as Map<String, dynamic>?)?['achievementName']?.toString() ?? id).join(", ")}';
    showImmersiveNotice(
      context,
      icon: Icons.home,
      message: '${trFor(lang, 'house_built_prefix')}: '
          '${_nameOf(houseId)}$achievementSuffix',
    );
  }

  Future<void> _buildAddition(TownAddition addition, CliffTown town) async {
    final before = ref.read(playerSessionProvider).townPieces.length;
    await ref
        .read(playerSessionProvider.notifier)
        .buildTownAddition(addition.id, addition.cost);
    if (!mounted) return;
    if (ref.read(playerSessionProvider).townPieces.length <= before) return;
    _afterBuild(addition.id, town);
  }

  /// Notes where [id] went (on [town] as it was before it) and moves the
  /// outline on to the next thing to build.
  void _afterBuild(String id, CliffTown town) {
    final spot = town.spotFor(footprintOf(id));
    final name = _nameOf(id);
    setState(() {
      _lastBuilt = town.pieces.length;
      _log = spot == null || spot.$1 == 0
          ? tr(ref, 'town_raised_quay').replaceAll('{name}', name)
          : tr(ref, 'town_raised_level')
              .replaceAll('{name}', name)
              .replaceAll('{level}', '${spot.$1 + 1}');
      if (!isTownAddition(id)) _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(playerSessionProvider);
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final town = CliffTown.build(session.townPieces);
    final built = session.builtHouseIds;

    bool buildable(String houseId) {
      final house = widget.houses[houseId] as Map<String, dynamic>;
      return !built.contains(houseId) &&
          meetsRequiredFlags(house, session.flags);
    }

    // What the outline shows: the card last tapped, else the first house
    // that can go up, else a timber room.
    var selected = _selected;
    if (selected == null ||
        (!isTownAddition(selected) && built.contains(selected))) {
      selected = _showAdditions
          ? townAdditions.first.id
          : _houseIds.firstWhere(buildable,
              orElse: () => townAdditions.first.id);
    }
    final previewFootprint = footprintOf(selected);

    final houseCount = built.length;
    final additionCount = session.townPieces.where(isTownAddition).length;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final townHeight = (screenHeight * 0.42).clamp(260.0, 420.0);

    Widget card({
      required String id,
      required String name,
      required String detail,
      required TownFootprint footprint,
      required int cost,
      required bool isBuilt,
      String? lockReason,
      required VoidCallback onBuild,
    }) {
      final isSelected = id == selected;
      final affordable = session.gold >= cost;
      final canBuild = !isBuilt && lockReason == null && affordable;
      Widget action;
      if (isBuilt) {
        action = InkTag(label: tr(ref, 'house_built_prefix'), color: ink.heal);
      } else if (lockReason != null) {
        action = Text(lockReason,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
      } else if (!affordable) {
        action = Text(
          '$cost G · ${tr(ref, 'town_need')} ${cost - session.gold}',
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        );
      } else {
        action = FilledButton(
          key: Key('town_build_$id'),
          onPressed: canBuild ? onBuild : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text('${tr(ref, 'build_button')} · $cost'),
        );
      }
      return GestureDetector(
        key: Key('town_card_$id'),
        onTap: () {
          setState(() => _selected = id);
          if (!isBuilt) _reveal(town, footprint);
        },
        child: Container(
          width: 156,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: isSelected && !isBuilt
                    ? theme.colorScheme.primary
                    : ink.seam),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500)),
                  ),
                  Text('${footprint.width}×${footprint.height}',
                      style:
                          theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(detail,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: ink.ash, height: 1.3)),
              ),
              const SizedBox(height: 6),
              action,
            ],
          ),
        ),
      );
    }

    final cards = _showAdditions
        ? [
            for (final addition in townAdditions)
              card(
                id: addition.id,
                name: tr(ref, '${addition.id}_name'),
                detail: tr(ref, '${addition.id}_desc'),
                footprint: addition.footprint,
                cost: addition.cost,
                isBuilt: false,
                onBuild: () => _buildAddition(addition, town),
              ),
          ]
        : [
            for (final houseId in _houseIds)
              () {
                final house = widget.houses[houseId] as Map<String, dynamic>;
                final isBuilt = built.contains(houseId);
                final lock = isBuilt || meetsRequiredFlags(house, session.flags)
                    ? null
                    : [
                        tr(ref, 'requires_zone_prefix'),
                        lockRequirementName(house, session.flags, widget.zones),
                      ].whereType<String>().join(': ');
                final capacity =
                    (house['partyCapacityBonus'] as num?)?.toInt() ?? 0;
                final health =
                    (house['partyHealthBonus'] as num?)?.toInt() ?? 0;
                final damage =
                    (house['partyDamageBonus'] as num?)?.toInt() ?? 0;
                final shopId = house['unlocksShopId']?.toString() ?? '';
                final shopName = shopId.isEmpty
                    ? null
                    : (widget.shops[shopId]
                                as Map<String, dynamic>?)?['shopName']
                            ?.toString() ??
                        shopId;
                final detail = [
                  if (capacity > 0)
                    '+$capacity ${tr(ref, 'party_capacity_label')}',
                  if (health > 0)
                    '+$health% ${tr(ref, 'party_health_bonus_label')}',
                  if (damage > 0)
                    '+$damage% ${tr(ref, 'party_damage_bonus_label')}',
                  if (shopName != null)
                    '${tr(ref, 'unlocks_shop_prefix')}: $shopName',
                ];
                return card(
                  id: houseId,
                  name: _nameOf(houseId),
                  detail: detail.isNotEmpty
                      ? detail.join(' · ')
                      : house['description']?.toString() ?? '',
                  footprint: footprintOf(houseId),
                  cost: (house['buildCost'] as num?)?.toInt() ?? 0,
                  isBuilt: isBuilt,
                  lockReason: lock,
                  onBuild: () => _buildHouse(houseId, town),
                );
              }(),
          ];

    final selectedAvailable = isTownAddition(selected) || buildable(selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(tr(ref, 'town_title'),
                  style: theme.textTheme.headlineSmall),
            ),
            Text(
              tr(ref, 'town_counts')
                  .replaceAll('{houses}', '$houseCount')
                  .replaceAll('{total}', '${widget.houses.length}')
                  .replaceAll('{additions}', '$additionCount'),
              style: theme.textTheme.labelSmall?.copyWith(color: ink.ash),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: townHeight,
            child: CliffTownView(
              key: const Key('cliff_town'),
              town: town,
              preview: selectedAvailable ? previewFootprint : null,
              previewLabel: _nameOf(selected),
              highlightIndex: _lastBuilt,
              harborAction: widget.harborAction,
              scrollController: _scroll,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            _log ??
                (town.pieces.isEmpty
                    ? tr(ref, 'town_start')
                    : tr(ref, 'town_tap_to_preview')),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontStyle: FontStyle.italic, color: ink.ash),
          ),
        ),
        Row(
          children: [
            ChoiceChip(
              key: const Key('town_tab_houses'),
              label: Text(tr(ref, 'houses_section')),
              selected: !_showAdditions,
              onSelected: (_) => setState(() {
                _showAdditions = false;
                _selected = null;
              }),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              key: const Key('town_tab_additions'),
              label: Text(tr(ref, 'town_additions_tab')),
              selected: _showAdditions,
              onSelected: (_) => setState(() {
                _showAdditions = true;
                _selected = null;
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => cards[i],
          ),
        ),
      ],
    );
  }
}
