// Who a heal mends (the user's rule, v1.663, heal_target.dart): the member
// it is aimed at, by default the most wounded one standing, the healer on a
// tie.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/heal_target.dart';

void main() {
  test('the most wounded member standing, by share of health', () {
    // The healer at 20/20, a companion at 9/30 (30%), another at 4/10 (40%).
    expect(
        defaultHealTarget([
          (current: 20, max: 20),
          (current: 9, max: 30),
          (current: 4, max: 10),
        ], 0),
        1);
  });

  test('a tie stays with the healer', () {
    expect(
        defaultHealTarget([
          (current: 5, max: 10),
          (current: 10, max: 20),
        ], 1),
        1);
    expect(
        defaultHealTarget([
          (current: 5, max: 10),
          (current: 10, max: 20),
        ], 0),
        0);
  });

  test('a member knocked out is never chosen; nobody standing is -1', () {
    expect(
        defaultHealTarget([
          (current: 18, max: 20),
          (current: 0, max: 30),
        ], 0),
        0);
    expect(defaultHealTarget([(current: 0, max: 20)], 0), -1);
    expect(defaultHealTarget(const [], 0), -1);
  });
}
