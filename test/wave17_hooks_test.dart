// Wave 17 hooks for UX and Narrative: the sea fight's entrance card
// (enemy_ships.json `entranceCard`, shipHasEntranceCard), and the companion
// flags the loyalty scenes hang off (`devoted_<id>` once Devoted, `ally_<id>`
// while on the roster), backfilled on an old save.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/data/approval.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/models/ally_state.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

PlayerSession _session(Map<String, dynamic> json) => PlayerSession.fromJson(
    {'raceId': 'human', 'professionId': 'warrior', ...json});

AllyState _ally(String id, int approval) => AllyState(
    companionId: id,
    currentHealth: AllyState.fullHealthSentinel,
    approval: approval);

const _race = {'standardSkillID': 'human_resolve'};
const _profession = {'standardSkillID': 'warrior_technique'};

Future<PlayerSessionNotifier> _notifier({String? saved}) async {
  SharedPreferences.setMockInitialValues(
      {if (saved != null) 'player_session': saved});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  return notifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the sea fight entrance card', () {
    final ships = _table('enemy_ships');
    bool card(String id) =>
        shipHasEntranceCard(id, ships[id] as Map<String, dynamic>);

    test('beasts, the void barge and the named raiders get one; the skiff not',
        () {
      for (final entry in ships.entries) {
        if ((entry.value as Map)['beast'] is Map) {
          expect(card(entry.key), isTrue, reason: entry.key);
        }
      }
      expect(card('void_barge'), isTrue);
      expect(card('corsair_brig'), isTrue);
      expect(card('inquisition_cutter'), isTrue);
      expect(card('raider_skiff'), isFalse);
    });

    test('an explicit entranceCard overrides the default', () {
      expect(
          shipHasEntranceCard('x', const {
            'beast': {
              'waters': <int>[3]
            },
            'entranceCard': false,
          }),
          isFalse);
      expect(shipHasEntranceCard('x', const {'minChapter': 4}), isTrue);
      expect(
          shipHasEntranceCard(
              'x', const {'minChapter': 4, 'entranceCard': false}),
          isFalse);
      expect(shipHasEntranceCard('x', const {'minChapter': 2}), isFalse);
      expect(
          shipHasEntranceCard(
              'x', const {'minChapter': 2, 'entranceCard': true}),
          isTrue);
      expect(shipHasEntranceCard('x', null), isFalse);
    });

    test('the field is in the enemy_ships schema, a bool where set', () {
      expect(
          enemyShipsSchema.fields.map((f) => f.key), contains('entranceCard'));
      for (final entry in ships.entries) {
        final value = (entry.value as Map)['entranceCard'];
        expect(value == null || value is bool, isTrue, reason: entry.key);
      }
    });
  });

  group('companion flags', () {
    test('withCompanionFlags adds ally and devoted flags, keeps devoted', () {
      final flags = withCompanionFlags(
          const ['a', 'ally_gone'], const {'kelda': 3, 'sable': 12});
      expect(flags, containsAll(['a', 'ally_kelda', 'ally_sable']));
      expect(flags, contains('devoted_sable'));
      expect(flags, isNot(contains('devoted_kelda')));
      expect(flags, isNot(contains('ally_gone')));
      // Devoted stays once set, and the roster leaving takes only ally_.
      final later = withCompanionFlags(flags, const {});
      expect(later, contains('devoted_sable'));
      expect(later.where((f) => f.startsWith(allyFlagPrefix)), isEmpty);
      // Nothing to change: the very same list.
      final same = ['ally_kelda'];
      expect(identical(withCompanionFlags(same, const {'kelda': 0}), same),
          isTrue);
    });

    test(
        'recruiting sets ally_, Devoted sets devoted_ once, leaving clears ally_',
        () async {
      final notifier = await _notifier();
      await notifier.recruitAlly('kelda', race: _race, profession: _profession);
      expect(notifier.state.flags, contains('ally_kelda'));
      expect(notifier.state.flags, isNot(contains('devoted_kelda')));

      final companions = _table('companions');
      // Kelda likes a kind deed (approvesGood 2, doubled for a big one).
      for (var i = 0; i < 3; i++) {
        await notifier.reactToDeed(companions: companions, alignmentMod: 3);
      }
      expect(notifier.state.recruitedAllies.single.approval,
          greaterThanOrEqualTo(devotedApproval));
      expect(notifier.state.flags.where((f) => f == 'devoted_kelda'),
          hasLength(1));

      // Falling back below Devoted keeps the flag.
      await notifier.reactToDeed(
          companions: companions, approvalMods: const {'kelda': -5});
      expect(notifier.state.recruitedAllies.single.approval,
          lessThan(devotedApproval));
      expect(notifier.state.flags, contains('devoted_kelda'));

      // The story takes her: ally_ goes, devoted_ stays.
      await notifier.applyChoiceEffects(loseAllyId: 'kelda');
      expect(notifier.state.flags, isNot(contains('ally_kelda')));
      expect(notifier.state.flags, contains('devoted_kelda'));
    });

    test('a companion who walks out loses ally_', () async {
      final notifier = await _notifier();
      await notifier.recruitAlly('maren', race: _race, profession: _profession);
      await notifier.reactToDeed(
          companions: _table('companions'), approvalMods: const {'maren': -20});
      expect(notifier.state.departedAllyIds, ['maren']);
      expect(notifier.state.flags, isNot(contains('ally_maren')));
    });

    test('an old save gets its flags on load: devoted only at Devoted',
        () async {
      final old = _session({
        'flags': ['old_flag'],
        'recruitedAllies': [
          _ally('kelda', devotedApproval).toJson(),
          _ally('sable', devotedApproval - 1).toJson(),
        ],
        'activeAllyIds': ['kelda', 'sable'],
      });
      // The save as written has none of them.
      expect(old.flags, ['old_flag']);
      final notifier = await _notifier(saved: jsonEncode(old.toJson()));
      final flags = notifier.state.flags;
      expect(flags, containsAll(['old_flag', 'ally_kelda', 'ally_sable']));
      expect(flags, contains('devoted_kelda'));
      expect(flags, isNot(contains('devoted_sable')));
    });

    test('an old save without companions loads with no companion flags',
        () async {
      final old = _session({
        'flags': ['old_flag']
      });
      final notifier = await _notifier(saved: jsonEncode(old.toJson()));
      expect(notifier.state.flags, ['old_flag']);
    });

    test('the story reads the companion flags but never sets them', () {
      final dag = jsonDecode(
              File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;
      for (final entry in dag.entries) {
        for (final choice in (entry.value as Map)['choices'] as List) {
          for (final flag in ((choice as Map)['flagsToAdd'] as List?) ?? []) {
            expect(
                flag.toString().startsWith(allyFlagPrefix) ||
                    flag.toString().startsWith('devoted_'),
                isFalse,
                reason: '${entry.key} sets $flag');
          }
        }
      }
    });
  });
}
