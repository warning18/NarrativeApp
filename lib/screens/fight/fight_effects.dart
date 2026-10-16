part of '../fight_screen.dart';

/// The on-screen effects: screen shake, and the effects played for
/// faces, enemy moves and spells.
extension _FightEffects on _FightScreenState {
  bool get _effectsOn => ref.read(combatEffectsEnabledProvider) && !_quick;

  void _triggerShake() {
    if (!ref.read(trembleEnabledProvider)) return;
    _shakeController.forward(from: 0);
  }

  /// The hero's sprite on the ground below the party's cards, facing the
  /// enemies on the right (see fight_figure.dart): as big as the room
  /// the cards leave allows, and not at all where they leave none, so it
  /// never pushes the dice or the controls (a phone's fight is tight).
  List<Widget> _heroOnGround(BoxConstraints area) {
    final hero = _party.where((m) => m.isPlayer).firstOrNull;
    if (hero == null) return const [];
    // Each card, with a margin (an estimate: a card grows with its chips).
    final cards = _party.length * 112.0;
    final animate = ref.watch(combatEffectsEnabledProvider) &&
        !_quick &&
        !MediaQuery.of(context).disableAnimations;
    // The hero's art, and so its frame size, comes from the resolver
    // (fight_sprites.dart): a taller or wider sprite just takes a smaller
    // pixel, down to one, or none where the room is short.
    final session = ref.read(playerSessionProvider);
    final sprite = FightSpriteImages.effective(heroFightSprite(
        raceId: session.raceId, professionId: session.professionId));
    for (final pixel in const [3.0, 2.0, 1.0]) {
      final size = FightFigure.sizeFor(sprite, pixel);
      if (area.maxHeight - cards < size.height + 8) continue;
      // Centred under the party's column (five parts of eleven).
      final column = (area.maxWidth - 24 - 8) * 5 / 11;
      if (size.width > column + 24) continue;
      return [
        Positioned(
          left: 12 + max(0.0, (column - size.width) / 2),
          bottom: 4,
          child: IgnorePointer(
            child: FightFigure(
              controller: _vfx,
              anchor: _memberCardKey(hero.id),
              alive: !hero.isKnockedOut,
              animate: animate,
              sprite: sprite,
              pixel: pixel,
            ),
          ),
        ),
      ];
    }
    return const [];
  }

  /// The enemies that have art stand on the ground below the enemy cards,
  /// facing west toward the hero (see fight_sprites.dart, enemyFightSprite):
  /// each beside the others as far as the room goes, as large as it allows,
  /// and none where the cards leave no room. An enemy with no art, or whose
  /// image is missing, keeps its card alone.
  List<Widget> _enemiesOnGround(BoxConstraints area) {
    final worn = <(_EnemyMember, FightSpriteSet)>[
      for (final enemy in _enemies)
        if (enemyFightSprite(enemy.enemyId) case final set?
            when !FightSpriteImages.failed(set))
          (enemy, set),
    ];
    if (worn.isEmpty) return const [];
    // Each card, with a margin (an estimate: a card grows with its chips and
    // the move it announces).
    final cards = _enemies.length * 124.0;
    final animate = ref.watch(combatEffectsEnabledProvider) &&
        !_quick &&
        !MediaQuery.of(context).disableAnimations;
    // The enemies' column: six parts of eleven.
    final column = (area.maxWidth - 24 - 8) * 6 / 11;
    for (final pixel in const [3.0, 2.0, 1.0]) {
      final sizes = [
        for (final (_, set) in worn) FightFigure.sizeFor(set, pixel),
      ];
      final tallest = sizes.map((s) => s.height).reduce(max);
      final width = sizes.fold<double>(
              0, (sum, s) => sum + s.width - FightFigure.lungeReach) +
          FightFigure.lungeReach;
      if (area.maxHeight - cards < tallest + 8 || width > column + 24) {
        continue;
      }
      return [
        Positioned(
          right: 12,
          bottom: 4,
          child: IgnorePointer(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, (enemy, set)) in worn.indexed)
                  FightFigure(
                    figureKey: Key('fight_enemy_sprite_${enemy.key}'),
                    controller: _vfx,
                    anchor: _enemyCardKey(enemy.key),
                    alive: enemy.currentHealth > 0,
                    animate: animate,
                    sprite: set,
                    pixel: pixel,
                    downOpacity: 0,
                    fallback: false,
                    phase: (i * 0.37) % 1.0,
                  ),
              ],
            ),
          ),
        ),
      ];
    }
    return const [];
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
