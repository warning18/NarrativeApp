// The ship battle's pixel-art cutaways: every ship has its sprite, the
// enemy's is picked by its id (or its size), the Eel's by her refit, a
// ship below half its hull is drawn battered, and each room's tile sits
// on its room inside the hull.
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/screens/ship_battle_panel.dart';
import 'package:narrative_data_app/widgets/ship_cutaway.dart';

ShipState _eel({int level = 1}) => ShipState(
      hull: 100,
      maxHull: 100,
      layers: 0,
      rooms: {
        for (final room in ShipRoom.values) room: RoomState(level: level),
      },
      weapons: const [
        ShipWeapon(
            id: 'ballista',
            name: 'Ballista',
            nameFr: 'Baliste',
            damage: 12,
            chargeTurns: 1),
      ],
    );

ShipState _enemy({int maxHull = 80, int? hull}) {
  final ship = buildEnemyShip({
    'maxHull': maxHull,
    'rooms': {'helm': 1, 'guns': 1, 'bulwark': 1, 'hold': 1},
    'weapons': [
      {'weaponName': 'Slow Gun', 'damage': 5, 'chargeTurns': 9},
    ],
  });
  return hull == null ? ship : ship.copyWith(hull: hull);
}

String _assetOf(WidgetTester tester, String key) {
  final image = tester.widget<Image>(find.byKey(Key(key)));
  return (image.image as AssetImage).assetName;
}

void main() {
  test('every sprite the battle can ask for is on disk', () {
    final paths = {
      for (final battered in [false, true]) ...[
        for (final refit in [0, 1, 2])
          ShipCutaway.rustyEel.asset(battered: battered, refit: refit),
        for (final c in ShipCutaway.enemies) c.asset(battered: battered),
      ],
    };
    // The Eel at three refits, four ships and three sea beasts, each whole
    // and battered.
    expect(paths, hasLength(20));
    for (final path in paths) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/visuals/ship_cutaways/'));
  });

  test('an enemy is drawn by its id, or by its size without one', () {
    expect(ShipCutaway.forEnemy('void_barge', _enemy()).id, 'void_barge');
    expect(ShipCutaway.forEnemy(null, _enemy(maxHull: 60)).id, 'raider_skiff');
    expect(
        ShipCutaway.forEnemy('ghost', _enemy(maxHull: 80)).id, 'corsair_brig');
    expect(ShipCutaway.forEnemy(null, _enemy(maxHull: 95)).id,
        'inquisition_cutter');
    expect(ShipCutaway.forEnemy(null, _enemy(maxHull: 200)).id, 'void_barge');
  });

  test('the Eel shows her refits: level 2 rooms, then level 3', () {
    expect(ShipCutaway.refitOf(_eel(level: 1)), 0);
    expect(ShipCutaway.refitOf(_eel(level: 2)), 1);
    expect(ShipCutaway.refitOf(_eel(level: 3)), 2);
  });

  test('a mirrored room keeps its size and flips its place', () {
    const eel = ShipCutaway.rustyEel;
    final helm = eel.roomRect(ShipRoom.helm, 390, flip: false);
    final flipped = eel.roomRect(ShipRoom.helm, 390, flip: true);
    expect(flipped.size, helm.size);
    expect(flipped.right, closeTo(390 - helm.left, 0.001));
    // Big enough to tap.
    for (final c in [eel, ...ShipCutaway.enemies]) {
      for (final room in ShipRoom.values) {
        final r = c.roomRect(room, 358, flip: false);
        expect(r.width, greaterThanOrEqualTo(60), reason: '${c.id} $room');
        expect(r.height, greaterThanOrEqualTo(40), reason: '${c.id} $room');
      }
    }
  });

  testWidgets('the panel draws both ships and puts each room on its room',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: ShipBattlePanel(
            player: _eel(level: 2),
            enemy: _enemy(maxHull: 140, hull: 60),
            shipName: 'The Rusty Eel',
            enemyName: 'Void Barge',
            enemyShipId: 'void_barge',
            crew: const [
              ShipCrew(
                id: 'player',
                name: 'Ada',
                strength: 3,
                dexterity: 3,
                constitution: 3,
                wisdom: 3,
                health: 50,
                maxHealth: 50,
                isPlayer: true,
              ),
            ],
            foresight: false,
            random: Random(4),
            rules: const ShipBattleRules(seaEvents: false),
            onFinished: (_) {},
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(_assetOf(tester, 'ship_sprite_eel'),
        'assets/visuals/ship_cutaways/rusty_eel_1.png');
    // Below half its hull: battered.
    expect(_assetOf(tester, 'ship_sprite_enemy'),
        'assets/visuals/ship_cutaways/void_barge_battered.png');

    for (final side in ['eel', 'enemy']) {
      final hull = tester.getRect(find.byKey(Key('ship_hull_$side')));
      final helm = tester.getRect(find.byKey(Key('ship_room_${side}_helm')));
      final hold = tester.getRect(find.byKey(Key('ship_room_${side}_hold')));
      expect(hull.contains(helm.center), isTrue, reason: side);
      expect(hold.top, greaterThan(helm.bottom), reason: side);
      // The Eel's helm is aft, on the left; the enemy faces her, so its
      // helm is on the right.
      if (side == 'eel') {
        expect(helm.center.dx, lessThan(hull.center.dx));
      } else {
        expect(helm.center.dx, greaterThan(hull.center.dx));
      }
    }
  });
}
