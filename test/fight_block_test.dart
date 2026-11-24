// The fighter block of the fight board (fight_block.dart, enemy_groups.dart): an
// enemy's group is read from its own `group`, else its faction, else its kind;
// every enemy of enemies.json has one; the block fits the narrowest slot with
// the numbers in the same place, a gem hides when it is null, and a rank shows.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/enemy_groups.dart';
import 'package:narrative_data_app/widgets/enemy_groups.dart';
import 'package:narrative_data_app/widgets/fight_block.dart';

Widget _slot(Widget block, {double w = 160}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: w, height: 72, child: block),
        ),
      ),
    );

Widget _block({
  EnemyGroup? group,
  FightRank rank = FightRank.normal,
  int? armor,
  int? damage,
  String name = 'Inquisition Soldier',
}) =>
    FightBlock(
      name: name,
      plateColor: group?.color ?? Colors.teal,
      group: group,
      rank: rank,
      armor: armor,
      damage: damage,
      head: const SizedBox.shrink(),
      bar: const SizedBox(height: 14),
      chips: const [Icon(Icons.shield, size: 16), Icon(Icons.bolt, size: 16)],
      intent: const Text('Strike 6', style: TextStyle(fontSize: 8)),
    );

void main() {
  final enemies =
      jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
          as Map<String, dynamic>;

  test("every group Core names has a look; the Horn-Taker wears the Dominion's",
      () {
    for (final id in enemyGroupIds) {
      expect(enemyGroups, contains(id));
    }
    expect(groupLookOf({'group': 'dominion', 'kind': 'person'}).id, 'dominion');
  });

  test('a group is read from the enemy\'s group, else faction, else kind', () {
    expect(
        groupLookOf({'faction': 'dominion', 'kind': 'person'}).id, 'dominion');
    expect(groupLookOf({'kind': 'undead'}).id, 'undead');
    expect(groupLookOf({'kind': 'person'}).id, 'people');
    // Core's own group wins over the faction and the kind.
    expect(
        groupLookOf({'group': 'hollow_court', 'faction': '', 'kind': 'person'})
            .id,
        'hollow_court');
    // An unknown group falls through to the next field, then to the fallback.
    expect(groupLookOf({'group': 'no_such', 'kind': 'beast'}).id, 'beast');
    expect(groupLookOf({'group': 'no_such'}).id, 'people');
    expect(groupLookOf(null).id, 'people');
  });

  test('every enemy has a group, and the clans have their banners', () {
    for (final MapEntry(:key, :value) in enemies.entries) {
      final g = groupLookOf(value as Map<String, dynamic>);
      expect(enemyGroups, contains(g.id), reason: key);
    }
    for (final id in [
      'dominion',
      'crows',
      'compact',
      'mire',
      'vigil',
      'penitents'
    ]) {
      expect(enemyGroups[id]!.banner, 'clan_$id');
    }
    // Every group has a banner or a mark, and a known ornament.
    for (final g in enemyGroups.values) {
      expect(g.banner != null || g.glyph != null, isTrue, reason: g.id);
      expect(['studs', 'spikes', 'rivets', 'notches'], contains(g.ornament),
          reason: g.id);
    }
  });

  testWidgets('the block fits the narrowest slot, a boss and an elite show',
      (tester) async {
    for (final w in [136.0, 160.0, 190.0]) {
      for (final rank in FightRank.values) {
        await tester.pumpWidget(_slot(
          _block(
              group: enemyGroups['dominion'],
              rank: rank,
              armor: 2,
              name: 'Inquisitor-General Aurel Vane'),
          w: w,
        ));
        expect(tester.takeException(), isNull, reason: '$w $rank');
        // The rank's icon always shows; its word shows too while the name
        // fits on one line (a long name takes two lines and keeps the icon
        // only, #1100), and a rank never wears the other rank's word.
        expect(find.byIcon(Icons.workspace_premium),
            rank == FightRank.boss ? findsOneWidget : findsNothing);
        expect(
            find.text('BOSS'),
            rank == FightRank.boss
                ? anyOf(findsNothing, findsOneWidget)
                : findsNothing);
        expect(
            find.text('ELITE'),
            rank == FightRank.elite
                ? anyOf(findsNothing, findsOneWidget)
                : findsNothing);
      }
    }
  });

  testWidgets('a gem shows its number, and hides when it is null',
      (tester) async {
    await tester.pumpWidget(_slot(_block(armor: 3, damage: 4)));
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    await tester.pumpWidget(_slot(_block(armor: null, damage: null)));
    expect(find.byIcon(Icons.shield_outlined), findsNothing);
    expect(find.byIcon(Icons.bolt), findsOneWidget,
        reason: 'the chip, not a gem');
  });

  testWidgets('a long number shrinks to its gem', (tester) async {
    await tester.pumpWidget(_slot(_block(armor: 1234, damage: 567), w: 136));
    expect(tester.takeException(), isNull);
    expect(find.text('1234'), findsOneWidget);
  });
}
