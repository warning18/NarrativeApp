import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_aftermath.dart';
import '../combat/combat_engine.dart';
import '../combat/encounter.dart';
import '../data/alignment_events.dart';
import '../data/map_themes.dart';
import '../data/sub_node_engine.dart';
import '../data/zone_gating.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/aftermath_provider.dart';
import '../providers/combat_settings_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import 'fight_screen.dart';
import 'shop_detail_screen.dart';

enum _ExpeditionPhase { event, completed, retreated }

/// Walks one zone's fixed chain of expedition events (`expeditionCount` in
/// zones.json) — the Phase 1 "one zone, land only" slice of the roguelike
/// redesign. Each event is drawn live from [SubNodeEngine]'s existing themed
/// flavor pools rather than hand-authored content, so a new zone needs no
/// per-event writing to exist — only a zones.json row.
///
/// A fight lost or fled mid-expedition, or a voluntary retreat between
/// events, ends the run without the zone's own banked reward (see
/// [PlayerSessionNotifier.completeZone]) — everything already gained this
/// run (gold, items, XP from any won fight) is kept regardless.
class ExpeditionScreen extends ConsumerStatefulWidget {
  const ExpeditionScreen({super.key, required this.zoneId, required this.zone});

  final String zoneId;
  final Map<String, dynamic> zone;

  @override
  ConsumerState<ExpeditionScreen> createState() => _ExpeditionScreenState();
}

class _ExpeditionScreenState extends ConsumerState<ExpeditionScreen> {
  final _random = Random();
  int _index = 0;
  StoryNode? _current;
  _ExpeditionPhase _phase = _ExpeditionPhase.event;
  bool _busy = false;
  List<String> _summaryLines = const [];

  /// Bonus events queued ahead of the zone's own next draw -- a hunt's
  /// trail and quarry after a pack win (see [SubNodeEngine.buildHuntNodes]).
  /// They don't count toward [_expeditionCount]: a hunt is extra, never a
  /// substitute for the zone's own events.
  final List<StoryNode> _bonusQueue = [];

  /// Set once the zone's boss (zones.json `bossEnemyId`) has been beaten
  /// this run, so the zone completes instead of re-offering it.
  bool _bossDone = false;

  /// The zone's halfway beat has been shown this expedition.
  bool _midpointShown = false;

  /// The last fight's aftermath, opening the next event's text.
  String? _aftermath;

  int get _expeditionCount =>
      (widget.zone['expeditionCount'] as num?)?.toInt() ?? 3;

  int get _zoneChapter => (widget.zone['chapter'] as num?)?.toInt() ?? 1;

  String get _bossEnemyId => widget.zone['bossEnemyId']?.toString() ?? '';

  /// Every fight in this zone carries the zone's chapter (for the chapter
  /// difficulty curve and the chest's loot window) and its tier multiplier.
  EncounterModifiers _zoneModifiers(EncounterModifiers base) => base.copyWith(
        chapter: _zoneChapter,
        difficultyMultiplier: zoneTierMultiplier(zoneTier(widget.zone)),
      );

  bool _isBossNode(StoryNode? node) =>
      node != null && node.id == 'zone_boss_${widget.zoneId}';

  bool _isMidpointNode(StoryNode? node) =>
      node != null && node.id == 'zone_mid_${widget.zoneId}';

  /// The zone's halfway beat: a paragraph of the zone's own narration
  /// (`midpointFlavorText`) between two events, shown once per expedition
  /// and never counted as an event. Null for a zone without one.
  StoryNode? _buildMidpointNode() {
    final text = widget.zone['midpointFlavorText']?.toString() ?? '';
    if (text.isEmpty) return null;
    final textFr = widget.zone['midpointFlavorTextFr']?.toString() ?? '';
    return StoryNode(
      id: 'zone_mid_${widget.zoneId}',
      description: text,
      descriptionFr: textFr.isEmpty ? null : textFr,
      choices: [
        StoryChoice(
          text: trFor(AppLanguage.en, 'expedition_press_on'),
          textFr: trFor(AppLanguage.fr, 'expedition_press_on'),
          nextId: '',
        ),
      ],
    );
  }

  /// The zone-boss event: the zone's `bossFlavorText` and a single fight
  /// choice against `bossEnemyId`, shown once the zone's own events are
  /// done. Winning completes the zone; losing ends the run as a defeat.
  StoryNode _buildBossNode(Map<String, dynamic> boss) {
    final bossName = boss['enemyName']?.toString() ?? _bossEnemyId;
    final flavorFr = widget.zone['bossFlavorTextFr']?.toString() ?? '';
    return StoryNode(
      id: 'zone_boss_${widget.zoneId}',
      description: widget.zone['bossFlavorText']?.toString() ?? '',
      descriptionFr: flavorFr.isEmpty ? null : flavorFr,
      choices: [
        StoryChoice(
          text: '${trFor(AppLanguage.en, 'zone_boss_face_prefix')} $bossName',
          textFr: '${trFor(AppLanguage.fr, 'zone_boss_face_prefix')} $bossName',
          nextId: '',
          triggerEnemyId: _bossEnemyId,
        ),
      ],
    );
  }

  StoryNode _rollEvent({
    required Map<String, dynamic> shops,
    required Map<String, dynamic> enemies,
  }) {
    final session = ref.read(playerSessionProvider);
    final theme = MapTheme.values.firstWhere(
      (t) => t.name == (widget.zone['mapTheme']?.toString() ?? ''),
      orElse: () => defaultMapTheme,
    );
    final zoneChapter = _zoneChapter;
    final alignmentEvent = maybeAlignmentEvent(
      alignmentScore: session.alignmentScore,
      activeQuestIds: session.activeQuestIds,
      completedQuestIds: session.completedQuestIds,
      enemies: enemies,
      chapter: zoneChapter,
      random: _random,
      enabled: ref.read(alignmentHuntersEnabledProvider),
    );
    if (alignmentEvent != null) return alignmentEvent.first;
    final shopPool = SubNodeEngine.filterShopPool(
      shops: shops,
      unlockedShopIds: session.unlockedShopIds,
      chapter: zoneChapter,
    );
    final enemyPool = SubNodeEngine.filterEnemyPool(
      enemies: enemies,
      unlockedEnemyIds: session.unlockedEnemyIds,
      chapter: zoneChapter,
    );
    return SubNodeEngine.buildNode(
      random: _random,
      flavor: flavorFor(theme),
      shopPool: shopPool,
      enemyPool: enemyPool,
      packPool:
          SubNodeEngine.filterPackPool(enemies: enemies, enemyPool: enemyPool),
      maxPackSize: SubNodeEngine.maxPackSizeFor(
        zoneChapter,
        partySize: 1 + session.activeAllyIds.length,
      ),
      enemies: enemies,
      shops: shops,
    );
  }

  Future<void> _advance({
    required Map<String, dynamic> shops,
    required Map<String, dynamic> enemies,
    bool countsTowardZone = true,
  }) async {
    if (_bonusQueue.isNotEmpty) {
      setState(() {
        _current = _bonusQueue.removeAt(0);
        _busy = false;
      });
      return;
    }
    final nextIndex = countsTowardZone ? _index + 1 : _index;
    if (nextIndex >= _expeditionCount) {
      // The zone's own events are done: its boss (if it has one) guards
      // the banked reward; a zone without one completes outright.
      final boss = enemies[_bossEnemyId] as Map<String, dynamic>?;
      if (_bossEnemyId.isNotEmpty && !_bossDone && boss != null) {
        setState(() {
          _index = nextIndex;
          _current = _buildBossNode(boss);
          _busy = false;
        });
        return;
      }
      await _completeZone();
      return;
    }
    // Halfway through a zone of three or more events, its own narration
    // gets a word in before the next draw.
    if (countsTowardZone &&
        !_midpointShown &&
        _expeditionCount >= 3 &&
        nextIndex == _expeditionCount ~/ 2) {
      final beat = _buildMidpointNode();
      if (beat != null) {
        _midpointShown = true;
        setState(() {
          _index = nextIndex;
          _current = beat;
          _busy = false;
        });
        return;
      }
    }
    setState(() {
      _index = nextIndex;
      _current = _rollEvent(shops: shops, enemies: enemies);
      _busy = false;
    });
  }

  Future<void> _resolveChoice(
    StoryChoice choice, {
    required Map<String, dynamic> shops,
    required Map<String, dynamic> enemies,
  }) async {
    setState(() {
      _busy = true;
      _aftermath = null;
    });
    final notifier = ref.read(playerSessionProvider.notifier);
    // A bonus event (a hunt's trail or quarry, or an alignment ambush that
    // replaced a draw) is extra: resolving it never advances the zone's
    // own event count.
    final countsTowardZone = !_isBonusNode(_current);
    final isBoss = _isBossNode(_current);

    final enemyIds = choice.allTriggerEnemyIds;
    if (enemyIds.isNotEmpty) {
      final resolvedEnemies = {
        for (final eid in enemyIds) eid: enemies[eid] as Map<String, dynamic>?,
      };
      if (resolvedEnemies.values.any((e) => e == null)) {
        await _advance(
            shops: shops, enemies: enemies, countsTowardZone: countsTowardZone);
        return;
      }
      final won = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => FightScreen(
            enemyId: enemyIds.first,
            enemy: resolvedEnemies[enemyIds.first]!,
            additionalEnemyIds: enemyIds.skip(1).toList(),
            additionalEnemies: {
              for (final eid in enemyIds.skip(1)) eid: resolvedEnemies[eid]!,
            },
            modifiers: isBoss
                ? EncounterModifiers.zoneBoss(
                    chapter: _zoneChapter,
                    difficultyMultiplier:
                        zoneTierMultiplier(zoneTier(widget.zone)),
                  )
                : _zoneModifiers(EncounterModifiers.fromChoice(choice)),
          ),
        ),
      );
      if (!mounted) return;
      if (won != true) {
        await _endAsRetreat(defeated: true);
        return;
      }
      final outcome = ref.read(lastFightOutcomeProvider);
      if (outcome != null) {
        _aftermath = aftermathLineFor(
          outcome,
          french: ref.read(appLanguageProvider) == AppLanguage.fr,
          seed: _random.nextInt(1 << 20),
        );
      }
      for (final eid in enemyIds.toSet()) {
        await notifier.unlockContent(enemyId: eid);
      }
      if (!mounted) return;
      if (isBoss) {
        _bossDone = true;
        await _completeZone();
        return;
      }
      // A pack win may open a hunt: the trail, then the pack's named
      // survivor, queued as bonus events before the zone's next draw.
      final wasBonus = !countsTowardZone;
      if (enemyIds.length >= 2 &&
          _random.nextDouble() < SubNodeEngine.huntChance) {
        final quarryId = enemyIds[_random.nextInt(enemyIds.length)];
        _bonusQueue.addAll(SubNodeEngine.buildHuntNodes(
          quarryId: quarryId,
          quarryBaseName:
              (enemies[quarryId] as Map<String, dynamic>?)?['enemyName']
                      ?.toString() ??
                  quarryId,
          random: _random,
        ));
      }
      await _advance(
          shops: shops, enemies: enemies, countsTowardZone: !wasBonus);
      return;
    }

    final shopId = choice.unlockShopId;
    if (shopId != null && shopId.isNotEmpty) {
      final shop = shops[shopId] as Map<String, dynamic>?;
      await notifier.unlockContent(shopId: shopId);
      if (shop != null && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => ShopDetailScreen(shopId: shopId, shop: shop)),
        );
      }
      if (!mounted) return;
      await _advance(
          shops: shops, enemies: enemies, countsTowardZone: countsTowardZone);
      return;
    }

    final questId = choice.unlockQuestId;
    if (questId != null && questId.isNotEmpty) {
      await notifier.unlockContent(questId: questId);
      if (!mounted) return;
      await _advance(
          shops: shops, enemies: enemies, countsTowardZone: countsTowardZone);
      return;
    }

    if (choice.hasEffects) {
      await notifier.applyChoiceEffects(
        goldMod: choice.goldMod,
        alignmentMod: choice.alignmentMod,
        healAmount: choice.healAmount,
        flagsToAdd: choice.flagsToAdd,
        questIDToProgress: choice.questIDToProgress,
      );
    }
    if (!mounted) return;
    await _advance(
        shops: shops, enemies: enemies, countsTowardZone: countsTowardZone);
  }

  /// A hunt node (trail or quarry), a hunter ambush, or a temptation --
  /// anything not drawn from the zone's own pools.
  bool _isBonusNode(StoryNode? node) {
    if (node == null) return false;
    if (node.id.startsWith('hunter_') ||
        node.id.startsWith('temptation_') ||
        _isMidpointNode(node)) {
      return true;
    }
    final choice = node.choices.isEmpty ? null : node.choices.first;
    return choice != null &&
        ((choice.huntName ?? '').isNotEmpty ||
            (choice.text == 'Follow the trail'));
  }

  Future<void> _completeZone() async {
    final notifier = ref.read(playerSessionProvider.notifier);
    final rewardGold = (widget.zone['rewardGold'] as num?)?.toInt() ?? 0;
    final rewardItemId = widget.zone['rewardItemId']?.toString() ?? '';
    final rewardDiceId = widget.zone['rewardDiceId']?.toString() ?? '';
    final rewardAllyId = widget.zone['rewardAllyId']?.toString() ?? '';
    final rewardFlag = widget.zone['rewardFlag']?.toString() ?? '';
    final lang = ref.read(appLanguageProvider);
    final companions =
        ref.read(gameDbProvider(companionsSchema)).value ?? const {};

    await notifier.completeZone(
      widget.zoneId,
      rewardGold: rewardGold,
      rewardItemId: rewardItemId.isNotEmpty ? rewardItemId : null,
      rewardDiceId: rewardDiceId.isNotEmpty ? rewardDiceId : null,
      rewardFlag: rewardFlag.isNotEmpty ? rewardFlag : null,
    );

    final lines = <String>[];
    if (rewardGold > 0) {
      lines.add('+$rewardGold ${trFor(lang, 'gold_label')}');
    }
    if (rewardItemId.isNotEmpty) {
      final items = ref.read(gameDbProvider(itemsSchema)).value ?? const {};
      final itemName =
          (items[rewardItemId] as Map<String, dynamic>?)?['itemName']
              ?.toString();
      lines.add(itemName ?? rewardItemId);
    }
    if (rewardDiceId.isNotEmpty) {
      final dice = ref.read(gameDbProvider(diceSchema)).value ?? const {};
      final diceName =
          (dice[rewardDiceId] as Map<String, dynamic>?)?['diceName']
              ?.toString();
      lines.add(diceName ?? rewardDiceId);
    }
    if (rewardAllyId.isNotEmpty) {
      final races = ref.read(gameDbProvider(racesSchema)).value ?? const {};
      final professions =
          ref.read(gameDbProvider(professionsSchema)).value ?? const {};
      final companion = companions[rewardAllyId] as Map<String, dynamic>?;
      final race = races[companion?['raceId']?.toString() ?? '']
          as Map<String, dynamic>?;
      final profession =
          professions[companion?['professionId']?.toString() ?? '']
              as Map<String, dynamic>?;
      final houses = ref.read(gameDbProvider(housesSchema)).value ?? const {};
      await notifier.recruitAlly(
        rewardAllyId,
        race: race,
        profession: profession,
        companion: companion,
        dice: ref.read(gameDbProvider(diceSchema)).value ?? const {},
        houses: houses,
        requiredHouseId: companion?['requiredHouseId']?.toString(),
      );
      lines.add(companion?['companionName']?.toString() ?? rewardAllyId);
    }
    if (rewardFlag.isNotEmpty) {
      final flagKey = 'zone_flag_$rewardFlag';
      final flagLine = trFor(lang, flagKey);
      if (flagLine != flagKey) lines.add(flagLine);
    }

    final newAchievements = await notifier.checkAchievements(
        totalCompanionCount: companions.length);
    if (newAchievements.isNotEmpty) {
      final achievements =
          ref.read(gameDbProvider(achievementsSchema)).value ?? const {};
      for (final id in newAchievements) {
        final name =
            (achievements[id] as Map<String, dynamic>?)?['achievementName']
                ?.toString();
        lines.add(
            '${trFor(lang, 'achievement_unlocked_prefix')}: ${name ?? id}');
      }
    }

    if (!mounted) return;
    setState(() {
      _phase = _ExpeditionPhase.completed;
      _summaryLines = lines;
      _busy = false;
    });
  }

  Future<void> _endAsRetreat({required bool defeated}) async {
    if (!mounted) return;
    setState(() {
      _phase = _ExpeditionPhase.retreated;
      _summaryLines = [
        trFor(
          ref.read(appLanguageProvider),
          defeated
              ? 'expedition_defeated_message'
              : 'expedition_retreat_message',
        ),
      ];
      _busy = false;
    });
  }

  String _choiceLabel(StoryChoice choice) =>
      ref.watch(appLanguageProvider) == AppLanguage.fr &&
              (choice.textFr?.isNotEmpty ?? false)
          ? choice.textFr!
          : choice.text;

  @override
  Widget build(BuildContext context) {
    final zoneName = widget.zone['zoneName']?.toString() ?? '';
    final shopsAsync = ref.watch(gameDbProvider(shopsSchema));
    final enemiesAsync = ref.watch(gameDbProvider(enemiesSchema));
    final shops = shopsAsync.value;
    final enemies = enemiesAsync.value;

    if (shops == null || enemies == null) {
      return Scaffold(
        appBar: AppBar(title: Text(zoneName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    _current ??= _rollEvent(shops: shops, enemies: enemies);
    final lang = ref.watch(appLanguageProvider);

    return Scaffold(
      appBar: AppBar(title: Text(zoneName)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: switch (_phase) {
            _ExpeditionPhase.event =>
              _buildEvent(context, shops: shops, enemies: enemies, lang: lang),
            _ExpeditionPhase.completed => _buildSummary(
                context,
                icon: Icons.flag_circle,
                title: trFor(lang, 'zone_cleared_prefix'),
              ),
            _ExpeditionPhase.retreated => _buildSummary(
                context,
                icon: Icons.directions_walk,
                title: trFor(lang, 'expedition_ended_title'),
              ),
          },
        ),
      ),
    );
  }

  Widget _buildEvent(
    BuildContext context, {
    required Map<String, dynamic> shops,
    required Map<String, dynamic> enemies,
    required AppLanguage lang,
  }) {
    final node = _current!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
            value: (_index / _expeditionCount).clamp(0.0, 1.0)),
        const SizedBox(height: 8),
        Text(
          _isBossNode(node)
              ? trFor(lang, 'expedition_boss_label')
              : _isMidpointNode(node)
                  ? trFor(lang, 'expedition_midpoint_label')
                  : '${trFor(lang, 'expedition_progress_label')} ${_index + 1} / $_expeditionCount',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        // Why every event here happens: the party came to clear this
        // place, and its guardian stands between them and what it holds.
        Text(
          _goalLine(lang, enemies),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (node.contextNoteFor(lang == AppLanguage.fr)
                    case final note?) ...[
                  Text(
                    note,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_aftermath != null && _aftermath!.isNotEmpty) ...[
                  Text(
                    _aftermath!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  node.descriptionFor(lang == AppLanguage.fr),
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // A temptation scene offers two answers; every other event has one.
        for (final choice in node.choices) ...[
          ElevatedButton(
            onPressed: _busy
                ? null
                : () => _resolveChoice(choice, shops: shops, enemies: enemies),
            child: Text(_choiceLabel(choice)),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _endAsRetreat(defeated: false),
          icon: const Icon(Icons.directions_walk),
          label: Text(trFor(lang, 'retreat_button')),
        ),
      ],
    );
  }

  /// "Clear 4 encounters here, then its guardian, Overseer Renn, to claim
  /// the zone." -- the reason the party is fighting its way through.
  String _goalLine(AppLanguage lang, Map<String, dynamic> enemies) {
    final bossName =
        (enemies[_bossEnemyId] as Map<String, dynamic>?)?['enemyName']
                ?.toString() ??
            '';
    final key =
        bossName.isEmpty ? 'expedition_goal_no_boss' : 'expedition_goal';
    return trFor(lang, key)
        .replaceAll('{n}', '$_expeditionCount')
        .replaceAll('{boss}', bossName);
  }

  Widget _buildSummary(BuildContext context,
      {required IconData icon, required String title}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        for (final line in _summaryLines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(line, textAlign: TextAlign.center),
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_phase == _ExpeditionPhase.completed),
          child: Text(
              trFor(ref.watch(appLanguageProvider), 'return_to_town_button')),
        ),
      ],
    );
  }
}
