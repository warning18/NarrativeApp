// Where a stat comes from (stat_breakdown.dart, stat_ledger.dart,
// docs/proposals/stat-scale.md §7b): the kept rows add up to the stored
// number, every row to the fight's; a pick, a tome's pick, the patron's
// gifts and the formative memories are recorded as they happen; an old
// save's unexplained rest is one "earlier" row.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/gear_effects.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/data/stat_breakdown.dart';
import 'package:narrative_data_app/data/stat_ledger.dart';
import 'package:narrative_data_app/data/training.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

import 'player_session_provider_test.dart' show baseSession;

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final races = _table('races');
  final professions = _table('professions');
  final gameConfig = _table('game_config');
  final items = _table('items');
  final itemSets = parseItemSets(_table('item_sets'));
  final signs = parseSigns(_table('signs'));
  final clans = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );
  final paths = trainingPathsFrom(_table('training_paths'));

  List<StatSource> breakdown(PlayerSession s, String stat) =>
      statBreakdown(s, stat,
          races: races,
          professions: professions,
          gameConfig: gameConfig,
          items: items,
          itemSets: itemSets,
          signs: signs,
          clans: clans);

  int amountOf(List<StatSource> rows, String kind, [String? id]) => rows
      .where((r) => r.kind == kind && (id == null || r.id == id))
      .fold(0, (a, r) => a + r.amount);

  /// Every stat's kept rows add up to the stored number.
  void expectSums(PlayerSession s, {bool noEarlier = true}) {
    for (final stat in breakdownStats) {
      final rows = breakdown(s, stat);
      expect(rows.storedTotal, storedStatOf(s, stat), reason: stat);
      if (noEarlier) expect(rows.ofKind('earlier'), isEmpty, reason: stat);
    }
  }

  Future<PlayerSessionNotifier> notifier() async {
    SharedPreferences.setMockInitialValues({});
    final n = PlayerSessionNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return n;
  }

  Future<PlayerSessionNotifier> hero(String raceId, String professionId) async {
    final n = await notifier();
    await n.startNewGame(
      raceId: raceId,
      race: races[raceId] as Map<String, dynamic>,
      professionId: professionId,
      profession: professions[professionId] as Map<String, dynamic>,
    );
    return n;
  }

  test('a new hero: every stat of every race and profession adds up', () async {
    for (final raceId in races.keys) {
      for (final professionId in professions.keys) {
        final s = (await hero(raceId, professionId)).state;
        final why = '$raceId $professionId';
        expect(s.statSources, isEmpty, reason: why);
        for (final stat in breakdownStats) {
          final rows = breakdown(s, stat);
          expect(rows.storedTotal, storedStatOf(s, stat), reason: '$why $stat');
          expect(rows.ofKind('earlier'), isEmpty, reason: '$why $stat');
          expect(rows.every((r) => r.amount != 0), isTrue);
          if (stat == 'baseDamage' || stat == 'baseArmor') continue;
          // Nothing worn, no sign: the fight's number is the stored one.
          expect(rows.fightTotal, storedStatOf(s, stat), reason: '$why $stat');
        }
        final strength = breakdown(s, 'strength');
        int bonus(Map<String, dynamic> r) =>
            (r['bonusStrength'] as num?)?.toInt() ?? 0;
        expect(amountOf(strength, 'race', raceId),
            bonus(races[raceId] as Map<String, dynamic>));
        expect(amountOf(strength, 'profession', professionId),
            bonus(professions[professionId] as Map<String, dynamic>));
      }
    }
  });

  test('a pick shows by its path, with the damage and health it brings',
      () async {
    final n = await hero('human', 'warrior');
    await n.loadSession(n.state.copyWith(statPoints: 3));
    for (var i = 0; i < 3; i++) {
      final offer = await n.ensureStatPick(paths, random: Random(i));
      // The calling: a warrior's Strength or Constitution, most often.
      final index = offer.indexWhere((o) =>
          o.gains.containsKey('strength') ||
          o.gains.containsKey('constitution'));
      final pick = offer[max(0, index)];
      final before = n.state;
      expect(await n.takeStatPick(max(0, index)), isTrue);
      final s = n.state;
      expectSums(s);
      for (final MapEntry(key: stat, value: v) in pick.gains.entries) {
        expect(
            amountOf(breakdown(s, stat), 'pick', pick.pathId) -
                amountOf(breakdown(before, stat), 'pick', pick.pathId),
            v,
            reason: stat);
      }
      expect(
          amountOf(breakdown(s, 'baseDamage'), 'pick') -
              amountOf(breakdown(before, 'baseDamage'), 'pick'),
          pick.gains['strength'] ?? 0);
      expect(
          amountOf(breakdown(s, 'maxHealth'), 'pick') -
              amountOf(breakdown(before, 'maxHealth'), 'pick'),
          5 * (pick.gains['constitution'] ?? 0));
    }
  });

  test("a tome's pick shows as the tome's", () async {
    final n = await hero('elf', 'mage');
    await n.applyCombatResult(
        hpAfter: n.state.currentHealth,
        itemsGained: const ['tome_of_insight'],
        items: items);
    expect(n.state.pendingStatPicks, 1);
    expect(n.state.tomePicks, ['tome_of_insight']);
    final offer = await n.ensureStatPick(paths, random: Random(3));
    expect(await n.takeStatPick(0), isTrue);
    final s = n.state;
    expect(s.tomePicks, isEmpty);
    expectSums(s);
    final stat = offer.first.stat;
    expect(amountOf(breakdown(s, stat), 'tome', 'tome_of_insight'),
        offer.first.gains[stat]);
    expect(amountOf(breakdown(s, stat), 'pick'), 0);
  });

  test("the patron's gifts show by the clan", () async {
    final n = await hero('human', 'warrior');
    var politics = n.state.politics;
    politics =
        setStandingValue(politics, 'dominion', 40, 'edit', data: clans).state;
    await n.loadSession(n.state.copyWith(politics: politics));
    // Level 1 to 5: the gifts of levels 2 and 4 (+1 Strength, +1 Charisma).
    await n.applyCombatResult(
        hpAfter: n.state.currentHealth, xpGain: 1000, items: items);
    final s = n.state;
    expect(s.level, 5);
    expectSums(s);
    expect(amountOf(breakdown(s, 'strength'), 'patron', 'dominion'), 1);
    expect(amountOf(breakdown(s, 'charisma'), 'patron', 'dominion'), 1);
    // Strength is a warrior's damage.
    expect(amountOf(breakdown(s, 'baseDamage'), 'patron', 'dominion'), 1);
    expect(amountOf(breakdown(s, 'maxHealth'), 'level'), 4 * 3);
  });

  test('the formative memories show as the origin', () async {
    final n = await hero('dwarf', 'cleric');
    await n.applyOriginMemories(
        alignmentMod: 0,
        abilities: const {'wisdom': 1, 'constitution': 1},
        flags: const []);
    final s = n.state;
    expectSums(s);
    expect(amountOf(breakdown(s, 'wisdom'), 'origin'), 1);
    expect(amountOf(breakdown(s, 'constitution'), 'origin'), 1);
    expect(amountOf(breakdown(s, 'maxHealth'), 'origin'), 3);
  });

  test('gear, a sign and a title are lent on top', () async {
    final n = await hero('human', 'warrior');
    final s = n.state.copyWith(
      equippedItemIds: const ['harborwatch_cutlass', 'harborwatch_coat'],
      heldSigns: const [HeldSign(signId: 'inked_passive_bulls_neck')],
      heldTitleIds: const ['gallows_breaker', 'the_challenged'],
      activeTitleId: 'gallows_breaker',
    );
    expectSums(s);

    final damage = breakdown(s, 'baseDamage');
    expect(amountOf(damage, 'gear', 'harborwatch_cutlass'), 2);
    // The sign's and the title's Strength lend a warrior its damage too.
    // (+1 Strength each since v1.461's effects-at-1 pass.)
    expect(amountOf(damage, 'sign', 'inked_passive_bulls_neck'), 1);
    expect(amountOf(damage, 'title', 'gallows_breaker'), 1);
    expect(damage.fightTotal, s.baseDamage + 2 + 1 + 1);

    final armor = breakdown(s, 'baseArmor');
    // The coat's own armor and the set's two-piece bonus.
    expect(amountOf(armor, 'gear', 'harborwatch_coat'), 2);
    expect(amountOf(armor, 'gear', 'harborwatch'), 1);
    expect(armor.where((r) => r.kind == 'gear').every((r) => r.lent), isTrue);

    final strength = breakdown(s, 'strength');
    expect(amountOf(strength, 'sign'), 1);
    expect(amountOf(strength, 'title'), 1);
    expect(strength.fightTotal, s.strength + 2);
    // A bad title is lent even when not worn.
    expect(amountOf(breakdown(s, 'maxHealth'), 'title', 'the_challenged'), -1);
    // The lent rows come after the kept ones.
    final firstLent = strength.indexWhere((r) => r.lent);
    expect(strength.skip(firstLent).every((r) => r.lent), isTrue);
  });

  test("an old save adds up, what it doesn't explain as earlier", () {
    final raw =
        jsonDecode(File('test/fixtures/session_v1_204.json').readAsStringSync())
            as Map<String, dynamic>;
    final s = PlayerSession.fromJson(raw);
    expect(s.statSources, isEmpty);
    expectSums(s, noEarlier: false);
    // A level-9 human warrior of 38 health: 20 + 5 (warrior) + 8 levels of
    // 4 + 3 (Vigor) is 60; the rescale took the rest away.
    final health = breakdown(s, 'maxHealth');
    expect(amountOf(health, 'level'), 24);
    expect(amountOf(health, 'perk', 'vigor'), 3);
    expect(health.ofKind('earlier'), hasLength(1));
    expect(health.storedTotal, 38);
    // Its Strength of 5: race and profession, the rest from before.
    final strength = breakdown(s, 'strength');
    expect(strength.storedTotal, 5);
    expect(amountOf(strength, 'earlier'),
        5 - amountOf(strength, 'race') - amountOf(strength, 'profession'));
  });

  test('the ledger and the tome picks survive a save, an empty one stays out',
      () {
    final fresh = baseSession(maxHealth: 20).copyWith(baseDamage: 2);
    expect(fresh.toJson().containsKey('statSources'), isFalse);
    expect(fresh.toJson().containsKey('tomePicks'), isFalse);
    final s = fresh.copyWith(professionId: 'warrior', tomePicks: const [
      'tome_of_insight'
    ]).withSourcedGains(ledgerPick, 'bruiser', const {
      'strength': 2
    }).withSourcedGains(ledgerPatron, 'dominion', const {'charisma': 1},
        maxHealth: 2);
    expect(s.statSources, {
      'pick:bruiser': {'strength': 2, 'baseDamage': 2},
      'patron:dominion': {'charisma': 1, 'maxHealth': 2},
    });
    expect(s.strength, 2);
    expect(s.baseDamage, 4);
    expect(s.maxHealth, 22);
    final back = PlayerSession.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
    expect(back.statSources, s.statSources);
    expect(back.tomePicks, ['tome_of_insight']);
    expect(
        ledgerFromJson({
          'x': 'bad',
          'pick:a': {'luck': 0}
        }),
        isEmpty);
  });
}
