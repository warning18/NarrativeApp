// The sea fight from above: each port's waters, the rooms laid along the
// deck stern to bow, and every sea under every weather painting cleanly.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/ship_battle.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/widgets/sea_battlefield.dart';

void main() {
  test('every port names waters the sea knows', () {
    final ports =
        jsonDecode(File('assets/gamedata/ports.json').readAsStringSync())
            as Map;
    final names = {for (final w in SeaWaters.values) w.name};
    for (final entry in ports.entries) {
      final waters = (entry.value as Map)['waters'];
      expect(names, contains(waters), reason: entry.key as String);
      expect(seaWatersFor(name: waters as String).name, waters);
    }
  });

  test('waters fall back on the port, then on the open sea', () {
    expect(seaWatersFor(portId: 'port_drowned_stair'), SeaWaters.drowned);
    expect(seaWatersFor(name: 'nonsense', portId: 'port_black_reliquary'),
        SeaWaters.abyss);
    expect(seaWatersFor(), SeaWaters.open);
  });

  test('rooms lie stern to bow, apart, inside the hull band', () {
    for (final look in [TopShipLook.rustyEel, ...TopShipLook.enemies]) {
      const width = 320.0;
      final box = Size(width, topShipBoxHeight(width, look));
      final band = topShipHullBand(box, look);
      for (final flip in [false, true]) {
        final order = [
          ShipRoom.helm,
          ShipRoom.hold,
          ShipRoom.guns,
          ShipRoom.bulwark
        ];
        final rects = [
          for (final r in order) topShipRoomRect(r, box, look, flip: flip)
        ];
        for (var i = 0; i < rects.length; i++) {
          expect(band.contains(rects[i].center), isTrue);
          expect(rects[i].width, greaterThan(50), reason: look.id);
          if (i > 0) {
            final a = rects[i - 1], b = rects[i];
            expect(a.overlaps(b), isFalse, reason: '${look.id} $flip');
            expect(flip ? b.center.dx < a.center.dx : b.center.dx > a.center.dx,
                isTrue);
          }
        }
      }
    }
  });

  test('every sea paints under every weather, with its ships', () {
    const size = Size(390, 420);
    for (final waters in SeaWaters.values) {
      for (final weather in SeaWeather.values) {
        for (final t in [0.0, 3.7, 61.2]) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          SeaSurfacePainter(waters: waters, weather: weather, t: t)
              .paint(canvas, size);
          for (final look in [TopShipLook.rustyEel, ...TopShipLook.enemies]) {
            TopShipPainter(
              look: look,
              flip: look != TopShipLook.rustyEel,
              facingDown: look != TopShipLook.rustyEel,
              t: t,
              layers: 1,
              maxLayers: 2,
              battered: t > 1,
              down: const {ShipRoom.helm},
              burning: const {ShipRoom.guns},
              water: 0.5,
              shield: Colors.blueGrey,
              foam: Colors.white,
              roomColors: {for (final r in ShipRoom.values) r: Colors.teal},
              refit: 2,
            ).paint(canvas, const Size(320, 160));
          }
          SeaWeatherPainter(
            waters: waters,
            weather: weather,
            t: t,
            enemyBand: const Rect.fromLTWH(0, 20, 390, 150),
          ).paint(canvas, size);
          recorder.endRecording().dispose();
        }
      }
    }
  });
}
