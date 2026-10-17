import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/companion_remarks.dart';
import 'package:narrative_data_app/models/ally_state.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/walking_party_provider.dart';

import 'player_session_provider_test.dart' show baseSession;

AllyState _ally(String id) =>
    AllyState(companionId: id, currentHealth: AllyState.fullHealthSentinel);

List<String> _ids(List<WalkingPartyMember> party) =>
    [for (final m in party) m.id];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('with no companion the hero walks alone', () {
    final party = walkingPartyOf(baseSession());
    expect(_ids(party), ['hero']);
    expect(party.single.isHero, isTrue);
    expect(party.single.spriteKey, 'hero');
  });

  test('a recruited companion left on the bench does not walk', () {
    final party = walkingPartyOf(baseSession(
        recruitedAllies: [_ally('maren'), _ally('malrik')],
        activeAllyIds: const ['malrik']));
    expect(_ids(party), ['hero', 'malrik']);
    expect(party[1].spriteKey, 'companion_malrik');
  });

  test('only the picked companions walk, at most two, in the order picked', () {
    final party = walkingPartyOf(baseSession(recruitedAllies: [
      _ally('maren'),
      _ally('malrik'),
      _ally('kelda'),
    ], activeAllyIds: const [
      'kelda',
      'maren',
      'malrik'
    ]));
    expect(_ids(party), ['hero', 'kelda', 'maren']);
  });

  test('a companion lost, gone or never recruited does not walk', () {
    final party = walkingPartyOf(baseSession(
      recruitedAllies: [_ally('maren'), _ally('malrik'), _ally('kelda')],
      activeAllyIds: const ['maren', 'malrik', 'ghost', 'kelda'],
    ).copyWith(
        lostAllyIds: const ['maren'], departedAllyIds: const ['malrik']));
    expect(_ids(party), ['hero', 'kelda']);
  });

  test('the provider follows the save', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(_ids(container.read(walkingPartyProvider)), ['hero']);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await container.read(playerSessionProvider.notifier).loadSession(
        baseSession(
            recruitedAllies: [_ally('maren')], activeAllyIds: const ['maren']));
    expect(_ids(container.read(walkingPartyProvider)), ['hero', 'maren']);
  });

  group('a word on the road', () {
    final book = RemarkBook({
      'kelda_walk': {
        'companionID': 'kelda',
        'trigger': 'walk',
        'lines': ['Keep to the verge.', 'Mind your feet.'],
        'lines_fr': ['Gardez le bord.', 'Vos pieds.'],
      },
      'sable_walk': {
        'companionID': 'sable',
        'trigger': 'walk',
        'lines': ['Pace yourself.'],
      },
    });

    test('a walking companion with walk lines says one', () {
      final said = walkRemark(book, const RemarkMemory(), ['maren', 'kelda']);
      expect(said.remark?.companionId, 'kelda');
      expect(said.remark?.kind, RemarkKind.walk);
      expect(said.remark!.lineFor(book, french: false), isNotEmpty);
    });

    test('nobody speaks when no walker has a line, or nobody walks', () {
      expect(walkRemark(book, const RemarkMemory(), ['maren']).remark, isNull);
      expect(walkRemark(book, const RemarkMemory(), const []).remark, isNull);
    });

    test('the one who spoke least recently goes first', () {
      final first = walkRemark(book, const RemarkMemory(), ['kelda', 'sable']);
      expect(first.remark?.companionId, 'kelda');
      final later = RemarkMemory(
        choices: first.memory.choices + remarkCooldownChoices,
        lastRemarkAt: first.memory.lastRemarkAt,
        lastSpokeAt: first.memory.lastSpokeAt,
        used: first.memory.used,
      );
      expect(walkRemark(book, later, ['kelda', 'sable']).remark?.companionId,
          'sable');
    });

    test('it waits out the cooldown after a remark', () {
      const recent = RemarkMemory(choices: 5, lastRemarkAt: 4);
      expect(walkRemark(book, recent, ['kelda']).remark, isNull);
      const past = RemarkMemory(choices: 7, lastRemarkAt: 4);
      expect(walkRemark(book, past, ['kelda']).remark, isNotNull);
    });

    test('walk is a trigger a remark record can have', () {
      expect(remarkTriggerOptions, contains('walk'));
    });
  });
}
