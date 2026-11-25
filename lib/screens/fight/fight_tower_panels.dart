part of '../fight_screen.dart';

/// The Tower's fight board in ink (v1.1008, the approved version A): the foes
/// and the party each stand in a slanted picture panel on the floor's plate,
/// their chibi in it and their nameplates (FightBlock's ink plate) laid over
/// the top. The cards are the usual slots with their taps and keys; only
/// their place changed. Used instead of [_buildSlots] under the Tower.
/// How one fighter panel is filled: [wide] today's (the plate beside the
/// figure), [slim] the plate only, [stacked] the plate over a tall figure.
enum _PanelMode { wide, slim, stacked }

extension _TowerPanels on _FightScreenState {
  static const double _panelGap = 4;

  Widget _buildTowerPanels(
      Map<String, dynamic> items, Map<String, _FacePreview> previews) {
    // Art's painted scene of the band: the foes' panel shows its middle, the
    // hero's its floor (v1.1008).
    final plate =
        towerFightScene(FightPlateOverride.maybeOf(context)?.floor ?? 1);
    // A short phone has no room for the figures under the plates.
    final figures = !_shortPhone;
    // A tall phone gives the pictures more room, so the figures stand bigger.
    final tall = MediaQuery.sizeOf(context).height >= 740;
    // One fighter on a side stands beside its plate, whole, feet on the floor
    // line; several stand under theirs.
    final foeLone = _enemies.length == 1;
    final partyLone = _party.length == 1;
    final foeH = figures ? (foeLone ? 128.0 : (tall ? 184.0 : 128.0)) : 84.0;
    final partyH =
        figures ? (partyLone ? 122.0 : (tall ? 172.0 : 132.0)) : 80.0;
    final figureH = tall ? 84.0 : 56.0;
    // The foe the picked die is aimed at (its index in the row), if any.
    final aimed = _towerAimedFoe();
    // The layout of the two panels (null: today's, foe above and "You" under).
    // The fight's own layout: a rival's two panels side by side (one foe), a
    // boss's tall panel, an Elite's small step; a forced one wins (pictures,
    // tests).
    final layout = towerPanelLayout.value ??
        (widget.rival && _enemies.length == 1
            ? TowerPanelLayout.rival
            : _enemies.any((e) => isBossEnemy(e.enemyId, e.data))
                ? TowerPanelLayout.boss
                : _isElite
                    ? TowerPanelLayout.elite
                    : TowerPanelLayout.ordinary);
    final total = foeH + _panelGap + partyH;
    Widget panel(
      double height,
      bool foes,
      List<Widget> cards, {
      _PanelMode mode = _PanelMode.wide,
      double figScale = 1,
      double figBottom = 22,
      bool mirror = false,
      double plateInset = 0,
      double plateRight = 0,
      Widget? overlay,
      List<Offset> Function(double w, double h)? shape,
    }) =>
        LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          // Slanted edges: the foes' panel rises to the right, the party's
          // falls, so the two read as one cut picture.
          final pts = shape?.call(w, height) ??
              (foes
                  ? [
                      const Offset(6, 14),
                      Offset(w - 6, 6),
                      Offset(w - 6, height - 6),
                      Offset(6, height - 6),
                    ]
                  : [
                      const Offset(6, 6),
                      Offset(w - 6, 6),
                      Offset(w - 6, height - 6),
                      Offset(6, height - 14),
                    ]);
          final wide = mode == _PanelMode.wide;
          final stacked = mode == _PanelMode.stacked;
          final showFigure = figures && mode != _PanelMode.slim;
          Widget figure = FightFigures(
            allies: foes ? const [] : [for (final m in _party) _headIdFor(m)],
            foes: foes ? [for (final e in _enemies) e.enemyId] : const [],
            height: figureH * figScale,
          );
          if (mirror) {
            figure = Transform.flip(flipX: true, child: figure);
          }
          return PanelFxShake(
            foe: foes,
            child: InkSlantPanel(
              key: foes ? towerFoePanelKey : towerPartyPanelKey,
              size: Size(w, height),
              points: pts,
              child: Stack(fit: StackFit.expand, children: [
                Image.asset(plate,
                    fit: BoxFit.cover,
                    alignment: foes
                        ? const Alignment(0, 0.25)
                        : Alignment.bottomCenter,
                    filterQuality: FilterQuality.none,
                    errorBuilder: (c, e, s) =>
                        const ColoredBox(color: inkDeep)),
                if (figures && foes && aimed != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        key: const Key('tower_aim_splash'),
                        painter: InkSplashPainter(
                            (aimed + 0.5) / _enemies.length, height - 40),
                      ),
                    ),
                  ),
                if (overlay != null) overlay,
                if (showFigure)
                  Positioned(
                    // A lone fighter: a box 176 wide holds its half (84) at the
                    // panel's edge; several share the whole width.
                    left: stacked || !(cards.length == 1 && foes) ? 8 : null,
                    right: stacked || !(cards.length == 1 && !foes) ? 8 : null,
                    width:
                        cards.length == 1 && !stacked ? 176 * figScale : null,
                    bottom: figBottom,
                    child: IgnorePointer(
                      child: stacked ? Center(child: figure) : figure,
                    ),
                  ),
                Positioned(
                  // One fighter's plate leaves its picture room to stand
                  // beside it (the hero left, a lone foe right), as in the
                  // approved A.
                  left: 12 +
                      (!foes ? plateInset : 0) +
                      (wide && !foes && figures && cards.length == 1 ? 96 : 0),
                  right: 12 +
                      plateRight +
                      (foes ? plateInset : 0) +
                      (wide && foes && figures && cards.length == 1 ? 96 : 0),
                  top: foes ? 18 : 10,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  ),
                ),
              ]),
            ),
          );
        });

    final foeCards = [
      for (final e in _enemies)
        KeyedSubtree(
          key: _enemyCardKey(e.key),
          child: VfxRecoil(
            controller: _vfx,
            anchor: _enemyCardKey(e.key),
            flash: false,
            child: _buildEnemySlot(e, previews),
          ),
        ),
    ];
    final partyCards = [
      for (final m in _party)
        KeyedSubtree(
          key: _memberCardKey(m.id),
          child: VfxRecoil(
            controller: _vfx,
            anchor: _memberCardKey(m.id),
            child: _buildPartySlot(m, items),
          ),
        ),
    ];
    switch (layout) {
      case TowerPanelLayout.ordinary:
        break;
      case TowerPanelLayout.elite:
        // A small step: the foe's panel a fifth taller.
        final fh = foeH * 1.2;
        return Column(children: [
          SizedBox(
              height: fh, child: panel(fh, true, foeCards, figScale: 1.15)),
          const SizedBox(height: _panelGap),
          SizedBox(
              height: total - fh - _panelGap,
              child: panel(total - fh - _panelGap, false, partyCards)),
        ]);
      case TowerPanelLayout.boss:
        // The boss scene: the boss facing the viewer in its tall panel, the hero
        // from behind in the strip under it, offset to the right so he never
        // covers the boss, his head and shoulders over the seam.
        final bossFrame = _enemies.length == 1
            ? bossSouthAsset(_enemies.first.enemyId)
            : null;
        final heroFrame = heroNorthAsset(heroWalkOf(context));
        if (bossFrame != null && heroFrame != null && figures) {
          const stripH = 70.0;
          final bh = total - stripH - _panelGap;
          panelFx.loneFoeX = 0.5;
          return SizedBox(
            height: total,
            child: Stack(clipBehavior: Clip.none, children: [
              Column(children: [
                SizedBox(
                    height: bh,
                    child: panel(bh, true, foeCards,
                        mode: _PanelMode.slim,
                        overlay: Positioned(
                            left: 0,
                            right: 0,
                            bottom: 10,
                            child: Center(
                                child: BossSceneFigure(
                                    key: const Key('boss_scene_foe'),
                                    asset: bossFrame,
                                    height: bh - 62))))),
                const SizedBox(height: _panelGap),
                SizedBox(
                    height: stripH,
                    child: LayoutBuilder(
                        builder: (context, box) => panel(
                            stripH, false, partyCards,
                            mode: _PanelMode.slim,
                            plateRight: box.maxWidth * 0.3))),
              ]),
              // The hero, over the seam (outside the panels' clip).
              Positioned(
                left: 0,
                right: 0,
                bottom: 6,
                child: PanelFxShake(
                  foe: false,
                  child: Align(
                    alignment: const Alignment(0.62, 0),
                    child: BossSceneFigure(
                        key: const Key('boss_scene_hero'),
                        asset: heroFrame,
                        height: 92),
                  ),
                ),
              ),
            ]),
          );
        }
        panelFx.loneFoeX = 0.74;
        // The foe's panel one and a half times taller, "You" slim under it.
        final fh = foeH * 1.5;
        return Column(children: [
          SizedBox(height: fh, child: panel(fh, true, foeCards, figScale: 1.5)),
          const SizedBox(height: _panelGap),
          SizedBox(
              height: total - fh - _panelGap,
              child: panel(total - fh - _panelGap, false, partyCards,
                  mode: _PanelMode.slim)),
        ]);
      case TowerPanelLayout.rival:
        // Two tall panels side by side, facing each other, a slanted gutter.
        const slant = 16.0;
        List<Offset> left(double w, double h) => [
              const Offset(6, 6),
              Offset(w - 6, 6),
              Offset(w - 6 - slant, h - 6),
              Offset(6, h - 6),
            ];
        List<Offset> right(double w, double h) => [
              const Offset(6 + slant, 6),
              Offset(w - 6, 6),
              Offset(w - 6, h - 6),
              Offset(6, h - 6),
            ];
        return FightNameWrap(
          child: SizedBox(
            height: total,
            child: Row(children: [
              Expanded(
                child: panel(total, true, foeCards,
                    mode: _PanelMode.stacked,
                    figScale: 2.3,
                    figBottom: 12,
                    mirror: true,
                    plateInset: slant + 6,
                    shape: left),
              ),
              Expanded(
                child: panel(total, false, partyCards,
                    mode: _PanelMode.stacked,
                    figScale: 2.3,
                    figBottom: 12,
                    mirror: true,
                    plateInset: slant + 6,
                    shape: right),
              ),
            ]),
          ),
        );
    }

    return Column(children: [
      SizedBox(height: foeH, child: panel(foeH, true, foeCards)),
      const SizedBox(height: _panelGap),
      SizedBox(height: partyH, child: panel(partyH, false, partyCards)),
    ]);
  }

  /// The index of the foe the picked die is aimed at (more than one foe
  /// standing, a die picked and not kept), else null.
  int? _towerAimedFoe() {
    final picked = _dieLocks.selected;
    if (picked == null || _isDieLocked(picked) || _enemies.length < 2) {
      return null;
    }
    final target = _selectedTargets[picked];
    if (target == null) return null;
    final i = _enemies.indexWhere((e) => e.key == target);
    return i < 0 ? null : i;
  }

  /// The faces of the first acting die in one strip under the board, the one
  /// rolled lit red (the approved A: the real dice with the face strip).
  Widget _buildTowerFaceStrip(_PartyMember actor) {
    final faces = actor.dieFaces;
    if (faces.isEmpty) return const SizedBox.shrink();
    final lit = _currentFaces[actor.id]?.faceIndex;
    return Padding(
      key: const Key('tower_face_strip'),
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        for (var i = 0; i < faces.length; i++)
          Expanded(
            child: Container(
              height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: inkDeep,
                border: Border.all(
                    color: i == lit ? inkRed : inkGrey.withValues(alpha: 0.6),
                    width: i == lit ? 2 : 1),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(faceKind('${faces[i]['type']}').icon,
                      size: IconSize.inline,
                      color: i == lit ? inkPaper : inkGrey),
                  if (faces[i]['value'] != null)
                    Text(' ${faces[i]['value']}',
                        style: TextStyle(
                            fontSize: 10,
                            height: 1,
                            color: i == lit ? inkPaper : inkGrey)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  /// A die's tag on the plate, "name · d6 · Fire": the die's name, its faces,
  /// and the element of the face on the table when it has one (the approved
  /// A's tags under the dice).
  Widget _buildTowerDieTag(_PartyMember actor, Map<String, dynamic> skills) {
    final lang = ref.watch(appLanguageProvider);
    final face = _currentFaces[actor.id];
    final element = face == null ? 'None' : _elementFor(face, skills);
    final id = actor.equippedDiceId;
    final name = id == null ? '?' : dieDisplayName(id, language: lang);
    final text = [
      name,
      'd${actor.dieFaces.length}',
      if (element != 'None') elementLabel(element, lang),
    ].join(' · ');
    return Container(
      key: Key('tower_die_tag_${actor.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: inkBlack.withValues(alpha: 0.88),
      child: Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontFamily: InkFonts.system,
              fontSize: 9,
              height: 1.1,
              color: inkPaper)),
    );
  }

  /// The hero's sheet, one tap on its plate (the Tower's lighter nameplates
  /// keep only the name and a thin bar): the health in numbers, the armour
  /// and the damage, and the status marks with their own popins.
  Future<void> _showTowerHeroSheet(
      _PartyMember member, int armor, int damage, List<Widget> icons) {
    final theme = Theme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: inkBlack,
      shape: const RoundedRectangleBorder(),
      builder: (sheet) => Theme(
        data: theme,
        child: TowerPanelStyle(
          child: SafeArea(
            child: Padding(
              key: Key('tower_hero_sheet_${member.id}'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.displayName,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: inkPaper)),
                  const SizedBox(height: 10),
                  Text('${member.currentHealth} / ${member.maxHealth}',
                      key: const Key('tower_hero_sheet_hp'),
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(color: inkPaper)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.shield_outlined,
                        size: IconSize.s16, color: inkPaper),
                    Text(' $armor   ',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: inkPaper)),
                    const Icon(Icons.bolt, size: IconSize.s16, color: inkRed),
                    Text(' $damage',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: inkPaper)),
                  ]),
                  if (icons.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(spacing: 4, runSpacing: 4, children: icons),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
