// A town changing hands (wave 16, UX): the save remembers who ruled each
// town when the world chart was last looked at; a town whose ruler is
// another now fades its tint to the new colour and says so in a toast.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/map_charts.dart' show ChartPalette;
import 'package:narrative_data_app/data/town_rulers.dart';
import 'package:narrative_data_app/data/world_map.dart' show MapLook;
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/providers/town_rulers_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';
import 'package:narrative_data_app/widgets/town_handover.dart';

TownRuler _town(String id, String clan, {bool district = false}) => TownRuler(
      placeId: id,
      cityId: district ? 'candlehold' : id,
      clanId: clan,
      source: clan.isEmpty ? TownRulerSource.none : TownRulerSource.own,
      color: 0xFF336699,
      accent: shadeColor(0xFF336699),
      isDistrict: district,
    );

void main() {
  test('a town with another ruler than the one seen has changed hands', () {
    final rulers = {
      'candlehold': _town('candlehold', 'crows'),
      'emberwick': _town('emberwick', 'compact'),
      'saltmouth': _town('saltmouth', ''),
      'newtown': _town('newtown', 'vigil'),
      // A district changing alone is not a town changing hands.
      'gate': _town('gate', 'crows', district: true),
    };
    final seen = {
      'candlehold': 'dominion',
      'emberwick': 'compact',
      'saltmouth': 'tidekin',
      'gate': 'dominion',
    };
    final changed = townHandovers(seen, rulers);
    expect({
      for (final h in changed) h.townId: (h.fromClan, h.toClan)
    }, {
      'candlehold': ('dominion', 'crows'),
      'saltmouth': ('tidekin', ''),
    });
  });

  test('a save that has seen none, or a town it never saw, changes nothing',
      () {
    final rulers = {'candlehold': _town('candlehold', 'crows')};
    expect(townHandovers(const {}, rulers), isEmpty);
    expect(townHandovers({'elsewhere': 'dominion'}, rulers), isEmpty);
    expect(
        townRulerIds({...rulers, 'gate': _town('gate', 'x', district: true)}),
        {'candlehold': 'crows'});
  });

  test('the old ruler\'s colours: the clan\'s fill and a darker outline', () {
    const h = TownHandover('candlehold', 'dominion', 'crows');
    final colours = handoverFromColours(h, {'dominion': 0xFF8844AA});
    expect(colours!.fill, 0xFF8844AA);
    expect(colours.accent, shadeColor(0xFF8844AA));
    // A town no one ruled before fades in from nothing.
    expect(handoverFromColours(const TownHandover('t', '', 'crows'), const {}),
        isNull);
  });

  test('the session remembers the rulers it saw, and an old save has none', () {
    final session = PlayerSession.fromJson({
      'seenTownRulers': {'candlehold': 'dominion'},
    });
    expect(session.seenTownRulers, {'candlehold': 'dominion'});
    expect(PlayerSession.fromJson(session.toJson()).seenTownRulers,
        {'candlehold': 'dominion'});
    expect(PlayerSession.fromJson(const {}).seenTownRulers, isEmpty);
  });

  testWidgets(
      'the world chart says so when a town changed hands since it was seen',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      // Everything is read in real time: the save and the tables load by
      // futures the test's fake clock would hold back.
      final notifier = container.read(playerSessionProvider.notifier);
      // Listened to in real time, so the tables behind it load (the story,
      // the geography, the clans, the plans).
      final sub = container.listen(townRulersProvider, (_, __) {});
      addTearDown(sub.close);
      await container.read(storyDataProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      // The player last saw Candlehold in the Compact's hands.
      await notifier.loadSession(container
          .read(playerSessionProvider)
          .copyWith(seenTownRulers: {'candlehold': 'compact'}));
    });
    expect(
        container.read(townRulersProvider)['candlehold']?.clanId, 'dominion');
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(ColorScheme.fromSeed(
            seedColor: Colors.amber, brightness: Brightness.dark)),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 560,
            child: JourneyWorldMap(
              level: JourneyMapLevel.world,
              palette: ChartPalette.of(MapLook.night),
              here: null,
              discovered: const {},
              legs: const [],
              ahead: null,
              shopPlaces: const {},
              campPlaces: const {},
              chapterColor: (_) => Colors.amber,
              onLayers: () {},
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('town_handover_toast')), findsOneWidget);
    expect(find.textContaining('Candlehold'), findsOneWidget);
    // Written down: seen as it is now, so it says so only once.
    expect(container.read(playerSessionProvider).seenTownRulers['candlehold'],
        'dominion');
    // The fade runs to its end without trouble.
    await tester.pump(const Duration(milliseconds: 1500));
    expect(tester.takeException(), isNull);
  });
}
