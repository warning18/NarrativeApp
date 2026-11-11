// The fighters standing on the fight board (v1.911, fight_figures.dart): the
// hero and the allies on the left, the foes on the right, a fighter with no
// sprite left out, and the row sized for the board's width.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/fight_figures.dart';

Widget _row(List<String> allies, List<String> foes, {double w = 400}) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: w,
          child: FightFigures(
              allies: allies, foes: foes, height: fightFigureHeight(w)),
        ),
      ),
    );

void main() {
  testWidgets('the hero stands left, the foes right, in order', (tester) async {
    await tester
        .pumpWidget(_row(['hero', 'kelda'], ['rat_matriarch', 'harbor_rat']));
    await tester.pump();
    final hero = tester.getCenter(find.byKey(const Key('fight_figure_hero')));
    final kelda = tester.getCenter(find.byKey(const Key('fight_figure_kelda')));
    final boss =
        tester.getCenter(find.byKey(const Key('fight_figure_rat_matriarch')));
    final rat =
        tester.getCenter(find.byKey(const Key('fight_figure_harbor_rat')));
    expect(hero.dx, lessThan(kelda.dx));
    expect(kelda.dx, lessThan(boss.dx));
    expect(boss.dx, lessThan(rat.dx));
    expect(tester.getSize(find.byKey(const Key('fight_figures'))).height,
        fightFigureHeight(400));
  });

  testWidgets('a fighter with no sprite draws nothing, the others stay',
      (tester) async {
    await tester.pumpWidget(_row(['hero'], ['no_such_enemy', 'rat_matriarch']));
    await tester.pump();
    expect(find.byKey(const Key('fight_figure_no_such_enemy')), findsNothing);
    expect(find.byKey(const Key('fight_figure_rat_matriarch')), findsOneWidget);
    expect(find.byKey(const Key('fight_figure_hero')), findsOneWidget);
  });

  testWidgets('six figures fit a 320 px board without overflow',
      (tester) async {
    await tester.pumpWidget(_row([
      'hero',
      'kelda',
      'sable'
    ], [
      'rat_matriarch',
      'harbor_rat',
      'plague_hound'
    ], w: 320));
    await tester.pump();
    expect(tester.takeException(), isNull);
    final box = tester.getRect(find.byKey(const Key('fight_figures')));
    for (final id in [
      'hero',
      'kelda',
      'sable',
      'rat_matriarch',
      'harbor_rat',
      'plague_hound'
    ]) {
      final r = tester.getRect(find.byKey(Key('fight_figure_$id')));
      expect(r.left, greaterThanOrEqualTo(box.left - 0.5), reason: id);
      expect(r.right, lessThanOrEqualTo(box.right + 0.5), reason: id);
    }
  });

  test('the row is 62 tall at 412, 54 at 360, 46 at 320', () {
    expect(fightFigureHeight(412), 62);
    expect(fightFigureHeight(360), 54);
    expect(fightFigureHeight(320), 46);
  });
}
