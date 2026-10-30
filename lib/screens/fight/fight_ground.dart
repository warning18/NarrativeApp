part of '../fight_screen.dart';

/// The ground the fight is on (v1.241): its stage, drawn behind the battle,
/// and the anomaly that may break over it -- see field_anomaly.dart for the
/// rules and fight_backdrop.dart for the picture.
extension _FightGround on _FightScreenState {
  /// The place the story stands at (null with no place: a detour, a test).
  String? _placeIdHere() {
    final geography = ref.read(geographyProvider);
    final story = ref.read(storyDataProvider).value;
    final play = ref.read(storyPlayProvider);
    return geography.placeOfNode(story?.nodeFor(play.currentNodeId))?.id;
  }

  /// Where this fight is drawn: the scene's own stage when the choice names
  /// one, else the stage the place the story stands at names (a hall for a
  /// prison or a crypt), else a town's streets, else the pattern of the
  /// land's biome, else open country.
  FightStage _stageHere() {
    final forced = widget.modifiers.forcedStage;
    if (forced != null) return forced;
    final geography = ref.read(geographyProvider);
    final placeId = _placeIdHere();
    final named = fightStageFromName(geography.placeStageNameOf(placeId));
    if (named != null) return named;
    // Open country has a few faces: the place picks one and keeps it.
    return poolStageOf(
        fightStageOf(geography.biomeOf(placeId)?.pattern,
            town: guardedPlaceKinds
                .contains(geography.locationOf(placeId)?.kind)),
        placeId);
  }

  /// The light this fight is fought in (see place_traits.dart): the place's,
  /// else the day's.
  String _lightHere() {
    if (widget.modifiers.tutorial) return '';
    return ref.read(geographyProvider).lightOf(_placeIdHere());
  }

  /// Sets the stage and rolls (or takes the forced) anomaly, once, in
  /// [_ensureEnemiesBuilt]. A lesson meets none; a test fight and a fight
  /// whose circumstances the story set itself (a forced condition: the
  /// ambush of a sneak gone wrong) meet one only when it is forced.
  void _setTheGround({required bool lesson}) {
    final modifiers = widget.modifiers;
    _stage = _stageHere();
    if (lesson) return;
    // The fight's context rule (context_rules.dart): a test fight keeps
    // the Tide alone.
    // On the feature ladder a place's rule waits for its fight; the Tide,
    // unmarked, plays meanwhile (feature_unlocks.dart).
    if (!modifiers.isTest) {
      _length.rule =
          ref.read(playerSessionProvider).featureOpen(GameFeature.placeRules)
              ? _contextRuleHere()
              : ContextRule.tide;
    }
    final forced = modifiers.forcedAnomaly;
    if (forced != null) {
      _anomaly = forced;
      return;
    }
    if (modifiers.isTest || modifiers.forcedCondition != null) return;
    final geography = ref.read(geographyProvider);
    final placeId = _placeIdHere();
    _anomaly = rollFieldAnomaly(
      stage: _stage,
      sky: _sky.kind == WeatherKind.clear ? null : _sky.kind,
      random: _random,
      // A dangerous place turns on its visitors more often; a holy one, a
      // haunted one or a ruin in its own way (see field_anomaly.dart).
      chanceFactor: dangerAnomalyFactor(geography.dangerOf(placeId)),
      tags: geography.tagsOf(placeId),
    );
  }

  /// The rule this fight plays by its place and foe: the watch in a city,
  /// a holy place's ground, the stage's own, the Tide where none applies or
  /// a boss is fought.
  ContextRule _contextRuleHere() {
    final geography = ref.read(geographyProvider);
    final placeId = _placeIdHere();
    return contextRuleFor(
      stage: _stage,
      bossFight: widget.modifiers.isZoneBoss ||
          widget._allEnemyEntries.any((e) =>
              isBossEnemy(e.key, e.value) || zoneBossEnemyIds.contains(e.key)),
      city: guardedPlaceKinds.contains(geography.place(placeId)?.kind),
      holy: geography.tagsOf(placeId).contains('holy'),
    );
  }

  /// The context rule as a round starts (context_rules.dart): its omen the
  /// round before it rises, its level as it rises, the ground's toll on
  /// both sides; in a boss's fight, the boss enraged as the Tide turns.
  /// Returns the watch's verdict when it breaks the fight up: true for the
  /// party ahead (the enemies scatter), false for both walking away; null
  /// while the fight goes on.
  bool? _contextRoundStart(List<_LogEntry> entries, AppLanguage lang) {
    final rule = _length.rule;
    final round = _roundsStarted;
    // What the foe is (foe_kind.dart): a beast tires, the dead crumble.
    for (final enemy in _enemies.where((e) => e.isAlive)) {
      final boss = isBossEnemy(enemy.enemyId, enemy.data);
      if (round == foeRuleStartRound &&
          !boss &&
          foeKindOf(enemy.data) == FoeKind.beast) {
        entries.add(_LogEntry(
            trFor(lang, 'foe_tiring_log')
                .replaceAll('{name}', enemy.displayName),
            _LogKind.info));
      }
      final dust = crumble(enemy.data, enemy.maxHealth, round, boss: boss);
      if (dust > 0) {
        enemy.currentHealth = afterTick(enemy.currentHealth, dust);
        entries.add(_LogEntry(
            trFor(lang, 'foe_crumbles_log')
                .replaceAll('{name}', enemy.displayName)
                .replaceAll('{n}', '$dust'),
            _LogKind.playerDamage));
      }
    }
    if (round == tideStartRound &&
        _enemies.any((e) => e.isAlive && isBossEnemy(e.enemyId, e.data))) {
      entries.add(_LogEntry(trFor(lang, 'boss_enraged_log'), _LogKind.info));
    }
    // The holder's people join in (context_rules.dart's reinforcements).
    if (!widget.modifiers.isTest) _reinforcements(entries, lang, round);
    final stem = rule.logStem;
    if (stem == null) return null;
    final start =
        rule == ContextRule.risingWater ? waterStartRound : risingStartRound;
    if (round == start - 1) {
      entries
          .add(_LogEntry(trFor(lang, 'context_${stem}_omen'), _LogKind.info));
    }
    if (rule.guardsCome(round)) {
      int sum(Iterable<int> values) => values.fold(0, (a, b) => a + b);
      final ahead = partyAheadOnHealth(
        partyHealth: sum(_party.map((m) => max(0, m.currentHealth))),
        partyMax: sum(_party.map((m) => m.maxHealth)),
        enemyHealth:
            sum(_enemies.where((e) => e.isAlive).map((e) => e.currentHealth)),
        enemyMax: sum(_enemies.map((e) => e.maxHealth)),
      );
      entries.add(_LogEntry(
          trFor(lang, ahead ? 'context_guards_won_log' : 'context_guards_log'),
          _LogKind.info));
      if (ahead) {
        for (final e in _enemies.where((e) => e.isAlive)) {
          e.fled = true;
          e.currentHealth = 0;
        }
      }
      return ahead;
    }
    final level = rule.levelAt(round);
    final rising = rule == ContextRule.risingWater
        ? level > 0 && level <= waterMaxLevel && round < start + waterMaxLevel
        : level > 0;
    if (!rising) return null;
    entries.add(_LogEntry(
        trFor(lang, 'context_${stem}_log').replaceAll('{n}', '$level'),
        _LogKind.info));
    // The mist's and the heat's toll, on both sides: it never finishes.
    final party = _party.where((m) => !m.isKnockedOut);
    for (final member in party) {
      member.currentHealth =
          afterTick(member.currentHealth, rule.tick(member.maxHealth, round));
    }
    for (final enemy in _enemies.where((e) => e.isAlive)) {
      enemy.currentHealth =
          afterTick(enemy.currentHealth, rule.tick(enemy.maxHealth, round));
    }
    return null;
  }

  /// The people of the clan that holds the place, joining the fight in
  /// [round] (context_rules.dart's reinforcements): on the party's side when
  /// it stands Friend or better with them, against it when they hunt it;
  /// never in a boss's fight, and never the finishing blow.
  void _reinforcements(List<_LogEntry> entries, AppLanguage lang, int round) {
    final bossFight = widget.modifiers.isZoneBoss ||
        _enemies.any((e) =>
            isBossEnemy(e.enemyId, e.data) ||
            zoneBossEnemyIds.contains(e.enemyId));
    if (!reinforcementsCome(round, bossFight: bossFight)) return;
    final geography = ref.read(geographyProvider);
    final politics = ref.read(politicsProvider);
    final data = ref.read(clanDataProvider);
    final placeId = _placeIdHere();
    final who = reinforcementAt(placeId, geography, politics, data);
    if (who == Reinforcement.none) return;
    final clan =
        data.faction(holderOf(placeId, geography, politics))?.nameOfFor(lang) ??
            '';
    if (who == Reinforcement.allies) {
      var struck = 0;
      for (final enemy in _enemies.where((e) => e.isAlive)) {
        final blow = allyStrike(enemy.maxHealth, round);
        enemy.currentHealth = afterTick(enemy.currentHealth, blow);
        struck = max(struck, blow);
      }
      entries.add(_LogEntry(
          trFor(lang, 'reinforce_allies_log')
              .replaceAll('{of}', clan)
              .replaceAll('{n}', '$struck'),
          _LogKind.playerDamage));
    } else {
      var struck = 0;
      for (final member in _party.where((m) => !m.isKnockedOut)) {
        final blow = foeStrike(member.maxHealth, round);
        member.currentHealth = afterTick(member.currentHealth, blow);
        struck = max(struck, blow);
      }
      entries.add(_LogEntry(
          trFor(lang, 'reinforce_foes_log')
              .replaceAll('{of}', clan)
              .replaceAll('{n}', '$struck'),
          _LogKind.enemyDamage));
    }
  }

  /// The anomaly's phase in the round now under way.
  AnomalyPhase get _anomalyPhase =>
      _anomaly?.phaseAt(_roundsStarted) ?? AnomalyPhase.quiet;

  /// [amount] of [element] after the day's sky and the anomaly (when it is
  /// upon the fight), struck by the party or by an enemy.
  int _groundDamage(int amount, String element, {required bool byParty}) {
    final skied = _sky.damage(amount, element);
    final plan = _anomaly;
    if (plan == null) return skied;
    return plan.damage(skied, element, byParty: byParty, round: _roundsStarted);
  }

  /// What is taken off the party's Perception by the sky and the anomaly.
  int get _groundPerceptionPenalty =>
      _sky.perceptionPenalty +
      (_anomaly?.perceptionPenalty(_roundsStarted) ?? 0);

  bool get _readsTheOmen =>
      _bestPartyPerception() - _sky.perceptionPenalty >= anomalyReadsSide;

  // --- Round by round ---------------------------------------------------------

  /// At the start of every party round: the omen, the break, the ticks and
  /// the end of the anomaly, in the log. Wounds never finish anyone.
  void _groundRoundStart(List<_LogEntry> entries, AppLanguage lang) {
    final plan = _anomaly;
    if (plan == null) return;
    final round = _roundsStarted;
    final name = trFor(lang, 'anomaly_${plan.anomaly.id}');
    switch (plan.phaseAt(round)) {
      case AnomalyPhase.quiet:
        return;
      case AnomalyPhase.omen:
        final omen = trFor(lang, 'anomaly_omen_${plan.anomaly.family.name}')
            .replaceAll('{name}', name);
        entries.add(_LogEntry(
            '$omen ${trFor(lang, _readsTheOmen ? _favourKey(plan) : 'anomaly_for_unknown')}',
            _LogKind.info));
      case AnomalyPhase.active:
        if (round == plan.onset) {
          entries.add(_LogEntry(
              '$name: ${anomalyEffectText(plan, lang).join(' · ')}',
              _LogKind.phase));
        }
        _applyTicks(plan, name, entries, lang);
      case AnomalyPhase.over:
        if (round == plan.last + 1) {
          entries.add(_LogEntry(
              trFor(lang, 'anomaly_over').replaceAll('{name}', name),
              _LogKind.info));
        }
    }
  }

  String _favourKey(FieldAnomalyPlan plan) => switch (plan.helpsParty) {
        true => 'anomaly_for_party',
        false => 'anomaly_for_enemies',
        null => 'anomaly_for_both',
      };

  void _applyTicks(FieldAnomalyPlan plan, String name, List<_LogEntry> entries,
      AppLanguage lang) {
    final style = anomalyVfxStyle(plan.anomaly);
    var delay = 0;
    for (final hit in plan.ticksAt(_roundsStarted)) {
      if (hit.onParty) {
        final living = [
          for (final member in _party)
            if (!member.isKnockedOut) member,
        ];
        for (final member in _tickTargets(living, hit)) {
          final amount = hit.amountFor(member.maxHealth);
          final before = member.currentHealth;
          member.currentHealth = hit.mend
              ? min(member.maxHealth, before + amount)
              : healthAfterHurt(before, amount);
          final change = (member.currentHealth - before).abs();
          if (change == 0) continue;
          _fx(hit.mend ? VfxStyle.heal : style, _memberCardKey(member.id),
              delayMs: delay += 140,
              text: '${hit.mend ? '+' : '-'}$change',
              textKind: hit.mend ? VfxTextKind.heal : VfxTextKind.hurt);
          entries.add(_tickEntry(lang, hit.mend, name, member.displayName,
              change, hit.mend ? _LogKind.playerHeal : _LogKind.enemyDamage));
        }
      } else {
        final living = [
          for (final enemy in _enemies)
            if (enemy.isAlive) enemy,
        ];
        for (final enemy in _tickTargets(living, hit)) {
          final amount = hit.amountFor(enemy.maxHealth);
          final before = enemy.currentHealth;
          enemy.currentHealth = hit.mend
              ? min(enemy.maxHealth, before + amount)
              : healthAfterHurt(before, amount);
          final change = (enemy.currentHealth - before).abs();
          if (change == 0) continue;
          _fx(hit.mend ? VfxStyle.heal : style, _enemyCardKey(enemy.key),
              delayMs: delay += 140,
              text: '${hit.mend ? '+' : '-'}$change',
              textKind: hit.mend ? VfxTextKind.heal : VfxTextKind.damage);
          entries.add(_tickEntry(lang, hit.mend, name, enemy.displayName,
              change, hit.mend ? _LogKind.enemyDamage : _LogKind.playerDamage));
        }
      }
    }
  }

  /// Who a tick falls on: everyone standing, or one of them by the roll.
  List<T> _tickTargets<T>(List<T> living, AnomalyTickHit hit) {
    if (living.isEmpty || !hit.one) return living;
    return [living[_random.nextInt(living.length)]];
  }

  _LogEntry _tickEntry(AppLanguage lang, bool mend, String name, String who,
      int amount, _LogKind kind) {
    return _LogEntry(
      trFor(lang, mend ? 'anomaly_mends_line' : 'anomaly_hurts_line')
          .replaceAll('{name}', name)
          .replaceAll('{who}', who)
          .replaceAll('{n}', '$amount')
          .replaceAll('{hp}', trFor(lang, 'hp_label')),
      kind,
    );
  }

  // --- On screen ----------------------------------------------------------------

  /// The ground behind the battle, under a veil that keeps the cards and
  /// the log readable in either theme.
  Widget _buildBackdrop({double veil = 0.4}) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        FightBackdrop(
          key: const Key('fight_backdrop'),
          stage: _stage,
          light: lightLevel(_light),
          weather: false,
          events: false,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.surface.withValues(alpha: veil + 0.2),
                scheme.surface.withValues(alpha: veil - 0.12),
                scheme.surface.withValues(alpha: veil + 0.25),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  /// The day's weather over the whole screen, cards and board included: it
  /// takes no touch and is read through.
  Widget _buildWeatherOverlay() {
    if (_sky.kind == WeatherKind.clear) return const SizedBox.shrink();
    return IgnorePointer(
      child: FightBackdrop(
        key: const Key('fight_weather'),
        stage: _stage,
        sky: _sky.kind,
        ground: false,
        events: false,
      ),
    );
  }

  /// The anomaly (an earth break, a storm, a glare) on the dice board alone.
  Widget _buildBoardEvent() {
    final plan = _anomaly;
    if (plan == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: FightBackdrop(
        key: const Key('fight_board_event'),
        stage: _stage,
        anomaly: plan.anomaly,
        phase: _anomalyPhase,
        ground: false,
        weather: false,
      ),
    );
  }

  /// The anomaly's chip over the battle once it is announced: its name, in
  /// green when it favours the party, in red when it favours the enemies,
  /// with its effects in the tooltip.
  Widget? _anomalyChip() {
    final plan = _anomaly;
    if (plan == null) return null;
    final phase = _anomalyPhase;
    if (phase != AnomalyPhase.omen && phase != AnomalyPhase.active) {
      return null;
    }
    final lang = ref.watch(appLanguageProvider);
    final name = trFor(lang, 'anomaly_${plan.anomaly.id}');
    final reads = phase == AnomalyPhase.active || _readsTheOmen;
    final favour = reads ? plan.helpsParty : null;
    final scheme = Theme.of(context).colorScheme;
    final colour = switch (favour) {
      true => Colors.green,
      false => scheme.error,
      null => scheme.tertiary,
    };
    final left = max(0, plan.last - _roundsStarted + 1);
    final soon = phase == AnomalyPhase.omen
        ? trFor(lang, 'anomaly_soon')
        : '$left${trFor(lang, 'anomaly_rounds_left')}';
    return _telegraphChip(
      anomalyIcon(plan.anomaly.family),
      name,
      key: const Key('fight_anomaly_chip'),
      color: colour,
      badge: phase == AnomalyPhase.omen ? '!' : '$left',
      subtitle: soon,
      tip: anomalyEffectText(plan, lang).join('\n'),
    );
  }

  /// The fight's title with the ground under it (its stage and the day's
  /// sky), for the app bar: it adds no height to the setup screen.
  Widget _buildTitle() {
    final lang = ref.watch(appLanguageProvider);
    final sky = _sky.kind == WeatherKind.clear
        ? ''
        : ' · ${trFor(lang, 'weather_${_sky.kind.name}')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${tr(ref, 'fight_prefix')}: ${_battleTitle()}'),
        Text(
          '${trFor(lang, 'stage_${_stage.name}')}$sky',
          key: const Key('fight_ground_strip'),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

/// The effect of the anomaly shown for each side, one clause per line, in
/// [lang]: elements, what a side deals, Perception, and the tick.
List<String> anomalyEffectText(FieldAnomalyPlan plan, AppLanguage lang) {
  final anomaly = plan.anomaly;
  String pct(num factor) {
    final n = ((factor - 1) * 100).round();
    final sign = n >= 0 ? '+' : '−';
    return lang == AppLanguage.fr ? '$sign${n.abs()} %' : '$sign${n.abs()}%';
  }

  final colon = lang == AppLanguage.fr ? '\u00A0:' : ':';
  String element(String name) =>
      trFor(lang, 'element_name_${name.toLowerCase()}');
  String who(AnomalySide side) => trFor(lang, 'anomaly_who_${side.name}');
  final lines = <String>[];
  final elements = {
    for (final e in anomaly.elements.entries) e.key: e.value,
  };
  if (elements.isNotEmpty) {
    lines.add([
      for (final e in elements.entries) '${element(e.key)} ${pct(e.value)}',
    ].join(', '));
  }
  if (anomaly.picksSide) {
    final side = plan.side;
    final sideLine = <String>[
      for (final e in anomaly.sideElements.entries)
        '${element(e.key)} ${pct(e.value)}',
      if (anomaly.sideDamage != 1)
        '${trFor(lang, 'anomaly_damage_word')} ${pct(anomaly.sideDamage)}',
    ];
    if (sideLine.isNotEmpty) {
      lines.add('${who(side)}$colon ${sideLine.join(', ')}');
    }
  }
  if (anomaly.perception > 0) {
    lines.add('${trFor(lang, 'perception_label')} −${anomaly.perception}');
  }
  final tick = anomaly.tick;
  if (tick != null) {
    final n = '${tick.mend ? '+' : '−'}${tick.percent}'
        '${lang == AppLanguage.fr ? ' ' : ''}%';
    final one = tick.one ? trFor(lang, 'anomaly_one_suffix') : '';
    lines.add('${who(plan.side)}${lang == AppLanguage.fr ? ' ' : ''}: '
        '$n ${trFor(lang, 'anomaly_health_round')}$one');
  }
  return lines;
}

/// The effect that plays for an anomaly's omen and its ticks.
VfxStyle anomalyVfxStyle(FieldAnomaly anomaly) => switch (anomaly.id) {
      'thunderstorm' || 'sea_storm' => VfxStyle.lightning,
      'rockslide' ||
      'cliff_fall' ||
      'collapse' ||
      'earth_break' ||
      'sinking_ground' ||
      'brine_crust' =>
        VfxStyle.quake,
      'heatstroke' ||
      'ember_pits' ||
      'scalding_vent' ||
      'blaze' =>
        VfxStyle.flame,
      'whiteout' || 'black_ice' || 'hailstorm' => VfxStyle.frost,
      'sandstorm' || 'tailwind' || 'ash_storm' => VfxStyle.wind,
      'flash_flood' ||
      'racing_tide' ||
      'downpour' ||
      'fog_bank' =>
        VfxStyle.splash,
      'eclipse' => VfxStyle.shadow,
      'marsh_lights' => VfxStyle.voidRift,
      'salt_glare' || 'glass_field' || 'sunburst' => VfxStyle.radiance,
      'wellspring' => VfxStyle.heal,
      _ => VfxStyle.impact,
    };

IconData anomalyIcon(AnomalyFamily family) => switch (family) {
      AnomalyFamily.storm => Icons.thunderstorm_outlined,
      AnomalyFamily.ground => Icons.landscape,
      AnomalyFamily.cold => Icons.ac_unit,
      AnomalyFamily.heat => Icons.local_fire_department,
      AnomalyFamily.water => Icons.water,
      AnomalyFamily.light => Icons.wb_sunny_outlined,
    };
