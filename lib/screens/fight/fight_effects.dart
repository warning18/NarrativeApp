part of '../fight_screen.dart';

/// The on-screen effects: screen shake, and the effects played for
/// faces, enemy moves and spells.
extension _FightEffects on _FightScreenState {
  bool get _effectsOn => ref.read(combatEffectsEnabledProvider);

  void _triggerShake() {
    if (!ref.read(trembleEnabledProvider)) return;
    _shakeController.forward(from: 0);
  }

  /// What one party member's die looks like on screen: the face's (or its
  /// skill's) effect on the enemy it hit with the damage floating off it,
  /// a critical's starburst, the status it left, a heal, a shield or mana
  /// on the member, and a lifesteal drawn back to them.
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
    final style = styleForFace(face.type, skill);
    final support = isSupportSkill(skill);
    if (target != null) {
      final targetKey = _enemyCardKey(target.key);
      if (dealt > 0) {
        _vfx.play(
          style: support ? VfxStyle.slash : style,
          target: targetKey,
          source: actorKey,
          element: element,
          delayMs: delayMs,
          text: '-$dealt',
          textKind: result.isCritical ? VfxTextKind.crit : VfxTextKind.damage,
          big: result.isCritical,
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
      );
    }
    if (block > 0) {
      _vfx.play(
        style: VfxStyle.shield,
        target: actorKey,
        delayMs: delayMs,
        text: '+$block',
        textKind: VfxTextKind.block,
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
    _vfx.play(
      style: style,
      target: targetKey,
      source: _enemyCardKey(enemy.key),
      element: skillId.isEmpty ? 'Enemy' : element,
      delayMs: delayMs,
      text: damage > 0 ? '-$damage' : null,
      textKind: VfxTextKind.hurt,
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
