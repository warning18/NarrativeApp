part of '../ship_battle_panel.dart';

/// The dock at the bottom (the clock, the aim bar, the weapons) and the status
/// chips and bars around the sea. Cut out of ship_battle_panel.dart with no
/// change (setState is called as _update).
extension _ShipBattleDock on _ShipBattlePanelState {
  /// The player's side of the turn, always in reach at the bottom: the
  /// clock, the hint (or the aim bar), the weapons, the shot, the crew and
  /// the end of the turn.
  Widget _buildDock(AppLanguage lang, bool fr, Map<String, dynamic>? enemies,
      bool canBoard, String hint,
      {bool warn = false}) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final total = max(1, widget.turnSeconds ?? 1);
    final timed = widget.turnSeconds != null && !_over;
    return DecoratedBox(
      key: const Key('ship_dock'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: ink.seam)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The turn's clock runs along the top edge.
          if (timed)
            LinearProgressIndicator(
              value: (_secondsLeft / total).clamp(0.0, 1.0),
              minHeight: 3,
              color: !_busy && _secondsLeft <= 5 ? ink.blood : ink.gold,
              backgroundColor: ink.seam,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _shipBar(
                  name: widget.shipName,
                  ship: _battle.player,
                  evasion: _battle.playerEvasion,
                  color: ink.gold,
                  eel: true,
                ),
                const SizedBox(height: 6),
                if (_aimRoom != null)
                  _buildAimBar(lang)
                else
                  Row(
                    children: [
                      // The round and what just happened (or, before
                      // anything has, what to do); the whole log a tap away.
                      Expanded(
                        child: Tooltip(
                          message: hint,
                          child: Text(
                            // Under 30% hull the warning to run stands in
                            // for the log, in red.
                            warn
                                ? '${trFor(lang, 'round_label')} ${_battle.turn} · $hint'
                                : '${trFor(lang, 'round_label')} ${_battle.turn} · '
                                    '${_battle.log.isEmpty ? hint : _battle.log.reversed.take(2).map(_line).join('\n')}',
                            key: Key(warn ? 'ship_hint' : 'ship_log'),
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: (_busy && !_over) || warn
                                    ? ink.blood
                                    : ink.ash),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('ship_log_button'),
                        tooltip: trFor(lang, 'ship_log_title'),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                            width: 30, height: 26),
                        icon: Icon(Icons.history,
                            size: IconSize.s16, color: ink.ash),
                        onPressed: _battle.log.isEmpty ? null : _openLog,
                      ),
                      if (timed) ...[
                        const SizedBox(width: 8),
                        _buildClock(lang),
                      ],
                    ],
                  ),
                const SizedBox(height: 6),
                _buildPlayerWeapons(fr),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton.outlined(
                      key: const Key('ship_crew_button'),
                      tooltip: trFor(lang, 'ship_crew_title'),
                      onPressed: _battle.crew.isEmpty
                          ? null
                          : () => _openCrewSheet(enemies),
                      icon: const Icon(Icons.groups_2_outlined,
                          size: IconSize.s16),
                    ),
                    const SizedBox(width: 8),
                    // Push a room past its limit, once a turn.
                    if (widget.rules.push) ...[
                      IconButton.outlined(
                        key: const Key('ship_push_button'),
                        tooltip: trFor(lang, 'ship_push_button'),
                        onPressed: _canPushNow ? _openPushSheet : null,
                        icon: Icon(Icons.bolt,
                            size: IconSize.s16,
                            color: _canPushNow ? ink.ember : null),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Boarding takes what room the row has left (a
                    // phone's is narrow); else End turn keeps to the
                    // corner.
                    if (canBoard) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('ship_board_button'),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10)),
                          onPressed: () => _boardThem(enemies),
                          icon: const Icon(Icons.sports_kabaddi,
                              size: IconSize.s16),
                          label: Text(trFor(lang, 'ship_board_button'),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ] else
                      const Spacer(),
                    // End turn: compact, at the thumb's corner.
                    FilledButton.icon(
                      key: const Key('ship_end_turn'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 16)),
                      onPressed:
                          _busy || _over ? null : () => _endTurn(manual: true),
                      icon: const Icon(Icons.hourglass_bottom,
                          size: IconSize.s16),
                      label: Text(trFor(lang, 'ship_end_turn_button')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The turn's seconds left, red for the last five and still while the
  /// enemy fires (its bar runs along the top of the dock). While half of
  /// it is left, ending the turn is quick orders.
  Widget _buildClock(AppLanguage lang) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final urgent = !_busy && _secondsLeft <= 5;
    final color = urgent ? ink.blood : ink.gold;
    final quick = _quickNow;
    return Row(
      key: const Key('ship_turn_clock'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: IconSize.s16, color: color),
        const SizedBox(width: 3),
        Text(
          trFor(lang, 'ship_turn_seconds').replaceAll('{n}', '$_secondsLeft'),
          style: theme.textTheme.labelMedium?.copyWith(
              color: color, fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: trFor(lang, 'ship_quick_orders_hint')
              .replaceAll('{n}', '$quickOrdersEvasion'),
          child: Row(
            key: const Key('ship_quick_orders'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt,
                  size: IconSize.s16, color: quick ? ink.ember : ink.ash),
              Text(
                '+$quickOrdersEvasion%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: quick ? ink.ember : ink.ash,
                  fontWeight: quick ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The aim bar: a marker sweeps from edge to edge; stop it in the middle
  /// for a critical, in the amber for a plain shot; at the red edges the
  /// shot goes wide.
  Widget _buildAimBar(AppLanguage lang) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Row(
      key: const Key('ship_aim_bar'),
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: trFor(lang, 'cancel'),
          onPressed: () => _update(_cancelAim),
          icon: const Icon(Icons.close, size: IconSize.s16),
        ),
        Expanded(
          child: GestureDetector(
            onTap: _releaseAim,
            child: SizedBox(
              height: 26,
              child: AnimatedBuilder(
                animation: _aim,
                builder: (context, _) => CustomPaint(
                  painter: _AimBarPainter(
                    position: _aim.value,
                    marker: theme.colorScheme.onSurface,
                    wide: ink.blood,
                    steady: ink.gold,
                    perfect: ink.heal,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        FilledButton(
          key: const Key('ship_aim_fire'),
          onPressed: _releaseAim,
          child: Text(trFor(lang, 'ship_aim_fire_button')),
        ),
      ],
    );
  }

  /// A small dark chip floating on the sea.
  Widget _seaChip(Widget child, {Key? key, Color? border}) => Container(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: border ?? Colors.white.withValues(alpha: 0.12)),
        ),
        child: child,
      );

  /// This round's weather and the next, in a chip in the sea's corner;
  /// a wreck adrift beside it. A squall building for the next round is
  /// called out in words (the weather keeps a trend since v1.190: it
  /// builds out of a crosswind).
  Widget _weatherChip(AppLanguage lang) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final small = theme.textTheme.labelSmall;
    final squallComing = _battle.nextWeather == SeaWeather.squall &&
        _battle.weather != SeaWeather.squall;
    return Tooltip(
      message: trFor(lang, 'ship_weather_${_battle.weather.name}_hint'),
      child: _seaChip(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_weatherIcon(_battle.weather),
              size: IconSize.s16, color: _weatherColor(ink, _battle.weather)),
          const SizedBox(width: 4),
          Text(trFor(lang, 'ship_weather_${_battle.weather.name}'),
              style: small?.copyWith(color: Colors.white)),
          const SizedBox(width: 6),
          if (squallComing)
            Tooltip(
              message: trFor(lang, 'ship_weather_squall_coming_hint'),
              child: Row(
                key: const Key('ship_squall_coming'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${trFor(lang, 'ship_weather_squall_coming')} ',
                      style: small?.copyWith(
                          color: ink.ember, fontWeight: FontWeight.bold)),
                  Icon(_weatherIcon(SeaWeather.squall),
                      size: IconSize.s16, color: ink.ember),
                ],
              ),
            )
          else ...[
            Text('${trFor(lang, 'ship_weather_next_label')} ',
                style: small?.copyWith(color: ink.ash)),
            Tooltip(
              message: trFor(lang, 'ship_weather_${_battle.nextWeather.name}'),
              child: Icon(_weatherIcon(_battle.nextWeather),
                  size: IconSize.s16, color: ink.ash),
            ),
          ],
          if (_battle.wreck) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: trFor(lang, 'ship_wreck_hint'),
              child: Icon(Icons.sailing_outlined,
                  size: IconSize.s16,
                  color: _roomColor(context, ShipRoom.hold)),
            ),
          ],
        ],
      )),
    );
  }

  /// Close in and pull away: two round buttons on the sea's right edge,
  /// up toward the enemy and down away from her.
  Widget _rangeButtons(AppLanguage lang) {
    final ink = InkColors.of(context);
    final range = _battle.range;
    final closer = range.index > 0 ? ShipRange.values[range.index - 1] : null;
    final farther = range.index < ShipRange.values.length - 1
        ? ShipRange.values[range.index + 1]
        : null;
    final canAct = !_busy && !_over;
    Widget button(Key key, IconData icon, String label, VoidCallback? onTap) {
      final on = onTap != null;
      return Tooltip(
        message: label,
        child: Material(
          color: Colors.black.withValues(alpha: 0.55),
          shape: CircleBorder(
              side: BorderSide(color: on ? ink.gold : ink.seam, width: 1.5)),
          child: InkWell(
            key: key,
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon,
                  size: IconSize.s32, color: on ? ink.gold : ink.ash),
            ),
          ),
        ),
      );
    }

    return Column(
      key: const Key('ship_range_bar'),
      mainAxisSize: MainAxisSize.min,
      children: [
        button(
          const Key('ship_close_in'),
          Icons.keyboard_double_arrow_up,
          trFor(lang, 'ship_close_in_button'),
          canAct && closer != null && _battle.canMoveTo(closer)
              ? () => _update(() {
                    _battle.maneuver(closer);
                    _rearm();
                  })
              : null,
        ),
        const SizedBox(height: 10),
        // At long range the Eel can run for it instead (see
        // ShipBattle.runForIt).
        if (farther == null && widget.canFlee)
          button(
            const Key('ship_run_button'),
            Icons.directions_boat_filled_outlined,
            '${trFor(lang, 'ship_run_button')}: '
            '${trFor(lang, 'ship_run_hint')} '
            '${trFor(lang, 'ship_run_left_hint').replaceAll('{n}', '${escapeNeeded - _battle.escape}')}',
            canAct && _battle.canRun
                ? () => _update(() {
                      _battle.runForIt();
                      _rearm();
                      if (_battle.over) _finish();
                    })
                : null,
          )
        else
          button(
            const Key('ship_pull_away'),
            Icons.keyboard_double_arrow_down,
            trFor(lang, 'ship_pull_away_button'),
            canAct && farther != null && _battle.canMoveTo(farther)
                ? () => _update(() {
                      _battle.maneuver(farther);
                      _rearm();
                    })
                : null,
          ),
      ],
    );
  }

  /// What the enemy is about to do and what is coming its way, in a line
  /// under its name: its intent (see [_intentChip]), a friend's sail on
  /// the horizon or its consort come up, and for a beast what it shows
  /// besides (see [_beastChips]).
  Widget _buildEnemyStatus(AppLanguage lang) {
    final b = _battle;
    final ink = InkColors.of(context);
    final chips = <Widget>[
      if (widget.rules.intents && !_over) _intentChip(lang),
      if (b.sailIn > 0)
        _statusChip(
          Icons.sailing,
          trFor(lang, 'ship_sail_coming_label')
              .replaceAll('{n}', '${b.sailIn}'),
          ink.ember,
          'ship_sail_coming',
          tooltip: trFor(lang, 'ship_sail_coming_hint')
              .replaceAll('{n}', '${b.sailIn}'),
        ),
      if (b.consortArrived)
        _statusChip(Icons.sailing, trFor(lang, 'ship_consort_label'), ink.blood,
            'ship_consort',
            tooltip: trFor(lang, 'ship_consort_hint')),
      if (widget.beast != null) ..._beastChips(lang),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Wrap(
        spacing: 10,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: chips,
      ),
    );
  }

  /// One small mark in the enemy's status line: an icon and a few words.
  Widget _statusChip(IconData icon, String text, Color color, String key,
      {String? tooltip}) {
    final small = Theme.of(context).textTheme.labelSmall;
    final chip = Row(
      key: Key(key),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: IconSize.s16, color: color),
        const SizedBox(width: 3),
        Flexible(
          child: Text(text,
              style: small?.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
    return tooltip == null ? chip : Tooltip(message: tooltip, child: chip);
  }

  /// What the enemy shows it will do in its next phase (see ShipIntent),
  /// picked out in a pill under its name: an icon, a few words, and on a
  /// hold what it means and how to answer it. The fog hides it. A beast's
  /// is worded for a beast where it has its own words.
  Widget _intentChip(AppLanguage lang) {
    final ink = InkColors.of(context);
    final small = Theme.of(context).textTheme.labelSmall;
    final seen = _battle.intentVisible;
    final intent = _battle.intent;
    String words(String key) {
      final beastKey = 'beast_$key';
      return trFor(
          lang,
          widget.beast != null && trFor(AppLanguage.en, beastKey) != beastKey
              ? beastKey
              : key);
    }

    final label = seen
        ? words('ship_intent_${intent.name}')
        : trFor(lang, 'ship_intent_hidden');
    final hint = seen
        ? words('ship_intent_${intent.name}_hint')
        : trFor(lang, 'ship_intent_hidden_hint');
    final color = seen ? _intentColor(ink, intent) : ink.ash;
    return Tooltip(
      message: hint,
      child: Container(
        key: const Key('ship_enemy_intent'),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(seen ? _intentIcon(intent) : Icons.question_mark,
                size: IconSize.inline, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: small?.copyWith(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// What the beast is about to do, in the status line under its name:
  /// held on the line, when it dives next, whether it is turning for the
  /// deep, what it heals a round, and the crew's edge against it.
  List<Widget> _beastChips(AppLanguage lang) {
    final beast = widget.beast!;
    final b = _battle;
    final ink = InkColors.of(context);
    // Held on the line, or its fins torn, it cannot dive.
    final dive = b.tethered || b.enemy.room(ShipRoom.helm).isDown
        ? null
        : b.roundsToDive;
    final heartDown = b.enemy.room(ShipRoom.hold).isDown;
    return [
      if (b.beastTurning)
        _statusChip(Icons.keyboard_double_arrow_down,
            trFor(lang, 'beast_status_turning'), ink.blood, 'beast_turning'),
      if (b.tethered)
        _statusChip(
            Icons.link,
            trFor(lang, 'beast_status_tethered')
                .replaceAll('{n}', '${b.tether}'),
            ink.gold,
            'beast_tethered'),
      if (dive != null)
        _statusChip(
            Icons.waves,
            dive == 0
                ? trFor(lang, 'beast_status_dives_now')
                : trFor(lang, 'beast_status_dives_in')
                    .replaceAll('{n}', '$dive'),
            dive == 0 ? ink.blood : ink.tide,
            'beast_dive'),
      if (beast.regen > 0)
        _statusChip(
            heartDown ? Icons.heart_broken : Icons.favorite,
            heartDown || b.tethered
                ? trFor(lang, 'beast_status_regen_stopped')
                : trFor(lang, 'beast_status_regen')
                    .replaceAll('{n}', '${beast.regen}'),
            heartDown || b.tethered ? ink.ash : ink.blood,
            'beast_regen'),
      if (beast.edge > 0)
        _statusChip(
            Icons.visibility,
            trFor(lang, 'beast_status_edge').replaceAll('{n}', '${beast.edge}'),
            ink.tide,
            'beast_edge'),
    ];
  }

  /// The sums of the enemy's shield: its layers and how many shots of the
  /// armed weapon it takes to get one through (fewer aimed at the
  /// bulwark), and a flag when the guns ready now can do it this turn.
  Widget _buildShieldSums(AppLanguage lang) {
    final b = _battle;
    final layers = b.enemy.layers;
    final weapon = b.weaponById(_armedWeaponId);
    if (!b.shieldBreakOn || _over || layers == 0 || weapon == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final style = theme.textTheme.labelSmall;
    final plain = b.shotsToLand(weapon.id, ShipRoom.guns) ?? 1;
    final aimed = b.shotsToLand(weapon.id, ShipRoom.bulwark) ?? plain;
    var text = weapon.piercing
        ? trFor(lang, 'ship_sums_pierce').replaceAll('{n}', '$layers')
        : trFor(lang, layers == 1 ? 'ship_sums_one' : 'ship_sums')
            .replaceAll('{n}', '$layers')
            .replaceAll('{m}', '$plain');
    if (!weapon.piercing && aimed < plain) {
      text += trFor(lang, 'ship_sums_bulwark').replaceAll('{k}', '$aimed');
    }
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Flexible(
            child: Text(text,
                key: const Key('ship_shield_sums'),
                style: style?.copyWith(
                    color: _roomColor(context, ShipRoom.bulwark)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          if (b.salvoReady) ...[
            const SizedBox(width: 8),
            Icon(Icons.bolt, size: IconSize.inline, color: ink.gold),
            Flexible(
              child: Text(trFor(lang, 'ship_sums_salvo'),
                  key: const Key('ship_salvo_ready'),
                  style: style?.copyWith(
                      color: ink.gold, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ],
      ),
    );
  }

  /// A ship on one line and a bar: her name, the enemy's habit, her
  /// shields and how often she slips a shot, then her hull as planks.
  Widget _shipBar({
    required String name,
    required ShipState ship,
    required int evasion,
    required Color color,
    EnemyHabit habit = EnemyHabit.none,
    bool eel = false,
  }) {
    final pop = _hullPops[eel];
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    final ratio = ship.maxHull == 0 ? 0.0 : ship.hull / ship.maxHull;
    final showHabit = widget.rules.habits && habit != EnemyHabit.none;
    final steel = _roomColor(context, ShipRoom.bulwark);
    final small = theme.textTheme.labelSmall;
    final heavy = _battle.heavyEvasion(ship);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(name,
                  style: TextStyle(
                      fontFamily: InkFonts.display, fontSize: 18, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (showHabit) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Tooltip(
                  message: trFor(lang, 'ship_habit_${habit.name}_hint'),
                  child: Container(
                    key: const Key('ship_enemy_habit'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ink.ember),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_habitIcon(habit),
                            size: IconSize.inline, color: ink.ember),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            trFor(lang, 'ship_habit_${habit.name}'),
                            style: small?.copyWith(color: ink.ember),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const Spacer(),
            for (var i = 0; i < max(ship.maxLayers, ship.layers); i++)
              Icon(
                i < ship.layers ? Icons.shield : Icons.shield_outlined,
                size: IconSize.s16,
                color: steel,
              ),
            const SizedBox(width: 6),
            // Heavy with water: each open leak costs evasion (v1.190).
            if (heavy > 0) ...[
              Icon(Icons.water_drop,
                  key: Key('ship_heavy_${eel ? 'eel' : 'enemy'}'),
                  size: IconSize.inline,
                  color: ink.blood),
              Text(
                trFor(lang, 'ship_heavy_label').replaceAll('{n}', '$heavy'),
                style: small?.copyWith(color: ink.blood),
              ),
              const SizedBox(width: 4),
            ],
            Tooltip(
              message: heavy > 0
                  ? '${trFor(lang, 'ship_evasion_hint')}\n'
                      '${trFor(lang, 'ship_heavy_hint').replaceAll('{n}', '$heavy')}'
                  : trFor(lang, 'ship_evasion_hint'),
              child: Text(
                trFor(lang, 'ship_slips_label').replaceAll('{n}', '$evasion'),
                style: small?.copyWith(color: ink.tide),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 7,
                child: CustomPaint(
                  painter: _PlankBarPainter(
                    ratio: ratio.clamp(0.0, 1.0),
                    color: ratio > 0.5
                        ? color
                        : ratio > 0.25
                            ? ink.ember
                            : ink.blood,
                    empty: ink.seam,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Text('${ship.hull}/${ship.maxHull}',
                    style: small?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()])),
                // The hull a shot just took, rising off the count.
                if (pop != null)
                  Positioned(
                    right: 0,
                    top: -18,
                    child: _Flash(
                      key: ValueKey('hull_${pop.$2}'),
                      text: '−${pop.$1}',
                      color: eel ? ink.blood : ink.gold,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
