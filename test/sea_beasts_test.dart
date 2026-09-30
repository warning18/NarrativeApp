// The sea beasts (v1.185): what the crew keeps of each, when one crosses
// the Eel's path, and what a beast does in battle that a ship does not.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/sea_beasts.dart';
import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/data/contracts.dart';
import 'package:narrative_data_app/data/sea_events.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/harbor_screen.dart';

Map<String, dynamic> _data(String name) =>
    json.decode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

final _ships = _data('enemy_ships');
final _parts = _data('ship_parts');

ShipCrew _hand(String id, {bool player = false}) => ShipCrew(
      id: id,
      name: id,
      strength: 3,
      dexterity: 3,
      constitution: 3,
      wisdom: 3,
      health: 60,
      maxHealth: 60,
      isPlayer: player,
    );

ShipState _eel({List<String> parts = const ['ballista']}) => buildPlayerShip(
    ship: _data('ships')['rusty_eel'] as Map<String, dynamic>,
    parts: _parts,
    installedPartIds: parts,
    currentHull: -1);

ShipState _beast({int hull = 100, int helm = 2, int hold = 2}) => ShipState(
      hull: hull,
      maxHull: 100,
      layers: 0,
      rooms: {
        ShipRoom.helm: RoomState(level: helm),
        ShipRoom.guns: const RoomState(level: 1),
        ShipRoom.bulwark: const RoomState(level: 0),
        ShipRoom.hold: RoomState(level: hold),
      },
      weapons: const [
        ShipWeapon(
            id: 'enemy_weapon_0',
            name: 'Jaws',
            nameFr: '',
            damage: 5,
            chargeTurns: 1),
      ],
    );

/// Every roll comes up 0: whatever can steer does, nothing slips a shot.
class _Zero implements Random {
  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

ShipBattle _battle(
  BeastProfile beast, {
  ShipState? enemy,
  List<String> parts = const ['ballista'],
}) =>
    ShipBattle(
      player: _eel(parts: parts),
      enemy: enemy ?? _beast(),
      crew: [_hand('player', player: true), _hand('kelda')],
      random: Random(1),
      beast: beast,
      rules: const ShipBattleRules(weather: false, seaEvents: false),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the data', () {
    test('three beasts, met in the order of their waters', () {
      expect(beastIdsIn(_ships), ['brinejaw', 'pale_leviathan', 'tide_kraken']);
      expect(beastWaters(_ships['brinejaw'] as Map<String, dynamic>), [3, 4]);
    });

    test('a beast is never a raider', () {
      for (var chapter = 1; chapter <= 7; chapter++) {
        for (final id in raiderPoolFor(_ships, chapter)) {
          expect(isBeastRecord(_ships[id] as Map<String, dynamic>), isFalse,
              reason: '$id at $chapter');
        }
      }
    });

    test('each beast leaves a trophy, and has its words in both languages', () {
      for (final id in beastIdsIn(_ships)) {
        final record = _ships[id] as Map<String, dynamic>;
        final part = _parts[beastTrophyPartId(record)] as Map<String, dynamic>;
        expect(part['trophyOf'], id);
        expect(part['cost'], 0);
        final spec = beastSpecOf(record);
        for (final key in ['omen', 'sighting', 'hunt']) {
          expect(spec[key], isNotEmpty, reason: '$id $key');
          expect(spec['${key}_fr'], isNot(spec[key]), reason: '$id $key');
        }
      }
      expect(_parts['hunters_harpoon']['beastGear'], isTrue);
      expect(_parts['hunters_harpoon']['tetherRounds'], 2);
      // Its line reaches no farther than the rack's: a beast is not kited
      // from long range, out of reach of its arms and jaws.
      expect(weaponRangesFrom(_parts['hunters_harpoon']['ranges']),
          {ShipRange.close, ShipRange.medium});
    });

    test('the Tide-Mother\'s arms come over the rail only in her battle', () {
      final enemies = _data('enemies');
      expect(enemies, contains('kraken_arm'));
      expect(isRandomDrawEnemy('kraken_arm'), isFalse);
      expect(
          boardingProfileFor(_ships['tide_kraken'] as Map<String, dynamic>)
              .crew,
          everyElement('kraken_arm'));
    });
  });

  group('what the crew keeps', () {
    test('wounds stay, up to half the beast', () {
      const fresh = BeastState();
      expect(beastStartHull(200, fresh), 200);
      expect(beastStartHull(200, const BeastState(wounds: 60)), 140);
      expect(beastStartHull(200, const BeastState(wounds: 500)), 100);
      expect(woundsAfter(maxHull: 200, hullAtEnd: 150), 50);
      expect(woundsAfter(maxHull: 200, hullAtEnd: 10), 100);
    });

    test('living through a meeting is a sign of it; a slain beast is done', () {
      final met = beastAfterBattle(const BeastState(),
          maxHull: 200, hullAtEnd: 140, slain: false);
      expect(met.seen, isTrue);
      expect(met.encounters, 1);
      expect(met.clues, 1);
      expect(met.wounds, 60);
      expect(met.tracked, isTrue);
      final slain =
          beastAfterBattle(met, maxHull: 200, hullAtEnd: 0, slain: true);
      expect(slain.slain, isTrue);
      expect(slain.tracked, isFalse);
      expect(slain.huntReady, isFalse);
      expect(const BeastState(seen: true, clues: 9).clues, 9,
          reason: 'the constructor keeps what it is given');
      expect(met.copyWith(clues: 9).clues, cluesNeeded);
    });

    test('a battle run from or sunk in teaches nothing; its wounds stay', () {
      const known = BeastState(seen: true, clues: 1, encounters: 1);
      final ran = beastAfterBattle(known,
          maxHull: 200, hullAtEnd: 150, slain: false, learned: false);
      expect(ran.clues, 1, reason: 'no sign');
      expect(ran.encounters, 1, reason: 'no edge');
      expect(ran.wounds, 50);
      expect(ran.tracked, isTrue);
    });

    test('the crew\'s edge grows with every meeting, more on a hunt', () {
      expect(beastEdge(const BeastState(), hunt: false), 0);
      expect(beastEdge(const BeastState(encounters: 1), hunt: true),
          edgePerEncounter + huntEdge);
      expect(beastEdge(const BeastState(encounters: 9), hunt: false),
          maxEncounterEdge);
    });

    test('a beast crosses the Eel\'s path only in its own waters', () {
      var met = 0;
      var metFirst = 0;
      var brinejawFirst = 0;
      var brinejawLater = 0;
      for (var seed = 0; seed < 2000; seed++) {
        final id = rollBeastEncounter(
            random: Random(seed),
            enemyShips: _ships,
            chapter: 5,
            beasts: const {'pale_leviathan': BeastState(seen: true)});
        if (id != null) {
          met++;
          expect(id, 'pale_leviathan');
        }
        // Not seen yet: it shows itself more readily in the first waters
        // it roams (the Brinejaw's chapter-3 waters, not its chapter 4).
        if (rollBeastEncounter(
                random: Random(seed),
                enemyShips: _ships,
                chapter: 5,
                beasts: const {}) !=
            null) {
          metFirst++;
        }
        for (final (chapter, tally) in [(3, 0), (4, 1)]) {
          if (rollBeastEncounter(
                  random: Random(seed),
                  enemyShips: _ships,
                  chapter: chapter,
                  beasts: const {}) ==
              'brinejaw') {
            if (tally == 0) {
              brinejawFirst++;
            } else {
              brinejawLater++;
            }
          }
        }
        expect(
            rollBeastEncounter(
                random: Random(seed),
                enemyShips: _ships,
                chapter: 2,
                beasts: const {}),
            isNull);
        expect(
            rollBeastEncounter(
                random: Random(seed),
                enemyShips: _ships,
                chapter: 5,
                beasts: const {'pale_leviathan': BeastState(slain: true)}),
            isNull);
      }
      expect(met / 2000, closeTo(beastEncounterChance, 0.04));
      expect(metFirst / 2000, closeTo(firstWatersEncounterChance, 0.04));
      expect(brinejawFirst / 2000, closeTo(firstWatersEncounterChance, 0.04));
      expect(brinejawLater / 2000, closeTo(beastEncounterChance, 0.04));
      expect(
          trackedBeastIn(
              enemyShips: _ships,
              chapter: 4,
              beasts: const {'brinejaw': BeastState(seen: true, clues: 1)}),
          'brinejaw');
      expect(
          trackedBeastIn(
              enemyShips: _ships,
              chapter: 4,
              beasts: const {'brinejaw': BeastState(seen: true, clues: 3)}),
          isNull,
          reason: 'enough signs already');
    });

    test('the day it is met, and its omen the day before', () {
      final record = _ships['brinejaw'] as Map<String, dynamic>;
      final days = buildVoyage(
          random: Random(3), length: 3, enemyShips: _ships, chapter: 3);
      final laid = withBeastDay(days, 2, 'brinejaw', record);
      expect(laid, hasLength(3));
      expect(laid[2].kind, SeaEventKind.beast);
      expect(laid[2].enemyShipId, 'brinejaw');
      expect(laid[1].omenBeastId, 'brinejaw');
      expect(laid[0].omenBeastId, isNull);
      final actions = [for (final c in laid[2].choices) c.action];
      expect(actions, [SeaAction.fight, SeaAction.outrun, SeaAction.holdStill]);
      final run = laid[2].choices[1];
      expect(seaChoiceDc(run, 3), seaCheckDc(3) + beastOutrunDcBonus);
      final hunt = beastDayFor('brinejaw', record, hunt: true);
      expect(hunt.kind, SeaEventKind.hunt);
      expect([for (final c in hunt.choices) c.action], [SeaAction.fight]);
      // Never the first day of a crossing that has one before it for its
      // omen.
      for (var seed = 0; seed < 60; seed++) {
        for (final length in [2, 3, 4]) {
          expect(beastDayIndex(Random(seed), length),
              inInclusiveRange(1, length - 1));
        }
      }
      expect(beastDayIndex(Random(1), 1), 0);
    });
  });

  group('a beast in battle', () {
    test('it heals while its heart beats, not on the line', () {
      final b = _battle(const BeastProfile(regen: 6, fleeShare: 0),
          enemy: _beast(hull: 80));
      b.startEnemyPhase();
      b.endRound();
      expect(b.enemy.hull, 86);
      b.tether = 2;
      b.startEnemyPhase();
      b.endRound();
      expect(b.enemy.hull, 86, reason: 'held on the line');
      expect(b.tether, 1);
      final heartless = _battle(const BeastProfile(regen: 6, fleeShare: 0),
          enemy: _beast(hull: 80, hold: 0));
      heartless.startEnemyPhase();
      heartless.endRound();
      expect(heartless.enemy.hull, 80);
    });

    test('a harpoon that bites holds it', () {
      final b = _battle(const BeastProfile(),
          parts: const ['hunters_harpoon', 'ballista']);
      final harpoon = b.player.weapons.firstWhere((w) => w.tetherRounds > 0);
      expect(harpoon.tetherRounds, 2);
      // Charged enough to fire, at a beast that cannot slip it.
      b.player = b.player.withWeapon(harpoon.withCharge(harpoon.chargeTurns));
      b.helmMarked = true;
      final shot = b.fire(harpoon.id, ShipRoom.guns);
      expect(shot!.landed, isTrue);
      expect(b.tethered, isTrue);
      expect(b.tether, 2);
      expect(b.log.any((l) => l.key == 'ship_log_tethered'), isTrue);
    });

    test('it dives instead of its volley, and breaches under the Eel', () {
      final b = _battle(const BeastProfile(diveEvery: 1, breach: 14));
      expect(b.roundsToDive, 0);
      final hull = b.player.hull;
      b.startEnemyPhase();
      expect(b.dived, isTrue);
      expect(b.enemyVolley, isEmpty);
      expect(b.player.hull, hull - 14);
      expect(b.player.leaks, 1);
      final braced = _battle(const BeastProfile(diveEvery: 1, breach: 14))
        ..braced = true;
      braced.startEnemyPhase();
      expect(braced.player.hull, hull - 7);
      final held = _battle(const BeastProfile(diveEvery: 1, breach: 14))
        ..tether = 1;
      held.startEnemyPhase();
      expect(held.dived, isFalse, reason: 'held on the line');
      final every3 = _battle(const BeastProfile(diveEvery: 3, breach: 14));
      expect(every3.roundsToDive, 2);
    });

    test('hurt, it turns for the deep, and is gone unless held', () {
      ShipBattle hurt() =>
          _battle(const BeastProfile(fleeShare: 0.3), enemy: _beast(hull: 30));
      final b = hurt();
      b.startEnemyPhase();
      expect(b.over, isFalse, reason: 'it turns first');
      b.endRound();
      expect(b.beastTurning, isTrue);
      b.startEnemyPhase();
      expect(b.end, BattleEnd.escaped);

      final held = hurt();
      held.startEnemyPhase();
      held.endRound();
      held.tether = 1;
      held.startEnemyPhase();
      expect(held.over, isFalse);

      final finless = _battle(const BeastProfile(fleeShare: 0.3),
          enemy: _beast(hull: 30, helm: 0));
      finless.startEnemyPhase();
      finless.endRound();
      finless.startEnemyPhase();
      expect(finless.over, isFalse, reason: 'no fins to go with');
    });

    test('nobody boards a beast, and it does not chase a ship that runs', () {
      final b = ShipBattle(
        player: _eel(),
        enemy: _beast(helm: 9),
        crew: [
          _hand('player', player: true),
          _hand('grosh'),
        ],
        random: _Zero(),
        boarding: const BoardingProfile(crew: ['kraken_arm'], chance: 1),
        habit: EnemyHabit.boarder,
        beast: const BeastProfile(),
        rules: const ShipBattleRules(weather: false, seaEvents: false),
      );
      b.range = ShipRange.close;
      b.enemy = b.enemy.copyWith(layers: 0);
      expect(b.canBoardThem, isFalse);
      expect(b.canOrder(b.crew[1]), isFalse, reason: 'no grapple');
      // The turn she runs, it lets her go.
      b.range = ShipRange.long;
      b.runForIt();
      expect(b.escape, 1);
      b.startEnemyPhase();
      expect(b.range, ShipRange.long);
      b.endRound();
      // A turn she stays to fight, it comes on again, and the run loses
      // the ground it made.
      b.startEnemyPhase();
      expect(b.range, ShipRange.medium);
      expect(b.escape, 0);
      expect(b.log.any((l) => l.key == 'ship_log_run_caught'), isTrue);
    });

    test('the round it dives, it breaches and sends nothing over the rail', () {
      ShipBattle alongside(BeastProfile beast) => ShipBattle(
            player: _eel(),
            enemy: _beast(),
            crew: [_hand('player', player: true), _hand('grosh')],
            random: _Zero(),
            boarding: const BoardingProfile(crew: ['kraken_arm'], chance: 1),
            habit: EnemyHabit.boarder,
            beast: beast,
            rules: const ShipBattleRules(weather: false, seaEvents: false),
          )
            ..range = ShipRange.close
            // Its third round alongside: a boarder's arms come over.
            ..roundsAlongside = 2;
      final diving = alongside(const BeastProfile(diveEvery: 1, breach: 5));
      diving.startEnemyPhase();
      expect(diving.dived, isTrue);
      expect(diving.enemyBoards(), isNull);
      expect(diving.log.any((l) => l.key == 'ship_log_boarders'), isFalse);
      final surfaced = alongside(const BeastProfile());
      surfaced.startEnemyPhase();
      expect(surfaced.enemyBoards(), isNotNull);
    });

    test('healed past its share with its fins torn, it turns back', () {
      final b = _battle(const BeastProfile(regen: 20, fleeShare: 0.5),
          enemy: _beast(hull: 30, helm: 0));
      b.startEnemyPhase();
      b.endRound();
      expect(b.beastTurning, isTrue);
      b.startEnemyPhase();
      expect(b.over, isFalse, reason: 'no fins to go with');
      b.endRound();
      expect(b.enemy.hull, 70);
      expect(b.beastTurning, isFalse);
      expect(b.log.last.key, 'ship_log_beast_turns_back');
      // Its fins mended, it stays and fights: it is hurt no longer.
      b.enemy = b.enemy.withRoom(ShipRoom.helm, const RoomState(level: 2));
      b.startEnemyPhase();
      expect(b.over, isFalse);
    });

    test('grape and chain are only light shot to a beast', () {
      const parts = ['grape_swivel', 'chain_swivel'];
      final b = _battle(const BeastProfile(), parts: parts);
      final grape = b.weaponById('grape_swivel')!;
      final chain = b.weaponById('chain_swivel')!;
      final chainMods = b.shotMods(ShipRoom.guns, weapon: chain);
      expect(chainMods.helmPips, 0, reason: 'no rigging to tear');
      expect(chainMods.damageFactor, 0.5);
      b.player = b.player.withWeapon(grape.withCharge(grape.chargeTurns));
      b.helmMarked = true;
      expect(b.fire(grape.id, ShipRoom.guns)!.landed, isTrue);
      expect(b.grapeLeft, 0, reason: 'no deck to sweep');
      // A ship's deck and rigging are another matter.
      final ship = ShipBattle(
        player: _eel(parts: parts),
        enemy: _beast(),
        crew: [_hand('player', player: true), _hand('kelda')],
        random: Random(1),
        rules: const ShipBattleRules(weather: false, seaEvents: false),
      );
      expect(ship.shotMods(ShipRoom.guns, weapon: chain).helmPips, 1);
      ship.player = ship.player.withWeapon(grape.withCharge(grape.chargeTurns));
      ship.helmMarked = true;
      expect(ship.fire(grape.id, ShipRoom.guns)!.landed, isTrue);
      expect(ship.grapeLeft, grapeRounds);
    });
  });

  test('the beast\'s bounty goes up while one is tracked, and pays half again',
      () {
    var posted = 0;
    for (var seed = 0; seed < 200; seed++) {
      final plain = rollContracts(
          chapter: 4,
          huntPool: const ['harbor_rat'],
          random: Random(seed),
          boardNumber: seed,
          sea: true);
      expect(plain.any((c) => c.kind == ContractKind.beastFought), isFalse);
      final board = rollContracts(
          chapter: 4,
          huntPool: const ['harbor_rat'],
          random: Random(seed),
          boardNumber: seed,
          sea: true,
          beastTracked: true);
      for (final c in board) {
        if (c.kind != ContractKind.beastFought) continue;
        posted++;
        expect(c.rewardGold, (contractGoldFor(4) * beastContractPay).round());
        expect(progressContract(c, const ContractTally(beastsFought: 1)).done,
            isTrue);
      }
    }
    expect(posted, greaterThan(60));
  });

  group('the Harbor', () {
    test('beast gear once a beast is seen, a trophy once it is slain', () {
      final harpoon = _parts['hunters_harpoon'] as Map<String, dynamic>;
      final hide = _parts['sharkskin_hull'] as Map<String, dynamic>;
      final none = PlayerSession.fromJson(const {});
      expect(
          HarborScreen.partOffered('hunters_harpoon', harpoon, none), isFalse);
      expect(HarborScreen.partOffered('sharkskin_hull', hide, none), isFalse);
      final seen = PlayerSession.fromJson(const {
        'seaBeasts': {
          'brinejaw': {'seen': true},
        },
      });
      expect(
          HarborScreen.partOffered('hunters_harpoon', harpoon, seen), isTrue);
      expect(HarborScreen.partOffered('sharkskin_hull', hide, seen), isFalse);
      final slain = PlayerSession.fromJson(const {
        'seaBeasts': {
          'brinejaw': {'seen': true, 'slain': true},
        },
      });
      expect(HarborScreen.partOffered('sharkskin_hull', hide, slain), isTrue);
      expect(
          HarborScreen.partOffered(
              'ballista', _parts['ballista'] as Map<String, dynamic>, none),
          isTrue);
    });

    test('a part swapped off waits in store and goes back on for nothing',
        () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = PlayerSessionNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await notifier.loadSession(PlayerSession.fromJson(const {
        'raceId': 'human',
        'professionId': 'warrior',
        'gold': 400,
        'shipPartIds': ['ballista', 'harpoon_rack'],
      }));
      expect(
          await notifier.installShipPart('hunters_harpoon', 180,
              replacing: ['harpoon_rack']),
          isTrue);
      var session = notifier.state;
      expect(session.shipPartIds, ['ballista', 'hunters_harpoon']);
      expect(session.storedShipPartIds, ['harpoon_rack']);
      expect(session.gold, 220);
      expect(
          await notifier.installShipPart('harpoon_rack', 160,
              replacing: ['hunters_harpoon']),
          isTrue);
      session = notifier.state;
      expect(session.gold, 220, reason: 'a stored part costs nothing');
      expect(session.storedShipPartIds, ['hunters_harpoon']);
      await notifier.storeShipPart('sharkskin_hull');
      await notifier.updateSeaBeast(
          'brinejaw', (b) => b.copyWith(seen: true, clues: 2));
      final back = PlayerSession.fromJson(
          json.decode(json.encode(notifier.state.toJson()))
              as Map<String, dynamic>);
      expect(back.storedShipPartIds, ['hunters_harpoon', 'sharkskin_hull']);
      expect(back.seaBeasts['brinejaw']!.clues, 2);
      expect(back.seaBeasts['brinejaw']!.seen, isTrue);
    });
  });

  test('every line of the beasts is written in both languages', () {
    final keys = [
      for (final room in ShipRoom.values) ...[
        'beast_room_${room.name}',
        'beast_room_${room.name}_title',
        'beast_room_${room.name}_hint',
      ],
      for (final key in [
        'turning',
        'tethered',
        'dives_now',
        'dives_in',
        'regen',
        'regen_stopped',
        'edge',
      ])
        'beast_status_$key',
      'tip_ship_beast',
      'tip_ship_tether',
      'ship_log_tethered',
      'ship_log_tether_slips',
      'ship_log_beast_escaped',
      'ship_log_beast_dives',
      'ship_log_beast_breach',
      'ship_log_beast_heals',
      'ship_log_beast_turning',
      'ship_log_beast_turns_back',
      'ship_log_beast_outran',
      'ship_log_beast_sign_outran',
      'ship_run_warning',
      'ship_run_left_hint',
      'beast_ship_log_leak',
      'beast_ship_log_flooding',
      'beast_ship_log_shot_absorbed',
      'sea_event_beast',
      'sea_event_hunt',
      'beast_wounds_line',
      'beast_known_line',
      'ship_log_beast_sign_wreck',
      'ship_log_beast_sign_sighting',
      'ship_log_beast_watched',
      'ship_log_beast_clues',
      'ship_log_beast_hunt_ready',
      'ship_log_beast_passed',
      'ship_log_beast_noticed',
      'ship_log_beast_caught',
      'ship_log_beast_slain',
      'ship_log_beast_got_away',
      'ship_log_trophy_fitted',
      'ship_log_trophy_waiting',
      'beasts_section',
      'beasts_none_hint',
      'beasts_hint',
      'beast_slain_label',
      'beast_signs_label',
      'beast_wounds_label',
      'beast_hunt_away_hint',
      'beast_hunt_button',
      'swap_title',
      'swap_button',
      'part_stored_note',
      'free_label',
      'tether_label',
      'contract_beastFought',
    ];
    for (final key in keys) {
      expect(trFor(AppLanguage.en, key), isNot(key), reason: key);
      expect(trFor(AppLanguage.fr, key), isNot(trFor(AppLanguage.en, key)),
          reason: '$key has no French');
    }
  });
}
