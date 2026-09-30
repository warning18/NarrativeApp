// v1.190's three dynamics of the ship battle (see ship_battle.dart):
// the enemy's intents (what it will do next, which the fog hides, and how
// its mind changes as the fight goes), pushing one of the Eel's rooms past
// its limit once a turn, and the battle getting worse over time (fire
// spreads, leaks weigh a ship down, the weather keeps a trend, a second
// sail comes).
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/sea_beasts.dart';
import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';

/// A Random that plays back the rolls it is given, then [fallback]; every
/// int it draws is 0.
class _Rolls implements Random {
  _Rolls([this.doubles = const []]);

  final List<double> doubles;
  double fallback = 0.99;
  int _d = 0;

  @override
  double nextDouble() => _d < doubles.length ? doubles[_d++] : fallback;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

ShipState _ship({
  int hull = 100,
  int maxHull = 100,
  int layers = 0,
  Map<ShipRoom, int> levels = const {},
  List<ShipWeapon> weapons = const [],
  int crew = 1,
}) =>
    ShipState(
      hull: hull,
      maxHull: maxHull,
      layers: layers,
      rooms: {
        for (final room in ShipRoom.values)
          room: RoomState(level: levels[room] ?? 1),
      },
      weapons: weapons,
      repairsPerRound: crew,
    );

const _gun = ShipWeapon(
    id: 'gun', name: 'Gun', nameFr: 'Canon', damage: 12, chargeTurns: 1);
const _bigGun = ShipWeapon(
    id: 'big', name: 'Big gun', nameFr: '', damage: 22, chargeTurns: 3);
const _theirGun = ShipWeapon(
    id: 'enemy_weapon_0',
    name: 'Their gun',
    nameFr: '',
    damage: 10,
    chargeTurns: 1);

ShipCrew _member(String id, {bool player = false}) => ShipCrew(
      id: id,
      name: id,
      strength: 3,
      dexterity: 3,
      constitution: 3,
      wisdom: 3,
      health: 40,
      maxHealth: 50,
      isPlayer: player,
    );

final _you = _member('player', player: true);

/// Every rule but the weather and the sea's events, which only get in the
/// way of a scene set by hand.
const _rules = ShipBattleRules(weather: false, seaEvents: false);

ShipBattle _battle({
  ShipState? player,
  ShipState? enemy,
  List<ShipCrew>? crew,
  Random? random,
  ShipBattleRules rules = _rules,
  EnemyHabit habit = EnemyHabit.none,
  BoardingProfile boarding = const BoardingProfile(),
  BeastProfile? beast,
}) =>
    ShipBattle(
      player: player ?? _ship(weapons: const [_gun]),
      enemy: enemy ??
          _ship(levels: const {ShipRoom.helm: 2}, weapons: const [_theirGun]),
      crew: crew ?? [_you],
      random: random ?? _Rolls(),
      rules: rules,
      habit: habit,
      boarding: boarding,
      beast: beast,
    );

void main() {
  test('every line and label of the dynamics has its words in both languages',
      () {
    final keys = [
      for (final intent in ShipIntent.values) ...[
        'ship_intent_${intent.name}',
        'ship_intent_${intent.name}_hint',
      ],
      for (final key in ['volley', 'flee', 'ram']) ...[
        'beast_ship_intent_$key',
        'beast_ship_intent_${key}_hint',
      ],
      'ship_intent_hidden',
      'ship_intent_hidden_hint',
      'tip_ship_intent',
      'tip_ship_push',
      for (final room in ShipRoom.values) 'ship_push_${room.name}_hint',
      for (final key in [
        'button',
        'title',
        'once_label',
        'strain_label',
        'strain_hint',
        'flash',
        'strain_flash',
      ])
        'ship_push_$key',
      for (final key in [
        'intent_helm_slow',
        'intent_ram_missed',
        'intent_board_foiled',
        'intent_board_held',
        'intent_mend',
        'intent_brace',
        'push_guns',
        'push_helm',
        'push_bulwark',
        'push_hold',
        'push_strain',
        'push_strain_fire',
        'fire_spreads',
        'sail_sighted',
        'sail_arrives',
      ])
        'ship_log_$key',
      'ship_heavy_label',
      'ship_heavy_hint',
      'ship_weather_squall_coming',
      'ship_weather_squall_coming_hint',
      'ship_sail_coming_label',
      'ship_sail_coming_hint',
      'ship_consort_label',
      'ship_consort_hint',
    ];
    // The enemy's name stands without an article in French.
    final article = RegExp(r"\b(le|la|les|du|des|au|aux|l')\s*\{ship\}",
        caseSensitive: false);
    for (final key in keys) {
      final en = trFor(AppLanguage.en, key);
      expect(en, isNot(key), reason: key);
      final fr = trFor(AppLanguage.fr, key);
      // (A missing French falls back to the English.)
      expect(fr, isNot(en), reason: key);
      expect(article.hasMatch(fr), isFalse, reason: '$key: $fr');
    }
    expect(consortWeaponFor(_ship(weapons: const [_gun])).nameFor(true),
        'Canons du renfort');
  });

  group('intents: what the enemy means to do', () {
    test('a volley by default, and nothing but volleys without intents', () {
      final b = _battle();
      expect(b.intent, ShipIntent.volley);
      final off = _battle(
          habit: EnemyHabit.ram,
          rules: const ShipBattleRules(
              weather: false, seaEvents: false, intents: false));
      expect(off.intent, ShipIntent.volley);
    });

    test('its habit sets the range it steers for', () {
      final rammer = _battle(habit: EnemyHabit.ram);
      expect(rammer.intent, ShipIntent.closeIn);
      expect(rammer.intentRange, ShipRange.close);
      final marksman = _battle(habit: EnemyHabit.marksman);
      expect(marksman.intent, ShipIntent.pullAway);
      expect(marksman.intentRange, ShipRange.long);
      // A helm knocked out steers nowhere.
      final pinned = _battle(
          habit: EnemyHabit.marksman,
          enemy: _ship(
              levels: const {ShipRoom.helm: 0}, weapons: const [_theirGun]));
      expect(pinned.intent, ShipIntent.volley);
    });

    test(
        'guns hurt to a pip: a boarder comes alongside, a gunner goes where '
        'its guns reach', () {
      final b = _battle(
          habit: EnemyHabit.marksman,
          enemy: _ship(
              levels: const {ShipRoom.helm: 2, ShipRoom.guns: 2},
              weapons: const [_theirGun]),
          boarding: const BoardingProfile(crew: ['bandit']));
      expect(b.intent, ShipIntent.pullAway, reason: 'a marksman, guns whole');
      b.enemy =
          b.enemy.withRoom(ShipRoom.guns, const RoomState(level: 2, damage: 1));
      b.planEnemyTurn();
      expect(b.intent, ShipIntent.closeIn);
      expect(b.intentRange, ShipRange.close);

      // No crew to board with: where most of its guns reach.
      const shortGun = ShipWeapon(
          id: 'enemy_weapon_1',
          name: 'Short',
          nameFr: '',
          damage: 6,
          chargeTurns: 1,
          ranges: {ShipRange.close});
      final gunner = _battle(
          habit: EnemyHabit.marksman,
          enemy: _ship(
              levels: const {ShipRoom.helm: 2, ShipRoom.guns: 2},
              weapons: const [_theirGun, shortGun]));
      expect(gunner.intent, ShipIntent.pullAway);
      gunner.enemy = gunner.enemy
          .withRoom(ShipRoom.guns, const RoomState(level: 2, damage: 1));
      gunner.planEnemyTurn();
      expect(gunner.intent, ShipIntent.closeIn);
    });

    test('a boarder thrown back once stands off from a full bulwark', () {
      final b = _battle(
          habit: EnemyHabit.boarder,
          player: _ship(
              layers: 2,
              levels: const {ShipRoom.bulwark: 2},
              weapons: const [_gun]),
          boarding: const BoardingProfile(crew: ['wisp']));
      expect(b.intent, ShipIntent.closeIn);
      b.boardersRepelled();
      b.planEnemyTurn();
      expect(b.intent, ShipIntent.volley, reason: 'it holds at medium');
      b.range = ShipRange.close;
      b.planEnemyTurn();
      expect(b.intent, ShipIntent.pullAway);
      expect(b.intentRange, ShipRange.medium);
    });

    test('a hurt runner makes sail, unless its helm is out', () {
      final b = _battle(
          habit: EnemyHabit.flee,
          enemy: _ship(
              hull: 30,
              levels: const {ShipRoom.helm: 2},
              weapons: const [_theirGun]));
      expect(b.intent, ShipIntent.flee);
      expect(b.intentRange, ShipRange.long);
      final pinned = _battle(
          habit: EnemyHabit.flee,
          enemy: _ship(
              hull: 30,
              levels: const {ShipRoom.helm: 0},
              weapons: const [_theirGun]));
      expect(pinned.intent, isNot(ShipIntent.flee));
    });

    test(
        'guns out, holed or burning: all hands to the pumps, not twice '
        'running unless the guns are still out', () {
      final b = _battle(
          enemy: _ship(
              levels: const {ShipRoom.helm: 2, ShipRoom.guns: 1},
              weapons: const [_theirGun]));
      b.enemy = b.enemy.copyWith(leaks: 2);
      b.planEnemyTurn();
      expect(b.intent, ShipIntent.mend);
      b.turn++;
      b.planEnemyTurn();
      expect(b.intent, isNot(ShipIntent.mend), reason: 'not two running');
      b.enemy =
          b.enemy.withRoom(ShipRoom.guns, const RoomState(level: 1, damage: 1));
      b.turn++;
      b.planEnemyTurn();
      expect(b.intent, ShipIntent.mend);
      b.turn++;
      b.planEnemyTurn();
      expect(b.intent, ShipIntent.mend, reason: 'its guns are still out');
    });

    test('a rammer alongside comes about to ram', () {
      final b = _battle(habit: EnemyHabit.ram);
      b.range = ShipRange.close;
      b.planEnemyTurn();
      expect(b.intent, ShipIntent.ram);
    });

    test('its boarding party masses at the rail on its nerve, or eagerly', () {
      final b = _battle(
          boarding: const BoardingProfile(crew: ['bandit'], chance: 0.4));
      b.range = ShipRange.close;
      expect(b.enemyIntentFor(boardRoll: () => 0.3).intent, ShipIntent.board);
      expect(b.enemyIntentFor(boardRoll: () => 0.5).intent,
          isNot(ShipIntent.board));
      // An eager boarder comes on its third round alongside, nerve or not.
      final eager = _battle(
          habit: EnemyHabit.boarder,
          boarding: const BoardingProfile(crew: ['wisp']));
      eager.range = ShipRange.close;
      eager.roundsAlongside = 2;
      expect(
          eager.enemyIntentFor(boardRoll: () => 0.99).intent, ShipIntent.board);
      eager.roundsAlongside = 3;
      expect(eager.enemyIntentFor(boardRoll: () => 0.99).intent,
          ShipIntent.volley);
    });

    test(
        'a hurt ship braces when the Eel\'s ready guns would tear it open, '
        'once in three rounds', () {
      final b = _battle(
          player: _ship(weapons: const [_gun]),
          enemy: _ship(
              hull: 60,
              levels: const {ShipRoom.helm: 0},
              weapons: const [_theirGun]));
      expect(b.intent, isNot(ShipIntent.brace),
          reason: 'at 60 of 100 it is not hurt enough');
      b.enemy = b.enemy.copyWith(hull: 30);
      b.planEnemyTurn();
      expect(b.intent, isNot(ShipIntent.brace),
          reason: '12 of 30 could not all but sink it');
      b.enemy = b.enemy.copyWith(hull: 20);
      b.planEnemyTurn();
      expect(b.intent, ShipIntent.brace);
      expect(b.enemyBraced, isTrue);
      b.turn++;
      b.planEnemyTurn();
      expect(b.intent, isNot(ShipIntent.brace));
      b.turn += 2;
      b.planEnemyTurn();
      expect(b.intent, ShipIntent.brace);
    });

    test('the fog hides it', () {
      final b = _battle(habit: EnemyHabit.ram);
      expect(b.intentVisible, isTrue);
      b.weather = SeaWeather.fog;
      expect(b.intentVisible, isFalse);
    });

    test('a beast\'s shows what it does anyway', () {
      final b = _battle(
          enemy: _ship(
              hull: 200,
              maxHull: 200,
              levels: const {ShipRoom.helm: 2},
              weapons: const [_theirGun]),
          beast: const BeastProfile(diveEvery: 2, breach: 10));
      expect(b.intent, ShipIntent.volley, reason: 'round 1');
      b.turn = 2;
      expect(b.intent, ShipIntent.dive);
      b.tether = 1;
      expect(b.intent, ShipIntent.volley, reason: 'held on the line');
      b.tether = 0;
      b.beastTurning = true;
      expect(b.intent, ShipIntent.flee);
    });
  });

  group('intents: what the enemy does', () {
    test('pulled away from, the ram cuts empty water and waits', () {
      final b = _battle(
          habit: EnemyHabit.ram,
          player: _ship(layers: 1, weapons: const [_gun]));
      b.range = ShipRange.close;
      b.planEnemyTurn();
      expect(b.intent, ShipIntent.ram);
      b.maneuver(ShipRange.medium);
      b.startEnemyPhase();
      expect(b.rammed, isFalse, reason: 'not spent');
      expect(b.player.hull, 100);
      expect(b.log.any((l) => l.key == 'ship_log_intent_ram_missed'), isTrue);

      // Left alongside, it rams.
      final hit = _battle(habit: EnemyHabit.ram);
      hit.range = ShipRange.close;
      hit.planEnemyTurn();
      hit.startEnemyPhase();
      expect(hit.rammed, isTrue);
      expect(hit.player.hull, 100 - ramHullDamage);
    });

    test('pulled away from, the boarders are left at the rail', () {
      final b = _battle(
          player:
              _ship(levels: const {ShipRoom.bulwark: 0}, weapons: const [_gun]),
          boarding: const BoardingProfile(crew: ['bandit'], chance: 1));
      b.range = ShipRange.close;
      b.planEnemyTurn();
      expect(b.intent, ShipIntent.board);
      b.maneuver(ShipRange.medium);
      b.startEnemyPhase();
      expect(b.enemyBoards(), isNull);
      expect(b.log.any((l) => l.key == 'ship_log_intent_board_foiled'), isTrue);
      expect(b.enemyBoardingSpent, isFalse);

      // Alongside with the rail open, they come.
      final c = _battle(
          player:
              _ship(levels: const {ShipRoom.bulwark: 0}, weapons: const [_gun]),
          boarding: const BoardingProfile(crew: ['bandit'], chance: 1));
      c.range = ShipRange.close;
      c.planEnemyTurn();
      c.startEnemyPhase();
      expect(c.enemyBoards(), isNotNull);

      // A rail that holds keeps them aboard their own ship.
      final shut = _battle(
          player: _ship(layers: 1, weapons: const [_gun]),
          boarding: const BoardingProfile(crew: ['bandit'], chance: 1));
      shut.range = ShipRange.close;
      shut.planEnemyTurn();
      expect(shut.intent, ShipIntent.board);
      shut.startEnemyPhase();
      expect(shut.enemyBoards(), isNull);
      expect(
          shut.log.any((l) => l.key == 'ship_log_intent_board_held'), isTrue);
    });

    test('a round at the pumps: more repairs, and its guns hold fire', () {
      final b = _battle(
          enemy: _ship(
              levels: const {ShipRoom.helm: 2, ShipRoom.guns: 2},
              weapons: const [_theirGun]));
      b.enemy = b.enemy
          .withRoom(ShipRoom.guns, const RoomState(level: 2, damage: 2))
          .withRoom(ShipRoom.hold, const RoomState(level: 1, damage: 1));
      b.planEnemyTurn();
      expect(b.intent, ShipIntent.mend);
      b.startEnemyPhase();
      // One repair a round, and two more: both guns pips and the hold.
      expect(b.enemy.room(ShipRoom.guns).damage, 0);
      expect(b.enemy.room(ShipRoom.hold).damage, 0);
      expect(b.enemyVolley, isEmpty);
      expect(b.enemy.weapons.single.isReady, isTrue,
          reason: 'its guns charge still: the next volley is a full one');
      expect(b.log.any((l) => l.key == 'ship_log_intent_mend'), isTrue);
    });

    test('braced, it takes half the hull and holds its fire', () {
      final b = _battle(
          player: _ship(weapons: const [_gun]),
          enemy: _ship(
              hull: 20,
              levels: const {ShipRoom.helm: 0},
              weapons: const [_theirGun]));
      expect(b.intent, ShipIntent.brace);
      expect(b.preview('gun', ShipRoom.guns)!.hullDamage, 6);
      final shot = b.fire('gun', ShipRoom.guns)!;
      expect(shot.hullDamage, 6);
      expect(shot.roomDamage, 1, reason: 'the room\'s pips as ever');
      expect(b.log.any((l) => l.key == 'ship_log_intent_brace'), isTrue);
      b.startEnemyPhase();
      expect(b.enemyVolley, isEmpty);
    });

    test('a declared step answers the helm, or its helm is slow', () {
      // One helm pip: 70%.
      expect(intentHelmChance(_ship(levels: const {ShipRoom.helm: 1})), 0.7);
      expect(intentHelmChance(_ship(levels: const {ShipRoom.helm: 3})), 1.0);
      final slow = _battle(
          habit: EnemyHabit.ram,
          enemy: _ship(
              levels: const {ShipRoom.helm: 1}, weapons: const [_theirGun]),
          random: _Rolls()..fallback = 0.8);
      expect(slow.intent, ShipIntent.closeIn);
      slow.startEnemyPhase();
      expect(slow.range, ShipRange.medium);
      expect(slow.log.any((l) => l.key == 'ship_log_intent_helm_slow'), isTrue);
      final quick = _battle(
          habit: EnemyHabit.ram,
          enemy: _ship(
              levels: const {ShipRoom.helm: 1}, weapons: const [_theirGun]),
          random: _Rolls()..fallback = 0.6);
      quick.startEnemyPhase();
      expect(quick.range, ShipRange.close);
    });

    test('a ship that means to fire does not drift', () {
      final b = _battle(random: _Rolls()..fallback = 0.0);
      expect(b.intent, ShipIntent.volley);
      b.range = ShipRange.long;
      b.planEnemyTurn();
      // Habit none likes medium: it declares the step in, and takes it.
      expect(b.intent, ShipIntent.closeIn);
      b.startEnemyPhase();
      expect(b.range, ShipRange.medium);
      b.endRound();
      expect(b.intent, ShipIntent.volley);
      b.startEnemyPhase();
      expect(b.range, ShipRange.medium);
    });
  });

  group('push a room past its limit', () {
    test('the guns: every weapon a step closer, a gun one short fires now', () {
      final b = _battle(
          player: _ship(weapons: [_gun, _bigGun.withCharge(1)]), crew: [_you]);
      // The first turn charged every weapon a step.
      expect(b.weaponById('big')!.charge, 2);
      expect(b.canFire(b.weaponById('big')!), isFalse);
      expect(b.canPush(ShipRoom.guns), isTrue);
      b.pushRoom(ShipRoom.guns);
      expect(b.canFire(b.weaponById('big')!), isTrue);
      expect(b.log.any((l) => l.key == 'ship_log_push_guns'), isTrue);
      // Once a turn.
      expect(b.canPush(ShipRoom.helm), isFalse);
      expect(b.pushes, 1);
    });

    test('the helm: harder to hit this round, not the next', () {
      final b = _battle();
      final before = b.playerEvasion;
      b.pushRoom(ShipRoom.helm);
      expect(b.playerEvasion, before + pushEvasion);
      b.startEnemyPhase();
      b.endRound();
      expect(b.helmPushed, isFalse);
      expect(b.canPush(ShipRoom.helm), isTrue, reason: 'a new turn');
    });

    test('the bulwark: a layer past what it holds, never past three', () {
      final b = _battle(
          player: _ship(
              layers: 1,
              levels: const {ShipRoom.bulwark: 1},
              weapons: const [_gun]));
      expect(b.player.maxLayers, 1);
      b.pushRoom(ShipRoom.bulwark);
      expect(b.player.layers, 2);
      final full = _battle(
          player: _ship(
              layers: 3,
              levels: const {ShipRoom.bulwark: 3},
              weapons: const [_gun]));
      expect(full.canPush(ShipRoom.bulwark), isFalse);
    });

    test('the hold: a leak bailed and hull patched', () {
      final b = _battle(player: _ship(hull: 50, weapons: const [_gun]));
      b.player = b.player.copyWith(leaks: 2);
      b.pushRoom(ShipRoom.hold);
      expect(b.player.leaks, 1);
      expect(b.player.hull, 50 + pushHullPatch);
      final whole = _battle();
      expect(whole.canPush(ShipRoom.hold), isFalse, reason: 'nothing to do');
    });

    test('strain: 30%, 20 more each push, 10 less with a hand there', () {
      expect(pushStrainFor(pushes: 0, manned: false), 30);
      expect(pushStrainFor(pushes: 0, manned: true), 20);
      expect(pushStrainFor(pushes: 1, manned: false), 50);
      expect(pushStrainFor(pushes: 2, manned: false), 70);
      expect(pushStrainFor(pushes: 9, manned: false), pushStrainMax);
      final b = _battle();
      // You stand at the helm.
      expect(b.pushStrainChance(ShipRoom.helm), 20);
      expect(b.pushStrainChance(ShipRoom.guns), 30);
    });

    test('a strained room loses a pip; under a third of the chance it burns',
        () {
      // Rolls: the enemy's aim, then the strain.
      final b = _battle(
          player:
              _ship(levels: const {ShipRoom.guns: 2}, weapons: const [_bigGun]),
          random: _Rolls([0.5, 0.20]));
      b.pushRoom(ShipRoom.guns);
      expect(b.player.room(ShipRoom.guns).damage, 1);
      expect(b.player.room(ShipRoom.guns).onFire, isFalse);
      expect(b.log.last.key, 'ship_log_push_strain');
      final burnt = _battle(
          player:
              _ship(levels: const {ShipRoom.guns: 2}, weapons: const [_bigGun]),
          random: _Rolls([0.5, 0.05]));
      burnt.pushRoom(ShipRoom.guns);
      expect(burnt.player.room(ShipRoom.guns).onFire, isTrue);
      expect(burnt.log.last.key, 'ship_log_push_strain_fire');
      final spared = _battle(
          player:
              _ship(levels: const {ShipRoom.guns: 2}, weapons: const [_bigGun]),
          random: _Rolls([0.5, 0.30]));
      spared.pushRoom(ShipRoom.guns);
      expect(spared.player.room(ShipRoom.guns).damage, 0);
    });

    test(
        'not a room knocked out, not once the battle is over, not without '
        'the rule', () {
      final b = _battle(
          player:
              _ship(levels: const {ShipRoom.helm: 0}, weapons: const [_gun]));
      expect(b.canPush(ShipRoom.helm), isFalse);
      b.end = BattleEnd.won;
      expect(b.canPushAny, isFalse);
      final off = _battle(
          rules: const ShipBattleRules(
              weather: false, seaEvents: false, push: false));
      expect(off.canPushAny, isFalse);
    });
  });

  group('the battle gets worse', () {
    test('a fire nobody fights spreads after two round-ends, not after one',
        () {
      // Nobody aboard to fight it; every roll a spread.
      final b = _battle(
          crew: const [],
          player: _ship(weapons: const [_gun]),
          random: _Rolls()..fallback = 0.0);
      b.player = b.player
          .withRoom(ShipRoom.guns, const RoomState(level: 3, onFire: true));
      b.startEnemyPhase();
      b.endRound();
      expect(b.log.any((l) => l.key == 'ship_log_fire_spreads'), isFalse);
      expect(b.player.room(ShipRoom.guns).onFire, isTrue);
      b.startEnemyPhase();
      b.endRound();
      final spread = b.log.where((l) => l.key == 'ship_log_fire_spreads');
      expect(spread, hasLength(1));
      expect(spread.single.side, BattleSide.eel);
      // Helm or bulwark, beside the guns.
      expect(spread.single.room, isIn([ShipRoom.helm, ShipRoom.bulwark]));
      expect(b.player.room(spread.single.room!).onFire, isTrue);
    });

    test('without the rule a fire stays where it is', () {
      final b = _battle(
          crew: const [],
          rules: const ShipBattleRules(
              weather: false, seaEvents: false, escalation: false),
          random: _Rolls()..fallback = 0.0);
      b.player = b.player
          .withRoom(ShipRoom.guns, const RoomState(level: 3, onFire: true));
      for (var i = 0; i < 2; i++) {
        b.startEnemyPhase();
        b.endRound();
      }
      expect(b.log.any((l) => l.key == 'ship_log_fire_spreads'), isFalse);
    });

    test('each leak makes a ship heavy: 5 evasion off', () {
      final b = _battle(
          enemy: _ship(
              levels: const {ShipRoom.helm: 3}, weapons: const [_theirGun]));
      final eel = b.playerEvasion;
      final them = b.enemyEvasion;
      b.player = b.player.copyWith(leaks: 2);
      b.enemy = b.enemy.copyWith(leaks: 1);
      expect(b.playerEvasion, eel - 2 * leakEvasion);
      expect(b.enemyEvasion, them - leakEvasion);
    });

    test('the weather keeps a trend: never calm to squall', () {
      for (var i = 0; i < 100; i++) {
        final roll = i / 100;
        expect(nextWeatherFor(SeaWeather.calm, roll), isNot(SeaWeather.squall));
        expect(nextWeatherFor(SeaWeather.tailwind, roll),
            isNot(SeaWeather.squall));
        expect(nextWeatherFor(SeaWeather.fog, roll),
            isIn([SeaWeather.fog, SeaWeather.calm]));
      }
      expect(nextWeatherFor(SeaWeather.crosswind, 0.0), SeaWeather.crosswind);
      expect(nextWeatherFor(SeaWeather.crosswind, 0.36), SeaWeather.squall);
      expect(nextWeatherFor(SeaWeather.squall, 0.99), SeaWeather.calm);
      for (final weights in weatherTrend.values) {
        expect(weights.values.fold<int>(0, (a, b) => a + b), 100);
      }
    });

    test('a second sail: from round 6, three round-ends out, once', () {
      final b = _battle(
          enemy: _ship(
              levels: const {ShipRoom.helm: 0},
              weapons: const [_theirGun, _bigGun]),
          random: _Rolls()..fallback = 0.0);
      for (var round = 1; round < sailFromRound; round++) {
        b.startEnemyPhase();
        b.endRound();
      }
      expect(b.sailSighted, isFalse, reason: 'not before round 6');
      b.player = b.player.copyWith(hull: 100);
      b.startEnemyPhase();
      b.endRound();
      expect(b.sailSighted, isTrue);
      expect(b.sailIn, sailRounds);
      expect(b.log.last.key, isNot('ship_log_sail_arrives'));
      for (var i = 0; i < sailRounds; i++) {
        expect(b.consortArrived, isFalse);
        b.player = b.player.copyWith(hull: 100);
        b.startEnemyPhase();
        b.endRound();
      }
      expect(b.consortArrived, isTrue);
      final consort =
          b.enemy.weapons.firstWhere((w) => w.id == consortWeaponId);
      expect(consort.damage, 22, reason: 'the enemy\'s biggest gun');
      expect(consort.ranges, {ShipRange.medium, ShipRange.long});
      expect(b.log.any((l) => l.key == 'ship_log_sail_arrives'), isTrue);
      for (var i = 0; i < 10; i++) {
        b.player = b.player.copyWith(hull: 100);
        b.startEnemyPhase();
        b.endRound();
      }
      expect(
          b.enemy.weapons.where((w) => w.id == consortWeaponId), hasLength(1),
          reason: 'once a battle');
    });

    test('with its friend up, a ship that closes stands off where both reach',
        () {
      final b = _battle(habit: EnemyHabit.ram);
      b.range = ShipRange.close;
      b.rammed = true;
      b.planEnemyTurn();
      expect(b.intent, ShipIntent.volley, reason: 'it likes it close');
      b.enemy = b.enemy
          .copyWith(weapons: [...b.enemy.weapons, consortWeaponFor(b.enemy)]);
      b.planEnemyTurn();
      expect(b.intent, ShipIntent.pullAway);
      expect(b.intentRange, ShipRange.medium);
    });

    test('a hurt raider waits for its friend on the horizon', () {
      final b = _battle(
          habit: EnemyHabit.flee,
          enemy: _ship(
              hull: 30,
              levels: const {ShipRoom.helm: 2},
              weapons: const [_theirGun]));
      expect(b.intent, ShipIntent.flee);
      b.sailIn = 2;
      b.planEnemyTurn();
      expect(b.intent, isNot(ShipIntent.flee));
      // Far off, it does not slip away while it waits.
      b.range = ShipRange.long;
      b.planEnemyTurn();
      b.startEnemyPhase();
      expect(b.end, isNull);
      // Too hurt to wait.
      b.enemy = b.enemy.copyWith(hull: 20);
      b.planEnemyTurn();
      expect(b.intent, ShipIntent.flee);
    });

    test('no friend comes for a beast', () {
      final b = _battle(
          enemy: _ship(hull: 500, maxHull: 500, weapons: const [_theirGun]),
          beast: const BeastProfile(),
          random: _Rolls()..fallback = 0.0);
      for (var round = 1; round < 12 && !b.over; round++) {
        b.player = b.player.copyWith(hull: 100);
        b.startEnemyPhase();
        b.endRound();
      }
      expect(b.sailSighted, isFalse);
    });
  });
}
