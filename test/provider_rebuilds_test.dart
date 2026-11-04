// P4 (docs/proposals/core-improvements.md): providers that watched the
// whole session for a small value told everything below them to rebuild
// on every change. A change that leaves their value the same now notifies
// nobody: the count of notifications over five such changes is pinned.
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/offers_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/tab_badges_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'five session changes that move no badge and no clan effect notify '
      'neither provider', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(playerSessionProvider.notifier);
    while (!notifier.isLoaded) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    var badges = 0;
    var clan = 0;
    container.listen(tabBadgesProvider, (_, __) => badges++);
    container.listen(clanEffectsProvider, (_, __) => clan++);
    // Let the tables load, so their arrival is not counted.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    badges = 0;
    clan = 0;

    for (var i = 0; i < 5; i++) {
      await notifier
          .applyChoiceEffects(flagsToAdd: ['p4_probe_$i'], goldIsProfit: false);
      await Future<void>.delayed(Duration.zero);
      container.read(tabBadgesProvider);
      container.read(clanEffectsProvider);
    }
    expect(container.read(playerSessionProvider).flags, contains('p4_probe_4'));
    // ignore: avoid_print
    print('P4 notifications over 5 changes: badges $badges, clan $clan');
    expect(badges, 0);
    expect(clan, 0);
  });

  test('a change they read still reaches them', () async {
    SharedPreferences.setMockInitialValues({
      'player_session': json.encode({
        'raceId': 'human',
        'professionId': 'warrior',
        'statPoints': 1,
        'heldTitleIds': ['title_a', 'title_b'],
        'activeTitleId': 'title_a',
      }),
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(playerSessionProvider.notifier);
    while (!notifier.isLoaded) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    var clan = 0;
    container.listen(clanEffectsProvider, (_, __) => clan++);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    clan = 0;
    // A point to spend lights the Character tab.
    expect(container.read(tabBadgesProvider).character, isTrue);
    // Wearing another title is read by the clan effects.
    await notifier.setActiveTitle('title_b');
    await Future<void>.delayed(Duration.zero);
    container.read(clanEffectsProvider);
    expect(clan, 1);
  });
}
