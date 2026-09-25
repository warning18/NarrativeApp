import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/dice_faces.dart';
import '../combat/encounter.dart';
import '../combat/enemy_affix.dart';
import '../combat/ship_combat.dart';
import '../data/chapter_grid_layout.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/aftermath_provider.dart';
import '../providers/combat_active_provider.dart';
import '../providers/combat_settings_provider.dart';
import '../providers/game_config_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import 'fight_screen.dart';
import 'ship_battle_panel.dart';
import 'voyage_screen.dart';

/// Zone-tier style multipliers offered for a test fight's enemies.
const List<double> _difficulties = [0.75, 1.0, 1.25, 1.5, 2.0];

/// Edit Mode: launches any land fight (one to three enemies, a chapter, a
/// difficulty, an affix, a die, alone or with the party) or any ship
/// battle, as a test. Tests never run permadeath, and the game is put
/// back as it was afterwards unless "Keep what happens" is on.
class FightLabScreen extends ConsumerStatefulWidget {
  const FightLabScreen({super.key});

  @override
  ConsumerState<FightLabScreen> createState() => _FightLabScreenState();
}

class _FightLabScreenState extends ConsumerState<FightLabScreen> {
  final List<String> _enemyIds = [];
  late int _chapter;
  double _difficulty = 1.0;
  EnemyAffix? _affix;
  String? _dieId;
  bool _solo = false;
  bool _fullHealth = true;
  bool _keep = false;
  String? _shipId;
  bool _allParts = false;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _chapter = max(1, chapterOfNode(ref.read(storyPlayProvider).currentNodeId));
  }

  String _enemyName(Map<String, dynamic> enemies, String id) =>
      (enemies[id] as Map<String, dynamic>?)?['enemyName']?.toString() ?? id;

  Future<void> _pickEnemy(Map<String, dynamic> enemies) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _EnemyPicker(enemies: enemies),
      ),
    );
    if (picked != null && mounted) setState(() => _enemyIds.add(picked));
  }

  /// Runs [battle] as a test: the session is prepared (die, party, health)
  /// before and put back after, keeping what happened only when asked.
  Future<void> _asTest(
      Future<bool?> Function() battle, String wonKey, String lostKey) async {
    if (_running) return;
    setState(() => _running = true);
    final notifier = ref.read(playerSessionProvider.notifier);
    final before = ref.read(playerSessionProvider);
    final outcomeBefore = ref.read(lastFightOutcomeProvider);
    final retreatedBefore = ref.read(lastFightRetreatedProvider);
    var test = before;
    final die = _dieId;
    if (die != null) {
      test = test.copyWith(
        equippedDiceId: die,
        ownedDiceIds: {...before.ownedDiceIds, die}.toList(),
      );
    }
    if (_solo) test = test.copyWith(activeAllyIds: const []);
    await notifier.loadSession(test);
    if (_fullHealth) await notifier.healPartyToFull();

    ref.read(combatActiveProvider.notifier).state = true;
    final won = await battle();
    ref.read(combatActiveProvider.notifier).state = false;

    final after = ref.read(playerSessionProvider);
    if (_keep) {
      await notifier.loadSession(after.copyWith(
        equippedDiceId: before.equippedDiceId,
        ownedDiceIds: {...before.ownedDiceIds, ...after.ownedDiceIds}
            .where((id) => id != die || before.ownedDiceIds.contains(id))
            .toList(),
        activeAllyIds: before.activeAllyIds,
      ));
    } else {
      await notifier.loadSession(before);
      ref.read(lastFightOutcomeProvider.notifier).state = outcomeBefore;
      ref.read(lastFightRetreatedProvider.notifier).state = retreatedBefore;
    }
    if (!mounted) return;
    setState(() => _running = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        '${tr(ref, won == true ? wonKey : lostKey)} · '
        '${tr(ref, _keep ? 'fight_lab_kept' : 'fight_lab_restored')}',
      ),
    ));
  }

  Future<void> _runFight(Map<String, dynamic> enemies) => _asTest(
        () => Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => FightScreen(
              enemyId: _enemyIds.first,
              enemy: enemies[_enemyIds.first] as Map<String, dynamic>,
              additionalEnemyIds: _enemyIds.skip(1).toList(),
              additionalEnemies: {
                for (final id in _enemyIds.skip(1))
                  id: enemies[id] as Map<String, dynamic>,
              },
              modifiers: EncounterModifiers(
                chapter: _chapter,
                difficultyMultiplier: _difficulty,
                forcedAffixes: [if (_affix != null) _affix!],
                isTest: true,
              ),
            ),
          ),
        ),
        'fight_lab_fight_won',
        'fight_lab_fight_lost',
      );

  Future<void> _runShip(Map<String, dynamic> enemyShips) async {
    final ships = ref.read(localizedDbProvider(shipsSchema)).value ?? {};
    final parts = ref.read(localizedDbProvider(shipPartsSchema)).value ?? {};
    final companions =
        ref.read(localizedDbProvider(companionsSchema)).value ?? {};
    final races = ref.read(localizedDbProvider(racesSchema)).value ?? {};
    final professions =
        ref.read(localizedDbProvider(professionsSchema)).value ?? {};
    final gameConfig = ref.read(gameConfigProvider).value ?? {};
    final shipId = _shipId ?? enemyShips.keys.first;
    final data = enemyShips[shipId] as Map<String, dynamic>;
    final lang = ref.read(appLanguageProvider);
    final fr = lang == AppLanguage.fr;
    final enemyName = (fr ? data['displayName_fr']?.toString() : null) ??
        data['displayName']?.toString() ??
        shipId;
    final chapter = _chapter;
    final allParts = _allParts;

    await _asTest(
      () {
        final session = ref.read(playerSessionProvider);
        final ship = ships['rusty_eel'] as Map<String, dynamic>? ??
            (ships.values.isEmpty
                ? const <String, dynamic>{}
                : ships.values.first as Map<String, dynamic>);
        final installed = allParts
            ? parts.keys.where((id) => !id.startsWith('sail_')).toList()
            : session.shipPartIds;
        List<ShipCrew> crew() => buildShipCrew(
              session: ref.read(playerSessionProvider),
              companions: companions,
              races: races,
              professions: professions,
              gameConfig: gameConfig,
              youLabel: trFor(lang, 'you_label'),
            );
        return Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (pageContext) => Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: Text('${trFor(lang, 'fight_lab_title')} · $enemyName'),
              ),
              body: ShipBattlePanel(
                player: buildPlayerShip(
                  ship: ship,
                  parts: parts,
                  installedPartIds: installed,
                  currentHull: -1,
                ),
                enemy: buildEnemyShip(data),
                shipName: trFor(lang, 'boat_title'),
                enemyName: enemyName,
                crew: crew(),
                foresight: false,
                random: Random(),
                boarding: boardingProfileFor(data),
                chapter: chapter,
                buildCrew: crew,
                isTest: true,
                turnSeconds: ref.read(shipTurnTimerProvider)
                    ? shipTurnSeconds(
                        ship: ship, parts: parts, installedPartIds: installed)
                    : null,
                onFinished: (outcome) =>
                    Navigator.of(pageContext).pop(outcome.won),
              ),
            ),
          ),
        );
      },
      'fight_lab_ship_won',
      'fight_lab_ship_lost',
    );
  }

  @override
  Widget build(BuildContext context) {
    final enemies = ref.watch(localizedDbProvider(enemiesSchema)).value ??
        const <String, dynamic>{};
    final dice = ref.watch(localizedDbProvider(diceSchema)).value ??
        const <String, dynamic>{};
    final enemyShips = ref.watch(localizedDbProvider(enemyShipsSchema)).value ??
        const <String, dynamic>{};
    final session = ref.watch(playerSessionProvider);
    final lang = ref.watch(appLanguageProvider);
    final fr = lang == AppLanguage.fr;
    final theme = Theme.of(context);
    final diceIds = dice.keys.toList()..sort();
    final shipIds = enemyShips.keys.toList()..sort();

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(title, style: theme.textTheme.titleMedium),
        );

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'fight_lab_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(tr(ref, 'fight_lab_intro'), style: theme.textTheme.bodySmall),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr(ref, 'fight_lab_keep')),
            subtitle: Text(tr(ref, 'fight_lab_keep_desc')),
            value: _keep,
            onChanged: (v) => setState(() => _keep = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr(ref, 'fight_lab_full_health')),
            value: _fullHealth,
            onChanged: (v) => setState(() => _fullHealth = v),
          ),
          Text('${tr(ref, 'chapter_label')} $_chapter',
              style: theme.textTheme.labelLarge),
          Slider(
            value: _chapter.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            label: '$_chapter',
            onChanged: (v) => setState(() => _chapter = v.round()),
          ),

          // ---- Land fight --------------------------------------------
          section(tr(ref, 'fight_lab_land_section')),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (var i = 0; i < _enemyIds.length; i++)
                InputChip(
                  label: Text(_enemyName(enemies, _enemyIds[i])),
                  onDeleted: () => setState(() => _enemyIds.removeAt(i)),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: Text(tr(ref, 'fight_lab_add_enemy')),
                onPressed: _enemyIds.length >= 3 || enemies.isEmpty
                    ? null
                    : () => _pickEnemy(enemies),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(tr(ref, 'fight_lab_difficulty'),
              style: theme.textTheme.labelLarge),
          Wrap(
            spacing: 8,
            children: [
              for (final d in _difficulties)
                ChoiceChip(
                  label: Text('×$d'),
                  selected: _difficulty == d,
                  onSelected: (_) => setState(() => _difficulty = d),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(tr(ref, 'fight_lab_affix'), style: theme.textTheme.labelLarge),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(tr(ref, 'fight_lab_none')),
                selected: _affix == null,
                onSelected: (_) => setState(() => _affix = null),
              ),
              for (final affix in EnemyAffix.values)
                ChoiceChip(
                  label: Text(tr(ref, affixLabelKey(affix))),
                  selected: _affix == affix,
                  onSelected: (_) => setState(() => _affix = affix),
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            key: ValueKey('die_${_dieId ?? ''}'),
            initialValue: _dieId,
            isExpanded: true,
            decoration: InputDecoration(labelText: tr(ref, 'fight_lab_die')),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(
                    '${tr(ref, 'fight_lab_equipped_die')}: ${dieDisplayName(session.equippedDiceId ?? 'starter_die', language: lang)}'),
              ),
              for (final id in diceIds)
                DropdownMenuItem<String?>(
                  value: id,
                  child: Text(dieDisplayName(id, language: lang)),
                ),
            ],
            onChanged: (v) => setState(() => _dieId = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr(ref, 'fight_lab_solo')),
            subtitle: Text(session.activeAllyIds.isEmpty
                ? tr(ref, 'fight_lab_no_party')
                : '${tr(ref, 'fight_lab_party')}: ${session.activeAllyIds.length}'),
            value: _solo,
            onChanged: (v) => setState(() => _solo = v),
          ),
          FilledButton.icon(
            key: const Key('fight_lab_start_fight'),
            onPressed:
                _enemyIds.isEmpty || _running ? null : () => _runFight(enemies),
            icon: const Icon(Icons.sports_martial_arts),
            label: Text(tr(ref, 'fight_lab_start_fight')),
          ),

          // ---- Ship battle -------------------------------------------
          section(tr(ref, 'fight_lab_ship_section')),
          if (shipIds.isNotEmpty)
            DropdownButtonFormField<String>(
              key: ValueKey('ship_${_shipId ?? ''}'),
              initialValue: _shipId ?? shipIds.first,
              isExpanded: true,
              decoration:
                  InputDecoration(labelText: tr(ref, 'fight_lab_enemy_ship')),
              items: [
                for (final id in shipIds)
                  DropdownMenuItem(
                    value: id,
                    child: Text(() {
                      final ship = enemyShips[id] as Map<String, dynamic>;
                      final name =
                          (fr ? ship['displayName_fr']?.toString() : null) ??
                              ship['displayName']?.toString() ??
                              id;
                      final ch = (ship['minChapter'] as num?)?.toInt();
                      return ch == null
                          ? name
                          : '$name · ${tr(ref, 'chapter_label')} $ch';
                    }()),
                  ),
              ],
              onChanged: (v) => setState(() => _shipId = v),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr(ref, 'fight_lab_all_parts')),
            subtitle: Text(tr(ref, 'fight_lab_all_parts_desc')),
            value: _allParts,
            onChanged: (v) => setState(() => _allParts = v),
          ),
          FilledButton.icon(
            key: const Key('fight_lab_start_ship'),
            onPressed:
                shipIds.isEmpty || _running ? null : () => _runShip(enemyShips),
            icon: const Icon(Icons.sailing),
            label: Text(tr(ref, 'fight_lab_start_ship')),
          ),
        ],
      ),
    );
  }
}

/// Every enemy, searchable, grouped by the chapter it first appears in.
class _EnemyPicker extends ConsumerStatefulWidget {
  const _EnemyPicker({required this.enemies});

  final Map<String, dynamic> enemies;

  @override
  ConsumerState<_EnemyPicker> createState() => _EnemyPickerState();
}

class _EnemyPickerState extends ConsumerState<_EnemyPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final entries = widget.enemies.entries
        .where((e) => e.value is Map<String, dynamic>)
        .map((e) => MapEntry(e.key, e.value as Map<String, dynamic>))
        .where((e) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return e.key.toLowerCase().contains(q) ||
          (e.value['enemyName']?.toString().toLowerCase().contains(q) ?? false);
    }).toList()
      ..sort((a, b) {
        final ca = (a.value['minChapter'] as num?)?.toInt() ?? 1;
        final cb = (b.value['minChapter'] as num?)?.toInt() ?? 1;
        if (ca != cb) return ca.compareTo(cb);
        return (a.value['enemyName']?.toString() ?? a.key)
            .compareTo(b.value['enemyName']?.toString() ?? b.key);
      });
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            autofocus: false,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: tr(ref, 'fight_lab_search_enemy'),
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final e in entries)
                ListTile(
                  dense: true,
                  title: Text(e.value['enemyName']?.toString() ?? e.key),
                  subtitle: Text(
                    '${tr(ref, 'chapter_label')} ${(e.value['minChapter'] as num?)?.toInt() ?? 1} · '
                    '${tr(ref, 'hp_label')} ${e.value['maxHealth']} · '
                    '${tr(ref, 'damage_label')} ${e.value['damage']}',
                  ),
                  trailing: Text(e.key,
                      style: Theme.of(context).textTheme.labelSmall),
                  onTap: () => Navigator.of(context).pop(e.key),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
