// What the stat picks (lib/widgets/stat_pick_picker.dart) show of a training
// path's gains: a stat's label and colour, a path's pixel art, and where a
// stat stands now.
import 'package:flutter/material.dart';

import '../providers/player_session_provider.dart';
import '../theme/stitched_ink.dart';

/// The label key of a training gain's stat.
String trainingStatLabelKey(String stat) => switch (stat) {
      'baseDamage' => 'base_damage_label',
      'baseArmor' => 'base_armor_label',
      'maxHealth' => 'max_health_label',
      _ => '${stat}_label',
    };

/// What a stat is worth to the eye: attack burns, defence and health run
/// cool, the mind goes violet, the quick are green, the social gold.
Color trainingStatColor(String stat, InkColors ink) => switch (stat) {
      'baseDamage' || 'strength' => ink.ember,
      'baseArmor' || 'maxHealth' || 'constitution' => ink.tide,
      'intelligence' || 'wisdom' => ink.voidColor,
      'dexterity' || 'perception' || 'luck' => ink.heal,
      _ => ink.gold,
    };

/// The pixel art of a path (training_paths.json's `icon`): the item of the
/// game that stands for it, drawn the way the pack shows it.
String trainingPathItem(String icon) => switch (icon) {
      'fist' || 'knuckles' => 'thug_knuckle_wrap',
      'blade' => 'dagger_t1',
      'shield' => 'shield_t3',
      'tower' => 'shield_t4',
      'book' => 'spellbook_ember_wave',
      'sun' => 'spellbook_sanctified_ground',
      'feather' => 'spellbook_smoke_veil',
      'bow' => 'spellbook_arrow_volley',
      'scroll' => 'scroll_fireball',
      _ => 'tome_of_insight',
    };

/// The stat's value on [s] now (the gains' "before").
int trainingStatNow(PlayerSession s, String stat) => switch (stat) {
      'baseDamage' => s.baseDamage,
      'baseArmor' => s.baseArmor,
      'maxHealth' => s.maxHealth,
      'strength' => s.strength,
      'dexterity' => s.dexterity,
      'constitution' => s.constitution,
      'intelligence' => s.intelligence,
      'wisdom' => s.wisdom,
      'perception' => s.perception,
      'luck' => s.luck,
      'charisma' => s.charisma,
      _ => 0,
    };
