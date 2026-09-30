// Face smithing at the Hammersmith (v1.182): what the work does to a die,
// what it costs, and how the session pays for it and keeps it.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/face_keywords.dart';
import 'package:narrative_data_app/combat/face_smithing.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

const List<Map<String, dynamic>> _die = [
  {'type': 'Attack', 'value': 6, 'element': 'None'},
  {'type': 'Defend', 'value': 5, 'element': 'None'},
  {'type': 'Skill', 'value': 0, 'linkedSkillID': 'rogue_backstab'},
  {'type': 'Heal', 'value': 7, 'element': 'None'},
  {'type': 'Mana', 'value': 1, 'element': 'None'},
  {
    'type': 'Attack',
    'value': 4,
    'element': 'None',
    'keywords': ['pierce'],
  },
];

Future<PlayerSessionNotifier> _notifier(PlayerSession session) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(session);
  return notifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the work on a die', () {
    test('a Hone, a Temper, an inscription and a Recast', () {
      final faces = smithedFaces(_die, {
        '0': const FaceUpgrade(
            hones: 2, element: 'Fire', keyword: FaceKeyword.cleave),
        '1': const FaceUpgrade(recastType: 'Heal', hones: 1),
        '2': const FaceUpgrade(keyword: FaceKeyword.pain),
      });
      expect(faces[0]['value'], 10);
      expect(faces[0]['element'], 'Fire');
      expect(faceKeywordsOf(faces[0]), {FaceKeyword.cleave});
      expect(faces[1]['type'], 'Heal');
      expect(faces[1]['value'], 7);
      expect(faceKeywordsOf(faces[2]), {FaceKeyword.pain});
      // The die itself is left as it was.
      expect(_die[0]['value'], 6);
      expect(faces[3], same(_die[3]));
    });

    test('work that no longer fits the face is left out', () {
      final faces = smithedFaces(_die, {
        // Growth doesn't fit a Mana face; a Temper only goes on an Attack.
        '4': const FaceUpgrade(keyword: FaceKeyword.growth),
        '1': const FaceUpgrade(element: 'Ice'),
      });
      expect(faceKeywordsOf(faces[4]), isEmpty);
      expect(faces[1]['element'], 'None');
    });

    test('what each face can take', () {
      expect(canSmith(SmithingWork.hone, _die[0]), isTrue);
      expect(canSmith(SmithingWork.hone, _die[0], const FaceUpgrade(hones: 3)),
          isFalse);
      expect(canSmith(SmithingWork.temper, _die[1]), isFalse);
      expect(
          canSmith(SmithingWork.temper, _die[1],
              const FaceUpgrade(recastType: 'Attack')),
          isTrue);
      expect(canSmith(SmithingWork.hone, _die[2]), isFalse);
      expect(canSmith(SmithingWork.recast, _die[2]), isFalse);
      expect(canSmith(SmithingWork.inscribe, _die[2]), isTrue);
      expect(inscribableKeywords(_die[5]), isNot(contains(FaceKeyword.pierce)));
      expect(inscribableKeywords(_die[1]),
          containsAll([FaceKeyword.steady, FaceKeyword.growth]));
      expect(inscribableKeywords(_die[1]), isNot(contains(FaceKeyword.cleave)));
    });

    test('a Hone costs more each time', () {
      expect(honeCost(0).gold, 80);
      expect(honeCost(1).gold, 160);
      expect(honeCost(2).iron, 3);
      expect(
          smithingCostFor(SmithingWork.inscribe, FaceUpgrade.none).trophies, 1);
    });

    test('kept in a save', () {
      final upgrades = {
        'iron_die': {
          '0': const FaceUpgrade(hones: 2, keyword: FaceKeyword.steady),
          '3': const FaceUpgrade(recastType: 'Attack', element: 'Void'),
        },
      };
      expect(parseDiceUpgrades(diceUpgradesToJson(upgrades)), upgrades);
      expect(parseDiceUpgrades(null), isEmpty);
      expect(
          parseDiceUpgrades({
            'x': {
              '0': {'hones': 9, 'element': 'Plasma'}
            }
          })['x']!['0'],
          const FaceUpgrade(hones: maxHones));
    });
  });

  group('the Hammersmith is paid', () {
    PlayerSession session({int gold = 1000, List<String> pack = const []}) =>
        PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'ownedDiceIds': ['iron_die'],
          'equippedDiceId': 'iron_die',
          'gold': gold,
          'inventoryItemIds': pack,
        });

    test('a Hone takes gold and iron, and stays on the die', () async {
      final notifier = await _notifier(session(
          pack: ['material_iron_ore', 'material_iron_ore', 'elite_trophy']));
      final done = await notifier.smithFace(
          dieId: 'iron_die',
          faceIndex: 0,
          faces: _die,
          work: SmithingWork.hone);
      expect(done, isTrue);
      expect(notifier.state.gold, 920);
      expect(notifier.state.inventoryItemIds,
          ['material_iron_ore', 'elite_trophy']);
      expect(notifier.state.diceUpgrades['iron_die']!['0'],
          const FaceUpgrade(hones: 1));
      final saved = PlayerSession.fromJson(notifier.state.toJson());
      expect(saved.diceUpgrades['iron_die']!['0']!.hones, 1);
    });

    test('an inscription takes a trophy, an Elite Mark first', () async {
      final notifier =
          await _notifier(session(pack: ['boss_trophy', 'elite_trophy']));
      expect(
          await notifier.smithFace(
              dieId: 'iron_die',
              faceIndex: 1,
              faces: _die,
              work: SmithingWork.inscribe,
              keyword: FaceKeyword.steady),
          isTrue);
      expect(notifier.state.inventoryItemIds, ['boss_trophy']);
      expect(notifier.state.gold, 750);
      // Cleave doesn't fit a guard.
      expect(
          await notifier.smithFace(
              dieId: 'iron_die',
              faceIndex: 1,
              faces: _die,
              work: SmithingWork.inscribe,
              keyword: FaceKeyword.cleave),
          isFalse);
    });

    test('nothing is done without the means', () async {
      final notifier = await _notifier(session(gold: 50));
      expect(
          await notifier.smithFace(
              dieId: 'iron_die',
              faceIndex: 0,
              faces: _die,
              work: SmithingWork.hone),
          isFalse);
      expect(notifier.state.diceUpgrades, isEmpty);
      expect(notifier.state.gold, 50);
    });

    test('a Recast back to the die\'s own type clears it', () async {
      final notifier = await _notifier(session());
      await notifier.smithFace(
          dieId: 'iron_die',
          faceIndex: 0,
          faces: _die,
          work: SmithingWork.temper,
          element: 'Fire');
      await notifier.smithFace(
          dieId: 'iron_die',
          faceIndex: 0,
          faces: _die,
          work: SmithingWork.recast,
          recastType: 'Defend');
      var upgrade = notifier.state.diceUpgrades['iron_die']!['0']!;
      expect(upgrade.recastType, 'Defend');
      expect(upgrade.element, isNull, reason: 'a Temper stays on an Attack');
      await notifier.smithFace(
          dieId: 'iron_die',
          faceIndex: 0,
          faces: _die,
          work: SmithingWork.recast,
          recastType: 'Attack');
      upgrade = notifier.state.diceUpgrades['iron_die']!['0']!;
      expect(upgrade.recastType, isNull);
    });
  });
}
