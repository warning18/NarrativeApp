part of '../fight_screen.dart';

/// The Tower's fight board in ink (v1.1008, the approved version A): the foes
/// and the party each stand in a slanted picture panel on the floor's plate,
/// their chibi in it and their nameplates (FightBlock's ink plate) laid over
/// the top. The cards are the usual slots with their taps and keys; only
/// their place changed. Used instead of [_buildSlots] under the Tower.
extension _TowerPanels on _FightScreenState {
  static const double _panelGap = 4;

  Widget _buildTowerPanels(
      Map<String, dynamic> items, Map<String, _FacePreview> previews) {
    final plate = _plateHere();
    // A short phone has no room for the figures under the plates.
    final figures = !_shortPhone;
    final foeH = figures ? 128.0 : 84.0;
    final partyH = figures ? 132.0 : 80.0;
    // The foe the picked die is aimed at (its index in the row), if any.
    final aimed = _towerAimedFoe();
    Widget panel(
      double height,
      bool foes,
      List<Widget> cards,
    ) =>
        LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          // Slanted edges: the foes' panel rises to the right, the party's
          // falls, so the two read as one cut picture.
          final pts = foes
              ? [
                  Offset(6, 14),
                  Offset(w - 6, 6),
                  Offset(w - 6, height - 6),
                  Offset(6, height - 6),
                ]
              : [
                  Offset(6, 6),
                  Offset(w - 6, 6),
                  Offset(w - 6, height - 6),
                  Offset(6, height - 14),
                ];
          return InkSlantPanel(
            size: Size(w, height),
            points: pts,
            child: Stack(fit: StackFit.expand, children: [
              Image.asset(plate,
                  fit: BoxFit.cover,
                  alignment:
                      foes ? Alignment.topCenter : Alignment.bottomCenter,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (c, e, s) => const ColoredBox(color: inkDeep)),
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
              if (figures)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 6,
                  child: IgnorePointer(
                    child: FightFigures(
                      allies: foes
                          ? const []
                          : [for (final m in _party) _headIdFor(m)],
                      foes: foes
                          ? [for (final e in _enemies) e.enemyId]
                          : const [],
                      height: 56,
                    ),
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
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
          );
        });

    return Column(children: [
      _buildClimbStrip(),
      SizedBox(
        height: foeH,
        child: panel(foeH, true, [
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
        ]),
      ),
      const SizedBox(height: _panelGap),
      SizedBox(
        height: partyH,
        child: panel(partyH, false, [
          for (final m in _party)
            KeyedSubtree(
              key: _memberCardKey(m.id),
              child: VfxRecoil(
                controller: _vfx,
                anchor: _memberCardKey(m.id),
                child: _buildPartySlot(m, items),
              ),
            ),
        ]),
      ),
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

  /// The 30 floors as a strip of ticks, those climbed in paper, this one in
  /// red, the bosses' taller and outlined in red (the approved A's header).
  Widget _buildClimbStrip() {
    final floor = FightPlateOverride.maybeOf(context)?.floor ?? 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SizedBox(
        key: const Key('tower_climb_strip'),
        height: 20,
        child: Row(children: [
          for (var i = 1; i <= 30; i++)
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(0.8, i % 10 == 0 ? 0 : 6, 0.8, 0),
                decoration: BoxDecoration(
                  color: i < floor
                      ? inkGrey
                      : i == floor
                          ? inkRed
                          : inkBlack,
                  border: Border.all(
                      color: i % 10 == 0
                          ? inkRed
                          : inkGrey.withValues(alpha: 0.6)),
                ),
              ),
            ),
        ]),
      ),
    );
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
}
