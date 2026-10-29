part of '../fight_screen.dart';

/// The on-screen effects: screen shake, and the effects played for
/// faces, enemy moves and spells.
extension _FightEffects on _FightScreenState {
  bool get _effectsOn => ref.read(combatEffectsEnabledProvider) && !_quick;

  void _triggerShake() {
    if (!ref.read(trembleEnabledProvider)) return;
    _shakeController.forward(from: 0);
  }

  /// The stage under the cards (docs/proposals/fight-fixed-sizes.md): one
  /// fixed box for each figure, whatever the party and the pack are, the art
  /// scaled to its box and every figure on one ground line. The hero stands
  /// in front on the left, the allies in a back row behind it (a disc with
  /// their initial: they have no sprite yet), the foes fill front-right,
  /// front-left, then the back row, and a boss has its own bigger box. Its
  /// height is reserved ([FightBoxes.stageHeight]) so nothing under it moves;
  /// the cards above give way, never the stage. Each figure takes its health
  /// bar over its box; the figures take no touch.
  Widget _fightStage(double width) {
    final boxes = FightBoxes.forWidth(width);
    final boss = isBossEnemy(widget.enemyId, widget.enemy) ||
        _enemies.any((e) => isBossEnemy(e.enemyId, e.data));
    final animate = ref.watch(combatEffectsEnabledProvider) &&
        !_quick &&
        !MediaQuery.of(context).disableAnimations;
    const ground = 6.0;
    const backLift = 10.0;
    final children = <Widget>[];

    // A figure's slot: its centre on the stage and how far the back row
    // stands above the ground.
    void place({
      required double cx,
      required double box,
      required Widget body,
      required Widget bar,
      required double bodyLeft,
      double lift = 0,
    }) {
      children.add(Positioned(
        left: cx - bodyLeft,
        bottom: lift,
        child: IgnorePointer(child: body),
      ));
      children.add(Positioned(
        left: cx - box * 0.45,
        bottom: lift + ground + box + 2,
        child: IgnorePointer(child: bar),
      ));
    }

    // The foes: the back row is drawn first, so the front one stands over it.
    final foes = _enemies;
    final foeBox = boxes.foe;
    final gap = foeBox * 0.7;
    var right = width - 12 - foeBox / 2;
    final bossFoe =
        foes.where((e) => isBossEnemy(e.enemyId, e.data)).firstOrNull;
    if (bossFoe != null) right -= (boxes.boss - foeBox) / 2;
    final slots = <(double, double)>[]; // (cx, lift) by slot
    for (var i = 0; i < foes.length; i++) {
      slots.add(switch (foes.length) {
        1 => (right, 0.0),
        2 => (right - i * gap, 0.0),
        _ => switch (i) {
            0 => (right, 0.0),
            1 => (right - 2 * gap, 0.0),
            _ => (right - gap * (i == 2 ? 1 : i + 0.0), backLift),
          },
      });
    }
    final order = [
      for (var i = 0; i < foes.length; i++) i,
    ]..sort((a, b) => slots[b].$2.compareTo(slots[a].$2));
    for (final i in order) {
      final enemy = foes[i];
      final isBoss = isBossEnemy(enemy.enemyId, enemy.data);
      final box = isBoss ? boxes.boss : foeBox;
      final set = enemyFightSprite(enemy.enemyId);
      final cx = isBoss && foes.length == 1 ? right : slots[i].$1;
      final worn = set != null && !FightSpriteImages.failed(set);
      final Widget body;
      final double bodyLeft;
      if (worn) {
        final pixel = FightBoxes.pixelFor(set, box);
        final size = FightFigure.sizeFor(set, pixel);
        bodyLeft =
            FightFigure.lungeReach + (size.width - FightFigure.lungeReach) / 2;
        body = FightFigure(
          figureKey: Key('fight_enemy_sprite_${enemy.key}'),
          controller: _vfx,
          anchor: _enemyCardKey(enemy.key),
          alive: enemy.isAlive,
          animate: animate,
          sprite: set,
          pixel: pixel,
          downOpacity: 0,
          fallback: false,
          phase: (i * 0.37) % 1.0,
        );
      } else {
        // No art (or its image is missing): its portrait stands in the box.
        final side = box * 0.75;
        bodyLeft = side / 2;
        body = Padding(
          padding: const EdgeInsets.only(bottom: ground),
          child: PixelEnemyPortrait(
            key: Key('fight_enemy_sprite_${enemy.key}'),
            enemyId: enemy.enemyId,
            alive: enemy.isAlive,
            controller: _vfx,
            anchor: _enemyCardKey(enemy.key),
            boss: isBoss,
            animate: animate,
            size: side,
          ),
        );
      }
      place(
        cx: cx,
        box: box,
        lift: slots[i].$2,
        bodyLeft: bodyLeft,
        body: body,
        bar: enemy.isAlive
            ? StageBar(
                key: Key('fight_stage_bar_${enemy.key}'),
                current: enemy.currentHealth,
                max: enemy.maxHealth,
                width: box * 0.9)
            : const SizedBox.shrink(),
      );
    }

    // The allies, in a back row to the left of the hero, one step higher,
    // their boxes overlapping; the hero in front.
    final heroCx = width * 0.30;
    final allies = [
      for (final m in _party)
        if (!m.isPlayer) m,
    ];
    final firstAlly = heroCx - boxes.hero * 0.55;
    final minAlly = 12 + boxes.ally / 2;
    final step = allies.length > 1
        ? max(6.0,
            min(boxes.ally * 0.62, (firstAlly - minAlly) / (allies.length - 1)))
        : 0.0;
    for (final (i, ally) in allies.indexed.toList().reversed) {
      final side = boxes.ally * 0.8;
      place(
        cx: firstAlly - i * step,
        box: boxes.ally,
        lift: backLift,
        bodyLeft: side / 2,
        body: Padding(
          padding: const EdgeInsets.only(bottom: ground),
          child: StageDisc(
            key: Key('fight_ally_disc_${ally.id}'),
            initial: ally.displayName.isEmpty
                ? '?'
                : ally.displayName[0].toUpperCase(),
            accent: _accentFor(ally),
            diameter: side,
            alive: !ally.isKnockedOut,
          ),
        ),
        bar: ally.isKnockedOut
            ? const SizedBox.shrink()
            : StageBar(
                key: Key('fight_stage_bar_${ally.id}'),
                current: ally.currentHealth,
                max: ally.maxHealth,
                width: boxes.ally * 0.9),
      );
    }

    // The hero, in front: the art from the resolver (fight_sprites.dart),
    // scaled to the hero's box.
    final hero = _party.where((m) => m.isPlayer).firstOrNull;
    if (hero != null) {
      final session = ref.read(playerSessionProvider);
      final sprite = FightSpriteImages.effective(heroFightSprite(
          raceId: session.raceId, professionId: session.professionId));
      final pixel = FightBoxes.pixelFor(sprite, boxes.hero);
      final size = FightFigure.sizeFor(sprite, pixel);
      place(
        cx: heroCx,
        box: boxes.hero,
        bodyLeft: (size.width - FightFigure.lungeReach) / 2,
        body: FightFigure(
          controller: _vfx,
          anchor: _memberCardKey(hero.id),
          alive: !hero.isKnockedOut,
          animate: animate,
          sprite: sprite,
          pixel: pixel,
        ),
        bar: hero.isKnockedOut
            ? const SizedBox.shrink()
            : StageBar(
                key: const Key('fight_stage_bar_hero'),
                current: hero.currentHealth,
                max: hero.maxHealth,
                width: boxes.hero * 0.9),
      );
    }

    return SizedBox(
      key: const Key('fight_stage'),
      height: boxes.stageHeight(boss: boss),
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }

  /// A mighty blow landing, as the effect layer plays it: the screen
  /// shakes and the phone gives a heavy tap, both under the tremble
  /// setting.
  void _onVfxImpact(VfxImpact impact) {
    if (!mounted || !impact.hit || impact.tier != VfxTier.mighty) return;
    if (!ref.read(trembleEnabledProvider)) return;
    _shakeController.forward(from: 0);
    HapticFeedback.heavyImpact();
  }

  /// The weapon [actor] holds, as its family and its rarity (lowercase,
  /// for [vfxPowerFor]): the equipped one that hits hardest, so a shield
  /// held beside it does not count. Null with none, a bare-handed blow.
  (WeaponFamily, String)? _weaponOf(_PartyMember actor) {
    final items = ref.read(localizedDbProvider(itemsSchema)).value;
    if (items == null) return null;
    Map<String, dynamic>? best;
    var bestDamage = 0;
    for (final id in actor.equippedItemIds) {
      final item = items[id];
      if (item is! Map<String, dynamic> || item['itemType'] != 'Weapon') {
        continue;
      }
      final damage = (item['attackDamage'] as num?)?.toInt() ?? 0;
      if (damage > bestDamage) {
        best = item;
        bestDamage = damage;
      }
    }
    if (best == null) return null;
    final family = weaponFamilyOf(best['id']?.toString() ?? '',
        best['itemName']?.toString() ?? '', bestDamage);
    return (family, best['rarity']?.toString().toLowerCase() ?? 'common');
  }

  /// What one party member's die looks like on screen: the face's (or its
  /// skill's) effect on the enemy it hit with the damage floating off it,
  /// a critical's starburst, the status it left, a heal, a shield or mana
  /// on the member, and a lifesteal drawn back to them. Each plays at the
  /// power of the skill behind it (see [vfxPowerFor]): its rarity, its
  /// upgrades, how much of the target's health it takes, a critical; a
  /// mighty blow also shakes the screen as it lands (see [_onVfxImpact]).
  void _playFaceEffects({
    required _PartyMember actor,
    required DiceFaceResult face,
    required Map<String, dynamic> skills,
    required String element,
    required PlayerActionResult result,
    required _EnemyMember? target,
    required int dealt,
    required int healing,
    required int block,
    required int drained,
    required int delayMs,
  }) {
    if (!_effectsOn) return;
    final actorKey = _memberCardKey(actor.id);
    final skill = face.type == 'Skill'
        ? skills[_effectiveSkillId(face)] as Map<String, dynamic>?
        : null;
    final weapon = _weaponOf(actor);
    final style = styleForFace(face.type, skill, weapon: weapon?.$1);
    final support = isSupportSkill(skill);
    // A plain strike plays at the weight of the weapon in hand.
    final rarity =
        skill == null ? weapon?.$2 : skill['rarity']?.toString().toLowerCase();
    final tier = skill == null ? 0 : actor.skillTiers[_effectiveSkillId(face)];
    double powerFor(int amount, int maxHealth, {bool critical = false}) =>
        vfxPowerFor(
          rarity: rarity,
          tier: tier ?? 0,
          amount: amount,
          targetMaxHealth: maxHealth,
          critical: critical,
        );
    if (target != null) {
      final targetKey = _enemyCardKey(target.key);
      // The hero steps in with its blow (see fight_figure.dart).
      if (actor.isPlayer) {
        _vfx.cue(actorKey, PortraitCue.lunge, delayMs: delayMs);
      }
      if (dealt > 0) {
        final power =
            powerFor(dealt, target.maxHealth, critical: result.isCritical);
        final hitStyle = support ? VfxStyle.slash : style;
        _vfx.play(
          style: hitStyle,
          target: targetKey,
          source: actorKey,
          element: element,
          delayMs: delayMs,
          text: '-$dealt',
          textKind: result.isCritical ? VfxTextKind.crit : VfxTextKind.damage,
          power: power,
          accent: vfxAccentOf(skill),
        );
        if (result.isCritical) {
          _vfx.play(
              style: VfxStyle.crit, target: targetKey, delayMs: delayMs + 250);
        }
      } else {
        _vfx.play(style: VfxStyle.miss, target: targetKey, delayMs: delayMs);
      }
      final inflicted = result.inflictedStatus;
      if (inflicted != null) {
        _vfx.play(
          style: styleForStatus(inflicted.type),
          target: targetKey,
          delayMs: delayMs + 350,
        );
      }
      if (drained > 0) {
        _vfx.play(
          style: VfxStyle.drain,
          target: targetKey,
          source: actorKey,
          element: 'Void',
          delayMs: delayMs + 300,
        );
        _vfx.play(
          style: VfxStyle.heal,
          target: actorKey,
          delayMs: delayMs + 700,
          text: '+$drained',
          textKind: VfxTextKind.heal,
        );
      }
    }
    if (healing > 0) {
      _vfx.play(
        style: support ? style : VfxStyle.heal,
        target: actorKey,
        element: support ? element : 'None',
        delayMs: delayMs + (dealt > 0 && !support ? 250 : 0),
        text: '+$healing',
        textKind: VfxTextKind.heal,
        power: powerFor(healing, actor.maxHealth),
        accent: vfxAccentOf(skill),
      );
    }
    if (block > 0) {
      _vfx.play(
        style: VfxStyle.shield,
        target: actorKey,
        delayMs: delayMs,
        text: '+$block',
        textKind: VfxTextKind.block,
        power: powerFor(block, actor.maxHealth),
      );
    }
    if (result.manaGained > 0) {
      _vfx.play(
        style: VfxStyle.mana,
        target: actorKey,
        delayMs: delayMs,
        text: '+${result.manaGained}',
        textKind: VfxTextKind.mana,
      );
    }
    if (face.type == 'Empty') {
      _vfx.play(style: VfxStyle.miss, target: actorKey, delayMs: delayMs);
    }
  }

  /// Plays one effect when effects are on.
  void _fx(
    VfxStyle style,
    GlobalKey target, {
    GlobalKey? source,
    String element = 'None',
    int delayMs = 0,
    String? text,
    VfxTextKind textKind = VfxTextKind.info,
    bool big = false,
    double? power,
  }) {
    if (!_effectsOn) return;
    _vfx.play(
      style: style,
      target: target,
      source: source,
      element: element,
      delayMs: delayMs,
      text: text,
      textKind: textKind,
      big: big,
      power: power,
    );
  }

  /// What an enemy's move looks like on screen: its skill's effect (a
  /// claw-and-blade strike for a plain attack) on the member it hit, the
  /// damage floating off them, a shield when their guard or a ward took it
  /// all, a puff when they dodged, and the status it left.
  void _playEnemyMoveEffects({
    required _EnemyMember enemy,
    required _PartyMember target,
    required String skillId,
    required String element,
    required Map<String, dynamic> skills,
    required bool dodged,
    required bool warded,
    required int damage,
    required StatusEffect? inflicted,
    required int delayMs,
  }) {
    if (!_effectsOn) return;
    final targetKey = _memberCardKey(target.id);
    final lang = ref.read(appLanguageProvider);
    // The enemy lunges at whom it strikes, as the blow sets off.
    final from = globalRectOf(_enemyCardKey(enemy.key));
    final to = globalRectOf(targetKey);
    _vfx.cue(_enemyCardKey(enemy.key), PortraitCue.lunge,
        delayMs: delayMs,
        dir: from == null || to == null
            ? const Offset(-1, 0)
            : to.center - from.center);
    if (dodged) {
      _vfx.play(
        style: VfxStyle.miss,
        target: targetKey,
        delayMs: delayMs,
        text: trFor(lang, 'vfx_dodge_label'),
      );
      return;
    }
    final style = styleForEnemyMove(skillId, skills);
    final skill = skills[skillId] as Map<String, dynamic>?;
    _vfx.play(
      style: style,
      target: targetKey,
      source: _enemyCardKey(enemy.key),
      element: skillId.isEmpty ? 'Enemy' : element,
      delayMs: delayMs,
      text: damage > 0 ? '-$damage' : null,
      textKind: VfxTextKind.hurt,
      // A boss's blows, and a blow that takes much of the member's health,
      // play bigger; a plain enemy's scratch smaller.
      power: vfxPowerFor(
        rarity: skill?['rarity']?.toString(),
        amount: damage,
        targetMaxHealth: target.maxHealth,
        boss: isBossEnemy(enemy.enemyId, enemy.data),
      ),
    );
    if (damage <= 0 || warded) {
      _vfx.play(
        style: VfxStyle.shield,
        target: targetKey,
        delayMs: delayMs + 250,
        text: '0',
        textKind: VfxTextKind.block,
      );
    }
    if (inflicted != null && damage > 0 && !target.isKnockedOut) {
      _vfx.play(
        style: styleForStatus(inflicted.type),
        target: targetKey,
        delayMs: delayMs + 350,
      );
    }
  }
}
