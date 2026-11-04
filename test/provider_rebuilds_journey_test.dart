// P4, part 2 (docs/proposals/core-improvements.md): the Journey's providers
// that watched the whole session (or the whole story state) for a few
// fields. A change that leaves those fields alone now notifies nobody.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/walking_party_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'five session changes that touch no roll, ward or companion notify '
      'none of the three', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(playerSessionProvider.notifier);
    while (!notifier.isLoaded) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final counts = {'campRolls': 0, 'roadWards': 0, 'walkingParty': 0};
    container.listen(campRollsProvider,
        (_, __) => counts['campRolls'] = counts['campRolls']! + 1);
    container.listen(roadWardsProvider,
        (_, __) => counts['roadWards'] = counts['roadWards']! + 1);
    container.listen(walkingPartyProvider,
        (_, __) => counts['walkingParty'] = counts['walkingParty']! + 1);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    counts.updateAll((_, __) => 0);

    for (var i = 0; i < 5; i++) {
      await notifier
          .applyChoiceEffects(flagsToAdd: ['p4_probe_$i'], goldIsProfit: false);
      await Future<void>.delayed(Duration.zero);
      container.read(campRollsProvider);
      container.read(roadWardsProvider);
      container.read(walkingPartyProvider);
    }
    expect(container.read(playerSessionProvider).flags, contains('p4_probe_4'));
    // ignore: avoid_print
    print('P4 journey notifications over 5 changes: $counts');
    expect(counts.values, everyElement(0));
  });
}
