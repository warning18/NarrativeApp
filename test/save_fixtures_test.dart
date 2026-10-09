// Save fixtures (v1.209): two on-disk saves of the same mid-game run (a
// level-9 warrior in chapter 4, a party of three, worn gear, quests active
// and done, flags, standing and marks, titles), one as v1.198 wrote it --
// before `itemOrigins` and `seenNpcIds` (v1.204) -- and one as v1.204
// does. Each loads through PlayerSession.fromJson, round-trips through
// toJson, the older one gets the new keys' defaults, and the save slots
// read both. PlayerSession's migrations key on missing keys, so these are
// what a migration is checked against.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/models/item_origin.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/save_game_provider.dart';

const String _v198 = 'test/fixtures/session_v1_198.json';
const String _v204 = 'test/fixtures/session_v1_204.json';

/// The keys v1.204 added to the save, missing from the v1.198 fixture.
const Set<String> _keysSince198 = {'itemOrigins', 'seenNpcIds'};

Map<String, dynamic> _fixture(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// The fields a save must bring back as they were: a representative list,
/// read off a session for a field-by-field comparison.
Map<String, Object?> _fields(PlayerSession s) => {
      'level': s.level,
      'currentXP': s.currentXP,
      'gold': s.gold,
      'alignmentScore': s.alignmentScore,
      'maxHealth': s.maxHealth,
      'currentHealth': s.currentHealth,
      'strength': s.strength,
      'wisdom': s.wisdom,
      'potionCount': s.potionCount,
      'flags': s.flags,
      'activeQuestIds': s.activeQuestIds,
      'completedQuestIds': s.completedQuestIds,
      'inventoryItemIds': s.inventoryItemIds,
      'equippedItemIds': s.equippedItemIds,
      'unlockedSkillIds': s.unlockedSkillIds,
      'diceSkillAssignments': s.diceSkillAssignments,
      'raceId': s.raceId,
      'professionId': s.professionId,
      'ownedDiceIds': s.ownedDiceIds,
      'equippedDiceId': s.equippedDiceId,
      'characterName': s.characterName,
      'trackedQuestId': s.trackedQuestId,
      'day': s.day,
      'watch': s.watch,
      'clockChapter': s.clockChapter,
      'provisions': s.provisions,
      'runSeed': s.runSeed,
      // Lists, not records: the matcher compares lists deeply, records by
      // identity of their list fields.
      'allies': [
        for (final a in s.recruitedAllies)
          [a.companionId, a.currentHealth, a.approval, ...a.equippedItemIds],
      ],
      'activeAllyIds': s.activeAllyIds,
      'perkRanks': s.perkRanks,
      'heldSigns': [
        for (final h in s.heldSigns) [h.signId, h.rarity.name, h.level],
      ],
      'pendingOffers': [for (final t in s.pendingOffers) t.source.name],
      'heldTitleIds': s.heldTitleIds,
      'activeTitleId': s.activeTitleId,
      'standings': s.politics.standings,
      'marks': s.politics.marks,
      'sworn': s.politics.swornFactionId,
      'applied': s.politics.appliedKeys,
      'log': s.politics.standingLog.length,
      'builtHouseIds': s.builtHouseIds,
      'completedZoneIds': s.completedZoneIds,
      'shipHull': s.shipHull,
      'shipPartIds': s.shipPartIds,
      'currentPortId': s.currentPortId,
      'enemyKillCounts': s.enemyKillCounts,
      'questKillBaselines': s.questKillBaselines,
      'contracts': [
        for (final c in s.contracts) [c.id, c.kind.name, c.progress],
      ],
      'seaBeasts': {
        for (final e in s.seaBeasts.entries)
          e.key: [e.value.seen, e.value.clues, e.value.encounters],
      },
      'bossDefeatCounts': s.bossDefeatCounts,
      'skillEssence': s.skillEssence,
      'skillTiers': s.skillTiers,
      'mana': s.mana,
      'knownSpellIds': s.knownSpellIds,
      'itemOrigins': s.itemOrigins,
      'seenNpcIds': s.seenNpcIds,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixtures = {'v1.198': _v198, 'v1.204': _v204};

  test('the fixtures are the saves they claim to be', () {
    final old = _fixture(_v198);
    final recent = _fixture(_v204);
    expect(old['saveVersion'], playerSessionSaveVersion);
    expect(recent['saveVersion'], playerSessionSaveVersion);
    for (final key in _keysSince198) {
      expect(old.containsKey(key), isFalse, reason: '$key is v1.204');
      expect(recent.containsKey(key), isTrue, reason: '$key is v1.204');
    }
    // The same run otherwise.
    expect(old.keys.toSet(), recent.keys.toSet().difference(_keysSince198));
    for (final key in old.keys) {
      expect(old[key], recent[key], reason: key);
    }
    // Mid-game: chapter 4, a party, gear worn, quests on both lists,
    // standing moved and marks set, a title worn.
    expect(recent['clockChapter'], 4);
    expect(recent['level'], 9);
    expect((recent['recruitedAllies'] as List).length, 3);
    expect((recent['equippedItemIds'] as List), isNotEmpty);
    expect((recent['activeQuestIds'] as List), isNotEmpty);
    expect((recent['completedQuestIds'] as List), isNotEmpty);
    expect((recent['flags'] as List), isNotEmpty);
    final politics = recent['politics'] as Map<String, dynamic>;
    expect((politics['standings'] as Map), isNotEmpty);
    expect((politics['marks'] as Map), isNotEmpty);
    expect((politics['log'] as List), isNotEmpty);
    expect((recent['heldTitleIds'] as List), isNotEmpty);
    expect(recent['activeTitleId'], isNotEmpty);
    expect((recent['itemOrigins'] as Map), isNotEmpty);
    expect((recent['seenNpcIds'] as List), isNotEmpty);
  });

  for (final fixture in fixtures.entries) {
    group('the ${fixture.key} save', () {
      late final Map<String, dynamic> json;
      late final PlayerSession session;
      setUpAll(() {
        json = _fixture(fixture.value);
        session = PlayerSession.fromJson(json);
      });

      test('loads', () {
        expect(session.level, 9);
        expect(session.characterName, 'Aubin Ferrand');
        expect(session.raceId, 'human');
        expect(session.professionId, 'warrior');
        expect(session.clockChapter, 4);
        expect(session.equippedItemIds, ['sword_t3', 'armor_leather']);
        expect(session.inventoryItemIds, contains('sword_t3'));
        expect(session.activeQuestIds, contains('q_ch4_bark_tithe'));
        expect(session.completedQuestIds, contains('q_ch2_unpaid_scaffold'));
        expect(session.activeAllyIds, ['kelda', 'maren']);
        expect(session.recruitedAllies.map((a) => a.companionId),
            ['kelda', 'maren', 'sable']);
        expect(session.recruitedAllies.first.equippedItemIds, ['shield_t2']);
        expect(session.flags, contains('scaffold_paid'));
        // Houses built reach the flags.
        expect(session.builtHouseIds, ['keldas_hall', 'hammersmith']);
        expect(session.flags, contains(houseFlag('keldas_hall')));
        expect(session.politics.standings['compact'], greaterThan(0));
        expect(session.politics.standings['dominion'], lessThan(-10));
        expect(session.politics.marks['scaffolders'], SubclanMark.friend);
        expect(session.politics.appliedKeys, isNotEmpty);
        expect(session.politics.standingLog, isNotEmpty);
        expect(session.heldTitleIds, isNotEmpty);
        expect(session.activeTitleId, session.heldTitleIds.first);
        expect(
            session.heldSigns.single.signId, 'standard_strike_rank_and_file');
        expect(session.pendingOffers, hasLength(1));
        expect(session.contracts.single.progress, 2);
        expect(session.seaBeasts['brinejaw']?.seen, isTrue);
        expect(session.enemyKillCounts['harbor_rat'], 12);
        expect(session.grandfatheredQuestIds, isEmpty,
            reason: 'a save with enemyKillCounts is not grandfathered');
        expect(session.mana, 10);
        expect(session.knownSpellIds, ['spell_frost_bind']);
      });

      test('round-trips field by field', () {
        final again = PlayerSession.fromJson(session.toJson());
        final before = _fields(session);
        final after = _fields(again);
        for (final key in before.keys) {
          expect(after[key], before[key], reason: key);
        }
        expect(again.toJson(), session.toJson());
      });

      test('writes every key of the current format', () {
        final written = session.toJson();
        expect(written['saveVersion'], playerSessionSaveVersion);
        expect(written.keys.toSet(), containsAll(_keysSince198));
        expect(written.keys.toSet(), containsAll(_fixture(_v204).keys));
      });
    });
  }

  test('the v1.198 save gets the defaults for the keys added since', () {
    final session = PlayerSession.fromJson(_fixture(_v198));
    expect(session.itemOrigins, isEmpty,
        reason: 'a save from before v1.204 knows no origins');
    expect(session.seenNpcIds, isEmpty);
    // The rest reads exactly as the v1.204 save of the same run.
    final recent = PlayerSession.fromJson(_fixture(_v204));
    final old = _fields(session)
      ..remove('itemOrigins')
      ..remove('seenNpcIds');
    final fresh = _fields(recent)
      ..remove('itemOrigins')
      ..remove('seenNpcIds');
    for (final key in old.keys) {
      expect(old[key], fresh[key], reason: key);
    }
    expect(recent.itemOrigins['sword_t3'],
        const ItemOrigin(placeId: 'alster_lower_town', chapter: 2));
    expect(recent.seenNpcIds, ['lysa', 'renn', 'aurel_vane']);
  });

  test('the save slots read both: a legacy save into slot 1, a slot save',
      () async {
    final old = _fixture(_v198);
    final recent = _fixture(_v204);
    SharedPreferences.setMockInitialValues({
      // The single save of earlier versions, read into slot 1.
      'saved_game_session': jsonEncode(old),
      'saved_game_story': jsonEncode({
        'currentNodeId': '4999_camp',
        'history': ['0', '100', '105', '2001', '3001', '4999'],
      }),
      'saved_game_slot_2': jsonEncode({
        'session': recent,
        'currentNodeId': '5003',
        'history': ['0', '100', '105', '2001', '3001', '4999', '4999_camp'],
        'savedAt': '2026-10-08T21:14:00.000',
      }),
    });
    final notifier = SavedGamesNotifier();
    await pumpEventQueue();
    expect(notifier.state, hasLength(saveSlotCount));
    final first = notifier.state[0];
    expect(first, isNotNull, reason: 'the legacy save became slot 1');
    expect(first!.characterName, 'Aubin Ferrand');
    expect(first.level, 9);
    expect(first.nodeId, '4999_camp');
    expect(first.savedAt, isNull);
    final second = notifier.state[1]!;
    expect(second.nodeId, '5003');
    expect(second.savedAt, DateTime.parse('2026-10-08T21:14:00.000'));
    expect(notifier.state[2], isNull);

    final slot1 = await notifier.load(1);
    expect(slot1, isNotNull);
    expect(slot1!.session.level, 9);
    expect(slot1.session.itemOrigins, isEmpty);
    expect(slot1.currentNodeId, '4999_camp');
    expect(slot1.history, hasLength(6));

    final slot2 = await notifier.load(2);
    expect(slot2, isNotNull);
    expect(slot2!.session.itemOrigins, hasLength(4));
    expect(slot2.session.seenNpcIds, hasLength(3));
    expect(slot2.currentNodeId, '5003');
    expect(
        _fields(slot2.session)
          ..remove('itemOrigins')
          ..remove('seenNpcIds'),
        _fields(slot1.session)
          ..remove('itemOrigins')
          ..remove('seenNpcIds'));
  });
}
