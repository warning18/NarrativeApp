import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cliff_town.dart';
import '../data/materials.dart';
import '../data/zone_gating.dart';
import '../l10n/app_locale.dart';
import '../gamedata/db_schema.dart'
    show companionsSchema, housesSchema, itemsSchema;
import '../l10n/app_strings.dart';
import '../providers/chapter_loop_provider.dart' show reachedChapterProvider;
import '../providers/game_db_providers.dart' show localizedDbProvider;
import '../data/companion_remarks.dart' show houseBuiltRemarkKinds;
import '../providers/moment_remark_provider.dart';
import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';
import '../tutorial/guide_tour.dart';
import '../data/camp_works.dart'
    show WorkCategory, tierFirstChapter, workTierOf;
import 'camp_build_tray.dart';
import 'camp_works_list.dart';
import 'companion_remark_bubble.dart';
import 'cliff_town_view.dart';
import 'immersive_notice.dart';
import 'moments.dart';

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
  BuildFilter? _filter;
  WorkCategory? _category;
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

  /// What a house gives, in a line: its bonuses and the shop it opens, else
  /// its description.
  String _houseDetail(String houseId) {
    final house = (widget.houses[houseId] ??
        ref.read(localizedDbProvider(housesSchema)).value?[houseId] ??
        const <String, dynamic>{}) as Map<String, dynamic>;
    final capacity = (house['partyCapacityBonus'] as num?)?.toInt() ?? 0;
    final health = (house['partyHealthBonus'] as num?)?.toInt() ?? 0;
    final damage = (house['partyDamageBonus'] as num?)?.toInt() ?? 0;
    final shopId = house['unlocksShopId']?.toString() ?? '';
    final shopName = shopId.isEmpty
        ? null
        : (widget.shops[shopId] as Map<String, dynamic>?)?['shopName']
                ?.toString() ??
            shopId;
    final detail = [
      if (capacity > 0) '+$capacity ${tr(ref, 'party_capacity_label')}',
      if (health > 0) '+$health% ${tr(ref, 'party_health_bonus_label')}',
      if (damage > 0) '+$damage% ${tr(ref, 'party_damage_bonus_label')}',
      if (shopName != null) '${tr(ref, 'unlocks_shop_prefix')}: $shopName',
    ];
    return detail.isNotEmpty
        ? detail.join(' · ')
        : house['description']?.toString() ?? '';
  }

  /// A tap on a piece of the town: its name and what it gives, in a sheet.
  void _showInfo(String id) {
    final isAddition = isTownAddition(id);
    final detail = isAddition
        ? tr(ref, '${id}_desc')
        : widget.houses.containsKey(id)
            ? _houseDetail(id)
            : '';
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            key: const Key('town_piece_info'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nameOf(id), style: theme.textTheme.titleMedium),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(detail, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Each item's name, for the material chips' tooltips.
  Map<String, String> _itemNames() {
    final items = ref.read(localizedDbProvider(itemsSchema)).value ?? const {};
    return {
      for (final e in items.entries)
        e.key: (e.value as Map?)?['itemName']?.toString() ?? e.key,
    };
  }

  Future<void> _buildHouse(String houseId, CliffTown town) async {
    final house = widget.houses[houseId] as Map<String, dynamic>;
    final cost = (house['buildCost'] as num?)?.toInt() ?? 0;
    final notifier = ref.read(playerSessionProvider.notifier);
    await notifier.buildHouse(houseId, cost,
        unlocksShopId: house['unlocksShopId']?.toString() ?? '',
        requiredFlags: requiredFlagsOf(house),
        unlockedByFlags: unlockedByFlagsOf(house),
        materialCost: materialCountsOf(house, 'materialCost'),
        // A house comes with its tier's chapter (camp_works.dart).
        fromChapter: tierFirstChapter(workTierOf(house)),
        chapter: ref.read(reachedChapterProvider),
        requiredAllyId: house['requiredAllyId']?.toString());
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
    if (newAchievements.isNotEmpty) {
      unawaited(announceAchievements(
          context,
          [
            for (final id in newAchievements)
              (widget.achievements[id]
                          as Map<String, dynamic>?)?['achievementName']
                      ?.toString() ??
                  id
          ],
          trFor(lang, 'achievement_unlocked_prefix').toUpperCase()));
    }
    // A companion's word on some houses (Core's speakUpOnMoment), after
    // the notice, as for a shared drink.
    final kind = houseBuiltRemarkKinds[houseId];
    final remark = kind == null ? null : speakUpOnMoment(ref, kind);
    final notice = showImmersiveNotice(
      context,
      icon: Icons.home,
      message: '${trFor(lang, 'house_built_prefix')}: '
          '${_nameOf(houseId)}$achievementSuffix',
    );
    if (remark == null) return;
    await notice;
    if (mounted) await showCompanionRemarks(context, ref, [remark]);
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
    watchMomentRemarks(ref);
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

    final selectedAvailable = isTownAddition(selected) || buildable(selected);
    // Where the outlined piece would go, said in words under the town.
    String? whereLine;
    if (selectedAvailable) {
      final spot = town.spotFor(previewFootprint);
      if (spot != null) {
        whereLine = spot.$1 == 0
            ? tr(ref, 'town_goes_quay').replaceAll('{name}', _nameOf(selected))
            : tr(ref, 'town_goes_level')
                .replaceAll('{name}', _nameOf(selected))
                .replaceAll('{level}', '${spot.$1 + 1}');
      }
    }

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
        TutorialTarget(
          id: 'camp.town',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: townHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CliffTownView(
                    key: const Key('cliff_town'),
                    town: town,
                    preview: selectedAvailable ? previewFootprint : null,
                    previewLabel: _nameOf(selected),
                    highlightIndex: _lastBuilt,
                    harborAction: widget.harborAction,
                    scrollController: _scroll,
                    onPieceTap: (id) => _showInfo(id),
                  ),
                  // The hour over the town (the world clock).
                  WatchSky(
                      watch: ref
                          .watch(playerSessionProvider.select((s) => s.watch))),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            _log ??
                whereLine ??
                (town.pieces.isEmpty
                    ? tr(ref, 'town_start')
                    : tr(ref, 'town_tap_to_preview')),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontStyle: FontStyle.italic, color: ink.ash),
          ),
        ),
        TutorialTarget(
          id: 'camp.tray',
          child: CampBuildTray(
            showAdditions: _showAdditions,
            onShowAdditions: (additions) => setState(() {
              _showAdditions = additions;
              _selected = null;
            }),
            filter: _filter,
            onFilter: (f) => setState(() => _filter = f),
            category: _category,
            onCategory: (c) => setState(() => _category = c),
            gold: session.gold,
            selectedId: selected,
            additions: [
              for (final addition in townAdditions)
                AdditionStatus(
                  addition: addition,
                  gold: session.gold,
                  built: townPieceCount(session.townPieces, addition.id),
                  limit: townAdditionLimit(addition.id,
                      houseCount: session.builtHouseIds.length),
                ),
            ],
            onSelectAddition: (id) {
              setState(() => _selected = id);
              _reveal(town, footprintOf(id));
            },
            onBuildAddition: (id) => _buildAddition(
                townAdditions.firstWhere((a) => a.id == id), town),
            houseList: (works) => CampWorksList(
              works: works,
              houses: ref.watch(localizedDbProvider(housesSchema)).value ??
                  widget.houses,
              shops: widget.shops,
              zones: widget.zones,
              itemNames: _itemNames(),
              companionNames: {
                for (final e in (ref
                            .watch(localizedDbProvider(companionsSchema))
                            .value ??
                        const <String, dynamic>{})
                    .entries)
                  e.key:
                      (e.value as Map?)?['companionName']?.toString() ?? e.key,
              },
              selectedId: selected,
              detailOf: _houseDetail,
              onSelect: (id) {
                setState(() => _selected = id);
                _reveal(town, footprintOf(id));
              },
              onBuild: (id) => _buildHouse(id, town),
            ),
          ),
        ),
      ],
    );
  }
}
