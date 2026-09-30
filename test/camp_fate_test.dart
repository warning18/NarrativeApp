// The camp's fate die (v1.183): what it shows, where it lands and what
// each face comes to.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/camp_fate.dart';
import 'package:narrative_data_app/data/journey_rules.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

FateContext _camp({
  int chapter = 4,
  int gold = 500,
  int provisions = 10,
  List<String> companions = const ['grosh', 'maren'],
  List<String> places = const ['5100'],
}) =>
    FateContext(
      chapter: chapter,
      gold: gold,
      provisions: provisions,
      provisionsMax: 12,
      companionIds: companions,
      rumorPlaceIds: places,
    );

FateRoll _landOn(FateFace face, FateContext context) {
  for (var seed = 0; seed < 5000; seed++) {
    final roll = rollFate(context, Random(seed));
    if (roll.face == face) return roll;
  }
  throw StateError('never landed on $face');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the die', () {
    test('a face that cannot happen shows a quiet night', () {
      expect(fateDieFor(_camp()), fateDieFaces);
      final lonely = fateDieFor(_camp(companions: ['grosh'], places: []));
      expect(lonely, isNot(contains(FateFace.rumor)));
      expect(lonely, isNot(contains(FateFace.quarrel)));
      expect(lonely.where((f) => f == FateFace.quiet), hasLength(3));
    });

    test('the same night rolls the same', () {
      final a = rollFate(_camp(), fateRandomFor(42, 17));
      final b = rollFate(_camp(), fateRandomFor(42, 17));
      expect(a.faceIndex, b.faceIndex);
      expect(a.visitor, b.visitor);
      final faces = {
        for (var day = 0; day < 200; day++)
          rollFate(_camp(), fateRandomFor(42, day)).face,
      };
      expect(faces, FateFace.values.toSet());
    });

    test('a quarrel is between two different companions', () {
      final roll = _landOn(
          FateFace.quarrel, _camp(companions: ['grosh', 'maren', 'kelda']));
      expect(roll.quarrelers, hasLength(2));
      expect(roll.quarrelers.first, isNot(roll.quarrelers.last));
      expect(fateChoicesFor(roll), [
        FateChoice.sideWithFirst,
        FateChoice.sideWithSecond,
        FateChoice.makePeace,
      ]);
    });

    test('a rumor names a place still to find', () {
      final roll = _landOn(FateFace.rumor, _camp(places: ['6100']));
      expect(roll.placeId, '6100');
      expect(fateOutcome(roll, _camp()).revealPlaceId, '6100');
    });
  });

  group('what the night comes to', () {
    test('a windfall brings gold, or rations when the pack runs low', () {
      final roll = _landOn(FateFace.windfall, _camp());
      expect(fateOutcome(roll, _camp()).gold, windfallGold(4));
      final low = fateOutcome(roll, _camp(provisions: 3));
      expect(low.gold, 0);
      expect(low.provisions, windfallRations);
    });

    test('a thief is caught on Perception, or takes gold or rations', () {
      final roll = _landOn(FateFace.theft, _camp());
      final dc = fateCheckDc(4);
      final caught = fateOutcome(roll, _camp(), checkTotal: dc);
      expect(caught.checkPassed, isTrue);
      expect(caught.isEmpty, isTrue);
      final robbed = fateOutcome(roll, _camp(gold: 500), checkTotal: dc - 1);
      expect(robbed.gold, -50);
      expect(fateOutcome(roll, _camp(gold: 5000), checkTotal: 1).gold, -120,
          reason: 'at most 30 gold per chapter');
      final broke = fateOutcome(roll, _camp(gold: 0), checkTotal: 1);
      expect(broke.provisions, -theftRations);
      // A natural 20 passes whatever the total (see rollAbilityCheck).
      expect(
          fateOutcome(roll, _camp(), checkTotal: 3, checkPassed: true)
              .checkPassed,
          isTrue);
    });

    test('the visitors ask for a choice', () {
      final context = _camp();
      final roll = _landOn(FateFace.visitor, context);
      FateOutcome pick(FateChoice choice) =>
          fateOutcome(roll, context, choice: choice);
      expect(pick(FateChoice.shareRations).provisions, -pilgrimRations);
      expect(pick(FateChoice.shareRations).alignment, pilgrimShareAlignment);
      expect(pick(FateChoice.sendOn).alignment, pilgrimRefuseAlignment);
      expect(pick(FateChoice.handOver).gold, deserterBounty(4));
      expect(pick(FateChoice.handOver).alignment, deserterHandOverAlignment);
      expect(pick(FateChoice.listen).approval,
          {'grosh': storytellerApproval, 'maren': storytellerApproval});
      expect(fateChoiceOpen(FateChoice.shareRations, _camp(provisions: 1)),
          isFalse);
    });

    test('a quarrel moves approval', () {
      final context = _camp();
      final roll = _landOn(FateFace.quarrel, context);
      final first = roll.quarrelers.first;
      final second = roll.quarrelers.last;
      expect(
          fateOutcome(roll, context, choice: FateChoice.sideWithFirst).approval,
          {first: quarrelSideApproval, second: -quarrelSideApproval});
      final peace = fateOutcome(roll, context,
          choice: FateChoice.makePeace, checkTotal: fateCheckDc(4));
      expect(peace.approval, {first: 1, second: 1});
      final failed = fateOutcome(roll, context,
          choice: FateChoice.makePeace, checkTotal: 2);
      expect(failed.approval, {first: -1, second: -1});
    });
  });

  test('every line of the die is written in both languages', () {
    final keys = [
      'fate_title',
      'fate_intro',
      'fate_hint',
      for (final face in FateFace.values) 'fate_face_${face.name}',
      for (final visitor in FateVisitor.values) 'fate_visitor_${visitor.name}',
      for (final choice in FateChoice.values) ...[
        'fate_choice_${choice.name}',
      ],
      for (var i = 0; i < fateQuarrelTopics; i++) 'fate_quarrel_topic_$i',
      for (var i = 0; i < fateQuietLines; i++) 'fate_quiet_$i',
      for (final choice in [
        FateChoice.shareRations,
        FateChoice.sendOn,
        FateChoice.hideDeserter,
        FateChoice.handOver,
        FateChoice.listen,
        FateChoice.sendAway,
      ])
        'fate_result_${choice.name}',
    ];
    for (final key in keys) {
      expect(trFor(AppLanguage.en, key), isNot(key), reason: key);
      expect(trFor(AppLanguage.fr, key), isNot(trFor(AppLanguage.en, key)),
          reason: '$key has no French');
    }
  });

  test('the pack keeps between empty and full', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = PlayerSessionNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await notifier.loadSession(PlayerSession.fromJson({
      'raceId': 'human',
      'professionId': 'warrior',
      'provisions': provisionsMax - 2,
    }));
    expect(await notifier.adjustProvisions(5), 2);
    expect(notifier.state.provisions, provisionsMax);
    expect(await notifier.adjustProvisions(-20), -provisionsMax);
    expect(notifier.state.provisions, 0);
  });
}
