// The marks on a foe's nameplate never overflow it (v1.996): the longest foe
// names, in English and French, with the group emblem, three marks and a boss
// rank, on a slot as narrow as a 320 dp phone gives (about 143 dp). A name
// that cannot stay readable beside its marks sends them to the chip row.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/utils/game_icons.dart';
import 'package:narrative_data_app/widgets/enemy_groups.dart';
import 'package:narrative_data_app/widgets/fight_block.dart';

void main() {
  final enemies =
      jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
          as Map<String, dynamic>;
  String longest(String key) => [
        for (final e in enemies.values) (e as Map)[key]?.toString() ?? '',
      ].reduce((a, b) => a.length >= b.length ? a : b);

  Widget slot(String name, double width,
          {required int marks, FightRank rank = FightRank.boss}) =>
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              height: 86,
              child: FightBlock(
                name: name,
                plateColor: Colors.blue,
                group: enemyGroups['dominion'],
                rank: rank,
                marks: [
                  for (var i = 0; i < marks; i++)
                    FightMark(
                        icon: elementIcon(i == 0 ? 'Light' : 'Fire'),
                        text: i == 2 ? '×½' : '×3',
                        weak: i != 2),
                ],
                head: const SizedBox(),
                bar: const SizedBox(height: 10),
              ),
            ),
          ),
        ),
      );

  for (final width in [143.0, 163.0]) {
    for (final key in ['enemyName', 'enemyName_fr']) {
      testWidgets('the longest $key with 3 marks and a boss rank at $width',
          (tester) async {
        await tester.pumpWidget(slot(longest(key), width, marks: 3));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
      'a short name keeps its marks on the plate, a long one drops them',
      (tester) async {
    await tester.pumpWidget(slot('Rat', 163, marks: 2, rank: FightRank.normal));
    final rect =
        tester.getRect(find.byKey(const Key('fight_block_Rat_dominion')));
    final mark = find
        .byWidgetPredicate((w) => w.key.toString().contains('fight_mark_weak'))
        .first;
    expect(tester.getRect(mark).top, lessThan(rect.top + 24));
    final longName = longest('enemyName');
    await tester.pumpWidget(slot(longName, 143, marks: 3));
    final block = find.byKey(Key('fight_block_${longName}_dominion'));
    final mark2 = find
        .byWidgetPredicate((w) => w.key.toString().contains('fight_mark_weak'))
        .first;
    expect(
        tester.getRect(mark2).top, greaterThan(tester.getRect(block).top + 24));
  });
}
