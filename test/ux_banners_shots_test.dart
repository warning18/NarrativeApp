// The 20 banners at game size (UX_SHOTS=<folder>, UX_TAG=before|after), on the
// Tower's dark and on parchment. Drawn only with UX_SHOTS.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/pixel_banner.dart';

const _names = [
  'clan_choir', 'clan_compact', 'clan_crows', 'clan_dominion', 'clan_giants',
  'clan_kindly', 'clan_mire', 'clan_oni', 'clan_open_hand', 'clan_penitents',
  'clan_pit', 'clan_tidekin', 'clan_vigil', 'heirloom_shroud',
  'moon_shard_shroud', 'reliquary_thread', 'sovereign_mantle',
  'void_standard', 'warden_standard', 'white_fleet_sail', //
];

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final tag = Platform.environment['UX_TAG'] ?? 'after';

  testWidgets('the 20 banners', skip: shots == null, (tester) async {
    for (final dark in [true, false]) {
      final key = GlobalKey();
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: Container(
              color: dark ? const Color(0xFF10141F) : const Color(0xFFF2E8D0),
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final n in _names) PixelBanner(id: n, scale: 2),
                ],
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 200)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      late List<int> bytes;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
      });
      Directory(shots!).createSync(recursive: true);
      File('$shots/banners-${dark ? 'dark' : 'light'}-$tag.png')
          .writeAsBytesSync(bytes);
    }
  });
}
