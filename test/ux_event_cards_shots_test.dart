// PICTURES (UX_SHOTS=<folder>): MOCKS of clearer Tower event cards: each
// button says what it does, its outcome sits under it, a check shows its stat
// and odds, and plays the real transparent d20 (D20Roll). Not wired in.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/screens/tower/ink/ink_palette.dart';
import 'package:narrative_data_app/screens/tower/tower_look.dart'
    show TowerNight;
import 'package:narrative_data_app/theme/stitched_ink.dart' show InkFonts;
import 'package:narrative_data_app/widgets/d20_roll.dart';
import 'package:narrative_data_app/widgets/ink_panel.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart'
    show buildAppTheme, stitchedInkScheme;

import 'support/fonts.dart';

Widget _tag(IconData i, String t, Color c) => Builder(
    builder: (context) => Row(children: [
          Icon(i, size: 16, color: c),
          const SizedBox(width: 6),
          Text(t.toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: c, letterSpacing: 1.2)),
        ]));

/// A choice: its button, then under it what it costs and what it wins.
class _Choice extends StatelessWidget {
  const _Choice(this.label, this.sub, this.lines,
      {this.primary = false, this.check});
  final String label;
  final String sub;
  final List<(IconData, Color, String)> lines;
  final bool primary;
  final String? check;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final btn = primary
        ? FilledButton(onPressed: () {}, child: Text(label))
        : OutlinedButton(onPressed: () {}, child: Text(label));
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        border: Border.all(color: inkSlate, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: double.infinity, child: btn),
        const SizedBox(height: 6),
        Text(sub, style: t.bodyMedium),
        if (check != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(check!, style: t.labelLarge?.copyWith(color: inkPaper)),
          ),
        for (final (icon, color, text) in lines)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: t.bodySmall)),
            ]),
          ),
      ]),
    );
  }
}

Widget _title(BuildContext c, String s) => Text(s,
    style: Theme.of(c)
        .textTheme
        .titleMedium
        ?.copyWith(fontFamily: InkFonts.display));

class _Shortcut extends StatelessWidget {
  const _Shortcut();
  @override
  Widget build(BuildContext context) => InkPanel(
        lit: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _tag(Icons.stairs, 'Shortcut', inkPaper),
          const SizedBox(height: 6),
          _title(context, 'A stair that skips the floors'),
          Text('A narrow stair climbs past floors 5 and 6, straight to 7.',
              style: Theme.of(context).textTheme.bodyMedium),
          const _Choice(
            'Take the stair',
            'Fight a tougher foe now: an Elite.',
            [
              (Icons.north, inkPaper, 'Win: skip 2 floors, land on floor 7.'),
              (Icons.close, inkRed, 'Lose: the run ends here.'),
            ],
            primary: true,
          ),
          const _Choice(
            'Take the door',
            'Climb floor 5 as it is.',
            [
              (Icons.check, inkPaper, 'No risk, no floors skipped.'),
            ],
          ),
        ]),
      );
}

class _Parley extends StatelessWidget {
  const _Parley();
  @override
  Widget build(BuildContext context) => InkPanel(
        lit: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _tag(Icons.forum_outlined, 'Parley', inkPaper),
          const SizedBox(height: 6),
          _title(context, 'The guardian will hear you'),
          Text('It lowers its guard, if the words are right.',
              style: Theme.of(context).textTheme.bodyMedium),
          const _Choice(
            'Talk  ·  Charisma +3',
            'Roll d20 + 3 against 12: 60% to pass.',
            [
              (Icons.north, inkPaper, 'Pass: slip by, land on floor 6.'),
              (Icons.sports_mma, inkRed, 'Fail: you fight it anyway.'),
              (
                Icons.info_outline,
                inkSlate,
                'Skipping the fight gives up its spoils.'
              ),
            ],
            primary: true,
          ),
          const _Choice(
            'Fight',
            'No roll. Take the fight and its spoils.',
            [
              (Icons.check, inkPaper, 'Win it: floor 5 as usual, spoils kept.'),
            ],
          ),
        ]),
      );
}

/// The check, step by step with the real d20.
class _Check extends StatelessWidget {
  const _Check(this.stage, {this.roll = 14, this.pass = true, this.rollId = 1});
  final int stage; // 0 ready, 1 rolling, 2 landed, 3 result
  final int roll;
  final bool pass;
  final int rollId;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final total = roll + 3;
    final landed = stage >= 2;
    final color = !landed ? inkPaper : (pass ? inkPaper : inkRed);
    return InkPanel(
      lit: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tag(Icons.forum_outlined, 'Parley · Charisma check', inkPaper),
        const SizedBox(height: 6),
        _title(context, 'The guardian will hear you'),
        const SizedBox(height: 6),
        Text(
            stage == 0
                ? 'Charisma +3 against DC 12 · 60% to pass'
                : 'Charisma +3 against DC 12',
            style: t.bodyMedium),
        const SizedBox(height: 26),
        Center(
          child: D20Roll(
            roll: stage == 0 ? null : roll,
            success: landed ? pass : null,
            rollId: rollId,
            size: 140,
          ),
        ),
        SizedBox(
          height: 26,
          child: Center(
            child: Text(landed ? '$roll + 3 = $total  ·  DC 12' : '',
                style: t.titleMedium?.copyWith(color: color)),
          ),
        ),
        SizedBox(
          height: 24,
          child: Center(
            child: Text(stage >= 3 ? (pass ? 'PASSED' : 'FAILED') : '',
                style: t.titleSmall?.copyWith(color: color, letterSpacing: 2)),
          ),
        ),
        if (stage >= 3)
          Row(children: [
            Icon(pass ? Icons.north : Icons.sports_mma, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    pass
                        ? 'Words win: you slip by and land on floor 6.'
                        : 'It does not listen: the fight begins.',
                    style: t.bodyMedium)),
          ])
        else
          const SizedBox(height: 20),
      ]),
    );
  }
}

Future<void> _shot(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final render =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<GlobalKey> _show(
    WidgetTester tester, double w, double h, Widget card) async {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1;
  final key = GlobalKey();
  await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(stitchedInkScheme(Brightness.dark)),
    home: RepaintBoundary(
      key: key,
      child: TowerNight(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(padding: const EdgeInsets.all(16), child: card),
        ),
      ),
    ),
  )));
  await tester.pump(const Duration(milliseconds: 100));
  return key;
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final scene = Platform.environment['UX_SCENE'] ?? 'cards';

  testWidgets('event cards', skip: shots == null || scene != 'cards',
      (tester) async {
    await tester.runAsync(loadAppFonts);
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.reset);
    for (final w in [412.0, 360.0]) {
      var key = await _show(tester, w, 450, const _Shortcut());
      await _shot(tester, key, '$shots/shortcut-${w.toInt()}.png');
      key = await _show(tester, w, 480, const _Parley());
      await _shot(tester, key, '$shots/parley-${w.toInt()}.png');
    }
  });

  testWidgets('check frames', skip: shots == null || scene != 'check',
      (tester) async {
    await tester.runAsync(loadAppFonts);
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.reset);
    var key = await _show(tester, 412, 440, const _Check(0));
    await _shot(tester, key, '$shots/gif/f00.png');
    var n = 1;
    // Roll: the d20 tumbles (frames every 100 ms), then lands, then result.
    await tester.pumpWidget(const SizedBox());
    for (final pass in [true, false]) {
      key = await _show(tester, 412, 440, const _Check(0));
      final roll = pass ? 14 : 6;
      Future<void> frame(int stage, {int ms = 0}) async {
        if (ms > 0) await tester.pump(Duration(milliseconds: ms));
        await _shot(tester, key,
            '$shots/gif${pass ? '' : 'f'}/f${(n++).toString().padLeft(2, '0')}.png');
      }

      // Replace the card with the rolling one (rolls on its own).
      tester.view.physicalSize = const Size(412, 440);
      await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(stitchedInkScheme(Brightness.dark)),
        home: RepaintBoundary(
          key: key,
          child: TowerNight(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _Check(1, roll: roll, pass: pass),
              ),
            ),
          ),
        ),
      )));
      await frame(1);
      for (var i = 0; i < 16; i++) {
        await frame(1, ms: 100);
      }
      // Landed: roll, bonus, total, target.
      await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(stitchedInkScheme(Brightness.dark)),
        home: RepaintBoundary(
          key: key,
          child: TowerNight(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _Check(2, roll: roll, pass: pass),
              ),
            ),
          ),
        ),
      )));
      for (var i = 0; i < 4; i++) {
        await frame(2, ms: 100);
      }
      await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(stitchedInkScheme(Brightness.dark)),
        home: RepaintBoundary(
          key: key,
          child: TowerNight(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _Check(3, roll: roll, pass: pass),
              ),
            ),
          ),
        ),
      )));
      for (var i = 0; i < 10; i++) {
        await frame(3, ms: 100);
      }
      n = 1;
    }
  });
}
