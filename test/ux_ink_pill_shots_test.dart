// UX picture tool (not a guard): the four private tag chips as they were, and
// InkPill in their place, side by side (wave 3b).
// UX_SHOTS=<folder> flutter test test/ux_ink_pill_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'support/fonts.dart';

// The chips as they were.
Widget _harbor(BuildContext c, String t, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(t,
          style: Theme.of(c)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontSize: 10)),
    );

Widget _origin(BuildContext c, IconData icon, String t, Color color) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(t,
            style: Theme.of(c).textTheme.labelMedium?.copyWith(color: color)),
      ]),
    );

Widget _offer(BuildContext c, String t, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(t,
          style: Theme.of(c)
              .textTheme
              .labelSmall
              ?.copyWith(fontWeight: FontWeight.w700)),
    );

Widget _choice(BuildContext c, String t, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.7)),
        color: color.withValues(alpha: 0.12),
      ),
      child: Text(t,
          style: Theme.of(c)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w700)),
    );

void main() {
  final dir = Platform.environment['UX_SHOTS'];
  testWidgets('the tag chips, before and after', (tester) async {
    if (dir == null) return;
    await tester.runAsync(loadAppFonts);
    tester.view.physicalSize = const Size(720, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    const rare = Color(0xFF4FA3A5), ash = Color(0xFF9A96A6);
    const clan = Color(0xFFB04A3A), gold = Color(0xFFF2C14E);
    Widget row(String name, Widget before, Widget after) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            SizedBox(
                width: 130,
                child:
                    Text(name, style: const TextStyle(color: Colors.white70))),
            SizedBox(
                width: 250,
                child: Align(alignment: Alignment.centerLeft, child: before)),
            SizedBox(
                width: 250,
                child: Align(alignment: Alignment.centerLeft, child: after)),
          ]),
        );
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(const ColorScheme.dark()),
      home: Scaffold(
        body: RepaintBoundary(
          key: key,
          child: Builder(
            builder: (c) => Container(
              color: const Color(0xFF17151B),
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Row(children: [
                  SizedBox(width: 130),
                  SizedBox(
                      width: 250,
                      child: Text('Before',
                          style: TextStyle(color: Colors.white))),
                  SizedBox(
                      width: 250,
                      child: Text('After: InkPill',
                          style: TextStyle(color: Colors.white))),
                ]),
                row('Harbour parts', _harbor(c, 'Rare', rare),
                    const InkPill(label: 'Rare', color: rare)),
                row('Harbour version', _harbor(c, 'Version III', ash),
                    const InkPill(label: 'Version III', color: ash)),
                row(
                    'Origin lesson',
                    _origin(c, Icons.auto_awesome, 'Patience', gold),
                    const InkPill(
                        label: 'Patience',
                        color: gold,
                        icon: Icons.auto_awesome,
                        large: true)),
                row(
                    'Offer',
                    _offer(c, 'Skill', clan),
                    const InkPill(
                        label: 'Skill', color: clan, neutralText: true)),
                row('Choice card', _choice(c, '+20 G', gold),
                    const InkPill(label: '+20 G', color: gold)),
              ]),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(dir).createSync(recursive: true);
      File('$dir/ink-pill-before-after.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
