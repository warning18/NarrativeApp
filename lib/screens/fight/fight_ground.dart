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
  /// one, else the stage of the place the story stands at (a hall for a
  /// prison or a crypt, otherwise the pattern of the land's biome), else
  /// open country.
  FightStage _stageHere() {
    final forced = widget.modifiers.forcedStage;
    if (forced != null) return forced;
    final geography = ref.read(geographyProvider);
    final named = fightStageFromName(geography.stageNameOf(_placeIdHere()));
    return named ?? FightStage.fields;
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
    final plan = _anomaly;
    return Stack(
      fit: StackFit.expand,
      children: [
        FightBackdrop(
          key: const Key('fight_backdrop'),
          stage: _stage,
          sky: _sky.kind == WeatherKind.clear ? null : _sky.kind,
          anomaly: plan?.anomaly,
          phase: _anomalyPhase,
          light: lightLevel(_light),
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
    final soon = phase == AnomalyPhase.omen
        ? ' · ${trFor(lang, 'anomaly_soon')}'
        : ' · ${max(0, plan.last - _roundsStarted + 1)}'
            '${trFor(lang, 'anomaly_rounds_left')}';
    return Tooltip(
      message: anomalyEffectText(plan, lang).join('\n'),
      child: Container(
        key: const Key('fight_anomaly_chip'),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.18),
          border: Border.all(color: colour.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(anomalyIcon(plan.anomaly.family), size: 12, color: colour),
            const SizedBox(width: 3),
            Text('$name$soon',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface)),
          ],
        ),
      ),
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
