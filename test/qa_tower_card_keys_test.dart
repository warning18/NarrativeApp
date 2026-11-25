// QA guard (the Tower's tarot cards, v2.3.0): the art hook covers every key
// the game's data can ask for. Every element a skill has, every family a
// spell's effect maps to, every die size, every rarity: each has Art's picture
// (or its seal / icon), declared in the bundle, so no card ever falls back to a
// stand-in or to nothing without a test saying so. Pure data; no screen.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/screens/tower/tower_card_art.dart';

Map<String, dynamic> _data(String name) =>
    json.decode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

Iterable<Map<String, dynamic>> _records(String name) => [
      for (final v in _data(name).values)
        if (v is Map<String, dynamic>) v
    ];

void main() {
  test('every skill element has Art\'s vignette', () {
    final elements = {for (final s in _records('skills')) '${s['element']}'};
    expect(elements, isNotEmpty);
    for (final e in elements) {
      expect(towerCardArt.containsKey('skill:$e'), isTrue,
          reason: 'a skill of element $e has no vignette in towerCardArt');
      expect(File(towerCardArt['skill:$e']!).existsSync(), isTrue, reason: e);
    }
  });

  test('every spell effect maps to one of Art\'s four families', () {
    final families = {
      for (final s in _records('spells')) towerSpellFamily('${s['effect']}')
    };
    expect(families, isNotEmpty);
    for (final f in families) {
      expect(towerCardArt.containsKey('spell:$f'), isTrue,
          reason: 'family $f has no vignette in towerCardArt');
    }
  });

  test('every rarity of a skill has its seal, and a die has none', () {
    final rarities = {for (final s in _records('skills')) '${s['rarity']}'};
    for (final r in rarities) {
      final i = towerRarityIndex(r);
      expect(i, isNotNull, reason: 'rarity "$r" has no seal');
      expect(File('$towerCardsDir/seal_${i! + 1}dots.png').existsSync(), isTrue,
          reason: 'the seal of $r');
    }
    expect(rarities.length, 5);
    expect(towerRarityIndex(null), isNull);
  });

  test('every die size has the bone icon the card shows', () {
    final sizes = {
      for (final d in _records('dice')) (d['faces'] as List).length
    };
    final missing = <int>{};
    for (final n in sizes) {
      final path = towerCardIcon('die', 'any', faces: n);
      expect(path, isNotNull, reason: 'd$n');
      if (!File(path!).existsSync()) missing.add(n);
    }
    // The d10's came with #1144 (Art's die_d10_bone_44.png).
    expect(missing, isEmpty, reason: 'the die sizes with no bone picture');
  });

  test('every kind has a stand-in and the frame, seal and stamp are there', () {
    for (final k in const ['skill', 'die', 'spell', 'oath']) {
      expect(File(towerCardStandIn[k]!).existsSync(), isTrue, reason: k);
    }
    for (final f in [towerCardFrame, towerCardSealBlank, towerCardStamp]) {
      expect(File(f).existsSync(), isTrue, reason: f);
    }
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('$towerCardsDir/'));
    for (final path in towerCardStandIn.values) {
      expect(pubspec, contains(path.substring(0, path.lastIndexOf('/') + 1)),
          reason: '$path is not in a declared asset folder');
    }
  });
}
