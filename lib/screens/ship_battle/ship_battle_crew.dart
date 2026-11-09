part of '../ship_battle_panel.dart';

/// The crew: their orders, the placement, the weapons, the sheets and the
/// log. Cut out of ship_battle_panel.dart with no change (setState is called
/// as _update).
extension _ShipBattleCrew on _ShipBattlePanelState {
  /// The crew's orders on the sea, one chip each: the hand, what they can
  /// do and from where. A tap gives it (sending them to its room first if
  /// they stand elsewhere); a spent order is ticked; the token drags to a
  /// room.
  Widget _buildCrewSkills(AppLanguage lang) {
    final enemies = ref.read(localizedDbProvider(enemiesSchema)).value;
    // Each hand's die keeps its place, spent or not.
    final crew = [
      for (final c in _battle.crew)
        if (orderFor(c) != null) c
    ];
    final chips = [
      for (final c in crew) _skillChip(lang, c, orderFor(c)!, enemies),
    ];
    return SingleChildScrollView(
      key: const Key('ship_crew_skills'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final chip in chips)
            Padding(padding: const EdgeInsets.only(right: 8), child: chip),
        ],
      ),
    );
  }

  /// One hand's order as a die, as the dice fight rolls its faces: a tap
  /// gives it (the die spins, the hand goes to its room first if they
  /// stand elsewhere); a hold tells what it does and from where. The
  /// hand's initial sits in its corner, an arrow when giving it moves them.
  Widget _skillChip(AppLanguage lang, ShipCrew member, CrewOrder order,
      Map<String, dynamic>? enemies) {
    final ink = InkColors.of(context);
    final spent = _battle.ordersUsed.contains(member.id);
    final usable = _orderUsable(member, enemies);
    final fits = _battle.orderFitsStation(member);
    final color = spent
        ? ink.ash
        : usable
            ? (fits ? ink.gold : ink.tide)
            : ink.ash;
    const side = 42.0;
    return Semantics(
      button: true,
      label: '${trFor(lang, 'ship_order_${order.name}')} · ${member.name}',
      child: InkWell(
        key: Key('ship_order_${order.name}'),
        borderRadius: BorderRadius.circular(10),
        onTap: usable ? () => _useOrder(member) : null,
        onLongPress: () => _showOrderSheet(lang, member, order),
        child: AnimatedRotation(
          turns: (_orderSpins[member.id] ?? 0).toDouble(),
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOutBack,
          child: Opacity(
            opacity: usable || spent ? 1 : 0.55,
            child: Container(
              width: side,
              height: side,
              decoration: BoxDecoration(
                color: spent
                    ? Colors.black.withValues(alpha: 0.55)
                    : Color.alphaBlend(color.withValues(alpha: 0.18),
                        Colors.black.withValues(alpha: 0.7)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color, width: usable ? 2 : 1),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black54,
                      blurRadius: 3,
                      offset: Offset(1, 2)),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(spent ? Icons.check : _orderIcon(order),
                        size: 20, color: spent ? ink.ash : color),
                  ),
                  Positioned(
                    left: 3,
                    top: 2,
                    child: Text(
                      member.name.characters.first,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: spent ? ink.ash : Colors.white70),
                    ),
                  ),
                  if (usable && !fits)
                    Positioned(
                      right: 2,
                      bottom: 1,
                      child:
                          Icon(Icons.directions_walk, size: 10, color: color),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A hold on an order die: what the order does, who gives it and from
  /// which rooms, and where they stand now.
  Future<void> _showOrderSheet(
      AppLanguage lang, ShipCrew member, CrewOrder order) {
    final ink = InkColors.of(context);
    final spent = _battle.ordersUsed.contains(member.id);
    final here = _battle.stationOf(member.id);
    final rooms = !widget.rules.orderStations || order == CrewOrder.allHands
        ? trFor(lang, 'ship_order_anywhere')
        : orderRooms[order]!
            .map((r) => _roomName(lang, r, enemy: false, suffix: '_title'))
            .join(' / ');
    final room = _battle.orderRoomFor(member);
    final where = spent
        ? trFor(lang, 'ship_order_spent')
        : _battle.orderFitsStation(member) || room == null
            ? null
            : trFor(lang, 'ship_order_go')
                .replaceAll('{room}', _roomName(lang, room, enemy: false));
    return showInkSheet<void>(
      context: context,
      scrollControlled: false,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            key: const Key('ship_order_sheet'),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_orderIcon(order), color: ink.gold, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(trFor(lang, 'ship_order_${order.name}'),
                          style: const TextStyle(
                              fontFamily: InkFonts.display, fontSize: 20)),
                    ),
                    _crewToken(member, size: 22),
                    const SizedBox(width: 6),
                    Text(member.isPlayer
                        ? trFor(lang, 'you_label')
                        : member.name),
                  ],
                ),
                const SizedBox(height: 8),
                Text(trFor(lang, 'ship_order_${order.name}_hint'),
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  '${trFor(lang, 'ship_order_from_label')} $rooms'
                  '${here == null ? '' : ' · ${trFor(lang, 'ship_order_now_label')} ${_roomName(lang, here, enemy: false, suffix: '_title')}'}',
                  style: theme.textTheme.labelMedium?.copyWith(color: ink.ash),
                ),
                if (where != null) ...[
                  const SizedBox(height: 4),
                  Text(
                      '${member.isPlayer ? trFor(lang, 'you_label') : member.name} $where',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: spent ? ink.ash : ink.tide)),
                ],
                const SizedBox(height: 6),
                Text(trFor(lang, 'ship_order_once_label'),
                    style:
                        theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Before the first round: the Eel from above and her crew, each hand
  /// dragged (or tapped, then a room tapped) to a station; what each room
  /// does and which orders are given from it; then the fight begins.
  Widget _buildPlacement(AppLanguage lang, Map<String, dynamic>? enemies) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final look = ref.watch(playerShipLookProvider);
    return ColoredBox(
      key: const Key('ship_placement'),
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                Text(trFor(lang, 'ship_place_title'),
                    style: const TextStyle(
                        fontFamily: InkFonts.display, fontSize: 24)),
                const SizedBox(height: 2),
                Text(
                  tidyShipLine(
                      trFor(lang, 'ship_place_intro')
                          .replaceAll('{ship}', widget.enemyName),
                      lang),
                  style: theme.textTheme.bodySmall?.copyWith(color: ink.ash),
                ),
                const SizedBox(height: 10),
                // The Eel, large: each room a drop target.
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 190,
                    child: LayoutBuilder(builder: (context, c) {
                      final length = min(c.maxWidth - 24, 340.0);
                      final box = topShipBoxHeight(length, look);
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: SeaSurfacePainter(
                                  waters: widget.waters,
                                  weather: SeaWeather.calm,
                                  t: 0),
                            ),
                          ),
                          Positioned(
                            left: (c.maxWidth - length) / 2,
                            top: (190 - box) / 2 - 8,
                            width: length,
                            height: box,
                            child: _topShip(
                                ship: _battle.player,
                                isPlayer: true,
                                look: look,
                                t: 0),
                          ),
                          Positioned(
                            left: (c.maxWidth - length) / 2,
                            top: (190 - box) / 2 - 8 + box,
                            width: length,
                            height: 16,
                            child: _roomLabelRow(look: look, flip: false),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 10),
                Text(trFor(lang, 'ship_place_hint'),
                    style:
                        theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
                const SizedBox(height: 8),
                for (final c in _battle.crew) _placeRow(lang, c),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border(top: BorderSide(color: ink.seam)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      IconButton.outlined(
                        key: const Key('ship_place_auto'),
                        tooltip: trFor(lang, 'ship_auto_station_button'),
                        onPressed: () => _update(() {
                          _battle.autoStation();
                          _selectedCrewId = null;
                        }),
                        icon: const Icon(Icons.auto_fix_high, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: OutlinedButton.icon(
                          key: const Key('ship_place_skills'),
                          onPressed: () => _update(() {
                            for (final c in _battle.crew) {
                              final room = _battle.orderRoomFor(c);
                              if (room != null && !c.isPlayer) {
                                _battle.station(c.id, room);
                              }
                            }
                            _selectedCrewId = null;
                          }),
                          icon: const Icon(Icons.bolt, size: 16),
                          label: Text(trFor(lang, 'ship_place_skills'),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: const Key('ship_start_battle'),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 18)),
                  onPressed: _startBattle,
                  icon: const Icon(Icons.sailing, size: 18),
                  label: Text(trFor(lang, 'ship_place_start')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One hand in the placement list: their token (drag it to a room), the
  /// room they hold, their order and the rooms it is given from; a tap
  /// picks them, then a tap on a room places them.
  Widget _placeRow(AppLanguage lang, ShipCrew c) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final order = orderFor(c);
    final here = _battle.stationOf(c.id);
    final picked = _selectedCrewId == c.id;
    final fits = _battle.orderFitsStation(c);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: picked
            ? ink.gold.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: picked ? ink.gold : ink.seam),
        ),
        child: InkWell(
          key: Key('ship_place_${c.id}'),
          borderRadius: BorderRadius.circular(10),
          onTap: () => _update(() => _selectedCrewId = picked ? null : c.id),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _draggableToken(c, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          c.isPlayer
                              ? '${c.name} (${trFor(lang, 'you_label')})'
                              : c.name,
                          style: theme.textTheme.titleSmall),
                      if (order != null)
                        Text(
                          '${trFor(lang, 'ship_order_${order.name}')} · '
                          '${!widget.rules.orderStations || order == CrewOrder.allHands ? trFor(lang, 'ship_order_anywhere') : orderRooms[order]!.map((r) => _roomName(lang, r, enemy: false, suffix: '_title')).join(' / ')}',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: fits ? ink.gold : ink.ash),
                        ),
                    ],
                  ),
                ),
                if (here != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _roomColor(context, here)),
                    ),
                    child: Text(
                        _roomName(lang, here, enemy: false, suffix: '_title'),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: _roomColor(context, here))),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A crew member's round token: their initial, gold when picked to be
  /// moved.
  Widget _crewToken(ShipCrew crew, {required double size}) {
    final ink = InkColors.of(context);
    final picked = _selectedCrewId == crew.id;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (picked ? ink.gold : ink.tide).withValues(alpha: 0.18),
        border: Border.all(color: picked ? ink.gold : ink.tide, width: 1.5),
      ),
      child: Text(
        crew.name.isEmpty ? '?' : crew.name[0].toUpperCase(),
        style: TextStyle(
            fontFamily: InkFonts.system,
            fontSize: size * 0.48,
            color: picked ? ink.gold : ink.tide),
      ),
    );
  }

  /// What the armed weapon would do to this room if it lands: the shield
  /// that would stop it, or the hull and pips it would cost, KO when the
  /// room would go down, a flame when it would burn, a drop for a leak.
  Widget _buildShotPreview(ShotOutcome preview) {
    final theme = Theme.of(context);
    final lang = ref.watch(appLanguageProvider);
    final style = theme.textTheme.labelSmall
        ?.copyWith(fontWeight: FontWeight.bold, color: _previewColor);
    if (preview.absorbed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield, size: 13, color: _previewColor),
          Text(preview.hullDamage > 0 ? '−${preview.hullDamage}' : '0',
              style: style),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('−${preview.hullDamage}', style: style),
        if (preview.roomDamage > 0) ...[
          const SizedBox(width: 3),
          const Icon(Icons.grid_view, size: 11, color: _previewColor),
          Text('−${preview.roomDamage}', style: style),
        ],
        if (preview.roomKnockedOut) ...[
          const SizedBox(width: 3),
          Text(trFor(lang, 'preview_lethal_label'), style: style),
        ],
        if (preview.fireStarted) ...[
          const SizedBox(width: 2),
          const Icon(Icons.local_fire_department,
              size: 13, color: _previewColor),
        ],
        if (preview.leakOpened) ...[
          const SizedBox(width: 2),
          const Icon(Icons.water_drop, size: 13, color: _previewColor),
        ],
      ],
    );
  }

  /// The enemy's guns in the sea's corner: each its charge as a ring and
  /// its damage, and the Eel's room it means to hit when a foresight sail
  /// shows it.
  Widget _buildEnemyWeapons() {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    final fr = lang == AppLanguage.fr;
    final enemy = _battle.enemy;
    final small = theme.textTheme.labelSmall;
    Widget chip(ShipWeapon w) {
      final aimAt =
          widget.foresight && _battle.aimVisible && readyNextTurn(w, enemy)
              ? _battle.plan[w.id]
              : null;
      final note = !_battle.inRange(w)
          ? trFor(lang, 'ship_out_of_range_label')
          : aimAt != null
              ? trFor(lang, 'ship_room_${aimAt.name}_title')
              : w.isReady
                  ? trFor(lang, 'ship_weapon_ready_label')
                  : '${w.charge}/${w.chargeTurns}';
      return Tooltip(
        message: '${w.nameFor(fr)} · ${w.damage} · $note',
        child: _seaChip(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ChargeRing(
                value: w.chargeTurns <= 0 ? 1 : w.charge / w.chargeTurns,
                color: _battle.inRange(w) ? ink.blood : ink.ash,
                track: ink.seam,
                size: 18,
                child: Icon(_weaponIcon(w), size: 9, color: ink.blood),
              ),
              const SizedBox(width: 4),
              Text('${w.damage}', style: small?.copyWith(color: Colors.white)),
              if (aimAt != null) ...[
                const SizedBox(width: 3),
                Icon(Icons.south, size: 11, color: ink.blood),
                Text(trFor(lang, 'ship_room_${aimAt.name}_title'),
                    style: small?.copyWith(color: ink.blood)),
              ],
            ],
          ),
          border: aimAt != null ? ink.blood : null,
        ),
      );
    }

    final weapons = enemy.weapons;
    if (weapons.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 4,
      runSpacing: 4,
      children: [for (final w in weapons) chip(w)],
    );
  }

  /// The Eel's guns as cards: the charge as a ring, gold when ready; the
  /// armed one picked out. Tap to arm, then tap a room of the enemy.
  /// The Eel's weapons in one row, however many she carries (up to nine
  /// on the biggest hulls): each a tile with its charge ring, damage and,
  /// when there is room, its name. A tap arms it; a hold names it, its
  /// shot and its state.
  Widget _buildPlayerWeapons(bool fr) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    final weapons = _battle.player.weapons;
    Widget tile(ShipWeapon w, double width) {
      final armed = _armedWeaponId == w.id;
      final ready = _battle.inRange(w) && w.isReady;
      final state = !_battle.inRange(w)
          ? trFor(lang, 'ship_out_of_range_label')
          : armed
              ? trFor(lang, 'ship_weapon_armed_label')
              : w.isReady
                  ? trFor(lang, 'ship_weapon_ready_label')
                  : '${w.charge}/${w.chargeTurns}';
      final enabled = _battle.canFire(w) && !_busy && !_over;
      final roomy = width >= 76;
      final ring = _ChargeRing(
        value: w.chargeTurns <= 0 ? 1 : w.charge / w.chargeTurns,
        color: ready ? ink.gold : ink.tide,
        track: ink.seam,
        size: 26,
        child:
            Icon(_weaponIcon(w), size: 13, color: ready ? ink.gold : ink.ash),
      );
      final damage = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (w.ammo != ShipAmmo.round) ...[
            Icon(_ammoIcon(w.ammo),
                key: Key('ship_weapon_ammo_${w.id}'),
                size: 10,
                color: ready ? ink.ember : ink.ash),
            const SizedBox(width: 2),
          ],
          Text('${w.damage}',
              style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ready ? ink.gold : ink.ash)),
        ],
      );
      return Tooltip(
        message: '${w.nameFor(fr)} · ${w.damage} · $state\n'
            '${trFor(lang, 'ship_ammo_${w.ammo.name}_hint')}',
        child: Material(
          color: armed
              ? ink.gold.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
                color: armed ? ink.gold : ink.seam, width: armed ? 2 : 1),
          ),
          child: InkWell(
            key: Key('ship_weapon_${w.id}'),
            borderRadius: BorderRadius.circular(8),
            onTap: enabled
                ? () => _update(() {
                      _armedWeaponId = armed ? null : w.id;
                      _selectedCrewId = null;
                      _cancelAim();
                    })
                : null,
            child: SizedBox(
              height: 48,
              child: roomy
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        children: [
                          ring,
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(w.nameFor(fr),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                            color: ready ? null : ink.ash)),
                                Row(
                                  children: [
                                    damage,
                                    Flexible(
                                      child: Text(' · $state',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                  color: ready
                                                      ? ink.gold
                                                      : ink.ash)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [ring, const SizedBox(height: 1), damage],
                    ),
            ),
          ),
        ),
      );
    }

    if (weapons.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 5.0;
      final width =
          (constraints.maxWidth - gap * (weapons.length - 1)) / weapons.length;
      return Row(
        children: [
          for (final (i, w) in weapons.indexed) ...[
            if (i > 0) const SizedBox(width: gap),
            SizedBox(width: width, child: tile(w, width)),
          ],
        ],
      );
    });
  }

  /// The crew, one card each: health, the station they hold (tap another
  /// to move them) and their order, once a battle.
  Future<void> _openCrewSheet(Map<String, dynamic>? enemies) {
    final lang = ref.read(appLanguageProvider);
    return showInkSheet<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          void act(VoidCallback change) {
            _update(change);
            setSheet(() {});
          }

          final theme = Theme.of(sheetContext);
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75),
              child: ListView(
                key: const Key('ship_crew_sheet'),
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(trFor(lang, 'ship_crew_title'),
                            style: const TextStyle(
                                fontFamily: InkFonts.display, fontSize: 20)),
                      ),
                      OutlinedButton.icon(
                        key: const Key('ship_auto_station'),
                        onPressed: _busy || _over || _battle.crew.isEmpty
                            ? null
                            : () => act(() {
                                  _battle.autoStation();
                                  _selectedCrewId = null;
                                }),
                        icon: const Icon(Icons.auto_fix_high, size: 16),
                        label: Text(trFor(lang, 'ship_auto_station_button'),
                            style: theme.textTheme.labelSmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final c in _battle.crew) _crewCard(c, enemies, act),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _crewCard(ShipCrew c, Map<String, dynamic>? enemies,
      void Function(VoidCallback) act) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.read(appLanguageProvider);
    final station = _battle.stationOf(c.id);
    final order = orderFor(c);
    final ratio = c.maxHealth <= 0 ? 0.0 : c.health / c.maxHealth;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: ink.seam),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _crewToken(c, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: ratio.clamp(0.0, 1.0),
                              minHeight: 4,
                              color: ink.heal,
                              backgroundColor: ink.seam,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('${c.health}/${c.maxHealth}',
                            style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final room in ShipRoom.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: OutlinedButton(
                      key: Key('ship_station_${c.id}_${room.name}'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: station == room
                            ? _roomColor(context, room).withValues(alpha: 0.16)
                            : null,
                        side: BorderSide(
                            color: station == room
                                ? _roomColor(context, room)
                                : ink.seam),
                      ),
                      onPressed: _busy || _over
                          ? null
                          : () => act(() {
                                _battle.station(c.id, room);
                                _selectedCrewId = null;
                              }),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          trFor(lang, 'ship_room_${room.name}_title'),
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (order != null) ...[
            const SizedBox(height: 8),
            Text(
                '${trFor(lang, 'ship_order_${order.name}')} · ${trFor(lang, 'ship_order_${order.name}_hint')}',
                style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
          ],
        ],
      ),
    );
  }

  Future<void> _openLog() {
    final lang = ref.read(appLanguageProvider);
    final lines = [for (final line in _battle.log.reversed) _line(line)];
    return showInkSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(trFor(lang, 'ship_log_title'),
                  style: const TextStyle(
                      fontFamily: InkFonts.display, fontSize: 20)),
              const SizedBox(height: 8),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(line,
                      style: Theme.of(sheetContext).textTheme.bodyMedium),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
