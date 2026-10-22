// Wave 16 hooks for UX and Narrative: the part of the day (the town drawn
// at the hour), the foes that get a fight entrance card, a companion's word
// at sea, and the events' `anyPowerAtLeast` condition.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/companion_remarks.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/journey_rules.dart';
import 'package:narrative_data_app/data/politics_events.dart';
import 'package:narrative_data_app/models/ally_state.dart';
import 'package:narrative_data_app/providers/day_phase_provider.dart';
import 'package:narrative_data_app/providers/moment_remark_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/remark_provider.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

PlayerSession _session(Map<String, dynamic> json) => PlayerSession.fromJson(
    {'raceId': 'human', 'professionId': 'warrior', ...json});

PlayerSession _roundTrip(PlayerSession s) => PlayerSession.fromJson(
    jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);

AllyState _ally(String id) =>
    AllyState(companionId: id, currentHealth: AllyState.fullHealthSentinel);

Map<String, dynamic> _seaLines(String id) => {
      '${id}_atSea': {
        'companionID': id,
        'trigger': 'atSea',
        'lines': ['$id at sea, one', '$id at sea, two'],
        'lines_fr': ['$id en mer, un', '$id en mer, deux'],
      },
    };

void main() {
  group('the part of the day', () {
    test('each watch is a phase and an hour', () {
      expect([for (var w = 0; w < 4; w++) dayPhaseOf(w)],
          [DayPhase.dawn, DayPhase.day, DayPhase.dusk, DayPhase.night]);
      expect([for (var w = 0; w < 4; w++) hourOfWatch(w)], [6, 12, 18, 0]);
      // Out of range is kept in it.
      expect(dayPhaseOf(9), DayPhase.night);
      expect(dayPhaseOf(-1), DayPhase.dawn);
    });

    test('the session shows it, saves it, and an old save is at day', () {
      final dusk = _session({'day': 4, 'watch': 2});
      expect(dusk.dayPhase, DayPhase.dusk);
      expect(dusk.hourOfDay, 18);
      expect(_roundTrip(dusk).dayPhase, DayPhase.dusk);
      final old = _session({});
      expect(old.dayPhase, DayPhase.day);
      expect(old.hourOfDay, 12);
    });

    test('the providers follow the clock', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = PlayerSessionNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await notifier.loadSession(_session({'day': 2, 'watch': 1}));
      final container = ProviderContainer(overrides: [
        playerSessionProvider.overrideWith((ref) => notifier),
      ]);
      addTearDown(container.dispose);
      expect(container.read(dayPhaseProvider), DayPhase.day);
      expect(container.read(hourOfDayProvider), 12);
      await notifier.passTime(2);
      expect(container.read(dayPhaseProvider), DayPhase.night);
      expect(container.read(hourOfDayProvider), 0);
      await notifier.restUntilDawn();
      expect(container.read(dayPhaseProvider), DayPhase.dawn);
    });
  });

  group('the entrance card', () {
    final enemies = _table('enemies');

    test('every boss has one, an ordinary foe none', () {
      final bosses = [
        for (final e in enemies.entries)
          if (isBossEnemy(e.key, e.value as Map<String, dynamic>)) e.key,
      ];
      expect(bosses, isNotEmpty);
      for (final id in bosses) {
        expect(hasEntranceCard(id, enemies[id] as Map<String, dynamic>), isTrue,
            reason: id);
      }
      expect(
          hasEntranceCard(
              'slum_thug', enemies['slum_thug'] as Map<String, dynamic>),
          isFalse);
    });

    test('a foe marked entranceCard has one', () {
      final thug = {
        ...enemies['slum_thug'] as Map<String, dynamic>,
        'entranceCard': true,
      };
      expect(hasEntranceCard('slum_thug', thug), isTrue);
      expect(hasEntranceCard('x', const {'entranceCard': false}), isFalse);
    });
  });

  group('a word at sea', () {
    test('a kind a record may have, silent with no lines', () {
      expect(remarkTriggerOptions, contains('atSea'));
      final said = momentRemark(RemarkBook.empty, const RemarkMemory(),
          const ['maren'], RemarkKind.atSea);
      expect(said.remark, isNull);
    });

    test('once a chapter', () {
      expect(seaRemarkDue(3, 0), isTrue);
      expect(seaRemarkDue(3, 3), isFalse);
      expect(seaRemarkDue(4, 3), isTrue);
    });

    test('the chapter is saved; an old save has had none', () {
      final s = _session({'seaRemarkChapter': 4});
      expect(_roundTrip(s).seaRemarkChapter, 4);
      expect(_session({}).seaRemarkChapter, 0);
      expect(_session({}).toJson().containsKey('seaRemarkChapter'), isFalse);
    });

    testWidgets('speakUpAtSea speaks once a chapter, and waits for lines',
        (tester) async {
      late PlayerSessionNotifier notifier;
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({});
        notifier = PlayerSessionNotifier();
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await notifier.loadSession(_session({
          'recruitedAllies': [_ally('maren').toJson()],
          'activeAllyIds': ['maren'],
        }));
      });
      var book = RemarkBook.empty;
      late WidgetRef widgetRef;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          playerSessionProvider.overrideWith((ref) => notifier),
          remarkBookProvider.overrideWith((ref) => book),
        ],
        child: Consumer(builder: (context, ref, _) {
          widgetRef = ref;
          return const SizedBox();
        }),
      ));

      // No lines yet: silent, and the chapter's turn is not used.
      expect(speakUpAtSea(widgetRef, chapter: 3), isNull);
      expect(notifier.state.seaRemarkChapter, 0);

      // Narrative's lines arrive.
      book = RemarkBook(_seaLines('maren'));
      widgetRef.invalidate(remarkBookProvider);
      CompanionRemark? first;
      await tester.runAsync(() async {
        first = speakUpAtSea(widgetRef, chapter: 3);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      expect(first?.companionId, 'maren');
      expect(first?.kind, RemarkKind.atSea);
      expect(notifier.state.seaRemarkChapter, 3);
      // The chapter's next voyage is quiet; the next chapter's speaks.
      expect(speakUpAtSea(widgetRef, chapter: 3), isNull);
      await tester.runAsync(() async {
        expect(speakUpAtSea(widgetRef, chapter: 4)?.companionId, 'maren');
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      expect(notifier.state.seaRemarkChapter, 4);
    });
  });

  group('anyPowerAtLeast', () {
    final data = ClanData.fromTables(
      factions: _table('factions'),
      subclans: _table('subclans'),
      relations: _table('relations'),
      titles: _table('titles'),
    );
    const mains = [
      'dominion',
      'vigil',
      'compact',
      'mire',
      'crows',
      'penitents'
    ];
    PoliticsState all(int power) => PoliticsState.empty
        .copyWith(power: {for (final id in mains) id: power});

    test('the strongest main clan', () {
      expect(strongestPower(PoliticsState.empty, data), 60); // the Dominion
      expect(strongestPower(all(30), data), 30);
      expect(
          strongestPower(
              all(30).copyWith(power: {...all(30).power, 'mire': 77}), data),
          77);
      // A minor holder doesn't count.
      expect(
          strongestPower(
              all(30).copyWith(power: {...all(30).power, 'kindly': 90}), data),
          30);
    });

    test('a condition read, held when some clan is that strong', () {
      expect(EventConditions.keys, contains('anyPowerAtLeast'));
      final conditions = EventConditions.fromJson({'anyPowerAtLeast': 50});
      expect(conditions.anyPowerAtLeast, 50);
      final world = CoastWorld(data: data, chapter: 7);
      expect(conditions.holds(world, const [], all(49)), isFalse);
      expect(
          conditions.holds(world, const [],
              all(49).copyWith(power: {...all(49).power, 'crows': 50})),
          isTrue);
      expect(EventConditions.fromJson(const {}).anyPowerAtLeast, isNull);
      expect(EventConditions.fromJson(const {}).holds(world, const [], all(0)),
          isTrue);
    });

    test('a variant written with it: full size, else the fallback', () {
      final event = PoliticsEvent.fromJson('conclave', {
        'trigger': {'chapter': 7},
        'variants': [
          {
            'conditions': {'anyPowerAtLeast': 50},
            'news': 'full',
          },
          {'news': 'half'},
        ],
      });
      final world = CoastWorld(data: data, chapter: 7);
      String news(PoliticsState p) => event.variants
          .firstWhere((v) => v.conditions.holds(world, const [], p))
          .news;
      expect(news(all(40)), 'half');
      expect(news(all(40).copyWith(power: {...all(40).power, 'vigil': 60})),
          'full');
    });
  });
}
