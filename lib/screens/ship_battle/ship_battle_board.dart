part of '../ship_battle_panel.dart';

/// The sea: the two hulls, the battlefield, the room tiles and the crew
/// tokens. Cut out of ship_battle_panel.dart with no change (setState is
/// called as _update).
extension _ShipBattleBoard on _ShipBattlePanelState {
  /// The two hulls in side view above the sea (see [SeaDuelScene]): the
  /// Eel as she is dressed and as battered as she is, the enemy as hers is.
  Widget _buildDuelStrip() {
    final weather = widget.rules.weather ? _battle.weather : SeaWeather.calm;
    final player = _battle.player;
    final enemy = _battle.enemy;
    return SizedBox(
      key: const Key('ship_duel_strip'),
      height: 96,
      child: SeaDuelScene(
        waters: widget.waters,
        weather: weather,
        ship: ref.watch(shipFormProvider),
        dress: ref.watch(shipDressProvider),
        condition: player.maxHull <= 0
            ? 1.0
            : (player.hull / player.maxHull).clamp(0.0, 1.0),
        enemyId: widget.enemyShipId,
        enemyCondition: enemy.maxHull <= 0
            ? 1.0
            : (enemy.hull / enemy.maxHull).clamp(0.0, 1.0),
        enemyIsBeast: widget.beast != null,
        range: switch (_battle.range) {
          ShipRange.close => 0.0,
          ShipRange.medium => 0.5,
          ShipRange.long => 1.0,
        },
      ),
    );
  }

  /// The fight from the masthead (see sea_battlefield.dart), filling the
  /// screen between the enemy's bar and the dock: the enemy above, the
  /// Eel below, broadside to broadside, the gap between them the range
  /// they lie at; the waters' own waves under them and the weather
  /// drifting over them. Each ship's rooms lie along her deck, helm at
  /// the stern to bulwark at the bow, and each is the tile that is
  /// tapped. On the water: the weather, the enemy's guns, the range with
  /// the helm's maneuvers and the last of the log (a tip shows above the
  /// dock, see build).
  Widget _buildBattlefield(AppLanguage lang) {
    final weather = widget.rules.weather ? _battle.weather : SeaWeather.calm;
    if (_shownWeather != null && _shownWeather != weather) {
      // The weather turns: a wave rolls under both ships as it does.
      _fadingWeather = _shownWeather;
      _weatherTurnedAt = _seaClock.value * _seaSeconds;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fx.play(ShipFxKind.wave, _seaKey);
      });
    }
    _shownWeather = weather;
    final eelLook = ref.watch(playerShipLookProvider);
    final enemyLook = TopShipLook.forEnemy(widget.enemyShipId, widget.enemy);
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      const label = 14.0;
      const top = 40.0;
      const bottom = 50.0;
      // The ships fit the sea's height as well as its width, with the
      // closest range at full size and nearly no water between them; at
      // each longer range they are drawn smaller (see [seaZoomFor]) and the
      // water between them opens, so being close or far reads at a glance.
      final byHeight = max(0.0, height - top - bottom - 2 * label) *
          0.9 /
          (topShipBoxHeight(1, enemyLook) + topShipBoxHeight(1, eelLook));
      final full = min(min(width * 0.72, 290.0), byHeight);
      final length = full * seaZoomFor(_battle.range);
      final left = (width - length) / 2;
      final enemyBox = topShipBoxHeight(length, enemyLook);
      final eelBox = topShipBoxHeight(length, eelLook);
      final spare =
          max(0.0, height - top - bottom - enemyBox - eelBox - 2 * label);
      // The range is how much of the open water lies between them; the
      // rest is split above and below.
      final gap = spare *
          switch (_battle.range) {
            ShipRange.close => 0.03,
            ShipRange.medium => 0.5,
            ShipRange.long => 1.0,
          };
      final slack = (spare - gap) / 2;
      final enemyTop = top + label + slack;
      final eelTop = enemyTop + enemyBox + gap;
      final enemyBand = Rect.fromLTWH(0, enemyTop, width, enemyBox);
      final middle = eelTop - gap / 2;
      const move = Duration(milliseconds: 700);
      return AnimatedBuilder(
        animation: _seaClock,
        builder: (context, _) {
          final t = _seaClock.value * _seaSeconds;
          return Stack(
            key: const Key('ship_sea_strip'),
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  key: const Key('ship_battlefield'),
                  painter: SeaSurfacePainter(
                      waters: widget.waters, weather: weather, t: t),
                ),
              ),
              // The water between the ships, where the sea's own
              // surprises break.
              AnimatedPositioned(
                duration: move,
                curve: Curves.easeInOut,
                left: 0,
                right: 0,
                top: enemyTop + enemyBox * 0.7,
                height: max(8, gap + enemyBox * 0.6),
                child:
                    KeyedSubtree(key: _seaKey, child: const SizedBox.expand()),
              ),
              if (widget.rules.range)
                AnimatedPositioned(
                  duration: move,
                  curve: Curves.easeInOut,
                  left: 6,
                  top: enemyTop + enemyBox / 2,
                  width: 18,
                  height:
                      max(20, eelTop + eelBox / 2 - (enemyTop + enemyBox / 2)),
                  child: _rangeBracket(lang),
                ),
              AnimatedPositioned(
                duration: move,
                curve: Curves.easeInOut,
                left: left,
                top: enemyTop - label,
                width: length,
                height: label,
                child: _roomLabelRow(look: enemyLook, flip: true),
              ),
              AnimatedPositioned(
                duration: move,
                curve: Curves.easeInOut,
                left: left,
                top: enemyTop,
                width: length,
                height: enemyBox,
                child: _topShip(
                    ship: _battle.enemy,
                    isPlayer: false,
                    look: enemyLook,
                    t: t),
              ),
              AnimatedPositioned(
                duration: move,
                curve: Curves.easeInOut,
                left: left,
                top: eelTop,
                width: length,
                height: eelBox,
                child: _topShip(
                    ship: _battle.player, isPlayer: true, look: eelLook, t: t),
              ),
              AnimatedPositioned(
                duration: move,
                curve: Curves.easeInOut,
                left: left,
                top: eelTop + eelBox,
                width: length,
                height: label,
                child: _roomLabelRow(look: eelLook, flip: false),
              ),
              for (final (w, opacity) in _weatherLayers(weather, t))
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: opacity,
                      child: CustomPaint(
                        painter: SeaWeatherPainter(
                          waters: widget.waters,
                          weather: w,
                          t: t,
                          enemyBand: enemyBand,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 8,
                right: 8,
                top: 8,
                child: Row(
                  children: [
                    if (widget.rules.weather) _weatherChip(lang),
                    const Spacer(),
                    Flexible(flex: 3, child: _buildEnemyWeapons()),
                  ],
                ),
              ),
              if (widget.rules.range)
                AnimatedPositioned(
                  duration: move,
                  curve: Curves.easeInOut,
                  right: 8,
                  top: max(top, middle - 47),
                  child: _rangeButtons(lang),
                ),
              if (_battle.crew.isNotEmpty)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: _buildCrewSkills(lang),
                ),
            ],
          );
        },
      );
    });
  }

  /// The weather to draw over the sea and how strongly: the current one,
  /// and while it turns, the last one fading out.
  List<(SeaWeather, double)> _weatherLayers(SeaWeather weather, double t) {
    final since = t - _weatherTurnedAt;
    final fading = _fadingWeather;
    // A still sea, a clock gone round or the fade done: the weather alone.
    if (fading == null ||
        !_seaClock.isAnimating ||
        since < 0 ||
        since >= _weatherFade) {
      return [(weather, 1)];
    }
    final k = since / _weatherFade;
    return [(fading, 1 - k), (weather, k)];
  }

  /// The range as a bracket down the left edge of the sea: from ship to
  /// ship, with its name.
  Widget _rangeBracket(AppLanguage lang) {
    final ink = InkColors.of(context);
    final theme = Theme.of(context);
    return Tooltip(
      message: trFor(lang, 'ship_range_${_battle.range.name}_hint'),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
                painter:
                    _BracketPainter(color: ink.gold.withValues(alpha: 0.8))),
          ),
          Center(
            child: RotatedBox(
              quarterTurns: 3,
              // Far off, or with a run under way, the turns of running
              // still needed to get away.
              child: Text(
                widget.canFlee &&
                        !_over &&
                        (_battle.range == ShipRange.long || _battle.escape > 0)
                    ? '${trFor(lang, 'ship_range_${_battle.range.name}_title')} · '
                        '${trFor(lang, 'ship_escape_label').replaceAll('{n}', '${escapeNeeded - _battle.escape}')}'
                    : trFor(lang, 'ship_range_${_battle.range.name}_title'),
                key: const Key('ship_range_label'),
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: ink.gold,
                    fontSize: 10,
                    shadows: const [Shadow(blurRadius: 3)]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The rooms' names in a row along a ship's far side, each over its own
  /// room, in its colour.
  Widget _roomLabelRow({required TopShipLook look, required bool flip}) {
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    return IgnorePointer(
      child: LayoutBuilder(builder: (context, c) {
        final box = Size(c.maxWidth, topShipBoxHeight(c.maxWidth, look));
        return Stack(children: [
          for (final room in ShipRoom.values)
            Positioned(
              left: topShipRoomRect(room, box, look, flip: flip).left,
              width: topShipRoomRect(room, box, look, flip: flip).width,
              top: 0,
              bottom: 0,
              child: Center(
                child: Text(
                  _roomName(lang, room, enemy: flip, suffix: '_title')
                      .toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9.5,
                    letterSpacing: 0.8,
                    color: _roomColor(context, room),
                    shadows: const [Shadow(blurRadius: 3)],
                  ),
                ),
              ),
            ),
        ]);
      }),
    );
  }

  /// One ship from above with her rooms as tiles on her deck. The enemy
  /// is mirrored, her bow to the left, so the two pass broadside to
  /// broadside; a ship below half her hull is battered.
  Widget _topShip({
    required ShipState ship,
    required bool isPlayer,
    required TopShipLook look,
    required double t,
  }) {
    final flip = !isPlayer;
    final sinking = _sinkingEel == isPlayer;
    final evasion = isPlayer ? _battle.playerEvasion : _battle.enemyEvasion;
    final bob = sin(t * 1.3 + (isPlayer ? 0 : 2)) * 1.5;
    return AnimatedBuilder(
      animation: _sink,
      builder: (context, child) {
        if (!sinking) return child!;
        final k = Curves.easeIn.transform(_sink.value);
        return Opacity(
          opacity: (1 - k * 0.85).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 1 - 0.25 * k,
            child: Transform.rotate(angle: 0.3 * k, child: child),
          ),
        );
      },
      child: Transform.translate(
        offset: Offset(0, bob),
        child: KeyedSubtree(
          key: _hullKeys[isPlayer],
          child: LayoutBuilder(builder: (context, c) {
            final box = Size(c.maxWidth, c.maxHeight);
            return SizedBox(
              key: Key('ship_hull_${isPlayer ? 'eel' : 'enemy'}'),
              width: box.width,
              height: box.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      key: Key('ship_sprite_${isPlayer ? 'eel' : 'enemy'}'),
                      painter: TopShipPainter(
                        look: look,
                        flip: flip,
                        facingDown: !isPlayer,
                        t: t,
                        layers: ship.layers,
                        maxLayers: ship.maxLayers,
                        battered: ship.hull * 2 < ship.maxHull,
                        down: {
                          for (final r in ShipRoom.values)
                            if (ship.room(r).isDown) r
                        },
                        burning: {
                          for (final r in ShipRoom.values)
                            if (ship.room(r).onFire) r
                        },
                        water: min(ship.leaks, 3) / 3,
                        shield: _roomColor(context, ShipRoom.bulwark),
                        foam: Palette.cyan93,
                        roomColors: {
                          for (final r in ShipRoom.values)
                            r: _roomColor(context, r)
                        },
                        refit: isPlayer ? ShipCutaway.refitOf(ship) : 0,
                        dress: isPlayer ? ref.read(shipDressProvider) : null,
                        speed: (evasion / 22).clamp(0.0, 2.0),
                      ),
                    ),
                  ),
                  for (final room in ShipRoom.values)
                    Positioned.fromRect(
                      rect: topShipRoomRect(room, box, look, flip: flip)
                          .deflate(1.5),
                      child: KeyedSubtree(
                        key: _roomKeys[(isPlayer, room)],
                        child: _buildRoomTile(
                          ship: ship,
                          room: room,
                          isPlayer: isPlayer,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRoomTile({
    required ShipState ship,
    required ShipRoom room,
    required bool isPlayer,
  }) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    final state = ship.room(room);
    final color = _roomColor(context, room);
    final crew = isPlayer ? _battle.crewById(_battle.stations[room]) : null;
    final armed = _battle.weaponById(_armedWeaponId);
    final canFireHere = !isPlayer &&
        armed != null &&
        _battle.canFire(armed) &&
        !_busy &&
        !_over;
    final canStationHere = isPlayer && _selectedCrewId != null && !_busy;
    final aiming = !isPlayer && _aimRoom == room;
    final incoming = <ShipWeapon>[
      if (isPlayer && widget.foresight && _battle.aimVisible)
        for (final w in _battle.enemy.weapons)
          if (readyNextTurn(w, _battle.enemy) && _battle.plan[w.id] == room) w,
    ];
    final preview = canFireHere ? _battle.preview(_armedWeaponId, room) : null;
    final focused = !isPlayer && (_battle.focus[room] ?? 0) > 0;
    final leaks = room == ShipRoom.hold ? ship.leaks : 0;
    final railOpen = room == ShipRoom.bulwark && bulwarkOpen(ship);
    final flash = _flashes[(isPlayer, room)];
    const pipSize = 6.0;
    final label = theme.textTheme.labelSmall;

    final Color border;
    final double borderWidth;
    if (aiming || canFireHere) {
      border = ink.gold;
      borderWidth = aiming ? 3 : 2;
    } else if (canStationHere) {
      border = ink.tide;
      borderWidth = 2;
    } else if (incoming.isNotEmpty) {
      border = ink.blood;
      borderWidth = 2;
    } else {
      border = Colors.transparent;
      borderWidth = 1;
    }
    // The room itself is drawn on the ship (see _topShip): the tile is
    // only a frame over it, tinted when it can be fired at.
    final background = canFireHere
        ? ink.gold.withValues(alpha: aiming ? 0.22 : 0.10)
        : Colors.transparent;

    final status = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.level == 0)
            Text('—', style: label)
          else
            for (var i = 0; i < state.level; i++)
              Container(
                width: pipSize,
                height: pipSize,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: i < state.working ? color : null,
                  border: i < state.working
                      ? null
                      : Border.all(color: ink.blood, width: 1.5),
                ),
              ),
          if (state.isDown) ...[
            const SizedBox(width: 2),
            Text(trFor(lang, 'ship_room_out_label'),
                style: label?.copyWith(color: ink.blood)),
          ],
          if (state.onFire) ...[
            const SizedBox(width: 2),
            Icon(Icons.local_fire_department,
                size: IconSize.s16, color: ink.ember),
          ],
          for (var i = 0; i < leaks; i++)
            Icon(Icons.water_drop,
                key: Key('ship_leak_$i'), size: IconSize.s16, color: ink.tide),
          for (final w in incoming) ...[
            const SizedBox(width: 2),
            Icon(Icons.warning_amber_rounded,
                size: IconSize.s16, color: ink.blood),
            Text('${w.damage}', style: label?.copyWith(color: ink.blood)),
          ],
          if (railOpen) ...[
            const SizedBox(width: 2),
            Icon(Icons.door_front_door_outlined,
                size: IconSize.s16, color: ink.ember),
          ],
          if (preview != null) ...[
            const SizedBox(width: 4),
            _buildShotPreview(preview),
          ],
        ],
      ),
    );
    final stationRoll =
        crew == null || !isPlayer ? null : _battle.stationRoll(crew.id);
    final die = stationRoll == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(left: 4),
            child: StationDie(
              die: _battle.crewDice[crew!.id]!,
              roll: stationRoll,
              turn: _battle.turn,
              accent: ink.tide,
              skin: dieSkinOf(_equippedDieOf(crew)),
              size: 24,
              still: MediaQuery.of(context).disableAnimations,
            ),
          );
    final token = crew == null
        ? null
        : isPlayer && !_busy && !_over
            ? _draggableToken(crew, size: 15)
            : _crewToken(crew, size: 15);
    // Labels sit on small dark chips so the room's art shows around them:
    // the name at the top, the pips and marks along the bottom.
    Widget chip(Widget child) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(3),
          ),
          child: child,
        );
    // The name is written by the ship (see _roomLabelRow) and the room's
    // state painted on its deck: the tile adds who mans it at the top and
    // its pips and marks at the bottom. Each has half a tile at most: on a
    // short one (the bow's bulwark on a phone's small sea) they shrink
    // rather than spill.
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (token != null || focused)
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (token != null) token,
                  if (die != null) die,
                  if (focused)
                    Tooltip(
                      message: trFor(lang, 'ship_focus_hint'),
                      child: Icon(Icons.center_focus_strong,
                          size: IconSize.s16, color: ink.ember),
                    ),
                ],
              ),
            ),
          ),
        Flexible(
          child: Align(
            alignment: Alignment.bottomRight,
            child: FittedBox(fit: BoxFit.scaleDown, child: chip(status)),
          ),
        ),
      ],
    );
    final tile = Tooltip(
      message: railOpen
          ? trFor(lang, 'ship_room_bulwark_open_hint')
          : [
              _roomName(lang, room, enemy: !isPlayer, suffix: '_hint'),
              if (stationRoll != null) _stationRollHint(lang, stationRoll),
            ].join('\n'),
      child: GestureDetector(
        key: Key('ship_room_${isPlayer ? 'eel' : 'enemy'}_${room.name}'),
        onTap: () {
          if (canFireHere) {
            _fire(room);
          } else if (canStationHere) {
            _station(room);
          } else if (isPlayer && crew != null && !_busy) {
            _update(() => _selectedCrewId = crew.id);
          }
        },
        onLongPress:
            canFireHere && ref.watch(aimedShotsProvider) != AimedShots.off
                ? () => _startAim(room)
                : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border, width: borderWidth),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: content),
              if (flash != null)
                Positioned(
                  left: -30,
                  right: -30,
                  top: -26,
                  child: Center(
                    child: _Flash(
                      key: ValueKey(flash.$2),
                      text: flash.$1,
                      color: isPlayer ? ink.blood : ink.gold,
                      // A hit's number, big; a slip or a block, smaller.
                      size: flash.$1.startsWith('−') ? 24 : 15,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (!isPlayer) return tile;
    // A hand can be dragged onto any room of the Eel.
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => !_busy && !_over,
      onAcceptWithDetails: (d) => _dropCrew(d.data, room),
      builder: (context, candidates, _) => candidates.isEmpty
          ? tile
          : DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ink.tide, width: 2),
                color: ink.tide.withValues(alpha: 0.18),
              ),
              child: tile,
            ),
    );
  }

  /// A hand's token that can be dragged to another room; a tap picks
  /// them, as before.
  Widget _draggableToken(ShipCrew crew, {required double size}) {
    return Draggable<String>(
      data: crew.id,
      feedback: Material(
          type: MaterialType.transparency,
          child: _crewToken(crew, size: size * 2.2)),
      childWhenDragging:
          Opacity(opacity: 0.3, child: _crewToken(crew, size: size)),
      child: _crewToken(crew, size: size),
    );
  }
}
