// The road's rules (v1.176): rations eaten on the road between two places,
// days that pass on the road, in a night's rest and at sea, enemies that
// gather strength while a chapter drags on, and the sellsword a purse can
// hire. None of it touches chapter 1, which has no town to buy from.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/journey_rules.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

Future<PlayerSessionNotifier> _notifier(Map<String, dynamic> json) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(PlayerSession.fromJson(
      {'raceId': 'human', 'professionId': 'warrior', ...json}));
  return notifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the rules', () {
    test('only from chapter 2', () {
      expect(roadRulesApply(1), isFalse);
      expect(roadRulesApply(2), isTrue);
      expect(roadRulesApply(6), isTrue);
    });

    test('enemies gather strength past the grace, up to a ceiling', () {
      expect(threatFor(0, chapter: 3), 0);
      expect(threatFor(threatGraceDays, chapter: 3), 0);
      expect(threatFor(threatGraceDays + 1, chapter: 3),
          closeTo(threatPerDay, 1e-9));
      expect(threatFor(threatGraceDays + 4, chapter: 3),
          closeTo(4 * threatPerDay, 1e-9));
      expect(threatFor(1000, chapter: 3), threatMax);
    });

    test('the chapters crossed by sea have a longer grace', () {
      // A voyage takes days: a party that sails to each of an open
      // chapter's places isn't lingering.
      expect(threatGraceDaysFor(2), threatGraceDays);
      expect(threatGraceDaysFor(3), threatGraceDays);
      for (final chapter in [4, 5, 6]) {
        expect(threatGraceDaysFor(chapter), greaterThanOrEqualTo(24));
        expect(threatFor(20, chapter: chapter), 0);
        expect(threatFor(threatGraceDaysFor(chapter) + 2, chapter: chapter),
            closeTo(2 * threatPerDay, 1e-9));
      }
      expect(threatGraceDaysFor(6), greaterThan(threatGraceDaysFor(5)));
    });

    test('hunger bites a share of health, never the last point', () {
      expect(hungerDamage(health: 100, maxHealth: 100), 8);
      expect(hungerDamage(health: 5, maxHealth: 100), 4);
      expect(hungerDamage(health: 1, maxHealth: 100), 0);
      expect(hungerDamage(health: 10, maxHealth: 5), 1);
    });

    test('prices grow with the chapter', () {
      expect(provisionPrice(3), greaterThan(provisionPrice(2)));
      expect(sellswordPrice(5), greaterThan(sellswordPrice(2)));
      expect(sellswordDamage(6), greaterThan(sellswordDamage(2)));
    });

    test('a road step crosses the map, a move within a place does not', () {
      expect(isRoadStep('2001', '2005'), isTrue);
      expect(isRoadStep('5003', '5004'), isFalse);
      expect(isRoadStep('2015', '2015'), isFalse);
      expect(isRoadStep('2015', 'no_such_scene'), isFalse);
    });
  });

  group('the session', () {
    test('a fresh save and an old one start with a full pack on day 1', () {
      final fresh = PlayerSession.fromJson(const {});
      expect(fresh.provisions, provisionsStart);
      expect(fresh.day, 1);
      expect(fresh.sellswordFights, 0);
      expect(fresh.seenEchoKeys, isEmpty);
      final json = fresh.toJson();
      for (final key in [
        'provisions',
        'day',
        'stepsToday',
        'clockChapter',
        'chapterStartDay',
        'sellswordFights',
        'seenEchoKeys',
      ]) {
        expect(json, contains(key));
      }
    });

    test('the road state survives a save', () {
      final session = PlayerSession.fromJson(const {
        'provisions': 3,
        'day': 9,
        'stepsToday': 2,
        'clockChapter': 4,
        'chapterStartDay': 5,
        'sellswordFights': 2,
        'seenEchoKeys': ['5004_altar|court_fled'],
      });
      final back = PlayerSession.fromJson(session.toJson());
      expect(back.provisions, 3);
      expect(back.day, 9);
      expect(back.stepsToday, 2);
      expect(back.clockChapter, 4);
      expect(back.chapterStartDay, 5);
      expect(back.sellswordFights, 2);
      expect(back.seenEchoKeys, ['5004_altar|court_fled']);
    });

    test('chapter 1 roads cost nothing', () async {
      final notifier = await _notifier(const {});
      final step = await notifier.takeRoadStep(chapter: 1);
      expect(step.counted, isFalse);
      expect(notifier.state.provisions, provisionsStart);
      expect(notifier.state.day, 1);
    });

    test('each step eats a ration, and every fourth ends the day', () async {
      final notifier = await _notifier(const {});
      for (var i = 1; i < stepsPerDay; i++) {
        final step = await notifier.takeRoadStep(chapter: 2);
        expect(step.counted, isTrue);
        expect(step.dayEnded, isFalse);
      }
      final last = await notifier.takeRoadStep(chapter: 2);
      expect(last.dayEnded, isTrue);
      expect(last.day, 2);
      expect(notifier.state.provisions, provisionsStart - stepsPerDay);
      expect(notifier.state.stepsToday, 0);
    });

    test('with no ration left, hunger costs health', () async {
      final notifier = await _notifier(const {
        'provisions': 0,
        'maxHealth': 100,
        'currentHealth': 100,
      });
      final step = await notifier.takeRoadStep(chapter: 3);
      expect(step.hungry, isTrue);
      expect(step.hunger, 8);
      expect(notifier.state.currentHealth, 92);
      expect(notifier.state.provisions, 0);
    });

    test('the threat counts the days spent in the chapter', () async {
      final notifier = await _notifier(const {'day': 3});
      expect(notifier.state.threatIn(4), 0);
      await notifier.passDays(1, chapter: 4);
      expect(notifier.state.clockChapter, 4);
      expect(notifier.state.chapterStartDay, 3);
      await notifier.passDays(threatGraceDaysFor(4) + 1, chapter: 4);
      expect(notifier.state.threatIn(4), closeTo(2 * threatPerDay, 1e-9));
      // Another chapter starts its own count.
      expect(notifier.state.threatIn(5), 0);
      await notifier.takeRoadStep(chapter: 5);
      expect(notifier.state.threatIn(5), 0);
    });

    test('a night’s rest heals and passes a day', () async {
      final notifier = await _notifier(const {
        'maxHealth': 100,
        'currentHealth': 30,
        'day': 4,
        'stepsToday': 3,
      });
      await notifier.restNight(chapter: 3);
      expect(notifier.state.currentHealth, 100);
      expect(notifier.state.day, 5);
      expect(notifier.state.stepsToday, 0);
      // In chapter 1 the day still turns (the world clock runs
      // everywhere), but no chapter's threat is counted for it.
      await notifier.restNight(chapter: 1);
      expect(notifier.state.day, 6);
      expect(notifier.state.watch, 0);
      expect(notifier.state.clockChapter, 3);
    });

    test('rations are bought up to what the pack holds', () async {
      final notifier = await _notifier(const {'gold': 100, 'provisions': 10});
      expect(await notifier.buyProvisions(3, price: 10), isFalse);
      expect(await notifier.buyProvisions(2, price: 10), isTrue);
      expect(notifier.state.provisions, provisionsMax);
      expect(notifier.state.gold, 80);
      final poor = await _notifier(const {'gold': 5, 'provisions': 0});
      expect(await poor.buyProvisions(1, price: 10), isFalse);
      expect(poor.state.provisions, 0);
    });

    test('a sellsword is hired once, for a few fights', () async {
      final notifier = await _notifier(const {'gold': 500});
      expect(await notifier.hireSellsword(price: 200), isTrue);
      expect(notifier.state.gold, 300);
      expect(notifier.state.sellswordFights, sellswordContractFights);
      expect(await notifier.hireSellsword(price: 200), isFalse);
      for (var i = 0; i < sellswordContractFights + 1; i++) {
        await notifier.spendSellswordFight();
      }
      expect(notifier.state.sellswordFights, 0);
      expect(await notifier.hireSellsword(price: 400), isFalse);
    });

    test('a retreat costs a fifth of the purse and a potion', () async {
      expect(retreatCostFor(300), 60);
      final notifier = await _notifier(const {'gold': 300, 'potionCount': 2});
      await notifier.applyRetreat(
          hpAfter: 10, goldLost: retreatCostFor(300), dropPotion: true);
      expect(notifier.state.gold, 240);
      expect(notifier.state.potionCount, 1);
    });

    test('echoes read are remembered once', () async {
      final notifier = await _notifier(const {});
      await notifier.noteEchoes(['a|x', 'b|y', 'a|x']);
      await notifier.noteEchoes(['b|y', 'c|z']);
      expect(notifier.state.seenEchoKeys, ['a|x', 'b|y', 'c|z']);
    });
  });
}
