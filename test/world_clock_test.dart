// The world clock (v1.178): days and watches pass on the road and at sea,
// a rest runs to dawn, and the time is kept with the save.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/moments.dart';

void main() {
  test('a new session starts on day 1 in daytime', () {
    final session = PlayerSession.fromJson(const {});
    expect(session.day, 1);
    expect(session.watch, 1);
  });

  test('the day and the watch are saved and read back, kept in range', () {
    final session = PlayerSession.fromJson(const {}).copyWith(day: 7, watch: 3);
    final back = PlayerSession.fromJson(session.toJson());
    expect(back.day, 7);
    expect(back.watch, 3);
    final odd = PlayerSession.fromJson(const {'day': 0, 'watch': 9});
    expect(odd.day, 1);
    expect(odd.watch, 3);
  });

  test('time passes watch by watch into the next days; a rest ends at dawn',
      () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(playerSessionProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await notifier.loadSession(PlayerSession.fromJson(const {}));

    await notifier.passTime(2); // daytime -> night
    expect(container.read(playerSessionProvider).day, 1);
    expect(container.read(playerSessionProvider).watch, 3);

    await notifier.passTime(4); // a whole day at sea
    expect(container.read(playerSessionProvider).day, 2);
    expect(container.read(playerSessionProvider).watch, 3);

    await notifier.passTime(0);
    expect(container.read(playerSessionProvider).watch, 3);

    await notifier.restUntilDawn();
    expect(container.read(playerSessionProvider).day, 3);
    expect(container.read(playerSessionProvider).watch, 0);
  });

  testWidgets('the sky over the town: clear by day, starred at night',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: WatchSky(watch: 1),
      ),
    ));
    expect(find.byKey(const Key('watch_sky_1')), findsNothing);
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: WatchSky(watch: 3),
      ),
    ));
    expect(find.byKey(const Key('watch_sky_3')), findsOneWidget);
  });
}
