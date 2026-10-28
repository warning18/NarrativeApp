// Vica, the companion every hero gets (v1.601, docs/proposals/
// guide-dog-companion.md §6, story_companions.dart): she joins at her scene
// or the White Wells, sits down whenever the party would be empty, is
// benched only by seating someone else, never walks out and is never taken
// by the story; the simulator gives her to every policy.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/duo_techniques.dart';
import 'package:narrative_data_app/data/approval.dart';
import 'package:narrative_data_app/data/sim_companions.dart';
import 'package:narrative_data_app/data/story_companions.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

final _companions = _table('companions');
final _races = _table('races');
final _professions = _table('professions');
final _dice = _table('dice');
final _houses = _table('houses');

Future<PlayerSessionNotifier> _notifierWith(Map<String, dynamic> raw) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(PlayerSession.fromJson(raw));
  return notifier;
}

Future<List<String>> _join(PlayerSessionNotifier n, Iterable<String> visited) =>
    n.recruitStoryCompanions(visited,
        companions: _companions,
        races: _races,
        professions: _professions,
        dice: _dice,
        houses: _houses);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('her entry', () {
    test('the story gives her, she stays, at her scene or the White Wells', () {
      final vica = _companions['vica'] as Map<String, dynamic>;
      expect(isStoryRecruit(vica), isTrue);
      expect(isPermanentCompanion(vica), isTrue);
      expect(joinNodeIdsOf(vica), ['1150_vica', '1200']);
      expect(vica['recruitQuestId'], '');
      expect(vica['raceId'], '');
      expect(vica['professionId'], 'ranger');
      expect(_dice[vica['signatureDiceId']], isNotNull);
      // No other companion is given by the story.
      expect(
          _companions.keys.where(
              (id) => isStoryRecruit(_companions[id] as Map<String, dynamic>)),
          ['vica']);
    });

    test('her duo is The Hunt, with Liora', () {
      expect(duoTechniques.where((d) => d.involves('vica')).map((d) => d.id),
          ['the_hunt']);
      expect(
          duoTechniques
              .firstWhere((d) => d.id == 'the_hunt')
              .pairs('liora', 'vica'),
          isTrue);
    });

    test('her numbers as measured: 29 health and 2 damage at level 3', () {
      final party = SimParty(
        companions: _companions,
        races: _races,
        professions: _professions,
        gameConfig: _table('game_config'),
        dice: _dice,
        skills: _table('skills'),
      )..levelIs(3);
      party.recruit('vica', chapter: 1, cause: 'the story');
      final vica = party.fightAllies().single;
      expect(vica.maxHealth, 29);
      expect(vica.damage, 2);
    });
  });

  group('the rules', () {
    test('she joins once the story reaches her scene, else the Wells', () {
      List<String> due(List<String> visited) =>
          storyRecruitsDue(_companions, visited: visited, recruited: const []);
      expect(due(['0', '1100']), isEmpty);
      expect(due(['0', '1150_vica']), ['vica']);
      expect(due(['0', '1200']), ['vica']);
      expect(
          storyRecruitsDue(_companions,
              visited: ['1200'], recruited: const ['vica']),
          isEmpty);
    });

    test(
        'she sits down when the party would be empty, and is benched only '
        'by seating someone else', () {
      expect(
          withPermanentSeated(const [],
              recruited: const ['kelda', 'vica'], companions: _companions),
          ['vica']);
      expect(
          withPermanentSeated(const ['kelda'],
              recruited: const ['kelda', 'vica'], companions: _companions),
          ['kelda']);
      expect(
          canBenchCompanion('vica',
              active: const ['vica'], companions: _companions),
          isFalse);
      expect(
          canBenchCompanion('vica',
              active: const ['vica', 'kelda'], companions: _companions),
          isTrue);
      expect(
          canBenchCompanion('kelda',
              active: const ['kelda'], companions: _companions),
          isTrue);
    });

    test('she never walks out, and the story never takes her', () {
      final vica = _companions['vica'] as Map<String, dynamic>;
      expect(permanentApprovalFloor(vica, -15), leavingApproval + 1);
      expect(permanentApprovalFloor(vica, -6), -6);
      expect(
          permanentApprovalFloor(
              _companions['kelda'] as Map<String, dynamic>, -15),
          -15);
      expect(
          storyLossOf('vica', active: const ['vica'], companions: _companions),
          isNull);
      expect(
          storyLossOf('*',
              active: const ['vica', 'kelda'], companions: _companions),
          'kelda');
      expect(storyLossOf('*', active: const ['vica'], companions: _companions),
          isNull);
    });
  });

  group('the session', () {
    test('a save past the Wells gets her, seated, once', () async {
      final n = await _notifierWith({'professionId': 'warrior', 'level': 3});
      expect(await _join(n, const ['0', '1100']), isEmpty);
      expect(n.state.recruitedAllies, isEmpty);
      expect(await _join(n, const ['0', '1200']), ['vica']);
      expect(n.state.activeAllyIds, ['vica']);
      expect(await _join(n, const ['0', '1200', '2000']), isEmpty);
      expect(n.state.recruitedAllies, hasLength(1));
    });

    test(
        'the camp cannot bench her alone; benching the last other one '
        'seats her', () async {
      final n = await _notifierWith({'professionId': 'mage'});
      await _join(n, const ['1150_vica']);
      await n.setAllyActive('vica', false,
          partyCapacity: 2, companions: _companions);
      expect(n.state.activeAllyIds, ['vica']);
      expect(n.canBench('vica', _companions), isFalse);
      await n.recruitAlly('kelda',
          companion: _companions['kelda'] as Map<String, dynamic>);
      expect(n.state.activeAllyIds, ['vica', 'kelda']);
      expect(n.canBench('vica', _companions), isTrue);
      await n.setAllyActive('vica', false,
          partyCapacity: 2, companions: _companions);
      expect(n.state.activeAllyIds, ['kelda']);
      await n.setAllyActive('kelda', false,
          partyCapacity: 2, companions: _companions);
      expect(n.state.activeAllyIds, ['vica']);
    });

    test(
        'a choice taking `*` or her by name leaves her be; scorn does not '
        'send her away', () async {
      final n = await _notifierWith({'professionId': 'rogue'});
      await _join(n, const ['1200']);
      await n.applyChoiceEffects(loseAllyId: '*', companions: _companions);
      await n.applyChoiceEffects(loseAllyId: 'vica', companions: _companions);
      for (var i = 0; i < 4; i++) {
        await n.applyChoiceEffects(
            approvalMods: const {'vica': -9}, companions: _companions);
      }
      expect(n.state.activeAllyIds, ['vica']);
      expect(n.state.lostAllyIds, isEmpty);
      expect(n.state.departedAllyIds, isEmpty);
      expect(n.state.recruitedAllies.single.approval, leavingApproval + 1);
    });

    test('her scene sets her mood: the shared water devoted, the coins wary',
        () async {
      final n = await _notifierWith({'professionId': 'cleric'});
      await _join(n, const ['1150_vica']);
      await n.applyChoiceEffects(
          approvalMods: const {'vica': 9}, companions: _companions);
      expect(approvalTierFor(n.state.recruitedAllies.single.approval),
          ApprovalTier.devoted);
      final m = await _notifierWith({'professionId': 'cleric', 'gold': 20});
      await _join(m, const ['1150_vica']);
      await m.applyChoiceEffects(
          goldMod: -10,
          approvalMods: const {'vica': -8},
          companions: _companions);
      expect(approvalTierFor(m.state.recruitedAllies.single.approval),
          ApprovalTier.wary);
    });
  });
}
