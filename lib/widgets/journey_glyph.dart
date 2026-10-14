// What a way on the Journey looks like (v1.309): its mark carries a glyph
// fitted to what the way is -- a fight with a beast is not a fight with a
// guard, a check of strength is not a check of wisdom, a forge is not an
// apothecary -- and that glyph breathes a little: a flag sways, a flame
// flickers, a boat bobs. A badge on the mark says when the way is tied to a
// quest (the main one, or a side job).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/journey_map.dart';
import '../models/story_node.dart';

/// How a glyph moves when nothing else does.
enum JourneyIdle { sway, pulse, breathe, bob, flicker, glint, tilt }

class JourneyGlyph {
  const JourneyGlyph(this.icon, this.idle);

  final IconData icon;
  final JourneyIdle idle;
}

bool _has(String? id, List<String> words) {
  final s = (id ?? '').toLowerCase();
  return s.isNotEmpty && words.any(s.contains);
}

/// The glyph of the way [choice] takes, of [kind] (see journeyStepKindOf).
JourneyGlyph journeyGlyphOf(StoryChoice choice, JourneyStepKind kind) {
  switch (kind) {
    case JourneyStepKind.ending:
      return const JourneyGlyph(Icons.auto_stories_outlined, JourneyIdle.glint);
    case JourneyStepKind.mainQuest:
      return const JourneyGlyph(Icons.flag_outlined, JourneyIdle.sway);
    case JourneyStepKind.expedition:
      final zone = choice.launchZoneId;
      if (_has(
          zone, ['cave', 'mine', 'crypt', 'undercroft', 'cellar', 'deep'])) {
        return const JourneyGlyph(
            Icons.landscape_outlined, JourneyIdle.breathe);
      }
      if (_has(zone, ['ruin', 'temple', 'spire', 'tower', 'vault'])) {
        return const JourneyGlyph(
            Icons.account_balance_outlined, JourneyIdle.glint);
      }
      if (_has(zone, ['forest', 'wood', 'grove', 'marsh', 'bog'])) {
        return const JourneyGlyph(Icons.park_outlined, JourneyIdle.sway);
      }
      if (_has(zone, ['sea', 'reef', 'wreck', 'shore', 'beach', 'coast'])) {
        return const JourneyGlyph(Icons.waves, JourneyIdle.bob);
      }
      if (_has(zone, ['desert', 'dune', 'sand', 'waste', 'ash'])) {
        return const JourneyGlyph(Icons.wb_sunny_outlined, JourneyIdle.pulse);
      }
      return const JourneyGlyph(Icons.explore_outlined, JourneyIdle.tilt);
    case JourneyStepKind.fight:
      if ((choice.shipBattleId ?? '').isNotEmpty) {
        return const JourneyGlyph(
            Icons.directions_boat_filled_outlined, JourneyIdle.bob);
      }
      final enemy = choice.triggerEnemyId ??
          (choice.triggerEnemyIds.isEmpty
              ? null
              : choice.triggerEnemyIds.first);
      if (_has(enemy, [
        'wolf',
        'hound',
        'rat',
        'beast',
        'dog',
        'boar',
        'spider',
        'serpent',
        'crab',
        'gull',
        'jaw',
        'drake',
        'wyrm'
      ])) {
        return const JourneyGlyph(Icons.pets, JourneyIdle.breathe);
      }
      if (_has(enemy, [
        'ghost',
        'wraith',
        'shade',
        'spirit',
        'void',
        'tear',
        'hollow',
        'wisp',
        'lich'
      ])) {
        return const JourneyGlyph(Icons.blur_on, JourneyIdle.flicker);
      }
      if (_has(enemy, [
        'inquisit',
        'guard',
        'blade',
        'knight',
        'captain',
        'soldier',
        'warden',
        'sentinel'
      ])) {
        return const JourneyGlyph(Icons.shield_outlined, JourneyIdle.glint);
      }
      if (_has(enemy, ['archer', 'sniper', 'hunter'])) {
        return const JourneyGlyph(Icons.gps_fixed, JourneyIdle.pulse);
      }
      return const JourneyGlyph(Icons.sports_martial_arts, JourneyIdle.pulse);
    case JourneyStepKind.challenge:
      return const JourneyGlyph(Icons.casino, JourneyIdle.tilt);
    case JourneyStepKind.check:
      return switch (choice.checkAbility) {
        'strength' =>
          const JourneyGlyph(Icons.fitness_center, JourneyIdle.pulse),
        'dexterity' =>
          const JourneyGlyph(Icons.sports_gymnastics, JourneyIdle.sway),
        'constitution' =>
          const JourneyGlyph(Icons.favorite_border, JourneyIdle.pulse),
        'intelligence' =>
          const JourneyGlyph(Icons.psychology_outlined, JourneyIdle.glint),
        'wisdom' =>
          const JourneyGlyph(Icons.visibility_outlined, JourneyIdle.breathe),
        'charisma' => const JourneyGlyph(
            Icons.record_voice_over_outlined, JourneyIdle.sway),
        'perception' => const JourneyGlyph(Icons.search, JourneyIdle.tilt),
        _ => const JourneyGlyph(Icons.casino_outlined, JourneyIdle.tilt),
      };
    case JourneyStepKind.shop:
      final shop = choice.unlockShopId;
      if (_has(
          shop, ['forge', 'smith', 'armor', 'armour', 'weapon', 'hammer'])) {
        return const JourneyGlyph(Icons.hardware_outlined, JourneyIdle.glint);
      }
      if (_has(shop, ['apothec', 'herb', 'potion', 'alchem', 'remed'])) {
        return const JourneyGlyph(Icons.science_outlined, JourneyIdle.bob);
      }
      if (_has(
          shop, ['arcane', 'bazaar', 'bazar', 'magic', 'rune', 'occult'])) {
        return const JourneyGlyph(Icons.auto_awesome, JourneyIdle.glint);
      }
      if (_has(
          shop, ['ship', 'chandler', 'harbor', 'harbour', 'dock', 'wharf'])) {
        return const JourneyGlyph(Icons.anchor, JourneyIdle.sway);
      }
      return const JourneyGlyph(Icons.storefront_outlined, JourneyIdle.sway);
    case JourneyStepKind.quest:
      return const JourneyGlyph(Icons.chat_bubble_outline, JourneyIdle.bob);
    case JourneyStepKind.travel:
      return const JourneyGlyph(Icons.sailing_outlined, JourneyIdle.bob);
    case JourneyStepKind.rest:
      return _has(choice.nextId, ['camp', 'fire'])
          ? const JourneyGlyph(
              Icons.local_fire_department_outlined, JourneyIdle.flicker)
          : const JourneyGlyph(Icons.bedtime_outlined, JourneyIdle.breathe);
    case JourneyStepKind.road:
      return const JourneyGlyph(Icons.signpost_outlined, JourneyIdle.sway);
  }
}

/// A glyph's idle motion at [t] seconds (the common period is twelve), for a
/// mark that starts [phase] seconds in.
Widget journeyIdleGlyph({
  required JourneyGlyph glyph,
  required Color colour,
  required double t,
  double phase = 0,
  double size = 20,
}) {
  double wave(double period, [double shift = 0]) =>
      math.sin(2 * math.pi * ((t + phase) / period + shift));
  Widget icon([Color? c, double? s]) =>
      Icon(glyph.icon, size: s ?? size, color: c ?? colour);
  switch (glyph.idle) {
    case JourneyIdle.sway:
      return Transform.rotate(
          angle: wave(3) * 0.14,
          alignment: Alignment.bottomCenter,
          child: icon());
    case JourneyIdle.tilt:
      // A slow swing, then a pause.
      final k = ((t + phase) % 6) / 6;
      final a = k < 0.5 ? math.sin(k / 0.5 * 2 * math.pi) * 0.3 : 0.0;
      return Transform.rotate(angle: a, child: icon());
    case JourneyIdle.pulse:
      return Transform.scale(scale: 1 + wave(2) * 0.08, child: icon());
    case JourneyIdle.breathe:
      return Opacity(
          opacity: 0.8 + 0.2 * (0.5 + 0.5 * wave(4)),
          child: Transform.scale(scale: 1 + wave(4) * 0.05, child: icon()));
    case JourneyIdle.bob:
      return Transform.translate(
          offset: Offset(0, wave(3) * 1.6), child: icon());
    case JourneyIdle.flicker:
      final f = 0.5 * wave(1.5) + 0.3 * wave(1, 0.3) + 0.2 * wave(0.75, 0.6);
      return Opacity(
          opacity: 0.78 + 0.22 * (0.5 + 0.5 * f),
          child: Transform.scale(scale: 1 + f * 0.07, child: icon()));
    case JourneyIdle.glint:
      // Bright for half a second every four.
      final k = ((t + phase) % 4) / 4;
      final lit = k < 0.12 ? math.sin(k / 0.12 * math.pi) : 0.0;
      return icon(Color.lerp(colour, Colors.white, lit * 0.8));
  }
}

/// How a way is tied to a quest: the main one, or a side job.
enum JourneyQuestTie { main, side }

/// Whether [choice] is tied to a quest: it is the main quest's way on, it
/// carries a quest forward that is under way, or it offers one not taken
/// yet. [mainIds] are the quests of the main quest.
JourneyQuestTie? journeyQuestTieOf(
  StoryChoice choice, {
  required Set<String> active,
  required Set<String> done,
  required Set<String> mainIds,
}) {
  if (choice.mainQuest) return JourneyQuestTie.main;
  JourneyQuestTie of(String id) =>
      mainIds.contains(id) ? JourneyQuestTie.main : JourneyQuestTie.side;
  final progress = choice.questIDToProgress;
  if (progress != null && progress.isNotEmpty && active.contains(progress)) {
    return of(progress);
  }
  final offered = choice.unlockQuestId;
  if (offered != null &&
      offered.isNotEmpty &&
      !active.contains(offered) &&
      !done.contains(offered)) {
    return of(offered);
  }
  return null;
}
