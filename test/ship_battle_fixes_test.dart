// v1.158: the fixes from the review of the v1.153 ship battle. The clock
// setting is waited for; a knocked-out helm slips nothing; a chain shot on
// the helm is logged and previewed in full; Liora's and Malrik's orders
// wait for a turn a gun can fire; the Void Barge boards every third round
// alongside (see ship_battle_test.dart); the Harbor reads a weapon's reach
// with the battle's own parser.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/providers/combat_settings_provider.dart';

ShipState _ship({
  Map<ShipRoom, int> levels = const {},
  List<ShipWeapon> weapons = const [],
}) =>
    ShipState(
      hull: 100,
      maxHull: 100,
      layers: 0,
      rooms: {
        for (final room in ShipRoom.values)
          room: RoomState(level: levels[room] ?? 1),
      },
      weapons: weapons,
    );

const _gun = ShipWeapon(
    id: 'gun', name: 'Gun', nameFr: 'Canon', damage: 12, chargeTurns: 1);
const _slowGun = ShipWeapon(
    id: 'slow', name: 'Slow', nameFr: 'Lent', damage: 12, chargeTurns: 3);

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

void main() {
  group('the clock setting', () {
    test('is read only once the saved choice is in', () async {
      SharedPreferences.setMockInitialValues(
          {'ship_turn_timer_enabled': false});
      final flag =
          PersistedFlagNotifier('ship_turn_timer_enabled', defaultValue: true);
      expect(flag.state, isTrue, reason: 'the default, for a moment');
      await flag.loaded;
      expect(flag.state, isFalse);
      flag.dispose();
    });

    test('a choice made before the saved one arrives wins', () async {
      SharedPreferences.setMockInitialValues({'combat_tremble_enabled': false});
      final flag =
          PersistedFlagNotifier('combat_tremble_enabled', defaultValue: true);
      await flag.setEnabled(true);
      await flag.loaded;
      expect(flag.state, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('combat_tremble_enabled'), isTrue);
      flag.dispose();
    });
  });

  test('a knocked-out helm slips nothing, far off or in any wind', () {
    final steering = _ship(levels: const {ShipRoom.helm: 2});
    final adrift =
        steering.withRoom(ShipRoom.helm, const RoomState(level: 2, damage: 2));
    for (final weather in SeaWeather.values) {
      expect(
          battleEvasion(adrift,
              range: ShipRange.long,
              weather: weather,
              eel: false,
              bonus: quickOrdersEvasion),
          0,
          reason: weather.name);
    }
    expect(
        battleEvasion(steering,
            range: ShipRange.long, weather: SeaWeather.crosswind, eel: false),
        greaterThan(0));
  });

  group('chain shot on the helm', () {
    test('the preview shows both pips it tears off', () {
      final target = _ship(levels: const {ShipRoom.helm: 3});
      final preview = previewShot(
          target: target,
          weapon: _gun,
          room: ShipRoom.helm,
          mods: ammoMods(ShipAmmo.chain));
      expect(preview.roomDamage, 2);
      expect(preview.target.room(ShipRoom.helm).damage, 2);
    });

    test('knocking the helm out is logged, aimed at it or elsewhere', () {
      ShipBattle battle(Map<ShipRoom, int> levels) => ShipBattle(
            player: _ship(weapons: const [_gun]),
            enemy: _ship(levels: levels),
            crew: [_member('player', player: true)],
            random: Random(1),
            rules: ShipBattleRules.classic,
          )..ammo = ShipAmmo.chain;

      bool helmDownLogged(ShipBattle b) => b.log
          .any((l) => l.key == 'ship_log_room_down' && l.room == ShipRoom.helm);

      // Its own pip and the tear: a two-pip helm goes down.
      final onHelm = battle(const {ShipRoom.helm: 2});
      final shot = onHelm.fire('gun', ShipRoom.helm)!;
      expect(shot.roomKnockedOut, isTrue);
      expect(helmDownLogged(onHelm), isTrue);

      // Aimed at the guns, the tear alone takes a one-pip helm down.
      final elsewhere = battle(const {ShipRoom.helm: 1, ShipRoom.guns: 3});
      final other = elsewhere.fire('gun', ShipRoom.guns)!;
      expect(other.helmKnockedOut, isTrue);
      expect(helmDownLogged(elsewhere), isTrue);
    });
  });

  test('eagle eye and the mark wait for a turn a gun can fire', () {
    final liora = _member('liora');
    final malrik = _member('malrik');
    ShipBattle battle(List<ShipWeapon> weapons) => ShipBattle(
          player: _ship(weapons: weapons),
          enemy: _ship(),
          crew: [_member('player', player: true), liora, malrik],
          random: Random(2),
          rules: ShipBattleRules.classic,
        );
    final silent = battle(const [_slowGun]);
    expect(silent.anyShotReady, isFalse);
    expect(silent.canOrder(liora), isFalse);
    expect(silent.canOrder(malrik), isFalse);
    final ready = battle(const [_gun, _slowGun]);
    expect(ready.anyShotReady, isTrue);
    expect(ready.canOrder(liora), isTrue);
    expect(ready.canOrder(malrik), isTrue);
  });

  test('a weapon\'s reach: its ranges, every one when it names none', () {
    expect(weaponRangesFrom(['close', 'nowhere']), {ShipRange.close});
    expect(weaponRangesFrom(['medium', 'long']),
        {ShipRange.medium, ShipRange.long});
    expect(weaponRangesFrom(null), ShipRange.values.toSet());
    expect(weaponRangesFrom(['nowhere']), ShipRange.values.toSet());
  });
}
