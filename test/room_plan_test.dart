// The inside of a building (v1.207, see room_plan.dart): every kind lays
// out a door, a floor and its named spots within its walls; a way out
// leaves by the back door from the back rooms; a walk between two rooms
// goes through the doorway; the plan is kept once laid; and the painter
// draws every kind. The geography knows a building as a level below the
// district, where a scene can stand.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/room_plan.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/widgets/room_plan_painter.dart';

void main() {
  group('RoomPlan', () {
    test('every kind has a door, a floor and its spots within the walls', () {
      for (final kind in [...geoBuildingKinds, 'something_else']) {
        final plan = RoomPlan.of(seed: 7, kind: kind);
        expect(plan.has('door'), isTrue, reason: kind);
        expect(plan.has('floor'), isTrue, reason: kind);
        expect(plan.doors.any((d) => d.id == 'door'), isTrue, reason: kind);
        expect(plan.rooms, isNotEmpty, reason: kind);
        final frame = plan.frame;
        for (final entry in plan.anchors.entries) {
          expect(frame.contains(entry.value), isTrue,
              reason: '$kind ${entry.key}');
        }
        for (final f in plan.furniture) {
          expect(frame.inflate(10).contains(f.centre), isTrue,
              reason: '$kind ${f.kind.name}');
        }
        // The floor is in a room.
        expect(plan.rooms.any((r) => r.rect.contains(plan.anchorOf('floor'))),
            isTrue,
            reason: kind);
      }
      expect(RoomPlan.of(seed: 1, kind: 'something_else').kind, RoomKind.plain);
    });

    test('the den: the Blind Beggar has its bar, tables, cage and gallery', () {
      final den = RoomPlan.of(seed: 3, kind: 'den');
      for (final spot in [
        'bar',
        'tables',
        'cage',
        'gallery',
        'counting',
        'strongbox',
        'stairs',
        'back',
        'front'
      ]) {
        expect(den.has(spot), isTrue, reason: spot);
      }
      expect(den.furniture.where((f) => f.kind == FurnitureKind.table).length,
          greaterThanOrEqualTo(8));
      expect(den.furniture.any((f) => f.kind == FurnitureKind.cage), isTrue);
      expect(den.furniture.any((f) => f.kind == FurnitureKind.bar), isTrue);
      // An unknown spot falls to the floor.
      expect(den.anchorOf('moon'), den.anchorOf('floor'));
      expect(den.anchorOf(''), den.anchorOf('floor'));
    });

    test('a way out leaves by the back door from the back rooms', () {
      final den = RoomPlan.of(seed: 3, kind: 'den');
      expect(den.exitFrom('tables'), 'back');
      expect(den.exitFrom('gallery'), 'back');
      expect(den.exitFrom('counting'), 'back');
      expect(den.exitFrom('bar'), 'door');
      expect(den.exitFrom('front'), 'door');
      // A house with no back door leaves by the front.
      final hall = RoomPlan.of(seed: 3, kind: 'hall');
      expect(hall.has('back'), isFalse);
      expect(hall.exitFrom('dais'), 'door');
    });

    test('a walk between two rooms goes through the doorway', () {
      final den = RoomPlan.of(seed: 3, kind: 'den');
      final across = den.route(den.anchorOf('bar'), den.anchorOf('tables'));
      expect(across.length, 3);
      final doorway = den.doors.firstWhere((d) => d.id == 'inner');
      expect(across[1], doorway.at);
      final within = den.route(den.anchorOf('tables'), den.anchorOf('cage'));
      expect(within.length, 2);
    });

    test('kept once laid, and laid anew for another seed or kind', () {
      final a = RoomPlan.of(seed: 11, kind: 'tavern');
      expect(identical(a, RoomPlan.of(seed: 11, kind: 'tavern')), isTrue);
      expect(identical(a, RoomPlan.of(seed: 12, kind: 'tavern')), isFalse);
      expect(identical(a, RoomPlan.of(seed: 11, kind: 'inn')), isFalse);
      expect(RoomKind.of('cave').rough, isTrue);
      expect(RoomKind.of('temple').stone, isTrue);
      expect(RoomKind.of('tavern').stone, isFalse);
    });

    testWidgets('the painter draws every kind', (tester) async {
      for (final kind in geoBuildingKinds) {
        final plan = RoomPlan.of(seed: 5, kind: kind);
        final frame = plan.frame;
        final scale = 300 / frame.longestSide;
        final origin = Offset(
            150 - frame.center.dx * scale, 150 - frame.center.dy * scale);
        await tester.pumpWidget(MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: CustomPaint(
                painter: RoomPlanPainter(
                  plan: plan,
                  scale: scale,
                  origin: origin,
                  palette: ChartPalette.of(MapLook.night),
                  ember: const Color(0xFFE0762B),
                ),
              ),
            ),
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: kind);
      }
    });
  });

  group('a building in the geography', () {
    final world = Geography.parse(geography: {
      'alster': {'level': 'location', 'parent': '', 'kind': 'city'},
      'lower': {'level': 'district', 'parent': 'alster', 'glyph': 'slum'},
      'beggar': {
        'level': 'building',
        'parent': 'lower',
        'kind': 'den',
        'name': 'The Blind Beggar',
      },
    });

    test('stands in its district, below it, where a scene can be', () {
      final beggar = world.place('beggar')!;
      expect(beggar.level, GeoLevel.building);
      expect(beggar.isBuilding, isTrue);
      expect(beggar.isSpot, isTrue);
      expect(beggar.kind, 'den');
      expect(world.locationOf('beggar')!.id, 'alster');
      expect(world.pathOf('beggar').map((p) => p.id),
          ['alster', 'lower', 'beggar']);
      expect(world.childrenOf('lower').single.id, 'beggar');
      expect(geoLevelNamed('building'), GeoLevel.building);
    });

    test('a scene and a way keep their spot in the file', () {
      final node = StoryNode.fromJson('100', {
        'id': '100',
        'description': 'At the tables.',
        'location': 'beggar',
        'spot': 'tables',
        'choices': [
          {'text': 'To the bar', 'next_id': '105', 'spot': 'bar'},
          {'text': 'Out', 'next_id': '250'},
        ],
      });
      expect(node.spot, 'tables');
      expect(node.choices[0].spot, 'bar');
      expect(node.choices[1].spot, isNull);
      final json = node.toJson();
      expect(json['spot'], 'tables');
      expect((json['choices'] as List)[0]['spot'], 'bar');
      expect((json['choices'] as List)[1].containsKey('spot'), isFalse);
      expect(world.placeOfNode(node)!.id, 'beggar');
    });

    test('the Blind Beggar is in the game\'s geography, at its tables', () {
      // Read straight from the asset, as the game does.
      expect(worldMapLandmarks.any((l) => l.id == 'beggar'), isTrue);
    });
  });

  group('Kinds and variants by name (v1.210)', () {
    test('a name says what the building is, in English or French', () {
      expect(RoomKind.resolve('house', 'The Gilded Casino'), 'casino');
      expect(RoomKind.resolve('hall', 'North Barracks'), 'barracks');
      expect(RoomKind.resolve('', 'Caserne du Port'), 'barracks');
      expect(RoomKind.resolve('hall', "Saint Orla's Chapel"), 'temple');
      expect(RoomKind.resolve('house', 'Église Saint-Orla'), 'temple');
      expect(RoomKind.resolve('hall', 'The Old Gaol'), 'prison');
      expect(RoomKind.resolve('house', 'Ashby Smithy'), 'forge');
      expect(RoomKind.resolve('house', 'The Grey Inn'), 'inn');
      // The kind stands when the name says nothing, and a word inside
      // another word says nothing.
      expect(RoomKind.resolve('den', 'The Blind Beggar'), 'den');
      expect(RoomKind.resolve('house', 'Linnet House'), 'house');
      expect(RoomKind.resolve('house', 'Gatekeeper Row'), 'house');
    });

    test('each new kind is laid with its own spots and its own look', () {
      final spots = {
        'casino': ['wheel', 'tables', 'cashier', 'vip', 'vault', 'back'],
        'barracks': ['bunks', 'mess', 'armoury', 'officers', 'guard', 'back'],
        'library': ['stacks', 'reading', 'archive', 'scriptorium', 'counter'],
        'prison': ['cells', 'cell1', 'cell10', 'guard', 'back'],
        'forge': ['anvil', 'forge', 'trough', 'store', 'back'],
        'theatre': ['stage', 'pit', 'seats', 'dressing', 'props', 'back'],
        'baths': ['pool', 'hot', 'cold', 'changing', 'back'],
      };
      for (final entry in spots.entries) {
        final plan = RoomPlan.of(seed: 4, kind: entry.key);
        expect(plan.kind, RoomKind.of(entry.key), reason: entry.key);
        expect(plan.kind, isNot(RoomKind.plain), reason: entry.key);
        for (final spot in entry.value) {
          expect(plan.has(spot), isTrue, reason: '${entry.key} $spot');
        }
        // No spot falls on a piece of furniture (but the stage, which the
        // party stands on).
        for (final spot in entry.value) {
          final at = plan.anchorOf(spot);
          expect(
              plan.furniture.any(
                  (f) => f.kind != FurnitureKind.stage && f.rect.contains(at)),
              isFalse,
              reason: '${entry.key} $spot');
        }
      }
      // A way out from the cells leaves by the back gate, from the
      // guardroom by the front door.
      final prison = RoomPlan.of(seed: 4, kind: 'prison');
      expect(prison.exitFrom('cell3'), 'back');
      expect(prison.exitFrom('guard'), 'door');
    });

    test('a seed picks a temple and an inn their shape', () {
      final nave = RoomPlan.of(seed: 9, kind: 'temple');
      final cross = RoomPlan.of(seed: 7, kind: 'temple');
      final round = RoomPlan.of(seed: 5, kind: 'temple');
      expect(nave.outline.length, 4);
      expect(cross.outline.length, 12);
      expect(round.outline.length, greaterThan(20));
      for (final plan in [nave, cross, round]) {
        expect(plan.has('altar'), isTrue);
        expect(plan.has('door'), isTrue);
      }
      final street = RoomPlan.of(seed: 9, kind: 'inn');
      final yard = RoomPlan.of(seed: 7, kind: 'inn');
      expect(street.outline.length, 4);
      expect(yard.outline.length, 8);
      for (final plan in [street, yard]) {
        for (final spot in ['bar', 'hearth', 'kitchen', 'rooms', 'stairs']) {
          expect(plan.has(spot), isTrue, reason: spot);
        }
      }
    });
  });
}
