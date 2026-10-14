part of '../fight_screen.dart';

/// The fight's goal and its enemies' doctrine (v1.212, see fight_goal.dart
/// and doctrine.dart): the progress checks, the thieves' purse, and the
/// banners and chips that say so.
extension _FightGoals on _FightScreenState {
  /// Checked after every blow that can hurt an enemy, before the Skittish
  /// check (a fighter who would yield yields, rather than flees): a Rout's
  /// fallen captain routs the rest, a Subdue's broken fighter yields.
  void _noteGoalProgress(List<_LogEntry> entries, AppLanguage lang) {
    switch (_goal.kind) {
      case FightGoalKind.rout:
        final captain = _enemies.where((e) => e.isCaptain).firstOrNull;
        if (captain == null || captain.isAlive) return;
        final rest = _enemies.where((e) => e.isAlive).toList();
        if (rest.isEmpty) return;
        for (final enemy in rest) {
          enemy.fled = true;
          enemy.currentHealth = 0;
        }
        entries
            .add(_LogEntry(trFor(lang, 'goal_won_rout_log'), _LogKind.victory));
      case FightGoalKind.subdue:
        for (final enemy in _enemies) {
          if (!enemy.isAlive || enemy.yielded) continue;
          if (!yieldsNow(enemy.currentHealth, enemy.maxHealth)) continue;
          enemy.yielded = true;
          enemy.currentHealth = 0;
          entries.add(_LogEntry(
              trFor(lang, 'goal_yield_log')
                  .replaceAll('{name}', enemy.displayName),
              _LogKind.victory));
        }
      case FightGoalKind.hold:
      case FightGoalKind.slay:
        return;
    }
  }

  /// True once a hold has been held: called when the enemies' turn is
  /// over, with the fight still going.
  bool get _holdHeld =>
      holdComplete(_goal, _roundsStarted) && _enemies.any((e) => e.isAlive);

  /// The Writ falls on [round]: the party's skill faces fall silent.
  bool _writFalls(int round) =>
      _doctrine?.rule == DoctrineRule.writ && writSilencesRound(round);

  /// A thief of the Short Con landed a hit: it lifts a share of its own
  /// reward, carried until it is defeated.
  void _plunderFrom(_EnemyMember enemy, AppLanguage lang) {
    final doctrine = _doctrine;
    if (doctrine == null ||
        doctrine.rule != DoctrineRule.plunder ||
        enemy.faction != doctrine.factionId) {
      return;
    }
    final reward = scaledReward(
        (enemy.data['goldReward'] as num?)?.toInt() ?? 0, _playerLevel);
    final hit = plunderPerHit(reward);
    if (hit <= 0) return;
    final before = enemy.stash;
    enemy.stash = plunderStashAfter(before, hit, plunderCap(reward));
    final lifted = enemy.stash - before;
    if (lifted <= 0) return;
    _log.add(_LogEntry(
        trFor(lang, 'plunder_hit_log')
            .replaceAll('{name}', enemy.displayName)
            .replaceAll('{n}', '$lifted'),
        _LogKind.enemyDamage));
  }

  /// The goal's name and rules text, with its numbers filled in.
  String _goalName() => tr(ref, goalLabelKey(_goal.kind));

  String _goalText() => tr(ref, goalDescriptionKey(_goal.kind))
      .replaceAll('{n}', '${_goal.rounds}')
      .replaceAll('{pct}', '${(yieldHealthShare * 100).round()}');

  IconData get _goalIcon => switch (_goal.kind) {
        FightGoalKind.hold => Icons.shield_outlined,
        FightGoalKind.rout => Icons.flag_outlined,
        FightGoalKind.subdue => Icons.handshake_outlined,
        FightGoalKind.slay => Icons.sports_martial_arts,
      };

  /// The goal's banner on the setup screen: what the fight asks, so it is
  /// read before the first die is rolled.
  Widget _buildGoalBanner() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('fight_goal_banner'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.secondary),
      ),
      child: Row(
        children: [
          Icon(_goalIcon, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tr(ref, 'goal_label')}: ${_goalName()}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  _goalText(),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorScheme.onSecondaryContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The doctrine's banner on the setup screen: whose fighters these are
  /// and how they fight.
  Widget _buildDoctrineBanner(Doctrine doctrine) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('fight_doctrine_banner'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(Icons.gavel, color: colorScheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tr(ref, 'doctrine_label')}: ${tr(ref, doctrine.nameKey)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  tr(ref, doctrine.descriptionKey),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorScheme.onErrorContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The goal's chips during battle: the goal itself (a hold counts its
  /// rounds) and the doctrine.
  List<Widget> _goalChips() => [
        if (!_goal.isSlay)
          _telegraphChip(
            _goalIcon,
            _goal.kind == FightGoalKind.hold
                ? tr(ref, 'goal_chip_hold')
                    .replaceAll('{r}', '${min(_roundsStarted, _goal.rounds)}')
                    .replaceAll('{n}', '${_goal.rounds}')
                : _goalName(),
          ),
        if (_doctrine != null)
          _telegraphChip(Icons.gavel, tr(ref, _doctrine!.nameKey)),
      ];

  /// The marks on an enemy's card: the Rout's captain, a thief's purse.
  List<Widget> _goalMarks(_EnemyMember enemy) => [
        if (enemy.isCaptain && enemy.isAlive)
          _stateChip(Icons.military_tech, tr(ref, 'goal_captain'),
              Colors.amber.shade800),
        if (enemy.stash > 0 && enemy.isAlive)
          _stateChip(
              Icons.savings_outlined,
              tr(ref, 'plunder_stash_chip').replaceAll('{n}', '${enemy.stash}'),
              Colors.brown),
      ];
}
