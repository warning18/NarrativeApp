import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/map_themes.dart';
import '../data/sub_node_engine.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
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

  int get _expeditionCount => (widget.zone['expeditionCount'] as num?)?.toInt() ?? 3;

  StoryNode _rollEvent({
    required Map<String, dynamic> shops,
    required Map<String, dynamic> enemies,
  }) {
    final session = ref.read(playerSessionProvider);
    final theme = MapTheme.values.firstWhere(
      (t) => t.name == (widget.zone['mapTheme']?.toString() ?? ''),
      orElse: () => defaultMapTheme,
    );
    final shopPool = shops.keys.where((id) => !session.unlockedShopIds.contains(id)).toList();
    final enemyPool =
        enemies.keys.where((id) => !session.unlockedEnemyIds.contains(id)).toList();
    return SubNodeEngine.buildNode(
      random: _random,
      flavor: flavorFor(theme),
      shopPool: shopPool,
      enemyPool: enemyPool,
    );
  }

  Future<void> _advance({
    required Map<String, dynamic> shops,
    required Map<String, dynamic> enemies,
  }) async {
    final nextIndex = _index + 1;
    if (nextIndex >= _expeditionCount) {
      await _completeZone();
      return;
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
    setState(() => _busy = true);
    final notifier = ref.read(playerSessionProvider.notifier);

    final enemyId = choice.triggerEnemyId;
    if (enemyId != null && enemyId.isNotEmpty) {
      final enemy = enemies[enemyId] as Map<String, dynamic>?;
      if (enemy == null) {
        await _advance(shops: shops, enemies: enemies);
        return;
      }
      final won = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => FightScreen(enemyId: enemyId, enemy: enemy)),
      );
      if (!mounted) return;
      if (won != true) {
        await _endAsRetreat(defeated: true);
        return;
      }
      await notifier.unlockContent(enemyId: enemyId);
      if (!mounted) return;
      await _advance(shops: shops, enemies: enemies);
      return;
    }

    final shopId = choice.unlockShopId;
    if (shopId != null && shopId.isNotEmpty) {
      final shop = shops[shopId] as Map<String, dynamic>?;
      await notifier.unlockContent(shopId: shopId);
      if (shop != null && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ShopDetailScreen(shopId: shopId, shop: shop)),
        );
      }
      if (!mounted) return;
      await _advance(shops: shops, enemies: enemies);
      return;
    }

    final questId = choice.unlockQuestId;
    if (questId != null && questId.isNotEmpty) {
      await notifier.unlockContent(questId: questId);
      if (!mounted) return;
      await _advance(shops: shops, enemies: enemies);
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
    await _advance(shops: shops, enemies: enemies);
  }

  Future<void> _completeZone() async {
    final notifier = ref.read(playerSessionProvider.notifier);
    final rewardGold = (widget.zone['rewardGold'] as num?)?.toInt() ?? 0;
    final rewardItemId = widget.zone['rewardItemId']?.toString() ?? '';
    final rewardDiceId = widget.zone['rewardDiceId']?.toString() ?? '';
    final rewardAllyId = widget.zone['rewardAllyId']?.toString() ?? '';
    final rewardFlag = widget.zone['rewardFlag']?.toString() ?? '';
    final lang = ref.read(appLanguageProvider);
    final companions = ref.read(gameDbProvider(companionsSchema)).value ?? const {};

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
      final itemName = (items[rewardItemId] as Map<String, dynamic>?)?['itemName']?.toString();
      lines.add(itemName ?? rewardItemId);
    }
    if (rewardDiceId.isNotEmpty) {
      final dice = ref.read(gameDbProvider(diceSchema)).value ?? const {};
      final diceName = (dice[rewardDiceId] as Map<String, dynamic>?)?['diceName']?.toString();
      lines.add(diceName ?? rewardDiceId);
    }
    if (rewardAllyId.isNotEmpty) {
      final races = ref.read(gameDbProvider(racesSchema)).value ?? const {};
      final professions = ref.read(gameDbProvider(professionsSchema)).value ?? const {};
      final companion = companions[rewardAllyId] as Map<String, dynamic>?;
      final race = races[companion?['raceId']?.toString() ?? ''] as Map<String, dynamic>?;
      final profession =
          professions[companion?['professionId']?.toString() ?? ''] as Map<String, dynamic>?;
      await notifier.recruitAlly(rewardAllyId, race: race, profession: profession);
      lines.add(companion?['companionName']?.toString() ?? rewardAllyId);
    }
    if (rewardFlag.isNotEmpty) {
      final flagKey = 'zone_flag_$rewardFlag';
      final flagLine = trFor(lang, flagKey);
      if (flagLine != flagKey) lines.add(flagLine);
    }

    final newAchievements =
        await notifier.checkAchievements(totalCompanionCount: companions.length);
    if (newAchievements.isNotEmpty) {
      final achievements = ref.read(gameDbProvider(achievementsSchema)).value ?? const {};
      for (final id in newAchievements) {
        final name = (achievements[id] as Map<String, dynamic>?)?['achievementName']?.toString();
        lines.add('${trFor(lang, 'achievement_unlocked_prefix')}: ${name ?? id}');
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
          defeated ? 'expedition_defeated_message' : 'expedition_retreat_message',
        ),
      ];
      _busy = false;
    });
  }

  String _choiceLabel(StoryChoice choice) =>
      ref.watch(appLanguageProvider) == AppLanguage.fr && (choice.textFr?.isNotEmpty ?? false)
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
        LinearProgressIndicator(value: _index / _expeditionCount),
        const SizedBox(height: 8),
        Text(
          '${trFor(lang, 'expedition_progress_label')} ${_index + 1} / $_expeditionCount',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              node.descriptionFor(lang == AppLanguage.fr),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (node.choices.isNotEmpty)
          ElevatedButton(
            onPressed: _busy
                ? null
                : () => _resolveChoice(node.choices.first, shops: shops, enemies: enemies),
            child: Text(_choiceLabel(node.choices.first)),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _endAsRetreat(defeated: false),
          icon: const Icon(Icons.directions_walk),
          label: Text(trFor(lang, 'retreat_button')),
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context, {required IconData icon, required String title}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        for (final line in _summaryLines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(line, textAlign: TextAlign.center),
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_phase == _ExpeditionPhase.completed),
          child: Text(trFor(ref.watch(appLanguageProvider), 'return_to_town_button')),
        ),
      ],
    );
  }
}
