// The dice speed (v1.679): the default throw is slow enough to watch, 2x and
// 4x are the default divided by two and four, and the choice survives a
// restart.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/combat_settings_provider.dart';

void main() {
  test('2x and 4x are the default divided by 2 and 4', () {
    for (final base in [diceThrowBase, diceLandBase]) {
      expect(diceTimeFor(base, DiceSpeed.normal), base);
      expect(diceTimeFor(base, DiceSpeed.double) * 2, base);
      expect(diceTimeFor(base, DiceSpeed.quad) * 4, base);
    }
  });

  test('the default throw is slower than the old 650 ms', () {
    expect(diceThrowBase, greaterThan(const Duration(milliseconds: 650)));
    expect(DiceSpeed.values.first, DiceSpeed.normal);
  });

  test('the speed starts at 1x and survives a restart', () async {
    SharedPreferences.setMockInitialValues({});
    var container = ProviderContainer();
    expect(container.read(diceSpeedProvider), DiceSpeed.normal);
    await container.read(diceSpeedProvider.notifier).set(DiceSpeed.quad);
    expect(container.read(diceSpeedProvider), DiceSpeed.quad);
    container.dispose();

    container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(diceSpeedProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(diceSpeedProvider), DiceSpeed.quad);
  });
}
