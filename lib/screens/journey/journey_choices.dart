part of '../journey_screen.dart';

/// The panel under the map: its height, the choice cards, the rings and the
/// list sheets, and who the scene faces. Cut out of journey_screen.dart with
/// no change (setState is called as _update).
extension _JourneyChoices on _JourneyViewState {
  double _panelHeight(double area, List<_Step> steps) {
    final plain = math.min(124.0, math.max(104.0, area * 0.26));
    final cards = steps.where((s) => s.onCard).length;
    if (!_writtenDetour || cards == 0) return plain;
    // On a short phone the map keeps its room and the cards scroll; a taller
    // one gives them more, up to three cards.
    final room = ((area - 430) * 0.4).clamp(0.0, 90.0);
    return math.max(plain, math.min(plain + room, 66.0 * 3 + 8));
  }

  /// The tag a card carries: a price, an alignment shift, a check or the
  /// kind of fight, whichever the choice has first (Core's choiceTags).
  ChoiceTag? _cardTag(_Step step, InkColors ink) {
    final c = step.choice;
    final tags = step.tags;
    String signed(int v) => v > 0 ? '+$v' : '−${v.abs()}';
    if (tags.cost > 0) {
      return ChoiceTag('${tags.cost} ${tr(ref, 'gold_label')}', ink.gold);
    }
    if (tags.alignment != 0) {
      return ChoiceTag(
          '${tr(ref, 'alignment_label')} ${signed(tags.alignment)}',
          ink.voidColor);
    }
    if (c.hasAbilityCheck) {
      return ChoiceTag(
          '${tr(ref, '${c.checkAbility}_label')} DC ${c.checkDC ?? 10}',
          ink.tide);
    }
    if (step.shape.action == ChoiceAction.fight) {
      return ChoiceTag(tr(ref, 'journey_kind_fight'), ink.blood);
    }
    return null;
  }

  /// The icon of a choice done here: its glyph (a fight, a roll, a shop), or
  /// for a plain decision or word, the action's own (the road's signpost
  /// would say it leads somewhere).
  IconData _iconOf(_Step step) {
    if (step.kind != JourneyStepKind.road) return step.glyph.icon;
    return switch (step.shape.action) {
      ChoiceAction.talk => Icons.chat_bubble_outline,
      ChoiceAction.decide => Icons.balance,
      ChoiceAction.pay => Icons.paid_outlined,
      ChoiceAction.sneak => Icons.visibility_off_outlined,
      ChoiceAction.attempt => Icons.casino_outlined,
      ChoiceAction.evade => Icons.directions_run,
      _ => step.glyph.icon,
    };
  }

  Color _groupColor(ChoiceGroup g, InkColors ink) => switch (g) {
        ChoiceGroup.fight => ink.blood,
        ChoiceGroup.talkDecide => ink.tide,
        ChoiceGroup.checksPay => ink.voidColor,
        ChoiceGroup.go => ink.ash,
      };

  /// The steps of ring [id] (a [ChoiceGroup]'s name, or 'ways' for the pins),
  /// by their place in the list of steps.
  List<int> _ringSteps(List<_Step> steps, String id) => [
        for (var i = 0; i < steps.length; i++)
          if (id == 'ways'
              ? !steps[i].onCard
              : steps[i].onCard && steps[i].tags.group.name == id)
            i,
      ];

  /// The rings of a hub: one for each kind with choices, with their icons.
  List<ChoiceRing> _rings(List<_Step> steps, InkColors ink) => [
        for (final g in _ringOrder)
          if (_ringSteps(steps, g.name).isNotEmpty)
            ChoiceRing(
              id: g.name,
              label: tr(ref, 'choice_group_${g.name}'),
              count: _ringSteps(steps, g.name).length,
              color: _groupColor(g, ink),
              icons: [
                for (final i in _ringSteps(steps, g.name)) _iconOf(steps[i]),
              ],
            ),
      ];

  /// [selected] when it is a card (the scene view has no pins to show).
  _Step? _pickedCard(_Step? selected) =>
      selected != null && selected.onCard ? selected : null;

  bool _isHub(List<_Step> steps) =>
      steps.where((s) => s.onCard).length > _hubCards;

  /// Who the scene faces, from the NPCs, the enemies and the companions
  /// (null for a voice, or no one).
  SceneFaced? _facedOf(String id, bool french) {
    if (id.isEmpty) return null;
    final npcs = ref.watch(localizedDbProvider(npcsSchema)).value;
    final enemies = ref.watch(localizedDbProvider(enemiesSchema)).value;
    final companions = ref.watch(localizedDbProvider(companionsSchema)).value;
    String pick(Map? r, String en, String fr) {
      if (r == null) return '';
      final local = french ? (r[fr]?.toString() ?? '') : '';
      return local.trim().isNotEmpty ? local : (r[en]?.toString() ?? '');
    }

    final npc = npcs?[id] as Map?;
    final enemy = enemies?[id] as Map?;
    final companion = companions?[id] as Map?;
    final name = pick(npc, 'npcName', 'npcName_fr').isNotEmpty
        ? pick(npc, 'npcName', 'npcName_fr')
        : pick(enemy, 'enemyName', 'enemyName_fr').isNotEmpty
            ? pick(enemy, 'enemyName', 'enemyName_fr')
            : pick(companion, 'companionName', 'companionName_fr');
    if (name.isEmpty) return null;
    return SceneFaced(id: id, name: name, role: pick(npc, 'role', 'role_fr'));
  }

  /// The scene's vignette and question over a panel's cards (the scene
  /// panel, UX's in-place choices): for a scene whose choices a panel shows
  /// (not a hub, not the stage), when it has someone it faces or a question.
  Widget? _vignetteFor(StoryNode node, List<_Step> steps, StoryData story,
      Geography world, bool french,
      {_Step? picked}) {
    if (_isHub(steps) || !steps.any((s) => s.onCard)) return null;
    final mode = sceneChoiceMode(node,
        story: story,
        geography: world,
        choices: [for (final s in steps) s.choice],
        hasSprite: sceneHasSprite);
    final prompt = node.promptFor(french);
    final faced = _facedOf(node.facing, french);
    if (mode == SceneChoiceMode.stage && faced != null) {
      // A fight facing someone with a sprite: the stage; the picked choice
      // speaks in a balloon, and the door shows where it leads.
      final door = picked == null
          ? null
          : doorOf(node, picked.choice,
              story: story, geography: world, shape: picked.shape);
      final doorLabel = door == null ? '' : doorName(door, french: french);
      return SceneStage(
        foeId: node.facing,
        foeName: faced.name,
        prompt: prompt,
        balloon: picked?.choice.replyFor(french) ?? '',
        doorName: doorLabel,
        doorLit: doorLabel.isNotEmpty,
      );
    }
    if (mode != SceneChoiceMode.panel) return null;
    if (prompt.isEmpty && faced == null) return null;
    final onCard = steps.where((s) => s.onCard).toList();
    // Four choices, or a long one: the vignette folds to a line.
    final folded = onCard.length >= panelChoiceLimit ||
        onCard.any((s) => s.label.length > 46);
    return SceneVignette(
      heroName: ref.watch(playerSessionProvider).characterName,
      prompt: prompt,
      faced: faced,
      folded: folded,
    );
  }

  /// The panel under the map in a place (design 1 of
  /// docs/proposals/inplace-choices.md): every choice acted out here is a
  /// card, the pin picked (if one is) leading with its own detail. A hub
  /// (design 3) shows a chip for each kind of choice instead: a tap opens
  /// that list. In the scene view (and under the map of a written detour,
  /// which has no pins).
  Widget _choicePanel(
      List<_Step> steps, _Step? selected, bool french, StoryData story,
      {bool shrinkWrap = false, bool all = false, Widget? lead}) {
    final ink = InkColors.of(context);
    final palette = ChartPalette.of(ref.watch(mapLookProvider));
    final enemies = ref.watch(localizedDbProvider(enemiesSchema)).value;
    // A locked page ([all], v1.553) lists every way as a card: the ways
    // somewhere as road cards, which go back to the map and walk them.
    final hub = !all && _isHub(steps);
    return ListView(
      key: const ValueKey('journey_choice_cards'),
      padding: EdgeInsets.zero,
      shrinkWrap: shrinkWrap,
      children: [
        // The scene in small and its question, over a panel's cards.
        if (!all && !hub && lead != null) lead,
        if (!all && selected != null && !selected.onCard) ...[
          _StepDetail(
            step: selected,
            busy: _busy,
            french: french,
            isExcursion: false,
            onGo: () => _take(_selected!, selected),
          ),
          const SizedBox(height: 6),
        ],
        if (hub) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final ring in _rings(steps, ink))
                ChoiceGroupChip(
                  key: ValueKey('choice_chip_${ring.id}'),
                  label: ring.label,
                  count: ring.count,
                  color: ring.color,
                  onTap: () => _openList(ring.id, steps, french, story),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(tr(ref, 'choice_hub_hint'),
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic)),
          ),
        ] else
          for (var i = 0; i < steps.length; i++)
            if (steps[i].onCard || (all && steps[i].shape.here))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _cardFor(i, steps[i], french, ink, palette, enemies,
                    identical(selected, steps[i])),
              )
            else if (all)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _cardFor(i, steps[i], french, ink, palette, enemies,
                    identical(selected, steps[i]),
                    onTap: () => _selected == i && !steps[i].locked
                        ? _leaveByRoad(i, steps[i])
                        : _update(() => _selected = i),
                    onGo: () => _leaveByRoad(i, steps[i])),
              ),
      ],
    );
  }

  /// Whether the map shows a banner for any of [steps] (not a card, not a
  /// round mark of a fight or a roll).
  bool _hasBannerPins(List<_Step> steps) => [
        for (final i in _pinIdx)
          if (i < steps.length &&
              journeyPinCatOf(steps[i].kind, steps[i].questTie) != null)
            i
      ].isNotEmpty;

  /// The key button at the map's top right: what the banners mean.
  Widget _legendButton(ChartPalette palette) => Positioned(
        right: 8,
        top: 8,
        child: _MapButton(
          key: const Key('journey_legend_key'),
          icon: Icons.vpn_key_outlined,
          tip: tr(ref, 'journey_legend_tip'),
          palette: palette,
          onTap: () => showJourneyLegend(context),
        ),
      );

  /// A ring's list (or the pins', "ways") in a sheet over the lower half of
  /// the screen: a tap picks a card (a pin lights its road on the map above)
  /// and a second tap does it. The ring stays lit on the map meanwhile.
  Future<void> _openList(
      String id, List<_Step> steps, bool french, StoryData story) async {
    if (_busy) return;
    _update(() => _ringOpen = id);
    final ink = InkColors.of(context);
    final palette = ChartPalette.of(ref.read(mapLookProvider));
    final enemies = ref.read(localizedDbProvider(enemiesSchema)).value;
    final title = id == 'ways'
        ? tr(ref, 'choice_ways_chip')
        : tr(ref, 'choice_group_$id');
    final members = _ringSteps(steps, id);
    final color = id == 'ways'
        ? Theme.of(context).colorScheme.onSurface
        : _groupColor(ChoiceGroup.values.firstWhere((g) => g.name == id), ink);
    final taken = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
      barrierColor: Colors.black26,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 6),
                child: Row(
                  children: [
                    Icon(Icons.circle_outlined, size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('$title · ${members.length}',
                          style: Theme.of(sheet)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  fontFamily: InkFonts.display, color: color)),
                    ),
                    IconButton(
                      key: const ValueKey('choice_sheet_close'),
                      onPressed: () => Navigator.of(sheet).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    for (final i in members)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _cardFor(
                          i,
                          steps[i],
                          french,
                          ink,
                          palette,
                          enemies,
                          _selected == i,
                          onTap: () {
                            if (_selected == i && !steps[i].locked) {
                              Navigator.of(sheet).pop(i);
                              return;
                            }
                            _update(() => _selected = i);
                            setSheet(() {});
                          },
                          onGo: () => Navigator.of(sheet).pop(i),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) _update(() => _ringOpen = null);
    if (taken != null && mounted && taken < steps.length) {
      _take(taken, steps[taken]);
    }
  }

  Widget _cardFor(int i, _Step step, bool french, InkColors ink,
      ChartPalette palette, Map<String, dynamic>? enemies, bool picked,
      {VoidCallback? onTap, VoidCallback? onGo}) {
    final choice = step.choice;
    final ids = choice.allTriggerEnemyIds;
    final roster =
        enemies == null || ids.isEmpty || ids.any((id) => id.startsWith('@'))
            ? null
            : enemyRoster(ids, enemies);
    final to = step.tags.destination;
    final cat = journeyPinCatOf(step.kind, step.questTie);
    return Opacity(
      // The choice taken stays lit; the others dim while it plays out.
      opacity: _busy && _pressed != null && _pressed != i ? 0.45 : 1,
      child: ChoiceCard(
        key: ValueKey('journey_choice_card_$i'),
        icon: step.onCard ? _iconOf(step) : step.glyph.icon,
        leading: step.onCard || cat == null
            ? null
            : BannerPin(
                cat: cat,
                color: cat.colorOn(ink,
                    dark: Theme.of(context).brightness == Brightness.dark),
                dark: Theme.of(context).brightness == Brightness.dark,
                scale: 0.8,
                lit: picked,
              ),
        // The card sits on the app's page, not on the map: the map's own pale
        // road colour would vanish on a light page.
        color: switch (step.kind) {
          JourneyStepKind.road =>
            Theme.of(context).colorScheme.onSurfaceVariant,
          JourneyStepKind.mainQuest => ink.gold,
          _ => _colorFor(step.kind, ink, palette, greyed: false),
        },
        text: step.label,
        notes: [
          if (roster != null && !step.locked)
            tr(ref, 'choice_fight_roster').replaceAll('{roster}', roster),
        ],
        leadsTo: to != null && !step.locked ? to.nameFor(french) : null,
        tag: step.locked ? null : _cardTag(step, ink),
        selected: picked,
        locked: step.locked,
        busy: _busy,
        goLabel: tr(ref, 'journey_go'),
        goKey: const ValueKey('journey_go'),
        onTap: _busy ? null : (onTap ?? () => _tap(i, step)),
        onGo: onGo ?? () => _take(i, step),
      ),
    );
  }
}
