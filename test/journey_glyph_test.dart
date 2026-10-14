// What a way on the Journey looks like (lib/widgets/journey_glyph.dart): a
// glyph fitted to what the way is, an idle motion for it, and the quest
// badge.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/journey_map.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/widgets/journey_glyph.dart';

StoryChoice _choice(Map<String, dynamic> json) =>
    StoryChoice.fromJson({'text': 'Go', 'next_id': '100', ...json});

JourneyGlyph _glyph(Map<String, dynamic> json) {
  final c = _choice(json);
  return journeyGlyphOf(c, journeyStepKindOf(c));
}

void main() {
  test('ways of one kind look different by what they are', () {
    // Fights.
    expect(_glyph({'triggerEnemyId': 'harbor_rat'}).icon, Icons.pets);
    expect(_glyph({'triggerEnemyId': 'inquisition_blade'}).icon,
        Icons.shield_outlined);
    expect(_glyph({'triggerEnemyId': 'void_wraith'}).icon, Icons.blur_on);
    expect(_glyph({'triggerEnemyId': 'slum_thug'}).icon,
        Icons.sports_martial_arts);
    // Checks, by ability.
    final checks = {
      for (final a in [
        'strength',
        'dexterity',
        'constitution',
        'intelligence',
        'wisdom',
        'charisma',
        'perception',
        'luck',
      ])
        a: _glyph({'checkAbility': a}).icon,
    };
    expect(checks.values.toSet().length, checks.length,
        reason: 'every ability has its own glyph');
    // Shops.
    expect(_glyph({'unlockShopId': 'hammersmith_forge'}).icon,
        Icons.hardware_outlined);
    expect(_glyph({'unlockShopId': 'apothecary_row'}).icon,
        Icons.science_outlined);
    expect(_glyph({'unlockShopId': 'shop_a'}).icon, Icons.storefront_outlined);
    // Expeditions.
    expect(_glyph({'launchZoneId': 'z_old_mill'}).icon, Icons.explore_outlined);
    expect(
        _glyph({'launchZoneId': 'z_salt_cave'}).icon, Icons.landscape_outlined);
    // The plain ones keep theirs.
    expect(_glyph({}).icon, Icons.signpost_outlined);
    expect(_glyph({'mainQuest': true}).icon, Icons.flag_outlined);
  });

  testWidgets('every glyph moves a little and none moves far', (tester) async {
    for (final idle in JourneyIdle.values) {
      final glyph = JourneyGlyph(Icons.flag, idle);
      for (final t in [0.0, 0.3, 1.1, 2.5, 4.05, 7.9]) {
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: journeyIdleGlyph(
                glyph: glyph, colour: Colors.red, t: t, phase: 0.9),
          ),
        ));
        expect(tester.takeException(), isNull, reason: '$idle at $t');
        expect(find.byIcon(Icons.flag), findsOneWidget);
      }
    }
  });

  test('a way is tied to a quest when it is, offers or carries one', () {
    const none = <String>{};
    JourneyQuestTie? tie(Map<String, dynamic> json,
            {Set<String> active = none,
            Set<String> done = none,
            Set<String> main = const {'q_main'}}) =>
        journeyQuestTieOf(_choice(json),
            active: active, done: done, mainIds: main);
    expect(tie({}), isNull);
    expect(tie({'mainQuest': true}), JourneyQuestTie.main);
    // A way offering a quest not taken yet.
    expect(tie({'unlockQuestId': 'q_side'}), JourneyQuestTie.side);
    expect(tie({'unlockQuestId': 'q_main'}), JourneyQuestTie.main);
    expect(tie({'unlockQuestId': 'q_side'}, active: {'q_side'}), isNull);
    expect(tie({'unlockQuestId': 'q_side'}, done: {'q_side'}), isNull);
    // A way that carries a quest under way forward.
    expect(tie({'questIDToProgress': 'q_side'}, active: {'q_side'}),
        JourneyQuestTie.side);
    expect(tie({'questIDToProgress': 'q_main'}, active: {'q_main'}),
        JourneyQuestTie.main);
    expect(tie({'questIDToProgress': 'q_side'}), isNull);
  });

  test('the glyph table covers every kind, and ids of the real story map', () {
    for (final kind in JourneyStepKind.values) {
      final g = journeyGlyphOf(_choice({}), kind);
      expect(g.icon, isNotNull, reason: kind.name);
    }
    // Real shop ids resolve to something (a forge, a stall...).
    final shops =
        jsonDecode(File('assets/gamedata/shops.json').readAsStringSync())
            as Map;
    final glyphs = {
      for (final id in shops.keys)
        id.toString(): _glyph({'unlockShopId': id.toString()}).icon,
    };
    expect(glyphs.values.toSet().length, greaterThan(1),
        reason: 'the shops are not all one glyph');
  });
}
